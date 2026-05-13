extends Node2D

@onready var machine_anim: AnimatedSprite2D = $AnimatedSprite2D

@onready var slot_condition_operator = $SlotConditionOperator
@onready var slot_condition_value = $SlotConditionValue
@onready var slot_action_operator = $SlotActionOperator
@onready var slot_action_value = $SlotActionValue


func _ready():
	play_idle()


func is_rule_correct() -> bool:
	return (
		str(slot_condition_operator.stored_value) == ">"
		and str(slot_condition_value.stored_value) == "15"
		and str(slot_action_operator.stored_value) == "-"
		and str(slot_action_value.stored_value) == "1"
	)


func play_success():
	if machine_anim.sprite_frames.has_animation("active"):
		machine_anim.play("active")


func play_error():
	if machine_anim.sprite_frames.has_animation("error"):
		machine_anim.play("error")


func play_idle():
	if machine_anim.sprite_frames.has_animation("idle"):
		machine_anim.play("idle")
