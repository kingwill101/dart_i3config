# i3config

[![Pub Version](https://img.shields.io/pub/v/i3config)](https://pub.dev/packages/i3config)
[![Pub Points](https://img.shields.io/pub/points/i3config)](https://pub.dev/packages/i3config/score)
[![Pub Popularity](https://img.shields.io/pub/popularity/i3config)](https://pub.dev/packages/i3config/score)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.9-blue)](https://dart.dev)
[![License](https://img.shields.io/github/license/kingwill101/dart_i3config)](LICENSE)
[![GitHub](https://img.shields.io/badge/repo-github-blue)](https://github.com/kingwill101/dart_i3config)

A Dart library for parsing and processing i3/Sway configuration files. Includes a state machine processor with pluggable handlers, scoped contexts, variable expansion, file imports, string interpolation, block references, dotted command heads, hex color value support, inline comments, and a virtual filesystem for testing.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Key Features](#key-features)
- [Language Features](#language-features)
- [Built-in Handlers](#built-in-handlers)
- [Custom Handlers](#custom-handlers)
- [Assignments and Arrays](#assignments-and-arrays)
- [Error Handling](#error-handling)
- [Examples](#examples)
- [Documentation](#documentation)
- [License](#license)

## Installation

```yaml
dependencies:
  i3config: ^2.0.0
```

```bash
dart pub get
```

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

`Config.parse` builds the AST. `ConfigProcessor.process` / `processString` run the state machine and execute registered handlers.

For simple AST access without the state machine:

```dart
import 'package:i3config/i3config.dart';

void main() {
  final config = Config.parse('''
    set \$mod Mod4
    bar {
        status_command i3status
    }
  ''');

  for (final stmt in config.statements) {
    print('${stmt.runtimeType}: $stmt');
  }
}
```

## Key Features

- **State Machine** — advanced processing pipeline with configurable states
- **Handler System** — extensible command and block handlers
- **Scoped Commands** — commands that only work within specific blocks
- **Variable Expansion** — dynamic variable resolution with scoping
- **String Interpolation** — double-quoted strings support `$variable` references
- **Block References** — reference block properties via dotted paths like `bar.main.position`
- **Dotted Command Heads** — commands with dotted names (`client.focused`, `client.background`) parse as a single head
- **Hex Color Values** — `#`-prefixed hex colors parsed as bare arguments
- **File Imports** — `include` with variable expansion, nesting, and circular detection
- **Pluggable Filesystem** — `PhysicalFileSystem` for production, `VirtualFileSystem` for tests
- **Error Reporting** — configurable warnings for unresolved references with source spans
- **Async Support** — handlers can be sync or async; the processor awaits them
- **Array Handling** — built-in support for array operations via `+=`
- **Context Management** — hierarchical variable and option scoping

## Language Features

i3conf parses and processes the full i3/Sway config syntax, with several
extensions for dynamic configuration.

### String Interpolation

Double-quoted strings resolve `$variable` references. Single-quoted strings are literal.

```i3
set $theme   dark
set $status  "i3status -c $theme"
set $launcher "rofi -font 'Noto Sans $font_size'"
```

### Block References

Reference properties from other blocks using dotted paths.

```i3
bar "main" {
    status_command i3status
    position top
}

set $bar_pos  bar.main.position
set $bar_cmd  bar.main.status_command
```

Omitting the identifier matches the first block of that type:

```i3
set $first_cmd  bar.status_command
```

### Dotted Command Heads

Commands with dotted names parse as a single head:

```i3
client.focused   #tabbed   #4c7899
client.unfocused #tabbed   #285577
client.urgent    #tabbed   #900000
```

### Hex Color Values

`#`-prefixed hex colors are parsed as bare argument values:

```i3
set $bg       #2e3440
set $fg       #d8dee9
client.focused #tabbed #4c7899
```

### Inline Comments

Trailing `#` comments after commands and assignments are preserved:

```i3
bindsym $mod+Return exec alacritty  # launch terminal
set $mod Mod4                        # set mod key
```

### Assignments and Arrays

`=` assigns a scalar, `+=` appends to an array:

```i3
order = "wireless wlan0"
order += "battery 0"
order += "clock"
```

### File Imports with Variable Expansion

Include external config files during processing:

```i3
include "modules/bar.conf"
include "$config_dir/colors.conf"
include "~/.config/i3/workspaces.conf"
```

## Built-in Handlers

`ConfigProcessor` auto-registers these handlers:

| Command | Handler | Effect |
|---------|---------|--------|
| `set $var value` | `SetCommandHandler` | Stores a variable in the current context |
| `include "path"` | `IncludeHandler` | Reads, parses, and processes another config file |

Unhandled commands pass through for default property processing.

## Custom Handlers

### Custom Command Handler

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

### Block-Scoped Handlers

Block handlers register commands that only work inside a specific block:

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

Inside a `bar` block, `status_command` and `position` resolve through bar-scoped handlers. Outside, those handlers are inactive.

## Assignments and Arrays

`=` and `+=` produce `Assignment` nodes. Direct assignment produces a scalar; append assignment builds an array.

```dart
await processor.processString('''
order = "wireless wlan0"
order += "battery 0"
order += "clock"
''');

print(processor.context.getVariable('order'));
// [wireless wlan0, battery 0, clock]
```

Use `Config.parse` to inspect the AST without processing:

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

## Examples

Full runnable examples are in the [example/](example/) directory:

- `interpolation_and_block_ref_example.dart` — string interpolation and block references
- `dotted_heads_colors_example.dart` — dotted command heads and hex colors
- `i3conf_example.dart` — basic state machine usage
- `file_imports_example.dart` — file imports with virtual filesystem
- `formatter_example.dart` — formatting config AST back to text
- `block_scoped_handlers_example.dart` — block-scoped command handlers
- `command_value_extraction_example.dart` — extracting values from commands

## Documentation

- [Language Guide](docs/language-guide.md) — i3 config syntax and library usage
- [Block Handlers](docs/block-handlers.md) — processing block types and scoped commands
- [Command Handlers](docs/command-handlers.md) — processing individual commands, file imports
- [Context and Scoping](docs/context-and-scoping.md) — variable management and inheritance
- [Configuration Examples](docs/configuration-examples.md) — real-world config to handler mapping
- [Simple AST Iteration](docs/simple-ast-iteration.md) — using the parser without the state machine

## License

MIT — see [LICENSE](LICENSE).

## Additional Resources

- [i3 User Guide](https://i3wm.org/docs/userguide.html#configuring)
- [Package Documentation](https://pub.dev/documentation/i3config)
