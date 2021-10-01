extends GridContainer

var cell_obj_matrix := []
# export (PackedScene) var Cell
var Cell = preload("res://Cell.tscn")

func create_cells(row, col):
	self.columns = col  # for grid container
	for i in range(len(cell_obj_matrix)):
		while not cell_obj_matrix[i].empty():
			var cell = cell_obj_matrix[i].pop_back()
			remove_child(cell)
			cell.queue_free()
	
	cell_obj_matrix.clear()
	
	for i in range(row):
		cell_obj_matrix.append([])
		for j in range(col):
			var cell = Cell.instance()
			add_child(cell)
			cell_obj_matrix[-1].append(cell)

func change_cells(row, col, idx: int):
	if idx == 0:
		cell_obj_matrix[row][col].color = Color(0,0,0)
	else:
		cell_obj_matrix[row][col].color = Color(1,1,1)
