# Piece.gd
extends Node2D

@export var value: int # The numerical value of the tile (e.g., 2, 4, 8)
@export var next_value: PackedScene # The tile scene this piece turns into when merged
var just_merged := false # Flag to prevent double merging in a single move

# --- READY ---
func _ready():
	# Ensure starting scale is correct, though 'appear()' handles the animation
	scale = Vector2(1, 1)

# --- MOVEMENT (SMOOTH SLIDING) ---
func move(new_position: Vector2):
	var tween = create_tween()
	# TRANS_SINE or TRANS_QUAD gives a smooth, clean slide for tiles
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 0.15 seconds is a good duration for smooth, quick movement
	tween.tween_property(self, "position", new_position, 0.35)

# --- APPEARANCE ANIMATION (On Spawn) ---
func appear():
	scale = Vector2(0, 0)
	var tween = create_tween()
	# Use a basic transition (TRANS_QUAD or TRANS_SINE) for the custom overshoot steps
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 1. Quick initial pop
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15) 
	
	# 2. Smooth settlement (increased duration for better feel)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.25)
# --- MERGE ANIMATION (On Value Increase) ---
func merge_animation():
	var tween = create_tween()
	# Pop out bigger
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	# Shrink back to normal
	tween.tween_property(self, "scale", Vector2(1, 1), 0.1)

# --- REMOVAL ---
func remove():
	# You could add a fade-out animation here, but queue_free() works instantly
	queue_free()
