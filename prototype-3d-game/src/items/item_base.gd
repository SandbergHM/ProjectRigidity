class_name Item
extends Resource

@export var display_name : String
@export var icon : Texture2D
@export var max_stack_size : int = 5
@export var world_item_scene : PackedScene

func _on_use (player) -> bool:
	
	return false
