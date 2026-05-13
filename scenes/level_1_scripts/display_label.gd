extends Label

@export var typing_speed := 0.08
@export var cursor_speed := 0.8

var current_message := ""
var typing_id := 0


func show_message(message: String):
	if message == current_message:
		return

	current_message = message
	typing_id += 1

	var my_id = typing_id
	text = ""

	await type_text(message, my_id)


func type_text(message: String, my_id: int):
	for i in message.length():
		if my_id != typing_id:
			return

		text += message[i]
		await get_tree().create_timer(typing_speed).timeout

	blink_cursor(message, my_id)


func blink_cursor(message: String, my_id: int):
	while my_id == typing_id:
		text = message + "_"
		await get_tree().create_timer(cursor_speed).timeout

		if my_id != typing_id:
			return

		text = message
		await get_tree().create_timer(cursor_speed).timeout
