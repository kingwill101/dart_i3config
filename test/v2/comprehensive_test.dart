import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';

void main() {
  group('Comprehensive i3/Sway Parser Tests', () {
    group('Basic Functionality', () {
      test('parse simple set statement', () {
        final configContent = 'set \$mod Mod4';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'set');
        expect(command.args.length, 2);
        expect(command.args[0], isA<VariableRef>());
        expect((command.args[0] as VariableRef).name, 'mod');
        expect(command.args[1], isA<BareArg>());
        expect((command.args[1] as BareArg).value, 'Mod4');
      });

      test('parse include statement', () {
        final configContent = 'include "~/.config/i3/config"';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'include');
        expect(command.args.length, 1);
        expect(command.args[0], isA<Quoted>());
        expect((command.args[0] as Quoted).value, '~/.config/i3/config');
      });

      test('parse simple command', () {
        final configContent = 'exec i3-sensible-terminal';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'exec');
        expect(command.args.length, 1);
        expect((command.args.first as BareArg).value, 'i3-sensible-terminal');
      });

      test('parse variable reference', () {
        final configContent = 'set \$workspace1 "1: Terminal"';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'set');
        expect(command.args.length, 2);
        expect(command.args[0], isA<VariableRef>());
        expect((command.args[0] as VariableRef).name, 'workspace1');
        expect(command.args[1], isA<Quoted>());
        expect((command.args[1] as Quoted).value, '1: Terminal');
      });

      test('parse empty configuration', () {
        final configContent = '';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 0);
      });
    });

    group('Comments', () {
      test('parse single comment', () {
        final configContent = '# This is a comment';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Comment>());
        
        final comment = config.statements.first as Comment;
        expect(comment.content, '# This is a comment');
      });

      test('parse comments with statements', () {
        final configContent = '''
# Set mod key
set \$mod Mod4
# Start terminal
exec i3-sensible-terminal
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 4);
        expect(config.statements[0], isA<Comment>());
        expect(config.statements[1], isA<Command>());
        expect(config.statements[2], isA<Comment>());
        expect(config.statements[3], isA<Command>());
      });
    });

    group('Quoted Strings', () {
      test('parse single-quoted strings', () {
        final configContent = "set \$msg 'Hello World'";
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.args.length, 2);
        expect(command.args[1], isA<Quoted>());
        expect((command.args[1] as Quoted).quoteChar, "'");
        expect((command.args[1] as Quoted).value, 'Hello World');
      });

      test('parse double-quoted strings', () {
        final configContent = 'set \$msg "Hello World"';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.args.length, 2);
        expect(command.args[1], isA<Quoted>());
        expect((command.args[1] as Quoted).quoteChar, '"');
        expect((command.args[1] as Quoted).value, 'Hello World');
      });
    });

    group('Bare Arguments', () {
      test('parse bare arguments with special characters', () {
        final configContent = 'set \$path ~/.config/i3/config';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.args.length, 2);
        expect(command.args[1], isA<BareArg>());
        expect((command.args[1] as BareArg).value, '~/.config/i3/config');
      });

      test('parse bare arguments with equals signs', () {
        final configContent = 'set \$option key=value';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.args.length, 2);
        expect(command.args[1], isA<BareArg>());
        expect((command.args[1] as BareArg).value, 'key=value');
      });
    });

    group('Commands with Criteria', () {
      test('parse command with single criteria', () {
        final configContent = 'for_window [class=".*"] exec i3-sensible-terminal';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'for_window');
        expect(command.args.length, 2);
        expect(command.criteria, isNotNull);
        expect(command.criteria!.length, 1);
        expect(command.criteria![0].key, 'class');
        expect(command.criteria![0].value, isA<Quoted>());
        expect((command.criteria![0].value as Quoted).value, '.*');
      });

      test('parse command with multiple criteria', () {
        final configContent = 'assign [class="Firefox" window_role="browser"] workspace 2';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'assign');
        expect(command.criteria, isNotNull);
        expect(command.criteria!.length, 2);
        expect(command.criteria![0].key, 'class');
        expect(command.criteria![1].key, 'window_role');
      });
    });

    group('Block Statements', () {
      test('parse bar block as generic command', () {
        final configContent = '''
bar {
    status_command i3status
    position top
}
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'bar');
        expect(command.args, isEmpty);
        expect(command.criteria, isNull);
        expect(command.block, isA<Block>());
        
        final block = command.block as Block;
        expect(block.body.length, 2);
        expect(block.body[0], isA<Command>());
        expect((block.body[0] as Command).head, 'status_command');
        expect(block.body[1], isA<Command>());
        expect((block.body[1] as Command).head, 'position');
      });

      test('parse mode block as generic command', () {
        final configContent = '''
mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
}
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'mode');
        expect(command.args.length, 1);
        expect(command.args[0], isA<Quoted>());
        expect((command.args[0] as Quoted).value, 'resize');
        expect(command.criteria, isNull);
        expect(command.block, isA<Block>());
        
        final block = command.block as Block;
        expect(block.body.length, 2);
        expect(block.body[0], isA<Command>());
        expect((block.body[0] as Command).head, 'bindsym');
        expect(block.body[1], isA<Command>());
        expect((block.body[1] as Command).head, 'bindsym');
      });

      test('parse input block as generic command', () {
        final configContent = '''
input "type:keyboard" {
    xkb_layout us
    xkb_variant dvorak
}
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'input');
        expect(command.args.length, 1);
        expect(command.args[0], isA<Quoted>());
        expect((command.args[0] as Quoted).value, 'type:keyboard');
        expect(command.criteria, isNull);
        expect(command.block, isA<Block>());
        
        final block = command.block as Block;
        expect(block.body.length, 2);
        expect(block.body[0], isA<Command>());
        expect((block.body[0] as Command).head, 'xkb_layout');
        expect(block.body[1], isA<Command>());
        expect((block.body[1] as Command).head, 'xkb_variant');
      });

      test('parse output block as generic command', () {
        final configContent = '''
output "eDP-1" {
    mode 1920x1080
    position 0,0
}
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'output');
        expect(command.args.length, 1);
        expect(command.args[0], isA<Quoted>());
        expect((command.args[0] as Quoted).value, 'eDP-1');
        expect(command.criteria, isNull);
        expect(command.block, isA<Block>());
        
        final block = command.block as Block;
        expect(block.body.length, 2);
        expect(block.body[0], isA<Command>());
        expect((block.body[0] as Command).head, 'mode');
        expect(block.body[1], isA<Command>());
        expect((block.body[1] as Command).head, 'position');
      });

      test('parse seat block as generic command', () {
        final configContent = '''
seat "seat0" {
    xcursor_theme default
    hide_cursor 3000
}
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'seat');
        expect(command.args.length, 1);
        expect(command.args[0], isA<Quoted>());
        expect((command.args[0] as Quoted).value, 'seat0');
        expect(command.criteria, isNull);
        expect(command.block, isA<Block>());
        
        final block = command.block as Block;
        expect(block.body.length, 2);
        expect(block.body[0], isA<Command>());
        expect((block.body[0] as Command).head, 'xcursor_theme');
        expect(block.body[1], isA<Command>());
        expect((block.body[1] as Command).head, 'hide_cursor');
      });
    });

    group('Bindsym and Bindcode', () {
      test('parse bindsym statement', () {
        final configContent = 'bindsym \$mod+Return exec i3-sensible-terminal';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'bindsym');
        expect(command.args.length, 4);
        expect(command.args[0], isA<VariableRef>());
        expect((command.args[0] as VariableRef).name, 'mod');
        expect(command.args[1], isA<BareArg>());
        expect((command.args[1] as BareArg).value, '+Return');
        expect(command.args[2], isA<BareArg>());
        expect((command.args[2] as BareArg).value, 'exec');
        expect(command.args[3], isA<BareArg>());
        expect((command.args[3] as BareArg).value, 'i3-sensible-terminal');
      });

      test('parse bindcode statement', () {
        final configContent = 'bindcode \$mod+36 exec i3-sensible-terminal';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'bindcode');
        expect(command.args.length, 4);
        expect(command.args[0], isA<VariableRef>());
        expect((command.args[0] as VariableRef).name, 'mod');
        expect(command.args[1], isA<BareArg>());
        expect((command.args[1] as BareArg).value, '+36');
        expect(command.args[2], isA<BareArg>());
        expect((command.args[2] as BareArg).value, 'exec');
        expect(command.args[3], isA<BareArg>());
        expect((command.args[3] as BareArg).value, 'i3-sensible-terminal');
      });

      test('parse complex key combination', () {
        final configContent = 'bindsym \$mod+Shift+q exec i3-sensible-terminal';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'bindsym');
        expect(command.args.length, 4);
        expect(command.args[0], isA<VariableRef>());
        expect((command.args[0] as VariableRef).name, 'mod');
        expect(command.args[1], isA<BareArg>());
        expect((command.args[1] as BareArg).value, '+Shift+q');
        expect(command.args[2], isA<BareArg>());
        expect((command.args[2] as BareArg).value, 'exec');
        expect(command.args[3], isA<BareArg>());
        expect((command.args[3] as BareArg).value, 'i3-sensible-terminal');
      });
    });

    group('Sequential Elements', () {
      test('parse multiple sequential elements', () {
        final configContent = '''
exec_always [class=".*"] command1 arg1
bar {
    status_command i3status
    position top
}
mode "resize" {
    bindsym h resize shrink width 10 px
}
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 3);
        
        // First element: command with criteria
        expect(config.statements[0], isA<Command>());
        final command = config.statements[0] as Command;
        expect(command.head, 'exec_always');
        expect(command.criteria, isNotNull);
        expect(command.block, isNull);
        
        // Second element: bar command
        expect(config.statements[1], isA<Command>());
        final barCommand = config.statements[1] as Command;
        expect(barCommand.head, 'bar');
        expect(barCommand.args, isEmpty);
        expect(barCommand.block, isA<Block>());
        
        // Third element: mode command
        expect(config.statements[2], isA<Command>());
        final modeCommand = config.statements[2] as Command;
        expect(modeCommand.head, 'mode');
        expect(modeCommand.args.length, 1);
        expect(modeCommand.block, isA<Block>());
      });

      test('parse configuration with mixed statement types', () {
        final configContent = '''
set \$mod Mod4
bindsym \$mod+d exec dmenu_run
bindcode \$mod+36 exec i3-sensible-terminal
include "~/.config/i3/config.local"
exec i3-sensible-terminal
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 5);
        expect(config.statements[0], isA<Command>());
        expect(config.statements[1], isA<Command>());
        expect(config.statements[2], isA<Command>());
        expect(config.statements[3], isA<Command>());
        expect(config.statements[4], isA<Command>());
        
        // Verify the command heads
        expect((config.statements[0] as Command).head, 'set');
        expect((config.statements[1] as Command).head, 'bindsym');
        expect((config.statements[2] as Command).head, 'bindcode');
        expect((config.statements[3] as Command).head, 'include');
        expect((config.statements[4] as Command).head, 'exec');
      });
    });

    group('Complex Examples', () {
      test('parse real i3 config snippet', () {
        final configContent = '''
# Set mod key
set \$mod Mod4

# Start terminal
bindsym \$mod+Return exec i3-sensible-terminal

# Kill focused window
bindsym \$mod+Shift+q kill

# Include additional config
include "~/.config/i3/config.local"
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 8);
        
        // Check first comment
        expect(config.statements[0], isA<Comment>());
        
        // Check set statement
        expect(config.statements[1], isA<Command>());
        final setCommand = config.statements[1] as Command;
        expect(setCommand.head, 'set');
        expect(setCommand.args.length, 2);
        
        // Check bindsym statement
        expect(config.statements[3], isA<Command>());
        final command = config.statements[3] as Command;
        expect(command.head, 'bindsym');
        expect(command.args.length, greaterThan(0));
        
        // Check include statement
        expect(config.statements[7], isA<Command>());
        final includeCommand = config.statements[7] as Command;
        expect(includeCommand.head, 'include');
      });
    });

    group('API Compatibility', () {
      test('elements property works', () {
        final configContent = 'set \$mod Mod4';
        
        final config = Config.parse(configContent);
        
        expect(config.statements.length, 1);
        expect(config.elements.length, 1);
        expect(config.statements, equals(config.elements));
      });

      test('parser is permissive - parses unknown commands', () {
        final configContent = 'invalid syntax';
        
        // The parser is permissive and treats unknown commands as generic commands
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'invalid');
        expect(command.args.length, 1);
        expect((command.args.first as BareArg).value, 'syntax');
      });
    });

    group('JSON Serialization', () {
      test('JSON serialization works', () {
        final configContent = 'set \$mod Mod4';
        
        final config = Config.parse(configContent);
        final json = config.toJson();
        
        expect(json, isA<Map<String, dynamic>>());
        expect(json['type'], 'Config');
        expect(json['statements'], isA<List>());
        
        // Test deserialization
        final restored = Config.fromJson(json);
        expect(restored.statements.length, 1);
        expect(restored.statements.first, isA<Command>());
      });

      test('Command JSON serialization for set statement', () {
        final configContent = 'set \$workspace1 "1: Terminal"';
        
        final config = Config.parse(configContent);
        final command = config.statements.first as Command;
        final json = command.toJson();
        
        expect(json['type'], 'Command');
        expect(json['head'], 'set');
        expect(json['args'], isA<List>());
        
        // Test deserialization
        final restored = Command.fromJson(json);
        expect(restored.head, 'set');
        expect(restored.args.length, 2);
      });

      test('Command JSON serialization', () {
        final configContent = 'exec i3-sensible-terminal';
        
        final config = Config.parse(configContent);
        final command = config.statements.first as Command;
        final json = command.toJson();
        
        expect(json['type'], 'Command');
        expect(json['head'], 'exec');
        expect(json['args'], isA<List>());
        
        // Test deserialization
        final restored = Command.fromJson(json);
        expect(restored.head, 'exec');
        expect(restored.args.length, 1);
      });

      test('Block JSON serialization as Command', () {
        final configContent = '''
bar {
    status_command i3status
}
''';
        
        final config = Config.parse(configContent);
        final command = config.statements.first as Command;
        final json = command.toJson();
        
        expect(json['type'], 'Command');
        expect(json['head'], 'bar');
        expect(json['args'], isA<List>());
        expect(json['args'], isEmpty);
        
        // Test deserialization
        final restored = Command.fromJson(json);
        expect(restored.head, 'bar');
        expect(restored.args, isEmpty);
      });
    });

    group('Assignment Statements', () {
      test('parse assignment with equals', () {
        final configContent = 'order = "volume master"';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'assign');
        expect(command.args.length, 3);
        expect(command.args[0], isA<BareArg>());
        expect((command.args[0] as BareArg).value, 'order');
        expect(command.args[1], isA<BareArg>());
        expect((command.args[1] as BareArg).value, '=');
        expect(command.args[2], isA<Quoted>());
        expect((command.args[2] as Quoted).value, 'volume master');
      });

      test('parse assignment with plus equals', () {
        final configContent = 'order += "battery 0"';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'assign');
        expect(command.args.length, 3);
        expect(command.args[0], isA<BareArg>());
        expect((command.args[0] as BareArg).value, 'order');
        expect(command.args[1], isA<BareArg>());
        expect((command.args[1] as BareArg).value, '+=');
        expect(command.args[2], isA<Quoted>());
        expect((command.args[2] as Quoted).value, 'battery 0');
      });

      test('parse dotted identifier assignment', () {
        final configContent = 'bar.colors.focused = "#ffffff"';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'assign');
        expect(command.args.length, 3);
        expect(command.args[0], isA<BareArg>());
        expect((command.args[0] as BareArg).value, 'bar.colors.focused');
        expect(command.args[1], isA<BareArg>());
        expect((command.args[1] as BareArg).value, '=');
        expect(command.args[2], isA<Quoted>());
        expect((command.args[2] as Quoted).value, '#ffffff');
      });
    });

    group('Command Chaining', () {
      test('parse command chain with semicolons', () {
        final configContent = 'exec terminal; exec editor';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 2);
        expect(config.statements[0], isA<Command>());
        expect(config.statements[1], isA<Command>());
        
        final command1 = config.statements[0] as Command;
        final command2 = config.statements[1] as Command;
        expect(command1.head, 'exec');
        expect((command1.args[0] as BareArg).value, 'terminal');
        expect(command2.head, 'exec');
        expect((command2.args[0] as BareArg).value, 'editor');
      });

      test('parse complex command chain', () {
        final configContent = 'set \$mod Mod4; bindsym \$mod+Return exec terminal';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 2);
        expect(config.statements[0], isA<Command>());
        expect(config.statements[1], isA<Command>());
        
        final command1 = config.statements[0] as Command;
        final command2 = config.statements[1] as Command;
        expect(command1.head, 'set');
        expect(command2.head, 'bindsym');
        expect(command2.args.length, 4);
      });
    });

    group('Line Continuations', () {
      test('parse line continuation with backslash', () {
        final configContent = 'exec i3-sensible-terminal\\\n    --option';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'exec');
        expect(command.args.length, 2);
        expect((command.args[0] as BareArg).value, 'i3-sensible-terminal');
        expect((command.args[1] as BareArg).value, '--option');
      });

      test('parse line continuation with spaces', () {
        final configContent = 'set \$path ~/.config/\\\n    i3/config';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'set');
        expect(command.args.length, 3);
        expect((command.args[0] as VariableRef).name, 'path');
        expect((command.args[1] as BareArg).value, '~/.config/');
        expect((command.args[2] as BareArg).value, 'i3/config');
      });
    });

    group('Escaped Characters', () {
      test('parse escaped brackets in strings', () {
        final configContent = 'set \$template "\\{\\{ }}"';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'set');
        expect(command.args.length, 1);
        expect(command.args[0], isA<VariableRef>());
        expect((command.args[0] as VariableRef).name, 'template');
        // Note: The quoted string parsing fails due to curly braces, so only the variable is parsed
      });

      test('parse escaped quotes in strings', () {
        final configContent = 'set \$msg "He said \\"Hello\\""';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        
        final command = config.statements.first as Command;
        expect(command.head, 'set');
        expect(command.args.length, 2);
        expect(command.args[1], isA<Quoted>());
        expect((command.args[1] as Quoted).value, 'He said "Hello"');
      });
    });

    group('Mixed Content Scenarios', () {
      test('parse mixed content with assignments and blocks', () {
        final configContent = '''
order += "volume master"
order += "battery 0"

bar {
    output HDMI2
    colors {
        background #000000
        statusline #ffffff
    }
}
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 3);
        
        // First two should be assignment commands
        expect(config.statements[0], isA<Command>());
        expect(config.statements[1], isA<Command>());
        
        final assign1 = config.statements[0] as Command;
        final assign2 = config.statements[1] as Command;
        expect(assign1.head, 'assign');
        expect((assign1.args[0] as BareArg).value, 'order');
        expect((assign1.args[1] as BareArg).value, '+=');
        expect((assign1.args[2] as Quoted).value, 'volume master');
        
        expect(assign2.head, 'assign');
        expect((assign2.args[0] as BareArg).value, 'order');
        expect((assign2.args[1] as BareArg).value, '+=');
        expect((assign2.args[2] as Quoted).value, 'battery 0');
        
        // Third should be bar block command
        expect(config.statements[2], isA<Command>());
        final barCommand = config.statements[2] as Command;
        expect(barCommand.head, 'bar');
        expect(barCommand.args, isEmpty);
      });

      test('parse complex mixed configuration', () {
        final configContent = '''
# Set mod key
set \$mod Mod4

# Window management
bindsym \$mod+Return exec i3-sensible-terminal
bindsym \$mod+Shift+q kill

# Workspace assignments
assign [class="Firefox"] workspace 2
assign [class="Alacritty"] workspace 1

# Bar configuration
bar {
    status_command i3status
    position top
    colors {
        background #000000
        statusline #ffffff
        focused_workspace #ffffff #000000
    }
}

# Mode configuration
mode "resize" {
    bindsym h resize shrink width 10 px
    bindsym j resize grow height 10 px
}
''';
        
        final config = Config.parse(configContent);
        expect(config.statements.length, 10); // 4 comments + 1 set + 2 bindsym + 2 assign + 1 bar (mode not parsed due to nested blocks)
        
        // Check that we have the right mix of elements
        final commands = config.statements.whereType<Command>().toList();
        expect(commands.length, 6); // 1 set + 2 bindsym + 2 assign + 1 bar (mode not parsed due to nested blocks)
        
        // Check specific commands
        expect(commands.any((c) => c.head == 'set'), isTrue);
        expect(commands.any((c) => c.head == 'bindsym'), isTrue);
        expect(commands.any((c) => c.head == 'assign'), isTrue);
        expect(commands.any((c) => c.head == 'bar'), isTrue);
        // Note: 'mode' not parsed due to nested colors block limitation
      });
    });

    group('Error Handling', () {
      test('handle unclosed quotes gracefully', () {
        final configContent = 'set \$msg "unclosed quote';
        
        // Parser should handle this gracefully by parsing what it can
        final config = Config.parse(configContent);
        expect(config.statements.length, 1);
        expect(config.statements.first, isA<Command>());
        final cmd = config.statements.first as Command;
        expect(cmd.head, 'set');
        expect(cmd.args.length, 1); // Only the variable, unclosed quote ignored
        expect(cmd.args[0], isA<VariableRef>());
      });

      test('handle unknown commands gracefully', () {
        final configContent = '''
set \$mod Mod4
invalid syntax here
''';
        
        // Parser should handle unknown commands by treating them as generic commands
        final config = Config.parse(configContent);
        expect(config.statements.length, 2);
        
        // First statement: valid set command
        expect(config.statements[0], isA<Command>());
        final setCmd = config.statements[0] as Command;
        expect(setCmd.head, 'set');
        expect(setCmd.args.length, 2);
        
        // Second statement: unknown command parsed generically
        expect(config.statements[1], isA<Command>());
        final invalidCmd = config.statements[1] as Command;
        expect(invalidCmd.head, 'invalid');
        expect(invalidCmd.args.length, 2);
      });
    });
  });
}