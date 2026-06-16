extends Node

func get_save_dir() -> String:
	var exe_dir = OS.get_executable_path().get_base_dir()
	return exe_dir + "/saves/"

func save_ship(ship_name: String, placed_blocks: Dictionary, ship_size: String) -> bool:
	var save_dir = get_save_dir()
	DirAccess.make_dir_absolute(save_dir)
	
	var data = {
		"name": ship_name,
		"size": ship_size,
		"version": "1.0",
		"blocks": {}
	}
	
	for cell in placed_blocks:
		var block = placed_blocks[cell]
		var key = str(cell.x) + "," + str(cell.y) + "," + str(cell.z)
		data["blocks"][key] = {
			"id": block.get("id", ""),
			"rotation": {
				"x": block.get("rotation", Vector3i(0,0,0)).x,
				"y": block.get("rotation", Vector3i(0,0,0)).y,
				"z": block.get("rotation", Vector3i(0,0,0)).z
			},
			"origin": {
				"x": block.get("origin", cell).x,
				"y": block.get("origin", cell).y,
				"z": block.get("origin", cell).z
			}
		}
	
	var path = save_dir + ship_name.replace(" ", "_") + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("Error al guardar: ", path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Nave guardada en: ", path)
	return true

func load_ship(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error al cargar: ", path)
		return {}
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error != OK:
		print("Error al parsear: ", path)
		return {}
	return json.get_data()

func get_saved_ships() -> Array:
	var ships = []
	var dir = DirAccess.open(get_save_dir())
	if dir == null:
		return ships
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			ships.append(get_save_dir() + file_name)
		file_name = dir.get_next()
	return ships
