# =============================================================================
# doublejump_ability.gd
# =============================================================================
# Pickup fuer die Double-Jump-Ability (Area2D).
#
# Wenn der Spieler dieses Objekt beruehrt, wird der Doppelsprung freigeschaltet.
# Der Spieler kann danach in der Luft ein zweites Mal springen.
#
# Das Pickup-Objekt entfernt sich nach der Aktivierung selbst aus der Szene.
# =============================================================================

extends Area2D

# =============================================================================
# _ready()
# Verbindet das body_entered-Signal.
# =============================================================================
func _ready() -> void:
	# Falls die Ability bereits eingesammelt wurde, Pickup nicht erneut anzeigen.
	if GameManager.has_double_jump:
		queue_free()
		return
	body_entered.connect(_on_body_entered)

# =============================================================================
# _on_body_entered(body)
# Wird aufgerufen wenn der Spieler das Pickup beruehrt.
# Schaltet den Double Jump frei und entfernt das Pickup.
# =============================================================================
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.unlock_double_jump()   # Ability im Spieler-Skript aktivieren
		Hud.show_ability_message("Doppelsprung freigeschaltet!\nIn der Luft erneut springen")
		queue_free()                # Pickup aus der Szene entfernen
