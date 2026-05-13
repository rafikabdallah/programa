extends Node2D

@onready var machine_anim: AnimatedSprite2D = $AnimatedSprite2D

@onready var slot_loop_variable = $SlotLoopVariable
@onready var slot_loop_operator = $SlotLoopOperator
@onready var slot_loop_value = $SlotLoopValue

@onready var slot_action_variable = $SlotActionVariable
@onready var slot_action_operator = $SlotActionOperator
@onready var slot_action_value = $SlotActionValue


func _ready():
	play_idle()


func is_rule_correct() -> bool:
	return (
		str(slot_loop_variable.stored_value) == "oxygen"
		and str(slot_loop_operator.stored_value) == "<"
		and str(slot_loop_value.stored_value) == "10"
		and str(slot_action_variable.stored_value) == "oxygen"
		and str(slot_action_operator.stored_value) == "+"
		and str(slot_action_value.stored_value) == "2"
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
