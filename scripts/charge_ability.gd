# =============================================================================
# charge_ability.gd
# =============================================================================
# Pickup fuer die Charge-Ability (Area2D).
#
# Wenn der Spieler dieses Objekt beruehrt, wird die Charge-Ability freigeschaltet.
# Der Spieler kann danach mit der "charge"-Taste (E) einen schnellen Dash ausfuehren.
#
# Das Pickup-Objekt entfernt sich nach der Aktivierung selbst aus der Szene.
# =============================================================================

extends Area2D

# =============================================================================
# _ready()
# Verbindet das body_entered-Signal.
# =============================================================================
func _ready():
	body_entered.connect(_on_body_entered)

# =============================================================================
# _on_body_entered(body)
# Wird aufgerufen wenn der Spieler das Pickup beruehrt.
# Schaltet die Charge-Ability frei und entfernt das Pickup.
# =============================================================================
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.unlock_charge()    # Ability im Spieler-Skript aktivieren
		queue_free()            # Pickup aus der Szene entfernen
