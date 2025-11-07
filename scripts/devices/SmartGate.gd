extends SmartDevice

@onready var gate_panel: Node3D = $GatePanel

func _ready() -> void:
	super._ready()
	device_type = "gate"
	
	# Initialize state
	current_state = {
		"open": false
	}
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not gate_panel:
		return
	
	# Handle open/close state with sliding animation
	if new_state.has("open"):
		var target_position = 3.0 if new_state["open"] else 0.0  # Slide 3 meters to the side
		var tween = create_tween()
		tween.tween_property(gate_panel, "position:x", target_position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func toggle() -> void:
	set_state({"open": not current_state.get("open", false)})
