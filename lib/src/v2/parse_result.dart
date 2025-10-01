import 'ast.dart' show Config, ParseError;

/// Result of a parsing operation.
sealed class ParseResult {
  const ParseResult();
  
  /// Create a successful result.
  factory ParseResult.success(Config config) = ParseSuccess;
  
  /// Create a failed result.
  factory ParseResult.failure(ParseError error, String? suggestion) = ParseFailure;
  
  /// Whether the parsing was successful.
  bool get isSuccess;
  
  /// Whether the parsing failed.
  bool get isFailure => !isSuccess;
}

/// Successful parse result.
class ParseSuccess extends ParseResult {
  final Config config;
  
  const ParseSuccess(this.config);
  
  @override
  bool get isSuccess => true;
}

/// Failed parse result.
class ParseFailure extends ParseResult {
  final ParseError error;
  final String? suggestion;
  
  const ParseFailure(this.error, this.suggestion);
  
  @override
  bool get isSuccess => false;
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Parse failed: ${error.toString()}');
    if (suggestion != null) {
      buffer.writeln('Suggestion: $suggestion');
    }
    return buffer.toString();
  }
}
