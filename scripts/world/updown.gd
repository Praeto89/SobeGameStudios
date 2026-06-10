extends AnimatableBody2D

enum StartRichtung { OBEN, UNTEN }

@export_category("Plattform Einstellungen")
# Hier stellt man ein, ob die Plattform ZUERST nach oben oder nach unten fliegen soll
@export var start_richtung: StartRichtung = StartRichtung.OBEN

# Wie weit fliegt sie von ihrer Startposition weg?
@export var distanz: float = 200.0

# Wie schnell ist sie?
@export var geschwindigkeit: float = 100.0

var start_position: Vector2
var ziel_position: Vector2
var fliege_zu_ziel: bool = true

func _ready():
	# Die Mitte/Startposition, wo sie im Editor platziert wurde
	start_position = global_position
	
	# Berechnet das Ziel basierend auf der Auswahl im Inspector
	if start_richtung == StartRichtung.OBEN:
		ziel_position = start_position + Vector2(0, -distanz) # -Y ist oben
	else:
		ziel_position = start_position + Vector2(0, distanz)  # +Y ist unten

func _physics_process(delta):
	if fliege_zu_ziel:
		global_position = global_position.move_toward(ziel_position, geschwindigkeit * delta)
		if global_position.distance_to(ziel_position) < 0.1:
			fliege_zu_ziel = false
	else:
		global_position = global_position.move_toward(start_position, geschwindigkeit * delta)
		if global_position.distance_to(start_position) < 0.1:
			fliege_zu_ziel = true
