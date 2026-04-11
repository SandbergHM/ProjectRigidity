extends CharacterBody3D

enum CombatType { Melee, Ranged, Spellcaster }
enum MovementType { Ground, Flying }

@export_category("Export values")

@export_group("General properties")
@export var health: float = 100.0
@export var movement_speed: float = 5.0
@export var combat_type: CombatType
@export var movement_type: MovementType

@export_group("Damage properties")
@export var base_damage: float = 10.0
@export var damage_cooldown_duration: float = 0.2

@export_group("Navigation properties")
## How close the enemy needs to be to its target before stopping
@export var stopping_distance: float = 1.5
## How often the navigation target is updated, in seconds
@export var path_refresh_rate: float = 0.2

var is_damage_cooldown_active: bool = false
var _target: Node3D = null
var _path_refresh_timer: float = 0.0

@onready var damage_cooldown_timer: Timer = $DamageCooldown
@onready var status_effects: StatusEffectComponent = $StatusEffectComponent
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	_target = get_tree().get_first_node_in_group("player")
	
	nav_agent.max_speed = movement_speed
	nav_agent.path_desired_distance = stopping_distance
	nav_agent.target_desired_distance = stopping_distance

func _physics_process(delta: float) -> void:
	_check_collision_damage()
	_check_death()
	_handle_navigation(delta)

	if is_damage_cooldown_active and damage_cooldown_timer.is_stopped():
		damage_cooldown_timer.start(damage_cooldown_duration)


func _handle_navigation(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return

	# Refresh the navigation target periodically rather than every frame
	_path_refresh_timer -= delta
	if _path_refresh_timer <= 0.0:
		_path_refresh_timer = path_refresh_rate
		nav_agent.target_position = _target.global_position

	if nav_agent.is_navigation_finished():
		# Reached stopping distance — zero out horizontal movement
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var next_point := nav_agent.get_next_path_position()
		var direction := (next_point - global_position)
		
		if movement_type == MovementType.Flying:
			direction = direction.normalized()
			velocity = direction * movement_speed
		else:
			# Ground enemies ignore vertical component of path direction
			direction.y = 0.0
			direction = direction.normalized()
			velocity.x = direction.x * movement_speed
			velocity.z = direction.z * movement_speed
			# Keep gravity
			if not is_on_floor():
				velocity.y -= globals.FALL_ACCELLERATION * get_physics_process_delta_time()
			else:
				velocity.y = -0.5

	move_and_slide()



func set_target(new_target: Node3D) -> void:
	_target = new_target


func _check_death() -> void:
	if health <= 0.0:
		await get_tree().process_frame
		queue_free()


func _check_collision_damage() -> void:
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if is_damage_cooldown_active or not collider is RigidBody3D:
			continue
		var damage := _calculate_collision_damage(collider)
		if damage >= 1.0:
			take_damage(damage)


func _calculate_collision_damage(collider: RigidBody3D) -> float:
	return collider.mass * collider.linear_velocity.length()


func _on_damage_cooldown_timeout() -> void:
	is_damage_cooldown_active = false


func take_damage(amount: float) -> void:
	if is_damage_cooldown_active:
		return
	health -= amount
	is_damage_cooldown_active = true


func set_on_fire() -> void:
	status_effects.apply(BurningEffect.new())
