extends Area2D

var stored_value = null
var stored_piece_source = null

@onready var inserted_sprite: Sprite2D = $InsertedSprite


func _ready():
	inserted_sprite.visible = false


func insert_value(piece_data):
	if piece_data == null:
		return false

	if stored_value != null:
		return false

	stored_value = piece_data["value"]
	stored_piece_source = piece_data["source"]

	inserted_sprite.texture = piece_data["texture"]
	inserted_sprite.visible = true

	stored_piece_source.keep_hidden_after_insert()

	if get_tree().current_scene.has_method("update_if_machine_state"):
		get_tree().current_scene.update_if_machine_state()

	print(name, "=", stored_value)

	return true


func clear_slot():
	if stored_piece_source != null:
		stored_piece_source.return_to_origin()

	stored_value = null
	stored_piece_source = null

	inserted_sprite.texture = null
	inserted_sprite.visible = false

	if get_tree().current_scene.has_method("update_if_machine_state"):
		get_tree().current_scene.update_if_machine_state()
