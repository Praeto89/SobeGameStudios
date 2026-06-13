# =============================================================================
# slime_base.gd
# =============================================================================
# Gemeinsame Basis-Klasse fuer ALLE Slime-Gegner (CharacterBody2D).
#
# Hier lebt das komplette Slime-Verhalten EINMAL an einem Ort:
#   - Patrouille:    Laeuft hin und her, dreht um wenn er gegen eine Wand stoesst
#   - Erkennung:     Erkennt den Spieler innerhalb von "detection_range" Pixeln
#   - Aktivierung:   Spielt einmalig die Aktivierungs-Animation wenn Spieler nah ist
#   - Tod:           Deaktiviert Kollision, spielt Todesanimation, entfernt sich
#   - Persistenz:    Besiegte (fest platzierte) Slimes bleiben besiegt
#
# Die konkreten Slimes (green_slime, wall_slime, purple_slime_wall) ERBEN von
# dieser Klasse und stellen nur noch ihre Unterschiede ein:
#   - andere Werte fuer speed/gravity/detection_range (im Editor pro Szene)
#   - ein anderes Spritesheet
#   - optional: einen zusaetzlichen Zustand (siehe _handle_extra_state)
#
# WARUM eine Basis-Klasse?
#   Frueher war dieser Code in jedem Slime-Skript kopiert. Aenderte man das
#   Verhalten, musste man es an mehreren Stellen nachziehen – fehleranfaellig.
#   Jetzt gilt: ein Bug hier gefixt = in allen Slimes gefixt.
#
# Schwierigkeit: [FORTGESCHRITTEN] – Zustandsautomat (State Machine) + await.
# =============================================================================

class_name SlimeBase
extends CharacterBody2D

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  DEIN SPIELFELD – diese Werte kannst du im Godot-Editor tunen,          ║
# ║  ohne eine einzige Zeile Code anzufassen:                               ║
# ║  Slime im Level anklicken → rechts im Inspector scrollen.               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# -----------------------------------------------------------------------------
# Export-Variablen (im Godot-Editor pro Szene/Instanz einstellbar)
# -----------------------------------------------------------------------------
@export var speed := 80.0               # Laufgeschwindigkeit  <- probier: 200 (hektisch) oder 20 (schleichend)
@export var gravity := 800.0            # Schwerkraft  <- 0 = schwebt (Wand-Slime), 2000 = faellt sehr schnell
@export var detection_range := 200.0    # Erkennungsreichweite in Pixeln  <- 0 = blind, 500 = scharfaeuging
@export var gold_drop := 1               # Wie viel Gold (Muenzen) beim Tod abfaellt  <- 0 = nichts, staerkere Gegner mehr

# --- Jagd & Sprung (das macht den Slime "schlau") -----------------------------
@export var chase_player := true        # Jagt der Slime den Spieler aktiv?  <- false = nur stures Patrouillieren
@export var chase_speed := 130.0        # Tempo beim Jagen (meist schneller als speed)  <- 60 = gemuetlich, 250 = Panik
@export var can_jump := true            # Darf der Slime springen?  <- false = bleibt am Boden kleben
@export var jump_strength := 320.0      # Wie hoch der Sprung geht  <- 150 = Huepfer, 600 = Riesensatz
@export var jump_interval := 1.0        # Sekunden zwischen zwei Spruengen beim Jagen  <- 0.4 = Dauerhuepfen

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
var jump_cooldown := 0.0                # Wartezeit bis zum naechsten Sprung (zaehlt herunter)
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
# Fuegt den Slime zur Gruppe "enemy" hinzu (damit Spieler-Roll/Attacke ihn
# treffen kann), holt sich die Spieler-Referenz und verbindet das Hitbox-Signal.
# =============================================================================
func _ready():
	add_to_group(GameConstants.GROUP_ENEMY)
	player = get_tree().get_first_node_in_group(GameConstants.GROUP_PLAYER)
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
# Wird aufgerufen wenn der Spieler den Slime per Roll, Attacke oder Charge trifft.
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
	# Jeder Gegner hinterlaesst beim Ableben Gold (Muenzen) zum Aufsammeln.
	_spawn_gold(gold_drop)
	# WARUM set_deferred?
	# Diese Funktion wird aus einem Kollisions-Callback heraus aufgerufen
	# (der Spieler trifft den Slime). Mitten in einem Physik-Frame darf
	# man Kollisions-Shapes nicht direkt aendern – daher set_deferred,
	# das die Aenderung auf nach dem Frame verschiebt.
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.monitoring = false
	if has_node("SoundDeath"):
		$SoundDeath.play()
	# Effekt: kurz hell aufleuchten ("Treffer-Blitz"), dann erst sterben.
	# modulate-Werte > 1 leuchten dank Glow-Environment richtig auf. Rein
	# optisch – laeuft parallel zur Todesanimation ab.
	sprite.modulate = Color(3.0, 3.0, 3.0)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.18)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		# WARUM await?
		# await haelt diese Funktion an, bis die Animation fertig ist,
		# ohne das ganze Spiel zu blockieren. Godot fuehrt in der Zwischenzeit
		# alle anderen Frames normal weiter – das ist eine sog. Coroutine.
		await sprite.animation_finished
	queue_free()

# =============================================================================
# _spawn_gold(count)
# Instanziiert count Muenzen ("Gold") als Kinder des Eltern-Knotens (des Levels)
# und verteilt sie zufaellig um die aktuelle Position. Als Kinder des Levels
# (nicht des Gegners) bleiben sie sammelbar, obwohl der Gegner gleich per
# queue_free() verschwindet. Gleiche Idee wie bei Truhe und Mimik.
# =============================================================================
func _spawn_gold(count: int) -> void:
	if count <= 0:
		return
	var parent := get_parent()
	if parent == null:
		return
	var coin_scene := load("res://scenes/pickups/coin.tscn")
	for i in count:
		var c = coin_scene.instantiate()
		var angle := randf() * TAU
		var dist := randf_range(10.0, 26.0)
		c.global_position = global_position + Vector2(cos(angle) * dist, sin(angle) * dist - 14.0)
		parent.add_child(c)

# =============================================================================
# _physics_process(delta)
# Hauptschleife – laeuft jeden Physik-Frame.
#
# Ablauf:
#   1. Wenn tot: nur Schwerkraft anwenden und nichts tun
#   2. Schwerkraft anwenden wenn nicht am Boden
#   3. Wand-Cooldown herunterzaehlen
#   4. Aktivierung laeuft noch? -> warten
#   5. Zusatz-Zustand (z. B. Flucht) fragen -> ggf. uebernimmt der
#   6. Spieler-Naehe pruefen -> Aktivierung oder Patrouille
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

	# --- 3. Cooldowns (Wand & Sprung) herunterzaehlen ---
	if wall_cooldown > 0:
		wall_cooldown -= delta
	if jump_cooldown > 0:
		jump_cooldown -= delta

	# --- 4. Aktivierung laeuft noch: warten bis Animation fertig ist ---
	# Ohne diesen Check wuerde _state_activation in jedem Frame erneut
	# gestartet werden, weil await die Funktion sofort zurueckgibt.
	if is_activating:
		move_and_slide()
		return

	# --- 5. Zusatz-Zustand (von Unterklassen ueberschreibbar, siehe unten) ---
	# Gibt true zurueck wenn der Zusatz-Zustand die Bewegung uebernommen hat.
	if _handle_extra_state(delta):
		move_and_slide()
		return

	# --- 6. Spieler-Naehe pruefen und passenden Zustand waehlen ---
	var player_near = player and is_instance_valid(player) and global_position.distance_to(player.global_position) < detection_range
	if player_near and not activated:
		_state_activation()         # Spieler zum ersten Mal entdeckt -> aufwachen
	elif player_near and chase_player:
		_state_chase(delta)         # Spieler in Reichweite -> jagen (und springen)
	else:
		_state_patrol()             # niemand in der Naehe -> stur hin und her laufen

	move_and_slide()

# =============================================================================
# _handle_extra_state(delta) -> bool
# "Haken" (engl. hook) fuer Unterklassen: hier koennen einzelne Slimes einen
# EIGENEN Zustand ergaenzen (z. B. Flucht), ohne die ganze Hauptschleife zu
# kopieren. Standardmaessig passiert nichts (false = "ich uebernehme nicht").
#
# Siehe AUFGABEN.md -> A3 (Slime mit Flucht-Verhalten).
# =============================================================================
func _handle_extra_state(_delta: float) -> bool:
	return false

# =============================================================================
# _state_activation()
# Einmaliger Uebergang-Zustand: Slime dreht sich zum Spieler und spielt
# die Aktivierungs-Animation. Danach ist "activated = true" und der Slime
# laeuft normal weiter.
#
# Hat das Spritesheet keine "activation"-Animation (z. B. ein simpler
# Wand-Slime), wird der Zustand uebersprungen – kein Absturz.
# =============================================================================
func _state_activation():
	is_activating = true
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed
	sprite.flip_h = direction < 0
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("activation"):
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

# =============================================================================
# _state_chase(delta)
# Jagd-Zustand: der Slime hat den Spieler entdeckt und laeuft ihm aktiv
# hinterher. Beim Jagen ist er schneller als beim Patrouillieren (chase_speed)
# und springt in Abstaenden (jump_interval) – so kommt er auch ueber kleine
# Hindernisse und es sieht lebendig aus.
# =============================================================================
func _state_chase(delta: float) -> void:
	# Richtung zum Spieler bestimmen: +1 = Spieler ist rechts, -1 = links.
	var direction = sign(player.global_position.x - global_position.x)
	if direction == 0:
		direction = patrol_direction        # genau uebereinander? -> alte Richtung halten
	velocity.x = direction * chase_speed
	sprite.flip_h = direction < 0
	patrol_direction = direction            # merken, damit Patrouille spaeter nahtlos weitergeht

	# --- Springen ---
	# Nur springen wenn erlaubt, wenn wir auf festem Boden stehen und die
	# Pause (jump_cooldown) abgelaufen ist. Steht eine Wand im Weg, springt
	# der Slime sofort, um darueber zu klettern.
	if can_jump and is_on_floor() and (jump_cooldown <= 0 or is_on_wall()):
		_do_jump()

	# --- Animation ---
	# In der Luft die Sprung-Animation, am Boden die normale Lauf-Animation.
	if not is_on_floor() and sprite.sprite_frames and sprite.sprite_frames.has_animation("jump"):
		sprite.play("jump")
	else:
		sprite.play("patrol")

# =============================================================================
# _do_jump()
# Loest einen Sprung aus: gibt der Geschwindigkeit nach oben einen Stoss
# (negatives y = nach oben) und startet die Sprung-Pause neu.
# =============================================================================
func _do_jump() -> void:
	velocity.y = -jump_strength
	jump_cooldown = jump_interval
	if has_node("SoundJump"):
		$SoundJump.play()
