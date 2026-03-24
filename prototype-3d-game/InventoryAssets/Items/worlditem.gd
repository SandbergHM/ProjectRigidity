extends InteractableObject

@export var item_name : String

var highlighted : bool = false

var model : MeshInstance3D = null

func _ready():
	pass

func _interact():
	#Load selected item and add to player inventory
	var item = load("res://InventoryAssets/Items/Item data/" + item_name + ".tres")
	signal_bus.on_give_player_item.emit(item, 1)
	queue_free()
