class_name StatusEffect
extends Resource

@export var effect_name: String = "Status Effect"
@export var duration: float = 5.0
@export var tick_interval: float = 0.5
@export var icon: Texture2D

# Called once when the effect is first applied
func on_apply(entity: Node) -> void:
	pass

# Called every tick_interval seconds while active
func on_tick(entity: Node) -> void:
	pass

# Called once when the effect expires or is removed
func on_remove(entity: Node) -> void:
	pass


func on_refresh(entity: Node) -> void:
	duration = get_script().new().duration
