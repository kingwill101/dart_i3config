import 'package:i3config/i3config_v2.dart';

/// Example demonstrating simple AST iteration with V2 parser
/// without using the state machine - perfect for users who want
/// V2's improved parser but don't need the complexity of handlers.
Future<void> main() async {
  print('=== Simple AST Iteration with V2 Parser ===\n');

  final configContent = '''
# Global variables
set \$mod Mod4
set \$terminal alacritty

# Key bindings
bindsym \$mod+Return exec \$terminal
bindsym \$mod+Shift+q kill

# Bar configuration
bar "top" {
    status_command i3status
    position top
    height 30
}

# Array operations
order = book pencil sharpener
order += eraser
''';

  final config = Config.parse(configContent);
  
  print('📋 Configuration Elements:');
  print('=' * 50);
  
  for (final element in config.statements) {
    switch (element) {
      case Command command when command.block != null:
        print('📦 Block: ${command.head}');
        for (final child in command.block!.body) {
          if (child is Command) {
            print('  🔧 Command: ${child.head}');
            for (int i = 0; i < child.args.length; i++) {
              final arg = child.args[i];
              if (arg is BareArg) {
                print('    📝 Arg $i: ${arg.value}');
              } else if (arg is Quoted) {
                print('    💬 Arg $i: "${arg.value}"');
              } else if (arg is VariableRef) {
                print('    🔗 Arg $i: \$${arg.name}');
              }
            }
          } else if (child is Assignment) {
            print(
              '  ⚡ Assignment: ${child.variable} ${child.operator} '
              '${child.values.map((v) => v is BareArg ? v.value : v.toString()).join(' ')}',
            );
          }
        }
        break;
      case Command command:
        print('🔧 Command: ${command.head}');
        for (int i = 0; i < command.args.length; i++) {
          final arg = command.args[i];
          if (arg is BareArg) {
            print('  📝 Arg $i: ${arg.value}');
          } else if (arg is Quoted) {
            print('  💬 Arg $i: "${arg.value}"');
          } else if (arg is VariableRef) {
            print('  🔗 Arg $i: \$${arg.name}');
          }
        }
        break;
      case Assignment assignment:
        print(
          '⚡ Assignment: ${assignment.variable} ${assignment.operator} '
          '${assignment.values.map((v) => v is BareArg ? v.value : v.toString()).join(' ')}',
        );
        break;
      case Comment comment:
        print('💭 Comment: ${comment.content}');
        break;
      default:
        print('ℹ️  ${element.runtimeType}');
        break;
    }
  }
  
  print('\n🔍 Finding Specific Elements:');
  print('=' * 50);
  
  // Find all set commands
  final setCommands = config.statements
      .whereType<Command>()
      .where((c) => c.head == 'set');
  
  print('📋 Set Commands:');
  for (final cmd in setCommands) {
    if (cmd.args.length >= 2) {
      final varRef = cmd.args[0];
      final value = cmd.args[1];
      if (varRef is VariableRef && value is BareArg) {
        print('  \$${varRef.name} = ${value.value}');
      }
    }
  }
  
  // Find all key bindings
  final bindsymCommands = config.statements
      .whereType<Command>()
      .where((c) => c.head == 'bindsym');
  
  print('\n⌨️  Key Bindings:');
  for (final cmd in bindsymCommands) {
    if (cmd.args.length >= 2) {
      final key = cmd.args[0];
      final action = cmd.args[1];
      if (key is BareArg && action is BareArg) {
        print('  ${key.value} -> ${action.value}');
      }
    }
  }
  
  // Find all assignments
  final assignments = config.statements.whereType<Assignment>();
  
  print('\n📊 Assignments:');
  for (final assignment in assignments) {
    print('  ${assignment.variable} ${assignment.operator} ${assignment.values.map((v) => v is BareArg ? v.value : v.toString()).join(' ')}');
  }
  
  print('\n✅ Benefits of this approach:');
  print('• V2\'s improved parser without state machine complexity');
  print('• Direct control over element processing');
  print('• No async processing overhead');
  print('• Easy to understand and maintain');
  print('• Perfect for simple configuration analysis');
}
