# =============================================================================
# green_platform.gd
# =============================================================================
# Horizontal bewegliche Plattform (Node2D).
#
# Die Plattform pendelt gleichmaessig links und rechts um ihre Startposition.
# Die maximale Entfernung und Geschwindigkeit sind im Editor einstellbar.
#
# Funktionsweise:
#   - Startposition wird in _ready() gespeichert
#   - In jedem Frame wird position.x veraendert
#   - Wenn die Entfernung von der Startposition groesser als "distance" wird,
#     kehrt sich die Richtung um
# =============================================================================

extends Node2D

# -----------------------------------------------------------------------------
# Export-Variablen (im Godot-Editor einstellbar)
# -----------------------------------------------------------------------------
@export var speed := 50.0       # Bewegungsgeschwindigkeit in Pixel/Sekunde
@export var distance := 45.0    # Maximale Entfernung von der Startposition in Pixeln

# -----------------------------------------------------------------------------
# Interne Variablen
# -----------------------------------------------------------------------------
var start_x := 0.0              # X-Position beim Start (wird als Mittelpunkt verwendet)
var direction := 1              # Aktuelle Richtung: 1 = rechts, -1 = links

# =============================================================================
# _ready()
# Speichert die Startposition als Mittelpunkt der Pendelbewegung.
# =============================================================================
func _ready():
	start_x = position.x

# =============================================================================
# _process(delta)
# Bewegt die Plattform und kehrt die Richtung um wenn die Grenze erreicht wird.
# =============================================================================
func _process(delta):
	position.x += speed * direction * delta

	# Richtung umkehren wenn Grenzwert ueberschritten
	if abs(position.x - start_x) > distance:
		direction *= -1
