extends SpellBase

# =============================================================================
# EXPORT VARIABLES
# =============================================================================

## Speed at which thrown objects are launched (mass-independent)
@export var throw_force: float = 20.0

# =============================================================================
# CONSTANTS
# =============================================================================

const HOLD_DISTANCE: float = 2.0
const LIFT_DURATION: float = 0.2
const HOLD_LERP_SPEED: float = 0.2

## Blend between camera forward (0.75) and player forward (0.25) for throw direction
const THROW_CAM_WEIGHT: float = 0.75
const THROW_PLAYER_WEIGHT: float = 0.25

# =============================================================================
# STATE
# =============================================================================

var is_holding: bool = false
var held_object: RigidBody3D = null
var hold_tween: Tween = null
var _player: Player = null

const HOLD_ALPHA: float = 0.35
const FADE_DURATION: float = 0.2

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	spell_name = "Telekinesis"
	_player = _find_player()
	if _player:
		_player.physics_frame.connect(_on_physics_frame)


func _find_player() -> Player:
	var node := get_parent()
	while node:
		if node is Player:
			return node as Player
		node = node.get_parent()
	return null

# =============================================================================
# SPELL INTERFACE
# =============================================================================

func _try_primary_cast(collider: Node3D, player: Player) -> bool:
	if is_holding:
		_throw_held_object(player)
		return true

	if collider == null:
		return false

	# Quick-flick throw without picking up first
	if collider is RigidBody3D and collider.is_in_group("interactable"):
		collider.linear_velocity = _get_throw_direction(player) * throw_force
		return true

	return false


func _try_secondary_cast(collider: Node3D, player: Player) -> bool:
	if collider == null or not (collider is RigidBody3D) or not collider.is_in_group("interactable"):
		return false

	_pick_up(collider, player)
	return true

# =============================================================================
# PICK UP & THROW
# =============================================================================

func _pick_up(object: RigidBody3D, player: Player) -> void:
	held_object = object
	is_holding = true
	_player = player
	held_object.freeze = true
	_set_held_alpha(object, HOLD_ALPHA)
	signal_bus.is_player_holding = true

	if hold_tween:
		hold_tween.kill()

	hold_tween = create_tween()
	hold_tween.set_ease(Tween.EASE_OUT)
	hold_tween.set_trans(Tween.TRANS_QUINT)
	hold_tween.tween_property(held_object, "global_position", _get_hold_position(player), LIFT_DURATION)


func _throw_held_object(player: Player) -> void:
	is_holding = false
	held_object.freeze = false
	held_object.linear_velocity = _get_throw_direction(player) * throw_force
	_set_held_alpha(held_object, 1.0)
	signal_bus.is_player_holding = false

	if hold_tween:
		hold_tween.kill()
		hold_tween = null

	held_object = null

# =============================================================================
# HELPERS
# =============================================================================

func _get_throw_direction(player: Player) -> Vector3:
	var cam_forward := -player.camera.global_transform.basis.z
	var player_forward := -player.global_transform.basis.z
	return (cam_forward * THROW_CAM_WEIGHT + player_forward * THROW_PLAYER_WEIGHT).normalized()


func _get_hold_position(player: Player) -> Vector3:
	return player.camera.global_position + (-player.camera.global_transform.basis.z * HOLD_DISTANCE)


func _get_held_mesh(object: RigidBody3D) -> MeshInstance3D:
	for child in object.get_children():
		if child is MeshInstance3D:
			return child
	return null


func _set_held_alpha(object: RigidBody3D, target_alpha: float) -> void:
	var mesh := _get_held_mesh(object)
	if mesh == null:
		return
	var mat := mesh.get_active_material(0)
	if mat == null or not mat is StandardMaterial3D:
		return
	# Duplicate so we don't affect other instances sharing this material
	var std_mat := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
	mesh.set_surface_override_material(0, std_mat)
	if target_alpha < 1.0:
		std_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween := create_tween()
	tween.tween_method(
		func(a: float) -> void:
			var c := std_mat.albedo_color
			c.a = a
			std_mat.albedo_color = c,
		std_mat.albedo_color.a, target_alpha, FADE_DURATION
	)
	if target_alpha >= 1.0:
		tween.tween_callback(func() -> void:
			std_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		)

# =============================================================================
# FRAME UPDATE & CLEANUP
# =============================================================================

func _on_physics_frame() -> void:
	if not is_holding or hold_tween and hold_tween.is_running():
		return
	# Smoothly follow the hold point each frame after the initial lift tween
	held_object.global_position = lerp(held_object.global_position, _get_hold_position(_player), HOLD_LERP_SPEED)


func on_unequip() -> void:
	if is_holding:
		_throw_held_object(_player)
