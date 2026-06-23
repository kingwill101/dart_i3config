/// A library for parsing and manipulating i3 window manager configuration files.
///
/// This library provides a robust parser and data model for working with i3 configuration files.
/// It handles all major i3 configuration elements including commands, assignments, blocks, and
/// comments while preserving their structure and order.
///
/// ## Key Features
///
/// - Full support for i3/Sway configuration syntax
/// - State machine processor with pluggable handlers
/// - Block-scoped commands and contexts
/// - Variable expansion and string interpolation
/// - Block references for cross-block property access
/// - File imports with nesting and circular detection
/// - Dotted command heads (`client.focused`, `client.unfocused`)
/// - Hex color value support
/// - Inline comments
/// - Preserves comments and formatting
/// - Source position tracking
/// - JSON serialization
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
/// ## Error Handling
///
/// The parser provides detailed error information:
///
/// ```dart
/// try {
///   final config = Config.parse(malformedContent);
/// } catch (e) {
///   print('Parse error: $e');
/// }
/// ```
///
/// ## Core Classes
///
/// - `Config`: Root container with source position tracking
/// - `Statement`: Sealed class hierarchy for all statements
/// - `Command`: Generic commands with type-safe argument access
/// - `Assignment`: Variable assignments and array appends
/// - `Block`: First-class block elements with nested body
/// - `Value`: Sealed hierarchy for values (Quoted, VariableRef, BareArg, InterpolatedString, BlockReference)
/// - `ConfigProcessor`: State machine processor with pluggable handlers
/// - `Context`: Scoped variable and option management
///
/// ## Additional Information
///
/// For more details on i3 configuration syntax and options, see the
/// [i3 User Guide](https://i3wm.org/docs/userguide.html#configuring).
library;

export 'i3config_v2.dart';
