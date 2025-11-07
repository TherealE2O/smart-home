extends Node3D

@onready var devices_container: Node3D = $Devices
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var explore_camera: Camera3D = $ExploreCamera
@onready var device_control_panel: Panel = $UI/DeviceControlPanel
@onready var automation_history_panel: Panel = $UI/AutomationHistoryPanel

# Device name mappings
var device_configs: Dictionary = {
	"LivingRoomLight": {"id": "light_living_room", "name": "Living Room Light"},
	"BedroomLight": {"id": "light_bedroom", "name": "Bedroom Light"},
	"KitchenLight": {"id": "light_kitchen", "name": "Kitchen Light"},
	"BathroomLight": {"id": "light_bathroom", "name": "Bathroom Light"},
	"LivingRoomTV": {"id": "tv_living_room", "name": "Living Room TV"},
	"LivingRoomAC": {"id": "ac_living_room", "name": "Living Room AC"},
	"BedroomHeater": {"id": "heater_bedroom", "name": "Bedroom Heater"},
	"FrontDoor": {"id": "door_front", "name": "Front Door"},
	"BedroomDoor": {"id": "door_bedroom", "name": "Bedroom Door"},
	"BathroomDoor": {"id": "door_bathroom", "name": "Bathroom Door"},
	"LivingRoomWindow": {"id": "window_living_room", "name": "Living Room Window"},
	"BedroomWindow": {"id": "window_bedroom", "name": "Bedroom Window"},
	"KitchenWindow": {"id": "window_kitchen", "name": "Kitchen Window"},
	"LivingRoomBlind": {"id": "blind_living_room", "name": "Living Room Blind"},
	"BedroomBlind": {"id": "blind_bedroom", "name": "Bedroom Blind"},
	"KitchenSink": {"id": "tap_kitchen", "name": "Kitchen Sink"},
	"BathroomSink": {"id": "tap_bathroom", "name": "Bathroom Sink"},
	"WaterPump": {"id": "pump_main", "name": "Water Pump"},
	"WaterTank": {"id": "tank_main", "name": "Water Tank"}
}

func _ready() -> void:
	print("Interior scene loaded")
	
	# Configure and register all devices
	_configure_all_devices()
	
	# Set camera for InteractionManager
	if explore_camera and InteractionManager:
		InteractionManager.set_camera(explore_camera)
		
		# Connect InteractionManager signals to control panel
		InteractionManager.device_clicked.connect(_on_device_clicked)
	
	# Connect automation history panel signals
	if automation_history_panel:
		automation_history_panel.device_highlight_requested.connect(_on_device_highlight_requested)
		automation_history_panel.camera_focus_requested.connect(_on_camera_focus_requested)
		automation_history_panel.hide()  # Start hidden

func _on_device_clicked(device: SmartDevice) -> void:
	"""Handle device click to show control panel"""
	if device_control_panel:
		device_control_panel.show_device(device)

func _on_device_highlight_requested(device_ids: Array) -> void:
	"""Handle request to highlight devices from history panel"""
	if InteractionManager:
		InteractionManager.highlight_devices(device_ids)

func _on_camera_focus_requested(device_ids: Array) -> void:
	"""Handle request to focus camera on devices from history panel"""
	if InteractionManager:
		InteractionManager.focus_camera_on_devices(device_ids)

func _input(event: InputEvent) -> void:
	"""Handle input for showing history panel"""
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_H:
			# Toggle history panel with H key
			if automation_history_panel:
				if automation_history_panel.visible:
					automation_history_panel.hide()
					InteractionManager.clear_history_highlights()
				else:
					automation_history_panel.show_panel()

func _configure_all_devices() -> void:
	"""Configure device IDs and names, then register with DeviceRegistry"""
	if not devices_container:
		return
	
	for device in devices_container.get_children():
		if device is SmartDevice:
			var device_node_name = device.name
			
			# Set device ID and name from config
			if device_configs.has(device_node_name):
				var config = device_configs[device_node_name]
				device.device_id = config["id"]
				device.device_name = config["name"]
			else:
				# Fallback if not in config
				device.device_id = device_node_name.to_lower()
				device.device_name = device_node_name
			
			# Register with DeviceRegistry
			DeviceRegistry.register_device(device)
			print("Registered device: ", device.device_name, " (", device.device_id, ")")
