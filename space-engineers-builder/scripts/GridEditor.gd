extends Node3D

@onready var grid_map: GridMap = $GridMap
@onready var camera: Camera3D = $Camera3D
@onready var block_preview: MeshInstance3D = $BlockPreview

var selected_block_id: String = "MeshInstance3D"
var placed_blocks: Dictionary = {}
var is_placing: bool = true

# Material preview colocar
var mat_place: StandardMaterial3D
# Material preview borrar
var mat_erase: StandardMaterial3D

signal block_placed(placed_blocks: Dictionary)
signal block_removed(placed_blocks: Dictionary)

func _ready():
	print("GridEditor listo")
	var box = BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	block_preview.mesh = box
	
	mat_place = StandardMaterial3D.new()
	mat_place.albedo_color = Color(0.2, 0.6, 1.0, 0.4)
	mat_place.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	mat_erase = StandardMaterial3D.new()
	mat_erase.albedo_color = Color(1.0, 0.2, 0.2, 0.4)
	mat_erase.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	block_preview.material_override = mat_place
	block_preview.visible = false

func _unhandled_input(event):
	# Toggle modo borrar con X
	if event is InputEventKey:
		if event.keycode == KEY_X and event.pressed and not event.echo:
			is_placing = !is_placing
			if is_placing:
				block_preview.material_override = mat_place
				print("Modo: Colocar")
			else:
				block_preview.material_override = mat_erase
				print("Modo: Borrar")
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	
	if is_placing:
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell != null:
			# No mostrar preview si ya hay un bloque en esa celda
			if placed_blocks.has(cell):
				block_preview.visible = false
				return
			block_preview.visible = true
			var target_pos = grid_map.map_to_local(cell)
			block_preview.position = block_preview.position.lerp(target_pos, 20.0 * delta)
		else:
			block_preview.visible = false
	else:
		var cell = _get_cell_under_mouse(mouse_pos)
		if cell != null and placed_blocks.has(cell):
			# Preview fijo sin lerp en modo borrar para evitar parpadeo
			block_preview.visible = true
			block_preview.position = grid_map.map_to_local(cell)
		else:
			block_preview.visible = false

func _get_cell_at_mouse(mouse_pos: Vector2):
	var from = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + direction * 100.0)
	query.collision_mask = 1
	query.collide_with_bodies = true
	var result = space.intersect_ray(query)
	
	if result and result.size() > 0:
		var offset = grid_map.cell_size.x * 0.5
		var hit_pos = result.position + result.normal * offset
		return grid_map.local_to_map(hit_pos)
	else:
		if direction.y == 0:
			return null
		var t = -from.y / direction.y
		if t < 0:
			return null
		var hit_pos = from + direction * t
		return grid_map.local_to_map(hit_pos)

func _get_cell_under_mouse(mouse_pos: Vector2):
	var from = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + direction * 100.0)
	query.collision_mask = 1
	query.collide_with_bodies = true
	var result = space.intersect_ray(query)
	
	if result and result.size() > 0:
		# Sin offset — apunta al centro del bloque detectado
		var hit_pos = result.position - result.normal * 0.1
		return grid_map.local_to_map(hit_pos)
	return null
	
func _handle_click(mouse_pos: Vector2):
	if is_placing:
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell != null:
			_place_block(cell)
	else:
		var cell = _get_cell_under_mouse(mouse_pos)
		if cell != null:
			_remove_block(cell)

func _place_block(cell: Vector3i):
	var item = grid_map.mesh_library.find_item_by_name("MeshInstance3D")
	grid_map.set_cell_item(cell, item)
	placed_blocks[cell] = selected_block_id
	emit_signal("block_placed", placed_blocks)
	print("Bloque colocado en: ", cell, " ID: ", selected_block_id)

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

func _on_block_catalog_block_selected(block_id: String):
	selected_block_id = block_id
	print("Bloque activo: ", block_id)

func _on_block_catalog_size_changed(size: String):
	grid_map.clear()
	placed_blocks.clear()
	emit_signal("block_placed", placed_blocks)
	print("Tamaño cambiado a: ", size)
