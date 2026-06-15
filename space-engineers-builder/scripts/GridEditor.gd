extends Node3D

# Referencias a nodos
@onready var grid_map: GridMap = $GridMap
@onready var camera: Camera3D = $Camera3D

# Estado del editor
var selected_block_id: String = ""
var placed_blocks: Dictionary = {}
var is_placing: bool = true  # true = colocar, false = borrar

# Señales para comunicarse con la UI
signal block_placed(placed_blocks: Dictionary)
signal block_removed(placed_blocks: Dictionary)

func _ready():
	print("GridEditor listo")

func _input(event):
	# Clic izquierdo — colocar o borrar bloque
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)

func _handle_click(mouse_pos: Vector2):
	# Rayo desde la cámara hacia donde hizo clic el mouse
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100.0

	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(query)

	if result:
		var cell = grid_map.local_to_map(result.position)
		if is_placing and selected_block_id != "":
			_place_block(cell)
		elif not is_placing:
			_remove_block(cell)

func _place_block(cell: Vector3i):
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
