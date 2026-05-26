# =============================================================================
# geen_slime_spawner.gd
# =============================================================================
# Gegner-Spawner (Node2D).
#
# Erzeugt in regelmaessigen Abstaenden neue Slimes an der Position des Spawners.
# Respektiert eine maximale Anzahl gleichzeitig aktiver Gegner – sobald das
# Limit erreicht ist, wird kein weiterer Slime gespawnt bis einer stirbt.
#
# Einrichtung im Editor:
#   - slime_scene: Die zu spawnende Szene (z. B. green_slime.tscn) zuweisen
#   - spawn_interval: Sekunden zwischen zwei Spawns
#   - max_slimes: Maximale Gegneranzahl gleichzeitig in der Szene
# =============================================================================

extends Node2D

# -----------------------------------------------------------------------------
# Export-Variablen (im Godot-Editor einstellbar)
# -----------------------------------------------------------------------------
@export var slime_scene: PackedScene    # Die Szene des Gegners der gespawnt werden soll
@export var spawn_interval := 3.0       # Wartezeit in Sekunden zwischen zwei Spawns
@export var max_slimes := 5             # Maximal erlaubte Anzahl gleichzeitiger Gegner

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var timer := $Timer            # Timer-Node der den Spawn-Takt steuert

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

	# Alle Nodes in der Gruppe "enemy" zaehlen (Slimes fuegen sich selbst hinzu)
	var current_slimes = get_tree().get_nodes_in_group("enemy").size()
	if current_slimes >= max_slimes:
		return

	var slime = slime_scene.instantiate()
	slime.global_position = global_position
	get_parent().add_child(slime)
