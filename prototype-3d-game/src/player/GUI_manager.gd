extends Node

@onready var health_text = $HealthText
@onready var SpellText = $SpellText
@onready var player = $".."

func _ready() -> void:
	health_text.text = "Health: " + str(player.player_health)
	player.spell_changed.connect(_on_spell_changed)
	_update_player_spell()

func _process(_delta: float) -> void:
	_update_player_health()

func _update_player_health() -> void:
	health_text.text = "Health: " + str(player.player_health)

func _update_player_spell() -> void:
	if player.current_spell == null:
		SpellText.text = "Spell: None"
	else:
		SpellText.text = "Spell: " + player.current_spell.spell_name

func _on_spell_changed(spell: SpellBase) -> void:
	if spell == null:
		SpellText.text = "Spell: None"
	else:
		SpellText.text = "Spell: " + spell.spell_name
