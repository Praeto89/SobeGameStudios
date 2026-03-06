extends CharacterBody2D

@export var speed := 80.0
@export var gravity := 800.0
@export var detection_range := 200.0

@onready var sprite := $AnimatedSprite2D

var player: Node2D = null
var patrol_direction := 1.0
var wall_cooldown := 0.0

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if wall_cooldown > 0:
		wall_cooldown -= delta

	var player_near = player and global_position.distance_to(player.global_position) < detection_range

	if player_near:
		_state_activation()
	else:
		_state_patrol()

	move_and_slide()

func _state_activation():
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed
	sprite.flip_h = direction < 0
	sprite.play("activation")

func _state_patrol():
	velocity.x = patrol_direction * speed
	sprite.flip_h = patrol_direction < 0
	sprite.play("patrol")

	if is_on_wall() and wall_cooldown <= 0:
		patrol_direction *= -1
		wall_cooldown = 0.3
