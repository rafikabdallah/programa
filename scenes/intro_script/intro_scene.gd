extends Control

@onready var intro_label: Label = $TerminalPanel/IntroLabel
@onready var continue_hint: Label = $ContinueHint
@onready var continue_hint_2: Label = $ContinueHint2

@onready var ambience_player: AudioStreamPlayer = $Audio/AmbiencePlayer
@onready var terminal_blip_player: AudioStreamPlayer = $Audio/TerminalBlipPlayer
@onready var press_player: AudioStreamPlayer = $Audio/PressPlayer

@export var typing_speed := 0.025
@export var page_wait_time := 0.15
@export var blip_every_characters := 3
@export var next_scene_path := "res://scenes/level1.tscn"

var typing_finished := false
var blink_active := false
var changing_scene := false

var is_typing := false
var skip_typing_requested := false
var waiting_for_continue := false

var intro_pages := [
	"""> SYSTEM BOOTING...

> ROBOT E-LIS ONLINE

> LOCATION:
> DISTANT PLANET COLUSIIEM""",

	"""> PLANET STATUS:

> POWER CORE....... OFFLINE
> PRESSURE VALVE... UNSTABLE
> OXYGEN ...... EMPTY""",


	"""> MISSION:

> RESTORE THE PLANET
> USING LOGIC.

> BEGIN RESTORATION PROTOCOL."""
]


func _ready():
	intro_label.text = ""
	continue_hint.visible = false
	continue_hint_2.visible = false

	ambience_player.play()

	await play_intro_sequence()


func play_intro_sequence():
	for page in intro_pages:
		intro_label.text = ""
		continue_hint.visible = false
		continue_hint_2.visible = false
		skip_typing_requested = false

		await get_tree().create_timer(0.25).timeout
		await type_text(page)

		await wait_for_continue()

	intro_label.text = ""
	continue_hint.visible = false
	continue_hint_2.visible = false
	skip_typing_requested = false

	await type_text("""> PRESS ANY KEY TO BEGIN""")

	typing_finished = true
	continue_hint.visible = true
	blink_active = true
	blink_continue_hint(continue_hint)


func wait_for_continue():
	waiting_for_continue = true
	continue_hint_2.visible = true
	blink_active = true
	blink_continue_hint(continue_hint_2)

	while waiting_for_continue:
		await get_tree().process_frame

	blink_active = false
	continue_hint_2.visible = false
	await get_tree().create_timer(page_wait_time).timeout


func _input(event):
	if changing_scene:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		handle_intro_input()
		return

	if event is InputEventMouseButton and event.pressed:
		handle_intro_input()
		return


func handle_intro_input():
	if is_typing:
		skip_typing_requested = true
		return

	if waiting_for_continue:
		play_press_sound()
		waiting_for_continue = false
		return

	if typing_finished:
		go_to_level_1()


func go_to_level_1():
	changing_scene = true
	blink_active = false

	play_press_sound()

	await get_tree().create_timer(0.15).timeout

	LoadingManager.load_scene(next_scene_path)


func type_text(text_to_type: String):
	is_typing = true
	skip_typing_requested = false

	var blip_counter := 0
	intro_label.text = ""

	for i in text_to_type.length():
		if skip_typing_requested:
			intro_label.text = text_to_type
			break

		var character := text_to_type[i]
		intro_label.text += character

		if character != " " and character != "\n":
			blip_counter += 1

			if blip_counter >= blip_every_characters:
				play_terminal_blip()
				blip_counter = 0

		if character == "\n":
			await get_tree().create_timer(0.13).timeout
		elif character == ".":
			await get_tree().create_timer(0.05).timeout
		else:
			await get_tree().create_timer(typing_speed).timeout

	is_typing = false
	skip_typing_requested = false


func play_terminal_blip():
	terminal_blip_player.stop()
	terminal_blip_player.pitch_scale = randf_range(0.95, 1.05)
	terminal_blip_player.play()


func play_press_sound():
	press_player.stop()
	press_player.play()


func blink_continue_hint(label_to_blink: Label):
	while blink_active:
		label_to_blink.visible = not label_to_blink.visible
		await get_tree().create_timer(0.45).timeout
