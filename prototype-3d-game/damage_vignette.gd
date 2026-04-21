extends ColorRect

## Peak intensity reached at the start of the flash (0–1)
@export var flash_intensity: float = 0.25
## How long the flash takes to fade out, in seconds
@export var fade_duration: float = 0.3
## Easing curve for the fade — EASE_IN makes it snap on and ease off
@export var fade_ease: Tween.EaseType = Tween.EASE_IN

var _material: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	_material = material as ShaderMaterial
	# Start fully invisible
	_material.set_shader_parameter("intensity", 0.0)

	# Connect to the player's damage signal once the scene is ready
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.took_damage.connect(_on_player_took_damage)
	else:
		push_warning("DamageVignette: no node in group 'player' found.")


func flash() -> void:
	if _tween:
		_tween.kill()
	_material.set_shader_parameter("intensity", flash_intensity)
	_tween = create_tween()
	_tween.set_ease(fade_ease)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_method(
		func(v: float) -> void: _material.set_shader_parameter("intensity", v),
		flash_intensity,
		0.0,
		fade_duration
	)


func _on_player_took_damage(_amount: float, _source: Node) -> void:
	flash()
