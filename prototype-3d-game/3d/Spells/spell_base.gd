extends Node

class_name SpellBase

@export var spell_name: String = "Spell Name"
@export var spell_description: String = "Spell Description"
@export var primary_cast_description: String = "Primary Cast Description"
@export var secondary_cast_description: String = "Secondary Cast Description"
@export var spell_icon: Texture2D
@export var spell_cooldown: float = 1.0
@export var spell_range: float = 5.0
@export var spell_unlocked: bool = false

var cooldown_timer: Timer

func _ready():
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)

func _try_primary_cast(collider, player: Player):
	return false

func _try_secondary_cast(collider, player: Player):
	return false

# In spell_base.gd
func on_unequip() -> void:
	pass  # Override to clean up



func _on_cooldown_timer_timeout() -> void:
	pass # Replace with function body.
