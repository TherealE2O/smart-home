extends SmartDevice

@onready var garage_door: Node3D = $DoorPanel

func _ready() -> void:
	super._ready()
	device_type = "garage"
	
	# Initialize state
	current_state = {
		"open": false
	}
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not garage_door:
		return
	
	# Handle open/close state with upward sliding animation
	if new_state.has("open"):
		var target_position = 2.5 if new_state["open"] else 0.0  # Slide up 2.5 meters
		var tween = create_tween()
		tween.tween_property(garage_door, "position:y", target_position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func toggle() -> void:
	set_state({"open": not current_state.get("open", false)})
