# =============================================================================
# main_menu.gd
# =============================================================================
# Hauptmenue – der erste Bildschirm, den der Spieler beim Start sieht.
#
# Buttons:
#   - Fortsetzen  -> laedt den Spielstand und springt ins zuletzt gespielte Level
#                    (nur sichtbar, wenn ein Spielstand existiert)
#   - Neues Spiel -> loescht den Spielstand und startet frisch im ersten Level
#   - Abspann     -> zeigt den Abspann (Credits)
#   - Beenden     -> schliesst das Spiel
#
# Diese Szene ist als Start-Szene eingetragen:
#   Projekt > Projekteinstellungen > Anwendung > Ausfuehren > Hauptszene
# =============================================================================
extends Control

## Pfad zum ersten Level, das "Neues Spiel" startet.
## Aufstieg ist das Lehr-Level: ohne Abilities starten, beide Gates oeffnen,
## danach per Portal weiter ins Hauptlevel (main.tscn).
const LEVEL_SCENE := "res://scenes/levels/aufstieg.tscn"
## Pfad zum Abspann.
const CREDITS_SCENE := "res://scenes/ui/credits.tscn"

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var _continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var _play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var _credits_button: Button = $CenterContainer/VBoxContainer/CreditsButton
@onready var _quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	# Jeden Button mit seiner Funktion verbinden.
	_continue_button.pressed.connect(_on_continue_pressed)
	_play_button.pressed.connect(_on_new_game_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	# "Fortsetzen" nur anbieten, wenn es ueberhaupt einen Spielstand gibt.
	# Sonst waere der Button ein Sackgassen-Klick.
	var has_save := GameManager.has_save_file()
	_continue_button.visible = has_save
	# Fokus sinnvoll setzen: auf "Fortsetzen", falls vorhanden, sonst auf
	# "Neues Spiel" -- so ist das Menue auch ohne Maus bedienbar.
	if has_save:
		_continue_button.grab_focus()
	else:
		_play_button.grab_focus()


func _on_continue_pressed() -> void:
	# Spielstand laden und ins gemerkte Level springen. Fehlt der Pfad
	# (alter Spielstand ohne current_scene), faellt es aufs erste Level zurueck.
	GameManager.load_game()
	var target := GameManager.current_scene
	if target == "" or not ResourceLoader.exists(target):
		target = LEVEL_SCENE
	get_tree().change_scene_to_file(target)


func _on_new_game_pressed() -> void:
	# Frischer Spielstart: Spielstand loeschen und alles zuruecksetzen.
	GameManager.delete_save()
	GameManager.reset_game()
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
