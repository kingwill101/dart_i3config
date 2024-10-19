/// A library for parsing and handling i3 configuration files.
///
/// This library provides classes and functions to parse i3 configuration files,
/// allowing you to work with sections, properties, arrays, and commands in a structured way.
///
/// ## Example
///
/// ```dart
/// import 'package:i3config/i3config.dart';
///
/// void main() {
///   final configContent = '''
///   general {
///       interval = 1
///       colors = true
///   }
///
///   order += "volume master"
///   order += "battery 0"
///
///   set \$ws1 "1: Terminal"
///   include <pattern>
///
///   bar {
///       output HDMI2
///       colors {
///           background #000000
///           statusline #ffffff
///       }
///   }
///   ''';
///
///   final parser = I3ConfigParser(configContent);
///   final config = parser.parse();
///
///   print(config);
/// }
/// ```
///
/// ## Classes
///
/// - [I3Config]: Represents the entire i3 configuration.
/// - [ConfigElement]: An abstract class representing a configuration element.
/// - [Section]: Represents a section in the i3 configuration.
/// - [ArrayElement]: Represents an array element in the i3 configuration.
/// - [Property]: Represents a property in the i3 configuration.
/// - [Command]: Represents a command in the i3 configuration.
/// - [I3ConfigParser]: A parser for i3 configuration files.
///
/// ## Usage
///
/// To use this library, import it in your Dart code:
///
/// ```dart
/// import 'package:i3config/i3config.dart';
/// ```
///
/// Then, create an instance of [I3ConfigParser] with the configuration content
/// and call the `parse` method to get an [I3Config] object.
///
/// ## Features
///
/// - Parses sections, properties, arrays, and commands.
/// - Supports nested sections.
/// - Preserves the order of elements.
///
/// ## Additional Information
///
/// For more information, see the [i3 window manager documentation](https://i3wm.org/docs/userguide.html).
library i3conf;

export 'src/i3conf_base.dart';
