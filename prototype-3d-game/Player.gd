extends CharacterBody3D
class_name Player

# =============================================================================
# EXPORT VARIABLES
# =============================================================================

## Player health
@export var player_health: float = 100.0
## Player movement speed
@export var movement_speed: float = 10.0
## Player jump height force
@export var jump_height: float = 5.0
## Mouse rotation sensitivity — lower value = faster turning
@export var rotation_speed: float = 0.002
## Extra speed added when sprinting
@export var sprint_speed: float = 5.0
## Push force when colliding with RigidBodies (velocity.length * push_force * mass_factor)
@export var push_force: float = 5.0
## Force applied when throwing an object
@export var throw_force: float = 20.0

# =============================================================================
# STATE & RUNTIME VARIABLES
# =============================================================================

var player_state: globals.Player_state = globals.Player_state.IDLE
var target_velocity := Vector3.ZERO
var movement_boost: float = 0.0
var lock_rotation: bool = false
var current_spell: SpellBase = null
var _current_spell_index: int = 0

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var camera: Camera3D = $Camera3D
@onready var interact_line = $InteractLine
@onready var spell_slot = $SpellSlot
@onready var GUI_manager = $GUI

# =============================================================================
# CONSTANTS
# =============================================================================

const SPELLS := {
	"telekinesis": preload("res://3d/Spells/telekenesis/telekenesis.tscn"),
	"incinerate":  preload("res://3d/Spells/incinerate/incinerate.tscn"),
}

const SPELL_ORDER := ["incinerate", "telekinesis"]

# =============================================================================
# SIGNALS
# =============================================================================

signal physics_frame

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	up_direction = Vector3.UP
	signal_bus.lock_player_rotation.connect(_on_lock_player_rotation)
	_equip_first_unlocked_spell()
	GUI_manager._update_player_spell()


func _equip_first_unlocked_spell() -> void:
	for i in SPELL_ORDER.size():
		if _is_spell_unlocked(i):
			_current_spell_index = i
			equip_spell(SPELLS[SPELL_ORDER[i]])
			return
	push_warning("Player: No unlocked spells found on ready.")


func _physics_process(delta: float) -> void:
	emit_signal("physics_frame")
	_handle_movement(delta)
	_handle_spellcast(current_spell)


func _unhandled_input(event: InputEvent) -> void:
	_handle_mouse_look(event)
	_handle_spell_switch(event)

# =============================================================================
# INPUT HANDLERS
# =============================================================================

func _handle_mouse_look(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion) or lock_rotation:
		return
	var mouse_event := event as InputEventMouseMotion
	rotation.y -= mouse_event.relative.x * rotation_speed
	camera.rotation.x -= mouse_event.relative.y * rotation_speed
	camera.rotation.x = clampf(camera.rotation.x, -PI / 2.0, PI / 2.0)


func _handle_spell_switch(event: InputEvent) -> void:
	# Scroll wheel cycling
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_spell(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_spell(1)

	# Number key direct selection
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: _select_spell(0)
			KEY_2: _select_spell(1)

# =============================================================================
# MOVEMENT
# =============================================================================

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector(
		"player_move_right", "player_move_left",
		"player_move_back", "player_move_forward"
	)

	# Compute camera-relative horizontal direction
	var camera_basis := camera.global_transform.basis
	var direction := (-(camera_basis.z * input_dir.y) - (camera_basis.x * input_dir.x))
	direction.y = 0.0
	direction = direction.normalized()

	_update_state(direction)

	var is_sprinting := Input.is_action_pressed("player_sprint") and is_on_floor()
	var speed := movement_speed + (sprint_speed if is_sprinting else 0.0)

	if is_on_floor():
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed
		target_velocity.y = jump_height if Input.is_action_just_pressed("3D_player_jump") else -0.5
	else:
		# Air movement: full air control, gravity applied manually
		target_velocity.x = lerp(target_velocity.x, direction.x * movement_speed, 1.0)
		target_velocity.z = lerp(target_velocity.z, direction.z * movement_speed, 1.0)
		target_velocity.y = max(
			target_velocity.y - (globals.FALL_ACCELLERATION * delta),
			globals.TERMINAL_VELOCITY
		)

	velocity = target_velocity
	move_and_slide()

# =============================================================================
# SPELLCASTING
# =============================================================================

func _handle_spellcast(spell: SpellBase) -> void:
	if spell == null:
		return
	var target: Node3D = interact_line.get_collider()
	if Input.is_action_just_pressed("player_primary_cast"):
		spell._try_primary_cast(target, self)
	if Input.is_action_just_pressed("player_secondary_cast"):
		spell._try_secondary_cast(target, self)

# =============================================================================
# STATE MACHINE
# =============================================================================

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


## Called whenever state changes — add animation/sound logic here.
func _change_state(new_state: globals.Player_state) -> void:
	# Exit logic for current state
	match player_state:
		globals.Player_state.JUMP: pass
		globals.Player_state.FALL: pass

	player_state = new_state

	# Enter logic for new state
	match new_state:
		globals.Player_state.DEAD:   pass
		globals.Player_state.IDLE:   pass
		globals.Player_state.RUN:    pass
		globals.Player_state.JUMP:   pass
		globals.Player_state.FALL:   pass
		globals.Player_state.SPRINT: pass

# =============================================================================
# SPELL EQUIPPING
# =============================================================================

func equip_spell(spell_scene: PackedScene) -> void:
	if current_spell:
		current_spell.on_unequip()
		spell_slot.remove_child(current_spell)
		current_spell.queue_free()
	current_spell = spell_scene.instantiate()
	spell_slot.add_child(current_spell)


func _is_spell_unlocked(index: int) -> bool:
	var key: String = SPELL_ORDER[index]
	var scene: PackedScene = SPELLS[key]
	var instance := scene.instantiate() as SpellBase
	var unlocked := instance.spell_unlocked
	instance.free()
	return unlocked


func _cycle_spell(direction: int) -> void:
	# Walk in the given direction, skipping locked spells
	var total := SPELL_ORDER.size()
	var next := (_current_spell_index + direction) % total
	for i in total:
		if _is_spell_unlocked(next):
			_select_spell(next)
			return
		next = (next + direction) % total
	# No unlocked spell found — stay on current


func _select_spell(index: int) -> void:
	if index == _current_spell_index and current_spell != null:
		return
	if index < 0 or index >= SPELL_ORDER.size():
		return
	if not _is_spell_unlocked(index):
		print("Spell locked: ", SPELL_ORDER[index])
		return
	_current_spell_index = index
	var key: String = SPELL_ORDER[index]
	equip_spell(SPELLS[key])
	print("Equipped: ", key)
	GUI_manager._update_player_spell()

# =============================================================================
# SIGNAL CALLBACKS
# =============================================================================

func _on_lock_player_rotation(lock: bool) -> void:
	lock_rotation = lock
