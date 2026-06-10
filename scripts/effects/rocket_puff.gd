# =============================================================================
# rocket_puff.gd
# =============================================================================
# Ein einzelnes Abgas-Woelkchen fuer den Charge-Dash ("Raketen-Antrieb").
# Es wird hinten am Spieler ausgestossen, waechst leicht und blendet dabei aus
# (faded), dann loescht es sich selbst (queue_free). Viele davon kurz
# hintereinander ergeben den nachziehenden Raketen-Strahl.
#
# Gespawnt wird es vom Spieler (player.gd -> _spawn_rocket_puff) waehrend des
# Charge-Dashs.
# =============================================================================

extends Sprite2D

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Tuning – gefahrlos aenderbar:                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
const LIFETIME := 0.35       # Sekunden bis das Woelkchen verschwunden ist  <- groesser = laengerer Schweif
const GROW := 1.6            # Auf das Wievielfache es waehrend des Ausblendens waechst
const START_ALPHA := 0.85    # Anfangs-Deckkraft (0..1)

func _ready() -> void:
	modulate.a = START_ALPHA
	# Ausblenden + leicht aufblaehen = "loest sich auf wie Rauch".
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME)
	tween.tween_property(self, "scale", scale * GROW, LIFETIME)
	# Nach Ablauf der Animation sauber entfernen.
	tween.chain().tween_callback(queue_free)
