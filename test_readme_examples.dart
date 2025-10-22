import 'package:i3config/i3config.dart';

void main() {
  // Test basic parsing
  final config = Config.parse('''
  # Set mod key  
  set \$mod Mod4
  
  # Start terminal
  bindsym \$mod+Return exec i3-sensible-terminal
  ''');

  print('Parsed ${config.statements.length} statements');

  // Check what we actually get
  for (final statement in config.statements) {
    print('Statement type: ${statement.runtimeType}');

    if (statement.span != null) {
      final span = statement.span!;
      print(
        '  Location: line ${span.start.line + 1}, column ${span.start.column + 1}',
      );
      print('  Source: "${span.text.trim()}"');
    }

    if (statement is Command) {
      print('  Command: head="${statement.head}", args=${statement.args}');
    } else if (statement is Comment) {
      print('  Comment: "${statement.content}"');
    } else if (statement is Block) {
      print(
        '  Block: type="${statement.blockType}", body length=${statement.body.length}',
      );
    }
  }
}
