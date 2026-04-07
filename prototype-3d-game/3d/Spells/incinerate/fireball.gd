extends RigidBody3D

var burning_material := preload("res://3d/materials/shaders/burning.gdshader")

@onready var material = $MeshInstance3D

func _ready() -> void:
	#apply burning shader
	var shader_material := ShaderMaterial.new()
	shader_material.shader = burning_material
	shader_material.set_shader_parameter("noise_tex", preload("res://2d_noise_example.png"))
	shader_material.set_shader_parameter("fire_color", globals.COLOR_ORANGE)
	shader_material.set_shader_parameter("speed", 1.0)
	shader_material.set_shader_parameter("fire_intensity", 7)
	shader_material.set_shader_parameter("fresnel_power", 1)
	shader_material.set_shader_parameter("distortion_strength", 0.2)
	shader_material.set_shader_parameter("noise_scale", 1)
	material.material_overlay = shader_material
