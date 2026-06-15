extends Node3D

@onready var grid_map: GridMap = $GridMap
@onready var camera: Camera3D = $Camera3D

var selected_block_id: String = "MeshInstance3D"
var placed_blocks: Dictionary = {}
var is_placing: bool = true

signal block_placed(placed_blocks: Dictionary)
signal block_removed(placed_blocks: Dictionary)

func _ready():
	print("GridEditor listo")
	var item = grid_map.mesh_library.find_item_by_name("MeshInstance3D")
	print("Item ID: ", item)
	grid_map.set_cell_item(Vector3i(0, 0, 0), item)
	print("Bloque colocado en origen")

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)

func _handle_click(mouse_pos: Vector2):
	var from = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	
	if direction.y == 0:
		return
	var t = -from.y / direction.y
	if t < 0:
		return
	var hit_pos = from + direction * t
	
	var cell = grid_map.local_to_map(hit_pos)
	print("Clic en celda: ", cell)
	
	if is_placing:
		_place_block(cell)
	else:
		_remove_block(cell)

func _place_block(cell: Vector3i):
	var item = grid_map.mesh_library.find_item_by_name("MeshInstance3D")
	grid_map.set_cell_item(cell, item)
	placed_blocks[cell] = selected_block_id
	emit_signal("block_placed", placed_blocks)
	print("Bloque colocado en: ", cell)

func _remove_block(cell: Vector3i):
	if placed_blocks.has(cell):
		placed_blocks.erase(cell)
		grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
		emit_signal("block_removed", placed_blocks)
		print("Bloque eliminado en: ", cell)

func set_selected_block(block_id: String):
	selected_block_id = block_id

func set_mode(placing: bool):
	is_placing = placing
