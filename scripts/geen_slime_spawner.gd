extends Node2D

@export var slime_scene: PackedScene
@export var spawn_interval := 2.0
@export var max_slimes := 50

@onready var timer := $Timer

func _ready() -> void:
	print("Spawner bereit")
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	print("Timer feuert, aktuelle Slimes: ", get_tree().get_nodes_in_group("enemy").size())
	if slime_scene == null:
		print("slime_scene ist null!")
		return
	var current_slimes = get_tree().get_nodes_in_group("enemy").size()
	if current_slimes >= max_slimes:
		print("Max Slimes erreicht")
		return
	var slime = slime_scene.instantiate()
	slime.global_position = global_position
	get_parent().add_child(slime)
	print("Slime gespawnt")
