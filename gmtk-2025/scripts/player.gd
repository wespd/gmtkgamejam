extends CharacterBody2D

const DIMENSIONS : Vector2 = Vector2(16,16)

@export_group("frame data ")
@export var acceleration_frames : int = 10
@export var deacceleration_frames : int = 6
@export var jump_accent_frames : int = 30
@export var jump_deccent_frames : int = 20
@export var coyote_jump_frames : int = 15
@export var input_buffer_frames : int = 15
@export var dash_wind_up_frames : int = 60
@export var wall_jump_input_lock_frames : int = 30

@export_group("movement data")
@export var max_speed : float = 100
@export var jump_hieght_relative_to_player_height : float = 3
@export var wall_jump_horizontal_multiplier : float
@export var wall_jump_vertical_multiplier : float
@export var wall_drag_multiplier : float
@export var max_y_velocity : float

@export_category("sounds")
@export var walk_sounds : Array[AudioStreamWAV] = []
@export var dash_sounds : Array[AudioStreamWAV] = []
@export var woosh_sounds : Array[AudioStreamWAV] = []
@export var walk_noise_delay_frames : int = 15
@onready var audio_stream_player = $AudioStreamPlayer
@export var slide_sound : AudioStreamWAV
@export var death_sound : AudioStreamWAV
@onready var woosh_player = $wooshPlayer



enum FrameDataType 
{
	COYOTE_JUMP, INPUT_BUFFER, DASH_WIND_UP, WALL_JUMP_LOCK, COYOTE_WALL_JUMP, WALK_NOISE_DELAY
}
var tween : Tween

##constants for horizontal movement
var acceleration_speed : float
var deacceleration_speed : float

var initial_jump_velocity : float
var acceleration_due_to_gravity : float
var gravity_snap_multiplier : float

var current_frame_data : Array[int] = []
var left_wall_jump_ray_casts : Array[RayCast2D] = []
var right_wall_jump_ray_casts : Array[RayCast2D] = []

var wall_jump_direction : float = 0

var current_horizontal_movement : float

var can_input : bool = true
var can_move : bool = true
var is_dashing : bool = false
var is_sliding : bool = false
var is_dying : bool = false

var last_direction : float
var is_player_disabled : bool = false

@onready var hurtbox = $Hurtbox
@onready var wall_jump_cooldown_timer = $WallJumpCooldownTimer
@onready var area_2d = $Area2D
@onready var sprite_2d = $Sprite2D


func _ready():
	initialize_constants()
	initialize_frame_data()
	initialize_ray_casts(3)
	hurtbox.body_entered.connect(on_hit)
	hurtbox.area_entered.connect(on_hit)
	area_2d.area_entered.connect(on_enter_portal)
	area_2d.body_entered.connect(on_enter_portal)
	wall_jump_cooldown_timer.timeout.connect(on_wall_jump_complete)
	EventBus.player_death.connect(on_death)
	EventBus.disable_player.connect(player_disable)
	EventBus.enable_player.connect(player_enable)
	LevelManager.player = self
	
	
func _physics_process(delta):
	increment_frame_data()
	handle_inputs()
	handle_jump(delta)
	handle_movement(delta)
	handle_wall_jump()
	handle_dash()
	handle_friction(delta)
	handle_animations()
	handle_sounds()
	move_and_slide()
	

func initialize_constants():
	acceleration_speed = max_speed / (float(acceleration_frames) / 60 )
	deacceleration_speed = max_speed / (float(deacceleration_frames) / 60 )
	print(acceleration_speed)
	print(deacceleration_speed)
	
	initial_jump_velocity = 2 * jump_hieght_relative_to_player_height * DIMENSIONS.y / (float(jump_accent_frames) / 60)
	print(initial_jump_velocity)
	acceleration_due_to_gravity = 2 * jump_hieght_relative_to_player_height * DIMENSIONS.y / pow(float(jump_accent_frames) / 60, 2)
	print(acceleration_due_to_gravity)
	
	var decent_acel = 2 * jump_hieght_relative_to_player_height * DIMENSIONS.y / pow(float(jump_deccent_frames) / 60.0, 2)
	gravity_snap_multiplier = decent_acel / acceleration_due_to_gravity
	print(gravity_snap_multiplier)
	
func initialize_frame_data():
	for type in FrameDataType.keys():
		print("Initializing %s" %type)
		current_frame_data.append(0)
	current_frame_data[FrameDataType.INPUT_BUFFER] = input_buffer_frames
	current_frame_data[FrameDataType.COYOTE_JUMP] = coyote_jump_frames
	current_frame_data[FrameDataType.WALL_JUMP_LOCK] = wall_jump_input_lock_frames
	current_frame_data[FrameDataType.COYOTE_WALL_JUMP] = coyote_jump_frames
	
func initialize_ray_casts(amount : int):
	var increment : float = (DIMENSIONS.y - 1.2)  / (amount - 1)
	for i in amount:
		var raycast := RayCast2D.new()
		raycast.position.y = (DIMENSIONS.y - 1.2) /2 - increment * i
		raycast.target_position = Vector2(DIMENSIONS.x/2 + 0.5, 0)
		self.add_child(raycast)
		right_wall_jump_ray_casts.append(raycast)
		
		raycast = RayCast2D.new()
		raycast.position.y = (DIMENSIONS.y - 1.2) /2 - increment * i
		raycast.target_position = Vector2(-DIMENSIONS.x/2 - 0.5, 0)
		self.add_child(raycast)
		left_wall_jump_ray_casts.append(raycast)
		
	
func increment_frame_data():
	current_frame_data[FrameDataType.INPUT_BUFFER] += 1
	current_frame_data[FrameDataType.COYOTE_JUMP] += 1
	current_frame_data[FrameDataType.COYOTE_WALL_JUMP] += 1
	current_frame_data[FrameDataType.WALL_JUMP_LOCK] += 1
	current_frame_data[FrameDataType.WALK_NOISE_DELAY] += 1
	if Input.is_action_pressed("dash") and is_on_floor():
		velocity.x = 0
		current_frame_data[FrameDataType.DASH_WIND_UP] += 1
	
func handle_inputs():
	if Input.is_action_just_pressed("jump"):
		current_frame_data[FrameDataType.INPUT_BUFFER] = 0

	if not can_input or not can_move or is_player_disabled:
		current_horizontal_movement = 0
		return

	current_horizontal_movement = Input.get_axis("move_left", "move_right")
	if current_horizontal_movement != 0.0 and current_frame_data[FrameDataType.DASH_WIND_UP] == 0 and not is_dashing:
		last_direction = current_horizontal_movement
	
	
func handle_jump(delta : float):
	if is_on_floor():
		current_frame_data[FrameDataType.COYOTE_JUMP] = 0
	if not can_move or is_player_disabled:
		return
		
	velocity.y += acceleration_due_to_gravity * delta * (1 if velocity.y < 0 or is_dashing else gravity_snap_multiplier)
	if velocity.y > max_y_velocity:
		velocity.y = max_y_velocity
	if is_on_wall() and  velocity.y > max_y_velocity * wall_drag_multiplier:
		velocity.y = max_y_velocity * wall_drag_multiplier
		is_sliding = true
	else:
		is_sliding = false
	
	if not can_input or current_frame_data[FrameDataType.DASH_WIND_UP] != 0 or is_player_disabled:
		return
		
	if current_frame_data[FrameDataType.COYOTE_JUMP] < coyote_jump_frames and current_frame_data[FrameDataType.INPUT_BUFFER]  < input_buffer_frames:
		velocity.y = -initial_jump_velocity
		if is_on_wall():
			velocity.y += get_platform_velocity().y
		current_frame_data[FrameDataType.COYOTE_JUMP] = coyote_jump_frames
		current_frame_data[FrameDataType.INPUT_BUFFER]  = input_buffer_frames
		
	
func handle_movement(delta : float):
	if is_dashing or current_frame_data[FrameDataType.DASH_WIND_UP] != 0:
		return
	var direction = velocity.abs().x / velocity.x
	velocity.x += current_horizontal_movement * (acceleration_speed if direction > 0 else deacceleration_speed) * delta
	if absf(velocity.x) > max_speed and not is_dashing:
		velocity.x = max_speed * direction
		
func handle_wall_jump():
	if not can_input or not can_move or is_dashing or is_player_disabled:
		return
		
	var left_colliding : bool = false
	var right_colliding : bool = false
	var left_distance : float = 10
	var right_distance : float = 10
	for raycast in left_wall_jump_ray_casts:
		if raycast.is_colliding():
			current_frame_data[FrameDataType.COYOTE_WALL_JUMP] = 0
			wall_jump_direction = -1
			left_colliding = true
			var distance = raycast.get_collision_point().distance_to(global_position)
			if distance < left_distance:
				left_distance = distance
	for raycast in right_wall_jump_ray_casts:
		if raycast.is_colliding():
			current_frame_data[FrameDataType.COYOTE_WALL_JUMP] = 0
			wall_jump_direction = 1
			right_colliding = true
			var distance = raycast.get_collision_point().distance_to(global_position)
			if distance < right_distance:
				right_distance = distance
	
	if left_colliding and right_colliding:
		wall_jump_direction = -1 if left_distance < right_distance else 1
	
	if current_frame_data[FrameDataType.INPUT_BUFFER] < input_buffer_frames and not is_on_floor() and (left_colliding or right_colliding):
		velocity.x = max_speed * wall_jump_horizontal_multiplier * -wall_jump_direction
		velocity.y = -initial_jump_velocity * wall_jump_vertical_multiplier
		current_frame_data[FrameDataType.COYOTE_WALL_JUMP] = coyote_jump_frames
		current_frame_data[FrameDataType.INPUT_BUFFER] = input_buffer_frames
		can_input = false
		wall_jump_cooldown_timer.start(float(wall_jump_input_lock_frames) / 60)
		woosh_player.stream = woosh_sounds.pick_random()
		woosh_player.playing = true
			
	
		
	
	
func handle_dash():
	if not can_input or not can_move or is_player_disabled:
		return

		
	if is_on_floor() or is_on_wall() or velocity.x == 0.0:
		is_dashing = false
		
	if current_frame_data[FrameDataType.DASH_WIND_UP] >= dash_wind_up_frames and Input.is_action_just_released("dash"):
		is_dashing = true
		current_frame_data[FrameDataType.DASH_WIND_UP] = 0
		var time := (2 * sqrt(2 * DIMENSIONS.y / acceleration_due_to_gravity))
		var distance := 6 * DIMENSIONS.x
		velocity.x = max_speed * 1.75 * last_direction
		velocity.y = -(distance - 1/2 * acceleration_due_to_gravity * time * time)/time
		
	if not Input.is_action_pressed("dash"):
		current_frame_data[FrameDataType.DASH_WIND_UP] = 0
func handle_friction(delta : float):
	if current_horizontal_movement != 0.0 and not is_dashing or velocity.x == 0 or not can_input or is_player_disabled:
		return
	
	var direction = velocity.abs().x / velocity.x
	var amount = deacceleration_speed * delta * direction * (0 if is_dashing and (current_horizontal_movement == last_direction or current_horizontal_movement == 0.0) else 1)
	if velocity.abs().x - absf(amount) > 0:
		velocity.x -= amount
	else:
		velocity.x = 0
		
		
func handle_animations():
	if is_dying:
		sprite_2d.play("death")
		return
	if velocity.x < 0:
		sprite_2d.flip_h = true
	elif velocity.x > 0:
		sprite_2d.flip_h = false
	if velocity.y == initial_jump_velocity:
		sprite_2d.play("jump")
	elif current_frame_data[FrameDataType.DASH_WIND_UP] != 0:
		if current_frame_data[FrameDataType.DASH_WIND_UP] <= dash_wind_up_frames:
			sprite_2d.play("dash_charge")
		else:
			sprite_2d.frame = 0
	elif is_on_wall_only():
		sprite_2d.play("slide")
	elif not is_on_floor():
		if velocity.y > 0:
			sprite_2d.play("deccending")
		else:
			sprite_2d.play("accending")
	elif current_horizontal_movement:
		sprite_2d.play("walk")
	else:
		sprite_2d.play("idle")
		
func handle_sounds():
	if is_player_disabled:
		audio_stream_player.playing = false
		audio_stream_player.stream = null
		woosh_player.playing = false
		woosh_player.stream = null
	if not is_on_wall():
		if audio_stream_player.playing and audio_stream_player.stream == slide_sound:
			audio_stream_player.playing = false
			audio_stream_player.stream = null

	if velocity.y == initial_jump_velocity:
		print("jump")

	elif Input.is_action_just_released("dash") and is_dashing and is_on_floor():
		audio_stream_player.stream = dash_sounds.pick_random()
		audio_stream_player.playing = true
		woosh_player.stream = woosh_sounds.pick_random()
		woosh_player.playing = true
		print("dash sound!")
	elif velocity.y == -initial_jump_velocity:
		woosh_player.stream = woosh_sounds.pick_random()
		woosh_player.playing = true
	elif is_on_wall_only():
		if not audio_stream_player.playing and audio_stream_player.stream != slide_sound:
			audio_stream_player.stream = slide_sound
			audio_stream_player.playing = true

	elif not is_on_floor():
		pass
	elif current_horizontal_movement and current_frame_data[FrameDataType.DASH_WIND_UP] == 0:
		if current_frame_data[FrameDataType.WALK_NOISE_DELAY] >= walk_noise_delay_frames:
			audio_stream_player.stream = walk_sounds.pick_random()
			audio_stream_player.playing = true
			current_frame_data[FrameDataType.WALK_NOISE_DELAY] = 0
		
func on_hit(body : Node2D):
	velocity = Vector2.ZERO
	UIOverlay.player_deaths += 1
	tween = get_tree().create_tween()
	tween.tween_method(set_shader_params, 0.0, 1.0, 0.5)
	audio_stream_player.stream = death_sound
	audio_stream_player.playing = true
	can_move = false
	await tween.finished
	set_shader_params(0.0)
	can_move = true
	EventBus.player_death.emit()
	
	
func on_death():
	velocity = Vector2.ZERO
func on_enter_portal(body : Node2D):
	EventBus.next_level.emit()
	

func player_disable():
	is_player_disabled = true

func player_enable():
	is_player_disabled = false
	
func on_wall_jump_complete():
	can_input = true
	
func set_shader_params(value : float):
	sprite_2d.material.set_shader_parameter("progress", value)
