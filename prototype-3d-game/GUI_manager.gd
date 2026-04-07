extends Node

@onready var health_text = $HealthText
@onready var player = $".."

func _ready() -> void:
	health_text.text = "Health: " + str(player.player_health)

func _process(delta: float) -> void:
	_update_player_health()

func _update_player_health():
	health_text.text = "Health: " + str(player.player_health)
