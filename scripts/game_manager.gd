# GameManager.gd
# -------------------------------------------------------
# Als Autoload-Singleton einrichten:
#   Projekt > Projekteinstellungen > Autoload
#   Skript: res://GameManager.gd  |  Name: GameManager
# -------------------------------------------------------
extends Node

## ID des Portals, aus dem der Spieler zuletzt kam.
## Wird genutzt, um beim Szenenwechsel das Spawn-Portal zu finden.
var came_from_portal_id: String = ""

# -------------------------------------------------------
# Persistente Ability-Flags
# -------------------------------------------------------
# Diese Variablen ueberleben Szenen-Wechsel (Autoload bleibt am Leben).
# Beim Szenen-Wechsel wird der Player neu instanziiert -> ohne diese
# Flags waeren alle Abilities im neuen Level wieder weg.
# Der Player liest die Flags in _ready() und schreibt sie in unlock_*().
var has_charge: bool = false
var has_wallcrawl: bool = false
var has_double_jump: bool = false

# -------------------------------------------------------
# Persistenter Spieler-Zustand
# -------------------------------------------------------
const MAX_HEALTH: int = 4
var current_health: int = MAX_HEALTH
var coin_count: int = 0

# -------------------------------------------------------
# Persistente Welt-Aenderungen
# -------------------------------------------------------
# IDs der Coins die bereits eingesammelt wurden (Format siehe get_persistent_id).
var collected_coin_ids: Array[String] = []
# IDs der Gegner die bereits besiegt wurden.
var defeated_enemy_ids: Array[String] = []
# Szenen-Pfade die der Spieler in dieser Session betreten UND wieder verlassen hat.
# Wird vom portal.gd befuellt wenn ein Portal in die Galerie fuehrt.
# Die Galerie liest diese Liste in galerie.gd, um ⭐-Sticker an besuchten
# Slot-Portalen anzuzeigen.
var visited_scenes: Array[String] = []

# =============================================================================
# mark_scene_visited(scene_path)
# Markiert eine Szene als "besucht" (Spieler war drin und ist wieder raus).
# Doppelte Eintraege werden ignoriert.
# =============================================================================
func mark_scene_visited(scene_path: String) -> void:
	if scene_path != "" and not scene_path in visited_scenes:
		visited_scenes.append(scene_path)

# =============================================================================
# get_persistent_id(node)
# Erzeugt eine eindeutige, ueber Szenen-Wechsel stabile ID fuer einen Node.
# Format: "<scene_pfad>::<node_name>"
#   z. B. "res://scenes/levels/main.tscn::coin"
#
# Nur fuer Nodes die FEST in einer Szene platziert sind -- zur Laufzeit
# gespawnte Nodes haben automatisch generierte Namen, die nicht stabil sind.
# =============================================================================
func get_persistent_id(node: Node) -> String:
	var scene = get_tree().current_scene
	if scene == null:
		return ""
	return scene.scene_file_path + "::" + node.name
