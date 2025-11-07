extends SmartDevice

@onready var effect_spawn: Node3D = $EffectSpawn
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var particles: GPUParticles3D

func _ready() -> void:
	super._ready()
	device_type = "water_pump"
	
	# Initialize state
	current_state = {
		"on": false,
		"flow_rate": 1.0
	}
	
	# Create particle effect for water flow
	_setup_particles()
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _setup_particles() -> void:
	if not effect_spawn:
		return
	
	particles = GPUParticles3D.new()
	particles.amount = 30
	particles.lifetime = 1.5
	particles.emitting = false
	effect_spawn.add_child(particles)
	
	# Create particle material for water
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 15.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 2.0
	material.gravity = Vector3(0, -9.8, 0)
	particles.process_material = material

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not particles:
		return
	
	# Handle on/off state
	if new_state.has("on"):
		particles.emitting = new_state["on"]
		
		# Add visual feedback to mesh
		if mesh_instance and new_state["on"]:
			var material = mesh_instance.get_active_material(0)
			if not material:
				material = StandardMaterial3D.new()
				mesh_instance.set_surface_override_material(0, material)
			
			if material is StandardMaterial3D:
				material.emission_enabled = true
				material.emission = Color(0.0, 0.5, 1.0)  # Blue glow
				var tween = create_tween()
				tween.tween_property(material, "emission_energy", 0.8, 0.3)
		elif mesh_instance and not new_state["on"]:
			var material = mesh_instance.get_active_material(0)
			if material is StandardMaterial3D:
				var tween = create_tween()
				tween.tween_property(material, "emission_energy", 0.0, 0.3)
				await tween.finished
				material.emission_enabled = false
	
	# Handle flow rate changes
	if new_state.has("flow_rate") and current_state.get("on", false):
		particles.amount = int(30 * new_state["flow_rate"])

func toggle() -> void:
	set_state({"on": not current_state.get("on", false)})
