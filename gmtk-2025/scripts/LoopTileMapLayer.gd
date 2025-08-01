extends TileMapLayer
class_name LoopTileMapLayer

@export var is_testing_this_level := false
@export var desired_level : int

func _ready():
	if is_testing_this_level:
		set_current_loop_to_this()
func set_current_loop_to_this():
	var loop_index = -1
	for i in LevelManager.layers.size():
		if LevelManager.layers[i] == self:
			loop_index = i
	
	for i in loop_index:
		call_deferred("emit_next_loop")
		print("next_loop")
	for i in desired_level:
		call_deferred("emit_next_level")
			

func emit_next_loop():
	EventBus.next_loop.emit()
	
func emit_next_level():
	EventBus.next_level.emit()
