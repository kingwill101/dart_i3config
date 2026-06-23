/// PetitParser-based parser for i3/Sway configuration files.
///
/// This module provides the main parser implementation using the comprehensive
/// grammar specification with enhanced error reporting and line continuation support.
library;

import 'parse_result.dart' show ParseResult;
import 'ast.dart';
import 'grammar.dart';

/// Main parser class for i3/Sway configuration files.
class Parser {
  /// Parse configuration content into an AST.
  ///
  /// This method preprocesses the content to handle line continuations,
  /// then parses it using the comprehensive grammar.
  ///
  /// Throws [ParseError] if parsing fails, with precise location information.
  Config parse(String configContent, {Uri? url}) {
    try {
      final grammar = Grammar(configContent, url: url);
      // First pass: line-continuation (backslash-newline joining).
      // Grammar.parse() handles blank-line removal internally.
      final preprocessed = grammar.preprocess(configContent);
      return grammar.parse(preprocessed);
    } catch (e) {
      if (e is ParseError) {
        rethrow;
      } else {
        throw ParseError('Unexpected error during parsing: $e', 1, 1);
      }
    }
  }

  /// Parse configuration content with detailed error information.
  ///
  /// Returns a result object that contains either the parsed configuration
  /// or detailed error information including suggestions for fixing issues.
  ParseResult parseWithDetails(String configContent, {Uri? url}) {
    try {
      final grammar = Grammar(configContent, url: url);
      final preprocessed = grammar.preprocess(configContent);
      final config = grammar.parse(preprocessed);
      return ParseResult.success(config);
    } catch (e) {
      if (e is ParseError) {
        return ParseResult.failure(e, _suggestFix(e.message));
      }
      return ParseResult.failure(
        ParseError('Unexpected error during parsing: $e', 1, 1),
        null,
      );
    }
  }

  /// Generate suggestions for fixing parse errors.
  String? _suggestFix(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('missing closing')) {
      return 'Add the missing closing character indicated in the error.';
    } else if (normalized.contains('expected')) {
      return 'Check syntax around the error location. Common issues include missing quotes, brackets, or semicolons.';
    } else if (normalized.contains('unexpected')) {
      return 'Remove or fix the unexpected character or token.';
    } else if (normalized.contains('end of input')) {
      return 'Configuration file appears to be incomplete. Check for missing closing brackets or quotes.';
    }
    return null;
  }
}
