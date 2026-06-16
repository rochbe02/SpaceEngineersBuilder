extends PanelContainer
signal exportar_plano

@onready var materials_list: VBoxContainer = $VBoxContainer/ScrollContainer/MaterialsList
@onready var pcu_value: Label = $VBoxContainer/HBoxContainer/PCUValue
@onready var btn_exportar: Button = $VBoxContainer/BtnExportar

func _ready():
	print("MaterialsPanel listo")
	btn_exportar.pressed.connect(_on_exportar_pressed)

func _on_exportar_pressed():
	emit_signal("exportar_plano")

func update_stats(placed_blocks: Dictionary):
	for child in materials_list.get_children():
		child.queue_free()
	
	var totals = {}
	var total_pcu = 0
	
	for cell in placed_blocks:
		var block_data = placed_blocks[cell]
		# Soporta tanto formato viejo (String) como nuevo (Dictionary)
		var block_id = ""
		if block_data is String:
			block_id = block_data
		elif block_data is Dictionary:
			block_id = block_data.get("id", "")
		
		var block = BlockDatabase.get_block(block_id)
		if block.is_empty():
			continue
		
		for material in block.get("materials", {}):
			totals[material] = totals.get(material, 0) + block["materials"][material]
		total_pcu += block.get("pcu", 0)
	
	for material in totals:
		var row = HBoxContainer.new()
		var name_label = Label.new()
		name_label.text = material + ":"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var amount_label = Label.new()
		amount_label.text = str(totals[material])
		row.add_child(name_label)
		row.add_child(amount_label)
		materials_list.add_child(row)
	
	pcu_value.text = str(total_pcu)


func _on_viewport_3d_block_placed(placed_blocks: Dictionary):
	update_stats(placed_blocks)

func _on_viewport_3d_block_removed(placed_blocks: Dictionary):
	update_stats(placed_blocks)
