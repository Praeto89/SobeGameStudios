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
@export var spawn_interval := 3.0       # Wartezeit in Sekunden zwischen zwei Spawns
@export var max_slimes := 5             # Maximal erlaubte Anzahl gleichzeitiger Gegner (pro Spawner)
@export var spawn_spread := 8.0         # Zufaelliger horizontaler Versatz beim Spawn (Pixel)
@export var despawn_distance := 0.0     # Spieler-Abstand ab dem Slimes entfernt werden (0 = aus)

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
	slime.global_position = global_position + Vector2(offset_x, 0.0)
	get_parent().add_child(slime)
	_spawned.append(slime)

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
