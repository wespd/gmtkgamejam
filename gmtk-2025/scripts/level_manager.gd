extends Node

const LEVELS : Array[PackedScene] = [preload("res://scenes/game.tscn"), preload("res://scenes/Levels.tscn")]

var current_level_object : Node2D

var current_level : int = 0
var current_loop : int = 0

var layers : Array[LoopTileMapLayer] = []
var spawn_locations : Array[SpawnMarker] = []

var player_respawn_location : Vector2
var player : Node2D
var final_location : Vector2

func respawn_player():
	player.position = player_respawn_location
	if not final_location:
		final_location = get_tree().current_scene.get_child(get_tree().current_scene.get_child_count(true) - 1).position


func restart():
	await get_tree().process_frame
	current_level = 0
	current_loop = 0
	layers.clear()
	spawn_locations.clear()
	for child in get_tree().current_scene.get_children(true):
			if child is LoopTileMapLayer:
				layers.append(child)
	for child in get_tree().current_scene.get_children(true):
		if child is SpawnMarker:
			spawn_locations.append(child)
	player_respawn_location = spawn_locations[current_level].position
	load_level()

func _ready():
	EventBus.next_level.connect(on_next_level)
	EventBus.next_loop.connect(on_next_loop)
	EventBus.player_death.connect(respawn_player)
	EventBus.restart_game.connect(restart)
	for child in get_tree().current_scene.get_children(true):
		if child is LoopTileMapLayer:
			layers.append(child)
	for child in get_tree().current_scene.get_children(true):
		if child is SpawnMarker:
			spawn_locations.append(child)
	player_respawn_location = spawn_locations[current_level].position
	call_deferred("load_level")
func on_next_level():
	current_level += 1
	if current_level >= spawn_locations.size():
		print(current_level)
		EventBus.next_loop.emit()
		return
	load_level()
	
func on_next_loop():
	current_level = 0
	current_loop += 1
	load_level()
	
func load_level():
	player_respawn_location = spawn_locations[current_level].position
	if current_loop == 4:
		player_respawn_location = final_location
		EventBus.player_death.emit()
		EventBus.game_over.emit()
		return

	for i in layers.size():
		if i != current_loop:
			layers[i].collision_enabled = false
			layers[i].enabled = false
		else:
			layers[i].collision_enabled = true
			layers[i].enabled = true
	EventBus.player_death.emit()
