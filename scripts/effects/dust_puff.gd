# =============================================================================
# dust_puff.gd
# =============================================================================
# Ein kurzes Staub-Woelkchen, das beim Laufen unter den Fuessen erscheint.
# Es spielt seine 8-Frame-Animation EINMAL ab und loescht sich danach selbst
# wieder aus der Szene (queue_free) -- so sammeln sich keine toten Knoten an.
#
# Gespawnt wird es vom Spieler (player.gd -> _spawn_dust_puff), immer wenn
# genug Laufstrecke zurueckgelegt wurde ("ein Schritt").
# =============================================================================

extends AnimatedSprite2D

func _ready() -> void:
	# Sobald die (nicht loopende) Animation durch ist -> selbst entfernen.
	animation_finished.connect(queue_free)
	play("puff")
