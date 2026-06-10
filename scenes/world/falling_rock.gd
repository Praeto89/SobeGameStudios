extends CharacterBody2D

# =============================================================================
# falling_rock.gd
# =============================================================================
# Ein herabfallender Stein, der dem Spieler Schaden zufuegt, wenn er ihn beruehrt.
#
# WARUM machte er vorher KEINEN Schaden?
#   Zwei Dinge mussten zusammenpassen:
#   1. Die Trefferzone ist ein Area2D-Knoten ("Hitbox"). Eine Area2D MELDET zwar
#      per Signal "body_entered", wenn etwas sie beruehrt -- aber dieses Signal
#      muss man auch MIT EINER FUNKTION VERBINDEN (.connect), sonst wird die
#      Funktion nie aufgerufen. (Siehe _ready() unten.)
#   2. Der Stein-KOERPER (CharacterBody2D) hatte keine eigene CollisionShape2D.
#      Ohne Koerper-Form wird is_on_floor() NIE wahr -> der Stein bremst nie ab
#      und faellt einfach durch den Boden aus dem Level, bevor ihn jemand
#      beruehren kann. Der Knoten "Koerper" in der Szene behebt das: jetzt landet
#      der Stein auf der naechsten Kante und bleibt dort als Falle liegen.
# =============================================================================

const FALL_GRAVITY := 90.0     # Wie stark der Stein beschleunigt (px/s pro Sekunde)
const MAX_FALL_SPEED := 700.0   # Maximale Fallgeschwindigkeit (sonst wird er beliebig schnell)

# Referenz auf die Trefferzone. Pfad "$Sprite2D/Hitbox", weil die Hitbox UNTER
# dem Sprite haengt -- nicht direkt unter dem Stein.
@onready var hitbox: Area2D = $Sprite2D/Hitbox

func _ready() -> void:
	# ── DER FIX ──────────────────────────────────────────────────────────────
	# Trefferzonen-Signal mit unserer Schadens-Funktion verbinden. Ab jetzt ruft
	# Godot _on_hitbox_body_entered() automatisch auf, sobald ein Koerper die
	# Hitbox betritt. (Genau diese eine Zeile hat vorher gefehlt.)
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	# Schwerkraft AUFSUMMIEREN (nicht jeden Frame neu setzen) -> der Stein wird
	# immer schneller und faellt wirklich, bis er auf dem Boden aufkommt.
	if not is_on_floor():
		velocity.y = min(velocity.y + FALL_GRAVITY * delta, MAX_FALL_SPEED)
	else:
		velocity.y = 0.0          # Auf dem Boden angekommen -> ruhig liegen bleiben
	move_and_slide()

func _on_hitbox_body_entered(body: Node) -> void:
	# Nur Koerper mit einer take_damage-Methode (= der Spieler) nehmen Schaden.
	if body.has_method("take_damage"):
		# Rueckstoss-Richtung: weg vom Stein (positiv = rechts, negativ = links)
		var knockback_dir = sign(body.global_position.x - global_position.x)
		body.take_damage(1, knockback_dir)
