# =============================================================================
# checkpoint.gd
# =============================================================================
# Checkpoint (Area2D).
#
# Beruehrt der Spieler diese Fahne, wird sie zum neuen Respawn-Punkt: Stirbt
# er danach, taucht er HIER wieder auf statt am Levelanfang. Das nimmt
# laengeren Passagen den Frust und haelt den Flow am Laufen.
#
# Technisch wird einfach die spawn_position des Spielers ueberschrieben --
# player.respawn() nutzt genau diese Variable. Der Checkpoint muss also gar
# nichts ueber den Respawn-Vorgang selbst wissen.
#
# Verwendung: Diese Szene an sinnvollen Stellen im Level platzieren
# (vor schweren Sprung-Passagen, nach einem Gegner-Pulk ...).
#
# Schwierigkeit: [EINSTEIGER] -- setzt nur eine Variable auf dem Spieler.
# =============================================================================

extends Area2D

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  DEIN SPIELFELD – im Inspector einstellbar:                             ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
@export var active_color: Color = Color(0.3, 0.9, 0.4)    # Fahne wenn aktiviert
@export var inactive_color: Color = Color(0.5, 0.5, 0.55) # Fahne im Ausgangszustand

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var _flag: Polygon2D = $Flag
@onready var _sound: AudioStreamPlayer2D = $Sound

# Schon aktiviert? Dann nicht erneut ausloesen (kein wiederholter Sound).
var _activated := false

# =============================================================================
# _ready()
# Faerbt die Fahne in den Ausgangszustand und verbindet das Signal.
# =============================================================================
func _ready() -> void:
	_flag.color = inactive_color
	body_entered.connect(_on_body_entered)

# =============================================================================
# _on_body_entered(body)
# Setzt den Respawn-Punkt des Spielers auf diese Position.
# =============================================================================
func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	# Nur der Spieler hat eine spawn_position -- so kracht es nicht, wenn z. B.
	# ein Gegner die Fahne beruehrt.
	if body.is_in_group("player") and "spawn_position" in body:
		body.spawn_position = global_position
		_activated = true
		_flag.color = active_color
		_sound.play()
