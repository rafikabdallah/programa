extends Control

@onready var intro_label: Label = $TerminalPanel/IntroLabel
@onready var continue_hint: Label = $ContinueHint

@onready var ambience_player: AudioStreamPlayer = $Audio/AmbiencePlayer
@onready var terminal_blip_player: AudioStreamPlayer = $Audio/TerminalBlipPlayer
@onready var press_player: AudioStreamPlayer = $Audio/PressPlayer

@export var typing_speed := 0.025
@export var page_wait_time := 1.2
@export var blip_every_characters := 3
@export var next_scene_path := "res://scenes/level1.tscn"

var typing_finished := false
var blink_active := false
var changing_scene := false

var intro_pages := [
	"""> SYSTEM BOOTING...

> UNIT E-LIS ONLINE

> LOCATION:
> DISTANT PLANET COLUSIIEM""",

	"""> PLANET STATUS:

> POWER CORE....... OFFLINE
> PRESSURE VALVE... UNSTABLE
> OXYGEN ...... EMPTY""",

	"""> LIFE SIGNAL DETECTED:

> WEAK...
> BUT NOT LOST.""",

	"""> MISSION:

> RESTORE THE PLANET
> USING LOGIC.

> BEGIN RESTORATION PROTOCOL."""
]


func _ready():
	intro_label.text = ""
	continue_hint.visible = false
	
	ambience_player.play()
	
	await play_intro_sequence()


func play_intro_sequence():
	for page in intro_pages:
		intro_label.text = ""
		await get_tree().create_timer(0.25).timeout
		await type_text(page)
		await get_tree().create_timer(page_wait_time).timeout
	
	intro_label.text = ""
	await type_text("""> PRESS ANY KEY TO BEGIN""")
	
	typing_finished = true
	continue_hint.visible = true
	blink_active = true
	blink_continue_hint()


func _input(event):
	if not typing_finished:
		return
	
	if changing_scene:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		go_to_level_1()

	if event is InputEventMouseButton and event.pressed:
		go_to_level_1()


func go_to_level_1():
	changing_scene = true
	blink_active = false
	
	if press_player != null:
		press_player.play()
	
	await get_tree().create_timer(0.15).timeout
	
	get_tree().change_scene_to_file(next_scene_path)


func type_text(text_to_type: String):
	var blip_counter := 0

	for i in text_to_type.length():
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


func play_terminal_blip():
	if terminal_blip_player == null:
		return
	
	terminal_blip_player.stop()
	terminal_blip_player.pitch_scale = randf_range(0.95, 1.05)
	terminal_blip_player.play()


func blink_continue_hint():
	while blink_active:
		continue_hint.visible = not continue_hint.visible
		await get_tree().create_timer(0.45).timeout
