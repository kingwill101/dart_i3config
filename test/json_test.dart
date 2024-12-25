import 'dart:convert';
import 'package:test/test.dart';
import 'package:i3config/src/models.dart';

void main() {
  group('JSON Serialization and Deserialization', () {
    test('I3Config to/from JSON', () {
      final config = I3Config()
        ..elements = [
          Section('bar')
            ..properties = {'status_command': 'i3status'}
            ..children = [
              Property('position', 'top'),
              ArrayElement('colors')..values = ['#ffffff', '#000000'],
            ],
          Command('exec --no-startup-id nm-applet'),
          Property('font', 'pango:monospace 8'),
        ];

      final jsonStr = jsonEncode(config.toJson());
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final decodedConfig = I3Config.fromJson(jsonMap);

      expect(decodedConfig.elements.length, equals(config.elements.length));
      expect(decodedConfig.elements[0], isA<Section>());
      expect(decodedConfig.elements[1], isA<Command>());
      expect(decodedConfig.elements[2], isA<Property>());

      final section = decodedConfig.elements[0] as Section;
      expect(section.name, equals('bar'));
      expect(section.properties, equals({'status_command': 'i3status'}));
      expect(section.children.length, equals(2));
      expect(section.children[0], isA<Property>());
      expect(section.children[1], isA<ArrayElement>());

      final decodedCommand = decodedConfig.elements[1] as Command;
      expect(decodedCommand.command, equals('exec --no-startup-id nm-applet'));

      final decodedProperty = decodedConfig.elements[2] as Property;
      expect(decodedProperty.key, equals('font'));
      expect(decodedProperty.value, equals('pango:monospace 8'));
    });

    test('Section to/from JSON', () {
      final section = Section('workspace')
        ..properties = {'output': 'primary'}
        ..children = [
          Property('layout', 'tabbed'),
          Command('bindsym \$mod+1 workspace 1'),
        ];

      final jsonStr = jsonEncode(section.toJson());
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final decodedSection = Section.fromJson(jsonMap);

      expect(decodedSection.name, equals('workspace'));
      expect(decodedSection.properties, equals({'output': 'primary'}));
      expect(decodedSection.children.length, equals(2));
      expect(decodedSection.children[0], isA<Property>());
      expect(decodedSection.children[1], isA<Command>());
    });

    test('ArrayElement to/from JSON', () {
      final arrayElement = ArrayElement('colors')
        ..values = ['#ffffff', '#000000', '#ff0000'];

      final jsonStr = jsonEncode(arrayElement.toJson());
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final decodedArrayElement = ArrayElement.fromJson(jsonMap);

      expect(decodedArrayElement.name, equals('colors'));
      expect(decodedArrayElement.values,
          equals(['#ffffff', '#000000', '#ff0000']));
    });

    test('Property to/from JSON', () {
      final property = Property('font', 'pango:monospace 8');

      final json = jsonEncode(property.toJson());
      final decodedProperty = Property.fromJson(jsonDecode(json));

      expect(decodedProperty.key, equals('font'));
      expect(decodedProperty.value, equals('pango:monospace 8'));
    });

    test('Command to/from JSON', () {
      final command = Command('exec --no-startup-id nm-applet');

      final json = jsonEncode(command.toJson());
      final decodedCommand = Command.fromJson(jsonDecode(json));

      expect(decodedCommand.command, equals('exec --no-startup-id nm-applet'));
    });
  });

  group('Full String Test', () {
    test('Parse, serialize, and deserialize a complete i3 config', () {
      final configString = '''
  # i3 config file (v4)
  font pango:monospace 8
  floating_modifier Mod1

  # start a terminal
  bindsym Mod1+Return exec i3-sensible-terminal

  # kill focused window
  bindsym Mod1+Shift+q kill

  # start dmenu (a program launcher)
  bindsym Mod1+d exec dmenu_run

  # change focus
  bindsym Mod1+j focus left
  bindsym Mod1+k focus right

  # enter fullscreen mode for the focused container
  bindsym Mod1+f fullscreen toggle

  # change container layout (stacked, tabbed, toggle split)
  bindsym Mod1+s layout stacking
  bindsym Mod1+w layout tabbed
  bindsym Mod1+e layout toggle split

  # switch to workspace
  bindsym Mod1+1 workspace 1
  bindsym Mod1+2 workspace 2

  # move focused container to workspace
  bindsym Mod1+Shift+1 move container to workspace 1
  bindsym Mod1+Shift+2 move container to workspace 2

  # reload the configuration file
  bindsym Mod1+Shift+c reload

  # restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
  bindsym Mod1+Shift+r restart

  # exit i3 (logs you out of your X session)
  bindsym Mod1+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"

  # resize window (you can also use the mouse for that)
  mode "resize" {
          bindsym j resize shrink width 10 px or 10 ppt
          bindsym k resize grow height 10 px or 10 ppt
          bindsym l resize shrink height 10 px or 10 ppt
          bindsym semicolon resize grow width 10 px or 10 ppt

          # back to normal: Enter or Escape or Mod1+r
          bindsym Return mode "default"
          bindsym Escape mode "default"
          bindsym Mod1+r mode "default"
  }

  bindsym Mod1+r mode "resize"

  # Start i3bar to display a workspace bar
  bar {
          status_command i3status
  }

  # Autostart applications
  exec --no-startup-id nm-applet
  exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork
  ''';

      // Parse the config string
      final parsedConfig = I3Config.parse(configString);

      // Convert to JSON and back
      final json = jsonEncode(parsedConfig.toJson());
      final decodedConfig = I3Config.fromJson(jsonDecode(json));

      // Helper function to compare configs
      bool compareConfigs(I3Config a, I3Config b) {
        if (a.elements.length != b.elements.length) return false;
        for (var i = 0; i < a.elements.length; i++) {
          if (a.elements[i].toString() != b.elements[i].toString()) {
            return false;
          }
        }
        return true;
      }

      // Compare the original parsed config with the decoded config
      expect(compareConfigs(parsedConfig, decodedConfig), isTrue,
          reason:
              'The original parsed config should match the decoded config after JSON conversion');

      // Optionally, you can also compare the string representations
      expect(parsedConfig.toString(), equals(decodedConfig.toString()),
          reason: 'The string representations of the configs should match');
    });
  });
}
