extends Node

class_name SpellBase

@export var spell_name: String = "Spell Name"
@export var spell_description: String = "Spell Description"
@export var spell_icon: Texture2D
@export var spell_cooldown: float = 1.0
@export var spell_range: float = 5.0
@export var spell_unlocked: bool = false

func _try_primary_cast(collider, player: Player):
	return false

func _try_secondary_cast(collider, player: Player):
	return false
