extends Node2D
class_name LoopObject

var children : Array[Node] = []
@export var loop_to_spawn : int = 0
@export var loop_to_despawn : int = 10

func _ready():
	children = get_children()
	if loop_to_spawn > 0:
		for child in children:
			remove_child(child)
	EventBus.next_loop.connect(on_new_loop)
	
	

func on_new_loop():
	if LevelManager.current_loop >= loop_to_spawn and LevelManager.current_loop < loop_to_despawn and loop_to_spawn > 0:
		for child in children:
			add_child(child)
	if LevelManager.current_loop >= loop_to_despawn:
		for child in children:
			remove_child(child)
