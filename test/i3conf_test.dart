import 'package:test/test.dart';
import 'package:i3config/i3config.dart';

void main() {
  group('I3ConfigParser', () {
    test('parses simple properties', () {
      final configContent = '''
      general {
          interval = 1
          colors = true
      }
      ''';

      final parser = I3ConfigParser(configContent);
      final config = parser.parse();

      expect(config.elements.length, 1);
      expect(config.elements[0], isA<Section>());

      final section = config.elements[0] as Section;
      expect(section.name, 'general');
      expect(section.properties['interval'], '1');
      expect(section.properties['colors'], 'true');
    });

    test('parses arrays', () {
      final configContent = '''
      order += "volume master"
      order += "battery 0"
      ''';

      final parser = I3ConfigParser(configContent);
      final config = parser.parse();

      expect(config.elements.length, 1);
      expect(config.elements[0], isA<ArrayElement>());

      final arrayElement = config.elements[0] as ArrayElement;
      expect(arrayElement.name, 'order');
      expect(arrayElement.values, ['volume master', 'battery 0']);
    });

    test('parses commands', () {
      final configContent = '''
      set \$ws1 "1: Terminal"
      include <pattern>
      ''';

      final parser = I3ConfigParser(configContent);
      final config = parser.parse();

      expect(config.elements.length, 2);
      expect(config.elements[0], isA<Command>());
      expect(config.elements[1], isA<Command>());

      final command1 = config.elements[0] as Command;
      final command2 = config.elements[1] as Command;
      expect(command1.command, 'set \$ws1 "1: Terminal"');
      expect(command2.command, 'include <pattern>');
    });

    test('parses nested sections', () {
      final configContent = '''
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

      expect(config.elements.length, 1);
      expect(config.elements[0], isA<Section>());

      final section = config.elements[0] as Section;
      expect(section.name, 'bar');
      expect(section.children.length, 2);

      final property = section.children[0] as Property;
      expect(property.key, 'output');
      expect(property.value, 'HDMI2');

      final nestedSection = section.children[1] as Section;
      expect(nestedSection.name, 'colors');
      expect(nestedSection.children.length, 2);

      final backgroundProperty = nestedSection.children[0] as Property;
      expect(backgroundProperty.key, 'background');
      expect(backgroundProperty.value, '#000000');

      final statuslineProperty = nestedSection.children[1] as Property;
      expect(statuslineProperty.key, 'statusline');
      expect(statuslineProperty.value, '#ffffff');
    });

    test('parses mixed content', () {
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

      expect(config.elements.length, 5);

      final section = config.elements[0] as Section;
      expect(section.name, 'general');
      expect(section.properties['interval'], '1');
      expect(section.properties['colors'], 'true');

      final arrayElement1 = config.elements[1] as ArrayElement;
      expect(arrayElement1.name, 'order');
      expect(arrayElement1.values, ['volume master', "battery 0"]);

      final command1 = config.elements[2] as Command;
      expect(command1.command, 'set \$ws1 "1: Terminal"');

      final command2 = config.elements[3] as Command;
      expect(command2.command, 'include <pattern>');

      final barSection = config.elements[4] as Section;
      expect(barSection.name, 'bar');
      expect(barSection.children.length, 2);

      final barProperty = barSection.children[0] as Property;
      expect(barProperty.key, 'output');
      expect(barProperty.value, 'HDMI2');

      final colorsSection = barSection.children[1] as Section;
      expect(colorsSection.name, 'colors');
      expect(colorsSection.children.length, 2);

      final backgroundProperty = colorsSection.children[0] as Property;
      expect(backgroundProperty.key, 'background');
      expect(backgroundProperty.value, '#000000');

      final statuslineProperty = colorsSection.children[1] as Property;
      expect(statuslineProperty.key, 'statusline');
      expect(statuslineProperty.value, '#ffffff');
    });
  });
}