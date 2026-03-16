class_name Inventory
extends Node

var slots : Array[Inventory_slot]
@onready var window : Panel = get_node("InventoryUI")
@onready var info_text : Label = get_node("InventoryUI/InfoText")

@export var starter_items : Array[Item]

func _ready():
	toggle_window(false)
	
	signal_bus.on_give_player_item.connect(on_give_player_item)
	
	for child in get_node("InventoryUI/SlotContainer").get_children():
		slots.append(child)
		child.set_item(null)
		child.inventory = self
	
	for item in starter_items:
		add_item(item)
	
func _process (delta):
	if Input.is_action_just_pressed("open_inventory"):
		toggle_window(!window.visible)
	

	
func toggle_window (open:bool):
	window.visible = open
	
	#Configure mouse and player rotation during inventory management
	if open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		signal_bus.lock_player_rotation.emit(true)
	else:		
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		signal_bus.lock_player_rotation.emit(false)

func on_give_player_item (item: Item, amount : int):
	for i in range(amount):
		add_item(item)
	
func add_item (item:Item):
	var slot = get_slot_to_add(item)
	
	if slot == null:
		return
	
	if slot.item == null:
		slot.set_item(item)
	else:
		slot.add_item()
		
func remove_item(item:Item):
	var slot = get_slot_to_remove(item)
	
	if slot == null or slot.item == null:
		return
	
	slot.remove_item()

func get_slot_to_add(item:Item) -> Inventory_slot:
	for slot in slots:
		if slot.item == item and slot.item_quantity < item.max_stack_size:
			return slot
		
	for slot in slots:
		if slot.item == null:
			return slot
	
	return null

func get_slot_to_remove(item:Item) -> Inventory_slot:
	for slot in slots:
		if slot.item == item:
			return slot
	
	return null
	
func get_number_of_item(item:Item):
	var total = 0
	
	for slot in slots:
		if slot.item == item:
			total += slot.quantity
	
	return total
