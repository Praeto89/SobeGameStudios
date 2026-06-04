extends PointLight2D
## Laesst ein 2D-Licht "leben": entweder ein zufaelliges Fackel-Flackern
## (fuer die Spieler-Laterne) oder ein ruhiges Pulsieren (fuer Portale
## und leuchtende Pickups).
##
## Anhaengen an: einen PointLight2D-Knoten.
## Schwierigkeit: [EINSTEIGER]
##
## Probier es: drehe im Inspector an "staerke" und "tempo" und schau,
## wie sich die Stimmung aendert.

# Zwei Betriebsarten - im Inspector als Dropdown auswaehlbar.
enum Modus { FLACKERN, PULSIEREN }

@export var modus: Modus = Modus.FLACKERN
## Wie stark die Helligkeit schwankt (0 = aus, 0.3 = deutlich sichtbar).
@export var staerke: float = 0.22
## Geschwindigkeit der Schwankung (hoeher = nervoeser/schneller).
@export var tempo: float = 8.0

# Wird in _ready() aus der im Editor gesetzten Helligkeit uebernommen,
# damit jedes Licht seinen eigenen Grundwert behaelt.
var _basis_energie: float = 1.0
var _zeit: float = 0.0
var _ziel_energie: float = 1.0


func _ready() -> void:
	_basis_energie = energy
	_ziel_energie = energy


func _process(delta: float) -> void:
	_zeit += delta * tempo

	if modus == Modus.PULSIEREN:
		# Gleichmaessiges Atmen: ein sauberer Sinus um den Grundwert.
		energy = _basis_energie + sin(_zeit) * staerke
	else:
		# Fackel: ab und zu ein neues Helligkeits-Ziel auswuerfeln und
		# weich dorthin gleiten -> wirkt wie eine zuckende Flamme.
		if randf() < delta * tempo:
			_ziel_energie = _basis_energie + randf_range(-staerke, staerke)
		energy = lerp(energy, _ziel_energie, delta * 12.0)
