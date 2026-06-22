/// Test fixtures and example handlers for testing block-scoped handler functionality.
/// These are NOT part of the core library - just examples and test utilities.
library;

import 'package:i3config/i3config_v2.dart';

// ============================================================================
// EXAMPLE HANDLERS FOR TESTING
// ============================================================================

/// Example handler for 'bindsym' commands.
/// Used in tests to demonstrate global command handling.
class BindsymCommandHandler with ValueExpander implements CommandHandler {
  @override
  String get commandName => 'bindsym';

  @override
  void handle(Command command, Context context) {
    if (command.args.length >= 2) {
      final keyCombo = expandValue(command.args[0], context);
      final action = expandValue(command.args[1], context);

      final bindings =
          context.options['bindings'] as Map<String, String>? ??
          <String, String>{};
      bindings[keyCombo] = action;
      context.options['bindings'] = bindings;

      print('Registered binding: $keyCombo -> $action');
    }
  }
}

/// Example handler for 'bar' blocks.
/// Demonstrates the pattern where block handlers register their own scoped commands.
class BarBlockHandler
    with ValueExpander, DefaultChildProcessing
    implements BlockHandler {
  @override
  String get blockType => 'bar';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', BarStatusCommandHandler());
    registry.registerCommand('position', BarPositionCommandHandler());
  }

  @override
  void handle(Block block, Context context) {
    print('Processing bar block...');
  }
}

/// Example handler for 'mode' blocks.
/// Demonstrates registering a mode-specific bindsym handler.
class ModeBlockHandler
    with ValueExpander, DefaultChildProcessing
    implements BlockHandler {
  @override
  String get blockType => 'mode';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('bindsym', ModeBindsymHandler());
  }

  @override
  void handle(Block block, Context context) {
    final modeName = block.identifier != null
        ? expandValue(block.identifier!, context)
        : 'unnamed';

    print('Processing mode block: $modeName');
  }
}

/// Example block-scoped handler for 'status_command' in bar blocks.
class BarStatusCommandHandler with ValueExpander implements CommandHandler {
  @override
  String get commandName => 'status_command';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final statusCmd = expandValue(command.args[0], context);
      print('  Bar status command: $statusCmd');
    }
  }
}

/// Example block-scoped handler for 'position' in bar blocks.
class BarPositionCommandHandler with ValueExpander implements CommandHandler {
  @override
  String get commandName => 'position';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final position = expandValue(command.args[0], context);
      final validPositions = ['top', 'bottom', 'left', 'right'];
      if (validPositions.contains(position)) {
        print('  Bar position: $position');
      } else {
        print('  Warning: Invalid bar position: $position');
      }
    }
  }
}

/// Example block-scoped handler for 'bindsym' in mode blocks.
class ModeBindsymHandler with ValueExpander implements CommandHandler {
  @override
  String get commandName => 'bindsym';

  @override
  void handle(Command command, Context context) {
    if (command.args.length >= 2) {
      final key = expandValue(command.args[0], context);
      final action = expandValue(command.args[1], context);
      print('  Mode binding: $key -> $action');

      final globalContext = context.globalContext;
      final modeBindings =
          globalContext.options['mode_bindings'] as Map<String, String>? ??
          <String, String>{};
      modeBindings[key] = action;
      globalContext.options['mode_bindings'] = modeBindings;
    }
  }
}

/// Example error handler for testing.
class DefaultErrorHandler implements ErrorHandler {
  @override
  void handleError(dynamic error, Context context) {
    print('Processing error: $error');
  }
}

class CommandCollectorVisitor
    implements ConfigVisitor<Map<String, List<Command>>> {
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

  @override
  Map<String, List<Command>> visitArrayValue(ArrayValue value) {
    return _commands;
  }

  void _visitElement(ConfigElement element) {
    switch (element) {
      case Assignment assignment:
        visitAssignment(assignment);
        break;
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
      case ArrayValue array:
        if (array.items.isEmpty) {
          _errors.add('Array is empty');
        }
        break;
    }

    return _errors;
  }

  @override
  List<String> visitArrayValue(ArrayValue value) {
    return visitValue(value);
  }

  void _visitElement(ConfigElement element) {
    switch (element) {
      case Assignment assignment:
        visitAssignment(assignment);
        break;
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
