/// AST (Abstract Syntax Tree) classes for i3/Sway configuration files.
///
/// This module defines a sealed class hierarchy for representing parsed
/// configuration elements with better type safety and exhaustiveness checking.
library;

import 'package:i3config/src/v2/value.dart';
import 'package:source_span/source_span.dart';
import 'parser.dart';

/// Base class for all configuration elements.
sealed class ConfigElement {
  /// Source span for this element (optional for backwards compatibility)
  SourceSpan? span;

  ConfigElement([this.span]);

  /// Set the source span for this element
  void setSpan(SourceSpan span) => this.span = span;

  /// Convert to JSON representation.
  Map<String, dynamic> toJson();

  /// Create from JSON representation.
  static ConfigElement fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'Config':
        return Config.fromJson(json);
      case 'Assignment':
        return Assignment.fromJson(json);
      case 'Block':
        return Block.fromJson(json);
      case 'Command':
        return Command.fromJson(json);
      case 'Comment':
        return Comment.fromJson(json);
      default:
        throw Exception('Unknown ConfigElement type: ${json['type']}');
    }
  }
}

/// Root configuration container.
class Config extends ConfigElement {
  final List<ConfigElement> statements;

  Config(this.statements, [super.span]);

  @override
  String toString() => 'Config(statements: $statements)';

  /// Compatibility property for existing API.
  /// Returns all statements as elements.
  List<ConfigElement> get elements => statements;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Config',
    'statements': statements.map((s) => s.toJson()).toList(),
  };

  factory Config.fromJson(Map<String, dynamic> json) => Config(
    (json['statements'] as List).map((s) => ConfigElement.fromJson(s)).toList(),
  );

  /// Static parse method for backward compatibility.
  static Config parse(String configContent, {Uri? url}) {
    final parser = Parser();
    return parser.parse(configContent, url: url);
  }
}

/// Assignment operators for i3 config variables
enum AssignmentOperator {
  assign('='), // Set value
  append('+='); // Append to existing value

  const AssignmentOperator(this.symbol);
  final String symbol;

  /// Parse operator symbol to enum value
  static AssignmentOperator fromSymbol(String symbol) {
    switch (symbol) {
      case '=':
        return AssignmentOperator.assign;
      case '+=':
        return AssignmentOperator.append;
      default:
        throw ArgumentError('Unknown assignment operator: $symbol');
    }
  }

  @override
  String toString() => symbol;
}

/// Base class for all statements.
sealed class Statement extends ConfigElement {
  Statement([super.span]);
}

/// Assignment statement: `variable = value` or `variable += value`
class Assignment extends Statement {
  final String variable; // Left-hand side (property name, may be dotted)
  final AssignmentOperator operator; // Assignment operator
  final List<Value> values; // Right-hand side values

  /// Inline comment at the end of the line (without `#` prefix).
  String? trailingComment;

  Assignment(this.variable, this.operator, this.values, [super.span]);

  @override
  String toString() =>
      'Assignment(variable: $variable, operator: $operator, values: $values${trailingComment != null ? ', trailing: $trailingComment' : ''})';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Assignment',
    'variable': variable,
    'operator': operator.symbol,
    'values': values.map((v) => v.toJson()).toList(),
    if (trailingComment != null) 'trailingComment': trailingComment,
  };

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    json['variable'],
    AssignmentOperator.fromSymbol(json['operator']),
    (json['values'] as List).map((v) => Value.fromJson(v)).toList(),
  )..trailingComment = json['trailingComment'] as String?;
}

/// Block statement: `{ ... }` with optional type and identifier
class Block extends Statement {
  final String? blockType; // 'mode', 'bar', 'input', 'output', 'seat', etc.
  final Value? identifier;
  final List<ConfigElement> body;

  /// Parent block reference (null if at top level).
  /// This is NOT populated by the parser by default - use buildBlockHierarchy() to establish links.
  Block? parentBlock;

  Block(this.blockType, this.identifier, this.body, [super.span]);

  /// Get all child blocks contained in this block's body.
  /// Returns an empty list if there are no child blocks.
  List<Block> get childBlocks {
    return body.whereType<Block>().toList();
  }

  @override
  String toString() =>
      'Block(type: $blockType, identifier: $identifier, body: $body)';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Block',
    'blockType': blockType,
    'identifier': identifier?.toJson(),
    'body': body.map((b) => b.toJson()).toList(),
  };

  factory Block.fromJson(Map<String, dynamic> json) => Block(
    json['blockType'],
    json['identifier'] != null ? Value.fromJson(json['identifier']) : null,
    (json['body'] as List).map((b) => ConfigElement.fromJson(b)).toList(),
  );
}

/// Generic command statement
class Command extends Statement {
  final String head;
  final List<Value> args;
  final List<Criterion>? criteria;
  final Block? block;

  /// Inline comment at the end of the line (without `#` prefix).
  String? trailingComment;

  Command(this.head, this.args, [this.criteria, this.block, SourceSpan? span])
    : super(span);

  @override
  String toString() =>
      'Command(head: $head, args: $args, criteria: $criteria, block: $block${trailingComment != null ? ', trailing: $trailingComment' : ''})';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Command',
    'head': head,
    'args': args.map((a) => a.toJson()).toList(),
    'criteria': criteria?.map((c) => c.toJson()).toList(),
    'block': block?.toJson(),
    if (trailingComment != null) 'trailingComment': trailingComment,
  };

  factory Command.fromJson(Map<String, dynamic> json) {
    final cmd = Command(
      json['head'],
      (json['args'] as List).map((a) => Value.fromJson(a)).toList(),
      json['criteria'] != null
          ? (json['criteria'] as List).map((c) => Criterion.fromJson(c)).toList()
          : null,
      json['block'] != null ? Block.fromJson(json['block']) : null,
    );
    cmd.trailingComment = json['trailingComment'] as String?;
    return cmd;
  }
}

/// Comment element
class Comment extends ConfigElement {
  final String content;

  Comment(this.content, [super.span]);

  @override
  String toString() => 'Comment(content: $content)';

  @override
  Map<String, dynamic> toJson() => {'type': 'Comment', 'content': content};

  factory Comment.fromJson(Map<String, dynamic> json) =>
      Comment(json['content']);
}

/// Key part for bindings (symbolic or code)
class KeyPart {
  final String value;

  const KeyPart(this.value);

  @override
  String toString() => 'KeyPart($value)';

  Map<String, dynamic> toJson() => {'value': value};

  factory KeyPart.fromJson(Map<String, dynamic> json) => KeyPart(json['value']);
}

/// Criterion for criteria blocks: `key=value`
class Criterion {
  final String key;
  final Value value;

  /// Source span for this criterion (optional for backwards compatibility)
  SourceSpan? span;

  Criterion(this.key, this.value, [this.span]);

  /// Set the source span for this criterion
  void setSpan(SourceSpan span) => this.span = span;

  @override
  String toString() => 'Criterion($key=${value.toString()})';

  Map<String, dynamic> toJson() => {'key': key, 'value': value.toJson()};

  factory Criterion.fromJson(Map<String, dynamic> json) =>
      Criterion(json['key'], Value.fromJson(json['value']));
}

/// Parse error with location information
class ParseError extends Error {
  final String message;
  final int line;
  final int column;
  final String? context;

  ParseError(this.message, this.line, this.column, [this.context]);

  @override
  String toString() => 'ParseError at line $line, column $column: $message';
}

/// Build block hierarchy by establishing parent-child relationships.
///
/// This function traverses the configuration and sets the `parentBlock` field
/// on all nested blocks. By default, blocks parsed from configuration do not
/// have their parent references set for performance reasons.
///
/// Example:
/// ```dart
/// final config = Config.parse(configContent);
/// buildBlockHierarchy(config);
///
/// // Now blocks have parent references
/// final nestedBlock = someBlock;
/// final parent = nestedBlock.parentBlock; // Not null if nested
/// ```
void buildBlockHierarchy(Config config) {
  void linkBlocks(List<ConfigElement> elements, Block? parent) {
    for (final element in elements) {
      if (element is Block) {
        element.parentBlock = parent;
        linkBlocks(element.body, element);
      }
    }
  }

  linkBlocks(config.statements, null);
}
