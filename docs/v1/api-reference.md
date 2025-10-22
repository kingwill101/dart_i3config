# V1 API Reference

Complete API reference for i3conf V1.

## Core Classes

### I3Config
Root configuration container.

```dart
class I3Config {
  List<ConfigElement> elements = [];
  
  I3Config();
  
  // Parse configuration from string
  static I3Config parse(String configContent);
  
  // Convert to JSON
  Map<String, dynamic> toJson();
  
  // Create from JSON
  factory I3Config.fromJson(Map<String, dynamic> json);
}
```

### I3ConfigParser
Main parser class.

```dart
class I3ConfigParser {
  final String configContent;
  
  I3ConfigParser(this.configContent);
  
  // Parse configuration
  I3Config parse();
}
```

### ConfigElement (Abstract)
Base class for all configuration elements.

```dart
abstract class ConfigElement {
  // Convert to JSON
  Map<String, dynamic> toJson();
  
  // Create from JSON
  static ConfigElement fromJson(Map<String, dynamic> json);
}
```

## Element Types

### Section
Represents section blocks.

```dart
class Section extends ConfigElement {
  final String name;
  final List<ConfigElement> elements;
  
  Section(this.name, this.elements);
  
  // Convert to JSON
  @override
  Map<String, dynamic> toJson();
  
  // Create from JSON
  factory Section.fromJson(Map<String, dynamic> json);
}
```

### Property
Represents key-value properties.

```dart
class Property extends ConfigElement {
  final String name;
  final dynamic value;
  
  Property(this.name, this.value);
  
  // Convert to JSON
  @override
  Map<String, dynamic> toJson();
  
  // Create from JSON
  factory Property.fromJson(Map<String, dynamic> json);
}
```

### ArrayElement
Represents array additions.

```dart
class ArrayElement extends ConfigElement {
  final String name;
  final String value;
  
  ArrayElement(this.name, this.value);
  
  // Convert to JSON
  @override
  Map<String, dynamic> toJson();
  
  // Create from JSON
  factory ArrayElement.fromJson(Map<String, dynamic> json);
}
```

### Command
Represents raw commands.

```dart
class Command extends ConfigElement {
  final String command;
  
  Command(this.command);
  
  // Convert to JSON
  @override
  Map<String, dynamic> toJson();
  
  // Create from JSON
  factory Command.fromJson(Map<String, dynamic> json);
}
```

### Comment
Represents single-line comments.

```dart
class Comment extends ConfigElement {
  final String text;
  
  Comment(this.text);
  
  // Convert to JSON
  @override
  Map<String, dynamic> toJson();
  
  // Create from JSON
  factory Comment.fromJson(Map<String, dynamic> json);
}
```

### CommentBlock
Represents multi-line comment blocks.

```dart
class CommentBlock extends ConfigElement {
  final String text;
  
  CommentBlock(this.text);
  
  // Convert to JSON
  @override
  Map<String, dynamic> toJson();
  
  // Create from JSON
  factory CommentBlock.fromJson(Map<String, dynamic> json);
}
```

## Usage Examples

### Basic Parsing
```dart
import 'package:i3config/i3config_v1.dart';

final parser = I3ConfigParser(configContent);
final config = parser.parse();

for (var element in config.elements) {
  print(element);
}
```

### Finding Elements
```dart
final config = parser.parse();

// Find all sections
final sections = config.elements.whereType<Section>();

// Find properties
final properties = config.elements.whereType<Property>();

// Find array elements
final arrayElements = config.elements.whereType<ArrayElement>();

// Find specific property
final interval = config.elements
    .whereType<Property>()
    .firstWhere((p) => p.name == 'interval');
```

### Processing Nested Elements
```dart
for (var element in config.elements) {
  if (element is Section) {
    print('Section: ${element.name}');
    for (var child in element.elements) {
      if (child is Property) {
        print('  ${child.name} = ${child.value}');
      } else if (child is ArrayElement) {
        print('  ${child.name} += ${child.value}');
      }
    }
  }
}
```

### JSON Serialization
```dart
final config = parser.parse();

// Convert to JSON
final json = config.toJson();

// Restore from JSON
final restored = I3Config.fromJson(json);
```

### Type Inference
```dart
for (var element in config.elements) {
  if (element is Property) {
    final value = element.value;
    
    if (value is int) {
      print('Integer: $value');
    } else if (value is bool) {
      print('Boolean: $value');
    } else if (value is String) {
      print('String: $value');
    }
  }
}
```

## Element Type Summary

| Type | Purpose | Example |
|------|---------|---------|
| Section | Block structures | `general { }` |
| Property | Key-value pairs | `interval = 1` |
| ArrayElement | Array additions | `order += "item"` |
| Command | Raw commands | `bindsym Mod4+Return exec terminal` |
| Comment | Single-line comments | `# comment` |
| CommentBlock | Multi-line comments | `/* comment */` |

## Limitations

- No built-in variable expansion
- No scoped command handling
- No state machine processing
- Manual element processing required
- No async support

