class_name SmartDevice
extends Node3D

## Signals
signal state_changed(device_id: String, new_state: Dictionary)
signal interaction_requested(device: SmartDevice)

## Properties
@export var device_id: String = ""
@export var device_name: String = ""
@export var device_type: String = ""
@export var is_interactable: bool = true

var current_state: Dictionary = {}

## Lifecycle Methods
func _ready() -> void:
	# Set up input event handling for mouse clicks
	if has_node("CollisionObject"):
		var collision_object = get_node("CollisionObject")
		if collision_object is CollisionObject3D:
			collision_object.input_event.connect(_on_input_event)
	
	# Register with DeviceRegistry if available
	if DeviceRegistry:
		DeviceRegistry.register_device(self)

func _exit_tree() -> void:
	# Unregister from DeviceRegistry
	if DeviceRegistry and device_id != "":
		DeviceRegistry.unregister_device(device_id)

## Public Methods
func set_state(new_state: Dictionary) -> void:
	"""Update device state and emit signal"""
	var old_state = current_state.duplicate()
	
	# Merge new state with current state
	for key in new_state:
		current_state[key] = new_state[key]
	
	# Apply the state change (override in subclasses)
	_apply_state_change(old_state, current_state)
	
	# Emit signal
	state_changed.emit(device_id, current_state)

func get_state() -> Dictionary:
	"""Return current device state"""
	return current_state.duplicate()

func toggle() -> void:
	"""Toggle device on/off state (override in subclasses for specific behavior)"""
	if current_state.has("on"):
		set_state({"on": not current_state["on"]})

## Protected Methods (override in subclasses)
func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	"""Override this method in subclasses to apply visual/functional changes"""
	pass

## Input Handling
func _on_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	"""Handle mouse click events on the device"""
	if not is_interactable:
		return
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			interaction_requested.emit(self)
