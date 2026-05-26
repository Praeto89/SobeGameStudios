# =============================================================================
# death.gd
# =============================================================================
# Todeszone (Area2D).
#
# Wenn ein Koerper diese Zone betritt und die Methode "respawn" besitzt,
# wird der Respawn sofort ausgeloest. Das betrifft in der Regel den Spieler.
#
# Verwendung: Diese Scene unter Abgruende, Lava, oder andere toedliche
# Bereiche im Level platzieren.
# =============================================================================

extends Area2D

# =============================================================================
# _on_body_entered(body)
# Wird aufgerufen wenn ein Koerper die Todeszone betritt.
# Loest den Respawn aus falls moeglich.
# =============================================================================
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("respawn"):
		body.respawn()
