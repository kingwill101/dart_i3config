import 'dart:async';
import 'package:i3config/i3config_v2.dart';

/// Example demonstrating array handling with += operations
///
/// This shows how the system handles:
/// - Direct assignment: order = book pencil sharpener
/// - Append operations: order += eraser
/// - Array expansion in strings
Future<void> main() async {
  final config = '''
# Direct assignment - creates array from multiple values
order = book pencil sharpener

# Append operations - adds to existing array
order += eraser
order += ruler

# Single value assignment
name = "John Doe"

# Append to single value - converts to array
name += "Smith"

# Array expansion in strings
message = "Items: \$order"

# Block with array usage
shopping_list "groceries" {
    items = milk bread eggs
    items += butter cheese
    items += \$order
    
    # Access array in block handler
    print_items true
}
''';

  final parsed = Config.parse(config);
  final processor = ConfigProcessor();

  // Register a block handler to demonstrate array access
  processor.registerBlockHandler(ShoppingListBlockHandler());

  print(
    'Registered block handlers: ${processor.context.globalContext.blockHandlers.keys}',
  );

  await processor.process(parsed);
}

/// Block handler that demonstrates array access
class ShoppingListBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'shopping_list';

  @override
  void handle(Block block, Context context) {
    final id = getBlockIdentifier(block, context);
    print('\\n🛒 Processing shopping list: $id');
    print('  Block type: ${block.blockType}');
    print('  Block body length: ${block.body.length}');
    print('  Handler found and called!');
  }

  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    // Access the array that was built up
    final items = context.getVariable('items');
    final printItems = context.getVariable('print_items');

    print('  📋 Items: $items');
    print('  📋 Items type: ${items.runtimeType}');

    if (printItems == 'true' && items is List) {
      print('  📝 Shopping list:');
      for (int i = 0; i < items.length; i++) {
        print('    ${i + 1}. ${items[i]}');
      }
    }
  }
}
