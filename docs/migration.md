# Migration Guide: V1 to V2

> **Note:** V1 has been removed as of version 2.4.0. The `i3config_v1.dart` import is no longer
> available. Migrate any remaining V1 usage to V2 using this guide.

This guide helps you migrate from i3conf V1 to V2.

## Quick Migration (AST Iteration Only)

If you just want V2's improved parser without the state machine:

### Before (V1)
```dart
import 'package:i3config/i3config_v1.dart';

final parser = I3ConfigParser(configContent);
final config = parser.parse();

for (var element in config.elements) {
  print(element);
}
```

### After (V2 - Simple)
```dart
import 'package:i3config/i3config.dart';

final config = Config.parse(configContent);

for (final element in config.statements) {
  print(element);
}
```

**Changes:**
- Import `i3config.dart` instead of `i3config_v1.dart`
- Use `Config.parse()` instead of `I3ConfigParser`
- Access `config.statements` instead of `config.elements`

## Full Migration (With State Machine)

### Step 1: Update Imports and Parsing
```dart
// Before (V1 - removed in 2.4.0)
import 'package:i3config/i3config_v1.dart';
final parser = I3ConfigParser(configContent);
final config = parser.parse();

// After
import 'package:i3config/i3config.dart';
final config = Config.parse(configContent);
```

### Step 2: Replace Manual Processing with Handlers

#### Before (V1 - Manual Processing)
```dart
for (var element in config.elements) {
  if (element is Section) {
    if (element.name == 'bar') {
      for (var child in element.elements) {
        if (child is Property) {
          if (child.name == 'status_command') {
            print('Status: ${child.value}');
          }
        }
      }
    }
  }
}
```

#### After (V2 - Handler-Based)
```dart
class BarHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', StatusHandler());
  }
}

class StatusHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'status_command';
  
  @override
  String? handle(Command command, Context context) {
    final status = command.getArgAsString(0, context);
    print('Status: $status');
    return status;
  }
}

final processor = ConfigProcessor();
processor.registerBlockHandler(BarHandler());
await processor.process(config);
```

### Step 3: Handle Variables

#### Before (V1 - Manual Variable Handling)
```dart
// V1 doesn't have built-in variable support
final properties = config.elements.whereType<Property>();
for (final prop in properties) {
  if (prop.name.startsWith('\$')) {
    // Manual variable expansion
  }
}
```

#### After (V2 - Built-in Variables)
```dart
final config = Config.parse('''
set \$mod Mod4
set \$terminal alacritty
''');

final processor = ConfigProcessor();
await processor.process(config);

// Variables are automatically available in context
final mod = processor.context.getVariable('mod');
final terminal = processor.context.getVariable('terminal');
```

### Step 4: Update Element Type Checks

#### Before (V1 - 6 Element Types)
```dart
for (var element in config.elements) {
  if (element is Section) {
    // Handle section blocks
  } else if (element is Property) {
    // Handle key-value properties
  } else if (element is ArrayElement) {
    // Handle array additions
  } else if (element is Command) {
    // Handle raw commands
  } else if (element is Comment) {
    // Handle comments
  } else if (element is CommentBlock) {
    // Handle comment blocks
  }
}
```

#### After (V2 - 5 Element Types)
```dart
for (final element in config.statements) {
  if (element is Block) {
    // Handle block (replaces Section)
    print('Block: ${element.blockType}');
  } else if (element is Command) {
    // Handle regular command
    print('Command: ${element.head}');
  } else if (element is Assignment) {
    // Handle assignment (replaces Property + ArrayElement)
    print('Assignment: ${element.variable}');
  } else if (element is Comment) {
    // Handle comment (replaces Comment + CommentBlock)
    print('Comment: ${element.content}');
  }
}
```

## Common Migration Patterns

### Pattern 1: Simple Element Iteration
```dart
// V1
for (var element in config.elements) {
  print(element);
}

// V2
for (final element in config.statements) {
  print(element);
}
```

### Pattern 2: Finding Specific Elements
```dart
// V1
final sections = config.elements.whereType<Section>();
final properties = config.elements.whereType<Property>();

// V2
final commands = config.statements.whereType<Command>();
final assignments = config.statements.whereType<Assignment>();
final blocks = commands.where((c) => c.block != null);

for (final blockCommand in blocks) {
  final block = blockCommand.block!;
  print('${block.blockType} block with ${block.body.length} statements');
}
```

### Pattern 3: Processing Nested Elements
```dart
// V1
for (var element in config.elements) {
  if (element is Section) {
    for (var child in element.elements) {
      // Process child
    }
  }
}

// V2
for (final element in config.statements) {
  if (element is Command && element.block != null) {
    for (final child in element.block!.body) {
      if (child is Assignment) {
        print('  Assignment: ${child.variable}');
      }
    }
  }
}
```

## Migration Checklist

- [ ] Update imports to `i3config.dart` (was `i3config_v1.dart`)
- [ ] Replace `I3ConfigParser` with `Config.parse()`
- [ ] Update element iteration (`config.statements` instead of `config.elements`)
- [ ] Update element type checks (Command, Assignment, Block, Comment)
- [ ] Replace legacy `Command('assign', ...)` detection with `Assignment` handling
- [ ] Review command handlers for block-aware commands (`command.block != null`)
- [ ] Replace manual processing with handlers (if using state machine)
- [ ] Update variable handling to use context system
- [ ] Test all functionality after migration

## Benefits of Migration

- **Better Parser**: More robust parsing with PetitParser
- **Variable Support**: Built-in variable expansion and scoping
- **Handler System**: Extensible command and block processing
- **Async Support**: Asynchronous processing capabilities
- **Type Safety**: Better type safety with base handler classes
- **Context Management**: Hierarchical variable and option scoping

## Troubleshooting

### Common Issues

1. **Import Errors**: Make sure you're importing `i3config.dart` (V1 import `i3config_v1.dart` was removed in 2.4.0)
2. **Element Access**: Use `config.statements` instead of `config.elements`
3. **Type Changes**: Command/Assignment instead of Section/Property
4. **Async Processing**: Remember to `await processor.process(config)`

### Getting Help

- Review the [V2 API Reference](api-reference.md)
- See the [V1 vs V2 Comparison](../comparison.md)
- Check the [Simple AST Iteration Guide](simple-ast-iteration.md)
