# Portal.gd
# -------------------------------------------------------
# Node-Struktur fuer jedes Portal:
#
#   Portal  (Area2D)  <-- dieses Skript hier
#   ├── CollisionShape2D
#   └── AnimationPlayer  (optional, fuer Leucht-Effekt)
#
# Jedes Portal zur Gruppe "portals" hinzufuegen!
# (Node auswaehlen > Gruppen > "portals")
# -------------------------------------------------------
extends Area2D

## Eindeutige ID dieses Portals (z. B. "level1_portal_a")
@export var portal_id: String = "portal_a"

## ID des Ziel-Portals (muss mit portal_id des Partners uebereinstimmen)
@export var target_portal_id: String = "portal_b"

## Pfad zur Zielszene fuer Level-Wechsel (leer lassen = gleiches Level)
## Beispiel: "res://scenes/Level2.tscn"
@export var target_scene: String = ""

## Wie lange (Sekunden) das Portal nach Benutzung gesperrt bleibt
@export var cooldown_duration: float = 1.2

# -------------------------------------------------------
# Interne Variablen
# -------------------------------------------------------
var _on_cooldown: bool = false


func _ready() -> void:
	add_to_group("portals")
	body_entered.connect(_on_body_entered)

	# Spieler kam gerade aus diesem Portal -> kurz sperren
	# (verhindert sofortiges Zurueckteleportieren)
	if GameManager.came_from_portal_id == portal_id:
		GameManager.came_from_portal_id = ""
		_start_cooldown()


func _on_body_entered(body: Node2D) -> void:
	if _on_cooldown:
		return
	if not body.is_in_group("player"):
		return

	# Ziel-Portal merken, damit wir dort spawnen koennen
	GameManager.came_from_portal_id = target_portal_id

	if target_scene != "":
		# ── Level-Wechsel ──────────────────────────────────
		get_tree().change_scene_to_file(target_scene)
	else:
		# ── Teleport im selben Level ───────────────────────
		_teleport_in_scene(body)


func _teleport_in_scene(body: Node2D) -> void:
	var all_portals := get_tree().get_nodes_in_group("portals")
	for portal in all_portals:
		if portal == self:
			continue
		if portal.portal_id == target_portal_id:
			body.global_position = portal.global_position
			portal._start_cooldown()   # Partner sperren -> kein Ping-Pong
			_start_cooldown()
			return
	push_warning("Portal '%s': Kein Partner mit ID '%s' gefunden!" % [portal_id, target_portal_id])


func _start_cooldown() -> void:
	_on_cooldown = true
	# Visuelles Feedback: Portal leicht abdunkeln
	modulate.a = 0.4
	await get_tree().create_timer(cooldown_duration).timeout
	modulate.a = 1.0
	_on_cooldown = false
