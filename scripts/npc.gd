extends Area2D

@export var dialogue_control_path: NodePath
@export var npc_name: String = "Moomin mama"  # Set per NPC in the inspector
@export var npc_portrait: Texture2D  # NPC portrait for dialogue

var dialogue_control
var player_in_range = false
var interact_prompt

func _ready():
	dialogue_control = get_node(dialogue_control_path)
	interact_prompt = get_node("../InteractPrompt")
	# Set process input to run even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_chat_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		if interact_prompt:
			interact_prompt.visible = true

func _on_chat_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		if interact_prompt:
			interact_prompt.visible = false

func _input(event):
	# Only trigger when E is pressed, player is in range, and not already in dialogue
	if event.is_action_pressed("interact") and not event.is_echo():
		if player_in_range and dialogue_control and not dialogue_control.visible:
			# Hide interact prompt when dialogue opens
			if interact_prompt:
				interact_prompt.visible = false
			dialogue_control.start_dialogue(self)
