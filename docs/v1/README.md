# i3conf V1 Documentation

V1 provides a simple, direct AST-based parser for i3 configuration files. It's perfect for basic parsing, configuration analysis, and simple manipulation tasks.

## Quick Start

```dart
import 'package:i3config/i3config_v1.dart';

final configContent = '''
general {
    interval = 1
    colors = true
}

order += "volume slave"
''';

final parser = I3ConfigParser(configContent);
final config = parser.parse();

// Iterate through all elements
for (var element in config.elements) {
  print(element);
}
```

## Key Features

- **Simple AST**: Direct access to parsed configuration elements
- **Type Inference**: Automatic parsing of integers, booleans, and strings
- **Order Preservation**: Maintains original element order
- **JSON Support**: Serialize/deserialize to JSON
- **Comment Preservation**: Keeps original comments and formatting

## API Reference

### I3ConfigParser

Main parser class for V1.

```dart
final parser = I3ConfigParser(configContent);
final config = parser.parse();
```

### Config

Root configuration object containing all parsed elements.

```dart
final config = parser.parse();
print('Total elements: ${config.elements.length}');

for (var element in config.elements) {
  print('${element.runtimeType}: $element');
}
```

### Element Types

- **Section**: `general { }` blocks
- **Property**: `interval = 1` key-value pairs  
- **ArrayElement**: `order += "item"` array additions
- **Command**: Raw i3 directives
- **Comment**: `# comments`
- **CommentBlock**: Multi-line comment blocks

## Examples

### Basic Parsing
```dart
final parser = I3ConfigParser('''
general {
    interval = 1
    colors = true
}
''');

final config = parser.parse();
// Process elements...
```

### JSON Serialization
```dart
final config = parser.parse();
final json = config.toJson();
final restored = Config.fromJson(json);
```

### Element Filtering
```dart
final config = parser.parse();

// Find all sections
final sections = config.elements.whereType<Section>();

// Find properties with specific names
final intervals = config.elements
    .whereType<Property>()
    .where((p) => p.name == 'interval');
```

## When to Use V1

- Simple configuration parsing and analysis
- Direct AST manipulation
- Legacy system compatibility
- Minimal processing requirements
- Learning the i3 configuration format

## Limitations

- No advanced processing capabilities
- No variable expansion
- No scoped command handling
- No state machine features
- Limited to basic AST operations
