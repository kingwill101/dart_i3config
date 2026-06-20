import 'package:i3config/src/v2/ast.dart';
import 'package:i3config/src/v2/builtin.dart';
import 'package:i3config/src/v2/context.dart' show Context;
import 'package:i3config/src/v2/handlers.dart';
import 'package:i3config/src/v2/include_handler.dart';
import 'package:i3config/src/v2/state.dart' show ProcessorState, InitialState;
import 'filesystem.dart' show FileSystem, PhysicalFileSystem;

/// Main configuration processor that orchestrates the state machine.
class ConfigProcessor implements BlockHandlerRegistry {
  final Context _context = Context();
  final List<ProcessorState> _stateStack = [];
  final List<Context> _contextStack = [];

  /// Track which block type we're currently registering commands for.
  String? _currentBlockTypeRegistration;

  /// The filesystem used by built-in handlers (e.g. [IncludeHandler]).
  final FileSystem fileSystem;

  /// Constructor that automatically registers built-in handlers.
  ///
  /// Provide a [fileSystem] to control how files are read.
  /// Defaults to [PhysicalFileSystem] for real I/O.
  /// Pass a [VirtualFileSystem] for testing.
  ConfigProcessor({FileSystem? fileSystem})
      : fileSystem = fileSystem ?? const PhysicalFileSystem() {
    _registerBuiltinHandlers();
  }

  /// Register built-in command handlers using the same registry system.
  void _registerBuiltinHandlers() {
    registerCommandHandler(SetCommandHandler());
    registerCommandHandler(IncludeHandler(fileSystem: fileSystem));
  }

  /// Current processing state.
  ProcessorState get currentState =>
      _stateStack.isNotEmpty ? _stateStack.last : InitialState();

  /// Current processing context.
  Context get context =>
      _contextStack.isNotEmpty ? _contextStack.last : _context;

  /// Push a new state onto the stack.
  void pushState(ProcessorState state) {
    _stateStack.add(state);
  }

  /// Pop the current state from the stack.
  ProcessorState? popState() {
    return _stateStack.isNotEmpty ? _stateStack.removeLast() : null;
  }

  /// Push a new context onto the context stack.
  void pushContext() {
    final currentContext = context;
    _contextStack.add(currentContext.pushContext());
  }

  /// Pop the current context from the context stack.
  void popContext() {
    if (_contextStack.isNotEmpty) {
      _contextStack.removeLast();
    }
  }

  /// Process a configuration.
  /// Returns a Future that completes when all processing is done.
  /// Handlers can be sync or async - the processor waits for async handlers to complete.
  Future<void> process(Config config) async {
    pushState(InitialState());
    _context.currentState = InitialState();
    // Store processor reference for manual processing (if needed)
    _context.options['_processor'] = this;

    try {
      for (final element in config.statements) {
        try {
          await currentState.process(element, this);
        } catch (e) {
          _context.errorHandler?.handleError(e, _context);
          // Continue processing other elements
        }
      }
    } finally {
      popState();
    }
  }

  /// Register a command handler.
  void registerCommandHandler(CommandHandler handler) {
    _context.commandHandlers[handler.commandName] = handler;
  }

  /// Register a block handler.
  /// This will also call the handler's registerScopedCommands method to set up
  /// any block-scoped command handlers.
  void registerBlockHandler(BlockHandler handler) {
    _context.blockHandlers[handler.blockType] = handler;

    // Allow the block handler to register its scoped commands
    _currentBlockTypeRegistration = handler.blockType;
    try {
      handler.registerScopedCommands(this);
    } finally {
      _currentBlockTypeRegistration = null;
    }
  }

  /// Register a command handler scoped to a specific block type.
  /// The handler will only be invoked for commands inside blocks of the specified type.
  ///
  /// Note: Prefer using BlockHandler.registerScopedCommands for better encapsulation.
  void registerBlockScopedCommandHandler(
    String blockType,
    CommandHandler handler,
  ) {
    _context.blockScopedCommandHandlers.putIfAbsent(
      blockType,
      () => {},
    )[handler.commandName] = handler;
  }

  /// Register a block handler scoped to a specific parent block type.
  /// The handler will only be invoked for child blocks inside a parent block
  /// of the specified type.
  ///
  /// This is useful for deeply nested configurations where a block's meaning
  /// depends on its parent context.
  ///
  /// Example:
  /// ```dart
  /// processor.registerBlockScopedBlockHandler('resource', ActionsBlockHandler());
  /// ```
  void registerBlockScopedBlockHandler(
    String parentBlockType,
    BlockHandler handler,
  ) {
    _context.blockScopedBlockHandlers.putIfAbsent(
      parentBlockType,
      () => {},
    )[handler.blockType] = handler;
  }

  @override
  void registerCommand(String commandName, CommandHandler handler) {
    if (_currentBlockTypeRegistration == null) {
      throw StateError(
        'registerCommand can only be called from within BlockHandler.registerScopedCommands',
      );
    }

    _context.blockScopedCommandHandlers.putIfAbsent(
      _currentBlockTypeRegistration!,
      () => {},
    )[commandName] = handler;
  }

  @override
  void registerScopedBlockHandler(String blockType, BlockHandler handler) {
    if (_currentBlockTypeRegistration == null) {
      throw StateError(
        'registerScopedBlockHandler can only be called from within BlockHandler.registerScopedCommands',
      );
    }

    _context.blockScopedBlockHandlers.putIfAbsent(
      _currentBlockTypeRegistration!,
      () => {},
    )[blockType] = handler;
  }

  /// Get all block-scoped handlers registered for a specific block type.
  /// Returns an empty map if no handlers are registered for the block type.
  Map<String, CommandHandler> getBlockScopedHandlers(String blockType) {
    return _context.blockScopedCommandHandlers[blockType] ?? {};
  }

  /// Set the error handler.
  void setErrorHandler(ErrorHandler handler) {
    _context.errorHandler = handler;
  }

  /// Process a configuration string directly.
  /// Convenience method for parsing and processing in one step.
  Future<void> processString(String content) async {
    final config = Config.parse(content);
    await process(config);
  }
}

/// Extension to provide manual element processing for custom block handlers.
extension ManualProcessing on ConfigProcessor {
  /// Manually process a list of elements.
  /// This is useful for block handlers that set processChildrenAutomatically = false
  /// and want to process children with custom logic (filtering, reordering, multi-pass, etc.).
  Future<void> processElements(List<ConfigElement> elements) async {
    for (final element in elements) {
      pushState(InitialState());
      try {
        await currentState.process(element, this);
      } finally {
        popState();
      }
    }
  }
}
