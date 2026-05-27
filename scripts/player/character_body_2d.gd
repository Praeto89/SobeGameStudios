# =============================================================================
# player.gd
# =============================================================================
# Steuerskript fuer den Spieler-Charakter (CharacterBody2D).
#
# Abilities (freischaltbar per Pickup):
#   - Charge:       Langer Dash nach vorne (Taste: "charge")
#   - Wallcrawl:    An Waenden hoch-/runterklettern + Wall Jump
#   - Double Jump:  Zweiter Sprung in der Luft
#
# Movement-Features (immer aktiv):
#   - Variable Sprunghoehe    (kurz/lang druecken)
#   - Coyote Time             (kurz nach Plattformrand noch springen)
#   - Jump Buffer             (Sprung kurz vor Landen vorregistrieren)
#   - Schnellfall             (Pfeiltaste unten in der Luft)
#   - Reduzierte Luftkontrolle
#
# Signale:
#   health_changed(new_health)   -> wird von der UI abgehoert
#   coin_collected(new_count)    -> wird von der UI abgehoert
# =============================================================================

class_name Player extends CharacterBody2D

# -----------------------------------------------------------------------------
# Bewegungs-Konstanten
# -----------------------------------------------------------------------------
const SPEED = 150.0                 # Horizontale Laufgeschwindigkeit am Boden
const AIR_SPEED = 140.0             # Horizontale Geschwindigkeit in der Luft (leicht reduziert)
const JUMP_VELOCITY = -400.0        # Initialer Aufwaertsimpuls beim Springen (negativ = nach oben)
const JUMP_RELEASE_MULTIPLIER  = 2.5 # Gravity-Multiplikator wenn Sprung losgelassen wird (variable Hoehe)
const ROLL_SPEED = 300.0            # Geschwindigkeit waehrend des Rolls
const CHARGE_SPEED = 700.0          # Geschwindigkeit waehrend des Charge-Dashs
const CHARGE_DURATION = 0.5         # Sekunden die "charge" gehalten werden muss um auszuloesen
const CHARGE_MAX_TIME = 0.5         # Maximale Dauer des Charge-Dashs in Sekunden
const WALL_CRAWL_SPEED = 120.0      # Vertikale Klettergeschwindigkeit an der Wand
const WALL_JUMP_VELOCITY = Vector2(350.0, -450.0) # Horizontaler / vertikaler Impuls beim Wall Jump

# -----------------------------------------------------------------------------
# Gravity-Konstanten
# -----------------------------------------------------------------------------
const GRAVITY = 1800.0              # Basis-Gravity beim Steigen und normalen Fallen
const FALL_GRAVITY = 3000.0         # Erhoehte Gravity nach dem Sprung-Peak (schwereres Fallen)
const MAX_FALL_SPEED = 900.0        # Maximale Fallgeschwindigkeit (Terminal Velocity)
const FAST_FALL_SPEED = 1400.0      # Fallgeschwindigkeit bei Schnellfall (Pfeiltaste unten)

# -----------------------------------------------------------------------------
# Coyote Time & Jump Buffer
# -----------------------------------------------------------------------------
const COYOTE_TIME = 0.12            # Sekunden nach Plattformrand wo noch gesprungen werden kann
const JUMP_BUFFER_TIME = 0.12       # Sekunden vor dem Landen wo Sprung vorregistriert wird

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var animated_sprite = $AnimatedSprite2D
@onready var roll_hitbox := $"RollHitbox"

# -----------------------------------------------------------------------------
# Zustandsvariablen — Bewegung & Abilities
# -----------------------------------------------------------------------------
var is_rolling = false              # Ob der Spieler gerade rollt
var is_charging = false             # Ob der Charge-Dash aktiv ist
var charge_timer := 0.0             # Wie lange "charge" bereits gehalten wird (vor Ausloesung)
var charge_time_active := 0.0       # Wie lange der Charge-Dash bereits laeuft

# -----------------------------------------------------------------------------
# Zustandsvariablen — Spieler-Status
# -----------------------------------------------------------------------------
var spawn_position: Vector2         # Spawn-Position fuer Respawn
var max_health = 4                  # Maximale Lebenspunkte
var current_health = 4              # Aktuelle Lebenspunkte
var coin_count = 0                  # Gesammelte Muenzen
var is_hit := false                 # Ob der Spieler gerade im Treffer-Zustand ist
var hit_timer := 0.0                # Verbleibende Zeit des Treffer-Zustands
const HIT_DURATION = 0.6            # Dauer des Treffer-Zustands in Sekunden
var is_dead := false                # Ob der Spieler tot ist

# -----------------------------------------------------------------------------
# Ability-Flags — werden per Pickup freigeschaltet
# -----------------------------------------------------------------------------
var has_charge = false              # Charge-Ability freigeschaltet
var has_wallcrawl = false           # Wallcrawl-Ability freigeschaltet
var has_double_jump = false         # Double-Jump-Ability freigeschaltet

# -----------------------------------------------------------------------------
# Wallcrawl-Variablen
# -----------------------------------------------------------------------------
var is_wall_crawling = false        # Ob der Spieler gerade an einer Wand klebt
var last_wall_normal := Vector2.ZERO # Letzte bekannte Wandnormale (Richtung weg von der Wand)

# -----------------------------------------------------------------------------
# Double-Jump-Variablen
# -----------------------------------------------------------------------------
var can_double_jump = false         # Ob der Double Jump noch verfuegbar ist

# -----------------------------------------------------------------------------
# Coyote Time & Jump Buffer — Laufvariablen
# -----------------------------------------------------------------------------
var coyote_timer := 0.0             # Verbleibende Coyote-Zeit in Sekunden
var jump_buffer_timer := 0.0        # Verbleibende Jump-Buffer-Zeit in Sekunden
var was_on_floor := false           # Boden-Status des letzten Frames (fuer Coyote Time)
var is_jumping := false             # Ob ein Sprung aktiv gehalten wird

# -----------------------------------------------------------------------------
# Signale
# -----------------------------------------------------------------------------
signal health_changed(new_health)
signal coin_collected(new_count)

# =============================================================================
# _ready()
# Wird einmalig beim Start aufgerufen.
# Speichert die Startposition als Spawn-Punkt und aktiviert die Roll-Hitbox.
# =============================================================================
func _ready() -> void:
	spawn_position = global_position
	# Roll-Hitbox nur waehrend des Rolls aktiv (siehe Roll-Block in _physics_process).
	# Verhindert unnoetige Kollisions-Checks und Gegner-Treffer ausserhalb des Rolls.
	roll_hitbox.monitoring = false
	# Abilities aus dem GameManager laden, damit sie ueber Szenen-Wechsel
	# hinweg erhalten bleiben (Player wird beim Wechsel neu instanziiert).
	has_charge = GameManager.has_charge
	has_wallcrawl = GameManager.has_wallcrawl
	has_double_jump = GameManager.has_double_jump

# =============================================================================
# respawn()
# Setzt den Spieler auf den Spawn-Punkt zurueck und stellt alle
# Zustandsvariablen auf ihren Ausgangswert zurueck.
# Wird nach dem Tod aufgerufen.
# =============================================================================
func respawn() -> void:
	# Solange _die() noch laeuft (Death-Animation), keinen Respawn ausloesen.
	# Sonst kann z. B. eine Death-Area waehrend der Animation den Spieler
	# wiederbeleben und _die() raeumt danach nochmal auf -> inkonsistenter Zustand.
	if is_dead:
		return
	global_position = spawn_position
	velocity = Vector2.ZERO
	is_rolling = false
	is_charging = false
	charge_timer = 0.0
	charge_time_active = 0.0
	is_hit = false
	hit_timer = 0.0
	is_wall_crawling = false
	last_wall_normal = Vector2.ZERO
	can_double_jump = false
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	was_on_floor = false
	is_jumping = false
	roll_hitbox.monitoring = false
	$CollisionShape2D.set_deferred("disabled", false)

# =============================================================================
# take_damage(amount, knockback_direction)
# Zieht dem Spieler Leben ab und versetzt ihn in den Treffer-Zustand.
# Waehrend Roll, Charge oder Wallcrawl ist der Spieler unverwundbar.
#
# amount:               Anzahl der abzuziehenden Lebenspunkte
# knockback_direction:  Richtung des Rueckstosses (-1 = links, 1 = rechts, 0 = keiner)
# =============================================================================
func take_damage(amount: int, knockback_direction: float = 0.0) -> void:
	if is_hit or is_dead or is_rolling or is_charging or is_wall_crawling:
		return
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	emit_signal("health_changed", current_health)
	velocity.x = knockback_direction * 400.0
	velocity.y = -200.0
	if current_health <= 0:
		_die()
		return
	is_hit = true
	hit_timer = HIT_DURATION

# =============================================================================
# _die()
# Wird aufgerufen wenn die Lebenspunkte auf 0 fallen.
# Spielt die Todesanimation ab, verlangsamt kurz die Zeit (Dramatik),
# und loest danach den Respawn aus.
# =============================================================================
func _die() -> void:
	is_dead = true
	is_rolling = false
	is_charging = false
	is_wall_crawling = false
	last_wall_normal = Vector2.ZERO
	can_double_jump = false
	is_jumping = false
	charge_timer = 0.0
	charge_time_active = 0.0
	velocity.x = 0
	roll_hitbox.monitoring = false
	$CollisionShape2D.set_deferred("disabled", true)
	Engine.time_scale = 0.5
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	Engine.time_scale = 1.0
	# is_dead VOR respawn() zuruecksetzen, damit respawn() nicht durch
	# seinen eigenen is_dead-Schutz abgewiesen wird.
	is_dead = false
	respawn()
	current_health = max_health
	emit_signal("health_changed", current_health)

# =============================================================================
# collect_coin()
# Erhoeht den Muenzen-Zaehler um 1 und sendet das Signal an die UI.
# Wird vom Coin-Objekt aufgerufen wenn der Spieler es beruehrt.
# =============================================================================
func collect_coin() -> void:
	coin_count += 1
	emit_signal("coin_collected", coin_count)

# =============================================================================
# unlock_charge() / unlock_wallcrawl() / unlock_double_jump()
# Schaltet die jeweilige Ability frei.
# Wird vom entsprechenden Pickup-Objekt aufgerufen.
# =============================================================================
func unlock_charge() -> void:
	has_charge = true
	GameManager.has_charge = true

func unlock_wallcrawl() -> void:
	has_wallcrawl = true
	GameManager.has_wallcrawl = true

func unlock_double_jump() -> void:
	has_double_jump = true
	GameManager.has_double_jump = true

# =============================================================================
# _physics_process(delta)
# Hauptschleife — laeuft jeden Physik-Frame.
# Verarbeitet in dieser Reihenfolge:
#   1. Tod-Zustand
#   2. Treffer-Timer
#   3. Coyote Time
#   4. Jump Buffer
#   5. Wallcrawl-Erkennung
#   6. Gravity
#   7. Springen (inkl. Wall Jump & Double Jump)
#   8. Roll
#   9. Charge
#  10. Horizontale Bewegung
#  11. move_and_slide + Animation
# =============================================================================
func _physics_process(delta: float) -> void:

	# --- 1. Tod: nur Gravity + Slide, kein Input ---
	if is_dead:
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		move_and_slide()
		return

	# --- 2. Treffer-Timer herunterzaehlen ---
	if hit_timer > 0:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit = false

	# --- 3. Coyote Time ---
	# Wenn der Spieler gerade vom Boden weggelaufen ist (nicht gesprungen),
	# startet ein kurzes Zeitfenster in dem noch gesprungen werden kann.
	if was_on_floor and not is_on_floor() and not is_jumping:
		coyote_timer = COYOTE_TIME
	if coyote_timer > 0:
		coyote_timer -= delta
	was_on_floor = is_on_floor()

	# --- 4. Jump Buffer ---
	# Sprung-Taste wird registriert auch wenn man noch nicht ganz gelandet ist.
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# --- 5. Wallcrawl-Erkennung ---
	# Wallcrawl ist aktiv wenn: Ability freigeschaltet, an einer Wand,
	# nicht am Boden, nicht in Charge oder Roll.
	if has_wallcrawl and is_on_wall() and not is_on_floor() and not is_charging and not is_rolling:
		is_wall_crawling = true
		last_wall_normal = get_wall_normal() # Wandrichtung speichern fuer Wall Jump
	else:
		is_wall_crawling = false

	# --- 6. Gravity ---
	# Verschiedene Gravity-Werte je nach Zustand fuer ein natuerliches Gefuehl:
	# - Schnellfall:     sehr schnell wenn Pfeiltaste unten
	# - Fallen:          schwerere Gravity nach Sprung-Peak
	# - Sprung halten:   leichtere Gravity beim Aufstieg
	# - Sprung loslassen: Aufstieg wird abgebremst (variable Sprunghoehe)
	if not is_on_floor() and not is_wall_crawling and not is_charging and charge_time_active <= 0:
		var fast_fall = Input.is_action_pressed("ui_down") and velocity.y > 0
		if fast_fall:
			velocity.y = min(velocity.y + FAST_FALL_SPEED * delta, FAST_FALL_SPEED)
		elif velocity.y > 0:
			velocity.y = min(velocity.y + FALL_GRAVITY * delta, MAX_FALL_SPEED)
		elif not Input.is_action_pressed("ui_accept") and velocity.y < 0:
			velocity.y += GRAVITY * JUMP_RELEASE_MULTIPLIER * delta
		else:
			velocity.y += GRAVITY * delta

	# --- 7. Springen ---
	# Prioritaet: Boden/Coyote > Wall Jump > Double Jump
	var can_jump = is_on_floor() or coyote_timer > 0
	if jump_buffer_timer > 0 and can_jump and not is_wall_crawling:
		# Normaler Sprung (mit Jump Buffer und Coyote Time)
		velocity.y = JUMP_VELOCITY
		can_double_jump = true
		is_jumping = true
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	elif Input.is_action_just_pressed("ui_accept"):
		if is_wall_crawling:
			# Wall Jump: von der Wand wegspringen
			velocity.x = last_wall_normal.x * WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y
			is_wall_crawling = false
			can_double_jump = true
			is_jumping = true
		elif has_double_jump and can_double_jump:
			# Double Jump: zweiter Sprung in der Luft
			velocity.y = JUMP_VELOCITY
			can_double_jump = false
			is_jumping = true

	# Sprung-Flag zuruecksetzen wenn gelandet
	if is_on_floor():
		is_jumping = false

	# --- 8. Roll ---
	# Nur am Boden auslösbar. Waehrend des Rolls werden Gegner per Hitbox getroffen.
	# Hitbox wird mit dem Roll aktiviert/deaktiviert, damit sie ausserhalb des Rolls
	# keine Gegner toetet.
	if Input.is_action_just_pressed("ui_shift") and is_on_floor():
		is_rolling = true
		roll_hitbox.monitoring = true
	if Input.is_action_just_released("ui_shift"):
		is_rolling = false
		roll_hitbox.monitoring = false

	# --- 9. Charge ---
	# "charge" halten laedt auf. Nach CHARGE_DURATION wird der Dash ausgeloest.
	# Charge wird abgebrochen wenn Wand, Decke oder Boden getroffen wird.
	if Input.is_action_pressed("charge") and has_charge and not is_rolling and not is_charging and not is_wall_crawling:
		charge_timer += delta
		if charge_timer >= CHARGE_DURATION:
			is_charging = true
			charge_timer = 0.0
			velocity.y = -900.0
	if Input.is_action_just_released("charge") and not is_charging:
		charge_timer = 0.0

	# --- 10. Horizontale Bewegung ---
	var direction := Input.get_axis("ui_left", "ui_right")

	if is_wall_crawling:
		# Wallcrawl: nur vertikale Bewegung, leichter Druck in die Wand
		var vertical := Input.get_axis("ui_up", "ui_down")
		velocity.y = vertical * WALL_CRAWL_SPEED
		velocity.x = -last_wall_normal.x * 50.0
	elif is_rolling:
		# Roll: fixe Geschwindigkeit in Blickrichtung, Gegner-Hitbox pruefen
		var roll_dir = -1.0 if animated_sprite.flip_h else 1.0
		velocity.x = roll_dir * ROLL_SPEED
		for body in roll_hitbox.get_overlapping_bodies():
			if body == self:
				continue
			if body.is_in_group("enemy"):
				body.die()
			elif body.get_parent().is_in_group("enemy"):
				body.get_parent().die()
	elif is_charging:
		# Charge: schneller Dash in Blickrichtung, Gravity wird gedaempft
		charge_time_active += delta
		var charge_dir = -1.0 if animated_sprite.flip_h else 1.0
		velocity.x = charge_dir * CHARGE_SPEED
		velocity.y = move_toward(velocity.y, 0, 300)
		if charge_time_active >= CHARGE_MAX_TIME:
			is_charging = false
			charge_time_active = 0.0
		elif charge_time_active > 0.1:
			if is_on_wall() or is_on_ceiling() or is_on_floor():
				is_charging = false
				charge_time_active = 0.0
	elif direction:
		# Normale Bewegung: leicht reduzierte Geschwindigkeit in der Luft
		var target_speed = SPEED if is_on_floor() else AIR_SPEED
		velocity.x = direction * target_speed
		animated_sprite.flip_h = direction < 0
	else:
		# Kein Input: abremsen
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# --- 11. Physik anwenden und Animation aktualisieren ---
	move_and_slide()
	_update_animation()

# =============================================================================
# _update_animation()
# Bestimmt welche Animation abgespielt wird basierend auf dem aktuellen Zustand.
# Prioritaet (hoch → tief):
#   Tod → Treffer → Charge-Aufladung → Roll → Charge → Wallcrawl →
#   Double Jump → Sprung → Laufen → Idle
# =============================================================================
func _update_animation() -> void:
	if is_dead:
		return

	# Treffer-Animation hat hoechste Prioritaet (ausser Tod)
	if is_hit:
		if animated_sprite.animation != "hit":
			animated_sprite.play("hit")
		return

	# Charge wird aufgeladen (Taste gehalten, noch nicht ausgeloest)
	if charge_timer > 0 and not is_charging:
		if animated_sprite.animation != "charge_pickup":
			animated_sprite.play("charge_pickup")
		return

	# Roll-Animation
	if is_rolling:
		if animated_sprite.animation != "roll":
			animated_sprite.play("roll")
		return

	# Charge-Dash-Animation
	if is_charging:
		if animated_sprite.animation != "charge":
			animated_sprite.play("charge")
		return

	# Wallcrawl: Klettern-Animation nur wenn Bewegung, sonst Idle
	if is_wall_crawling:
		if velocity.y != 0:
			if animated_sprite.animation != "wallcrawl":
				animated_sprite.play("wallcrawl")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
		return

	# Double Jump: eigene Animation waehrend des zweiten Sprungs
	if not is_on_floor() and not can_double_jump and has_double_jump:
		if animated_sprite.animation != "double_jump":
			animated_sprite.play("double_jump")
		return

	# Standard-Animationen: Sprung / Laufen / Idle
	if not is_on_floor():
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif velocity.x != 0:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
