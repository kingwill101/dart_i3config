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

- [Block Handlers](block-handlers.md) - Processing block types and scoped commands
- [Command Handlers](command-handlers.md) - Processing individual commands
- [Context and Scoping](context-and-scoping.md) - Variable management and inheritance
- [Configuration Examples](configuration-examples.md) - Real-world config to handler mapping
- [Simple AST Iteration](simple-ast-iteration.md) - Using V2 parser without state machine
- [Migration Guide](migration.md) - Upgrading from V1 to V2
- [API Reference](api-reference.md) - Complete V2 API documentation
