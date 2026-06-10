# =============================================================================
# shockwave.gd
# =============================================================================
# Bodenschock-Welle, ausgeloest wenn der Spieler mit dem Luft-Runterschlag
# ("attack_from_above") auf dem Boden aufkommt. Eine Area2D, deren Radius sich
# kurz ausbreitet und dabei JEDEN beruehrten Gegner toetet (gleiche die()-Logik
# wie Schwert/Roll/Charge). Danach loescht sie sich selbst (queue_free).
#
# Gespawnt wird sie vom Spieler (player.gd -> _spawn_shockwave).
# =============================================================================

extends Area2D

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Tuning – gefahrlos aenderbar:                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
const MAX_RADIUS := 46.0     # Wie weit die Welle reicht (Pixel)  <- groesser = maechtiger
const DURATION := 0.28       # Lebensdauer in Sekunden  <- laenger = langsamere Welle
const RING_COLOR := Color(1.0, 0.95, 0.7, 0.9)  # Ringfarbe (>1-Anteile leuchten dank Glow)
const RING_WIDTH := 3.0      # Strichbreite des Rings

var _cs: CollisionShape2D     # Die mitwachsende Kollisions-Shape
var _time := 0.0              # Verstrichene Zeit seit dem Spawn

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2        # Layer 2 = Gegner (gleich wie Roll-/Attack-Hitbox)
	_cs = $CollisionShape2D
	# Eigene Kopie der CircleShape2D, damit sich mehrere Wellen nicht gegenseitig
	# den Radius verstellen (Resourcen werden sonst geteilt).
	_cs.shape = _cs.shape.duplicate()
	_cs.shape.radius = 1.0

func _physics_process(delta: float) -> void:
	_time += delta
	var t := clampf(_time / DURATION, 0.0, 1.0)
	# Radius waechst mit "ease out" -> knackiger Schlag, der am Ende ausrollt.
	var r := MAX_RADIUS * (1.0 - pow(1.0 - t, 2.0))
	_cs.shape.radius = maxf(r, 1.0)
	queue_redraw()
	# Getroffene Gegner sofort toeten (identische Logik wie player.gd Roll/Attacke).
	for body in get_overlapping_bodies():
		if body.is_in_group(GameConstants.GROUP_ENEMY):
			body.die()
		elif body.get_parent() and body.get_parent().is_in_group(GameConstants.GROUP_ENEMY):
			body.get_parent().die()
	if _time >= DURATION:
		queue_free()

func _draw() -> void:
	# Halbkreis-Ring entlang des Bodens (untere Haelfte: Winkel 0..PI, da Y nach
	# unten zeigt). Der Ring waechst mit und blendet dabei aus.
	var t := clampf(_time / DURATION, 0.0, 1.0)
	var r := MAX_RADIUS * (1.0 - pow(1.0 - t, 2.0))
	var col := RING_COLOR
	col.a *= (1.0 - t)
	draw_arc(Vector2.ZERO, maxf(r, 1.0), 0.0, PI, 28, col, RING_WIDTH, true)
