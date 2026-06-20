import 'dart:async';
import 'package:i3config/i3config_v2.dart';

/// Example demonstrating block-scoped block handler registration.
///
/// Shows how nested handlers (resource > actions > copy > backup)
/// are registered via registerScopedBlockHandler and resolved by
/// the state machine based on the current parent block type.
Future<void> main() async {
  final config = Config.parse('''
resource {
    source mydir
    type directory
    actions {
        copy {
            target /tmp/dest
            owner king
            backup {
                recursive true
                backup_path .mybackups
            }
        }
    }
}
''');

  final processor = ConfigProcessor();

  // Register top-level block handlers (they register scoped handlers
  // for their child blocks via registerScopedCommands).
  processor.registerBlockHandler(ResourceBlockHandler());
  processor.registerBlockHandler(CopyBlockHandler());

  await processor.process(config);
}

/// Top-level block handler for "resource" blocks.
/// Registers an "actions" scoped block handler.
class ResourceBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'resource';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerScopedBlockHandler('actions', ActionsBlockHandler());
  }

  @override
  void handle(Block block, Context context) {
    final id = getBlockIdentifier(block, context);
    print('Processing resource: $id');
  }
}

/// Handles "actions" blocks that appear inside "resource" blocks.
/// Registers "copy" as a scoped block handler.
class ActionsBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'actions';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerScopedBlockHandler('copy', CopyBlockHandler());
  }

  @override
  void handle(Block block, Context context) {
    print('Processing actions...');
  }
}

/// Handles "copy" blocks. Can be registered both at top level (global)
/// and as a scoped handler inside "actions".
/// Registers "backup" as a scoped block handler.
class CopyBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'copy';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerScopedBlockHandler('backup', BackupBlockHandler());
    registry.registerCommand('target', CopyTargetHandler());
    registry.registerCommand('owner', CopyOwnerHandler());
  }

  @override
  void handle(Block block, Context context) {
    print('Processing copy...');
  }

  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    final target = context.getVariable('copy_target');
    final owner = context.getVariable('copy_owner');
    final hasBackup = block.body
        .whereType<Command>()
        .any((c) => c.block?.blockType == 'backup');
    print('  Copy summary: target=$target, owner=$owner, backup=$hasBackup');
  }
}

/// Handles "backup" blocks that appear inside "copy" blocks.
class BackupBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'backup';

  @override
  void handle(Block block, Context context) {
    final recursive = findFirstCommand(block, 'recursive');
    final backupPath = findFirstCommand(block, 'backup_path');
    if (recursive != null) {
      print('  Backup: recursive=${recursive.getArgAsString(0, context)}');
    }
    if (backupPath != null) {
      print('  Backup: path=${backupPath.getArgAsString(0, context)}');
    }
  }
}

/// Scoped command handler for "target" inside "copy" blocks.
class CopyTargetHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'target';

  @override
  String? handle(Command command, Context context) {
    final target = getArgAsString(command, 0, context);
    context.setVariable('copy_target', target);
    print('  Target: $target');
    return target;
  }
}

/// Scoped command handler for "owner" inside "copy" blocks.
class CopyOwnerHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'owner';

  @override
  String? handle(Command command, Context context) {
    final owner = getArgAsString(command, 0, context);
    context.setVariable('copy_owner', owner);
    print('  Owner: $owner');
    return owner;
  }
}
