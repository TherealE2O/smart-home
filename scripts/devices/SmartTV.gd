extends SmartDevice

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	super._ready()
	device_type = "tv"
	
	# Initialize state
	current_state = {
		"on": false,
		"channel": 1
	}
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not mesh_instance:
		return
	
	# Handle on/off state with emission
	if new_state.has("on"):
		var material = mesh_instance.get_active_material(0)
		if not material:
			material = StandardMaterial3D.new()
			mesh_instance.set_surface_override_material(0, material)
		
		if material is StandardMaterial3D:
			var tween = create_tween()
			if new_state["on"]:
				material.emission_enabled = true
				tween.tween_property(material, "emission_energy", 2.0, 0.3)
			else:
				tween.tween_property(material, "emission_energy", 0.0, 0.3)
				await tween.finished
				material.emission_enabled = false

func toggle() -> void:
	set_state({"on": not current_state.get("on", false)})
