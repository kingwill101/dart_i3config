# Simple AST Iteration with V2

V2's parser is more robust than V1, but you don't need to use the state machine if you just want to iterate over the parsed AST.

## Why Use V2 Parser Without State Machine?

- **Better Parsing**: V2 uses PetitParser for more robust parsing
- **Improved AST**: Better structured AST with clearer element types
- **Future-Proof**: Easy to add state machine features later
- **No Complexity**: Avoid handler registration and async processing

## Basic AST Iteration

```dart
import 'package:i3config/i3config.dart';

final configContent = '''
# Global variables
set \$mod Mod4
set \$terminal alacritty

# Key bindings
bindsym \$mod+Return exec \$terminal
bindsym \$mod+Shift+q kill

# Bar configuration
bar "top" {
    status_command i3status
    position top
    height 30
}

# Array operations
order = book pencil sharpener
order += eraser
''';

final config = Config.parse(configContent);

// Simple iteration over all statements
for (final statement in config.statements) {
  print('${statement.runtimeType}: $statement');
}
```

## Element Type Handling

```dart
for (final element in config.statements) {
  switch (element.runtimeType) {
    case Command:
      final command = element as Command;
      if (command.block != null) {
        print('Block command: ${command.head}');
        // Process block children
        for (final child in command.block!.body) {
          print('  Child: $child');
        }
      } else {
        print('Regular command: ${command.head}');
      }
      break;
      
    case Assignment:
      final assignment = element as Assignment;
      print('Assignment: ${assignment.variable} ${assignment.operator} ${assignment.values}');
      break;
      
    case Comment:
      final comment = element as Comment;
      print('Comment: ${comment.content}');
      break;
  }
}
```

## Finding Specific Elements

```dart
// Find all commands
final commands = config.statements.whereType<Command>();

// Find all assignments
final assignments = config.statements.whereType<Assignment>();

// Find all block commands
final blocks = config.statements
    .whereType<Command>()
    .where((c) => c.block != null);

// Find specific command types
final setCommands = config.statements
    .whereType<Command>()
    .where((c) => c.head == 'set');

final bindsymCommands = config.statements
    .whereType<Command>()
    .where((c) => c.head == 'bindsym');
```

## Processing Block Contents

```dart
for (final element in config.statements) {
  if (element is Command && element.block != null) {
    final block = element.block!;
    print('Block: ${element.head}');
    
    for (final child in block.body) {
      if (child is Command) {
        print('  Command: ${child.head}');
        // Access command arguments
        for (final arg in child.args) {
          print('    Arg: $arg');
        }
      } else if (child is Assignment) {
        print('  Assignment: ${child.variable} = ${child.values}');
      }
    }
  }
}
```

## Extracting Command Arguments

```dart
for (final element in config.statements) {
  if (element is Command) {
    final command = element;
    
    // Get command head (command name)
    print('Command: ${command.head}');
    
    // Get all arguments
    for (int i = 0; i < command.args.length; i++) {
      final arg = command.args[i];
      print('  Arg $i: $arg (${arg.runtimeType})');
      
      // Handle different argument types
      if (arg is BareArg) {
        print('    Bare value: ${arg.value}');
      } else if (arg is Quoted) {
        print('    Quoted value: ${arg.value}');
      } else if (arg is VariableRef) {
        print('    Variable reference: \$${arg.name}');
      }
    }
  }
}
```

## Working with Assignments

```dart
for (final element in config.statements) {
  if (element is Assignment) {
    final assignment = element;
    
    print('Variable: ${assignment.variable}');
    print('Operator: ${assignment.operator}');
    
    // Get assignment values
    for (final value in assignment.values) {
      if (value is BareArg) {
        print('  Value: ${value.value}');
      } else if (value is Quoted) {
        print('  Quoted: ${value.value}');
      } else if (value is VariableRef) {
        print('  Variable: \$${value.name}');
      }
    }
  }
}
```

## Building Configuration Objects

```dart
class SimpleConfig {
  final Map<String, String> variables = {};
  final List<KeyBinding> keyBindings = [];
  final List<BarConfig> bars = [];
  
  void processConfig(Config config) {
    for (final element in config.statements) {
      if (element is Command && element.head == 'set') {
        // Process set commands
        if (element.args.length >= 2) {
          final varRef = element.args[0];
          final value = element.args[1];
          
          if (varRef is VariableRef && value is BareArg) {
            variables[varRef.name] = value.value;
          }
        }
      } else if (element is Command && element.head == 'bindsym') {
        // Process key bindings
        if (element.args.length >= 2) {
          final key = element.args[0];
          final action = element.args[1];
          
          if (key is BareArg && action is BareArg) {
            keyBindings.add(KeyBinding(key.value, action.value));
          }
        }
      } else if (element is Command && element.head == 'bar' && element.block != null) {
        // Process bar blocks
        final barConfig = BarConfig();
        for (final child in element.block!.body) {
          if (child is Command) {
            barConfig.addCommand(child.head, child.args);
          }
        }
        bars.add(barConfig);
      }
    }
  }
}

class KeyBinding {
  final String key;
  final String action;
  KeyBinding(this.key, this.action);
}

class BarConfig {
  final Map<String, List<dynamic>> commands = {};
  
  void addCommand(String name, List<dynamic> args) {
    commands[name] = args;
  }
}
```

## When to Use This Approach

Use simple AST iteration when you:
- Want V2's improved parser without complexity
- Need direct control over element processing
- Are building simple configuration analysis tools
- Want to avoid async processing
- Don't need variable expansion or scoped commands

## When to Use State Machine Instead

Use the state machine when you:
- Need variable expansion and scoping
- Want handler-based architecture
- Need async processing capabilities
- Are building complex configuration tools
- Want automatic command/block processing

## Performance

Simple AST iteration is very fast:
- No handler registration overhead
- No async processing overhead
- Direct element access
- Minimal memory usage

This approach gives you V2's parsing benefits with V1's simplicity.
