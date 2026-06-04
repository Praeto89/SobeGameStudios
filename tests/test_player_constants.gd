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

func run(t) -> void:
	print("Player-Konstanten:")

	# player.gd hat ein "class_name Player". Ein preload() davon liefert den
	# Klassen-TYP -- und auf einem Typ laesst sich die Instanz-Methode
	# get_script_constant_map() nicht direkt aufrufen (Parse-Fehler in 4.6).
	# Deshalb das Skript zur Laufzeit als Resource laden; darauf funktioniert
	# die Methode wie erwartet.
	var player_script := load("res://scripts/player/player.gd")
	var c: Dictionary = player_script.get_script_constant_map()

	t.check(c.has("JUMP_VELOCITY"), "JUMP_VELOCITY ist definiert")
	t.check(c.get("JUMP_VELOCITY", 0.0) < 0.0, "JUMP_VELOCITY ist negativ (Sprung geht nach oben)")
	t.check(c.get("SPEED", 0.0) > 0.0, "SPEED ist positiv")
	t.check(c.get("GRAVITY", 0.0) > 0.0, "GRAVITY ist positiv")
	t.check(c.get("MAX_FALL_SPEED", 0.0) > 0.0, "MAX_FALL_SPEED ist positiv")
	# Fallen soll sich schwerer anfuehlen als steigen (Game-Feel-Entscheidung).
	t.check(c.get("FALL_GRAVITY", 0.0) >= c.get("GRAVITY", 0.0), "FALL_GRAVITY ist >= GRAVITY (knackigeres Fallen)")

	# --- Effekt-Konstanten (Squash & Stretch, siehe VISUALS.md) ---
	# Beim Absprung soll das Sprite HOCH & SCHMAL werden: y-Faktor > 1, x < 1.
	var stretch: Vector2 = c.get("JUMP_STRETCH_SCALE", Vector2.ONE)
	t.check(stretch.y > 1.0 and stretch.x < 1.0, "JUMP_STRETCH_SCALE streckt nach oben (hoch & schmal)")
	# Beim Aufprall genau umgekehrt: BREIT & FLACH (x > 1, y < 1).
	var squash: Vector2 = c.get("LANDING_SQUASH_SCALE", Vector2.ONE)
	t.check(squash.x > 1.0 and squash.y < 1.0, "LANDING_SQUASH_SCALE staucht flach (breit & flach)")
	# Treffer-Blitz nutzt einen Wert > 1, damit das Glow-Environment ihn aufleuchten laesst.
	var flash: Color = c.get("HIT_FLASH_COLOR", Color.WHITE)
	t.check(flash.r > 1.0, "HIT_FLASH_COLOR leuchtet auf (Rot-Kanal > 1)")
	t.check(c.get("SQUASH_RECOVER_TIME", 0.0) > 0.0, "SQUASH_RECOVER_TIME ist positiv")
