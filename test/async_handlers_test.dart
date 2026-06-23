import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';

void main() {
  group('Async Handler Support', () {
    test('should support async command handlers', () async {
      final configContent = '''
fetch_config "https://example.com/config"
set \$mod Mod4
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final fetchedData = <String>[];
      processor.registerCommandHandler(AsyncFetchHandler(fetchedData));
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      // Verify async handler completed
      expect(fetchedData, contains('https://example.com/config'));

      // Verify subsequent sync handler also processed
      expect(processor.context.getVariable('mod'), equals('Mod4'));
    });

    test('should support async block handlers', () async {
      final configContent = '''
async_block {
    set \$inner "value"
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final events = <String>[];
      processor.registerBlockHandler(AsyncBlockHandler(events));
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      // Verify async block handler completed in order
      expect(events, equals(['block:start', 'block:end']));
    });

    test('should process async handlers sequentially', () async {
      final configContent = '''
async_cmd step1
async_cmd step2
async_cmd step3
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final processOrder = <String>[];
      processor.registerCommandHandler(AsyncDelayHandler(processOrder));

      await processor.process(config);

      // Verify sequential processing (not parallel)
      expect(processOrder, equals(['step1', 'step2', 'step3']));
    });

    test(
      'should await async handlers before processing next element',
      () async {
        final configContent = '''
async_cmd first
set \$var "value"
async_cmd second
''';

        final config = Config.parse(configContent);
        final processor = ConfigProcessor();

        final timeline = <String>[];
        processor.registerCommandHandler(AsyncTimelineHandler(timeline));
        processor.registerCommandHandler(SyncTimelineSetHandler(timeline));

        await processor.process(config);

        // Verify correct ordering: async completes before next element
        expect(
          timeline,
          equals([
            'async:first:start',
            'async:first:end',
            'set:var',
            'async:second:start',
            'async:second:end',
          ]),
        );
      },
    );

    test('should support mix of sync and async handlers', () async {
      final configContent = '''
sync_cmd test1
async_cmd test2
sync_cmd test3
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final processOrder = <String>[];
      processor.registerCommandHandler(SyncTestHandler(processOrder));
      processor.registerCommandHandler(AsyncTestHandler(processOrder));

      await processor.process(config);

      expect(processOrder, equals(['sync:test1', 'async:test2', 'sync:test3']));
    });

    test('should support async block-scoped handlers', () async {
      final configContent = '''
async_block {
    scoped_async_cmd data1
    scoped_async_cmd data2
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final processOrder = <String>[];
      processor.registerBlockHandler(AsyncScopedBlockHandler(processOrder));

      await processor.process(config);

      // Verify block and scoped handlers both async
      expect(processOrder, contains('scoped:data1'));
      expect(processOrder, contains('scoped:data2'));
    });
  });
}

/// Example async command handler that simulates fetching data.
class AsyncFetchHandler with ValueExpander implements CommandHandler {
  final List<String> fetchedData;

  AsyncFetchHandler(this.fetchedData);

  @override
  String get commandName => 'fetch_config';

  @override
  Future<void> handle(Command command, Context context) async {
    if (command.args.isNotEmpty) {
      final url = expandValue(command.args[0], context);

      // Simulate async operation
      await Future.delayed(Duration(milliseconds: 10));

      fetchedData.add(url);
    }
  }
}

/// Example async block handler.
class AsyncBlockHandler with DefaultChildProcessing implements BlockHandler {
  final List<String> events;

  AsyncBlockHandler(this.events);

  @override
  String get blockType => 'async_block';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // No scoped commands for this simple example
  }

  @override
  Future<void> handle(Block block, Context context) async {
    events.add('block:start');

    // Simulate async setup
    await Future.delayed(Duration(milliseconds: 5));

    events.add('block:end');
  }
}

/// Handler that adds delay to test sequential processing.
class AsyncDelayHandler with ValueExpander implements CommandHandler {
  final List<String> processOrder;

  AsyncDelayHandler(this.processOrder);

  @override
  String get commandName => 'async_cmd';

  @override
  Future<void> handle(Command command, Context context) async {
    if (command.args.isNotEmpty) {
      final value = expandValue(command.args[0], context);

      // Add delay to ensure we're really awaiting
      await Future.delayed(Duration(milliseconds: 10));

      processOrder.add(value);
    }
  }
}

/// Handler that tracks timeline of async operations.
class AsyncTimelineHandler with ValueExpander implements CommandHandler {
  final List<String> timeline;

  AsyncTimelineHandler(this.timeline);

  @override
  String get commandName => 'async_cmd';

  @override
  Future<void> handle(Command command, Context context) async {
    if (command.args.isNotEmpty) {
      final value = expandValue(command.args[0], context);
      timeline.add('async:$value:start');
      await Future.delayed(Duration(milliseconds: 5));
      timeline.add('async:$value:end');
    }
  }
}

/// Sync handler for timeline testing.
class SyncTimelineSetHandler with ValueExpander implements CommandHandler {
  final List<String> timeline;

  SyncTimelineSetHandler(this.timeline);

  @override
  String get commandName => 'set';

  @override
  void handle(Command command, Context context) {
    if (command.args.length >= 2 && command.args[0] is VariableRef) {
      final varName = (command.args[0] as VariableRef).name;
      timeline.add('set:$varName');
      context.setVariable(varName, expandValue(command.args[1], context));
    }
  }
}

/// Sync test handler.
class SyncTestHandler with ValueExpander implements CommandHandler {
  final List<String> processOrder;

  SyncTestHandler(this.processOrder);

  @override
  String get commandName => 'sync_cmd';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final value = expandValue(command.args[0], context);
      processOrder.add('sync:$value');
    }
  }
}

/// Async test handler.
class AsyncTestHandler with ValueExpander implements CommandHandler {
  final List<String> processOrder;

  AsyncTestHandler(this.processOrder);

  @override
  String get commandName => 'async_cmd';

  @override
  Future<void> handle(Command command, Context context) async {
    if (command.args.isNotEmpty) {
      final value = expandValue(command.args[0], context);
      await Future.delayed(Duration(milliseconds: 5));
      processOrder.add('async:$value');
    }
  }
}

/// Block handler with async scoped commands.
class AsyncScopedBlockHandler
    with DefaultChildProcessing
    implements BlockHandler {
  final List<String> processOrder;

  AsyncScopedBlockHandler(this.processOrder);

  @override
  String get blockType => 'async_block';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand(
      'scoped_async_cmd',
      AsyncScopedCommandHandler(processOrder),
    );
  }

  @override
  Future<void> handle(Block block, Context context) async {
    await Future.delayed(Duration(milliseconds: 5));
  }
}

/// Async scoped command handler.
class AsyncScopedCommandHandler with ValueExpander implements CommandHandler {
  final List<String> processOrder;

  AsyncScopedCommandHandler(this.processOrder);

  @override
  String get commandName => 'scoped_async_cmd';

  @override
  Future<void> handle(Command command, Context context) async {
    if (command.args.isNotEmpty) {
      final value = expandValue(command.args[0], context);
      await Future.delayed(Duration(milliseconds: 5));
      processOrder.add('scoped:$value');
    }
  }
}
