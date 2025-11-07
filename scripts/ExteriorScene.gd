extends Node3D

@onready var smart_gate: Node3D = $SmartGate
@onready var smart_garage: Node3D = $SmartGarage
@onready var gate_trigger: Area3D = $SmartGate/GateTrigger
@onready var garage_trigger: Area3D = $SmartGarage/GarageTrigger
@onready var interior_transition_trigger: Area3D = $InteriorTransitionTrigger

var gate_opened: bool = false
var garage_opened: bool = false
var transition_triggered: bool = false

func _ready() -> void:
	# Connect trigger signals
	if gate_trigger:
		gate_trigger.body_entered.connect(_on_gate_trigger_entered)
	if garage_trigger:
		garage_trigger.body_entered.connect(_on_garage_trigger_entered)
	if interior_transition_trigger:
		interior_transition_trigger.body_entered.connect(_on_interior_transition_trigger_entered)
	
	# Register devices with DeviceRegistry
	if smart_gate and smart_gate.has_method("_ready"):
		smart_gate.device_id = "gate_exterior"
		smart_gate.device_name = "Exterior Gate"
		DeviceRegistry.register_device(smart_gate)
	
	if smart_garage and smart_garage.has_method("_ready"):
		smart_garage.device_id = "garage_exterior"
		smart_garage.device_name = "Garage Door"
		DeviceRegistry.register_device(smart_garage)

func _on_gate_trigger_entered(body: Node3D) -> void:
	if body is VehicleBody3D and not gate_opened:
		gate_opened = true
		if smart_gate and smart_gate.has_method("set_state"):
			smart_gate.set_state({"open": true})
			print("Gate opening automatically")

func _on_garage_trigger_entered(body: Node3D) -> void:
	if body is VehicleBody3D and not garage_opened:
		garage_opened = true
		if smart_garage and smart_garage.has_method("set_state"):
			smart_garage.set_state({"open": true})
			print("Garage opening automatically")

func _on_interior_transition_trigger_entered(body: Node3D) -> void:
	if body is VehicleBody3D and not transition_triggered:
		transition_triggered = true
		print("Transitioning to interior scene...")
		# Wait a moment for the vehicle to settle
		await get_tree().create_timer(1.0).timeout
		# Transition to interior scene
		SceneManager.change_scene("res://scenes/InteriorScene.tscn", true)
