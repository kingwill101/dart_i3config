import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';

void main() {
  group('SetCommandHandler (Built-in)', () {
    test('should set simple variable', () async {
      final configContent = 'set \$mod Mod4';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('mod'), equals('Mod4'));
    });

    test('should set variable with quoted value', () async {
      final configContent = 'set \$terminal "alacritty"';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('terminal'), equals('alacritty'));
    });

    test('should set variable with bare argument', () async {
      final configContent = 'set \$browser firefox';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('browser'), equals('firefox'));
    });

    test('should expand variable references in values', () async {
      final configContent = '''
set \$base_dir /home/user
set \$config_dir \$base_dir
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('base_dir'), equals('/home/user'));
      expect(processor.context.getVariable('config_dir'), equals('/home/user'));
    });

    test('should handle multiple variable assignments', () async {
      final configContent = '''
set \$mod Mod4
set \$terminal alacritty
set \$browser firefox
set \$editor vim
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.variables.length, equals(4));
      expect(processor.context.getVariable('mod'), equals('Mod4'));
      expect(processor.context.getVariable('terminal'), equals('alacritty'));
      expect(processor.context.getVariable('browser'), equals('firefox'));
      expect(processor.context.getVariable('editor'), equals('vim'));
    });

    test('should overwrite existing variable', () async {
      final configContent = '''
set \$var "initial"
set \$var "updated"
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('var'), equals('updated'));
      expect(processor.context.variables.length, equals(1));
    });

    test('should expand variables in bare argument values', () async {
      final configContent = '''
set \$mod Mod4
set \$key_prefix \$mod
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('mod'), equals('Mod4'));
      expect(processor.context.getVariable('key_prefix'), equals('Mod4'));
    });

    test('should handle commands with insufficient args gracefully', () async {
      final configContent = 'set \$incomplete';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      // Should not throw, just not set anything
      expect(() async => await processor.process(config), returnsNormally);
      expect(processor.context.getVariable('incomplete'), isNull);
    });

    test('should only process VariableRef as first argument', () async {
      // This tests the check for VariableRef type
      final config = Config([
        Command('set', [
          BareArg('not_a_var'), // Not a VariableRef
          BareArg('value'),
        ]),
      ]);

      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      // Should not set anything because first arg isn't a VariableRef
      expect(processor.context.variables, isEmpty);
    });

    test('should expand variables in quoted strings', () async {
      final configContent = '''
set \$user alice
set \$home_path "/home/\$user"
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('user'), equals('alice'));
      expect(processor.context.getVariable('home_path'), equals('/home/alice'));
    });

    test('should make global variables available inside blocks', () async {
      final configContent = '''
set \$global_var "global_value"
set \$another_global "another_value"
bar {
    status_command \$global_var
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      // Create a test handler that captures the expanded value
      final capturedValues = <String>[];
      final testHandler = _CaptureValueHandler(capturedValues);
      processor.registerBlockScopedCommandHandler('bar', testHandler);

      await processor.process(config);

      // Verify global variables were set
      expect(
        processor.context.getVariable('global_var'),
        equals('global_value'),
      );
      expect(
        processor.context.getVariable('another_global'),
        equals('another_value'),
      );

      // Verify the block command saw the expanded global variable
      expect(capturedValues, contains('global_value'));
    });

    test('should allow blocks to shadow global variables', () async {
      final configContent = '''
set \$var "global"
bar {
    set \$var "block_local"
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      // After block processing, global variable should be unchanged
      expect(processor.context.getVariable('var'), equals('global'));
    });

    test(
      'should allow referencing global variables from block context',
      () async {
        final configContent = '''
set \$base "base_value"
bar {
    set \$derived \$base
}
''';

        final config = Config.parse(configContent);
        final processor = ConfigProcessor();
        processor.registerCommandHandler(SetCommandHandler());

        // Capture what value was set inside the block
        final capturedVars = <String, String>{};

        // Use a test block handler that tracks variable sets
        final testHandler = _TrackingBarBlockHandler(capturedVars);
        processor.registerBlockHandler(testHandler);

        await processor.process(config);

        // Global variable should still be accessible
        expect(processor.context.getVariable('base'), equals('base_value'));

        // Verify the block saw and could reference the global variable
        expect(capturedVars.containsKey('derived'), isTrue);
        expect(capturedVars['derived'], equals('base_value'));
      },
    );
  });
}

/// Test handler that captures expanded values from command arguments.
class _CaptureValueHandler with ValueExpander implements CommandHandler {
  final List<String> capturedValues;

  _CaptureValueHandler(this.capturedValues);

  @override
  String get commandName => 'status_command';

  @override
  void handle(Command command, Context context) {
    for (final arg in command.args) {
      capturedValues.add(expandValue(arg, context));
    }
  }
}

/// Test block handler that tracks variables set within the block.
class _TrackingBarBlockHandler
    with DefaultChildProcessing
    implements BlockHandler {
  final Map<String, String> capturedVars;

  _TrackingBarBlockHandler(this.capturedVars);

  @override
  String get blockType => 'bar';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('set', _TrackingSetHandler(capturedVars));
  }

  @override
  void handle(Block block, Context context) {
    // Just track that block was processed
  }
}

/// Test handler that tracks set commands within a specific context.
class _TrackingSetHandler with ValueExpander implements CommandHandler {
  final Map<String, String> capturedVars;

  _TrackingSetHandler(this.capturedVars);

  @override
  String get commandName => 'set';

  @override
  void handle(Command command, Context context) {
    if (command.args.length >= 2) {
      final varRef = command.args[0];
      final value = command.args[1];

      if (varRef is VariableRef) {
        final varName = varRef.name;
        final varValue = expandValue(value, context);
        capturedVars[varName] = varValue;
        context.setVariable(varName, varValue);
      }
    }
  }
}
