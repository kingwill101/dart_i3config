import 'package:i3config/src/v2/handlers.dart';
import 'package:i3config/src/v2/state.dart';

/// Context object that holds processing state and configuration.
class Context {
  /// Variables defined during processing (e.g., from 'set' commands).
  /// Values can be String, List&ltString&gt, or other dynamic types.
  final Map<String, dynamic> variables = {};

  /// Current processing state.
  ProcessorState? currentState;

  /// Current block type being processed (null if at global scope).
  String? currentBlockType;

  /// Parent context for scoping (null for global context).
  final Context? parentContext;

  /// Registry of custom command handlers.
  final Map<String, CommandHandler> commandHandlers = {};

  /// Registry of custom block handlers.
  final Map<String, BlockHandler> blockHandlers = {};

  final Map<String, Map<String, CommandHandler>> blockScopedCommandHandlers =
      {};

  /// Registry of block handlers scoped to a parent block type.
  /// Outer key = parent block type, inner key = child block type.
  final Map<String, Map<String, BlockHandler>> blockScopedBlockHandlers = {};

  /// Processing options and flags.
  final Map<String, dynamic> options = {};

  /// Error handler for processing errors.
  ErrorHandler? errorHandler;

  /// Create a new processing context.
  Context({this.parentContext, this.errorHandler});

  /// Push a new context onto the stack (e.g., when entering a block).
  /// This creates a child context that has access to parent variables.
  Context pushContext() {
    return Context(parentContext: this, errorHandler: errorHandler);
  }

  /// Set a variable value in the current scope.
  /// Value can be String, List&lt;String&gt;, or other dynamic types.
  void setVariable(String name, dynamic value) {
    variables[name] = value;
  }

  /// Get a variable value, searching up the context chain.
  /// Returns the raw value (String, List&lt;String&gt;, etc.).
  dynamic getVariable(String name) {
    // First check current context
    if (variables.containsKey(name)) {
      return variables[name];
    }

    // Then check parent contexts
    Context? current = parentContext;
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

    // Collect all variables from the entire context chain.
    // Parent contexts are added first so that child (local) values
    // take precedence when they share a key.
    final allVariables = <String, String>{};
    Context? current = this;
    // Walk to the root first to collect ancestors.
    final chain = <Context>[];
    while (current != null) {
      chain.add(current);
      current = current.parentContext;
    }
    // Apply from root to leaf so local scope wins.
    for (final ctx in chain.reversed) {
      ctx.variables.forEach((name, value) {
        allVariables[name] = _valueToString(value);
      });
    }

    // Expand variables (local scope takes precedence)
    allVariables.forEach((name, value) {
      result = result.replaceAll('\$$name', value);
    });

    return result;
  }

  /// Convert a dynamic value to a string representation.
  String _valueToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) return value.join(' ');
    return value.toString();
  }

  /// Get the global context (root of the context chain).
  Context get globalContext {
    Context? current = this;
    while (current!.parentContext != null) {
      current = current.parentContext;
    }
    return current;
  }
}
