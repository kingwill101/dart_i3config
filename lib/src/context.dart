import 'package:i3config/src/handlers.dart';
import 'package:i3config/src/state.dart';
import 'package:i3config/src/value.dart'
    show
        Value,
        Quoted,
        TripleQuoted,
        VariableRef,
        BareArg,
        ArrayValue,
        InterpolatedString,
        ValueSegmentLiteral,
        ValueSegmentVariableReference,
        BlockReference;
import 'package:source_span/source_span.dart';

/// Hook for intercepting variable operations on a [Context].
///
/// Implement this to add cross-cutting behavior around variable lifecycle:
/// - **Redaction** — mask sensitive values in logs, output, or interpolation
/// - **Transformation** — normalize, encrypt, or derive values on set/get
/// - **Validation** — reject values that don't meet criteria
/// - **Audit logging** — track reads, writes, and expansions
/// - **Cache invalidation** — react to variable changes
///
/// Multiple middleware are chained in registration order. Any middleware
/// can short-circuit by returning `null` (reject set/get) or `null` from
/// `onExpand` (skip expansion of the text).
///
/// Example — sensitive value redaction in expand output:
/// ```dart
/// class SensitiveMiddleware implements VariableMiddleware {
///   final Set<String> _keys;
///
///   SensitiveMiddleware(this._keys);
///
///   @override
///   dynamic onSet(String name, dynamic value, Context ctx) => value;
///
///   @override
///   dynamic onGet(String name, dynamic value, Context ctx) => value;
///
///   @override
///   String? onExpand(String text, Context ctx) {
///     // Replace variable references before substitution.
///     for (final key in _keys) {
///       text = text.replaceAll('\$$key', '<SENSITIVE>');
///     }
///     return text;
///   }
/// }
/// ```
abstract class VariableMiddleware {
  /// Called before a value is stored. Return the value to store, or `null`
  /// to reject the set operation.
  dynamic onSet(String name, dynamic value, Context context);

  /// Called after a value is retrieved. Return the value to return to the
  /// caller, or `null` to block access.
  dynamic onGet(String name, dynamic value, Context context);

  /// Called before variable expansion in a string. Return the modified
  /// text to expand, or `null` to skip expansion entirely.
  String? onExpand(String text, Context context);
}

/// Context object that holds processing state and configuration.
class Context {
  /// Variables defined during processing (e.g., from 'set' commands).
  /// Values can be `String`, `List<String>`, or other dynamic types.
  final Map<String, dynamic> variables = {};

  /// Current processing state.
  ProcessorState? currentState;

  /// Current block type being processed (null if at global scope).
  String? currentBlockType;

  /// Current block identifier being processed (null if not applicable).
  /// Set by the processor before calling block handlers so handlers can
  /// access the command-level identifier (e.g., host name) during their
  /// lifecycle (handle, processChildren, afterChildrenProcessed).
  String? currentBlockIdentifier;

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

  /// Registered variable middleware, run in order.
  final List<VariableMiddleware> _variableMiddleware = [];

  /// Create a new processing context.
  Context({this.parentContext, this.errorHandler});

  /// Register a [VariableMiddleware] to intercept variable operations.
  void registerVariableMiddleware(VariableMiddleware middleware) {
    _variableMiddleware.add(middleware);
  }

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
  /// Runs through registered [VariableMiddleware.onSet] hooks.
  /// Value can be `String`, `List<String>`, or other dynamic types.
  void setVariable(String name, dynamic value) {
    var result = value;
    for (final mw in _variableMiddleware) {
      result = mw.onSet(name, result, this);
      if (result == null) return;
    }
    variables[name] = result;
  }

  /// Get a variable value, searching up the context chain.
  /// Runs through registered [VariableMiddleware.onGet] hooks from both
  /// the source context (where the variable is defined) and the requesting
  /// context (where the variable is accessed).
  /// Returns the raw value (`String`, `List<String>`, etc.).
  dynamic getVariable(String name) {
    // First check current context
    if (variables.containsKey(name)) {
      var result = variables[name];
      for (final mw in _variableMiddleware) {
        result = mw.onGet(name, result, this);
        if (result == null) return null;
      }
      return result;
    }

    // Then check parent contexts
    Context? current = parentContext;
    while (current != null) {
      if (current.variables.containsKey(name)) {
        var result = current.variables[name];
        for (final mw in current._variableMiddleware) {
          result = mw.onGet(name, result, current);
          if (result == null) return null;
        }
        for (final mw in _variableMiddleware) {
          result = mw.onGet(name, result, this);
          if (result == null) return null;
        }
        return result;
      }
      current = current.parentContext;
    }

    return null;
  }

  /// Expand variables in a string, searching up the context chain.
  /// Runs through registered [VariableMiddleware.onExpand] hooks.
  String expandVariables(String text) {
    String result = text;

    // Apply expansion middleware before variable substitution
    for (final mw in _variableMiddleware) {
      final expanded = mw.onExpand(result, this);
      if (expanded == null) return result;
      result = expanded;
    }

    // Collect all variable names from the entire context chain.
    final allNames = <String>{};
    Context? current = this;
    while (current != null) {
      allNames.addAll(current.variables.keys);
      current = current.parentContext;
    }

    if (allNames.isEmpty) return result;

    final names = allNames.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp(
      r'\$(' + names.map(RegExp.escape).join('|') + r')(?![a-zA-Z0-9_])',
    );
    result = result.replaceAllMapped(pattern, (m) {
      final key = m.group(1)!;
      final val = getVariable(key);
      if (val == null) return m.group(0) ?? '';
      return _valueToString(val);
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

  /// Expand a [Value] by resolving variables in this context.
  /// This is the public equivalent of the internal `_expandValue` helpers
  /// found in state.dart, base_handlers.dart, and mixin.dart.
  String expandValue(Value value) {
    switch (value) {
      case Quoted quoted:
        return expandVariables(quoted.value);
      case TripleQuoted triple:
        return triple.value;
      case VariableRef varRef:
        final resolved = getVariable(varRef.name);
        if (resolved != null) return resolved;
        if (reportUnresolvedVariables) {
          reportError('Unknown variable: \$${varRef.name}', span: varRef.span);
        }
        return '\$${varRef.name}';
      case BareArg bareArg:
        return expandVariables(bareArg.value);
      case ArrayValue array:
        return array.items.map((v) => expandValue(v)).join(', ');
      case InterpolatedString interpolated:
        return _expandInterpolatedString(interpolated);
      case BlockReference blockRef:
        return resolveBlockReference(blockRef);
    }
  }

  String _expandInterpolatedString(InterpolatedString str) {
    final buffer = StringBuffer();
    for (final seg in str.segments) {
      if (seg is ValueSegmentLiteral) {
        buffer.write(seg.text);
      } else if (seg is ValueSegmentVariableReference) {
        final resolved = getVariable(seg.name);
        if (resolved is List) {
          buffer.writeAll(resolved, ' ');
        } else if (resolved != null) {
          buffer.write(resolved);
        } else {
          if (reportUnresolvedVariables) {
            reportError('Unknown variable: \$${seg.name}', span: null);
          }
          buffer.write('\$${seg.name}');
        }
      }
    }
    return buffer.toString();
  }

  /// Get a variable with a specific type, returning null if not set or wrong type.
  /// Goes through [VariableMiddleware.onGet] hooks.
  T? getVariableAs<T>(String name) => getVariable(name) as T?;

  /// Get a string variable, returning [defaultValue] if not set or wrong type.
  /// Goes through [VariableMiddleware.onGet] hooks.
  String getString(String name, [String defaultValue = '']) {
    final val = getVariable(name);
    if (val is String) return val;
    return defaultValue;
  }

  /// Get an integer variable from a numeric string or int value.
  /// Goes through [VariableMiddleware.onGet] hooks.
  int? getInt(String name) {
    final val = getVariable(name);
    if (val is int) return val;
    if (val is String) return int.tryParse(val);
    return null;
  }

  /// Get a double variable from a numeric string or double value.
  /// Goes through [VariableMiddleware.onGet] hooks.
  double? getDouble(String name) {
    final val = getVariable(name);
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  /// Get a list variable as `List<String>`, returning empty list if not set.
  /// Goes through [VariableMiddleware.onGet] hooks.
  List<String> getList(String name) {
    final val = getVariable(name);
    if (val is List) return val.map((e) => e.toString()).toList();
    return const [];
  }

  /// Get a boolean variable from common true/false string representations.
  /// Goes through [VariableMiddleware.onGet] hooks.
  bool getBool(String name, [bool defaultValue = false]) {
    final val = getVariable(name);
    if (val is bool) return val;
    if (val is String) {
      switch (val.toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
        case 'on':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'off':
          return false;
      }
    }
    return defaultValue;
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

  /// Get properties of a registered block by type and identifier.
  ///
  /// Returns `null` if no block of [type] with the given [identifier] exists.
  /// The identifier can be `null` for blocks without an explicit identifier.
  Map<String, dynamic>? getChildBlock(String type, String? identifier) {
    return blockRegistry[type]?[identifier];
  }

  /// Get all registered blocks of a given [type].
  ///
  /// Returns a list of property maps for every block of the given type.
  /// Returns an empty list if no blocks of that type are registered.
  /// Each element is the property map that was passed to [registerBlock].
  List<Map<String, dynamic>> getAllBlocks(String type) {
    final entries = blockRegistry[type];
    if (entries == null) return const [];
    return entries.values.where((e) => e.isNotEmpty).toList();
  }

  /// Count how many blocks of a given [type] have been registered.
  ///
  /// Returns the number of non-empty block entries of the given type.
  /// Returns 0 if no blocks of that type are registered.
  int countBlock(String type) {
    final entries = blockRegistry[type];
    if (entries == null) return 0;
    return entries.values.where((e) => e.isNotEmpty).length;
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
