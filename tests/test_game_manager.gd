# =============================================================================
# test_game_manager.gd
# =============================================================================
# Tests fuer die Logik im GameManager (scripts/game_manager.gd).
#
# Wir testen eine FRISCHE Instanz (.new()), nicht das laufende Autoload --
# so beeinflussen sich Tests nicht gegenseitig und brauchen keine Szene.
# =============================================================================

extends RefCounted

const GameManagerScript = preload("res://scripts/game_manager.gd")

func run(t) -> void:
	print("GameManager:")

	var gm = GameManagerScript.new()

	# --- reset_game() setzt alles auf Anfang zurueck ---
	gm.has_charge = true
	gm.has_double_jump = true
	gm.ability_levels["charge"] = 3
	gm.ability_levels["jump"] = 2
	gm.ability_levels["health"] = 1
	gm.ability_levels["attack"] = 2
	gm.coin_count = 99
	gm.current_health = 1
	gm.collected_coin_ids.append("res://x.tscn::coin")
	gm.defeated_enemy_ids.append("res://x.tscn::slime")

	gm.reset_game()

	t.check(gm.has_charge == false, "reset_game setzt has_charge auf false")
	t.check(gm.has_double_jump == false, "reset_game setzt has_double_jump auf false")
	t.check(gm.get_level("charge") == 0, "reset_game setzt charge-Stufe auf 0")
	t.check(gm.get_level("jump") == 0, "reset_game setzt jump-Stufe auf 0")
	t.check(gm.get_level("health") == 0, "reset_game setzt health-Stufe auf 0")
	t.check(gm.get_level("attack") == 0, "reset_game setzt attack-Stufe auf 0")
	t.check(gm.coin_count == 0, "reset_game setzt coin_count auf 0")
	t.check(gm.current_health == gm.MAX_HEALTH, "reset_game stellt volle Leben her")
	t.check(gm.collected_coin_ids.is_empty(), "reset_game leert collected_coin_ids")
	t.check(gm.defeated_enemy_ids.is_empty(), "reset_game leert defeated_enemy_ids")

	# --- has_*-Eigenschaften spiegeln die Stufe ---
	t.check(not gm.has_charge, "has_charge ist false bei Stufe 0")
	gm.has_charge = true
	t.check(gm.has_charge and gm.get_level("charge") == 1,
		"has_charge = true hebt auf Stufe 1 (abgeschwaechte erste Version)")
	gm.has_charge = false
	t.check(not gm.has_charge and gm.get_level("charge") == 0,
		"has_charge = false sperrt die Faehigkeit wieder")

	# --- get_max_health() beruecksichtigt die Health-Stufen ---
	gm.ability_levels["health"] = 0
	t.check(gm.get_max_health() == gm.MAX_HEALTH, "get_max_health ohne Stufe = MAX_HEALTH")
	gm.ability_levels["health"] = 1
	t.check(gm.get_max_health() == gm.MAX_HEALTH + gm.HEALTH_UPGRADE_BONUS,
		"get_max_health Stufe 1 = MAX_HEALTH + Bonus")
	gm.ability_levels["health"] = 3
	t.check(gm.get_max_health() == gm.MAX_HEALTH + 3 * gm.HEALTH_UPGRADE_BONUS,
		"get_max_health Stufe 3 = MAX_HEALTH + 3x Bonus")
	gm.ability_levels["health"] = 0

	# --- Preise sind fuer alle Spuren definiert, positiv und steigen je Stufe ---
	for key in gm.ability_levels.keys():
		t.check(gm.ABILITY_COSTS.has(key), "ABILITY_COSTS enthaelt '%s'" % key)
		var costs: Array = gm.ABILITY_COSTS.get(key, [])
		t.check(costs.size() == gm.MAX_ABILITY_LEVEL,
			"ABILITY_COSTS['%s'] hat %d Stufen-Preise" % [key, gm.MAX_ABILITY_LEVEL])
		t.check(costs[0] > 0, "ABILITY_COSTS['%s'][0] ist positiv" % key)
		t.check(costs[gm.MAX_ABILITY_LEVEL - 1] >= costs[0],
			"ABILITY_COSTS['%s'] wird pro Stufe nicht billiger" % key)

	# --- Stufen-Helfer: add_level steigert bis zum Maximum, dann Stopp ---
	gm.ability_levels["dash"] = 0
	t.check(gm.get_next_cost("dash") == gm.ABILITY_COSTS["dash"][0],
		"get_next_cost liefert den Preis fuer Stufe 1")
	t.check(gm.can_upgrade("dash"), "can_upgrade('dash') bei Stufe 0 = true")
	gm.add_level("dash"); gm.add_level("dash"); gm.add_level("dash")
	t.check(gm.get_level("dash") == gm.MAX_ABILITY_LEVEL, "add_level deckelt bei MAX_ABILITY_LEVEL")
	t.check(not gm.can_upgrade("dash"), "can_upgrade('dash') bei MAX = false")
	t.check(gm.get_next_cost("dash") == -1, "get_next_cost bei MAX = -1")
	gm.add_level("dash")
	t.check(gm.get_level("dash") == gm.MAX_ABILITY_LEVEL, "add_level ueber MAX hinaus bleibt bei MAX")

	# --- mark_scene_visited() vermeidet Duplikate und leere Pfade ---
	gm.mark_scene_visited("res://a.tscn")
	gm.mark_scene_visited("res://a.tscn")   # Duplikat -> wird ignoriert
	gm.mark_scene_visited("res://b.tscn")
	t.check(gm.visited_scenes.size() == 2, "mark_scene_visited ignoriert Duplikate")

	gm.mark_scene_visited("")                # leerer Pfad -> wird ignoriert
	t.check(gm.visited_scenes.size() == 2, "mark_scene_visited ignoriert leeren Pfad")

	# GameManager erbt von Node -> wieder freigeben, damit nichts leakt.
	gm.free()
