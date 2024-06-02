### i3config

A Dart library for parsing and handling i3 configuration files.

## Overview

This library provides classes and functions to parse i3 configuration files, allowing you to work with sections, properties, arrays, and commands in a structured way. It supports nested sections and preserves the order of elements.

## Getting Started

### Prerequisites
Dart SDK

### Installation

Add the following to your pubspec.yaml file:
```yaml
dependencies:
  i3config:
    git:
      url: https://github.com/yourusername/dart_i3config.git
```

Then, run dart pub get to install the package.

Usage
To use this library, import it in your Dart code:
```dart
import 'package:i3config/i3config.dart';

void main() {
  final configContent = '''
  general {
      interval = 1
      colors = true
  }

  order += "volume master"
  order += "battery 0"

  set \$ws1 "1: Terminal"
  include <pattern>

  bar {
      output HDMI2
      colors {
          background #000000
          statusline #ffffff
      }
  }
  ''';

  final parser = I3ConfigParser(configContent);
  final config = parser.parse();

  print(config);
}
```

### Contributing

Contributions are welcome! Please open an issue or submit a pull request.

### License
This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
