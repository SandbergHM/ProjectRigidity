extends CharacterBody3D

@export_category("Export properties")
@export_group("General properties")
@export var health: float = 100.0
@export var movement_speed: float = 5.0
@export_group("Damage properties")
@export var base_damage: float = 10.0
@export var damage_cooldown: float = 0.2

var damage_taken: bool = false

@onready var damagetakencooldown: Timer = $DamageCooldown

func _ready() -> void:
	damagetakencooldown.one_shot = true

func _physics_process(delta: float) -> void:
	move_and_slide()
	_check_collision_damage()
	
	# Manage damage cooldown
	if damage_taken and damagetakencooldown.is_stopped():
		damagetakencooldown.start(damage_cooldown)
	
	if health <= 0.0:
		# Give one frame before deleting node in order to provide collisions a chance to register and affect the physical objects
		get_tree().process_frame
		queue_free()


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
