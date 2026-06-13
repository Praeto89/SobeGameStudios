# =============================================================================
# boss_dragon.gd
# =============================================================================
# Fliegender Drachen-Boss -- das Finale ganz oben im Turm.
#
# Verhalten:
#   - schwebt (keine Schwerkraft) und fliegt zwischen zwei Punkten HIN UND HER
#   - wippt dabei sanft auf und ab (Sinus) -> wirkt wie echtes Fliegen
#   - stuerzt gelegentlich Richtung Spieler herab (Sturzflug) und kehrt zurueck
#   - fuegt dem Spieler bei Beruehrung Schaden zu (Hitbox)
#   - haelt MEHRERE Treffer aus (MAX_HP); zwischen zwei Treffern gibt es kurze
#     Unverwundbarkeit, damit eine einzelne Attacke ihn nicht sofort zerlegt
#   - beim Ableben: viel Gold + Triumph-Hinweis; bleibt danach besiegt (Save)
#
# Besonderheit: der Drache hat KEIN Sprite-Sheet -- er wird komplett per Code
# gezeichnet (_draw), inklusive schlagender Fluegel. Dadurch braucht er keine
# externen Grafik-Dateien und passt trotzdem zur lila "PurpleDragons"-Welt.
# =============================================================================

class_name BossDragon
extends CharacterBody2D

# -----------------------------------------------------------------------------
# Tuning (im Editor pro Instanz einstellbar)
# -----------------------------------------------------------------------------
@export var max_hp: int = 6                  # Wie viele Treffer er aushaelt
@export var patrol_half_width: float = 340.0 # Halbe Flugstrecke links/rechts vom Startpunkt
@export var speed: float = 95.0              # Tempo beim normalen Hin-und-Her-Fliegen
@export var bob_amplitude: float = 26.0      # Wie weit er beim Fliegen auf/ab wippt
@export var bob_speed: float = 2.2           # Tempo des Auf-/Ab-Wippens
@export var flap_speed: float = 9.0          # Tempo des Fluegelschlags (nur Optik)
@export var detection_range: float = 380.0   # Ab welcher Naehe er den Sturzflug erwaegt
@export var dive_depth: float = 150.0        # Wie tief der Sturzflug nach unten geht
@export var dive_speed: float = 175.0        # Horizontaltempo waehrend des Sturzflugs
@export var dive_cooldown: float = 4.5       # Mindestpause zwischen zwei Sturzfluegen
@export var dive_chance: float = 0.004       # Wahrscheinlichkeit pro Frame, einen Sturzflug zu starten
@export var gold_drop: int = 25              # Gold-Belohnung beim Sieg

# -----------------------------------------------------------------------------
# Konstanten
# -----------------------------------------------------------------------------
const HIT_IFRAME := 0.35      # Sekunden Unverwundbarkeit nach einem Treffer
const DIVE_DURATION := 1.1    # Dauer eines Sturzflugs in Sekunden

# -----------------------------------------------------------------------------
# Laufzeit-Zustand
# -----------------------------------------------------------------------------
var hp: int
var player: Node2D = null
var is_dead := false

var base_y := 0.0             # Ruhe-Flughoehe (um die herum gewippt wird)
var left_bound := 0.0         # Linke Wende-Position
var right_bound := 0.0        # Rechte Wende-Position
var patrol_dir := 1.0         # 1 = nach rechts, -1 = nach links
var face := 1.0               # Blickrichtung fuer die Zeichnung (1 rechts, -1 links)

var _bob_phase := 0.0
var _flap := 0.0
var hit_cd := 0.0

var is_diving := false
var dive_phase := 0.0
var dive_target_x := 0.0
var dive_cd := 0.0

# Persistenz: einmal besiegt, bleibt der Boss bei Re-Entry weg.
var _persistent_id: String = ""

@onready var hitbox: Area2D = $Hitbox


# =============================================================================
# _ready()
# =============================================================================
func _ready() -> void:
	add_to_group(GameConstants.GROUP_ENEMY)
	hp = max_hp
	player = get_tree().get_first_node_in_group(GameConstants.GROUP_PLAYER)
	# Flug-Grenzen aus der Start-Position ableiten.
	base_y = global_position.y
	left_bound = global_position.x - patrol_half_width
	right_bound = global_position.x + patrol_half_width
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	# Persistenz: schon mal besiegt? -> gar nicht erst erscheinen.
	_persistent_id = GameManager.get_persistent_id(self)
	if _persistent_id != "" and _persistent_id in GameManager.defeated_enemy_ids:
		queue_free()
		return
	queue_redraw()


# =============================================================================
# _physics_process(delta)
# =============================================================================
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Optik: Fluegelschlag-Phase weiterdrehen und neu zeichnen.
	_flap += delta * flap_speed
	queue_redraw()

	# Treffer-Unverwundbarkeit herunterzaehlen.
	if hit_cd > 0.0:
		hit_cd -= delta

	if is_diving:
		_do_dive(delta)
	else:
		_do_patrol(delta)

	move_and_slide()

	# Sicherheitsnetz: nie zu weit aus dem vorgesehenen Luftraum geraten.
	global_position.x = clampf(global_position.x, left_bound - 30.0, right_bound + 30.0)
	global_position.y = clampf(global_position.y, base_y - bob_amplitude - 40.0, base_y + dive_depth + 30.0)


# -----------------------------------------------------------------------------
# _do_patrol(delta) – normales Hin-und-Her-Fliegen mit Auf-/Ab-Wippen
# -----------------------------------------------------------------------------
func _do_patrol(delta: float) -> void:
	velocity.x = patrol_dir * speed

	# An den Wende-Punkten die Richtung umkehren.
	if patrol_dir > 0 and global_position.x >= right_bound:
		patrol_dir = -1.0
	elif patrol_dir < 0 and global_position.x <= left_bound:
		patrol_dir = 1.0
	face = patrol_dir

	# Sanftes Auf-/Ab-Wippen: zur Sinus-Sollhoehe ziehen.
	_bob_phase += delta * bob_speed
	var target_y := base_y + sin(_bob_phase) * bob_amplitude
	velocity.y = (target_y - global_position.y) * 4.0

	# Gelegentlich in den Sturzflug uebergehen, wenn der Spieler in Reichweite ist.
	if dive_cd > 0.0:
		dive_cd -= delta
	if dive_cd <= 0.0 and player != null and is_instance_valid(player):
		if global_position.distance_to(player.global_position) < detection_range and randf() < dive_chance:
			_start_dive()


# -----------------------------------------------------------------------------
# _start_dive() / _do_dive(delta) – Sturzflug zum Spieler und wieder hoch
# -----------------------------------------------------------------------------
func _start_dive() -> void:
	is_diving = true
	dive_phase = 0.0
	dive_cd = dive_cooldown
	dive_target_x = player.global_position.x if (player and is_instance_valid(player)) else global_position.x

func _do_dive(delta: float) -> void:
	dive_phase += delta
	if dive_phase >= DIVE_DURATION:
		is_diving = false
		return
	# Vertikal: Bogen nach unten und wieder hoch (sin geht 0 -> 1 -> 0).
	var frac := dive_phase / DIVE_DURATION
	var target_y := base_y + sin(frac * PI) * dive_depth
	velocity.y = (target_y - global_position.y) * 6.0
	# Horizontal: in Richtung des anvisierten Punktes gleiten (in den Grenzen).
	var clamped_target := clampf(dive_target_x, left_bound, right_bound)
	var dir := signf(clamped_target - global_position.x)
	velocity.x = dir * dive_speed
	if dir != 0.0:
		face = dir


# =============================================================================
# _on_hitbox_body_entered(body)
# Beruehrt der Spieler den Drachen, nimmt er Schaden mit Rueckstoss.
# =============================================================================
func _on_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return
	if body.has_method("take_damage"):
		var knockback_dir := signf(body.global_position.x - global_position.x)
		body.take_damage(1, knockback_dir)


# =============================================================================
# die()
# Wird von den Hitboxen des Spielers (Roll/Attacke) aufgerufen. Jeder Treffer
# zieht 1 HP ab; dazwischen liegt eine kurze Unverwundbarkeit (HIT_IFRAME),
# damit eine einzige, mehrere Frames aktive Attacke ihn nicht in einem Wimpern-
# schlag toetet. Der toedliche Treffer startet die Sterbe-Sequenz.
# =============================================================================
func die() -> void:
	if is_dead or hit_cd > 0.0:
		return
	hp -= 1
	hit_cd = HIT_IFRAME
	if hp > 0:
		# Treffer-Blitz: kurz hell aufleuchten, dann zurueck.
		modulate = Color(3.0, 1.5, 1.8)
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.25)
		return
	_start_death()


# =============================================================================
# _start_death()
# Sieg! Boss deaktivieren, Gold ausschuetten, Triumph anzeigen, ausblenden.
# =============================================================================
func _start_death() -> void:
	is_dead = true
	# Als besiegt markieren -> erscheint beim erneuten Betreten des Levels nicht mehr.
	if _persistent_id != "" and not _persistent_id in GameManager.defeated_enemy_ids:
		GameManager.defeated_enemy_ids.append(_persistent_id)
	# Kollision & Hitbox abschalten (kein Schaden mehr beim Verschwinden).
	hitbox.monitoring = false
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("SoundDeath"):
		$SoundDeath.play()
	# Grosse Gold-Belohnung.
	_spawn_gold(gold_drop)
	# Triumph-Hinweis (HUD ist autoloaded -> ueberall erreichbar).
	Hud.show_ability_message("Der Drache ist besiegt!\nFliehe nach oben zum ZIEL!", 4.0)
	# Ausblenden: kurz aufleuchten, langsam fallen, drehen und transparent werden.
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate", Color(1, 1, 1, 0.0), 1.4)
	t.tween_property(self, "rotation", 0.6, 1.4)
	t.tween_property(self, "global_position", global_position + Vector2(0, 80), 1.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	queue_free()


# =============================================================================
# _spawn_gold(count)
# Verteilt count Muenzen um die aktuelle Position. Als Kinder des Levels
# (nicht des Bosses) bleiben sie sammelbar, obwohl der Boss gleich verschwindet.
# (Gleiche Idee wie in slime_base.gd.)
# =============================================================================
func _spawn_gold(count: int) -> void:
	if count <= 0:
		return
	var parent := get_parent()
	if parent == null:
		return
	var coin_scene := load("res://scenes/pickups/coin.tscn")
	for i in count:
		var c = coin_scene.instantiate()
		var angle := randf() * TAU
		var dist := randf_range(12.0, 48.0)
		c.global_position = global_position + Vector2(cos(angle) * dist, sin(angle) * dist - 10.0)
		parent.add_child(c)


# =============================================================================
# _draw()
# Zeichnet den Drachen komplett aus einfachen Formen. Standardmaessig schaut er
# nach rechts; ueber "face" (-1) wird die x-Achse gespiegelt. Die Fluegel
# schlagen, weil ihre Punkte um die Schulter mit einem Sinus-Winkel rotiert
# werden und _physics_process jeden Frame neu zeichnen laesst.
# =============================================================================
func _draw() -> void:
	var body_col := Color(0.42, 0.24, 0.55)
	var belly_col := Color(0.62, 0.43, 0.74)
	var dark_col := Color(0.32, 0.18, 0.42)
	var bone_col := Color(0.92, 0.87, 0.70)

	# Fernen Fluegel zuerst (hinter dem Koerper), etwas dunkler & versetzt.
	draw_colored_polygon(_wing(_flap + PI * 0.18, 0.88), Color(0.30, 0.17, 0.40))

	# Schwanz + Schwanzspitze (Pfeil).
	draw_colored_polygon(_poly([Vector2(-18, -2), Vector2(-40, -16), Vector2(-54, -12), Vector2(-44, -6), Vector2(-20, 3)]), body_col)
	draw_colored_polygon(_poly([Vector2(-50, -14), Vector2(-64, -20), Vector2(-58, -10), Vector2(-66, -7), Vector2(-54, -5)]), dark_col)

	# Beine mit Krallen.
	draw_colored_polygon(_poly([Vector2(-10, 8), Vector2(-2, 8), Vector2(-4, 20), Vector2(-12, 18)]), dark_col)
	draw_colored_polygon(_poly([Vector2(8, 8), Vector2(16, 8), Vector2(14, 20), Vector2(6, 18)]), dark_col)

	# Koerper + Bauch.
	draw_colored_polygon(_ell(0, 0, 26, 16), body_col)
	draw_colored_polygon(_ell(3, 6, 18, 9), belly_col)

	# Hals.
	draw_colored_polygon(_poly([Vector2(14, -8), Vector2(26, -18), Vector2(34, -10), Vector2(22, 0)]), body_col)

	# Kopf.
	draw_colored_polygon(_ell(32, -12, 11, 10), body_col)
	# Schnauze.
	draw_colored_polygon(_poly([Vector2(38, -15), Vector2(49, -11), Vector2(48, -5), Vector2(36, -6)]), body_col)
	# Mundlinie.
	draw_line(Vector2(40 * face, -8), Vector2(48 * face, -8), Color(0.18, 0.09, 0.26), 1.5)
	# Nuestern.
	draw_circle(Vector2(46 * face, -11), 1.0, Color(0.18, 0.09, 0.26))

	# Hoerner.
	draw_colored_polygon(_poly([Vector2(27, -20), Vector2(22, -35), Vector2(33, -21)]), bone_col)
	draw_colored_polygon(_poly([Vector2(33, -18), Vector2(30, -31), Vector2(39, -19)]), Color(0.86, 0.80, 0.62))

	# Auge (boese, gelb mit schmaler Pupille).
	draw_colored_polygon(_ell(34, -15, 3.4, 3.4, 10), Color(1.0, 0.82, 0.18))
	draw_colored_polygon(_ell(35, -15, 1.2, 2.6, 8), Color(0.08, 0.04, 0.10))

	# Naher Fluegel zuletzt (vor dem Koerper) + Fluegel-Streben.
	var near := _wing(_flap, 1.0)
	draw_colored_polygon(near, Color(0.55, 0.32, 0.70))
	var shoulder := Vector2(-2 * face, -10)
	for idx in [1, 2, 3]:
		draw_line(shoulder, near[idx], dark_col, 1.5)


# -----------------------------------------------------------------------------
# Zeichen-Helfer
# -----------------------------------------------------------------------------
# Spiegelt eine plain Vector2-Liste an "face" (Blickrichtung) und gibt eine
# PackedVector2Array fuer draw_colored_polygon zurueck.
func _poly(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(Vector2(p.x * face, p.y))
	return out

# Ellipse als Polygon (n Eckpunkte), bereits an "face" gespiegelt.
func _ell(cx: float, cy: float, rx: float, ry: float, n: int = 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(Vector2((cx + cos(a) * rx) * face, cy + sin(a) * ry))
	return pts

# Fledermaus-Fluegel, um die Schulter mit Sinus-Winkel "geschlagen" rotiert.
# scale_f staucht/streckt den Fluegel (fuer den ferneren, kleineren Fluegel).
func _wing(flap: float, scale_f: float) -> PackedVector2Array:
	var base := [
		Vector2(0, 0), Vector2(-4, -22), Vector2(-16, -34), Vector2(-30, -28),
		Vector2(-22, -15), Vector2(-30, -7), Vector2(-18, -5), Vector2(-8, -1),
	]
	var shoulder := Vector2(-2, -10)
	var ang := -0.15 + sin(flap) * 0.5
	var ca := cos(ang)
	var sa := sin(ang)
	var out := PackedVector2Array()
	for p in base:
		var q: Vector2 = p * scale_f
		var r := Vector2(q.x * ca - q.y * sa, q.x * sa + q.y * ca)
		var w := shoulder + r
		out.append(Vector2(w.x * face, w.y))
	return out
