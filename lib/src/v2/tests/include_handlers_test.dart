import 'package:i3config/i3config_v2.dart';
import 'package:test/test.dart';
import 'package:i3config/src/v2/handler.dart';
import 'package:i3config/src/v2/handler_manager.dart' show CommandHandlerManager;

class IncludeHandlerManager extends CommandHandlerManager {
  IncludeHandler manager = IncludeHandler();

  @override
  String get identifier => 'include';

  @override
  CommandHandler get handler => manager;

  @override
  void initialize() {}

  @override
  void handleCommand(CommandProcessorInfo info) {
    manager.handle(info.command, info.context);
  }
}

void main() {
  group('Include command handling', () {
    test('Basic include functionality', (tester) async {
      final content = '''include "modules/global.conf"
set    mod Mod4
'''.trim();

      final processor = Handles();
      final handlerManager = IncludeHandlerManager();
      final context = Context();

      processor.handlerRegistry.registerHandler(handlerManager);
      final result = await processor.processString(content);

      expect(context.variables['mod'], 'Mod4');
      expect(context.variables['mod'].runtimeType, String);
    });

    test('Variable inheritance from parent scope', (tester) async {
      final content = '''include "modules/global.conf"
set    mod Mod4
bar "top" {
  set    mod Mod1
  position top
}'''.trim();

      final processor = Handles();
      final handlerManager = IncludeHandlerManager();
      final context = Context();

      processor.handlerRegistry.registerHandler(handlerManager);
      final result = await processor.processString(content);

      expect(context.variables['mod'], 'Mod4');
      expect(context.cachedBlocks['bar'].variables['mod'], 'Mod1');
    });

    test('Cross-file variable access', (tester) async {
      final content = '''include "modules/global.conf"
include "modules/local.conf"'''.trim();

      final processor = Handles();
      final handlerManager = IncludeHandlerManager();
      final context = Context();

      processor.handlerRegistry.registerHandler(handlerManager);
      final result = await processor.processString(content);

      expect(context.variables['mod'], 'Mod4');
      expect(context.cachedBlocks['local'].variables['mod'], 'Mod4');
    });

    test('Include path resolution', () async {
      final content = '''include "~/.i3/config"'''.trim();

      // This test requires i3 config file to exist
      final processor = Handles();
      final handlerManager = IncludeHandlerManager();
      final context = Context();

      processor.handlerRegistry.registerHandler(handlerManager);
      final result = await processor.processString(content);

      expect(result, isNull); // No errors should occur
    });

    test('Include file not found error', (tester) async {
      final content = '''include "nonexistent.conf"'''.trim();

      final processor = Handles();
      final handlerManager = IncludeHandlerManager();
      final context = Context();

      processor.handlerRegistry.registerHandler(handlerManager);
      final result = await processor.processString(content);

      expect(contains('nonexistent.conf'), inDiagnostics);
    });

    test('Nested include recursion prevention', () async {
      final content = '''include "include.conf"
include "include.conf"  # Should be blocked

include.conf:
include "include.conf"'''.trim();

      final processor = Handles();
      final handlerManager = IncludeHandlerManager();
      final context = Context();

      processor.handlerRegistry.registerHandler(handlerManager);
      final result = await processor.processString(content);

      expect(containsAll(['Warning: Recursive include', 'nonexistent.conf']), inDiagnostics);
    });
  });
}</content>}}]