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
		_current_highlight_target.get_surface_override_material(0).next_pass = null
	_current_highlight_target = null


func _apply_highlight(mesh: MeshInstance3D, collider: PhysicsBody3D) -> void:
	var base_material: StandardMaterial3D
	var active_material := mesh.get_active_material(0)

	if active_material == null:
		base_material = StandardMaterial3D.new()
	else:
		base_material = active_material.duplicate()

	var shader_material := ShaderMaterial.new()
	shader_material.shader = HIGHLIGHT_SHADER
	shader_material.set_shader_parameter("outline_color", _get_highlight_color(collider))

	base_material.next_pass = shader_material
	mesh.set_surface_override_material(0, base_material)
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
