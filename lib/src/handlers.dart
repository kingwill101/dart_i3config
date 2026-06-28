import 'dart:async';

import 'package:i3config/src/context.dart';
import 'package:i3config/src/ast.dart';
import 'package:source_span/source_span.dart';

/// Handler for specific command types.
abstract class CommandHandler {
  /// Handle a command with the given context.
  /// Can return a Future for async operations or void for sync operations.
  /// Can optionally return a value of any type.
  FutureOr<dynamic> handle(Command command, Context context);

  /// Get the command name this handler processes.
  String get commandName;
}

/// Handler for specific block types.
///
/// ## Handler Lifecycle
///
/// When a block is processed, the following lifecycle methods are called
/// in order:
///
/// 1. `handle(block, context)` — Setup/initialization. Called once when
///    the block is entered.
/// 2. `processChildren(block, context)` — Child processing. Return `null`
///    to use automatic sequential processing, or a `Future<void>` to
///    provide custom processing.
/// 3. `afterChildrenProcessed(block, context)` — Post-processing. Called
///    after all children have been processed. Use this for validation,
///    aggregation, or cleanup that needs child results.
///
/// ## Data Availability
///
/// - During `handle()`: Context variables from parent scopes are available,
///   but child commands have not yet run.
/// - During `processChildren()`: Default processing runs child commands,
///   populating context variables. Custom processing can inspect or
///   reorder `block.body`.
/// - During `afterChildrenProcessed()`: All child commands have run,
///   context variables are fully populated, and `blockRegistry` contains
///   any blocks processed during this block's scope.
///
/// ## BlockRegistry
///
/// Child blocks register their data via `Context.registerBlock()`, making
/// it available to parent handlers through `Context.blockRegistry`.
/// Use `getChildBlock()`, `getAllBlocks()`, and `countBlock()` helpers
/// for convenient access.
abstract class BlockHandler {
  /// Handle a block with the given context.
  /// Can return a Future for async operations or void for sync operations.
  FutureOr<void> handle(Block block, Context context);

  /// Get the block type this handler processes.
  String get blockType;

  /// Register block-scoped command handlers for this block type.
  /// Override this method to register commands that should only be active
  /// within this block type.
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // Default: no scoped commands
  }

  /// Process child elements of the block.
  ///
  /// Return `null` for automatic sequential processing.
  /// Return a `Future<void>` for custom async processing.
  FutureOr<void>? processChildren(Block block, Context context);
}

/// Registry interface for registering commands and sub-block handlers
/// within a block handler's `registerScopedCommands` method.
abstract class BlockHandlerRegistry {
  /// Register a command handler scoped to the current block type.
  void registerCommand(String commandName, CommandHandler handler);

  /// Register a block handler scoped to the current block type.
  ///
  /// The handler will only be invoked for child blocks of the given type
  /// that appear inside the current block. This enables clean nested-block
  /// processing without polluting the global handler registry.
  ///
  /// Example inside a `ResourceBlockHandler`:
  /// ```dart
  /// @override
  /// void registerScopedCommands(BlockHandlerRegistry registry) {
  ///   registry.registerScopedBlockHandler('actions', ActionsBlockHandler());
  /// }
  /// ```
  void registerScopedBlockHandler(String blockType, BlockHandler handler);
}

/// Error handler for processing errors.
abstract class ErrorHandler {
  /// Handle a processing error.
  void handleError(String message, Context context, {SourceSpan? span});
}
