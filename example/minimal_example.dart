import 'package:i3config/i3config_v2.dart';

/// Minimal example showing default behavior - only global 'set' command is supported.
Future<void> main() async {
  print('=== Minimal Default Configuration Processing ===\n');

  final configContent = '''
# Global variables (supported by default)
set \$mod Mod4
set \$terminal alacritty
set \$browser firefox

# Variables can reference other variables
set \$editor \$terminal -e vim
''';

  final config = Config.parse(configContent);
  final processor = ConfigProcessor();

  // By default, NO handlers are registered!
  // You must explicitly add any handlers you need.

  // The only built-in handler is SetCommandHandler for global variables
  processor.registerCommandHandler(SetCommandHandler());

  await processor.process(config);

  print('Global variables defined:');
  processor.context.variables.forEach((name, value) {
    print('  \$$name = "$value"');
  });

  print('\n=== Key Points ===');
  print('1. By default, ConfigProcessor has NO registered handlers');
  print(
    '2. SetCommandHandler is the only built-in handler (for global variables)',
  );
  print(
    '3. All block handlers (bar, mode, etc.) are examples - NOT registered by default',
  );
  print('4. You explicitly register only what you need for your use case');
  print('\nThis keeps the core minimal and flexible!');
}
