import 'package:i3config/i3config_v2.dart';

Future<void> main() {
  final configContent = '''
# Font configuration
font pango:monospace 10

# Set variables
set \$mod Mod4
set \$term kitty # My favorite terminal

# Bar block
bar {
    status_command i3status
    position top
}

# Keybindings
bindsym \$mod+Return exec \$term  # Launch terminal
bindsym \$mod+d exec "dmenu_run"
''';

  // Parse, format with defaults
  final config = Config.parse(configContent);
  var formatted = ConfigFormatter().format(config);
  print('=== Default Formatting ===');
  print(formatted);

  // With sorted assignments
  formatted = ConfigFormatter(
    options: const FormatterOptions(sortAssignments: true),
  ).format(config);
  print('=== Sorted Assignments ===');
  print(formatted);

  // With custom indent
  formatted = ConfigFormatter(
    options: const FormatterOptions(indent: 4),
  ).format(config);
  print('=== 4-Space Indent ===');
  print(formatted);

  // Without trailing newline
  formatted = ConfigFormatter(
    options: const FormatterOptions(trailingNewline: false),
  ).format(config);
  print('=== No Trailing Newline ===');
  print(formatted);
}
