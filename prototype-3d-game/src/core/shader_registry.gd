extends Node

var _burning_effect: ShaderMaterial

func _ready() -> void:
	#Burning effect shader
	_burning_effect = ShaderMaterial.new()
	_burning_effect.shader = preload("res://3d/materials/shaders/burning.gdshader").duplicate()
	_burning_effect.set_shader_parameter("noise_tex", preload("res://2d_noise_example.png"))
	_burning_effect.set_shader_parameter("fire_color", globals.COLOR_ORANGE)
	_burning_effect.set_shader_parameter("speed", 1.0)
	_burning_effect.set_shader_parameter("fire_intensity", 7)
	_burning_effect.set_shader_parameter("fresnel_power", 1)
	_burning_effect.set_shader_parameter("distortion_strength", 0.2)
	_burning_effect.set_shader_parameter("noise_scale", 1)

func _get_burning_effect() -> ShaderMaterial:
	return _burning_effect.duplicate()
