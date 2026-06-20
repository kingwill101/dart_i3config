# Nested Block Processing Guide

## TL;DR

✅ **Blocks automatically process their child commands and blocks sequentially by default**  
✅ **Block handlers don't need to manually iterate children**  
✅ **Processing order is depth-first, sequential (as declared in config)**

## How It Works

### Default Sequential Processing

When a block is encountered, the state machine **automatically**:

1. **Calls the block handler** (if registered) for setup/teardown
2. **Processes all child elements sequentially** in declaration order
3. **Handles nested blocks recursively** using the same pattern

```dart
// From state.dart - _processCommandWithBlock()
for (final element in block.body) {
  processor.pushState(InitialState());
  await processor.currentState.process(element, processor);
  processor.popState();
}
```

### What This Means for Block Handlers

Block handlers **don't need to process children manually**. They focus on block-specific setup/teardown:

```dart
class BarBlockHandler implements BlockHandler {
  @override
  void handle(Block block, ProcessingContext context) {
    // Do bar-specific setup
    print('Entering bar block...');
    
    // NO NEED TO DO THIS - it happens automatically:
    // for (final element in block.body) { ... }
    
    // Optional teardown would go here (but happens after auto-processing)
  }
}
```

## Sequential Processing Order

Given this config:
```
set $global "global"
bar {
    set $var1 "first"
    status_command test
    set $var2 "second"
    mode "resize" {
        bindsym h resize
    }
}
```

**Processing order:**
1. `set $global` (global)
2. Enter `bar` block
   - `BarBlockHandler.handle()` called
   - `set $var1` (in bar context)
   - `status_command test` (bar-scoped handler)
   - `set $var2` (in bar context)
   - Enter `mode` block (nested)
     - `ModeBlockHandler.handle()` called
     - `bindsym h resize` (mode-scoped handler)
   - Exit `mode` block
3. Exit `bar` block

## Test Coverage

**Verified with 5 comprehensive tests:**

✅ Sequential processing of commands in blocks  
✅ Nested command-with-block structures  
✅ Automatic child processing (no manual iteration needed)  
✅ Context chain maintained through nesting  
✅ Deeply nested blocks processed in correct order

## Key Implementation Details

### Where Sequential Processing Happens

**For commands with blocks** (`bar { ... }`):
```dart
// lib/src/v2/visitor.dart - _processCommandWithBlock()
void _processCommandWithBlock(Command command, ConfigProcessor processor) {
  // ... setup ...
  
  // Process block contents sequentially
  for (final element in block.body) {
    processor.pushState(InitialState());
    processor.currentState.process(element, processor);
    processor.popState();
  }
  
  // ... teardown ...
}
```

**For standalone Block elements**:
```dart
// lib/src/v2/visitor.dart - _processDefaultBlock()
void _processDefaultBlock(Block block, ConfigProcessor processor) {
  // ... setup context ...
  
  // Process block contents sequentially
  for (final element in block.body) {
    processor.pushState(InitialState());
    processor.currentState.process(element, processor);
    processor.popState();
  }
  
  // ... cleanup ...
}
```

### Nested Blocks Work Recursively

When processing `block.body`, if an element is itself a `Command` with a block or a `Block`, the `InitialState.process()` dispatches to the appropriate handler:

```dart
// lib/src/v2/visitor.dart - InitialState.process()
case Command command:
  processor.pushState(CommandProcessingState());
  processor.currentState.process(command, processor);
  processor.popState();
  break;
case Block block:
  processor.pushState(BlockProcessingState());
  processor.currentState.process(block, processor);
  processor.popState();
  break;
```

This creates a **natural recursive descent** through the block tree.

## Best Practices

### ✅ DO: Let the default implementation handle children

```dart
class MyBlockHandler implements BlockHandler {
  @override
  void handle(Block block, ProcessingContext context) {
    // Setup
    print('Entering my block');
    // Children are processed automatically after this returns
  }
}
```

### ❌ DON'T: Manually iterate children

```dart
class MyBlockHandler implements BlockHandler {
  @override
  void handle(Block block, ProcessingContext context) {
    // DON'T DO THIS - it's already done for you:
    for (final element in block.body) {
      // ...
    }
  }
}
```

### When You Might Need Manual Processing

The **only** time you'd manually process children is if you need:
- Non-sequential processing (filtering, reordering)
- Conditional processing (skip certain elements)
- Custom error handling per element
- Multi-pass processing

In those cases, you can override the default by not relying on automatic processing.

## Summary

The state machine provides **automatic, sequential, recursive processing** of nested blocks by default. Block handlers focus on setup/teardown, while child processing is handled transparently by the framework. This keeps block handler code clean and simple!
