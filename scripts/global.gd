extends Node

var from_scene = ""  # Tracks which scene we're coming from ("house_interior", "fishing_scene", etc.)
var current_location = "tent"  # Tracks where the player currently is on the map (tent, moomin_house, bridge)
var previous_scene = ""  # Tracks which scene to return to after closing map
var saved_player_position = Vector2.ZERO  # Saves player position before opening map
var saved_position_scene = ""  # Which scene the saved position belongs to
