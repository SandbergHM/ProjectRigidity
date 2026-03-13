extends Node
class_name globals

const FALL_ACCELLERATION = 9.8
const TERMINAL_VELOCITY = -50.0


static func item_highlight(mesh_instance: MeshInstance3D, brightness: float = 0.2) -> MeshInstance3D:
	var overlay = StandardMaterial3D.new()
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay.albedo_color = Color(brightness, brightness, brightness, 0.7)
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	overlay.cull_mode = BaseMaterial3D.CULL_BACK
	overlay.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	var mat = mesh_instance.get_active_material(0)
	if mat:
		var mat_copy = mat.duplicate()
		mat_copy.next_pass = overlay
		mesh_instance.set_surface_override_material(0, mat_copy)

	else:
		mesh_instance.set_surface_override_material(0, overlay)
	return mesh_instance

static func remove_item_highlight(mesh_instance: MeshInstance3D) -> MeshInstance3D:
	var mat = mesh_instance.get_active_material(0)
	if mat:
		mat.next_pass = null
	return mesh_instance
