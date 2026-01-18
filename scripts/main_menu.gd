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
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	hover_style.content_margin_left = 25
	hover_style.content_margin_right = 25
	hover_style.content_margin_top = 15
	hover_style.content_margin_bottom = 15
	hover_style.border_width_left = 3
	hover_style.border_width_right = 3
	hover_style.border_width_top = 3
	hover_style.border_width_bottom = 3
	hover_style.border_color = Color(0.224, 0.369, 0.216)
	hover_style.shadow_size = 8
	hover_style.shadow_color = Color(0, 0, 0, 0.25)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.165, 0.275, 0.157)  # Darker green
	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_left = 8
	pressed_style.corner_radius_bottom_right = 8
	pressed_style.content_margin_left = 25
	pressed_style.content_margin_right = 25
	pressed_style.content_margin_top = 17
	pressed_style.content_margin_bottom = 13
	pressed_style.border_width_left = 3
	pressed_style.border_width_right = 3
	pressed_style.border_width_top = 3
	pressed_style.border_width_bottom = 3
	pressed_style.border_color = Color(0.118, 0.196, 0.11)
	
	start_button.add_theme_stylebox_override("normal", normal_style)
	start_button.add_theme_stylebox_override("hover", hover_style)
	start_button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Add subtle fade-in animation
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)

func _on_start_button_pressed():
	# Fade out animation before starting
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	await tween.finished
	
	# Start the game at the map scene
	get_tree().change_scene_to_file("res://scenes/map_scene.tscn")
