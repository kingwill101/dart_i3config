import 'package:source_span/source_span.dart' show SourceSpan;

/// Base class for all values
sealed class Value {
  /// Source span for this value (optional for backwards compatibility)
  SourceSpan? span;

  Value([this.span]);

  /// Set the source span for this value
  void setSpan(SourceSpan span) => this.span = span;

  /// Convert to JSON representation.
  Map<String, dynamic> toJson();

  /// Format this value as it would appear in an i3 config file.
  String toConfigString();

  /// Create from JSON representation.
  static Value fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'Quoted':
        return Quoted.fromJson(json);
      case 'VariableRef':
        return VariableRef.fromJson(json);
      case 'BareArg':
        return BareArg.fromJson(json);
      case 'ArrayValue':
        return ArrayValue.fromJson(json);
       case 'InterpolatedString':
         return InterpolatedString.fromJson(json);
       case 'BlockReference':
         return BlockReference.fromJson(json);
       case 'TripleQuoted':
         return TripleQuoted.fromJson(json);
       default:
         throw Exception('Unknown Value type: ${json['type']}');
    }
  }
}

/// Array value: `["a", "b", "c"]`
class ArrayValue extends Value {
  final List<Value> items;

  ArrayValue(this.items, [super.span]);

  @override
  String toString() =>
      'ArrayValue([${items.map((v) => v.toString()).join(', ')}])';

  @override
  String toConfigString() =>
      '[${items.map((v) => v.toConfigString()).join(', ')}]';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ArrayValue',
    'items': items.map((v) => v.toJson()).toList(),
  };

  factory ArrayValue.fromJson(Map<String, dynamic> json) => ArrayValue(
    (json['items'] as List).map((v) => Value.fromJson(v)).toList(),
  );
}

/// Quoted string value
class Quoted extends Value {
  final String value;
  final String quoteChar; // '"' or "'"

  Quoted(this.value, this.quoteChar, [super.span]);

  @override
  String toString() => 'Quoted($quoteChar$value$quoteChar)';

  @override
  String toConfigString() {
    final escaped = value
        .replaceAll('\\', '\\\\')
        .replaceAll(quoteChar, '\\$quoteChar');
    return '$quoteChar$escaped$quoteChar';
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Quoted',
    'value': value,
    'quoteChar': quoteChar,
  };

  factory Quoted.fromJson(Map<String, dynamic> json) =>
      Quoted(json['value'], json['quoteChar']);
}

/// Triple-quoted string value (multi-line literal).
///
/// Supports both `"""..."""` and `'''...'''` delimiters.
/// Content is taken literally — no escape sequence processing.
class TripleQuoted extends Value {
  final String value;
  final String delimiter; // '"""' or "'''"

  TripleQuoted(this.value, this.delimiter, [super.span]);

  @override
  String toString() => 'TripleQuoted($delimiter$value$delimiter)';

  @override
  String toConfigString() => '$delimiter$value$delimiter';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'TripleQuoted',
    'value': value,
    'delimiter': delimiter,
  };

  factory TripleQuoted.fromJson(Map<String, dynamic> json) =>
      TripleQuoted(json['value'], json['delimiter']);
}

/// Variable reference: `$variable`
class VariableRef extends Value {
  final String name;

  VariableRef(this.name, [super.span]);

  @override
  String toString() => 'VariableRef(\$$name)';

  @override
  String toConfigString() => '\$$name';

  @override
  Map<String, dynamic> toJson() => {'type': 'VariableRef', 'name': name};

  factory VariableRef.fromJson(Map<String, dynamic> json) =>
      VariableRef(json['name']);
}

/// Bare argument (unquoted value)
class BareArg extends Value {
  final String value;

  BareArg(this.value, [super.span]);

  @override
  String toString() => 'BareArg($value)';

  @override
  String toConfigString() => value;

  @override
  Map<String, dynamic> toJson() => {'type': 'BareArg', 'value': value};

  factory BareArg.fromJson(Map<String, dynamic> json) => BareArg(json['value']);
}

/// Segment inside an interpolated string.
sealed class ValueSegment {
  const ValueSegment();

  /// Format this segment for config serialization.
  String toConfigString();

  /// Convert to JSON representation.
  Map<String, dynamic> toJson();

  /// Create from JSON representation.
  factory ValueSegment.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'Literal':
        return ValueSegmentLiteral.fromJson(json);
      case 'VariableReference':
        return ValueSegmentVariableReference.fromJson(json);
      default:
        throw Exception('Unknown ValueSegment type: ${json['type']}');
    }
  }
}

/// Literal text segment inside an [InterpolatedString].
class ValueSegmentLiteral extends ValueSegment {
  final String text;

  const ValueSegmentLiteral(this.text);

  @override
  String toString() => 'Literal($text)';

  @override
  String toConfigString() => _escapeForDoubleQuote(text);

  @override
  Map<String, dynamic> toJson() => {'type': 'Literal', 'text': text};

  factory ValueSegmentLiteral.fromJson(Map<String, dynamic> json) =>
      ValueSegmentLiteral(json['text']);
}

/// Variable reference segment inside an [InterpolatedString].
class ValueSegmentVariableReference extends ValueSegment {
  final String name;

  const ValueSegmentVariableReference(this.name);

  @override
  String toString() => 'VariableReference(\$$name)';

  @override
  String toConfigString() => '\$$name';

  @override
  Map<String, dynamic> toJson() => {'type': 'VariableReference', 'name': name};

  factory ValueSegmentVariableReference.fromJson(Map<String, dynamic> json) =>
      ValueSegmentVariableReference(json['name']);
}

/// Double-quoted string with variable interpolation, e.g. `"base/$dir/config"`.
class InterpolatedString extends Value {
  final List<ValueSegment> segments;
  final String quoteChar; // always '"' for interpolated strings

  InterpolatedString(this.segments, this.quoteChar, [super.span]);

  @override
  String toString() =>
      'InterpolatedString($quoteChar${segments.map((s) => s.toString()).join('')}$quoteChar)';

  @override
  String toConfigString() {
    final buffer = StringBuffer();
    buffer.write(quoteChar);
    for (final seg in segments) {
      buffer.write(seg.toConfigString());
    }
    buffer.write(quoteChar);
    return buffer.toString();
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'InterpolatedString',
    'segments': segments.map((s) => s.toJson()).toList(),
    'quoteChar': quoteChar,
  };

  factory InterpolatedString.fromJson(Map<String, dynamic> json) {
    final segments = (json['segments'] as List)
        .map((s) => ValueSegment.fromJson(s as Map<String, dynamic>))
        .toList();
    return InterpolatedString(segments, json['quoteChar']);
  }
}

/// Dotted-path block reference, e.g. `bar.main.position`.
class BlockReference extends Value {
  final List<String> path;

  BlockReference(this.path, [super.span]);

  @override
  String toString() => 'BlockReference(${path.join('.')})';

  @override
  String toConfigString() => path.join('.');

  @override
  Map<String, dynamic> toJson() => {'type': 'BlockReference', 'path': path};

  factory BlockReference.fromJson(Map<String, dynamic> json) =>
      BlockReference((json['path'] as List).cast<String>());
}

/// Escape a raw string for inclusion inside a double-quoted i3 config value.
String _escapeForDoubleQuote(String text) {
  return text
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}
