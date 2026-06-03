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
	gm.coin_count = 99
	gm.current_health = 1
	gm.collected_coin_ids.append("res://x.tscn::coin")
	gm.defeated_enemy_ids.append("res://x.tscn::slime")
	gm.opened_gate_ids.append("res://x.tscn::charge_gate")

	gm.reset_game()

	t.check(gm.has_charge == false, "reset_game setzt has_charge auf false")
	t.check(gm.has_double_jump == false, "reset_game setzt has_double_jump auf false")
	t.check(gm.coin_count == 0, "reset_game setzt coin_count auf 0")
	t.check(gm.current_health == gm.MAX_HEALTH, "reset_game stellt volle Leben her")
	t.check(gm.collected_coin_ids.is_empty(), "reset_game leert collected_coin_ids")
	t.check(gm.defeated_enemy_ids.is_empty(), "reset_game leert defeated_enemy_ids")
	t.check(gm.opened_gate_ids.is_empty(), "reset_game leert opened_gate_ids")

	# --- mark_scene_visited() vermeidet Duplikate und leere Pfade ---
	gm.mark_scene_visited("res://a.tscn")
	gm.mark_scene_visited("res://a.tscn")   # Duplikat -> wird ignoriert
	gm.mark_scene_visited("res://b.tscn")
	t.check(gm.visited_scenes.size() == 2, "mark_scene_visited ignoriert Duplikate")

	gm.mark_scene_visited("")                # leerer Pfad -> wird ignoriert
	t.check(gm.visited_scenes.size() == 2, "mark_scene_visited ignoriert leeren Pfad")

	# --- save_game()/load_game() Roundtrip (auf einen Temp-Pfad) ---
	# Bewusst NICHT der echte Speicherstand (SAVE_PATH), damit der Test ihn
	# nicht ueberschreibt.
	var tmp_path := "user://test_savegame.json"
	gm.has_charge = true
	gm.has_wallcrawl = false
	gm.has_double_jump = true
	gm.coin_count = 7
	gm.current_health = 2
	gm.opened_gate_ids.append("res://lvl.tscn::gate_a")
	gm.collected_coin_ids.append("res://lvl.tscn::coin_a")
	gm.save_game(tmp_path)

	# Zustand verfaelschen, dann aus der Datei wiederherstellen
	gm.has_charge = false
	gm.has_double_jump = false
	gm.coin_count = 0
	gm.current_health = gm.MAX_HEALTH
	gm.opened_gate_ids.clear()
	gm.collected_coin_ids.clear()

	t.check(gm.load_game(tmp_path), "load_game meldet Erfolg bei vorhandener Datei")
	t.check(gm.has_charge == true, "load_game stellt has_charge wieder her")
	t.check(gm.has_double_jump == true, "load_game stellt has_double_jump wieder her")
	t.check(gm.coin_count == 7, "load_game stellt coin_count wieder her")
	t.check(gm.current_health == 2, "load_game stellt current_health wieder her")
	t.check(gm.opened_gate_ids.has("res://lvl.tscn::gate_a"), "load_game stellt opened_gate_ids wieder her")
	t.check(gm.collected_coin_ids.has("res://lvl.tscn::coin_a"), "load_game stellt collected_coin_ids wieder her")

	# Fehlende Datei -> false, kein Crash
	t.check(gm.load_game("user://does_not_exist_42.json") == false, "load_game meldet false ohne Datei")

	# Temp-Datei wieder aufraeumen
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))

	# GameManager erbt von Node -> wieder freigeben, damit nichts leakt.
	gm.free()
