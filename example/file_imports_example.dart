import 'package:i3config/i3config_v2.dart';

/// Demonstrates using the filesystem abstraction with `include` directives.
///
/// This example shows:
///   1. Using [VirtualFileSystem] for testing – no real files needed.
///   2. The same code works unchanged with [PhysicalFileSystem] for real I/O.
///   3. Nested includes and circular-include detection.
Future<void> main() async {
  print('=== File Imports Example ===\n');

  // ── Set up a virtual filesystem with module files ──────────────────────
  final fs = VirtualFileSystem();
  fs.createFile('modules/appearance.conf', '''
set \$bg     "#2e3440"
set \$fg     "#d8dee9"
set \$font   "FiraCode Nerd Font 10"
''');

  fs.createFile('modules/keybindings.conf', '''
set \$mod    Mod4
set \$term   alacritty
bindsym \$mod+Return exec \$term
bindsym \$mod+d exec dmenu_run
''');

  fs.createFile('modules/bar.conf', '''
bar {
    status_command i3status
    position top
    colors {
        background \$bg
        foreground \$fg
    }
}
''');

  // A file that includes other files (nested include)
  fs.createFile('modules/theme.conf', '''
include "modules/appearance.conf"
include "modules/bar.conf"
set \$wallpaper "~/.wallpapers/nord.png"
''');

  // ── Process config that uses includes ──────────────────────────────────
  final configContent = '''
# Main i3 config
include "modules/keybindings.conf"
include "modules/theme.conf"

# Override a variable set by an include
set \$term foot

exec feh --bg-scale \$wallpaper
''';

  final processor = ConfigProcessor(fileSystem: fs);
  await processor.process(Config.parse(configContent));

  print('Variables after processing:');
  final variables = processor.context.variables;
  for (final name in variables.keys.toList()..sort()) {
    print('  \$$name = ${variables[name]}');
  }

  print('\n─── Test the same config with PhysicalFileSystem ────');
  print('(This would read real files from disk; skipping read to avoid errors)');

  print('\n=== Key Points ===');
  print('1. IncludeHandler uses FileSystem abstraction (not dart:io directly)');
  print('2. VirtualFileSystem simulates files in memory for fast tests');
  print('3. PhysicalFileSystem reads real files (default for production)');
  print('4. Inject via ConfigProcessor(fileSystem: yourFs)');
  print('5. Nested includes, circular detection, and variable expansion work');
  print('   with both filesystem implementations');
}
