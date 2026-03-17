# weapon_data.gd
class_name WeaponData extends Resource

@export var name: String
@export var scene: PackedScene

# Shared combat stats
@export var damage: float
@export var attack_speed: float      # attacks per second

# Ranged only
@export var ammo_max: int
@export var is_automatic: bool
@export var projectile_scene: PackedScene

# Melee only
@export var reach: float = 2.0       # raycast length
@export var combo_window: float = 0.5 # time to chain next hit
@export var heavy_damage_mult: float = 2.0
