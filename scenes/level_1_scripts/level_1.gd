extends Node2D

var current_x = null

@onready var display_label: Label = $objects/display_screen/DisplayLabel
@onready var light_layer: TileMapLayer = $lights
@onready var darkness_overlay: ColorRect = $DarknessOverlay

@onready var battery_anim: AnimatedSprite2D = $objects/battrie
@onready var monitor_anim: AnimatedSprite2D = $objects/cool_display

@export var success_panel_texture: Texture2D
@export var fail_panel_texture: Texture2D

@onready var result_panel = $UI/UIRoot/ResultPanel
@onready var panel_image: TextureRect = $UI/UIRoot/ResultPanel/PanelImage
@onready var result_message: Label = $UI/UIRoot/ResultPanel/MessageLabel
@onready var try_again_button = $UI/UIRoot/ResultPanel/TryAgainButton
@onready var next_button = $UI/UIRoot/ResultPanel/NextButton

@onready var door_anim: AnimatedSprite2D = $objects/Door/AnimatedSprite2D
@onready var door_blocker_collision: CollisionShape2D = $objects/Door/DoorBlocker/CollisionShape2D
@onready var exit_trigger = $objects/Door/ExitTrigger
@onready var value_5 = $objects/Value5

@onready var guide_panel = $UI/UIRoot/GuidePanel
@onready var continue_hint: Label = $UI/UIRoot/GuidePanel/ContinueHint
@onready var e_lis = $"objects/E-lis"

@onready var ambience_player: AudioStreamPlayer = $AmbiencePlayer
@onready var pickup_sound: AudioStreamPlayer = $SoundPlayers/PickupSound
@onready var insert_sound: AudioStreamPlayer = $SoundPlayers/InsertSound
@onready var success_sound: AudioStreamPlayer = $SoundPlayers/SuccessSound
@onready var error_sound: AudioStreamPlayer = $SoundPlayers/ErrorSound
@onready var door_open_sound: AudioStreamPlayer = $SoundPlayers/DoorOpenSound
@onready var drop_sound: AudioStreamPlayer = $SoundPlayers/DropSound

var guide_active := true
var blink_timer := 0.0


func _ready():
	ambience_player.play()

	guide_panel.visible = true
	continue_hint.visible = true
	guide_active = true
	blink_timer = 0.0

	e_lis.set_input_enabled(false)

	result_panel.visible = false
	try_again_button.visible = false
	next_button.visible = false
	next_button.disabled = false

	exit_trigger.monitoring = false
	exit_trigger.monitorable = false

	try_again_button.pressed.connect(restart_level)
	next_button.pressed.connect(open_door_from_panel)
	exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)

	set_waiting_state()


func _process(delta):
	if guide_active == false:
		return

	blink_timer += delta

	if blink_timer >= 0.5:
		blink_timer = 0.0
		continue_hint.visible = !continue_hint.visible


func _input(event):
	if guide_active == false:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		close_guide_panel()
		return

	if event is InputEventMouseButton and event.pressed:
		close_guide_panel()
		return


func close_guide_panel():
	guide_active = false
	guide_panel.visible = false
	continue_hint.visible = true

	e_lis.set_input_enabled(true)


func set_x_value(value):
	if current_x == value:
		return

	current_x = value

	if current_x == 2:
		set_success_state()
	elif current_x == 5:
		set_error_state()


func set_waiting_state():
	light_layer.modulate = Color.html("#FFD84D")
	darkness_overlay.modulate = Color("#00000080")

	display_label.show_message("needs 2 power")

	play_if_exists(battery_anim, "off")
	play_if_exists(monitor_anim, "broken")


func set_success_state():
	light_layer.modulate = Color.html("#35D0FF")
	success_sound.play()

	display_label.show_message("x = 2\npower restoring /\\")

	play_if_exists(battery_anim, "recharge")
	await get_tree().create_timer(1.0).timeout

	play_if_exists(battery_anim, "full")
	play_if_exists(monitor_anim, "on")

	fade_darkness(0.15)
	show_success_result()


func set_error_state():
	light_layer.modulate = Color.html("#FF4D4D")
	darkness_overlay.modulate = Color("#00000080")
	error_sound.play()

	display_label.show_message("too much power\nsystem error")

	await get_tree().create_timer(1.0).timeout
	show_fail_result()


func fade_darkness(target_alpha: float):
	var tween = create_tween()
	tween.tween_property(
		darkness_overlay,
		"modulate:a",
		target_alpha,
		0.8
	)


func play_if_exists(animated_sprite: AnimatedSprite2D, anim_name: String):
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)


func show_fail_result():
	result_panel.visible = true

	panel_image.visible = true
	panel_image.texture = fail_panel_texture

	result_message.visible = true
	result_message.add_theme_color_override("font_color", Color.html("#FF4D4D"))
	result_message.text = "wrong value\ntry again"

	try_again_button.visible = true
	next_button.visible = false


func show_success_result():
	result_panel.visible = true

	panel_image.visible = true
	panel_image.texture = success_panel_texture

	result_message.visible = true
	result_message.add_theme_color_override("font_color", Color.html("#4DFF88"))
	result_message.text = "system restored\nlogic accepted"

	try_again_button.visible = false
	next_button.visible = true
	next_button.disabled = false


func restart_level():
	get_tree().reload_current_scene()


func open_door_from_panel():
	next_button.disabled = true
	result_panel.visible = false

	disable_value_5_after_success()

	door_open_sound.play()

	if door_anim.sprite_frames.has_animation("open"):
		door_anim.play("open")
		await door_anim.animation_finished

	door_blocker_collision.disabled = true

	exit_trigger.monitoring = true
	exit_trigger.monitorable = true


func disable_value_5_after_success():
	value_5.visible = false
	value_5.monitoring = false
	value_5.monitorable = false

	var value_collision = value_5.get_node_or_null("CollisionShape2D")
	if value_collision != null:
		value_collision.disabled = true


func play_pickup_sound():
	pickup_sound.play()


func play_insert_sound():
	insert_sound.play()
	
func play_drop_sound():
	drop_sound.play()


func _on_exit_trigger_body_entered(body: Node2D) -> void:
	if body.name == "E-lis":
		body.visible = false
		await get_tree().create_timer(0.4).timeout
		get_tree().change_scene_to_file("res://scenes/level2.tscn")
