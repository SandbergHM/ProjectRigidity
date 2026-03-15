extends Node

#region player signals
##Player highlight object in sight, emits the collider of the object in sight, or null if no object in sight
signal player_highlight()
##Control player rotation
signal lock_player_rotation(lock:bool)
#endregion
