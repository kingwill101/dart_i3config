import 'package:i3config/i3config_v2.dart';
import '../test/v2/test_handlers.dart';

void main() {
  print('=== Block-Scoped Handler Example ===\n');
  
  final configContent = '''
# Global bindings
bindsym Mod4+Return exec terminal

# Bar block with scoped commands
bar {
    status_command i3status
    position top
}

# Mode block with mode-specific bindsym
mode "resize" {
    bindsym h resize shrink width 10 px
    bindsym l resize grow width 10 px
}
''';

  final config = Config.parse(configContent);
  final processor = ConfigProcessor();
  
  // NOTE: By default, ConfigProcessor has NO handlers registered!
  // You must explicitly register what you need.
  
  // Register global handlers (if you need them)
  processor.registerCommandHandler(BindsymCommandHandler());
  
  // Register block handlers - these internally register their scoped commands
  processor.registerBlockHandler(BarBlockHandler());
  processor.registerBlockHandler(ModeBlockHandler());
  
  print('Processing configuration...\n');
  processor.process(config);
  
  print('\n=== Results ===');
  
  // Global bindings
  final globalBindings = processor.context.options['bindings'] as Map<String, String>?;
  if (globalBindings != null) {
    print('\nGlobal bindings:');
    globalBindings.forEach((key, value) {
      print('  $key -> $value');
    });
  }
  
  // Mode bindings (stored separately by ModeBindsymHandler)
  final modeBindings = processor.context.options['mode_bindings'] as Map<String, String>?;
  if (modeBindings != null) {
    print('\nMode-specific bindings:');
    modeBindings.forEach((key, value) {
      print('  $key -> $value');
    });
  }
  
  print('\n=== Block Handler Architecture ===');
  print('''
The new architecture allows BlockHandler classes to internally register
their own scoped commands. This provides better encapsulation:

1. BarBlockHandler registers:
   - status_command (only valid in bar blocks)
   - position (only valid in bar blocks)

2. ModeBlockHandler registers:
   - bindsym (mode-specific, different from global bindsym)

This approach keeps block-specific command logic organized within
the appropriate block handler class, making the codebase more maintainable.
''');
}



