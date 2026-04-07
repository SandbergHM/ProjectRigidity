extends SpellBase

func _ready():
	spell_name = "Incinerate"
	spell_description = "Sets fire to target or launches ball of fire"
	spell_cooldown = 5.0
	spell_range = 3.0
	
func _try_primary_cast(collider, player: Player):
	#if collider and collider.is_in_group("enemies"):
		#var enemy = collider as Enemy
		#enemy.apply_status_effect("burning", 5.0) # Apply burning effect for 5 seconds
		#return true
	return false
	
func _try_secondary_cast(collider, player: Player):
	# Launch a fireball in the direction the player is facing
	#var fireball = Fireball.new()
	#fireball.global_position = player.global_position
	#fireball.direction = player.facing_direction
	#get_parent().add_child(fireball)
	return true
