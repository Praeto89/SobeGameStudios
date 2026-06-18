# =============================================================================
# checkpoint.gd
# =============================================================================
# Checkpoint / Speicherpunkt (Area2D).
#
# Betritt der Spieler diesen Bereich, wird sein Respawn-Punkt auf diese Stelle
# gesetzt. Stirbt er danach, taucht er hier wieder auf statt am Level-Anfang.
# Gedacht fuer lange Levels, damit man nach einem Sturz nicht alles wiederholen
# muss.
#
# Damit der Spieler sauber auf festem Boden erscheint, sucht der Checkpoint per
# Strahl nach unten den Boden und merkt sich diese Position (statt der Fahnen-
# hoehe).
#
# Verwendung: Diese Scene entlang des Weges im Level platzieren.
# =============================================================================

extends Area2D

# Farbe der Fahne: grau = noch nicht erreicht, gruen = aktiviert.
const COLOR_INACTIVE := Color(0.6, 0.6, 0.6)
const COLOR_ACTIVE := Color(0.2, 0.9, 0.3)

@export var ground_ray_length := 600.0  # Wie weit nach unten nach Boden gesucht wird (Pixel)
@export var ground_mask := 1            # Physik-Ebene des Bodens (Standard-Welt = 1)

@onready var flag := $Flag

# True sobald dieser Checkpoint einmal erreicht wurde (faerbt die Fahne gruen).
var _activated := false

# =============================================================================
# _on_body_entered(body)
# Wird aufgerufen wenn ein Koerper den Checkpoint betritt. Besitzt er die
# Methode "set_checkpoint" (also der Spieler), wird sein Respawn-Punkt gesetzt.
# =============================================================================
func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("set_checkpoint"):
		return
	body.set_checkpoint(_respawn_point())
	if not _activated:
		_activated = true
		flag.color = COLOR_ACTIVE

# =============================================================================
# _respawn_point()
# Schiesst einen Strahl nach unten und gibt die Position knapp ueber dem Boden
# zurueck. Findet sich kein Boden, wird die Fahnen-Position genommen.
# =============================================================================
func _respawn_point() -> Vector2:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, global_position + Vector2(0.0, ground_ray_length), ground_mask)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return global_position
	return Vector2(global_position.x, hit.position.y - 16.0)
