extends Node3D

@onready var grid_map: GridMap = $GridMap
@onready var camera: Camera3D = $Camera3D
@onready var block_preview: MeshInstance3D = $BlockPreview

var tool_second_cell = null
var tool_start_cell = null  # primer clic de la herramienta
var selected_block_id: String = "MeshInstance3D"
var placed_blocks: Dictionary = {}
var is_placing: bool = true
var current_rotation: Vector3i = Vector3i(0, 0, 0)

var mat_place: StandardMaterial3D
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
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_X:
				is_placing = !is_placing
				if is_placing:
					block_preview.material_override = mat_place
					print("Modo: Colocar")
				else:
					block_preview.material_override = mat_erase
					print("Modo: Borrar")
			KEY_Q:
				current_rotation.y = (current_rotation.y + 90) % 360
				_update_preview_rotation()
			KEY_E:
				current_rotation.y = (current_rotation.y - 90 + 360) % 360
				_update_preview_rotation()
			KEY_HOME:
				current_rotation.x = (current_rotation.x + 90) % 360
				_update_preview_rotation()
			KEY_END:
				current_rotation.x = (current_rotation.x - 90 + 360) % 360
				_update_preview_rotation()
			KEY_PAGEUP:
				current_rotation.z = (current_rotation.z + 90) % 360
				_update_preview_rotation()
			KEY_PAGEDOWN:
				current_rotation.z = (current_rotation.z - 90 + 360) % 360
				_update_preview_rotation()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)

func _update_preview_rotation():
	block_preview.rotation_degrees = Vector3(
		current_rotation.x,
		current_rotation.y,
		current_rotation.z
	)
	print("Rotación: ", current_rotation)

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	
	if current_tool == "pincel":
		if is_placing:
			var cell = _get_cell_at_mouse(mouse_pos)
			if cell != null:
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
				block_preview.visible = true
				block_preview.position = grid_map.map_to_local(cell)
			else:
				block_preview.visible = false
	elif current_tool == "linea":
		_update_line_preview(mouse_pos)
	elif current_tool == "plano":
		_update_plano_preview(mouse_pos)
	elif current_tool == "cubo":
		_update_cubo_preview(mouse_pos)

func _update_cubo_preview(mouse_pos: Vector2):
	if tool_start_cell == null:
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell != null:
			block_preview.visible = true
			block_preview.position = grid_map.map_to_local(cell)
		else:
			block_preview.visible = false
	elif tool_second_cell == null:
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell != null:
			var cells = _get_plano_cells(tool_start_cell, cell)
			_show_multi_preview(cells)
	else:
		var height = _get_height_from_mouse(mouse_pos)
		var cells = _get_cubo_cells_3click(tool_start_cell, tool_second_cell, height)
		_show_multi_preview(cells)

func _update_plano_preview(mouse_pos: Vector2):
	if tool_start_cell == null:
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell != null:
			block_preview.visible = true
			block_preview.position = grid_map.map_to_local(cell)
		else:
			block_preview.visible = false
	else:
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell != null:
			var cells = _get_plano_cells(tool_start_cell, cell)
			_show_multi_preview(cells)


func _update_line_preview(mouse_pos: Vector2):
	if tool_start_cell == null:
		# Mostrar preview simple del primer punto
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell != null:
			block_preview.visible = true
			block_preview.position = grid_map.map_to_local(cell)
		else:
			block_preview.visible = false
	else:
		# Mostrar preview de toda la línea
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell != null:
			_show_line_preview(tool_start_cell, cell)

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
		var hit_pos = result.position - result.normal * 0.1
		return grid_map.local_to_map(hit_pos)
	return null

func _handle_click(mouse_pos: Vector2):
	if current_tool == "pincel":
		if is_placing:
			var cell = _get_cell_at_mouse(mouse_pos)
			if cell != null:
				_place_block(cell)
		else:
			var cell = _get_cell_under_mouse(mouse_pos)
			if cell != null:
				_remove_block(cell)
	elif current_tool == "linea":
		_handle_line_tool(mouse_pos)
	elif current_tool == "plano":
		_handle_plano_tool(mouse_pos)
	elif current_tool == "cubo":
		_handle_cubo_tool(mouse_pos)


func _handle_cubo_tool(mouse_pos: Vector2):
	if tool_start_cell == null:
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell == null:
			return
		tool_start_cell = cell
		print("Cubo: punto inicial ", cell)
	elif tool_second_cell == null:
		var cell = _get_cell_at_mouse(mouse_pos)
		if cell == null:
			return
		tool_second_cell = cell
		print("Cubo: área definida ", cell)
	else:
		var height = _get_height_from_mouse(mouse_pos)
		var cubo_cells = _get_cubo_cells_3click(tool_start_cell, tool_second_cell, height)
		if is_placing:
			_place_blocks_batch(cubo_cells)
		else:
			_remove_blocks_batch(cubo_cells)
		tool_start_cell = null
		tool_second_cell = null
		_hide_line_preview()
		print("Cubo completado: ", cubo_cells.size(), " bloques")
		

func _place_blocks_batch(cells: Array):
	var item = grid_map.mesh_library.find_item_by_name("MeshInstance3D")
	var basis = _rotation_to_basis()
	var block_data = BlockDatabase.get_block(selected_block_id)
	var block_size = block_data.get("block_size", {"x": 1, "y": 1, "z": 1})
	
	for cell in cells:
		var occupied_cells = _get_occupied_cells(cell, block_size, current_rotation)
		var can_place = true
		for c in occupied_cells:
			if placed_blocks.has(c):
				can_place = false
				break
		if not can_place:
			continue
		
		grid_map.set_cell_item(cell, item, basis)
		for c in occupied_cells:
			placed_blocks[c] = {
				"id": selected_block_id,
				"rotation": current_rotation,
				"origin": cell
			}
	
	emit_signal("block_placed", placed_blocks)

func _get_height_from_mouse(mouse_pos: Vector2) -> int:
	# Usamos la distancia vertical del mouse desde el punto de partida
	# para determinar cuántos niveles sube/baja
	var from = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	
	var base_pos = grid_map.map_to_local(tool_second_cell)
	
	# Proyectar el rayo sobre un plano vertical que pasa por el punto base
	var plane_normal = Vector3(direction.x, 0, direction.z).normalized()
	if plane_normal.length() < 0.01:
		plane_normal = Vector3(1, 0, 0)
	
	var plane = Plane(plane_normal, base_pos)
	var hit = plane.intersects_ray(from, direction)
	
	if hit:
		var height = hit.y - base_pos.y
		return int(round(height))
	return 0

func _get_cubo_cells_3click(start: Vector3i, area_end: Vector3i, height: int) -> Array:
	var cells = []
	var min_x = min(start.x, area_end.x)
	var max_x = max(start.x, area_end.x)
	var min_z = min(start.z, area_end.z)
	var max_z = max(start.z, area_end.z)
	var base_y = start.y
	
	var min_y = min(base_y, base_y + height)
	var max_y = max(base_y, base_y + height)
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			for z in range(min_z, max_z + 1):
				if is_hollow:
					var is_edge = x == min_x or x == max_x or y == min_y or y == max_y or z == min_z or z == max_z
					if is_edge:
						cells.append(Vector3i(x, y, z))
				else:
					cells.append(Vector3i(x, y, z))
	
	return cells

func _handle_plano_tool(mouse_pos: Vector2):
	var cell = _get_cell_at_mouse(mouse_pos)
	if cell == null:
		return
	
	if tool_start_cell == null:
		tool_start_cell = cell
		print("Plano: esquina inicial ", cell)
	else:
		var plano_cells = _get_plano_cells(tool_start_cell, cell)
		if is_placing:
			_place_blocks_batch(plano_cells)
		else:
			_remove_blocks_batch(plano_cells)
		tool_start_cell = null
		_hide_line_preview()
		print("Plano completado: ", plano_cells.size(), " bloques")

func _remove_blocks_batch(cells: Array):
	for cell in cells:
		if not placed_blocks.has(cell):
			continue
		var origin = placed_blocks[cell].get("origin", cell)
		var block_id = placed_blocks[cell].get("id", "")
		var rotation = placed_blocks[cell].get("rotation", Vector3i(0, 0, 0))
		var block_data = BlockDatabase.get_block(block_id)
		var block_size = block_data.get("block_size", {"x": 1, "y": 1, "z": 1})
		var occupied = _get_occupied_cells(origin, block_size, rotation)
		for c in occupied:
			placed_blocks.erase(c)
			grid_map.set_cell_item(c, GridMap.INVALID_CELL_ITEM)
	
	emit_signal("block_removed", placed_blocks)

func _get_plano_cells(start: Vector3i, end: Vector3i) -> Array:
	var cells = []
	var min_x = min(start.x, end.x)
	var max_x = max(start.x, end.x)
	var min_z = min(start.z, end.z)
	var max_z = max(start.z, end.z)
	var y = start.y
	
	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			if is_hollow:
				# Solo el borde
				if x == min_x or x == max_x or z == min_z or z == max_z:
					cells.append(Vector3i(x, y, z))
			else:
				cells.append(Vector3i(x, y, z))
	
	return cells

func _handle_line_tool(mouse_pos: Vector2):
	var cell = _get_cell_at_mouse(mouse_pos)
	if cell == null:
		return
	
	if tool_start_cell == null:
		tool_start_cell = cell
		print("Línea: punto inicial ", cell)
	else:
		var line_cells = _get_line_cells(tool_start_cell, cell)
		if is_placing:
			_place_blocks_batch(line_cells)
		else:
			_remove_blocks_batch(line_cells)
		tool_start_cell = null
		_hide_line_preview()
		print("Línea completada: ", line_cells.size(), " bloques")

func _get_line_cells(start: Vector3i, end: Vector3i) -> Array:
	var cells = []
	var dx = end.x - start.x
	var dy = end.y - start.y
	var dz = end.z - start.z
	
	var steps = max(abs(dx), max(abs(dy), abs(dz)))
	if steps == 0:
		cells.append(start)
		return cells
	
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var x = round(start.x + dx * t)
		var y = round(start.y + dy * t)
		var z = round(start.z + dz * t)
		cells.append(Vector3i(x, y, z))
	
	return cells

func _place_block(cell: Vector3i):
	var item = grid_map.mesh_library.find_item_by_name("MeshInstance3D")
	var basis = _rotation_to_basis()
	var block_data = BlockDatabase.get_block(selected_block_id)
	var block_size = block_data.get("block_size", {"x": 1, "y": 1, "z": 1})
	
	# Calcular todas las celdas que ocupa el bloque según rotación
	var cells = _get_occupied_cells(cell, block_size, current_rotation)
	
	# Verificar que ninguna celda esté ocupada
	for c in cells:
		if placed_blocks.has(c):
			print("Celda ocupada: ", c)
			return
	
	# Colocar el bloque visual solo en la celda principal
	grid_map.set_cell_item(cell, item, basis)
	
	# Registrar todas las celdas como ocupadas
	for c in cells:
		placed_blocks[c] = {
			"id": selected_block_id,
			"rotation": current_rotation,
			"origin": cell  # celda principal del bloque
		}
	
	emit_signal("block_placed", placed_blocks)
	print("Bloque colocado en: ", cell, " celdas: ", cells.size())

func _remove_block(cell: Vector3i):
	if not placed_blocks.has(cell):
		return
	
	# Encontrar la celda origen del bloque
	var origin = placed_blocks[cell].get("origin", cell)
	var block_id = placed_blocks[cell].get("id", "")
	var rotation = placed_blocks[cell].get("rotation", Vector3i(0, 0, 0))
	var block_data = BlockDatabase.get_block(block_id)
	var block_size = block_data.get("block_size", {"x": 1, "y": 1, "z": 1})
	
	# Borrar todas las celdas que ocupa
	var cells = _get_occupied_cells(origin, block_size, rotation)
	for c in cells:
		placed_blocks.erase(c)
		grid_map.set_cell_item(c, GridMap.INVALID_CELL_ITEM)
	
	emit_signal("block_removed", placed_blocks)
	print("Bloque eliminado en: ", origin)

func _get_occupied_cells(origin: Vector3i, block_size: Dictionary, rotation: Vector3i) -> Array:
	var cells = []
	var sx = block_size.get("x", 1)
	var sy = block_size.get("y", 1)
	var sz = block_size.get("z", 1)
	
	# Intercambiar dimensiones según rotación en Y
	if rotation.y == 90 or rotation.y == 270:
		var temp = sx
		sx = sz
		sz = temp
	
	for x in range(sx):
		for y in range(sy):
			for z in range(sz):
				cells.append(origin + Vector3i(x, y, z))
	
	return cells

func _rotation_to_basis() -> int:
	match current_rotation.y:
		90: return 22
		180: return 10
		270: return 14
	return 0

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

var current_tool: String = "pincel"
var is_hollow: bool = false

func set_tool(tool_name: String):
	current_tool = tool_name
	print("Herramienta activa: ", tool_name)

func set_hollow(hollow: bool):
	is_hollow = hollow
	print("Hueco actualizado a: ", hollow)
	
var line_preview_meshes: Array = []

func _show_multi_preview(cells: Array):
	while line_preview_meshes.size() < cells.size():
		var mesh_instance = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1, 1, 1)
		mesh_instance.mesh = box
		mesh_instance.material_override = mat_place
		add_child(mesh_instance)
		line_preview_meshes.append(mesh_instance)
	
	for i in range(line_preview_meshes.size()):
		if i < cells.size():
			line_preview_meshes[i].visible = true
			line_preview_meshes[i].position = grid_map.map_to_local(cells[i])
		else:
			line_preview_meshes[i].visible = false
	
	block_preview.visible = false

func _show_line_preview(start: Vector3i, end: Vector3i):
	var cells = _get_line_cells(start, end)
	_show_multi_preview(cells)

func _hide_line_preview():
	for mesh in line_preview_meshes:
		mesh.visible = false
