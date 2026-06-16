# =============================================================================
# dark_knight.gd
# =============================================================================
# The Dark Knight – a mirror of the player painted red and black.
# Uses the same knight sprite sheet but tinted crimson via modulate.
#
# What makes him dangerous (vs. normal slimes):
#   - 3 HP: must be hit three times to kill (staggers on each non-lethal hit)
#   - Melee attack: charges a swing when the player gets close
#   - Dodge-roll: occasionally rolls away when the player is right on top of him
#   - Faster than normal enemies, higher jump, wider detection range
#
# Inherits from SlimeBase so patrol/chase/activation/persistence all work
# for free. _handle_extra_state() takes over movement for attacks and dodges.
# =============================================================================

class_name DarkKnight
extends SlimeBase

# --- Tuning constants --------------------------------------------------------

const MAX_HP            := 3
const BASE_MODULATE     := Color(1.0, 0.08, 0.08)   # deep crimson tint

const ATTACK_RANGE      := 32.0    # px – start swinging when player is this close
const ATTACK_DURATION   := 0.50    # seconds total for one attack cycle
const ATTACK_OPEN       := 0.33    # hitbox activates when timer drops below this
const ATTACK_CLOSE      := 0.12    # hitbox deactivates when timer drops below this
const ATTACK_COOLDOWN   := 1.8     # seconds before he can attack again

const DODGE_SPEED       := 260.0   # horizontal speed during dodge-roll
const DODGE_DURATION    := 0.28    # how long the roll lasts
const DODGE_COOLDOWN    := 3.0     # seconds between dodge opportunities
const DODGE_RANGE       := 55.0    # px – only dodge when player is this close
const DODGE_CHANCE      := 0.012   # probability per physics frame when in range

# --- State variables ---------------------------------------------------------

var hp               := MAX_HP
var is_attacking     := false
var attack_timer     := 0.0
var attack_hit_done  := false      # ensures only one hit per swing
var attack_cd        := 0.0

var is_dodging       := false
var dodge_timer      := 0.0
var dodge_dir        := 1.0
var dodge_cd         := 0.0

@onready var attack_hitbox := $AttackHitbox

# =============================================================================
# _ready()
# =============================================================================
func _ready() -> void:
	super._ready()
	sprite.modulate = BASE_MODULATE
	# Override SlimeBase defaults for a tougher opponent
	speed            = 110.0
	chase_speed      = 180.0
	detection_range  = 300.0
	jump_strength    = 430.0
	jump_interval    = 0.9
	gold_drop        = 5      # zaeher Gegner -> mehr Gold beim Ableben
	attack_hitbox.monitoring = false

# =============================================================================
# die()
# Called by the player's roll/attack/charge hitboxes.
# First two hits stagger (flash) without killing; third hit calls super.die().
# =============================================================================
func die() -> void:
	hp -= 1
	if hp > 0:
		# Stagger flash: bright red, fade back to base tint
		sprite.modulate = Color(4.0, 0.6, 0.6)
		create_tween().tween_property(sprite, "modulate", BASE_MODULATE, 0.25)
		return
	super.die()

# =============================================================================
# _handle_extra_state(delta) -> bool
# Returns true when the dark knight is managing its own movement this frame.
# The SlimeBase patrol/chase loop is skipped while this returns true.
# =============================================================================
func _handle_extra_state(delta: float) -> bool:
	if is_dead:
		return false

	# Tick cooldowns
	if attack_cd   > 0.0: attack_cd   -= delta
	if dodge_cd    > 0.0: dodge_cd    -= delta

	# ── Active dodge-roll ────────────────────────────────────────────────────
	if is_dodging:
		dodge_timer -= delta
		velocity.x   = dodge_dir * DODGE_SPEED
		sprite.flip_h = dodge_dir < 0
		sprite.play("roll")
		if dodge_timer <= 0.0:
			is_dodging = false
		return true

	# ── Active melee attack ──────────────────────────────────────────────────
	if is_attacking:
		attack_timer -= delta
		# Stand (almost) still while swinging
		velocity.x = move_toward(velocity.x, 0.0, 900.0)
		sprite.play("attack")

		# Open hitbox only during the active swing window
		var in_swing := attack_timer <= ATTACK_OPEN and attack_timer > ATTACK_CLOSE
		attack_hitbox.monitoring = in_swing
		if in_swing and not attack_hit_done:
			for body in attack_hitbox.get_overlapping_bodies():
				if body.has_method("take_damage"):
					var kdir: float = sign(body.global_position.x - global_position.x)
					body.take_damage(1, kdir)
					attack_hit_done = true
					break

		if attack_timer <= 0.0:
			is_attacking = false
			attack_cd    = ATTACK_COOLDOWN
			attack_hitbox.monitoring = false
		return true

	# ── Decide next action ───────────────────────────────────────────────────
	if player == null or not is_instance_valid(player):
		return false

	var dist := global_position.distance_to(player.global_position)

	# Attack when in melee range and cooled down
	if dist <= ATTACK_RANGE and is_on_floor() and attack_cd <= 0.0:
		_start_attack()
		return true

	# Random dodge-roll when player is dangerously close
	if dist < DODGE_RANGE and dodge_cd <= 0.0 and is_on_floor() and randf() < DODGE_CHANCE:
		_start_dodge()
		return true

	return false

# =============================================================================
# _start_attack()
# =============================================================================
func _start_attack() -> void:
	is_attacking    = true
	attack_timer    = ATTACK_DURATION
	attack_hit_done = false
	attack_hitbox.monitoring = false
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir != 0:
		sprite.flip_h          = dir < 0
		attack_hitbox.position.x = dir * 14.0

# =============================================================================
# _start_dodge()
# Rolls AWAY from the player.
# =============================================================================
func _start_dodge() -> void:
	is_dodging  = true
	dodge_timer = DODGE_DURATION
	dodge_cd    = DODGE_COOLDOWN
	dodge_dir   = sign(global_position.x - player.global_position.x)
	if dodge_dir == 0:
		dodge_dir = 1.0
