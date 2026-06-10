# =============================================================================
# test_player_abilities.gd
# =============================================================================
# Prueft die Ability- und Upgrade-Konstanten des Spielers.
#
# Getestet: CHARGE_*, WALL_CRAWL_*, WALL_JUMP_VELOCITY, KNOCKBACK_VELOCITY
# sowie alle Upgrade-Multiplikatoren (muessen > 1 sein, sonst verschlechtert
# das "Upgrade" die Faehigkeit statt sie zu verbessern).
# =============================================================================

extends RefCounted

func run(t) -> void:
	print("Spieler-Ability-Konstanten:")

	var player_script := load("res://scripts/player/player.gd")
	var c: Dictionary = player_script.get_script_constant_map()

	# Charge-Ability
	t.check(c.get("CHARGE_SPEED",    0.0) > 0.0, "CHARGE_SPEED ist positiv")
	t.check(c.get("CHARGE_DURATION", 0.0) > 0.0, "CHARGE_DURATION ist positiv")
	t.check(c.get("CHARGE_MAX_TIME", 0.0) > 0.0, "CHARGE_MAX_TIME ist positiv")

	# Wallcrawl-Ability
	t.check(c.get("WALL_CRAWL_SPEED", 0.0) > 0.0, "WALL_CRAWL_SPEED ist positiv")
	var wjv: Vector2 = c.get("WALL_JUMP_VELOCITY", Vector2.ZERO)
	t.check(wjv.x > 0.0, "WALL_JUMP_VELOCITY.x ist positiv (horizontaler Abstoss)")
	t.check(wjv.y < 0.0, "WALL_JUMP_VELOCITY.y ist negativ (Sprung nach oben)")

	# Upgrade-Multiplikatoren muessen > 1 sein (ein Upgrade muss verbessern)
	t.check(c.get("JUMP_UPGRADE_MULTIPLIER",          0.0) > 1.0,
		"JUMP_UPGRADE_MULTIPLIER verbessert den Sprung (> 1)")
	t.check(c.get("CHARGE_SPEED_UPGRADE_MULTIPLIER",  0.0) > 1.0,
		"CHARGE_SPEED_UPGRADE_MULTIPLIER verbessert Charge-Speed (> 1)")
	t.check(c.get("CHARGE_TIME_UPGRADE_MULTIPLIER",   0.0) > 1.0,
		"CHARGE_TIME_UPGRADE_MULTIPLIER verlaengert Charge-Dauer (> 1)")

	# Knockback: muss nach oben schleudern
	var knockback: Vector2 = c.get("KNOCKBACK_VELOCITY", Vector2.ZERO)
	t.check(knockback.y < 0.0,
		"KNOCKBACK_VELOCITY.y ist negativ (schleudert nach oben)")
