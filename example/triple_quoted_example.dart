import 'package:i3config/i3config.dart';

/// Demonstrates triple-quoted string support (`"""..."""`) for
/// multi-line i3 config values.
void main() {
  final configSource = [
    '# Triple-quoted strings for multi-line exec commands',
    'set \$term kitty',
    'set \$launcher rofi -show drun',
    '',
    '# Multi-line exec command using """',
    'bindsym \$mod+Return exec --no-startup-id """',
    '  kitty --class "terminal" \\',
    '    -e "fish -l"',
    '"""',
    '',
    '# Variable assignment with multi-line message',
    'set \$motd """',
    '  Welcome to i3!',
    '"""',
    '',
    '# Triple-quoted string in an array (comma-separated)',
    'set \$fonts ["Noto Sans", """10""", "Noto Mono", """11, Antialias=true"""]',
  ].join('\n');

  final config = Config.parse(configSource);

  print('=== Parsed Statements ===');
  for (final element in config.statements) {
    switch (element) {
      case Assignment a:
        final values = a.values
            .map((v) => switch (v) {
                  TripleQuoted t => '"""${t.value}"""',
                  Quoted q => '"${q.value}"',
                  BareArg b => b.value,
                  ArrayValue a => '[${a.items.map((i) => i.toConfigString()).join(", ")}]',
                  InterpolatedString i => i.segments
                      .map((s) => s is ValueSegmentLiteral
                          ? s.text
                          : '\$${(s as ValueSegmentVariableReference).name}')
                      .join(),
                  BlockReference r => r.path.join('.'),
                  VariableRef v => '\$${v.name}',
                })
            .join(' ');
        print('  Assignment: ${a.variable} ${a.operator} $values');

      case Command c:
        final args = c.args
            .map((v) => switch (v) {
                  TripleQuoted t => '"""${t.value}"""',
                  Quoted q => '"${q.value}"',
                  BareArg b => b.value,
                  _ => v.toConfigString(),
                })
            .join(' ');
        print('  Command: ${c.head} $args');

      case Block b:
        print('  Block: ${b.blockType ?? "?"} {${b.body.length} children}');

      case Comment c:
        print('  Comment: ${c.content}');

      default:
        print('  ${element.runtimeType}');
    }
  }

  print('\n=== Formatted Output ===');
  final formatted = ConfigFormatter().format(config);
  print(formatted);

  print('=== Formatter Idempotent ===');
  final reparsed = Config.parse(formatted);
  final reformatted = ConfigFormatter().format(reparsed);
  print('Pass: ${formatted == reformatted}');
}
