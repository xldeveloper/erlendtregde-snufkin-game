# Interaction Area Template
# Use this template for creating interaction zones in your game
# Examples: entering houses, starting fishing, talking to NPCs

extends Area2D

# Configuration
@export var interaction_label_text: String = "Press E to interact"
@export var target_scene: String = "res://scenes/target.tscn"
@export var save_position_before_transition: bool = true

# State tracking
var entered = false
var player_character_body = null

# Node references
@onready var label = $Label

func _ready():
	# Hide label initially
	label.visible = false
	label.text = interaction_label_text
	
	# Connect signals
	# Make sure to connect these in the editor OR use these functions as signal targets

func _on_body_entered(body):
	if body.is_in_group("Player"):
		entered = true
		player_character_body = body
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		entered = false
		player_character_body = null
		label.visible = false

func _process(_delta):
	if entered and Input.is_action_just_pressed("interact"):
		trigger_interaction()

func trigger_interaction():
	# Save position if needed (e.g., entering a new area)
	if save_position_before_transition and player_character_body:
		Global.save_position(player_character_body.global_position)
	
	# Change scene
	get_tree().change_scene_to_file(target_scene)

# SETUP INSTRUCTIONS:
# 1. Add this script to an Area2D node
# 2. Add a Label child node for the interaction prompt
# 3. Add a CollisionShape2D for detection area
# 4. In Inspector, set:
#    - interaction_label_text: What to show player
#    - target_scene: Path to scene to load
#    - save_position_before_transition: true for entrances, false for exits
# 5. Connect signals in editor:
#    - body_entered → _on_body_entered
#    - body_exited → _on_body_exited
# 6. Ensure player is in group "Player"
