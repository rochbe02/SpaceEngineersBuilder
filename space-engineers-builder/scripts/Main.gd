extends Node

@onready var blueprint_export = $BlueprintExport
@onready var viewport_3d = $Viewport3D
@onready var materials_panel = $CanvasLayer/MaterialsPanel
@onready var load_dialog = $LoadDialog

func _on_materials_panel_exportar_plano():
	_exportar_plano()

func _on_toolbar_exportar_presionado():
	_exportar_plano()

func _exportar_plano():
	var grid_map = viewport_3d.get_node("GridMap")
	var placed_blocks = viewport_3d.placed_blocks
	var block_preview = viewport_3d.get_node("BlockPreview")
	var ship_name = materials_panel.get_ship_name()
	var author = materials_panel.get_author_name()
	
	block_preview.visible = false
	var original_pos = block_preview.position
	block_preview.position = Vector3(9999, 9999, 9999)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	blueprint_export.setup_cameras(placed_blocks, grid_map)
	blueprint_export.set_metadata(ship_name, author, placed_blocks)
	await blueprint_export.export_blueprint("user://plano_nave.png")
	
	block_preview.position = original_pos
	block_preview.visible = true
	print("Plano guardado")

func _on_materials_panel_guardar_nave(ship_name: String):
	var placed_blocks = viewport_3d.placed_blocks
	var ship_size = "Large"
	SaveSystem.save_ship(ship_name, placed_blocks, ship_size)

func _on_toolbar_guardar_presionado():
	var ship_name = materials_panel.get_ship_name()
	if ship_name == "":
		print("Escribe un nombre para la nave")
		return
	var placed_blocks = viewport_3d.placed_blocks
	SaveSystem.save_ship(ship_name, placed_blocks, "Large")

func _on_materials_panel_cargar_nave():
	_abrir_dialogo_carga()

func _on_toolbar_cargar_presionado():
	_abrir_dialogo_carga()

func _abrir_dialogo_carga():
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

func _on_toolbar_nuevo_presionado():
	var grid_map = viewport_3d.get_node("GridMap")
	grid_map.clear()
	viewport_3d.placed_blocks.clear()
	materials_panel.update_stats({})
	print("Nuevo proyecto")

func _on_toolbar_herramienta_cambiada(herramienta: String):
	viewport_3d.set_tool(herramienta)

func _on_toolbar_hueco_cambiado(hueco: bool):
	viewport_3d.set_hollow(hueco)
