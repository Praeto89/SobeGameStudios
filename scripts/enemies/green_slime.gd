# =============================================================================
# green_slime.gd
# =============================================================================
# KI-Skript fuer den gruenen Boden-Slime (CharacterBody2D).
#
# Verhalten:
#   - Patrouille:    Laeuft hin und her, dreht um wenn er gegen eine Wand stoesst
#   - Erkennung:     Erkennt den Spieler innerhalb von "detection_range" Pixeln
#   - Aktivierung:   Spielt einmalig die Aktivierungs-Animation wenn Spieler nah ist
#   - Tod:           Deaktiviert Kollision, spielt Todesanimation, entfernt sich
#
# Wird vom Spieler getoedet durch: Roll oder Charge-Ability
#
# Schwierigkeit: [FORTGESCHRITTEN] – Zustandsautomat (State Machine) + await.
#
# 📝 AUFGABE (A3, Stufe 5): Gib dem Slime einen "Flucht"-Zustand, wenn der
#    Spieler sehr nah ist (laeuft weg statt hin). Loesung: AUFGABEN.md -> A3
# =============================================================================

extends CharacterBody2D

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  DEIN SPIELFELD – diese Werte kannst du im Godot-Editor tunen,          ║
# ║  ohne eine einzige Zeile Code anzufassen:                               ║
# ║  Slime im Level anklicken → rechts im Inspector scrollen.               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# -----------------------------------------------------------------------------
# Export-Variablen (im Godot-Editor einstellbar)
# -----------------------------------------------------------------------------
@export var speed := 80.0               # Laufgeschwindigkeit  <- probier: 200 (hektisch) oder 20 (schleichend)
@export var gravity := 800.0            # Schwerkraft  <- 0 = schwebt, 2000 = faellt sehr schnell
@export var detection_range := 200.0    # Erkennungsreichweite in Pixeln  <- 0 = blind, 500 = scharfaeuging

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var sprite := $AnimatedSprite2D
@onready var hitbox := $Hitbox          # Area2D die Schaden an den Spieler gibt

# -----------------------------------------------------------------------------
# Zustandsvariablen
# -----------------------------------------------------------------------------
var player: Node2D = null               # Referenz auf den Spieler (wird in _ready() geholt)
var patrol_direction := 1.0             # Aktuelle Laufrichtung: 1.0 = rechts, -1.0 = links
var wall_cooldown := 0.0                # Wartezeit nach Wandkontakt (verhindert Flackern)
var activated := false                  # True sobald die Aktivierungsanimation einmal abgespielt wurde
var is_activating := false              # True waehrend die Aktivierungs-Animation laeuft (verhindert Mehrfach-Start)
var is_dead := false                    # True waehrend und nach der Todesanimation

# Persistenz-Flags
# Vom Spawner gesetzt, BEVOR der Slime dem Baum hinzugefuegt wird.
# Gespawnte Slimes sollen nicht persistiert werden -- sonst gibt es nach
# erstem Tod keine neuen Spawns mehr.
var is_spawned: bool = false
var _persistent_id: String = ""

# =============================================================================
# _ready()
# Wird einmalig beim Start aufgerufen.
# Fuegt den Slime zur Gruppe "enemy" hinzu (damit Spieler-Roll ihn treffen kann),
# holt sich die Spieler-Referenz und verbindet das Hitbox-Signal.
# =============================================================================
func _ready():
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	# Persistenz: nur fest platzierte Slimes (nicht vom Spawner) checken,
	# ob sie schon mal besiegt wurden.
	if not is_spawned:
		_persistent_id = GameManager.get_persistent_id(self)
		if _persistent_id != "" and _persistent_id in GameManager.defeated_enemy_ids:
			queue_free()

# =============================================================================
# _on_hitbox_body_entered(body)
# Wird aufgerufen wenn ein Koerper die Hitbox des Slimes beruehrt.
# Wenn dieser Koerper die Methode "take_damage" hat (also der Spieler ist),
# wird 1 Schadenspunkt mit Rueckstoss verursacht.
# =============================================================================
func _on_hitbox_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		# Rueckstoss-Richtung: weg vom Slime (positiv = rechts, negativ = links)
		var knockback_dir = sign(body.global_position.x - global_position.x)
		body.take_damage(1, knockback_dir)

# =============================================================================
# die()
# Wird aufgerufen wenn der Spieler den Slime per Roll oder Charge trifft.
# Deaktiviert Kollision und Hitbox sofort, spielt Todesanimation ab
# und entfernt den Slime dann aus der Szene.
# =============================================================================
func die() -> void:
	if is_dead:
		return
	is_dead = true
	# Persistierten Slime als besiegt markieren (taucht beim Re-Entry nicht mehr auf)
	if _persistent_id != "" and not _persistent_id in GameManager.defeated_enemy_ids:
		GameManager.defeated_enemy_ids.append(_persistent_id)
	# WARUM set_deferred?
	# Diese Funktion wird aus einem Kollisions-Callback heraus aufgerufen
	# (der Spieler trifft den Slime). Mitten in einem Physik-Frame darf
	# man Kollisions-Shapes nicht direkt aendern – daher set_deferred,
	# das die Aenderung auf nach dem Frame verschiebt.
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.monitoring = false
	sprite.play("death")
	# WARUM await?
	# await haelt diese Funktion an, bis die Animation fertig ist,
	# ohne das ganze Spiel zu blockieren. Godot fuehrt in der Zwischenzeit
	# alle anderen Frames normal weiter – das ist eine sog. Coroutine.
	await sprite.animation_finished
	queue_free()

# =============================================================================
# _physics_process(delta)
# Hauptschleife – laeuft jeden Physik-Frame.
#
# Ablauf:
#   1. Wenn tot: nur Schwerkraft anwenden und nichts tun
#   2. Schwerkraft anwenden wenn nicht am Boden
#   3. Wand-Cooldown herunterzaehlen
#   4. Spieler-Naehe pruefen -> Aktivierung oder Patrouille
# =============================================================================
func _physics_process(delta):
	# --- 1. Tod: nur fallen lassen ---
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return

	# --- 2. Schwerkraft ---
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- 3. Wand-Cooldown ---
	if wall_cooldown > 0:
		wall_cooldown -= delta

	# --- 4. Aktivierung laeuft noch: warten bis Animation fertig ist ---
	# Ohne diesen Check wuerde _state_activation in jedem Frame erneut
	# gestartet werden, weil await die Funktion sofort zurueckgibt.
	if is_activating:
		move_and_slide()
		return

	# --- 5. Spieler-Naehe pruefen ---
	var player_near = player and is_instance_valid(player) and global_position.distance_to(player.global_position) < detection_range
	if player_near and not activated:
		_state_activation()
	else:
		_state_patrol()

	move_and_slide()

# =============================================================================
# _state_activation()
# Einmaliger Uebergang-Zustand: Slime dreht sich zum Spieler und spielt
# die Aktivierungs-Animation. Danach ist "activated = true" und der Slime
# laeuft normal weiter.
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
# Normales Patrouillier-Verhalten: Slime laeuft in patrol_direction.
# Wenn er gegen eine Wand laeuft (und der Cooldown abgelaufen ist),
# dreht er die Richtung um.
# =============================================================================
func _state_patrol():
	velocity.x = patrol_direction * speed
	sprite.flip_h = patrol_direction < 0
	sprite.play("patrol")
	if is_on_wall() and wall_cooldown <= 0:
		patrol_direction *= -1      # Richtung umkehren
		wall_cooldown = 0.3         # Kurze Pause damit der Slime nicht sofort wieder dreht
