extends Control
## Main Menu Scene
## Provides entry point to the smart home experience with branding and settings

@onready var settings_panel: Panel = $SettingsPanel
@onready var low_button: Button = $SettingsPanel/MarginContainer/VBoxContainer/GraphicsQualityContainer/QualityButtons/LowButton
@onready var medium_button: Button = $SettingsPanel/MarginContainer/VBoxContainer/GraphicsQualityContainer/QualityButtons/MediumButton
@onready var high_button: Button = $SettingsPanel/MarginContainer/VBoxContainer/GraphicsQualityContainer/QualityButtons/HighButton

var current_quality: String = "medium"

func _ready() -> void:
	# Load saved graphics quality setting
	var settings = StorageManager.load_data("settings")
	if settings and settings.has("graphics_quality"):
		current_quality = settings["graphics_quality"]
	else:
		current_quality = "medium"
	
	_update_quality_buttons()

func _on_start_button_pressed() -> void:
	"""Start the smart home experience by loading the exterior scene"""
	SceneManager.change_scene("res://scenes/LoadingScreen.tscn", false)

func _on_settings_button_pressed() -> void:
	"""Show the settings panel"""
	settings_panel.visible = true

func _on_close_settings_pressed() -> void:
	"""Hide the settings panel"""
	settings_panel.visible = false

func _on_quality_button_pressed(quality: String) -> void:
	"""Handle graphics quality selection"""
	current_quality = quality
	_update_quality_buttons()
	_apply_graphics_quality(quality)
	_save_settings()

func _update_quality_buttons() -> void:
	"""Update button states to show current selection"""
	low_button.disabled = (current_quality == "low")
	medium_button.disabled = (current_quality == "medium")
	high_button.disabled = (current_quality == "high")

func _apply_graphics_quality(quality: String) -> void:
	"""Apply graphics quality settings"""
	match quality:
		"low":
			# Reduce rendering quality
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			get_viewport().use_taa = false
		"medium":
			# Balanced quality
			get_viewport().msaa_3d = Viewport.MSAA_2X
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			get_viewport().use_taa = false
		"high":
			# Maximum quality
			get_viewport().msaa_3d = Viewport.MSAA_4X
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			get_viewport().use_taa = true

func _save_settings() -> void:
	"""Save settings to LocalStorage"""
	var settings = {
		"graphics_quality": current_quality,
		"audio_enabled": true
	}
	StorageManager.save_data("settings", settings)
