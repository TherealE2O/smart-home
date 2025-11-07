extends SmartDevice

@onready var effect_spawn: Node3D = $EffectSpawn
var particles: GPUParticles3D

func _ready() -> void:
	super._ready()
	device_type = "tap"
	
	# Initialize state
	current_state = {
		"on": false,
		"flow_rate": 1.0
	}
	
	# Create particle effect for water
	_setup_particles()
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _setup_particles() -> void:
	if not effect_spawn:
		return
	
	particles = GPUParticles3D.new()
	particles.amount = 25
	particles.lifetime = 1.0
	particles.emitting = false
	effect_spawn.add_child(particles)
	
	# Create particle material for water stream
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.spread = 5.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 3.0
	material.gravity = Vector3(0, -9.8, 0)
	particles.process_material = material

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not particles:
		return
	
	# Handle on/off state
	if new_state.has("on"):
		particles.emitting = new_state["on"]
	
	# Handle flow rate changes
	if new_state.has("flow_rate") and current_state.get("on", false):
		particles.amount = int(25 * new_state["flow_rate"])
		var material = particles.process_material as ParticleProcessMaterial
		if material:
			material.initial_velocity_min = 2.0 * new_state["flow_rate"]
			material.initial_velocity_max = 3.0 * new_state["flow_rate"]

func toggle() -> void:
	set_state({"on": not current_state.get("on", false)})
