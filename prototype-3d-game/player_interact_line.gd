extends RayCast3D

@onready var interact_prompt_label : Label = get_node("InteractionPrompt")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enabled = true

func _process(delta):
	var object = get_collider()
	interact_prompt_label.text = ""
	
	if object and object is InteractableObject:
		if object.can_interact == false:
			return
		
		interact_prompt_label.text = "[E] " + object.interact_prompt
		
		if Input.is_action_just_pressed("interact"):
			object._interact()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var parent_transform = get_parent().global_transform
	global_transform.basis = $"../Camera3D".global_transform.basis

	if is_colliding():
		var collider = get_collider()
		if collider != null and collider.is_in_group("interactable"):
			signal_bus.player_highlight.emit(collider)
		else:
			signal_bus.player_highlight.emit(null)
	else:
		signal_bus.player_highlight.emit(null)
