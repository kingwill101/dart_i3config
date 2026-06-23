# i3config

[![Pub Version](https://img.shields.io/pub/v/i3config)](https://pub.dev/packages/i3config)
[![Pub Points](https://img.shields.io/pub/points/i3config)](https://pub.dev/packages/i3config/score)
[![Pub Popularity](https://img.shields.io/pub/popularity/i3config)](https://pub.dev/packages/i3config/score)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.9-blue)](https://dart.dev)
[![License](https://img.shields.io/github/license/kingwill101/dart_i3config)](LICENSE)
[![GitHub](https://img.shields.io/badge/repo-github-blue)](https://github.com/kingwill101/dart_i3config)

A Dart library for parsing and processing i3/Sway like configuration files. Includes a state machine processor with pluggable handlers, scoped contexts, variable expansion, file imports, string interpolation, block references, dotted command heads, hex color value support, inline comments, and a virtual filesystem for testing.

## Features

### Core
- **State machine processor** – `ConfigProcessor` routes AST nodes through states and handlers
- **Pluggable handlers** – register custom `CommandHandler` and `BlockHandler` implementations
- **Block-scoped commands** – commands that only apply inside a specific block type
- **File imports** – `include` with variable expansion, nesting, and circular detection
- **Pluggable filesystem** – `PhysicalFileSystem` for real I/O, `VirtualFileSystem` for tests
- **Variable scoping** – block-level context with parent inheritance
- **Async handlers** – handlers can be sync or async; the processor awaits them


## Quick Start

```dart
import 'package:i3config/i3config.dart';

Future<void> main() async {
  final processor = ConfigProcessor();

  await processor.processString('''
set \$mod Mod4
bindsym \$mod+Return exec i3-sensible-terminal
''');

  print(processor.context.getVariable('mod')); // Mod4
}
```

`Config.parse` builds the AST. `ConfigProcessor.process` / `processString` run
the state machine and execute registered handlers.

## How It Works

```
Config text → Parser → AST → State Machine → Handlers → Context
```

1. **Parse** – `Config.parse(text)` produces an AST of statements
2. **Process** – `processor.process(config)` routes each element through the state machine
3. **Handle** – registered handlers execute per command/block type
4. **Context** – variables, options, and errors accumulate in the scoped context

## Built-in Handlers

`ConfigProcessor` auto-registers these handlers:

| Command | Handler | Effect |
|---------|---------|--------|
| `set $var value` | `SetCommandHandler` | Stores a variable in the current context |
| `include "path"` | `IncludeHandler` | Reads, parses, and processes another config file |

Unhandled commands are passed through for default property processing.

## Custom Command Handlers

```dart
class BindsymHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'bindsym';

  @override
  void handle(Command command, Context context) {
    final key = command.getArgAsString(0, context);
    final action = command.getArgAsString(1, context);
    context.setVariable('binding_$key', action);
  }
}

Future<void> main() async {
  final processor = ConfigProcessor()
    ..registerCommandHandler(BindsymHandler());

  await processor.processString('bindsym \$mod+Return exec alacritty');
}
```

### Handler Resolution

1. Block-scoped command handlers (when inside a matching block)
2. Global command handlers
3. Default command processing

## Block-Scoped Handlers

Block handlers register commands that only work inside a specific block.
They also create child contexts – variables set inside the block are local
but parent variables remain readable.

```dart
class BarBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';

  @override
  void handle(Block block, Context context) {
    print('Bar: ${getBlockIdentifier(block, context)}');
  }

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', StatusHandler());
    registry.registerCommand('position', PositionHandler());
  }
}

class StatusHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'status_command';

  @override
  void handle(Command command, Context context) {
    context.setVariable('bar_status', command.getArgAsString(0, context));
  }
}

class PositionHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'position';

  @override
  void handle(Command command, Context context) {
    context.setVariable('bar_position', command.getArgAsString(0, context));
  }
}

Future<void> main() async {
  final processor = ConfigProcessor()
    ..registerBlockHandler(BarBlockHandler());

  await processor.processString('''
bar "top" {
    status_command i3status
    position top
}
''');
}
```

Inside a `bar` block, `status_command` and `position` resolve through
bar-scoped handlers. Outside, those handlers are inactive.

## File Imports

The built-in `IncludeHandler` reads and processes external config files
during state machine execution.

```dart
await processor.processString('''
set \$config_dir ~/.config/i3
include "\$config_dir/modules/bar.conf"
include "\$config_dir/modules/colors.conf"
''');
```

Supports:
- Relative and absolute paths
- Variable expansion (`$var` / `${var}`)
- `~` home-directory expansion
- Nested includes
- Circular include detection

### Pluggable Filesystem

The `IncludeHandler` reads files through a `FileSystem` interface rather than
`dart:io` directly, so you can swap implementations:

| Implementation | When to Use |
|----------------|-------------|
| `PhysicalFileSystem` | Production (default) |
| `VirtualFileSystem` | Tests (in-memory) |

```dart
import 'package:i3config/i3config.dart';
import 'package:i3config/src/test_vfs.dart';

void main() async {
  final vfs = VirtualFileSystem();
  vfs.createFile('colors.conf', 'set \$bg "#2e3440"');

  final processor = ConfigProcessor(fileSystem: vfs);
  await processor.processString('include "colors.conf"');

  print(processor.context.getVariable('bg')); // #2e3440
}
```

The `VirtualFileSystem` lives in `src/test_vfs.dart` and is available
in published releases for your own tests.

## Assignments and Arrays

The library represents `=` and `+=` as `Assignment` nodes. Direct assignment produces a
scalar; append assignment builds an array.

```dart
await processor.processString('''
order = "wireless wlan0"
order += "battery 0"
order += "clock"
''');

print(processor.context.getVariable('order'));
// [wireless wlan0, battery 0, clock]
```

Use `Config.parse` directly to inspect the AST without processing:

```dart
final config = Config.parse('order += "wireless"');
for (final a in config.statements.whereType<Assignment>()) {
  print('${a.variable} ${a.operator} ${a.values}');
}
```

## Error Handling

Parse errors throw from `Config.parse`. Processing errors flow through the error handler.

```dart
class Logger implements ErrorHandler {
  @override
  void handleError(String message, Context context, {SourceSpan? span}) {
    print('Error at ${span?.start.line ?? '?'}:${span?.start.column ?? '?'}: $message');
  }
}

final processor = ConfigProcessor()..setErrorHandler(Logger());
await processor.processString('include "missing.conf"');
```

Enable warnings for unresolved references:

```dart
processor.context.reportUnresolvedVariables = true;
processor.context.reportUnresolvedBlockReferences = true;
```

## Installation

```yaml
dependencies:
  i3config: ^2.0.0
```

```bash
dart pub get
```

## Documentation

- **[Documentation](docs/)** – state machine architecture, handlers, scoping, filesystem
- **[Examples](example/)** – runnable Dart example files

## License

MIT – see [LICENSE](LICENSE).

## Additional Resources

- [i3 User Guide](https://i3wm.org/docs/userguide.html#configuring)
- [Package Documentation](https://pub.dev/documentation/i3config)
