extends Node
## SceneManager singleton for handling scene transitions
## Manages loading, unloading, and transitioning between scenes

signal scene_loading_started(scene_path: String)
signal scene_loading_progress(progress: float)
signal scene_loaded(scene_path: String)
signal scene_transition_completed()

var current_scene: Node = null
var is_transitioning: bool = false

func _ready() -> void:
	# Get the initial scene
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

## Load a new scene with optional transition
func change_scene(scene_path: String, use_transition: bool = true) -> void:
	if is_transitioning:
		push_warning("Scene transition already in progress")
		return
	
	is_transitioning = true
	scene_loading_started.emit(scene_path)
	
	if use_transition:
		await _fade_out()
	
	# Load the new scene
	call_deferred("_deferred_change_scene", scene_path)

func _deferred_change_scene(scene_path: String) -> void:
	# Remove current scene
	if current_scene:
		current_scene.free()
	
	# Load new scene
	var new_scene = load(scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	current_scene = new_scene
	
	scene_loaded.emit(scene_path)
	await _fade_in()
	
	is_transitioning = false
	scene_transition_completed.emit()

## Fade out transition effect
func _fade_out() -> void:
	# Placeholder for fade transition
	await get_tree().create_timer(0.3).timeout

## Fade in transition effect
func _fade_in() -> void:
	# Placeholder for fade transition
	await get_tree().create_timer(0.3).timeout

## Get the current active scene
func get_current_scene() -> Node:
	return current_scene
