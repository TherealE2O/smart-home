extends Node
## DeviceRegistry singleton for managing smart home devices
## Handles device registration, state management, and device queries

signal device_registered(device_id: String)
signal device_unregistered(device_id: String)
signal device_state_changed(device_id: String, property: String, value: Variant)

## Device data structure
class Device:
	var id: String
	var type: String  # "light", "thermostat", "lock", "camera", "sensor"
	var name: String
	var room: String
	var state: Dictionary = {}
	var node_reference: Node = null
	
	func _init(p_id: String, p_type: String, p_name: String, p_room: String) -> void:
		id = p_id
		type = p_type
		name = p_name
		room = p_room

# Dictionary to store all devices by ID
var devices: Dictionary = {}

# Dictionary to organize devices by room
var devices_by_room: Dictionary = {}

# Dictionary to organize devices by type
var devices_by_type: Dictionary = {}

var _auto_save_timer: Timer = null
var _pending_save: bool = false

func _ready() -> void:
	# Set up auto-save timer (save device states every 30 seconds if changes occurred)
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = 30.0
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(_auto_save_timer)
	_auto_save_timer.start()
	
	# Connect to device state changes
	device_state_changed.connect(_on_device_state_changed_internal)

func _on_device_state_changed_internal(_device_id: String, _property: String, _value: Variant) -> void:
	"""Mark that we have pending changes to save"""
	_pending_save = true

func _on_auto_save_timeout() -> void:
	"""Auto-save device states if there are pending changes"""
	if _pending_save and AutomationEngine:
		AutomationEngine.save_device_states()
		_pending_save = false

## Register a new device (supports both SmartDevice nodes and manual registration)
func register_device(device_id_or_node, device_type: String = "", device_name: String = "", room: String = "", initial_state: Dictionary = {}):
	# Handle SmartDevice node registration
	if device_id_or_node is Node:
		var smart_device = device_id_or_node
		var device_id = smart_device.device_id
		var device_type_val = smart_device.device_type if smart_device.device_type != "" else "unknown"
		var device_name_val = smart_device.device_name if smart_device.device_name != "" else device_id
		var room_val = "unknown"  # Could be extracted from scene hierarchy if needed
		
		if devices.has(device_id):
			push_warning("Device %s already registered, updating reference" % device_id)
			devices[device_id].node_reference = smart_device
			return devices[device_id]
		
		var device = Device.new(device_id, device_type_val, device_name_val, room_val)
		device.state = smart_device.current_state.duplicate()
		device.node_reference = smart_device
		
		devices[device_id] = device
		
		# Add to room index
		if not devices_by_room.has(room_val):
			devices_by_room[room_val] = []
		devices_by_room[room_val].append(device)
		
		# Add to type index
		if not devices_by_type.has(device_type_val):
			devices_by_type[device_type_val] = []
		devices_by_type[device_type_val].append(device)
		
		device_registered.emit(device_id)
		return device
	
	# Handle manual registration with parameters
	else:
		var device_id = device_id_or_node
		if devices.has(device_id):
			push_warning("Device %s already registered" % device_id)
			return devices[device_id]
		
		var device = Device.new(device_id, device_type, device_name, room)
		device.state = initial_state
		
		devices[device_id] = device
		
		# Add to room index
		if not devices_by_room.has(room):
			devices_by_room[room] = []
		devices_by_room[room].append(device)
		
		# Add to type index
		if not devices_by_type.has(device_type):
			devices_by_type[device_type] = []
		devices_by_type[device_type].append(device)
		
		device_registered.emit(device_id)
		return device

## Unregister a device
func unregister_device(device_id: String) -> void:
	if not devices.has(device_id):
		push_warning("Device %s not found" % device_id)
		return
	
	var device = devices[device_id]
	
	# Remove from room index
	if devices_by_room.has(device.room):
		devices_by_room[device.room].erase(device)
	
	# Remove from type index
	if devices_by_type.has(device.type):
		devices_by_type[device.type].erase(device)
	
	devices.erase(device_id)
	device_unregistered.emit(device_id)

## Get a device by ID
func get_device(device_id: String) -> Device:
	return devices.get(device_id, null)

## Get all devices in a room
func get_devices_in_room(room: String) -> Array:
	return devices_by_room.get(room, [])

## Get all devices of a specific type
func get_devices_by_type(device_type: String) -> Array:
	return devices_by_type.get(device_type, [])

## Get all devices
func get_all_devices() -> Array:
	return devices.values()

## Update device state
func update_device_state(device_id: String, property: String, value: Variant) -> void:
	var device = get_device(device_id)
	if not device:
		push_warning("Device %s not found" % device_id)
		return
	
	device.state[property] = value
	device_state_changed.emit(device_id, property, value)

## Get device state property
func get_device_state(device_id: String, property: String) -> Variant:
	var device = get_device(device_id)
	if not device:
		return null
	return device.state.get(property, null)

## Set device node reference (for 3D scene interaction)
func set_device_node(device_id: String, node: Node) -> void:
	var device = get_device(device_id)
	if device:
		device.node_reference = node

## Reset all devices to their default states
func reset_all_devices() -> void:
	"""Reset all registered devices to their default states"""
	for device in devices.values():
		if device.node_reference and device.node_reference.has_method("reset_to_default"):
			device.node_reference.reset_to_default()
		else:
			# Fallback: set common default states
			match device.type:
				"light":
					if device.node_reference and device.node_reference.has_method("set_state"):
						device.node_reference.set_state({"on": false, "brightness": 1.0})
				"door", "window", "blind", "gate", "garage":
					if device.node_reference and device.node_reference.has_method("set_state"):
						device.node_reference.set_state({"open": false})
				"tv", "ac", "heater", "pump", "tap":
					if device.node_reference and device.node_reference.has_method("set_state"):
						device.node_reference.set_state({"on": false})
				"tank":
					if device.node_reference and device.node_reference.has_method("set_state"):
						device.node_reference.set_state({"level": 1.0})
	
	print("All devices reset to default states")
