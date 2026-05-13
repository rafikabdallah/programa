extends Area2D

var stored_value = null
var insert_id := 0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	if anim.sprite_frames.has_animation("normal"):
		anim.play("normal")


func insert_value(value):
	stored_value = value
	insert_id += 1
	var my_id = insert_id

	if anim.sprite_frames.has_animation("insert"):
		anim.play("insert")

	get_tree().current_scene.set_x_value(stored_value)

	print("x =", stored_value)

	await get_tree().create_timer(1.0).timeout

	if my_id != insert_id:
		return

	if anim.sprite_frames.has_animation("normal"):
		anim.play("normal")
	else:
		anim.stop()
