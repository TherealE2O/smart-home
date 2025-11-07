extends Panel
## AutomationHistoryPanel - Displays automation execution history with details and replay functionality

signal closed()
signal device_highlight_requested(device_ids: Array)
signal camera_focus_requested(device_ids: Array)

# UI References
@onready var history_list: ItemList = $MarginContainer/VBoxContainer/HistoryListContainer/ScrollContainer/HistoryList
@onready var details_text: RichTextLabel = $MarginContainer/VBoxContainer/DetailsContainer/ScrollContainer/DetailsText
@onready var highlight_button: Button = $MarginContainer/VBoxContainer/DetailsContainer/ActionButtons/HighlightButton
@onready var focus_button: Button = $MarginContainer/VBoxContainer/DetailsContainer/ActionButtons/FocusButton
@onready var replay_button: Button = $MarginContainer/VBoxContainer/DetailsContainer/ActionButtons/ReplayButton
@onready var replay_progress: ProgressBar = $MarginContainer/VBoxContainer/DetailsContainer/ReplayProgress
@onready var replay_label: Label = $MarginContainer/VBoxContainer/DetailsContainer/ReplayLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/TitleBar/CloseButton
@onready var refresh_button: Button = $MarginContainer/VBoxContainer/TitleBar/RefreshButton

# Current selection
var selected_history_entry: AutomationHistoryEntry = null
var history_entries: Array[AutomationHistoryEntry] = []

# Replay state
var is_replaying: bool = false
var replay_timer: Timer = null

func _ready() -> void:
	# Connect signals
	history_list.item_selected.connect(_on_history_item_selected)
	close_button.pressed.connect(_on_close_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	highlight_button.pressed.connect(_on_highlight_pressed)
	focus_button.pressed.connect(_on_focus_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	
	# Setup replay timer
	replay_timer = Timer.new()
	replay_timer.one_shot = false
	add_child(replay_timer)
	
	# Hide replay progress initially
	replay_progress.visible = false
	replay_label.visible = false
	
	# Load history
	refresh_history()

func refresh_history() -> void:
	"""Load and display automation history from AutomationEngine"""
	history_list.clear()
	history_entries.clear()
	
	# Get all history from AutomationEngine (most recent first)
	var all_history = AutomationEngine.get_all_history()
	
	# Reverse to show most recent first
	for i in range(all_history.size() - 1, -1, -1):
		var entry = all_history[i]
		history_entries.append(entry)
		
		# Format list item text
		var timestamp_str = _format_timestamp(entry.timestamp)
		var status_icon = "✓" if entry.success else "✗"
		var list_text = "%s [%s] %s - %s" % [
			status_icon,
			timestamp_str,
			entry.automation_name,
			entry.trigger_reason
		]
		
		history_list.add_item(list_text)
	
	# Clear selection
	selected_history_entry = null
	_update_details_view()
	_update_button_states()

func _format_timestamp(unix_time: int) -> String:
	"""Format Unix timestamp as readable date/time string"""
	var datetime = Time.get_datetime_dict_from_unix_time(unix_time)
	var now = Time.get_datetime_dict_from_system()
	
	# Check if it's today
	if datetime.year == now.year and datetime.month == now.month and datetime.day == now.day:
		return "Today %02d:%02d" % [datetime.hour, datetime.minute]
	
	# Check if it's yesterday
	var yesterday_time = Time.get_unix_time_from_system() - 86400
	var yesterday = Time.get_datetime_dict_from_unix_time(yesterday_time)
	if datetime.year == yesterday.year and datetime.month == yesterday.month and datetime.day == yesterday.day:
		return "Yesterday %02d:%02d" % [datetime.hour, datetime.minute]
	
	# Otherwise show full date
	return "%02d/%02d %02d:%02d" % [
		datetime.month, datetime.day,
		datetime.hour, datetime.minute
	]

func _on_history_item_selected(index: int) -> void:
	"""Handle selection of history item"""
	if index >= 0 and index < history_entries.size():
		selected_history_entry = history_entries[index]
		_update_details_view()
		_update_button_states()

func _update_details_view() -> void:
	"""Update the details panel with selected entry information"""
	if not selected_history_entry:
		details_text.text = "Select an automation from the list to view details."
		return
	
	var entry = selected_history_entry
	
	# Build detailed information
	var details = ""
	details += "[b]Automation:[/b] %s\n" % entry.automation_name
	details += "[b]Executed:[/b] %s\n" % entry.get_formatted_timestamp()
	details += "[b]Trigger:[/b] %s\n" % entry.trigger_reason
	details += "[b]Status:[/b] %s\n\n" % ("Success" if entry.success else "Failed")
	
	if not entry.success and entry.error_message:
		details += "[color=red][b]Error:[/b] %s[/color]\n\n" % entry.error_message
	
	# List affected devices
	details += "[b]Affected Devices (%d):[/b]\n" % entry.affected_devices.size()
	for device_id in entry.affected_devices:
		var device = DeviceRegistry.get_device(device_id)
		if device:
			details += "  • %s (%s)\n" % [device.name, device_id]
		else:
			details += "  • %s (not found)\n" % device_id
	
	details += "\n[b]Actions Performed (%d):[/b]\n" % entry.actions_performed.size()
	for action_data in entry.actions_performed:
		var device_id = action_data.get("device_id", "unknown")
		var action_type = action_data.get("action_type", "unknown")
		var parameters = action_data.get("parameters", {})
		var success = action_data.get("success", false)
		
		var device = DeviceRegistry.get_device(device_id)
		var device_name = device.name if device else device_id
		
		var status_icon = "✓" if success else "✗"
		details += "  %s [b]%s[/b]: %s\n" % [status_icon, device_name, action_type]
		
		# Show parameters
		for key in parameters.keys():
			details += "      - %s: %s\n" % [key, str(parameters[key])]
	
	details_text.text = details

func _update_button_states() -> void:
	"""Enable/disable buttons based on selection"""
	var has_selection = selected_history_entry != null
	var has_devices = has_selection and selected_history_entry.affected_devices.size() > 0
	
	highlight_button.disabled = not has_devices or is_replaying
	focus_button.disabled = not has_devices or is_replaying
	replay_button.disabled = not has_selection or is_replaying

func _on_highlight_pressed() -> void:
	"""Emit signal to highlight affected devices in 3D scene"""
	if selected_history_entry and selected_history_entry.affected_devices.size() > 0:
		device_highlight_requested.emit(selected_history_entry.affected_devices)

func _on_focus_pressed() -> void:
	"""Emit signal to focus camera on affected devices"""
	if selected_history_entry and selected_history_entry.affected_devices.size() > 0:
		camera_focus_requested.emit(selected_history_entry.affected_devices)

func _on_replay_pressed() -> void:
	"""Replay the selected automation"""
	if not selected_history_entry or is_replaying:
		return
	
	_start_replay(selected_history_entry)

func _start_replay(entry: AutomationHistoryEntry) -> void:
	"""Start replaying an automation from history"""
	is_replaying = true
	_update_button_states()
	
	# Show progress UI
	replay_progress.visible = true
	replay_label.visible = true
	replay_progress.value = 0.0
	replay_label.text = "Replaying automation..."
	
	# Execute actions with delays
	var actions = entry.actions_performed
	if actions.size() == 0:
		_finish_replay()
		return
	
	# Execute actions sequentially
	_replay_action_sequence(actions, 0)

func _replay_action_sequence(actions: Array, index: int) -> void:
	"""Recursively execute actions with delays"""
	if index >= actions.size():
		_finish_replay()
		return
	
	var action_data = actions[index]
	var device_id = action_data.get("device_id", "")
	var action_type = action_data.get("action_type", "")
	var parameters = action_data.get("parameters", {})
	
	# Update progress
	var progress = float(index) / float(actions.size())
	replay_progress.value = progress
	replay_label.text = "Replaying: %s (%d/%d)" % [device_id, index + 1, actions.size()]
	
	# Execute the action
	var device = DeviceRegistry.get_device(device_id)
	if device and device.node_reference:
		var device_node = device.node_reference
		if device_node.has_method("set_state"):
			device_node.set_state(parameters)
	
	# Wait before next action
	await get_tree().create_timer(0.8).timeout
	
	# Continue with next action
	_replay_action_sequence(actions, index + 1)

func _finish_replay() -> void:
	"""Finish replay and reset UI"""
	is_replaying = false
	replay_progress.value = 1.0
	replay_label.text = "Replay complete!"
	
	# Hide progress after a delay
	await get_tree().create_timer(1.5).timeout
	replay_progress.visible = false
	replay_label.visible = false
	
	_update_button_states()

func _on_close_pressed() -> void:
	"""Handle close button"""
	closed.emit()
	hide()

func _on_refresh_pressed() -> void:
	"""Handle refresh button"""
	refresh_history()

func show_panel() -> void:
	"""Show the panel and refresh history"""
	show()
	refresh_history()
