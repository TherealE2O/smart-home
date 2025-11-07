extends Node
## AutomationEngine singleton for managing automation rules
## Handles rule creation, evaluation, and execution

signal automation_triggered(rule_id: String)
signal automation_executed(rule_id: String)

## Automation rule structure
class AutomationRule:
	var id: String
	var name: String
	var enabled: bool = true
	var conditions: Array = []  # Array of condition dictionaries
	var actions: Array = []  # Array of action dictionaries
	
	func _init(p_id: String, p_name: String) -> void:
		id = p_id
		name = p_name

# Dictionary to store all automation rules
var rules: Dictionary = {}

# Track last evaluation time for time-based rules
var last_evaluation_time: float = 0.0

func _ready() -> void:
	# Connect to DeviceRegistry signals to evaluate rules on state changes
	DeviceRegistry.device_state_changed.connect(_on_device_state_changed)
	
	# Set up periodic evaluation for time-based rules
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_evaluate_time_based_rules)
	add_child(timer)
	timer.start()

## Create a new automation rule
func create_rule(rule_id: String, rule_name: String) -> AutomationRule:
	if rules.has(rule_id):
		push_warning("Rule %s already exists" % rule_id)
		return rules[rule_id]
	
	var rule = AutomationRule.new(rule_id, rule_name)
	rules[rule_id] = rule
	return rule

## Delete an automation rule
func delete_rule(rule_id: String) -> void:
	if rules.has(rule_id):
		rules.erase(rule_id)

## Get a rule by ID
func get_rule(rule_id: String) -> AutomationRule:
	return rules.get(rule_id, null)

## Get all rules
func get_all_rules() -> Array:
	return rules.values()

## Add a condition to a rule
func add_condition(rule_id: String, condition: Dictionary) -> void:
	var rule = get_rule(rule_id)
	if rule:
		rule.conditions.append(condition)

## Add an action to a rule
func add_action(rule_id: String, action: Dictionary) -> void:
	var rule = get_rule(rule_id)
	if rule:
		rule.actions.append(action)

## Enable or disable a rule
func set_rule_enabled(rule_id: String, enabled: bool) -> void:
	var rule = get_rule(rule_id)
	if rule:
		rule.enabled = enabled

## Evaluate all conditions for a rule
func evaluate_rule(rule_id: String) -> bool:
	var rule = get_rule(rule_id)
	if not rule or not rule.enabled:
		return false
	
	# All conditions must be true
	for condition in rule.conditions:
		if not _evaluate_condition(condition):
			return false
	
	return true

## Evaluate a single condition
func _evaluate_condition(condition: Dictionary) -> bool:
	var condition_type = condition.get("type", "")
	
	match condition_type:
		"device_state":
			var device_id = condition.get("device_id", "")
			var property = condition.get("property", "")
			var operator = condition.get("operator", "==")
			var value = condition.get("value")
			
			var current_value = DeviceRegistry.get_device_state(device_id, property)
			return _compare_values(current_value, operator, value)
		
		"time":
			var time_condition = condition.get("time", "")
			return _evaluate_time_condition(time_condition)
		
		_:
			push_warning("Unknown condition type: %s" % condition_type)
			return false

## Compare values based on operator
func _compare_values(current: Variant, operator: String, target: Variant) -> bool:
	match operator:
		"==": return current == target
		"!=": return current != target
		">": return current > target
		"<": return current < target
		">=": return current >= target
		"<=": return current <= target
		_: return false

## Evaluate time-based condition
func _evaluate_time_condition(time_condition: String) -> bool:
	# Placeholder for time evaluation logic
	# Would check current time against condition
	return false

## Execute all actions for a rule
func execute_rule(rule_id: String) -> void:
	var rule = get_rule(rule_id)
	if not rule:
		return
	
	automation_triggered.emit(rule_id)
	
	for action in rule.actions:
		_execute_action(action)
	
	automation_executed.emit(rule_id)

## Execute a single action
func _execute_action(action: Dictionary) -> void:
	var action_type = action.get("type", "")
	
	match action_type:
		"set_device_state":
			var device_id = action.get("device_id", "")
			var property = action.get("property", "")
			var value = action.get("value")
			DeviceRegistry.update_device_state(device_id, property, value)
		
		_:
			push_warning("Unknown action type: %s" % action_type)

## Called when a device state changes
func _on_device_state_changed(device_id: String, property: String, value: Variant) -> void:
	# Evaluate all rules that might be affected by this state change
	for rule in rules.values():
		if evaluate_rule(rule.id):
			execute_rule(rule.id)

## Periodically evaluate time-based rules
func _evaluate_time_based_rules() -> void:
	for rule in rules.values():
		if not rule.enabled:
			continue
		
		# Check if rule has time-based conditions
		var has_time_condition = false
		for condition in rule.conditions:
			if condition.get("type") == "time":
				has_time_condition = true
				break
		
		if has_time_condition and evaluate_rule(rule.id):
			execute_rule(rule.id)
