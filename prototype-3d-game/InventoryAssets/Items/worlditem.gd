extends InteractableObject

@export var item_name : String

func _interact():
	var item = load("res://InventoryAssets/Items/Item data/" + item_name + ".tres")
	
