extends PanelContainer

@onready var category_list: ItemList = $HBoxContainer/VBoxContainer/ItemList
@onready var search_box: LineEdit = $HBoxContainer/VBoxContainer/LineEdit
@onready var block_grid: GridContainer = $"HBoxContainer/VBoxContainer/BlockPanel/ScrollContainer/GridContainer"
@onready var blocks_panel = $"HBoxContainer/VBoxContainer/BlockPanel"
@onready var btn_large: Button = $"HBoxContainer/VBoxContainer/HBoxContainer/BtnLarge"
@onready var btn_small: Button = $"HBoxContainer/VBoxContainer/HBoxContainer/BtnSmall"

signal block_selected(block_id: String)
signal size_changed(size: String)

var current_size: String = "Large"
var current_category: String = ""

func _ready():
	print("BlockCatalog listo")
	_build_category_list()
	category_list.item_selected.connect(_on_category_selected)
	search_box.text_changed.connect(_on_search_changed)
	btn_large.pressed.connect(_on_large_pressed)
	btn_small.pressed.connect(_on_small_pressed)

func _build_category_list():
	category_list.clear()
	for category in BlockDatabase.categories:
		category_list.add_item(category)

func _on_category_selected(index: int):
	var category = BlockDatabase.categories[index]
	print("Categoría: ", category, " visible: ", blocks_panel.visible)
	
	if category == current_category and blocks_panel.visible:
		blocks_panel.visible = false
		current_category = ""
		return
	
	current_category = category
	blocks_panel.visible = true
	_show_category(category)

func _show_category(category: String):
	var all_blocks = BlockDatabase.get_blocks_by_category(category)
	var filtered = {}
	for block_id in all_blocks:
		if all_blocks[block_id].get("size", "Large") == current_size:
			filtered[block_id] = all_blocks[block_id]
	_populate_grid(filtered)

func _populate_grid(blocks: Dictionary):
	for child in block_grid.get_children():
		child.queue_free()
	
	for block_id in blocks:
		var block = blocks[block_id]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.tooltip_text = block.get("name", block_id)
		
		# Cargar ícono si existe
		var icon_name = block.get("icon", "")
		if icon_name != "":
			var icon_path = "res://assets/blocks/icons/" + icon_name
			if ResourceLoader.exists(icon_path):
				var tex = load(icon_path)
				btn.icon = tex
				btn.expand_icon = true
			else:
				btn.text = block.get("name", block_id)
		else:
			btn.text = block.get("name", block_id)
		
		btn.pressed.connect(_on_block_pressed.bind(block_id))
		block_grid.add_child(btn)

func _on_block_pressed(block_id: String):
	print("Bloque seleccionado: ", block_id)
	emit_signal("block_selected", block_id)

func _on_large_pressed():
	current_size = "Large"
	btn_large.button_pressed = true
	btn_small.button_pressed = false
	emit_signal("size_changed", "Large")
	if current_category != "":
		_show_category(current_category)

func _on_small_pressed():
	current_size = "Small"
	btn_small.button_pressed = true
	btn_large.button_pressed = false
	emit_signal("size_changed", "Small")
	if current_category != "":
		_show_category(current_category)

func _on_search_changed(text: String):
	if text == "":
		if current_category != "":
			_show_category(current_category)
		else:
			blocks_panel.visible = false
		return
	
	blocks_panel.visible = true
	var all_blocks = BlockDatabase.get_all_blocks()
	var filtered = {}
	for block_id in all_blocks:
		var block = all_blocks[block_id]
		if block.get("name", "").to_lower().contains(text.to_lower()) and block.get("size", "Large") == current_size:
			filtered[block_id] = block
	_populate_grid(filtered)

func get_ship_name() -> String:
	return ""

func get_author_name() -> String:
	return ""
