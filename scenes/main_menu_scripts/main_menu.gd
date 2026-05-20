extends Control

@export var intro_scene_path := "res://scenes/IntroScene.tscn"

@onready var start_button = $Buttons/StartButton
@onready var about_button = $Buttons/AboutButton
@onready var exit_button = $Buttons/ExitButton

@onready var about_panel = $AboutPanel
@onready var back_button = $AboutPanel/BackButton
@onready var exit_message_label: Label = $ExitMessageLabel

@onready var ambience_player: AudioStreamPlayer = $UISounds/AmbiencePlayer
@onready var hover_sound: AudioStreamPlayer = $UISounds/HoverSound
@onready var press_sound: AudioStreamPlayer = $UISounds/PressSound
@onready var panel_open_sound: AudioStreamPlayer = $UISounds/PanelOpenSound
@onready var panel_close_sound: AudioStreamPlayer = $UISounds/PanelCloseSound


func _ready():
	about_panel.visible = false
	exit_message_label.visible = false

	ambience_player.play()

	start_button.pressed.connect(_on_start_button_pressed)
	about_button.pressed.connect(_on_about_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

	start_button.mouse_entered.connect(play_hover_sound)
	about_button.mouse_entered.connect(play_hover_sound)
	exit_button.mouse_entered.connect(play_hover_sound)
	back_button.mouse_entered.connect(play_hover_sound)


func _on_start_button_pressed():
	play_press_sound()
	await get_tree().create_timer(0.12).timeout
	LoadingManager.load_scene(intro_scene_path)


func _on_about_button_pressed():
	play_panel_open_sound()

	exit_message_label.visible = false
	about_panel.visible = true


func _on_back_button_pressed():
	play_panel_close_sound()

	about_panel.visible = false


func _on_exit_button_pressed():
	play_press_sound()

	if OS.has_feature("web"):
		show_exit_message_temporarily()
	else:
		await get_tree().create_timer(0.12).timeout
		get_tree().quit()


func show_exit_message_temporarily():
	about_panel.visible = false
	exit_message_label.visible = true

	await get_tree().create_timer(3.0).timeout

	exit_message_label.visible = false


func play_hover_sound():
	hover_sound.stop()
	hover_sound.play()


func play_press_sound():
	press_sound.stop()
	press_sound.play()


func play_panel_open_sound():
	panel_open_sound.stop()
	panel_open_sound.play()


func play_panel_close_sound():
	panel_close_sound.stop()
	panel_close_sound.play()
