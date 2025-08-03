extends Node2D

func _process(delta):
	if Input.is_action_just_pressed("reset_game"):
		EventBus.restart_game.emit()
		get_tree().reload_current_scene()
