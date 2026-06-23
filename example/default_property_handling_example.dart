import 'dart:async';
import 'package:i3config/i3config.dart';

/// Example showing the default property command handling
///
/// This demonstrates how the system automatically handles property-value pairs
/// without needing to create handlers for every single property.
Future<void> main() async {
  final config = '''
set \$theme "dark"
set \$primary_color "#3498db"

# These commands will be automatically handled by the default property handler
rectangle "my_rect" {
    color 0xffffff
    width 200
    height 100
    border_color \$primary_color
    border_width 2
    opacity 0.9
    visible true
    position "top-left"
    z_index 10
}

# More properties - all handled automatically
widget "button" {
    text "Click me"
    font_size 14
    font_family "Arial"
    background_color \$primary_color
    text_color white
    padding 8px
    margin 4px
    border_radius 4
    hover_effect true
    clickable true
}

# Even complex properties work
theme "dark_theme" {
    primary_color "#2c3e50"
    secondary_color "#34495e"
    accent_color "#3498db"
    background_color "#1a1a1a"
    text_color "#ecf0f1"
    border_color "#7f8c8d"
    shadow_color "rgba(0,0,0,0.3)"
    animation_duration 300ms
    transition_easing "ease-in-out"
}
''';

  final parsed = Config.parse(config);
  final processor = ConfigProcessor();

  // Only register the built-in set command handler
  // All other commands (color, width, height, etc.) are handled automatically!
  processor.registerCommandHandler(SetCommandHandler());

  // Register block handlers to demonstrate scoped properties
  processor.registerBlockHandler(RectangleBlockHandler());
  processor.registerBlockHandler(WidgetBlockHandler());
  processor.registerBlockHandler(ThemeBlockHandler());

  await processor.process(parsed);
}

/// Block handler that demonstrates scoped property access
class RectangleBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'rectangle';

  @override
  void handle(Block block, Context context) {
    final id = getBlockIdentifier(block, context);
    print('\\n📦 Processing rectangle: $id');
  }

  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    // Access the properties that were automatically set by the default handler
    final color = context.getVariable('color');
    final width = context.getVariable('width');
    final height = context.getVariable('height');
    final borderColor = context.getVariable('border_color');
    final borderWidth = context.getVariable('border_width');
    final opacity = context.getVariable('opacity');
    final visible = context.getVariable('visible');
    final position = context.getVariable('position');
    final zIndex = context.getVariable('z_index');

    print('  🎨 Color: $color');
    print('  📏 Size: $width×$height');
    print('  🔲 Border: $borderColor (${borderWidth}px)');
    print('  👁️  Opacity: $opacity, Visible: $visible');
    print('  📍 Position: $position, Z-Index: $zIndex');
  }
}

class WidgetBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'widget';

  @override
  void handle(Block block, Context context) {
    final id = getBlockIdentifier(block, context);
    print('\\n🔘 Processing widget: $id');
  }

  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    // Access all the automatically set properties
    final text = context.getVariable('text');
    final fontSize = context.getVariable('font_size');
    final fontFamily = context.getVariable('font_family');
    final backgroundColor = context.getVariable('background_color');
    final textColor = context.getVariable('text_color');
    final padding = context.getVariable('padding');
    final margin = context.getVariable('margin');
    final borderRadius = context.getVariable('border_radius');
    final hoverEffect = context.getVariable('hover_effect');
    final clickable = context.getVariable('clickable');

    print('  📝 Text: "$text"');
    print('  🔤 Font: $fontFamily, Size: $fontSize');
    print('  🎨 Colors: BG=$backgroundColor, Text=$textColor');
    print('  📐 Spacing: Padding=$padding, Margin=$margin');
    print('  🔲 Border Radius: $borderRadius');
    print('  🖱️  Interactive: Hover=$hoverEffect, Clickable=$clickable');
  }
}

class ThemeBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'theme';

  @override
  void handle(Block block, Context context) {
    final id = getBlockIdentifier(block, context);
    print('\\n🎨 Processing theme: $id');
  }

  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    // Access all the theme properties
    final primaryColor = context.getVariable('primary_color');
    final secondaryColor = context.getVariable('secondary_color');
    final accentColor = context.getVariable('accent_color');
    final backgroundColor = context.getVariable('background_color');
    final textColor = context.getVariable('text_color');
    final borderColor = context.getVariable('border_color');
    final shadowColor = context.getVariable('shadow_color');
    final animationDuration = context.getVariable('animation_duration');
    final transitionEasing = context.getVariable('transition_easing');

    print('  🎨 Primary: $primaryColor');
    print('  🎨 Secondary: $secondaryColor');
    print('  🎨 Accent: $accentColor');
    print('  🎨 Background: $backgroundColor');
    print('  🎨 Text: $textColor');
    print('  🎨 Border: $borderColor');
    print('  🎨 Shadow: $shadowColor');
    print('  ⚡ Animation: $animationDuration, Easing: $transitionEasing');
  }
}
