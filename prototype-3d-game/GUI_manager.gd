extends Node

@onready var health_text = $HealthText
@onready var SpellText = $SpellText
@onready var player = $".."

func _ready() -> void:
	print(player.current_spell)
	health_text.text = "Health: " + str(player.player_health)

func _process(delta: float) -> void:
	_update_player_health()

func _update_player_health():
	health_text.text = "Health: " + str(player.player_health)
	
func _update_player_spell():
	if player.current_spell == null:
		SpellText.text = "Spell: None"
	else:
		SpellText.text = "Spell: " + player.current_spell.spell_name
