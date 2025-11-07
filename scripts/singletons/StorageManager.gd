extends Node
# StorageManager.gd
# Singleton for managing browser LocalStorage persistence
# Provides a simple interface for saving and loading data with JSON serialization

signal storage_ready
signal storage_unavailable

var _is_web: bool = false
var _storage_available: bool = false

# Storage keys
const KEY_USER_AUTOMATIONS = "smart_home_user_automations"
const KEY_DEVICE_STATES = "smart_home_device_states"
const KEY_SETTINGS = "smart_home_settings"
const KEY_TUTORIAL_COMPLETED = "smart_home_tutorial_completed"

func _ready() -> void:
	_is_web = OS.has_feature("web")
	
	if _is_web:
		_check_storage_availability()
	else:
		# For desktop testing, use file-based storage
		_storage_available = true
		storage_ready.emit()
		print("StorageManager: Running in non-web mode, using file-based storage")

func _check_storage_availability() -> void:
	# Check if localStorage is available
	if _is_web:
		var result = JavaScriptBridge.eval("typeof(Storage) !== 'undefined'", true)
		_storage_available = result
		
		if _storage_available:
			storage_ready.emit()
			print("StorageManager: LocalStorage is available")
		else:
			storage_unavailable.emit()
			push_warning("StorageManager: LocalStorage is not available")
	else:
		_storage_available = true
		storage_ready.emit()

func is_available() -> bool:
	return _storage_available

## Save data to storage with JSON serialization
func save_data(key: String, data: Variant) -> bool:
	if not _storage_available:
		push_warning("StorageManager: Storage not available")
		return false
	
	var json_string = JSON.stringify(data)
	
	if _is_web:
		# Use JavaScript bridge for web
		var js_code = """
		try {
			localStorage.setItem('%s', '%s');
			true;
		} catch (e) {
			console.error('Failed to save to localStorage:', e);
			false;
		}
		""" % [key, json_string.replace("'", "\\'")]
		
		var result = JavaScriptBridge.eval(js_code, true)
		return result
	else:
		# Use file-based storage for desktop testing
		return _save_to_file(key, json_string)

## Load data from storage with JSON deserialization
func load_data(key: String) -> Variant:
	if not _storage_available:
		push_warning("StorageManager: Storage not available")
		return null
	
	var json_string: String = ""
	
	if _is_web:
		# Use JavaScript bridge for web
		var js_code = """
		try {
			var value = localStorage.getItem('%s');
			value !== null ? value : '';
		} catch (e) {
			console.error('Failed to load from localStorage:', e);
			'';
		}
		""" % [key]
		
		json_string = JavaScriptBridge.eval(js_code, true)
	else:
		# Use file-based storage for desktop testing
		json_string = _load_from_file(key)
	
	if json_string == "" or json_string == null:
		return null
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("StorageManager: Failed to parse JSON for key '%s': %s" % [key, json.get_error_message()])
		return null
	
	return json.data

## Remove data from storage
func remove_data(key: String) -> bool:
	if not _storage_available:
		return false
	
	if _is_web:
		var js_code = """
		try {
			localStorage.removeItem('%s');
			true;
		} catch (e) {
			console.error('Failed to remove from localStorage:', e);
			false;
		}
		""" % [key]
		
		var result = JavaScriptBridge.eval(js_code, true)
		return result
	else:
		return _remove_file(key)

## Clear all storage
func clear_all() -> bool:
	if not _storage_available:
		return false
	
	if _is_web:
		var js_code = """
		try {
			localStorage.clear();
			true;
		} catch (e) {
			console.error('Failed to clear localStorage:', e);
			false;
		}
		"""
		
		var result = JavaScriptBridge.eval(js_code, true)
		return result
	else:
		return _clear_all_files()

## Save user automations
func save_user_automations(automations: Array) -> bool:
	var automation_data = []
	for automation in automations:
		if automation is Automation:
			automation_data.append(_serialize_automation(automation))
	
	return save_data(KEY_USER_AUTOMATIONS, automation_data)

## Load user automations
func load_user_automations() -> Array:
	var data = load_data(KEY_USER_AUTOMATIONS)
	if data == null:
		return []
	
	var automations = []
	for automation_dict in data:
		var automation = _deserialize_automation(automation_dict)
		if automation != null:
			automations.append(automation)
	
	return automations

## Save device states
func save_device_states(states: Dictionary) -> bool:
	return save_data(KEY_DEVICE_STATES, states)

## Load device states
func load_device_states() -> Dictionary:
	var data = load_data(KEY_DEVICE_STATES)
	if data == null:
		return {}
	return data

## Save settings
func save_settings(settings: Dictionary) -> bool:
	return save_data(KEY_SETTINGS, settings)

## Load settings
func load_settings() -> Dictionary:
	var data = load_data(KEY_SETTINGS)
	if data == null:
		return {
			"graphics_quality": "medium",
			"audio_enabled": true,
			"tutorial_completed": false
		}
	return data

## Save tutorial completion status
func save_tutorial_completed(completed: bool) -> bool:
	return save_data(KEY_TUTORIAL_COMPLETED, completed)

## Load tutorial completion status
func load_tutorial_completed() -> bool:
	var data = load_data(KEY_TUTORIAL_COMPLETED)
	if data == null:
		return false
	return data

# Helper methods for serialization
func _serialize_automation(automation: Automation) -> Dictionary:
	return {
		"automation_id": automation.automation_id,
		"automation_name": automation.automation_name,
		"trigger": _serialize_trigger(automation.trigger),
		"conditions": _serialize_conditions(automation.conditions),
		"actions": _serialize_actions(automation.actions),
		"is_enabled": automation.is_enabled,
		"created_timestamp": automation.created_timestamp
	}

func _serialize_trigger(trigger: AutomationTrigger) -> Dictionary:
	if trigger == null:
		return {}
	
	return {
		"trigger_type": trigger.trigger_type,
		"parameters": trigger.parameters
	}

func _serialize_conditions(conditions: Array) -> Array:
	var result = []
	for condition in conditions:
		if condition is AutomationCondition:
			result.append({
				"device_id": condition.device_id,
				"state_key": condition.state_key,
				"operator": condition.operator,
				"value": condition.value
			})
	return result

func _serialize_actions(actions: Array) -> Array:
	var result = []
	for action in actions:
		if action is AutomationAction:
			result.append({
				"target_device_id": action.target_device_id,
				"action_type": action.action_type,
				"parameters": action.parameters
			})
	return result

func _deserialize_automation(data: Dictionary) -> Automation:
	var automation = Automation.new()
	automation.automation_id = data.get("automation_id", "")
	automation.automation_name = data.get("automation_name", "")
	automation.trigger = _deserialize_trigger(data.get("trigger", {}))
	automation.conditions = _deserialize_conditions(data.get("conditions", []))
	automation.actions = _deserialize_actions(data.get("actions", []))
	automation.is_enabled = data.get("is_enabled", true)
	automation.created_timestamp = data.get("created_timestamp", 0)
	return automation

func _deserialize_trigger(data: Dictionary) -> AutomationTrigger:
	if data.is_empty():
		return null
	
	var trigger = AutomationTrigger.new()
	trigger.trigger_type = data.get("trigger_type", AutomationTrigger.TriggerType.MANUAL)
	trigger.parameters = data.get("parameters", {})
	return trigger

func _deserialize_conditions(data: Array) -> Array:
	var conditions = []
	for condition_dict in data:
		var condition = AutomationCondition.new()
		condition.device_id = condition_dict.get("device_id", "")
		condition.state_key = condition_dict.get("state_key", "")
		condition.operator = condition_dict.get("operator", "==")
		condition.value = condition_dict.get("value", null)
		conditions.append(condition)
	return conditions

func _deserialize_actions(data: Array) -> Array:
	var actions = []
	for action_dict in data:
		var action = AutomationAction.new()
		action.target_device_id = action_dict.get("target_device_id", "")
		action.action_type = action_dict.get("action_type", "")
		action.parameters = action_dict.get("parameters", {})
		actions.append(action)
	return actions

# File-based storage for desktop testing
func _get_storage_path() -> String:
	return "user://storage/"

func _get_file_path(key: String) -> String:
	return _get_storage_path() + key + ".json"

func _save_to_file(key: String, json_string: String) -> bool:
	DirAccess.make_dir_recursive_absolute(_get_storage_path())
	
	var file = FileAccess.open(_get_file_path(key), FileAccess.WRITE)
	if file == null:
		push_error("StorageManager: Failed to open file for writing: " + _get_file_path(key))
		return false
	
	file.store_string(json_string)
	file.close()
	return true

func _load_from_file(key: String) -> String:
	if not FileAccess.file_exists(_get_file_path(key)):
		return ""
	
	var file = FileAccess.open(_get_file_path(key), FileAccess.READ)
	if file == null:
		push_error("StorageManager: Failed to open file for reading: " + _get_file_path(key))
		return ""
	
	var content = file.get_as_text()
	file.close()
	return content

func _remove_file(key: String) -> bool:
	if FileAccess.file_exists(_get_file_path(key)):
		DirAccess.remove_absolute(_get_file_path(key))
		return true
	return false

func _clear_all_files() -> bool:
	var dir = DirAccess.open(_get_storage_path())
	if dir == null:
		return false
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	return true
