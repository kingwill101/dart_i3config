import 'package:i3config/i3config_v2.dart';

Future<void> main() async {
  final configContent = '''
# Set mod key
set \$mod Mod4

# Basic key bindings
bindsym \$mod+Return exec i3-sensible-terminal
bindsym \$mod+Shift+q kill

# Variable assignment
set \$terminal i3-sensible-terminal
''';

final config = Config.parse(configContent);
  print('Parsed ${config.statements.length} configuration statements\n');

  // Access specific statements
  for (final statement in config.statements) {
    switch (statement) {
      case Assignment assignment:
        final values = assignment.values
            .map((value) => switch (value) {
                  BareArg bare => bare.value,
                  Quoted quoted => '"${quoted.value}"',
                  VariableRef ref => '\$${ref.name}',
                })
            .join(' ');
        print('Assignment → ${assignment.variable} ${assignment.operator} $values');
        break;
      case Command command:
        final args = command.args
            .map((value) => switch (value) {
                  BareArg bare => bare.value,
                  Quoted quoted => '"${quoted.value}"',
                  VariableRef ref => '\$${ref.name}',
                })
            .join(' ');
        print('Command    → ${command.head} $args');
        break;
      case Comment comment:
        print('Comment    → ${comment.content}');
        break;
      default:
        print('Statement  → ${statement.runtimeType}');
        break;
    }
  }

  // Quick access to all assignments using the new API
  final assignments = config.statements.whereType<Assignment>().toList();
  print('\nFound ${assignments.length} assignment statement(s).');
}
