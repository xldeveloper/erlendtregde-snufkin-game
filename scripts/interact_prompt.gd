extends Label

# Animate the interact prompt with a gentle bounce (no scaling)

func _ready():
	# Add gentle vertical bob only
	var original_y = position.y
	var bob_tween = create_tween()
	bob_tween.set_loops()
	bob_tween.tween_property(self, "position:y", original_y - 10, 0.8).set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(self, "position:y", original_y, 0.8).set_ease(Tween.EASE_IN_OUT)
