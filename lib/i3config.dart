/// A library for parsing and manipulating i3 window manager configuration files.
///
/// This library provides a robust parser and data model for working with i3 configuration files.
/// It handles all major i3 configuration elements including sections, properties, arrays, commands,
/// and comments while preserving their structure and order.
///
/// ## Version Information
/// 
/// This package provides two parser implementations:
/// 
/// - **Default (v1)**: Stable, hand-written parser - recommended for production use
/// - **V2**: Modern PetitParser implementation with enhanced features
/// 
/// To use the advanced v2 implementation with source position tracking:
/// ```dart
/// import 'package:i3config/i3config_v2.dart';
/// ```
///
/// ## Key Features
///
/// - Full support for i3/Sway configuration syntax
/// - Preserves comments and formatting  
/// - Handles nested sections and blocks
/// - Supports line continuations
/// - Enhanced error reporting
/// - Built-in JSON serialization
/// - Preserves order of configuration elements
///
/// ## Basic Usage
///
/// Parse an i3 configuration file:
///
/// ```dart
/// import 'package:i3config/i3config.dart';
///
/// void main() {
///   final config = I3Config.parse('''
///   # Set mod key
///   set \$mod Mod4
///
///   # Start terminal
///   bindsym \$mod+Return exec i3-sensible-terminal
///   ''');
///
///   print('Parsed ${config.elements.length} elements');
/// }
/// ```
///
/// ## Enhanced Features (V2)
///
/// For advanced use cases, use the v2 implementation:
///
/// ```dart
/// import 'package:i3config/i3config_v2.dart';
///
/// final config = Config.parse(configContent);
/// 
/// // Access source position information
/// for (final statement in config.statements) {
///   if (statement.span != null) {
///     print('Statement at line ${statement.span!.start.line + 1}');
///   }
/// }
/// ```
///
/// ## Error Handling
///
/// The parser provides detailed error information:
///
/// ```dart
/// try {
///   final config = I3Config.parse(malformedContent);
/// } catch (e) {
///   print('Parse error: $e');
/// }
/// ```
///
/// ## Migration Guide
///
/// - **Existing code**: No changes needed, continues to use stable v1 parser
/// - **New projects**: Consider using `package:i3config/i3config_v2.dart` for enhanced features
/// - **Gradual migration**: Import v2 explicitly when ready to upgrade
///
/// ## Core Classes
///
/// **V1 (Default)**:
/// - `I3Config`: The root configuration container
/// - `ConfigElement`: Base class for all configuration elements
/// 
/// **V2 (Enhanced)**:
/// - `Config`: Enhanced root container with source position tracking
/// - `Statement`: Base class for all statements with sealed class hierarchy
/// - `Command`: Generic commands with enhanced type safety
/// - `Value`: Sealed hierarchy for values (Quoted, VariableRef, BareArg)
/// - `I3ConfigParser`: Advanced parsing engine with detailed error reporting
///
/// ## Additional Information
///
/// For more details on i3 configuration syntax and options, see the
/// [i3 User Guide](https://i3wm.org/docs/userguide.html#configuring).

// Export the stable v1 implementation by default
export 'i3config_v1.dart';
