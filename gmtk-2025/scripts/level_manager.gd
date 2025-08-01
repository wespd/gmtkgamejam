@tool
extends Node

const LEVELS : Array[PackedScene] = [preload("res://scenes/game.tscn"), preload("res://scenes/Levels.tscn")]

var current_level_object : Node2D

var current_level : int = 0
var current_loop : int = 0

var layers : Array[LoopTileMapLayer] = []
var spawn_locations : Array[SpawnMarker] = []

var player_respawn_location : Vector2
var player : Node2D

func respawn_player():
	player.position = player_respawn_location


func _ready():
	EventBus.next_level.connect(on_next_level)
	EventBus.next_loop.connect(on_next_loop)
	EventBus.player_death.connect(respawn_player)
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
	for i in layers.size():
		if i != current_loop:
			layers[i].collision_enabled = false
			layers[i].enabled = false
		else:
			layers[i].collision_enabled = true
			layers[i].enabled = true
	EventBus.player_death.emit()
