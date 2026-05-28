# =============================================================================
# green_platform_vertikal.gd
# =============================================================================
# Vertikal bewegliche Plattform (AnimatableBody2D).
#
# Funktioniert identisch zu green_platform.gd, aber bewegt sich auf der
# Y-Achse (auf und ab) statt auf der X-Achse (links und rechts).
#
# Wichtig: extends AnimatableBody2D + Bewegung in _physics_process, damit
# der Spieler beim Draufstehen mit der Plattform mitfaehrt.
#
# Die Plattform pendelt gleichmaessig zwischen zwei Punkten:
#   Startposition - distance  <-->  Startposition + distance
# =============================================================================

extends AnimatableBody2D

# -----------------------------------------------------------------------------
# Export-Variablen (im Godot-Editor einstellbar)
# -----------------------------------------------------------------------------
@export var speed := 100.0      # Bewegungsgeschwindigkeit in Pixel/Sekunde
@export var distance := 30.0    # Maximale Entfernung von der Startposition in Pixeln

# -----------------------------------------------------------------------------
# Interne Variablen
# -----------------------------------------------------------------------------
var start_y := 0.0              # Y-Position beim Start (wird als Mittelpunkt verwendet)
var direction := 1              # Aktuelle Richtung: 1 = nach unten, -1 = nach oben

# =============================================================================
# _ready()
# Speichert die Startposition als Mittelpunkt der Pendelbewegung.
# =============================================================================
func _ready():
	start_y = position.y

# =============================================================================
# _physics_process(delta)
# Bewegt die Plattform vertikal und kehrt die Richtung um wenn die Grenze erreicht wird.
# Position-Aenderung muss im Physik-Tick passieren, damit der Spieler
# (CharacterBody2D) korrekt mitgenommen wird.
# =============================================================================
func _physics_process(delta):
	position.y += speed * direction * delta

	# Richtung umkehren wenn Grenzwert ueberschritten
	if abs(position.y - start_y) > distance:
		direction *= -1
