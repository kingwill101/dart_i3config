import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';

void main() {
  group('Custom Child Processing', () {
    test(
      'should skip automatic child processing when handler opts out',
      () async {
        final configContent = '''
custom_block {
    set \$var1 "value1"
    set \$var2 "value2"
}
''';

        final config = Config.parse(configContent);
        final processor = ConfigProcessor();

        processor.registerCommandHandler(SetCommandHandler());
        processor.registerBlockHandler(NoAutoProcessHandler());

        await processor.process(config);

        // Variables should NOT be set (children weren't processed)
        expect(processor.context.getVariable('var1'), isNull);
        expect(processor.context.getVariable('var2'), isNull);
      },
    );

    test('should allow manual child processing with custom logic', () async {
      final configContent = '''
filter_block {
    allowed_cmd arg1
    forbidden_cmd arg2
    allowed_cmd arg3
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final processedCommands = <String>[];
      processor.registerBlockHandler(FilteringBlockHandler(processedCommands));

      await processor.process(config);

      // Only 'allowed_cmd' commands should be processed
      expect(processedCommands, equals(['arg1', 'arg3']));
      expect(processedCommands, isNot(contains('arg2')));
    });

    test('should allow reordering children before processing', () async {
      final configContent = '''
reverse_block {
    cmd first
    cmd second
    cmd third
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final processOrder = <String>[];
      processor.registerBlockHandler(ReverseProcessingHandler(processOrder));

      await processor.process(config);

      // Children should be processed in reverse order
      expect(processOrder, equals(['third', 'second', 'first']));
    });

    test('should allow multi-pass processing', () async {
      final configContent = '''
multi_pass {
    declare var1
    declare var2
    use var1
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final phases = <String>[];
      processor.registerBlockHandler(MultiPassHandler(phases));

      await processor.process(config);

      // Should process in two passes
      expect(
        phases,
        equals(['pass1:declare', 'pass1:declare', 'pass2:use']),
      );
    });

    test('should provide access to processor for manual processing', () async {
      final configContent = '''
manual_block {
    cmd arg1
    cmd arg2
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final processed = <String>[];
      processor.registerCommandHandler(TrackingCmdHandler(processed));
      processor.registerBlockHandler(ManualProcessingHandler());

      await processor.process(config);

      // Handler manually processed children using processElements()
      expect(processed, equals(['arg1', 'arg2']));
    });
  });
}

/// Block handler that opts out of automatic child processing.
class NoAutoProcessHandler implements BlockHandler {
  @override
  String get blockType => 'custom_block';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  Future<void> processChildren(Block block, Context context) async {
    // Return non-null to take control (do nothing = skip children)
  }

  @override
  void handle(Block block, Context context) {
    // Do nothing - children won't be processed
  }
}

/// Block handler that filters which children to process.
class FilteringBlockHandler implements BlockHandler {
  final List<String> processedCommands;

  FilteringBlockHandler(this.processedCommands);

  @override
  String get blockType => 'filter_block';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  Future<void> processChildren(Block block, Context context) async {
    // Custom processing: filter and handle only allowed commands
    for (final element in block.body) {
      if (element is Command && element.head == 'allowed_cmd') {
        if (element.args.isNotEmpty) {
          final arg = element.args[0];
          if (arg is BareArg) {
            processedCommands.add(arg.value);
          }
        }
      }
    }
  }

  @override
  void handle(Block block, Context context) {
    // Setup logic here
  }
}

/// Block handler that processes children in reverse order.
class ReverseProcessingHandler with ValueExpander implements BlockHandler {
  final List<String> processOrder;

  ReverseProcessingHandler(this.processOrder);

  @override
  String get blockType => 'reverse_block';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  void processChildren(Block block, Context context) {
    // Custom processing: reverse order
    for (final element in block.body.reversed) {
      if (element is Command && element.args.isNotEmpty) {
        final arg = expandValue(element.args[0], context);
        processOrder.add(arg);
      }
    }
  }

  @override
  void handle(Block block, Context context) {
    // Setup logic here
  }
}

/// Block handler that processes children in multiple passes.
class MultiPassHandler implements BlockHandler {
  final List<String> phases;

  MultiPassHandler(this.phases);

  @override
  String get blockType => 'multi_pass';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  void processChildren(Block block, Context context) {
    // Custom processing: multi-pass
    // Pass 1: Process 'declare' commands
    for (final element in block.body) {
      if (element is Command && element.head == 'declare') {
        phases.add('pass1:declare');
      }
    }

    // Pass 2: Process 'use' commands
    for (final element in block.body) {
      if (element is Command && element.head == 'use') {
        phases.add('pass2:use');
      }
    }
  }

  @override
  void handle(Block block, Context context) {
    // Setup logic here
  }
}

/// Block handler that manually processes using ConfigProcessor.processElements().
class ManualProcessingHandler implements BlockHandler {
  @override
  String get blockType => 'manual_block';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  Future<void> processChildren(Block block, Context context) async {
    // Custom processing: use processor.processElements()
    final processor =
        context.globalContext.options['_processor'] as ConfigProcessor?;
    if (processor != null) {
      await processor.processElements(block.body);
    }
  }

  @override
  void handle(Block block, Context context) {
    // Setup logic here
  }
}

/// Simple tracking handler for testing.
class TrackingCmdHandler with ValueExpander implements CommandHandler {
  final List<String> processed;

  TrackingCmdHandler(this.processed);

  @override
  String get commandName => 'cmd';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      processed.add(expandValue(command.args[0], context));
    }
  }
}
