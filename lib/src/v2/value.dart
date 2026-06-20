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

  /// Create from JSON representation.
  static Value fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'Quoted':
        return Quoted.fromJson(json);
      case 'VariableRef':
        return VariableRef.fromJson(json);
      case 'BareArg':
        return BareArg.fromJson(json);
      default:
        throw Exception('Unknown Value type: ${json['type']}');
    }
  }
}

/// Quoted string value
class Quoted extends Value {
  final String value;
  final String quoteChar; // '"' or "'"

  Quoted(this.value, this.quoteChar, [super.span]);

  @override
  String toString() => 'Quoted($quoteChar$value$quoteChar)';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Quoted',
    'value': value,
    'quoteChar': quoteChar,
  };

  factory Quoted.fromJson(Map<String, dynamic> json) =>
      Quoted(json['value'], json['quoteChar']);
}

/// Variable reference: `$variable`
class VariableRef extends Value {
  final String name;

  VariableRef(this.name, [super.span]);

  @override
  String toString() => 'VariableRef(\$$name)';

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
  Map<String, dynamic> toJson() => {'type': 'BareArg', 'value': value};

  factory BareArg.fromJson(Map<String, dynamic> json) => BareArg(json['value']);
}
