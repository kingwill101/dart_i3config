import 'dart:async';
import 'package:i3config/src/context.dart' show Context;
import 'package:i3config/src/handlers.dart';
import 'package:i3config/src/value.dart';

import 'ast.dart';

/// Base class for command handlers with built-in value expansion.
///
/// Provides default implementations for common operations:
/// - Value expansion (no mixin needed)
/// - Type-safe argument extraction
/// - Error handling
/// - Optional return value support
abstract class BaseCommandHandler<T> implements CommandHandler {
  /// Get the command name this handler processes.
  @override
  String get commandName;

  /// Handle a command with the given context.
  /// Override this method to implement command-specific logic.
  /// Can return a value of type T, or null for no return value.
  @override
  FutureOr<T?> handle(Command command, Context context);

  /// Expand a value by resolving variables.
  /// Built-in - no mixin required!
  String expandValue(Value value, Context context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
      case TripleQuoted triple:
        return triple.value;
      case VariableRef varRef:
        final resolved = context.getVariable(varRef.name);
        if (resolved != null) return resolved;
        if (context.reportUnresolvedVariables) {
          context.reportError(
            'Unknown variable: \$${varRef.name}',
            span: varRef.span,
          );
        }
        return '\$${varRef.name}';
      case BareArg bareArg:
        return context.expandVariables(bareArg.value);
      case ArrayValue array:
        return array.items.map((v) => expandValue(v, context)).join(', ');
      case InterpolatedString interpolated:
        return _expandInterpolatedString(interpolated, context);
      case BlockReference blockRef:
        return context.resolveBlockReference(blockRef);
    }
  }

  String _expandInterpolatedString(InterpolatedString str, Context context) {
    final buffer = StringBuffer();
    for (final seg in str.segments) {
      if (seg is ValueSegmentLiteral) {
        buffer.write(seg.text);
      } else if (seg is ValueSegmentVariableReference) {
        final resolved = context.getVariable(seg.name);
        if (resolved is List) {
          buffer.writeAll(resolved, ' ');
        } else if (resolved != null) {
          buffer.write(resolved);
        } else {
          if (context.reportUnresolvedVariables) {
            context.reportError('Unknown variable: \$${seg.name}', span: null);
          }
          buffer.write('\$${seg.name}');
        }
      }
    }
    return buffer.toString();
  }

  /// Get argument as string with variable expansion.
  String getArgAsString(Command command, int index, Context context) {
    if (index >= command.args.length) {
      throw ArgumentError(
        'Command $commandName requires argument at index $index',
      );
    }
    return expandValue(command.args[index], context);
  }

  /// Get argument as integer with variable expansion.
  int getArgAsInt(Command command, int index, Context context) {
    final str = getArgAsString(command, index, context);
    final result = int.tryParse(str);
    if (result == null) {
      throw ArgumentError(
        'Command $commandName argument $index must be an integer, got: $str',
      );
    }
    return result;
  }

  /// Get argument as double with variable expansion.
  double getArgAsDouble(Command command, int index, Context context) {
    final str = getArgAsString(command, index, context);
    final result = double.tryParse(str);
    if (result == null) {
      throw ArgumentError(
        'Command $commandName argument $index must be a number, got: $str',
      );
    }
    return result;
  }

  /// Get argument as boolean with variable expansion.
  bool getArgAsBool(Command command, int index, Context context) {
    final str = getArgAsString(command, index, context).toLowerCase();
    switch (str) {
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
      default:
        throw ArgumentError(
          'Command $commandName argument $index must be a boolean, got: $str',
        );
    }
  }

  /// Get all arguments as strings with variable expansion.
  List<String> getAllArgsAsStrings(Command command, Context context) {
    return command.args.map((arg) => expandValue(arg, context)).toList();
  }
}

/// Base class for block handlers with built-in child processing.
///
/// Provides default implementations for common operations:
/// - Automatic child processing (no mixin needed)
/// - Value expansion
/// - Scoped command registration
abstract class BaseBlockHandler implements BlockHandler {
  /// Get the block type this handler processes.
  @override
  String get blockType;

  /// Handle a block with the given context.
  /// Override this method to implement block-specific logic.
  @override
  FutureOr<void> handle(Block block, Context context);

  /// Register block-scoped command handlers for this block type.
  /// Override this method to register commands that should only be active
  /// within this block type.
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // Default: no scoped commands
  }

  /// Process child elements of the block.
  ///
  /// **Default behavior**: Automatic sequential processing.
  ///
  /// **Override** to customize child processing:
  /// - Filter which children to process
  /// - Reorder children before processing
  /// - Multi-pass processing
  /// - Conditional execution
  ///
  /// Call `super.processChildren()` to get default behavior.
  @override
  FutureOr<void>? processChildren(Block block, Context context) {
    // Default: automatic sequential processing
    return null;
  }

  /// Called after all children have been processed.
  ///
  /// This is useful for accessing properties that were set by child commands
  /// during the default property handling.
  ///
  /// Override this method to perform post-processing actions.
  FutureOr<void> afterChildrenProcessed(Block block, Context context) {
    // Default: no post-processing
  }

  /// Expand a value by resolving variables.
  /// Built-in - no mixin required!
  String expandValue(Value value, Context context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
      case TripleQuoted triple:
        return triple.value;
      case VariableRef varRef:
        final resolved = context.getVariable(varRef.name);
        if (resolved != null) return resolved;
        if (context.reportUnresolvedVariables) {
          context.reportError(
            'Unknown variable: \$${varRef.name}',
            span: varRef.span,
          );
        }
        return '\$${varRef.name}';
      case BareArg bareArg:
        return context.expandVariables(bareArg.value);
      case ArrayValue array:
        return array.items.map((v) => expandValue(v, context)).join(', ');
      case InterpolatedString interpolated:
        return _expandInterpolatedString(interpolated, context);
      case BlockReference blockRef:
        return context.resolveBlockReference(blockRef);
    }
  }

  String _expandInterpolatedString(InterpolatedString str, Context context) {
    final buffer = StringBuffer();
    for (final seg in str.segments) {
      if (seg is ValueSegmentLiteral) {
        buffer.write(seg.text);
      } else if (seg is ValueSegmentVariableReference) {
        final resolved = context.getVariable(seg.name);
        if (resolved is List) {
          buffer.writeAll(resolved, ' ');
        } else if (resolved != null) {
          buffer.write(resolved);
        } else {
          if (context.reportUnresolvedVariables) {
            context.reportError('Unknown variable: \$${seg.name}', span: null);
          }
          buffer.write('\$${seg.name}');
        }
      }
    }
    return buffer.toString();
  }

  /// Get block identifier as string with variable expansion.
  String? getBlockIdentifier(Block block, Context context) {
    if (block.identifier == null) return null;
    return expandValue(block.identifier!, context);
  }

  /// Find commands with specific head in block body.
  List<Command> findCommands(Block block, String commandHead) {
    return block.body
        .whereType<Command>()
        .where((cmd) => cmd.head == commandHead)
        .toList();
  }

  /// Find first command with specific head in block body.
  Command? findFirstCommand(Block block, String commandHead) {
    return block.body
        .whereType<Command>()
        .where((cmd) => cmd.head == commandHead)
        .firstOrNull;
  }
}

/// Extension on Command for ergonomic value extraction.
extension CommandValueExtraction on Command {
  /// Get argument as string with variable expansion.
  String getArgAsString(int index, Context context) {
    if (index >= args.length) {
      throw ArgumentError('Command $head requires argument at index $index');
    }
    return _expandValue(args[index], context);
  }

  /// Get argument as integer with variable expansion.
  int getArgAsInt(int index, Context context) {
    final str = getArgAsString(index, context);
    final result = int.tryParse(str);
    if (result == null) {
      throw ArgumentError(
        'Command $head argument $index must be an integer, got: $str',
      );
    }
    return result;
  }

  /// Get argument as double with variable expansion.
  double getArgAsDouble(int index, Context context) {
    final str = getArgAsString(index, context);
    final result = double.tryParse(str);
    if (result == null) {
      throw ArgumentError(
        'Command $head argument $index must be a number, got: $str',
      );
    }
    return result;
  }

  /// Get argument as boolean with variable expansion.
  bool getArgAsBool(int index, Context context) {
    final str = getArgAsString(index, context).toLowerCase();
    switch (str) {
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
      default:
        throw ArgumentError(
          'Command $head argument $index must be a boolean, got: $str',
        );
    }
  }

  /// Get all arguments as strings with variable expansion.
  List<String> getAllArgsAsStrings(Context context) {
    return args.map((arg) => _expandValue(arg, context)).toList();
  }

  /// Internal helper for value expansion.
  String _expandValue(Value value, Context context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
      case TripleQuoted triple:
        return triple.value;
      case VariableRef varRef:
        final resolved = context.getVariable(varRef.name);
        if (resolved != null) return resolved;
        if (context.reportUnresolvedVariables) {
          context.reportError(
            'Unknown variable: \$${varRef.name}',
            span: varRef.span,
          );
        }
        return '\$${varRef.name}';
      case BareArg bareArg:
        return context.expandVariables(bareArg.value);
      case ArrayValue array:
        return array.items.map((v) => _expandValue(v, context)).join(', ');
      case InterpolatedString interpolated:
        return _expandInterpolatedString(interpolated, context);
      case BlockReference blockRef:
        return context.resolveBlockReference(blockRef);
    }
  }

  String _expandInterpolatedString(InterpolatedString str, Context context) {
    final buffer = StringBuffer();
    for (final seg in str.segments) {
      if (seg is ValueSegmentLiteral) {
        buffer.write(seg.text);
      } else if (seg is ValueSegmentVariableReference) {
        final resolved = context.getVariable(seg.name);
        if (resolved is List) {
          buffer.writeAll(resolved, ' ');
        } else if (resolved != null) {
          buffer.write(resolved);
        } else {
          if (context.reportUnresolvedVariables) {
            context.reportError('Unknown variable: \$${seg.name}', span: null);
          }
          buffer.write('\$${seg.name}');
        }
      }
    }
    return buffer.toString();
  }
}
