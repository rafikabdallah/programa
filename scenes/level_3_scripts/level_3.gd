extends Node2D

var oxygen := 0
var target_oxygen := 10
var level_finished := false
var checking_rule := false
var oxygen_fill_should_loop := false

@export var success_panel_texture: Texture2D
@export var fail_panel_texture: Texture2D
@export var next_scene_path := "res://scenes/ending_screen.tscn"

@onready var slot_loop_variable = $objects/LoopMachine/SlotLoopVariable
@onready var slot_loop_operator = $objects/LoopMachine/SlotLoopOperator
@onready var slot_loop_value = $objects/LoopMachine/SlotLoopValue

@onready var slot_action_variable = $objects/LoopMachine/SlotActionVariable
@onready var slot_action_operator = $objects/LoopMachine/SlotActionOperator
@onready var slot_action_value = $objects/LoopMachine/SlotActionValue

@onready var display_label = $objects/display_screen/DisplayLabel

@onready var lights = get_node_or_null("lights")
@onready var darkness_overlay: ColorRect = get_node_or_null("DarknessOverlay")

@onready var loop_machine_anim: AnimatedSprite2D = get_node_or_null("objects/LoopMachine/AnimatedSprite2D")
@onready var oxygen_generator_anim: AnimatedSprite2D = get_node_or_null("objects/OxygenGenerator")
@onready var oxygen_bar_anim: AnimatedSprite2D = get_node_or_null("objects/OxygenBar")
@onready var life_pod_anim: AnimatedSprite2D = get_node_or_null("objects/LifePod")

@onready var result_panel = $UI/UIRoot/ResultPanel
@onready var panel_image = $UI/UIRoot/ResultPanel/PanelImage
@onready var result_message: Label = $UI/UIRoot/ResultPanel/MessageLabel
@onready var try_again_button = $UI/UIRoot/ResultPanel/TryAgainButton
@onready var next_button = $UI/UIRoot/ResultPanel/NextButton

@onready var door_anim: AnimatedSprite2D = get_node_or_null("objects/Door/AnimatedSprite2D")
@onready var door_blocker_collision: CollisionShape2D = get_node_or_null("objects/Door/DoorBlocker/CollisionShape2D")
@onready var exit_trigger: Area2D = get_node_or_null("objects/Door/ExitTrigger")

# AUDIO
@onready var ambience_player: AudioStreamPlayer = $AmbiencePlayer
@onready var oxygen_fill_player: AudioStreamPlayer = $OxygenFillPlayer

@onready var pickup_sound: AudioStreamPlayer = $SoundPlayers/PickupSound
@onready var drop_sound: AudioStreamPlayer = $SoundPlayers/DropSound
@onready var insert_sound: AudioStreamPlayer = $SoundPlayers/InsertSound
@onready var oxygen_pulse_sound: AudioStreamPlayer = $SoundPlayers/OxygenPulseSound
@onready var life_pod_sound: AudioStreamPlayer = $SoundPlayers/LifePodSound
@onready var success_sound: AudioStreamPlayer = $SoundPlayers/SuccessSound
@onready var error_sound: AudioStreamPlayer = $SoundPlayers/ErrorSound
@onready var door_open_sound: AudioStreamPlayer = $SoundPlayers/DoorOpenSound


func _ready():
	oxygen = 0
	target_oxygen = 10
	level_finished = false
	checking_rule = false

	result_panel.visible = false
	panel_image.visible = false
	try_again_button.visible = false
	next_button.visible = false

	play_level_start_audio()

	if exit_trigger != null:
		exit_trigger.monitoring = false
		exit_trigger.monitorable = false

		if not exit_trigger.body_entered.is_connected(_on_exit_trigger_body_entered):
			exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)

	if darkness_overlay != null:
		darkness_overlay.color.a = 0.45

	if lights != null:
		lights.modulate = Color.html("#FFD84D")

	play_level_start_animations()

	display_label.show_message("OXYGEN LOW\nCURRENT: 0\nTARGET: 10")

	if not try_again_button.pressed.is_connected(_on_try_again_button_pressed):
		try_again_button.pressed.connect(_on_try_again_button_pressed)

	if not next_button.pressed.is_connected(_on_next_button_pressed):
		next_button.pressed.connect(_on_next_button_pressed)


func update_loop_machine_state():
	if level_finished:
		return

	if checking_rule:
		return

	if not are_all_slots_filled():
		display_label.show_message("BUILD LOOP RULE\nWHILE ?\nDO ?")
		return

	checking_rule = true
	call_deferred("check_rule_after_all_slots_inserted")


func are_all_slots_filled() -> bool:
	return (
		slot_loop_variable.stored_value != null
		and slot_loop_operator.stored_value != null
		and slot_loop_value.stored_value != null
		and slot_action_variable.stored_value != null
		and slot_action_operator.stored_value != null
		and slot_action_value.stored_value != null
	)


func check_rule_after_all_slots_inserted():
	await get_tree().create_timer(0.25).timeout

	if level_finished:
		return



	if is_rule_correct():
		await run_success_sequence()
	else:
		show_fail_state()


func is_rule_correct() -> bool:
	return (
		str(slot_loop_variable.stored_value) == "oxygen"
		and str(slot_loop_operator.stored_value) == "<"
		and str(slot_loop_value.stored_value) == "10"
		and str(slot_action_variable.stored_value) == "oxygen"
		and str(slot_action_operator.stored_value) == "+"
		and str(slot_action_value.stored_value) == "2"
	)


func run_success_sequence():
	level_finished = true

	play_correct_rule_animations()
	play_oxygen_fill_sound()

	if lights != null:
		lights.modulate = Color.html("#35D0FF")

	display_label.show_message("LOOP ACCEPTED\nFILLING OXYGEN")

	while oxygen < target_oxygen:
		await get_tree().create_timer(0.45).timeout
		oxygen += 2

		play_oxygen_pulse_sound()

		display_label.show_message("OXYGEN FILLING\nCURRENT: " + str(oxygen))

	play_safe_animations()

	stop_oxygen_fill_sound()
	play_life_pod_sound()
	play_success_sound()

	fade_darkness_to(0.0)

	display_label.show_message("OXYGEN STABLE\nCURRENT: 10\nLIFE SUPPORT ONLINE")

	await get_tree().create_timer(0.5).timeout
	show_success_panel()


func show_fail_state():
	level_finished = true
	checking_rule = false

	play_wrong_rule_animations()
	play_error_sound()

	if lights != null:
		lights.modulate = Color.html("#FF4D4D")

	if darkness_overlay != null:
		darkness_overlay.color.a = 0.45

	display_label.show_message("LOOP ERROR\nOXYGEN NOT STABLE")

	result_panel.visible = true
	panel_image.visible = true

	if fail_panel_texture != null:
		panel_image.texture = fail_panel_texture
	else:
		print("Missing fail_panel_texture on Level3 root")

	result_message.visible = true
	result_message.text = "loop error\ntry again"
	result_message.add_theme_color_override("font_color", Color.html("#FF4D4D"))

	try_again_button.visible = true
	next_button.visible = false


func show_success_panel():
	result_panel.visible = true
	panel_image.visible = true

	if success_panel_texture != null:
		panel_image.texture = success_panel_texture
	else:
		print("Missing success_panel_texture on Level3 root")

	result_message.visible = true
	result_message.text = "oxygen stable\nlife support online"
	result_message.add_theme_color_override("font_color", Color.html("#4DFF88"))

	try_again_button.visible = false
	next_button.visible = true


func _on_try_again_button_pressed():
	get_tree().reload_current_scene()


func _on_next_button_pressed():
	unlock_exit_after_success()


func unlock_exit_after_success():
	result_panel.visible = false

	play_door_open_sound()

	if door_anim != null:
		if door_anim.sprite_frames.has_animation("open"):
			door_anim.play("open")

	if door_blocker_collision != null:
		door_blocker_collision.disabled = true

	if exit_trigger != null:
		exit_trigger.monitoring = true
		exit_trigger.monitorable = true


func _on_exit_trigger_body_entered(body):
	if body is CharacterBody2D:
		get_tree().change_scene_to_file(next_scene_path)


func fade_darkness_to(target_alpha: float):
	if darkness_overlay == null:
		return

	var tween = create_tween()
	tween.tween_property(darkness_overlay, "color:a", target_alpha, 0.8)


func play_level_start_animations():
	play_animation_if_exists(loop_machine_anim, "idle")
	play_animation_if_exists(oxygen_generator_anim, "empty")
	play_animation_if_exists(oxygen_bar_anim, "empty")
	play_animation_if_exists(life_pod_anim, "closed")


func play_correct_rule_animations():
	play_animation_if_exists(loop_machine_anim, "active")
	play_animation_if_exists(oxygen_generator_anim, "filling")
	play_animation_if_exists(oxygen_bar_anim, "filling")
	play_animation_if_exists(life_pod_anim, "waking")


func play_safe_animations():
	play_animation_if_exists(loop_machine_anim, "active")
	play_animation_if_exists(oxygen_generator_anim, "full")
	play_animation_if_exists(oxygen_bar_anim, "full")
	play_animation_if_exists(life_pod_anim, "active")


func play_wrong_rule_animations():
	play_animation_if_exists(loop_machine_anim, "error")
	play_animation_if_exists(oxygen_generator_anim, "error")
	play_animation_if_exists(oxygen_bar_anim, "error")
	play_animation_if_exists(life_pod_anim, "closed")


func play_animation_if_exists(animated_sprite: AnimatedSprite2D, animation_name: String):
	if animated_sprite == null:
		print("Missing AnimatedSprite2D for animation: ", animation_name)
		return

	if animated_sprite.sprite_frames == null:
		print("Missing SpriteFrames on: ", animated_sprite.name)
		return

	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		print("Missing animation: ", animation_name, " on ", animated_sprite.name)


# -------------------------
# AUDIO FUNCTIONS
# -------------------------

func play_level_start_audio():
	if ambience_player != null:
		ambience_player.play()

	if oxygen_fill_player != null:
		oxygen_fill_player.stop()


func play_pickup_sound():
	if pickup_sound != null:
		pickup_sound.play()


func play_drop_sound():
	if drop_sound != null:
		drop_sound.play()


func play_insert_sound():
	if insert_sound != null:
		insert_sound.play()




func play_oxygen_fill_sound():
	print("Trying to play OxygenFillPlayer")

	oxygen_fill_should_loop = true

	if oxygen_fill_player == null:
		print("ERROR: OxygenFillPlayer node is null")
		return

	if oxygen_fill_player.stream == null:
		print("ERROR: OxygenFillPlayer has no audio stream assigned")
		return

	print("OxygenFillPlayer found, playing now")
	oxygen_fill_player.play()

func stop_oxygen_fill_sound():
	if oxygen_fill_player != null and oxygen_fill_player.playing:
		oxygen_fill_player.stop()


func play_oxygen_pulse_sound():
	if oxygen_pulse_sound != null:
		oxygen_pulse_sound.play()


func play_life_pod_sound():
	if life_pod_sound != null:
		life_pod_sound.play()


func play_success_sound():
	if success_sound != null:
		success_sound.play()


func play_error_sound():
	stop_oxygen_fill_sound()

	if error_sound != null:
		error_sound.play()


func play_door_open_sound():
	if door_open_sound != null:
		door_open_sound.play()
		
