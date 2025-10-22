## 1.1.0 (Legacy)

### Major Features
- **Dedicated Assignment AST**: Assignment statements like `order += "value"` are now parsed as first-class `Assignment` objects instead of generic commands
- **Semantic Clarity**: Clean API with `assignment.variable`, `assignment.operator`, and `assignment.values` properties
- **Dotted Identifiers**: Full support for complex assignments like `bar.colors.focused = "#ffffff"`
- **Enhanced Grammar**: Implements proper assignment grammar: `LHS WS* AssignOp WS* RhsList`
- **Comprehensive Coverage**: Command parsing unified across blocks, chains, criteria, and escape sequences
- **Actionable Errors**: `parseWithDetails` now normalizes suggestions for common syntax issues

### Breaking Changes
- **Assignment Parsing**: Assignment statements are no longer parsed as `Command` objects with `head='assign'`
- **Migration Required**: Update code using `whereType<Command>().where((cmd) => cmd.head == 'assign')` to use `whereType<Assignment>()`

### New API
- `Assignment` class: Dedicated AST node for assignment statements
- `Assignment.variable`: Left-hand side variable name (supports dotted identifiers)  
- `Assignment.operator`: Assignment operator ('=' or '+=')
- `Assignment.values`: List of right-hand side values
- Full JSON serialization support for Assignment objects
- Visitor pattern support with `visitAssignment()` method

### Tooling & Documentation
- Added `test/v2/advanced_parser_test.dart` to cover grammar breadth, error reporting, and line continuations
- Refreshed V2 API reference, migration guide, and README with 2.0 guidance

### Migration Guide

#### Before (V3.0.x):
```dart
// Old confusing way
final assignments = config.statements
    .whereType<Command>()
    .where((cmd) => cmd.head == 'assign');
    
for (final cmd in assignments) {
  final variable = (cmd.args[0] as BareArg).value;
  final operator = (cmd.args[1] as BareArg).value;
  final value = cmd.args[2];
}
```

#### After (V2.0.0+):
```dart
// New clean way
final assignments = config.statements
    .whereType<Assignment>();
    
for (final assignment in assignments) {
  final variable = assignment.variable;
  final operator = assignment.operator;
  final value = assignment.values[0];
}
```

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
