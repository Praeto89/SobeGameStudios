# =============================================================================
# credits.gd
# =============================================================================
# Abspann (Credits) – die Namen laufen langsam von unten nach oben,
# wie im Kino.
#
# ACHTUNG: Die Texte sind aktuell nur PLATZHALTER. Zum Aendern einfach
# im Editor das "ScrollText"-Label anklicken und im Inspector unter
# "Text" die Namen eintragen.
#
# Zurueck ins Hauptmenue:
#   - per "Zurueck"-Button
#   - mit der ESC-Taste (Eingabe-Aktion "ui_cancel")
#   - automatisch, sobald der Text komplett durchgelaufen ist
# =============================================================================
extends Control

## Pfad zurueck zum Hauptmenue.
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

## Geschwindigkeit des Hochscrollens in Pixeln pro Sekunde.
## Groesser = schneller. Im Inspector einstellbar.
@export var scroll_speed: float = 40.0

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var _text: Label = $ScrollText
@onready var _back_button: Button = $BackButton


func _ready() -> void:
	_back_button.pressed.connect(_back_to_menu)
	# Den Text knapp unterhalb des sichtbaren Bereichs starten lassen,
	# damit er von unten ins Bild hineinwandert.
	_text.position.y = get_viewport_rect().size.y


func _process(delta: float) -> void:
	# Text Bild fuer Bild ein kleines Stueck nach oben schieben.
	_text.position.y -= scroll_speed * delta
	# Ist der gesamte Text oben aus dem Bild gewandert? -> zurueck ins Menue.
	# get_combined_minimum_size() liefert die echte Hoehe des Textinhalts
	# (das normale "size" entspricht nur dem gesetzten Rechteck).
	var text_height := _text.get_combined_minimum_size().y
	if _text.position.y + text_height < 0.0:
		_back_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	# ESC / "Zurueck"-Taste bringt sofort zurueck ins Hauptmenue.
	if event.is_action_pressed("ui_cancel"):
		_back_to_menu()


func _back_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
