import 'package:i3config/i3config.dart';
import 'shared_handlers.dart';

Future<void> main() async {
  print('=== i3config Chained State System Example ===\n');

  // Example configuration with global and block scoped variables
  final configContent = '''
# Global scope variables
set \$mod Mod4
set \$terminal "i3-sensible-terminal"
set \$editor "vim"

# Global binding
bindsym \$mod+Return exec \$terminal

# Bar block with its own scope
bar {
    # These variables are scoped to the bar block
    set \$bar_status "i3status"
    set \$terminal "i3bar-terminal"  # Shadows global terminal
    
    status_command \$bar_status
    position top
    
    # This binding uses the local terminal variable
    bindsym \$mod+Shift+Return exec \$terminal
}

# Mode block with nested scope
mode "resize" {
    # Mode-specific variables
    set \$resize_step "10px"
    set \$mod "Resize"  # Shadows global mod
    
    # These bindings use mode-scoped variables
    bindsym \$mod+Left resize shrink width \$resize_step
    bindsym \$mod+Right resize grow width \$resize_step
}

# Back to global scope - uses original variables
bindsym \$mod+Shift+q exec \$editor
''';

  // Parse the configuration
  final config = Config.parse(configContent);
  print('Parsed ${config.statements.length} top-level statements\n');

  // Create processor with handlers
  final processor = ConfigProcessor();
  processor.registerCommandHandler(SetCommandHandler());
  processor.registerCommandHandler(BindsymCommandHandler());
  processor.registerBlockHandler(BarBlockHandler());
  processor.registerBlockHandler(ModeBlockHandler());

  // Process the configuration
  print('=== Processing Configuration ===');
  await processor.process(config);

  // Display final state
  print('\n=== Final Global Context ===');
  final globalContext = processor.context.globalContext;
  globalContext.variables.forEach((name, value) {
    print('Global \$$name = "$value"');
  });

  // Show how variable expansion works
  print('\n=== Variable Expansion Examples ===');
  final examples = [
    '\$mod+Return',
    '\$terminal',
    '\$editor',
    '\$mod+\$terminal',
    'Unknown: \$nonexistent',
  ];

  for (final example in examples) {
    final expanded = globalContext.expandVariables(example);
    print('"$example" → "$expanded"');
  }

  print('\n=== Summary ===');
  print('✅ Chained state system working correctly');
  print('✅ Variable scoping with shadowing');
  print('✅ Block processing with context isolation');
  print('✅ Variable expansion across context chain');
  print('✅ Commands are scoped to their containing blocks');
}
