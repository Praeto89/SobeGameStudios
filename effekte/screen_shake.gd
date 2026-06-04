# =============================================================================
# screen_shake.gd
# =============================================================================
# Kamera-Shake-Effekt. Drag&Drop als Kind von Camera2D in player.tscn.
#
# Verbindet sich automatisch mit dem Spieler-Schadenssignal und schüttelt
# die Kamera bei jedem Treffer. Kann auch manuell per shake() aufgerufen werden.
#
# Aufbau:
#   player.tscn
#   └── Camera2D
#       └── ScreenShake   <- hierhin ziehen
#
# Alternativ auch als Kind in einer Level-Szene nutzbar (findet Kamera dann
# per Gruppe "kamera" – dafuer muss Camera2D in diese Gruppe eingetragen sein).
# =============================================================================
extends Node

@export var standard_staerke := 4.0   ## Probier: 1 (sanft) bis 12 (heftig)
@export var standard_dauer   := 0.25  ## Probier: 0.1 (kurz) bis 0.6 (lang)

var _betrag := 0.0
var _kamera: Camera2D
var _letztes_leben := -1

func _ready() -> void:
	# Direkt als Kind der Kamera? -> sofort verwenden
	if get_parent() is Camera2D:
		_kamera = get_parent()

	# 1 Frame warten, damit alle anderen Nodes bereit sind
	await get_tree().process_frame

	# Kamera noch nicht gefunden? -> per Gruppe suchen
	if _kamera == null:
		_kamera = get_tree().get_first_node_in_group("kamera") as Camera2D

	# Automatisch mit Spieler-Schadenssignal verbinden
	var spieler = get_tree().get_first_node_in_group("spieler")
	if spieler and spieler.has_signal("health_changed"):
		spieler.health_changed.connect(_on_leben_geaendert)
		if "current_health" in spieler:
			_letztes_leben = spieler.current_health

# Shake von außen auslösen (z. B. bei Explosion, Boss-Attack, ...)
func shake(staerke: float = standard_staerke, dauer: float = standard_dauer) -> void:
	_betrag = staerke
	create_tween().tween_property(self, "_betrag", 0.0, dauer)

func _on_leben_geaendert(neues_leben: int) -> void:
	if neues_leben < _letztes_leben:
		shake()
	_letztes_leben = neues_leben

func _process(_delta: float) -> void:
	if _kamera == null:
		return
	if _betrag < 0.1:
		_kamera.offset = Vector2.ZERO
		return
	_kamera.offset = Vector2(
		randf_range(-_betrag, _betrag),
		randf_range(-_betrag, _betrag)
	)
