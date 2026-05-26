# =============================================================================
# fade_area.gd
# =============================================================================
# Transparenz-Ausloeser (Area2D).
#
# Wenn der Spieler diese Area betritt, wird die Eltern-Node fast unsichtbar
# (alpha = 0.1). So kann der Spieler durch Plattformen oder Waende
# "hindurchschauen" wenn er dahinter steht.
#
# Wenn der Spieler die Area verlaesst, wird die Eltern-Node wieder
# vollstaendig sichtbar (alpha = 1.0).
#
# Einrichtung: Diese Scene als Kind-Node der Plattform/des Objekts einfuegen
# das ausgeblendet werden soll.
# =============================================================================

extends Area2D

# =============================================================================
# _on_body_entered(body)
# Wird aufgerufen wenn der Spieler die Area betritt.
# Blendet das Eltern-Objekt fast komplett aus.
# =============================================================================
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var parent = self.get_parent()
		if parent:
			parent.modulate.a = 0.1     # Fast unsichtbar (10% Deckkraft)

# =============================================================================
# _on_body_exited(body)
# Wird aufgerufen wenn der Spieler die Area verlaesst.
# Stellt die volle Sichtbarkeit des Eltern-Objekts wieder her.
# =============================================================================
func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		var parent = self.get_parent()
		if parent:
			parent.modulate.a = 1       # Vollstaendig sichtbar
