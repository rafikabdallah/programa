extends Area2D

var stored_value = null
var stored_piece_source = null
var stored_texture: Texture2D = null
var locked := false

@onready var inserted_sprite: Sprite2D = $InsertedSprite


func _ready():
	inserted_sprite.visible = false


func insert_value(piece_data):
	if locked:
		return false

	if piece_data == null:
		return false

	if stored_value != null:
		return false

	stored_value = piece_data["value"]
	stored_texture = piece_data["texture"]
	stored_piece_source = piece_data["source"]

	inserted_sprite.texture = stored_texture
	inserted_sprite.visible = true

	stored_piece_source.keep_hidden_after_insert()

	notify_level_machine_state()

	print(name, "=", stored_value)

	return true


func remove_piece():
	if locked:
		return null

	if stored_value == null:
		return null

	var piece_data = {
		"value": stored_value,
		"texture": stored_texture,
		"source": stored_piece_source
	}

	stored_value = null
	stored_texture = null
	stored_piece_source = null

	inserted_sprite.texture = null
	inserted_sprite.visible = false

	notify_level_machine_state()

	return piece_data
	
	
func lock_slot():
	locked = true
	monitoring = false
	monitorable = false
	
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape != null:
		collision_shape.disabled = true


func clear_slot():
	if stored_piece_source != null:
		stored_piece_source.return_to_origin()

	stored_value = null
	stored_texture = null
	stored_piece_source = null

	inserted_sprite.texture = null
	inserted_sprite.visible = false

	notify_level_machine_state()


func notify_level_machine_state():
	if get_tree().current_scene.has_method("update_if_machine_state"):
		get_tree().current_scene.update_if_machine_state()

	if get_tree().current_scene.has_method("update_loop_machine_state"):
		get_tree().current_scene.update_loop_machine_state()
