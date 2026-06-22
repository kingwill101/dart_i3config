import 'package:i3config/i3config_v2.dart';

void main() {
  final parser = Parser();
  final result = parser.parseWithDetails('''
# Top comment
set \$mod Mod4  # inline
bindsym \$mod+Return exec terminal  # launch term

bar {
    status_command i3status  # status
    position top
}

# Full line after
set \$other "value"  # trailing on assign
''');
  if (result is ParseSuccess) {
    for (final stmt in result.config.statements) {
      final s = stmt.toString();
      final truncated = s.length > 90 ? '${s.substring(0, 90)}...' : s;
      print('${stmt.runtimeType}: "$truncated"');
    }
    
    // Test formatter
    final formatter = ConfigFormatter();
    final output = formatter.format(result.config);
    print('\n=== Formatted output ===');
    print(output);
    print('=== End ===');
    
    // Check trailing comments
    final stmts = result.config.statements;
    for (final stmt in stmts) {
      if (stmt is Command && stmt.trailingComment != null) {
        print('Command "${stmt.head}" has trailing: "${stmt.trailingComment}"');
      }
      if (stmt is Assignment && stmt.trailingComment != null) {
        print('Assignment "${stmt.variable}" has trailing: "${stmt.trailingComment}"');
      }
    }
  } else {
    final failure = result as ParseFailure;
    print('Parse error: ${failure.error}');
  }
}
