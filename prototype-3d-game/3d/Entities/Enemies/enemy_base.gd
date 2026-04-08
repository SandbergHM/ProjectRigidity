extends CharacterBody3D

enum CombatType { Melee, Ranged, Spellcaster }
enum MovementType { Ground, Flying }

@export_category("Export values")

@export_group("General properties")
## Enemy health
@export var health: float = 100.0
## Enemy base movement speed
@export var movement_speed: float = 5.0
## Type of combat this enemy uses
@export var combat_type: CombatType
## Movement type used for navigation
@export var movement_type: MovementType

@export_group("Damage properties")
## Base damage dealt to the player, used in all damage calculations
@export var base_damage: float = 10.0
## Minimum seconds between instances of damage the enemy can receive
@export var damage_cooldown_duration: float = 0.2

var is_damage_cooldown_active: bool = false

@onready var damage_cooldown_timer: Timer = $DamageCooldown
@onready var status_effects: StatusEffectComponent = $StatusEffectComponent


func _ready() -> void:
	pass  # StatusEffectComponent is added via the scene tree


func _physics_process(_delta: float) -> void:
	move_and_slide()
	_check_collision_damage()
	_check_death()

	if is_damage_cooldown_active and damage_cooldown_timer.is_stopped():
		damage_cooldown_timer.start(damage_cooldown_duration)


func _check_death() -> void:
	if health <= 0.0:
		# Defer by one frame so collisions can register before removal
		await get_tree().process_frame
		queue_free()


## Checks slide collisions and applies damage from RigidBody3D impacts
func _check_collision_damage() -> void:
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if is_damage_cooldown_active or not collider is RigidBody3D:
			continue
		var damage := _calculate_collision_damage(collider)
		if damage >= 1.0:
			take_damage(damage)


## Returns impact damage based on the collider's mass and speed
func _calculate_collision_damage(collider: RigidBody3D) -> float:
	return collider.mass * collider.linear_velocity.length()


func _on_damage_cooldown_timeout() -> void:
	is_damage_cooldown_active = false


func take_damage(amount: float) -> void:
	if is_damage_cooldown_active:
		return
	health -= amount
	is_damage_cooldown_active = true
	print(health)


func set_on_fire() -> void:
	status_effects.apply(BurningEffect.new())
