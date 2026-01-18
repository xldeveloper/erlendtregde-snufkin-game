# Main Menu System

## Overview
A storybook-inspired main menu that introduces players to the game, explains controls, and provides a beautiful entry point to the adventure.

## Design Philosophy

**Aesthetic Direction**: Organic/Natural Storybook
- Cream/parchment background colors (#EAE5D6)
- Forest green accents (#395E37)
- Warm brown text (#3F332B)
- Clean, readable typography
- Generous spacing and margins
- Subtle fade animations

## Scene Structure (`scenes/main_menu.tscn`)

### Root Control
```
MainMenu (Control)
├── Background (ColorRect) - Cream color
│   └── BackgroundTexture (ColorRect) - Subtle overlay
├── MainContainer (HBoxContainer)
│   ├── LeftPanel (MarginContainer) - Text content
│   │   └── ContentVBox (VBoxContainer)
│   │       ├── TitleContainer
│   │       │   ├── Title - "Snufkin's Journey"
│   │       │   └── Subtitle - "A Peaceful Adventure..."
│   │       ├── AboutTitle
│   │       ├── AboutText (RichTextLabel)
│   │       ├── ControlsTitle
│   │       ├── ControlsList (RichTextLabel)
│   │       └── StartButton
│   └── RightPanel (MarginContainer) - Character image
│       └── CharacterContainer (CenterContainer)
│           └── SnufkinImage (TextureRect)
└── VersionLabel
```

### Layout Specifications

#### Left Panel
- Margin: 80px left, 60px top/bottom, 40px right
- Stretch ratio: 1.2 (takes more space than right)
- VBox separation: 35px between sections

#### Right Panel
- Margin: 40px left, 100px top/bottom, 80px right
- Contains centered Snufkin smoking image
- Image size: 600x600 pixels minimum

## Script Implementation (`scripts/main_menu.gd`)

```gdscript
extends Control

@onready var start_button = $MainContainer/LeftPanel/ContentVBox/StartButton

func _ready():
    # Style the start button with custom StyleBox
    var normal_style = StyleBoxFlat.new()
    normal_style.bg_color = Color(0.224, 0.369, 0.216)  # Forest green
    normal_style.corner_radius_top_left = 8
    normal_style.corner_radius_top_right = 8
    normal_style.corner_radius_bottom_left = 8
    normal_style.corner_radius_bottom_right = 8
    normal_style.content_margin_left = 25
    normal_style.content_margin_right = 25
    normal_style.content_margin_top = 15
    normal_style.content_margin_bottom = 15
    normal_style.border_width_left = 3
    normal_style.border_width_right = 3
    normal_style.border_width_top = 3
    normal_style.border_width_bottom = 3
    normal_style.border_color = Color(0.165, 0.275, 0.157)
    
    var hover_style = StyleBoxFlat.new()
    hover_style.bg_color = Color(0.275, 0.447, 0.267)  # Lighter green
    # ... same properties plus shadow
    hover_style.shadow_size = 8
    hover_style.shadow_color = Color(0, 0, 0, 0.25)
    
    var pressed_style = StyleBoxFlat.new()
    pressed_style.bg_color = Color(0.165, 0.275, 0.157)  # Darker green
    # ... adjusted margins for pressed effect
    pressed_style.content_margin_top = 17
    pressed_style.content_margin_bottom = 13
    
    start_button.add_theme_stylebox_override("normal", normal_style)
    start_button.add_theme_stylebox_override("hover", hover_style)
    start_button.add_theme_stylebox_override("pressed", pressed_style)
    
    # Fade-in animation
    modulate.a = 0.0
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)

func _on_start_button_pressed():
    # Fade out before transitioning
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
    await tween.finished
    
    # Go to map scene
    get_tree().change_scene_to_file("res://scenes/map_scene.tscn")
```

## Typography Hierarchy

### Title
- Font size: 72px
- Color: Forest green (#395E37)
- Outline: Cream (#EAE5D6), 3px
- Text: "Snufkin's Journey"

### Subtitle
- Font size: 26px
- Color: Warm brown (#665848)
- Text: "A Peaceful Adventure in Moominvalley"

### Section Titles (About, Controls)
- Font size: 32px
- Color: Dark brown (#4C3F32)

### Body Text
- Font size: 20px
- Color: Deep brown (#3F3328)
- Uses RichTextLabel for formatting
- BBCode enabled for bold text

### Start Button
- Font size: 32px
- Color: Cream on green background
- Hover: White text
- Minimum size: 320x70 pixels

## Content Text

### About Section
```
Wander through Moominvalley as Snufkin. Fish by the bridge, visit friends at the Moomin House, and rest by your tent. Use the map to travel between peaceful locations.
```

### Controls Section
```
[b]Movement[/b] — Arrow keys or A/D
[b]Interact[/b] — Space bar
[b]Open Map[/b] — M key
[b]Close Map[/b] — Escape key

[b]Map Navigation[/b]
Right-click and drag Snufkin to move him on the map
Left-click on Snufkin when over a location to travel there
```

## Button Styling

### Normal State
- Background: Forest green (#395E37)
- Border: Dark forest green (#2A4628), 3px
- Rounded corners: 8px radius
- Content margin: 25px horizontal, 15px vertical

### Hover State
- Background: Lighter green (#467143)
- Border: Forest green (#395E37), 3px
- Shadow: 8px, semi-transparent black
- Content margin: Same as normal

### Pressed State
- Background: Darker green (#2A4628)
- Border: Very dark green (#1E311C), 3px
- Content margin: 25px horizontal, 17px top, 13px bottom (creates pressed effect)

## Animation Details

### Fade-In (On Load)
- Duration: 0.8 seconds
- Easing: EASE_OUT
- Property: modulate.a (0.0 → 1.0)

### Fade-Out (On Button Press)
- Duration: 0.4 seconds
- Easing: EASE_IN
- Property: modulate.a (1.0 → 0.0)
- Followed by: Scene change to map_scene.tscn

## Project Configuration

Update `project.godot`:
```ini
[application]
config/name="snufkingame"
run/main_scene="res://scenes/main_menu.tscn"
```

## Assets Required

### Images
- `res://dialague/Images/idleSmokeing.png` - Snufkin smoking idle sprite
  - UID: uid://dxq4efhlrxub2
  - Display size: 600x600px
  - Stretch mode: Keep aspect centered

## Integration with Game Flow

### User Journey
1. **Game starts** → Main menu loads with fade-in
2. **Player reads** → Information about game and controls
3. **Button click** → "Begin Journey" fades out menu
4. **Scene transition** → Opens map_scene.tscn
5. **Map interaction** → Player can select starting location

### Scene Flow
```
main_menu.tscn
    ↓ (Begin Journey button)
map_scene.tscn
    ↓ (Select location)
main.tscn / house_interior.tscn / fishing_scene.tscn
```

## Design Patterns

### Color Palette
```gdscript
# Primary Colors
var cream = Color(0.918, 0.898, 0.839)      # #EAE5D6
var forest_green = Color(0.224, 0.369, 0.216)  # #395E37
var dark_brown = Color(0.298, 0.247, 0.196)    # #4C3F32

# Accent Colors
var light_green = Color(0.275, 0.447, 0.267)   # #467143
var very_dark_green = Color(0.118, 0.196, 0.11) # #1E311C

# Text Colors
var warm_brown = Color(0.4, 0.35, 0.3)         # #665848
var deep_brown = Color(0.247, 0.2, 0.157)      # #3F3328
```

### StyleBox Pattern
```gdscript
func create_button_style(bg_color, border_color, margin_top=15, margin_bottom=15):
    var style = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    style.content_margin_left = 25
    style.content_margin_right = 25
    style.content_margin_top = margin_top
    style.content_margin_bottom = margin_bottom
    style.border_width_left = 3
    style.border_width_right = 3
    style.border_width_top = 3
    style.border_width_bottom = 3
    style.border_color = border_color
    return style
```

## Best Practices

1. **Consistent spacing**: Use theme overrides for margins and separations
2. **RichTextLabel for formatting**: Enables bold text and future styling
3. **Custom StyleBox**: Complete control over button appearance
4. **Smooth transitions**: Fade animations create polished feel
5. **Readable text**: High contrast between text and background
6. **Centered image**: TextureRect with proper minimum size
7. **Version label**: Bottom-right corner, subtle and unobtrusive

## Common Customizations

### Change Button Text
```gdscript
# In main_menu.tscn
[node name="StartButton" type="Button"]
text = "Begin Journey"  # Change this
```

### Adjust Fade Speed
```gdscript
# In main_menu.gd _ready()
tween.tween_property(self, "modulate:a", 1.0, 0.8)  # Change 0.8
```

### Modify Colors
Edit the StyleBox creation in `_ready()`:
```gdscript
normal_style.bg_color = Color(0.224, 0.369, 0.216)  # Change RGB values
```

### Update Content
Edit RichTextLabel text properties in scene:
```
[node name="AboutText" type="RichTextLabel"]
text = "Your new about text here"
```

### Resize Image
```
[node name="SnufkinImage" type="TextureRect"]
custom_minimum_size = Vector2(600, 600)  # Change dimensions
```
