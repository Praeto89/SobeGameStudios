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
# Ability-Upgrades (im weissen Upgrade-Tor gekauft)
# -------------------------------------------------------
# Im "Upgrade-Tor" (scenes/world/upgrade_gate.tscn) kann der Spieler gesammelte
# Muenzen gegen dauerhaft staerkere Abilities eintauschen. Jedes Upgrade ist
# EINMAL kaufbar (Festpreis). Die Flags ueberleben -- genau wie die has_*-Flags
# -- den Szenenwechsel, weil der GameManager als Autoload am Leben bleibt.
var upgrade_charge: bool = false    # Charge-Dash: schneller & laenger
var upgrade_jump: bool = false      # Sprung: hoeher
var upgrade_health: bool = false    # Leben: +HEALTH_UPGRADE_BONUS Herzen
var upgrade_attack: bool = false    # Attacke: groessere & weiter reichende Hitbox

# Festpreis je Upgrade in Muenzen. Schluessel = Upgrade-Name (siehe upgrade_gate.gd).
const UPGRADE_COSTS := {
	"charge": 8,
	"jump": 6,
	"health": 10,
	"attack": 8,
}

# Wie viele zusaetzliche Herzen das Health-Upgrade gewaehrt.
const HEALTH_UPGRADE_BONUS: int = 2

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
# get_max_health()
# Effektives Lebens-Maximum: Basis (MAX_HEALTH) plus Bonus, wenn das
# Health-Upgrade im Tor gekauft wurde. Eine Quelle der Wahrheit fuer Player
# (max_health) und HUD (Anzahl der Klingen-Segmente).
# =============================================================================
func get_max_health() -> int:
	return MAX_HEALTH + (HEALTH_UPGRADE_BONUS if upgrade_health else 0)

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

# =============================================================================
# reset_game()
# Setzt den kompletten Session-Zustand auf die Startwerte zurueck:
# Abilities, Leben, Muenzen sowie alle eingesammelten/besiegten Marker.
# Aufrufen, bevor ein frisches Spiel gestartet wird (z. B. aus einem
# Start-/Game-Over-Menue oder per "Neu starten").
# =============================================================================
func reset_game() -> void:
	came_from_portal_id = ""
	has_charge = false
	has_wallcrawl = false
	has_double_jump = false
	upgrade_charge = false
	upgrade_jump = false
	upgrade_health = false
	upgrade_attack = false
	current_health = MAX_HEALTH
	coin_count = 0
	collected_coin_ids.clear()
	defeated_enemy_ids.clear()
	visited_scenes.clear()
