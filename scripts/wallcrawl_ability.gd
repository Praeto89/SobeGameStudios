# =============================================================================
# wallcrawl_ability.gd
# =============================================================================
# Pickup fuer die Wallcrawl-Ability (Area2D).
#
# Wenn der Spieler dieses Objekt beruehrt, wird das Wandklettern freigeschaltet.
# Der Spieler kann danach an Waenden hoch- und runterklettern
# sowie von Waenden abspringen (Wall Jump).
#
# Das Pickup-Objekt entfernt sich nach der Aktivierung selbst aus der Szene.
# =============================================================================

extends Area2D

# =============================================================================
# _ready()
# Verbindet das body_entered-Signal.
# =============================================================================
func _ready() -> void:
	body_entered.connect(_on_body_entered)

# =============================================================================
# _on_body_entered(body)
# Wird aufgerufen wenn der Spieler das Pickup beruehrt.
# Schaltet die Wallcrawl-Ability frei und entfernt das Pickup.
# =============================================================================
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.unlock_wallcrawl()     # Ability im Spieler-Skript aktivieren
		queue_free()                # Pickup aus der Szene entfernen
