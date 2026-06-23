import 'dart:async';
import 'package:i3config/i3config.dart';
import 'shared_handlers.dart';

Future<void> main() async {
  print('=== Async Handler Example ===\n');

  final configContent = '''
# Simulate fetching remote config
# fetch_remote "https://dotfiles.example.com/i3/config"

set \$mod Mod4
set \$terminal alacritty

bar {
    status_command i3status
    position top
}
''';

  final config = Config.parse(configContent);
  final processor = ConfigProcessor();

  // Register handlers - can be sync or async
  processor.registerCommandHandler(SetCommandHandler()); // Sync
  processor.registerCommandHandler(AsyncFetchRemoteHandler()); // Async
  processor.registerBlockHandler(BarBlockHandler()); // Sync block handler

  print('Processing configuration (with async handlers)...\n');

  // process() returns Future<void> - must await it
  await processor.process(config);

  print('\n=== Results ===');
  print('Variables set:');
  processor.context.variables.forEach((name, value) {
    print('  \$$name = "$value"');
  });

  print('\n=== Key Points ===');
  print('1. Handlers can return void (sync) or Future<void> (async)');
  print('2. processor.process() returns Future<void> - must await it');
  print('3. Async handlers are awaited sequentially (not parallel)');
  print('4. Mix sync and async handlers freely');
  print('5. Useful for: file I/O, network requests, database queries, etc.');
}

/// Example async handler that simulates fetching remote configuration.
class AsyncFetchRemoteHandler with ValueExpander implements CommandHandler {
  @override
  String get commandName => 'fetch_remote';

  @override
  Future<void> handle(Command command, Context context) async {
    if (command.args.isNotEmpty) {
      final url = expandValue(command.args[0], context);
      print('Fetching from $url...');

      // Simulate network request
      await Future.delayed(Duration(milliseconds: 100));

      print('✓ Fetched remote config');

      // Could parse and merge remote config here
    }
  }
}
