import 'dart:async';

import 'package:i3config/src/ast.dart' show Block;
import 'package:i3config/src/context.dart';
import 'package:i3config/src/value.dart';

/// Mixin that provides value expansion utility for handlers.
mixin ValueExpander {
  /// Helper method to expand a value by resolving variables.
  /// This is a common operation in handlers.
  String expandValue(Value value, Context context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
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
}

/// Provides default automatic child processing.
/// Mix this in for standard sequential processing (most common case).
mixin DefaultChildProcessing {
  FutureOr<void>? processChildren(Block block, Context context) {
    return null; // Automatic sequential processing
  }
}
