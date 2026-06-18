# =============================================================================
# green_slime_spawner.gd
# =============================================================================
# Gegner-Spawner (Node2D).
#
# Erzeugt in regelmaessigen Abstaenden neue Slimes an der Position des Spawners.
# Respektiert eine maximale Anzahl gleichzeitig aktiver Gegner – sobald das
# Limit erreicht ist, wird kein weiterer Slime gespawnt bis einer stirbt.
#
# WICHTIG: Das Limit zaehlt nur die SELBST gespawnten Slimes dieses Spawners.
#   Frueher wurde die globale Gruppe "enemy" gezaehlt – dadurch teilten sich
#   mehrere Spawner (z. B. 3 in turm.tscn) zusammen EIN Limit, und fest
#   platzierte Slimes zaehlten faelschlich mit.
#
# Einrichtung im Editor:
#   - slime_scene:      Die zu spawnende Szene (z. B. green_slime.tscn) zuweisen
#   - spawn_interval:   Sekunden zwischen zwei Spawns
#   - max_slimes:       Maximale Gegneranzahl gleichzeitig (pro Spawner)
#   - spawn_spread:     Zufaelliger horizontaler Versatz, damit Slimes sich
#                       nicht exakt aufeinander stapeln (0 = aus)
#   - despawn_distance: Ist der Spieler weiter als dieser Abstand entfernt,
#                       werden gespawnte Slimes wieder entfernt (0 = aus).
#                       Spart Leistung bei weit entfernten Spawnern.
# =============================================================================

extends Node2D

# -----------------------------------------------------------------------------
# Export-Variablen (im Godot-Editor einstellbar)
# -----------------------------------------------------------------------------
@export var slime_scene: PackedScene    # Die Szene des Gegners der gespawnt werden soll
@export var spawn_interval := 6.0       # Wartezeit in Sekunden zwischen zwei Spawns  <- groesser = seltener
@export var max_slimes := 5             # Maximal erlaubte Anzahl gleichzeitiger Gegner (pro Spawner)
@export var spawn_spread := 8.0         # Zufaelliger horizontaler Versatz beim Spawn (Pixel)
@export var despawn_distance := 0.0     # Spieler-Abstand ab dem Slimes entfernt werden (0 = aus)

# --- Boden-Spawn ---------------------------------------------------------------
# Damit Slimes nicht "aus dem Himmel fallen", sucht der Spawner per Strahl nach
# unten den Boden und setzt den frischen Slime direkt darauf.
@export var ground_ray_length := 2000.0 # Wie weit nach unten nach Boden gesucht wird (Pixel)
@export var ground_offset := 10.0       # Wie hoch ueber dem gefundenen Boden der Slime erscheint (Pixel)
@export var ground_mask := 1            # Physik-Ebene des Bodens (Standard-Welt = 1)

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var timer := $Timer            # Timer-Node der den Spawn-Takt steuert

# -----------------------------------------------------------------------------
# Zustand
# -----------------------------------------------------------------------------
# Liste der von DIESEM Spawner erzeugten, noch lebenden Slimes.
var _spawned: Array[Node] = []

# =============================================================================
# _ready()
# Konfiguriert den Timer und startet ihn.
# =============================================================================
func _ready() -> void:
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

# =============================================================================
# _on_timer_timeout()
# Wird aufgerufen wenn der Timer ablaeuft.
# Prueft ob gespawnt werden darf und erzeugt ggf. einen neuen Slime.
# =============================================================================
func _on_timer_timeout() -> void:
	if slime_scene == null:
		return

	# Bereits entfernte Slimes (z. B. besiegt) aus der Liste werfen.
	_prune()

	# Optional: weit entfernte Slimes wieder entfernen (Leistung sparen).
	if despawn_distance > 0.0:
		_despawn_distant()

	# Limit erreicht? -> nichts tun.
	if _spawned.size() >= max_slimes:
		return

	var slime = slime_scene.instantiate()
	# Markieren BEVOR der Slime in den Baum kommt, damit sein _ready()
	# ihn nicht persistiert. Sonst gaebe es nach erstem Tod eines Spawn-
	# Slimes keine neuen Spawns mehr im Level.
	if "is_spawned" in slime:
		slime.is_spawned = true
	# Kleiner Zufallsversatz, damit frische Slimes sich nicht exakt stapeln.
	var offset_x = randf_range(-spawn_spread, spawn_spread) if spawn_spread > 0.0 else 0.0
	var spawn_pos := global_position + Vector2(offset_x, 0.0)
	# Auf den Boden setzen, statt aus der Luft fallen zu lassen.
	spawn_pos = _ground_position(spawn_pos)
	slime.global_position = spawn_pos
	get_parent().add_child(slime)
	_spawned.append(slime)

# =============================================================================
# _ground_position(from)
# Schiesst einen Strahl von "from" gerade nach unten und gibt die Position
# knapp ueber dem ersten getroffenen Boden zurueck. Findet sich kein Boden
# (z. B. ueber einem Abgrund), wird "from" unveraendert zurueckgegeben.
# =============================================================================
func _ground_position(from: Vector2) -> Vector2:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		from, from + Vector2(0.0, ground_ray_length), ground_mask)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return from
	return Vector2(from.x, hit.position.y - ground_offset)

# =============================================================================
# _prune()
# Entfernt ungueltige (bereits freigegebene) Eintraege aus der Liste.
# =============================================================================
func _prune() -> void:
	_spawned = _spawned.filter(func(s): return is_instance_valid(s))

# =============================================================================
# _despawn_distant()
# Entfernt gespawnte Slimes, die weiter als despawn_distance vom Spieler weg
# sind. So wachsen weit entfernte Spawner nicht endlos an.
# =============================================================================
func _despawn_distant() -> void:
	var player = get_tree().get_first_node_in_group(GameConstants.GROUP_PLAYER)
	if player == null or not is_instance_valid(player):
		return
	for slime in _spawned:
		if is_instance_valid(slime) and slime.global_position.distance_to(player.global_position) > despawn_distance:
			slime.queue_free()
	_prune()
