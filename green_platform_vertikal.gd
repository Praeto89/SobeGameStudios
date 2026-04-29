extends Node2D

@export var speed := 100.0
@export var distance := 30.0

var start_y := 0.0
var direction := 1

func _ready():
	start_y = position.y

func _process(delta):
	position.y += speed * direction * delta

	if abs(position.y - start_y) > distance:
		direction *= -1
