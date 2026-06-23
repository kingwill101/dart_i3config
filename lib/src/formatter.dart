import 'ast.dart';

/// Options for configuring the [ConfigFormatter].
class FormatterOptions {
  /// Number of spaces per indentation level.
  final int indent;

  /// Whether to sort assignments alphabetically within their parent context.
  final bool sortAssignments;

  /// Whether to add a trailing newline at the end of the output.
  final bool trailingNewline;

  const FormatterOptions({
    this.indent = 2,
    this.sortAssignments = false,
    this.trailingNewline = true,
  });
}

/// Formats an i3 config AST back to formatted config text.
class ConfigFormatter {
  final FormatterOptions options;
  final StringBuffer _buffer = StringBuffer();

  ConfigFormatter({FormatterOptions? options})
    : options = options ?? const FormatterOptions();

  /// Formats [config] and returns the formatted config text.
  String format(Config config) {
    _buffer.clear();
    _writeElements(config.statements, 0);
    if (options.trailingNewline) {
      _buffer.writeln();
    }
    return _buffer.toString();
  }

  void _writeElements(List<ConfigElement> elements, int depth) {
    final indent = ' ' * (depth * options.indent);
    final statements = _maybeSort(elements);

    for (final element in statements) {
      switch (element) {
        case Assignment a:
          _writeAssignment(a, indent);
        case Command c:
          _writeCommand(c, depth);
        case Block b:
          _writeBlock(b, depth);
        case Comment c:
          _writeComment(c, indent);
        case Config _:
      }
    }
  }

  List<ConfigElement> _maybeSort(List<ConfigElement> elements) {
    if (!options.sortAssignments) return elements;
    final result = List<ConfigElement>.from(elements);
    final indices = <int>[];
    final assignments = <Assignment>[];
    for (var i = 0; i < result.length; i++) {
      if (result[i] is Assignment) {
        indices.add(i);
        assignments.add(result[i] as Assignment);
      }
    }
    assignments.sort((a, b) => a.variable.compareTo(b.variable));
    for (var i = 0; i < indices.length; i++) {
      result[indices[i]] = assignments[i];
    }
    return result;
  }

  void _trailingInline(String? trailing) {
    if (trailing != null) _buffer.write('  $trailing');
    _buffer.writeln();
  }

  void _writeAssignment(Assignment assignment, String indent) {
    _buffer.write('$indent${assignment.variable} ${assignment.operator}');
    for (final value in assignment.values) {
      _buffer.write(' ${value.toConfigString()}');
    }
    _trailingInline(assignment.trailingComment);
  }

  void _writeCommand(Command command, int depth) {
    final indent = ' ' * (depth * options.indent);
    _buffer.write(indent);

    if (command.block != null) {
      final block = command.block!;
      if (block.blockType != null) {
        _buffer.write(block.blockType!);
      }
      if (block.identifier != null) {
        _buffer.write(' ${block.identifier!.toConfigString()}');
      }
      _buffer.writeln(' {');
      _writeElements(block.body, depth + 1);
      _buffer.writeln('$indent}');
      return;
    }

    _buffer.write(command.head);

    if (command.criteria != null && command.criteria!.isNotEmpty) {
      _buffer.write(' [');
      for (var i = 0; i < command.criteria!.length; i++) {
        if (i > 0) _buffer.write(' ');
        final c = command.criteria![i];
        _buffer.write('${c.key}=${c.value.toConfigString()}');
      }
      _buffer.write(']');
    }

    for (final arg in command.args) {
      _buffer.write(' ${arg.toConfigString()}');
    }
    _trailingInline(command.trailingComment);
  }

  void _writeBlock(Block block, int depth) {
    final indent = ' ' * (depth * options.indent);
    _buffer.write(indent);
    if (block.blockType != null) {
      _buffer.write(block.blockType!);
    }
    if (block.identifier != null) {
      _buffer.write(' ${block.identifier!.toConfigString()}');
    }
    _buffer.writeln(' {');
    _writeElements(block.body, depth + 1);
    _buffer.writeln('$indent}');
  }

  void _writeComment(Comment comment, String indent) {
    _buffer.writeln('$indent${comment.content}');
  }
}
