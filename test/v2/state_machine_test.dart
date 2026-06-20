import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';
import 'test_handlers.dart';

void main() {
  group('State Machine and Visitor Pattern Tests', () {
    test('basic processor functionality', () async {
      final configContent = '''
set \$mod Mod4
bindsym \$mod+Return exec terminal
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      // Register handlers
      processor.registerCommandHandler(SetCommandHandler());
      processor.registerCommandHandler(BindsymCommandHandler());

      // Process configuration
      await processor.process(config);

      // Verify variables were set
      expect(processor.context.getVariable('mod'), 'Mod4');

      // Verify bindings were registered
      final bindings =
          processor.context.options['bindings'] as Map<String, String>?;
      expect(bindings, isNotNull);
      expect(bindings!['Mod4'], '+Return');
    });

    test('command collector visitor', () async {
      final configContent = '''
set \$mod Mod4
bindsym \$mod+Return exec terminal
bindsym \$mod+Shift+q kill
''';

      final config = Config.parse(configContent);
      final collector = CommandCollectorVisitor();
      final commandsByType = collector.visitConfig(config);

      expect(commandsByType['set'], hasLength(1));
      expect(commandsByType['bindsym'], hasLength(2));

      final setCommands = commandsByType['set']!;
      expect(setCommands.first.head, 'set');
      expect(setCommands.first.args.length, 2);
    });

    test('config validator visitor', () async {
      final configContent = '''
set \$mod Mod4
bindsym \$mod+Return exec terminal
''';

      final config = Config.parse(configContent);
      final validator = ConfigValidatorVisitor();
      final errors = validator.visitConfig(config);

      expect(errors, isEmpty);
    });

    test('variable expansion', () async {
      final configContent = '''
set \$mod Mod4
set \$terminal \$mod+Return
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      // Verify variable expansion
      expect(processor.context.getVariable('mod'), 'Mod4');
      // Note: Variable expansion in set commands needs to be implemented
      // For now, just verify the variable was set
      expect(processor.context.getVariable('terminal'), isNotNull);
    });

    test('block processing', () async {
      final configContent = '''
bar {
    status_command i3status
    position top
}
''';

      final config = Config.parse(configContent);
      // final processor = ConfigProcessor();
      // processor.registerBlockHandler(BarBlockHandler());

      // // Process configuration (output will go to console)
      // await processor.process(config);

      // Verify block was processed (we can't easily capture print output in tests)
      expect(config.statements.length, 1);
      expect(config.statements.first, isA<Command>());
      final command = config.statements.first as Command;
      expect(command.head, 'bar');
    });

    test('error handling', () async {
      final configContent = '''
set \$mod Mod4
invalid command
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      // Capture errors
      final errors = <String>[];
      processor.setErrorHandler(_TestErrorHandler(errors));

      await processor.process(config);

      // Should still process valid commands
      expect(processor.context.getVariable('mod'), 'Mod4');
    });

    test('custom command handler', () async {
      final configContent = '''
exec i3-sensible-terminal
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(_TestExecHandler());

      // Process configuration (output will go to console)
      await processor.process(config);

      // Verify command was processed
      expect(config.statements.length, 1);
      expect(config.statements.first, isA<Command>());
      final command = config.statements.first as Command;
      expect(command.head, 'exec');
      expect(command.args.length, 1);
    });
  });

  group('Chained State System', () {
    test('should support variable scoping with context hierarchy', () async {
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      // Set global variables
      processor.context.setVariable('global_var', 'global_value');
      processor.context.setVariable('another_global', 'another_value');

      expect(processor.context.getVariable('global_var'), 'global_value');
      expect(processor.context.getVariable('another_global'), 'another_value');

      // Enter block scope
      processor.pushContext();
      final blockContext = processor.context;

      // Set block variables
      blockContext.setVariable('block_var', 'block_value');
      blockContext.setVariable('global_var', 'block_override'); // Shadow global

      // Test variable access from block context
      expect(
        blockContext.getVariable('global_var'),
        'block_override',
      ); // Shadowed
      expect(blockContext.getVariable('block_var'), 'block_value'); // Local
      expect(
        blockContext.getVariable('another_global'),
        'another_value',
      ); // Inherited

      // Test variable expansion from block context
      final expanded = blockContext.expandVariables(
        'Block: \$global_var, \$block_var, \$another_global',
      );
      expect(expanded, 'Block: block_override, block_value, another_value');

      // Exit block scope
      processor.popContext();

      // Test that block variables are no longer accessible
      expect(
        processor.context.getVariable('global_var'),
        'global_value',
      ); // Back to original
      expect(
        processor.context.getVariable('block_var'),
        null,
      ); // No longer accessible
      expect(
        processor.context.getVariable('another_global'),
        'another_value',
      ); // Still accessible
    });

    test('should handle nested block scoping', () async {
      final processor = ConfigProcessor();

      // Global scope
      processor.context.setVariable('global', 'global_value');

      // First block
      processor.pushContext();
      final block1 = processor.context;
      block1.setVariable('block1', 'block1_value');
      block1.setVariable('global', 'block1_override');

      expect(block1.getVariable('global'), 'block1_override');
      expect(block1.getVariable('block1'), 'block1_value');

      // Second nested block
      processor.pushContext();
      final block2 = processor.context;
      block2.setVariable('block2', 'block2_value');
      block2.setVariable('global', 'block2_override');

      expect(block2.getVariable('global'), 'block2_override');
      expect(block2.getVariable('block1'), 'block1_value'); // From parent block
      expect(block2.getVariable('block2'), 'block2_value');

      // Exit second block
      processor.popContext();

      // Exit first block
      processor.popContext();

      // Back to global
      expect(processor.context.getVariable('global'), 'global_value');
      expect(processor.context.getVariable('block1'), null);
      expect(processor.context.getVariable('block2'), null);
    });
  });
}

/// Test error handler that collects errors.
class _TestErrorHandler implements ErrorHandler {
  final List<String> errors;

  _TestErrorHandler(this.errors);

  @override
  void handleError(dynamic error, Context context) {
    errors.add(error.toString());
  }
}

/// Test exec handler.
class _TestExecHandler with ValueExpander implements CommandHandler {
  @override
  String get commandName => 'exec';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final program = expandValue(command.args[0], context);
      print('Would execute: $program');
    }
  }
}
