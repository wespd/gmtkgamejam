extends Node2D

@export var player_respawn_location : Node2D
@export var player : Node2D

func _ready():
	EventBus.player_death.connect(respawn_player)
	
	
func respawn_player():
	player.position = player_respawn_location.position
