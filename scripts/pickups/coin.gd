# =============================================================================
# coin.gd
# =============================================================================
# Sammelbare Muenze (Area2D).
#
# Ablauf wenn der Spieler die Muenze beruehrt:
#   1. collect_coin() auf dem Spieler aufrufen (erhoehe Zaehler, sende Signal ans HUD)
#   2. Sammel-Sound abspielen
#   3. Warten bis der Sound fertig ist (damit er nicht abgeschnitten wird)
#   4. Muenze aus der Szene entfernen
#
# Die Muenze spielt beim Start automatisch eine Dreh-Animation ab.
# =============================================================================

extends Area2D

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var audio := $AudioStreamPlayer2D  # Sammel-Sound

# =============================================================================
# _ready()
# Startet die Dreh-Animation und verbindet das body_entered-Signal.
# =============================================================================
func _ready() -> void:
	$AnimatedSprite2D.play("spin")
	body_entered.connect(_on_body_entered)

# =============================================================================
# _on_body_entered(body)
# Wird aufgerufen wenn ein CharacterBody2D (also der Spieler) die Muenze beruehrt.
# Loest Sammlung aus und entfernt die Muenze nach dem Sound.
# =============================================================================
func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		body.collect_coin()          # Zaehler im Spieler erhoehen
		audio.play()
		# Warten bis der Sound komplett abgespielt ist, dann Muenze loeschen
		await get_tree().create_timer(audio.stream.get_length()).timeout
		queue_free()
