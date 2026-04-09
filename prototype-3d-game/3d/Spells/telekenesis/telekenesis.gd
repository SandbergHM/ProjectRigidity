extends SpellBase

@export var throw_force: float = 20.0

var lock_rotation: bool = false
var is_holding: bool = false
var held_object: RigidBody3D = null
var hold_tween: Tween = null
var _player: Player = null

const HOLD_DISTANCE: float = 2
const LIFT_DURATION: float = 0.2

func _ready() -> void:
	spell_name = "Telekinesis"
	# Walk up the tree to find the Player node
	_player = _find_player()
	if _player:
		_player.connect("physics_frame", _on_physics_frame)

func _find_player() -> Player:
	var node = get_parent()
	while node:
		if node is Player:
			return node
		node = node.get_parent()
	return null

func _on_physics_frame() -> void:
	if is_holding:
		_update_held_position(_player)

func _try_primary_cast(collider, player):
	if collider == null:
		return false
		
	if is_holding:
		_throw_object(player)
		return true
	elif collider is RigidBody3D and collider.is_in_group("interactable"):
		var camera = player.camera
		var cam_forward = -camera.global_transform.basis.z
		var player_forward = -player.global_transform.basis.z
		var throw_direction = (cam_forward * 0.75 + player_forward * 0.25).normalized()
		collider.apply_impulse(throw_direction * throw_force)
	return false

func _try_secondary_cast(collider, player):
	if collider == null:
		return false

	if collider is RigidBody3D and collider.is_in_group("interactable"):
		held_object = collider
		is_holding = true
		_player = player        # store the instance, not the class
		held_object.freeze = true
		var target_pos = _get_hold_position(_player)
		if hold_tween:
			hold_tween.kill()
		hold_tween = create_tween()
		hold_tween.set_ease(Tween.EASE_OUT)
		hold_tween.set_trans(Tween.TRANS_QUINT)
		hold_tween.tween_property(held_object, "global_position", target_pos, LIFT_DURATION)
		return true

	return false

func _update_held_position(player):
	# Smoothly follow the camera hold point each frame after the initial lift
	var target_pos = _get_hold_position(player)

	if hold_tween and hold_tween.is_running():
		return  # Let the lift tween finish first

	held_object.global_position = lerp(
		held_object.global_position,
		target_pos,
		0.2  # Adjust for tighter or looser tracking
	)

func _throw_object(player):
	is_holding = false

	# Re-enable physics
	held_object.freeze = false
	var camera = player.camera
	var cam_forward = -camera.global_transform.basis.z
	var player_forward = -player.global_transform.basis.z
	var throw_direction = (cam_forward * 0.75 + player_forward * 0.25).normalized()
	held_object.apply_impulse(throw_direction * throw_force)

	if hold_tween:
		hold_tween.kill()
		hold_tween = null

	held_object = null

func _get_hold_position(player) -> Vector3:
	return player.camera.global_position + (-player.camera.global_transform.basis.z * HOLD_DISTANCE)
	
# In telekenesis.gd
func on_unequip() -> void:
	if is_holding:
		_throw_object(_player)
