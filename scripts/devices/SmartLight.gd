extends SmartDevice

@onready var light: OmniLight3D = $Light

func _ready() -> void:
	super._ready()
	device_type = "light"
	
	# Initialize state
	current_state = {
		"on": false,
		"brightness": 1.0
	}
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not light:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Handle on/off state
	if new_state.has("on"):
		light.visible = new_state["on"]
		if new_state["on"]:
			tween.tween_property(light, "light_energy", new_state.get("brightness", 1.0), 0.3)
		else:
			tween.tween_property(light, "light_energy", 0.0, 0.3)
	
	# Handle brightness changes
	elif new_state.has("brightness") and current_state.get("on", false):
		tween.tween_property(light, "light_energy", new_state["brightness"], 0.3)

func toggle() -> void:
	set_state({"on": not current_state.get("on", false)})
