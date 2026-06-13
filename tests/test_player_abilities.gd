# =============================================================================
# test_player_abilities.gd
# =============================================================================
# Prueft die Ability- und Stufen-Konstanten des Spielers.
#
# Getestet: CHARGE_*, WALL_CRAWL_*, WALL_JUMP_VELOCITY, KNOCKBACK_VELOCITY
# sowie die Stufen-Tabellen (Stufe 1 = abgeschwaecht, Stufe 3 = stark). Eine
# hoehere Stufe muss eine Faehigkeit verbessern, sonst lohnt das Upgrade nicht.
# =============================================================================

extends RefCounted

func run(t) -> void:
	print("Spieler-Ability-Konstanten:")

	var player_script := load("res://scripts/player/player.gd")
	var c: Dictionary = player_script.get_script_constant_map()

	# Charge-Ability (Basiswerte)
	t.check(c.get("CHARGE_SPEED",    0.0) > 0.0, "CHARGE_SPEED ist positiv")
	t.check(c.get("CHARGE_DURATION", 0.0) > 0.0, "CHARGE_DURATION ist positiv")
	t.check(c.get("CHARGE_MAX_TIME", 0.0) > 0.0, "CHARGE_MAX_TIME ist positiv")

	# Wallcrawl-Ability
	t.check(c.get("WALL_CRAWL_SPEED", 0.0) > 0.0, "WALL_CRAWL_SPEED ist positiv")
	var wjv: Vector2 = c.get("WALL_JUMP_VELOCITY", Vector2.ZERO)
	t.check(wjv.x > 0.0, "WALL_JUMP_VELOCITY.x ist positiv (horizontaler Abstoss)")
	t.check(wjv.y < 0.0, "WALL_JUMP_VELOCITY.y ist negativ (Sprung nach oben)")

	# --- Stufen-Tabellen: Stufe 3 muss besser sein als Stufe 1 ---
	# (Index 0 = "nicht gekauft", Indizes 1..3 = Stufen.)
	_check_growing(t, c, "CHARGE_SPEED_BY_LEVEL",  "Charge-Speed steigt je Stufe")
	_check_growing(t, c, "CHARGE_TIME_BY_LEVEL",   "Charge-Dauer steigt je Stufe")
	_check_growing(t, c, "ROLL_SPEED_BY_LEVEL",    "Roll/Dash-Speed steigt je Stufe")
	_check_growing(t, c, "DOUBLE_JUMP_FACTOR_BY_LEVEL", "Doppelsprung-Kraft steigt je Stufe")
	_check_growing(t, c, "WALL_CRAWL_SPEED_BY_LEVEL",   "Klettertempo steigt je Stufe")
	_check_growing(t, c, "AIR_ATTACK_HITBOX_BY_LEVEL",  "Luft-Attacke-Hitbox steigt je Stufe")
	_check_growing(t, c, "ATTACK_SCALE_BY_LEVEL",  "Attacke-Hitbox steigt je Stufe")
	_check_growing(t, c, "JUMP_MULT_BY_LEVEL",     "Sprung-Multiplikator steigt je Stufe")

	# Erste Charge-Stufe ist bewusst SCHWAECHER als der alte Standard (700/0.5 s).
	var charge_by_level: Array = c.get("CHARGE_SPEED_BY_LEVEL", [])
	if charge_by_level.size() >= 2:
		t.check(charge_by_level[1] < c.get("CHARGE_SPEED", 0.0),
			"Charge Stufe 1 ist schwaecher als CHARGE_SPEED (abgeschwaechte erste Version)")

	# Knockback: muss nach oben schleudern
	var knockback: Vector2 = c.get("KNOCKBACK_VELOCITY", Vector2.ZERO)
	t.check(knockback.y < 0.0,
		"KNOCKBACK_VELOCITY.y ist negativ (schleudert nach oben)")


# Hilfsfunktion: prueft, dass eine Stufen-Tabelle [0, s1, s2, s3] bei den
# Stufen 1..3 streng waechst (jede Stufe besser als die vorige).
func _check_growing(t, c: Dictionary, key: String, label: String) -> void:
	var arr: Array = c.get(key, [])
	if arr.size() < 4:
		t.check(false, "%s: Tabelle hat 4 Eintraege (Stufe 0..3)" % key)
		return
	t.check(arr[3] > arr[1] and arr[2] > arr[1], label)
