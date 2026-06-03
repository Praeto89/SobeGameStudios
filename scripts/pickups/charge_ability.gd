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

@onready var audio := $SoundPickup

# =============================================================================
# _ready()
# Verbindet das body_entered-Signal.
# =============================================================================
func _ready():
	# Falls die Ability bereits eingesammelt wurde (z. B. in einem anderen
	# Level), Pickup nicht nochmal anzeigen.
	if GameManager.has_charge:
		queue_free()
		return
	body_entered.connect(_on_body_entered)

# =============================================================================
# _on_body_entered(body)
# Wird aufgerufen wenn der Spieler das Pickup beruehrt.
# Schaltet die Charge-Ability frei und entfernt das Pickup.
# =============================================================================
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.unlock_charge()    # Ability im Spieler-Skript aktivieren
		# Spieler-Hinweis: was die Ability tut + Tasten-Hinweis
		Hud.show_ability_message("Charge freigeschaltet!\n'E' gedrueckt halten fuer einen schnellen Dash")
		Hud.celebrate_unlock()   # kurze Zeitlupe als "Wow"-Moment
		set_deferred("monitoring", false)
		$Sprite2D.visible = false
		audio.play()
		await audio.finished
		queue_free()
