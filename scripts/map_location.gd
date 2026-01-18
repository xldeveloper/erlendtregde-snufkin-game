extends Area2D

# Assign these in the editor
@export var location_name: String = ""
@export var target_scene_path: String = ""
@export var focused_texture: Texture2D

# Reference to the focused sprite and label (created in _ready)
var focused_sprite: Sprite2D
var name_label: Label
var is_hovering = false

func _ready():
	# Connect hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	
	# Create the focused sprite (initially hidden)
	focused_sprite = Sprite2D.new()
	focused_sprite.texture = focused_texture
	focused_sprite.visible = false
	focused_sprite.z_index = 100  # Draw below DraggableSnufkin
	add_child(focused_sprite)
	
	# Create the hover label (initially hidden)
	name_label = Label.new()
	name_label.text = location_name
	name_label.visible = false
	name_label.z_index = 400  # Draw above everything
	
	# Style the label
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85))  # Cream color
	name_label.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.1))  # Dark brown outline
	name_label.add_theme_constant_override("outline_size", 8)
	
	# Center the label above the location
	name_label.position = Vector2(-100, -80)  # Adjust Y value: lower number = higher, higher number = lower
	name_label.custom_minimum_size = Vector2(200, 0)  # Set width for centering
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	add_child(name_label)

func _on_mouse_entered():
	is_hovering = true
	if focused_sprite and focused_texture:
		focused_sprite.visible = true
	if name_label:
		name_label.visible = true
	
	# Change cursor to pointing hand
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited():
	is_hovering = false
	if focused_sprite:
		focused_sprite.visible = false
	if name_label:
		name_label.visible = false
	
	# Reset cursor
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_input_event(_viewport, event, _shape_idx):
	# Handle click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_hovering:
			change_scene()

func change_scene():
	if target_scene_path != "":
		get_tree().change_scene_to_file(target_scene_path)
