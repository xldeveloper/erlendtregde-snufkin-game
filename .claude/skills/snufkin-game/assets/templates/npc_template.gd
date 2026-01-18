# NPC Template
# Use this template for creating interactive NPCs with dialogue

extends Area2D

# Configuration - Set these in Inspector
@export var dialogue_control_path: NodePath
@export var npc_name: String = "NPC Name"

# State
var dialogue_control = null
var player_in_range = false

func _ready():
	# Get reference to dialogue controller
	dialogue_control = get_node(dialogue_control_path)
	
	# Connect signals
	# Make sure to connect body_entered and body_exited in editor

func _on_chat_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		# Optional: Show prompt label
		# $Label.visible = true

func _on_chat_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		# Optional: Hide prompt label
		# $Label.visible = false

func _input(event):
	if event.is_action_pressed("interact"):
		if player_in_range and dialogue_control:
			dialogue_control.start_dialogue(self)

# SETUP INSTRUCTIONS:
# 1. Add this script to an Area2D node
# 2. Add CollisionShape2D for detection area
# 3. Add Sprite2D or AnimatedSprite2D for NPC visual
# 4. Optional: Add Label child for "Press E to talk" prompt
# 5. In Inspector, set:
#    - npc_name: Display name in dialogue
#    - dialogue_control_path: Path to Dialogue Control node (usually in same scene)
# 6. Connect signals in editor:
#    - body_entered → _on_chat_detection_area_body_entered
#    - body_exited → _on_chat_detection_area_body_exited
# 7. Ensure player is in group "Player"
#
# DIALOGUE SETUP:
# 1. Create JSON file in res://dialogue/npc_name.json
# 2. Format: [{"name": "NPC Name", "text": "Hello!"}]
# 3. Add sprite to dialogue controller's npc_sprite_path dictionary
