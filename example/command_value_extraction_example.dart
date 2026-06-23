import 'dart:async';
import 'package:i3config/i3config.dart';

/// Example showing the most ergonomic way to extract command values
Future<void> main() async {
  final config = '''
set \$default_color "#3498db"

rectangle "my_rect" {
    color 0xffffff
    width 200
    height 100
    border_color \$default_color
}
''';

  final parsed = Config.parse(config);
  final processor = ConfigProcessor();
  processor.registerCommandHandler(SetCommandHandler());
  processor.registerBlockHandler(RectangleBlockHandler());

  await processor.process(parsed);
}

/// Most ergonomic approach: Extend BaseBlockHandler
class RectangleBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'rectangle';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('color', ColorCommandHandler());
    registry.registerCommand('width', WidthCommandHandler());
    registry.registerCommand('height', HeightCommandHandler());
    registry.registerCommand('border_color', BorderColorCommandHandler());
  }

  @override
  void handle(Block block, Context context) {
    final id = getBlockIdentifier(block, context);
    print('Processing rectangle: $id');
  }

  // processChildren() inherited from BaseBlockHandler (automatic processing)
}

/// Command handlers with ergonomic value extraction and return values
class ColorCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'color';

  @override
  String? handle(Command command, Context context) {
    // Option 1: Extension method (most ergonomic)
    final color = command.getArgAsString(0, context); // ← Clean!
    print('Setting color: $color');

    // Return the color value for use by other parts of the system
    return color;
  }
}

class WidthCommandHandler extends BaseCommandHandler<int> {
  @override
  String get commandName => 'width';

  @override
  int? handle(Command command, Context context) {
    final width = command.getArgAsInt(0, context); // ← Type-safe!
    print('Setting width: $width');

    // Return the width value
    return width;
  }
}

class HeightCommandHandler extends BaseCommandHandler<int> {
  @override
  String get commandName => 'height';

  @override
  int? handle(Command command, Context context) {
    final height = command.getArgAsInt(0, context);
    print('Setting height: $height');

    // Return the height value
    return height;
  }
}

class BorderColorCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'border_color';

  @override
  String? handle(Command command, Context context) {
    final color = command.getArgAsString(0, context);
    print('Setting border color: $color');

    // Return the border color value
    return color;
  }
}
