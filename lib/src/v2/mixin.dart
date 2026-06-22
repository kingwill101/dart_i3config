import 'dart:async';

import 'package:i3config/src/v2/ast.dart' show Block;
import 'package:i3config/src/v2/context.dart';
import 'package:i3config/src/v2/value.dart';

/// Mixin that provides value expansion utility for handlers.
mixin ValueExpander {
  /// Helper method to expand a value by resolving variables.
  /// This is a common operation in handlers.
  String expandValue(Value value, Context context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
      case VariableRef varRef:
        return context.getVariable(varRef.name) ?? '\$${varRef.name}';
      case BareArg bareArg:
        return context.expandVariables(bareArg.value);
      case ArrayValue array:
        return array.items.map((v) => expandValue(v, context)).join(', ');
    }
  }
}

/// Provides default automatic child processing.
/// Mix this in for standard sequential processing (most common case).
mixin DefaultChildProcessing {
  FutureOr<void>? processChildren(Block block, Context context) {
    return null; // Automatic sequential processing
  }
}
