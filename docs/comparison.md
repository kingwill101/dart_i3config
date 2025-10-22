# V1 vs V2 Comparison

This document provides side-by-side comparisons of common operations in V1 and V2.

## Basic Parsing

### V1 - Simple Parser
```dart
import 'package:i3config/i3config_v1.dart';

final parser = I3ConfigParser(configContent);
final config = parser.parse();

for (var element in config.elements) {
  print(element);
}
```

### V2 - State Machine
```dart
import 'package:i3config/i3config_v2.dart';

final config = Config.parse(configContent);
final processor = ConfigProcessor();
await processor.process(config);
```

### V2 - Simple AST Iteration
```dart
import 'package:i3config/i3config_v2.dart';

final config = Config.parse(configContent);
for (final element in config.statements) {
  print(element);
}
```

## Finding Elements

### V1 - Direct Element Access
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

### V2 - Simplified AST Navigation
```dart
final config = Config.parse(configContent);

// Find all commands
final commands = config.statements.whereType<Command>();

// Find assignments (replaces Property + ArrayElement)
final assignments = config.statements.whereType<Assignment>();

// Find blocks (replaces Section)
final blocks = config.statements.whereType<Block>();
```

## Variable Handling

### V1 - No Built-in Variable Support
```dart
// V1 doesn't handle variables - you need to implement this yourself
final properties = config.elements.whereType<Property>();
for (final prop in properties) {
  if (prop.name.startsWith('\$')) {
    // Manual variable handling
    print('Variable: ${prop.name} = ${prop.value}');
  }
}
```

### V2 - Built-in Variable System
```dart
final config = Config.parse('''
set \$mod Mod4
set \$terminal alacritty
''');

final processor = ConfigProcessor();
await processor.process(config);

// Access variables from context
final mod = processor.context.getVariable('mod');
final terminal = processor.context.getVariable('terminal');
```

## Block Processing

### V1 - Manual Block Handling
```dart
final config = parser.parse();

for (var element in config.elements) {
  if (element is Section) {
    print('Section: ${element.name}');
    for (var child in element.elements) {
      if (child is Property) {
        print('  ${child.name} = ${child.value}');
      }
    }
  }
}
```

### V2 - Handler-Based Block Processing
```dart
class BarHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';
  
  @override
  void handle(Block block, Context context) {
    print('Processing bar block');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', StatusHandler());
  }
}

final processor = ConfigProcessor();
processor.registerBlockHandler(BarHandler());
await processor.process(config);
```

## Command Processing

### V1 - Manual Command Handling
```dart
final config = parser.parse();

for (var element in config.elements) {
  if (element is Command) {
    print('Command: ${element.command}');
    // Manual command processing
  }
}
```

### V2 - Handler-Based Command Processing
```dart
class BindsymHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'bindsym';
  
  @override
  void handle(Command command, Context context) {
    final key = command.getArgAsString(0, context);
    final action = command.getArgAsString(1, context);
    print('Binding: $key -> $action');
  }
}

final processor = ConfigProcessor();
processor.registerCommandHandler(BindsymHandler());
await processor.process(config);
```

## JSON Serialization

### V1 - Built-in JSON Support
```dart
final config = parser.parse();
final json = config.toJson();
final restored = Config.fromJson(json);
```

### V2 - Manual JSON Handling
```dart
// V2 doesn't have built-in JSON serialization
// You need to implement this based on your needs
final config = Config.parse(configContent);
// Custom JSON serialization logic...
```

## AST Type Comparison

| V1 (6 Types) | V2 (5 Types) | Notes |
|--------------|--------------|-------|
| Section | Block | Blocks are now first-class Block elements |
| Property | Assignment | Properties become assignments with `=` operator |
| ArrayElement | Assignment | Array additions become assignments with `+=` operator |
| Command | Command | Raw commands remain the same |
| Comment | Comment | Single-line comments remain the same |
| CommentBlock | Comment | Multi-line comments merged into Comment |

**V2 AST Simplification Benefits:**
- Fewer types to handle (5 vs 6)
- Cleaner pattern matching
- Better type safety with sealed classes
- More intuitive API design
- Blocks are first-class elements, not attached to commands

## Performance Comparison

| Operation | V1 | V2 |
|-----------|----|----|
| Parsing | Fast | Fast |
| Simple Iteration | Very Fast | Very Fast |
| Variable Expansion | Manual | Built-in |
| Block Processing | Manual | Handler-based |
| Memory Usage | Low | Medium |
| Complexity | Low | High |

## When to Use Each Version

### Use V1 When:
- Simple configuration parsing
- Direct AST manipulation
- Minimal processing needs
- Legacy compatibility
- Learning i3 config format

### Use V2 When:
- Building configuration tools
- Need advanced processing
- Want handler architecture
- Require scoped commands
- Building on top of i3 config
- Need async processing

## Migration Path

1. **Simple Migration**: Use V2 parser with AST iteration (no state machine)
2. **Full Migration**: Implement handlers and use state machine
3. **Gradual Migration**: Start with V2 parser, add handlers incrementally
