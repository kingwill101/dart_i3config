import 'package:i3config/i3config.dart';

void main() {
  // Test block parsing
  final config = Config.parse('''
bar {
    status_command i3status
    position top
}
''');

  print('Parsed ${config.statements.length} statements');

  for (final statement in config.statements) {
    print('Statement type: ${statement.runtimeType}');

    if (statement is Command) {
      print('  Command: head="${statement.head}", args=${statement.args}');
      if (statement.block != null) {
        print('    Has block with ${statement.block!.body.length} elements');
      }
    } else if (statement is Block) {
      print(
        '  Block: type="${statement.blockType}", body length=${statement.body.length}',
      );
    }
  }
}
