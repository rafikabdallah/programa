extends Control

@onready var ending_label: Label = $TerminalPanel/EndingLabel
@onready var credit_label: Label = $TerminalPanel/CreditLabel
@onready var back_button: TextureButton = $BackToMenuButton
@onready var continue_hint: Label = $ContinueHint

@onready var ambience_player: AudioStreamPlayer = $Audio/AmbiencePlayer
@onready var terminal_blip_player: AudioStreamPlayer = $Audio/TerminalBlipPlayer
@onready var press_player: AudioStreamPlayer = $Audio/PressPlayer

@export var typing_speed := 0.025
@export var page_wait_time := 0.15
@export var clear_wait_time := 0.35
@export var blip_every_characters := 3

var typing_finished := false
var is_typing := false
var skip_typing_requested := false
var waiting_for_continue := false
var blink_active := false
var changing_scene := false

var ending_pages := [
	"""> CHAPTER 1 COMPLETE

> POWER CORE.......... ONLINE
> PRESSURE VALVE...... STABLE
> OXYGEN ......... RESTORED""",



	"""> NEW MODULES DETECTED

> SCANNER SYSTEM....... LOCKED
> ADVANCED LOGIC....... LOCKED

> MORE LEVELS COMING SOON..."""
]


func _ready():
	back_button.visible = false
	credit_label.visible = false
	continue_hint.visible = false
	ending_label.text = ""
	typing_finished = false

	play_ambience()

	if not back_button.pressed.is_connected(_on_back_to_menu_button_pressed):
		back_button.pressed.connect(_on_back_to_menu_button_pressed)

	await play_ending_sequence()


func play_ending_sequence():
	for page in ending_pages:
		ending_label.text = ""
		continue_hint.visible = false
		skip_typing_requested = false

		await get_tree().create_timer(clear_wait_time).timeout
		await type_text(page)

		await wait_for_continue()

	ending_label.text = ""
	continue_hint.visible = false
	skip_typing_requested = false

	await type_text("""> REPORT COMPLETE

> THANK YOU FOR PLAYING PROGRAMA""")

	await get_tree().create_timer(0.6).timeout

	show_credit()
	back_button.visible = true
	continue_hint.visible = false
	typing_finished = true


func wait_for_continue():
	waiting_for_continue = true
	continue_hint.visible = true
	blink_active = true
	blink_continue_hint()

	while waiting_for_continue:
		await get_tree().process_frame

	blink_active = false
	continue_hint.visible = false
	await get_tree().create_timer(page_wait_time).timeout


func _input(event):
	if changing_scene:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		handle_ending_input()
		return

	if event is InputEventMouseButton and event.pressed:
		handle_ending_input()
		return


func handle_ending_input():
	if is_typing:
		skip_typing_requested = true
		return

	if waiting_for_continue:
		play_press_sound()
		waiting_for_continue = false
		return


func type_text(text_to_type: String):
	is_typing = true
	skip_typing_requested = false

	var blip_counter := 0
	ending_label.text = ""

	for i in text_to_type.length():
		if skip_typing_requested:
			ending_label.text = text_to_type
			break

		var character := text_to_type[i]
		ending_label.text += character

		if character != " " and character != "\n":
			blip_counter += 1

			if blip_counter >= blip_every_characters:
				play_terminal_blip()
				blip_counter = 0

		if character == "\n":
			await get_tree().create_timer(0.14).timeout
		elif character == ".":
			await get_tree().create_timer(0.045).timeout
		else:
			await get_tree().create_timer(typing_speed).timeout

	is_typing = false
	skip_typing_requested = false


func blink_continue_hint():
	while blink_active:
		continue_hint.visible = not continue_hint.visible
		await get_tree().create_timer(0.45).timeout


func show_credit():
	credit_label.text = "Created by Abdallah Rafik"
	credit_label.visible = true


func play_ambience():
	ambience_player.play()


func play_terminal_blip():
	terminal_blip_player.stop()
	terminal_blip_player.play()


func play_press_sound():
	press_player.stop()
	press_player.play()


func _on_back_to_menu_button_pressed():
	if not typing_finished:
		return

	changing_scene = true
	play_press_sound()

	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
