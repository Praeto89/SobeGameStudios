# =============================================================================
# test_game_manager_persistence.gd
# =============================================================================
# Prueft die Persistenz-Logik des GameManagers:
#   - Eingesammelte Coins und besiegte Gegner werden korrekt gespeichert
#   - Lookup (in-Operator) liefert die erwarteten Ergebnisse
#   - Ability-Flags starten false und koennen gesetzt werden
# =============================================================================

extends RefCounted

const GameManagerScript = preload("res://scripts/game_manager.gd")

func run(t) -> void:
	print("GameManager-Persistenz:")

	var gm = GameManagerScript.new()

	# Coin-IDs: bekannte ID wird gefunden, unbekannte nicht
	gm.collected_coin_ids.append("res://level.tscn::coin_gold")
	t.check("res://level.tscn::coin_gold" in gm.collected_coin_ids,
		"eingesammelte Coin-ID wird als 'gesammelt' erkannt")
	t.check(not ("res://level.tscn::coin_silver" in gm.collected_coin_ids),
		"nicht eingesammelte Coin-ID wird korrekt als fehlend erkannt")

	# Gegner-IDs: bekannte ID wird gefunden, unbekannte nicht
	gm.defeated_enemy_ids.append("res://level.tscn::slime1")
	t.check("res://level.tscn::slime1" in gm.defeated_enemy_ids,
		"besiegter Gegner wird als 'besiegt' erkannt")
	t.check(not ("res://level.tscn::slime2" in gm.defeated_enemy_ids),
		"nicht besiegter Gegner wird korrekt als aktiv erkannt")

	# Ability-Flags starten false
	var gm2 = GameManagerScript.new()
	t.check(not gm2.has_charge,      "has_charge startet als false")
	t.check(not gm2.has_wallcrawl,   "has_wallcrawl startet als false")
	t.check(not gm2.has_double_jump, "has_double_jump startet als false")
	gm2.has_charge = true
	t.check(gm2.has_charge, "has_charge kann auf true gesetzt werden")

	gm.free()
	gm2.free()
