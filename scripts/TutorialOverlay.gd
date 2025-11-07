extends CanvasLayer
## TutorialOverlay - Step-by-step tutorial for first-time users

signal tutorial_completed
signal tutorial_skipped

@onready var step_title: Label = $TutorialPanel/MarginContainer/VBoxContainer/Content/StepTitle
@onready var step_description: RichTextLabel = $TutorialPanel/MarginContainer/VBoxContainer/Content/StepDescription
@onready var step_counter: Label = $TutorialPanel/MarginContainer/VBoxContainer/Header/StepCounter
@onready var prev_button: Button = $TutorialPanel/MarginContainer/VBoxContainer/ButtonContainer/PrevButton
@onready var next_button: Button = $TutorialPanel/MarginContainer/VBoxContainer/ButtonContainer/NextButton
@onready var skip_button: Button = $TutorialPanel/MarginContainer/VBoxContainer/ButtonContainer/SkipButton
@onready var highlight_panel: Panel = $Highlight

var current_step: int = 0
var tutorial_steps: Array[Dictionary] = []

func _ready() -> void:
	# Connect button signals
	prev_button.pressed.connect(_on_prev_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	
	# Define tutorial steps
	_define_tutorial_steps()
	
	# Check if tutorial should be shown
	if not _should_show_tutorial():
		hide()
		return
	
	# Show first step
	_show_step(0)

func _define_tutorial_steps() -> void:
	"""Define all tutorial steps"""
	tutorial_steps = [
		{
			"title": "Welcome to Smart Home Demo",
			"description": "[b]Welcome![/b]\n\nThis interactive demo lets you experience a complete smart home system.\n\nYou can:\n• Drive through smart gates and garage\n• Explore the interior and interact with devices\n• View automation history\n• Create custom automations\n\nLet's get started!",
			"highlight": null
		},
		{
			"title": "Navigation Controls",
			"description": "[b]Moving Around[/b]\n\n[b]Explore Mode:[/b]\n• WASD - Move camera\n• Mouse - Look around\n• Click on devices to interact\n\n[b]Vehicle Mode:[/b]\n• W/S - Accelerate/Brake\n• A/D - Steer\n• Mouse - Rotate camera",
			"highlight": null
		},
		{
			"title": "Interacting with Devices",
			"description": "[b]Smart Devices[/b]\n\n• Click on any device to open its control panel\n• Adjust settings like brightness, temperature, or position\n• Watch the device respond in real-time\n• Devices include lights, doors, windows, AC, heater, and more",
			"highlight": null
		},
		{
			"title": "Mode Switching",
			"description": "[b]Three Modes Available[/b]\n\n[b]Explore:[/b] Navigate the home and interact with devices\n[b]History:[/b] View past automation executions and replay them\n[b]Editor:[/b] Create custom automations with a visual editor\n\nUse the buttons at the top to switch between modes.",
			"highlight": "mode_switcher"
		},
		{
			"title": "You're Ready!",
			"description": "[b]Start Exploring[/b]\n\nYou're all set! Here are some tips:\n\n• Press [b]H[/b] to toggle automation history\n• Press [b]E[/b] to open the automation editor\n• Click the [b]?[/b] button for help anytime\n• Use the [b]Reset[/b] button to restore all devices\n\nEnjoy exploring your smart home!",
			"highlight": null
		}
	]

func _should_show_tutorial() -> bool:
	"""Check if tutorial should be shown (first time user)"""
	# Check StorageManager for tutorial completion
	return not StorageManager.load_tutorial_completed()

func _set_tutorial_completed() -> void:
	"""Mark tutorial as completed in StorageManager"""
	StorageManager.save_tutorial_completed(true)
	print("TutorialOverlay: Tutorial marked as completed")

func _show_step(step_index: int) -> void:
	"""Display a specific tutorial step"""
	if step_index < 0 or step_index >= tutorial_steps.size():
		return
	
	current_step = step_index
	var step = tutorial_steps[step_index]
	
	# Update UI
	step_title.text = step["title"]
	step_description.text = step["description"]
	step_counter.text = "%d/%d" % [step_index + 1, tutorial_steps.size()]
	
	# Update button states
	prev_button.disabled = (step_index == 0)
	
	if step_index == tutorial_steps.size() - 1:
		next_button.text = "Finish"
	else:
		next_button.text = "Next"
	
	# Handle highlighting
	_update_highlight(step.get("highlight", null))

func _update_highlight(highlight_target: Variant) -> void:
	"""Highlight a specific UI element"""
	if highlight_target == null:
		highlight_panel.visible = false
		return
	
	# Find the target element and position highlight
	match highlight_target:
		"mode_switcher":
			_highlight_element("Control/TopBar/MarginContainer/HBoxContainer/ModeSwitcher")
		_:
			highlight_panel.visible = false

func _highlight_element(node_path: String) -> void:
	"""Position highlight panel around a specific element"""
	# Try to find the element in MainHUD
	var main_hud = get_tree().root.get_node_or_null("InteriorScene/MainHUD")
	if not main_hud:
		main_hud = get_tree().root.get_node_or_null("ExteriorScene/MainHUD")
	if not main_hud:
		main_hud = get_tree().root.get_node_or_null("AutomationEditorScene/MainHUD")
	
	if main_hud and main_hud.has_node(node_path):
		var target = main_hud.get_node(node_path)
		if target is Control:
			var rect = target.get_global_rect()
			highlight_panel.position = rect.position - Vector2(10, 10)
			highlight_panel.size = rect.size + Vector2(20, 20)
			highlight_panel.visible = true
			return
	
	highlight_panel.visible = false

func _on_prev_button_pressed() -> void:
	"""Go to previous step"""
	if current_step > 0:
		_show_step(current_step - 1)

func _on_next_button_pressed() -> void:
	"""Go to next step or finish tutorial"""
	if current_step < tutorial_steps.size() - 1:
		_show_step(current_step + 1)
	else:
		_finish_tutorial()

func _on_skip_button_pressed() -> void:
	"""Skip the tutorial"""
	_set_tutorial_completed()
	tutorial_skipped.emit()
	queue_free()

func _finish_tutorial() -> void:
	"""Complete the tutorial"""
	_set_tutorial_completed()
	tutorial_completed.emit()
	queue_free()

## Public API
func show_tutorial() -> void:
	"""Show the tutorial overlay"""
	show()
	_show_step(0)

func reset_tutorial() -> void:
	"""Reset tutorial completion flag"""
	StorageManager.save_tutorial_completed(false)
	print("TutorialOverlay: Tutorial reset")
