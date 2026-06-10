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

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  DEIN SPIELFELD – hier kannst du sicher experimentieren!                ║
# ║  Aendere einen Wert, druecke F5 und schau was passiert.                 ║
# ║  Nichts kann hier kaputt gehen – Strg+Z setzt alles zurueck.            ║
# ║  Tipp: immer nur EINEN Wert auf einmal aendern, sonst weisst du         ║
# ║  nicht welche Aenderung welchen Effekt hatte.                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# -----------------------------------------------------------------------------
# Bewegungs-Konstanten
# -----------------------------------------------------------------------------
const SPEED = 175.0                 # Laufgeschwindigkeit  <- probier: 80 (langsam) oder 300 (schnell)
const AIR_SPEED = 140.0             # Geschwindigkeit in der Luft  <- kleiner als SPEED = traegere Luft
const JUMP_VELOCITY = -520.0        # Sprungkraft (negativ = nach oben!)  <- probier: -250 oder -600
const JUMP_RELEASE_MULTIPLIER  = 2.5 # Gravity-Multiplikator wenn Sprung losgelassen wird (variable Hoehe)
const ROLL_SPEED = 300.0            # Geschwindigkeit waehrend des Rolls
const CHARGE_SPEED = 700.0          # Geschwindigkeit waehrend des Charge-Dashs  <- probier: 400 oder 1200
const CHARGE_DURATION = 0.5         # Sekunden die "charge" gehalten werden muss um auszuloesen
const CHARGE_MAX_TIME = 0.5         # Maximale Dauer des Charge-Dashs in Sekunden
const WALL_CRAWL_SPEED = 120.0      # Vertikale Klettergeschwindigkeit an der Wand
const WALL_JUMP_VELOCITY = Vector2(350.0, -450.0) # Horizontaler / vertikaler Impuls beim Wall Jump
const WALL_CRAWL_PRESS_FORCE = 50.0 # Leichter Andruck in die Wand waehrend des Kletterns
const CHARGE_LAUNCH_VELOCITY = -900.0 # Aufwaerts-Impuls im Moment der Charge-Ausloesung
const KNOCKBACK_VELOCITY = Vector2(400.0, -200.0) # Rueckstoss bei einem Treffer (x wird mit Richtung multipliziert)
const ATTACK_DURATION = 0.35        # Sekunden die eine Attacke dauert (Hitbox aktiv)  <- probier: 0.2 (schnell) oder 0.6 (lang)
const ATTACK_HITBOX_OFFSET = 14.0   # Wie weit vor dem Spieler die Angriffs-Hitbox liegt (in Blickrichtung)

# -----------------------------------------------------------------------------
# Upgrade-Faktoren (Upgrade-Tor, siehe upgrade_gate.gd + GameManager)
# -----------------------------------------------------------------------------
# Diese Faktoren werden in apply_upgrades() auf die Basiswerte oben angewendet,
# wenn das jeweilige Upgrade gekauft wurde. Die Basis-Konstanten bleiben
# unveraendert -- die effektiven Werte stehen in den var-Variablen weiter unten.
const JUMP_UPGRADE_MULTIPLIER = 1.18         # Hoeherer Sprung (negativer = hoeher)
const CHARGE_SPEED_UPGRADE_MULTIPLIER = 1.4  # Schnellerer Charge-Dash
const CHARGE_TIME_UPGRADE_MULTIPLIER = 1.5   # Laengerer Charge-Dash
const ATTACK_REACH_UPGRADE = 8.0             # Zusaetzliche Reichweite der Attacke (Offset)
const ATTACK_HITBOX_UPGRADE_SCALE = 1.6      # Groessere Angriffs-Hitbox

# -----------------------------------------------------------------------------
# Gravity-Konstanten
# -----------------------------------------------------------------------------
const GRAVITY = 1800.0              # Schwerkraft beim Aufstieg  <- probier: 500 (Mondgravity) oder 4000 (Bleiklotz)
const FALL_GRAVITY = 3000.0         # Erhoehte Gravity nach dem Sprung-Peak (schwereres Fallen)
const MAX_FALL_SPEED = 900.0        # Maximale Fallgeschwindigkeit (Terminal Velocity)
const FAST_FALL_SPEED = 1400.0      # Fallgeschwindigkeit bei Schnellfall (Pfeiltaste unten)

# -----------------------------------------------------------------------------
# Coyote Time & Jump Buffer
# -----------------------------------------------------------------------------
const COYOTE_TIME = 0.12            # Sekunden nach Plattformrand wo noch gesprungen werden kann
const JUMP_BUFFER_TIME = 0.12       # Sekunden vor dem Landen wo Sprung vorregistriert wird

# -----------------------------------------------------------------------------
# Effekt-Konstanten (Game Feel) — rein optisch, beeinflussen keine Physik
# -----------------------------------------------------------------------------
# "Squash & Stretch" ist ein Klassiker aus der Trick-Animation: beim Absprung
# wird die Figur kurz schmal+hoch (gestreckt), beim Aufprall breit+flach
# (gestaucht). Das verkauft Schwung und Wucht – ganz ohne neue Sprites.
# Die Werte sind FAKTOREN auf die Grund-Skalierung des Sprites (1,1 = normal).
const JUMP_STRETCH_SCALE := Vector2(0.82, 1.18)   # Absprung: schmal & hoch  <- probier (0.7, 1.3)
const LANDING_SQUASH_SCALE := Vector2(1.25, 0.75) # Aufprall: breit & flach  <- probier (1.4, 0.6)
const SQUASH_RECOVER_TIME := 0.22                 # Sekunden bis das Sprite zurueckfedert
const LANDING_SQUASH_MIN_SPEED := 250.0           # Erst ab dieser Fallgeschwindigkeit stauchen
const HIT_FLASH_COLOR := Color(2.5, 0.6, 0.6)     # Treffer-Aufleuchten (>1 = leuchtet dank Glow)
const HIT_FLASH_FADE := 0.25                      # Sekunden bis der rote Blitz wieder abklingt

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var animated_sprite = $AnimatedSprite2D
@onready var roll_hitbox := $"RollHitbox"
@onready var attack_hitbox := $"AttackHitbox"
@onready var sound_jump := $SoundJump
@onready var sound_hurt := $SoundHurt
@onready var sound_death := $SoundDeath
@onready var sound_attack := $SoundAttack

# -----------------------------------------------------------------------------
# Zustandsvariablen — Bewegung & Abilities
# -----------------------------------------------------------------------------
var is_rolling = false              # Ob der Spieler gerade rollt
var is_charging = false             # Ob der Charge-Dash aktiv ist
var charge_timer := 0.0             # Wie lange "charge" bereits gehalten wird (vor Ausloesung)
var charge_time_active := 0.0       # Wie lange der Charge-Dash bereits laeuft
var is_attacking := false           # Ob der Spieler gerade attackiert (Hitbox aktiv)
var attack_timer := 0.0             # Verbleibende Zeit der aktuellen Attacke
var attack_facing_left := false     # Blickrichtung beim Start der Attacke (true = links)
var attack_from_air := false        # War der Spieler beim Start der Attacke in der Luft? (Luft-Attacke nach unten)

# -----------------------------------------------------------------------------
# Zustandsvariablen — Spieler-Status
# -----------------------------------------------------------------------------
var spawn_position: Vector2         # Spawn-Position fuer Respawn
var max_health = GameManager.MAX_HEALTH  # Maximale Lebenspunkte (eine Quelle der Wahrheit: GameManager)
var current_health = GameManager.MAX_HEALTH  # Aktuelle Lebenspunkte
var coin_count = 0                  # Gesammelte Muenzen
var is_hit := false                 # Ob der Spieler gerade im Treffer-Zustand ist
var hit_timer := 0.0                # Verbleibende Zeit des Treffer-Zustands
const HIT_DURATION = 0.6            # Dauer des Treffer-Zustands in Sekunden
var is_dead := false                # Ob der Spieler tot ist
var _death_slowmo := false          # Ob gerade die Death-Zeitlupe (Engine.time_scale) aktiv ist

# -----------------------------------------------------------------------------
# Ability-Flags — werden per Pickup freigeschaltet
# -----------------------------------------------------------------------------
var has_charge = false              # Charge-Ability freigeschaltet
var has_wallcrawl = false           # Wallcrawl-Ability freigeschaltet
var has_double_jump = false         # Double-Jump-Ability freigeschaltet

# -----------------------------------------------------------------------------
# Effektive Ability-Werte — Basiswert, ggf. durch ein Upgrade verstaerkt
# -----------------------------------------------------------------------------
# Im _physics_process werden diese Variablen statt der Basis-Konstanten benutzt.
# apply_upgrades() setzt sie beim Start und nach jedem Kauf im Upgrade-Tor.
var jump_velocity := JUMP_VELOCITY            # effektive Sprungkraft
var charge_speed := CHARGE_SPEED              # effektive Charge-Geschwindigkeit
var charge_max_time := CHARGE_MAX_TIME        # effektive Charge-Dauer
var attack_hitbox_offset := ATTACK_HITBOX_OFFSET  # effektive Angriffs-Reichweite

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
# Effekt-Laufvariablen (Squash & Stretch, Treffer-Blitz)
# -----------------------------------------------------------------------------
var _base_sprite_scale := Vector2.ONE  # Grund-Skalierung des Sprites (in _ready gemerkt)
var _fx_prev_on_floor := true          # Boden-Status des letzten Frames (fuer Landungs-Erkennung)
var _fx_last_fall_speed := 0.0         # Fallgeschwindigkeit kurz vor der Landung
var _squash_tween: Tween = null        # Laufende Squash/Stretch-Animation (zum Abbrechen)
var _flash_tween: Tween = null         # Laufende Treffer-Blitz-Animation (zum Abbrechen)

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
	# Grund-Skalierung des Sprites merken, damit Squash & Stretch immer dorthin
	# zurueckfedert (statt fest auf 1,1 – falls jemand das Sprite skaliert hat).
	_base_sprite_scale = animated_sprite.scale
	# Roll-Hitbox nur waehrend des Rolls aktiv (siehe Roll-Block in _physics_process).
	# Verhindert unnoetige Kollisions-Checks und Gegner-Treffer ausserhalb des Rolls.
	roll_hitbox.monitoring = false
	# Angriffs-Hitbox ebenfalls nur waehrend einer Attacke aktiv (siehe Attacke-Block).
	attack_hitbox.monitoring = false
	# Persistierten Zustand aus dem GameManager laden, damit Abilities,
	# Leben und Muenzen ueber Szenen-Wechsel hinweg erhalten bleiben.
	has_charge = GameManager.has_charge
	has_wallcrawl = GameManager.has_wallcrawl
	has_double_jump = GameManager.has_double_jump
	current_health = GameManager.current_health
	coin_count = GameManager.coin_count
	# Gekaufte Upgrades aus dem GameManager auf die effektiven Werte anwenden.
	apply_upgrades()
	# HUD initial befuellen (sonst zeigt es kurz die Default-Werte)
	call_deferred("emit_signal", "health_changed", current_health)
	call_deferred("emit_signal", "coin_collected", coin_count)

# =============================================================================
# _exit_tree()
# Sicherheitsnetz: Wird der Spieler waehrend der Death-Zeitlupe aus dem Baum
# entfernt (z. B. durch einen Szenenwechsel mitten in der Death-Animation),
# kommt das await in _die() nie zurueck und Engine.time_scale bliebe bei 0.5
# haengen -> das ganze Spiel liefe dauerhaft in Zeitlupe. Hier setzen wir die
# globale Zeit defensiv wieder auf Normalgeschwindigkeit zurueck.
# =============================================================================
func _exit_tree() -> void:
	if _death_slowmo:
		Engine.time_scale = 1.0
		_death_slowmo = false

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
	is_attacking = false
	attack_timer = 0.0
	attack_hitbox.monitoring = false
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
	# Effekt-Zustand zuruecksetzen: ein evtl. laufender Squash/Flash-Tween
	# wuerde sonst beim Respawn ein verzerrtes/rotes Sprite hinterlassen.
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	animated_sprite.scale = _base_sprite_scale
	animated_sprite.modulate = Color.WHITE
	_fx_prev_on_floor = true
	# WARUM set_deferred statt .disabled = false direkt?
	# Wir sind im Physik-Frame (move_and_slide laeuft gerade). Kollisions-
	# Shapes darf man dort nicht direkt aendern – Godot wirft sonst einen
	# Fehler. set_deferred("disabled", false) verzoegert die Aenderung
	# auf den naechsten sicheren Moment (nach dem Physik-Schritt).
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
	GameManager.current_health = current_health
	emit_signal("health_changed", current_health)
	velocity.x = knockback_direction * KNOCKBACK_VELOCITY.x
	velocity.y = KNOCKBACK_VELOCITY.y
	if current_health <= 0:
		_die()
		return
	sound_hurt.play()
	_flash_hit()                    # Effekt: kurz rot aufleuchten
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
	is_attacking = false
	attack_timer = 0.0
	attack_hitbox.monitoring = false
	is_wall_crawling = false
	last_wall_normal = Vector2.ZERO
	can_double_jump = false
	is_jumping = false
	charge_timer = 0.0
	charge_time_active = 0.0
	velocity.x = 0
	roll_hitbox.monitoring = false
	$CollisionShape2D.set_deferred("disabled", true)
	sound_death.play()
	_death_slowmo = true
	Engine.time_scale = 0.5
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	Engine.time_scale = 1.0
	_death_slowmo = false
	# is_dead VOR respawn() zuruecksetzen, damit respawn() nicht durch
	# seinen eigenen is_dead-Schutz abgewiesen wird.
	is_dead = false
	respawn()
	current_health = max_health
	GameManager.current_health = max_health
	emit_signal("health_changed", current_health)

# =============================================================================
# collect_coin()
# Erhoeht den Muenzen-Zaehler um 1 und sendet das Signal an die UI.
# Wird vom Coin-Objekt aufgerufen wenn der Spieler es beruehrt.
# =============================================================================
func collect_coin() -> void:
	coin_count += 1
	GameManager.coin_count = coin_count
	emit_signal("coin_collected", coin_count)

# =============================================================================
# heal(amount)
# Fuellt Lebenspunkte wieder auf (Gegenstueck zu take_damage).
# Wird z. B. von einem Heil-Pickup aufgerufen (siehe AUFGABEN.md -> A4).
#
# amount: Anzahl der aufzufuellenden Lebenspunkte (Standard: 1)
#
# Wie bei take_damage wird auf max_health begrenzt und GameManager + HUD
# (per health_changed) auf dem aktuellen Stand gehalten. Bei einem toten
# Spieler passiert nichts.
# =============================================================================
func heal(amount: int = 1) -> void:
	if is_dead:
		return
	current_health = clamp(current_health + amount, 0, max_health)
	GameManager.current_health = current_health
	emit_signal("health_changed", current_health)

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
# apply_upgrades()
# Liest die im Upgrade-Tor gekauften Upgrade-Flags aus dem GameManager und
# berechnet daraus die effektiven Ability-Werte. Wird einmal in _ready() und
# nach jedem Kauf (upgrade_gate.gd) aufgerufen, damit ein frisch gekauftes
# Upgrade sofort wirkt.
# =============================================================================
func apply_upgrades() -> void:
	jump_velocity = JUMP_VELOCITY * (JUMP_UPGRADE_MULTIPLIER if GameManager.upgrade_jump else 1.0)
	charge_speed = CHARGE_SPEED * (CHARGE_SPEED_UPGRADE_MULTIPLIER if GameManager.upgrade_charge else 1.0)
	charge_max_time = CHARGE_MAX_TIME * (CHARGE_TIME_UPGRADE_MULTIPLIER if GameManager.upgrade_charge else 1.0)
	attack_hitbox_offset = ATTACK_HITBOX_OFFSET + (ATTACK_REACH_UPGRADE if GameManager.upgrade_attack else 0.0)
	# Groessere Angriffs-Hitbox: die ganze AttackHitbox-Area skalieren.
	var atk_scale = ATTACK_HITBOX_UPGRADE_SCALE if GameManager.upgrade_attack else 1.0
	attack_hitbox.scale = Vector2(atk_scale, atk_scale)
	# Lebens-Maximum (Health-Upgrade); aktuelle Leben nie ueber das Maximum.
	max_health = GameManager.get_max_health()
	current_health = min(current_health, max_health)

# =============================================================================
# spend_coins(amount)
# Zieht Muenzen ab (Gegenstueck zu collect_coin) und haelt GameManager + HUD
# ueber das coin_collected-Signal aktuell. Wird vom Upgrade-Tor beim Kauf
# aufgerufen.
# =============================================================================
func spend_coins(amount: int) -> void:
	coin_count = max(0, coin_count - amount)
	GameManager.coin_count = coin_count
	emit_signal("coin_collected", coin_count)

# =============================================================================
# _play_squash(ziel_faktor, dauer)
# Spielt einen Squash-&-Stretch-Effekt: setzt das Sprite sofort auf eine
# verzerrte Skalierung (z. B. breit & flach) und laesst es dann elastisch in
# seine Grund-Skalierung zurueckfedern. Rein optisch – die Kollision (eigener
# CollisionShape2D-Knoten) bleibt unveraendert.
#
# ziel_faktor: Start-Verzerrung als Faktor auf _base_sprite_scale
# dauer:       Sekunden bis das Sprite zurueckgefedert ist
# =============================================================================
func _play_squash(ziel_faktor: Vector2, dauer: float) -> void:
	# Laufenden Effekt abbrechen, damit sich zwei Tweens nicht ueberlagern.
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()
	animated_sprite.scale = _base_sprite_scale * ziel_faktor
	# TRANS_ELASTIC + EASE_OUT = federt am Ende leicht ueber -> wirkt "lebendig".
	_squash_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_squash_tween.tween_property(animated_sprite, "scale", _base_sprite_scale, dauer)

# =============================================================================
# _flash_hit()
# Laesst das Spieler-Sprite bei einem Treffer kurz rot aufleuchten und wieder
# zur Normalfarbe (Weiss) abklingen. Nutzt dieselbe Idee wie die HUD-Herzen
# (hud.gd) – ein modulate-Wert > 1 leuchtet dank Glow-Environment richtig auf.
# =============================================================================
func _flash_hit() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	animated_sprite.modulate = HIT_FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, HIT_FLASH_FADE)

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
	# Laeufst du ueber den Rand einer Plattform, bist du fuer einen kurzen
	# Moment in der Luft, obwohl du subjektiv "noch auf der Plattform" warst.
	# Ohne Coyote Time wuerde der Sprung in diesem Moment versagen – das
	# fuehlt sich ungerecht an. Mit COYOTE_TIME = 0.12 s vergibt das Spiel
	# diesen Fehler und erlaubt den Sprung trotzdem. Das ist ein Standard-
	# Trick in fast jedem kommerziellen 2D-Plattformer.
	if was_on_floor and not is_on_floor() and not is_jumping:
		coyote_timer = COYOTE_TIME
	if coyote_timer > 0:
		coyote_timer -= delta
	was_on_floor = is_on_floor()

	# --- 4. Jump Buffer ---
	# Drueckst du Springen kurz BEVOR du landest, merkt das Spiel es trotzdem.
	# Ohne Buffer muesste das Timing pixelgenau stimmen – das ist frustrierend.
	# Mit JUMP_BUFFER_TIME = 0.12 s gilt: "Ich wollte springen" gilt auch fuer
	# die naechsten 120 ms, falls du gerade noch in der Luft warst.
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
	if not is_on_floor() and not is_wall_crawling:
		if is_charging:
			# Waehrend des Charge-Bogens: normale Gravity ohne Multiplikatoren,
			# damit der Aufwaerts-Impuls natuerlich in einen Bogen uebergeht.
			velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		elif charge_time_active <= 0:
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
		velocity.y = jump_velocity
		can_double_jump = true
		is_jumping = true
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		pass  # sound_jump.play() -- Sprung-Sound deaktiviert (zu nervig); zum Reaktivieren diese Zeile wieder zu sound_jump.play() machen
		_play_squash(JUMP_STRETCH_SCALE, SQUASH_RECOVER_TIME)  # Effekt: Absprung-Stretch
	elif Input.is_action_just_pressed("ui_accept"):
		if is_wall_crawling:
			# Wall Jump: von der Wand wegspringen
			velocity.x = last_wall_normal.x * WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y
			is_wall_crawling = false
			can_double_jump = true
			is_jumping = true
			pass  # sound_jump.play() -- Sprung-Sound deaktiviert (zu nervig); zum Reaktivieren diese Zeile wieder zu sound_jump.play() machen
			_play_squash(JUMP_STRETCH_SCALE, SQUASH_RECOVER_TIME)  # Effekt: Wall-Jump-Stretch
		elif has_double_jump and can_double_jump:
			# Double Jump: zweiter Sprung in der Luft
			velocity.y = jump_velocity
			can_double_jump = false
			is_jumping = true
			pass  # sound_jump.play() -- Sprung-Sound deaktiviert (zu nervig); zum Reaktivieren diese Zeile wieder zu sound_jump.play() machen
			_play_squash(JUMP_STRETCH_SCALE, SQUASH_RECOVER_TIME)  # Effekt: Double-Jump-Stretch

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
			velocity.y = CHARGE_LAUNCH_VELOCITY
	if Input.is_action_just_released("charge") and not is_charging:
		charge_timer = 0.0

	# --- 9b. Attacke ---
	# "attack" (Taste X) loest einen Nahkampf-Schlag aus. Waehrend der Attacke
	# ist die AttackHitbox vor dem Spieler aktiv und toetet getroffene Gegner.
	# Nicht ausloesbar waehrend Roll, Charge, Wallcrawl oder im Treffer-Zustand.
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_rolling and not is_charging and not is_wall_crawling and not is_hit:
		is_attacking = true
		attack_timer = ATTACK_DURATION
		attack_hitbox.monitoring = true
		# Blickrichtung beim Start merken (flip_h = true bedeutet: schaut nach links)
		attack_facing_left = animated_sprite.flip_h
		# In der Luft? -> Attacke nach unten (eigene, einmalige Animation)
		attack_from_air = not is_on_floor()
		# Animation sofort starten (auch fuer korrekten is_playing()-Status der
		# Luft-Attacke schon im selben Frame, sonst wuerde sie unten faelschlich
		# als "fertig" gewertet, wenn noch der alte Animationszustand anliegt).
		animated_sprite.flip_h = attack_facing_left
		animated_sprite.play("attack_from_above" if attack_from_air else "attack")
		sound_attack.play()
	if is_attacking:
		# Hitbox in Blickrichtung vor den Spieler setzen
		attack_hitbox.position.x = -attack_hitbox_offset if attack_facing_left else attack_hitbox_offset
		# Getroffene Gegner toeten (gleiche Logik wie beim Roll)
		for body in attack_hitbox.get_overlapping_bodies():
			if body == self:
				continue
			if body.is_in_group(GameConstants.GROUP_ENEMY):
				body.die()
			elif body.get_parent() and body.get_parent().is_in_group(GameConstants.GROUP_ENEMY):
				body.get_parent().die()
		# Ende der Attacke:
		#  - Boden-Attacke: nach fester Dauer (ATTACK_DURATION, Animation loopt)
		#  - Luft-Attacke:  wenn die einmalige attack_from_above-Animation
		#                   (Stich -> Schwert herausziehen) durchgelaufen ist
		var attack_done := false
		if attack_from_air:
			attack_done = animated_sprite.animation == "attack_from_above" and not animated_sprite.is_playing()
		else:
			attack_timer -= delta
			attack_done = attack_timer <= 0
		if attack_done:
			is_attacking = false
			attack_hitbox.monitoring = false
			# Blickrichtung wiederherstellen, damit Idle/Lauf (nutzen flip_h)
			# danach in die richtige Richtung schauen.
			animated_sprite.flip_h = attack_facing_left

	# --- 10. Horizontale Bewegung ---
	var direction := Input.get_axis("ui_left", "ui_right")

	if is_wall_crawling:
		# Wallcrawl: nur vertikale Bewegung, leichter Druck in die Wand
		var vertical := Input.get_axis("ui_up", "ui_down")
		velocity.y = vertical * WALL_CRAWL_SPEED
		velocity.x = -last_wall_normal.x * WALL_CRAWL_PRESS_FORCE
	elif is_rolling:
		# Roll: fixe Geschwindigkeit in Blickrichtung, Gegner-Hitbox pruefen
		var roll_dir = -1.0 if animated_sprite.flip_h else 1.0
		velocity.x = roll_dir * ROLL_SPEED
		for body in roll_hitbox.get_overlapping_bodies():
			if body == self:
				continue
			if body.is_in_group(GameConstants.GROUP_ENEMY):
				body.die()
			elif body.get_parent().is_in_group(GameConstants.GROUP_ENEMY):
				body.get_parent().die()
	elif is_charging:
		# Charge: schneller Dash in Blickrichtung, Bogen durch Gravity (kein Daempfen)
		charge_time_active += delta
		var charge_dir = -1.0 if animated_sprite.flip_h else 1.0
		velocity.x = charge_dir * charge_speed
		if charge_time_active >= charge_max_time:
			is_charging = false
			charge_time_active = 0.0
		elif charge_time_active > 0.1:
			if is_on_wall() or is_on_ceiling() or is_on_floor():
				is_charging = false
				charge_time_active = 0.0
	elif direction:
		# Normale Bewegung: leicht reduzierte Geschwindigkeit in der Luft
		var target_speed = SPEED if is_on_floor() else AIR_SPEED
		if is_on_floor():
			velocity.x = direction * target_speed
		else:
			# Leichte Lufttraegheit: Richtungswechsel braucht ~0.17s (HK-feel)
			velocity.x = move_toward(velocity.x, direction * target_speed, AIR_SPEED * 6.0 * delta)
		animated_sprite.flip_h = direction < 0
	else:
		# Kein Input: abremsen
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# --- 11. Physik anwenden und Animation aktualisieren ---
	# Fallgeschwindigkeit VOR move_and_slide merken: beim Bodenkontakt setzt
	# move_and_slide velocity.y zurueck, danach waere die Wucht nicht mehr ablesbar.
	_fx_last_fall_speed = velocity.y
	move_and_slide()

	# --- 12. Effekt: Landungs-Squash ---
	# Genau in dem Frame, in dem aus "in der Luft" ein Bodenkontakt wird, und
	# nur wenn schnell genug gefallen wurde, das Sprite kurz stauchen.
	var on_floor_now := is_on_floor()
	if on_floor_now and not _fx_prev_on_floor and _fx_last_fall_speed > LANDING_SQUASH_MIN_SPEED:
		_play_squash(LANDING_SQUASH_SCALE, SQUASH_RECOVER_TIME)
	_fx_prev_on_floor = on_floor_now

	_update_animation()

# =============================================================================
# _update_animation()
# Bestimmt welche Animation abgespielt wird basierend auf dem aktuellen Zustand.
# Prioritaet (hoch → tief):
#   Tod → Treffer → Attacke → Charge-Aufladung → Roll → Charge → Wallcrawl →
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

	# Attacke-Animation. Am Boden: "attack" (Schlag zur Seite); in der Luft:
	# "attack_from_above" (Stich nach unten). Beide zeigen nach rechts und
	# werden fuer links per flip_h gespiegelt.
	if is_attacking:
		animated_sprite.flip_h = attack_facing_left
		var atk_anim = "attack_from_above" if attack_from_air else "attack"
		if animated_sprite.animation != atk_anim:
			animated_sprite.play(atk_anim)
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
