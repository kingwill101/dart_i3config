import 'visitor.dart';
import 'ast.dart';

/// Built-in handler for 'set' commands (global variable assignment).
/// 
/// This is the ONLY handler included in the core library.
/// It provides basic support for setting global variables using the `set` command.
/// 
/// All other handlers (for blocks, other commands, etc.) should be implemented
/// by users as needed. See test/v2/test_handlers.dart for examples.
class SetCommandHandler with ValueExpander implements CommandHandler {
  @override
  String get commandName => 'set';
  
  @override
  void handle(Command command, ProcessingContext context) {
    if (command.args.length >= 2) {
      final varRef = command.args[0];
      final value = command.args[1];
      
      if (varRef is VariableRef) {
        final varName = varRef.name;
        final varValue = expandValue(value, context);
        context.setVariable(varName, varValue);
        
        // Optional: Log the variable setting
        print('Set variable: \$$varName = $varValue');
      }
    }
  }
}
