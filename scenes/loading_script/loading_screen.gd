extends Control

@export var minimum_loading_time := 2.5

@onready var loading_label: Label = $LoadingLabel
@onready var loading_bar: AnimatedSprite2D = $LoadingBar

var loading_texts := [
	"LOADING.",
	"LOADING..",
	"LOADING..."
]

var loading_text_index := 0
var text_loop_active := true


func _ready():
	loading_label.text = "LOADING."

	if loading_bar.sprite_frames.has_animation("loading"):
		loading_bar.play("loading")

	start_loading_text_loop()

	await get_tree().create_timer(minimum_loading_time).timeout

	text_loop_active = false

	if LoadingManager.next_scene_path != "":
		get_tree().change_scene_to_file(LoadingManager.next_scene_path)


func start_loading_text_loop():
	while text_loop_active:
		loading_label.text = loading_texts[loading_text_index]

		loading_text_index += 1

		if loading_text_index >= loading_texts.size():
			loading_text_index = 0

		await get_tree().create_timer(0.35).timeout
