extends Control

@onready var timer = $Timer
@export var shifting_text : Node
@export var ui : Node

var is_shifting := false

func _ready():
	visible = false
	EventBus.next_loop.connect(tower_shifting)
	timer.timeout.connect(tower_done_shifting)
	
func tower_shifting():
	visible = true
	is_shifting = true
	if ui.get_parent() == self:
		remove_child(ui)
	if shifting_text.get_parent() != self:
		add_child(shifting_text)
	timer.start(3.0)
	EventBus.disable_player.emit()
	
func tower_done_shifting():
	visible = false
	is_shifting = false
	EventBus.enable_player.emit()
	
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel") and not is_shifting:
		if shifting_text.get_parent() == self:
			remove_child(shifting_text)
		visible = not visible
		if ui.get_parent() != self:
			add_child(ui)
