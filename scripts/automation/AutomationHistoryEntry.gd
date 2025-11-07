class_name AutomationHistoryEntry
extends Resource

@export var automation_id: String = ""
@export var automation_name: String = ""
@export var timestamp: int = 0
@export var trigger_reason: String = ""
@export var actions_performed: Array = []  # Array of Dictionary
@export var affected_devices: Array = []  # Array of String (device_ids)
@export var success: bool = true
@export var error_message: String = ""

func _init():
	timestamp = Time.get_unix_time_from_system()

func to_dict() -> Dictionary:
	return {
		"automation_id": automation_id,
		"automation_name": automation_name,
		"timestamp": timestamp,
		"trigger_reason": trigger_reason,
		"actions_performed": actions_performed,
		"affected_devices": affected_devices,
		"success": success,
		"error_message": error_message
	}

static func from_dict(data: Dictionary) -> AutomationHistoryEntry:
	var entry = AutomationHistoryEntry.new()
	entry.automation_id = data.get("automation_id", "")
	entry.automation_name = data.get("automation_name", "")
	entry.timestamp = data.get("timestamp", 0)
	entry.trigger_reason = data.get("trigger_reason", "")
	entry.actions_performed = data.get("actions_performed", [])
	entry.affected_devices = data.get("affected_devices", [])
	entry.success = data.get("success", true)
	entry.error_message = data.get("error_message", "")
	return entry

func get_formatted_timestamp() -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
