extends AnimatableBody2D

var pos1 : Marker2D
var pos2 : Marker2D

@export var speed_up_frames : int = 10
@export var total_frame_time : int = 90
@export var cooldown_frame_time : int = 30

var max_velocity : float
var distance : float

func _ready():
	for child in get_children():
		if child is Marker2D:
			if not pos1:
				pos1 = child
			else:
				pos2 = child
				
	
				
func _physics_process(delta):
	pass
