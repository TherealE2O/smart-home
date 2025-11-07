extends SmartDevice

@onready var effect_spawn: Node3D = $EffectSpawn
var particles: GPUParticles3D

func _ready() -> void:
	super._ready()
	device_type = "ac"
	
	# Initialize state
	current_state = {
		"on": false,
		"temperature": 22.0,
		"mode": "cool"
	}
	
	# Create particle effect for air flow
	_setup_particles()
	
	# Apply initial state
	_apply_state_change({}, current_state)

func _setup_particles() -> void:
	if not effect_spawn:
		return
	
	particles = GPUParticles3D.new()
	particles.amount = 20
	particles.lifetime = 2.0
	particles.emitting = false
	effect_spawn.add_child(particles)
	
	# Create simple particle material
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 1.0
	particles.process_material = material

func _apply_state_change(old_state: Dictionary, new_state: Dictionary) -> void:
	if not particles:
		return
	
	# Handle on/off state
	if new_state.has("on"):
		particles.emitting = new_state["on"]

func toggle() -> void:
	set_state({"on": not current_state.get("on", false)})
