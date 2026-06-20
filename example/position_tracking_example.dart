#!/usr/bin/env dart

import 'package:i3config/i3config_v2.dart'
    show Assignment, Block, Command, Comment, Config, VariableRef;

Future<void> main() async {
  print('=== i3config Parser - Source Position Tracking Example ===\n');

  // Sample i3 configuration with various elements
  const configContent = '''# i3 configuration file
set \$mod Mod4
set \$terminal i3-sensible-terminal

# Key bindings
bindsym \$mod+Return exec \$terminal
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec rofi -show run

# Workspace navigation
bindsym \$mod+1 workspace number 1
bindsym \$mod+2 workspace number 2

mode "resize" {
    bindsym j resize shrink width 10 px or 10 ppt
    bindsym k resize grow height 10 px or 10 ppt
    bindsym Return mode "default"
}
''';

  print('Parsing configuration with source position tracking...\n');

  try {
    // Parse the configuration - positions are automatically tracked
    final config = Config.parse(configContent);

    print(
      'Successfully parsed ${config.statements.length} top-level statements\n',
    );

    // Demonstrate position tracking for different element types
    for (int i = 0; i < config.statements.length; i++) {
      final element = config.statements[i];

      print('--- Statement ${i + 1}: ${element.runtimeType} ---');

      // Show source position if available
      if (element.span != null) {
        final span = element.span!;
        print(
          'Location: Line ${span.start.line + 1}, Column ${span.start.column + 1}',
        );
        print('Source: "${span.text.replaceAll('\n', '\\n')}"');
      } else {
        print('No position information available');
      }

      // Element-specific information
      switch (element) {
        case Assignment assignment:
          // Property assignment like: order += "value"
          final op = assignment.operator; // enum AssignmentOperator
          print('Assignment: ${assignment.variable} ${op.symbol} ...');
          // Show values and their positions if available
          for (int j = 0; j < assignment.values.length; j++) {
            final value = assignment.values[j];
            if (value.span != null) {
              final vSpan = value.span!;
              print(
                '  Value ${j + 1}: "${vSpan.text}" at ${vSpan.start.line + 1}:${vSpan.start.column + 1}',
              );
            } else {
              print('  Value ${j + 1}: ${value.toString()}');
            }
          }

        case Comment comment:
          print('Content: "${comment.content}"');

        case Command command:
          print('Command: ${command.head}');
          print('Arguments: ${command.args.length}');

          // Show argument positions
          for (int j = 0; j < command.args.length; j++) {
            final arg = command.args[j];
            if (arg.span != null) {
              final argSpan = arg.span!;
              print(
                '  Arg ${j + 1}: "${argSpan.text}" at ${argSpan.start.line + 1}:${argSpan.start.column + 1}',
              );
            }
          }

          // Show criteria if present
          if (command.criteria != null) {
            print('Criteria: ${command.criteria!.length} items');
            for (final criterion in command.criteria!) {
              if (criterion.span != null) {
                print(
                  '  ${criterion.key}=${criterion.value} at ${criterion.span!.start.line + 1}:${criterion.span!.start.column + 1}',
                );
              }
            }
          }

          // Show block information
          if (command.block != null) {
            final block = command.block!;
            if (block.span != null) {
              print(
                'Block: ${block.body.length} statements at ${block.span!.start.line + 1}:${block.span!.start.column + 1}',
              );
            }
          }

        case Block block:
          print('Block type: ${block.blockType ?? 'generic'}');
          print('Body: ${block.body.length} statements');

        case Config config:
          print('Root config with ${config.statements.length} statements');
      }

      print('');
    }

    // Demonstrate practical usage: Find all variable definitions
    print('=== Practical Example: Finding Variable Definitions ===');
    findVariableDefinitions(config, configContent);
  } catch (e) {
    print('Parse error: $e');
  }
}

/// Example utility function that uses position information to find and report variable definitions
void findVariableDefinitions(Config config, String source) {
  print('Variable definitions found:');

  for (final statement in config.statements) {
    if (statement is Command &&
        statement.head == 'set' &&
        statement.args.length >= 2) {
      final varName = statement.args[0];
      final varValue = statement.args[1];

      if (varName is VariableRef && statement.span != null) {
        final line = statement.span!.start.line + 1;
        final column = statement.span!.start.column + 1;

        // VariableRef.name does not include the leading '$'
        print('  Variable: \$${varName.name}');
        print('    Value: ${varValue.toString()}');
        print('    Location: Line $line, Column $column');

        // Show the source line for context
        final lines = source.split('\n');
        if (line <= lines.length) {
          print('    Source: ${lines[line - 1].trim()}');
        }
        print('');
      }
    }
  }
}
