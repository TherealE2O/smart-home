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

func _ready() -> void:
	pass

## Register a new device
func register_device(device_id: String, device_type: String, device_name: String, room: String, initial_state: Dictionary = {}) -> Device:
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
