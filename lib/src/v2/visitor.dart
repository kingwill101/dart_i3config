import 'package:i3config/src/v2/value.dart';

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
