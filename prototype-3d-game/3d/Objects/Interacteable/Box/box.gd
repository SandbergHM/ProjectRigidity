extends RigidBody3D

@onready var model : MeshInstance3D = $BoxModel

var highlighted : bool = false

func _on_player_highlight(collider: Variant) -> void:
	if collider != null and collider == self:
		var mesh = model.get_active_material(0)
		if not highlighted:
			highlighted = true
			model = globals.item_highlight(model)
	else:
		highlighted = false
		model = globals.remove_item_highlight(model)
