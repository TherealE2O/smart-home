extends SmartDevice

@onready var window_panel: Node3D = $WindowPanel

func _ready() -> void:
	super._ready()
	device_type = "window"
	
	# Initialize state
	current_state = {
		"open": false,
		"position": 0.0  # 0.0 = closed, 1.0 = fully open
	}
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not window_panel:
		return
	
	# Handle open/close state
	if new_state.has("open"):
		var target_position = 0.6 if new_state["open"] else 0.0
		new_state["position"] = target_position
	
	# Handle position changes
	if new_state.has("position"):
		var target_y = new_state["position"] * 0.6  # Max 0.6m upward movement
		var tween = create_tween()
		tween.tween_property(window_panel, "position:y", target_y, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func toggle() -> void:
	set_state({"open": not current_state.get("open", false)})
