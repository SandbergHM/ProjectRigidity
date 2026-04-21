class_name StatusEffectComponent
extends Node

signal effect_applied(effect: StatusEffect)
signal effect_removed(effect: StatusEffect)

var _active: Dictionary = {}

func _process(delta: float) -> void:
	for key in _active.keys():
		var entry = _active[key]
		entry["tick_acc"] += delta
		entry["remaining"] -= delta

		if entry["tick_acc"] >= entry["effect"].tick_interval:
			entry["tick_acc"] -= entry["effect"].tick_interval
			entry["effect"].on_tick(get_parent())

		if entry["remaining"] <= 0.0:
			_remove_effect(key)

func apply(effect: StatusEffect, instigator: Node = null) -> void:
	var key = effect.effect_name
	if _active.has(key):
		_active[key]["effect"].on_refresh(get_parent())
		_active[key]["remaining"] = _active[key]["effect"].duration
		return

	# Re-instantiate from the same script instead of duplicate()
	var instance: StatusEffect = effect.get_script().new()
	# Forward instigator if the effect supports it
	if instigator != null and "instigator" in instance:
		instance.instigator = instigator
	instance.on_apply(get_parent())
	_active[key] = {
		"effect": instance,
		"remaining": instance.duration,
		"tick_acc": 0.0
	}
	effect_applied.emit(instance)

func remove(effect_name: String) -> void:
	_remove_effect(effect_name)

func has_effect(effect_name: String) -> bool:
	return _active.has(effect_name)

func _remove_effect(key: String) -> void:
	if not _active.has(key):
		return
	var entry = _active[key]
	entry["effect"].on_remove(get_parent())
	effect_removed.emit(entry["effect"])
	_active.erase(key)
