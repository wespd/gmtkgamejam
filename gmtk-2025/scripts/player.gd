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

##constants for horizontal movement
var acceleration_speed : float
var deacceleration_speed : float

var initial_jump_velocity : float
var acceleration_due_to_gravity : float
var gravity_snap_multiplier : float

var current_frame_data : Array[int] = []



func _ready():
	#initialize_constants()
	#initialize_frame_data()
	#connect to any relevent signals
	pass
	
	
func _physics_process(delta):
	#handle_inputs
	#handle_jump
	#handle_movement
	#handle_friction
	pass
	

func initialize_constants():
	acceleration_speed = max_speed / acceleration_frames
	deacceleration_speed = max_speed / deacceleration_frames
	
	initial_jump_velocity = 2 * jump_hieght_relative_to_player_height * DIMENSIONS.y / jump_accent_frames
	acceleration_due_to_gravity = 2 * jump_hieght_relative_to_player_height * DIMENSIONS.y / pow(jump_accent_frames, 2)
	
	var decent_acel = 2 * jump_hieght_relative_to_player_height * DIMENSIONS.y / pow(jump_deccent_frames, 2)
	gravity_snap_multiplier = decent_acel / acceleration_due_to_gravity
	
func initialize_frame_data():
	pass
	
func handle_inputs():
	pass
	
func handle_jump():
	pass
	
func handle_movement():
	pass
	
func handle_friction():
	pass
