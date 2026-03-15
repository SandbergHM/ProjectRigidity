extends RigidBody3D

@onready var model : MeshInstance3D = $BoxModel

var highlighted : bool = false

func _ready():
	signal_bus.player_highlight.connect(_on_player_highlight)

func _on_player_highlight(collider: Variant) -> void:
	if collider != null and collider == self:
		var mesh = model.get_active_material(0)
		if mesh and not highlighted:
			highlighted = true
			model = globals.item_highlight(model)
	else:
		highlighted = false
		model = globals.remove_item_highlight(model)
