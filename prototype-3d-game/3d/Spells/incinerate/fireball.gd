extends RigidBody3D

@export var blast_range: float = 3.0
@export var blast_force: float = 10.0

var burning_material := preload("res://3d/materials/shaders/burning.gdshader")
var _blast_query: PhysicsShapeQueryParameters3D
var blast_damage: float = 30.0

@onready var material = $MeshInstance3D

func _ready() -> void:
	#apply burning shader
	material.material_overlay = Shader_registry._get_burning_effect()
	
	var blast_shape = SphereShape3D.new()
	blast_shape.radius = blast_range

	_blast_query = PhysicsShapeQueryParameters3D.new()
	_blast_query.shape = blast_shape


func _on_body_entered(body):
	if body is Player:
		return	

	_blast_query.transform = Transform3D(Basis.IDENTITY, global_position)

	var results = get_world_3d().direct_space_state.intersect_shape(_blast_query)
	for result in results:
		var obj = result.collider
		if obj is Player:
			continue

		var offset = obj.global_position - global_position
		var dist = offset.length()
		var direction = offset.normalized() if dist > 0.01 else Vector3.UP
		var falloff = 1.0 - clamp(dist / blast_range, 0.0, 1.0)

		# Impulse only applies to RigidBodies
		if obj is RigidBody3D:
			obj.apply_impulse(direction * blast_force * falloff)

		# Damage applies to anything with take_damage
		if obj.has_method("take_damage"):
			obj.take_damage(blast_damage * falloff)
		
	queue_free()
