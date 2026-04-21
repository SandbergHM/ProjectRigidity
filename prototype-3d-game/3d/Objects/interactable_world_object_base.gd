extends RigidBody3D

enum DestructionType { COLLAPSE, EXPLOSION }

@export var health: float = 1.0
@export var destructible: bool = true
@export var destruction_type: DestructionType = DestructionType.COLLAPSE
@export var explosion_radius: float = 5.0
@export var damage_cooldown_duration: float = 0.2

signal destroyed

var _is_damage_cooldown_active: bool = false

@onready var _damage_cooldown_timer: Timer = $DamageCooldownTimer

func _ready() -> void:
	collision_layer = 15
	collision_mask = 15
	var timer := Timer.new()
	timer.name = "DamageCooldownTimer"
	timer.one_shot = true
	timer.timeout.connect(_on_damage_cooldown_timeout)
	add_child(timer)

func take_damage(amount: float) -> void:
	if not destructible or _is_damage_cooldown_active:
		return
	health -= amount
	_is_damage_cooldown_active = true
	_damage_cooldown_timer.start(damage_cooldown_duration)
	signal_bus.damage_dealt.emit(amount, global_position)
	if health <= 0.0:
		destroy()

func destroy() -> void:
	match destruction_type:
		DestructionType.COLLAPSE:
			collapse()
		DestructionType.EXPLOSION:
			explode()
	destroyed.emit()
	queue_free()

func explode() -> void:
	pass

func collapse() -> void:
	var scene_path := scene_file_path.get_basename() + "_shattered.tscn"
	if ResourceLoader.exists(scene_path):
		var shattered := load(scene_path) as PackedScene
		if shattered:
			var instance := shattered.instantiate()
			get_parent().add_child(instance)
			instance.global_transform = global_transform
	else:
		push_warning("No shattered variant found for: " + scene_file_path)

func _on_damage_cooldown_timeout() -> void:
	_is_damage_cooldown_active = false
