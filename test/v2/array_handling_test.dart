import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';

void main() {
  group('Array Handling Tests', () {
    test('Direct assignment creates array from multiple values', () async {
      final config = '''
order = book pencil sharpener
''';

      final parsed = Config.parse(config);
      final processor = ConfigProcessor();
      await processor.process(parsed);

      final order = processor.context.getVariable('order');
      expect(order, isA<List>());
      expect(order, equals(['book', 'pencil', 'sharpener']));
    });

    test('Append operation adds to existing array', () async {
      final config = '''
order = book pencil sharpener
order += eraser
order += ruler
''';

      final parsed = Config.parse(config);
      final processor = ConfigProcessor();
      await processor.process(parsed);

      final order = processor.context.getVariable('order');
      expect(order, isA<List>());
      expect(order, equals(['book', 'pencil', 'sharpener', 'eraser', 'ruler']));
    });

    test('Append to single value converts to array', () async {
      final config = '''
name = "John Doe"
name += "Smith"
''';

      final parsed = Config.parse(config);
      final processor = ConfigProcessor();
      await processor.process(parsed);

      final name = processor.context.getVariable('name');
      expect(name, isA<List>());
      expect(name, equals(['John Doe', 'Smith']));
    });

    test('Array expansion in strings', () async {
      final config = '''
order = book pencil sharpener
message = "Items: \$order"
''';

      final parsed = Config.parse(config);
      final processor = ConfigProcessor();
      await processor.process(parsed);

      final message = processor.context.getVariable('message');
      expect(message, equals('Items: book pencil sharpener'));
    });

    test('Arrays work inside blocks', () async {
      final config = '''
shopping_list "groceries" {
    items = milk bread eggs
    items += butter cheese
}
''';

      final parsed = Config.parse(config);
      final processor = ConfigProcessor();

      // Register a block handler to access variables within the block scope
      processor.registerBlockHandler(TestBlockHandler());

      await processor.process(parsed);
    });

    test('Array scoping works correctly', () async {
      final config = '''
global_items = apple banana
shopping_list "groceries" {
    items = milk bread eggs
    items += \$global_items
}
''';

      final parsed = Config.parse(config);
      final processor = ConfigProcessor();

      // Register a block handler to access variables within the block scope
      processor.registerBlockHandler(TestBlockHandler());

      await processor.process(parsed);

      // Global variables should still be accessible
      final globalItems = processor.context.getVariable('global_items');
      expect(globalItems, equals(['apple', 'banana']));

      // Local variables should not be accessible after block (correct scoping behavior)
      final localItems = processor.context.getVariable('items');
      expect(localItems, isNull);
    });
  });
}

/// Test block handler that verifies array functionality within block scope
class TestBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'shopping_list';

  @override
  void handle(Block block, Context context) {
    // Block setup - no special handling needed
  }

  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    final items = context.getVariable('items');
    expect(items, isA<List>());
    expect(items, equals(['milk', 'bread', 'eggs', 'butter', 'cheese']));
  }
}
