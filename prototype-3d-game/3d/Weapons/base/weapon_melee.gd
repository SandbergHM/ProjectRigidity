# weapon_melee.gd
class_name WeaponMelee extends WeaponBase

# Combo state
var combo_step := 0
var max_combo := 3
var can_attack := true
var combo_timer: SceneTreeTimer

# Hitbox — activated during attack window only
@onready var hitbox: Area3D = $Hitbox
@onready var hitbox_shape: CollisionShape3D = $Hitbox/CollisionShape3D

func get_type() -> WeaponType:
	return WeaponType.MELEE

func _ready() -> void:
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hit)

func try_attack() -> void:
	if not can_attack:
		return
	_light_attack()

func try_heavy_attack() -> void:
	if not can_attack:
		return
	_heavy_attack()

# --- Light attack (combo chain) ---

func _light_attack() -> void:
	can_attack = false
	emit_signal("attack_started")

	var anim = "attack_%d" % (combo_step + 1)   # attack_1, attack_2, attack_3
	anim_player.play(anim)

	# Open hitbox mid-swing (sync these to your actual animation)
	await get_tree().create_timer(0.1).timeout
	_enable_hitbox()
	await get_tree().create_timer(0.15).timeout
	_disable_hitbox()

	await get_tree().create_timer(1.0 / data.attack_speed).timeout

	can_attack = true
	emit_signal("attack_finished")

	# Advance combo, reset if window expires
	combo_step = (combo_step + 1) % max_combo
	if combo_timer:
		combo_timer.timeout.disconnect(_reset_combo)
	combo_timer = get_tree().create_timer(data.combo_window)
	combo_timer.timeout.connect(_reset_combo)

# --- Heavy attack (interrupts combo) ---

func _heavy_attack() -> void:
	_reset_combo()
	can_attack = false
	anim_player.play("attack_heavy")

	await get_tree().create_timer(0.2).timeout
	_enable_hitbox(true)
	await get_tree().create_timer(0.25).timeout
	_disable_hitbox()

	await get_tree().create_timer(1.5 / data.attack_speed).timeout
	can_attack = true

# --- Hit detection ---

func _enable_hitbox(is_heavy: bool = false) -> void:
	hitbox.set_meta("is_heavy", is_heavy)
	hitbox.monitoring = true

func _disable_hitbox() -> void:
	hitbox.monitoring = false

func _on_hit(body: Node3D) -> void:
	if not body.has_method("take_damage"):
		return
	var is_heavy: bool = hitbox.get_meta("is_heavy", false)
	var dmg = data.damage * (data.heavy_damage_mult if is_heavy else 1.0)
	body.take_damage(dmg)

func _reset_combo() -> void:
	combo_step = 0
