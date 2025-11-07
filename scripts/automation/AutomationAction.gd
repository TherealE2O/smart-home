class_name AutomationAction
extends Resource

@export var target_device_id: String = ""
@export var action_type: String = "set_state"  # "set_state", "toggle", "animate"
@export var parameters: Dictionary = {}

func _init(device_id: String = "", type: String = "set_state", params: Dictionary = {}):
	target_device_id = device_id
	action_type = type
	parameters = params

func execute() -> bool:
	if target_device_id.is_empty():
		push_error("AutomationAction: target_device_id is empty")
		return false
	
	var device = DeviceRegistry.get_device(target_device_id)
	if device == null:
		push_error("AutomationAction: Device not found: " + target_device_id)
		return false
	
	match action_type:
		"set_state":
			device.set_state(parameters)
			return true
		"toggle":
			device.toggle()
			return true
		"animate":
			# Custom animation logic if needed
			device.set_state(parameters)
			return true
		_:
			push_warning("AutomationAction: Unknown action_type: " + action_type)
			return false

func to_dict() -> Dictionary:
	return {
		"target_device_id": target_device_id,
		"action_type": action_type,
		"parameters": parameters
	}

static func from_dict(data: Dictionary) -> AutomationAction:
	var action = AutomationAction.new()
	action.target_device_id = data.get("target_device_id", "")
	action.action_type = data.get("action_type", "set_state")
	action.parameters = data.get("parameters", {})
	return action
