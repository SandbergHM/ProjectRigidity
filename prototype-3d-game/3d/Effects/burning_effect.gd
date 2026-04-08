class_name BurningEffect
extends StatusEffect

@export var damage_per_tick: float = 5.0

func _init() -> void:
	effect_name = "Burning"
	duration = 5.0
	tick_interval = 0.5

func on_apply(entity: Node) -> void:
	var mesh := _get_mesh(entity)
	if mesh:
		mesh.material_overlay = Shader_registry._get_burning_effect()

func on_tick(entity: Node) -> void:
	if entity.has_method("take_damage"):
		entity.take_damage(damage_per_tick)

func on_remove(entity: Node) -> void:
	var mesh := _get_mesh(entity)
	if mesh:
		mesh.material_overlay = null

func _get_mesh(entity: Node) -> MeshInstance3D:
	for child in entity.get_children():
		if child is MeshInstance3D:
			return child
	return null
