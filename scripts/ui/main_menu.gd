# =============================================================================
# main_menu.gd
# =============================================================================
# Hauptmenue – der erste Bildschirm, den der Spieler beim Start sieht.
#
# Buttons:
#   - Neues Spiel -> setzt den Spielstand zurueck und startet das erste Level
#   - Fortsetzen   -> laedt den gespeicherten Stand und springt ins letzte Level
#   - Abspann      -> zeigt den Abspann (Credits)
#   - Beenden      -> schliesst das Spiel
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
@onready var _logo: TextureRect = $CenterContainer/VBoxContainer/Logo
@onready var _play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var _continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var _credits_button: Button = $CenterContainer/VBoxContainer/CreditsButton
@onready var _quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	# Jeden Button mit seiner Funktion verbinden.
	_play_button.pressed.connect(_on_play_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	# "Fortsetzen" nur anbieten, wenn es ueberhaupt einen Speicherstand gibt.
	# Ohne Save bleibt der Knopf sichtbar, ist aber ausgegraut und nicht fokussierbar.
	var save_exists := GameManager.has_save()
	_continue_button.disabled = not save_exists
	_continue_button.focus_mode = Control.FOCUS_ALL if save_exists else Control.FOCUS_NONE
	# Tastatur-/Gamepad-Fokus auf den sinnvollsten Button legen,
	# damit man das Menue auch ohne Maus bedienen kann.
	if save_exists:
		_continue_button.grab_focus()
	else:
		_play_button.grab_focus()
	# Den Studio-Schriftzug animiert auftauchen lassen.
	_logo_animieren()


# =============================================================================
# _logo_animieren()
# Laesst den Schriftzug einblenden, kurz "aufploppen" und danach sanft atmen.
# =============================================================================
func _logo_animieren() -> void:
	# Drehpunkt in die Mitte legen, damit das Logo zentriert waechst.
	_logo.pivot_offset = _logo.custom_minimum_size / 2.0
	# Startzustand: noch unsichtbar und etwas kleiner.
	_logo.modulate.a = 0.0
	_logo.scale = Vector2(0.6, 0.6)

	# Auftauchen: gleichzeitig einblenden UND mit kleinem "Pop" gross werden.
	var intro := create_tween()
	intro.set_parallel(true)
	intro.tween_property(_logo, "modulate:a", 1.0, 0.5)
	intro.tween_property(_logo, "scale", Vector2.ONE, 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Danach dezentes Dauer-"Atmen".
	intro.finished.connect(_atmen_starten)


# Leichtes, endloses Pulsieren – der Schriftzug wirkt dadurch "lebendig".
func _atmen_starten() -> void:
	var puls := create_tween().set_loops()
	puls.tween_property(_logo, "scale", Vector2(1.04, 1.04), 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	puls.tween_property(_logo, "scale", Vector2.ONE, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_play_pressed() -> void:
	# Frischer Spielstart: Abilities, Leben, Muenzen usw. zuruecksetzen.
	GameManager.reset_game()
	# Sofort speichern, damit "Fortsetzen" auf den frischen Start zeigt (und nicht
	# auf einen alten, schon abgeschlossenen Spielstand).
	GameManager.save_game(LEVEL_SCENE)
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _on_continue_pressed() -> void:
	# Gespeicherten Stand laden und in die zuletzt besuchte Szene springen.
	if not GameManager.load_game():
		return
	var scene := GameManager.get_saved_scene()
	if scene == "":
		scene = LEVEL_SCENE
	get_tree().change_scene_to_file(scene)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
