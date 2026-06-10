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
# "ScrollContent" enthaelt das Studio-Logo UND die Namen – beides wandert
# gemeinsam nach oben.
@onready var _content: VBoxContainer = $ScrollContent
@onready var _back_button: Button = $BackButton


func _ready() -> void:
	_back_button.pressed.connect(_back_to_menu)
	# Den Inhalt knapp unterhalb des sichtbaren Bereichs starten lassen,
	# damit er von unten ins Bild hineinwandert.
	_content.position.y = get_viewport_rect().size.y


func _process(delta: float) -> void:
	# Inhalt Bild fuer Bild ein kleines Stueck nach oben schieben.
	_content.position.y -= scroll_speed * delta
	# Ist alles oben aus dem Bild gewandert? -> zurueck ins Menue.
	# get_combined_minimum_size() liefert die echte Hoehe des Inhalts
	# (das normale "size" entspricht nur dem gesetzten Rechteck).
	var content_height := _content.get_combined_minimum_size().y
	if _content.position.y + content_height < 0.0:
		_back_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	# ESC / "Zurueck"-Taste bringt sofort zurueck ins Hauptmenue.
	if event.is_action_pressed("ui_cancel"):
		_back_to_menu()


func _back_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
