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
	# Falls diese Muenze bereits eingesammelt wurde (Persistenz),
	# sich sofort selbst entfernen.
	var id = GameManager.get_persistent_id(self)
	if id != "" and id in GameManager.collected_coin_ids:
		queue_free()
		return
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
		# Diese Muenze als gesammelt persistieren (verschwindet beim Re-Entry)
		var id = GameManager.get_persistent_id(self)
		if id != "" and not id in GameManager.collected_coin_ids:
			GameManager.collected_coin_ids.append(id)
		audio.play()
		# Muenze sofort visuell + kollisionsmaessig entfernen,
		# aber Node erst freigeben wenn der Sound fertig ist
		# (sonst wird der Sound mit der Node abgeschnitten)
		$AnimatedSprite2D.visible = false
		set_deferred("monitoring", false)
		await audio.finished
		queue_free()
