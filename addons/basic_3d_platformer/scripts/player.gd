class_name Player # setting a class name makes it easier to pull references of the player from other scripts and nodes
extends CharacterBody3D
# camera variables
@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25 # pre-determine the sensitivity and set a cap on it
# movement variables
@export_group("Movement")
@export var move_speed := 5.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0 # how quickly Gobot turns to face the move direction
@export var jump_velocity := 5.0
# this frame's mouse motion after sensitivity; applied in _physics_process
var _camera_input_direction := Vector2.ZERO
# default facing so Gobot does not snap on the first frame
var _last_movement_direction := Vector3.BACK

@onready var _camera_pivot: Node3D = $CameraPivot # direct child so using $ (not %) is okay
@onready var _camera: Camera3D = %Camera3D # usually use unique name (%) if the node is not a direct child
@onready var _skin: GobotSkin = $GobotSkin # rotate this instead of the CharacterBody3D so the camera does not spin

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # make mouse hidden
	elif event.is_action_pressed("ui_cancel"): # "ui_cancel" is a default input for escape (esc)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # show mouse

func _unhandled_input(event: InputEvent) -> void:
	# handle look when the mouse is captured
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	# rotate pivot vertically (along x-axis) then clamp so camera can not rotate too far / flip over
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI / 6.0, PI / 3.0) # these are tested values that work, feel free to change
	# rotate pivot horizontally (along y-axis)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO # reset this frame's look so it does not keep spinning after input is released
	
	# get a 2d input vector for movement
	var raw_input := Input.get_vector(
		"move_left",     # set as A in Input Map
		"move_right",    # set as D in Input Map
		"move_forward",  # set as W in Input Map
		"move_backward", # set as S in Input Map 
	)
	
	# camera-relative (pressing W walks where the camera looks, not the skin: Gobot)
	var forward := _camera.global_basis.z # store a relative reference to the camera's forward direction
	var right := _camera.global_basis.x # store a relative reference to the camera's right direction
	var move_direction := (forward * raw_input.y) + (right * raw_input.x)
	move_direction.y = 0.0 # flatten the move_direction so looking up or down does not make player fly
	move_direction = move_direction.normalized() # same speed no matter direction
	
	# apply gravity only if in the air
	if not is_on_floor():
		velocity += get_gravity() * delta # gravity from Project Settings -> Physics -> 3D
	# handle jump (set as space in Input Map) but only possible in air
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		
	# lerp only x and z so jump and gravity (y) are not pulled back to 0 when they shouldn't be
	var target_velocity := move_direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	
	# required for velocity to be implemented
	move_and_slide()
	
	if move_direction.length() > 0.2: # deadzone
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)
	
	# horizontal speed only (x and z), y is vertical and would count falling as running
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	
	# animations
	# IMPORTANT: these are custom functions adjusted from GDQuest's open source Gobot model!
	# the file was edited to make things easier. enter gobot_skin.gd to learn more
	if not is_on_floor():
		if velocity.y > 0.0:
			_skin.jump()
		else:
			_skin.fall()
	elif ground_speed > (move_speed / 2.0):
		_skin.run()
	elif ground_speed > 0.2:
		_skin.walk()
	else:
		_skin.idle()
