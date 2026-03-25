extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ROLL_SPEED = 600.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var roll_hitbox := $"RollHitbox"
var is_rolling = false
var spawn_position: Vector2

var max_health = 4
var current_health = 4
var coin_count = 0

var is_hit := false
var hit_timer := 0.0
const HIT_DURATION = 0.6

var is_dead := false

signal health_changed(new_health)
signal coin_collected(new_count)

func _ready() -> void:
	spawn_position = global_position
	roll_hitbox.monitoring = true

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	is_rolling = false
	is_dead = false
	is_hit = false
	hit_timer = 0.0
	$CollisionShape2D.set_deferred("disabled", false)

func take_damage(amount: int, knockback_direction: float = 0.0) -> void:
	if is_hit or is_dead or is_rolling:
		return
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	emit_signal("health_changed", current_health)
	velocity.x = knockback_direction * 400.0
	velocity.y = -200.0
	if current_health <= 0:
		_die()
		return
	is_hit = true
	hit_timer = HIT_DURATION

func _die() -> void:
	is_dead = true
	is_rolling = false
	velocity.x = 0
	$CollisionShape2D.set_deferred("disabled", true)
	Engine.time_scale = 0.5
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	Engine.time_scale = 1.0
	respawn()
	current_health = max_health
	emit_signal("health_changed", current_health)

func collect_coin() -> void:
	coin_count += 1
	emit_signal("coin_collected", coin_count)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity += get_gravity() * delta
		move_and_slide()
		return
	if hit_timer > 0:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit = false
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("ui_shift") and is_on_floor():
		is_rolling = true
	if Input.is_action_just_released("ui_shift"):
		is_rolling = false
	var direction := Input.get_axis("ui_left", "ui_right")
	if is_rolling:
		var roll_dir = -1.0 if animated_sprite.flip_h else 1.0
		velocity.x = roll_dir * ROLL_SPEED
		for body in roll_hitbox.get_overlapping_bodies():
			if body == self:
				continue
			if body.is_in_group("enemy"):
				body.die()
			elif body.get_parent().is_in_group("enemy"):
				body.get_parent().die()
	elif direction:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	_update_animation()

func _update_animation() -> void:
	if is_dead:
		return
	if is_hit:
		animated_sprite.play("hit")
		return
	if is_rolling:
		animated_sprite.play("roll")
		return
	if not is_on_floor():
		animated_sprite.play("jump")
	elif velocity.x != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
