extends SmartDevice

@onready var water_level_indicator: Node3D = $WaterLevelIndicator

func _ready() -> void:
	super._ready()
	device_type = "water_tank"
	
	# Initialize state
	current_state = {
		"level": 0.75  # 0.0 = empty, 1.0 = full
	}
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not water_level_indicator:
		return
	
	# Handle water level changes
	if new_state.has("level"):
		var target_y = (new_state["level"] - 0.5) * 0.8  # Scale to tank height
		var tween = create_tween()
		tween.tween_property(water_level_indicator, "position:y", target_y, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
		# Update color based on level
		var mesh_instance = water_level_indicator.get_node_or_null("MeshInstance3D")
		if mesh_instance:
			var material = mesh_instance.get_active_material(0)
			if not material:
				material = StandardMaterial3D.new()
				mesh_instance.set_surface_override_material(0, material)
			
			if material is StandardMaterial3D:
				# Color changes from red (low) to blue (high)
				var color = Color(1.0 - new_state["level"], 0.3, new_state["level"])
				material.albedo_color = color

func toggle() -> void:
	# Toggle between empty and full
	var new_level = 1.0 if current_state.get("level", 0.5) < 0.5 else 0.0
	set_state({"level": new_level})
