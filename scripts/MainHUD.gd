extends CanvasLayer
## MainHUD - Persistent HUD overlay for mode switching and navigation

signal mode_changed(mode: String)

enum Mode { EXPLORE, HISTORY, EDITOR }

@onready var explore_button: Button = $Control/TopBar/MarginContainer/HBoxContainer/ModeSwitcher/ExploreButton
@onready var history_button: Button = $Control/TopBar/MarginContainer/HBoxContainer/ModeSwitcher/HistoryButton
@onready var editor_button: Button = $Control/TopBar/MarginContainer/HBoxContainer/ModeSwitcher/EditorButton
@onready var help_button: Button = $Control/TopBar/MarginContainer/HBoxContainer/HelpButton
@onready var reset_button: Button = $Control/TopBar/MarginContainer/HBoxContainer/ResetButton
@onready var help_overlay: PanelContainer = $Control/HelpOverlay
@onready var close_help_button: Button = $Control/HelpOverlay/MarginContainer/VBoxContainer/CloseButton
@onready var reset_confirm_dialog: ConfirmationDialog = $Control/ResetConfirmDialog
@onready var current_mode_label: Label = $Control/Minimap/MarginContainer/VBoxContainer/CurrentMode
@onready var player_marker: ColorRect = $Control/Minimap/MarginContainer/VBoxContainer/FloorPlan/PlayerMarker

var current_mode: Mode = Mode.EXPLORE
var current_scene_path: String = ""

func _ready() -> void:
	# Connect button signals
	explore_button.pressed.connect(_on_explore_button_pressed)
	history_button.pressed.connect(_on_history_button_pressed)
	editor_button.pressed.connect(_on_editor_button_pressed)
	help_button.pressed.connect(_on_help_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	close_help_button.pressed.connect(_on_close_help_button_pressed)
	reset_confirm_dialog.confirmed.connect(_on_reset_confirmed)
	
	# Update button states
	_update_button_states()
	
	# Get current scene
	_detect_current_scene()

func _detect_current_scene() -> void:
	"""Detect which scene we're currently in"""
	var scene = get_tree().current_scene
	if scene:
		current_scene_path = scene.scene_file_path
		
		# Update mode based on scene
		if "Interior" in current_scene_path or "Exterior" in current_scene_path:
			current_mode = Mode.EXPLORE
		elif "AutomationEditor" in current_scene_path:
			current_mode = Mode.EDITOR
		
		_update_button_states()
		_update_mode_label()

func _on_explore_button_pressed() -> void:
	"""Switch to explore mode (interior scene)"""
	if current_mode == Mode.EXPLORE:
		return
	
	current_mode = Mode.EXPLORE
	_update_button_states()
	_update_mode_label()
	mode_changed.emit("explore")
	
	# Load interior scene if not already there
	if "Interior" not in current_scene_path:
		SceneManager.change_scene("res://scenes/InteriorScene.tscn")

func _on_history_button_pressed() -> void:
	"""Toggle history panel in current scene"""
	current_mode = Mode.HISTORY
	_update_button_states()
	_update_mode_label()
	mode_changed.emit("history")
	
	# Try to show history panel in current scene
	var scene = get_tree().current_scene
	if scene and scene.has_node("UI/AutomationHistoryPanel"):
		var history_panel = scene.get_node("UI/AutomationHistoryPanel")
		if history_panel.visible:
			history_panel.hide()
			if scene.has_method("_on_history_panel_closed"):
				scene._on_history_panel_closed()
		else:
			history_panel.show_panel()
	else:
		# If no history panel in current scene, go to interior scene
		if "Interior" not in current_scene_path:
			SceneManager.change_scene("res://scenes/InteriorScene.tscn")

func _on_editor_button_pressed() -> void:
	"""Switch to automation editor"""
	if current_mode == Mode.EDITOR:
		return
	
	current_mode = Mode.EDITOR
	_update_button_states()
	_update_mode_label()
	mode_changed.emit("editor")
	
	# Load automation editor scene
	SceneManager.change_scene("res://scenes/AutomationEditorScene.tscn")

func _on_help_button_pressed() -> void:
	"""Show help overlay"""
	help_overlay.visible = true

func _on_close_help_button_pressed() -> void:
	"""Hide help overlay"""
	help_overlay.visible = false

func _on_reset_button_pressed() -> void:
	"""Show reset confirmation dialog"""
	reset_confirm_dialog.popup_centered()

func _on_reset_confirmed() -> void:
	"""Reset all devices to default states"""
	DeviceRegistry.reset_all_devices()
	
	# Save the reset state
	AutomationEngine.save_device_states()
	
	print("All devices reset to default states and saved")

func _update_button_states() -> void:
	"""Update button visual states based on current mode"""
	# Reset all buttons
	explore_button.disabled = false
	history_button.disabled = false
	editor_button.disabled = false
	
	# Highlight current mode button
	match current_mode:
		Mode.EXPLORE:
			explore_button.disabled = true
		Mode.HISTORY:
			history_button.disabled = true
		Mode.EDITOR:
			editor_button.disabled = true

func _update_mode_label() -> void:
	"""Update the mode label in the minimap"""
	match current_mode:
		Mode.EXPLORE:
			current_mode_label.text = "Mode: Explore"
		Mode.HISTORY:
			current_mode_label.text = "Mode: History"
		Mode.EDITOR:
			current_mode_label.text = "Mode: Editor"

func update_player_position(position_2d: Vector2, map_size: Vector2) -> void:
	"""Update player marker position on minimap
	position_2d: normalized position (0-1) on the map
	map_size: size of the floor plan area
	"""
	var floor_plan = $Control/Minimap/MarginContainer/VBoxContainer/FloorPlan
	if floor_plan:
		var map_rect = floor_plan.get_rect()
		player_marker.position = Vector2(
			position_2d.x * map_rect.size.x - 5,
			position_2d.y * map_rect.size.y - 5
		)

func _process(_delta: float) -> void:
	"""Update minimap player position based on camera"""
	var scene = get_tree().current_scene
	if scene and scene.has_node("ExploreCamera"):
		var camera = scene.get_node("ExploreCamera")
		if camera is Camera3D:
			# Convert 3D position to 2D minimap position (normalized 0-1)
			# This is a simple mapping - adjust based on your scene layout
			var pos_3d = camera.global_position
			var normalized_pos = Vector2(
				(pos_3d.x + 10) / 20.0,  # Assuming scene is roughly -10 to 10 in X
				(pos_3d.z + 10) / 20.0   # Assuming scene is roughly -10 to 10 in Z
			)
			normalized_pos = normalized_pos.clamp(Vector2.ZERO, Vector2.ONE)
			update_player_position(normalized_pos, Vector2(180, 150))
