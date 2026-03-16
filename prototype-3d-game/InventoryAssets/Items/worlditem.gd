extends InteractableObject

@export var item_name : String

var highlighted : bool = false

var model : MeshInstance3D = null

func _ready():
	#Connect and prepare item highlighting
	signal_bus.player_highlight.connect(_on_player_highlight)
	for child in get_children():
		if child is MeshInstance3D:
			model = child

func _interact():
	#Load selected item and add to player inventory
	var item = load("res://InventoryAssets/Items/Item data/" + item_name + ".tres")
	signal_bus.on_give_player_item.emit(item, 1)
	queue_free()

func _on_player_highlight(collider: Variant) -> void:
	#Highlight item if player is looking at it, otherwise remove highlight
	if collider != null and collider == self and model:
		var mesh = model.get_active_material(0)
		if mesh and not highlighted:
			highlighted = true
			model = globals.item_highlight(model)
	else:
		highlighted = false
		model = globals.remove_item_highlight(model)
