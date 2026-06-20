import 'package:i3config/i3config_v2.dart';

/// Comprehensive example demonstrating how i3/Sway configurations
/// map to handlers and processing in the V2 state machine.
Future<void> main() async {
  print('=== Comprehensive Configuration Example ===\n');

  // Complete i3 configuration
  final configContent = '''
# Global variables
set \$mod Mod4
set \$terminal alacritty
set \$browser firefox
set \$editor vim

# Key bindings
bindsym \$mod+Return exec \$terminal
bindsym \$mod+Shift+b exec \$browser
bindsym \$mod+Shift+e exec \$terminal -e \$editor
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec rofi -show run

# Window assignments
assign [class="Firefox"] 2
assign [class="Alacritty"] 1
assign [title=".*Vim.*"] 3

# Window rules
for_window [class=".*"] border pixel 1
for_window [class="Firefox"] floating enable

# Bar configuration
bar "top" {
    status_command i3status
    position top
    height 30
    font pango:DejaVu Sans Mono 10
    
    colors {
        background #000000
        statusline #ffffff
        focused_workspace #007acc #007acc #ffffff
        inactive_workspace #333333 #333333 #ffffff
    }
    
    tray_output primary
}

# Mode configuration
mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
}

# Custom application configuration
app "firefox" {
    theme dark
    keybindings {
        ctrl+t new_tab
        ctrl+w close_tab
        ctrl+r reload
    }
    settings {
        homepage "https://www.google.com"
        search_engine "Google"
        privacy_mode enabled
    }
}
''';

  // Parse configuration
  final config = Config.parse(configContent);
  
  // Create processor with custom handlers
  final processor = ConfigProcessor();
  
  // Register global command handlers
  processor.registerCommandHandler(BindsymHandler());
  processor.registerCommandHandler(AssignHandler());
  processor.registerCommandHandler(ForWindowHandler());
  
  // Register block handlers
  processor.registerBlockHandler(BarBlockHandler());
  processor.registerBlockHandler(ModeBlockHandler());
  processor.registerBlockHandler(AppBlockHandler());
  
  // Process configuration
  await processor.process(config);
  
  print('\n=== Processing Complete ===');
  print('Global variables: ${processor.context.variables.keys}');
}

// Global Command Handlers

class BindsymHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'bindsym';

  @override
  void handle(Command command, Context context) {
    final key = command.getArgAsString(0, context);
    final action = command.args.length > 1
        ? command.args.skip(1).map((v) => expandValue(v, context)).join(' ')
        : '';

    print('⌨️  Key binding: $key -> $action');

    // Store in context
    final bindings = context.getVariable('key_bindings') as Map<String, String>? ?? {};
    bindings[key] = action;
    context.setVariable('key_bindings', bindings);
  }
}

class AssignHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'assign';
  
  @override
  void handle(Command command, Context context) {
    final criteriaStr = command.criteria
        ?.map((c) => '${c.key}=${expandValue(c.value, context)}')
        .join(', ');
    final workspace = command.getArgAsString(0, context);
    
    print('🪟 Window assignment: $criteriaStr -> workspace $workspace');
    
    // Store in context
    final assignments = context.getVariable('window_assignments') as List<Map<String, String>>? ?? [];
    assignments.add({'criteria': criteriaStr ?? '', 'workspace': workspace});
    context.setVariable('window_assignments', assignments);
  }
}

class ForWindowHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'for_window';
  
  @override
  void handle(Command command, Context context) {
    final criteriaStr = command.criteria
        ?.map((c) => '${c.key}=${expandValue(c.value, context)}')
        .join(', ');
    final action = command.args.isNotEmpty
        ? command.args.map((v) => expandValue(v, context)).join(' ')
        : '';
    
    print('🪟 Window rule: $criteriaStr -> $action');
    
    // Store in context
    final rules = context.getVariable('window_rules') as List<Map<String, String>>? ?? [];
    rules.add({'criteria': criteriaStr ?? '', 'action': action});
    context.setVariable('window_rules', rules);
  }
}

// Block Handlers

class BarBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';
  
  @override
  void handle(Block block, Context context) {
    final id = getBlockIdentifier(block, context);
    print('📊 Setting up bar: $id');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', StatusCommandHandler());
    registry.registerCommand('position', PositionHandler());
    registry.registerCommand('height', HeightHandler());
    registry.registerCommand('font', FontHandler());
    registry.registerCommand('colors', ColorsHandler());
    registry.registerCommand('tray_output', TrayOutputHandler());
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    final id = getBlockIdentifier(block, context);
    final statusCommand = context.getVariable('status_command');
    final position = context.getVariable('position');
    final height = context.getVariable('height');
    
    print('📊 Bar "$id" configured:');
    print('  Status: $statusCommand');
    print('  Position: $position');
    print('  Height: $height');
  }
}

class ModeBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'mode';
  
  @override
  void handle(Block block, Context context) {
    final modeName = getBlockIdentifier(block, context);
    print('🔄 Setting up mode: $modeName');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // Mode-specific bindsym commands
    registry.registerCommand('bindsym', ModeBindsymHandler());
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    final modeName = getBlockIdentifier(block, context);
    print('🔄 Mode "$modeName" configured with ${block.body.length} bindings');
  }
}

class AppBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'app';
  
  @override
  void handle(Block block, Context context) {
    final appName = getBlockIdentifier(block, context);
    print('📱 Configuring app: $appName');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('theme', AppThemeHandler());
    registry.registerCommand('keybindings', AppKeybindingsHandler());
    registry.registerCommand('settings', AppSettingsHandler());
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    final appName = getBlockIdentifier(block, context);
    final theme = context.getVariable('theme');
    
    print('📱 App "$appName" configured with theme: $theme');
  }
}

// Scoped Command Handlers

class StatusCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'status_command';
  
  @override
  String? handle(Command command, Context context) {
    final statusCommand = command.getArgAsString(0, context);
    print('📊 Status command: $statusCommand');
    context.setVariable('status_command', statusCommand);
    return statusCommand;
  }
}

class PositionHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'position';
  
  @override
  String? handle(Command command, Context context) {
    final position = command.getArgAsString(0, context);
    print('📍 Position: $position');
    context.setVariable('position', position);
    return position;
  }
}

class HeightHandler extends BaseCommandHandler<int> {
  @override
  String get commandName => 'height';
  
  @override
  int? handle(Command command, Context context) {
    final height = command.getArgAsInt(0, context);
    print('📏 Height: $height');
    context.setVariable('height', height);
    return height;
  }
}

class FontHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'font';
  
  @override
  String? handle(Command command, Context context) {
    final font = command.getArgAsString(0, context);
    print('🔤 Font: $font');
    context.setVariable('font', font);
    return font;
  }
}

class ColorsHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'colors';
  
  @override
  void handle(Command command, Context context) {
    print('🎨 Processing colors block');
    // Colors block would be processed by its own handler
  }
}

class TrayOutputHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'tray_output';
  
  @override
  String? handle(Command command, Context context) {
    final output = command.getArgAsString(0, context);
    print('📱 Tray output: $output');
    context.setVariable('tray_output', output);
    return output;
  }
}

class ModeBindsymHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'bindsym';
  
  @override
  void handle(Command command, Context context) {
    final key = command.getArgAsString(0, context);
    final action = command.args.length > 1
        ? command.args.skip(1).map((v) => expandValue(v, context)).join(' ')
        : '';
    
    print('⌨️  Mode binding: $key -> $action');
    
    // Store mode-specific bindings
    final modeBindings = context.getVariable('mode_bindings') as List<Map<String, String>>? ?? [];
    modeBindings.add({'key': key, 'action': action});
    context.setVariable('mode_bindings', modeBindings);
  }
}

class AppThemeHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'theme';
  
  @override
  String? handle(Command command, Context context) {
    final theme = command.getArgAsString(0, context);
    print('🎨 App theme: $theme');
    context.setVariable('theme', theme);
    return theme;
  }
}

class AppKeybindingsHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'keybindings';
  
  @override
  void handle(Command command, Context context) {
    print('⌨️  Processing app keybindings block');
    // Keybindings block would be processed by its own handler
  }
}

class AppSettingsHandler extends BaseCommandHandler<void> {
  @override
  String get commandName => 'settings';
  
  @override
  void handle(Command command, Context context) {
    print('⚙️  Processing app settings block');
    // Settings block would be processed by its own handler
  }
}

