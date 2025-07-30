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
	COYOTE_JUMP, INPUT_BUFFER, DASH_WIND_UP, WALL_JUMP_LOCK
}

##constants for horizontal movement
var acceleration_speed : float
var deacceleration_speed : float

var initial_jump_velocity : float
var acceleration_due_to_gravity : float
var gravity_snap_multiplier : float

var current_frame_data : Array[int] = []

var current_horizontal_movement : float

var can_input : bool = true
var can_move : bool = true


func _ready():
	initialize_constants()
	initialize_frame_data()
	#connect to any relevent signals
	
	
func _physics_process(delta):
	increment_frame_data()
	handle_inputs()
	handle_jump(delta)
	handle_movement(delta)
	handle_friction(delta)
	

func initialize_constants():
	acceleration_speed = max_speed / acceleration_frames
	deacceleration_speed = max_speed / deacceleration_frames
	
	initial_jump_velocity = 2 * jump_hieght_relative_to_player_height * DIMENSIONS.y / jump_accent_frames
	acceleration_due_to_gravity = 2 * jump_hieght_relative_to_player_height * DIMENSIONS.y / pow(jump_accent_frames, 2)
	
	var decent_acel = 2 * jump_hieght_relative_to_player_height * DIMENSIONS.y / pow(jump_deccent_frames, 2)
	gravity_snap_multiplier = decent_acel / acceleration_due_to_gravity
	
func initialize_frame_data():
	for type in FrameDataType.keys():
		print("Initializing %s" %type)
		current_frame_data.append(0)
	current_frame_data[FrameDataType.INPUT_BUFFER] = input_buffer_frames
	current_frame_data[FrameDataType.COYOTE_JUMP] = coyote_jump_frames
	current_frame_data[FrameDataType.WALL_JUMP_LOCK] = wall_jump_input_lock_frames
	
func increment_frame_data():
	current_frame_data[FrameDataType.INPUT_BUFFER] += 1
	current_frame_data[FrameDataType.COYOTE_JUMP] += 1
	current_frame_data[FrameDataType.WALL_JUMP_LOCK] += 1
	
func handle_inputs():
	if not can_input:
		current_horizontal_movement = 0
		return
	current_horizontal_movement = Input.get_axis("move_left", "move_right")
	if Input.is_action_just_pressed("jump"):
		current_frame_data[FrameDataType.INPUT_BUFFER] = 0
	
	
	
func handle_jump(delta : float):
	if is_on_floor():
		current_frame_data[FrameDataType.COYOTE_JUMP] = 0
	if not can_move:
		return
		
	velocity.y += acceleration_due_to_gravity * delta * 1 if velocity.y < 0 else gravity_snap_multiplier
	
	if not can_input:
		return
		
	if current_frame_data[FrameDataType.COYOTE_JUMP] < coyote_jump_frames and current_frame_data[FrameDataType.INPUT_BUFFER]  < input_buffer_frames:
		velocity.y -= initial_jump_velocity
		
	
func handle_movement(delta : float):
	pass
	
func handle_friction(delta : float):
	pass
