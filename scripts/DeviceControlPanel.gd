extends Panel

## Device Control Panel - UI for controlling smart devices

signal panel_closed()

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleBar/TitleLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/TitleBar/CloseButton
@onready var device_info_label: Label = $MarginContainer/VBoxContainer/DeviceInfo
@onready var controls_container: VBoxContainer = $MarginContainer/VBoxContainer/ControlsContainer

var current_device: SmartDevice = null

func _ready() -> void:
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Hide panel initially
	visible = false
	
	# Make panel draggable (optional enhancement)
	mouse_filter = Control.MOUSE_FILTER_STOP

func show_device(device: SmartDevice) -> void:
	"""Display control panel for the given device"""
	if not device:
		return
	
	current_device = device
	
	# Update title
	if title_label:
		title_label.text = device.device_name
	
	# Update device info
	if device_info_label:
		device_info_label.text = "Type: %s | ID: %s" % [device.device_type, device.device_id]
	
	# Clear existing controls
	_clear_controls()
	
	# Populate controls based on device type and state
	_populate_controls()
	
	# Show panel
	visible = true

func hide_panel() -> void:
	"""Hide the control panel"""
	visible = false
	current_device = null
	panel_closed.emit()

func _clear_controls() -> void:
	"""Remove all existing control widgets"""
	if not controls_container:
		return
	
	for child in controls_container.get_children():
		child.queue_free()

func _populate_controls() -> void:
	"""Create control widgets based on device state"""
	if not current_device or not controls_container:
		return
	
	var state = current_device.get_state()
	
	# Add controls based on state keys
	for key in state.keys():
		match key:
			"on":
				_add_toggle_control("Power", key, state[key])
			"brightness":
				_add_slider_control("Brightness", key, state[key], 0.0, 1.0, 0.01)
			"temperature":
				_add_slider_control("Temperature (°C)", key, state[key], 16.0, 30.0, 0.5)
			"position":
				_add_slider_control("Position", key, state[key], 0.0, 1.0, 0.01)
			"open":
				_add_toggle_control("Open/Close", key, state[key])
			"locked":
				_add_toggle_control("Locked", key, state[key])
			"flow_rate":
				_add_slider_control("Flow Rate", key, state[key], 0.0, 1.0, 0.1)
			"level":
				_add_slider_control("Level", key, state[key], 0.0, 1.0, 0.05)
			"mode":
				_add_mode_control("Mode", key, state[key])
			"fan_speed":
				_add_slider_control("Fan Speed", key, state[key], 0.0, 3.0, 1.0)
			"channel":
				_add_slider_control("Channel", key, state[key], 1.0, 99.0, 1.0)

func _add_toggle_control(label_text: String, state_key: String, current_value: bool) -> void:
	"""Add a toggle button control"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(label)
	
	var toggle = CheckButton.new()
	toggle.button_pressed = current_value
	toggle.toggled.connect(func(pressed): _on_control_changed(state_key, pressed))
	hbox.add_child(toggle)
	
	controls_container.add_child(hbox)

func _add_slider_control(label_text: String, state_key: String, current_value: float, min_val: float, max_val: float, step: float) -> void:
	"""Add a slider control with value label"""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	
	# Label with current value
	var label = Label.new()
	label.text = "%s: %.2f" % [label_text, current_value]
	vbox.add_child(label)
	
	# Slider
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = current_value
	slider.custom_minimum_size = Vector2(300, 0)
	
	# Update label and device state on slider change
	slider.value_changed.connect(func(value):
		label.text = "%s: %.2f" % [label_text, value]
		_on_control_changed(state_key, value)
	)
	
	vbox.add_child(slider)
	controls_container.add_child(vbox)

func _add_mode_control(label_text: String, state_key: String, current_value: String) -> void:
	"""Add a dropdown for mode selection"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(label)
	
	var option_button = OptionButton.new()
	
	# Add common modes (can be expanded based on device type)
	var modes = ["cool", "heat", "fan", "auto"]
	for mode in modes:
		option_button.add_item(mode)
	
	# Set current selection
	var current_index = modes.find(current_value)
	if current_index >= 0:
		option_button.selected = current_index
	
	option_button.item_selected.connect(func(index):
		_on_control_changed(state_key, modes[index])
	)
	
	hbox.add_child(option_button)
	controls_container.add_child(hbox)

func _on_control_changed(state_key: String, value: Variant) -> void:
	"""Handle control value changes and update device state"""
	if not current_device:
		return
	
	# Create state update dictionary
	var new_state = {}
	new_state[state_key] = value
	
	# Update device state
	current_device.set_state(new_state)

func _on_close_button_pressed() -> void:
	"""Handle close button click"""
	hide_panel()

func _input(event: InputEvent) -> void:
	"""Handle clicks outside panel to close"""
	if not visible:
		return
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# Check if click is outside panel
			var mouse_pos = get_viewport().get_mouse_position()
			var panel_rect = get_global_rect()
			
			if not panel_rect.has_point(mouse_pos):
				hide_panel()
				get_viewport().set_input_as_handled()
