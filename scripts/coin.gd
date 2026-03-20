extends Area2D

@onready var audio := $AudioStreamPlayer2D

func _ready() -> void:
	$AnimatedSprite2D.play("spin")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		body.collect_coin()
		audio.play()
		await get_tree().create_timer(audio.stream.get_length()).timeout
		queue_free()
