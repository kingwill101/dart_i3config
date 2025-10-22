import 'dart:async';
import 'package:i3config/i3config_v2.dart';

/// Example showing custom child processing with super.processChildren()
Future<void> main() async {
  final config = '''
conditional_block {
    enabled_feature "dark_mode"
    disabled_feature "beta_ui"
    enabled_feature "animations"
    regular_command "this_will_be_processed"
}

multi_pass_block {
    declare "theme" "dark"
    declare "font" "monospace"
    use "theme"
    use "font"
}
''';

  final parsed = Config.parse(config);
  final processor = ConfigProcessor();
  processor.registerBlockHandler(ConditionalBlockHandler());
  processor.registerBlockHandler(MultiPassBlockHandler());

  await processor.process(parsed);
}

/// Custom processing: Filter children, then call super for remaining
class ConditionalBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'conditional_block';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('enabled_feature', FeatureHandler(true));
    registry.registerCommand('disabled_feature', FeatureHandler(false));
    registry.registerCommand('regular_command', RegularCommandHandler());
  }

  @override
  void handle(Block block, Context context) {
    print('Processing conditional block...');
  }

  @override
  Future<void> processChildren(Block block, Context context) async {
    // Custom logic: Filter enabled features first
    final enabledFeatures = findCommands(block, 'enabled_feature');
    for (final cmd in enabledFeatures) {
      print('✅ Processing enabled feature: ${cmd.getArgAsString(0, context)}');
    }

    // Skip disabled features (don't process them)
    final disabledFeatures = findCommands(block, 'disabled_feature');
    for (final cmd in disabledFeatures) {
      print('❌ Skipping disabled feature: ${cmd.getArgAsString(0, context)}');
    }

    // Process remaining commands normally using super
    final remainingCommands = block.body
        .whereType<Command>()
        .where(
          (cmd) =>
              cmd.head != 'enabled_feature' && cmd.head != 'disabled_feature',
        )
        .toList();

    if (remainingCommands.isNotEmpty) {
      print('🔄 Processing remaining commands with super...');
      // Create a temporary block with remaining commands
      final tempBlock = Block('temp', null, remainingCommands);
      await super.processChildren(tempBlock, context);
    }
  }
}

/// Multi-pass processing: Collect declarations, then process usages
class MultiPassBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'multi_pass_block';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('declare', DeclareHandler());
    registry.registerCommand('use', UseHandler());
  }

  @override
  void handle(Block block, Context context) {
    print('Processing multi-pass block...');
  }

  @override
  Future<void> processChildren(Block block, Context context) async {
    final declarations = <String, String>{};

    // Pass 1: Collect all declarations
    final declareCommands = findCommands(block, 'declare');
    for (final cmd in declareCommands) {
      final key = cmd.getArgAsString(0, context);
      final value = cmd.getArgAsString(1, context);
      declarations[key] = value;
      print('📝 Collected declaration: $key = $value');
    }

    // Pass 2: Process usages (can now reference declarations)
    final useCommands = findCommands(block, 'use');
    for (final cmd in useCommands) {
      final key = cmd.getArgAsString(0, context);
      final value = declarations[key];
      if (value != null) {
        print('🔗 Using declaration: $key = $value');
      } else {
        print('⚠️  Undefined reference: $key');
      }
    }

    // Process any remaining commands with super
    final remainingCommands = block.body
        .whereType<Command>()
        .where((cmd) => cmd.head != 'declare' && cmd.head != 'use')
        .toList();

    if (remainingCommands.isNotEmpty) {
      final tempBlock = Block('temp', null, remainingCommands);
      await super.processChildren(tempBlock, context);
    }
  }
}

/// Simple command handlers with return values
class FeatureHandler extends BaseCommandHandler<bool> {
  final bool enabled;

  FeatureHandler(this.enabled);

  @override
  String get commandName => enabled ? 'enabled_feature' : 'disabled_feature';

  @override
  bool? handle(Command command, Context context) {
    final feature = command.getArgAsString(0, context);
    print('Feature handler: $feature (enabled: $enabled)');

    // Return whether this feature is enabled
    return enabled;
  }
}

class RegularCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'regular_command';

  @override
  String? handle(Command command, Context context) {
    final value = command.getArgAsString(0, context);
    print('Regular command: $value');

    // Return the processed value
    return value;
  }
}

class DeclareHandler extends BaseCommandHandler<Map<String, String>> {
  @override
  String get commandName => 'declare';

  @override
  Map<String, String>? handle(Command command, Context context) {
    // This is called during super.processChildren()
    final key = command.getArgAsString(0, context);
    final value = command.getArgAsString(1, context);
    print('Declare handler: $key = $value');

    // Return the declaration as a map
    return {key: value};
  }
}

class UseHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'use';

  @override
  String? handle(Command command, Context context) {
    // This is called during super.processChildren()
    final key = command.getArgAsString(0, context);
    print('Use handler: $key');

    // Return the key being used
    return key;
  }
}
