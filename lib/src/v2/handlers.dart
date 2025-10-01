import 'visitor.dart';
import 'ast.dart';

/// Example handler for 'set' commands.
class SetCommandHandler implements CommandHandler {
  @override
  String get commandName => 'set';
  
  @override
  void handle(Command command, ProcessingContext context) {
    if (command.args.length >= 2) {
      final varRef = command.args[0];
      final value = command.args[1];
      
      if (varRef is VariableRef) {
        final varName = varRef.name;
        final varValue = _expandValue(value, context);
        context.setVariable(varName, varValue);
        
        // Optional: Log the variable setting
        print('Set variable: \$$varName = $varValue');
      }
    }
  }
  
  String _expandValue(Value value, ProcessingContext context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
      case VariableRef varRef:
        return context.getVariable(varRef.name) ?? '\$${varRef.name}';
      case BareArg bareArg:
        return context.expandVariables(bareArg.value);
    }
  }
}

/// Example handler for 'bindsym' commands.
class BindsymCommandHandler implements CommandHandler {
  @override
  String get commandName => 'bindsym';
  
  @override
  void handle(Command command, ProcessingContext context) {
    if (command.args.length >= 2) {
      final keyCombo = _expandValue(command.args[0], context);
      final action = _expandValue(command.args[1], context);
      
      // Store binding information in context
      final bindings = context.options['bindings'] as Map<String, String>? ?? <String, String>{};
      bindings[keyCombo] = action;
      context.options['bindings'] = bindings;
      
      print('Registered binding: $keyCombo -> $action');
    }
  }
  
  String _expandValue(Value value, ProcessingContext context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
      case VariableRef varRef:
        return context.getVariable(varRef.name) ?? '\$${varRef.name}';
      case BareArg bareArg:
        return context.expandVariables(bareArg.value);
    }
  }
}

/// Example handler for 'bar' blocks.
class BarBlockHandler implements BlockHandler {
  @override
  String get blockType => 'bar';
  
  @override
  void handle(Block block, ProcessingContext context) {
    print('Processing bar block...');
    
    // Note: Context management is now handled by the processor
    // This handler just processes the block contents
    
    // Process block contents
    for (final element in block.body) {
      if (element is Command) {
        _processBarCommand(element, context);
      }
    }
  }
  
  void _processBarCommand(Command command, ProcessingContext context) {
    switch (command.head) {
      case 'status_command':
        if (command.args.isNotEmpty) {
          final cmd = _expandValue(command.args[0], context);
          print('  Bar status command: $cmd');
        }
        break;
      case 'position':
        if (command.args.isNotEmpty) {
          final pos = _expandValue(command.args[0], context);
          print('  Bar position: $pos');
        }
        break;
      default:
        print('  Unknown bar command: ${command.head}');
    }
  }
  
  String _expandValue(Value value, ProcessingContext context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
      case VariableRef varRef:
        return context.getVariable(varRef.name) ?? '\$${varRef.name}';
      case BareArg bareArg:
        return context.expandVariables(bareArg.value);
    }
  }
}

/// Example handler for 'mode' blocks.
class ModeBlockHandler implements BlockHandler {
  @override
  String get blockType => 'mode';
  
  @override
  void handle(Block block, ProcessingContext context) {
    final modeName = block.identifier != null 
        ? _expandValue(block.identifier!, context)
        : 'unnamed';
    
    print('Processing mode block: $modeName');
    
    // Note: Context management is now handled by the processor
    // This handler just processes the block contents
    
    // Process block contents
    for (final element in block.body) {
      if (element is Command) {
        _processModeCommand(element, context);
      }
    }
  }
  
  void _processModeCommand(Command command, ProcessingContext context) {
    switch (command.head) {
      case 'bindsym':
        if (command.args.length >= 2) {
          final key = _expandValue(command.args[0], context);
          final action = _expandValue(command.args[1], context);
          print('  Mode binding: $key -> $action');
        }
        break;
      default:
        print('  Unknown mode command: ${command.head}');
    }
  }
  
  String _expandValue(Value value, ProcessingContext context) {
    switch (value) {
      case Quoted quoted:
        return context.expandVariables(quoted.value);
      case VariableRef varRef:
        return context.getVariable(varRef.name) ?? '\$${varRef.name}';
      case BareArg bareArg:
        return context.expandVariables(bareArg.value);
    }
  }
}

/// Example error handler.
class DefaultErrorHandler implements ErrorHandler {
  @override
  void handleError(dynamic error, ProcessingContext context) {
    print('Processing error: $error');
    // Could also log to file, send to monitoring system, etc.
  }
}

/// Example visitor that collects all commands by type.
class CommandCollectorVisitor implements ConfigVisitor<Map<String, List<Command>>> {
  final Map<String, List<Command>> _commands = {};
  
  @override
  Map<String, List<Command>> visitConfig(Config config) {
    _commands.clear();
    for (final element in config.statements) {
      _visitElement(element);
    }
    return Map.from(_commands);
  }
  
  @override
  Map<String, List<Command>> visitAssignment(Assignment assignment) {
    // Assignments are not commands, so we don't collect them here
    return _commands;
  }
  
  @override
  Map<String, List<Command>> visitCommand(Command command) {
    _commands.putIfAbsent(command.head, () => []).add(command);
    return _commands;
  }
  
  @override
  Map<String, List<Command>> visitBlock(Block block) {
    for (final element in block.body) {
      _visitElement(element);
    }
    return _commands;
  }
  
  @override
  Map<String, List<Command>> visitComment(Comment comment) {
    // Comments don't contain commands
    return _commands;
  }
  
  @override
  Map<String, List<Command>> visitValue(Value value) {
    // Values don't contain commands
    return _commands;
  }
  
  void _visitElement(ConfigElement element) {
    switch (element) {
      case Command command:
        visitCommand(command);
        break;
      case Block block:
        visitBlock(block);
        break;
      case Comment comment:
        visitComment(comment);
        break;
      default:
        // Handle other element types if needed
        break;
    }
  }
}

/// Example visitor that validates configuration.
class ConfigValidatorVisitor implements ConfigVisitor<List<String>> {
  final List<String> _errors = [];
  
  @override
  List<String> visitConfig(Config config) {
    _errors.clear();
    for (final element in config.statements) {
      _visitElement(element);
    }
    return List.from(_errors);
  }
  
  @override
  List<String> visitAssignment(Assignment assignment) {
    // Validate assignment structure
    if (assignment.variable.isEmpty) {
      _errors.add('Assignment has empty variable name');
    }
    
    // Operator validation is now handled by the enum - no need to check
    
    if (assignment.values.isEmpty) {
      _errors.add('Assignment has no values');
    }
    
    return _errors;
  }
  
  @override
  List<String> visitCommand(Command command) {
    // Validate command structure
    if (command.head.isEmpty) {
      _errors.add('Command has empty head');
    }
    
    // Validate specific commands
    switch (command.head) {
      case 'set':
        _validateSetCommand(command);
        break;
      case 'bindsym':
      case 'bindcode':
        _validateBindingCommand(command);
        break;
    }
    
    return _errors;
  }
  
  @override
  List<String> visitBlock(Block block) {
    // Validate block structure
    if (block.blockType?.isEmpty == true) {
      _errors.add('Block has empty type');
    }
    
    // Validate block contents
    for (final element in block.body) {
      _visitElement(element);
    }
    
    return _errors;
  }
  
  @override
  List<String> visitComment(Comment comment) {
    // Comments are always valid
    return _errors;
  }
  
  @override
  List<String> visitValue(Value value) {
    // Validate value structure
    switch (value) {
      case Quoted quoted:
        if (quoted.value.isEmpty) {
          _errors.add('Quoted string is empty');
        }
        break;
      case VariableRef varRef:
        if (varRef.name.isEmpty) {
          _errors.add('Variable reference has empty name');
        }
        break;
      case BareArg bareArg:
        if (bareArg.value.isEmpty) {
          _errors.add('Bare argument is empty');
        }
        break;
    }
    
    return _errors;
  }
  
  void _visitElement(ConfigElement element) {
    switch (element) {
      case Command command:
        visitCommand(command);
        break;
      case Block block:
        visitBlock(block);
        break;
      case Comment comment:
        visitComment(comment);
        break;
      default:
        // Handle other element types if needed
        break;
    }
  }
  
  void _validateSetCommand(Command command) {
    if (command.args.length < 2) {
      _errors.add('set command requires at least 2 arguments');
      return;
    }
    
    if (command.args[0] is! VariableRef) {
      _errors.add('set command first argument must be a variable reference');
    }
  }
  
  void _validateBindingCommand(Command command) {
    if (command.args.length < 2) {
      _errors.add('${command.head} command requires at least 2 arguments');
      return;
    }
    
    // Additional validation could be added here
  }
}
