extends Node2D

@export var speed := 50.0
@export var distance := 45.0

var start_x := 0.0
var direction := 1

func _ready():
	start_x = position.x

func _process(delta):
	position.x += speed * direction * delta

	if abs(position.x - start_x) > distance:
		direction *= -1
