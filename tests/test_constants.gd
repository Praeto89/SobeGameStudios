# =============================================================================
# test_constants.gd
# =============================================================================
# Prueft, dass GameConstants alle erwarteten Werte enthaelt.
# Schuetzt vor versehentlichem Umbenennen oder Loeschen von Konstanten.
# =============================================================================

extends RefCounted

func run(t) -> void:
	print("GameConstants:")
	t.check(GameConstants.GROUP_PLAYER  == "player",  "GROUP_PLAYER hat Wert 'player'")
	t.check(GameConstants.GROUP_ENEMY   == "enemy",   "GROUP_ENEMY hat Wert 'enemy'")
	t.check(GameConstants.GROUP_PORTALS == "portals", "GROUP_PORTALS hat Wert 'portals'")
	t.check(GameConstants.SCENE_GALERIE.ends_with(".tscn"), "SCENE_GALERIE endet auf .tscn")
	t.check(GameConstants.SCENE_GALERIE.begins_with("res://"), "SCENE_GALERIE ist ein res://-Pfad")
