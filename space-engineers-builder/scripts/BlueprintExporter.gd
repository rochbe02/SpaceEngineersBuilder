extends Node

@onready var cam_top = $"SubViewportContainer(Top)/SubViewport/Camera3D"
@onready var cam_front = $"SubViewportContainer(Front)/SubViewport/Camera3D"
@onready var cam_side = $"SubViewportContainer(Side)/SubViewport/Camera3D"
@onready var cam_iso = $"SubViewportContainer(Iso)/SubViewport/Camera3D"

@onready var vp_top = $"SubViewportContainer(Top)/SubViewport"
@onready var vp_front = $"SubViewportContainer(Front)/SubViewport"
@onready var vp_side = $"SubViewportContainer(Side)/SubViewport"
@onready var vp_iso = $"SubViewportContainer(Iso)/SubViewport"

func setup_cameras(placed_blocks: Dictionary, grid_map: GridMap):
	if placed_blocks.is_empty():
		return
	
	# Compartir el mundo 3D del viewport principal
	var main_world = grid_map.get_world_3d()
	vp_top.world_3d = main_world
	vp_front.world_3d = main_world
	vp_side.world_3d = main_world
	vp_iso.world_3d = main_world
	
	# Calcular bounding box
	var min_cell = Vector3i(999, 999, 999)
	var max_cell = Vector3i(-999, -999, -999)
	
	for cell in placed_blocks:
		min_cell.x = min(min_cell.x, cell.x)
		min_cell.y = min(min_cell.y, cell.y)
		min_cell.z = min(min_cell.z, cell.z)
		max_cell.x = max(max_cell.x, cell.x)
		max_cell.y = max(max_cell.y, cell.y)
		max_cell.z = max(max_cell.z, cell.z)
	
	var center = grid_map.map_to_local((min_cell + max_cell) / 2)
	var size = max_cell - min_cell
	var max_size = max(max(size.x, size.y), size.z) + 5.0
	var distance = max_size * 2.0
	
	cam_top.position = center + Vector3(0, distance, 0)
	cam_top.look_at(center, Vector3(0, 0, -1))
	cam_top.size = max_size
	
	cam_front.position = center + Vector3(0, 0, distance)
	cam_front.look_at(center, Vector3.UP)
	cam_front.size = max_size
	
	cam_side.position = center + Vector3(distance, 0, 0)
	cam_side.look_at(center, Vector3.UP)
	cam_side.size = max_size
	
	cam_iso.position = center + Vector3(distance, distance, distance)
	cam_iso.look_at(center, Vector3.UP)
	cam_iso.size = max_size

func export_blueprint(_path: String):
	vp_top.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp_front.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp_side.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp_iso.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img_top = vp_top.get_texture().get_image()
	var img_front = vp_front.get_texture().get_image()
	var img_side = vp_side.get_texture().get_image()
	var img_iso = vp_iso.get_texture().get_image()
	
	img_top.convert(Image.FORMAT_RGBA8)
	img_front.convert(Image.FORMAT_RGBA8)
	img_side.convert(Image.FORMAT_RGBA8)
	img_iso.convert(Image.FORMAT_RGBA8)
	
	var w = img_top.get_width()
	var h = img_top.get_height()
	var final_img = Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	
	final_img.blit_rect(img_top, Rect2i(0, 0, w, h), Vector2i(0, 0))
	final_img.blit_rect(img_front, Rect2i(0, 0, w, h), Vector2i(w, 0))
	final_img.blit_rect(img_side, Rect2i(0, 0, w, h), Vector2i(0, h))
	final_img.blit_rect(img_iso, Rect2i(0, 0, w, h), Vector2i(w, h))
	
	# Guardar en carpeta Imágenes del sistema
	var pictures_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES) + "/SpaceEngineersBuilder/"
	DirAccess.make_dir_absolute(pictures_dir)
	var time = Time.get_datetime_string_from_system().replace(":", "-")
	var final_path = pictures_dir + "plano_" + time + ".png"
	final_img.save_png(final_path)
	print("Plano exportado en: ", final_path)
