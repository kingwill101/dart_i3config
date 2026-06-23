import 'package:i3config/i3config_v2.dart' show ConfigProcessor;
import 'package:test/test.dart';
import 'package:i3config/src/test_vfs.dart';

void main() {
  group('Include command tests', () {
    setUp(() {
      vfs.createFile('modules/global.conf', '''
set \$mod Mod4
set \$terminal alacritty
set \$browser firefox
''');

      vfs.createFile('modules/local.conf', '''
set \$editor vim
set \$mod Mod1
''');

      vfs.createFile('modules/colors.conf', '''
set \$bg_color "#000000"
set \$fg_color "#ffffff"
''');

      vfs.createFile('config/main.conf', '''
set \$workspace1 1
set \$workspace2 2
''');

      vfs.createFile('modules/nested.conf', '''
include "modules/colors.conf"
set \$nested_var nested_value
''');
    });

    tearDown(() {
      vfs.clear();
    });

    test('Basic include merges variables', () async {
      final processor = ConfigProcessor(fileSystem: vfs);

      final configContent = '''
include "modules/global.conf"
set \$mod Mod4
''';

      await processor.processString(configContent);

      expect(processor.context.getVariable('mod'), 'Mod4');
      expect(processor.context.getVariable('terminal'), 'alacritty');
      expect(processor.context.getVariable('browser'), 'firefox');
    });

    test('Multiple includes merge variables', () async {
      final processor = ConfigProcessor(fileSystem: vfs);

      final configContent = '''
include "modules/global.conf"
include "modules/local.conf"
''';

      await processor.processString(configContent);

      expect(processor.context.getVariable('mod'), 'Mod1');
      expect(processor.context.getVariable('editor'), 'vim');
      expect(processor.context.getVariable('terminal'), 'alacritty');
    });

    test('Nested includes process recursively', () async {
      final processor = ConfigProcessor(fileSystem: vfs);

      final configContent = '''
include "modules/nested.conf"
''';

      await processor.processString(configContent);

      expect(processor.context.getVariable('bg_color'), '#000000');
      expect(processor.context.getVariable('fg_color'), '#ffffff');
      expect(processor.context.getVariable('nested_var'), 'nested_value');
    });

    test('Circular include is detected', () async {
      vfs.createFile('circular.conf', 'include "circular.conf"');

      final processor = ConfigProcessor(fileSystem: vfs);

      final configContent = '''
include "circular.conf"
set \$mod Mod4
''';

      await processor.processString(configContent);

      expect(processor.context.getVariable('mod'), 'Mod4');
    });

    test('File not found is handled gracefully', () async {
      final processor = ConfigProcessor(fileSystem: vfs);

      final configContent = '''
include "nonexistent.conf"
set \$mod Mod4
''';

      await processor.processString(configContent);

      expect(processor.context.getVariable('mod'), 'Mod4');
    });
  });
}
