# =============================================================================
# wall_slime.gd
# =============================================================================
# Der Wand-/Decken-Slime – ein SPEZIELLER Gegner.
#
# Faehigkeiten:
#   - Kriecht an einer DECKE oder einer WAND entlang (Schwerkraft aus).
#   - Laesst sich FALLEN, sobald der Spieler direkt unter ihm steht.
#   - Nach der Landung wird er zu einem normalen Boden-Slime und kriecht weiter.
#
# Das gemeinsame Slime-Grundgeruest (Hitbox-Schaden, die(), Persistenz, Spieler-
# Referenz) kommt aus SlimeBase. Die BEWEGUNG ist hier komplett eigen, weil sich
# ein Decken-Kriecher voellig anders verhaelt als ein Boden-Slime.
#
# Spritesheet: assets/sprites/slime_purple.png
#   (es gibt im Projekt kein eigenes Kriech-Sheet – die Frames werden je nach
#    Oberflaeche gespiegelt/orientiert; ein dediziertes Sheet liesse sich in
#    wall_slime.tscn einfach austauschen.)
#
# Schwierigkeit: [PROFI] – mehrere Zustaende, oberflaechenabhaengige Bewegung.
# =============================================================================

extends SlimeBase

# -----------------------------------------------------------------------------
# An welcher Oberflaeche klebt der Slime? Im Editor pro Instanz einstellen,
# je nachdem wo du ihn platzierst.
# -----------------------------------------------------------------------------
enum Surface { CEILING, WALL_LEFT, WALL_RIGHT }

@export var surface: Surface = Surface.CEILING   # CEILING = Decke, WALL_* = Wand
@export var crawl_speed := 30.0                  # Kriech-Geschwindigkeit
@export var drop_gravity := 800.0                # Fall-Beschleunigung nach dem Loslassen
@export var drop_trigger_width := 24.0           # Wie genau muss der Spieler "darunter" sein (Pixel)
@export var drop_delay := 0.15                   # Kurze Anspannung, bevor er faellt (Sekunden)

# -----------------------------------------------------------------------------
# Interne Zustaende des Slimes
# -----------------------------------------------------------------------------
enum State { CRAWL, PREP, FALL, GROUND }
var state: int = State.CRAWL
var crawl_dir := 1.0        # Richtung entlang der Oberflaeche (+1 / -1)
var prep_timer := 0.0       # Countdown fuer die Anspannung vor dem Fall

# =============================================================================
# _ready()
# Erst das SlimeBase-Setup (Gruppe, Spieler, Hitbox, Persistenz), dann den
# Slime passend zur Oberflaeche ausrichten.
# =============================================================================
func _ready() -> void:
	super()
	_orient()

# =============================================================================
# _orient()
# Richtet das Sprite zur gewaehlten Oberflaeche aus. An der Decke haengt der
# Slime "kopfueber" (vertikal gespiegelt).
# =============================================================================
func _orient() -> void:
	sprite.flip_v = (surface == Surface.CEILING)

# =============================================================================
# _physics_process(delta)
# Zustandsautomat: je nach state ein anderes Verhalten.
# =============================================================================
func _physics_process(delta: float) -> void:
	# Tot: nur noch zu Boden fallen lassen.
	if is_dead:
		velocity.y += drop_gravity * delta
		move_and_slide()
		return

	match state:
		State.CRAWL:
			_do_crawl()
		State.PREP:
			_do_prep(delta)
		State.FALL:
			_do_fall(delta)
		State.GROUND:
			_do_ground(delta)

	move_and_slide()

# =============================================================================
# _do_crawl()
# Kriecht an der Oberflaeche entlang und dreht am Ende der "Schiene" um.
# Sobald der Spieler darunter ist -> Wechsel in die Anspannung (PREP).
# =============================================================================
func _do_crawl() -> void:
	sprite.play("crawl")
	if surface == Surface.CEILING:
		# Decke: horizontal kriechen, an Waenden umdrehen.
		velocity = Vector2(crawl_dir * crawl_speed, 0.0)
		sprite.flip_h = crawl_dir < 0
		if is_on_wall():
			crawl_dir *= -1.0
	else:
		# Wand: vertikal kriechen, oben/unten umdrehen.
		velocity = Vector2(0.0, crawl_dir * crawl_speed)
		if is_on_floor() or is_on_ceiling():
			crawl_dir *= -1.0

	if _player_below():
		state = State.PREP
		prep_timer = drop_delay
		velocity = Vector2.ZERO
		sprite.play("fall")

# =============================================================================
# _do_prep(delta)
# Kurze Schrecksekunde an Ort und Stelle, dann faellt der Slime.
# =============================================================================
func _do_prep(delta: float) -> void:
	velocity = Vector2.ZERO
	prep_timer -= delta
	if prep_timer <= 0.0:
		state = State.FALL

# =============================================================================
# _do_fall(delta)
# Freier Fall. Bei Bodenkontakt wird der Slime zum Boden-Kriecher.
# =============================================================================
func _do_fall(delta: float) -> void:
	sprite.play("fall")
	velocity.x = move_toward(velocity.x, 0.0, crawl_speed)
	velocity.y += drop_gravity * delta
	if is_on_floor():
		state = State.GROUND
		sprite.flip_v = false   # steht wieder normal herum

# =============================================================================
# _do_ground(delta)
# Nach der Landung verhaelt er sich wie ein gewoehnlicher Boden-Slime:
# laeuft hin und her und dreht an Waenden um.
# =============================================================================
func _do_ground(delta: float) -> void:
	if not is_on_floor():
		velocity.y += drop_gravity * delta
	velocity.x = crawl_dir * crawl_speed
	sprite.flip_h = crawl_dir < 0
	sprite.play("crawl")
	if is_on_wall():
		crawl_dir *= -1.0

# =============================================================================
# _player_below() -> bool
# True, wenn der Spieler unterhalb des Slimes und horizontal nah genug ist.
# =============================================================================
func _player_below() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var dx = abs(player.global_position.x - global_position.x)
	var is_under = player.global_position.y > global_position.y
	return is_under and dx <= drop_trigger_width
