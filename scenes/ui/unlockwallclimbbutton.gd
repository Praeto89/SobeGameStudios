extends Button

# =============================================================================
# unlockwallclimbbutton.gd
# =============================================================================
# Debug-/Cheat-Button im HUD: schaltet per Klick die Wallcrawl-Faehigkeit des
# Spielers frei (an Waenden hoch-/runterklettern + Wall Jump), ohne dass man das
# zugehoerige Pickup erst finden muss. Praktisch zum Testen der Faehigkeit.
# =============================================================================

func _ready() -> void:
	# Buttons feuern beim Anklicken das "pressed"-Signal (ohne Argumente).
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var player = get_tree().get_first_node_in_group(GameConstants.GROUP_PLAYER)
	if player and player.has_method("unlock_wallcrawl"):
		player.unlock_wallcrawl()    # Faehigkeit im Spieler-Skript aktivieren
		# Spieler-Hinweis: was die Faehigkeit tut.
		Hud.show_ability_message("Wallcrawl freigeschaltet!\nAn Waenden hoch-/runterklettern + Wall Jump")
	# Button hat seinen Zweck erfuellt -> entfernen.
	queue_free()
