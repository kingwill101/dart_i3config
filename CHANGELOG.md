## 3.0.0

### Major Features
- **V2 Now Default**: Enhanced PetitParser implementation is now the default export
- **Dual Parser Architecture**: Support for both V1 (legacy) and V2 (default) parsers
- **Source Position Tracking**: V2 parser provides precise source location information for all parsed elements
- **Enhanced Type Safety**: V2 uses sealed classes for better pattern matching and exhaustiveness checking
- **Legacy V1 Support**: V1 parser available via explicit import for backward compatibility

### New API Endpoints
- `package:i3config/i3config.dart` - Default export (V2 enhanced parser)
- `package:i3config/i3config_v1.dart` - Legacy V1 parser (stable, hand-written)
- `package:i3config/i3config_v2.dart` - Explicit V2 parser (same as default)

### V2 Parser Features
- **Source Spans**: Every parsed element includes optional `SourceSpan` with line/column information
- **Enhanced Error Reporting**: Detailed error messages with suggestions and precise location info
- **Visitor Pattern**: Built-in visitor support for AST traversal and processing
- **Processing Framework**: Extensible handlers for custom configuration processing
- **Modern Architecture**: Uses PetitParser framework for robust parsing

### V1 Parser Improvements
- Fixed quote handling inconsistency in fallback property parsing
- Properties using `key "value"` format now correctly strip quotes (consistent with `key = "value"`)

### Examples and Documentation
- Added comprehensive position tracking example demonstrating V2 features
- Updated README with migration guide and version selection guidance
- Added processor examples showing advanced V2 capabilities
- Enhanced API documentation for both parser versions

### Usage Examples

#### V2 (Default) Usage
```dart
import 'package:i3config/i3config.dart'; // V2 by default
final config = Config.parse(configContent);
for (final stmt in config.statements) {
  if (stmt.span != null) {
    print('${stmt.runtimeType} at line ${stmt.span!.start.line + 1}');
  }
}
```

#### V1 (Legacy) Usage  
```dart
import 'package:i3config/i3config_v1.dart';
final config = I3Config.parse(configContent);
print('Elements: ${config.elements.length}');
```

### Migration Path
- **Existing Projects**: No changes needed, continue using V1
- **New Projects**: Consider V2 for enhanced features like position tracking  
- **Gradual Migration**: Import V2 explicitly when ready for advanced features

### Technical Improvements
- **Restructured Architecture**: Clean separation between V1 and V2 implementations
- **Enhanced Testing**: Comprehensive test coverage for both parser versions
- **Better Error Handling**: V2 provides detailed parse errors with context and suggestions
- **Memory Efficiency**: V2 uses modern parsing techniques for better performance

### Dependencies
- Added `source_span` ^1.10.1 for position tracking support
- Updated `petitparser` ^7.0.0 for V2 implementation

### Breaking Changes
- Package structure reorganized with v1/v2 subdirectories
- Default import now explicitly uses V1 for maximum backward compatibility
- V2 has different API surface with enhanced type safety (sealed classes)

## 2.0.1

### Features
- fix parsing double quoted strings in sections when not using the assign operator
- Added topics metadata to package

## 2.0.0

### Breaking Changes
- Values are now automatically parsed into appropriate types (int, bool, double, string)
- Comments are now preserved and structured into CommentBlocks
- Fixed array handling in sections to properly group values under the same ArrayElement
- Changed Property value type from String to dynamic to support typed values

### Features
- Added type inference for configuration values
- Added structured comment preservation
- Improved array handling in sections
- Added JSON serialization support
## 1.1.1
- support properties with escaped curlies

## 1.0.1

- support section variables with longer names containing spaces
- add helpers for getting module name and types
## 1.0.0

- Initial version.
