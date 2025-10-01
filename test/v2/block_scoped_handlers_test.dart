import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';
import 'test_handlers.dart';

void main() {
  group('Block-Scoped Handler Registration', () {
    test('should register and retrieve block-scoped handlers', () {
      final processor = ConfigProcessor();
      final handler = BarStatusCommandHandler();
      
      processor.registerBlockScopedCommandHandler('bar', handler);
      
      final barHandlers = processor.getBlockScopedHandlers('bar');
      expect(barHandlers, isNotEmpty);
      expect(barHandlers['status_command'], equals(handler));
    });

    test('should return empty map for block type with no handlers', () {
      final processor = ConfigProcessor();
      
      final inputHandlers = processor.getBlockScopedHandlers('input');
      expect(inputHandlers, isEmpty);
    });

    test('should allow multiple handlers for same block type', () {
      final processor = ConfigProcessor();
      final statusHandler = BarStatusCommandHandler();
      final positionHandler = BarPositionCommandHandler();
      
      processor.registerBlockScopedCommandHandler('bar', statusHandler);
      processor.registerBlockScopedCommandHandler('bar', positionHandler);
      
      final barHandlers = processor.getBlockScopedHandlers('bar');
      expect(barHandlers.length, equals(2));
      expect(barHandlers['status_command'], equals(statusHandler));
      expect(barHandlers['position'], equals(positionHandler));
    });

    test('should allow same command name in different block types', () {
      final processor = ConfigProcessor();
      final globalBindsym = BindsymCommandHandler();
      final modeBindsym = ModeBindsymHandler();
      
      processor.registerCommandHandler(globalBindsym);
      processor.registerBlockScopedCommandHandler('mode', modeBindsym);
      
      final modeHandlers = processor.getBlockScopedHandlers('mode');
      expect(modeHandlers['bindsym'], equals(modeBindsym));
      expect(modeHandlers['bindsym'], isNot(equals(globalBindsym)));
    });
  });

  group('Handler Resolution Order', () {
    test('should use block-scoped handler over global handler', () {
      final configContent = '''
mode "resize" {
    bindsym h resize shrink width 10 px
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      // Register both global and block-scoped handlers
      processor.registerCommandHandler(BindsymCommandHandler());
      processor.registerBlockScopedCommandHandler('mode', ModeBindsymHandler());
      
      processor.process(config);
      
      // Verify mode-specific bindings were stored (from ModeBindsymHandler)
      final modeBindings = processor.context.options['mode_bindings'] as Map<String, String>?;
      expect(modeBindings, isNotNull);
    });

    test('should fall back to global handler when no block-scoped handler', () {
      final configContent = '''
set \$global_test "value"
bar {
    set \$block_test "block_value"
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      // Only register global set handler
      processor.registerCommandHandler(SetCommandHandler());
      
      processor.process(config);
      
      // Global variable should be accessible (from global SetCommandHandler)
      expect(processor.context.getVariable('global_test'), equals('value'));
      // Block variable should NOT be accessible (scoped to block which is now popped)
      expect(processor.context.getVariable('block_test'), isNull);
    });

    test('should use block-scoped handler for commands in blocks', () {
      final configContent = '''
bar {
    status_command i3status
    position top
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      // Register block-scoped handlers
      processor.registerBlockScopedCommandHandler('bar', BarStatusCommandHandler());
      processor.registerBlockScopedCommandHandler('bar', BarPositionCommandHandler());
      
      // Should not throw - handlers should be invoked
      expect(() => processor.process(config), returnsNormally);
    });

    test('should not use block-scoped handler outside of block', () {
      final configContent = '''
status_command i3status
bar {
    status_command i3bar_status
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      // Register block-scoped handler only
      processor.registerBlockScopedCommandHandler('bar', BarStatusCommandHandler());
      
      // The global status_command should use default processing (not throw)
      expect(() => processor.process(config), returnsNormally);
    });

    test('should handle multiple blocks with scoped handlers', () {
      final configContent = '''
bar {
    status_command i3status
}
mode "resize" {
    bindsym h resize shrink
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      processor.registerBlockHandler(BarBlockHandler());
      processor.registerBlockHandler(ModeBlockHandler());
      
      processor.process(config);
      
      // Verify mode bindings were processed
      final modeBindings = processor.context.options['mode_bindings'] as Map<String, String>?;
      expect(modeBindings, isNotNull);
      expect(modeBindings!['h'], equals('resize'));
    });
  });

  group('Block Hierarchy', () {
    test('should have null parentBlock by default', () {
      final configContent = '''
bar {
    position top
}
''';

      final config = Config.parse(configContent);
      final barBlock = config.statements.whereType<Command>().first;
      
      // Block is parsed as Command with optional block
      expect(barBlock, isA<Command>());
      final command = barBlock;
      expect(command.block, isNotNull);
      expect(command.block!.parentBlock, isNull);
    });

    test('should build block hierarchy when requested', () {
      final configContent = '''
bar {
    position top
}
mode "resize" {
    bindsym h resize shrink
}
''';

      final config = Config.parse(configContent);
      buildBlockHierarchy(config);
      
      // Top-level blocks should have null parent
      for (final statement in config.statements) {
        if (statement is Command && statement.block != null) {
          expect(statement.block!.parentBlock, isNull);
        }
      }
    });

    test('should link nested blocks to parents', () {
      // Create a nested structure manually for testing
      final innerBlock = Block('inner', null, []);
      final middleBlock = Block('middle', null, [innerBlock]);
      final outerBlock = Block('outer', null, [middleBlock]);
      final config = Config([outerBlock]);
      
      buildBlockHierarchy(config);
      
      expect(outerBlock.parentBlock, isNull);
      expect(middleBlock.parentBlock, equals(outerBlock));
      expect(innerBlock.parentBlock, equals(middleBlock));
    });

    test('should expose child blocks via getter', () {
      final child1 = Block('child1', null, []);
      final child2 = Block('child2', null, []);
      final comment = Comment('test comment');
      final parent = Block('parent', null, [child1, comment, child2]);
      
      final children = parent.childBlocks;
      expect(children.length, equals(2));
      expect(children, contains(child1));
      expect(children, contains(child2));
      expect(children, isNot(contains(comment)));
    });

    test('should return empty list when no child blocks', () {
      final command = Command('set', [VariableRef('var'), BareArg('value')]);
      final block = Block('empty', null, [command]);
      
      expect(block.childBlocks, isEmpty);
    });
  });

  group('Backward Compatibility', () {
    test('should not break existing global handler registration', () {
      final configContent = '''
set \$mod Mod4
bindsym \$mod+Return exec terminal
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      // Use old API only
      processor.registerCommandHandler(SetCommandHandler());
      processor.registerCommandHandler(BindsymCommandHandler());
      
      processor.process(config);
      
      expect(processor.context.getVariable('mod'), equals('Mod4'));
      final bindings = processor.context.options['bindings'] as Map<String, String>?;
      expect(bindings, isNotNull);
    });

    test('should work with existing block handlers', () {
      final configContent = '''
bar {
    status_command i3status
    position top
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      // Use old block handler API
      processor.registerBlockHandler(BarBlockHandler());
      
      expect(() => processor.process(config), returnsNormally);
    });

    test('should allow mixing old and new APIs', () {
      final configContent = '''
set \$mod Mod4
bar {
    status_command i3status
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      // Mix old and new APIs
      processor.registerCommandHandler(SetCommandHandler());
      processor.registerBlockScopedCommandHandler('bar', BarStatusCommandHandler());
      
      processor.process(config);
      
      expect(processor.context.getVariable('mod'), equals('Mod4'));
    });
  });

  group('Context Scoping with Block-Scoped Handlers', () {
    test('should maintain variable scoping with block-scoped handlers', () {
      final configContent = '''
set \$global "global_value"
bar {
    set \$local "local_value"
    status_command \$local
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      processor.registerCommandHandler(SetCommandHandler());
      processor.registerBlockScopedCommandHandler('bar', BarStatusCommandHandler());
      
      processor.process(config);
      
      // Global variable should be accessible
      expect(processor.context.getVariable('global'), equals('global_value'));
      
      // Local variable should not be accessible outside block
      expect(processor.context.getVariable('local'), isNull);
    });

    test('should resolve handlers in correct block context', () {
      final configContent = '''
mode "resize" {
    bindsym h resize shrink width 10 px
}
mode "move" {
    bindsym h move left 10 px
}
''';

      final config = Config.parse(configContent);
      final processor = ConfigProcessor();
      
      processor.registerBlockScopedCommandHandler('mode', ModeBindsymHandler());
      
      processor.process(config);
      
      // Both modes should be processed with the same handler
      final modeBindings = processor.context.options['mode_bindings'] as Map<String, String>?;
      expect(modeBindings, isNotNull);
      expect(modeBindings, isNotEmpty);
    });
  });
}

