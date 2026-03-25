extends CharacterBody3D
class_name Player
#region export variables
## Player health
@export var player_health: float = 100.0
## Player movement speed
@export var movement_speed: float = 10.0
## Player jump height force
@export var jump_height: float = 5.0
## Player mouse rotation speed, lower is faster
@export var rotation_speed: float = 0.002
## Player speed added when sprint action is pressed
@export var sprint_speed: float = 5.0
## Player push force when running into other rigidbodies (push_direction * velocity.length() * push_force*mass_factor).
@export var push_force: float = 5.0
## Object throw force
@export var throw_force: float = 20.0
#endregion

#region local variables

var player_state = globals.Player_state.IDLE
var target_velocity = Vector3.ZERO
var movement_boost: float = 0
var collider = null
var lock_rotation: bool = false
var is_holding: bool = false
var held_object: RigidBody3D = null
var hold_tween: Tween = null
#endregion

#region onreadys

@onready var camera = $Camera3D
@onready var interact_line = $InteractLine

#endregion

#region constants
const HOLD_DISTANCE: float = 3.0
const LIFT_DURATION: float = 0.2
#endregion

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	up_direction = Vector3.UP
	signal_bus.lock_player_rotation.connect(_on_lock_player_rotation)


# Locks player rotation from signal bus, used for example when player is in a menu or dialogue
func _on_lock_player_rotation(lock):
	lock_rotation = lock

func _physics_process(delta: float) -> void:
#region player movement
	var direction = Vector3.ZERO
	var input_dir = Input.get_vector("player_move_right", "player_move_left", "player_move_back", "player_move_forward")
	var camera_basis = $Camera3D.global_transform.basis
	
	# Calculate movement relative to camera direction, ignoring the camera's tilt (vertical angle)
	direction = -(camera_basis.z * input_dir.y) - (camera_basis.x * input_dir.x)
	direction.y = 0 # Prevent flying
	direction = direction.normalized()
	
	_update_state(direction)
	
	if(Input.is_action_pressed("player_sprint") and is_on_floor()):
		movement_boost = sprint_speed
	else:
		movement_boost = 0
	
	if is_on_floor():
		target_velocity.x = direction.x * (movement_speed + movement_boost)
		target_velocity.z = direction.z * (movement_speed + movement_boost)
	else:
		var air_control: float = 1  # 0 = no control, 1 = full control
		target_velocity.x = lerp(target_velocity.x, direction.x * movement_speed, air_control)
		target_velocity.z = lerp(target_velocity.z, direction.z * movement_speed, air_control)
	
	if not is_on_floor():
		target_velocity.y = max(target_velocity.y - (globals.FALL_ACCELLERATION * delta),globals.TERMINAL_VELOCITY)
	elif Input.is_action_just_pressed("3D_player_jump") and is_on_floor():
		target_velocity.y = jump_height
	else:
		target_velocity.y = -0.5 
		
	velocity = target_velocity
	move_and_slide()
	
	#for i in get_slide_collision_count():
		#var collision = get_slide_collision(i)
		#var collider = collision.get_collider()
		#if collider is RigidBody3D:
			#var push_direction = -collision.get_normal()
			#var mass_factor = clamp(1.0/collider.mass,0.05, 2.0)
			#collider.apply_central_impulse(push_direction * velocity.length() * push_force*mass_factor)

#endregion
	
#region force lift
	if Input.is_action_just_pressed("player_force_lift"):
		_try_lift_object()

	if is_holding and held_object:
		_update_held_position()

		if Input.is_action_just_pressed("player_force_throw"):
			_throw_object()
#endregion

func _unhandled_input(event: InputEvent):
#region Player rotation
	if event is InputEventMouseMotion and not lock_rotation:
		var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		rotation.y -= mouse_motion_event.relative.x * rotation_speed
		$Camera3D.rotation.x -= mouse_motion_event.relative.y * rotation_speed
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, PI/-2, PI/2)
#endregion

func _update_state(direction: Vector3):
	var new_state: globals.Player_state = player_state
	
	match player_state:
		globals.Player_state.DEAD:
			return
		_:
			if player_health <= 0:
				new_state = globals.Player_state.DEAD
			elif not is_on_floor():
				if target_velocity.y > 0:
					new_state = globals.Player_state.JUMP
				else:
					new_state = globals.Player_state.FALL
			elif direction.length() > 0 and Input.is_action_pressed("player_sprint"):
				new_state = globals.Player_state.SPRINT
			elif direction.length() > 0:
				new_state = globals.Player_state.RUN
			else:
				new_state = globals.Player_state.IDLE
	if new_state != player_state:
		_change_state(new_state)
		print(player_state)

#implement state-specific logic such as animation players or sounds in this function, called whenever the state changes
func _change_state(new_state):
	# Exit logic for old state
	match player_state:
		globals.Player_state.JUMP:
			pass
		globals.Player_state.FALL:
			pass
	
	player_state = new_state
	
	# Enter logic for new state
	match new_state:
		globals.Player_state.DEAD:
			pass
		globals.Player_state.IDLE:
			pass
		globals.Player_state.RUN:
			pass
		globals.Player_state.JUMP:
			pass
		globals.Player_state.FALL:
			pass
		globals.Player_state.SPRINT:
			pass

func _try_lift_object():
	if not interact_line.is_colliding():
		return
	
	var collider = interact_line.get_collider()
	if collider is RigidBody3D and collider.is_in_group("interactable"):
		held_object = collider
		is_holding = true

		# Disable physics on the object while held
		held_object.freeze = true

		# Tween the object to in front of the camera
		var target_pos = _get_hold_position()

		if hold_tween:
			hold_tween.kill()

		hold_tween = create_tween()
		hold_tween.set_ease(Tween.EASE_OUT)
		hold_tween.set_trans(Tween.TRANS_QUINT)
		hold_tween.tween_property(held_object, "global_position", target_pos, LIFT_DURATION)

func _update_held_position():
	# Smoothly follow the camera hold point each frame after the initial lift
	var target_pos = _get_hold_position()

	if hold_tween and hold_tween.is_running():
		return  # Let the lift tween finish first

	held_object.global_position = lerp(
		held_object.global_position,
		target_pos,
		0.2  # Adjust for tighter or looser tracking
	)

func _throw_object():
	is_holding = false

	# Re-enable physics
	held_object.freeze = false

	var cam_forward = -camera.global_transform.basis.z
	var player_forward = -global_transform.basis.z
	var throw_direction = (cam_forward * 0.75 + player_forward * 0.25).normalized()
	held_object.apply_impulse(throw_direction * throw_force)

	if hold_tween:
		hold_tween.kill()
		hold_tween = null

	held_object = null

func _get_hold_position() -> Vector3:
	return camera.global_position + (-camera.global_transform.basis.z * HOLD_DISTANCE)
