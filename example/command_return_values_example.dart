import 'dart:async';
import 'package:i3config/i3config_v2.dart';

/// Example showing how to use command return values
Future<void> main() async {
  final config = '''
set \$theme "dark"

rectangle "my_rect" {
    color 0xffffff
    width 200
    height 100
    border_color \$theme
}

# Commands that return values can be used by other parts of the system
calculate_area {
    width 200
    height 100
    # The area calculation could use the returned width/height values
}
''';

  final parsed = Config.parse(config);
  final processor = ConfigProcessor();
  processor.registerCommandHandler(SetCommandHandler());
  processor.registerBlockHandler(RectangleBlockHandler());
  processor.registerBlockHandler(CalculateAreaBlockHandler());

  await processor.process(parsed);
}

/// Block handler that can collect return values from commands
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

/// Block handler that demonstrates using command return values
class CalculateAreaBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'calculate_area';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('width', WidthCommandHandler());
    registry.registerCommand('height', HeightCommandHandler());
  }

  @override
  void handle(Block block, Context context) {
    print('Calculating area...');
  }

  @override
  Future<void> processChildren(Block block, Context context) async {
    int? width, height;

    // Process commands and collect their return values
    for (final element in block.body) {
      if (element is Command) {
        // Create handlers for width/height commands
        CommandHandler? handler;
        if (element.head == 'width') {
          handler = WidthCommandHandler();
        } else if (element.head == 'height') {
          handler = HeightCommandHandler();
        }

        if (handler != null) {
          final result = await handler.handle(element, context);

          if (element.head == 'width' && result is int) {
            width = result;
            print('Collected width: $width');
          } else if (element.head == 'height' && result is int) {
            height = result;
            print('Collected height: $height');
          }
        }
      }
    }

    // Use the collected values
    if (width != null && height != null) {
      final area = width * height;
      print('🎯 Calculated area: $width × $height = $area');
    } else {
      print('⚠️  Missing width or height for area calculation');
    }
  }
}

/// Command handlers that return values
class ColorCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'color';

  @override
  String? handle(Command command, Context context) {
    final color = command.getArgAsString(0, context);
    print('Setting color: $color');
    return color; // Return the color value
  }
}

class WidthCommandHandler extends BaseCommandHandler<int> {
  @override
  String get commandName => 'width';

  @override
  int? handle(Command command, Context context) {
    final width = command.getArgAsInt(0, context);
    print('Setting width: $width');
    return width; // Return the width value
  }
}

class HeightCommandHandler extends BaseCommandHandler<int> {
  @override
  String get commandName => 'height';

  @override
  int? handle(Command command, Context context) {
    final height = command.getArgAsInt(0, context);
    print('Setting height: $height');
    return height; // Return the height value
  }
}

class BorderColorCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'border_color';

  @override
  String? handle(Command command, Context context) {
    final color = command.getArgAsString(0, context);
    print('Setting border color: $color');
    return color; // Return the border color value
  }
}
