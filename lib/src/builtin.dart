import 'package:i3config/src/context.dart' show Context;
import 'package:i3config/src/base_handlers.dart' show BaseCommandHandler;
import 'package:i3config/src/ast.dart' show Command;
import 'package:i3config/src/value.dart';

/// Built-in handler for 'set' commands (global variable assignment).
///
/// This is the ONLY handler included in the core library.
/// It provides basic support for setting global variables using the `set` command.
///
/// All other handlers (for blocks, other commands, etc.) should be implemented
/// by users as needed. See test/test_handlers.dart for examples.
class SetCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'set';

  @override
  String? handle(Command command, Context context) {
    if (command.args.length >= 2) {
      final varRef = command.args[0];
      final value = command.args[1];

      if (varRef is VariableRef) {
        final varName = varRef.name;
        final varValue = expandValue(value, context);
        context.setVariable(varName, varValue);

        // Log only when verbose mode is enabled
        if (context.options['verbose'] == true) {
          print('Set variable: \$$varName = $varValue');
        }

        // Return the value that was set
        return varValue;
      }
    }
    return null;
  }
}
