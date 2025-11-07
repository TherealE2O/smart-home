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

# Highlight state
var is_highlighted: bool = false
var highlight_material: StandardMaterial3D = null
var original_materials: Dictionary = {}  # mesh_instance -> original_material

## Lifecycle Methods
func _ready() -> void:
	# Set up input event handling for mouse clicks
	if has_node("CollisionObject"):
		var collision_object = get_node("CollisionObject")
		if collision_object is CollisionObject3D:
			collision_object.input_event.connect(_on_input_event)
	
	# Create highlight material
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(1.0, 0.8, 0.0, 1.0)
	highlight_material.emission_energy_multiplier = 3.0
	
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

func reset_to_default() -> void:
	"""Reset device to default state (override in subclasses for specific defaults)"""
	# Default implementation - subclasses should override
	match device_type:
		"light":
			set_state({"on": false, "brightness": 1.0})
		"door", "window", "blind", "gate", "garage":
			set_state({"open": false})
		"tv", "ac", "heater", "pump", "tap":
			set_state({"on": false})
		"tank":
			set_state({"level": 1.0})

func highlight(enable: bool = true) -> void:
	"""Highlight or unhighlight this device"""
	if enable == is_highlighted:
		return
	
	is_highlighted = enable
	
	if enable:
		_apply_highlight()
	else:
		_remove_highlight()

func _apply_highlight() -> void:
	"""Apply highlight effect to all mesh instances"""
	original_materials.clear()
	
	for child in _get_all_children(self):
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			# Store original material
			var original_mat = mesh_instance.get_surface_override_material(0)
			if original_mat:
				original_materials[mesh_instance] = original_mat
			# Apply highlight material
			mesh_instance.set_surface_override_material(0, highlight_material)

func _remove_highlight() -> void:
	"""Remove highlight effect and restore original materials"""
	for mesh_instance in original_materials.keys():
		if is_instance_valid(mesh_instance):
			var original_mat = original_materials[mesh_instance]
			mesh_instance.set_surface_override_material(0, original_mat)
	
	original_materials.clear()

func _get_all_children(node: Node) -> Array:
	"""Recursively get all children of a node"""
	var children = []
	for child in node.get_children():
		children.append(child)
		children.append_array(_get_all_children(child))
	return children

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
