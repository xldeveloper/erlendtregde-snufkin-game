extends CanvasLayer

# Dialogue System Configuration
@export var dialogue_file: String = "res://dialague/moominMama.json"
@export var typewriter_speed: float = 0.03  # Seconds per character
@export var player_portrait: Texture2D  # Player's portrait

# Dialogue Data
var dialogue = []
var current_dialogue_id = -1
var active_npc = null
var is_typing = false
var current_text = ""
var visible_characters = 0

# NPC Portrait Mappings
var npc_sprite_path = {}

# Node References
@onready var overlay = $Overlay
@onready var dialogue_container = $DialogueContainer
@onready var player_portrait_rect = $DialogueContainer/PlayerPortrait
@onready var player_name_label = $DialogueContainer/PlayerPortrait/PlayerNameLabel
@onready var npc_portrait_rect = $DialogueContainer/NPCPortrait
@onready var npc_portrait_name_label = $DialogueContainer/NPCPortrait/NPCNameLabel
@onready var dialogue_box = $DialogueContainer/DialogueBox
@onready var npc_name_label = $DialogueContainer/DialogueBox/NPCNameBanner/NPCName
@onready var dialogue_text = $DialogueContainer/DialogueBox/DialogueText
@onready var typewriter_timer = $TypewriterTimer
@onready var decorative_corners = [
	$DialogueContainer/DialogueBox/DecorativeCornerTL,
	$DialogueContainer/DialogueBox/DecorativeCornerTR,
	$DialogueContainer/DialogueBox/DecorativeCornerBL,
	$DialogueContainer/DialogueBox/DecorativeCornerBR
]

# Player reference
var player_node = null

func _ready():
	# Set process mode to work when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Get player reference
	player_node = get_tree().get_first_node_in_group("Player")
	
	# Setup NPC portrait mappings
	npc_sprite_path = {
		"Moomin mama": preload("res://assets/images/moominmama.PNG"),
	}
	
	# Setup typewriter timer
	typewriter_timer.wait_time = typewriter_speed
	typewriter_timer.timeout.connect(_on_typewriter_timeout)
	
	# Hide all UI elements initially
	visible = false
	overlay.visible = false
	dialogue_container.visible = false

func load_dialogue():
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	if not file:
		push_error("Failed to open dialogue file: " + dialogue_file)
		return
	var content = file.get_as_text()
	file.close()
	
	if content.is_empty():
		push_error("Dialogue file is empty: " + dialogue_file)
		return
		
	dialogue = JSON.parse_string(content)
	if dialogue == null:
		push_error("Failed to parse JSON in dialogue file: " + dialogue_file)

func start_dialogue(npc):
	if active_npc or get_tree().paused:
		return  # Prevent multiple dialogues or opening during pause
	
	active_npc = npc
	load_dialogue()
	
	if dialogue == null or dialogue.size() == 0:
		push_error("No dialogue data available")
		return
	
	# Pause the game
	get_tree().paused = true
	
	# Disable player input (player script will handle physics)
	if player_node:
		player_node.set_physics_process(false)
		if "velocity" in player_node:
			player_node.velocity = Vector2.ZERO
	
	# Setup portraits
	_setup_portraits(npc)
	
	# Show UI with fade-in animation
	visible = true
	_animate_dialogue_in()
	
	# Reset dialogue
	current_dialogue_id = -1
	
	# Start first dialogue
	await get_tree().create_timer(0.3, true, false, true).timeout  # Wait for animation
	next_dialogue()

func _setup_portraits(npc):
	# Set player portrait (left side)
	if player_portrait:
		player_portrait_rect.texture = player_portrait
	
	# Set NPC portrait (right side)
	if npc.npc_portrait:
		npc_portrait_rect.texture = npc.npc_portrait
	elif npc.npc_name in npc_sprite_path:
		npc_portrait_rect.texture = npc_sprite_path[npc.npc_name]
	
	# Set NPC name under portrait
	if npc.npc_name:
		npc_portrait_name_label.text = npc.npc_name

func _animate_dialogue_in():
	# Fade in overlay with subtle vignette effect
	overlay.modulate.a = 0
	overlay.visible = true
	
	# Position dialogue container
	dialogue_container.modulate.a = 0
	dialogue_container.visible = true
	
	# Position portraits for organic bounce-in effect
	var player_original_y = player_portrait_rect.position.y
	var npc_original_y = npc_portrait_rect.position.y
	player_portrait_rect.position.y += 80
	npc_portrait_rect.position.y += 80
	player_portrait_rect.modulate.a = 0
	npc_portrait_rect.modulate.a = 0
	player_portrait_rect.scale = Vector2(0.85, 0.85)
	npc_portrait_rect.scale = Vector2(0.85, 0.85)
	
	# Dialogue box starts slightly smaller
	dialogue_box.scale = Vector2(0.92, 0.92)
	dialogue_box.modulate.a = 0
	
	# Decorative corners start rotated and scaled
	for corner in decorative_corners:
		corner.modulate.a = 0
		corner.scale = Vector2(0.5, 0.5)
		corner.rotation = randf_range(-0.5, 0.5)
	
	# Main animation sequence
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Overlay gentle fade
	tween.tween_property(overlay, "modulate:a", 0.45, 0.4).set_ease(Tween.EASE_OUT)
	
	# Container fade
	tween.tween_property(dialogue_container, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	
	# Dialogue box pop in with elastic bounce
	tween.tween_property(dialogue_box, "scale", Vector2(1.0, 1.0), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.4).set_delay(0.1)
	
	# Player portrait organic bounce (slight rotation for life)
	tween.tween_property(player_portrait_rect, "position:y", player_original_y, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.15)
	tween.tween_property(player_portrait_rect, "modulate:a", 1.0, 0.4).set_delay(0.15)
	tween.tween_property(player_portrait_rect, "scale", Vector2(1.0, 1.0), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.15)
	tween.tween_property(player_portrait_rect, "rotation", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_delay(0.15)
	
	# NPC portrait organic bounce (delayed, with slight tilt)
	tween.tween_property(npc_portrait_rect, "position:y", npc_original_y, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.25)
	tween.tween_property(npc_portrait_rect, "modulate:a", 1.0, 0.4).set_delay(0.25)
	tween.tween_property(npc_portrait_rect, "scale", Vector2(1.0, 1.0), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.25)
	tween.tween_property(npc_portrait_rect, "rotation", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_delay(0.25)
	
	# Decorative corners cascade in with playful rotation
	for i in range(decorative_corners.size()):
		var corner = decorative_corners[i]
		var delay = 0.3 + (i * 0.08)
		tween.tween_property(corner, "modulate:a", 0.6, 0.3).set_delay(delay)
		tween.tween_property(corner, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(delay)
		tween.tween_property(corner, "rotation", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_delay(delay)

func _animate_dialogue_out():
	# Gentle fade and shrink out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Overlay fade
	tween.tween_property(overlay, "modulate:a", 0, 0.25).set_ease(Tween.EASE_IN)
	
	# Container fade
	tween.tween_property(dialogue_container, "modulate:a", 0, 0.3).set_ease(Tween.EASE_IN)
	
	# Dialogue box gentle shrink
	tween.tween_property(dialogue_box, "scale", Vector2(0.95, 0.95), 0.25).set_ease(Tween.EASE_IN)
	
	# Portraits gentle float down
	tween.tween_property(player_portrait_rect, "position:y", player_portrait_rect.position.y + 30, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_property(npc_portrait_rect, "position:y", npc_portrait_rect.position.y + 30, 0.3).set_ease(Tween.EASE_IN)
	
	await tween.finished

func _input(event):
	if not visible or not active_npc:
		return
	
	# ESC to exit dialogue
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		end_dialogue()
		get_viewport().set_input_as_handled()
	
	# Space/Enter or E to advance dialogue
	elif (event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")) and not event.is_echo():
		if is_typing:
			# Skip typewriter effect and show full text
			_finish_typing()
		else:
			# Move to next dialogue
			next_dialogue()
		get_viewport().set_input_as_handled()

func next_dialogue():
	if is_typing:
		return
	
	current_dialogue_id += 1
	
	if current_dialogue_id >= dialogue.size():
		end_dialogue()
		return
	
	var current_line = dialogue[current_dialogue_id]
	
	if "name" not in current_line or "text" not in current_line:
		push_error("Missing 'name' or 'text' in dialogue entry!")
		end_dialogue()
		return
	
	# Update NPC name
	npc_name_label.text = current_line['name']
	
	# Add subtle speaking animation to the correct portrait
	_animate_speaking_portrait(current_line['name'])
	
	# Start typewriter effect
	current_text = current_line['text']
	visible_characters = 0
	dialogue_text.text = ""
	is_typing = true
	
	typewriter_timer.start()

func _animate_speaking_portrait(speaker_name: String):
	# Determine which portrait to animate based on speaker
	var portrait_to_animate
	if speaker_name == "Snufkin" or speaker_name == "Player":
		portrait_to_animate = player_portrait_rect
	else:
		portrait_to_animate = npc_portrait_rect
	
	# Whimsical speaking animation - gentle wiggle and pulse
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	
	# Gentle scale pulse
	tween.tween_property(portrait_to_animate, "scale", Vector2(1.08, 1.08), 0.15).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(portrait_to_animate, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# Subtle rotation wiggle
	var original_rotation = portrait_to_animate.rotation
	tween.tween_property(portrait_to_animate, "rotation", original_rotation + 0.05, 0.12).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(portrait_to_animate, "rotation", original_rotation - 0.03, 0.15).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_property(portrait_to_animate, "rotation", original_rotation, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _on_typewriter_timeout():
	if visible_characters < current_text.length():
		visible_characters += 1
		dialogue_text.text = current_text.substr(0, visible_characters)
		
		# Play typing sound effect here if you have one
		# typing_sound.play()
	else:
		_finish_typing()

func _finish_typing():
	typewriter_timer.stop()
	is_typing = false
	dialogue_text.text = current_text
	visible_characters = current_text.length()

func end_dialogue():
	if not visible or not active_npc:
		return
	
	# Stop typing
	is_typing = false
	typewriter_timer.stop()
	
	# Animate out
	await _animate_dialogue_out()
	
	# Hide UI
	visible = false
	overlay.visible = false
	dialogue_container.visible = false
	
	# Reset state
	active_npc = null
	current_dialogue_id = -1
	current_text = ""
	visible_characters = 0
	
	# Re-enable player
	if player_node:
		player_node.set_physics_process(true)
	
	# Unpause game
	get_tree().paused = false
