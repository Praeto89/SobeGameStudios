# =============================================================================
# test_player_constants.gd
# =============================================================================
# Tests fuer die Bewegungs-Konstanten des Spielers (scripts/player/player.gd).
#
# Wir instanziieren den Spieler NICHT (das braeuchte eine Szene mit Kind-Nodes).
# Stattdessen lesen wir die Konstanten direkt aus dem Skript:
#   GDScript.get_script_constant_map() liefert ein Dictionary { Name: Wert }.
#
# Das schuetzt z. B. vor BUGCHASE-Bug #1: JUMP_VELOCITY MUSS negativ sein,
# sonst "springt" der Spieler nach unten (y waechst nach unten!).
# =============================================================================

extends RefCounted

const PlayerScript = preload("res://scripts/player/player.gd")

func run(t) -> void:
	print("Player-Konstanten:")

	var c: Dictionary = PlayerScript.get_script_constant_map()

	t.check(c.has("JUMP_VELOCITY"), "JUMP_VELOCITY ist definiert")
	t.check(c.get("JUMP_VELOCITY", 0.0) < 0.0, "JUMP_VELOCITY ist negativ (Sprung geht nach oben)")
	t.check(c.get("SPEED", 0.0) > 0.0, "SPEED ist positiv")
	t.check(c.get("GRAVITY", 0.0) > 0.0, "GRAVITY ist positiv")
	t.check(c.get("MAX_FALL_SPEED", 0.0) > 0.0, "MAX_FALL_SPEED ist positiv")
	# Fallen soll sich schwerer anfuehlen als steigen (Game-Feel-Entscheidung).
	t.check(c.get("FALL_GRAVITY", 0.0) >= c.get("GRAVITY", 0.0), "FALL_GRAVITY ist >= GRAVITY (knackigeres Fallen)")
