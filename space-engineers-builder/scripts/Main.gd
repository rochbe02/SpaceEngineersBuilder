extends Node

@onready var blueprint_export = $BlueprintExport
@onready var viewport_3d = $Viewport3D

func _on_materials_panel_exportar_plano():
	var grid_map = viewport_3d.get_node("GridMap")
	var placed_blocks = viewport_3d.placed_blocks
	var block_preview = viewport_3d.get_node("BlockPreview")
	
	# Mover el preview fuera de la escena
	var original_pos = block_preview.position
	block_preview.position = Vector3(9999, 9999, 9999)
	block_preview.visible = false
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	blueprint_export.setup_cameras(placed_blocks, grid_map)
	await blueprint_export.export_blueprint("user://plano_nave.png")
	
	# Restaurar preview
	block_preview.position = original_pos
	block_preview.visible = true
	print("Plano guardado en: ", OS.get_user_data_dir())
