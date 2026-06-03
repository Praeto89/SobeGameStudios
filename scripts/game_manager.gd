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

# Pfad der zuletzt aktiv gespielten Level-Szene. Wird vom Spieler in _ready()
# gesetzt und mitgespeichert, damit "Fortsetzen" im Menue wieder im richtigen
# Level landet.
var current_scene: String = ""

# -------------------------------------------------------
# Coin-Combo (nur fuer das "Juice"-Feedback beim Sammeln)
# -------------------------------------------------------
# Sammelst du mehrere Muenzen schnell hintereinander, steigt die Tonhoehe
# des Sammel-Sounds -- ein kleiner, eskalierender Belohnungsreiz. Dieser
# Zustand ist bewusst NICHT teil des Speicherstands (rein kosmetisch).
const _COIN_COMBO_WINDOW_MSEC: int = 1200   # Zeitfenster fuer "schnell hintereinander"
const _COIN_PITCH_STEP: float = 0.08        # Tonhoehen-Zuwachs pro Combo-Stufe
const _COIN_PITCH_MAX_STEPS: int = 12       # Deckel, damit es nicht schrill wird
var _coin_combo: int = 0
var _last_coin_msec: int = 0

# -------------------------------------------------------
# Speicherstand auf der Festplatte
# -------------------------------------------------------
# user:// ist Godots plattformunabhaengiger, beschreibbarer Ordner.
const SAVE_PATH: String = "user://savegame.json"

# -------------------------------------------------------
# Persistente Welt-Aenderungen
# -------------------------------------------------------
# IDs der Coins die bereits eingesammelt wurden (Format siehe get_persistent_id).
var collected_coin_ids: Array[String] = []
# IDs der Gegner die bereits besiegt wurden.
var defeated_enemy_ids: Array[String] = []
# IDs der Gates (z. B. Charge-Mauern), die bereits aufgebrochen wurden.
# Ein aufgebrochenes Gate bleibt fuer den Rest der Session offen -- so fuehlt
# sich die Welt dauerhaft veraendert an (Metroidvania-Prinzip).
var opened_gate_ids: Array[String] = []
# Szenen-Pfade die der Spieler in dieser Session betreten UND wieder verlassen hat.
# Wird vom portal.gd befuellt wenn ein Portal in die Galerie fuehrt.
# Die Galerie liest diese Liste in galerie.gd, um ⭐-Sticker an besuchten
# Slot-Portalen anzuzeigen.
var visited_scenes: Array[String] = []

# =============================================================================
# _ready()
# Laedt beim Spielstart einen evtl. vorhandenen Speicherstand. So ueberleben
# Abilities, Muenzen und geoeffnete Gates auch ein komplettes Beenden und
# Neustarten des Spiels (nicht nur einen Szenen-Wechsel).
# =============================================================================
func _ready() -> void:
	load_game()

# =============================================================================
# _notification(what)
# Faengt das Schliessen des Fensters ab und speichert vorher automatisch.
# So geht zum Beenden gesammelter Fortschritt nicht verloren.
# =============================================================================
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

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
	current_health = MAX_HEALTH
	coin_count = 0
	current_scene = ""
	collected_coin_ids.clear()
	defeated_enemy_ids.clear()
	opened_gate_ids.clear()
	visited_scenes.clear()
	_coin_combo = 0
	_last_coin_msec = 0

# =============================================================================
# next_coin_pitch()
# Liefert die Tonhoehe (pitch_scale) fuer den naechsten Muenz-Sound und
# aktualisiert dabei die Combo. Schnell hintereinander gesammelte Muenzen
# klingen hoeher -- ein kleiner eskalierender Belohnungsreiz. Reisst die
# Kette ab (laenger als _COIN_COMBO_WINDOW_MSEC), faengt sie wieder unten an.
# =============================================================================
func next_coin_pitch() -> float:
	var now := Time.get_ticks_msec()
	if now - _last_coin_msec <= _COIN_COMBO_WINDOW_MSEC:
		_coin_combo += 1
	else:
		_coin_combo = 0
	_last_coin_msec = now
	var steps := min(_coin_combo, _COIN_PITCH_MAX_STEPS)
	return 1.0 + steps * _COIN_PITCH_STEP

# =============================================================================
# save_game(path) / load_game(path)
# Schreiben bzw. lesen den Spielstand als JSON in user://. Der Pfad ist
# parametrierbar (Default SAVE_PATH) -- das erlaubt isolierte Tests auf einen
# Temp-Pfad, ohne den echten Spielstand anzufassen.
#
# Gespeichert wird nur der bedeutungstragende Fortschritt; rein transiente
# Werte (came_from_portal_id, Coin-Combo) bleiben bewusst draussen.
# =============================================================================
func save_game(path: String = SAVE_PATH) -> void:
	var data := {
		"has_charge": has_charge,
		"has_wallcrawl": has_wallcrawl,
		"has_double_jump": has_double_jump,
		"current_health": current_health,
		"coin_count": coin_count,
		"current_scene": current_scene,
		"collected_coin_ids": collected_coin_ids,
		"defeated_enemy_ids": defeated_enemy_ids,
		"opened_gate_ids": opened_gate_ids,
		"visited_scenes": visited_scenes,
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("save_game: konnte '%s' nicht schreiben (Fehler %d)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

# Gibt true zurueck, wenn ein Speicherstand gefunden und geladen wurde.
func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("load_game: konnte '%s' nicht lesen (Fehler %d)" % [path, FileAccess.get_open_error()])
		return false
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("load_game: '%s' ist kein gueltiger Speicherstand" % path)
		return false
	has_charge = data.get("has_charge", false)
	has_wallcrawl = data.get("has_wallcrawl", false)
	has_double_jump = data.get("has_double_jump", false)
	current_health = int(data.get("current_health", MAX_HEALTH))
	coin_count = int(data.get("coin_count", 0))
	current_scene = str(data.get("current_scene", ""))
	# Arrays einzeln uebernehmen, damit die String-Typisierung erhalten bleibt
	# (JSON liefert untypisierte Arrays zurueck).
	_load_string_array(collected_coin_ids, data.get("collected_coin_ids", []))
	_load_string_array(defeated_enemy_ids, data.get("defeated_enemy_ids", []))
	_load_string_array(opened_gate_ids, data.get("opened_gate_ids", []))
	_load_string_array(visited_scenes, data.get("visited_scenes", []))
	return true

# Hilfsfunktion: leert ein typisiertes String-Array und fuellt es aus einer
# (untypisierten) Quelle neu -- so bleibt der Array[String]-Typ intakt.
func _load_string_array(target: Array[String], source) -> void:
	target.clear()
	if source is Array:
		for item in source:
			target.append(str(item))

# =============================================================================
# has_save_file() / delete_save()
# Kleine Helfer fuers Menue: gibt es einen Spielstand (-> "Fortsetzen"
# anbieten)? Und ein hartes Loeschen fuer "Neues Spiel".
# =============================================================================
func has_save_file(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

func delete_save(path: String = SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
