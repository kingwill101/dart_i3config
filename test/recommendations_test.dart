import 'dart:async';

import 'package:test/test.dart';
import 'package:i3config/i3config_v2.dart';
import 'package:source_span/source_span.dart';

void main() {
  group('Issue #1: Command args inaccessible to block handlers', () {
    test('block handle() receives only Block, not Command with args', () async {
      final configContent = '''
host "web-01" {
    set \$addr "10.0.0.1"
}
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      String? capturedIdentifier;

      processor.registerBlockHandler(
        _IdentifierCapturingBlockHandler(
          onIdentifier: (id) => capturedIdentifier = id,
        ),
      );

      await processor.process(config);

      expect(capturedIdentifier, isNull);
    });

    test('identifier stored in blockRegistry AFTER afterChildrenProcessed',
        () async {
      final configContent = '''
host "web-01" {
    set \$addr "10.0.0.1"
}
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      processor.registerCommandHandler(SetCommandHandler());
      processor.registerBlockHandler(_AfterChildrenCheckHandler());

      await processor.process(config);

      final hosts = processor.context.blockRegistry['host'];
      expect(hosts, containsPair('web-01', containsPair('addr', '10.0.0.1')));
    });
  });

  group('Issue #2: processChildren return semantics', () {
    test('BaseBlockHandler.processChildren returns null (not false)', () {
      final handler = _DefaultProcessHandler();
      final context = Context();
      final block = Block('test', null, []);

      final result = handler.processChildren(block, context);
      expect(result, isNull);
    });

    test('BUG: async processChildren returning null DOES NOT trigger default processing',
        () async {
      // This test documents the bug: an async method that "returns null"
      // actually returns a non-null Future<void>, which causes the processor
      // to believe custom processing was provided and skip defaults.
      final configContent = '''
test_block {
    set \$var "value"
}
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      processor.registerCommandHandler(SetCommandHandler());
      processor.registerBlockHandler(_NullAsyncProcessHandler());

      await processor.process(config);

      // BUG: Default processing is skipped even though handler "returned null"
      expect(processor.context.getVariable('var'), isNull);
    });

    test('custom processChildren returning non-null Future skips defaults',
        () async {
      final configContent = '''
test_block {
    set \$var "value"
}
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      processor.registerBlockHandler(_NonNullAsyncProcessHandler());

      await processor.process(config);

      expect(processor.context.getVariable('var'), isNull);
    });

    test('async override always returns non-null Future (cannot use defaults)',
        () async {
      final handler = _AsyncOverrideHandler();
      final block = Block('test', null, []);
      final context = Context();

      final result = handler.processChildren(block, context);
      expect(result, isNotNull);
    });
  });

  group('Issue #3: Missing parent pointers on ConfigElement', () {
    test('ConfigElement has parent field but it is null before buildBlockHierarchy',
        () {
      final child = Block('child', null, []);
      final parent = Block('parent', null, [child]);

      // Before buildBlockHierarchy, parent is null
      expect(child.parent, isNull);
      expect((child as Block).parentBlock, isNull);
    });

    test('buildBlockHierarchy sets parent pointers', () {
      final inner = Block('inner', null, []);
      final middle = Block('middle', null, [inner]);
      final outer = Block('outer', null, [middle]);
      final config = Config([outer]);

      buildBlockHierarchy(config);

      expect(outer.parent, isNull);
      expect(middle.parent, equals(outer));
      expect(inner.parent, equals(middle));
    });

    test('handler can access parent Command from nested Block', () {
      final innerBlock = Block('inner', null, []);
      final hostCmd = Command('host', [BareArg('web-01')], null, innerBlock);
      final outerBlock = Block('inventory', null, [hostCmd]);
      final config = Config([outerBlock]);

      buildBlockHierarchy(config);

      // After buildBlockHierarchy, innerBlock.parent should be hostCmd
      expect(innerBlock.parent, equals(hostCmd));
      // And hostCmd.parent should be outerBlock
      expect(hostCmd.parent, equals(outerBlock));
    });
  });

  group('Issue #4: Inline blocks with semicolons', () {
    test('top-level inline block with semicolons parses', () {
      final configContent = r'''
host "web-01" { set \$addr "10.0.0.1"; set \$roles "[\"web\"]" }
''';

      final config = Config.parse(configContent);
      final cmd = config.statements.whereType<Command>().first;
      expect(cmd.head, 'host');
      expect(cmd.block, isNotNull);
    });

    test('nested inline blocks with semicolons parse correctly', () {
      final configContent = r'''
inventory {
    host "web-01" { set \$addr "10.0.0.1"; set \$roles "[\"web\"]" }
}
''';

      // Nested inline blocks with semicolons work in current implementation
      final config = Config.parse(configContent);
      expect(config.statements.length, 1);
      final outerCmd = config.statements.whereType<Command>().first;
      expect(outerCmd.head, 'inventory');
      final innerCmd = outerCmd.block!.body.whereType<Command>().first;
      expect(innerCmd.head, 'host');
    });

    test('multi-line nested block with semicolons on separate lines parses',
        () async {
      final configContent = '''
inventory {
    host "web-01" {
        set \$addr "10.0.0.1"
        set \$roles "[\"web\"]"
    }
}
''';

      final config = Config.parse(configContent);
      expect(config.statements.length, 1);
    });
  });

  group('Issue #5: expandValue not available as static/utility', () {
    test('plain BlockHandler without ValueExpander lacks expandValue', () {
      final handler = _PlainBlockHandler();

      expect(handler, isNot(isA<ValueExpander>()));
    });

    test('ValueExpander mixin provides expandValue', () {
      final handler = _MixinBlockHandler();
      final context = Context();
      context.setVariable('name', 'world');

      final result = handler.expandValue(BareArg('hello'), context);
      expect(result, 'hello');
    });
  });

  group('Issue #6: Better Context API for variable handling', () {
    test('getVariable returns dynamic without type safety', () {
      final context = Context();
      context.setVariable('str', 'hello');
      context.setVariable('num', 42);

      final strVal = context.getVariable('str');
      expect(strVal, isA<String>());

      final numVal = context.getVariable('num');
      expect(numVal, isA<int>());
    });

    test('no typed accessors (getString, getList, getBool)', () {
      final context = Context();
      context.setVariable('str', 'hello');
      context.setVariable('arr', ['a', 'b']);

      // getVariable returns dynamic; there are no typed accessors
      final strVal = context.getVariable('str');
      expect(strVal, isA<String>());

      final arrVal = context.getVariable('arr');
      expect(arrVal, isA<List>());
      // List<dynamic> requires manual casting
      final list = arrVal as List<dynamic>;
      expect(list.map((e) => e as String).toList(), ['a', 'b']);
    });

    test('no distinction between unset and empty string', () {
      final context = Context();

      expect(context.getVariable('missing'), isNull);
      context.setVariable('empty', '');
      expect(context.getVariable('empty'), '');
    });
  });

  group('Issue #7: blockRegistry data flow transparency', () {
    test('registerBlock stores data after children processed', () async {
      final configContent = '''
host "web-01" {
    set \$addr "10.0.0.1"
}
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      processor.registerCommandHandler(SetCommandHandler());

      await processor.process(config);

      final hosts = processor.context.blockRegistry['host'];
      expect(hosts, containsPair('web-01', containsPair('addr', '10.0.0.1')));
    });

    test('no getChildBlock / getAllBlocks / countBlock helpers', () {
      final context = Context();

      // User must navigate blockRegistry manually via nested map access
      final hosts = context.blockRegistry;
      expect(hosts, isEmpty);
    });
  });

  group('Issue #8: Variable middleware extensibility', () {
    test('VariableMiddleware can transform values on set', () {
      final context = Context();
      final mw = _UppercaseMiddleware();
      context.registerVariableMiddleware(mw);

      context.setVariable('name', 'hello');
      expect(context.getVariable('name'), 'HELLO');
    });

    test('VariableMiddleware can reject sets by returning null', () {
      final context = Context();
      final mw = _RejectingMiddleware();
      context.registerVariableMiddleware(mw);

      context.setVariable('secret', 'value');
      expect(context.getVariable('secret'), isNull);
    });

    test('VariableMiddleware can transform values on get', () {
      final context = Context();
      context.setVariable('raw', 'data');

      final mw = _PrefixMiddleware();
      context.registerVariableMiddleware(mw);

      expect(context.getVariable('raw'), 'PREFIX:data');
    });

    test('VariableMiddleware can block gets by returning null', () {
      final context = Context();
      context.setVariable('hidden', 'data');

      final mw = _BlockGetMiddleware();
      context.registerVariableMiddleware(mw);

      expect(context.getVariable('hidden'), isNull);
    });

    test('VariableMiddleware can redact variable references in expandVariables',
        () {
      final context = Context();
      context.setVariable('password', 's3cret123');

      final mw = _RedactionMiddleware(['password']);
      context.registerVariableMiddleware(mw);

      // Middleware replaces the variable reference before substitution
      final result = context.expandVariables(r'login with $password');
      expect(result, 'login with <REDACTED>');
      // Raw value still accessible via getVariable
      expect(context.getVariable('password'), 's3cret123');
    });

    test('VariableMiddleware can skip expansion by returning null', () {
      final context = Context();
      context.setVariable('x', '1');

      final mw = _SkipExpandMiddleware();
      context.registerVariableMiddleware(mw);

      final result = context.expandVariables(r'value is $x');
      expect(result, r'value is $x');
    });

    test('multiple middleware run in registration order', () {
      final context = Context();
      context.registerVariableMiddleware(_UppercaseMiddleware());
      context.registerVariableMiddleware(_PrefixMiddleware());

      context.setVariable('key', 'val');
      // Set: Uppercase transforms "val" -> "VAL", then Prefix prepends "PREFIX:"
      expect(context.getVariable('key'), 'PREFIX:VAL');
    });

    test('middleware sees parent context values on get', () {
      final parent = Context();
      parent.setVariable('shared', 'parent_val');

      final child = parent.pushContext();
      child.registerVariableMiddleware(_SuffixMiddleware());

      expect(child.getVariable('shared'), 'parent_val_suffix');
    });

    test('middleware onExpand sees interpolated values before substitution',
        () {
      final context = Context();
      context.setVariable('key', 'secret');

      final mw = _LoggingMiddleware();
      context.registerVariableMiddleware(mw);

      final logs = <String>[];
      mw.logs = logs;

      context.expandVariables(r'the value is $key');
      expect(logs, contains(r'expanding: the value is $key'));
    });

    test('processor-level middleware propagates to root context', () async {
      final processor = ConfigProcessor();
      processor.registerVariableMiddleware(_PrefixMiddleware());

      await processor.processString('set \$x hello');

      expect(processor.context.getVariable('x'), 'PREFIX:hello');
    });

    test('processor-level middleware propagates to child contexts', () async {
      final processor = ConfigProcessor();
      processor.registerVariableMiddleware(_PrefixMiddleware());

      await processor.processString('''
set \$x hello
block "test" {
    set \$y world
}
''');

      // After processing a block, variables are in block contexts
      expect(processor.context.getVariable('x'), 'PREFIX:hello');
    });

    test('processor-level middleware respects registration order with context-level',
        () async {
      final processor = ConfigProcessor();
      // Processor: uppercase first
      processor.registerVariableMiddleware(_UppercaseMiddleware());

      await processor.processString('set \$x hello');

      // Then register context-level prefix middleware
      processor.context.registerVariableMiddleware(_PrefixMiddleware());

      // Processor middleware runs first (uppercase), then context (prefix)
      processor.context.setVariable('y', 'val');
      expect(processor.context.getVariable('y'), 'PREFIX:VAL');
    });

    test('processor middleware on set propagates through processString',
        () async {
      final processor = ConfigProcessor();
      processor.registerVariableMiddleware(_UppercaseMiddleware());

      await processor.processString('''
set \$name alice
set \$greeting "hello \$name"
''');

      // All variables should be uppercased by processor middleware
      expect(processor.context.getVariable('name'), 'ALICE');
      expect(processor.context.getVariable('greeting'), 'HELLO ALICE');
    });
  });

  group('Issue #9: Error reporting with source location', () {
    test('reportError accepts optional SourceSpan', () {
      final context = Context();
      expect(() => context.reportError('test error', span: null),
          returnsNormally);
    });

    test('parse errors include line/column', () {
      final configContent = '''
host "web-01" {
    set
''';
      try {
        Config.parse(configContent);
        fail('Should have thrown ParseError');
      } on ParseError catch (e) {
        expect(e.line, greaterThan(0));
        expect(e.column, greaterThan(0));
      }
    });

    test('handler errors without span lack location info', () async {
      final configContent = '''
test_block {
    bad_cmd
}
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      final errors = <String>[];
      processor.setErrorHandler(_CollectingErrorHandler(errors));

      processor.registerBlockHandler(_ErrorReportingBlockHandler());

      await processor.process(config);

      expect(errors, isNotEmpty);
    });
  });

  group('Issue #10: Handler lifecycle documentation', () {
    test(
        'afterChildrenProcessed is only called on BaseBlockHandler subclasses',
        () async {
      final phases = <String>[];
      final configContent = '''
test_block {
    inner_cmd
}
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      // Plain BlockHandler implementation - afterChildrenProcessed won't be called
      processor.registerBlockHandler(
        _PlainLifecycleHandler(phases),
      );
      processor.registerCommandHandler(_TrackingCmdHandler('inner_cmd', phases));

      await processor.process(config);

      expect(phases, contains('handle'));
      expect(phases, contains('processChildren'));
      // afterChildrenProcessed is NOT called for plain BlockHandler
      expect(phases, isNot(contains('afterChildrenProcessed')));
    });

    test('afterChildrenProcessed runs after all children on BaseBlockHandler',
        () async {
      final phases = <String>[];
      final configContent = '''
test_block {
    cmd_a
    cmd_b
    cmd_c
}
''';
      final config = Config.parse(configContent);
      final processor = ConfigProcessor();

      processor.registerBlockHandler(
        _BaseLifecycleHandler(phases),
      );
      processor.registerCommandHandler(
        _TrackingCmdHandler(null, phases),
      );

      await processor.process(config);

      final afterIdx = phases.indexOf('afterChildrenProcessed');
      expect(afterIdx, greaterThan(0));
      // afterChildrenProcessed is the last lifecycle stage
      expect(afterIdx, equals(phases.length - 1));
    });
  });
}

// ============================================================================
// Test Helpers
// ============================================================================

class _IdentifierCapturingBlockHandler implements BlockHandler {
  final void Function(String?) onIdentifier;

  _IdentifierCapturingBlockHandler({required this.onIdentifier});

  @override
  String get blockType => 'host';

  @override
  void handle(Block block, Context context) {
    onIdentifier(null);
  }

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  FutureOr<void>? processChildren(Block block, Context context) => null;
}

class _AfterChildrenCheckHandler implements BlockHandler {
  @override
  String get blockType => 'host';

  @override
  void handle(Block block, Context context) {}

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  FutureOr<void>? processChildren(Block block, Context context) {
    final hosts = context.blockRegistry['host'];
    expect(hosts, isNull);
    return null;
  }

  @override
  FutureOr<void> afterChildrenProcessed(Block block, Context context) {
    final hosts = context.blockRegistry['host'];
    expect(hosts, isNull);
    return null;
  }
}

class _DefaultProcessHandler implements BlockHandler {
  @override
  String get blockType => 'test';

  @override
  void handle(Block block, Context context) {}

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  FutureOr<void>? processChildren(Block block, Context context) => null;
}

class _NullAsyncProcessHandler implements BlockHandler {
  @override
  String get blockType => 'test_block';

  @override
  void handle(Block block, Context context) {}

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  Future<void> processChildren(Block block, Context context) async {
    // Even returning null from async yields non-null Future<void>
    return null;
  }

  @override
  FutureOr<void> afterChildrenProcessed(Block block, Context context) {}
}

class _NonNullAsyncProcessHandler implements BlockHandler {
  @override
  String get blockType => 'test_block';

  @override
  void handle(Block block, Context context) {}

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  Future<void> processChildren(Block block, Context context) async {
    // Intentional no-op custom processing
  }

  @override
  FutureOr<void> afterChildrenProcessed(Block block, Context context) {}
}

class _AsyncOverrideHandler implements BlockHandler {
  @override
  String get blockType => 'test';

  @override
  void handle(Block block, Context context) {}

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  Future<void> processChildren(Block block, Context context) async {
    return null;
  }

  @override
  FutureOr<void> afterChildrenProcessed(Block block, Context context) {}
}

class _PlainBlockHandler implements BlockHandler {
  @override
  String get blockType => 'test';

  @override
  void handle(Block block, Context context) {}

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  FutureOr<void>? processChildren(Block block, Context context) => null;
}

class _MixinBlockHandler with ValueExpander implements BlockHandler {
  @override
  String get blockType => 'test';

  @override
  void handle(Block block, Context context) {}

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  FutureOr<void>? processChildren(Block block, Context context) => null;
}

class _ErrorReportingBlockHandler implements BlockHandler {
  @override
  String get blockType => 'test_block';

  @override
  void handle(Block block, Context context) {
    context.reportError('handler error', span: null);
  }

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  FutureOr<void>? processChildren(Block block, Context context) => null;
}

class _CollectingErrorHandler implements ErrorHandler {
  final List<String> errors;
  _CollectingErrorHandler(this.errors);

  @override
  void handleError(String message, Context context, {SourceSpan? span}) {
    errors.add(message);
  }
}

class _PlainLifecycleHandler implements BlockHandler {
  final List<String> phases;
  _PlainLifecycleHandler(this.phases);

  @override
  String get blockType => 'test_block';

  @override
  void handle(Block block, Context context) {
    phases.add('handle');
  }

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  FutureOr<void>? processChildren(Block block, Context context) {
    phases.add('processChildren');
    return null;
  }

  // afterChildrenProcessed is NOT part of BlockHandler interface,
  // so this method won't be called by the processor
  void afterChildrenProcessed(Block block, Context context) {
    phases.add('afterChildrenProcessed');
  }
}

class _BaseLifecycleHandler extends BaseBlockHandler {
  final List<String> phases;
  _BaseLifecycleHandler(this.phases);

  @override
  String get blockType => 'test_block';

  @override
  void handle(Block block, Context context) {
    phases.add('handle');
  }

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}

  @override
  FutureOr<void>? processChildren(Block block, Context context) {
    phases.add('processChildren');
    return null;
  }

  @override
  FutureOr<void> afterChildrenProcessed(Block block, Context context) {
    phases.add('afterChildrenProcessed');
    return null;
  }
}

// ============================================================================
// VariableMiddleware test helpers
// ============================================================================

class _UppercaseMiddleware implements VariableMiddleware {
  @override
  dynamic onSet(String name, dynamic value, Context context) {
    if (value is String) return value.toUpperCase();
    return value;
  }

  @override
  dynamic onGet(String name, dynamic? value, Context context) => value;

  @override
  String? onExpand(String text, Context context) => null;
}

class _RejectingMiddleware implements VariableMiddleware {
  @override
  dynamic onSet(String name, dynamic value, Context context) => null;

  @override
  dynamic onGet(String name, dynamic? value, Context context) => value;

  @override
  String? onExpand(String text, Context context) => null;
}

class _PrefixMiddleware implements VariableMiddleware {
  @override
  dynamic onSet(String name, dynamic value, Context context) => value;

  @override
  dynamic onGet(String name, dynamic? value, Context context) {
    if (value is String) return 'PREFIX:$value';
    return value;
  }

  @override
  String? onExpand(String text, Context context) => null;
}

class _SuffixMiddleware implements VariableMiddleware {
  @override
  dynamic onSet(String name, dynamic value, Context context) => value;

  @override
  dynamic onGet(String name, dynamic? value, Context context) {
    if (value is String) return '$value\_suffix';
    return value;
  }

  @override
  String? onExpand(String text, Context context) => null;
}

class _BlockGetMiddleware implements VariableMiddleware {
  @override
  dynamic onSet(String name, dynamic value, Context context) => value;

  @override
  dynamic onGet(String name, dynamic? value, Context context) => null;

  @override
  String? onExpand(String text, Context context) => null;
}

class _RedactionMiddleware implements VariableMiddleware {
  final List<String> _keys;
  _RedactionMiddleware(this._keys);

  @override
  dynamic onSet(String name, dynamic value, Context context) => value;

  @override
  dynamic onGet(String name, dynamic? value, Context context) => value;

  @override
  String? onExpand(String text, Context context) {
    for (final key in _keys) {
      text = text.replaceAll('\$$key', '<REDACTED>');
    }
    return text;
  }
}

class _SkipExpandMiddleware implements VariableMiddleware {
  @override
  dynamic onSet(String name, dynamic value, Context context) => value;

  @override
  dynamic onGet(String name, dynamic? value, Context context) => value;

  @override
  String? onExpand(String text, Context context) => null;
}

class _LoggingMiddleware implements VariableMiddleware {
  List<String>? logs;

  @override
  dynamic onSet(String name, dynamic value, Context context) => value;

  @override
  dynamic onGet(String name, dynamic? value, Context context) => value;

  @override
  String? onExpand(String text, Context context) {
    logs?.add('expanding: $text');
    return text;
  }
}

class _TrackingCmdHandler implements CommandHandler {
  final String? expectedHead;
  final List<String> phases;
  _TrackingCmdHandler(this.expectedHead, this.phases);

  @override
  String get commandName => expectedHead ?? 'tracking';

  @override
  void handle(Command command, Context context) {
    phases.add(command.head);
  }
}