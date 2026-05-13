extends CharacterBody2D

@export var speed := 70.0

var carried_value = null
var carried_value_source = null
var nearby_value = null
var nearby_slot = null
var input_enabled := true

var step_timer := 0.0
var step_interval := 0.32
var use_step_one := true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var holder: AnimatedSprite2D = $Holder
@onready var carried_sprite: Sprite2D = $Holder/CarriedValue
@onready var interaction_hint_box = $InteractionHintBox
@onready var interaction_hint: Label = $InteractionHintBox/InteractionHint

@onready var step_sound_1: AudioStreamPlayer = $StepSound1
@onready var step_sound_2: AudioStreamPlayer = $StepSound2


func _ready():
	holder.visible = false
	carried_sprite.visible = false
	interaction_hint_box.visible = false
	anim.play("idle")


func _physics_process(delta):
	if input_enabled == false:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1

	direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()

	update_animation(direction)
	update_step_sound(delta, direction)


func _process(_delta):
	if input_enabled == false:
		return

	if Input.is_action_just_pressed("pick_up"):
		pick_up_value()

	if Input.is_action_just_pressed("insert_value"):
		insert_into_slot()

	if Input.is_action_just_pressed("drop_piece"):
		drop_carried_value()


func set_input_enabled(enabled: bool):
	input_enabled = enabled
	velocity = Vector2.ZERO

	if enabled == false:
		play_anim("idle")
		step_timer = 0.0


func pick_up_value():
	if carried_value != null:
		return

	if nearby_value == null:
		return

	var data = nearby_value.pick_up()

	if data == null:
		nearby_value = null
		update_interaction_hint()
		return

	carried_value = data["value"]
	carried_value_source = data["source"]

	holder.visible = true
	carried_sprite.texture = data["texture"]
	carried_sprite.visible = true

	var level = get_tree().current_scene
	if level.has_method("play_pickup_sound"):
		level.play_pickup_sound()

	nearby_value = null
	update_interaction_hint()


func insert_into_slot():
	if carried_value == null:
		return

	if nearby_slot == null:
		return

	nearby_slot.insert_value(carried_value)

	var level = get_tree().current_scene
	if level.has_method("play_insert_sound"):
		level.play_insert_sound()

	carried_value = null
	carried_value_source = null

	holder.visible = false
	carried_sprite.texture = null
	carried_sprite.visible = false

	update_interaction_hint()


func drop_carried_value():
	if carried_value == null:
		return

	if carried_value_source != null:
		carried_value_source.return_to_origin()

	var level = get_tree().current_scene
	if level.has_method("play_drop_sound"):
		level.play_drop_sound()

	carried_value = null
	carried_value_source = null

	holder.visible = false
	carried_sprite.texture = null
	carried_sprite.visible = false

	update_interaction_hint()


func update_interaction_hint():
	if input_enabled == false:
		interaction_hint_box.visible = false
		return

	if carried_value == null:
		if nearby_value != null:
			interaction_hint_box.visible = true
			interaction_hint.text = "Press X To Pick"
		else:
			interaction_hint_box.visible = false
		return

	if carried_value != null:
		if nearby_slot != null:
			interaction_hint_box.visible = true
			interaction_hint.text = "Press Space To Insert"
		else:
			interaction_hint_box.visible = true
			interaction_hint.text = "Press E to Drop"
		return


func update_animation(direction: Vector2):
	if direction == Vector2.ZERO:
		play_anim("idle")
		return

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			play_anim("right")
		else:
			play_anim("left")
	else:
		if direction.y > 0:
			play_anim("down")
		else:
			play_anim("up")


func update_step_sound(delta, direction: Vector2):
	if direction == Vector2.ZERO:
		step_timer = 0.0
		return

	step_timer += delta

	if step_timer < step_interval:
		return

	step_timer = 0.0

	if use_step_one:
		step_sound_1.play()
	else:
		step_sound_2.play()

	use_step_one = !use_step_one


func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)
	elif not anim.is_playing():
		anim.play()


func _on_pickup_detector_area_entered(area):
	if input_enabled == false:
		return

	if area.has_method("pick_up"):
		nearby_value = area

	if area.has_method("insert_value"):
		nearby_slot = area

	update_interaction_hint()


func _on_pickup_detector_area_exited(area):
	if area == nearby_value:
		nearby_value = null

	if area == nearby_slot:
		nearby_slot = null

	update_interaction_hint()
