# i3config

A robust Dart library for parsing and manipulating i3 window manager configuration files.

## Features

- Full support for i3 configuration syntax
- Preserves comments and formatting
- Handles nested sections
- Type inference for values (numbers, booleans, strings)
- Built-in JSON serialization
- Preserves order of configuration elements
- Comprehensive error handling

## Parser Versions

This library provides two parser implementations:

### V2 (Default) - Enhanced PetitParser Implementation
- **Import**: `package:i3config/i3config.dart` (default)
- **Recommended for**: All new projects and production use
- **Features**: Source position tracking, enhanced error reporting, type-safe AST
- **Status**: Default implementation, actively developed

### V1 (Legacy) - Hand-Written Parser
- **Import**: `package:i3config/i3config_v1.dart`
- **Recommended for**: Legacy compatibility only
- **Features**: Basic parsing, simple API
- **Status**: Stable, maintained for compatibility

V2 is the recommended choice for all new projects with its enhanced features and modern architecture.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  i3config: ^3.0.0
```

Or use the development version:

```yaml
dependencies:
  i3config:
    git:
      url: https://github.com/kingwill101/dart_i3config.git
```

Then run:

```bash
dart pub get
```

## Basic Usage

```dart
import 'package:i3config/i3config.dart';

void main() {
  final config = Config.parse('''
  # Set mod key  
  set \$mod Mod4
  
  # Start terminal
  bindsym \$mod+Return exec i3-sensible-terminal
  ''');

  print('Parsed ${config.statements.length} statements');

  // Access statements with source position information
  for (final statement in config.statements) {
    print('Statement type: ${statement.runtimeType}');
    
    if (statement.span != null) {
      final span = statement.span!;
      print('  Location: line ${span.start.line + 1}, column ${span.start.column + 1}');
      print('  Source: "${span.text.trim()}"');
    }
  }
}
```

## Working with Sections

Handle nested sections and properties:

```dart
import 'package:i3config/i3config.dart';

final config = Config.parse('''
bar {
    status_command i3status
    position top
    colors {
        background #000000
        statusline #ffffff
    }
}
''');

// Find commands with blocks (sections)
final barCommand = config.statements.whereType<Command>()
    .firstWhere((cmd) => cmd.head == 'bar' && cmd.block != null);

print('Section command: ${barCommand.head}');

// Access commands within the block
if (barCommand.block != null) {
  for (final element in barCommand.block!.body) {
    if (element is Command) {
      print('Command: ${element.head} ${element.args.join(' ')}');
      if (element.span != null) {
        print('  At line ${element.span!.start.line + 1}');
      }
      // Check for nested blocks
      if (element.block != null) {
        print('  Has nested block with ${element.block!.body.length} elements');
      }
    }
  }
}
```

## Type Support

Values are represented as Value objects with their original text:

```dart
import 'package:i3config/i3config.dart';

final config = Config.parse('''
general {
    interval = 1          # parsed as BareArg
    colors = true        # parsed as BareArg  
    format = "%H:%M:%S"  # parsed as Quoted
}
''');

// Find the general command with a block
final generalCommand = config.statements.whereType<Command>()
    .firstWhere((cmd) => cmd.head == 'general' && cmd.block != null);

// Access properties within the block
if (generalCommand.block != null) {
  for (final element in generalCommand.block!.body) {
    if (element is Command && element.args.length >= 2) {
      final key = element.head;         // property name
      final operator = element.args[0]; // = or +=
      final value = element.args[1];    // the value
      print('${key}: ${value} (${value.runtimeType})');
      // Shows: BareArg, Quoted, or VariableRef types
    }
  }
}
```

## Array Handling

Support for i3's array syntax:

```dart
import 'package:i3config/i3config.dart';

final config = Config.parse('''
# Status bar modules
order += "wireless wlan0"
order += "battery 0" 
order += "clock"
''');

// Find array assignment commands (parsed as "assign" commands)
final orderCommands = config.statements
    .whereType<Command>()
    .where((cmd) => cmd.head == 'assign' && 
                   cmd.args.isNotEmpty && 
                   cmd.args[0].toString().contains('order'));

print('Array values:');
for (final cmd in orderCommands) {
  if (cmd.args.length >= 3) {
    final variable = cmd.args[0]; // order
    final operator = cmd.args[1]; // +=
    final value = cmd.args[2];    // The actual value
    print('  ${variable} ${operator} ${value}');
    if (cmd.span != null) {
      print('    (line ${cmd.span!.start.line + 1})');
    }
  }
}
```

## Error Handling

The V2 parser provides enhanced error reporting with source positions:

```dart
import 'package:i3config/i3config.dart';

try {
  final config = Config.parse(malformedContent);
  print('Successfully parsed ${config.statements.length} statements');
} catch (e) {
  print('Parse error: $e');
  // V2 provides detailed error messages with line/column information
}

// For legacy compatibility, use V1:
// import 'package:i3config/i3config_v1.dart';
// final config = I3Config.parse(content);
```

## Contributing

Contributions are welcome! Please feel free to:

1. File bug reports and feature requests in [Issues](issues)
2. Submit [Pull Requests](pulls) with improvements
3. Improve documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Additional Resources

- [i3 User Guide](https://i3wm.org/docs/userguide.html#configuring)
- [Package Documentation](https://pub.dev/documentation/i3config)
