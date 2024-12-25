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

Parse a simple i3 configuration:

```dart
import 'package:i3config/i3config.dart';

void main() {
  final config = I3Config.parse('''
  # Set mod key
  set $mod Mod4

  # Start terminal
  bindsym $mod+Return exec i3-sensible-terminal
  ''');

  // Access commands
  final commands = config.elements.whereType<Command>();
  print(commands.first.command); // "set $mod Mod4"
}
```

## Working with Sections

Handle nested sections and properties:

```dart
final config = I3Config.parse('''
bar {
    status_command i3status
    position top
    colors {
        background #000000
        statusline #ffffff
    }
}
''');

final barSection = config.elements.whereType<Section>().first;
print(barSection.properties['position']); // "top"

final colorsSection = barSection.children.whereType<Section>().first;
print(colorsSection.properties['background']); // "#000000"
```

## Type Support

Values are automatically parsed into appropriate types:

```dart
final config = I3Config.parse('''
general {
    interval = 1          # parsed as integer
    colors = true        # parsed as boolean
    format = "%H:%M:%S"  # parsed as string
}
''');

final section = config.elements.whereType<Section>().first;
print(section.properties['interval'].runtimeType); // int
print(section.properties['colors'].runtimeType);   // bool
```

## Array Handling

Support for i3's array syntax:

```dart
final config = I3Config.parse('''
# Status bar modules
order += "wireless wlan0"
order += "battery 0"
order += "clock"
''');

final array = config.elements.whereType<ArrayElement>().first;
print(array.name);   // "order"
print(array.values); // ["wireless wlan0", "battery 0", "clock"]
```

## Error Handling

The parser is designed to be forgiving with malformed input:

```dart
try {
  final config = I3Config.parse(malformedContent);
} catch (e) {
  print('Failed to parse config: $e');
}
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
