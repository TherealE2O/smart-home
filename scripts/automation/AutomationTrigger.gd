class_name AutomationTrigger
extends Resource

enum TriggerType { TIME, DEVICE_STATE, MANUAL }

@export var trigger_type: TriggerType = TriggerType.MANUAL
@export var parameters: Dictionary = {}

# TIME parameters: {hour: int, minute: int, days: Array}
# DEVICE_STATE parameters: {device_id: String, state_key: String, value: Variant}
# MANUAL parameters: {} (empty, triggered manually)

func _init(type: TriggerType = TriggerType.MANUAL, params: Dictionary = {}):
	trigger_type = type
	parameters = params

func evaluate() -> bool:
	match trigger_type:
		TriggerType.TIME:
			return _evaluate_time_trigger()
		TriggerType.DEVICE_STATE:
			return _evaluate_device_state_trigger()
		TriggerType.MANUAL:
			return false  # Manual triggers don't auto-evaluate
	return false

func _evaluate_time_trigger() -> bool:
	if not parameters.has("hour") or not parameters.has("minute"):
		return false
	
	var current_time = Time.get_datetime_dict_from_system()
	var target_hour = parameters.get("hour", 0)
	var target_minute = parameters.get("minute", 0)
	
	# Check if current time matches trigger time (within 1 minute window)
	if current_time.hour == target_hour and current_time.minute == target_minute:
		# Optional: Check days of week if specified
		if parameters.has("days") and parameters.days.size() > 0:
			var current_day = current_time.weekday
			return current_day in parameters.days
		return true
	
	return false

func _evaluate_device_state_trigger() -> bool:
	if not parameters.has("device_id") or not parameters.has("state_key"):
		return false
	
	var device = DeviceRegistry.get_device(parameters.device_id)
	if device == null:
		return false
	
	var device_state = device.get_state()
	if not device_state.has(parameters.state_key):
		return false
	
	var expected_value = parameters.get("value")
	var actual_value = device_state[parameters.state_key]
	
	return actual_value == expected_value

func to_dict() -> Dictionary:
	return {
		"trigger_type": trigger_type,
		"parameters": parameters
	}

static func from_dict(data: Dictionary) -> AutomationTrigger:
	var trigger = AutomationTrigger.new()
	trigger.trigger_type = data.get("trigger_type", TriggerType.MANUAL)
	trigger.parameters = data.get("parameters", {})
	return trigger
