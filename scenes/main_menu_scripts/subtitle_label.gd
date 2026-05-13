extends Label

@export var typing_speed := 0.06
@export var start_delay := 0.4

var full_text := ""


func _ready():
	full_text = text
	text = ""
	type_text()


func type_text():
	await get_tree().create_timer(start_delay).timeout

	for i in full_text.length():
		text += full_text[i]
		await get_tree().create_timer(typing_speed).timeout
