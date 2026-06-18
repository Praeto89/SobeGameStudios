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
	add_to_group(GameConstants.GROUP_PORTALS)
	body_entered.connect(_on_body_entered)

	# Spieler kam gerade aus diesem Portal (durch einen Level-Wechsel):
	# - Spieler an die Portal-Position setzen (sonst spawnt er an seiner
	#   Default-Position aus player.tscn, irgendwo im Level)
	# - Portal kurz sperren, damit es ihn nicht sofort zurueckteleportiert
	if GameManager.came_from_portal_id == portal_id:
		var player = get_tree().get_first_node_in_group(GameConstants.GROUP_PLAYER)
		if player:
			_place_body_at_portal(player)
		GameManager.came_from_portal_id = ""
		_start_cooldown()


func _on_body_entered(body: Node2D) -> void:
	if _on_cooldown:
		return
	if not body.is_in_group(GameConstants.GROUP_PLAYER):
		return

	# Ziel-Portal merken, damit wir dort spawnen koennen
	GameManager.came_from_portal_id = target_portal_id

	# Teleport-Sound. Laeuft ueber den AudioManager (Autoload) und wird daher
	# auch bei einem Level-Wechsel nicht abgeschnitten.
	AudioManager.play_sfx("power_up", 1.3)

	if target_scene != "":
		# Wenn der Spieler in die Galerie zurueckgeht, die aktuelle Szene
		# als "besucht" markieren -- die Galerie zeigt darueber ein ⭐
		# am entsprechenden Slot-Portal an.
		if target_scene == GameConstants.SCENE_GALERIE:
			var current = get_tree().current_scene
			if current != null:
				GameManager.mark_scene_visited(current.scene_file_path)
		# ── Level-Wechsel ──────────────────────────────────
		get_tree().change_scene_to_file(target_scene)
	else:
		# ── Teleport im selben Level ───────────────────────
		_teleport_in_scene(body)


func _teleport_in_scene(body: Node2D) -> void:
	var all_portals := get_tree().get_nodes_in_group(GameConstants.GROUP_PORTALS)
	for portal in all_portals:
		if portal == self:
			continue
		if portal.portal_id == target_portal_id:
			portal._place_body_at_portal(body)
			portal._start_cooldown()   # Partner sperren -> kein Ping-Pong
			_start_cooldown()
			return
	push_warning("Portal '%s': Kein Partner mit ID '%s' gefunden!" % [portal_id, target_portal_id])


# -------------------------------------------------------
# _place_body_at_portal(body)
# Setzt den Koerper (Spieler) sauber MITTIG ins Portal.
#
# WARUM nicht einfach body.global_position = global_position?
# Der Spieler hat seine CollisionShape2D im player.tscn versetzt liegen
# (sie sitzt ein Stueck links/oben vom Knoten-Ursprung). Setzt man nur den
# Ursprung aufs Portal, landet die KOLLISIONS-Kapsel daneben -- bei einem eng
# an einer Wand stehenden Portal (z. B. in area_1) steckt der Spieler dann in
# der Wand fest. Hier verschieben wir so, dass die Kapsel-MITTE aufs Portal
# faellt, also dort, wo optisch das offene Portal ist. Zusaetzlich setzen wir
# das Tempo auf 0, damit der Spieler nicht mit Schwung in die Wand rutscht.
# -------------------------------------------------------
func _place_body_at_portal(body: Node2D) -> void:
	var shape := body.get_node_or_null("CollisionShape2D")
	var shape_offset := Vector2.ZERO
	if shape:
		shape_offset = shape.global_position - body.global_position
	body.global_position = global_position - shape_offset
	if "velocity" in body:
		body.velocity = Vector2.ZERO


func _start_cooldown() -> void:
	_on_cooldown = true
	# Visuelles Feedback: Portal leicht abdunkeln
	modulate.a = 0.4
	await get_tree().create_timer(cooldown_duration).timeout
	modulate.a = 1.0
	_on_cooldown = false
