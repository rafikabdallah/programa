extends Control

@export var force_show := false

@onready var up_button: TextureButton = $UpButton
@onready var down_button: TextureButton = $DownButton
@onready var left_button: TextureButton = $LeftButton
@onready var right_button: TextureButton = $RightButton
@onready var action_button: TextureButton = $ActionButton
@onready var action_label: Label = $ActionLabel

var move_vector := Vector2.ZERO

var up_pressed := false
var down_pressed := false
var left_pressed := false
var right_pressed := false


func _ready():
	add_to_group("mobile_controls")

	visible = force_show or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

	action_button.visible = false
	action_label.visible = false

	up_button.button_down.connect(_on_up_down)
	up_button.button_up.connect(_on_up_up)

	down_button.button_down.connect(_on_down_down)
	down_button.button_up.connect(_on_down_up)

	left_button.button_down.connect(_on_left_down)
	left_button.button_up.connect(_on_left_up)

	right_button.button_down.connect(_on_right_down)
	right_button.button_up.connect(_on_right_up)

	action_button.pressed.connect(_on_action_button_pressed)


func _process(_delta):
	move_vector = Vector2.ZERO

	if right_pressed:
		move_vector.x += 1
	if left_pressed:
		move_vector.x -= 1
	if down_pressed:
		move_vector.y += 1
	if up_pressed:
		move_vector.y -= 1

	move_vector = move_vector.normalized()


func get_move_vector() -> Vector2:
	return move_vector


func set_action_button(button_text: String, enabled: bool):
	action_button.visible = enabled
	action_label.visible = enabled
	action_label.text = button_text


func _on_action_button_pressed():
	var players = get_tree().get_nodes_in_group("player")

	if players.size() == 0:
		return

	var player = players[0]

	if player.has_method("mobile_action_pressed"):
		player.mobile_action_pressed()


func _on_up_down():
	up_pressed = true


func _on_up_up():
	up_pressed = false


func _on_down_down():
	down_pressed = true


func _on_down_up():
	down_pressed = false


func _on_left_down():
	left_pressed = true


func _on_left_up():
	left_pressed = false


func _on_right_down():
	right_pressed = true


func _on_right_up():
	right_pressed = false
