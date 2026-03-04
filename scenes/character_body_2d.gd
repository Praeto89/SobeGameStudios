extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ROLL_SPEED = 600.0

@onready var animated_sprite = $AnimatedSprite2D

var is_rolling = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Roll starten oder beenden
	if Input.is_action_just_pressed("ui_shift") and is_on_floor():
		is_rolling = true
	if Input.is_action_just_released("ui_shift"):
		is_rolling = false

	var direction := Input.get_axis("ui_left", "ui_right")

	if is_rolling:
		var roll_dir = -1.0 if animated_sprite.flip_h else 1.0
		velocity.x = roll_dir * ROLL_SPEED
	elif direction:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	_update_animation()

func _update_animation() -> void:
	if is_rolling:
		animated_sprite.play("roll")
		return

	if not is_on_floor():
		animated_sprite.play("jump")
	elif velocity.x != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
