# i3conf Documentation

This directory contains comprehensive documentation for the i3conf library.

## Documentation

- **[V2 Guide](v2/)** - State machine architecture with advanced processing capabilities
  - [V2 API Reference](v2/api-reference.md) - Complete V2 API documentation
  - [Language Guide](v2/language-guide.md) - Complete language syntax and API reference
  - [Block Handlers](v2/block-handlers.md) - Processing block types and scoped commands
  - [Command Handlers](v2/command-handlers.md) - Processing individual commands
  - [Context and Scoping](v2/context-and-scoping.md) - Variable management and inheritance
  - [Configuration Examples](v2/configuration-examples.md) - Real-world config to handler mapping

## Quick Start

```dart
import 'package:i3config/i3config.dart';

final config = Config.parse(configContent);
final processor = ConfigProcessor();
await processor.process(config);
```

### Simple AST Iteration (No State Machine)

```dart
import 'package:i3config/i3config.dart';

final config = Config.parse(configContent);
for (final element in config.statements) {
  print('${element.runtimeType}: $element');
}
```
