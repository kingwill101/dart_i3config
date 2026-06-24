# i3 Config Language Guide

A complete reference for the i3/Sway configuration language and the `i3config` library.

---

## i3 Config Language Syntax

### Comments

Lines starting with `#` are full-line comments. Inline comments (after a command or assignment on the same line) are also supported and stored as `trailingComment` on the AST node:

```i3
# This is a full-line comment
set $mod Mod4
bindsym $mod+Return exec i3-sensible-terminal # launch terminal
```

### Value Types

#### Bare Arguments

Unquoted values like identifiers, paths, and numbers:

```i3
bindsym $mod+Return exec i3-sensible-terminal
position top
```

#### Hex Color Values

`#` prefixed hex color values are recognized as bare arguments:

```i3
client.focused #4c7899 #285577 #ffffff #2e9ef4 #285577
client.background #ffffff
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

#### String Interpolation

Double-quoted strings support variable interpolation:

```i3
set $theme dark
set $status "i3status -c $theme"
set $separator "8 px"
set $launcher "rofi -font 'Noto Sans $font_size'"
```

Single-quoted strings remain literal (no interpolation).

Inside interpolated strings, `\$` escapes the dollar sign so it is treated as a literal character rather than a variable reference.

Interpolation also works inside arrays:

```i3
set $workspaces ["1: Dev", "$ws2", bar.main.position]
```

#### Block References

Reference properties from processed blocks using dotted paths:

```i3
bar "main" {
    status_command i3status
    position top
}

set $bar_pos bar.main.position
set $bar_cmd bar.main.status_command
```

Block references without an identifier match the first entry of that block type:

```i3
set $first_cmd bar.status_command
```

Unresolved block references resolve to an empty string.

#### Array Values

Arrays group multiple values inside `[...]` brackets:

```i3
workspace = ["1: Dev", "2: Term"]
workspace += ["3: Mail"]
```

Array items are comma-separated. Items can be any value type (bare args, quoted strings, triple-quoted strings, variable refs, or nested arrays). Trailing commas are rejected.

#### Triple-Quoted Strings

Multi-line literal strings delimited by `"""` or `'''`:

```i3
bindsym $mod+Return exec --no-startup-id """
  kitty --class "terminal" \
    -e "fish -l"
"""
```

Content is taken literally — no escape sequence processing and no variable interpolation. Backslashes, blank lines, and single/double quotes (outside the delimiter sequence) are preserved as-is.

Triple-quoted strings work in any value position, including arrays:

```i3
set $fonts ["Noto Sans", """10 px""", "Noto Mono"]
```

When the content contains the delimiter (e.g. `"""` inside a `"""`-delimited string), the formatter automatically switches to the alternate delimiter. If the content contains both `"""` and `'''`, a single-quoted string is used instead.

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

Command heads can include dots, matching i3's color class syntax:

```i3
client.focused #4c7899 #285577 #ffffff #2e9ef4 #285577
client.focused_inactive #333333 #5f676a #ffffff #484e50 #5f676a
client.unfocused #333333 #222222 #888888 #292d2e #222222
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

#### Parsing

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

#### Error Handling

```dart
import 'package:i3config/i3config.dart';

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
import 'package:i3config/i3config.dart';

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
import 'package:i3config/i3config.dart';

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
| `TripleQuoted(value, delimiter)` | Multi-line literal | `"""value"""` or `'''value'''` |
| `VariableRef(name)` | `$name` reference | `$name` |
| `ArrayValue(items)` | `[item, ...]` | `[item1, item2]` |
| `InterpolatedString(segments, quoteChar)` | `"literal $var literal"` | `"literal $var literal"` |
| `BlockReference(path)` | `blockType.identifier.property` | `blockType.identifier.property` |

`InterpolatedString` contains `ValueSegment` nodes:

| Segment Type | Description |
|------|-------------|
| `ValueSegmentLiteral(text)` | Plain text inside an interpolated string |
| `ValueSegmentVariableReference(name)` | `$name` inside an interpolated string |

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

- [Command Handlers](command-handlers.md) — Deep dive into command processing
- [Block Handlers](block-handlers.md) — Block type handling and scoping
- [Context and Scoping](context-and-scoping.md) — Variable management
- [Configuration Examples](configuration-examples.md) — Real-world examples
- [i3 User Guide](https://i3wm.org/docs/userguide.html) — Official i3 documentation
