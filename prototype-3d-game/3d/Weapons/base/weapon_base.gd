# weapon_base.gd
class_name WeaponBase extends Node3D

enum WeaponType { RANGED, MELEE }

@export var data: WeaponData

@onready var anim_player: AnimationPlayer = $AnimationPlayer

signal attack_started
signal attack_finished

func get_type() -> WeaponType:
	return WeaponType.MELEE  # overridden in WeaponRanged

func try_attack() -> void:
	pass  # implemented by subclasses

func equip() -> void:
	anim_player.play("equip")

func unequip() -> void:
	anim_player.play("unequip")
	await anim_player.animation_finished
