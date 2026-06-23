/// i3config — PetitParser implementation with source position tracking
///
/// This library provides a robust parser and processor for i3/Sway
/// configuration files using the PetitParser framework.
///
/// ## Usage
///
/// ```dart
/// import 'package:i3config/i3config.dart';
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
/// // Use the state machine processor
/// final processor = ConfigProcessor();
/// await processor.process(config);
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
/// - **State Machine**: Advanced processing pipeline with configurable states
/// - **Variable Expansion**: Dynamic variable resolution with scoping
/// - **String Interpolation**: Double-quoted strings support `$variable` references
library;

// Export the implementation
export 'src/ast.dart';
export 'src/parser.dart';
export 'src/parse_result.dart';
export 'src/visitor.dart';
export 'src/handlers.dart';
export 'src/base_handlers.dart';
export 'src/context.dart';
export 'src/state.dart';
export 'src/processor.dart';
export 'src/models.dart';
export 'src/value.dart';
export 'src/builtin.dart';
export 'src/mixin.dart';
export 'src/filesystem.dart';
// VirtualFileSystem is exported for consumer testing use
export 'src/test_vfs.dart';
export 'src/formatter.dart';
