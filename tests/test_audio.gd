# =============================================================================
# test_audio.gd
# =============================================================================
# Prueft das zentrale Audio-System (AudioManager + Bus-Layout):
#   - die Sound-Bibliothek ist vollstaendig und die Dateien existieren
#   - das Bus-Layout (Master/Music/SFX) ist angelegt und verdrahtet
#   - die Lautstaerke-Umrechnung (Anteil <-> Dezibel) ist verlustfrei
#
# Laeuft headless ohne Audio-Hardware -- es wird kein Ton abgespielt, nur die
# Konfiguration und die Rechen-Logik geprueft.
# =============================================================================

extends RefCounted

const AudioManagerScript = preload("res://scripts/audio_manager.gd")


func run(t) -> void:
	print("Audio-System:")

	# --- Sound-Bibliothek: erwartete Effekte vorhanden + Dateien existieren ---
	var lib = AudioManagerScript.SFX_LIBRARY
	for key in ["coin", "jump", "hurt", "explosion", "power_up", "tap"]:
		t.check(lib.has(key), "SFX_LIBRARY enthaelt '%s'" % key)
	for key in lib:
		t.check(ResourceLoader.exists(lib[key]), "Sound-Datei existiert: %s" % lib[key])

	# --- Bus-Namen-Konstanten ---
	t.check(AudioManagerScript.MASTER_BUS == "Master", "MASTER_BUS heisst 'Master'")
	t.check(AudioManagerScript.MUSIC_BUS == "Music", "MUSIC_BUS heisst 'Music'")
	t.check(AudioManagerScript.SFX_BUS == "SFX", "SFX_BUS heisst 'SFX'")

	# --- Bus-Layout-Datei legt Master/Music/SFX an ---
	var layout := FileAccess.get_file_as_string("res://default_bus_layout.tres")
	t.check(layout.contains("\"Master\""), "Bus-Layout definiert Master")
	t.check(layout.contains("\"Music\""), "Bus-Layout definiert Music")
	t.check(layout.contains("\"SFX\""), "Bus-Layout definiert SFX")

	# --- project.godot bindet Layout + Autoloads ein ---
	var proj := FileAccess.get_file_as_string("res://project.godot")
	t.check(proj.contains("default_bus_layout.tres"), "project.godot referenziert das Bus-Layout")
	t.check(proj.contains("AudioManager="), "AudioManager ist als Autoload eingetragen")
	t.check(proj.contains("PauseMenu="), "PauseMenu ist als Autoload eingetragen")

	# --- Musik-Map: Szenen sind .tscn-Pfade, Musikdateien existieren ---
	var music_map = AudioManagerScript.MUSIC_MAP
	t.check(music_map.size() > 0, "MUSIC_MAP ist nicht leer")
	for scene_path in music_map:
		t.check(scene_path.begins_with("res://") and scene_path.ends_with(".tscn"),
			"MUSIC_MAP-Schluessel ist eine Szene: %s" % scene_path)
		t.check(ResourceLoader.exists(music_map[scene_path]),
			"Musikdatei existiert: %s" % music_map[scene_path])

	# --- Lautstaerke-Umrechnung Anteil <-> Dezibel ist (nahezu) verlustfrei ---
	for pct in [0.25, 0.5, 1.0]:
		var roundtrip: float = db_to_linear(linear_to_db(pct))
		t.check(abs(roundtrip - pct) < 0.001, "Lautstaerke %0.2f bleibt nach Umrechnung erhalten" % pct)
