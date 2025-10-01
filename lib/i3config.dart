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
/// - **Default (V2)**: Modern PetitParser implementation with enhanced features
/// - **V1**: Stable, hand-written parser for compatibility
/// 
/// To use the legacy V1 implementation:
/// ```dart
/// import 'package:i3config/i3config_v1.dart';
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
///   final config = Config.parse('''
///   # Set mod key
///   set \$mod Mod4
///
///   # Start terminal
///   bindsym \$mod+Return exec i3-sensible-terminal
///   ''');
///
///   // Access source position information
///   for (final statement in config.statements) {
///     if (statement.span != null) {
///       print('${statement.runtimeType} at line ${statement.span!.start.line + 1}');
///     }
///   }
/// }
/// ```
///
/// ## Legacy V1 Support
///
/// For compatibility with older code, use the V1 implementation:
///
/// ```dart
/// import 'package:i3config/i3config_v1.dart';
///
/// final config = I3Config.parse(configContent);
/// print('Parsed ${config.elements.length} elements');
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
/// - **Existing code**: Import `package:i3config/i3config_v1.dart` explicitly to maintain compatibility
/// - **New projects**: Use default import for enhanced V2 features
/// - **Gradual migration**: Default import now uses V2 with enhanced capabilities
///
/// ## Core Classes
///
/// **V2 (Default)**:
/// - `Config`: Enhanced root container with source position tracking
/// - `Statement`: Base class for all statements with sealed class hierarchy
/// - `Command`: Generic commands with enhanced type safety
/// - `Value`: Sealed hierarchy for values (Quoted, VariableRef, BareArg)
/// - `I3ConfigParser`: Advanced parsing engine with detailed error reporting
/// 
/// **V1 (Legacy)**:
/// - `I3Config`: The original root configuration container
/// - `ConfigElement`: Base class for all configuration elements
///
/// ## Additional Information
///
/// For more details on i3 configuration syntax and options, see the
/// [i3 User Guide](https://i3wm.org/docs/userguide.html#configuring).
library;

// Export the enhanced V2 implementation by default
export 'i3config_v2.dart';
