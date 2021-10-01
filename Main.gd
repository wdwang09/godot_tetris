extends Node2D

export var row_num := 20
export var col_num := 10

var cell_matrix = []
const blocks = [
	[[0,0,1,0],
	 [0,0,1,0],
	 [0,0,1,0],
	 [0,0,1,0]],
	
	[[0,0,0,0],
	 [1,1,1,0],
	 [0,1,0,0],
	 [0,0,0,0]],
	
	[[0,0,0,0],
	 [0,1,1,0],
	 [0,1,1,0],
	 [0,0,0,0]],
	
	[[0,0,0,0],
	 [0,1,1,0],
	 [0,1,0,0],
	 [0,1,0,0]],
	
	[[0,0,0,0],
	 [0,1,1,0],
	 [0,0,1,0],
	 [0,0,1,0]],
	
	[[0,0,0,0],
	 [1,1,0,0],
	 [0,1,1,0],
	 [0,0,0,0]],
	
	[[0,0,0,0],
	 [0,1,1,0],
	 [1,1,0,0],
	 [0,0,0,0]],
]

var is_game_over := false

var now_position = [-3,7]
var last_position = [0,0]
var now_block = []
var next_block = []

var score := 0

onready var board_container = $HBoxContainer/CenterContainer/Board
onready var next_block_container = $HBoxContainer/VBoxContainer/CenterContainer/NextBlock

enum Action {DOWN, LEFT, RIGHT, ROTATE}

#func deepcopy2(matrix):
#	assert(typeof(matrix) == TYPE_ARRAY)
#	var res = []
#	for i in range(len(matrix)):
#		res.append([])
#		for j in range(len(matrix[i])):
#			res[-1].append(matrix[i][j])
#	return res

func rotation(block):
	assert(typeof(block) == TYPE_ARRAY)
	var res = []
	for i in range(len(block)):
		res.append([])
		for j in range(len(block[i])):
			res[-1].append(0)
	for i in range(4):
		for j in range(4):
			res[i][j] = block[3-j][i]
	return res

func _ready():
	randomize()
	new_game(row_num, col_num)
	new_next_block()
	new_turn()
	$DropTimer.start()

func new_game(row, col):
	assert(typeof(row) == TYPE_INT and typeof(col) == TYPE_INT)
	
	row_num = row
	col_num = col
	score = 0
	
	is_game_over = false
	
	cell_matrix.clear()
	for i in range(row + 3):
		cell_matrix.append([])
		for j in range(col):
			cell_matrix[-1].append(0)
	
	board_container.create_cells(row, col)
	next_block_container.create_cells(6, 6)

func new_next_block():
	var next_block_num = randi() % len(blocks)
	var next_block_rotation = randi() % 4
	next_block = blocks[next_block_num]
	for i in range(next_block_rotation):
		next_block = rotation(next_block)

func new_turn():
	now_position = [-3, col_num / 2 - 2]
	last_position = [0,0]
	#now_block = blocks[next_block_num]
	#for i in range(next_block_rotation):
	#	now_block = rotation(now_block)
	now_block = next_block
	new_next_block()
	
	for i in range(4):
		for j in range(4):
			next_block_container.change_cells(i+1, j+1, next_block[i][j])
	draw()

func draw():
	for i in range(4):
		for j in range(4):
			if not isWall(last_position[0] + i, last_position[1] + j):
				setCell(last_position[0] + i, last_position[1] + j, 0)
			#if now_block[i][j] > 0:
			#	setCell(last_position[0] + i, last_position[1] + j, 0)
	for i in range(4):
		for j in range(4):
			if now_block[i][j] > 0:
				setCell(now_position[0] + i, now_position[1] + j, -now_block[i][j])  # negative
	last_position[0] = now_position[0]
	last_position[1] = now_position[1]

func draw_board():
	for i in range(row_num):
		for j in range(col_num):
			setCell(i, j, cell_matrix[i][j])

func setCell(r, c, num):
	if r < -3 or c < 0:
		return
	if r >= row_num or c >= col_num:
		return
	cell_matrix[r][c] = num
	if r >= 0:
		board_container.change_cells(r, c, num)

func isWall(r, c):
	if r < -3 or c < 0 or r >= row_num or c >= col_num:
		return true
	return cell_matrix[r][c] > 0

var one_tick = false
func _on_DropTimer_timeout():
	var is_bottom = not try_to_move(Action.DOWN)
	if is_bottom:
		if one_tick:
			bottom_action()
			one_tick = false
		else:
			one_tick = true

func bottom_action():
	for i in range(row_num):
		for j in range(col_num):
			if cell_matrix[i][j] < 0:
				if i == 0:
					print("Game Over")
					is_game_over = true
					$DropTimer.stop()
					return
				cell_matrix[i][j] = -cell_matrix[i][j]
	var clear_line_num = 0
	
	# clear line
	for i in range(row_num):
		var line_flag = true
		for j in range(col_num):
			if not isWall(i, j):
				line_flag = false
				break
		if not line_flag:
			continue
		clear_line_num += 1
		cell_matrix.remove(i)
		cell_matrix.insert(0, [])
		for j in range(col_num):
			cell_matrix[0].append(0)
		draw_board()
	if clear_line_num > 0:
		for i in range(clear_line_num):
			score += (i + 1)
		$HBoxContainer/VBoxContainer/Score.text = str(score)
	new_turn()

func _input(event):
	if is_game_over:
		return
	if event.is_action_pressed("ui_left"):
		try_to_move(Action.LEFT)
	elif event.is_action_pressed("ui_right"):
		try_to_move(Action.RIGHT)
	elif event.is_action_pressed("ui_up"):
		try_to_move(Action.ROTATE)
	elif event.is_action("ui_down"):  # without pressed to make it quickly
		try_to_move(Action.DOWN)
		try_to_move(Action.DOWN)

func try_to_move(action):
	var after_rotation = null
	if action == Action.ROTATE:
		after_rotation = rotation(now_block)
	for i in range(4):
		for j in range(4):
			if now_block[i][j] > 0:
				if action == Action.DOWN:
					if isWall(now_position[0] + i + 1, now_position[1] + j):
						return false
				elif action == Action.LEFT:
					if isWall(now_position[0] + i, now_position[1] + j - 1):
						return false
				elif action == Action.RIGHT:
					if isWall(now_position[0] + i, now_position[1] + j + 1):
						return false
			if action == Action.ROTATE and after_rotation[i][j] > 0:
				if isWall(now_position[0] + i, now_position[1] + j):
					return false
	if action == Action.DOWN:
		now_position[0] += 1
	elif action == Action.LEFT:
		now_position[1] -= 1
	elif action == Action.RIGHT:
		now_position[1] += 1
	elif action == Action.ROTATE:
		last_position[0] = now_position[0]
		last_position[1] = now_position[1]
		now_block = after_rotation
	draw()
	return true

func _on_HSlider_value_changed(value):
	# value 1~10
	# value 6 0.2
	# value 1 0.05
	$DropTimer.wait_time = 0.02 + 0.03 * value
