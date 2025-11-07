extends Node

## InteractionManager - Handles device interaction via raycasting and highlighting

signal device_hovered(device: SmartDevice)
signal device_unhovered(device: SmartDevice)
signal device_clicked(device: SmartDevice)

var camera: Camera3D = null
var raycast_length: float = 100.0
var highlighted_device: SmartDevice = null
var device_label: Label3D = null

# Highlight material
var highlight_material: StandardMaterial3D = null

func _ready() -> void:
	# Create highlight material with emission
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(1.0, 1.0, 0.5, 1.0)
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(1.0, 1.0, 0.3, 1.0)
	highlight_material.emission_energy_multiplier = 2.0
	
	# Create device label
	device_label = Label3D.new()
	device_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	device_label.no_depth_test = true
	device_label.fixed_size = true
	device_label.pixel_size = 0.005
	device_label.outline_size = 8
	device_label.font_size = 32
	device_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	device_label.visible = false
	add_child(device_label)

func _physics_process(_delta: float) -> void:
	if camera and camera.is_inside_tree():
		_perform_raycast()

func set_camera(new_camera: Camera3D) -> void:
	"""Set the active camera for raycasting"""
	camera = new_camera

func _perform_raycast() -> void:
	"""Perform raycast from camera center to detect devices"""
	if not camera:
		return
	
	# Get viewport and mouse position (center of screen)
	var viewport = camera.get_viewport()
	if not viewport:
		return
	
	var screen_center = viewport.get_visible_rect().size / 2.0
	
	# Create ray from camera
	var from = camera.project_ray_origin(screen_center)
	var to = from + camera.project_ray_normal(screen_center) * raycast_length
	
	# Perform raycast
	var space_state = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Check if we hit a device
		var collider = result.collider
		var device = _find_device_from_collider(collider)
		
		if device and device.is_interactable:
			if device != highlighted_device:
				_unhighlight_device()
				_highlight_device(device)
		else:
			_unhighlight_device()
	else:
		_unhighlight_device()

func _find_device_from_collider(collider: Node) -> SmartDevice:
	"""Find SmartDevice parent from collider node"""
	var current = collider
	while current:
		if current is SmartDevice:
			return current
		current = current.get_parent()
	return null

func _highlight_device(device: SmartDevice) -> void:
	"""Highlight the device and show its name label"""
	if not device:
		return
	
	highlighted_device = device
	
	# Apply highlight effect to all MeshInstance3D children
	_apply_highlight_to_meshes(device, true)
	
	# Show device name label
	if device_label:
		device_label.text = device.device_name
		device_label.global_position = device.global_position + Vector3(0, 1.5, 0)
		device_label.visible = true
	
	device_hovered.emit(device)

func _unhighlight_device() -> void:
	"""Remove highlight from current device"""
	if highlighted_device:
		# Remove highlight effect
		_apply_highlight_to_meshes(highlighted_device, false)
		
		device_unhovered.emit(highlighted_device)
		highlighted_device = null
	
	# Hide label
	if device_label:
		device_label.visible = false

func _apply_highlight_to_meshes(device: SmartDevice, apply: bool) -> void:
	"""Apply or remove highlight material to all mesh instances in device"""
	for child in _get_all_children(device):
		if child is MeshInstance3D:
			if apply:
				# Store original material and apply highlight
				if not child.has_meta("original_material"):
					var original_mat = child.get_surface_override_material(0)
					if original_mat:
						child.set_meta("original_material", original_mat)
				child.set_surface_override_material(0, highlight_material)
			else:
				# Restore original material
				if child.has_meta("original_material"):
					var original_mat = child.get_meta("original_material")
					child.set_surface_override_material(0, original_mat)
					child.remove_meta("original_material")
				else:
					child.set_surface_override_material(0, null)

func _get_all_children(node: Node) -> Array:
	"""Recursively get all children of a node"""
	var children = []
	for child in node.get_children():
		children.append(child)
		children.append_array(_get_all_children(child))
	return children

func _input(event: InputEvent) -> void:
	"""Handle click events on highlighted device"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if highlighted_device:
				device_clicked.emit(highlighted_device)
