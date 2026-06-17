extends Node

var font: FontFile
var meta_ship_name: String = ""
var meta_author: String = ""
var meta_block_count: int = 0
var meta_pcu: int = 0
var meta_date: String = ""

@onready var label_ship_name = $"LabelViewport/SubViewport/Control/LabelShipName"
@onready var label_date = $"LabelViewport/SubViewport/Control/LabelDate"
@onready var label_blocks = $"LabelViewport/SubViewport/Control/LabelBlocks"
@onready var label_author = $"LabelViewport/SubViewport/Control/LabelAuthor"
@onready var vp_labels = $"LabelViewport/SubViewport"
@onready var cam_top = $"SubViewportContainer(Top)/SubViewport/Camera3D"
@onready var cam_front = $"SubViewportContainer(Front)/SubViewport/Camera3D"
@onready var cam_side = $"SubViewportContainer(Side)/SubViewport/Camera3D"
@onready var cam_iso = $"SubViewportContainer(Iso)/SubViewport/Camera3D"
@onready var vp_top = $"SubViewportContainer(Top)/SubViewport"
@onready var vp_front = $"SubViewportContainer(Front)/SubViewport"
@onready var vp_side = $"SubViewportContainer(Side)/SubViewport"
@onready var vp_iso = $"SubViewportContainer(Iso)/SubViewport"

func _ready():
	font = load("res://assets/fonts/04B_20__.ttf")

func set_metadata(ship_name: String, author: String, placed_blocks: Dictionary):
	meta_ship_name = ship_name if ship_name != "" else "Sin nombre"
	meta_author = author if author != "" else "Anonimo"
	meta_date = Time.get_date_string_from_system()
	
	var origins = {}
	for cell in placed_blocks:
		var block = placed_blocks[cell]
		var origin = block.get("origin", cell)
		origins[origin] = true
	meta_block_count = origins.size()
	
	meta_pcu = 0
	for cell in origins:
		var block_id = placed_blocks[cell].get("id", "")
		var block = BlockDatabase.get_block(block_id)
		meta_pcu += block.get("pcu", 0)

func setup_cameras(placed_blocks: Dictionary, grid_map: GridMap):
	if placed_blocks.is_empty():
		return
	
	var main_world = grid_map.get_world_3d()
	vp_top.world_3d = main_world
	vp_front.world_3d = main_world
	vp_side.world_3d = main_world
	vp_iso.world_3d = main_world
	
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
	var padding = 40
	var label_height = 30
	var final_w = w * 2 + padding * 3
	var final_h = h * 2 + padding * 3 + label_height * 2
	
	var final_img = Image.create(final_w, final_h, false, Image.FORMAT_RGBA8)
	final_img.fill(Color(0.05, 0.1, 0.25, 1.0))
	
	# Grid de puntos
	var dot_color = Color(0.15, 0.25, 0.5, 1.0)
	for y in range(0, final_h, 20):
		for x in range(0, final_w, 20):
			final_img.set_pixel(x, y, dot_color)
	
	var positions = [
		Vector2i(padding, padding + label_height),
		Vector2i(w + padding * 2, padding + label_height),
		Vector2i(padding, h + padding * 2 + label_height * 2),
		Vector2i(w + padding * 2, h + padding * 2 + label_height * 2)
	]
	
	var images = [img_top, img_front, img_side, img_iso]
	for i in range(4):
		final_img.blit_rect(images[i], Rect2i(0, 0, w, h), positions[i])
	
	var line_color = Color(0.4, 0.7, 1.0, 0.8)
	for y in range(final_h):
		for x in range(2):
			final_img.set_pixel(w + padding + padding/2 + x, y, line_color)
	for x in range(final_w):
		for y in range(2):
			final_img.set_pixel(x, h + padding + label_height + padding/2 + y, line_color)
	
	# Actualizar labels con metadata
	label_ship_name.text = meta_ship_name
	label_date.text = "Fecha: " + meta_date
	label_blocks.text = "Bloques: " + str(meta_block_count) + "  PCU: " + str(meta_pcu)
	label_author.text = "Autor: " + meta_author
	
	# Renderizar etiquetas
	vp_labels.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img_labels = vp_labels.get_texture().get_image()
	img_labels.convert(Image.FORMAT_RGBA8)
	final_img.blit_rect_mask(img_labels, img_labels, Rect2i(0, 0, final_w, final_h), Vector2i(0, 0))
	
	var pictures_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES) + "/SpaceEngineersBuilder/"
	DirAccess.make_dir_absolute(pictures_dir)
	var time = Time.get_datetime_string_from_system().replace(":", "-")
	var final_path = pictures_dir + "plano_" + time + ".png"
	final_img.save_png(final_path)
	print("Plano exportado en: ", final_path)
