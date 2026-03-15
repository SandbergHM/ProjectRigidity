extends CharacterBody3D
class_name Player
#region export variables

@export var movement_speed: float = 10
@export var jump_height: float = 5
@export var rotation_speed: float = 0.002
@export var sprint_speed: float = 5


#endregion

#region local variables

var target_velocity = Vector3.ZERO
var movement_boost: float = 0
var collider = null
var lock_rotation: bool = false

#endregion

#region onreadys

@onready var interact_line = $InteractLine
@onready var camera = $Camera3D

#endregion

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	up_direction = Vector3.UP
	signal_bus.lock_player_rotation.connect(_on_lock_player_rotation)
	

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
	
	if(Input.is_action_pressed("player_sprint")):
		movement_boost = sprint_speed
	else:
		movement_boost = 0
	
	# Ground Velocity
	target_velocity.x = direction.x * (movement_speed + movement_boost)
	target_velocity.z = direction.z * (movement_speed + movement_boost)
	
	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor
		target_velocity.y = max(target_velocity.y - (globals.FALL_ACCELLERATION * delta),globals.TERMINAL_VELOCITY)
	elif Input.is_action_just_pressed("3D_player_jump") and is_on_floor():
		target_velocity.y = jump_height
	else:
		target_velocity.y = 0 
		
	# Moving the Character
	velocity = target_velocity
	#animation_player()
	move_and_slide()	

#endregion

#region object highlight
	#Highlight objects
	interact_line.global_transform.basis = $Camera3D.global_transform.basis
	if interact_line.is_colliding():
		collider = interact_line.get_collider()
		if collider != null and collider.is_in_group("interactable"):
			signal_bus.player_highlight.emit(collider)
		else:
			signal_bus.player_highlight.emit(null)
	else:
		signal_bus.player_highlight.emit(null)
	
#endregion

func _unhandled_input(event: InputEvent):
#region Player rotation
	if event is InputEventMouseMotion and not lock_rotation:
		var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		rotation.y -= mouse_motion_event.relative.x * rotation_speed
		$Camera3D.rotation.x -= mouse_motion_event.relative.y * rotation_speed
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, PI/-2, PI/2)
#endregion
