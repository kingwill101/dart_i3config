import 'package:i3config/src/handlers.dart';
import 'package:i3config/src/state.dart';
import 'package:i3config/src/value.dart' show BlockReference;
import 'package:source_span/source_span.dart';

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

  /// If true, report warnings for unresolved variable references.
  bool reportUnresolvedVariables = false;

  /// If true, report warnings for unresolved block references.
  bool reportUnresolvedBlockReferences = false;

  /// Create a new processing context.
  Context({this.parentContext, this.errorHandler});

  /// Report an error through the error handler with optional source span.
  void reportError(String message, {SourceSpan? span}) {
    if (errorHandler != null) {
      errorHandler!.handleError(message, this, span: span);
    }
  }

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

    if (allVariables.isEmpty) return result;

    // Sort by length descending to avoid prefix collisions ($mod1 before $mod)
    final names = allVariables.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp(
      r'\$(' + names.map(RegExp.escape).join('|') + r')(?![a-zA-Z0-9_])',
    );
    result = result.replaceAllMapped(pattern, (m) {
      final key = m.group(1)!;
      return allVariables[key]!;
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

  /// Registry of processed block properties, keyed by (blockType, identifier).
  final Map<String, Map<String?, Map<String, dynamic>>> blockRegistry = {};

  /// Register a processed block and its properties.
  void registerBlock(
    String blockType,
    String? identifier,
    Map<String, dynamic> properties,
  ) {
    blockRegistry.putIfAbsent(blockType, () => {})[identifier] = Map.from(
      properties,
    );
  }

  /// Resolve a [BlockReference] against the block registry.
  /// Returns the property value as a string, or empty string if unresolved.
  String resolveBlockReference(BlockReference ref) {
    final path = ref.path;
    if (path.isEmpty) return '';

    final blockType = path.first;

    final typeEntries = blockRegistry[blockType];
    if (typeEntries == null || typeEntries.isEmpty) {
      if (reportUnresolvedBlockReferences) {
        reportError(
          'Unknown block reference: ${ref.toConfigString()}',
          span: ref.span,
        );
      }
      return '';
    }

    if (path.length == 1) {
      return typeEntries.values.map((m) => m.values.join(' ')).join(' ');
    }

    String? identifier;
    List<String> propertyPath;

    if (typeEntries.containsKey(path[1])) {
      identifier = path[1];
      propertyPath = path.length > 2 ? path.sublist(2) : [];
    } else {
      identifier = null;
      propertyPath = path.sublist(1);
    }

    if (identifier != null) {
      final blockProps = typeEntries[identifier];
      if (blockProps == null) {
        if (reportUnresolvedBlockReferences) {
          reportError(
            'Unknown block identifier: ${ref.toConfigString()}',
            span: ref.span,
          );
        }
        return '';
      }
      if (propertyPath.isEmpty) return blockProps.values.join(' ');
      dynamic current = blockProps;
      for (final prop in propertyPath) {
        if (current is Map<String, dynamic>) {
          current = current[prop];
        } else {
          if (reportUnresolvedBlockReferences) {
            reportError(
              'Unknown block property: ${ref.toConfigString()}',
              span: ref.span,
            );
          }
          return '';
        }
        if (current == null) {
          if (reportUnresolvedBlockReferences) {
            reportError(
              'Unknown block property: ${ref.toConfigString()}',
              span: ref.span,
            );
          }
          return '';
        }
      }
      return current.toString();
    }

    for (final entry in typeEntries.values) {
      if (entry.isEmpty) continue;
      dynamic current = entry;
      for (final prop in propertyPath) {
        if (current is Map<String, dynamic>) {
          current = current[prop];
        } else {
          current = null;
          break;
        }
        if (current == null) break;
      }
      if (current != null) return current.toString();
    }

    if (reportUnresolvedBlockReferences) {
      reportError(
        'Unknown block reference: ${ref.toConfigString()}',
        span: ref.span,
      );
    }
    return '';
  }
}
