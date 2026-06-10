# =============================================================================
# splash.gd
# =============================================================================
# Intro-Bildschirm ("Studio-Logo") – das Erste, was beim Spielstart erscheint.
# Zeigt das "Sobe Game Studio"-Logo fuer ein paar Sekunden und wechselt
# danach automatisch ins Hauptmenue.
#
# Diese Szene ist als Start-Szene eingetragen:
#   Projekt > Projekteinstellungen > Anwendung > Ausfuehren > Hauptszene
#
# Tipp zum Aendern: Mit "anzeige_dauer" stellst du im Inspector ein,
# wie lange das Logo zu sehen ist.
# =============================================================================
extends Control

## Pfad zum Hauptmenue, das nach dem Logo erscheint.
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

## Wie viele Sekunden das Logo gezeigt wird, bevor das Menue kommt.
## Groesser = laenger sichtbar. Im Inspector einstellbar.
@export var anzeige_dauer: float = 2.5

# Merkt sich, ob wir schon weitergeschaltet haben (damit es nur einmal passiert).
var _fertig: bool = false


func _ready() -> void:
	# Nach "anzeige_dauer" Sekunden automatisch ins Hauptmenue wechseln.
	get_tree().create_timer(anzeige_dauer).timeout.connect(_weiter)


func _unhandled_input(event: InputEvent) -> void:
	# Wer nicht warten will: Taste druecken oder klicken ueberspringt das Logo.
	var taste := event is InputEventKey and event.pressed
	var klick := event is InputEventMouseButton and event.pressed
	if taste or klick:
		_weiter()


func _weiter() -> void:
	# Sicherstellen, dass der Wechsel nur ein einziges Mal ausgeloest wird.
	if _fertig:
		return
	_fertig = true
	get_tree().change_scene_to_file(MENU_SCENE)
