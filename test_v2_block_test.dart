import 'package:i3config/i3config_v2.dart';

void main() {
  final parser = Parser();
  final result = parser.parseWithDetails('''
bar {
    status_command i3status  # status comment
    position top
}
''');
  if (result is ParseSuccess) {
    final bar = result.config.statements.first as Command;
    for (final stmt in bar.block!.body) {
      final s = stmt.toString();
      final truncated = s.length > 90 ? '${s.substring(0, 90)}...' : s;
      print('${stmt.runtimeType}: "$truncated"');
      if (stmt is Command && stmt.trailingComment != null) {
        print('  trailing: "${stmt.trailingComment}"');
      }
    }
  } else {
    final failure = result as ParseFailure;
    print('Parse error: ${failure.error}');
  }
}
