extends Control

@onready var menu_icon_button: TextureButton = $HUD/MenuIconButton
@onready var pause_menu: Control = $PauseMenu

@onready var resume_button: TextureButton = $PauseMenu/MenuPanelImage/ResumeButton
@onready var restart_button: TextureButton = $PauseMenu/MenuPanelImage/RestartButton
@onready var exit_button: TextureButton = $PauseMenu/MenuPanelImage/ExitButton


func _ready():
	pause_menu.visible = false

	menu_icon_button.pressed.connect(open_pause_menu)
	resume_button.pressed.connect(close_pause_menu)
	restart_button.pressed.connect(restart_level)
	exit_button.pressed.connect(exit_to_main_menu)


func open_pause_menu():
	pause_menu.visible = true


func close_pause_menu():
	pause_menu.visible = false


func restart_level():
	get_tree().reload_current_scene()


func exit_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
