# =============================================================================
# checkpoint.gd
# =============================================================================
# Checkpoint-Fahne (Area2D).
#
# Beruehrt der Spieler die Fahne zum ersten Mal, wird sie "aktiviert":
#   - der Wiederbelebungs-Punkt des Spielers wandert hierher
#     (player.set_checkpoint), d. h. nach einem Tod erscheint er ab jetzt hier
#   - der Spielstand wird automatisch gespeichert (GameManager.save_game)
#   - die Fahne wechselt sichtbar die Farbe (rot -> gruen) und huepft kurz
#
# Verwendung: Diese Szene ins Level ziehen und auf einer Plattform/dem Boden
# platzieren. Mehrere Checkpoints pro Level sind moeglich -- jeder ueberschreibt
# den vorherigen Wiederbelebungs-Punkt.
# =============================================================================
extends Area2D

## Farbe der Fahne im inaktiven bzw. aktivierten Zustand.
const COLOR_INACTIVE := Color(0.75, 0.2, 0.2)   # ruhiges Rot
const COLOR_ACTIVE   := Color(0.3, 0.85, 0.4)   # leuchtendes Gruen

var _activated := false

@onready var _flag: Polygon2D = $Flag


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if _flag:
		_flag.color = COLOR_INACTIVE


func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if not body.is_in_group(GameConstants.GROUP_PLAYER):
		return
	_activated = true
	# Wiederbelebungs-Punkt auf diese Fahne legen.
	if body.has_method("set_checkpoint"):
		body.set_checkpoint(global_position)
	# Fortschritt automatisch sichern.
	GameManager.save_game()
	_show_activation()


# Sichtbares Feedback: Fahne wird gruen, huepft kurz auf und ein Hinweis erscheint.
func _show_activation() -> void:
	if _flag:
		_flag.color = COLOR_ACTIVE
		var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_flag.scale = Vector2(1.4, 1.4)
		t.tween_property(_flag, "scale", Vector2.ONE, 0.35)
	# Das HUD ist als Autoload registriert -> der Name "Hud" ist ueberall gueltig.
	Hud.show_ability_message("Checkpoint erreicht!", 1.6)
