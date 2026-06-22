/// Shared example handlers used across multiple example files.
///
/// These provide realistic handler implementations for `bindsym`, `bar`,
/// `mode`, and other common i3 config constructs, without depending on
/// test-only code.
library;

import 'package:i3config/i3config_v2.dart';

// ============================================================================
// Bindsym Handler
// ============================================================================

/// Example handler for 'bindsym' commands.
class BindsymCommandHandler with ValueExpander implements CommandHandler {
  @override
  String get commandName => 'bindsym';

  @override
  void handle(Command command, Context context) {
    if (command.args.length >= 2) {
      final keyCombo = expandValue(command.args[0], context);
      final action = command.args
          .skip(1)
          .map((a) => expandValue(a, context))
          .join(' ');
      final bindings =
          context.options['bindings'] as Map<String, String>? ??
          <String, String>{};
      bindings[keyCombo] = action;
      context.options['bindings'] = bindings;
      print('Registered binding: $keyCombo -> $action');
    }
  }
}

// ============================================================================
// Bar Block Handler
// ============================================================================

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

// ============================================================================
// Mode Block Handler
// ============================================================================

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

class ModeBindsymHandler with ValueExpander implements CommandHandler {
  @override
  String get commandName => 'bindsym';

  @override
  void handle(Command command, Context context) {
    if (command.args.length >= 2) {
      final key = expandValue(command.args[0], context);
      final action = command.args
          .skip(1)
          .map((a) => expandValue(a, context))
          .join(' ');
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

// ============================================================================
// Error Handler
// ============================================================================

class DefaultErrorHandler implements ErrorHandler {
  @override
  void handleError(dynamic error, Context context) {
    print('Processing error: $error');
  }
}

// ============================================================================
// Visitors
// ============================================================================

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
    return _commands;
  }

  @override
  Map<String, List<Command>> visitValue(Value value) {
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
      case Command command:
        visitCommand(command);
      case Block block:
        visitBlock(block);
      case Comment comment:
        visitComment(comment);
      case Config config:
        visitConfig(config);
    }
  }
}

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
    if (assignment.variable.isEmpty) {
      _errors.add('Assignment has empty variable name');
    }
    if (assignment.values.isEmpty) {
      _errors.add('Assignment has no values');
    }
    return _errors;
  }

  @override
  List<String> visitCommand(Command command) {
    if (command.head.isEmpty) {
      _errors.add('Command has empty head');
    }
    switch (command.head) {
      case 'set':
        _validateSetCommand(command);
      case 'bindsym':
      case 'bindcode':
        _validateBindingCommand(command);
    }
    return _errors;
  }

  @override
  List<String> visitBlock(Block block) {
    if (block.blockType?.isEmpty == true) {
      _errors.add('Block has empty type');
    }
    for (final element in block.body) {
      _visitElement(element);
    }
    return _errors;
  }

  @override
  List<String> visitComment(Comment comment) {
    return _errors;
  }

  @override
  List<String> visitValue(Value value) {
    switch (value) {
      case Quoted quoted:
        if (quoted.value.isEmpty) {
          _errors.add('Quoted string is empty');
        }
      case VariableRef varRef:
        if (varRef.name.isEmpty) {
          _errors.add('Variable reference has empty name');
        }
      case BareArg bareArg:
        if (bareArg.value.isEmpty) {
          _errors.add('Bare argument is empty');
        }
      case ArrayValue array:
        if (array.items.isEmpty) {
          _errors.add('Array is empty');
        }
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
      case Command command:
        visitCommand(command);
      case Block block:
        visitBlock(block);
      case Comment comment:
        visitComment(comment);
      case Config config:
        visitConfig(config);
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
    }
  }
}
