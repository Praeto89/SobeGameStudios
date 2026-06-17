# =============================================================================
# pause_menu.gd
# =============================================================================
# Pausenmenue als Overlay -- liegt als Autoload ("PauseMenu") ueber jedem Level
# und muss daher in keine einzelne Level-Szene eingebaut werden.
#
# Bedienung:
#   ESC (Aktion "ui_cancel")  -> Pause an/aus (nur in echten Leveln)
#   "Weiter"                  -> Spiel fortsetzen
#   "Hauptmenue"              -> zurueck ins Hauptmenue
#   Regler                    -> Lautstaerke (Gesamt/Musik/Effekte) live aendern
#
# Technik: Beim Pausieren wird get_tree().paused = true gesetzt. Damit dieses
# Overlay (und der AudioManager) trotzdem weiterlaufen, steht ihr process_mode
# auf ALWAYS. Die Knoepfe/Regler darunter erben das automatisch.
# =============================================================================
extends CanvasLayer

## Wohin "Hauptmenue" fuehrt.
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
## Pausieren ist nur in echten Leveln erlaubt (nicht in Menue-Szenen).
const LEVEL_PREFIX := "res://scenes/levels/"

@onready var _root: Control = $Root
@onready var _master_slider: HSlider = $Root/CenterContainer/VBoxContainer/MasterRow/MasterSlider
@onready var _music_slider: HSlider = $Root/CenterContainer/VBoxContainer/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $Root/CenterContainer/VBoxContainer/SfxRow/SfxSlider
@onready var _resume_button: Button = $Root/CenterContainer/VBoxContainer/ResumeButton
@onready var _menu_button: Button = $Root/CenterContainer/VBoxContainer/MenuButton

var _open := false      # ist das Menue gerade sichtbar?
var _syncing := false   # gerade Regler-Werte setzen (kein Klick-Feedback ausloesen)


func _ready() -> void:
	# Auch waehrend der Pause aktiv bleiben (sonst koennte man nichts klicken).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false

	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_resume_button.pressed.connect(_close)
	_menu_button.pressed.connect(_on_menu_pressed)


# ESC fangen wir global ab (funktioniert auch, waehrend das Spiel pausiert ist).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	if _open:
		_close()
	elif _can_pause():
		_open_menu()


# Nur in echten Leveln pausieren -- in Menues ergibt ESC keinen Sinn.
func _can_pause() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	return scene.scene_file_path.begins_with(LEVEL_PREFIX)


func _open_menu() -> void:
	_sync_sliders()
	get_tree().paused = true
	_root.visible = true
	_open = true
	_resume_button.grab_focus()


func _close() -> void:
	get_tree().paused = false
	_root.visible = false
	_open = false


func _on_menu_pressed() -> void:
	# Erst entpausieren, sonst startet die naechste Szene eingefroren.
	get_tree().paused = false
	_open = false
	_root.visible = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


# Regler auf die aktuell gespeicherten Lautstaerken stellen.
func _sync_sliders() -> void:
	_syncing = true
	_master_slider.value = AudioManager.get_volume(AudioManager.MASTER_BUS)
	_music_slider.value = AudioManager.get_volume(AudioManager.MUSIC_BUS)
	_sfx_slider.value = AudioManager.get_volume(AudioManager.SFX_BUS)
	_syncing = false


func _on_master_changed(value: float) -> void:
	AudioManager.set_volume(AudioManager.MASTER_BUS, value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_volume(AudioManager.MUSIC_BUS, value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_volume(AudioManager.SFX_BUS, value)
	if not _syncing:
		AudioManager.play_sfx("tap")  # kurzes Hoer-Feedback fuer den Effekt-Pegel
