extends Node2D

# This signal is connected to the 'move_all_pieces' function in the main game script.
signal move

func _ready():
	pass
	
func _process(_delta):
	# The 'ui_down' action is typically mapped to the Down Arrow key in Godot.
	# To fix the inversion (since array Y=0 is visually at the top), 
	# we emit the logical array UP direction (0, 1) when the user presses DOWN.
	if Input.is_action_just_pressed("down"):
		emit_signal("move", Vector2.DOWN)
		
	# The 'ui_up' action is typically mapped to the Up Arrow key.
	# We emit the logical array DOWN direction (0, -1) when the user presses UP.
	if Input.is_action_just_pressed("up"):
		emit_signal("move", Vector2.UP)
		
	# LEFT and RIGHT actions remain correctly mapped.
	if Input.is_action_just_pressed("left"):
		emit_signal("move", Vector2.LEFT)
		
	if Input.is_action_just_pressed("right"):
		emit_signal("move", Vector2.RIGHT)
