import 'package:i3config/i3config_v2.dart';

/// Demonstrates dotted command heads, hex color values, inline comments,
/// and the formatter round-trip.
void main() {
  final config = Config.parse('''
# Color classes with dotted command heads
client.focused          #4c7899 #285577 #ffffff #2e9ef4 #285577
client.focused_inactive #333333 #5f676a #ffffff #484e50 #5f676a
client.unfocused        #333333 #222222 #888888 #292d2e #222222
client.urgent           #2f343a #900000 #ffffff #900000 #900000
client.placeholder      #000000 #0c0c0c #ffffff #000000 #0c0c0c
client.background       #ffffff

# Inline comments after commands
set \$mod Mod4
set \$term kitty                   # default terminal
bindsym \$mod+Return exec \$term    # launch terminal

# Block with dotted heads and inline comments
bar {
  client.focused #444  # inline in block
  client.unfocused #333 #222 #888
}
''');

  print('=== Parsed AST ===');
  for (final element in config.statements) {
    switch (element) {
      case Comment c:
        print('  Comment: ${c.content}');

      case Command c:
        final blockPart =
            c.block != null ? ' { ... } (${c.block!.body.length} children)' : '';
        final argsStr =
            c.args.map((a) => a.toConfigString()).join(' ');
        final comment =
            c.trailingComment != null
                ? '  ${c.trailingComment}'
                : '';
        print('  Command: ${c.head}${argsStr.isNotEmpty ? ' $argsStr' : ''}$blockPart$comment');

      case Block b:
        print('  Block: ${b.blockType} { ... } (${b.body.length} children)');

      case Assignment a:
        print('  Assignment: ${a.variable} ${a.operator} ${a.values}');

      case Config _:
    }
  }

  print('\n=== Formatted Output ===');
  final formatted = ConfigFormatter().format(config);
  print(formatted);

  print('=== Roundtrip Idempotent ===');
  final reparsed = Config.parse(formatted);
  final reformatted = ConfigFormatter().format(reparsed);
  print('Pass: ${formatted == reformatted}');

  print('\n=== Formatter Sorted ===');
  final sorted =
      ConfigFormatter(
        options: FormatterOptions(sortAssignments: true),
      ).format(config);
  print(sorted);
}
