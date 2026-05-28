# =============================================================================
# galerie.gd
# =============================================================================
# Zeigt Beschriftungen ueber den Slot-Portalen:
#
#   ⭐  – dieser Slot wurde in der aktuellen Session besucht
#   Schuelername – gelesen aus dem "Hinweis"-Label der Slot-Szene, falls
#                  der Slot nicht mehr leer ist (d.h. nicht "Slot X – frei")
#
# Wie das Besucht-Tracking funktioniert:
#   1. Spieler betritt einen Slot ueber das Galerie-Portal
#   2. Spieler laeuft im Slot zurueck ins ReturnPortal
#   3. portal.gd ruft GameManager.mark_scene_visited(slot_pfad) auf
#   4. Beim naechsten Laden der Galerie liest dieses Skript die Liste
#      und haengt ein ⭐ ueber das passende Slot-Portal
#
# Wie der Schuelername gelesen wird:
#   Die Slot-Szene enthaelt einen Label-Node namens "Hinweis".
#   Sein Text-Inhalt (z. B. "Slot 1 – Mia") wird ueber dem Portal angezeigt.
#   Zeigt er noch "frei" oder ist er leer, wird nichts angezeigt.
# =============================================================================

extends Node2D

# Pfad-Muster, das identifiziert ob ein Portal zu einem Schueler-Slot fuehrt.
const _SLOT_PATH_PREFIX := "res://scenes/levels/student_levels/slot_"


func _ready() -> void:
	for portal in get_tree().get_nodes_in_group("portals"):
		if not _is_slot_portal(portal):
			continue
		_add_name_label(portal)
		if portal.target_scene in GameManager.visited_scenes:
			_add_sticker(portal)


func _is_slot_portal(portal: Node) -> bool:
	return portal.target_scene.begins_with(_SLOT_PATH_PREFIX)


# Laedt die Slot-Szene und liest den "Hinweis"-Label aus um den Schuelernamen
# zu ermitteln. Die Szene wird nur als Ressource geladen (kein Instanziieren),
# daher entsteht kein Laufzeit-Overhead fuer den Spieler.
func _add_name_label(portal: Node2D) -> void:
	if portal.target_scene == "":
		return
	var packed: PackedScene = load(portal.target_scene)
	if packed == null:
		return
	var state := packed.get_state()
	# Den Text-Wert des "Hinweis"-Nodes direkt aus dem Szenen-State lesen,
	# ohne die Szene zu instanziieren. Das ist effizienter als add_child.
	var slot_name := ""
	for i in range(state.get_node_count()):
		if state.get_node_name(i) == "Hinweis":
			for p in range(state.get_node_property_count(i)):
				if state.get_node_property_name(i, p) == "text":
					slot_name = state.get_node_property_value(i, p)
	# Nur anzeigen wenn der Slot nicht mehr leer ist
	if slot_name == "" or "frei" in slot_name.to_lower():
		return
	var label := Label.new()
	label.text = slot_name
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.offset_left = portal.position.x - 60.0
	label.offset_top = portal.position.y - 85.0
	label.offset_right = portal.position.x + 60.0
	label.offset_bottom = portal.position.y - 65.0
	add_child(label)


# Erzeugt ein ⭐-Label ueber dem Portal fuer besuchte Slots.
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
