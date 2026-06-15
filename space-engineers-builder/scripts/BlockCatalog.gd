extends PanelContainer

@onready var category_list: ItemList = $HBoxContainer/VBoxContainer/ItemList
@onready var search_box: LineEdit = $HBoxContainer/VBoxContainer/LineEdit
@onready var block_grid: GridContainer = $HBoxContainer/ScrollContainer/GridContainer

signal block_selected(block_id: String)

func _ready():
	print("BlockCatalog listo")
	_build_category_list()
	category_list.item_selected.connect(_on_category_selected)
	search_box.text_changed.connect(_on_search_changed)
	
	if BlockDatabase.categories.size() > 0:
		category_list.select(0)
		_show_category(BlockDatabase.categories[0])

func _build_category_list():
	category_list.clear()
	for category in BlockDatabase.categories:
		category_list.add_item(category)

func _show_category(category: String):
	var blocks = BlockDatabase.get_blocks_by_category(category)
	_populate_grid(blocks)

func _populate_grid(blocks: Dictionary):
	for child in block_grid.get_children():
		child.queue_free()
	
	for block_id in blocks:
		var block = blocks[block_id]
		var btn = Button.new()
		btn.text = block.get("name", block_id)
		btn.custom_minimum_size = Vector2(80, 80)
		btn.pressed.connect(_on_block_pressed.bind(block_id))
		block_grid.add_child(btn)

func _on_category_selected(index: int):
	var category = BlockDatabase.categories[index]
	_show_category(category)

func _on_block_pressed(block_id: String):
	print("Bloque seleccionado: ", block_id)
	emit_signal("block_selected", block_id)

func _on_search_changed(text: String):
	if text == "":
		var idx = category_list.get_selected_items()
		if idx.size() > 0:
			_show_category(BlockDatabase.categories[idx[0]])
		return
	
	var all_blocks = BlockDatabase.get_all_blocks()
	var filtered = {}
	for block_id in all_blocks:
		var block = all_blocks[block_id]
		if block.get("name", "").to_lower().contains(text.to_lower()):
			filtered[block_id] = block
	_populate_grid(filtered)
