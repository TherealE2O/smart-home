extends Control
## Loading Screen with progress indicator
## Shows loading progress during scene transitions

@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBarContainer/ProgressBar
@onready var progress_label: Label = $CenterContainer/VBoxContainer/ProgressBarContainer/ProgressLabel
@onready var loading_text: Label = $CenterContainer/VBoxContainer/LoadingText
@onready var animation_timer: Timer = $AnimationTimer

# Target scene to load
var target_scene: String = "res://scenes/ExteriorScene.tscn"

# Loading state
var loading_status: int = ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
var progress: float = 0.0
var is_loading: bool = false

# Loading messages
var loading_messages: Array[String] = [
	"Initializing smart home systems...",
	"Loading 3D environment...",
	"Connecting smart devices...",
	"Preparing automation engine...",
	"Setting up cameras...",
	"Almost ready..."
]
var current_message_index: int = 0

func _ready() -> void:
	# Start loading the target scene
	_start_loading()

func _start_loading() -> void:
	"""Begin asynchronous scene loading"""
	if ResourceLoader.has_cached(target_scene):
		# Scene already cached, load immediately
		_finish_loading()
		return
	
	# Start threaded loading
	var error = ResourceLoader.load_threaded_request(target_scene)
	if error != OK:
		push_error("Failed to start loading scene: " + target_scene)
		_finish_loading()
		return
	
	is_loading = true

func _process(_delta: float) -> void:
	"""Update loading progress"""
	if not is_loading:
		return
	
	# Get loading progress
	var progress_array: Array = []
	loading_status = ResourceLoader.load_threaded_get_status(target_scene, progress_array)
	
	if progress_array.size() > 0:
		progress = progress_array[0]
	
	# Update UI
	_update_progress_display()
	
	# Check if loading is complete
	match loading_status:
		ResourceLoader.THREAD_LOAD_LOADED:
			_finish_loading()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Failed to load scene: " + target_scene)
			_finish_loading()

func _update_progress_display() -> void:
	"""Update progress bar and labels"""
	progress_bar.value = progress
	progress_label.text = str(int(progress * 100)) + "%"
	
	# Update loading message based on progress
	var message_index = int(progress * loading_messages.size())
	if message_index >= loading_messages.size():
		message_index = loading_messages.size() - 1
	
	if message_index != current_message_index:
		current_message_index = message_index
		loading_text.text = loading_messages[current_message_index]

func _finish_loading() -> void:
	"""Complete loading and transition to target scene"""
	is_loading = false
	
	# Ensure progress shows 100%
	progress_bar.value = 1.0
	progress_label.text = "100%"
	loading_text.text = "Ready!"
	
	# Small delay before transitioning
	await get_tree().create_timer(0.5).timeout
	
	# Get the loaded scene
	var loaded_scene = ResourceLoader.load_threaded_get(target_scene)
	if loaded_scene:
		# Manually transition to avoid loading screen loop
		_transition_to_scene(loaded_scene)
	else:
		push_error("Failed to get loaded scene resource")
		# Fallback: try direct load
		SceneManager.change_scene(target_scene, true)

func _transition_to_scene(scene_resource: PackedScene) -> void:
	"""Manually transition to the loaded scene"""
	# Fade out
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade_overlay)
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.3)
	await tween.finished
	
	# Remove current scene and add new one
	var root = get_tree().root
	var current_scene = root.get_child(root.get_child_count() - 1)
	
	var new_scene = scene_resource.instantiate()
	root.add_child(new_scene)
	get_tree().current_scene = new_scene
	
	# Update SceneManager's reference
	SceneManager.current_scene = new_scene
	
	# Remove loading screen
	current_scene.queue_free()
	
	# Fade in (handled by SceneManager's overlay)
	await get_tree().create_timer(0.1).timeout
	SceneManager._fade_in()

func _on_animation_timer_timeout() -> void:
	"""Add subtle animation to loading text"""
	var dot_count = (Time.get_ticks_msec() / 500) % 4
	var dots = ".".repeat(dot_count)
	
	if is_loading and current_message_index < loading_messages.size():
		var base_message = loading_messages[current_message_index]
		loading_text.text = base_message + dots
