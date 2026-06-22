# i3 Config Language Guide

A complete reference for the i3/Sway configuration language and the `i3config` library.

---

## i3 Config Language Syntax

### Comments

Lines starting with `#` are comments:

```i3
# This is a comment
set $mod Mod4
```

### Value Types

#### Bare Arguments

Unquoted values like identifiers, paths, and numbers:

```i3
bindsym $mod+Return exec i3-sensible-terminal
position top
```

#### Quoted Strings

Double or single quoted strings for values containing spaces or special characters:

```i3
workspace = "1: Dev"
mode "resize" {
    bindsym h resize shrink width 10 px
}
```

Escape sequences inside quoted strings:
- `\"` → `"`, `\'` → `'`, `\\` → `\`
- `\n` → newline, `\r` → carriage return, `\t` → tab
- `\{` → `{`, `\}` → `}`

#### Variable References

Variables are defined with `set` and referenced with `$` prefix:

```i3
set $mod Mod4
set $terminal i3-sensible-terminal
bindsym $mod+Return exec $terminal
```

#### Array Values

Arrays group multiple values inside `[...]` brackets:

```i3
workspace = ["1: Dev", "2: Term"]
workspace += ["3: Mail"]
```

Array items are comma-separated. Items can be any value type (bare args, quoted strings, variable refs, or nested arrays). Trailing commas are rejected.

### Assignment Operators

| Operator | Meaning |
|----------|---------|
| `=` | Set variable to value(s) |
| `+=` | Append value(s) to existing array |

```i3
fonts = "Fira Code"
fonts += "Noto Sans"
```

### Commands

Commands are the main building blocks of i3 configs. They consist of a command head followed by arguments:

```i3
bindsym $mod+Return exec i3-sensible-terminal
exec --no-startup-id nm-applet
```

#### Criteria

Criteria target specific windows and appear in brackets after the command head:

```i3
for_window [class="Firefox"] move to workspace 2
assign [class="Firefox" instance="firefox"] → 2
```

Multiple criteria are space-separated. Each criterion is `key=value`.

#### Command Chains

Multiple commands can be chained on one line with `;`:

```i3
bindsym $mod+Shift+q kill; workspace 1
```

### Blocks

Blocks group commands under a header:

```i3
bar {
    status_command i3status
    position top
    tray_output primary
}

mode "resize" {
    bindsym h resize shrink width 10 px
    bindsym j resize grow height 10 px
}
```

Common block types: `bar`, `mode`, `input`, `output`, `seat`.

### Include Directives

Include other config files (processed at runtime, not during parsing):

```i3
include "~/.config/i3/modules/colors.conf"
include "$config_dir/bar.conf"
```

---

## Library Usage

### Installing

Add to `pubspec.yaml`:

```yaml
dependencies:
  i3config: ^2.1.0
```

### Parsing

#### V2 (Default)

```dart
import 'package:i3config/i3config.dart';

void main() {
  final config = Config.parse('''
    set $mod Mod4
    bindsym $mod+Return exec i3-sensible-terminal
    bar {
        status_command i3status
    }
  ''');

  for (final stmt in config.statements) {
    switch (stmt) {
      case Command c:
        print('Command: ${c.head}');
      case Assignment a:
        print('Assignment: ${a.variable} ${a.operator} ${a.values}');
      case Block b:
        print('Block: ${b.blockType}');
      case Comment c:
        print('Comment: ${c.content}');
    }
  }
}
```

#### V1 (Legacy)

```dart
import 'package:i3config/i3config_v1.dart';

void main() {
  final parser = I3ConfigParser(configContent);
  final config = parser.parse();
  print('Parsed ${config.elements.length} elements');
}
```

#### Error Handling

```dart
import 'package:i3config/i3config_v2.dart';

void main() {
  final parser = Parser();
  final result = parser.parseWithDetails(malformedContent);

  switch (result) {
    case ParseSuccess(:final config):
      print('Parsed ${config.statements.length} statements');
    case ParseFailure(:final error, :final suggestion):
      print('Line ${error.line}, col ${error.column}: ${error.message}');
      if (suggestion != null) print('Suggestion: $suggestion');
  }
}
```

### Processing with the State Machine

The state machine processes config elements through pluggable handlers:

```dart
import 'package:i3config/i3config_v2.dart';

class TerminalHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'exec';

  @override
  void handle(Command command, Context context) {
    final cmd = command.getArgAsString(0, context);
    print('Would execute: $cmd');
  }
}

void main() async {
  final processor = ConfigProcessor()
    ..registerCommandHandler(TerminalHandler());

  await processor.processString('''
    exec i3-sensible-terminal
    exec firefox
  ''');
}
```

#### Block Handlers

```dart
class StatusHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'status_command';

  @override
  void handle(Command command, Context context) {
    final status = command.getArgAsString(0, context);
    print('Bar status: $status');
  }
}

class BarHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', StatusHandler());
  }
}
```

### Formatting Configs

#### Programmatic API

```dart
import 'package:i3config/i3config.dart';

void main() {
  final config = Config.parse('''
    set $mod Mod4
    bar {
    status_command i3status
  }
  ''');

  final formatter = ConfigFormatter(
    options: FormatterOptions(indent: 4, sortAssignments: true),
  );

  print(formatter.format(config));
}
```

#### CLI Tool

Format config files from the command line:

```bash
# Format a file, output to stdout
dart run i3fmt config.conf

# Format and write to a new file
dart run i3fmt config.conf -o formatted.conf

# Read from stdin
cat config.conf | dart run i3fmt

# Custom indentation
dart run i3fmt config.conf --indent 4

# Sort assignments
dart run i3fmt config.conf --sort
```

### Testing

The library provides a `VirtualFileSystem` for testing `include` directives without real files:

```dart
import 'package:i3config/i3config_v2.dart';

void main() async {
  final vfs = VirtualFileSystem();
  vfs.createFile('colors.conf', 'set $bg "#2e3440"');

  final processor = ConfigProcessor(fileSystem: vfs);
  await processor.processString('include "colors.conf"');

  print(processor.context.getVariable('bg')); // #2e3440
}
```

### JSON Serialization

The AST supports JSON round-trip:

```dart
final config = Config.parse('set $mod Mod4');
final json = config.toJson();
final restored = Config.fromJson(json);
```

### Visitor Pattern

Traverse the AST with the visitor:

```dart
class CountingVisitor implements ConfigVisitor<void> {
  int commands = 0;
  int assignments = 0;
  int blocks = 0;

  @override
  void visitConfig(Config config) {
    for (final stmt in config.statements) {
      switch (stmt) {
        case Command c: commands++;
        case Assignment a: assignments++;
        case Block b: blocks++;
        case Comment _: break;
      }
    }
  }
  // ... other visit methods
}
```

### Value API Reference

| Type | Description | `toConfigString()` |
|------|-------------|-------------------|
| `BareArg(value)` | Unquoted value | `value` |
| `Quoted(value, char)` | Quoted string | `"value"` or `'value'` |
| `VariableRef(name)` | `$name` reference | `$name` |
| `ArrayValue(items)` | `[item, ...]` | `[item1, item2]` |

### Formatter API Reference

```dart
class FormatterOptions {
  final int indent;           // spaces per level (default: 2)
  final bool sortAssignments; // sort assignments alphabetically (default: false)
  final bool trailingNewline; // trailing blank line (default: true)
}

class ConfigFormatter {
  ConfigFormatter({FormatterOptions? options});
  String format(Config config);
}
```

---

## Additional Resources

- [API Reference](api-reference.md) — Complete class and method documentation
- [Command Handlers](command-handlers.md) — Deep dive into command processing
- [Block Handlers](block-handlers.md) — Block type handling and scoping
- [Context and Scoping](context-and-scoping.md) — Variable management
- [Configuration Examples](configuration-examples.md) — Real-world examples
- [Migration Guide](migration.md) — Upgrading from V1
- [i3 User Guide](https://i3wm.org/docs/userguide.html) — Official i3 documentation
