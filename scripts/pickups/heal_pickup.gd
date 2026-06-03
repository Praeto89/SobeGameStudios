# =============================================================================
# heal_pickup.gd
# =============================================================================
# Heil-Pickup (Area2D).
#
# Wenn der Spieler dieses Objekt beruehrt, werden seine Lebenspunkte um
# "heal_amount" aufgefuellt (begrenzt auf das Maximum). Danach entfernt sich
# das Pickup selbst aus der Szene.
#
# Schwierigkeit: [EINSTEIGER] – ruft nur eine Methode auf dem Spieler auf.
#
# Dieses Pickup ist das fertige Beispiel zu AUFGABEN.md -> A4.
# =============================================================================

extends Area2D

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  DEIN SPIELFELD – im Inspector einstellbar:                             ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
@export var heal_amount := 1    # Wie viele Herzen aufgefuellt werden  <- probier: 2 oder 4

@onready var audio := $SoundPickup

# =============================================================================
# _ready()
# Verbindet das body_entered-Signal.
# =============================================================================
func _ready() -> void:
	body_entered.connect(_on_body_entered)

# =============================================================================
# _on_body_entered(body)
# Wird aufgerufen wenn der Spieler das Pickup beruehrt.
# Fuellt Leben auf (nur wenn der Koerper eine heal()-Methode hat) und
# entfernt das Pickup.
# =============================================================================
func _on_body_entered(body: Node) -> void:
	# has_method-Check: nur der Spieler hat heal() -- so kracht es nicht,
	# wenn z. B. ein Gegner das Pickup beruehrt.
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(heal_amount)
		Hud.show_ability_message("Geheilt!  +%d Herz" % heal_amount)
		set_deferred("monitoring", false)
		$Sprite2D.visible = false
		audio.play()
		await audio.finished
		queue_free()
