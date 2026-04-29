class_name Player extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const ROLL_SPEED = 300.0
const CHARGE_SPEED = 700.0
const CHARGE_DURATION = 0.5
const CHARGE_MAX_TIME = 0.5
@onready var animated_sprite = $AnimatedSprite2D
@onready var roll_hitbox := $"RollHitbox"
var is_rolling = false
var is_charging = false
var charge_timer := 0.0
var charge_time_active := 0.0
var spawn_position: Vector2
var max_health = 4
var current_health = 4
var coin_count = 0
var is_hit := false
var hit_timer := 0.0
const HIT_DURATION = 0.6
var is_dead := false
var has_charge = false
signal health_changed(new_health)
signal coin_collected(new_count)
func _ready() -> void:
	spawn_position = global_position
	roll_hitbox.monitoring = true
func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	is_rolling = false
	is_charging = false
	charge_timer = 0.0
	charge_time_active = 0.0
	is_dead = false
	is_hit = false
	hit_timer = 0.0
	$CollisionShape2D.set_deferred("disabled", false)
func take_damage(amount: int, knockback_direction: float = 0.0) -> void:
	if is_hit or is_dead or is_rolling or is_charging:
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
	is_charging = false
	charge_timer = 0.0
	charge_time_active = 0.0
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
func unlock_charge() -> void:
	has_charge = true
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
		if not is_charging and charge_time_active <= 0:
			velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("ui_shift") and is_on_floor():
		is_rolling = true
	if Input.is_action_just_released("ui_shift"):
		is_rolling = false
	if Input.is_action_pressed("charge") and has_charge and not is_rolling and not is_charging:
		charge_timer += delta
		if charge_timer >= CHARGE_DURATION:
			is_charging = true
			charge_timer = 0.0
			velocity.y = -900.0
	if Input.is_action_just_released("charge") and not is_charging:
		charge_timer = 0.0
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
	elif is_charging:
		charge_time_active += delta
		var charge_dir = -1.0 if animated_sprite.flip_h else 1.0
		velocity.x = charge_dir * CHARGE_SPEED
		velocity.y = move_toward(velocity.y, 0, 300)
		if charge_time_active >= CHARGE_MAX_TIME:
			is_charging = false
			charge_time_active = 0.0
		elif charge_time_active > 0.1:
			if is_on_wall() or is_on_ceiling() or is_on_floor():
				is_charging = false
				charge_time_active = 0.0
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
		if animated_sprite.animation != "hit":
			animated_sprite.play("hit")
		return
	if charge_timer > 0 and not is_charging:
		if animated_sprite.animation != "charge_pickup":
			animated_sprite.play("charge_pickup")
		return
	if is_rolling:
		if animated_sprite.animation != "roll":
			animated_sprite.play("roll")
		return
	if is_charging:
		if animated_sprite.animation != "charge":
			animated_sprite.play("charge")
		return
	if not is_on_floor():
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif velocity.x != 0:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
