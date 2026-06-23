# Custom Child Processing Guide

## Overview

Block handlers can control how their child elements are processed by overriding the `processChildren()` method:
- **Conditional processing** (skip certain children)
- **Custom ordering** (reverse, sort, prioritize)
- **Multi-pass processing** (collect then apply)
- **Filtering** (only process specific element types)

## API

### BlockHandler Interface

```dart
abstract class BlockHandler {
  FutureOr<void> handle(Block block, ProcessingContext context);
  String get blockType;
  void registerScopedCommands(BlockHandlerRegistry registry) {}
  
  /// Override to customize child processing.
  /// Return null (default) for automatic sequential processing.
  /// Return non-null to take manual control.
  FutureOr<void>? processChildren(Block block, ProcessingContext context);
}
```

### Two Patterns

#### Pattern 1: Automatic Processing (Default)

Mix in `DefaultChildProcessing` for automatic sequential processing:

```dart
class MyBlockHandler with DefaultChildProcessing implements BlockHandler {
  @override
  String get blockType => 'my_block';
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('my_cmd', MyCmdHandler());
  }
  
  @override
  void handle(Block block, ProcessingContext context) {
    // Setup logic here
    // Children are AUTOMATICALLY processed sequentially after this
  }
  
  // processChildren() inherited from DefaultChildProcessing (returns null)
}
```

#### Pattern 2: Custom Processing

Override `processChildren()` to return non-null:

```dart
class FilteringBlockHandler implements BlockHandler {
  @override
  String get blockType => 'filter';
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}
  
  @override
  void handle(Block block, ProcessingContext context) {
    // Setup logic here
  }
  
  @override
  Future<void> processChildren(Block block, ProcessingContext context) async {
    // Custom processing: filter children
    for (final element in block.body) {
      if (shouldProcess(element)) {
        // Option A: Process manually
        if (element is Command) {
          // Handle directly
        }
        
        // Option B: Use processor.processElements()
        final processor = context.globalContext.options['_processor'] as ConfigProcessor;
        await processor.processElements([element]);
      }
    }
  }
  
  bool shouldProcess(ConfigElement element) {
    return element is Command && element.head == 'allowed_cmd';
  }
}
```

## Use Cases

### 1. Conditional Processing

Only process enabled features:

```dart
class ConditionalBlockHandler implements BlockHandler {
  @override
  String get blockType => 'conditional_block';
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}
  
  @override
  void handle(Block block, ProcessingContext context) {
    // Setup logic
  }
  
  @override
  Future<void> processChildren(Block block, ProcessingContext context) async {
    for (final element in block.body) {
      if (element is Command && element.head == 'enabled_feature') {
        // Process this one
        processFeature(element);
      } else if (element is Command && element.head == 'disabled_feature') {
        // Skip this one
        print('Skipping: ${element.args}');
      }
    }
  }
}
```

Config:
```
conditional_block {
    enabled_feature "dark_mode"     ← Processed
    disabled_feature "beta_ui"       ← Skipped
    enabled_feature "animations"    ← Processed
}
```

### 2. Reverse Processing

Process children in reverse order:

```dart
class ReverseBlockHandler implements BlockHandler {
  @override
  String get blockType => 'reverse_block';
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}
  
  @override
  void handle(Block block, ProcessingContext context) {
    // Setup logic
  }
  
  @override
  void processChildren(Block block, ProcessingContext context) {
    for (final element in block.body.reversed) {
      processElement(element, context);
    }
  }
}
```

Config:
```
reverse_block {
    cmd first    ← Processed THIRD
    cmd second   ← Processed SECOND
    cmd third    ← Processed FIRST
}
```

### 3. Multi-Pass Processing

Collect declarations, then process usages:

```dart
class MultiPassHandler implements BlockHandler {
  @override
  String get blockType => 'multi_pass';
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}
  
  @override
  void handle(Block block, ProcessingContext context) {
    // Setup logic
  }
  
  @override
  void processChildren(Block block, ProcessingContext context) {
    // Pass 1: Collect declarations
    for (final element in block.body) {
      if (element is Command && element.head == 'declare') {
        collectDeclaration(element);
      }
    }
    
    // Pass 2: Process usages (can now reference declarations)
    for (final element in block.body) {
      if (element is Command && element.head == 'use') {
        processUsage(element);
      }
    }
  }
}
```

### 4. Manual Processing with Full State Machine

Use `processor.processElements()` for full processing:

```dart
class ManualBlockHandler implements BlockHandler {
  @override
  String get blockType => 'manual_block';
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}
  
  @override
  void handle(Block block, ProcessingContext context) {
    // Setup logic
  }
  
  @override
  Future<void> processChildren(Block block, ProcessingContext context) async {
    final processor = context.globalContext.options['_processor'] as ConfigProcessor;
    
    // Filter and reorder
    final filtered = block.body.where((e) => shouldInclude(e)).toList();
    final sorted = filtered..sort(myComparator);
    
    // Process with full state machine support
    await processor.processElements(sorted);
  }
}
```

## Nested Blocks

Nested blocks work automatically with either pattern:

```
widget "container" {
    type container
    padding 16px
    
    style {              ← NESTED block
        font_weight bold  ← Processed automatically
        margin 20px
    }
}
```

The `style` block inside `widget`:
1. Widget handler runs first
2. Widget's children processed (including nested `style` block command)
3. Style block handler runs
4. Style's children processed
5. All sequential and automatic!

## Testing

See comprehensive tests in `test/custom_child_processing_test.dart`:

- ✅ Skip automatic processing
- ✅ Filter children
- ✅ Reorder children  
- ✅ Multi-pass processing
- ✅ Manual processing with `processor.processElements()`

## Summary

| Pattern | When to Use | Method Override |
|---------|-------------|-----------------|
| `with DefaultChildProcessing` | Standard sequential processing (most cases) | None - uses default |
| Override `processChildren()` | Custom logic needed | Return non-null |

**Key Points:**
- Default: mix `DefaultChildProcessing` mixin (returns `null` → automatic processing)
- Custom: override `processChildren()` and return non-null to take control
- Use `processor.processElements()` for full state machine support when processing manually
- Async handlers supported: `processChildren()` can return `Future<void>`
- Clean API: simple method override, no awkward getters or boolean flags

