import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';

void main() {
  group('Quoted String Interpolation', () {
    test('parses interpolated string with variable', () async {
      final configContent = 'set \$dir /home/user';
      final config = Config.parse(configContent);
      final cmd = config.statements.whereType<Command>().first;
      expect(cmd.head, 'set');
      expect(cmd.args.length, 2);
      expect(cmd.args[0], isA<VariableRef>());
      expect((cmd.args[0] as VariableRef).name, equals('dir'));
      expect(cmd.args[1], isA<BareArg>());
      expect((cmd.args[1] as BareArg).value, equals('/home/user'));

      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());
      await processor.process(config);
      expect(processor.context.getVariable('dir'), equals('/home/user'));
    });

    test('parses plain quoted string as Quoted not InterpolatedString', () {
      final configContent = 'set \$x "plain text"';
      final config = Config.parse(configContent);
      final cmd = config.statements.whereType<Command>().first;
      final value = cmd.args[1];
      expect(value, isA<Quoted>());
      expect(value, isNot(isA<InterpolatedString>()));
      expect((value as Quoted).value, equals('plain text'));
    });

    test('parses double-quoted with variable as InterpolatedString', () {
      final configContent = 'set \$x "hello \$world"';
      final config = Config.parse(configContent);
      final cmd = config.statements.whereType<Command>().first;
      final value = cmd.args[1];
      expect(value, isA<InterpolatedString>());
      final interp = value as InterpolatedString;
      expect(interp.segments.length, equals(3));
      expect(interp.segments[0], isA<ValueSegmentLiteral>());
      expect(interp.segments[1], isA<ValueSegmentVariableReference>());
      expect(interp.segments[2], isA<ValueSegmentLiteral>());
      expect((interp.segments[0] as ValueSegmentLiteral).text, equals('hello '));
      expect((interp.segments[1] as ValueSegmentVariableReference).name,
          equals('world'));
      expect((interp.segments[2] as ValueSegmentLiteral).text, equals(''));
    });

    test('single-quoted strings remain literal', () {
      final configContent = "set \$x 'no \$interpolation here'";
      final config = Config.parse(configContent);
      final cmd = config.statements.whereType<Command>().first;
      final value = cmd.args[1];
      expect(value, isA<Quoted>());
      expect(value, isNot(isA<InterpolatedString>()));
      expect((value as Quoted).value, equals('no \$interpolation here'));
    });

    test('expands variables in interpolated strings', () async {
      final configContent = '''
set \$dir /home/user
set \$full "base/\$dir/config"
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());
      await processor.process(config);

      expect(processor.context.getVariable('dir'), equals('/home/user'));
      expect(processor.context.getVariable('full'), equals('base//home/user/config'));
    });

    test('InterpolatedString toConfigString round-trips', () {
      final interp = InterpolatedString(
        [
          ValueSegmentLiteral('base/'),
          ValueSegmentVariableReference('dir'),
          ValueSegmentLiteral('/config'),
        ],
        '"',
      );
      expect(interp.toConfigString(), equals('"base/\$dir/config"'));
    });

    test('parses empty double-quoted string as Quoted', () {
      final configContent = 'set \$x ""';
      final config = Config.parse(configContent);
      final cmd = config.statements.whereType<Command>().first;
      final value = cmd.args[1];
      expect(value, isA<Quoted>());
      expect((value as Quoted).value, equals(''));
    });
  });

  group('Block References', () {
    test('parses dotted path as BlockReference', () {
      final configContent = 'set \$pos bar.main.position';
      final config = Config.parse(configContent);
      final cmd = config.statements.whereType<Command>().first;
      expect(cmd.args[1], isA<BlockReference>());
      expect((cmd.args[1] as BlockReference).path,
          equals(['bar', 'main', 'position']));
    });

    test('parses block reference without identifier', () {
      final configContent = 'set \$pos bar.position';
      final config = Config.parse(configContent);
      final cmd = config.statements.whereType<Command>().first;
      expect(cmd.args[1], isA<BlockReference>());
      expect((cmd.args[1] as BlockReference).path, equals(['bar', 'position']));
    });

    test('parses standalone variable as VariableRef not BlockReference', () {
      final configContent = 'set \$pos \$bar_pos';
      final config = Config.parse(configContent);
      final cmd = config.statements.whereType<Command>().first;
      expect(cmd.args[1], isA<VariableRef>());
      expect((cmd.args[1] as VariableRef).name, equals('bar_pos'));
    });

    test('resolves block reference from processed block', () async {
      final configContent = '''
bar "main" {
  status_command i3status
  position top
}
set \$pos bar.main.position
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('pos'), equals('top'));
    });

    test('resolves block reference without identifier', () async {
      final configContent = '''
bar {
  status_command i3status
}
set \$cmd bar.status_command
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('cmd'), equals('i3status'));
    });

    test('returns empty string for unresolved block reference', () async {
      final configContent = 'set \$pos nonexistent.foo';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      expect(processor.context.getVariable('pos'), equals(''));
    });

    test('BlockReference JSON serialization round-trip', () {
      final ref = BlockReference(['bar', 'main', 'position']);
      final json = ref.toJson();
      final restored = BlockReference.fromJson(json);
      expect(restored.path, equals(['bar', 'main', 'position']));
    });

    test('InterpolatedString JSON serialization round-trip', () {
      final interp = InterpolatedString(
        [
          ValueSegmentLiteral('hello '),
          ValueSegmentVariableReference('name'),
        ],
        '"',
      );
      final json = interp.toJson();
      final restored = InterpolatedString.fromJson(json);
      expect(restored.segments.length, equals(2));
      expect(restored.quoteChar, equals('"'));
    });
  });

  group('Include with Interpolated Path', () {
    test('resolves interpolated path in include', () async {
      final vfs = VirtualFileSystem();
      vfs.createFile('/home/user/.config/i3/bar.conf', 'set \$bar_value yes');

      final processor = ConfigProcessor(fileSystem: vfs);
      await processor.processString('''
set \$config_dir /home/user/.config/i3
include "\$config_dir/bar.conf"
''');

      expect(processor.context.getVariable('bar_value'), equals('yes'));
    });
  });
}
