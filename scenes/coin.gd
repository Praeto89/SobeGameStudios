extends Area2D

func _ready() -> void:
	$AnimatedSprite2D.play("spin")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		# Punkte vergeben, Sound abspielen, etc.
		queue_free()  # Coin verschwindet
