# =============================================================================
# upgrade_gate.gd
# =============================================================================
# Das weisse Upgrade-Tor (Area2D).
#
# Betritt der Spieler das Tor, oeffnet sich ein einfaches Coin-Menue. Dort kann
# er gesammelte Muenzen gegen dauerhaft staerkere Abilities eintauschen. Jedes
# Upgrade ist EINMAL kaufbar (Festpreis, siehe GameManager.UPGRADE_COSTS).
#
# Kaufen:
#   - mit der Maus auf einen Knopf klicken, ODER
#   - die Zifferntasten 1-4 druecken (passend zur Reihenfolge im Menue)
# Schliessen:
#   - einfach aus dem Tor herauslaufen.
#
# Node-Struktur (siehe upgrade_gate.tscn):
#   upgrade_gate (Area2D)  <-- dieses Skript
#   ├── Sprite2D           (das Tor-Bild)
#   └── CollisionShape2D   (Bereich, der den Spieler erkennt)
#
# Das Kauf-Feedback ("... gekauft!") laeuft ueber Hud.show_ability_message,
# damit es sich anfuehlt wie das Freischalten einer Ability.
# =============================================================================

extends Area2D

# Reihenfolge = Anzeige-Reihenfolge im Menue = Zifferntaste (1..4).
#   key   : Schluessel in GameManager.UPGRADE_COSTS und der upgrade_*-Flags
#   name  : Anzeigename
#   needs : Name einer has_*-Faehigkeit, die vorher freigeschaltet sein muss
#           ("" = keine Voraussetzung)
#   desc  : kurze Erklaerung, was das Upgrade bewirkt
const UPGRADES := [
	{"key": "charge", "name": "Charge-Power", "needs": "charge", "desc": "Dash schneller & laenger"},
	{"key": "jump",   "name": "Hoher Sprung", "needs": "",       "desc": "Springt deutlich hoeher"},
	{"key": "health", "name": "Extra-Herzen", "needs": "",       "desc": "+2 maximale Leben"},
	{"key": "attack", "name": "Schwert-Wucht","needs": "",       "desc": "Groessere, weiter reichende Attacke"},
]

# -------------------------------------------------------
# Interne Variablen
# -------------------------------------------------------
var _player: Node = null            # Spieler, der gerade im Tor steht (oder null)
var _menu: CanvasLayer = null       # Das Menue-Overlay (wird beim ersten Mal gebaut)
var _coin_label: Label = null       # Zeigt den aktuellen Coin-Stand im Menue
var _buttons: Array = []            # Die vier Kauf-Knoepfe (eine je Upgrade)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_open_menu()


func _on_body_exited(body: Node2D) -> void:
	if body != _player:
		return
	_player = null
	_close_menu()


# =============================================================================
# _open_menu() / _close_menu()
# Blendet das Coin-Menue ein bzw. aus. Beim ersten Oeffnen wird es gebaut.
# =============================================================================
func _open_menu() -> void:
	if _menu == null:
		_build_menu()
	_menu.visible = true
	_refresh()


func _close_menu() -> void:
	if _menu != null:
		_menu.visible = false


# =============================================================================
# _unhandled_input(event)
# Zifferntasten 1-4 als Kauf-Kuerzel, solange das Menue offen ist.
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if _menu == null or not _menu.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx := -1
		match event.keycode:
			KEY_1, KEY_KP_1: idx = 0
			KEY_2, KEY_KP_2: idx = 1
			KEY_3, KEY_KP_3: idx = 2
			KEY_4, KEY_KP_4: idx = 3
		if idx >= 0 and idx < UPGRADES.size():
			_buy(idx)
			get_viewport().set_input_as_handled()


# =============================================================================
# _build_menu()
# Baut das Menue einmalig im Code auf (analog zum Hilfe-Panel im HUD).
# Eigener CanvasLayer ueber dem HUD (layer 20 > HUD layer 10).
# =============================================================================
func _build_menu() -> void:
	_menu = CanvasLayer.new()
	_menu.layer = 20
	add_child(_menu)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -220.0
	panel.offset_top = -170.0
	panel.offset_right = 220.0
	panel.offset_bottom = 170.0
	_menu.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "⚒  UPGRADE-TOR  ⚒"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
	vbox.add_child(title)

	_coin_label = Label.new()
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coin_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_coin_label)

	# Ein Knopf je Upgrade. Der Index wird ueber bind() fest mitgegeben.
	_buttons.clear()
	for i in range(UPGRADES.size()):
		var btn := Button.new()
		btn.pressed.connect(_buy.bind(i))
		btn.add_theme_font_size_override("font_size", 16)
		vbox.add_child(btn)
		_buttons.append(btn)

	var hint := Label.new()
	hint.text = "Tasten 1-4 zum Kaufen  ·  verlasse das Tor zum Schliessen"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(hint)


# =============================================================================
# _refresh()
# Aktualisiert Coin-Stand und alle Knopf-Beschriftungen/-Zustaende.
#   - bereits gekauft        -> deaktiviert, "gekauft"
#   - Faehigkeit fehlt noch  -> deaktiviert, Hinweis
#   - genug Coins            -> aktiv
#   - zu wenig Coins         -> deaktiviert, "zu wenig Coins"
# =============================================================================
func _refresh() -> void:
	if _player == null or _menu == null:
		return
	_coin_label.text = "Coins: %d" % _player.coin_count
	for i in range(UPGRADES.size()):
		var u: Dictionary = UPGRADES[i]
		var cost: int = GameManager.UPGRADE_COSTS[u.key]
		var btn: Button = _buttons[i]
		var base := "[%d] %s  (%d Coins) – %s" % [i + 1, u.name, cost, u.desc]
		if GameManager.get("upgrade_" + u.key):
			btn.text = base + "   ✓ gekauft"
			btn.disabled = true
		elif u.needs != "" and not GameManager.get("has_" + u.needs):
			btn.text = base + "   🔒 Faehigkeit fehlt"
			btn.disabled = true
		elif _player.coin_count < cost:
			btn.text = base + "   (zu wenig Coins)"
			btn.disabled = true
		else:
			btn.text = base
			btn.disabled = false


# =============================================================================
# _buy(idx)
# Kauft das Upgrade mit Index idx, falls erlaubt: zieht Coins ab, setzt das
# Flag im GameManager, wendet die Wirkung sofort auf den Spieler an und gibt
# Feedback. Danach wird das Menue aufgefrischt.
# =============================================================================
func _buy(idx: int) -> void:
	if _player == null:
		return
	var u: Dictionary = UPGRADES[idx]
	var cost: int = GameManager.UPGRADE_COSTS[u.key]

	if GameManager.get("upgrade_" + u.key):
		Hud.show_ability_message("%s schon gekauft!" % u.name, 1.5)
		return
	if u.needs != "" and not GameManager.get("has_" + u.needs):
		Hud.show_ability_message("Erst die passende Faehigkeit finden!", 2.0)
		return
	if _player.coin_count < cost:
		Hud.show_ability_message("Du brauchst %d Coins dafuer." % cost, 2.0)
		return

	# Kauf durchfuehren
	_player.spend_coins(cost)
	GameManager.set("upgrade_" + u.key, true)
	_player.apply_upgrades()
	# Beim Herzen-Upgrade die neuen Herzen auch gleich auffuellen.
	if u.key == "health":
		_player.heal(GameManager.HEALTH_UPGRADE_BONUS)

	Hud.show_ability_message("%s freigeschaltet!" % u.name, 2.0)
	_refresh()
