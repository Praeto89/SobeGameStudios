# =============================================================================
# chest.gd
# =============================================================================
# Eine zerstörbare Schatztruhe – kein Gegner im klassischen Sinne, aber
# trotzdem in der Gruppe "enemy", damit Roll, Attacke und Charge sie treffen.
#
# Verhalten:
#   - Steht reglos da (idle-Animation, leichtes Wippen).
#   - Wird der Spieler getroffen Roll/Attacke/Charge sie: die() wird aufgerufen.
#   - die() spielt die Aufbrech-Animation ab (Deckel fliegt ab, Kasten öffnet
#     sich) und spawnt dabei COIN_COUNT Münzen rund um die Truhe.
#   - Die Truhe entfernt sich danach selbst aus der Szene.
#
# WARUM StaticBody2D?
#   Die Truhe braucht keine eigene Bewegung. StaticBody2D sitzt einfach auf dem
#   Boden – kein move_and_slide(), keine Schwerkraft-Berechnungen nötig.
#   Der CharacterBody2D des Spielers prallt trotzdem von ihr ab (Kollisions-Layer 2).
#
# Spritesheet: assets/sprites/chest.png  (6 Frames à 32×32)
#   idle (0-1) / break (2-5)
#
# Schwierigkeit: [EINSTEIGER/MITTEL] – kurze die()-Coroutine + Szene-Instanzierung.
# =============================================================================

extends StaticBody2D

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  DEIN SPIELFELD – im Godot-Editor pro Instanz einstellbar:               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
@export var coin_count := 5    # Wie viele Münzen beim Aufbrechen erscheinen  <- z. B. 10 für eine reiche Truhe

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var sprite := $AnimatedSprite2D

var is_dead := false

# =============================================================================
# _ready()
# Fügt die Truhe zur Gruppe "enemy" hinzu – damit der Spieler sie per Roll,
# Attacke oder Charge treffen kann (gleiche Logik wie bei den Slimes).
# =============================================================================
func _ready() -> void:
	add_to_group(GameConstants.GROUP_ENEMY)
	sprite.play("idle")

# =============================================================================
# die()
# Wird vom Spieler-Controller aufgerufen, wenn Roll/Attacke/Charge die Truhe trifft.
# Reihenfolge: Kollision deaktivieren → Münzen spawnen → Aufbrech-Animation
#              abspielen → Truhe entfernen.
# =============================================================================
func die() -> void:
	if is_dead:
		return
	is_dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("SoundDeath"):
		$SoundDeath.play()
	_spawn_coins(coin_count)
	sprite.play("break")
	await sprite.animation_finished
	queue_free()

# =============================================================================
# _spawn_coins(count)
# Erzeugt count Münzen als Kinder des Eltern-Knotens (also des Levels),
# verteilt sie zufällig in einem kleinen Radius um die Truhe herum.
#
# WARUM get_parent()?
# Würden wir die Münzen als Kinder der Truhe hinzufügen, würden sie mit
# queue_free() sofort wieder entfernt. Als Kinder des Levels leben sie weiter.
# =============================================================================
func _spawn_coins(count: int) -> void:
	var coin_scene := load("res://scenes/pickups/coin.tscn")
	for i in count:
		var c = coin_scene.instantiate()
		var angle := randf() * TAU
		var dist  := randf_range(10.0, 26.0)
		# Leicht nach oben versetzt, damit Münzen über dem Kasten erscheinen
		c.global_position = global_position + Vector2(cos(angle) * dist, sin(angle) * dist - 14.0)
		get_parent().add_child(c)
