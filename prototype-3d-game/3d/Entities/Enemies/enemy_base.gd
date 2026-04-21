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
## How long between melee strikes, in seconds
@export var attack_cooldown_duration: float = 1.0

@export_group("Navigation properties")
## How close the enemy needs to be to its target before stopping
@export var stopping_distance: float = 1.5
## How often the navigation target is updated, in seconds
@export var path_refresh_rate: float = 0.2
## Enemy hover height
@export var hover_height: float = 2.0

@export_group("Feedback")
## Seconds the hit flash takes to fade
@export var hit_flash_duration: float = 0.25
## Seconds before health bar hides after last hit
@export var health_bar_hide_delay: float = 3.0

var max_health: float
var is_damage_cooldown_active: bool = false
var _attack_cooldown_active: bool = false
var _target: Node3D = null
var _path_refresh_timer: float = 0.0
var _last_damage_source: Node = null
var _low_health_signal_sent: bool = false
var player_state: globals.Player_state = globals.Player_state.IDLE

@onready var damage_cooldown_timer: Timer = $DamageCooldown
@onready var status_effects: StatusEffectComponent = $StatusEffectComponent
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _health_bar: Label3D = $HealthBar3D

var _attack_cooldown_timer: Timer
var _hit_flash_mat: ShaderMaterial
var _health_bar_hide_timer: Timer


func _ready() -> void:
	max_health = health
	_target = get_tree().get_first_node_in_group("player")

	nav_agent.max_speed = movement_speed
	nav_agent.path_desired_distance = stopping_distance
	nav_agent.target_desired_distance = stopping_distance

	_attack_cooldown_timer = Timer.new()
	_attack_cooldown_timer.name = "AttackCooldown"
	_attack_cooldown_timer.one_shot = true
	_attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	add_child(_attack_cooldown_timer)

	_setup_hit_flash()
	_setup_health_bar()


# === HIT FLASH ===

func _setup_hit_flash() -> void:
	if _mesh == null:
		return
	var shader := load("res://3d/materials/shaders/hit_flash.gdshader") as Shader
	if shader == null:
		return
	_hit_flash_mat = ShaderMaterial.new()
	_hit_flash_mat.shader = shader
	_hit_flash_mat.set_shader_parameter("hit_flash", 0.0)
	# Attach as next_pass so the base material is completely untouched
	var base_mat := _mesh.get_active_material(0)
	if base_mat != null:
		base_mat.next_pass = _hit_flash_mat

func _play_hit_flash() -> void:
	if _hit_flash_mat == null:
		return
	_hit_flash_mat.set_shader_parameter("hit_flash", 1.0)
	var tween := create_tween()
	tween.tween_method(
		func(v: float) -> void: _hit_flash_mat.set_shader_parameter("hit_flash", v),
		1.0, 0.0, hit_flash_duration
	)


# === HEALTH BAR ===

func _setup_health_bar() -> void:
	_health_bar_hide_timer = Timer.new()
	_health_bar_hide_timer.name = "HealthBarHideTimer"
	_health_bar_hide_timer.one_shot = true
	_health_bar_hide_timer.timeout.connect(func() -> void: _health_bar.visible = false)
	add_child(_health_bar_hide_timer)

	if _health_bar != null:
		_health_bar.visible = false

func _update_health_bar() -> void:
	if _health_bar == null:
		return
	_health_bar.visible = true
	var pct := clampf(health / max_health, 0.0, 1.0)
	var bar_len := 10
	var filled := roundi(pct * bar_len)
	var empty := bar_len - filled
	_health_bar.text = "[%s%s] %d%%" % ["█".repeat(filled), "░".repeat(empty), roundi(pct * 100.0)]
	if pct > 0.5:
		_health_bar.modulate = Color.GREEN
	elif pct > 0.25:
		_health_bar.modulate = Color.YELLOW
	else:
		_health_bar.modulate = Color.RED
	_health_bar_hide_timer.start(health_bar_hide_delay)


# === NAVIGATION ===

func _physics_process(delta: float) -> void:
	_check_collision_damage()
	_check_death()
	_handle_navigation(delta)
	_check_melee_attack()

	if is_damage_cooldown_active and damage_cooldown_timer.is_stopped():
		damage_cooldown_timer.start(damage_cooldown_duration)


func _handle_navigation(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return

	if movement_type == MovementType.Flying:
		_handle_flying(delta)
	else:
		_handle_ground_navigation(delta)

func _handle_flying(delta: float) -> void:
	var hover_target := _target.global_position + Vector3.UP * hover_height
	var to_target := hover_target - global_position
	var dist := to_target.length()

	if dist <= stopping_distance:
		velocity = velocity.lerp(Vector3.ZERO, 10.0 * delta)
	else:
		velocity = to_target.normalized() * movement_speed

	move_and_slide()

func _handle_ground_navigation(delta: float) -> void:
	_path_refresh_timer -= delta
	if _path_refresh_timer <= 0.0:
		_path_refresh_timer = path_refresh_rate
		nav_agent.target_position = _target.global_position

	if nav_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var next_point := nav_agent.get_next_path_position()
		var direction := next_point - global_position
		direction.y = 0.0
		direction = direction.normalized()
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
		if not is_on_floor():
			velocity.y -= globals.FALL_ACCELLERATION * delta
		else:
			velocity.y = -0.5

	move_and_slide()

func set_target(new_target: Node3D) -> void:
	_target = new_target


# === COMBAT ===

func _check_melee_attack() -> void:
	if combat_type != CombatType.Melee:
		return
	if _target == null or not is_instance_valid(_target):
		return
	if _attack_cooldown_active:
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist <= stopping_distance and _target.has_method("take_damage"):
		_target.take_damage(base_damage, self)
		_attack_cooldown_active = true
		_attack_cooldown_timer.start(attack_cooldown_duration)

func _check_death() -> void:
	if health <= 0.0 and player_state != globals.Player_state.DEAD:
		player_state = globals.Player_state.DEAD
		queue_free()

func _check_collision_damage() -> void:
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if is_damage_cooldown_active or not collider is RigidBody3D or collider.is_in_group("projectiles"):
			continue
		var damage := _calculate_collision_damage(collider)
		if damage >= 1.0:
			take_damage(damage, collider)
			signal_bus.damage_dealt.emit(damage, global_position)

func _calculate_collision_damage(collider: RigidBody3D) -> float:
	return collider.mass * collider.linear_velocity.length()

func _on_damage_cooldown_timeout() -> void:
	is_damage_cooldown_active = false

func _on_attack_cooldown_timeout() -> void:
	_attack_cooldown_active = false

func take_damage(amount: float, source: Node = null) -> void:
	if is_damage_cooldown_active:
		return
	health -= amount
	_last_damage_source = source
	is_damage_cooldown_active = true
	signal_bus.damage_dealt.emit(amount, global_position)
	_play_hit_flash()
	_update_health_bar()
	var pct := health / max_health
	if pct < 0.25 and not _low_health_signal_sent:
		_low_health_signal_sent = true
		signal_bus.enemy_low_health.emit(self, pct)

func set_on_fire(instigator: Node = null) -> void:
	var effect := BurningEffect.new()
	status_effects.apply(effect, instigator)
