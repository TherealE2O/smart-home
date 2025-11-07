class_name Automation
extends Resource

@export var automation_id: String = ""
@export var automation_name: String = "Unnamed Automation"
@export var trigger: AutomationTrigger = null
@export var conditions: Array = []  # Array of AutomationCondition
@export var actions: Array = []  # Array of AutomationAction
@export var is_enabled: bool = true
@export var created_timestamp: int = 0

func _init():
	automation_id = _generate_id()
	created_timestamp = Time.get_unix_time_from_system()
	trigger = AutomationTrigger.new()

func _generate_id() -> String:
	return "auto_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)

func evaluate() -> bool:
	if not is_enabled:
		return false
	
	# Check trigger
	if trigger == null or not trigger.evaluate():
		return false
	
	# Check all conditions
	for condition in conditions:
		if condition is AutomationCondition:
			if not condition.evaluate():
				return false
	
	return true

func execute() -> AutomationHistoryEntry:
	var history_entry = AutomationHistoryEntry.new()
	history_entry.automation_id = automation_id
	history_entry.automation_name = automation_name
	history_entry.trigger_reason = _get_trigger_description()
	
	var affected_device_ids: Array = []
	var performed_actions: Array = []
	var all_success = true
	
	for action in actions:
		if action is AutomationAction:
			var success = action.execute()
			if not success:
				all_success = false
			
			if not action.target_device_id in affected_device_ids:
				affected_device_ids.append(action.target_device_id)
			
			performed_actions.append({
				"device_id": action.target_device_id,
				"action_type": action.action_type,
				"parameters": action.parameters,
				"success": success
			})
	
	history_entry.actions_performed = performed_actions
	history_entry.affected_devices = affected_device_ids
	history_entry.success = all_success
	
	return history_entry

func _get_trigger_description() -> String:
	if trigger == null:
		return "Unknown trigger"
	
	match trigger.trigger_type:
		AutomationTrigger.TriggerType.TIME:
			var hour = trigger.parameters.get("hour", 0)
			var minute = trigger.parameters.get("minute", 0)
			return "Time trigger: %02d:%02d" % [hour, minute]
		AutomationTrigger.TriggerType.DEVICE_STATE:
			var device_id = trigger.parameters.get("device_id", "unknown")
			var state_key = trigger.parameters.get("state_key", "unknown")
			var value = trigger.parameters.get("value", "unknown")
			return "Device state: %s.%s = %s" % [device_id, state_key, str(value)]
		AutomationTrigger.TriggerType.MANUAL:
			return "Manual trigger"
	
	return "Unknown trigger"

func to_dict() -> Dictionary:
	var trigger_dict = trigger.to_dict() if trigger != null else {}
	
	var conditions_array: Array = []
	for condition in conditions:
		if condition is AutomationCondition:
			conditions_array.append(condition.to_dict())
	
	var actions_array: Array = []
	for action in actions:
		if action is AutomationAction:
			actions_array.append(action.to_dict())
	
	return {
		"automation_id": automation_id,
		"automation_name": automation_name,
		"trigger": trigger_dict,
		"conditions": conditions_array,
		"actions": actions_array,
		"is_enabled": is_enabled,
		"created_timestamp": created_timestamp
	}

static func from_dict(data: Dictionary) -> Automation:
	var automation = Automation.new()
	automation.automation_id = data.get("automation_id", automation.automation_id)
	automation.automation_name = data.get("automation_name", "Unnamed Automation")
	automation.is_enabled = data.get("is_enabled", true)
	automation.created_timestamp = data.get("created_timestamp", 0)
	
	# Restore trigger
	if data.has("trigger"):
		automation.trigger = AutomationTrigger.from_dict(data.trigger)
	
	# Restore conditions
	if data.has("conditions"):
		for condition_data in data.conditions:
			automation.conditions.append(AutomationCondition.from_dict(condition_data))
	
	# Restore actions
	if data.has("actions"):
		for action_data in data.actions:
			automation.actions.append(AutomationAction.from_dict(action_data))
	
	return automation
