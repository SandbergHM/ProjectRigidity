extends SpellBase

@onready var fireball_scene: PackedScene = preload("res://3d/Spells/incinerate/fireball.tscn")

var ball_speed: float = 20.0
var projectile_lifetime: float = 10.0
var cooldown_active: bool = false

func _ready():
	super() # Call the base class _ready() to initialize cooldown timer
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	
	spell_name = "Incinerate"
	spell_description = "Sets fire to target or launches ball of fire"
	primary_cast_description = "Launches a fireball that explodes on impact"
	secondary_cast_description = "Sets the target on fire, causing damage over time"
	spell_cooldown = 1.0

	
func _try_primary_cast(collider, player: Player):
	if not cooldown_active:
		var camera = player.get_node("Camera3D")
		var fireball = fireball_scene.instantiate()
		
		get_tree().current_scene.add_child(fireball)
		
		fireball.global_transform.basis = camera.global_transform.basis
		fireball.global_transform.origin = camera.global_transform.origin + camera.global_transform.basis.z * -1.5
		fireball.linear_velocity = -camera.global_transform.basis.z * ball_speed
		fireball.blast_damage = spell_damage  # pass damage through
		
		start_cooldown()

	
func _try_secondary_cast(collider, player: Player):
	if not cooldown_active:
		if collider != null:
			if collider.is_in_group("enemies"):
				collider.set_on_fire()
				start_cooldown()


func start_cooldown():
	cooldown_timer.start(spell_cooldown)
	cooldown_active = true

func _on_cooldown_finished():
	cooldown_active = false

func _get_mesh(node) -> MeshInstance3D:
	for child in node.get_children():
			if child is MeshInstance3D:
				return child
	return null
