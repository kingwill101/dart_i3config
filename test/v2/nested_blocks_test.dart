import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';
import 'test_handlers.dart';

void main() {
  group('Nested Block Processing', () {
    test('should process commands inside blocks sequentially', () async {
      final configContent = '''
bar {
    status_command first
    position top
    status_command second
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      // Track order of processing
      final processOrder = <String>[];
      processor.registerBlockScopedCommandHandler(
        'bar',
        _OrderTrackingHandler(processOrder, 'status_command'),
      );
      processor.registerBlockScopedCommandHandler(
        'bar',
        _OrderTrackingHandler(processOrder, 'position'),
      );

      await processor.process(config);

      // Verify sequential processing in declaration order
      expect(
        processOrder,
        equals([
          'status_command:first',
          'position:top',
          'status_command:second',
        ]),
      );
    });

    test('should process nested command-with-block structures', () async {
      // Test structure: bar { set $var "value" } mode { bindsym ... }
      final configContent = '''
bar {
    status_command outer_bar
}
mode "resize" {
    bindsym h resize
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final processOrder = <String>[];
      processor.registerBlockHandler(_OrderedBarHandler(processOrder));
      processor.registerBlockHandler(_OrderedModeHandler(processOrder));

      await processor.process(config);

      // Verify blocks processed in order
      expect(
        processOrder,
        equals(['bar:start', 'bar:end', 'mode:start', 'mode:end']),
      );
    });

    test(
      'should allow block handlers to process children automatically',
      () async {
        final configContent = '''
bar {
    set \$var1 "value1"
    status_command test
    set \$var2 "value2"
}
''';

        final config = Config.parse(configContent);
        final processor = ConfigProcessor();

        processor.registerCommandHandler(SetCommandHandler());

        // Track what gets processed
        final processedCommands = <String>[];
        processor.registerBlockScopedCommandHandler(
          'bar',
          _TrackingHandler(processedCommands),
        );

        await processor.process(config);

        // Verify all commands were processed (automatically, not by block handler)
        // The set commands should have been processed
        expect(
          processor.context.variables.containsKey('var1'),
          isFalse,
        ); // Block scope
        expect(
          processor.context.variables.containsKey('var2'),
          isFalse,
        ); // Block scope

        // But status_command should have been seen
        expect(processedCommands, contains('status_command'));
      },
    );

    test('should maintain context chain through nested processing', () async {
      final configContent = '''
set \$global "global_value"
bar {
    set \$bar_local "bar_value"
    mode "resize" {
        set \$mode_local "mode_value"
    }
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      // Only global should be accessible after processing
      expect(processor.context.getVariable('global'), equals('global_value'));
      expect(processor.context.getVariable('bar_local'), isNull);
      expect(processor.context.getVariable('mode_local'), isNull);
    });

    test('should process deeply nested blocks in order', () async {
      // Manually create a nested structure since parser might not support it
      final innerCommand = Command('set', [
        VariableRef('inner'),
        BareArg('inner_val'),
      ]);
      final middleCommand = Command('set', [
        VariableRef('middle'),
        BareArg('middle_val'),
      ]);
      final outerCommand = Command('set', [
        VariableRef('outer'),
        BareArg('outer_val'),
      ]);

      final innerBlock = Block('inner_block', null, [innerCommand]);
      final middleBlock = Block('middle_block', null, [
        middleCommand,
        innerBlock,
      ]);
      final outerBlock = Block('outer_block', null, [
        outerCommand,
        middleBlock,
      ]);

      final config = Config([outerBlock]);
      final processor = ConfigProcessor();

      // Track processing order
      final processOrder = <String>[];
      final trackingHandler = _VarTrackingSetHandler(processOrder);
      processor.registerCommandHandler(trackingHandler);

      await processor.process(config);

      // Verify depth-first, sequential processing
      expect(processOrder, equals(['outer', 'middle', 'inner']));
    });
  });
}

/// Handler that tracks processing order by command name and first arg.
class _OrderTrackingHandler with ValueExpander implements CommandHandler {
  final List<String> processOrder;
  final String _commandName;

  _OrderTrackingHandler(this.processOrder, this._commandName);

  @override
  String get commandName => _commandName;

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final value = expandValue(command.args[0], context);
      processOrder.add('$commandName:$value');
    }
  }
}

/// Block handler that tracks start/end of block processing.
class _OrderedBarHandler with DefaultChildProcessing implements BlockHandler {
  final List<String> processOrder;

  _OrderedBarHandler(this.processOrder);

  @override
  String get blockType => 'bar';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', BarStatusCommandHandler());
  }

  @override
  void handle(Block block, Context context) {
    processOrder.add('bar:start');
    // Note: Child processing happens automatically after this
    processOrder.add('bar:end');
  }
}

/// Mode block handler that tracks order.
class _OrderedModeHandler with DefaultChildProcessing implements BlockHandler {
  final List<String> processOrder;

  _OrderedModeHandler(this.processOrder);

  @override
  String get blockType => 'mode';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('bindsym', ModeBindsymHandler());
  }

  @override
  void handle(Block block, Context context) {
    processOrder.add('mode:start');
    processOrder.add('mode:end');
  }
}

/// Handler that tracks commands processed.
class _TrackingHandler with ValueExpander implements CommandHandler {
  final List<String> processedCommands;

  _TrackingHandler(this.processedCommands);

  @override
  String get commandName => 'status_command';

  @override
  void handle(Command command, Context context) {
    processedCommands.add('status_command');
  }
}

/// Set handler that tracks variable names in order.
class _VarTrackingSetHandler with ValueExpander implements CommandHandler {
  final List<String> processOrder;

  _VarTrackingSetHandler(this.processOrder);

  @override
  String get commandName => 'set';

  @override
  void handle(Command command, Context context) {
    if (command.args.length >= 2) {
      final varRef = command.args[0];
      if (varRef is VariableRef) {
        processOrder.add(varRef.name);
      }
    }
  }
}
