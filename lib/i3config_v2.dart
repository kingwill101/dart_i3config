/// i3config v2 - Modern PetitParser implementation with source position tracking
///
/// This is the new, advanced implementation of the i3config parser using
/// the PetitParser framework. It provides enhanced features including:
///
/// - Precise source position tracking for all parsed elements
/// - Enhanced error reporting with line/column information
/// - Comprehensive AST with sealed class hierarchies
/// - Better type safety and exhaustiveness checking
/// - Support for complex parsing scenarios
///
/// ## Usage
///
/// ```dart
/// import 'package:i3config/i3config_v2.dart';
///
/// // Parse with automatic position tracking
/// final config = Config.parse(configContent);
///
/// // Access source position information
/// for (final statement in config.statements) {
///   if (statement.span != null) {
///     print('Statement at line ${statement.span!.start.line + 1}');
///     print('Source: "${statement.span!.text}"');
///   }
/// }
///
/// // Or use the parser directly for advanced options
/// final parser = I3ConfigParser();
/// final result = parser.parseWithDetails(configContent);
/// ```
///
/// ## Features
///
/// - **Source Position Tracking**: Every parsed element includes optional
///   `SourceSpan` information showing its exact location in source
/// - **Enhanced Error Reporting**: Detailed error messages with suggestions
/// - **Type-Safe AST**: Sealed classes for better pattern matching
/// - **Visitor Pattern**: Built-in visitor support for AST traversal
/// - **Extensible Handlers**: Plugin architecture for custom processing
///
/// ## Migration from V1
///
/// The v2 API is largely compatible with v1, but provides additional features:
///
/// ```dart
/// // v1 style (still works)
/// final config = Config.parse(configContent);
///
/// // v2 enhanced features
/// final parser = I3ConfigParser();
/// final result = parser.parseWithDetails(configContent, url: Uri.file('config'));
///
/// if (result.isSuccess) {
///   final config = result.config;
///   // Access position information
///   for (final stmt in config.statements) {
///     print('Statement span: ${stmt.span}');
///   }
/// } else {
///   print('Error: ${result.error}');
///   if (result.suggestion != null) {
///     print('Suggestion: ${result.suggestion}');
///   }
/// }
/// ```
library;

// Export the v2 PetitParser implementation
export 'src/v2/ast.dart';
export 'src/v2/parser.dart';
export 'src/v2/parse_result.dart';
export 'src/v2/visitor.dart';
export 'src/v2/handlers.dart';