extends SmartDevice

@onready var door_pivot: Node3D = $DoorPivot

func _ready() -> void:
	super._ready()
	device_type = "door"
	
	# Initialize state
	current_state = {
		"open": false,
		"locked": false
	}
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not door_pivot:
		return
	
	# Handle locked state
	if new_state.has("locked"):
		is_interactable = not new_state["locked"]
	
	# Handle open/close state
	if new_state.has("open"):
		var target_rotation = -90.0 if new_state["open"] else 0.0
		var tween = create_tween()
		tween.tween_property(door_pivot, "rotation_degrees:y", target_rotation, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func toggle() -> void:
	if not current_state.get("locked", false):
		set_state({"open": not current_state.get("open", false)})
