# =============================================================================
# options_menu.gd
# =============================================================================
# Optionen-Bildschirm: drei Schieberegler fuer die Lautstaerke.
#   - Gesamt  (Master-Bus)
#   - Musik   (Music-Bus)
#   - Effekte (SFX-Bus)
#
# Die eigentliche Arbeit macht der AudioManager (Autoload): er setzt die
# Bus-Lautstaerke und speichert sie dauerhaft. Dieses Menue ist nur die
# Bedienoberflaeche dazu.
# =============================================================================
extends Control

## Wohin der "Zurueck"-Button fuehrt.
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var _master_slider: HSlider = $CenterContainer/VBoxContainer/MasterRow/MasterSlider
@onready var _music_slider: HSlider = $CenterContainer/VBoxContainer/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $CenterContainer/VBoxContainer/SfxRow/SfxSlider
@onready var _back_button: Button = $CenterContainer/VBoxContainer/BackButton


func _ready() -> void:
	# Regler auf die aktuell gespeicherten Werte stellen ...
	_master_slider.value = AudioManager.get_volume(AudioManager.MASTER_BUS)
	_music_slider.value = AudioManager.get_volume(AudioManager.MUSIC_BUS)
	_sfx_slider.value = AudioManager.get_volume(AudioManager.SFX_BUS)

	# ... und auf jede Aenderung reagieren.
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_back_button.pressed.connect(_on_back_pressed)

	_back_button.grab_focus()


func _on_master_changed(value: float) -> void:
	AudioManager.set_volume(AudioManager.MASTER_BUS, value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_volume(AudioManager.MUSIC_BUS, value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_volume(AudioManager.SFX_BUS, value)
	# Kleines Hoer-Feedback, damit man den neuen Effekt-Pegel sofort merkt.
	AudioManager.play_sfx("tap")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
