import 'package:i3config/i3config_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter', () {
    test('formats basic config with assignment, command, block, comment', () {
      final config = Config.parse('''
# Set mod key
set \$mod Mod4
bindsym \$mod+Return exec i3-sensible-terminal
bar {
    status_command i3status
}
''');

      final formatter = ConfigFormatter();
      final output = formatter.format(config);

      expect(output, contains('# Set mod key'));
      expect(output, contains('set \$mod Mod4'));
      expect(output, contains('bindsym \$mod+Return exec i3-sensible-terminal'));
      expect(output, contains('bar {'));
      expect(output, contains('  status_command i3status'));
      expect(output, contains('}'));
    });

    test('handles array values', () {
      final config = Config.parse(r'''
workspace = ["1: Dev", "2: Term"]
workspace += ["3: Mail"]
''');

      final formatter = ConfigFormatter();
      final output = formatter.format(config);

      expect(output, contains('workspace = ["1: Dev", "2: Term"]'));
      expect(output, contains('workspace += ["3: Mail"]'));
    });

    test('handles criteria in commands', () {
      final config = Config.parse('''
for_window [class="Firefox"] move to workspace 2
bindsym \$mod+1 focus
''');

      final formatter = ConfigFormatter();
      final output = formatter.format(config);

      expect(output, contains('for_window [class="Firefox"] move to workspace 2'));
    });

    test('uses custom indent', () {
      final config = Config.parse('''
bar {
status_command i3status
}
''');

      final formatter = ConfigFormatter(options: FormatterOptions(indent: 4));
      final output = formatter.format(config);

      expect(output, contains('bar {'));
      expect(output, contains('    status_command i3status'));
      expect(output, contains('}'));
    });

    test('sorts assignments when option is set', () {
      final config = Config.parse('''
bindsym \$mod+a exec app1
zebra = v2
alpha = v1
bar {
    delta = z
    gamma = m
    status_command i3status
}
''');

      final formatter = ConfigFormatter(
        options: FormatterOptions(sortAssignments: true),
      );
      final output = formatter.format(config);

      final lines = output.split('\n').where((l) => l.trim().isNotEmpty).toList();

      final topLevelAssignments =
          lines.where((l) => l.startsWith('alpha') || l.startsWith('zebra')).toList();
      expect(topLevelAssignments[0], 'alpha = v1');
      expect(topLevelAssignments[1], 'zebra = v2');

      final barAssignments =
          lines.where((l) => l.startsWith('  delta') || l.startsWith('  gamma')).toList();
      expect(barAssignments[0], '  delta = z');
      expect(barAssignments[1], '  gamma = m');
    });

    test('trailing newline option', () {
      final config = Config.parse('set \$a 1');

      final withNewline = ConfigFormatter(
        options: FormatterOptions(trailingNewline: true),
      ).format(config);
      expect(withNewline.endsWith('\n'), isTrue);

      final withoutNewline = ConfigFormatter(
        options: FormatterOptions(trailingNewline: false),
      ).format(config);
      expect(withoutNewline.endsWith('\n'), isTrue);
    });

    test('produces output that can be re-parsed', () {
      final original = '''
# Comment at top
set \$mod Mod4

bindsym \$mod+Return exec terminal

workspace = ["1: Dev", "2: Term"]

bar {
    status_command i3status
}

for_window [class="Firefox"] move to workspace 2
''';

      final config = Config.parse(original);
      final formatter = ConfigFormatter(
        options: FormatterOptions(indent: 4, trailingNewline: false),
      );
      final formatted = formatter.format(config);

      final reparsed = Config.parse(formatted);
      expect(reparsed.statements.length, config.statements.length);
    });

    test('idempotent formatting', () {
      final config = Config.parse('''
bar {
    status_command i3status
    position top
}
set \$mod Mod4

bindsym \$mod+Return exec terminal
''');

      final formatter = ConfigFormatter(
        options: FormatterOptions(indent: 4),
      );
      final first = formatter.format(config);
      final second = formatter.format(Config.parse(first));

      expect(first, second);
    });
  });

  group('Value.toConfigString()', () {
    test('BareArg returns value as-is', () {
      expect(BareArg('status_command').toConfigString(), 'status_command');
    });

    test('Quoted returns quoted string', () {
      expect(Quoted('hello world', '"').toConfigString(), '"hello world"');
    });

    test('Quoted escapes special characters', () {
      expect(Quoted('say "hi"', '"').toConfigString(), r'"say \"hi\""');
    });

    test('Quoted uses single quotes', () {
      expect(Quoted('hello', "'").toConfigString(), "'hello'");
    });

    test('VariableRef returns dollar-prefixed name', () {
      expect(VariableRef('mod').toConfigString(), '\$mod');
    });

    test('ArrayValue formats items', () {
      final array = ArrayValue([BareArg('a'), BareArg('b'), Quoted('c', '"')]);
      expect(array.toConfigString(), '[a, b, "c"]');
    });

    test('ArrayValue with nested values', () {
      final array = ArrayValue([
        VariableRef('var'),
        ArrayValue([BareArg('nested')]),
      ]);
      expect(array.toConfigString(), '[\$var, [nested]]');
    });

    test('Empty ArrayValue', () {
      expect(ArrayValue([]).toConfigString(), '[]');
    });
  });
}
