extends GraphNode
## TriggerNode - Visual node for automation triggers
## Supports TIME, DEVICE_STATE, and MANUAL trigger types

enum TriggerType { TIME, DEVICE_STATE, MANUAL }

var trigger_type: TriggerType = TriggerType.MANUAL

# UI Controls
var trigger_type_label: Label
var time_controls: VBoxContainer
var device_state_controls: VBoxContainer

# Time trigger controls
var hour_spinbox: SpinBox
var minute_spinbox: SpinBox

# Device state trigger controls
var device_option_button: OptionButton
var state_key_line_edit: LineEdit
var state_value_line_edit: LineEdit

func _init() -> void:
	# GraphNode configuration
	title = "Trigger"
	resizable = true
	draggable = true
	selectable = true
	
	# Add output slot
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.GREEN)

func _ready() -> void:
	# Will be configured by setup functions
	pass

## Setup as TIME trigger
func setup_as_time_trigger() -> void:
	trigger_type = TriggerType.TIME
	title = "Time Trigger"
	
	_clear_controls()
	
	# Add trigger type label
	trigger_type_label = Label.new()
	trigger_type_label.text = "Trigger Type: TIME"
	add_child(trigger_type_label)
	
	# Time controls container
	time_controls = VBoxContainer.new()
	add_child(time_controls)
	
	# Hour control
	var hour_container = HBoxContainer.new()
	time_controls.add_child(hour_container)
	
	var hour_label = Label.new()
	hour_label.text = "Hour:"
	hour_label.custom_minimum_size = Vector2(60, 0)
	hour_container.add_child(hour_label)
	
	hour_spinbox = SpinBox.new()
	hour_spinbox.min_value = 0
	hour_spinbox.max_value = 23
	hour_spinbox.value = 12
	hour_spinbox.custom_minimum_size = Vector2(80, 0)
	hour_container.add_child(hour_spinbox)
	
	# Minute control
	var minute_container = HBoxContainer.new()
	time_controls.add_child(minute_container)
	
	var minute_label = Label.new()
	minute_label.text = "Minute:"
	minute_label.custom_minimum_size = Vector2(60, 0)
	minute_container.add_child(minute_label)
	
	minute_spinbox = SpinBox.new()
	minute_spinbox.min_value = 0
	minute_spinbox.max_value = 59
	minute_spinbox.value = 0
	minute_spinbox.custom_minimum_size = Vector2(80, 0)
	minute_container.add_child(minute_spinbox)
	
	# Update slot
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.GREEN)

## Setup as DEVICE_STATE trigger
func setup_as_device_state_trigger() -> void:
	trigger_type = TriggerType.DEVICE_STATE
	title = "Device State Trigger"
	
	_clear_controls()
	
	# Add trigger type label
	trigger_type_label = Label.new()
	trigger_type_label.text = "Trigger Type: DEVICE_STATE"
	add_child(trigger_type_label)
	
	# Device state controls container
	device_state_controls = VBoxContainer.new()
	add_child(device_state_controls)
	
	# Device selector
	var device_container = HBoxContainer.new()
	device_state_controls.add_child(device_container)
	
	var device_label = Label.new()
	device_label.text = "Device:"
	device_label.custom_minimum_size = Vector2(60, 0)
	device_container.add_child(device_label)
	
	device_option_button = OptionButton.new()
	device_option_button.custom_minimum_size = Vector2(150, 0)
	device_container.add_child(device_option_button)
	
	# Populate device list
	_populate_device_list()
	
	# State key input
	var state_key_container = HBoxContainer.new()
	device_state_controls.add_child(state_key_container)
	
	var state_key_label = Label.new()
	state_key_label.text = "State Key:"
	state_key_label.custom_minimum_size = Vector2(60, 0)
	state_key_container.add_child(state_key_label)
	
	state_key_line_edit = LineEdit.new()
	state_key_line_edit.placeholder_text = "e.g., 'on', 'open'"
	state_key_line_edit.custom_minimum_size = Vector2(150, 0)
	state_key_container.add_child(state_key_line_edit)
	
	# State value input
	var state_value_container = HBoxContainer.new()
	device_state_controls.add_child(state_value_container)
	
	var state_value_label = Label.new()
	state_value_label.text = "Value:"
	state_value_label.custom_minimum_size = Vector2(60, 0)
	state_value_container.add_child(state_value_label)
	
	state_value_line_edit = LineEdit.new()
	state_value_line_edit.placeholder_text = "e.g., 'true', '1.0'"
	state_value_line_edit.custom_minimum_size = Vector2(150, 0)
	state_value_container.add_child(state_value_line_edit)
	
	# Update slot
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.GREEN)

## Setup as MANUAL trigger
func setup_as_manual_trigger() -> void:
	trigger_type = TriggerType.MANUAL
	title = "Manual Trigger"
	
	_clear_controls()
	
	# Add trigger type label
	trigger_type_label = Label.new()
	trigger_type_label.text = "Trigger Type: MANUAL"
	add_child(trigger_type_label)
	
	var info_label = Label.new()
	info_label.text = "Triggered manually only"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info_label)
	
	# Update slot
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.GREEN)

## Clear all child controls
func _clear_controls() -> void:
	for child in get_children():
		child.queue_free()

## Populate device list from DeviceRegistry
func _populate_device_list() -> void:
	if not device_option_button:
		return
	
	device_option_button.clear()
	
	var devices = DeviceRegistry.get_all_devices()
	if devices.is_empty():
		device_option_button.add_item("(No devices available)")
		device_option_button.disabled = true
		return
	
	for device in devices:
		var display_name = "%s (%s)" % [device.name, device.id]
		device_option_button.add_item(display_name)
		device_option_button.set_item_metadata(device_option_button.item_count - 1, device.id)

## Get the AutomationTrigger resource from this node
func get_trigger() -> AutomationTrigger:
	match trigger_type:
		TriggerType.TIME:
			return _get_time_trigger()
		TriggerType.DEVICE_STATE:
			return _get_device_state_trigger()
		TriggerType.MANUAL:
			return _get_manual_trigger()
	
	return null

## Create TIME trigger
func _get_time_trigger() -> AutomationTrigger:
	var params = {
		"hour": int(hour_spinbox.value),
		"minute": int(minute_spinbox.value)
	}
	return AutomationTrigger.new(AutomationTrigger.TriggerType.TIME, params)

## Create DEVICE_STATE trigger
func _get_device_state_trigger() -> AutomationTrigger:
	var selected_idx = device_option_button.selected
	if selected_idx < 0:
		push_error("TriggerNode: No device selected")
		return null
	
	var device_id = device_option_button.get_item_metadata(selected_idx)
	var state_key = state_key_line_edit.text.strip_edges()
	var state_value_str = state_value_line_edit.text.strip_edges()
	
	if state_key.is_empty() or state_value_str.is_empty():
		push_error("TriggerNode: State key and value are required")
		return null
	
	# Parse value (try to convert to appropriate type)
	var state_value = _parse_value(state_value_str)
	
	var params = {
		"device_id": device_id,
		"state_key": state_key,
		"value": state_value
	}
	return AutomationTrigger.new(AutomationTrigger.TriggerType.DEVICE_STATE, params)

## Create MANUAL trigger
func _get_manual_trigger() -> AutomationTrigger:
	return AutomationTrigger.new(AutomationTrigger.TriggerType.MANUAL, {})

## Parse string value to appropriate type
func _parse_value(value_str: String) -> Variant:
	# Try boolean
	if value_str.to_lower() == "true":
		return true
	if value_str.to_lower() == "false":
		return false
	
	# Try integer
	if value_str.is_valid_int():
		return value_str.to_int()
	
	# Try float
	if value_str.is_valid_float():
		return value_str.to_float()
	
	# Return as string
	return value_str
