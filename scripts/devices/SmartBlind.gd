extends SmartDevice

@onready var blind_panel: Node3D = $BlindPanel

func _ready() -> void:
	super._ready()
	device_type = "blind"
	
	# Initialize state
	current_state = {
		"position": 1.0  # 0.0 = fully up, 1.0 = fully down
	}
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not blind_panel:
		return
	
	# Handle position changes (vertical movement)
	if new_state.has("position"):
		var target_y = new_state["position"] * 0.75  # Scale to blind height
		var tween = create_tween()
		tween.tween_property(blind_panel, "position:y", -target_y, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func toggle() -> void:
	var new_position = 0.0 if current_state.get("position", 1.0) > 0.5 else 1.0
	set_state({"position": new_position})
