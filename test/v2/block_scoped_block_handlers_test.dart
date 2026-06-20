import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';

void main() {
  group('Block-Scoped Block Handler Registration', () {
    test('via public API should invoke handler for nested block', () async {
      final config = Config.parse('''
alpha {
    beta {
        key value
    }
}
''');

      final processor = ConfigProcessor();
      final betaHandler = _TrackingHandler('beta');

      processor.registerBlockHandler(_NoopHandler('alpha'));
      processor.registerBlockScopedBlockHandler('alpha', betaHandler);

      await processor.process(config);

      expect(betaHandler.invoked, isTrue);
    });

    test('via registerScopedCommands should invoke handler for nested block',
        () async {
      final config = Config.parse('''
parent {
    child {
        key value
    }
}
''');

      final processor = ConfigProcessor();
      final childHandler = _TrackingHandler('child');
      final parentHandler = _ScopedRegistrar('parent', childHandler);

      processor.registerBlockHandler(parentHandler);

      await processor.process(config);

      expect(childHandler.invoked, isTrue);
    });

    test('should register multiple scoped block handlers', () async {
      final config = Config.parse('''
multi {
    sub_a {
        key a
    }
    sub_b {
        key b
    }
}
''');

      final processor = ConfigProcessor();
      final handlerA = _TrackingHandler('sub_a');
      final handlerB = _TrackingHandler('sub_b');
      final multiHandler = _MultiScopedRegistrar('multi', [
        handlerA,
        handlerB,
      ]);

      processor.registerBlockHandler(multiHandler);

      // Also register sub_b globally to verify scoped takes precedence
      processor.registerBlockHandler(_TrackingHandler('sub_b'));

      await processor.process(config);

      expect(handlerA.invoked, isTrue);
      expect(handlerB.invoked, isTrue);
    });
  });

  group('Handler Resolution Order', () {
    test('scoped handler takes precedence over global handler', () async {
      final config = Config.parse('''
container {
    item {
        key value
    }
}
''');

      final processor = ConfigProcessor();
      final globalHandler = _TrackingHandler('item');
      final scopedHandler = _TrackingHandler('item');

      processor.registerBlockHandler(globalHandler);
      processor.registerBlockHandler(
        _ScopedRegistrar('container', scopedHandler),
      );

      await processor.process(config);

      expect(scopedHandler.invoked, isTrue);
      expect(globalHandler.invoked, isFalse);
    });

    test('should fall back to global when no scoped block handler', () async {
      final config = Config.parse('''
wrapper {
    leaf {
        key value
    }
}
''');

      final processor = ConfigProcessor();
      final globalHandler = _TrackingHandler('leaf');

      processor.registerBlockHandler(_ScopedRegistrar('wrapper', null));
      processor.registerBlockHandler(globalHandler);

      await processor.process(config);

      expect(globalHandler.invoked, isTrue);
    });

    test('should fall through to default processing when no handler at all',
        () async {
      final config = Config.parse('''
unknown_block {
    some_command arg
}
''');

      final processor = ConfigProcessor();

      expect(() async => await processor.process(config), returnsNormally);
    });
  });

  group('Scope Isolation', () {
    test('scoped handler not invoked outside parent block', () async {
      final config = Config.parse('''
child {
    key value
}
wrapper {
    child {
        key value2
    }
}
''');

      final processor = ConfigProcessor();
      final globalInner = _TrackingHandler('child');
      final scopedInner = _TrackingHandler('child');

      processor.registerBlockHandler(globalInner);
      processor.registerBlockHandler(
        _ScopedRegistrar('wrapper', scopedInner),
      );

      await processor.process(config);

      expect(globalInner.invoked, isTrue);
      expect(scopedInner.invoked, isTrue);
    });

    test('scoped handler does not leak to sibling parent types', () async {
      final config = Config.parse('''
parent {
    child_a {
        key a
    }
}
other_parent {
    child_a {
        key other
    }
}
''');

      final processor = ConfigProcessor();
      final scoped = _TrackingHandler('child_a');
      final global = _TrackingHandler('child_a');

      processor.registerBlockHandler(_ScopedRegistrar('parent', scoped));
      processor.registerBlockHandler(global);

      await processor.process(config);

      expect(scoped.invoked, isTrue);
      expect(global.invoked, isTrue);
    });
  });

  group('Nested Scoping (3+ levels)', () {
    test('resolves scoped handlers at 3 levels deep', () async {
      final config = Config.parse('''
level_a {
    level_b {
        level_c {
            key value
        }
    }
}
''');

      final processor = ConfigProcessor();
      final handlerB = _TrackingHandler('level_b');
      final handlerC = _TrackingHandler('level_c');
      final globalC = _TrackingHandler('level_c');

      processor.registerBlockHandler(_ScopedRegistrar('level_a', handlerB));
      processor.registerBlockHandler(_ScopedRegistrar('level_b', handlerC));
      processor.registerBlockHandler(globalC);

      await processor.process(config);

      expect(handlerB.invoked, isTrue);
      expect(handlerC.invoked, isTrue);
      expect(globalC.invoked, isFalse);
    });

    test('handles each nesting level independently', () async {
      final config = Config.parse('''
root {
    middle {
        inner {
            key value
        }
    }
}
''');

      final processor = ConfigProcessor();
      final middleScoped = _TrackingHandler('middle');
      final innerScoped = _TrackingHandler('inner');
      final globalMiddle = _TrackingHandler('middle');
      final globalInner = _TrackingHandler('inner');

      processor.registerBlockHandler(_ScopedRegistrar('root', middleScoped));
      processor.registerBlockHandler(_ScopedRegistrar('middle', innerScoped));
      processor.registerBlockHandler(globalMiddle);
      processor.registerBlockHandler(globalInner);

      await processor.process(config);

      expect(middleScoped.invoked, isTrue);
      expect(innerScoped.invoked, isTrue);
      expect(globalMiddle.invoked, isFalse);
      expect(globalInner.invoked, isFalse);
    });

    test('tracks currentBlockType through nested scopes', () async {
      final config = Config.parse('''
resource {
    actions {
        copy {
            target /tmp/dest
        }
    }
}
''');

      final processor = ConfigProcessor();
      final blockTypes = <String?>[];

      processor.registerBlockHandler(
        _BlockTypeCaptureHandler('resource', blockTypes),
      );
      processor.registerBlockHandler(
        _BlockTypeCaptureHandler('actions', blockTypes),
      );
      processor.registerBlockHandler(
        _BlockTypeCaptureHandler('copy', blockTypes),
      );

      await processor.process(config);

      expect(blockTypes, contains('resource'));
      expect(blockTypes, contains('actions'));
      expect(blockTypes, contains('copy'));
    });
  });
}

// ============================================================================
// Test handler implementations
// ============================================================================

/// Simple handler that tracks whether its `handle` was invoked.
class _TrackingHandler with DefaultChildProcessing implements BlockHandler {
  final String _blockType;
  bool invoked = false;

  _TrackingHandler(this._blockType);

  @override
  String get blockType => _blockType;

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  void handle(Block block, Context context) {
    invoked = true;
  }
}

/// No-op handler with a given block type (no scoped children).
class _NoopHandler with DefaultChildProcessing implements BlockHandler {
  @override
  final String blockType;

  _NoopHandler(this.blockType);

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  void handle(Block block, Context context) {}
}

/// Registers a single optional block handler as scoped to this block type.
class _ScopedRegistrar with DefaultChildProcessing implements BlockHandler {
  @override
  final String blockType;
  final BlockHandler? _scopedChild;

  _ScopedRegistrar(this.blockType, this._scopedChild);

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    if (_scopedChild != null) {
      registry.registerScopedBlockHandler(
        _scopedChild.blockType,
        _scopedChild,
      );
    }
  }

  @override
  void handle(Block block, Context context) {}
}

/// Registers multiple scoped block handlers.
class _MultiScopedRegistrar
    with DefaultChildProcessing
    implements BlockHandler {
  @override
  final String blockType;
  final List<BlockHandler> _scopedChildren;

  _MultiScopedRegistrar(this.blockType, this._scopedChildren);

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    for (final child in _scopedChildren) {
      registry.registerScopedBlockHandler(child.blockType, child);
    }
  }

  @override
  void handle(Block block, Context context) {}
}

/// Captures the currentBlockType at invocation time.
class _BlockTypeCaptureHandler
    with DefaultChildProcessing
    implements BlockHandler {
  @override
  final String blockType;
  final List<String?> _captured;

  _BlockTypeCaptureHandler(this.blockType, this._captured);

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  void handle(Block block, Context context) {
    _captured.add(context.currentBlockType);
  }
}
