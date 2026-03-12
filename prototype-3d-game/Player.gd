extends CharacterBody3D

@export var movement_speed: float = 10
@export var fall_acceleration: float = 9.8
@export var terminal_velocity: float = -50.0
@export var jump_height: float = 5
@export var rotation_speed: float = 0.002

var target_velocity = Vector3.ZERO

@onready var mannequin: AnimationPlayer = $Mannequin/AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
#region player movement
	var direction = Vector3.ZERO
	var input_dir = Input.get_vector("player_move_right", "player_move_left", "player_move_back", "player_move_forward")
	var camera_basis = $Camera3D.global_transform.basis
	
	# Calculate movement relative to camera direction, ignoring the camera's tilt (vertical angle)
	direction = -(camera_basis.z * input_dir.y) - (camera_basis.x * input_dir.x)
	direction.y = 0 # Prevent flying
	direction = direction.normalized()
	
	
	# Ground Velocity
	target_velocity.x = direction.x * (movement_speed)
	target_velocity.z = direction.z * (movement_speed)
	
	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor
		target_velocity.y = max(target_velocity.y - (fall_acceleration * delta),terminal_velocity)
	elif Input.is_action_just_pressed("3D_player_jump") and is_on_floor():
		target_velocity.y = jump_height
		was_on_floor = false
	else:
		target_velocity.y = 0 
		
	# Moving the Character
	velocity = target_velocity
	move_and_slide()	
	animation_player()
#endregion


func _unhandled_input(event: InputEvent):
#region Player rotation
	if event is InputEventMouseMotion:
		var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		rotation.y -= mouse_motion_event.relative.x * rotation_speed
		$Camera3D.rotation.x -= mouse_motion_event.relative.y * rotation_speed
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, PI/-2, PI/2)
#endregion

var was_on_floor : bool = false

func animation_player():
	if is_on_floor() and not was_on_floor: #Landing animation
		mannequin.stop()
		mannequin.play("air_land")
		was_on_floor = true
	elif velocity != null and is_on_floor() and not mannequin.current_animation == "air_land": #Run/idle animation
		if velocity.x != 0 or velocity.y != 0:
			mannequin.play("run")
		else:
			mannequin.play("idle")
	elif Input.is_action_just_pressed("3D_player_jump") and is_on_floor(): #Jump animation
		mannequin.stop()
		mannequin.play("air_jump")

	print(mannequin.assigned_animation)
