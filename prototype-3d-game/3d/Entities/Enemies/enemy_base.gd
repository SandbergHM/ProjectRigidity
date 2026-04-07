extends CharacterBody3D

enum CombatTypeEnum {Melee, Ranged, Spellcaster}
enum MovementTypeEnum {Ground, Flying}

@export_category("Export values")
@export_group("General properties")
## Enemy health
@export var health: float = 100.0
## Enemy base movement speed
@export var movement_speed: float = 5.0
## Enemy asasigned type of combat
@export var combat_type: CombatTypeEnum
## Enemy movement type for navigation functionality
@export var movement_type: MovementTypeEnum
@export_group("Damage properties")
## Enemy base damage towards player, to be used for all damage calculations
@export var base_damage: float = 10.0
## Minimum time between each time the player can take damage
@export var damage_cooldown: float = 0.2

var damage_taken: bool = false

@onready var damagetakencooldown: Timer = $DamageCooldown


func _physics_process(delta: float) -> void:
	move_and_slide()
	_check_collision_damage()
	
	if health <= 0.0:
		# Give one frame before deleting node in order to provide collisions a chance to register and affect the physical objects
		get_tree().process_frame
		queue_free()
	
	# Manage damage cooldown
	if damage_taken and damagetakencooldown.is_stopped():
		damagetakencooldown.start(damage_cooldown)

## Checks all collisions and calculates any damage taken from projectiles or objects
func _check_collision_damage():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if not(damage_taken) and collider is RigidBody3D and _calculate_collision_damage(collider) >= 1.0:
			health -= _calculate_collision_damage(collider)
			print(health)
			damage_taken = true

## Calculate collision damage based on mass and velocity
func _calculate_collision_damage(collider) -> float:
	return collider.mass * collider.linear_velocity.length()

func _on_damage_cooldown_timeout():
	damage_taken = false
	damagetakencooldown.stop()
