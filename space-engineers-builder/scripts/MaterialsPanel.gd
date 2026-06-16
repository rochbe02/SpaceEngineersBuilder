extends PanelContainer

@onready var materials_list: VBoxContainer = $VBoxContainer/ScrollContainer/MaterialsList
@onready var pcu_value: Label = $VBoxContainer/HBoxContainer/PCUValue

func _ready():
	print("MaterialsPanel listo")

func update_stats(placed_blocks: Dictionary):
	for child in materials_list.get_children():
		child.queue_free()
	
	var totals = {}
	var total_pcu = 0
	
	for cell in placed_blocks:
		var block_id = placed_blocks[cell]
		var block = BlockDatabase.get_block(block_id)
		print("Block ID: ", block_id, " Block data: ", block)  # <- temporal
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
