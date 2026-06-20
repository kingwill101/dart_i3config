import 'dart:async' show FutureOr;

import 'package:i3config/src/v2/base_handlers.dart' show BaseBlockHandler;
import 'package:i3config/src/v2/context.dart' show Context;
import 'package:i3config/src/v2/handlers.dart';
import 'package:i3config/src/v2/processor.dart';
import 'package:i3config/src/v2/value.dart';
import 'package:i3config/src/v2/ast.dart'
    show
        Command,
        Block,
        Comment,
        AssignmentOperator,
        Assignment,
        ConfigElement,
        Config;

/// Base state for the configuration processor.
abstract class ProcessorState {
  /// Process a configuration element in this state.
  /// Can be async if handlers perform async operations.
  FutureOr<void> process(ConfigElement element, ConfigProcessor processor);

  /// Get the current state name for debugging.
  String get stateName;
}

/// Initial processing state.
class InitialState extends ProcessorState {
  InitialState();

  @override
  String get stateName => 'Initial';

  @override
  Future<void> process(ConfigElement element, ConfigProcessor processor) async {
    switch (element) {
      case Config config:
        // Process all statements in the config
        for (final statement in config.statements) {
          await process(statement, processor);
        }
        break;
      case Assignment assignment:
        processor.pushState(AssignmentProcessingState());
        await processor.currentState.process(assignment, processor);
        processor.popState();
        break;
      case Command command:
        processor.pushState(CommandProcessingState());
        await processor.currentState.process(command, processor);
        processor.popState();
        break;
      case Block block:
        processor.pushState(BlockProcessingState());
        await processor.currentState.process(block, processor);
        processor.popState();
        break;
      case Comment _:
        break;
    }
  }
}

/// State for processing commands.
class CommandProcessingState extends ProcessorState {
  @override
  String get stateName => 'CommandProcessing';

  @override
  Future<void> process(ConfigElement element, ConfigProcessor processor) async {
    if (element is Command) {
      final command = element;

      // If command has an attached block (e.g., bar { ... }), process it as a block
      if (command.block != null) {
        await _processCommandWithBlock(command, processor);
        return;
      }

      // Handler resolution order:
      // 1. Check for block-scoped handler (if inside a block)
      // 2. Check for global command handler
      // 3. Default command processing

      CommandHandler? handler;

      // Step 1: Check block-scoped handlers (from global context)
      final currentBlockType = processor.context.currentBlockType;
      if (currentBlockType != null) {
        final globalContext = processor.context.globalContext;
        final blockScopedHandlers =
            globalContext.blockScopedCommandHandlers[currentBlockType];
        if (blockScopedHandlers != null) {
          handler = blockScopedHandlers[command.head];
        }
      }

      // Step 2: Check global handlers if no block-scoped handler found
      handler ??= processor.context.globalContext.commandHandlers[command.head];

      // Step 3: If handler found, use it; otherwise use default processing
      if (handler != null) {
        await handler.handle(command, processor.context);
        return;
      }

      // Default command processing
      _processDefaultCommand(command, processor);
    }
  }

  Future<void> _processCommandWithBlock(
    Command command,
    ConfigProcessor processor,
  ) async {
    // Commands with blocks (like bar { ... }) should be processed as blocks
    // The block type is the command's head (e.g., 'bar', 'mode', etc.)
    final block = command.block!;

    // Handler resolution order:
    // 1. Block-scoped block handler (registered by a parent block handler)
    // 2. Global block handler
    BlockHandler? handler;
    final currentBlockType = processor.context.currentBlockType;
    if (currentBlockType != null) {
      handler = processor.context.globalContext
          .blockScopedBlockHandlers[currentBlockType]
          ?[command.head];
    }
    handler ??=
        processor.context.globalContext.blockHandlers[command.head];

    // Process block contents with the command head as block type
    processor.pushContext();

    final previousBlockType = processor.context.currentBlockType;
    processor.context.currentBlockType = command.head;

    try {
      // Call the block handler if registered (for setup/teardown)
      if (handler != null) {
        await handler.handle(block, processor.context);
      }

      // Process block contents - either custom or automatic
      if (handler != null) {
        final customProcessing = handler.processChildren(
          block,
          processor.context,
        );
        if (customProcessing != null) {
          // Handler provided custom processing
          await customProcessing;
        } else {
          // Default: automatic sequential processing
          for (final element in block.body) {
            processor.pushState(InitialState());
            await processor.currentState.process(element, processor);
            processor.popState();
          }
        }

        // Call afterChildrenProcessed hook if handler supports it
        if (handler is BaseBlockHandler) {
          await handler.afterChildrenProcessed(block, processor.context);
        }
      } else {
        // No handler: default automatic processing
        for (final element in block.body) {
          processor.pushState(InitialState());
          await processor.currentState.process(element, processor);
          processor.popState();
        }
      }
    } finally {
      processor.context.currentBlockType = previousBlockType;
      processor.popContext();
    }
  }

  void _processDefaultCommand(Command command, ConfigProcessor processor) {
    // Default property command processing: property_name value
    // This automatically sets the property name as a context variable with the given value
    if (command.args.isNotEmpty) {
      final propertyName = command.head;
      final value = command.args[0];

      // Expand the value (handles variables, quotes, etc.)
      final expandedValue = _expandValue(value, processor.context);

      // Set the property in the current context
      processor.context.setVariable(propertyName, expandedValue);
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
    }
  }
}

/// State for processing assignments.
class AssignmentProcessingState extends ProcessorState {
  @override
  String get stateName => 'AssignmentProcessing';

  @override
  Future<void> process(ConfigElement element, ConfigProcessor processor) async {
    if (element is Assignment) {
      final assignment = element;

      // Process assignment by expanding values and storing in context
      _processAssignment(assignment, processor);
    }
  }

  void _processAssignment(Assignment assignment, ConfigProcessor processor) {
    // Assignment processing logic
    switch (assignment.operator) {
      case AssignmentOperator.assign:
        // Handle direct assignment
        _processDirectAssignment(assignment, processor);
        break;
      case AssignmentOperator.append:
        // Handle append assignment
        _processAppendAssignment(assignment, processor);
        break;
    }
  }

  void _processDirectAssignment(
    Assignment assignment,
    ConfigProcessor processor,
  ) {
    // Direct assignment logic - sets the variable to the given value(s)
    final expandedValues = assignment.values
        .map((value) => _expandValue(value, processor.context))
        .toList();

    // Store the assignment in the current context
    if (expandedValues.length == 1) {
      // Single value - store as string
      processor.context.setVariable(assignment.variable, expandedValues.first);
    } else {
      // Multiple values - store as array
      processor.context.setVariable(assignment.variable, expandedValues);
    }
  }

  void _processAppendAssignment(
    Assignment assignment,
    ConfigProcessor processor,
  ) {
    // Append assignment logic - appends to existing array or creates new one
    final expandedValues = assignment.values
        .map((value) => _expandValue(value, processor.context))
        .toList();

    // Get existing value
    final existingValue = processor.context.getVariable(assignment.variable);

    if (existingValue == null) {
      // No existing value - create new array
      processor.context.setVariable(assignment.variable, expandedValues);
    } else if (existingValue is List) {
      // Existing array - append to it
      final newArray = [...existingValue, ...expandedValues];
      processor.context.setVariable(assignment.variable, newArray);
    } else {
      // Existing single value - convert to array and append
      final newArray = [existingValue, ...expandedValues];
      processor.context.setVariable(assignment.variable, newArray);
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
    }
  }
}

/// State for processing blocks.
class BlockProcessingState extends ProcessorState {
  @override
  String get stateName => 'BlockProcessing';

  @override
  Future<void> process(ConfigElement element, ConfigProcessor processor) async {
    if (element is Block) {
      final block = element;

      // Handler resolution order:
      // 1. Block-scoped block handler (registered by a parent block handler)
      // 2. Global block handler
      BlockHandler? handler;
      final currentBlockType = processor.context.currentBlockType;
      if (currentBlockType != null) {
        handler = processor.context.globalContext
            .blockScopedBlockHandlers[currentBlockType]
            ?[block.blockType ?? ''];
      }
      handler ??=
          processor.context.globalContext.blockHandlers[block.blockType ?? ''];

      final resolvedHandler = handler;
      if (resolvedHandler != null) {
        // Set block type before calling handler
        await _withBlockType(block.blockType, processor, () async {
          await resolvedHandler.handle(block, processor.context);
        });
        return;
      }

      // Default block processing
      await _processDefaultBlock(block, processor);
    }
  }

  Future<void> _processDefaultBlock(
    Block block,
    ConfigProcessor processor,
  ) async {
    // Push new context for block processing (creates child context)
    processor.pushContext();

    // Set the current block type for scoped handler lookup
    final previousBlockType = processor.context.currentBlockType;
    processor.context.currentBlockType = block.blockType;

    try {
      // Get handler and check for custom child processing
      final handler =
          processor.context.globalContext.blockHandlers[block.blockType ?? ''];

      if (handler != null) {
        // Call the block handler for setup
        await handler.handle(block, processor.context);

        final customProcessing = handler.processChildren(
          block,
          processor.context,
        );
        if (customProcessing != null) {
          // Handler provided custom processing
          await customProcessing;
        } else {
          // Default: automatic sequential processing
          for (final element in block.body) {
            processor.pushState(InitialState());
            await processor.currentState.process(element, processor);
            processor.popState();
          }
        }

        // Call afterChildrenProcessed hook if handler supports it
        if (handler is BaseBlockHandler) {
          await handler.afterChildrenProcessed(block, processor.context);
        }
      } else {
        // No handler: default automatic processing
        for (final element in block.body) {
          processor.pushState(InitialState());
          await processor.currentState.process(element, processor);
          processor.popState();
        }
      }
    } finally {
      // Restore previous block type
      processor.context.currentBlockType = previousBlockType;
      // Pop context when done with block
      processor.popContext();
    }
  }

  Future<void> _withBlockType(
    String? blockType,
    ConfigProcessor processor,
    Future<void> Function() action,
  ) async {
    final previousBlockType = processor.context.currentBlockType;
    processor.context.currentBlockType = blockType;
    try {
      await action();
    } finally {
      processor.context.currentBlockType = previousBlockType;
    }
  }
}
