extends Node
## AutomationEngine singleton for managing automation rules
## Handles rule creation, evaluation, and execution

signal automation_triggered(automation_id: String)
signal automation_executed(automation_id: String, history_entry: AutomationHistoryEntry)

# Active automations using new resource classes
var active_automations: Array[Automation] = []

# Automation history
var automation_history: Array[AutomationHistoryEntry] = []

# Maximum history entries to keep
const MAX_HISTORY_ENTRIES: int = 100

# Track last trigger times to prevent duplicate executions
var last_trigger_times: Dictionary = {}  # automation_id -> timestamp

# Evaluation timer
var evaluation_timer: Timer

func _ready() -> void:
	# Connect to DeviceRegistry signals to evaluate automations on state changes
	if DeviceRegistry.has_signal("device_state_changed"):
		DeviceRegistry.device_state_changed.connect(_on_device_state_changed)
	
	# Set up periodic evaluation timer (every second)
	evaluation_timer = Timer.new()
	evaluation_timer.wait_time = 1.0
	evaluation_timer.timeout.connect(evaluate_automations)
	add_child(evaluation_timer)
	evaluation_timer.start()
	
	# Create sample automations after a short delay to ensure devices are registered
	await get_tree().create_timer(0.5).timeout
	_create_sample_automations()

## Add a new automation to the active list
func add_automation(automation: Automation) -> void:
	if automation == null:
		push_error("AutomationEngine: Cannot add null automation")
		return
	
	# Check if automation with same ID already exists
	for existing in active_automations:
		if existing.automation_id == automation.automation_id:
			push_warning("AutomationEngine: Automation %s already exists, replacing" % automation.automation_id)
			active_automations.erase(existing)
			break
	
	active_automations.append(automation)
	print("AutomationEngine: Added automation '%s' (ID: %s)" % [automation.automation_name, automation.automation_id])

## Remove an automation by ID
func remove_automation(automation_id: String) -> void:
	for i in range(active_automations.size() - 1, -1, -1):
		if active_automations[i].automation_id == automation_id:
			print("AutomationEngine: Removed automation '%s'" % active_automations[i].automation_name)
			active_automations.remove_at(i)
			return
	
	push_warning("AutomationEngine: Automation %s not found" % automation_id)

## Get an automation by ID
func get_automation(automation_id: String) -> Automation:
	for automation in active_automations:
		if automation.automation_id == automation_id:
			return automation
	return null

## Get all active automations
func get_all_automations() -> Array[Automation]:
	return active_automations

## Evaluate all automations (called periodically by timer)
func evaluate_automations() -> void:
	var current_time = Time.get_unix_time_from_system()
	
	for automation in active_automations:
		if not automation.is_enabled:
			continue
		
		# Check if automation should trigger
		if automation.evaluate():
			# Prevent duplicate executions within 60 seconds
			var last_trigger = last_trigger_times.get(automation.automation_id, 0)
			if current_time - last_trigger < 60:
				continue
			
			# Execute the automation
			execute_automation(automation)
			last_trigger_times[automation.automation_id] = current_time

## Execute an automation and record to history
func execute_automation(automation: Automation) -> void:
	if automation == null:
		push_error("AutomationEngine: Cannot execute null automation")
		return
	
	print("AutomationEngine: Executing automation '%s'" % automation.automation_name)
	automation_triggered.emit(automation.automation_id)
	
	# Execute and get history entry
	var history_entry = automation.execute()
	
	# Add to history
	_add_to_history(history_entry)
	
	# Emit signal
	automation_executed.emit(automation.automation_id, history_entry)
	
	print("AutomationEngine: Completed automation '%s' - %d actions performed" % [
		automation.automation_name,
		history_entry.actions_performed.size()
	])

## Test an automation immediately (ignores trigger conditions)
func test_automation(automation: Automation) -> AutomationHistoryEntry:
	if automation == null:
		push_error("AutomationEngine: Cannot test null automation")
		return null
	
	print("AutomationEngine: Testing automation '%s'" % automation.automation_name)
	
	# Execute directly without checking trigger
	var history_entry = automation.execute()
	
	# Add to history with special marker
	history_entry.trigger_reason = "Manual Test"
	_add_to_history(history_entry)
	
	automation_executed.emit(automation.automation_id, history_entry)
	
	return history_entry

## Get automation history (most recent first)
func get_history(limit: int = 10) -> Array[AutomationHistoryEntry]:
	var result: Array[AutomationHistoryEntry] = []
	var count = min(limit, automation_history.size())
	
	# Return most recent entries first
	for i in range(count):
		result.append(automation_history[automation_history.size() - 1 - i])
	
	return result

## Get all history entries
func get_all_history() -> Array[AutomationHistoryEntry]:
	return automation_history

## Clear all history
func clear_history() -> void:
	automation_history.clear()
	print("AutomationEngine: History cleared")

## Add entry to history with size limit
func _add_to_history(entry: AutomationHistoryEntry) -> void:
	automation_history.append(entry)
	
	# Maintain maximum history size
	while automation_history.size() > MAX_HISTORY_ENTRIES:
		automation_history.remove_at(0)

## Called when a device state changes
func _on_device_state_changed(device_id: String, property: String, value: Variant) -> void:
	# Evaluate automations that might be triggered by device state changes
	for automation in active_automations:
		if not automation.is_enabled:
			continue
		
		# Check if this automation has a device state trigger
		if automation.trigger and automation.trigger.trigger_type == AutomationTrigger.TriggerType.DEVICE_STATE:
			var trigger_device_id = automation.trigger.parameters.get("device_id", "")
			if trigger_device_id == device_id:
				# Re-evaluate this automation
				if automation.evaluate():
					execute_automation(automation)


## Create sample automations for demonstration
func _create_sample_automations() -> void:
	print("AutomationEngine: Creating sample automations...")
	
	# Sample 1: Evening Lights - Turn on living room lights at 6 PM
	var evening_lights = Automation.new()
	evening_lights.automation_name = "Evening Lights"
	evening_lights.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.TIME,
		{"hour": 18, "minute": 0}
	)
	var action1 = AutomationAction.new("light_living_room", "set_state", {"on": true, "brightness": 0.7})
	evening_lights.actions.append(action1)
	add_automation(evening_lights)
	
	# Sample 2: Morning Routine - Turn on lights and open blinds at 7 AM
	var morning_routine = Automation.new()
	morning_routine.automation_name = "Morning Routine"
	morning_routine.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.TIME,
		{"hour": 7, "minute": 0}
	)
	var action2a = AutomationAction.new("light_bedroom", "set_state", {"on": true, "brightness": 0.5})
	var action2b = AutomationAction.new("blind_bedroom", "set_state", {"position": 1.0})
	morning_routine.actions.append(action2a)
	morning_routine.actions.append(action2b)
	add_automation(morning_routine)
	
	# Sample 3: Night Mode - Turn off all lights at 11 PM
	var night_mode = Automation.new()
	night_mode.automation_name = "Night Mode"
	night_mode.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.TIME,
		{"hour": 23, "minute": 0}
	)
	var action3a = AutomationAction.new("light_living_room", "set_state", {"on": false})
	var action3b = AutomationAction.new("light_bedroom", "set_state", {"on": false})
	var action3c = AutomationAction.new("light_kitchen", "set_state", {"on": false})
	night_mode.actions.append(action3a)
	night_mode.actions.append(action3b)
	night_mode.actions.append(action3c)
	add_automation(night_mode)
	
	# Sample 4: Door Opens → Lights On
	var door_lights = Automation.new()
	door_lights.automation_name = "Entry Light Activation"
	door_lights.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.DEVICE_STATE,
		{"device_id": "door_front", "state_key": "open", "value": true}
	)
	var action4 = AutomationAction.new("light_hallway", "set_state", {"on": true, "brightness": 1.0})
	door_lights.actions.append(action4)
	add_automation(door_lights)
	
	# Sample 5: Climate Control - Turn on AC when temperature is high
	var climate_control = Automation.new()
	climate_control.automation_name = "Auto Climate Control"
	climate_control.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.TIME,
		{"hour": 14, "minute": 0}
	)
	var action5 = AutomationAction.new("ac_living_room", "set_state", {"on": true, "temperature": 22.0})
	climate_control.actions.append(action5)
	add_automation(climate_control)
	
	# Sample 6: Window Closes → Heater On (winter mode)
	var window_heater = Automation.new()
	window_heater.automation_name = "Window Closed Heating"
	window_heater.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.DEVICE_STATE,
		{"device_id": "window_living_room", "state_key": "open", "value": false}
	)
	var action6 = AutomationAction.new("heater_living_room", "set_state", {"on": true, "temperature": 21.0})
	window_heater.actions.append(action6)
	add_automation(window_heater)
	
	# Sample 7: Afternoon Blinds - Close blinds at 2 PM to reduce heat
	var afternoon_blinds = Automation.new()
	afternoon_blinds.automation_name = "Afternoon Sun Protection"
	afternoon_blinds.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.TIME,
		{"hour": 14, "minute": 0}
	)
	var action7 = AutomationAction.new("blind_living_room", "set_state", {"position": 0.3})
	afternoon_blinds.actions.append(action7)
	add_automation(afternoon_blinds)
	
	# Sample 8: TV Time - Turn on TV and dim lights at 8 PM
	var tv_time = Automation.new()
	tv_time.automation_name = "Evening Entertainment"
	tv_time.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.TIME,
		{"hour": 20, "minute": 0}
	)
	var action8a = AutomationAction.new("tv_living_room", "set_state", {"on": true})
	var action8b = AutomationAction.new("light_living_room", "set_state", {"on": true, "brightness": 0.3})
	tv_time.actions.append(action8a)
	tv_time.actions.append(action8b)
	add_automation(tv_time)
	
	# Sample 9: Water Tank Monitoring - Turn on pump when tank is low
	var water_management = Automation.new()
	water_management.automation_name = "Auto Water Refill"
	water_management.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.DEVICE_STATE,
		{"device_id": "water_tank", "state_key": "level", "value": 0.2}
	)
	var action9 = AutomationAction.new("water_pump", "set_state", {"on": true, "flow_rate": 1.0})
	water_management.actions.append(action9)
	add_automation(water_management)
	
	# Sample 10: Security Mode - Close all doors and windows at midnight
	var security_mode = Automation.new()
	security_mode.automation_name = "Night Security Lock"
	security_mode.trigger = AutomationTrigger.new(
		AutomationTrigger.TriggerType.TIME,
		{"hour": 0, "minute": 0}
	)
	var action10a = AutomationAction.new("door_front", "set_state", {"open": false, "locked": true})
	var action10b = AutomationAction.new("window_living_room", "set_state", {"open": false})
	var action10c = AutomationAction.new("window_bedroom", "set_state", {"open": false})
	security_mode.actions.append(action10a)
	security_mode.actions.append(action10b)
	security_mode.actions.append(action10c)
	add_automation(security_mode)
	
	print("AutomationEngine: Created %d sample automations" % active_automations.size())
	
	# Execute a few automations to populate history
	_populate_sample_history()

## Populate history with sample executions
func _populate_sample_history() -> void:
	print("AutomationEngine: Populating sample history...")
	
	# Execute some automations to create history entries
	var automations_to_test = ["Evening Lights", "Morning Routine", "Entry Light Activation", "Auto Climate Control"]
	
	for auto_name in automations_to_test:
		for automation in active_automations:
			if automation.automation_name == auto_name:
				# Create a history entry manually with past timestamp
				var history_entry = AutomationHistoryEntry.new()
				history_entry.automation_id = automation.automation_id
				history_entry.automation_name = automation.automation_name
				history_entry.trigger_reason = automation._get_trigger_description()
				
				# Simulate past execution times
				var hours_ago = randi() % 24 + 1
				history_entry.timestamp = Time.get_unix_time_from_system() - (hours_ago * 3600)
				
				# Record actions
				for action in automation.actions:
					if action is AutomationAction:
						history_entry.actions_performed.append({
							"device_id": action.target_device_id,
							"action_type": action.action_type,
							"parameters": action.parameters,
							"success": true
						})
						if not action.target_device_id in history_entry.affected_devices:
							history_entry.affected_devices.append(action.target_device_id)
				
				history_entry.success = true
				_add_to_history(history_entry)
				break
	
	print("AutomationEngine: Added %d sample history entries" % automation_history.size())
