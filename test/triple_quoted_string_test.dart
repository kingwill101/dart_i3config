import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';

void main() {
  group('Triple-quoted strings', () {
    test('parses empty """ string', () {
      final config = Config.parse('set \$x """"""');
      final cmd = config.statements.whereType<Command>().first;
      expect(cmd.args.length, 2);
      expect(cmd.args[1], isA<TripleQuoted>());
      expect((cmd.args[1] as TripleQuoted).value, equals(''));
      expect((cmd.args[1] as TripleQuoted).delimiter, equals('"""'));
    });

    test('parses empty \'\'\' string', () {
      final config = Config.parse("set \$x ''''''");
      final cmd = config.statements.whereType<Command>().first;
      expect(cmd.args.length, 2);
      expect(cmd.args[1], isA<TripleQuoted>());
      expect((cmd.args[1] as TripleQuoted).value, equals(''));
      expect((cmd.args[1] as TripleQuoted).delimiter, equals("'''"));
    });

    test('parses """ with multi-line content', () {
      final config = Config.parse('set \$x """hello\nworld"""');
      final cmd = config.statements.whereType<Command>().first;
      expect(cmd.args[1], isA<TripleQuoted>());
      final tq = cmd.args[1] as TripleQuoted;
      expect(tq.value, equals('hello\nworld'));
      expect(tq.delimiter, equals('"""'));
    });

    test('parses """ with blank lines (preprocessible)', () {
      final content = 'set \$x """line1\n\nline2\n\n\nline3"""';
      final config = Config.parse(content);
      final cmd = config.statements.whereType<Command>().first;
      expect(cmd.args[1], isA<TripleQuoted>());
      final tq = cmd.args[1] as TripleQuoted;
      expect(tq.value, equals('line1\n\nline2\n\n\nline3'));
    });

    test('preserves literal quotes inside """', () {
      final config = Config.parse('set \$x """foo"bar"""');
      final cmd = config.statements.whereType<Command>().first;
      final tq = cmd.args[1] as TripleQuoted;
      expect(tq.value, equals('foo"bar'));
    });

    test('parses single-quote triple with apostrophes', () {
      final content = "set \$x '''it's here\nwon't stop'''";
      final config = Config.parse(content);
      final cmd = config.statements.whereType<Command>().first;
      final tq = cmd.args[1] as TripleQuoted;
      expect(tq.value, equals("it's here\nwon't stop"));
      expect(tq.delimiter, equals("'''"));
    });

    test('toConfigString roundtrips simple triple-quoted', () {
      final tq = TripleQuoted('hello\nworld', '"""');
      expect(tq.toConfigString(), equals('"""hello\nworld"""'));
    });

    test('toConfigString preserves backslash-laden content', () {
      final tq = TripleQuoted(r'path\to\file', '"""');
      expect(tq.toConfigString(), equals(r'''"""path\to\file"""'''));
    });

    test('toConfigString roundtrips single-quote triple', () {
      final tq = TripleQuoted("it's here", "'''");
      expect(tq.toConfigString(), equals("'''it's here'''"));
    });

    test(
      'toConfigString auto-switches delimiter when content contains """',
      () {
        final tq = TripleQuoted('foo"""bar', '"""');
        final out = tq.toConfigString();
        expect(out, equals("'''foo\"\"\"bar'''"));
      },
    );

    test(
      'toConfigString auto-switches delimiter when content contains \'\'\'',
      () {
        final tq = TripleQuoted("foo'''bar", "'''");
        final out = tq.toConfigString();
        expect(out, equals('"""foo\'\'\'bar"""'));
      },
    );

    test(
      'toConfigString fallback to single-quoted when both delimiters present',
      () {
        final tq = TripleQuoted('""" and \'\'\'', '"""');
        final out = tq.toConfigString();
        expect(out, startsWith("'"));
        expect(out, endsWith("'"));
      },
    );

    test('toConfigString output with auto-switch round-trips', () {
      final tq = TripleQuoted('foo"""bar', '"""');
      final out = tq.toConfigString();
      final reparsed = Config.parse('set \$x $out');
      final cmd = reparsed.statements.whereType<Command>().first;
      expect((cmd.args[1] as TripleQuoted).value, equals(tq.value));
    });

    test('toConfigString fallback to single-quoted round-trips', () {
      final tq = TripleQuoted('""" and \'\'\'', '"""');
      final out = tq.toConfigString();
      final reparsed = Config.parse('set \$x $out');
      final cmd = reparsed.statements.whereType<Command>().first;
      final arg = cmd.args[1];
      if (arg is TripleQuoted) {
        expect(arg.value, equals(tq.value));
      } else if (arg is Quoted) {
        expect(arg.value, equals(tq.value));
      } else {
        fail('Expected TripleQuoted or Quoted, got ${arg.runtimeType}');
      }
    });

    test('parse, format, and re-parse roundtrip', () {
      final content =
          'set \$title "My Title"\nset \$body """Line 1\nLine 2\nLine 3"""';
      final config = Config.parse(content);
      final formatter = ConfigFormatter();
      final output = formatter.format(config);
      expect(output, contains('"""Line 1'));
      expect(output, contains('Line 2'));
      expect(output, contains('Line 3"""'));
      final reparsed = Config.parse(output);
      final cmd = reparsed.statements.whereType<Command>().last;
      expect(
        (cmd.args[1] as TripleQuoted).value,
        equals('Line 1\nLine 2\nLine 3'),
      );
    });

    test('parser reports error on unclosed triple-quoted string', () {
      expect(
        () => Config.parse('set \$x """unclosed'),
        throwsA(isA<ParseError>()),
      );
    });

    test('triple-quoted in array values', () {
      final config = Config.parse('set \$x ["""a\nb""", c]');
      final cmd = config.statements.whereType<Command>().first;
      final array = cmd.args[1] as ArrayValue;
      expect(array.items.length, 2);
      expect(array.items[0], isA<TripleQuoted>());
      expect((array.items[0] as TripleQuoted).value, equals('a\nb'));
      expect(array.items[1], isA<BareArg>());
      expect((array.items[1] as BareArg).value, equals('c'));
    });

    test('JSON roundtrip', () {
      final tq = TripleQuoted('multi\nline', '"""');
      final json = tq.toJson();
      final restored = Value.fromJson(json);
      expect(restored, isA<TripleQuoted>());
      expect((restored as TripleQuoted).value, equals('multi\nline'));
      expect(restored.delimiter, equals('"""'));
    });

    test(
      'processor expandValue returns literal without variable substitution',
      () async {
        final config = Config.parse(
          'set \$name hello\nset \$body """\$name world"""',
        );
        final processor = ConfigProcessor();
        processor.registerCommandHandler(SetCommandHandler());
        await processor.process(config);
        // body value should be literal "$name world", not "hello world"
        expect(processor.context.getVariable('body'), equals('\$name world'));
      },
    );
  });
}
