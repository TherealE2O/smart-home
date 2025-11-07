class_name AutomationCondition
extends Resource

enum ConditionType { DEVICE_STATE, TIME_RANGE, ALWAYS }
enum Operator { EQUALS, NOT_EQUALS, GREATER_THAN, LESS_THAN, GREATER_EQUAL, LESS_EQUAL }

@export var condition_type: ConditionType = ConditionType.ALWAYS
@export var device_id: String = ""
@export var state_key: String = ""
@export var operator: Operator = Operator.EQUALS
@export var value: Variant = null

func _init(type: ConditionType = ConditionType.ALWAYS):
	condition_type = type

func evaluate() -> bool:
	match condition_type:
		ConditionType.ALWAYS:
			return true
		ConditionType.DEVICE_STATE:
			return _evaluate_device_state()
		ConditionType.TIME_RANGE:
			return _evaluate_time_range()
	return true

func _evaluate_device_state() -> bool:
	if device_id.is_empty() or state_key.is_empty():
		return false
	
	var device = DeviceRegistry.get_device(device_id)
	if device == null:
		return false
	
	var device_state = device.get_state()
	if not device_state.has(state_key):
		return false
	
	var actual_value = device_state[state_key]
	return _compare_values(actual_value, value, operator)

func _evaluate_time_range() -> bool:
	# Placeholder for time range evaluation
	return true

func _compare_values(actual: Variant, expected: Variant, op: Operator) -> bool:
	match op:
		Operator.EQUALS:
			return actual == expected
		Operator.NOT_EQUALS:
			return actual != expected
		Operator.GREATER_THAN:
			return actual > expected
		Operator.LESS_THAN:
			return actual < expected
		Operator.GREATER_EQUAL:
			return actual >= expected
		Operator.LESS_EQUAL:
			return actual <= expected
	return false

func to_dict() -> Dictionary:
	return {
		"condition_type": condition_type,
		"device_id": device_id,
		"state_key": state_key,
		"operator": operator,
		"value": value
	}

static func from_dict(data: Dictionary) -> AutomationCondition:
	var condition = AutomationCondition.new()
	condition.condition_type = data.get("condition_type", ConditionType.ALWAYS)
	condition.device_id = data.get("device_id", "")
	condition.state_key = data.get("state_key", "")
	condition.operator = data.get("operator", Operator.EQUALS)
	condition.value = data.get("value", null)
	return condition
