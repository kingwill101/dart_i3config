# i3config

A robust Dart library for parsing and manipulating i3 window manager configuration files.

## Features

- Full support for i3 configuration syntax (including nested blocks and command chains)
- Preserves comments and formatting
- Handles nested sections
- Type inference for values (numbers, booleans, strings)
- Built-in JSON serialization
- Preserves order of configuration elements
- Comprehensive error handling with contextual suggestions
- Dedicated AST nodes for assignments (`Assignment`) and criteria (`Criterion`)
- Line continuation support (`\`) with source-span tracking

## What's New in 2.0.0

- **Assignment-first AST** – variable assignments are represented by the new `Assignment` statement
- **Richer grammar coverage** – nested block parsing, complex criteria, chained commands, and escape sequences now share a single command pipeline
- **Actionable errors** – `Parser.parseWithDetails` returns suggestions for common syntax issues
- **Extended documentation** – refreshed migration guide, API reference, and end-to-end examples for V2

## Documentation

📚 **[Complete Documentation](docs/README.md)** - Comprehensive guides for both V1 and V2

- **[V1 Documentation](docs/v1/)** - Simple AST-based parser
- **[V2 Documentation](docs/v2/)** - State machine architecture  
- **[V1 vs V2 Comparison](docs/comparison.md)** - Side-by-side examples
- **[Migration Guide](docs/v2/migration.md)** - Upgrade from V1 to V2

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
  i3config: ^2.0.0
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

## Assignment Handling

Support for i3's assignment syntax with dedicated Assignment objects:

```dart
import 'package:i3config/i3config.dart';

final config = Config.parse('''
# Status bar modules
order += "wireless wlan0"
order += "battery 0" 
order += "clock"
''');

// Find assignment statements (now proper Assignment objects)
final orderAssignments = config.statements
    .whereType<Assignment>()
    .where((assignment) => assignment.variable == 'order');

print('Assignment values:');
for (final assignment in orderAssignments) {
  print('  ${assignment.variable} ${assignment.operator} ${assignment.values[0]}');
  if (assignment.span != null) {
    print('    (line ${assignment.span!.start.line + 1})');
  }
}

// Support for dotted identifiers
final dottedConfig = Config.parse('bar.colors.focused = "#ffffff"');
final dottedAssignment = dottedConfig.statements.first as Assignment;
print('Dotted assignment: ${dottedAssignment.variable} = ${dottedAssignment.values[0]}');
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
