extends Control

@export var intro_scene_path := "res://scenes/IntroScene.tscn"

@onready var start_button = $Buttons/StartButton
@onready var about_button = $Buttons/AboutButton
@onready var exit_button = $Buttons/ExitButton

@onready var about_panel = $AboutPanel
@onready var back_button = $AboutPanel/BackButton

@onready var hover_sound: AudioStreamPlayer = $UISounds/HoverSound
@onready var press_sound: AudioStreamPlayer = $UISounds/PressSound
@onready var panel_open_sound: AudioStreamPlayer = $UISounds/PanelOpenSound
@onready var panel_close_sound: AudioStreamPlayer = $UISounds/PanelCloseSound
@onready var ambience_player: AudioStreamPlayer = $UISounds/AmbiencePlayer


func _ready():
	about_panel.visible = false

	play_ambience()

	# Press signals
	start_button.pressed.connect(_on_start_button_pressed)
	about_button.pressed.connect(_on_about_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

	# Hover signals
	start_button.mouse_entered.connect(_play_hover_sound)
	about_button.mouse_entered.connect(_play_hover_sound)
	exit_button.mouse_entered.connect(_play_hover_sound)
	back_button.mouse_entered.connect(_play_hover_sound)


func play_ambience():
	if ambience_player != null:
		ambience_player.play()


func _play_hover_sound():
	if hover_sound != null:
		hover_sound.play()


func _play_press_sound():
	if press_sound != null:
		press_sound.play()


func _play_panel_open_sound():
	if panel_open_sound != null:
		panel_open_sound.play()


func _play_panel_close_sound():
	if panel_close_sound != null:
		panel_close_sound.play()


func _on_start_button_pressed():
	_play_press_sound()

	await get_tree().create_timer(0.12).timeout
	get_tree().change_scene_to_file(intro_scene_path)


func _on_about_button_pressed():
	_play_press_sound()
	about_panel.visible = true
	_play_panel_open_sound()


func _on_back_button_pressed():
	_play_press_sound()
	about_panel.visible = false
	_play_panel_close_sound()


func _on_exit_button_pressed():
	_play_press_sound()

	await get_tree().create_timer(0.12).timeout
	get_tree().quit()
