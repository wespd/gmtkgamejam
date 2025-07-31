extends Node2D

@export var player_respawn_location : Node2D
@export var player : Node2D

func _ready():
	EventBus.player_death.connect(respawn_player)
	EventBus.next_level.connect(func(): print("next level??"))
	
	
func respawn_player():
	player.position = player_respawn_location.position
