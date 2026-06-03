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
	gm.upgrade_charge = true
	gm.upgrade_jump = true
	gm.upgrade_health = true
	gm.upgrade_attack = true
	gm.coin_count = 99
	gm.current_health = 1
	gm.collected_coin_ids.append("res://x.tscn::coin")
	gm.defeated_enemy_ids.append("res://x.tscn::slime")

	gm.reset_game()

	t.check(gm.has_charge == false, "reset_game setzt has_charge auf false")
	t.check(gm.has_double_jump == false, "reset_game setzt has_double_jump auf false")
	t.check(gm.upgrade_charge == false, "reset_game setzt upgrade_charge auf false")
	t.check(gm.upgrade_jump == false, "reset_game setzt upgrade_jump auf false")
	t.check(gm.upgrade_health == false, "reset_game setzt upgrade_health auf false")
	t.check(gm.upgrade_attack == false, "reset_game setzt upgrade_attack auf false")
	t.check(gm.coin_count == 0, "reset_game setzt coin_count auf 0")
	t.check(gm.current_health == gm.MAX_HEALTH, "reset_game stellt volle Leben her")
	t.check(gm.collected_coin_ids.is_empty(), "reset_game leert collected_coin_ids")
	t.check(gm.defeated_enemy_ids.is_empty(), "reset_game leert defeated_enemy_ids")

	# --- get_max_health() beruecksichtigt das Health-Upgrade ---
	gm.upgrade_health = false
	t.check(gm.get_max_health() == gm.MAX_HEALTH, "get_max_health ohne Upgrade = MAX_HEALTH")
	gm.upgrade_health = true
	t.check(gm.get_max_health() == gm.MAX_HEALTH + gm.HEALTH_UPGRADE_BONUS, "get_max_health mit Upgrade = MAX_HEALTH + Bonus")
	gm.upgrade_health = false

	# --- Upgrade-Preise sind fuer alle vier Upgrades definiert und positiv ---
	for key in ["charge", "jump", "health", "attack"]:
		t.check(gm.UPGRADE_COSTS.has(key), "UPGRADE_COSTS enthaelt '%s'" % key)
		t.check(gm.UPGRADE_COSTS.get(key, 0) > 0, "UPGRADE_COSTS['%s'] ist positiv" % key)

	# --- mark_scene_visited() vermeidet Duplikate und leere Pfade ---
	gm.mark_scene_visited("res://a.tscn")
	gm.mark_scene_visited("res://a.tscn")   # Duplikat -> wird ignoriert
	gm.mark_scene_visited("res://b.tscn")
	t.check(gm.visited_scenes.size() == 2, "mark_scene_visited ignoriert Duplikate")

	gm.mark_scene_visited("")                # leerer Pfad -> wird ignoriert
	t.check(gm.visited_scenes.size() == 2, "mark_scene_visited ignoriert leeren Pfad")

	# GameManager erbt von Node -> wieder freigeben, damit nichts leakt.
	gm.free()
