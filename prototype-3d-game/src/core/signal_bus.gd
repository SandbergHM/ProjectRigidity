extends Node

#region player signals
##Player highlight object in sight, emits the collider of the object in sight, or null if no object in sight
signal player_highlight()
##Control player rotation
signal lock_player_rotation(lock:bool)
##Grant player an item from anywhere
signal on_give_player_item (item:Item, amount:int)
##Player has dealt damage
signal damage_dealt(amount: float, position: Vector3)
##Enemy HP dropped below 25% threshold
signal enemy_low_health(enemy: Node3D, health_pct: float)
##True while the player is holding an object with telekinesis
var is_player_holding: bool = false
#endregion
