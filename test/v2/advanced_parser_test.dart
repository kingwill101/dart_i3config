import 'package:i3config/i3config_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Grammar coverage', () {
    test('parses representative statements across the grammar', () {
      final configContent = '''
set \$mod Mod4
include "~/.config/i3/config"
bindsym \$mod+Return exec i3-sensible-terminal
for_window [class="Firefox"] move to workspace 2

# Variable assignments
workspace = "1: Dev"
workspace += "2: Term"

exec --no-startup-id nm-applet

bar {
    status_command i3status
    position top
    tray_output primary
}

mode "resize" {
    bindsym h resize shrink width 10 px
}

input "type:keyboard" {
    xkb_layout us
}

output eDP-1 {
    bg ~/wallpapers/bg.png fill
}

seat seat0 {
    fallback true
}
''';

      final config = Config.parse(configContent);

      final commands = config.statements
          .whereType<Command>()
          .map((c) => c.head)
          .toList();

      expect(
        commands,
        containsAll([
          'set',
          'include',
          'bindsym',
          'for_window',
          'exec',
          'bar',
          'mode',
          'input',
          'output',
          'seat',
        ]),
      );

      final assignments = config.statements.whereType<Assignment>().toList();
      expect(assignments.length, 2);
      expect(assignments.first.variable, 'workspace');

      final barCommand = config.statements.whereType<Command>().firstWhere(
        (command) => command.head == 'bar',
      );
      expect(barCommand.block, isNotNull);
      expect(barCommand.block!.body.length, 3);

      final modeCommand = config.statements.whereType<Command>().firstWhere(
        (command) => command.head == 'mode',
      );
      expect(modeCommand.block, isNotNull);
      expect(modeCommand.block!.body.single, isA<Command>());

      final inputCommand = config.statements.whereType<Command>().firstWhere(
        (command) => command.head == 'input',
      );
      expect(inputCommand.block, isNotNull);
      expect(inputCommand.block!.body.single, isA<Command>());

      final outputCommand = config.statements.whereType<Command>().firstWhere(
        (command) => command.head == 'output',
      );
      expect(outputCommand.block, isNotNull);
      expect(outputCommand.block!.body.single, isA<Command>());
    });
  });

  group('Error reporting', () {
    final parser = Parser();

    test('captures ParseError with precise location', () {
      final result = parser.parseWithDetails(
        'bar {\n    status_command i3status\n    position top\n',
      );
      expect(result, isA<ParseFailure>());
      final failure = result as ParseFailure;
      expect(failure.error.line, 1);
      expect(failure.error.column, 5);
    });

    test('parseWithDetails returns suggestion for malformed input', () {
      final invalidConfig = 'set \$mod "unterminated';

      final result = parser.parseWithDetails(invalidConfig);
      expect(result, isA<ParseFailure>());
      final failure = result as ParseFailure;
      expect(failure.error.line, 1);
      expect(failure.error.column, 10);
      expect(failure.suggestion, isNotNull);
      expect(failure.suggestion!.isNotEmpty, isTrue);
    });
  });

  group('Line continuation scenarios', () {
    test('handles multi-line command with inline comments', () {
      final content = '''
exec --no-startup-id my-script \\
    --option1 value1 \\
    --option2 value2
''';

      final config = Config.parse(content);
      expect(config.statements.length, 1);
      final command = config.statements.first as Command;
      final args = command.args
          .whereType<BareArg>()
          .map((a) => a.value)
          .toList();
      expect(args, [
        '--no-startup-id',
        'my-script',
        '--option1',
        'value1',
        '--option2',
        'value2',
      ]);
    });

    test('supports continued assignments with multiple values', () {
      final content = '''
set_from = alpha beta \\
    gamma delta \\
    epsilon
''';

      final config = Config.parse(content);
      expect(config.statements.length, 1);
      final assignment = config.statements.first as Assignment;
      final values = assignment.values.whereType<BareArg>().toList();
      expect(values.map((v) => v.value), [
        'alpha',
        'beta',
        'gamma',
        'delta',
        'epsilon',
      ]);
    });
  });

  group('Criteria and command chains', () {
    test('parses complex criteria with escaped characters', () {
      const content =
          'for_window [class="Firefox" title=".*\\"Browser\\".*"] exec reload';

      final config = Config.parse(content);
      expect(config.statements.first, isA<Command>());
      final command = config.statements.first as Command;
      expect(command.criteria, isNotNull);
      expect(command.criteria!.length, 2);
      expect(command.criteria![0].key, 'class');
      expect(command.criteria![1].key, 'title');
      expect((command.criteria![1].value as Quoted).value, contains('Browser'));
    });

    test('supports chained commands with trailing whitespace and comments', () {
      const content = 'exec terminal; exec editor; exec file-manager';

      final config = Config.parse(content);
      expect(config.statements.length, 3);
      expect((config.statements[0] as Command).head, 'exec');
      expect((config.statements[1] as Command).head, 'exec');
      expect((config.statements[2] as Command).head, 'exec');
    });
  });

  group('Nested blocks', () {
    test('parses nested blocks with assignment inline comments', () {
      final content = '''
resource {
  type "file"
  source "user_config.yml"
  destination "/etc/myapp/user_config.yml"
  require_root = true  # Default: all actions privileged

  actions {
    copy {
      # Inherits require_root = true from parent
    }
    permissions {
      mode "644"
      require_root = false  # Override: this action runs without privileges
    }
    validate {
      # Inherits require_root = true from parent
    }
  }
}
''';

      final config = Config.parse(content);
      final resource = config.statements.single as Command;

      expect(resource.head, 'resource');
      expect(resource.block, isNotNull);
      final actions =
          resource.block!.body.firstWhere(
                (element) => element is Command && element.head == 'actions',
                orElse: () => throw StateError('actions block not found'),
              )
              as Command;
      expect(actions.block, isNotNull);
      expect(actions.block!.body.whereType<Command>().map((c) => c.head), [
        'copy',
        'permissions',
        'validate',
      ]);
    });

    test('parses nested bar colors section', () {
      final content = '''
bar {
    status_command i3status
    colors {
        background #000000
        focused_workspace #ffffff #000000
    }
}
''';

      final config = Config.parse(content);
      final bar = config.statements.whereType<Command>().firstWhere(
        (command) => command.head == 'bar',
      );
      expect(bar.block, isNotNull);
      final colorsCommand =
          bar.block!.body.firstWhere(
                (element) => element is Command && element.head == 'colors',
                orElse: () => throw StateError('colors block not found'),
              )
              as Command;
      expect(colorsCommand.block, isNotNull);
      final nestedCommands = colorsCommand.block!.body.whereType<Command>().map(
        (c) => c.head,
      );
      expect(nestedCommands, containsAll(['background', 'focused_workspace']));
    });
  });
}
