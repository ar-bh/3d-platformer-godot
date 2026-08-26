class_name GobotSkin extends Node3D

## Determines whether blinking is enabled or disabled.
@export var is_blinking := true:
	set = set_blinking

## Gobot's MeshInstance3D model.
@export var gobot_model: MeshInstance3D = null

@export var left_eye_mat_override := ""
@export var right_eye_mat_override := ""
@export var opened_eye: CompressedTexture2D = null
@export var closed_eye: CompressedTexture2D = null

@onready var _blink_timer = %BlinkTimer
@onready var _closed_eyes_timer = %ClosedEyesTimer

@onready var _left_eye_mat: StandardMaterial3D = gobot_model.get(left_eye_mat_override)
@onready var _right_eye_mat: StandardMaterial3D = gobot_model.get(right_eye_mat_override)

@onready var animation_player: AnimationPlayer = $gobot/AnimationPlayer

func _ready() -> void:
	is_blinking = is_blinking

	_blink_timer.timeout.connect(
		func() -> void:
			_left_eye_mat.albedo_texture = closed_eye
			_right_eye_mat.albedo_texture = closed_eye
			_closed_eyes_timer.start(_closed_eyes_timer.wait_time)
	)

	_closed_eyes_timer.timeout.connect(
		func() -> void:
			_left_eye_mat.albedo_texture = opened_eye
			_right_eye_mat.albedo_texture = opened_eye
			_blink_timer.start(randf_range(1.0, 8.0))
	)

func set_blinking(new_is_blinking: bool) -> void:
	is_blinking = new_is_blinking
	if not is_node_ready():
		return

	if is_blinking:
		_blink_timer.start(0.2)
	else:
		_blink_timer.stop()
		_closed_eyes_timer.stop()

func edge_grab() -> void:
	if animation_player.current_animation != "edge_grab":
		animation_player.play("edge_grab", 0.05)
	
func fall() -> void:
	if animation_player.current_animation != "fall":
		animation_player.play("fall", 0.2)

func flip() -> void:
	if animation_player.current_animation != "flip":
		animation_player.play("flip", 0.05)
	
func idle() -> void:
	if animation_player.current_animation != "idle":
		animation_player.play("idle", 0.15)
	
func jump() -> void:
	if animation_player.current_animation != "jump":
		animation_player.play("jump", 0.1)
	
func run() -> void:
	if animation_player.current_animation != "run":
		animation_player.play("run", 0.12)
	
func victory_sign() -> void:
	if animation_player.current_animation != "victory_sign":
		animation_player.play("victory_sign", 0.2)
	
func walk() -> void:
	if animation_player.current_animation != "walk":
		animation_player.play("walk", 0.1)
	
func wall_slide() -> void:
	if animation_player.current_animation != "wall_slide":
		animation_player.play("wall_slide", 0.05)
