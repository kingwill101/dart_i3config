import 'package:i3config/i3config_v2.dart';
import 'shared_handlers.dart';

Future<void> main() async {
  // Example i3 configuration
  final configContent = '''
# Set mod key
set \$mod Mod4

# Key bindings
bindsym \$mod+Return exec i3-sensible-terminal
bindsym \$mod+Shift+q kill

# Bar configuration
bar {
    status_command i3status
    position top
}

# Resize mode
mode "resize" {
    bindsym h resize shrink width 10 px
    bindsym j resize grow height 10 px
}
''';

  // Parse the configuration
  final config = Config.parse(configContent);
  print('Parsed configuration with ${config.statements.length} elements\n');

  // Example 1: Basic processing with state machine
  print('=== Example 1: Basic Processing ===');
  final processor = ConfigProcessor();

  // Register command handlers
  processor.registerCommandHandler(SetCommandHandler());
  processor.registerCommandHandler(BindsymCommandHandler());

  // Register block handlers
  processor.registerBlockHandler(BarBlockHandler());
  processor.registerBlockHandler(ModeBlockHandler());

  // Set error handler
  processor.setErrorHandler(DefaultErrorHandler());

  // Process the configuration
  await processor.process(config);
  print('');

  // Example 2: Using visitor pattern to collect commands
  print('=== Example 2: Command Collection ===');
  final collector = CommandCollectorVisitor();
  final commandsByType = collector.visitConfig(config);

  print('Commands by type:');
  commandsByType.forEach((type, commands) {
    print('  $type: ${commands.length} commands');
  });
  print('');

  // Example 3: Using visitor pattern to validate configuration
  print('=== Example 3: Configuration Validation ===');
  final validator = ConfigValidatorVisitor();
  final errors = validator.visitConfig(config);

  if (errors.isEmpty) {
    print('Configuration is valid!');
  } else {
    print('Configuration errors:');
    for (final error in errors) {
      print('  - $error');
    }
  }
  print('');

  // Example 4: Accessing processing context
  print('=== Example 4: Processing Context ===');
  print('Variables defined:');
  processor.context.variables.forEach((name, value) {
    print('  \$$name = $value');
  });

  print('Bindings registered:');
  final bindings =
      processor.context.options['bindings'] as Map<String, String>?;
  if (bindings != null) {
    bindings.forEach((key, action) {
      print('  $key -> $action');
    });
  }
  print('');

  // Example 5: Custom command handler
  print('=== Example 5: Custom Command Handler ===');
  final customProcessor = ConfigProcessor();
  customProcessor.registerCommandHandler(CustomExecHandler());
  await customProcessor.process(config);
}

/// Custom handler for 'exec' commands.
class CustomExecHandler implements CommandHandler {
  @override
  String get commandName => 'exec';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final program = _expandValue(command.args[0], context);
      print('Would execute: $program');

      // Could add logic to actually execute the program
      // or validate that the program exists, etc.
    }
  }

  String _expandValue(Value value, Context context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
      case VariableRef varRef:
        return context.getVariable(varRef.name) ?? '\$${varRef.name}';
      case BareArg bareArg:
        return context.expandVariables(bareArg.value);
      case ArrayValue array:
        return array.items
            .map((v) => _expandValue(v, context))
            .join(', ');
    }
  }
}
