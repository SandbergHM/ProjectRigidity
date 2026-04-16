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
	if collider == null:
		return false

	if is_holding:
		_throw_held_object(player)
		return true

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
