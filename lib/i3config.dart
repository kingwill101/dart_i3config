/// A library for parsing and manipulating i3 window manager configuration files.
///
/// This library provides a robust parser and data model for working with i3 configuration files.
/// It handles all major i3 configuration elements including sections, properties, arrays, commands,
/// and comments while preserving their structure and order.
///
/// ## Key Features
///
/// - Full support for i3 configuration syntax
/// - Preserves comments and formatting
/// - Handles nested sections
/// - Supports type inference for values (numbers, booleans, strings)
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
///   set $mod Mod4
///
///   # Start terminal
///   bindsym $mod+Return exec i3-sensible-terminal
///   ''');
///
///   // Access commands
///   final commands = config.elements.whereType<Command>();
///   print(commands.first.command); // "set $mod Mod4"
/// }
/// ```
///
/// ## Working with Sections
///
/// The library handles nested sections with properties:
///
/// ```dart
/// final config = I3Config.parse('''
/// bar {
///     status_command i3status
///     position top
///     colors {
///         background #000000
///         statusline #ffffff
///     }
/// }
/// ''');
///
/// final barSection = config.elements.whereType<Section>().first;
/// print(barSection.properties['position']); // "top"
///
/// final colorsSection = barSection.children.whereType<Section>().first;
/// print(colorsSection.properties['background']); // "#000000"
/// ```
///
/// ## Type Support
///
/// Values are automatically parsed into appropriate types:
///
/// ```dart
/// final config = I3Config.parse('''
/// general {
///     interval = 1          # parsed as integer
///     colors = true        # parsed as boolean
///     format = "%H:%M:%S"  # parsed as string
/// }
/// ''');
///
/// final section = config.elements.whereType<Section>().first;
/// print(section.properties['interval'].runtimeType); // int
/// print(section.properties['colors'].runtimeType);   // bool
/// ```
///
/// ## Array Handling
///
/// Support for i3's array syntax:
///
/// ```dart
/// final config = I3Config.parse('''
/// # Status bar modules
/// order += "wireless wlan0"
/// order += "battery 0"
/// order += "clock"
/// ''');
///
/// final array = config.elements.whereType<ArrayElement>().first;
/// print(array.name);   // "order"
/// print(array.values); // ["wireless wlan0", "battery 0", "clock"]
/// ```
///
/// ## Core Classes
///
/// - [I3Config]: The root container for all configuration elements
/// - [Section]: Represents a configuration block with properties and nested elements
/// - [Property]: Key-value pairs with type inference
/// - [ArrayElement]: Represents array-like configurations with multiple values
/// - [Command]: Raw i3 commands and directives
/// - [CommentBlock]: Preserved comments with proper placement
/// - [I3ConfigParser]: The main parsing engine
///
/// ## Error Handling
///
/// The parser is designed to be forgiving and will try to make sense of malformed input:
///
/// ```dart
/// try {
///   final config = I3Config.parse(malformedContent);
/// } catch (e) {
///   print('Failed to parse config: $e');
/// }
/// ```
///
/// ## Additional Information
///
/// For more details on i3 configuration syntax and options, see the
/// [i3 User Guide](https://i3wm.org/docs/userguide.html#configuring).

export 'src/i3conf_base.dart';
