extends Node2D

# --- PERSISTENCE SETTINGS ---
const SAVE_FILE_PATH = "user://game_save.cfg"
const SAVE_SECTION = "game_data"
const BEST_SCORE_KEY = "best_score"

# --- GRID SETTINGS ---
var width := 4
var height := 4
var board := []
var score := 0
var best_score := 0
var game_over := false

const GRID_BOX_SIZE := Vector2(512, 512) # fixed box for the grid

# --- NODES ---
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var best_score_label: Label = $VBoxContainer/BestScoreLabel
@onready var game_over_label: Panel = $"../GameOverLabel"
@onready var game_over_sound: AudioStreamPlayer2D = $"../GameOverSound"
@onready var merge_sound: AudioStreamPlayer2D = $"../MergeSound"

# --- EXPORTS ---
@export var four_piece_chance : int
@export var number_of_starting_pieces : int = 2
@export var two_piece : PackedScene
@export var four_piece : PackedScene
@export var background_piece: PackedScene

# --- READY ---
func _ready():
	# --- BEST SCORE INIT ---
	load_best_score()
	# -----------------------
	randomize()
	board = make_2d_array()
	generate_background()
	game_over_label.visible = false
	reset_game()
	# We start the game in a 'game_over' state to prevent moves until a button is pressed

	# Connect the viewport signal for responsive design (Godot 4 Callable syntax)
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_resized"))

# --- SAVE ON QUIT (NEW IMPLEMENTATION) ---
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Close request received, saving best score...")
		# 1. Check if the current score is higher than the loaded best score.
		if score > best_score:
			save_best_score()
		# 2. Finally, quit the application.
		get_tree().quit()

# --- VIEWPORT RESIZE ---
func _on_viewport_resized():
	var scale_factor = get_grid_offset() / 128.0
	
	# Reposition and rescale all game pieces
	for x in range(width):
		for y in range(height):
			if board[x][y] != null:
				board[x][y].position = grid_to_pixel(Vector2(x, y))
				board[x][y].scale = Vector2(scale_factor, scale_factor)

	# Reposition and rescale background pieces
	for bg in get_children():
		if bg.name.begins_with("Background_"):
			var coords = bg.name.split("_")
			var i = int(coords[1])
			var j = int(coords[2])
			bg.position = grid_to_pixel(Vector2(i, j))
			bg.scale = Vector2(scale_factor, scale_factor)

# --- GRID HELPERS (The Centering Logic) ---
func get_grid_offset() -> float:
	# Calculates the size of one cell based on the fixed GRID_BOX_SIZE
	return min(GRID_BOX_SIZE.x / width, GRID_BOX_SIZE.y / height)

func get_grid_start() -> Vector2:
	var offset = get_grid_offset()
	# Total width/height of the grid from the center of the first piece to the center of the last
	var grid_span_width = offset * (width - 1)
	var grid_span_height = offset * (height - 1)
	
	# Find the top-left corner of the centered 512x512 box in the viewport
	var box_top_left = (get_viewport_rect().size - GRID_BOX_SIZE) / 2
	
	# The START position is the center of the top-left piece (0, 0)
	return Vector2(
		# X: Start of 512 box + (512 - grid span) / 2
		box_top_left.x + (GRID_BOX_SIZE.x - grid_span_width) / 2,
		# Y: Start of 512 box + (512 - grid span) / 2 + grid_span_height (to get to the bottom row center)
		# We must center the grid vertically relative to the fixed box.
		box_top_left.y + (GRID_BOX_SIZE.y - grid_span_height) / 2 + grid_span_height
	)

func grid_to_pixel(grid_position: Vector2) -> Vector2:
	var offset = get_grid_offset()
	var start = get_grid_start()
	# Position = Start + Offset * Index. Y is inverted (minus sign).
	return Vector2(
		start.x + offset * grid_position.x,
		start.y - offset * grid_position.y
	)

func pixel_to_grid(pixel_position: Vector2) -> Vector2:
	var offset = get_grid_offset()
	var start = get_grid_start()
	# The correct inverse of grid_to_pixel for a centered grid
	return Vector2(
		round((pixel_position.x - start.x) / offset),
		round((start.y - pixel_position.y) / offset)
	)

func is_in_grid(grid_position: Vector2) -> bool:
	return grid_position.x >= 0 and grid_position.x < width and grid_position.y >= 0 and grid_position.y < height

# --- ARRAY HELPERS ---
func make_2d_array():
	var arr = []
	for x in range(width):
		var col = []
		for y in range(height):
			col.append(null)
		arr.append(col)
	return arr

# --- BOARD HELPERS ---
func is_blank_space() -> bool:
	for i in range(width):
		for j in range(height):
			if board[i][j] == null:
				return true
	return false

# --- SCORE ---
func add_score(amount: int):
	score += amount
	score_label.text = str(score)
	# Check if the new score is a new best score
	if score > best_score:
		best_score = score
		best_score_label.text = str(best_score)

# --- BEST SCORE PERSISTENCE ---
func load_best_score():
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE_PATH)
	
	if err == OK:
		# Read the value, default to 0 if not found
		best_score = config.get_value(SAVE_SECTION, BEST_SCORE_KEY, 0)
	else:
		best_score = 0
		
	best_score_label.text = str(best_score)
	
# --- BEST SCORE PERSISTENCE (Simplified and Improved) ---
func save_best_score():
	var config = ConfigFile.new()
	# Always load existing config to maintain other data if any.
	config.load(SAVE_FILE_PATH)
	
	# Set the new best score (which is guaranteed to be the highest value seen so far
	# due to the logic in load_best_score() and add_score()).
	config.set_value(SAVE_SECTION, BEST_SCORE_KEY, best_score) # <--- USE best_score, not score
	
	# Save the file
	var err = config.save(SAVE_FILE_PATH)
	if err != OK:
		printerr("Error saving best score: ", err)

# --- RESET GAME ---
func _on_new_game_button_pressed():
	reset_game()

func reset_game():
	# Before clearing, update best score in case the player hit 'New Game' mid-game with a new high
	if score > best_score:
		save_best_score()
		
	for i in range(width):
		for j in range(height):
			if board[i][j] != null:
				board[i][j].queue_free()
				board[i][j] = null

	score = 0
	score_label.text = "0"
	game_over = false
	game_over_label.visible = false

	generate_new_piece(number_of_starting_pieces)

# --- GAME OVER CHECK ---
func check_game_over():
	if is_blank_space():
		return false

	for x in range(width):
		for y in range(height):
			var current = board[x][y]
			if current == null:
				continue
			var dirs = [Vector2(1,0), Vector2(0,1)]
			for dir in dirs:
				var nx = x + dir.x
				var ny = y + dir.y
				if is_in_grid(Vector2(nx, ny)):
					var neighbor = board[nx][ny]
					if neighbor != null and neighbor.value == current.value:
						return false
						
	game_over = true
	game_over_sound.play()
	MainTheme.stop()
	game_over_label.visible = true
	print("Game Over!")
	
	save_best_score()
	
	return true

# --- MOVE LOGIC ---
func move_all_pieces(direction: Vector2):
	if game_over:
		return

	# Initialize a dictionary to track if any piece moved or merged
	var move_data = {"moved": false}

	for i in range(width):
		for j in range(height):
			if board[i][j] != null:
				board[i][j].just_merged = false

	var dir := Vector2(direction.x, -direction.y)

	# The loops now pass 'move_data' to 'move_piece'
	match dir:
		Vector2.UP:
			for y in range(1, height):
				for x in range(width):
					if board[x][y] != null:
						move_piece(Vector2(x, y), dir, move_data)
		Vector2.DOWN:
			for y in range(height-2, -1, -1):
				for x in range(width):
					if board[x][y] != null:
						move_piece(Vector2(x, y), dir, move_data)
		Vector2.LEFT:
			for x in range(1, width):
				for y in range(height):
					if board[x][y] != null:
						move_piece(Vector2(x, y), dir, move_data)
		Vector2.RIGHT:
			for x in range(width-2, -1, -1):
				for y in range(height):
					if board[x][y] != null:
						move_piece(Vector2(x, y), dir, move_data)
		_:
			return

	# FIX: Only generate a new piece and check for game over IF a move or merge occurred.
	if move_data.moved:
		generate_new_piece(1)
		check_game_over()

# Function signature updated to include 'move_data'
func move_piece(pos: Vector2, direction: Vector2, move_data: Dictionary):
	var piece = board[pos.x][pos.y]
	if piece == null:
		return

	var value = piece.value
	var next_pos = pos + direction
	var last_valid = pos

	# 1. Find the furthest empty spot (last_valid)
	while is_in_grid(next_pos) and board[next_pos.x][next_pos.y] == null:
		last_valid = next_pos
		next_pos += direction

	# 2. Check for a Merge
	if is_in_grid(next_pos) and board[next_pos.x][next_pos.y] != null:
		var target_piece = board[next_pos.x][next_pos.y]
		if target_piece.value == value and not target_piece.just_merged and not piece.just_merged:
			var new_piece_scene = piece.next_value
			remove_and_clear(pos)
			remove_and_clear(next_pos)
			var new_piece = new_piece_scene.instantiate()
			add_child(new_piece)
			board[next_pos.x][next_pos.y] = new_piece
			
			# Set position and scale immediately after merging
			new_piece.position = grid_to_pixel(next_pos)
			new_piece.scale = Vector2.ONE * (get_grid_offset() / 128.0)
			
			new_piece.just_merged = true
			new_piece.merge_animation()
			add_score(new_piece.value)
			merge_sound.play()
			
			# Mark that a merge occurred
			move_data.moved = true
			return

	# 3. Check for a Simple Move
	if last_valid != pos:
		move_and_set_board_value(pos, last_valid)
		# Mark that a move occurred
		move_data.moved = true

func move_and_set_board_value(from_pos: Vector2, to_pos: Vector2):
	var piece = board[from_pos.x][from_pos.y]
	board[from_pos.x][from_pos.y] = null
	board[to_pos.x][to_pos.y] = piece
	piece.move(grid_to_pixel(to_pos))

func appear():
	scale = Vector2(0,0)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1,1), 0.4)

func remove_and_clear(pos: Vector2):
	if board[pos.x][pos.y] != null:
		board[pos.x][pos.y].remove()
	board[pos.x][pos.y] = null

# --- PIECE GENERATION ---
func generate_new_piece(number_of_pieces: int):
	if not is_blank_space():
		print("No more space for new pieces.")
		return

	var pieces_made = 0
	while pieces_made < number_of_pieces:
		var x = randi() % width
		var y = randi() % height
		if board[x][y] == null:
			var temp = is_two_or_four().instantiate()
			add_child(temp)
			board[x][y] = temp
			temp.position = grid_to_pixel(Vector2(x, y))
			temp.appear()
			# Scale on generation
			temp.scale = Vector2.ONE * (get_grid_offset() / 128.0)
			pieces_made += 1

func is_two_or_four() -> PackedScene:
	return two_piece if randf() < (1.0 - float(four_piece_chance)/100.0) else four_piece

# --- BACKGROUND ---
func generate_background():
	var scale_factor = get_grid_offset() / 128.0
	for i in range(width):
		for j in range(height):
			if background_piece:
				var temp = background_piece.instantiate()
				add_child(temp)
				temp.position = grid_to_pixel(Vector2(i, j))
				# Scale on generation
				temp.scale = Vector2(scale_factor, scale_factor)
				temp.name = "Background_%d_%d" % [i, j]

# --- CONTROLS ---
func _on_touch_control_move(direction: Vector2):
	move_all_pieces(direction)

func _on_keyboard_control_move(direction: Vector2):
	move_all_pieces(direction)


func _on_button_pressed():
	reset_game()
	Sfx.play()
	MainTheme.play()

func _on_menu_pressed():
	save_best_score()
	get_tree().change_scene_to_file("res://Main Menu/main_menu.tscn")
	Sfx.play()
