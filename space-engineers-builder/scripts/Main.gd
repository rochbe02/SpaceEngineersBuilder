extends Node

@onready var blueprint_export = $BlueprintExport
@onready var viewport_3d = $Viewport3D
@onready var materials_panel = $CanvasLayer/MaterialsPanel
@onready var load_dialog = $LoadDialog

func _on_materials_panel_exportar_plano():
	var grid_map = viewport_3d.get_node("GridMap")
	var placed_blocks = viewport_3d.placed_blocks
	var block_preview = viewport_3d.get_node("BlockPreview")
	
	# Ocultar preview y moverlo lejos
	block_preview.visible = false
	var original_pos = block_preview.position
	block_preview.position = Vector3(9999, 9999, 9999)
	
	# Esperar varios frames
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	blueprint_export.setup_cameras(placed_blocks, grid_map)
	await blueprint_export.export_blueprint("user://plano_nave.png")
	
	# Restaurar preview
	block_preview.position = original_pos
	block_preview.visible = true
	print("Plano guardado en: ", OS.get_user_data_dir())

func _on_materials_panel_guardar_nave(ship_name: String):
	var placed_blocks = viewport_3d.placed_blocks
	var ship_size = "Large"  # por ahora default
	SaveSystem.save_ship(ship_name, placed_blocks, ship_size)

func _on_materials_panel_cargar_nave():
	load_dialog.popup_centered(Vector2(600, 400))
	if not load_dialog.file_selected.is_connected(_on_file_selected):
		load_dialog.file_selected.connect(_on_file_selected)

func _on_file_selected(path: String):
	_load_ship(path)

func _load_ship(path: String):
	var data = SaveSystem.load_ship(path)
	if data.is_empty():
		return
	
	var grid_map = viewport_3d.get_node("GridMap")
	grid_map.clear()
	viewport_3d.placed_blocks.clear()
	
	for key in data["blocks"]:
		var parts = key.split(",")
		var cell = Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
		var block = data["blocks"][key]
		var rotation = Vector3i(
			block["rotation"]["x"],
			block["rotation"]["y"],
			block["rotation"]["z"]
		)
		var item = grid_map.mesh_library.find_item_by_name("MeshInstance3D")
		grid_map.set_cell_item(cell, item)
		viewport_3d.placed_blocks[cell] = {
			"id": block["id"],
			"rotation": rotation,
			"origin": cell
		}
	
	materials_panel.update_stats(viewport_3d.placed_blocks)
	print("Nave cargada: ", data.get("name", ""))
