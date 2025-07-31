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

enum FrameDataType 
{
	COYOTE_JUMP, INPUT_BUFFER, DASH_WIND_UP, WALL_JUMP_LOCK, COYOTE_WALL_JUMP
}

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

var last_direction : float

@onready var hurtbox = $Hurtbox
@onready var wall_jump_cooldown_timer = $WallJumpCooldownTimer


func _ready():
	initialize_constants()
	initialize_frame_data()
	initialize_ray_casts(3)
	hurtbox.body_entered.connect(on_hit)
	wall_jump_cooldown_timer.timeout.connect(on_wall_jump_complete)
	#connect to any relevent signals
	
	
func _physics_process(delta):
	increment_frame_data()
	handle_inputs()
	handle_jump(delta)
	handle_movement(delta)
	handle_wall_jump()
	handle_dash()
	handle_friction(delta)
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
	var increment : float = DIMENSIONS.y / (amount - 1)
	for i in amount:
		var raycast := RayCast2D.new()
		raycast.position.y = DIMENSIONS.y/2 - increment * i
		raycast.target_position = Vector2(DIMENSIONS.x/2 + 0.5, 0)
		self.add_child(raycast)
		right_wall_jump_ray_casts.append(raycast)
		
		raycast = RayCast2D.new()
		raycast.position.y = DIMENSIONS.y/2 - increment * i
		raycast.target_position = Vector2(-DIMENSIONS.x/2 - 0.5, 0)
		self.add_child(raycast)
		left_wall_jump_ray_casts.append(raycast)
		
	
func increment_frame_data():
	current_frame_data[FrameDataType.INPUT_BUFFER] += 1
	current_frame_data[FrameDataType.COYOTE_JUMP] += 1
	current_frame_data[FrameDataType.COYOTE_WALL_JUMP] += 1
	current_frame_data[FrameDataType.WALL_JUMP_LOCK] += 1
	if Input.is_action_pressed("dash") and is_on_floor():
		current_frame_data[FrameDataType.DASH_WIND_UP] += 1
		print("charging dash! now at %s" %current_frame_data[FrameDataType.DASH_WIND_UP])
	
func handle_inputs():
	if Input.is_action_just_pressed("jump"):
		current_frame_data[FrameDataType.INPUT_BUFFER] = 0
		print("jump key pressed!")

	if not can_input or not can_move or is_dashing or current_frame_data[FrameDataType.DASH_WIND_UP] != 0:
		current_horizontal_movement = 0
		return
	

	current_horizontal_movement = Input.get_axis("move_left", "move_right")
	if current_horizontal_movement != 0.0:
		last_direction = current_horizontal_movement
	
	
func handle_jump(delta : float):
	if is_on_floor():
		current_frame_data[FrameDataType.COYOTE_JUMP] = 0
	if not can_move:
		return
		
	velocity.y += acceleration_due_to_gravity * delta * (1 if velocity.y < 0 or is_dashing else gravity_snap_multiplier)
	
	if not can_input:
		return
		
	if current_frame_data[FrameDataType.COYOTE_JUMP] < coyote_jump_frames and current_frame_data[FrameDataType.INPUT_BUFFER]  < input_buffer_frames:
		velocity.y = -initial_jump_velocity
		if is_on_wall():
			velocity.y += get_platform_velocity().y
		current_frame_data[FrameDataType.COYOTE_JUMP] = coyote_jump_frames
		current_frame_data[FrameDataType.INPUT_BUFFER]  = input_buffer_frames
		
	
func handle_movement(delta : float):
	var direction = velocity.abs().x / velocity.x
	velocity.x += current_horizontal_movement * (acceleration_speed if direction > 0 else deacceleration_speed) * delta
	if absf(velocity.x) > max_speed and not is_dashing:
		velocity.x = max_speed * direction
		
func handle_wall_jump():
	if not can_input or not can_move or is_dashing:
		return
		

	for raycast in left_wall_jump_ray_casts:
		if raycast.is_colliding():
			current_frame_data[FrameDataType.COYOTE_WALL_JUMP] = 0
			wall_jump_direction = -1
	for raycast in right_wall_jump_ray_casts:
		if raycast.is_colliding():
			current_frame_data[FrameDataType.COYOTE_WALL_JUMP] = 0
			wall_jump_direction = 1
	
	if current_frame_data[FrameDataType.COYOTE_WALL_JUMP] < coyote_jump_frames and current_frame_data[FrameDataType.INPUT_BUFFER] < input_buffer_frames and not is_on_floor():
		velocity.x = max_speed * wall_jump_horizontal_multiplier * -wall_jump_direction
		velocity.y = -initial_jump_velocity * wall_jump_vertical_multiplier
		current_frame_data[FrameDataType.COYOTE_WALL_JUMP] = coyote_jump_frames
		current_frame_data[FrameDataType.INPUT_BUFFER] = input_buffer_frames
		can_input = false
		wall_jump_cooldown_timer.start(float(wall_jump_input_lock_frames) / 60)
			
	
		
	
	
func handle_dash():
	if not can_input or not can_move:
		return
	if not Input.is_action_pressed("dash"):
		current_frame_data[FrameDataType.DASH_WIND_UP] = 0
		
	if is_on_floor() or is_on_wall():
		is_dashing = false
		
	if current_frame_data[FrameDataType.DASH_WIND_UP] >= dash_wind_up_frames:
		print("dashing")
		is_dashing = true
		current_frame_data[FrameDataType.DASH_WIND_UP] = 0
		var time := (2 * sqrt(2 * DIMENSIONS.y / acceleration_due_to_gravity))
		var distance := 6 * DIMENSIONS.x
		velocity.x = max_speed * 1.75 * last_direction
		velocity.y = -(distance - 1/2 * acceleration_due_to_gravity * time * time)/time
		
	
func handle_friction(delta : float):
	if current_horizontal_movement != 0.0 or velocity.x == 0 or not can_input or is_dashing:
		return
	
	var direction = velocity.abs().x / velocity.x
	var amount = deacceleration_speed * delta * direction
	if velocity.abs().x - absf(amount) > 0:
		velocity.x -= deacceleration_speed * delta * direction
	else:
		velocity.x = 0
		
func on_hit(body : Node2D):
	EventBus.player_death.emit()
	velocity = Vector2.ZERO
	
	
func on_wall_jump_complete():
	can_input = true
