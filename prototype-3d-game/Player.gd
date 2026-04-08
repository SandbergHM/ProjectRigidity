extends CharacterBody3D
class_name Player

#region Export Variables

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
## Push force when running into other rigidbodies (push_direction * velocity.length() * push_force * mass_factor)
@export var push_force: float = 5.0
## Object throw force
@export var throw_force: float = 20.0

#endregion

#region Local Variables

var player_state: globals.Player_state = globals.Player_state.IDLE
var target_velocity := Vector3.ZERO
var movement_boost: float = 0.0
var lock_rotation: bool = false
var current_spell: SpellBase = null

#endregion

#region Onreadys

@onready var camera: Camera3D = $Camera3D
@onready var interact_line = $InteractLine
@onready var spell_slot = $SpellSlot

#endregion

const SPELLS := {
	"telekinesis": preload("res://3d/Spells/telekenesis/telekenesis.tscn"),
	"incinerate":  preload("res://3d/Spells/incinerate/incinerate.tscn"),
}

#region Signals

signal physics_frame

#endregion


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	up_direction = Vector3.UP
	signal_bus.lock_player_rotation.connect(_on_lock_player_rotation)
	equip_spell(SPELLS["incinerate"])


func _on_lock_player_rotation(lock: bool) -> void:
	lock_rotation = lock


func _physics_process(delta: float) -> void:
	emit_signal("physics_frame")
	_handle_movement(delta)
	_handle_spellcast(current_spell)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not lock_rotation:
		var mouse_event := event as InputEventMouseMotion
		rotation.y -= mouse_event.relative.x * rotation_speed
		camera.rotation.x -= mouse_event.relative.y * rotation_speed
		camera.rotation.x = clampf(camera.rotation.x, -PI / 2.0, PI / 2.0)


#region Movement

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("player_move_right", "player_move_left", "player_move_back", "player_move_forward")
	var camera_basis := camera.global_transform.basis
	var direction := (-(camera_basis.z * input_dir.y) - (camera_basis.x * input_dir.x))
	direction.y = 0.0
	direction = direction.normalized()

	_update_state(direction)

	var speed := movement_speed + (sprint_speed if Input.is_action_pressed("player_sprint") and is_on_floor() else 0.0)

	if is_on_floor():
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed
		target_velocity.y = jump_height if Input.is_action_just_pressed("3D_player_jump") else -0.5
	else:
		var air_control := 1.0
		target_velocity.x = lerp(target_velocity.x, direction.x * movement_speed, air_control)
		target_velocity.z = lerp(target_velocity.z, direction.z * movement_speed, air_control)
		target_velocity.y = max(target_velocity.y - (globals.FALL_ACCELLERATION * delta), globals.TERMINAL_VELOCITY)

	velocity = target_velocity
	move_and_slide()

#endregion

#region Spellcasting

func _handle_spellcast(spell) -> void:
	var target: Node3D = interact_line.get_collider()
	if Input.is_action_just_pressed("player_primary_cast"):
		spell._try_primary_cast(target, self) 
	if Input.is_action_just_pressed("player_secondary_cast"):
		spell._try_secondary_cast(target, self)

#endregion

#region State Machine

func _update_state(direction: Vector3) -> void:
	if player_state == globals.Player_state.DEAD:
		return

	var new_state: globals.Player_state
	if player_health <= 0:
		new_state = globals.Player_state.DEAD
	elif not is_on_floor():
		new_state = globals.Player_state.JUMP if target_velocity.y > 0 else globals.Player_state.FALL
	elif direction.length() > 0 and Input.is_action_pressed("player_sprint"):
		new_state = globals.Player_state.SPRINT
	elif direction.length() > 0:
		new_state = globals.Player_state.RUN
	else:
		new_state = globals.Player_state.IDLE

	if new_state != player_state:
		_change_state(new_state)
		print(player_state)


# Called whenever state changes — add animation/sound logic here
func _change_state(new_state: globals.Player_state) -> void:
	# Exit logic
	match player_state:
		globals.Player_state.JUMP: pass
		globals.Player_state.FALL: pass

	player_state = new_state

	# Enter logic
	match new_state:
		globals.Player_state.DEAD:   pass
		globals.Player_state.IDLE:   pass
		globals.Player_state.RUN:    pass
		globals.Player_state.JUMP:   pass
		globals.Player_state.FALL:   pass
		globals.Player_state.SPRINT: pass

#endregion

#region Spell Equipping

func equip_spell(spell_scene: PackedScene) -> void:
	if current_spell:
		spell_slot.remove_child(current_spell)
		current_spell.queue_free()
	current_spell = spell_scene.instantiate()
	spell_slot.add_child(current_spell)

#endregion
