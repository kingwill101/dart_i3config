import 'dart:async';

import 'package:i3config/src/v2/context.dart';
import 'package:i3config/src/v2/ast.dart';

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
abstract class BlockHandler {
  /// Handle a block with the given context.
  /// Can return a Future for async operations or void for sync operations.
  FutureOr<void> handle(Block block, Context context);

  /// Get the block type this handler processes.
  String get blockType;

  /// Register block-scoped command handlers for this block type.
  /// Override this method to register commands that should only be active
  /// within this block type.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void registerScopedCommands(BlockHandlerRegistry registry) {
  ///   registry.registerCommand('status_command', BarStatusCommandHandler());
  ///   registry.registerCommand('position', BarPositionCommandHandler());
  /// }
  /// ```
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // Default: no scoped commands
  }

  /// Process child elements of the block.
  ///
  /// **Default behavior**: Returns `null`, which triggers automatic sequential processing.
  ///
  /// **Override** to customize child processing:
  /// - Filter which children to process
  /// - Reorder children before processing
  /// - Multi-pass processing
  /// - Conditional execution
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> processChildren(Block block, ProcessingContext context) async {
  ///   // Filter and process only certain children
  ///   for (final child in block.body.where((e) => shouldProcess(e))) {
  ///     await processElement(child, context);
  ///   }
  /// }
  /// ```
  ///
  /// Return `null` (default) for automatic processing.
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
  void handleError(dynamic error, Context context);
}
