# =============================================================================
# galerie.gd
# =============================================================================
# Zeigt einen ⭐-Sticker ueber jedem Slot-Portal, das der Spieler in dieser
# Session schon besucht und wieder verlassen hat.
#
# Wie das Tracking funktioniert:
#   1. Spieler betritt einen Slot ueber das Galerie-Portal
#   2. Spieler laeuft im Slot zurueck ins Portal "ReturnPortal"
#   3. portal.gd ruft GameManager.mark_scene_visited(slot_pfad) auf
#   4. Beim naechsten Laden der Galerie liest dieses Skript die Liste
#      und haengt ein ⭐ ueber das passende Slot-Portal
#
# Die Sticker leben pro Session (kein Disk-Save) -- nach Spiel-Neustart
# sind sie weg. Bewusste Einfachheit, kann spaeter erweitert werden.
# =============================================================================

extends Node2D

# Pfad-Muster, das identifiziert ob ein Portal zu einem Schueler-Slot fuehrt.
const _SLOT_PATH_PREFIX := "res://scenes/levels/student_levels/slot_"


func _ready() -> void:
	for portal in get_tree().get_nodes_in_group("portals"):
		if not _is_slot_portal(portal):
			continue
		if portal.target_scene in GameManager.visited_scenes:
			_add_sticker(portal)


func _is_slot_portal(portal: Node) -> bool:
	return portal.target_scene.begins_with(_SLOT_PATH_PREFIX)


# Erzeugt ein ⭐-Label ueber dem Portal. Position aus portal.position --
# da der Galerie-Root-Node bei (0,0) liegt und keine Transformation hat,
# entsprechen Control-Offsets hier 1:1 den Welt-Koordinaten.
func _add_sticker(portal: Node2D) -> void:
	var sticker := Label.new()
	sticker.text = "★"
	sticker.add_theme_font_size_override("font_size", 32)
	sticker.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	sticker.add_theme_color_override("font_outline_color", Color.BLACK)
	sticker.add_theme_constant_override("outline_size", 4)
	sticker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sticker.offset_left = portal.position.x - 24.0
	sticker.offset_top = portal.position.y - 60.0
	sticker.offset_right = portal.position.x + 24.0
	sticker.offset_bottom = portal.position.y - 20.0
	add_child(sticker)
