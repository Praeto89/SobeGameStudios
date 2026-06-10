# =============================================================================
# vignette.gd
# =============================================================================
# Schadens-Vignette: dunkelt den Bildschirmrand ab und wird STAERKER, je weniger
# Leben der Spieler hat. Bei voller Gesundheit ist sie dezent, bei 1 Herz
# kraeftig -> der Spieler "spuert" Gefahr, ohne auf die Herzen schauen zu muessen.
#
# Andocken an: die Vignette-ColorRect (mit vignette.gdshader) -- siehe
# effekte/vignette.tscn. Per Drag&Drop ins Level ziehen; der Spieler
# muss in der Szene sein (Gruppe "player").
#
# Funktionsweise: Wir hoeren das health_changed-Signal des Spielers ab (genau
# wie das HUD, siehe README -> Signale) und setzen den Shader-Parameter
# "intensity" passend zur Restgesundheit.
#
# Schwierigkeit: [FORTGESCHRITTEN] -- Signal + Shader-Parameter steuern.
# =============================================================================

extends ColorRect

## Deckkraft am Rand bei NIEDRIGER Gesundheit (1 Herz).
@export var max_intensity := 0.7
## Deckkraft am Rand bei VOLLER Gesundheit (dezenter Grundschleier).
@export var ruhe_intensity := 0.12
## Sekunden, in denen die Vignette weich auf den neuen Wert gleitet.
@export var uebergang := 0.25

var _player: Node = null
var _tween: Tween = null

func _ready() -> void:
	# Spieler suchen (gleiches Muster wie slime_base.gd).
	_player = get_tree().get_first_node_in_group("player")
	if _player and _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_health_changed)
		# Startwert sofort setzen, sonst zeigt die Vignette kurz den Default.
		if "current_health" in _player:
			_set_intensity(_intensity_for(_player.current_health), true)

# =============================================================================
# _on_health_changed(new_health)
# Wird vom Spieler bei jeder Lebensaenderung gerufen.
# =============================================================================
func _on_health_changed(new_health: int) -> void:
	_set_intensity(_intensity_for(new_health), false)

# =============================================================================
# _intensity_for(health) -> float
# Rechnet Restgesundheit in eine Rand-Deckkraft um:
#   volle Gesundheit -> ruhe_intensity,  wenig Gesundheit -> max_intensity.
# =============================================================================
func _intensity_for(health: int) -> float:
	var maxh := 1
	if _player and "max_health" in _player:
		maxh = max(1, int(_player.max_health))
	var t := clamp(float(health) / float(maxh), 0.0, 1.0)
	# lerp(a, b, t): t=1 (voll) -> ruhe, t=0 (leer) -> max.
	return lerp(max_intensity, ruhe_intensity, t)

# =============================================================================
# _set_intensity(wert, sofort)
# Setzt den Shader-Parameter, optional weich per Tween.
# =============================================================================
func _set_intensity(wert: float, sofort: bool) -> void:
	if material == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	if sofort or uebergang <= 0.0:
		_apply_intensity(wert)
		return
	var von: float = material.get_shader_parameter("intensity")
	_tween = create_tween()
	# Der Tween ruft fuer jeden Zwischenwert _apply_intensity() auf und
	# laesst die Vignette so weich von "von" auf "wert" gleiten.
	_tween.tween_method(_apply_intensity, von, wert, uebergang)

# =============================================================================
# _apply_intensity(wert)
# Schreibt den Wert in den Shader-Parameter "intensity".
# Eigene kleine Funktion, damit der Tween sie direkt aufrufen kann.
# =============================================================================
func _apply_intensity(wert: float) -> void:
	if material:
		material.set_shader_parameter("intensity", wert)
