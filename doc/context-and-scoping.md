# Context and Scoping

Understanding how variables and options are managed across different scopes in i3conf.

## Overview

The context system provides hierarchical variable and option management:
- **Global Context**: Top-level variables and options
- **Block Context**: Scoped variables within blocks
- **Variable Expansion**: Dynamic resolution with inheritance
- **Context Inheritance**: Child contexts inherit from parent contexts
- **Variable Middleware**: Extensible hooks for intercepting variable operations
- **Typed Accessors**: Type-safe variable retrieval methods

## Context Hierarchy

```
Global Context
├── Block Context (bar "top")
│   ├── Block Context (colors)
│   └── Block Context (tray_output)
├── Block Context (mode "resize")
└── Block Context (output "eDP-1")
```

## Global Context

Global context contains variables and options that are available everywhere.

### Setting Global Variables

```i3
# Global variables - available everywhere
set $mod Mod4
set $terminal alacritty
set $browser firefox
set $editor vim
```

**Handler Processing:**
```dart
class SetCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'set';
  
  @override
  String? handle(Command command, Context context) {
    final varRef = command.args[0] as VariableRef;
    final value = command.getArgAsString(1, context);
    
    // Set in global context
    context.setVariable(varRef.name, value);
    
    return value;
  }
}
```

### Using Global Variables

```i3
# Global variables can be used anywhere
bindsym $mod+Return exec $terminal
bindsym $mod+Shift+b exec $browser
bindsym $mod+Shift+e exec $terminal -e $editor
```

**Variable Expansion:**
```dart
class BindsymHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'bindsym';
  
  @override
  void handle(Command command, Context context) {
    final key = command.getArgAsString(0, context);      // $mod+Return -> Mod4+Return
    final action = command.args.length > 1
        ? command.args.skip(1).map((v) => context.expandValue(v)).join(' ')
        : '';                                              // exec $terminal -> exec alacritty
    
    print('Binding: $key -> $action');
  }
}
```

## Block Context

Block contexts are created for each block and inherit from their parent context.

### Block Context Creation

```i3
# Global context
set $mod Mod4
set $terminal alacritty

# Block context inherits global variables
bar "top" {
    # $mod and $terminal are available here
    status_command i3status
    position top
    
    # Block can set local variables
    set $bar_height 30
    height $bar_height
}
```

**Context Management:**
```dart
class BarBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';
  
  @override
  void handle(Block block, Context context) {
    // This runs in the block's context
    // Global variables are inherited
    final globalMod = context.getVariable('mod');        // "Mod4"
    final globalTerminal = context.getVariable('terminal'); // "alacritty"
    
    print('Global mod: $globalMod');
    print('Global terminal: $globalTerminal');
  }
}
```

### Variable Shadowing

```i3
# Global context
set $mod Mod4
set $color #ffffff

# Block context can shadow global variables
bar "top" {
    # This shadows the global $mod
    set $mod Mod1
    set $color #000000
    
    # Uses local values
    bindsym $mod+Return exec terminal  # Uses Mod1, not Mod4
    background $color                  # Uses #000000, not #ffffff
}
```

**Shadowing Example:**
```dart
class BarBlockHandler extends BaseBlockHandler {
  @override
  void handle(Block block, Context context) {
    // Access shadowed variable
    final localMod = context.getVariable('mod');  // "Mod1" (local)
    
    // Access global variable (if not shadowed)
    final globalColor = context.getVariable('color'); // "#000000" (local shadows global)
  }
}
```

## Context Inheritance

Child contexts inherit variables from parent contexts but can override them.

### Nested Block Contexts

```i3
# Global context
set $base_color #ffffff
set $accent_color #007acc

# Block context
bar "top" {
    # Inherits global variables
    set $bar_color $base_color
    
    # Nested block context
    colors {
        # Inherits from both global and bar context
        background $bar_color
        statusline $accent_color
        
        # Can set its own variables
        set $text_color #000000
        focused_workspace $text_color $accent_color
    }
}
```

**Context Inheritance:**
```dart
class ColorsBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'colors';
  
  @override
  void handle(Block block, Context context) {
    // Access inherited variables
    final baseColor = context.getVariable('base_color');    // From global
    final barColor = context.getVariable('bar_color');      // From bar block
    final accentColor = context.getVariable('accent_color'); // From global
    
    print('Base: $baseColor, Bar: $barColor, Accent: $accentColor');
  }
}
```

## Variable Expansion

Variables are automatically expanded when accessed through the context system.

### Simple Variable Expansion

```i3
set $mod Mod4
set $terminal alacritty
set $editor vim

# Variables are expanded automatically
bindsym $mod+Return exec $terminal
bindsym $mod+Shift+e exec $terminal -e $editor
```

**Expansion Process:**
```dart
class BindsymHandler extends BaseCommandHandler<void> {
  @override
  void handle(Command command, Context context) {
    // getArgAsString automatically expands variables
    final key = command.getArgAsString(0, context);      // $mod+Return -> Mod4+Return
    final action = command.args.length > 1
        ? command.args.skip(1).map((v) => context.expandValue(v)).join(' ')
        : '';                                              // exec $terminal -> exec alacritty
    
    // Manual expansion if needed
    if (command.args.length > 1) {
      final expandedAction = context.expandVariables(
        command.args.skip(1).map((v) => v.toString()).join(' '),
      );
    }
  }
}
```

### Complex Variable Expansion

```i3
set $base_dir /home/user
set $config_dir $base_dir/.config
set $i3_config $config_dir/i3/config

# Nested variable expansion
include $i3_config
```

**Nested Expansion:**
```dart
class IncludeHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'include';

  @override
  Future<void> handle(Command command, Context context) async {
    final path = command.getArgAsString(0, context);

    // $i3_config -> $config_dir/i3/config -> $base_dir/.config/i3/config -> /home/user/.config/i3/config
    print('Including: $path');
  }
}
```

> **Note:** The real `IncludeHandler` uses a pluggable `FileSystem` interface.
> See the `FileSystem` class in the source code for details.

### Array Variable Expansion

```i3
set $apps "firefox alacritty vim"
set $launcher "rofi -show run"

# Array expansion
exec $launcher
```

**Array Expansion:**
```dart
class ExecHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'exec';
  
  @override
  void handle(Command command, Context context) {
    final command = command.getArgAsString(0, context);
    
    // Arrays are expanded as space-separated strings
    // $apps -> "firefox alacritty vim"
    print('Executing: $command');
  }
}
```

## Variable Middleware

Middleware intercepts variable operations at three points: `onSet` (before storing), `onGet` (after retrieval), and `onExpand` (before variable substitution in strings). Multiple middleware chain in registration order.

### Redaction Middleware

```dart
class SensitiveMiddleware implements VariableMiddleware {
  final Set<String> _keys;

  SensitiveMiddleware(this._keys);

  @override
  dynamic onSet(String name, dynamic value, Context context) => value;

  @override
  dynamic onGet(String name, dynamic? value, Context context) => value;

  @override
  String? onExpand(String text, Context context) {
    for (final key in _keys) {
      text = text.replaceAll('\$$key', '<SENSITIVE>');
    }
    return text;
  }
}

final context = Context();
context.registerVariableMiddleware(SensitiveMiddleware({'password'}));
context.setVariable('password', 's3cret123');

print(context.expandVariables('login with $password')); // login with <SENSITIVE>
print(context.getVariable('password')); // s3cret123 (raw value preserved)
```

### Transform Middleware

```dart
class PrefixMiddleware implements VariableMiddleware {
  @override
  dynamic onSet(String name, dynamic value, Context context) => value;

  @override
  dynamic onGet(String name, dynamic? value, Context context) {
    if (value is String) return 'PREFIX:$value';
    return value;
  }

  @override
  String? onExpand(String text, Context context) => null;
}
```

### Reject Middleware

```dart
class RejectingMiddleware implements VariableMiddleware {
  @override
  dynamic onSet(String name, dynamic value, Context context) => null; // Reject all sets

  @override
  dynamic onGet(String name, dynamic? value, Context context) => value;

  @override
  String? onExpand(String text, Context context) => null;
}
```

### Skip Expansion Middleware

Returning `null` from `onExpand` skips variable expansion entirely for the given text:

```dart
class SkipExpandMiddleware implements VariableMiddleware {
  @override
  dynamic onSet(String name, dynamic value, Context context) => value;

  @override
  dynamic onGet(String name, dynamic? value, Context context) => value;

  @override
  String? onExpand(String text, Context context) => null; // Skip expansion
}
```

### Chaining Middleware

Multiple middleware run in registration order. Each middleware receives the output of the previous one:

```dart
context.registerVariableMiddleware(UppercaseMiddleware());  // "val" -> "VAL"
context.registerVariableMiddleware(PrefixMiddleware());     // "VAL" -> "PREFIX:VAL"
context.setVariable('key', 'val');
print(context.getVariable('key')); // "PREFIX:VAL"
```

### Middleware and Context Inheritance

Child context middleware also applies to inherited parent values:

```dart
final parent = Context();
parent.setVariable('shared', 'value');

final child = parent.pushContext();
child.registerVariableMiddleware(SuffixMiddleware());

print(child.getVariable('shared')); // "value_suffix" (child middleware applied)
```

## Typed Variable Accessors

Context provides type-safe accessors that avoid manual casting:

```dart
context.setVariable('count', '42');
context.setVariable('name', 'alice');
context.setVariable('items', ['a', 'b', 'c']);
context.setVariable('enabled', 'true');

final count = context.getVariableAs<int>('count');     // 42
final name  = context.getString('name');               // "alice"
final items = context.getList('items');                // ["a", "b", "c"]
final enabled = context.getBool('enabled');            // true
```

These accessors:
- `getVariableAs<T>(name)` — casts the value to `T`, returns `null` on mismatch
- `getString(name)` — returns the variable as `String?`
- `getList(name)` — returns the variable as `List<String>?`
- `getBool(name)` — parses `"true"`/`"false"` strings to `bool?`

## Public expandValue()

The `expandValue(Value)` method on `Context` resolves any `Value` AST node through variable expansion:

```dart
final raw = Quoted('hello $name');
final expanded = context.expandValue(raw);
print(expanded); // "hello alice"
```

This replaces the previously private `_expandValue` implementations duplicated across processor states, base handlers, and mixins — now a single public method on Context.

## Processor-Level Variable Middleware

Middleware can be registered at the `ConfigProcessor` level to automatically apply to all contexts created during processing:

```dart
final processor = ConfigProcessor();

// All variable operations in every context will uppercase values
processor.registerVariableMiddleware(UppercaseMiddleware());

await processor.processString('''
set \$name alice
block "scope" {
    set \$role admin
}
''');

print(processor.context.getVariable('name')); // ALICE
print(processor.context.getVariable('role')); // ADMIN
```

Processor-level middleware is propagated to the root context and every child block context pushed during processing. It runs before context-level middleware in the registration chain, so context-level middleware can further transform values after processor middleware has run.

### Middleware Registration Order

When both processor-level and context-level middleware are registered:

```dart
final processor = ConfigProcessor();
processor.registerVariableMiddleware(UppercaseMiddleware());  // processor level

await processor.processString('set \$x hello');

processor.context.registerVariableMiddleware(PrefixMiddleware()); // context level

processor.context.setVariable('y', 'val');
// y passes through UppercaseMiddleware first ("val" -> "VAL"),
// then PrefixMiddleware ("VAL" -> "PREFIX:VAL")
print(processor.context.getVariable('y')); // "PREFIX:VAL"
```

## Block Identifier Access

During block processing, `context.currentBlockIdentifier` exposes the block's command-level identifier:

```dart
class HostBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'host';

  @override
  void handle(Block block, Context context) {
    final hostname = context.currentBlockIdentifier;
    print('Processing host: $hostname');
  }
}
```

Processed against: `host "web-01" { ... }` → `hostname = "web-01"`.

This is set by the processor before calling any handler lifecycle methods (`handle`, `processChildren`, `afterChildrenProcessed`).

## AST Hierarchy Navigation

Access parent references and build block hierarchies:

```dart
final config = Config.parse('''
host "web-01" {
    set $addr "10.0.0.1"
}
''');

// Navigate child -> parent
final block = config.statements.first as Block;
final child = block.body.first;
print(child.parent == block); // true

// Build full hierarchy map
final hierarchy = config.buildBlockHierarchy();
// hierarchy maps each block to parent -> children
```

## Context Management in Handlers

### Accessing Context Variables

```dart
class MyCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'my_command';
  
  @override
  String? handle(Command command, Context context) {
    // Access global variables
    final globalVar = context.getVariable('global_var');
    
    // Access block-local variables
    final localVar = context.getVariable('local_var');
    
    // Check if variable exists
    if (context.hasVariable('optional_var')) {
      final optionalVar = context.getVariable('optional_var');
      print('Optional: $optionalVar');
    }
    
    return localVar;
  }
}
```

### Setting Context Variables

```dart
class MyCommandHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'set_property';
  
  @override
  void handle(Command command, Context context) {
    final property = command.getArgAsString(0, context);
    final value = command.getArgAsString(1, context);
    
    // Set in current context (global or block)
    context.setVariable(property, value);
    
    // Set array variable
    final items = ['item1', 'item2', 'item3'];
    context.setVariable('items', items);
    
    // Set complex object
    final config = {
      'property': property,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    };
    context.setVariable('config', config);
  }
}
```

### Context in Block Handlers

```dart
class MyBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'my_block';
  
  @override
  void handle(Block block, Context context) {
    // Access inherited variables
    final inherited = context.getVariable('inherited_var');
    
    // Set block-local variables
    context.setVariable('block_id', getBlockIdentifier(block, context));
    context.setVariable('block_type', block.blockType);
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    // Access variables set by child commands
    final childVar1 = context.getVariable('child_var1');
    final childVar2 = context.getVariable('child_var2');
    
    // Process collected information
    final summary = {
      'block_id': context.getVariable('block_id'),
      'child_var1': childVar1,
      'child_var2': childVar2,
    };
    
    print('Block summary: $summary');
  }
}
```

## Real-World Examples

### i3 Bar Configuration

```i3
# Global context
set $mod Mod4
set $font "pango:DejaVu Sans Mono 10"
set $bg_color #000000
set $fg_color #ffffff

# Bar block context
bar "top" {
    # Inherits global variables
    font $font
    position top
    height 30
    
    # Bar-specific variables
    set $bar_bg $bg_color
    set $bar_fg $fg_color
    
    # Colors sub-block context
    colors {
        # Inherits from global and bar context
        background $bar_bg
        statusline $bar_fg
        
        # Colors-specific variables
        set $active_ws #007acc
        set $inactive_ws #333333
        
        focused_workspace $bar_fg $active_ws
        inactive_workspace $bar_fg $inactive_ws
    }
}
```

### Mode Configuration

```i3
# Global context
set $mod Mod4
set $resize_step 10

# Mode block context
mode "resize" {
    # Inherits global variables
    bindsym h resize shrink width $resize_step px or $resize_step ppt
    bindsym j resize grow height $resize_step px or $resize_step ppt
    bindsym k resize shrink height $resize_step px or $resize_step ppt
    bindsym l resize grow width $resize_step px or $resize_step ppt
    
    # Mode-specific variables
    set $mode_bg #ff0000
    set $mode_fg #ffffff
    
    # Return to default mode
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
```

## Best Practices

### 1. Use Descriptive Variable Names
```i3
# Good
set $modifier_key Mod4
set $terminal_app alacritty
set $browser_app firefox

# Avoid
set $m Mod4
set $t alacritty
set $b firefox
```

### 2. Group Related Variables
```i3
# Group related variables together
set $mod Mod4
set $terminal alacritty
set $browser firefox
set $editor vim

# Use consistent naming
set $app_terminal alacritty
set $app_browser firefox
set $app_editor vim
```

### 3. Use Context Appropriately
```dart
// Set variables in the appropriate context
class GlobalCommandHandler extends BaseCommandHandler<void> {
  @override
  void handle(Command command, Context context) {
    // Set in global context
    context.setVariable('global_var', 'value');
  }
}

class BlockCommandHandler extends BaseCommandHandler<void> {
  @override
  void handle(Command command, Context context) {
    // Set in block context (will shadow global if same name)
    context.setVariable('block_var', 'value');
  }
}
```

### 4. Handle Variable Resolution
```dart
class MyHandler extends BaseCommandHandler<String> {
  @override
  String? handle(Command command, Context context) {
    final value = command.getArgAsString(0, context);
    
    // Variables are automatically expanded
    // But you can also expand manually if needed
    final expanded = context.expandVariables(value);
    
    return expanded;
  }
}
```

## Context Debugging

### Inspecting Context State

```dart
void debugContext(Context context, String label) {
  print('=== $label Context ===');
  print('Variables: ${context.variables}');
  print('Options: ${context.options}');
  print('Parent: ${context.parent != null ? 'Yes' : 'No'}');
  print('==================');
}

class DebugHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'debug';
  
  @override
  void handle(Command command, Context context) {
    debugContext(context, 'Command');
  }
}
```

### Context Tracing

```dart
class TracingBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'tracing';
  
  @override
  void handle(Block block, Context context) {
    print('Entering block: ${getBlockIdentifier(block, context)}');
    print('Available variables: ${context.variables.keys}');
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    print('Exiting block: ${getBlockIdentifier(block, context)}');
    print('Final variables: ${context.variables.keys}');
  }
}
```

