# Command Handlers

Command handlers process specific commands and can return values for use by other handlers.

## Overview

Command handlers are responsible for:
- Processing specific command types
- Extracting and validating command arguments
- Setting context variables or performing actions
- Returning values for use by other handlers

## Basic Command Handler

```dart
class BindsymHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'bindsym';
  
  @override
  void handle(Command command, Context context) {
    final key = command.getArgAsString(0, context);
    final action = command.args.length > 1
        ? command.args.skip(1).map((v) => context.expandValue(v)).join(' ')
        : '';
    
    print('⌨️  Binding: $key -> $action');
    
    // Store binding in context
    final bindings = context.getVariable('bindings') as List<String>? ?? [];
    bindings.add('$key:$action');
    context.setVariable('bindings', bindings);
  }
}
```

## Configuration Mapping

Here's how i3 config commands map to handlers:

### Global Commands
```i3
# Global commands - processed by global handlers
set $mod Mod4
set $terminal alacritty
bindsym $mod+Return exec $terminal
bindsym $mod+Shift+q kill
assign [class="Firefox"] 2
for_window [class=".*"] border pixel 1
include ~/.config/i3/config.d/*
```

**Handler Processing:**
1. `SetCommandHandler` (built-in) processes `set` commands
2. `BindsymHandler` processes `bindsym` commands
3. `AssignHandler` processes `assign` commands
4. `ForWindowHandler` processes `for_window` commands
5. `IncludeHandler` processes `include` commands

### Scoped Commands (Inside Blocks)
```i3
bar "top" {
    # These commands only work inside bar blocks
    status_command i3status
    position top
    height 30
    colors {
        background #000000
        statusline #ffffff
    }
}
```

**Handler Processing:**
1. `BarBlockHandler` registers scoped commands
2. `StatusCommandHandler` processes `status_command`
3. `PositionHandler` processes `position`
4. `HeightHandler` processes `height`
5. `ColorsHandler` processes `colors` (nested block)

## Advanced Command Handler Features

### Returning Values

```dart
class WidthHandler extends BaseCommandHandler<int> {
  @override
  String get commandName => 'width';
  
  @override
  int? handle(Command command, Context context) {
    final width = command.getArgAsInt(0, context);
    
    // Set in context for other handlers to use
    context.setVariable('width', width);
    
    // Return value for immediate use
    return width;
  }
}

class HeightHandler extends BaseCommandHandler<int> {
  @override
  String get commandName => 'height';
  
  @override
  int? handle(Command command, Context context) {
    final height = command.getArgAsInt(0, context);
    context.setVariable('height', height);
    return height;
  }
}

// Using return values in block handler
class RectangleHandler extends BaseBlockHandler {
  @override
  String get blockType => 'rectangle';
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    final width = context.getVariable('width') as int?;
    final height = context.getVariable('height') as int?;
    
    if (width != null && height != null) {
      final area = width * height;
      print('Rectangle area: $area');
    }
  }
}
```

### Type-Safe Argument Extraction

```dart
class ColorHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'color';
  
  @override
  String? handle(Command command, Context context) {
    // Type-safe argument extraction
    final color = command.getArgAsString(0, context);
    final opacity = command.getArgAsDouble(1, context); // Optional
    final enabled = command.getArgAsBool(2, context);   // Optional
    
    print('🎨 Color: $color, Opacity: $opacity, Enabled: $enabled');
    
    // Validate color format
    if (!_isValidColor(color)) {
      throw ArgumentError('Invalid color format: $color');
    }
    
    context.setVariable('color', color);
    return color;
  }
  
  bool _isValidColor(String color) {
    return color.startsWith('#') && color.length == 7;
  }
}
```

### Variable Expansion

```dart
class ExecHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'exec';
  
  @override
  String? handle(Command command, Context context) {
    // Get all arguments as expanded strings
    final args = command.getAllArgsAsStrings(context);
    final command = args.join(' ');
    
    print('🚀 Executing: $command');
    
    // Variables are automatically expanded
    // exec $terminal -e vim -> exec alacritty -e vim
    
    return command;
  }
}
```

## Real-World Examples

### i3 Key Binding Handler

```dart
class I3BindsymHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'bindsym';
  
  @override
  void handle(Command command, Context context) {
    final key = command.getArgAsString(0, context);
    final action = command.args.length > 1
        ? command.args.skip(1).map((v) => context.expandValue(v)).join(' ')
        : '';
    
    print('⌨️  Key binding: $expandedKey -> $expandedAction');
    
    // Store in context for later use
    final bindings = context.getVariable('key_bindings') as Map<String, String>? ?? {};
    bindings[expandedKey] = expandedAction;
    context.setVariable('key_bindings', bindings);
  }
}
```

### Window Assignment Handler

```dart
class AssignHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'assign';
  
  @override
  void handle(Command command, Context context) {
    final criteriaStr = command.criteria
        ?.map((c) => '${c.key}=${context.expandValue(c.value)}')
        .join(', ');
    final workspace = command.getArgAsString(0, context);
    
    print('🪟 Window assignment: $criteriaStr -> workspace $workspace');
    
    // Store assignment
    final assignments = context.getVariable('window_assignments') as List<Map<String, dynamic>>? ?? [];
    assignments.add({
      'criteria': criteriaStr,
      'workspace': workspace,
    });
    context.setVariable('window_assignments', assignments);
  }
}
```

### Status Command Handler (Scoped)

```dart
class StatusCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'status_command';
  
  @override
  String? handle(Command command, Context context) {
    final statusCommand = command.getArgAsString(0, context);
    
    print('📊 Status command: $statusCommand');
    
    // Validate status command
    if (!_isValidStatusCommand(statusCommand)) {
      throw ArgumentError('Invalid status command: $statusCommand');
    }
    
    // Set in context for bar configuration
    context.setVariable('status_command', statusCommand);
    
    return statusCommand;
  }
  
  bool _isValidStatusCommand(String command) {
    // Check if command exists and is executable
    return command.isNotEmpty && !command.contains('..');
  }
}
```

### Font Handler (Scoped)

```dart
class FontHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'font';
  
  @override
  String? handle(Command command, Context context) {
    final fontSpec = command.getArgAsString(0, context);
    
    print('🔤 Font: $fontSpec');
    
    // Parse font specification
    final font = _parseFontSpec(fontSpec);
    
    // Set font properties in context
    context.setVariable('font_family', font['family']);
    context.setVariable('font_size', font['size']);
    context.setVariable('font_weight', font['weight']);
    
    return fontSpec;
  }
  
  Map<String, String> _parseFontSpec(String spec) {
    // Parse font spec like "pango:DejaVu Sans Mono 10"
    final parts = spec.split(' ');
    return {
      'family': parts.length > 1 ? parts[1] : 'monospace',
      'size': parts.length > 2 ? parts[2] : '10',
      'weight': 'normal',
    };
  }
}
```

## Context and Scoping

### Global Commands
```dart
// These commands set global variables
set $mod Mod4
set $terminal alacritty

// These commands use global context
bindsym $mod+Return exec $terminal
```

### Scoped Commands
```dart
bar "top" {
    # These commands only work inside bar blocks
    # They have access to both global and block context
    status_command i3status
    position top
    height 30
}
```

### Context Inheritance
```dart
class ScopedCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'scoped_cmd';
  
  @override
  String? handle(Command command, Context context) {
    // Access global variables
    final globalMod = context.getVariable('mod');
    
    // Set local variable (scoped to this block)
    final localValue = command.getArgAsString(0, context);
    context.setVariable('local_value', localValue);
    
    print('Global mod: $globalMod, Local value: $localValue');
    
    return localValue;
  }
}
```

## Best Practices

### 1. Validate Arguments
```dart
@override
String? handle(Command command, Context context) {
  if (command.args.length < 2) {
    throw ArgumentError('Command requires at least 2 arguments');
  }
  
  final value = command.getArgAsString(0, context);
  if (value.isEmpty) {
    throw ArgumentError('Value cannot be empty');
  }
  
  // Process command...
}
```

### 2. Use Type-Safe Extraction
```dart
// Good - type-safe with error handling
final width = command.getArgAsInt(0, context);

// Avoid - manual type checking
final arg = command.args[0];
if (arg is BareArg) {
  final width = int.tryParse(arg.value);
  // ...
}
```

### 3. Handle Variable Expansion
```dart
@override
String? handle(Command command, Context context) {
  // Variables are automatically expanded
  final expandedValue = command.getArgAsString(0, context);
  
  // Or expand manually if needed
  final rawValue = command.args[0];
  final expanded = context.expandVariables(rawValue.toString());
  
  return expandedValue;
}
```

### 4. Return Meaningful Values
```dart
@override
int? handle(Command command, Context context) {
  final value = command.getArgAsInt(0, context);
  
  // Set in context for other handlers
  context.setVariable('my_property', value);
  
  // Return for immediate use
  return value;
}
```

## Registration

### Global Command Handlers
```dart
final processor = ConfigProcessor();

// Register global command handlers
processor.registerCommandHandler(BindsymHandler());
processor.registerCommandHandler(AssignHandler());
processor.registerCommandHandler(ForWindowHandler());

await processor.process(config);
```

> **Note:** `IncludeHandler` is registered automatically by `ConfigProcessor`.
> You do not need to register it manually.

### Filesystem Injection for Includes

The built-in `IncludeHandler` reads files through a `FileSystem` abstraction (see [context-and-scoping.md](context-and-scoping.md) for details). This allows testing includes without real files:

```dart
final vfs = VirtualFileSystem();
vfs.createFile('modules/bar.conf', '''
status_command i3status
position top
''');

final processor = ConfigProcessor(fileSystem: vfs);
await processor.process(Config.parse('''
set $mod Mod4
include "modules/bar.conf"
'''));
```

In production, the default `PhysicalFileSystem` handles real I/O automatically.
Override by passing a custom `FileSystem` to the `ConfigProcessor` constructor.

### Scoped Command Handlers
```dart
class MyBlockHandler extends BaseBlockHandler {
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // Register commands that only work inside this block
    registry.registerCommand('status_command', StatusCommandHandler());
    registry.registerCommand('position', PositionHandler());
    registry.registerCommand('height', HeightHandler());
  }
}
```

## Testing Command Handlers

```dart
void main() async {
  final config = Config.parse('''
set $mod Mod4
bindsym $mod+Return exec alacritry
''');
  
  final processor = ConfigProcessor();
  processor.registerCommandHandler(BindsymHandler());
  
  await processor.process(config);
  
  // Verify command was processed
  final bindings = processor.context.getVariable('key_bindings') as Map<String, String>?;
  expect(bindings?['Mod4+Return'], equals('exec alacritry'));
}
```

### Testing Include Handlers with VirtualFileSystem

The `FileSystem` abstraction lets you
test `include` directives without touching the real filesystem:

```dart
import 'package:i3config/i3config.dart';

void main() {
  final vfs = VirtualFileSystem();
  
  setUp(() {
    vfs.createFile('modules/global.conf', '''
set \$mod Mod4
set \$terminal alacritty
''');
    vfs.createFile('modules/nested.conf', '''
include "modules/global.conf"
set \$nested_var nested_value
''');
  });

  tearDown(() => vfs.clear());

  test('include merges variables', () async {
    final processor = ConfigProcessor(fileSystem: vfs);
    await processor.processString('include "modules/global.conf"');
    expect(processor.context.getVariable('mod'), 'Mod4');
  });

  test('nested includes work', () async {
    final processor = ConfigProcessor(fileSystem: vfs);
    await processor.processString('include "modules/nested.conf"');
    expect(processor.context.getVariable('nested_var'), 'nested_value');
  });
}
```

Key points:
- Use `ConfigProcessor(fileSystem: vfs)` to inject the virtual filesystem
- `createFile(path, content)` adds virtual files before processing
- `vfs.clear()` resets the filesystem between tests
- Circular includes, missing files, and nested includes all work with VFS

