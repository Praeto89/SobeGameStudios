# =============================================================================
# main_menu.gd
# =============================================================================
# Hauptmenue – der erste Bildschirm, den der Spieler beim Start sieht.
#
# Buttons:
#   - Spielen  -> setzt den Spielstand zurueck und startet das erste Level
#   - Abspann  -> zeigt den Abspann (Credits)
#   - Beenden  -> schliesst das Spiel
#
# Diese Szene ist als Start-Szene eingetragen:
#   Projekt > Projekteinstellungen > Anwendung > Ausfuehren > Hauptszene
# =============================================================================
extends Control

## Pfad zum ersten Level, das der "Spielen"-Button startet.
const LEVEL_SCENE := "res://scenes/levels/main.tscn"
## Pfad zum Abspann.
const CREDITS_SCENE := "res://scenes/ui/credits.tscn"

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var _play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var _credits_button: Button = $CenterContainer/VBoxContainer/CreditsButton
@onready var _quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	# Jeden Button mit seiner Funktion verbinden.
	_play_button.pressed.connect(_on_play_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	# Tastatur-/Gamepad-Fokus auf den ersten Button legen,
	# damit man das Menue auch ohne Maus bedienen kann.
	_play_button.grab_focus()


func _on_play_pressed() -> void:
	# Frischer Spielstart: Abilities, Leben, Muenzen usw. zuruecksetzen.
	GameManager.reset_game()
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
