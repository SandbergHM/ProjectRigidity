extends RayCast3D

var current_target: MeshInstance3D = null
var highlight_material := preload("res://3d/materials/shaders/highlight.gdshader")

@onready var interact_prompt_label : Label = get_node("InteractionPrompt")

func _ready() -> void:
	enabled = true

func _process(delta):
	var collider = get_collider()
	interact_prompt_label.text = ""
	if collider and collider is InteractableObject:
		if collider.can_interact == false:
			return
		
		interact_prompt_label.text = "[E] " + collider.interact_prompt
		
		if Input.is_action_just_pressed("interact"):
			collider._interact()


func _physics_process(delta: float) -> void:
	#Rotate with player camera
	global_transform.basis = $"../Camera3D".global_transform.basis
	
	#region item higlight
	var collider := get_collider()
	var collider_mesh: MeshInstance3D = null
	
	#Retrieve meshinstance for object if it is interactable, otherwise return
	if collider is PhysicsBody3D and collider.is_in_group("interactable"):
		collider_mesh = get_mesh(collider)

	if collider_mesh == current_target:
		return

	if is_instance_valid(current_target):
		current_target.get_surface_override_material(0).next_pass = null
		current_target = null

	if collider_mesh != null:
		var original_material := collider_mesh.get_active_material(0)
		var new_material: StandardMaterial3D
		
		# In case of no active material, create a new one for shader application
		if original_material == null:
			new_material = StandardMaterial3D.new()
		else:
			new_material = original_material.duplicate()
		
		# Assign shader and apply correct highlight color based on object group
		var shader_material := ShaderMaterial.new()
		shader_material.shader = highlight_material
		shader_material.set_shader_parameter("outline_color", get_highlight_color(collider))
		
		new_material.next_pass = shader_material
		collider_mesh.set_surface_override_material(0, new_material)
	
		current_target = collider_mesh
	#endregion
	



#Only works if only one meshinstance is applied to object, structure for specific mesh names can be added if needed
func get_mesh(body: PhysicsBody3D) -> MeshInstance3D:
	for child in body.get_children():
		if child is MeshInstance3D:
			return child
	return null

#Consider adding to globals for general higlight color management
func get_highlight_color(body: PhysicsBody3D) -> Color:
	if body.is_in_group("enemy"):
		return globals.COLOR_RED
	elif body.is_in_group("friendly") or body.is_in_group("world_item"):
		return globals.COLOR_GREEN
	elif body.is_in_group("neutral"):
		return globals.COLOR_BLUE
	else:
		return globals.COLOR_WHITE
