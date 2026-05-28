# =============================================================================
# wall_slime.gd
# =============================================================================
# KI-Skript fuer den Wand-Slime (CharacterBody2D).
#
# Verhalt sich weitgehend identisch zum gruenen Boden-Slime (green_slime.gd),
# aber ist speziell fuer Waende ausgelegt:
#
#   - gravity = 0.0          -> der Slime faellt nicht herunter
#   - speed = 20.0           -> langsamer als der Boden-Slime
#   - detection_range = 0.0  -> erkennt den Spieler nicht, laeuft also immer nur Patrouille
#
# Diese Werte sind per @export im Editor anpassbar.
# =============================================================================

extends CharacterBody2D

# -----------------------------------------------------------------------------
# Export-Variablen (im Godot-Editor einstellbar)
# -----------------------------------------------------------------------------
@export var speed := 20.0               # Bewegungsgeschwindigkeit in Pixel/Sekunde (langsam)
@export var gravity := 0.0              # Keine Schwerkraft – Slime bleibt an der Wand
@export var detection_range := 0.0      # Erkennungsreichweite (0 = kein aktives Verfolgen)

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var sprite := $AnimatedSprite2D
@onready var hitbox := $Hitbox          # Area2D die Schaden an den Spieler gibt

# -----------------------------------------------------------------------------
# Zustandsvariablen
# -----------------------------------------------------------------------------
var player: Node2D = null               # Referenz auf den Spieler (nur fuer Aktivierungs-Logik)
var patrol_direction := 1.0             # Aktuelle Laufrichtung: 1.0 = rechts, -1.0 = links
var wall_cooldown := 0.0                # Wartezeit nach Wandkontakt (verhindert Flackern)
var activated := false                  # True sobald die Aktivierungsanimation abgespielt wurde
var is_activating := false              # True waehrend die Aktivierungs-Animation laeuft (verhindert Mehrfach-Start)
var is_dead := false                    # True waehrend und nach der Todesanimation

# Persistenz: vom Spawner gesetzt; gespawnte Slimes werden nicht persistiert.
var is_spawned: bool = false
var _persistent_id: String = ""

# =============================================================================
# _ready()
# Wird einmalig beim Start aufgerufen.
# Fuegt den Slime zur Gruppe "enemy" hinzu,
# holt die Spieler-Referenz und verbindet das Hitbox-Signal.
# =============================================================================
func _ready():
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	# Persistenz: nur fest platzierte Slimes auf "schon besiegt" pruefen.
	if not is_spawned:
		_persistent_id = GameManager.get_persistent_id(self)
		if _persistent_id != "" and _persistent_id in GameManager.defeated_enemy_ids:
			queue_free()

# =============================================================================
# _on_hitbox_body_entered(body)
# Wird aufgerufen wenn ein Koerper die Hitbox beruehrt.
# Verursacht 1 Schadenspunkt mit Rueckstoss Richtung weg vom Slime.
# =============================================================================
func _on_hitbox_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		var knockback_dir = sign(body.global_position.x - global_position.x)
		body.take_damage(1, knockback_dir)

# =============================================================================
# die()
# Wird vom Spieler ausgeloest (Roll oder Charge trifft den Slime).
# Deaktiviert Kollision und Hitbox, spielt Todesanimation, entfernt sich.
# =============================================================================
func die() -> void:
	if is_dead:
		return
	is_dead = true
	# Persistierten Slime als besiegt markieren
	if _persistent_id != "" and not _persistent_id in GameManager.defeated_enemy_ids:
		GameManager.defeated_enemy_ids.append(_persistent_id)
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.monitoring = false
	sprite.play("death")
	await sprite.animation_finished
	queue_free()

# =============================================================================
# _physics_process(delta)
# Hauptschleife – laeuft jeden Physik-Frame.
# Da gravity = 0, bleibt der Slime an seiner Position auf der Wand.
# =============================================================================
func _physics_process(delta):
	# --- Tot: Schwerkraft anwenden (gravity ist 0, also passiert nichts) ---
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if wall_cooldown > 0:
		wall_cooldown -= delta

	# Aktivierung laeuft: warten bis Animation fertig ist
	# (await gibt _state_activation sofort zurueck, deshalb dieser Guard)
	if is_activating:
		move_and_slide()
		return

	# Da detection_range = 0, ist player_near immer false -> nur Patrouille
	var player_near = player and is_instance_valid(player) and global_position.distance_to(player.global_position) < detection_range
	if player_near and not activated:
		_state_activation()
	else:
		_state_patrol()

	move_and_slide()

# =============================================================================
# _state_activation()
# Einmalige Reaktion wenn Spieler nah ist (bei detection_range > 0).
# =============================================================================
func _state_activation():
	is_activating = true
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed
	sprite.flip_h = direction < 0
	sprite.play("activation")
	await sprite.animation_finished
	activated = true
	is_activating = false

# =============================================================================
# _state_patrol()
# Slime laeuft in patrol_direction und dreht um wenn er auf eine Wand trifft.
# =============================================================================
func _state_patrol():
	velocity.x = patrol_direction * speed
	sprite.flip_h = patrol_direction < 0
	sprite.play("patrol")
	if is_on_wall() and wall_cooldown <= 0:
		patrol_direction *= -1
		wall_cooldown = 0.3
