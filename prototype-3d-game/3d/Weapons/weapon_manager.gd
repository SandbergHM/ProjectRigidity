# weapon_manager.gd
class_name WeaponManager extends Node

@export var weapon_holder: Node3D
@export var weapons: Array[WeaponData] = []

var current_index := 0
var current_weapon: WeaponBase

func _ready() -> void:
	equip(0)

func _input(event: InputEvent) -> void:
	match current_weapon.get_type():
		WeaponBase.WeaponType.RANGED:
			if event.is_action_pressed("fire") or \
			  (event.is_action("fire") and current_weapon.data.is_automatic):
				current_weapon.try_attack()
			if event.is_action_pressed("reload"):
				current_weapon.reload()

		WeaponBase.WeaponType.MELEE:
			if event.is_action_pressed("fire"):
				current_weapon.try_attack()           # light
			if event.is_action_pressed("alt_fire"):
				current_weapon.try_heavy_attack()     # heavy

	if event.is_action_pressed("next_weapon"):
		equip((current_index + 1) % weapons.size())

func equip(index: int) -> void:
	if current_weapon:
		current_weapon.queue_free()
	current_index = index
	current_weapon = weapons[index].scene.instantiate()
	current_weapon.data = weapons[index]
	weapon_holder.add_child(current_weapon)
