# i3config Library Restructuring Summary

## Overview

Successfully restructured the i3config library to support both the original hand-written parser (V1) and the new PetitParser implementation with source position tracking (V2).

## Directory Structure

```
lib/
├── i3config.dart              # Main entry point (exports V1 by default)
├── i3config_v1.dart           # V1 entry point (stable, hand-written parser)
├── i3config_v2.dart           # V2 entry point (PetitParser with position tracking)
└── src/
    ├── v1/                    # Original implementation
    │   ├── i3conf_base.dart   # Original hand-written parser
    │   └── models.dart        # Original AST models
    └── v2/                    # PetitParser implementation
        ├── ast.dart           # Enhanced AST with source spans
        ├── grammar.dart       # PetitParser grammar definition
        ├── handlers.dart      # Processing handlers
        ├── parse_result.dart  # Enhanced result types
        ├── parser.dart        # Main parser implementation
        └── visitor.dart       # Visitor pattern support
```

## Key Changes

### 1. **Backward Compatibility Preserved**
- Default import (`package:i3config/i3config.dart`) continues to use V1
- Existing code works without modification
- All tests pass without changes

### 2. **V1 Implementation**
- Stable, battle-tested hand-written parser
- Simple API with basic error handling
- Recommended for production use
- Located in `lib/src/v1/`

### 3. **V2 Implementation** 
- Modern PetitParser-based implementation
- Source position tracking for all parsed elements
- Enhanced error reporting with line/column information
- Type-safe sealed class AST hierarchy
- Visitor pattern support
- Advanced processing capabilities
- Located in `lib/src/v2/`

### 4. **Entry Points**
- `package:i3config/i3config.dart` - V1 (default, backward compatible)
- `package:i3config/i3config_v1.dart` - V1 (explicit)
- `package:i3config/i3config_v2.dart` - V2 (enhanced features)

## Usage Examples

### V1 Usage (Default)
```dart
import 'package:i3config/i3config.dart';

final config = I3Config.parse(configContent);
print('Elements: ${config.elements.length}');
```

### V2 Usage (Enhanced)
```dart
import 'package:i3config/i3config_v2.dart';

final config = Config.parse(configContent);
for (final stmt in config.statements) {
  if (stmt.span != null) {
    print('${stmt.runtimeType} at line ${stmt.span!.start.line + 1}');
  }
}
```

## Migration Strategy

1. **Existing Projects**: No changes needed, continue using V1
2. **New Projects**: Consider V2 for enhanced features
3. **Gradual Migration**: Import V2 explicitly when ready

## Features Added in V2

- **Source Position Tracking**: Every parsed element includes `SourceSpan` information
- **Enhanced Error Reporting**: Detailed error messages with suggestions
- **Type Safety**: Sealed classes for better pattern matching and exhaustiveness
- **Visitor Pattern**: Built-in visitor support for AST traversal
- **Processing Framework**: Extensible handlers for custom processing logic

## Testing

- All existing tests pass with V1
- V2 tests validate source position tracking
- Both implementations work independently
- Examples demonstrate both APIs

## Documentation

- Updated README with V1/V2 information
- Comprehensive API documentation for both versions
- Migration guide for users wanting to upgrade
- Examples showing both simple and advanced usage

## Status

✅ **Complete**: Both V1 and V2 implementations are functional and tested
✅ **Backward Compatible**: Existing code continues to work unchanged  
✅ **Future Ready**: V2 provides foundation for advanced features
✅ **Well Documented**: Clear guidance on choosing between versions