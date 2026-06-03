# =============================================================================
# charge_gate.gd
# =============================================================================
# Eine zerstoerbare Mauer (StaticBody2D), die NUR der Charge-Dash aufbricht.
#
# Das ist das erste echte "Ability-Gate" im Metroidvania-Sinn:
#   - Ohne Charge ist der Weg dahinter versperrt.
#   - Mit Charge (E gedrueckt halten) rauscht der Spieler hindurch und die
#     Mauer zerbricht dauerhaft.
#
# Damit wird eine Ability vom blossen "ich kann mehr" zum "ich komme JETZT
# an Orte, die vorher zu waren" -- der Kern eines Metroidvania.
#
# Node-Struktur:
#   ChargeGate (StaticBody2D)   <-- dieses Skript, blockiert den Spieler (Layer 1)
#   ├── Sprite      (Polygon2D)   sichtbare Mauer
#   ├── Block       (CollisionShape2D)  der feste, blockierende Koerper
#   ├── DetectArea  (Area2D)      etwas breiter -> erkennt den Charge-Dash
#   │     └── CollisionShape2D
#   └── SoundBreak  (AudioStreamPlayer2D)
#
# Persistenz: Eine aufgebrochene Mauer bleibt offen (siehe GameManager.
# opened_gate_ids) -- auch nach einem Szenen-Wechsel und Zurueckkommen.
#
# Schwierigkeit: [FORTGESCHRITTEN] -- kombiniert Kollision, Area-Erkennung,
# Coroutine (await) und Persistenz. Gut lesbares Vorbild fuer weitere Gates.
# =============================================================================

extends StaticBody2D

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var _block: CollisionShape2D = $Block          # blockierende Kollision
@onready var _sprite: Polygon2D = $Sprite               # sichtbare Mauer
@onready var _detect_area: Area2D = $DetectArea         # erkennt den Charge
@onready var _sound_break: AudioStreamPlayer2D = $SoundBreak

# =============================================================================
# _ready()
# Prueft die Persistenz: war die Mauer in dieser Session schon offen?
# =============================================================================
func _ready() -> void:
	# Wurde diese Mauer in dieser Session bereits aufgebrochen? Dann gar nicht
	# erst anzeigen -- der Durchgang bleibt frei.
	var id := GameManager.get_persistent_id(self)
	if id != "" and id in GameManager.opened_gate_ids:
		queue_free()
		return

# =============================================================================
# _physics_process(delta)
# Prueft jeden Physik-Frame, ob ein Spieler IM CHARGE-DASH die (etwas
# breitere) Erkennungs-Area beruehrt.
#
# WARUM pro Frame und nicht body_entered?
# body_entered feuert nur im Moment des Eintritts. Stuende der Spieler bereits
# an der Mauer und LUEDE DANN den Charge auf, kaeme das Signal nie -- die Mauer
# liesse sich nicht aufbrechen. Die Pro-Frame-Pruefung deckt beide Faelle ab
# (hineinrauschen UND davorstehen-dann-chargen). Das ist dasselbe Muster, das
# player.gd fuer die Roll- und Attack-Hitbox nutzt.
# =============================================================================
func _physics_process(_delta: float) -> void:
	for body in _detect_area.get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		# Der entscheidende Test: Der Spieler muss gerade chargen.
		# is_charging ist nur waehrend des Dashs true -- und der Dash setzt die
		# freigeschaltete Charge-Ability voraus. Damit ist das Gate implizit
		# ability-gegated, ohne hier extra has_charge pruefen zu muessen.
		if "is_charging" in body and body.is_charging:
			_break()
			return

# =============================================================================
# _break()
# Bricht die Mauer auf: persistieren, Kollision sofort freigeben (damit der
# Spieler im selben Frame durchrauscht), Sound + visuelles Verschwinden,
# und den Node nach dem Sound entfernen.
# =============================================================================
func _break() -> void:
	# Mehrfach-Ausloesung verhindern (Area kann im selben Dash mehrfach feuern)
	if not _detect_area.monitoring:
		return
	_detect_area.set_deferred("monitoring", false)

	# Dauerhaft als "offen" merken -> bleibt nach Szenenwechsel offen.
	var id := GameManager.get_persistent_id(self)
	if id != "" and not id in GameManager.opened_gate_ids:
		GameManager.opened_gate_ids.append(id)
		GameManager.save_game()   # geoeffnetes Gate sofort sichern

	# Blockierende Kollision sofort entfernen, damit der Charge nicht abrupt
	# an der Mauer stoppt, sondern hindurchfaehrt. set_deferred, weil wir
	# moeglicherweise im Physik-Schritt sind (Kollisionsform nicht direkt
	# aendern -- siehe gleiche Begruendung in player.gd respawn()).
	_block.set_deferred("disabled", true)

	# Visuelles + akustisches Feedback
	_sprite.visible = false
	_sound_break.play()

	# Node erst freigeben wenn der Break-Sound durch ist (sonst abgeschnitten).
	await _sound_break.finished
	queue_free()
