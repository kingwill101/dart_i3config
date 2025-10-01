import 'ast.dart';

/// Base visitor interface for processing configuration elements.
abstract class ConfigVisitor<T> {
  /// Visit a Config element (root container).
  T visitConfig(Config config);
  
  /// Visit an Assignment element.
  T visitAssignment(Assignment assignment);
  
  /// Visit a Command element.
  T visitCommand(Command command);
  
  /// Visit a Block element.
  T visitBlock(Block block);
  
  /// Visit a Comment element.
  T visitComment(Comment comment);
  
  /// Visit a Value element.
  T visitValue(Value value);
}

/// Base state for the configuration processor.
abstract class ProcessorState {
  /// Process a configuration element in this state.
  void process(ConfigElement element, ConfigProcessor processor);
  
  /// Get the current state name for debugging.
  String get stateName;
}

/// Context object that holds processing state and configuration.
class ProcessingContext {
  /// Variables defined during processing (e.g., from 'set' commands).
  final Map<String, String> variables = {};
  
  /// Current processing state.
  ProcessorState? currentState;
  
  /// Parent context for scoping (null for global context).
  final ProcessingContext? parentContext;
  
  /// Registry of custom command handlers.
  final Map<String, CommandHandler> commandHandlers = {};
  
  /// Registry of custom block handlers.
  final Map<String, BlockHandler> blockHandlers = {};
  
  /// Processing options and flags.
  final Map<String, dynamic> options = {};
  
  /// Error handler for processing errors.
  ErrorHandler? errorHandler;
  
  /// Create a new processing context.
  ProcessingContext({ProcessingContext? parentContext, ErrorHandler? errorHandler})
      : parentContext = parentContext,
        errorHandler = errorHandler;
  
  /// Push a new context onto the stack (e.g., when entering a block).
  /// This creates a child context that has access to parent variables.
  ProcessingContext pushContext() {
    return ProcessingContext(parentContext: this, errorHandler: errorHandler);
  }
  
  /// Set a variable value in the current scope.
  void setVariable(String name, String value) {
    variables[name] = value;
  }
  
  /// Get a variable value, searching up the context chain.
  String? getVariable(String name) {
    // First check current context
    if (variables.containsKey(name)) {
      return variables[name];
    }
    
    // Then check parent contexts
    ProcessingContext? current = parentContext;
    while (current != null) {
      if (current.variables.containsKey(name)) {
        return current.variables[name];
      }
      current = current.parentContext;
    }
    
    return null;
  }
  
  /// Expand variables in a string, searching up the context chain.
  String expandVariables(String text) {
    String result = text;
    
    // Collect all variables from the entire context chain
    final allVariables = <String, String>{};
    ProcessingContext? current = this;
    while (current != null) {
      allVariables.addAll(current.variables);
      current = current.parentContext;
    }
    
    // Expand variables (local scope takes precedence)
    allVariables.forEach((name, value) {
      result = result.replaceAll('\$$name', value);
    });
    
    return result;
  }
  
  /// Get the global context (root of the context chain).
  ProcessingContext get globalContext {
    ProcessingContext? current = this;
    while (current!.parentContext != null) {
      current = current.parentContext;
    }
    return current;
  }
}

/// Handler for specific command types.
abstract class CommandHandler {
  /// Handle a command with the given context.
  void handle(Command command, ProcessingContext context);
  
  /// Get the command name this handler processes.
  String get commandName;
}

/// Handler for specific block types.
abstract class BlockHandler {
  /// Handle a block with the given context.
  void handle(Block block, ProcessingContext context);
  
  /// Get the block type this handler processes.
  String get blockType;
}

/// Error handler for processing errors.
abstract class ErrorHandler {
  /// Handle a processing error.
  void handleError(dynamic error, ProcessingContext context);
}

/// Main configuration processor that orchestrates the state machine.
class ConfigProcessor {
  final ProcessingContext _context = ProcessingContext();
  final List<ProcessorState> _stateStack = [];
  final List<ProcessingContext> _contextStack = [];
  
  /// Current processing state.
  ProcessorState get currentState => _stateStack.isNotEmpty 
      ? _stateStack.last 
      : InitialState();
  
  /// Current processing context.
  ProcessingContext get context => _contextStack.isNotEmpty 
      ? _contextStack.last 
      : _context;
  
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
  void process(Config config) {
    _context.currentState = currentState;
    for (final element in config.statements) {
      try {
        currentState.process(element, this);
      } catch (e) {
        _context.errorHandler?.handleError(e, _context);
        // Continue processing other elements
      }
    }
  }
  
  /// Register a command handler.
  void registerCommandHandler(CommandHandler handler) {
    _context.commandHandlers[handler.commandName] = handler;
  }
  
  /// Register a block handler.
  void registerBlockHandler(BlockHandler handler) {
    _context.blockHandlers[handler.blockType] = handler;
  }
  
  /// Set the error handler.
  void setErrorHandler(ErrorHandler handler) {
    _context.errorHandler = handler;
  }
}

/// Initial processing state.
class InitialState extends ProcessorState {
  InitialState();
  
  @override
  String get stateName => 'Initial';
  
  @override
  void process(ConfigElement element, ConfigProcessor processor) {
    switch (element) {
      case Config config:
        // Process all statements in the config
        for (final statement in config.statements) {
          process(statement, processor);
        }
        break;
      case Assignment assignment:
        processor.pushState(AssignmentProcessingState());
        processor.currentState.process(assignment, processor);
        processor.popState();
        break;
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
      case Comment _:
        // Comments are typically ignored during processing
        break;
    }
  }
}

/// State for processing commands.
class CommandProcessingState extends ProcessorState {
  @override
  String get stateName => 'CommandProcessing';
  
  @override
  void process(ConfigElement element, ConfigProcessor processor) {
    if (element is Command) {
      final command = element;
      
      // Check for registered command handler
      final handler = processor.context.commandHandlers[command.head];
      if (handler != null) {
        handler.handle(command, processor.context);
        return;
      }
      
      // Default command processing
      _processDefaultCommand(command, processor);
    }
  }
  
  void _processDefaultCommand(Command command, ConfigProcessor processor) {
    switch (command.head) {
      case 'set':
        _processSetCommand(command, processor);
        break;
      case 'include':
        _processIncludeCommand(command, processor);
        break;
      case 'bindsym':
      case 'bindcode':
        _processBindingCommand(command, processor);
        break;
      case 'assign':
        _processAssignCommand(command, processor);
        break;
      case 'for_window':
        _processForWindowCommand(command, processor);
        break;
      default:
        _processGenericCommand(command, processor);
    }
  }
  
  void _processSetCommand(Command command, ConfigProcessor processor) {
    if (command.args.length >= 2) {
      final varRef = command.args[0];
      final value = command.args[1];
      
      if (varRef is VariableRef) {
        final varName = varRef.name;
        final varValue = _expandValue(value, processor.context);
        processor.context.setVariable(varName, varValue);
      }
    }
  }
  
  void _processIncludeCommand(Command command, ConfigProcessor processor) {
    // Include processing would typically load and process another config file
    // This is a placeholder for the actual implementation
    if (command.args.isNotEmpty) {
      final _ = _expandValue(command.args[0], processor.context);
      // TODO: Load and process included file
    }
  }
  
  void _processBindingCommand(Command command, ConfigProcessor processor) {
    // Binding commands would typically register key bindings
    // This is a placeholder for the actual implementation
    if (command.args.length >= 2) {
      _expandValue(command.args[0], processor.context);
      _expandValue(command.args[1], processor.context);
      // TODO: Register key binding
    }
  }
  
  void _processAssignCommand(Command command, ConfigProcessor processor) {
    // Assignment commands would typically assign values to variables
    // This is a placeholder for the actual implementation
    if (command.args.length >= 3) {
      final _ = _expandValue(command.args[0], processor.context);
      final _ = _expandValue(command.args[1], processor.context);
      final _ = _expandValue(command.args[2], processor.context);
      // TODO: Process assignment
    }
  }
  
  void _processForWindowCommand(Command command, ConfigProcessor processor) {
    // For window commands would typically set up window-specific rules
    // This is a placeholder for the actual implementation
    if (command.criteria != null) {
      // TODO: Process window criteria and actions
    }
  }
  
  void _processGenericCommand(Command command, ConfigProcessor processor) {
    // Generic command processing - could be extended for specific commands
    // This is a placeholder for the actual implementation
    final _ = command.args.map((arg) => _expandValue(arg, processor.context)).toList();
    // TODO: Process generic command
  }
  
  String _expandValue(Value value, ProcessingContext context) {
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
  void process(ConfigElement element, ConfigProcessor processor) {
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
  
  void _processDirectAssignment(Assignment assignment, ConfigProcessor processor) {
    // Direct assignment logic - could be used for configuration variables
    // This is a placeholder for future assignment processing
    final expandedValues = assignment.values.map((value) => _expandValue(value, processor.context)).toList();
    // TODO: Store assignment in appropriate context
    print('Assignment: ${assignment.variable} = ${expandedValues.join(' ')}');
  }
  
  void _processAppendAssignment(Assignment assignment, ConfigProcessor processor) {
    // Append assignment logic - commonly used for arrays
    // This is a placeholder for future assignment processing
    final expandedValues = assignment.values.map((value) => _expandValue(value, processor.context)).toList();
    // TODO: Append to existing variable or create new array
    print('Append assignment: ${assignment.variable} += ${expandedValues.join(' ')}');
  }
  
  String _expandValue(Value value, ProcessingContext context) {
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
  void process(ConfigElement element, ConfigProcessor processor) {
    if (element is Block) {
      final block = element;
      
      // Check for registered block handler
      final handler = processor.context.blockHandlers[block.blockType ?? 'generic'];
      if (handler != null) {
        handler.handle(block, processor.context);
        return;
      }
      
      // Default block processing
      _processDefaultBlock(block, processor);
    }
  }
  
  void _processDefaultBlock(Block block, ConfigProcessor processor) {
    // Push new context for block processing (creates child context)
    processor.pushContext();
    
    try {
      // Process block contents in the block's context
      for (final element in block.body) {
        processor.pushState(InitialState());
        processor.currentState.process(element, processor);
        processor.popState();
      }
    } finally {
      // Pop context when done with block
      processor.popContext();
    }
  }
}
