# =============================================================================
# landing_dust.gd
# =============================================================================
# Staubpartikel beim Landen. Drag&Drop als Kind des Spielers
# (CharacterBody2D) in player.tscn.
#
# Aufbau:
#   player.tscn
#   └── CharacterBody2D (Spieler-Root)
#       └── LandungStaub   <- hierhin ziehen
#
# Loest automatisch einen Partikel-Burst aus, sobald der Spieler mit genug
# Schwung auf dem Boden landet. Mindestgeschwindigkeit einstellbar.
# =============================================================================
extends CPUParticles2D

@export var mindest_geschwindigkeit := 150.0  ## Probier: 0 (immer) bis 350 (nur bei starkem Aufprall)

var _spieler:     CharacterBody2D
var _war_in_luft  := false
var _letzte_y_v   := 0.0

func _ready() -> void:
	emitting = false
	one_shot  = true
	_spieler  = get_parent() as CharacterBody2D

func _process(_delta: float) -> void:
	if _spieler == null:
		return
	var auf_boden := _spieler.is_on_floor()
	# Landung erkannt: vorherige Fallgeschwindigkeit >= Schwellwert nutzen,
	# weil velocity.y nach move_and_slide() bereits 0 ist.
	if _war_in_luft and auf_boden and _letzte_y_v >= mindest_geschwindigkeit:
		emitting = true
	_war_in_luft = not auf_boden
	if not auf_boden:
		_letzte_y_v = _spieler.velocity.y
