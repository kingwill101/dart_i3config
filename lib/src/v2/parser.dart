/// PetitParser-based parser for i3/Sway configuration files.
///
/// This module provides the main parser implementation using the comprehensive
/// grammar specification with enhanced error reporting and line continuation support.
library;

import 'parse_result.dart' show ParseResult;
import 'package:petitparser/petitparser.dart';
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
      // Create grammar with source content for position tracking
      final grammar = Grammar(configContent, url: url);

      // Preprocess to handle line continuations
      final preprocessed = grammar.preprocess(configContent);

      // Parse using the grammar
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
      // Create grammar with source content for position tracking
      final grammar = Grammar(configContent, url: url);

      final preprocessed = grammar.preprocess(configContent);
      final result = grammar.config.end().parse(preprocessed);

      if (result is Success) {
        return ParseResult.success(result.value);
      } else {
        final failure = result as Failure;
        final position = failure.position;
        final lines = preprocessed.substring(0, position).split('\n');
        final line = lines.length;
        final column = lines.last.length + 1;

        return ParseResult.failure(
          ParseError(
            'Parse error: ${failure.message}',
            line,
            column,
            preprocessed.split('\n')[line - 1],
          ),
          _suggestFix(failure.message, position, preprocessed),
        );
      }
    } catch (e) {
      if (e is ParseError) {
        return ParseResult.failure(e, null);
      } else {
        return ParseResult.failure(
          ParseError('Unexpected error during parsing: $e', 1, 1),
          null,
        );
      }
    }
  }

  /// Generate suggestions for fixing parse errors.
  String? _suggestFix(String message, int position, String content) {
    // Simple suggestions based on common error patterns
    final normalized = message.toLowerCase();
    if (normalized.contains('expected')) {
      return 'Check syntax around the error location. Common issues include missing quotes, brackets, or semicolons.';
    } else if (normalized.contains('unexpected')) {
      return 'Remove or fix the unexpected character or token.';
    } else if (normalized.contains('end of input')) {
      return 'Configuration file appears to be incomplete. Check for missing closing brackets or quotes.';
    }
    return null;
  }
}
