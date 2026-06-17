# =============================================================================
# audio_manager.gd
# =============================================================================
# Zentrales Audio-System des Spiels (Autoload-Singleton "AudioManager").
#
# Als Autoload einrichten (ist in project.godot bereits eingetragen):
#   Projekt > Projekteinstellungen > Autoload
#   Skript: res://scripts/audio_manager.gd  |  Name: AudioManager
#
# Was kann der AudioManager?
# --------------------------
#   1) SOUNDEFFEKTE von ueberall abspielen, ohne in jeder Szene einen eigenen
#      AudioStreamPlayer zu brauchen:
#         AudioManager.play_sfx("coin")
#         AudioManager.play_sfx("jump", 1.2)   # 1.2 = etwas hoehere Tonhoehe
#      Dafuer haelt der Manager einen kleinen "Pool" aus Spielern bereit, sodass
#      auch mehrere Effekte gleichzeitig klingen koennen.
#
#   2) HINTERGRUNDMUSIK, die einen Szenenwechsel ueberlebt (der Manager lebt als
#      Autoload dauerhaft) und sanft zwischen Stuecken ueberblendet:
#         AudioManager.play_music("res://assets/music/time_for_adventure.mp3")
#
#   3) LAUTSTAERKE getrennt nach Master / Musik / Effekte regeln und dauerhaft
#      speichern (user://settings.cfg). Das Optionen-Menue nutzt genau das:
#         AudioManager.set_volume("Music", 0.5)   # 0.0 = stumm, 1.0 = voll
#         AudioManager.get_volume("SFX")
#
# Lernkonzept: Singleton/Autoload, Objekt-Pool, Buses, Persistenz per ConfigFile.
# Schwierigkeit: [FORTGESCHRITTEN]
# =============================================================================
extends Node

## Wo die Lautstaerke-Einstellungen gespeichert werden (im Nutzerordner).
const SETTINGS_PATH := "user://settings.cfg"

## Namen der Audio-Buses (siehe default_bus_layout.tres).
const MASTER_BUS := "Master"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

## Bibliothek aller Soundeffekte: Kurzname -> Datei.
## Ueber play_sfx("name") abspielbar. Neuen Sound? Hier eine Zeile ergaenzen.
const SFX_LIBRARY := {
	"coin":      "res://assets/sounds/coin.wav",
	"jump":      "res://assets/sounds/jump.wav",
	"hurt":      "res://assets/sounds/hurt.wav",
	"explosion": "res://assets/sounds/explosion.wav",
	"power_up":  "res://assets/sounds/power_up.wav",
	"tap":       "res://assets/sounds/tap.wav",
}

## Wie viele Effekte gleichzeitig klingen koennen (Groesse des Spieler-Pools).
const POOL_SIZE := 8

## Welche Szene welche Hintergrundmusik bekommt (Szenen-Pfad -> Musik-Datei).
## Der AudioManager beobachtet die aktive Szene und startet automatisch die
## passende Musik. Weil play_music() dasselbe Stueck nicht neu startet, laeuft
## die Musik beim Wechsel zwischen Szenen mit GLEICHEM Track nahtlos weiter.
## Szenen, die hier NICHT stehen, lassen die laufende Musik einfach weiterlaufen.
const MUSIC_MAP := {
	"res://scenes/ui/main_menu.tscn":    "res://assets/music/for_a_school_game.mp3",
	"res://scenes/ui/credits.tscn":      "res://assets/music/for_a_school_game.mp3",
	"res://scenes/ui/options_menu.tscn": "res://assets/music/for_a_school_game.mp3",
	"res://scenes/levels/main.tscn":     "res://assets/music/time_for_adventure.mp3",
	"res://scenes/levels/turm.tscn":     "res://assets/music/time_for_adventure.mp3",
	"res://scenes/levels/sandbox.tscn":  "res://assets/music/time_for_adventure.mp3",
	"res://scenes/levels/galerie.tscn":  "res://assets/music/time_for_adventure.mp3",
	"res://scenes/levels/area_1.tscn":   "res://assets/music/new_project.mp3",
}

# -----------------------------------------------------------------------------
# Interner Zustand
# -----------------------------------------------------------------------------
var _sfx_pool: Array[AudioStreamPlayer] = []   # wiederverwendbare Effekt-Spieler
var _sfx_index := 0                             # naechster freier Spieler (Ringpuffer)
var _streams: Dictionary = {}                   # Kurzname -> geladener AudioStream
var _music_player: AudioStreamPlayer            # ein dauerhafter Spieler fuer Musik
var _current_music := ""                        # Pfad des aktuell laufenden Stuecks
var _last_scene_path := ""                      # zuletzt gesehene Szene (fuer MUSIC_MAP)


# =============================================================================
# _ready()
# Baut den Effekt-Pool und den Musik-Spieler auf, laedt alle Sounds vor und
# stellt die zuletzt gespeicherte Lautstaerke wieder her.
# =============================================================================
func _ready() -> void:
	# Auch waehrend einer Pause (get_tree().paused) weiterlaufen duerfen,
	# damit Menue-Klicks und Musik im Pausenmenue nicht verstummen.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Effekt-Pool: mehrere AudioStreamPlayer auf dem SFX-Bus.
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_pool.append(p)

	# Musik-Spieler: lebt dauerhaft -> Musik laeuft ueber Szenenwechsel weiter.
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)

	# Alle Sounds einmal vorladen (verhindert Ruckler beim ersten Abspielen).
	for key in SFX_LIBRARY:
		var stream = load(SFX_LIBRARY[key])
		if stream != null:
			_streams[key] = stream

	# Gespeicherte Lautstaerken anwenden.
	_load_settings()


# =============================================================================
# _process()
# Beobachtet, welche Szene gerade aktiv ist, und startet bei einem Wechsel die
# in MUSIC_MAP hinterlegte Musik. So braucht keine Level-Szene einen eigenen
# Musik-Player -- und die Musik laeuft ueber Szenenwechsel hinweg weiter.
# (Ein simpler String-Vergleich pro Frame, das kostet praktisch nichts.)
# =============================================================================
func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var path := scene.scene_file_path
	if path == _last_scene_path:
		return
	_last_scene_path = path
	if MUSIC_MAP.has(path):
		play_music(MUSIC_MAP[path])


# =============================================================================
# play_sfx(name, pitch, volume_db)
# Spielt einen Soundeffekt aus der Bibliothek ab.
#   name       : Kurzname aus SFX_LIBRARY, z. B. "coin"
#   pitch      : Tonhoehe (1.0 = original; <1 tiefer, >1 hoeher).
#                Tipp: leichte Zufallsschwankung klingt lebendiger.
#   volume_db  : Lautstaerke-Korrektur in Dezibel (0 = unveraendert, -6 = leiser).
# =============================================================================
func play_sfx(sfx_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not _streams.has(sfx_name):
		push_warning("AudioManager: unbekannter Sound '%s'" % sfx_name)
		return
	# Naechsten Spieler aus dem Pool nehmen (Ringpuffer -> reihum).
	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	player.stream = _streams[sfx_name]
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


# =============================================================================
# play_music(path, fade)
# Startet ein Musikstueck. Laeuft dasselbe Stueck schon, passiert nichts (so
# wird die Musik beim Szenenwechsel NICHT neu gestartet). Ein anderes Stueck
# wird sanft ueberblendet.
#   path : res://-Pfad zur Musikdatei
#   fade : Ueberblend-Dauer in Sekunden (0 = hart umschalten)
# =============================================================================
func play_music(path: String, fade: float = 0.8) -> void:
	if path == _current_music and _music_player.playing:
		return
	var stream = load(path)
	if stream == null:
		push_warning("AudioManager: Musik nicht gefunden '%s'" % path)
		return
	_current_music = path
	# Laeuft schon etwas? Erst aus-, dann das Neue einblenden.
	if _music_player.playing and fade > 0.0:
		var fade_out := create_tween()
		fade_out.tween_property(_music_player, "volume_db", -40.0, fade * 0.5)
		await fade_out.finished
	_music_player.stream = stream
	_music_player.volume_db = 0.0
	_music_player.play()


# =============================================================================
# stop_music(fade)
# Blendet die laufende Musik aus und stoppt sie.
# =============================================================================
func stop_music(fade: float = 0.6) -> void:
	if not _music_player.playing:
		return
	if fade > 0.0:
		var t := create_tween()
		t.tween_property(_music_player, "volume_db", -40.0, fade)
		await t.finished
	_music_player.stop()
	_current_music = ""


# =============================================================================
# set_volume(bus, pct) / get_volume(bus)
# Lautstaerke eines Buses ("Master" | "Music" | "SFX") als Anteil 0.0 .. 1.0.
# 0.0 schaltet den Bus stumm. Jede Aenderung wird sofort gespeichert.
# =============================================================================
func set_volume(bus: String, pct: float) -> void:
	_apply_volume(bus, pct)
	_save_settings()


func get_volume(bus: String) -> float:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return 1.0
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


# Setzt die Lautstaerke OHNE zu speichern (Helfer fuer set_volume und beim Laden).
func _apply_volume(bus: String, pct: float) -> void:
	pct = clampf(pct, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	# Bei (fast) 0 stummschalten -- linear_to_db(0) waere -unendlich.
	if pct <= 0.001:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(pct))


# =============================================================================
# Speichern / Laden der Lautstaerke (user://settings.cfg)
# =============================================================================
func _save_settings() -> void:
	var cfg := ConfigFile.new()
	for bus in [MASTER_BUS, MUSIC_BUS, SFX_BUS]:
		cfg.set_value("audio", bus, get_volume(bus))
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return  # noch keine Einstellungen vorhanden -> Standard (voll) bleibt
	for bus in [MASTER_BUS, MUSIC_BUS, SFX_BUS]:
		if cfg.has_section_key("audio", bus):
			_apply_volume(bus, float(cfg.get_value("audio", bus)))
