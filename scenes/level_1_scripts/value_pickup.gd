extends Area2D

@export var value := 2

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var picked := false
var original_position := Vector2.ZERO


func _ready():
	original_position = global_position


func pick_up():
	if picked:
		return null

	picked = true
	visible = false
	monitoring = false
	monitorable = false
	collision_shape.disabled = true

	return {
		"value": value,
		"texture": sprite.texture,
		"source": self
	}


func return_to_origin():
	picked = false
	global_position = original_position
	visible = true
	monitoring = true
	monitorable = true
	collision_shape.disabled = false


func drop_at_position(drop_global_position: Vector2):
	picked = false

	var visual_offset = sprite.global_position - global_position
	global_position = drop_global_position - visual_offset

	visible = true
	monitoring = true
	monitorable = true
	collision_shape.disabled = false
