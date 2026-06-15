extends Node

var blocks: Dictionary = {}
var categories: Array = [
	"Armor",
	"Conveyors",
	"Electricity",
	"Gyroscopes",
	"Landing",
	"Lights",
	"Miscellaneous",
	"Production",
	"Structural",
	"Thrusters",
	"Tools",
	"Weapons"
]

func _ready():
	_load_database()

func _load_database():
	var file = FileAccess.open("res://data/blocks_db.json", FileAccess.READ)
	if file == null:
		print("Error: no se pudo abrir blocks_db.json")
		return
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		blocks = json.get_data()
		print("Base de datos cargada: ", blocks.size(), " bloques")
	else:
		print("Error al parsear blocks_db.json")
	file.close()

func get_block(block_id: String) -> Dictionary:
	return blocks.get(block_id, {})

func get_blocks_by_category(category: String) -> Dictionary:
	var result = {}
	for id in blocks:
		if blocks[id].get("category", "") == category:
			result[id] = blocks[id]
	return result

func get_all_blocks() -> Dictionary:
	return blocks
