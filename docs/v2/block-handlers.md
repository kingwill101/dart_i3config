# Block Handlers

Block handlers process specific block types and can register scoped commands that only work within those blocks.

## Overview

Block handlers are responsible for:
- Processing block-level configuration
- Registering scoped commands that only work inside the block
- Managing block-specific context and variables
- Customizing how child elements are processed

## Basic Block Handler

```dart
class BarBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';
  
  @override
  void handle(Block block, Context context) {
    final id = getBlockIdentifier(block, context);
    print('📊 Processing bar: $id');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // Commands that only work inside bar blocks
    registry.registerCommand('status_command', StatusCommandHandler());
    registry.registerCommand('position', PositionCommandHandler());
    registry.registerCommand('height', HeightCommandHandler());
  }
}
```

## Configuration Mapping

Here's how i3 config blocks map to handlers:

### Bar Block Example
```i3
bar "top" {
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
1. `BarBlockHandler` processes the `bar` block
2. Scoped commands are registered: `status_command`, `position`, `height`
3. Each command is handled by its respective handler
4. Nested `colors` block would need its own handler

### Mode Block Example
```i3
mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
```

**Handler Processing:**
1. `ModeBlockHandler` processes the `mode` block
2. Scoped commands: `bindsym` (different from global bindsym)
3. Mode-specific key bindings are registered
4. Mode context is maintained during processing

## Advanced Block Handler Features

### Custom Child Processing

```dart
class ConditionalBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'conditional';
  
  @override
  Future<void> processChildren(Block block, Context context) async {
    // Custom processing: only process enabled features
    for (final child in block.body) {
      if (child is Command && child.head == 'enabled_feature') {
        // Process this child
        await super.processChildren(Block('temp', null, [child]), context);
      }
      // Skip disabled_feature commands
    }
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('enabled_feature', EnabledFeatureHandler());
    registry.registerCommand('disabled_feature', DisabledFeatureHandler());
  }
}
```

### Post-Processing Hook

```dart
class ThemeBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'theme';
  
  @override
  void handle(Block block, Context context) {
    print('🎨 Setting up theme: ${getBlockIdentifier(block, context)}');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('primary_color', ColorHandler());
    registry.registerCommand('secondary_color', ColorHandler());
    registry.registerCommand('font_size', FontSizeHandler());
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    // Access properties set by child commands
    final primaryColor = context.getVariable('primary_color');
    final secondaryColor = context.getVariable('secondary_color');
    final fontSize = context.getVariable('font_size');
    
    print('🎨 Theme configured:');
    print('  Primary: $primaryColor');
    print('  Secondary: $secondaryColor');
    print('  Font Size: $fontSize');
  }
}
```

## Context Scoping

### Global vs Block Context

```dart
class ScopedBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'scoped';
  
  @override
  void handle(Block block, Context context) {
    // This runs in the block's context
    print('Block context variables: ${context.variables.keys}');
    
    // Set block-local variable
    context.setVariable('block_local', 'value');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('set_local', SetLocalHandler());
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    // Access both global and local variables
    final global = context.getVariable('global_var');  // From parent context
    final local = context.getVariable('block_local');  // From this block
    
    print('Global: $global, Local: $local');
  }
}
```

### Context Inheritance

```dart
// Global context
set $mod Mod4
set $terminal alacritty

// Block context inherits global variables
bar "top" {
    # $mod and $terminal are available here
    status_command i3status
    # Block can override global variables
    set $mod Mod1  # This shadows the global $mod
}
```

## Real-World Examples

### i3 Bar Handler

```dart
class I3BarHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';
  
    @override
    void handle(Block block, Context context) {
      final id = getBlockIdentifier(block, context);
      print('Setting up i3bar: $id');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', StatusCommandHandler());
    registry.registerCommand('position', PositionHandler());
    registry.registerCommand('height', HeightHandler());
    registry.registerCommand('colors', ColorsHandler());
    registry.registerCommand('font', FontHandler());
    registry.registerCommand('tray_output', TrayOutputHandler());
  }
}
```

### Sway Output Handler

```dart
class SwayOutputHandler extends BaseBlockHandler {
  @override
  String get blockType => 'output';
  
  @override
  void handle(Block block, Context context) {
    final output = getBlockIdentifier(block, context);
    print('Configuring output: $output');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('mode', OutputModeHandler());
    registry.registerCommand('resolution', ResolutionHandler());
    registry.registerCommand('position', OutputPositionHandler());
    registry.registerCommand('scale', ScaleHandler());
    registry.registerCommand('background', BackgroundHandler());
  }
}
```

### Custom Application Handler

```dart
class AppConfigHandler extends BaseBlockHandler {
  @override
  String get blockType => 'app';
  
  @override
  void handle(Block block, Context context) {
    final appName = getBlockIdentifier(block, context);
    print('Configuring app: $appName');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('theme', AppThemeHandler());
    registry.registerCommand('keybindings', AppKeybindingsHandler());
    registry.registerCommand('settings', AppSettingsHandler());
    registry.registerCommand('plugins', AppPluginsHandler());
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    // Generate app configuration file
    final appName = getBlockIdentifier(block, context);
    final theme = context.getVariable('theme');
    final settings = context.getVariable('settings');
    
    print('Generating config for $appName with theme: $theme');
  }
}
```

## Best Practices

### 1. Use Descriptive Block Types
```dart
// Good
class DatabaseConfigHandler extends BaseBlockHandler {
  @override
  String get blockType => 'database';
}

// Avoid
class DBHandler extends BaseBlockHandler {
  @override
  String get blockType => 'db';
}
```

### 2. Register Relevant Commands Only
```dart
@override
void registerScopedCommands(BlockHandlerRegistry registry) {
  // Only register commands that make sense for this block type
  registry.registerCommand('host', DatabaseHostHandler());
  registry.registerCommand('port', DatabasePortHandler());
  registry.registerCommand('credentials', DatabaseCredentialsHandler());
  
  // Don't register unrelated commands
  // registry.registerCommand('window_title', ...); // Wrong!
}
```

### 3. Use Context Appropriately
```dart
@override
Future<void> afterChildrenProcessed(Block block, Context context) async {
  // Access variables set by child commands
  final config = {
    'host': context.getVariable('host'),
    'port': context.getVariable('port'),
    'database': context.getVariable('database'),
  };
  
  // Process the configuration
  await saveConfig(config);
}
```

### 4. Handle Nested Blocks
```dart
@override
Future<void> processChildren(Block block, Context context) async {
  for (final child in block.body) {
    if (child is Command && child.block != null) {
      // Handle nested blocks
      final nestedBlock = child.block!;
      if (nestedBlock.blockType == 'colors') {
        // Process colors sub-block
        await processColorsBlock(nestedBlock, context);
      }
    } else {
      // Process regular commands
      await super.processChildren(Block('temp', null, [child]), context);
    }
  }
}
```

## Registration

```dart
final processor = ConfigProcessor();

// Register block handlers
processor.registerBlockHandler(BarBlockHandler());
processor.registerBlockHandler(ModeBlockHandler());
processor.registerBlockHandler(OutputBlockHandler());
processor.registerBlockHandler(ThemeBlockHandler());

await processor.process(config);
```

## Testing Block Handlers

```dart
void main() async {
  final config = Config.parse('''
bar "top" {
    status_command i3status
    position top
    height 30
}
''');
  
  final processor = ConfigProcessor();
  processor.registerBlockHandler(BarBlockHandler());
  
  await processor.process(config);
  
  // Verify block was processed
  // Check context variables
  // Validate scoped commands were called
}
```
