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
# Faehigkeiten & Upgrades – EIN Stufen-System
# -------------------------------------------------------
# Der Charakter startet "nackt": ausser der normalen Boden-Attacke besitzt er
# keine Faehigkeit. Im Upgrade-Tor (scenes/world/upgrade_gate.tscn) kauft er mit
# Gold (= gesammelte Muenzen) Faehigkeiten frei und steigert sie danach.
#
# Jede Spur hat Stufen 0..MAX_ABILITY_LEVEL:
#   0 = nicht gekauft (Faehigkeit gesperrt bzw. keine Verbesserung)
#   1 = gekauft -> ABGESCHWAECHTE erste Version
#   2 = einmal verbessert
#   3 = voll ausgebaut
#
# Die Werte ueberleben Szenen-Wechsel, weil der GameManager als Autoload lebt.
# Der Player liest die Stufen in apply_upgrades() und rechnet daraus seine
# effektiven Werte aus.
const MAX_ABILITY_LEVEL: int = 3

var ability_levels := {
	"attack":      0,   # Boden-Attacke (Basis gratis) – Stufen vergroessern Reichweite/Hitbox
	"attack_air":  0,   # Luft-Attacke (Sturzschlag + Schockwelle)
	"dash":        0,   # Roll/Dash (SHIFT)
	"charge":      0,   # Charge-Dash (E halten)
	"wallcrawl":   0,   # Wandklettern + Wall Jump
	"double_jump": 0,   # Doppelsprung
	"jump":        0,   # Hoeherer Sprung
	"health":      0,   # Extra-Herzen
}

# Festpreise je Spur und Stufe (Index 0 = Sprung auf Stufe 1, usw.).
# Stufe 1 ist bewusst guenstig, damit der "nackte" Start schnell eine erste
# Faehigkeit erlaubt.
const ABILITY_COSTS := {
	"attack":      [4, 8, 12],
	"attack_air":  [6, 10, 14],
	"dash":        [4, 7, 11],
	"charge":      [6, 10, 15],
	"wallcrawl":   [6, 10, 15],
	"double_jump": [7, 11, 16],
	"jump":        [5, 9, 13],
	"health":      [8, 12, 18],
}

# Wie viele zusaetzliche Herzen JEDE Health-Stufe gewaehrt.
const HEALTH_UPGRADE_BONUS: int = 2

# -------------------------------------------------------
# Backward-compatible has_*-Eigenschaften
# -------------------------------------------------------
# Pickups, Player und Cheat-Buttons fragen weiterhin GameManager.has_charge ab
# (oder setzen es). Diese Eigenschaften spiegeln einfach die jeweilige Stufe:
#   lesen   -> true, sobald Stufe >= 1 (Faehigkeit freigeschaltet)
#   setzen  -> true hebt auf mindestens Stufe 1 (= abgeschwaechte erste Version),
#              false sperrt die Faehigkeit wieder (Stufe 0).
var has_attack_air: bool:
	get: return ability_levels["attack_air"] >= 1
	set(v): _set_unlocked("attack_air", v)
var has_dash: bool:
	get: return ability_levels["dash"] >= 1
	set(v): _set_unlocked("dash", v)
var has_charge: bool:
	get: return ability_levels["charge"] >= 1
	set(v): _set_unlocked("charge", v)
var has_wallcrawl: bool:
	get: return ability_levels["wallcrawl"] >= 1
	set(v): _set_unlocked("wallcrawl", v)
var has_double_jump: bool:
	get: return ability_levels["double_jump"] >= 1
	set(v): _set_unlocked("double_jump", v)

func _set_unlocked(key: String, value: bool) -> void:
	if value:
		ability_levels[key] = max(ability_levels[key], 1)
	else:
		ability_levels[key] = 0

# =============================================================================
# get_level(key) / can_upgrade(key) / get_next_cost(key) / add_level(key)
# Kleine Helfer rund um das Stufen-System. Eine Quelle der Wahrheit fuer
# Upgrade-Tor (Anzeige/Kauf) und Player (effektive Werte).
# =============================================================================
func get_level(key: String) -> int:
	return ability_levels.get(key, 0)

func can_upgrade(key: String) -> bool:
	return get_level(key) < MAX_ABILITY_LEVEL

## Preis fuer die NAECHSTE Stufe; -1 wenn bereits voll ausgebaut.
func get_next_cost(key: String) -> int:
	var lvl := get_level(key)
	if lvl >= MAX_ABILITY_LEVEL:
		return -1
	return ABILITY_COSTS[key][lvl]

## Hebt die Spur um eine Stufe (bis MAX_ABILITY_LEVEL). Gibt die neue Stufe zurueck.
func add_level(key: String) -> int:
	if can_upgrade(key):
		ability_levels[key] += 1
	return get_level(key)

# -------------------------------------------------------
# Persistenter Spieler-Zustand
# -------------------------------------------------------
const MAX_HEALTH: int = 4
var current_health: int = MAX_HEALTH
var coin_count: int = 0

# -------------------------------------------------------
# Speicherstand (Save-Game)
# -------------------------------------------------------
# Der komplette Fortschritt wird in eine Datei im Nutzer-Verzeichnis
# geschrieben (user:// liegt je nach Betriebssystem z. B. unter
# %APPDATA%/Godot bzw. ~/.local/share/godot). So bleibt alles erhalten,
# auch wenn das Spiel geschlossen wird. Das Hauptmenue bietet darueber den
# "Fortsetzen"-Knopf an.
const SAVE_PATH := "user://savegame.cfg"
## Szene, in der der Spieler zuletzt war -- der "Fortsetzen"-Knopf laedt sie.
var current_scene_path: String = ""

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
# Effektives Lebens-Maximum: Basis (MAX_HEALTH) plus Bonus je gekaufter
# Health-Stufe. Eine Quelle der Wahrheit fuer Player (max_health) und HUD
# (Anzahl der Klingen-Segmente).
# =============================================================================
func get_max_health() -> int:
	return MAX_HEALTH + HEALTH_UPGRADE_BONUS * get_level("health")

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
# Faehigkeiten/Upgrades, Leben, Muenzen sowie alle eingesammelten/besiegten
# Marker. Aufrufen, bevor ein frisches Spiel gestartet wird (z. B. aus einem
# Start-/Game-Over-Menue oder per "Neu starten").
# =============================================================================
func reset_game() -> void:
	came_from_portal_id = ""
	current_scene_path = ""
	for key in ability_levels.keys():
		ability_levels[key] = 0
	current_health = MAX_HEALTH
	coin_count = 0
	collected_coin_ids.clear()
	defeated_enemy_ids.clear()
	visited_scenes.clear()

# =============================================================================
# save_game(scene_path)
# Schreibt den kompletten Session-Zustand in die Save-Datei (SAVE_PATH).
# Wird automatisch beim Levelwechsel (portal.gd) und an Checkpoints aufgerufen,
# damit der Fortschritt ohne Zutun des Spielers erhalten bleibt.
#
# scene_path: Pfad der Szene, in der man sich befindet. Leer lassen, dann wird
#             die aktuell laufende Szene verwendet.
# =============================================================================
func save_game(scene_path: String = "") -> void:
	if scene_path != "":
		current_scene_path = scene_path
	elif get_tree() != null and get_tree().current_scene != null:
		current_scene_path = get_tree().current_scene.scene_file_path

	var cfg := ConfigFile.new()
	cfg.set_value("player", "current_health", current_health)
	cfg.set_value("player", "coin_count", coin_count)
	cfg.set_value("abilities", "levels", ability_levels)
	cfg.set_value("world", "collected_coin_ids", collected_coin_ids)
	cfg.set_value("world", "defeated_enemy_ids", defeated_enemy_ids)
	cfg.set_value("world", "visited_scenes", visited_scenes)
	cfg.set_value("world", "scene_path", current_scene_path)
	cfg.save(SAVE_PATH)

# =============================================================================
# has_save() -> bool
# True wenn eine Save-Datei existiert (steuert, ob "Fortsetzen" anwaehlbar ist).
# =============================================================================
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# =============================================================================
# load_game() -> bool
# Laedt den gespeicherten Zustand zurueck in den GameManager. Gibt true zurueck,
# wenn erfolgreich. Danach kann das Hauptmenue in die gespeicherte Szene wechseln
# (siehe get_saved_scene) -- der Player liest die Werte beim naechsten _ready().
# =============================================================================
func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	current_health = int(cfg.get_value("player", "current_health", MAX_HEALTH))
	coin_count = int(cfg.get_value("player", "coin_count", 0))
	var saved_levels: Dictionary = cfg.get_value("abilities", "levels", {})
	for key in ability_levels.keys():
		ability_levels[key] = int(saved_levels.get(key, 0))
	collected_coin_ids = _to_string_array(cfg.get_value("world", "collected_coin_ids", []))
	defeated_enemy_ids = _to_string_array(cfg.get_value("world", "defeated_enemy_ids", []))
	visited_scenes = _to_string_array(cfg.get_value("world", "visited_scenes", []))
	current_scene_path = str(cfg.get_value("world", "scene_path", ""))
	# Frisch geladen: nicht "aus einem Portal kommend" -- sonst wuerde der Spieler
	# beim Laden an eine alte Portal-Position teleportiert.
	came_from_portal_id = ""
	return true

## Pfad der zuletzt gespeicherten Szene (fuer den "Fortsetzen"-Knopf).
func get_saved_scene() -> String:
	return current_scene_path

# Hilfsfunktion: macht aus einer (untypisierten) ConfigFile-Array eine
# typisierte Array[String], wie die Felder oben sie erwarten.
func _to_string_array(arr) -> Array[String]:
	var out: Array[String] = []
	if arr is Array:
		for v in arr:
			out.append(str(v))
	return out
