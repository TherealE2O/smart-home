extends Control
## Automation Editor Scene
## Visual node-based editor for creating smart home automations

@onready var graph_edit: GraphEdit = $VBoxContainer/MainContent/GraphEdit
@onready var automation_name_edit: LineEdit = $VBoxContainer/Toolbar/AutomationNameEdit
@onready var status_label: Label = $VBoxContainer/StatusBar/MarginContainer/StatusLabel

# Current automation being edited
var current_automation: Automation = null

# Node counter for unique IDs
var node_counter: int = 0

# Track connections
var connections: Array = []

func _ready() -> void:
	# Configure GraphEdit
	graph_edit.show_grid = true
	graph_edit.snap_distance = 20
	graph_edit.zoom = 1.0
	graph_edit.zoom_min = 0.5
	graph_edit.zoom_max = 2.0
	
	# Initialize new automation
	_create_new_automation()
	
	_update_status("Ready - Add nodes from the palette")

## Create a new empty automation
func _create_new_automation() -> void:
	current_automation = Automation.new()
	automation_name_edit.text = current_automation.automation_name
	_update_status("New automation created")

## Update status bar message
func _update_status(message: String) -> void:
	status_label.text = message
	print("AutomationEditor: " + message)

## Add a time trigger node
func _on_time_trigger_button_pressed() -> void:
	var trigger_node = preload("res://scripts/TriggerNode.gd").new()
	trigger_node.setup_as_time_trigger()
	trigger_node.name = "TriggerNode_" + str(node_counter)
	node_counter += 1
	
	# Position new node
	var scroll_offset = graph_edit.scroll_offset
	trigger_node.position_offset = Vector2(100, 100) + scroll_offset / graph_edit.zoom
	
	graph_edit.add_child(trigger_node)
	_update_status("Added Time Trigger node")

## Add a device state trigger node
func _on_device_state_trigger_button_pressed() -> void:
	var trigger_node = preload("res://scripts/TriggerNode.gd").new()
	trigger_node.setup_as_device_state_trigger()
	trigger_node.name = "TriggerNode_" + str(node_counter)
	node_counter += 1
	
	var scroll_offset = graph_edit.scroll_offset
	trigger_node.position_offset = Vector2(100, 100) + scroll_offset / graph_edit.zoom
	
	graph_edit.add_child(trigger_node)
	_update_status("Added Device State Trigger node")

## Add a manual trigger node
func _on_manual_trigger_button_pressed() -> void:
	var trigger_node = preload("res://scripts/TriggerNode.gd").new()
	trigger_node.setup_as_manual_trigger()
	trigger_node.name = "TriggerNode_" + str(node_counter)
	node_counter += 1
	
	var scroll_offset = graph_edit.scroll_offset
	trigger_node.position_offset = Vector2(100, 100) + scroll_offset / graph_edit.zoom
	
	graph_edit.add_child(trigger_node)
	_update_status("Added Manual Trigger node")

## Add a device action node
func _on_device_action_button_pressed() -> void:
	var action_node = preload("res://scripts/ActionNode.gd").new()
	action_node.name = "ActionNode_" + str(node_counter)
	node_counter += 1
	
	var scroll_offset = graph_edit.scroll_offset
	action_node.position_offset = Vector2(400, 100) + scroll_offset / graph_edit.zoom
	
	graph_edit.add_child(action_node)
	_update_status("Added Device Action node")

## Handle connection requests
func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	# Validate connection
	var from_node_obj = graph_edit.get_node(NodePath(from_node))
	var to_node_obj = graph_edit.get_node(NodePath(to_node))
	
	if not from_node_obj or not to_node_obj:
		_update_status("Error: Invalid nodes for connection")
		return
	
	# Check if connection already exists
	for conn in connections:
		if conn.from_node == from_node and conn.from_port == from_port and conn.to_node == to_node and conn.to_port == to_port:
			_update_status("Connection already exists")
			return
	
	# Validate: Trigger nodes should connect TO action nodes (trigger is source)
	var is_valid = _validate_connection(from_node_obj, to_node_obj)
	
	if is_valid:
		graph_edit.connect_node(from_node, from_port, to_node, to_port)
		connections.append({
			"from_node": from_node,
			"from_port": from_port,
			"to_node": to_node,
			"to_port": to_port
		})
		_update_status("Connected: %s -> %s" % [from_node, to_node])
	else:
		_update_status("Invalid connection: Triggers must connect to Actions")

## Validate connection between nodes
func _validate_connection(from_node: Node, to_node: Node) -> bool:
	# Trigger nodes should output to Action nodes
	var from_script = from_node.get_script()
	var to_script = to_node.get_script()
	
	if from_script == null or to_script == null:
		return false
	
	var from_script_path = from_script.resource_path
	var to_script_path = to_script.resource_path
	
	# Trigger -> Action is valid
	if "TriggerNode" in from_script_path and "ActionNode" in to_script_path:
		return true
	
	# Action -> Action is valid (chaining actions)
	if "ActionNode" in from_script_path and "ActionNode" in to_script_path:
		return true
	
	return false

## Handle disconnection requests
func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	
	# Remove from connections array
	for i in range(connections.size() - 1, -1, -1):
		var conn = connections[i]
		if conn.from_node == from_node and conn.from_port == from_port and conn.to_node == to_node and conn.to_port == to_port:
			connections.remove_at(i)
			break
	
	_update_status("Disconnected: %s -> %s" % [from_node, to_node])

## Handle node deletion
func _on_graph_edit_delete_nodes_request(nodes: Array) -> void:
	for node_name in nodes:
		var node = graph_edit.get_node_or_null(NodePath(node_name))
		if node:
			# Remove all connections involving this node
			for i in range(connections.size() - 1, -1, -1):
				var conn = connections[i]
				if conn.from_node == node_name or conn.to_node == node_name:
					graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
					connections.remove_at(i)
			
			node.queue_free()
			_update_status("Deleted node: %s" % node_name)

## Save automation
func _on_save_button_pressed() -> void:
	var result = save_automation()
	if result.success:
		_update_status("Automation saved: %s" % result.automation.automation_name)
	else:
		_update_status("Error: %s" % result.error)

## Test automation immediately
func _on_test_button_pressed() -> void:
	var result = save_automation()
	if not result.success:
		_update_status("Error: Cannot test - %s" % result.error)
		return
	
	test_current_automation(result.automation)

## Clear all nodes
func _on_clear_button_pressed() -> void:
	# Clear all nodes
	for child in graph_edit.get_children():
		if child is GraphNode:
			child.queue_free()
	
	connections.clear()
	_create_new_automation()
	_update_status("Editor cleared")

## Close editor
func _on_close_button_pressed() -> void:
	# Return to previous scene (interior scene)
	SceneManager.change_scene("res://scenes/InteriorScene.tscn")

## Save automation and convert graph to Automation resource
func save_automation() -> Dictionary:
	# Validate automation name
	var auto_name = automation_name_edit.text.strip_edges()
	if auto_name.is_empty():
		return {"success": false, "error": "Automation name is required"}
	
	# Find trigger nodes
	var trigger_nodes = []
	var action_nodes = []
	
	for child in graph_edit.get_children():
		if child is GraphNode:
			var script = child.get_script()
			if script:
				var script_path = script.resource_path
				if "TriggerNode" in script_path:
					trigger_nodes.append(child)
				elif "ActionNode" in script_path:
					action_nodes.append(child)
	
	# Validate: Must have at least one trigger
	if trigger_nodes.is_empty():
		return {"success": false, "error": "At least one trigger node is required"}
	
	# Validate: Must have at least one action
	if action_nodes.is_empty():
		return {"success": false, "error": "At least one action node is required"}
	
	# Validate: Trigger must be connected to at least one action
	var trigger_connected = false
	for conn in connections:
		var from_node = graph_edit.get_node_or_null(NodePath(conn.from_node))
		if from_node in trigger_nodes:
			trigger_connected = true
			break
	
	if not trigger_connected:
		return {"success": false, "error": "Trigger must be connected to at least one action"}
	
	# Create automation
	var automation = Automation.new()
	automation.automation_name = auto_name
	automation.automation_id = "auto_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	automation.created_timestamp = Time.get_unix_time_from_system()
	
	# Use first trigger node (for simplicity, could be extended to support multiple)
	var trigger_node = trigger_nodes[0]
	automation.trigger = trigger_node.get_trigger()
	
	# Collect all connected action nodes
	var connected_actions = _get_connected_actions(trigger_nodes)
	
	for action_node in connected_actions:
		var action = action_node.get_action()
		if action:
			automation.actions.append(action)
	
	# Add to AutomationEngine
	AutomationEngine.add_automation(automation)
	
	return {"success": true, "automation": automation}

## Get all action nodes connected to trigger nodes
func _get_connected_actions(trigger_nodes: Array) -> Array:
	var connected_actions = []
	var visited = {}
	
	# Start from trigger nodes and traverse connections
	for trigger in trigger_nodes:
		_traverse_actions(trigger.name, connected_actions, visited)
	
	return connected_actions

## Recursively traverse action nodes
func _traverse_actions(node_name: String, result: Array, visited: Dictionary) -> void:
	if visited.has(node_name):
		return
	
	visited[node_name] = true
	
	# Find all connections from this node
	for conn in connections:
		if conn.from_node == node_name:
			var to_node = graph_edit.get_node_or_null(NodePath(conn.to_node))
			if to_node and to_node is GraphNode:
				var script = to_node.get_script()
				if script and "ActionNode" in script.resource_path:
					if not to_node in result:
						result.append(to_node)
					# Continue traversing (for action chaining)
					_traverse_actions(conn.to_node, result, visited)

## Test automation immediately
func test_current_automation(automation: Automation) -> void:
	_update_status("Testing automation: %s" % automation.automation_name)
	
	var history_entry = AutomationEngine.test_automation(automation)
	
	if history_entry:
		var actions_count = history_entry.actions_performed.size()
		var devices_count = history_entry.affected_devices.size()
		var success_text = "Success" if history_entry.success else "Failed"
		
		_update_status("Test complete: %s - %d actions on %d devices" % [success_text, actions_count, devices_count])
		
		# Show detailed results
		var details = "Test Results:\n"
		for action_data in history_entry.actions_performed:
			var device_id = action_data.get("device_id", "unknown")
			var action_type = action_data.get("action_type", "unknown")
			var success = action_data.get("success", false)
			details += "  - %s: %s (%s)\n" % [device_id, action_type, "OK" if success else "FAILED"]
		
		print(details)
	else:
		_update_status("Test failed: Could not execute automation")
