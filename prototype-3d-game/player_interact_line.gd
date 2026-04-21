extends RayCast3D

const HIGHLIGHT_SHADER := preload("res://3d/materials/shaders/highlight.gdshader")

var _current_highlight_target: MeshInstance3D = null
var _current_collider: Node


func _ready() -> void:
	enabled = true


func _process(_delta: float):
	pass


func _physics_process(_delta: float) -> void:
	global_transform.basis = $"../Camera3D".global_transform.basis
	_current_collider = get_collider()
	if signal_bus.is_player_holding:
		_clear_highlight()
		return
	_update_highlight(_current_collider)


func _update_highlight(collider: Object) -> void:
	var target_mesh: MeshInstance3D = null

	if collider is PhysicsBody3D and collider.is_in_group("interactable"):
		target_mesh = _get_mesh(collider)

	if target_mesh == _current_highlight_target:
		return

	_clear_highlight()

	if target_mesh != null:
		_apply_highlight(target_mesh, collider)


func _clear_highlight() -> void:
	if is_instance_valid(_current_highlight_target):
		# Walk to the end of the next_pass chain and remove the outline pass
		var mat := _current_highlight_target.get_active_material(0)
		while mat != null:
			if mat.next_pass != null and mat.next_pass.get("shader") != null \
					and (mat.next_pass as ShaderMaterial).shader == HIGHLIGHT_SHADER:
				mat.next_pass = null
				break
			mat = mat.next_pass
	_current_highlight_target = null


func _apply_highlight(mesh: MeshInstance3D, collider: PhysicsBody3D) -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = HIGHLIGHT_SHADER
	shader_material.set_shader_parameter("outline_color", _get_highlight_color(collider))

	# Append to the end of the next_pass chain so we don't stomp the hit flash pass
	var mat := mesh.get_active_material(0)
	if mat == null:
		var base := StandardMaterial3D.new()
		base.next_pass = shader_material
		mesh.set_surface_override_material(0, base)
	else:
		while mat.next_pass != null:
			mat = mat.next_pass
		mat.next_pass = shader_material

	_current_highlight_target = mesh


## Returns the first MeshInstance3D child of a body.
## Note: only works when a single mesh is present on the object.
func _get_mesh(body: PhysicsBody3D) -> MeshInstance3D:
	for child in body.get_children():
		if child is MeshInstance3D:
			return child
	return null


## Returns a highlight color based on the object's group membership.
## Consider centralizing this in a globals/highlight manager if reused elsewhere.
func _get_highlight_color(body: PhysicsBody3D) -> Color:
	if body.is_in_group("enemies"):
		return globals.COLOR_RED
	if body.is_in_group("friendly") or body.is_in_group("world_item"):
		return globals.COLOR_GREEN
	if body.is_in_group("neutral"):
		return globals.COLOR_BLUE
	return globals.COLOR_WHITE
