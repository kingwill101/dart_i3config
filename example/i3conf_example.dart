import 'package:i3config/i3config_v2.dart';

void main() {
  final configContent = '''
# Set mod key
set \$mod Mod4

# Basic key bindings
bindsym \$mod+Return exec i3-sensible-terminal
bindsym \$mod+Shift+q kill

# Variable assignment
set \$terminal i3-sensible-terminal
''';

  final config = Config.parse(configContent);
  print('Parsed ${config.elements.length} configuration elements');
  
  // Access specific elements
  for (final element in config.elements) {
    print('Element: ${element.runtimeType}');
  }
}

