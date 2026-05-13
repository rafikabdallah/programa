extends Control

@onready var ending_label: Label = $TerminalPanel/EndingLabel
@onready var credit_label: Label = $TerminalPanel/CreditLabel
@onready var back_button: TextureButton = $BackToMenuButton

@onready var ambience_player: AudioStreamPlayer = $Audio/AmbiencePlayer
@onready var terminal_blip_player: AudioStreamPlayer = $Audio/TerminalBlipPlayer
@onready var press_player: AudioStreamPlayer = $Audio/PressPlayer

@export var typing_speed := 0.025
@export var page_wait_time := 1.4
@export var clear_wait_time := 0.35
@export var blip_every_characters := 3

var typing_finished := false

var ending_pages := [
	"""> CHAPTER 1 COMPLETE

> POWER CORE.......... ONLINE
> PRESSURE VALVE...... STABLE
> OXYGEN ......... RESTORED""",

	"""> FIRST LIFE SIGNAL DETECTED

> E-LIS RESTORED THE INITIAL SYSTEMS

> LIFE SUPPORT CORE IS ACTIVE""",

	"""> NEW MODULES DETECTED

> SCANNER SYSTEM....... LOCKED
> ADVANCED LOGIC....... LOCKED

> MORE LEVELS COMING SOON..."""
]


func _ready():
	back_button.visible = false
	credit_label.visible = false
	ending_label.text = ""
	typing_finished = false

	play_ambience()

	if not back_button.pressed.is_connected(_on_back_to_menu_button_pressed):
		back_button.pressed.connect(_on_back_to_menu_button_pressed)

	await play_ending_sequence()


func play_ending_sequence():
	for page in ending_pages:
		ending_label.text = ""
		await get_tree().create_timer(clear_wait_time).timeout
		await type_text(page)
		await get_tree().create_timer(page_wait_time).timeout

	ending_label.text = ""

	await type_text("""> REPORT COMPLETE

> THANK YOU FOR PLAYING PROGRAMA""")

	await get_tree().create_timer(0.6).timeout

	show_credit()
	back_button.visible = true
	typing_finished = true


func type_text(text_to_type: String):
	var blip_counter := 0

	for i in text_to_type.length():
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


func show_credit():
	credit_label.text = "Created by Abdallah Rafik"
	credit_label.visible = true


func play_ambience():
	if ambience_player != null:
		ambience_player.play()


func play_terminal_blip():
	if terminal_blip_player == null:
		return

	terminal_blip_player.stop()
	terminal_blip_player.play()


func play_press_sound():
	if press_player != null:
		press_player.play()


func _on_back_to_menu_button_pressed():
	if not typing_finished:
		return

	play_press_sound()

	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
