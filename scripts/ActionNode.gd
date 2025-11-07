extends GraphNode
## ActionNode - Visual node for automation actions
## Allows selecting a device and configuring action parameters

# UI Controls
var device_option_button: OptionButton
var action_type_option: OptionButton
var parameters_container: VBoxContainer

# Current device type for parameter controls
var current_device_type: String = ""

# Parameter controls (dynamically created based on device type)
var parameter_controls: Dictionary = {}

func _init() -> void:
	# GraphNode configuration
	title = "Device Action"
	resizable = true
	draggable = true
	selectable = true
	
	# Add input and output slots
	set_slot(0, true, 0, Color.GREEN, true, 0, Color.GREEN)

func _ready() -> void:
	_build_ui()

## Build the UI controls
func _build_ui() -> void:
	# Device selector
	var device_container = HBoxContainer.new()
	add_child(device_container)
	
	var device_label = Label.new()
	device_label.text = "Device:"
	device_label.custom_minimum_size = Vector2(60, 0)
	device_container.add_child(device_label)
	
	device_option_button = OptionButton.new()
	device_option_button.custom_minimum_size = Vector2(180, 0)
	device_option_button.item_selected.connect(_on_device_selected)
	device_container.add_child(device_option_button)
	
	# Populate device list
	_populate_device_list()
	
	# Action type selector
	var action_container = HBoxContainer.new()
	add_child(action_container)
	
	var action_label = Label.new()
	action_label.text = "Action:"
	action_label.custom_minimum_size = Vector2(60, 0)
	action_container.add_child(action_label)
	
	action_type_option = OptionButton.new()
	action_type_option.custom_minimum_size = Vector2(180, 0)
	action_type_option.add_item("Set State")
	action_type_option.add_item("Toggle")
	action_container.add_child(action_type_option)
	
	# Parameters container (dynamically populated)
	parameters_container = VBoxContainer.new()
	add_child(parameters_container)
	
	# Update slot
	set_slot(3, true, 0, Color.GREEN, true, 0, Color.GREEN)

## Populate device list from DeviceRegistry
func _populate_device_list() -> void:
	device_option_button.clear()
	
	var devices = DeviceRegistry.get_all_devices()
	if devices.is_empty():
		device_option_button.add_item("(No devices available)")
		device_option_button.disabled = true
		return
	
	for device in devices:
		var display_name = "%s (%s)" % [device.name, device.id]
		device_option_button.add_item(display_name)
		device_option_button.set_item_metadata(device_option_button.item_count - 1, {
			"id": device.id,
			"type": device.type
		})
	
	# Select first device by default
	if device_option_button.item_count > 0:
		device_option_button.selected = 0
		_on_device_selected(0)

## Handle device selection change
func _on_device_selected(index: int) -> void:
	if index < 0:
		return
	
	var metadata = device_option_button.get_item_metadata(index)
	if metadata:
		current_device_type = metadata.type
		_update_parameter_controls()

## Update parameter controls based on device type
func _update_parameter_controls() -> void:
	# Clear existing controls
	for child in parameters_container.get_children():
		child.queue_free()
	
	parameter_controls.clear()
	
	# Add separator
	var separator = HSeparator.new()
	parameters_container.add_child(separator)
	
	var params_label = Label.new()
	params_label.text = "Parameters:"
	parameters_container.add_child(params_label)
	
	# Add device-specific controls
	match current_device_type:
		"light":
			_add_light_controls()
		"door", "window", "blind":
			_add_openable_controls()
		"ac", "heater":
			_add_climate_controls()
		"tv":
			_add_tv_controls()
		"water_pump", "tap":
			_add_water_controls()
		"water_tank":
			_add_tank_controls()
		"gate", "garage":
			_add_gate_controls()
		_:
			_add_generic_controls()

## Add controls for light devices
func _add_light_controls() -> void:
	# On/Off toggle
	var on_container = HBoxContainer.new()
	parameters_container.add_child(on_container)
	
	var on_label = Label.new()
	on_label.text = "On:"
	on_label.custom_minimum_size = Vector2(80, 0)
	on_container.add_child(on_label)
	
	var on_check = CheckBox.new()
	on_check.button_pressed = true
	on_container.add_child(on_check)
	parameter_controls["on"] = on_check
	
	# Brightness slider
	var brightness_container = HBoxContainer.new()
	parameters_container.add_child(brightness_container)
	
	var brightness_label = Label.new()
	brightness_label.text = "Brightness:"
	brightness_label.custom_minimum_size = Vector2(80, 0)
	brightness_container.add_child(brightness_label)
	
	var brightness_slider = HSlider.new()
	brightness_slider.min_value = 0.0
	brightness_slider.max_value = 1.0
	brightness_slider.step = 0.1
	brightness_slider.value = 0.8
	brightness_slider.custom_minimum_size = Vector2(120, 0)
	brightness_container.add_child(brightness_slider)
	parameter_controls["brightness"] = brightness_slider

## Add controls for openable devices (door, window, blind)
func _add_openable_controls() -> void:
	# Open/Close toggle
	var open_container = HBoxContainer.new()
	parameters_container.add_child(open_container)
	
	var open_label = Label.new()
	open_label.text = "Open:"
	open_label.custom_minimum_size = Vector2(80, 0)
	open_container.add_child(open_label)
	
	var open_check = CheckBox.new()
	open_check.button_pressed = true
	open_container.add_child(open_check)
	parameter_controls["open"] = open_check
	
	# Position slider (for blinds and windows)
	if current_device_type == "blind" or current_device_type == "window":
		var position_container = HBoxContainer.new()
		parameters_container.add_child(position_container)
		
		var position_label = Label.new()
		position_label.text = "Position:"
		position_label.custom_minimum_size = Vector2(80, 0)
		position_container.add_child(position_label)
		
		var position_slider = HSlider.new()
		position_slider.min_value = 0.0
		position_slider.max_value = 1.0
		position_slider.step = 0.1
		position_slider.value = 1.0
		position_slider.custom_minimum_size = Vector2(120, 0)
		position_container.add_child(position_slider)
		parameter_controls["position"] = position_slider

## Add controls for climate devices (AC, heater)
func _add_climate_controls() -> void:
	# On/Off toggle
	var on_container = HBoxContainer.new()
	parameters_container.add_child(on_container)
	
	var on_label = Label.new()
	on_label.text = "On:"
	on_label.custom_minimum_size = Vector2(80, 0)
	on_container.add_child(on_label)
	
	var on_check = CheckBox.new()
	on_check.button_pressed = true
	on_container.add_child(on_check)
	parameter_controls["on"] = on_check
	
	# Temperature spinbox
	var temp_container = HBoxContainer.new()
	parameters_container.add_child(temp_container)
	
	var temp_label = Label.new()
	temp_label.text = "Temp (°C):"
	temp_label.custom_minimum_size = Vector2(80, 0)
	temp_container.add_child(temp_label)
	
	var temp_spinbox = SpinBox.new()
	temp_spinbox.min_value = 16.0
	temp_spinbox.max_value = 30.0
	temp_spinbox.step = 0.5
	temp_spinbox.value = 22.0
	temp_spinbox.custom_minimum_size = Vector2(80, 0)
	temp_container.add_child(temp_spinbox)
	parameter_controls["temperature"] = temp_spinbox

## Add controls for TV
func _add_tv_controls() -> void:
	# On/Off toggle
	var on_container = HBoxContainer.new()
	parameters_container.add_child(on_container)
	
	var on_label = Label.new()
	on_label.text = "On:"
	on_label.custom_minimum_size = Vector2(80, 0)
	on_container.add_child(on_label)
	
	var on_check = CheckBox.new()
	on_check.button_pressed = true
	on_container.add_child(on_check)
	parameter_controls["on"] = on_check

## Add controls for water devices (pump, tap)
func _add_water_controls() -> void:
	# On/Off toggle
	var on_container = HBoxContainer.new()
	parameters_container.add_child(on_container)
	
	var on_label = Label.new()
	on_label.text = "On:"
	on_label.custom_minimum_size = Vector2(80, 0)
	on_container.add_child(on_label)
	
	var on_check = CheckBox.new()
	on_check.button_pressed = true
	on_container.add_child(on_check)
	parameter_controls["on"] = on_check
	
	# Flow rate slider
	var flow_container = HBoxContainer.new()
	parameters_container.add_child(flow_container)
	
	var flow_label = Label.new()
	flow_label.text = "Flow Rate:"
	flow_label.custom_minimum_size = Vector2(80, 0)
	flow_container.add_child(flow_label)
	
	var flow_slider = HSlider.new()
	flow_slider.min_value = 0.0
	flow_slider.max_value = 1.0
	flow_slider.step = 0.1
	flow_slider.value = 1.0
	flow_slider.custom_minimum_size = Vector2(120, 0)
	flow_container.add_child(flow_slider)
	parameter_controls["flow_rate"] = flow_slider

## Add controls for water tank
func _add_tank_controls() -> void:
	# Level slider
	var level_container = HBoxContainer.new()
	parameters_container.add_child(level_container)
	
	var level_label = Label.new()
	level_label.text = "Level:"
	level_label.custom_minimum_size = Vector2(80, 0)
	level_container.add_child(level_label)
	
	var level_slider = HSlider.new()
	level_slider.min_value = 0.0
	level_slider.max_value = 1.0
	level_slider.step = 0.1
	level_slider.value = 0.8
	level_slider.custom_minimum_size = Vector2(120, 0)
	level_container.add_child(level_slider)
	parameter_controls["level"] = level_slider

## Add controls for gate/garage
func _add_gate_controls() -> void:
	# Open/Close toggle
	var open_container = HBoxContainer.new()
	parameters_container.add_child(open_container)
	
	var open_label = Label.new()
	open_label.text = "Open:"
	open_label.custom_minimum_size = Vector2(80, 0)
	open_container.add_child(open_label)
	
	var open_check = CheckBox.new()
	open_check.button_pressed = true
	open_container.add_child(open_check)
	parameter_controls["open"] = open_check

## Add generic on/off control
func _add_generic_controls() -> void:
	var on_container = HBoxContainer.new()
	parameters_container.add_child(on_container)
	
	var on_label = Label.new()
	on_label.text = "On:"
	on_label.custom_minimum_size = Vector2(80, 0)
	on_container.add_child(on_label)
	
	var on_check = CheckBox.new()
	on_check.button_pressed = true
	on_container.add_child(on_check)
	parameter_controls["on"] = on_check

## Get the AutomationAction resource from this node
func get_action() -> AutomationAction:
	var selected_idx = device_option_button.selected
	if selected_idx < 0:
		push_error("ActionNode: No device selected")
		return null
	
	var metadata = device_option_button.get_item_metadata(selected_idx)
	if not metadata:
		return null
	
	var device_id = metadata.id
	var action_type = "set_state" if action_type_option.selected == 0 else "toggle"
	
	# Collect parameters from controls
	var parameters = {}
	for param_name in parameter_controls:
		var control = parameter_controls[param_name]
		
		if control is CheckBox:
			parameters[param_name] = control.button_pressed
		elif control is HSlider:
			parameters[param_name] = control.value
		elif control is SpinBox:
			parameters[param_name] = control.value
		elif control is LineEdit:
			parameters[param_name] = control.text
	
	return AutomationAction.new(device_id, action_type, parameters)
