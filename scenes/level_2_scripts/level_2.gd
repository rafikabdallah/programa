extends Node2D

var pressure := 16
var safe_pressure := 15
var level_finished := false
var checking_rule := false

@export var success_panel_texture: Texture2D
@export var fail_panel_texture: Texture2D

@export var next_level_path := "res://scenes/level3.tscn"

@onready var if_machine = $objects/IFMachine

@onready var if_machine_anim: AnimatedSprite2D = get_node_or_null("objects/IFMachine/AnimatedSprite2D")
@onready var pressure_tank_anim: AnimatedSprite2D = get_node_or_null("objects/PressureTank")
@onready var pressure_bar_anim: AnimatedSprite2D = get_node_or_null("objects/PressureBarTank")

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

# AUDIO
@onready var ambience_player: AudioStreamPlayer = $AmbiencePlayer
@onready var pressure_hiss_player: AudioStreamPlayer = $PressureHissPlayer

@onready var pickup_sound: AudioStreamPlayer = $SoundPlayers/PickupSound
@onready var drop_sound: AudioStreamPlayer = $SoundPlayers/DropSound
@onready var insert_sound: AudioStreamPlayer = $SoundPlayers/InsertSound
@onready var pressure_release_sound: AudioStreamPlayer= $SoundPlayers/PressureReleaseSound
@onready var success_sound: AudioStreamPlayer = $SoundPlayers/SuccessSound
@onready var error_sound: AudioStreamPlayer = $SoundPlayers/ErrorSound
@onready var door_open_sound: AudioStreamPlayer = $SoundPlayers/DoorOpenSound


func _ready():
	pressure = 20
	safe_pressure = 15
	level_finished = false
	checking_rule = false

	result_panel.visible = false
	try_again_button.visible = false
	next_button.visible = false

	play_level_start_audio()

	if exit_trigger != null:
		exit_trigger.monitoring = false
		exit_trigger.monitorable = false

		if not exit_trigger.body_entered.is_connected(_on_exit_trigger_body_entered):
			exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)

	if darkness_overlay != null:
		darkness_overlay.color.a = 0.35

	if light_layer != null:
		light_layer.modulate = Color.html("#FFD84D")

	play_level_start_animations()

	display_label.show_message("PRESSURE TOO HIGH\nCURRENT: 16\nSAFE MAX: 15")

	if not try_again_button.pressed.is_connected(_on_try_again_button_pressed):
		try_again_button.pressed.connect(_on_try_again_button_pressed)

	if not next_button.pressed.is_connected(_on_next_button_pressed):
		next_button.pressed.connect(_on_next_button_pressed)


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

	if light_layer != null:
		light_layer.modulate = Color.html("#35D0FF")

	display_label.show_message("RULE ACCEPTED\nSTABILIZING PRESSURE")

	while pressure > safe_pressure:
		await get_tree().create_timer(0.45).timeout
		pressure -= 1

		play_pressure_release_sound()

		display_label.show_message("PRESSURE LOWERING\nCURRENT: " + str(pressure))

	play_safe_animations()

	fade_darkness_to(0.0)

	display_label.show_message("PRESSURE STABLE\nCURRENT: 15\nSYSTEM SAFE")

	play_success_sound()

	await get_tree().create_timer(0.5).timeout
	show_success_panel()


func show_fail_state():
	level_finished = true
	checking_rule = false

	play_wrong_rule_animations()

	if light_layer != null:
		light_layer.modulate = Color.html("#FF4D4D")

	if darkness_overlay != null:
		darkness_overlay.color.a = 0.45

	if display_label != null:
		display_label.show_message("UNSAFE RULE\nPRESSURE NOT STABLE")

	play_error_sound()

	result_panel.visible = true
	panel_image.visible = true

	if fail_panel_texture != null:
		panel_image.texture = fail_panel_texture
	else:
		print("Missing fail_panel_texture on Level2 root")

	result_message.visible = true
	result_message.text = "unsafe rule\ntry again"
	result_message.add_theme_color_override("font_color", Color.html("#FF4D4D"))

	try_again_button.visible = true
	next_button.visible = false


func show_success_panel():
	result_panel.visible = true
	panel_image.visible = true

	if success_panel_texture != null:
		panel_image.texture = success_panel_texture
	else:
		print("Missing success_panel_texture in Level2 Inspector")

	result_message.visible = true
	result_message.text = "pressure stable\nsystem safe"
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


func fade_darkness_to(target_alpha: float):
	if darkness_overlay == null:
		return

	var tween = create_tween()
	tween.tween_property(darkness_overlay, "color:a", target_alpha, 0.8)


# -------------------------
# AUDIO FUNCTIONS
# -------------------------

func play_level_start_audio():
	if ambience_player != null:
		ambience_player.play()

	if pressure_hiss_player != null:
		pressure_hiss_player.play()


func play_pickup_sound():
	if pickup_sound != null:
		pickup_sound.play()


func play_drop_sound():
	if drop_sound != null:
		drop_sound.play()


func play_insert_sound():
	if insert_sound != null:
		insert_sound.play()




func play_pressure_release_sound():
	if pressure_release_sound != null:
		pressure_release_sound.play()


func play_success_sound():
	if pressure_hiss_player != null and pressure_hiss_player.playing:
		pressure_hiss_player.stop()

	if success_sound != null:
		success_sound.play()


func play_error_sound():
	if error_sound != null:
		error_sound.play()

	# PressureHissPlayer keeps playing on error.


func play_door_open_sound():
	if door_open_sound != null:
		door_open_sound.play()
