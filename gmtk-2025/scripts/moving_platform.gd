extends AnimatableBody2D

var target_position : Vector2
var starting_position : Vector2

@export var total_frame_time : int = 90
@export var cooldown_frame_time : int = 30

@onready var timer = $Timer

var distance : float
var velocity : float

var is_moving_up : bool = true
var is_frozen : bool = false


func _ready():
	starting_position = global_position
	timer.timeout.connect(unfreeze_movement)
	for child in get_children():
		if child is Marker2D:
			target_position = child.global_position
				
	distance =  target_position.y
	velocity = distance / (float(total_frame_time) / 60)
				
func _physics_process(delta):
	if is_frozen:
		return
	if is_moving_up and global_position.y <= target_position.y:
		is_moving_up = false
		print("starting to move down")
		is_frozen = true
		timer.start(cooldown_frame_time / 60)
	elif not is_moving_up and global_position.y >= starting_position.y:
		print("starting to move up")
		is_moving_up = true
		is_frozen = true
		timer.start(cooldown_frame_time / 60)

	global_position.y += velocity * delta * (1 if is_moving_up else -1)
	
func unfreeze_movement():
	is_frozen = false
