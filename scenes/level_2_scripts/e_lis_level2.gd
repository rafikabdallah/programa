extends CharacterBody2D

@export var speed := 70.0
@export var step_interval := 0.32

var nearby_value = null
var nearby_slots: Array = []

var carried_piece_data = null
var carried_piece_source = null

var step_timer := 0.0
var use_step_one := true
var interaction_enabled := true
var current_mobile_action := ""

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var holder: AnimatedSprite2D = $Holder
@onready var carried_sprite: Sprite2D = $Holder/CarriedValue
@onready var interaction_hint_box = $InteractionHintBox
@onready var interaction_hint: Label = $InteractionHintBox/InteractionHint

@onready var step_sound_1: AudioStreamPlayer = $StepSound1
@onready var step_sound_2: AudioStreamPlayer = $StepSound2


func _ready():
	add_to_group("player")
	holder.visible = false
	carried_sprite.visible = false
	interaction_hint_box.visible = false
	anim.play("idle")


func _physics_process(delta):
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1

	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1
		
	var mobile_direction = get_mobile_move_vector()

	if mobile_direction != Vector2.ZERO:
		direction = mobile_direction

	direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()

	update_animation(direction)
	update_step_sounds(direction, delta)


func _process(_delta):
	if interaction_enabled == false:
		return

	if Input.is_action_just_pressed("pick_up"):
		pick_up_value()

	if Input.is_action_just_pressed("insert_value"):
		insert_into_slot()

	if Input.is_action_just_pressed("drop_piece"):
		drop_carried_piece()

	if Input.is_action_just_pressed("retrieve_piece"):
		retrieve_from_slot()


func set_interaction_enabled(enabled: bool):
	interaction_enabled = enabled

	if enabled == false:
		interaction_hint_box.visible = false


func pick_up_value():
	if carried_piece_data != null:
		return

	if nearby_value == null:
		return

	var data = nearby_value.pick_up()

	if data == null:
		nearby_value = null
		update_interaction_hint()
		return

	carried_piece_data = data
	carried_piece_source = data["source"]

	holder.visible = true
	carried_sprite.texture = data["texture"]
	carried_sprite.visible = true

	play_level_sound("play_pickup_sound")

	nearby_value = null
	update_interaction_hint()


func insert_into_slot():
	if carried_piece_data == null:
		return

	var slot = get_best_empty_nearby_slot()

	if slot == null:
		update_interaction_hint()
		return

	var inserted = await slot.insert_value(carried_piece_data)

	if inserted:
		carried_piece_data = null
		carried_piece_source = null
		holder.visible = false
		carried_sprite.texture = null
		carried_sprite.visible = false

		play_level_sound("play_insert_sound")

	update_interaction_hint()


func retrieve_from_slot():
	if carried_piece_data != null:
		return

	var slot = get_best_filled_nearby_slot()

	if slot == null:
		return

	var data = slot.remove_piece()

	if data == null:
		return

	carried_piece_data = data
	carried_piece_source = data["source"]

	holder.visible = true
	carried_sprite.texture = data["texture"]
	carried_sprite.visible = true

	update_interaction_hint()


func drop_carried_piece():
	if carried_piece_data == null:
		return

	if carried_piece_source != null:
		var drop_position = anim.global_position + Vector2(32, 0)
		carried_piece_source.drop_at_position(drop_position)

	carried_piece_data = null
	carried_piece_source = null

	holder.visible = false
	carried_sprite.texture = null
	carried_sprite.visible = false

	play_level_sound("play_drop_sound")

	update_interaction_hint()


func get_best_empty_nearby_slot():
	var best_slot = null
	var best_distance := INF

	for slot in nearby_slots:
		if slot == null:
			continue

		if not is_instance_valid(slot):
			continue

		if not slot.has_method("insert_value"):
			continue

		if slot.stored_value != null:
			continue

		var distance = global_position.distance_to(slot.global_position)

		if distance < best_distance:
			best_distance = distance
			best_slot = slot

	return best_slot


func get_best_filled_nearby_slot():
	var best_slot = null
	var best_distance := INF

	for slot in nearby_slots:
		if slot == null:
			continue

		if not is_instance_valid(slot):
			continue

		if not slot.has_method("remove_piece"):
			continue

		if slot.stored_value == null:
			continue

		var distance = global_position.distance_to(slot.global_position)

		if distance < best_distance:
			best_distance = distance
			best_slot = slot

	return best_slot


func update_interaction_hint():
	if interaction_enabled == false:
		interaction_hint_box.visible = false
		set_mobile_action("", "")
		return

	if carried_piece_data == null:
		if nearby_value != null:
			interaction_hint_box.visible = true
			interaction_hint.text = "Press X To Pick"
			set_mobile_action("Pick", "pick")
		elif get_best_filled_nearby_slot() != null:
			interaction_hint_box.visible = true
			interaction_hint.text = "Press R To Retrieve"
			set_mobile_action("Retrieve", "retrieve")
		else:
			interaction_hint_box.visible = false
			set_mobile_action("", "")
		return

	if carried_piece_data != null:
		if get_best_empty_nearby_slot() != null:
			interaction_hint_box.visible = true
			interaction_hint.text = "Press Space To Insert"
			set_mobile_action("Insert", "insert")
		else:
			interaction_hint_box.visible = true
			interaction_hint.text = "Press E To Drop"
			set_mobile_action("Drop", "drop")
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


func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)
	elif not anim.is_playing():
		anim.play()


func update_step_sounds(direction: Vector2, delta: float):
	if direction == Vector2.ZERO:
		step_timer = 0.0
		return

	step_timer -= delta

	if step_timer <= 0.0:
		play_step_sound()
		step_timer = step_interval


func play_step_sound():
	if use_step_one:
		step_sound_1.play()
	else:
		step_sound_2.play()

	use_step_one = !use_step_one


func play_level_sound(function_name: String):
	var level = get_tree().current_scene

	if level.has_method(function_name):
		level.call(function_name)


func _on_pickup_detector_area_entered(area):
	if interaction_enabled == false:
		return

	if area.has_method("pick_up") and carried_piece_data == null:
		nearby_value = area

	if area.has_method("insert_value"):
		if not nearby_slots.has(area):
			nearby_slots.append(area)

	update_interaction_hint()


func _on_pickup_detector_area_exited(area):
	if area == nearby_value:
		nearby_value = null

	if nearby_slots.has(area):
		nearby_slots.erase(area)

	update_interaction_hint()
	
	
func get_mobile_move_vector() -> Vector2:
	var controls = get_tree().get_nodes_in_group("mobile_controls")

	if controls.size() == 0:
		return Vector2.ZERO

	return controls[0].get_move_vector()


func set_mobile_action(button_text: String, action_name: String):
	current_mobile_action = action_name

	var controls = get_tree().get_nodes_in_group("mobile_controls")

	if controls.size() == 0:
		return

	controls[0].set_action_button(button_text, action_name != "")


func mobile_action_pressed():
	if interaction_enabled == false:
		return

	if current_mobile_action == "pick":
		pick_up_value()
		return

	if current_mobile_action == "insert":
		insert_into_slot()
		return

	if current_mobile_action == "drop":
		drop_carried_piece()
		return

	if current_mobile_action == "retrieve":
		retrieve_from_slot()
		return
