extends CharacterBody2D

@export var speed := 20.0
@export var gravity := 0.0
@export var detection_range := 0.0
@onready var sprite := $AnimatedSprite2D
@onready var hitbox := $Hitbox

var player: Node2D = null
var patrol_direction := 1.0
var wall_cooldown := 0.0
var activated := false
var is_dead := false

func _ready():
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		var knockback_dir = sign(body.global_position.x - global_position.x)
		body.take_damage(1, knockback_dir)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.monitoring = false
	sprite.play("death")
	await sprite.animation_finished
	queue_free()

func _physics_process(delta):
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	if wall_cooldown > 0:
		wall_cooldown -= delta
	var player_near = player and global_position.distance_to(player.global_position) < detection_range
	if player_near and not activated:
		_state_activation()
	else:
		_state_patrol()
	move_and_slide()

func _state_activation():
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed
	sprite.flip_h = direction < 0
	sprite.play("activation")
	await sprite.animation_finished
	activated = true

func _state_patrol():
	velocity.x = patrol_direction * speed
	sprite.flip_h = patrol_direction < 0
	sprite.play("patrol")
	if is_on_wall() and wall_cooldown <= 0:
		patrol_direction *= -1
		wall_cooldown = 0.3
