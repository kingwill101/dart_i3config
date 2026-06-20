# i3conf V2 Documentation

V2 introduces a powerful state machine architecture with handler-based processing, scoped commands, variable expansion, and advanced configuration manipulation capabilities.

## Quick Start

### State Machine Processing
```dart
import 'package:i3config/i3config_v2.dart';

final config = Config.parse(configContent);
final processor = ConfigProcessor();

// Register handlers
processor.registerCommandHandler(MyCommandHandler());
processor.registerBlockHandler(MyBlockHandler());

await processor.process(config);
```

### Simple AST Iteration (No State Machine)
```dart
import 'package:i3config/i3config_v2.dart';

final config = Config.parse(configContent);

// Direct AST access without processing
for (final element in config.statements) {
  print('${element.runtimeType}: $element');
}
```

## Key Features

- **State Machine**: Advanced processing pipeline with configurable states
- **Handler System**: Extensible command and block handlers
- **Scoped Commands**: Commands that only work within specific blocks
- **Variable Expansion**: Dynamic variable resolution with scoping
- **Async Support**: Asynchronous handler processing
- **Array Handling**: Built-in support for array operations
- **Context Management**: Hierarchical variable and option scoping
- **File Imports**: Include and process external config files during processing

## Architecture Overview

```
Config → Parser → AST → State Machine → Handlers → Context
```

1. **Config**: Raw configuration text
2. **Parser**: PetitParser-based parsing to AST
3. **AST**: Abstract Syntax Tree representation
4. **State Machine**: Processing pipeline with different states
5. **Handlers**: User-defined command and block processors
6. **Context**: Variable and option management with scoping

## Core Concepts

### Simplified AST Types
V2 uses a simplified AST structure (5 types vs V1's 6 types):
- **ConfigElement** (sealed): Base for all elements
  - **Config**: Root container with statements
  - **Statement** (sealed): Base for all statements
    - **Assignment**: `variable = value` or `variable += value` (replaces Property + ArrayElement)
    - **Block**: `block_type { }` with body (replaces Section)
    - **Command**: Raw commands like `bindsym`, `set`
  - **Comment**: `# comments` (replaces Comment + CommentBlock)

**Benefits of Simplification:**
- Fewer types to handle in pattern matching
- Cleaner, more intuitive API
- Better type safety with sealed classes
- Easier migration from V1

### State Machine
The processing pipeline uses different states:
- **InitialState**: Routes elements to appropriate processors
- **CommandProcessingState**: Handles command execution
- **BlockProcessingState**: Manages block processing
- **AssignmentProcessingState**: Processes variable assignments

### Handlers
Extensible processing system:
- **CommandHandler**: Process specific commands
- **BlockHandler**: Handle block types with scoped commands
- **BaseCommandHandler**: Built-in value expansion and type safety
- **BaseBlockHandler**: Automatic child processing and helpers

### Context System
Hierarchical variable and option management:
- **Global Context**: Top-level variables and options
- **Block Context**: Scoped variables within blocks
- **Variable Expansion**: Dynamic resolution with inheritance

### File Imports
The V2 processor can execute `include` commands while processing a configuration. `Config.parse` still only builds the AST; file imports are resolved when you call `ConfigProcessor.process` or `processString`.

```i3
include "modules/bar.conf"
include "$config_dir/colors.conf"
```

The built-in `IncludeHandler` is registered automatically by `ConfigProcessor`. It reads the included file, parses it as V2 configuration, and processes it in place, so variables and commands from the included file become part of the current processing context.

File imports support:
- Relative and absolute paths
- Variable expansion with `$variable` and `${variable}`
- `~` home-directory expansion
- Nested includes
- Circular include detection

#### Filesystem Abstraction

The `IncludeHandler` uses a pluggable `FileSystem` interface instead of
accessing `dart:io` directly. Two implementations are provided:

- **`PhysicalFileSystem`** (default) — reads real files from disk via `dart:io`
- **`VirtualFileSystem`** — in-memory store for testing

Inject a filesystem via `ConfigProcessor`:

```dart
// Testing: use virtual filesystem
final vfs = VirtualFileSystem();
vfs.createFile('colors.conf', 'set $bg "#2e3440"');

final processor = ConfigProcessor(fileSystem: vfs);
await processor.processString('include "colors.conf"');

// Production: defaults to PhysicalFileSystem
final processor2 = ConfigProcessor();
await processor2.processString('include "/etc/i3/config"');
```

This makes it easy to test configurations that use `include` directives
without creating temporary files on disk.

### Block-Scoped Handlers
Block handlers can register commands that only apply inside a specific block type. Scoped command handlers take precedence over global handlers while the processor is inside the matching block.

```dart
class BarBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', StatusCommandHandler());
    registry.registerCommand('position', PositionCommandHandler());
  }
}
```

```i3
bar "top" {
    status_command i3status
    position top
}
```

Blocks also create child contexts. Variables set inside a block are scoped to that block, while parent/global variables remain readable unless shadowed.

## Examples

### Basic State Machine Usage
```dart
final config = Config.parse('''
set \$mod Mod4
bar "top" {
    status_command i3status
    position top
}
''');

final processor = ConfigProcessor();
await processor.process(config);
```

### Processing Included Files
```dart
final config = Config.parse('''
set \$config_dir ~/.config/i3
include "\$config_dir/modules/bar.conf"
include "\$config_dir/modules/colors.conf"
''');

final processor = ConfigProcessor();
await processor.process(config);
```

`include` commands are processed during state-machine execution, not during `Config.parse`. The included files are parsed and processed using the same processor and context.

Files are read through the [FileSystem abstraction](#filesystem-abstraction).
For tests, inject a virtual filesystem:

```dart
final vfs = VirtualFileSystem();
vfs.createFile('modules/bar.conf', 'position top');

final processor = ConfigProcessor(fileSystem: vfs);
await processor.process(Config.parse('include "modules/bar.conf"'));
```

### Block-Scoped Handler Example
```dart
class BarBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';

  @override
  void handle(Block block, Context context) {
    print('Processing bar: ${getBlockIdentifier(block, context)}');
  }

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', StatusCommandHandler());
    registry.registerCommand('position', PositionCommandHandler());
  }
}
```

```dart
final config = Config.parse('''
bar "top" {
    status_command i3status
    position top
}
''');

final processor = ConfigProcessor()
  ..registerBlockHandler(BarBlockHandler());

await processor.process(config);
```

When the processor enters a `bar` block, `status_command` and `position` are resolved through the bar-scoped handlers instead of the global command registry.

### Custom Command Handler
```dart
class MyCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'my_command';
  
  @override
  String? handle(Command command, Context context) {
    final value = command.getArgAsString(0, context);
    print('Processing: $value');
    return value;
  }
}
```

### Custom Block Handler
```dart
class MyBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'my_block';
  
  @override
  void handle(Block block, Context context) {
    print('Processing block: ${getBlockIdentifier(block, context)}');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('scoped_cmd', MyScopedHandler());
  }
}
```

### Simple AST Iteration
```dart
final config = Config.parse(configContent);

// Just iterate without processing
for (final statement in config.statements) {
  if (statement is Command) {
    print('Command: ${statement.head}');
  } else if (statement is Assignment) {
    print('Assignment: ${statement.variable} = ${statement.values}');
  }
}
```

## When to Use V2

- Building configuration management tools
- Need advanced processing capabilities
- Want handler-based architecture
- Require scoped commands and variables
- Building on top of i3 configuration
- Need async processing support

## Migration from V1

See [Migration Guide](migration.md) for detailed upgrade instructions.

## Advanced Topics

- [Command Handlers](command-handlers.md) - Processing individual commands, including file imports
- [Block Handlers](block-handlers.md) - Processing block types and scoped commands
- [Context and Scoping](context-and-scoping.md) - Variable management and inheritance
- [Configuration Examples](configuration-examples.md) - Real-world config to handler mapping
- [Simple AST Iteration](simple-ast-iteration.md) - Using V2 parser without state machine
- [Migration Guide](migration.md) - Upgrading from V1 to V2
- [API Reference](api-reference.md) - Complete V2 API documentation
