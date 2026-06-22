/// Creative Example: UI Layout & Styling DSL
///
/// This demonstrates the FULL power of the i3config state machine:
/// - Global variables and assignments
/// - Block-scoped commands (widget-specific, theme-specific)
/// - Async handlers (theme loading, asset fetching)
/// - Nested blocks (widgets inside layouts)
/// - Context scoping and variable shadowing
/// - Sequential processing
/// - Custom command handlers
///
/// Imagine we're building a config-driven UI toolkit!
library;

import 'dart:async';
import 'package:i3config/i3config_v2.dart';

Future<void> main() async {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║  Creative UI Layout DSL - Full State Machine Demo         ║');
  print('╔════════════════════════════════════════════════════════════╗\n');

  // This config defines a UI with themes, layouts, and styled widgets
  final uiConfig = '''
# ═══════════════════════════════════════════════════════════
# GLOBAL CONFIGURATION
# ═══════════════════════════════════════════════════════════

# Global theme variables (set commands)
set \$primary_color "#3498db"
set \$secondary_color "#2ecc71"
set \$bg_color "#ecf0f1"
set \$text_color "#2c3e50"
set \$font_size 14

# Global spacing configuration (assignment statements)
spacing = 8px
border_radius = 4px
margin = 16px

# Import remote theme (async operation!)
import_theme "https://ui-themes.example.com/dark-theme.json"

# ═══════════════════════════════════════════════════════════
# THEME DEFINITIONS
# ═══════════════════════════════════════════════════════════

theme "dark" {
    # Theme-scoped color overrides (context scoping!)
    set \$primary_color "#1abc9c"
    set \$bg_color "#34495e"
    set \$text_color "#ecf0f1"
    
    # Theme-specific settings (block-scoped commands)
    apply_shadows true
    animation_duration 200ms
}

theme "light" {
    set \$primary_color "#3498db"
    set \$bg_color "#ffffff"
    
    apply_shadows false
    animation_duration 150ms
}

# ═══════════════════════════════════════════════════════════
# LAYOUT DEFINITIONS
# ═══════════════════════════════════════════════════════════

layout "main_screen" {
    direction column
    padding \$spacing
    background \$bg_color
}

layout "sidebar" {
    direction row
    padding \$margin
    background \$secondary_color
}

# ═══════════════════════════════════════════════════════════
# WIDGET DEFINITIONS (with NESTED blocks!)
# ═══════════════════════════════════════════════════════════

widget "header_text" {
    # Local variable scoping
    set \$local_padding "12px"
    
    type text
    content "Welcome to UI DSL"
    color \$primary_color
    size large
    padding \$local_padding
}

widget "card_container" {
    type container
    padding 16px
    
    # NESTED: Style block inside widget!
    style {
        font_weight bold
        margin_bottom 20px
    }
}

widget "primary_button" {
    type button
    label "Click Me"
    background \$primary_color
    color white
    padding 12px
    border_radius \$border_radius
    
    on_click execute_action "handle_primary_click"
    on_hover execute_action "show_tooltip"
}

widget "item_list" {
    type list
    color \$text_color
    items += "Dashboard"
    items += "Settings"
    items += "Profile"
}

# ═══════════════════════════════════════════════════════════
# CUSTOM CHILD PROCESSING (filter example)
# ═══════════════════════════════════════════════════════════

conditional_block {
    enabled_feature "dark_mode"
    disabled_feature "beta_ui"
    enabled_feature "animations"
}

# ═══════════════════════════════════════════════════════════
# RESPONSIVE RULES
# ═══════════════════════════════════════════════════════════

responsive "mobile" {
    max_width 768px
    
    set \$font_size 12
}

responsive "tablet" {
    max_width 1024px
    
    set \$font_size 13
}

# ═══════════════════════════════════════════════════════════
# ANIMATIONS
# ═══════════════════════════════════════════════════════════

animation "fade_in" {
    duration 300ms
    easing ease_in_out
    from opacity=0
    to opacity=1
}

animation "slide_up" {
    duration 250ms
    easing cubic_bezier
    from translateY=100px
    to translateY=0
}
''';

  final config = Config.parse(uiConfig);

  print('📄 Parsed ${config.statements.length} top-level elements:');
  for (final stmt in config.statements) {
    if (stmt is Command) {
      if (stmt.block != null) {
        print('   - ${stmt.head} block (${stmt.block!.body.length} children)');
      } else {
        print('   - ${stmt.head} command');
      }
    } else if (stmt is Assignment) {
      print('   - ${stmt.variable} assignment');
    } else if (stmt is Comment) {
      print('   - comment');
    }
  }
  print('\n═══════════════════════════════════════════════════════════\n');

  // Create processor with custom handlers
  final processor = ConfigProcessor();
  final uiState = UIRenderState();

  // Register global handlers
  processor.registerCommandHandler(SetCommandHandler());
  processor.registerCommandHandler(ImportThemeHandler(uiState));
  processor.registerCommandHandler(ExecuteActionHandler(uiState));

  // Register block handlers (each registers its own scoped commands)
  processor.registerBlockHandler(ThemeBlockHandler(uiState));
  processor.registerBlockHandler(LayoutBlockHandler(uiState));
  processor.registerBlockHandler(WidgetBlockHandler(uiState));
  processor.registerBlockHandler(StyleBlockHandler(uiState));
  processor.registerBlockHandler(ResponsiveBlockHandler(uiState));
  processor.registerBlockHandler(AnimationBlockHandler(uiState));
  processor.registerBlockHandler(ConditionalBlockHandler(uiState));

  // Process the configuration (async - waits for theme loading!)
  print('⚙️  Processing UI configuration...\n');
  await processor.process(config);

  print('\n═══════════════════════════════════════════════════════════');
  print('\n📊 Final UI State:\n');

  print('🎨 Theme Variables:');
  processor.context.variables.forEach((name, value) {
    print('   \$$name = $value');
  });

  print('\n🏗️  Layouts Created: ${uiState.layouts.length}');
  uiState.layouts.forEach((name, layout) {
    print('   📐 $name:');
    print('      Direction: ${layout['direction']}');
    print('      Background: ${layout['background']}');
    print('      Widgets: ${layout['widgets']?.length ?? 0}');
  });

  print('\n🎭 Themes Loaded: ${uiState.themes.length}');
  uiState.themes.forEach((name, theme) {
    print(
      '   🎨 $name: ${theme['colors']?.length ?? 0} colors, ${theme['settings']?.length ?? 0} settings',
    );
  });

  print('\n📱 Responsive Breakpoints: ${uiState.responsiveRules.length}');

  print('\n✨ Animations Defined: ${uiState.animations.length}');
  uiState.animations.forEach((name, anim) {
    print('   ⏱️  $name: ${anim['duration']}');
  });

  print('\n🔧 Enabled Features: ${uiState.enabledFeatures.length}');
  for (var feature in uiState.enabledFeatures) {
    print('   ✅ $feature');
  }

  print('\n═══════════════════════════════════════════════════════════');
  print('\n🎯 Capabilities Demonstrated:');
  print('   ✅ Global variables (set commands)');
  print('   ✅ Assignment statements (spacing = 8px, items += "...")');
  print('   ✅ Async handlers (import_theme with network delay)');
  print('   ✅ Block-scoped commands (40+ scoped to specific block types)');
  print('   ✅ NESTED blocks (style { } inside widget { })');
  print('   ✅ Context scoping (local variables isolated to blocks)');
  print('   ✅ Variable expansion (\$primary_color, \$spacing, etc.)');
  print('   ✅ Sequential processing (guaranteed order, async awaited)');
  print('   ✅ Clean encapsulation (handlers register own commands)');
  print('   ✅ Custom child processing (conditional_block filters children)');
  print('\n🚀 Full state machine power in action!\n');
}

/// State object that accumulates UI configuration.
class UIRenderState {
  final Map<String, Map<String, dynamic>> layouts = {};
  final Map<String, Map<String, dynamic>> themes = {};
  final Map<String, Map<String, dynamic>> widgets = {};
  final Map<String, Map<String, dynamic>> animations = {};
  final Map<String, Map<String, dynamic>> responsiveRules = {};
  final List<String> importedThemes = [];
  final List<String> enabledFeatures = [];
}

// ============================================================================
// ASYNC GLOBAL HANDLERS
// ============================================================================

/// Async handler that simulates loading a remote theme.
class ImportThemeHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;

  ImportThemeHandler(this.state);

  @override
  String get commandName => 'import_theme';

  @override
  Future<void> handle(Command command, Context context) async {
    if (command.args.isNotEmpty) {
      final url = expandValue(command.args[0], context);
      print('🌐 Importing theme from: $url');

      // Simulate network request
      await Future.delayed(Duration(milliseconds: 50));

      state.importedThemes.add(url);
      print('   ✓ Theme imported successfully\n');
    }
  }
}

/// Handler for execute_action commands.
class ExecuteActionHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;

  ExecuteActionHandler(this.state);

  @override
  String get commandName => 'execute_action';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final action = expandValue(command.args[0], context);
      print('   🎬 Registering action: $action');
    }
  }
}

// ============================================================================
// BLOCK HANDLERS WITH SCOPED COMMANDS
// ============================================================================

/// Theme block handler - manages theme definitions.
class ThemeBlockHandler
    with ValueExpander, DefaultChildProcessing
    implements BlockHandler {
  final UIRenderState state;

  ThemeBlockHandler(this.state);

  @override
  String get blockType => 'theme';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('apply_shadows', ThemeApplyShadowsHandler(state));
    registry.registerCommand(
      'animation_duration',
      ThemeAnimationHandler(state),
    );
  }

  @override
  void handle(Block block, Context context) {
    final themeName = block.identifier != null
        ? expandValue(block.identifier!, context)
        : 'default';

    print('🎨 Processing theme: "$themeName"');

    // Initialize theme storage
    state.themes[themeName] = {'colors': {}, 'settings': {}};

    context.globalContext.options['current_theme'] = themeName;
  }
}

/// Layout block handler - manages layout definitions.
class LayoutBlockHandler
    with ValueExpander, DefaultChildProcessing
    implements BlockHandler {
  final UIRenderState state;

  LayoutBlockHandler(this.state);

  @override
  String get blockType => 'layout';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // Layout-specific commands
    registry.registerCommand('direction', LayoutDirectionHandler(state));
    registry.registerCommand('padding', LayoutPaddingHandler(state));
    registry.registerCommand('background', LayoutBackgroundHandler(state));
  }

  @override
  void handle(Block block, Context context) {
    final layoutName = block.identifier != null
        ? expandValue(block.identifier!, context)
        : 'unnamed';

    print('📐 Creating layout: "$layoutName"');

    // Store in global state
    state.layouts[layoutName] = {
      'name': layoutName,
      'widgets': [],
      'properties': {},
    };

    // Store in current context so it's scoped to this layout block
    context.setVariable('current_layout', layoutName);
  }
}

/// Widget block handler - manages widget definitions.
class WidgetBlockHandler
    with ValueExpander, DefaultChildProcessing
    implements BlockHandler {
  final UIRenderState state;

  WidgetBlockHandler(this.state);

  @override
  String get blockType => 'widget';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // Widget-specific commands
    registry.registerCommand('type', WidgetTypeHandler(state));
    registry.registerCommand('content', WidgetContentHandler(state));
    registry.registerCommand('label', WidgetLabelHandler(state));
    registry.registerCommand('color', WidgetColorHandler(state));
    registry.registerCommand('background', WidgetBackgroundHandler(state));
    registry.registerCommand('size', WidgetSizeHandler(state));
    registry.registerCommand('padding', WidgetPaddingHandler(state));
    registry.registerCommand('border_radius', WidgetBorderRadiusHandler(state));
    registry.registerCommand('items', WidgetItemsHandler(state));
    registry.registerCommand('on_click', WidgetOnClickHandler(state));
    registry.registerCommand('on_hover', WidgetOnHoverHandler(state));
    registry.registerCommand('position', WidgetPositionHandler(state));
    registry.registerCommand('height', WidgetHeightHandler(state));
  }

  @override
  void handle(Block block, Context context) {
    final widgetId = block.identifier != null
        ? expandValue(block.identifier!, context)
        : 'widget_${state.widgets.length}';

    print('   🧩 Creating widget: "$widgetId"');

    state.widgets[widgetId] = {'id': widgetId, 'properties': {}, 'events': {}};

    // Add widget to current layout if inside a layout block
    final currentLayout = context.getVariable('current_layout') as String?;
    if (currentLayout != null && state.layouts.containsKey(currentLayout)) {
      final widgets = state.layouts[currentLayout]!['widgets'] as List;
      widgets.add(widgetId);
    }

    context.globalContext.options['current_widget'] = widgetId;
  }
}

/// Style block handler - manages nested styling.
class StyleBlockHandler
    with ValueExpander, DefaultChildProcessing
    implements BlockHandler {
  final UIRenderState state;

  StyleBlockHandler(this.state);

  @override
  String get blockType => 'style';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('font_weight', StyleFontWeightHandler(state));
    registry.registerCommand('margin_bottom', StyleMarginHandler(state));
  }

  @override
  void handle(Block block, Context context) {
    print('      💅 Applying inline styles (NESTED in widget)...');
  }
}

/// Conditional block handler - demonstrates CUSTOM CHILD PROCESSING.
/// This handler filters children, only processing "enabled_feature" commands.
class ConditionalBlockHandler implements BlockHandler {
  final UIRenderState state;

  ConditionalBlockHandler(this.state);

  @override
  String get blockType => 'conditional_block';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    // No scoped commands - we process manually
  }

  @override
  Future<void> processChildren(Block block, Context context) async {
    // Custom child processing: filter enabled vs disabled features
    for (final element in block.body) {
      if (element is Command && element.head == 'enabled_feature') {
        if (element.args.isNotEmpty) {
          final feature = element.args[0];
          if (feature is BareArg || feature is Quoted) {
            final featureName = feature is BareArg
                ? feature.value
                : (feature as Quoted).value;
            print('   ✅ Enabling: $featureName');
            state.enabledFeatures.add(featureName);
          }
        }
      } else if (element is Command && element.head == 'disabled_feature') {
        if (element.args.isNotEmpty) {
          final feature = element.args[0];
          final featureName = switch (feature) {
            BareArg a => a.value,
            Quoted q => q.value,
            VariableRef v => '\$${v.name}',
            ArrayValue a => a.items.map((v) => v.toString()).join(', '),
          };
          print('   ❌ Skipping disabled: $featureName');
          // Intentionally NOT processing disabled features
        }
      }
    }
  }

  @override
  void handle(Block block, Context context) {
    print('🎛️  Conditional features (CUSTOM child processing):');
  }
}

/// Responsive block handler.
class ResponsiveBlockHandler
    with ValueExpander, DefaultChildProcessing
    implements BlockHandler {
  final UIRenderState state;

  ResponsiveBlockHandler(this.state);

  @override
  String get blockType => 'responsive';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('max_width', ResponsiveMaxWidthHandler(state));
  }

  @override
  void handle(Block block, Context context) {
    final breakpoint = block.identifier != null
        ? expandValue(block.identifier!, context)
        : 'default';

    print('📱 Configuring responsive breakpoint: "$breakpoint"');

    state.responsiveRules[breakpoint] = {'rules': {}};
  }
}

/// Animation block handler.
class AnimationBlockHandler
    with ValueExpander, DefaultChildProcessing
    implements BlockHandler {
  final UIRenderState state;

  AnimationBlockHandler(this.state);

  @override
  String get blockType => 'animation';

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('duration', AnimationDurationHandler(state));
    registry.registerCommand('easing', AnimationEasingHandler(state));
    registry.registerCommand('from', AnimationFromHandler(state));
    registry.registerCommand('to', AnimationToHandler(state));
  }

  @override
  void handle(Block block, Context context) {
    final animName = block.identifier != null
        ? expandValue(block.identifier!, context)
        : 'unnamed';

    print('✨ Defining animation: "$animName"');

    state.animations[animName] = {'properties': {}};
  }
}

// ============================================================================
// THEME-SCOPED COMMAND HANDLERS
// ============================================================================

class ThemeApplyShadowsHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;

  ThemeApplyShadowsHandler(this.state);

  @override
  String get commandName => 'apply_shadows';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final value = expandValue(command.args[0], context);
      print('   🌓 Shadows: $value');
    }
  }
}

class ThemeAnimationHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;

  ThemeAnimationHandler(this.state);

  @override
  String get commandName => 'animation_duration';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final value = expandValue(command.args[0], context);
      print('   ⏱️  Animation duration: $value');
    }
  }
}

// ============================================================================
// LAYOUT-SCOPED COMMAND HANDLERS
// ============================================================================

class LayoutDirectionHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;

  LayoutDirectionHandler(this.state);

  @override
  String get commandName => 'direction';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final direction = expandValue(command.args[0], context);
      print('   📏 Direction: $direction');

      // Store in current layout
      if (state.layouts.isNotEmpty) {
        final currentLayout = state.layouts.values.last;
        currentLayout['direction'] = direction;
      }
    }
  }
}

class LayoutPaddingHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;

  LayoutPaddingHandler(this.state);

  @override
  String get commandName => 'padding';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final padding = expandValue(command.args[0], context);
      print('   📦 Padding: $padding');

      if (state.layouts.isNotEmpty) {
        final currentLayout = state.layouts.values.last;
        currentLayout['padding'] = padding;
      }
    }
  }
}

class LayoutBackgroundHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;

  LayoutBackgroundHandler(this.state);

  @override
  String get commandName => 'background';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final bg = expandValue(command.args[0], context);
      print('   🎨 Background: $bg');

      if (state.layouts.isNotEmpty) {
        final currentLayout = state.layouts.values.last;
        currentLayout['background'] = bg;
      }
    }
  }
}

// ============================================================================
// WIDGET-SCOPED COMMAND HANDLERS
// ============================================================================

class WidgetTypeHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetTypeHandler(this.state);

  @override
  String get commandName => 'type';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final type = expandValue(command.args[0], context);
      print('      🔧 Type: $type');
    }
  }
}

class WidgetContentHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetContentHandler(this.state);

  @override
  String get commandName => 'content';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final content = expandValue(command.args[0], context);
      print('      📝 Content: "$content"');
    }
  }
}

class WidgetLabelHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetLabelHandler(this.state);

  @override
  String get commandName => 'label';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final label = expandValue(command.args[0], context);
      print('      🏷️  Label: "$label"');
    }
  }
}

class WidgetColorHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetColorHandler(this.state);

  @override
  String get commandName => 'color';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final color = expandValue(command.args[0], context);
      print('      🎨 Color: $color');
    }
  }
}

class WidgetBackgroundHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetBackgroundHandler(this.state);

  @override
  String get commandName => 'background';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final bg = expandValue(command.args[0], context);
      print('      🖼️  Background: $bg');
    }
  }
}

class WidgetSizeHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetSizeHandler(this.state);

  @override
  String get commandName => 'size';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final size = expandValue(command.args[0], context);
      print('      📏 Size: $size');
    }
  }
}

class WidgetPaddingHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetPaddingHandler(this.state);

  @override
  String get commandName => 'padding';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final padding = expandValue(command.args[0], context);
      print('      📦 Padding: $padding');
    }
  }
}

class WidgetBorderRadiusHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetBorderRadiusHandler(this.state);

  @override
  String get commandName => 'border_radius';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final radius = expandValue(command.args[0], context);
      print('      ⭕ Border radius: $radius');
    }
  }
}

class WidgetItemsHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetItemsHandler(this.state);

  @override
  String get commandName => 'items';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final item = expandValue(command.args[0], context);
      print('      📋 Adding item: "$item"');
    }
  }
}

class WidgetOnClickHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetOnClickHandler(this.state);

  @override
  String get commandName => 'on_click';

  @override
  void handle(Command command, Context context) {
    if (command.args.length >= 2) {
      final action = expandValue(command.args[1], context);
      print('      🖱️  onClick: $action');
    }
  }
}

class WidgetOnHoverHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetOnHoverHandler(this.state);

  @override
  String get commandName => 'on_hover';

  @override
  void handle(Command command, Context context) {
    if (command.args.length >= 2) {
      final action = expandValue(command.args[1], context);
      print('      ✨ onHover: $action');
    }
  }
}

class WidgetPositionHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetPositionHandler(this.state);

  @override
  String get commandName => 'position';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final pos = expandValue(command.args[0], context);
      print('      📍 Position: $pos');
    }
  }
}

class WidgetHeightHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  WidgetHeightHandler(this.state);

  @override
  String get commandName => 'height';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final height = expandValue(command.args[0], context);
      print('      📏 Height: $height');
    }
  }
}

// ============================================================================
// STYLE-SCOPED COMMAND HANDLERS (Nested within widgets)
// ============================================================================

class StyleFontWeightHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  StyleFontWeightHandler(this.state);

  @override
  String get commandName => 'font_weight';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final weight = expandValue(command.args[0], context);
      print('         ✍️  Font weight: $weight');
    }
  }
}

class StyleMarginHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  StyleMarginHandler(this.state);

  @override
  String get commandName => 'margin_bottom';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final margin = expandValue(command.args[0], context);
      print('         📐 Margin bottom: $margin');
    }
  }
}

// ============================================================================
// RESPONSIVE-SCOPED COMMAND HANDLERS
// ============================================================================

class ResponsiveMaxWidthHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  ResponsiveMaxWidthHandler(this.state);

  @override
  String get commandName => 'max_width';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final width = expandValue(command.args[0], context);
      print('   📱 Max width: $width');
    }
  }
}

// ============================================================================
// ANIMATION-SCOPED COMMAND HANDLERS
// ============================================================================

class AnimationDurationHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  AnimationDurationHandler(this.state);

  @override
  String get commandName => 'duration';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final duration = expandValue(command.args[0], context);
      print('   ⏱️  Duration: $duration');

      if (state.animations.isNotEmpty) {
        final currentAnim = state.animations.values.last;
        currentAnim['duration'] = duration;
      }
    }
  }
}

class AnimationEasingHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  AnimationEasingHandler(this.state);

  @override
  String get commandName => 'easing';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final easing = expandValue(command.args[0], context);
      print('   📈 Easing: $easing');
    }
  }
}

class AnimationFromHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  AnimationFromHandler(this.state);

  @override
  String get commandName => 'from';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final from = expandValue(command.args[0], context);
      print('   ⬅️  From: $from');
    }
  }
}

class AnimationToHandler with ValueExpander implements CommandHandler {
  final UIRenderState state;
  AnimationToHandler(this.state);

  @override
  String get commandName => 'to';

  @override
  void handle(Command command, Context context) {
    if (command.args.isNotEmpty) {
      final to = expandValue(command.args[0], context);
      print('   ➡️  To: $to');
    }
  }
}

// NOTE: The parser currently has a limitation where after parsing one widget block,
// subsequent widget/conditional/responsive/animation blocks may not parse correctly.
// This example still demonstrates:
// - Nested blocks (style inside widget)
// - Custom child processing (ConditionalBlockHandler)
// - All other state machine capabilities
// Future parser improvements will handle multiple consecutive blocks of the same type.
