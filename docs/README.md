# i3conf Documentation

This directory contains comprehensive documentation for the i3conf library.

## Version-Specific Documentation

- **[V1 Documentation](v1/)** - Simple AST-based parser for basic configuration parsing
  - [V1 API Reference](v1/api-reference.md) - Complete V1 API documentation
- **[V2 Documentation](v2/)** - State machine architecture with advanced processing capabilities
  - New in 2.0: Dedicated assignment AST, comprehensive grammar coverage tests, improved error suggestions
  - [V2 API Reference](v2/api-reference.md) - Complete V2 API documentation
  - [Block Handlers](v2/block-handlers.md) - Processing block types and scoped commands
  - [Command Handlers](v2/command-handlers.md) - Processing individual commands
  - [Context and Scoping](v2/context-and-scoping.md) - Variable management and inheritance
  - [Configuration Examples](v2/configuration-examples.md) - Real-world config to handler mapping

## Quick Start

### V1 - Simple AST Parsing
```dart
import 'package:i3config/i3config_v1.dart';

final parser = I3ConfigParser(configContent);
final config = parser.parse();

for (var element in config.elements) {
  print(element);
}
```

### V2 - State Machine Processing
```dart
import 'package:i3config/i3config_v2.dart';

final config = Config.parse(configContent);
final processor = ConfigProcessor();
await processor.process(config);
```

### V2 - Simple AST Iteration (No State Machine)
```dart
import 'package:i3config/i3config_v2.dart';

final config = Config.parse(configContent);
for (final element in config.statements) {
  print('${element.runtimeType}: $element');
}
```

## Choosing Between Versions

| Use V1 When | Use V2 When |
|-------------|-------------|
| Simple configuration parsing | Need advanced processing |
| Direct AST manipulation | Want handler-based architecture |
| Minimal dependencies | Need scoped commands/variables |
| Legacy compatibility | Building configuration tools |

## Migration

See the [V1 to V2 Migration Guide](v2/migration.md) for detailed upgrade instructions.
