# =============================================================================
# galerie.gd
# =============================================================================
# Haengt ueber jedem besuchten Slot-Portal einen ⭐-Sticker an:
#
#   ★  – dieser Slot wurde in der aktuellen Session schon besucht
#
# Wie das Besucht-Tracking funktioniert:
#   1. Spieler betritt einen Slot ueber das Galerie-Portal
#   2. Spieler laeuft im Slot zurueck ins ReturnPortal
#   3. portal.gd ruft GameManager.mark_scene_visited(slot_pfad) auf
#   4. Beim naechsten Laden der Galerie liest dieses Skript die Liste
#      und haengt ein ★ ueber das passende Slot-Portal
#
# Den Namen, wer welchen Slot haelt, tragen die statischen "SlotXLabel"-Labels
# direkt in galerie.tscn (z. B. "Riccardo"). Wer einen neuen Slot belegt,
# benennt dort das passende Label um (siehe student_levels/README.md).
# =============================================================================

extends Node2D

# Pfad-Muster, das identifiziert ob ein Portal zu einem Schueler-Slot fuehrt.
# Bewusst der ganze Ordner: die Slot-Szenen heissen nicht zwingend "slot_X"
# (Schueler benennen sie z. B. nach sich selbst, "riccardo.tscn").
const _SLOT_PATH_PREFIX := "res://scenes/levels/student_levels/"


func _ready() -> void:
	for portal in get_tree().get_nodes_in_group("portals"):
		if not _is_slot_portal(portal):
			continue
		if portal.target_scene in GameManager.visited_scenes:
			_add_sticker(portal)


func _is_slot_portal(portal: Node) -> bool:
	return portal.target_scene.begins_with(_SLOT_PATH_PREFIX)


# Erzeugt ein ★-Label ueber dem Portal fuer besuchte Slots.
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
