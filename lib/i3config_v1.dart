/// i3config v1 - Original hand-written parser implementation
///
/// This is the original, stable implementation of the i3config parser
/// using hand-written parsing logic. Use this for production code
/// until v2 is fully tested and stabilized.
///
/// ## Usage
///
/// ```dart
/// import 'package:i3config/i3config_v2.dart';
///
/// final parser = I3Config();
/// final result = parser.parseConfig(configContent);
/// ```
///
/// ## Features
///
/// - Stable, battle-tested parsing logic
/// - Simple error handling
/// - Basic AST structure
/// - Compatible with existing code
library;

// Export the original v1 implementation
export 'src/v1/i3conf_base.dart';
export 'src/v1/models.dart';
