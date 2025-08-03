extends Control
class_name UIOverlay

static var time : float
static var player_deaths : int = 0
var is_running = true

@onready var time_label = $TimeLabel
@onready var death_label = $DeathLabel
@export var final_time_node : RichTextLabel

func _ready():
	EventBus.disable_player.connect(func(): is_running = false)
	EventBus.game_over.connect(
		func(): 
			is_running = false
			final_time_node.text = "Final Time: %0.2f" %time)
	EventBus.enable_player.connect(func(): is_running = true)
	EventBus.restart_game.connect(
		func():
			player_deaths = 0
			time = 0.0
	)

func _process(delta):
	if is_running:
		time += delta
		time_label.text = "Time: %0.2f" %time
	death_label.text = "Deaths: %s" %player_deaths
