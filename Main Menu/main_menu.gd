extends Control

@onready var main_buttons: Panel = $MainButtons
@onready var settings: Panel = $Settings
@onready var credits: Panel = $Credits



func _ready():
	main_buttons.visible = true
	settings.visible = false
	credits.visible = false
	MainTheme.play()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
	Sfx.play()


func _on_settings_pressed() -> void:
	main_buttons.visible = false
	settings.visible = true
	Sfx.play()
func _on_exit_button_pressed() -> void:
	get_tree().quit()
	Sfx.play()


func _on_back_pressed() -> void:
	_ready();
	Sfx.play()


func _on_credits_pressed() -> void:
	main_buttons.visible = false
	credits.visible = true
	Sfx.play()
