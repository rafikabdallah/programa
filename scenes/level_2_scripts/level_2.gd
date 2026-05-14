extends Node2D

var pressure := 20
var safe_pressure := 15
var level_finished := false
var checking_rule := false

@export var success_panel_texture: Texture2D
@export var fail_panel_texture: Texture2D
@export var next_level_path := "res://scenes/level3.tscn"

@onready var if_machine = $objects/IFMachine

@onready var if_machine_anim: AnimatedSprite2D = $objects/IFMachine/AnimatedSprite2D
@onready var pressure_tank_anim: AnimatedSprite2D = $objects/PressureTank
@onready var pressure_bar_anim: AnimatedSprite2D = $objects/PressureBarTank

@onready var slot_condition_operator = $objects/IFMachine/SlotConditionOperator
@onready var slot_condition_value = $objects/IFMachine/SlotConditionValue
@onready var slot_action_operator = $objects/IFMachine/SlotActionOperator
@onready var slot_action_value = $objects/IFMachine/SlotActionValue

@onready var display_label = $objects/display_screen/DisplayLabel

@onready var light_layer = $lights
@onready var darkness_overlay = $DarknessOverlay

@onready var result_panel = $UI/UIRoot/ResultPanel
@onready var panel_image = $UI/UIRoot/ResultPanel/PanelImage
@onready var result_message: Label = $UI/UIRoot/ResultPanel/MessageLabel
@onready var try_again_button = $UI/UIRoot/ResultPanel/TryAgainButton
@onready var next_button = $UI/UIRoot/ResultPanel/NextButton

@onready var door_anim: AnimatedSprite2D = $objects/Door/AnimatedSprite2D
@onready var door_blocker_collision: CollisionShape2D = $objects/Door/DoorBlocker/CollisionShape2D
@onready var exit_trigger = $objects/Door/ExitTrigger

@onready var ambience_player: AudioStreamPlayer = $AmbiencePlayer
@onready var pressure_hiss_player: AudioStreamPlayer = $PressureHissPlayer

@onready var pickup_sound: AudioStreamPlayer = $SoundPlayers/PickupSound
@onready var drop_sound: AudioStreamPlayer = $SoundPlayers/DropSound
@onready var insert_sound: AudioStreamPlayer = $SoundPlayers/InsertSound
@onready var pressure_release_sound: AudioStreamPlayer = $SoundPlayers/PressureReleaseSound
@onready var success_sound: AudioStreamPlayer = $SoundPlayers/SuccessSound
@onready var error_sound: AudioStreamPlayer = $SoundPlayers/ErrorSound
@onready var door_open_sound: AudioStreamPlayer = $SoundPlayers/DoorOpenSound


func _ready():
	pressure = 20
	safe_pressure = 15
	level_finished = false
	checking_rule = false

	result_panel.visible = false
	panel_image.visible = false
	try_again_button.visible = false
	next_button.visible = false
	next_button.disabled = false

	exit_trigger.monitoring = false
	exit_trigger.monitorable = false

	try_again_button.pressed.connect(_on_try_again_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)

	darkness_overlay.color.a = 0.35
	light_layer.modulate = Color.html("#FFD84D")

	play_level_start_audio()
	play_level_start_animations()

	display_label.show_message("PRESSURE TOO HIGH\nCURRENT: 20\nSAFE MAX: 15")


func update_if_machine_state():
	if level_finished:
		return

	if checking_rule:
		return

	if not are_all_slots_filled():
		display_label.show_message("BUILD SAFETY RULE\nPRESSURE > ?\nACTION - ?")
		return

	checking_rule = true
	call_deferred("check_rule_after_all_slots_inserted")


func are_all_slots_filled() -> bool:
	return (
		slot_condition_operator.stored_value != null
		and slot_condition_value.stored_value != null
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
		str(slot_condition_operator.stored_value) == ">"
		and str(slot_condition_value.stored_value) == "15"
		and str(slot_action_operator.stored_value) == "-"
		and str(slot_action_value.stored_value) == "1"
	)


func run_success_sequence():
	level_finished = true

	play_correct_rule_animations()

	light_layer.modulate = Color.html("#FFD84D")
	display_label.show_message("RULE ACCEPTED\nSTABILIZING PRESSURE")

	lock_puzzle_after_success()

	while pressure > safe_pressure:
		await get_tree().create_timer(0.45).timeout
		pressure -= 1

		play_pressure_release_sound()
		display_label.show_message("PRESSURE LOWERING\nCURRENT: " + str(pressure))

	play_safe_animations()

	light_layer.modulate = Color.html("#35D0FF")
	fade_darkness_to(0.0)

	display_label.show_message("PRESSURE STABLE\nCURRENT: 15\nSYSTEM SAFE")

	play_success_sound()

	await get_tree().create_timer(0.5).timeout
	show_success_panel()


func show_fail_state():
	level_finished = true
	checking_rule = false

	play_wrong_rule_animations()

	light_layer.modulate = Color.html("#FF4D4D")
	darkness_overlay.color.a = 0.45

	display_label.show_message("UNSAFE RULE\nPRESSURE NOT STABLE")

	play_error_sound()

	result_panel.visible = true
	panel_image.visible = true
	panel_image.texture = fail_panel_texture

	result_message.visible = true
	result_message.text = "unsafe rule\ntry again"
	result_message.add_theme_color_override("font_color", Color.html("#FF4D4D"))

	try_again_button.visible = true
	next_button.visible = false


func show_success_panel():
	result_panel.visible = true
	panel_image.visible = true
	panel_image.texture = success_panel_texture

	result_message.visible = true
	result_message.text = "pressure stable\nsystem safe"
	result_message.add_theme_color_override("font_color", Color.html("#4DFF88"))

	try_again_button.visible = false
	next_button.visible = true
	next_button.disabled = false


func lock_puzzle_after_success():
	var pieces = get_tree().get_nodes_in_group("level_piece")
	for piece in pieces:
		if piece.has_method("disable_after_success"):
			piece.disable_after_success()

	var slots = get_tree().get_nodes_in_group("machine_slot")
	for slot in slots:
		if slot.has_method("lock_slot"):
			slot.lock_slot()

	var player = get_node_or_null("objects/E-lis")
	if player != null and player.has_method("set_interaction_enabled"):
		player.set_interaction_enabled(false)


func _on_try_again_button_pressed():
	get_tree().reload_current_scene()


func _on_next_button_pressed():
	unlock_exit_after_success()


func unlock_exit_after_success():
	result_panel.visible = false

	play_door_open_sound()

	if door_anim.sprite_frames.has_animation("open"):
		door_anim.play("open")

	door_blocker_collision.disabled = true

	exit_trigger.monitoring = true
	exit_trigger.monitorable = true


func _on_exit_trigger_body_entered(body):
	if body.name == "E-lis":
		get_tree().change_scene_to_file(next_level_path)


func play_level_start_animations():
	play_animation_if_exists(if_machine_anim, "idle")
	play_animation_if_exists(pressure_tank_anim, "high")
	play_animation_if_exists(pressure_bar_anim, "high")


func play_correct_rule_animations():
	play_animation_if_exists(if_machine_anim, "active")
	play_animation_if_exists(pressure_tank_anim, "lowering")
	play_animation_if_exists(pressure_bar_anim, "lowering")


func play_safe_animations():
	play_animation_if_exists(if_machine_anim, "active")
	play_animation_if_exists(pressure_tank_anim, "safe")
	play_animation_if_exists(pressure_bar_anim, "safe")


func play_wrong_rule_animations():
	play_animation_if_exists(if_machine_anim, "error")
	play_animation_if_exists(pressure_tank_anim, "high")
	play_animation_if_exists(pressure_bar_anim, "high")


func play_animation_if_exists(animated_sprite: AnimatedSprite2D, animation_name: String):
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)


func fade_darkness_to(target_alpha: float):
	var tween = create_tween()
	tween.tween_property(darkness_overlay, "color:a", target_alpha, 0.8)


func play_level_start_audio():
	ambience_player.play()
	pressure_hiss_player.play()


func play_pickup_sound():
	pickup_sound.play()


func play_drop_sound():
	drop_sound.play()


func play_insert_sound():
	insert_sound.play()


func play_pressure_release_sound():
	pressure_release_sound.play()


func play_success_sound():
	if pressure_hiss_player.playing:
		pressure_hiss_player.stop()

	success_sound.play()


func play_error_sound():
	error_sound.play()


func play_door_open_sound():
	door_open_sound.play()
