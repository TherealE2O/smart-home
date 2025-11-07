extends SmartDevice

@onready var effect_spawn: Node3D = $EffectSpawn
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var particles: GPUParticles3D

func _ready() -> void:
	super._ready()
	device_type = "heater"
	
	# Initialize state
	current_state = {
		"on": false,
		"temperature": 22.0
	}
	
	# Create particle effect for heat
	_setup_particles()
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _setup_particles() -> void:
	if not effect_spawn:
		return
	
	particles = GPUParticles3D.new()
	particles.amount = 15
	particles.lifetime = 2.0
	particles.emitting = false
	effect_spawn.add_child(particles)
	
	# Create particle material for heat waves
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 0.3
	material.initial_velocity_max = 0.8
	material.gravity = Vector3(0, 0.5, 0)  # Slight upward drift
	particles.process_material = material

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	# Handle on/off state
	if new_state.has("on"):
		if particles:
			particles.emitting = new_state["on"]
		
		# Add visual feedback to mesh with warm glow
		if mesh_instance and new_state["on"]:
			var material = mesh_instance.get_active_material(0)
			if not material:
				material = StandardMaterial3D.new()
				mesh_instance.set_surface_override_material(0, material)
			
			if material is StandardMaterial3D:
				material.emission_enabled = true
				material.emission = Color(1.0, 0.4, 0.0)  # Orange/warm glow
				var tween = create_tween()
				tween.tween_property(material, "emission_energy", 1.2, 0.3)
		elif mesh_instance and not new_state["on"]:
			var material = mesh_instance.get_active_material(0)
			if material is StandardMaterial3D:
				var tween = create_tween()
				tween.tween_property(material, "emission_energy", 0.0, 0.3)
				await tween.finished
				material.emission_enabled = false
	
	# Handle temperature changes (affects particle intensity)
	if new_state.has("temperature") and current_state.get("on", false) and particles:
		var temp_factor = (new_state["temperature"] - 15.0) / 15.0  # Scale 15-30°C to 0-1
		particles.amount = int(15 * clamp(temp_factor, 0.3, 1.5))

func toggle() -> void:
	set_state({"on": not current_state.get("on", false)})
