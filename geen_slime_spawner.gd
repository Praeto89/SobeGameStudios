extends Node2D

@export var slime_scene: PackedScene
@export var spawn_interval := 2.0
@export var max_slimes := 5

@onready var timer := $Timer

func _ready() -> void:
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	var current_slimes = get_tree().get_nodes_in_group("enemy").size()
	if current_slimes >= max_slimes:
		return
	var slime = slime_scene.instantiate()
	slime.global_position = global_position
	get_parent().add_child(slime)
