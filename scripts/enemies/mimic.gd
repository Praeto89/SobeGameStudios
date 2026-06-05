# =============================================================================
# mimic.gd
# =============================================================================
# Die Mimik-Truhe ("Mimic") – ein HINTERHALT-Gegner.
#
# Idee:
#   Sie sieht aus wie eine harmlose Schatztruhe und steht regungslos herum.
#   Kommt der Spieler zu nah, springt der Deckel auf, ein lila TENTAKEL schiesst
#   heraus – und die Truhe wird lebendig und greift an.
#
# Drei Zustaende:
#   DORMANT  – getarnt als geschlossene Truhe, bewegt sich nicht, tut NICHTS.
#              Ihre Schaden-Hitbox ist AUS (eine zu Truhe tut ja nicht weh).
#   WAKING   – Uebergang: Deckel auf, Tentakel kommt heraus (Aktivierungs-Anim).
#              Wird die Hitbox eingeschaltet -> ab jetzt gefaehrlich.
#   ACTIVE   – wach: schiebt sich auf den Spieler zu und wedelt mit dem Tentakel.
#
# Das gemeinsame Gegner-Grundgeruest (Gruppe "enemy", Spieler-Referenz,
# Hitbox-Schaden, die() mit Todesanimation, Persistenz) kommt aus SlimeBase –
# genau wie beim Wand-Slime. Eigen ist hier nur die Hinterhalt-BEWEGUNG.
#
# Spritesheet: assets/sprites/mimic.png  (14 Frames a 32x32)
#   idle / activation / attack / death
#
# Schwierigkeit: [PROFI] – Zustandsautomat + await + Hitbox erst spaet scharf.
# =============================================================================

extends SlimeBase

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  DEIN SPIELFELD – im Godot-Editor pro Instanz einstellbar:               ║
# ║  Mimik-Truhe im Level anklicken → rechts im Inspector scrollen.          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
@export var wake_range := 60.0     # Ab dieser Naehe (Pixel) erwacht die Truhe  <- klein = fieser Hinterhalt
@export var lunge_speed := 55.0    # Tempo, mit dem sie wach auf den Spieler zukriecht

# -----------------------------------------------------------------------------
# Interne Zustaende
# -----------------------------------------------------------------------------
enum State { DORMANT, WAKING, ACTIVE }
var state: int = State.DORMANT

# =============================================================================
# _ready()
# Erst das SlimeBase-Setup (Gruppe, Spieler, Hitbox-Signal, Persistenz),
# dann tarnen: Schaden-Hitbox aus und geschlossene Truhe zeigen.
# =============================================================================
func _ready() -> void:
	super()
	hitbox.monitoring = false        # getarnt: die Truhe tut (noch) nicht weh
	sprite.play("idle")

# =============================================================================
# _physics_process(delta)
# Zustandsautomat. WAKING wird von der _wake_up()-Coroutine gesteuert, deshalb
# passiert hier in diesem Zustand nichts ausser Schwerkraft.
# =============================================================================
func _physics_process(delta: float) -> void:
	# Tot: nur noch zu Boden fallen lassen.
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return

	# Schwerkraft (die Truhe soll auf dem Boden stehen bleiben).
	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		State.DORMANT:
			_do_dormant()
		State.WAKING:
			velocity.x = 0.0        # an Ort und Stelle aufklappen
		State.ACTIVE:
			_do_active()

	move_and_slide()

# =============================================================================
# _do_dormant()
# Getarnt warten. Kommt der Spieler in wake_range -> aufwachen.
# =============================================================================
func _do_dormant() -> void:
	velocity.x = 0.0
	sprite.play("idle")
	if player and is_instance_valid(player) \
			and global_position.distance_to(player.global_position) < wake_range:
		_wake_up()

# =============================================================================
# _wake_up()
# Uebergang DORMANT -> ACTIVE. Spielt die Aktivierungs-Animation einmal ab
# (Deckel auf, Tentakel heraus) und schaltet danach die Schaden-Hitbox scharf.
#
# WARUM await? Es haelt diese Funktion an, bis die Animation fertig ist, ohne
# das Spiel zu blockieren (Coroutine) – genau wie in SlimeBase.die().
# =============================================================================
func _wake_up() -> void:
	state = State.WAKING
	velocity.x = 0.0
	# zum Spieler ausrichten
	sprite.flip_h = (player.global_position.x - global_position.x) < 0
	if has_node("SoundActivate"):
		$SoundActivate.play()
	sprite.play("activation")
	await sprite.animation_finished
	hitbox.monitoring = true         # Tentakel ist draussen -> jetzt gefaehrlich
	state = State.ACTIVE

# =============================================================================
# die()
# Überschreibt SlimeBase.die(): spawnt erst Münzen, dann läuft die Basisversion
# (Kollision aus, Todesanimation abspielen, queue_free).
#
# WARUM hier und nicht in SlimeBase?
# Nur die Mimik-Truhe soll Münzen hinterlassen. Der grüne Slime tut das nicht.
# Durch das Überschreiben bleibt die Basis-Klasse sauber und jede Unterklasse
# entscheidet selbst, was beim Tod passiert.
# =============================================================================
func die() -> void:
	_spawn_coins(8)
	super()

# =============================================================================
# _spawn_coins(count)
# Instanziiert count Münzen als Kinder des Eltern-Knotens (des Levels) und
# verteilt sie zufällig um die aktuelle Position.
#
# WARUM get_parent()?
# Die Truhe wird gleich mit queue_free() entfernt. Münzen als eigene Kinder
# wären sofort weg. Als Kinder des Levels bleiben sie sammelbar.
# =============================================================================
func _spawn_coins(count: int) -> void:
	var coin_scene := load("res://scenes/pickups/coin.tscn")
	for i in count:
		var c = coin_scene.instantiate()
		var angle := randf() * TAU
		var dist  := randf_range(12.0, 32.0)
		c.global_position = global_position + Vector2(cos(angle) * dist, sin(angle) * dist - 14.0)
		get_parent().add_child(c)

# =============================================================================
# _do_active()
# Wach: kriecht auf den Spieler zu und wedelt mit dem Tentakel (attack-Anim).
# An einer Wand bleibt sie stehen statt sinnlos dagegen zu druecken.
# =============================================================================
func _do_active() -> void:
	sprite.play("attack")
	if player and is_instance_valid(player):
		var direction := signf(player.global_position.x - global_position.x)
		velocity.x = direction * lunge_speed
		sprite.flip_h = direction < 0
	else:
		velocity.x = 0.0
	if is_on_wall():
		velocity.x = 0.0
