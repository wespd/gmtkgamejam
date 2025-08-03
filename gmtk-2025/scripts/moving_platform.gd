extends AnimatableBody2D
class_name MovingPlatform

var target_position : Vector2
var starting_position : Vector2

@export var total_frame_time : int = 90
@export var cooldown_frame_time : int = 30

var current_frame_time : int

var timer : Timer

var is_moving_up : bool = true
var is_frozen : bool = false


func _ready():
	starting_position = global_position
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(unfreeze_movement)
	EventBus.player_death.connect(reset_movement)
	for child in get_children():
		if child is Marker2D:
			target_position = child.global_position
				
func _physics_process(delta):
	if is_frozen:
		return
	if is_moving_up and current_frame_time >= total_frame_time:
		is_moving_up = false
		is_frozen = true
		timer.start(cooldown_frame_time / 60)
	elif not is_moving_up and current_frame_time <= 0:
		is_moving_up = true
		is_frozen = true
		timer.start(cooldown_frame_time / 60)
	current_frame_time += 1 if is_moving_up else -1
	global_position = lerp(starting_position, target_position, float(current_frame_time) / float(total_frame_time))
	
func unfreeze_movement():
	is_frozen = false
	
func reset_movement():
	if not is_inside_tree():
		return
	current_frame_time = 0
	is_moving_up = true
	is_frozen = true
	global_position = lerp(starting_position, target_position, float(current_frame_time) / float(total_frame_time))
	timer.start(cooldown_frame_time / 60)
