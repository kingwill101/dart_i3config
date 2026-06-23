# Configuration Examples

Real-world examples showing how i3/Sway configurations map to handlers and processing.

## Complete i3 Configuration

### Configuration File
```i3
# Global variables
set $mod Mod4
set $terminal alacritty
set $browser firefox
set $editor vim

# Key bindings
bindsym $mod+Return exec $terminal
bindsym $mod+Shift+b exec $browser
bindsym $mod+Shift+e exec $terminal -e $editor
bindsym $mod+Shift+q kill
bindsym $mod+d exec rofi -show run

# Window assignments
assign [class="Firefox"] 2
assign [class="Alacritty"] 1
assign [title=".*Vim.*"] 3

# Window rules
for_window [class=".*"] border pixel 1
for_window [class="Firefox"] floating enable

# Bar configuration
bar "top" {
    status_command i3status
    position top
    height 30
    font pango:DejaVu Sans Mono 10
    
    colors {
        background #000000
        statusline #ffffff
        focused_workspace #007acc #007acc #ffffff
        inactive_workspace #333333 #333333 #ffffff
    }
    
    tray_output primary
}

# Mode configuration
mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
}

# Include additional configs
include ~/.config/i3/config.d/*
```

### Handler Mapping

| Configuration | Handler | Processing |
|---------------|---------|------------|
| `set $mod Mod4` | `SetCommandHandler` | Sets global variable `mod = "Mod4"` |
| `bindsym $mod+Return exec $terminal` | `BindsymHandler` | Creates key binding with variable expansion |
| `assign [class="Firefox"] 2` | `AssignHandler` | Assigns Firefox windows to workspace 2 |
| `for_window [class=".*"] border pixel 1` | `ForWindowHandler` | Sets border for all windows |
| `bar "top" { ... }` | `BarBlockHandler` | Processes bar block and registers scoped commands |
| `status_command i3status` | `StatusCommandHandler` | Scoped command within bar block |
| `colors { ... }` | `ColorsBlockHandler` | Nested block within bar |
| `mode "resize" { ... }` | `ModeBlockHandler` | Processes resize mode with scoped bindsym |

## Sway Configuration

### Configuration File
```i3
# Global variables
set $mod Mod4
set $terminal alacritty
set $menu wofi --show drun

# Key bindings
bindsym $mod+Return exec $terminal
bindsym $mod+d exec $menu
bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -b 'Yes' 'swaymsg exit'

# Output configuration
output "eDP-1" {
    mode 1920x1080
    position 0,0
    scale 1
    background ~/Pictures/wallpaper.jpg fill
}

output "HDMI-A-1" {
    mode 2560x1440
    position 1920,0
    scale 1
    background ~/Pictures/wallpaper.jpg fill
}

# Input configuration
input "type:keyboard" {
    xkb_layout us
    xkb_variant dvorak
    xkb_options caps:escape
}

input "type:touchpad" {
    tap enabled
    natural_scroll enabled
    middle_emulation enabled
}

# Bar configuration
bar {
    position top
    height 30
    status_command waybar
    
    colors {
        background #000000
        statusline #ffffff
        focused_workspace #007acc #007acc #ffffff
        inactive_workspace #333333 #333333 #ffffff
    }
}
```

### Handler Mapping

| Configuration | Handler | Processing |
|---------------|---------|------------|
| `output "eDP-1" { ... }` | `OutputBlockHandler` | Configures laptop display |
| `mode 1920x1080` | `ModeHandler` | Sets display resolution |
| `position 0,0` | `PositionHandler` | Sets display position |
| `scale 1` | `ScaleHandler` | Sets display scaling |
| `input "type:keyboard" { ... }` | `InputBlockHandler` | Configures keyboard input |
| `xkb_layout us` | `XkbLayoutHandler` | Sets keyboard layout |
| `input "type:touchpad" { ... }` | `InputBlockHandler` | Configures touchpad |

## Custom Application Configuration

### Configuration File
```i3
# Application configuration
app "firefox" {
    theme dark
    keybindings {
        ctrl+t new_tab
        ctrl+w close_tab
        ctrl+r reload
    }
    settings {
        homepage "https://www.google.com"
        search_engine "Google"
        privacy_mode enabled
    }
    plugins {
        adblocker enabled
        password_manager enabled
        sync enabled
    }
}

app "alacritty" {
    theme "gruvbox"
    font "JetBrains Mono"
    font_size 12
    opacity 0.9
    keybindings {
        ctrl+shift+c copy
        ctrl+shift+v paste
        ctrl+shift+t new_tab
    }
    settings {
        shell "/bin/zsh"
        login_shell true
        cursor_style "Block"
    }
}
```

### Handler Mapping

| Configuration | Handler | Processing |
|---------------|---------|------------|
| `app "firefox" { ... }` | `AppBlockHandler` | Processes Firefox configuration |
| `theme dark` | `ThemeHandler` | Sets application theme |
| `keybindings { ... }` | `KeybindingsBlockHandler` | Nested block for keybindings |
| `ctrl+t new_tab` | `KeybindingHandler` | Individual keybinding |
| `settings { ... }` | `SettingsBlockHandler` | Nested block for settings |
| `homepage "..."` | `HomepageHandler` | Sets homepage setting |
| `plugins { ... }` | `PluginsBlockHandler` | Nested block for plugins |

## Game Configuration

### Configuration File
```i3
# Game configuration
game "minecraft" {
    graphics {
        render_distance 12
        vsync enabled
        antialiasing 4x
        shadows enabled
    }
    controls {
        mouse_sensitivity 0.5
        invert_mouse false
        auto_jump enabled
    }
    audio {
        master_volume 0.8
        music_volume 0.6
        sfx_volume 1.0
    }
    world {
        difficulty normal
        cheats disabled
        hardcore false
    }
}
```

### Handler Mapping

| Configuration | Handler | Processing |
|---------------|---------|------------|
| `game "minecraft" { ... }` | `GameBlockHandler` | Processes Minecraft configuration |
| `graphics { ... }` | `GraphicsBlockHandler` | Graphics settings block |
| `render_distance 12` | `RenderDistanceHandler` | Sets render distance |
| `vsync enabled` | `VsyncHandler` | Enables VSync |
| `controls { ... }` | `ControlsBlockHandler` | Control settings block |
| `mouse_sensitivity 0.5` | `MouseSensitivityHandler` | Sets mouse sensitivity |

## Development Environment Configuration

### Configuration File
```i3
# Development environment
dev "project" {
    language "dart"
    framework "flutter"
    
    tools {
        editor "vscode"
        terminal "alacritty"
        browser "firefox"
        git_client "gitkraken"
    }
    
    settings {
        auto_format true
        lint_on_save true
        hot_reload true
        debug_mode enabled
    }
    
    keybindings {
        ctrl+shift+p command_palette
        ctrl+` toggle_terminal
        f5 debug_start
        ctrl+f5 run_without_debug
    }
    
    extensions {
        dart enabled
        flutter enabled
        gitlens enabled
        prettier enabled
    }
}
```

### Handler Mapping

| Configuration | Handler | Processing |
|---------------|---------|------------|
| `dev "project" { ... }` | `DevBlockHandler` | Processes development configuration |
| `language "dart"` | `LanguageHandler` | Sets programming language |
| `framework "flutter"` | `FrameworkHandler` | Sets framework |
| `tools { ... }` | `ToolsBlockHandler` | Development tools block |
| `editor "vscode"` | `EditorHandler` | Sets code editor |
| `settings { ... }` | `SettingsBlockHandler` | Development settings |
| `auto_format true` | `AutoFormatHandler` | Enables auto-formatting |

## Handler Implementation Examples

### Bar Block Handler
```dart
class BarBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'bar';
  
  @override
  void handle(Block block, Context context) {
    final id = getBlockIdentifier(block, context);
    print('📊 Setting up bar: $id');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('status_command', StatusCommandHandler());
    registry.registerCommand('position', PositionHandler());
    registry.registerCommand('height', HeightHandler());
    registry.registerCommand('font', FontHandler());
    registry.registerCommand('colors', ColorsHandler());
    registry.registerCommand('tray_output', TrayOutputHandler());
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    final id = getBlockIdentifier(block, context);
    final statusCommand = context.getVariable('status_command');
    final position = context.getVariable('position');
    final height = context.getVariable('height');
    
    print('📊 Bar "$id" configured:');
    print('  Status: $statusCommand');
    print('  Position: $position');
    print('  Height: $height');
  }
}
```

### Output Block Handler
```dart
class OutputBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'output';
  
  @override
  void handle(Block block, Context context) {
    final output = getBlockIdentifier(block, context);
    print('🖥️  Configuring output: $output');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('mode', OutputModeHandler());
    registry.registerCommand('position', OutputPositionHandler());
    registry.registerCommand('scale', OutputScaleHandler());
    registry.registerCommand('background', OutputBackgroundHandler());
    registry.registerCommand('transform', OutputTransformHandler());
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    final output = getBlockIdentifier(block, context);
    final mode = context.getVariable('mode');
    final position = context.getVariable('position');
    final scale = context.getVariable('scale');
    
    print('🖥️  Output "$output" configured:');
    print('  Mode: $mode');
    print('  Position: $position');
    print('  Scale: $scale');
  }
}
```

### App Block Handler
```dart
class AppBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'app';
  
  @override
  void handle(Block block, Context context) {
    final appName = getBlockIdentifier(block, context);
    print('📱 Configuring app: $appName');
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('theme', AppThemeHandler());
    registry.registerCommand('keybindings', AppKeybindingsHandler());
    registry.registerCommand('settings', AppSettingsHandler());
    registry.registerCommand('plugins', AppPluginsHandler());
    registry.registerCommand('font', AppFontHandler());
    registry.registerCommand('opacity', AppOpacityHandler());
  }
  
  @override
  Future<void> afterChildrenProcessed(Block block, Context context) async {
    final appName = getBlockIdentifier(block, context);
    final theme = context.getVariable('theme');
    final font = context.getVariable('font');
    final opacity = context.getVariable('opacity');
    
    print('📱 App "$appName" configured:');
    print('  Theme: $theme');
    print('  Font: $font');
    print('  Opacity: $opacity');
    
    // Generate app configuration file
    await _generateAppConfig(appName, context);
  }
  
  Future<void> _generateAppConfig(String appName, Context context) async {
    // Implementation to generate app-specific config file
    print('📄 Generating config file for $appName');
  }
}
```

## Processing Flow

### 1. Global Commands
```dart
// Processed first, set global context
set $mod Mod4
set $terminal alacritty
bindsym $mod+Return exec $terminal
```

### 2. Block Processing
```dart
// Each block creates its own context
bar "top" {
    // Inherits global context
    // Can set local variables
    // Registers scoped commands
}
```

### 3. Scoped Commands
```dart
// Commands within blocks use block context
status_command i3status  // Only works inside bar blocks
position top            // Only works inside bar blocks
```

### 4. Nested Blocks
```dart
// Nested blocks inherit from parent block context
bar "top" {
    colors {
        // Inherits from both global and bar context
        background #000000
    }
}
```

## Best Practices

### 1. Use Descriptive Block Types
```i3
# Good
app "firefox" { ... }
game "minecraft" { ... }
dev "project" { ... }

# Avoid
config "firefox" { ... }
settings "minecraft" { ... }
env "project" { ... }
```

### 2. Group Related Commands
```i3
# Group related commands in blocks
app "vscode" {
    theme dark
    font "JetBrains Mono"
    font_size 12
    keybindings {
        ctrl+shift+p command_palette
        ctrl+` toggle_terminal
    }
}
```

### 3. Use Consistent Naming
```i3
# Use consistent naming conventions
set $app_terminal alacritty
set $app_browser firefox
set $app_editor vscode

# Or use descriptive names
set $terminal_app alacritty
set $browser_app firefox
set $editor_app vscode
```

### 4. Leverage Context Inheritance
```i3
# Set base variables globally
set $base_color #ffffff
set $accent_color #007acc

# Use in blocks
bar "top" {
    colors {
        background $base_color
        focused_workspace $accent_color $accent_color $base_color
    }
}
```

