# =============================================================================
# upgrade_gate.gd
# =============================================================================
# Das weisse Upgrade-Tor (Area2D).
#
# Betritt der Spieler das Tor, oeffnet sich der Faehigkeiten-Laden. Dort kauft er
# mit Gold (= gesammelten Muenzen) Faehigkeiten frei und steigert sie danach.
#
# Stufen-System (siehe GameManager.ability_levels):
#   Stufe 0 -> nicht gekauft (Faehigkeit gesperrt / keine Verbesserung)
#   Stufe 1 -> gekauft = ABGESCHWAECHTE erste Version
#   Stufe 2 -> einmal verbessert
#   Stufe 3 -> voll ausgebaut (MAX)
#
# Jede Faehigkeit hat eine KARTE mit einer live abgespielten Vorschau-Animation
# (echte Spieler-Sprite-Animation der Faehigkeit), Stufen-Punkten (●●○) und dem
# Preis fuer die naechste Stufe. Beim Kauf gibt es eine kleine
# Freischalt-Animation (Aufleuchten + Pop).
#
# Kaufen:
#   - mit der Maus auf eine Karte klicken, ODER
#   - die Zifferntasten 1-8 druecken (passend zur Reihenfolge im Menue)
# Schliessen:
#   - einfach aus dem Tor herauslaufen.
#
# Node-Struktur (siehe upgrade_gate.tscn):
#   upgrade_gate (Area2D)  <-- dieses Skript
#   ├── Sprite2D           (das Tor-Bild)
#   └── CollisionShape2D   (Bereich, der den Spieler erkennt)
# =============================================================================

extends Area2D

# Reihenfolge = Anzeige-Reihenfolge im Menue = Zifferntaste (1..8).
#   key     : Schluessel in GameManager.ability_levels / ABILITY_COSTS
#   name    : Anzeigename
#   anim    : Name der Spieler-Animation fuer die Vorschau (siehe player.tscn)
#   ability : true  = echte Faehigkeit (Stufe 0 = gesperrt/grau)
#             false = Verbesserung einer Basis (Stufe 0 = vorhanden, nicht grau)
#   desc    : Kurztext je naechster Stufe [auf 1, auf 2, auf 3]
const TRACKS := [
	{"key": "attack_air",  "name": "Luft-Attacke",  "anim": "attack_from_above", "ability": true,
		"desc": ["Sturzschlag mit Schockwelle", "Groessere Schockwelle", "Riesen-Schockwelle"]},
	{"key": "dash",        "name": "Dash (Roll)",   "anim": "roll", "ability": true,
		"desc": ["Schneller Roll, kurz unverwundbar", "Schnellerer Roll", "Blitzschneller Roll"]},
	{"key": "charge",      "name": "Charge-Dash",   "anim": "charge", "ability": true,
		"desc": ["Kurzer Raketen-Dash (E halten)", "Schneller & laenger", "Maximaler Schub"]},
	{"key": "wallcrawl",   "name": "Wandklettern",  "anim": "wallcrawl", "ability": true,
		"desc": ["An Waenden klettern + Wall Jump", "Schnelleres Klettern", "Flinkes Klettern"]},
	{"key": "double_jump", "name": "Doppelsprung",  "anim": "double_jump", "ability": true,
		"desc": ["Zweiter Sprung (etwas schwach)", "Hoeherer zweiter Sprung", "Voller zweiter Sprung"]},
	{"key": "attack",      "name": "Schwert-Wucht", "anim": "attack", "ability": false,
		"desc": ["Groessere Boden-Attacke", "Noch groesser & weiter", "Maximale Reichweite"]},
	{"key": "jump",        "name": "Hoher Sprung",  "anim": "jump", "ability": false,
		"desc": ["Springt hoeher", "Springt deutlich hoeher", "Springt enorm hoch"]},
	{"key": "health",      "name": "Extra-Herzen",  "anim": "idle", "ability": false,
		"desc": ["+2 maximale Leben", "+2 weitere Leben", "+2 weitere Leben"]},
]

# -------------------------------------------------------
# Interne Variablen
# -------------------------------------------------------
var _player: Node = null            # Spieler, der gerade im Tor steht (oder null)
var _menu: CanvasLayer = null       # Das Menue-Overlay (wird beim ersten Mal gebaut)
var _gold_label: Label = null       # Zeigt den aktuellen Gold-Stand im Menue
var _cards: Array = []              # Pro Track ein Dictionary mit Knoten-Referenzen


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(GameConstants.GROUP_PLAYER):
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
# Blendet den Laden ein bzw. aus. Beim ersten Oeffnen wird er gebaut.
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
# Zifferntasten 1-8 als Kauf-Kuerzel, solange das Menue offen ist.
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
			KEY_5, KEY_KP_5: idx = 4
			KEY_6, KEY_KP_6: idx = 5
			KEY_7, KEY_KP_7: idx = 6
			KEY_8, KEY_KP_8: idx = 7
		if idx >= 0 and idx < TRACKS.size():
			_buy(idx)
			get_viewport().set_input_as_handled()


# =============================================================================
# _build_menu()
# Baut das Menue einmalig im Code auf. Eigener CanvasLayer ueber dem HUD
# (layer 20 > HUD layer 10). Ein Karten-Raster (4 Spalten) mit je einer
# animierten Faehigkeits-Vorschau.
# =============================================================================
func _build_menu() -> void:
	_menu = CanvasLayer.new()
	_menu.layer = 20
	add_child(_menu)

	# Halbdunkler Vollbild-Hintergrund, damit der Laden sich abhebt.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -360.0
	panel.offset_top = -290.0
	panel.offset_right = 360.0
	panel.offset_bottom = 290.0
	panel.add_theme_stylebox_override("panel", _make_panel_style(
		Color(0.10, 0.09, 0.14, 0.96), Color(1.0, 0.85, 0.35), 3))
	_menu.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "⚒  FÄHIGKEITEN-LADEN  ⚒"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 5)
	vbox.add_child(title)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override("font_size", 20)
	_gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	vbox.add_child(_gold_label)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	# Eine Karte je Track.
	_cards.clear()
	for i in range(TRACKS.size()):
		var card := _build_card(i)
		grid.add_child(card.root)
		_cards.append(card)

	var hint := Label.new()
	hint.text = "Klick oder Tasten 1-8 zum Kaufen / Verbessern  ·  verlasse das Tor zum Schliessen"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(hint)


# =============================================================================
# _build_card(idx)
# Baut eine einzelne Faehigkeits-Karte und gibt ein Dictionary mit den
# wichtigen Knoten zurueck (fuer spaeteres _refresh / Kauf-Animation).
#
# Aufbau: Ein Button (= die ganze klickbare Karte) mit einem darueber liegenden
# VBox, dessen Maus-Ereignisse durchgereicht werden, damit der Button den Klick
# erhaelt. Oben eine SubViewport-Vorschau mit der echten Spieler-Animation.
# =============================================================================
func _build_card(idx: int) -> Dictionary:
	var track: Dictionary = TRACKS[idx]

	var root := Button.new()
	root.custom_minimum_size = Vector2(160, 200)
	root.focus_mode = Control.FOCUS_NONE
	root.add_theme_stylebox_override("normal", _make_panel_style(
		Color(0.16, 0.15, 0.22, 1.0), Color(0.35, 0.33, 0.45), 2))
	root.add_theme_stylebox_override("hover", _make_panel_style(
		Color(0.22, 0.21, 0.30, 1.0), Color(1.0, 0.85, 0.35), 2))
	root.add_theme_stylebox_override("pressed", _make_panel_style(
		Color(0.22, 0.21, 0.30, 1.0), Color(1.0, 0.85, 0.35), 2))
	root.add_theme_stylebox_override("disabled", _make_panel_style(
		Color(0.13, 0.12, 0.17, 1.0), Color(0.28, 0.26, 0.34), 2))
	root.pressed.connect(_buy.bind(idx))

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vbox)

	# --- Vorschau: SubViewport mit live abgespielter Spieler-Animation ---
	var preview_box := SubViewportContainer.new()
	preview_box.stretch = true
	preview_box.custom_minimum_size = Vector2(84, 84)
	preview_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(preview_box)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(84, 84)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_box.add_child(viewport)

	var anim := AnimatedSprite2D.new()
	anim.position = Vector2(42, 50)
	anim.scale = Vector2(2.6, 2.6)
	if _player != null and _player.has_node("AnimatedSprite2D"):
		anim.sprite_frames = _player.get_node("AnimatedSprite2D").sprite_frames
		if anim.sprite_frames and anim.sprite_frames.has_animation(track.anim):
			anim.animation = track.anim
			anim.play(track.anim)
			# Nicht-loopende Animationen (z. B. roll, charge) in der Vorschau
			# erneut starten, damit sie dauerhaft spielen.
			anim.animation_finished.connect(_replay.bind(anim, track.anim))
	viewport.add_child(anim)

	# --- Name ---
	var name_label := Label.new()
	name_label.text = "%d  %s" % [idx + 1, track.name]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# --- Stufen-Punkte (●●○) ---
	var dots := Label.new()
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.add_theme_font_size_override("font_size", 16)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(dots)

	# --- Beschreibung der naechsten Stufe ---
	var desc := Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.85))
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)

	# --- Preis / Status ---
	var cost := Label.new()
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override("font_size", 14)
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost)

	return {
		"root": root, "anim": anim, "viewport": viewport,
		"name": name_label, "dots": dots, "desc": desc, "cost": cost,
	}


# =============================================================================
# _replay(anim, anim_name)
# Startet eine (nicht-loopende) Vorschau-Animation erneut, damit sie in der
# Karte dauerhaft laeuft.
# =============================================================================
func _replay(anim: AnimatedSprite2D, anim_name: String) -> void:
	if is_instance_valid(anim):
		anim.play(anim_name)


# =============================================================================
# _make_panel_style(bg, border, width)
# Kleiner Helfer: erzeugt eine StyleBoxFlat mit runden Ecken, Hintergrund und
# Rahmen. Wird fuer das Hauptpanel und die Karten genutzt.
# =============================================================================
func _make_panel_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(8)
	return s


# =============================================================================
# _refresh()
# Aktualisiert Gold-Stand und alle Karten (Stufen-Punkte, Vorschau-Faerbung,
# Preis/Status, Button-Zustand).
# =============================================================================
func _refresh() -> void:
	if _player == null or _menu == null:
		return
	_gold_label.text = "Gold: %d" % _player.coin_count
	for i in range(TRACKS.size()):
		_refresh_card(i)


func _refresh_card(idx: int) -> void:
	var track: Dictionary = TRACKS[idx]
	var card: Dictionary = _cards[idx]
	var level: int = GameManager.get_level(track.key)
	var maxed: bool = level >= GameManager.MAX_ABILITY_LEVEL
	var cost: int = GameManager.get_next_cost(track.key)
	var owned_or_base: bool = level >= 1 or not track.ability

	# Stufen-Punkte: gefuellt = erreicht, leer = offen.
	var filled := "●".repeat(level)
	var empty := "○".repeat(GameManager.MAX_ABILITY_LEVEL - level)
	card.dots.text = filled + empty
	card.dots.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if level > 0 else Color(0.5, 0.5, 0.55))

	# Vorschau-Faerbung: gesperrte Faehigkeiten (Stufe 0) grau und gedimmt.
	card.anim.modulate = Color(1, 1, 1, 1) if owned_or_base else Color(0.35, 0.35, 0.4, 0.8)

	# Beschreibung der naechsten Stufe (oder MAX-Hinweis).
	if maxed:
		card.desc.text = "Voll ausgebaut"
	else:
		card.desc.text = track.desc[level]

	# Preis / Status + Button-Zustand.
	if maxed:
		card.cost.text = "✓ MAX"
		card.cost.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		card.root.disabled = true
	elif _player.coin_count < cost:
		var verb := "Kaufen" if level == 0 else "Verbessern"
		card.cost.text = "%s: %d Gold" % [verb, cost]
		card.cost.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
		card.root.disabled = true
	else:
		var verb2 := ("🔒 Kaufen" if track.ability else "Kaufen") if level == 0 else "Verbessern"
		card.cost.text = "%s: %d Gold" % [verb2, cost]
		card.cost.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
		card.root.disabled = false


# =============================================================================
# _buy(idx)
# Kauft/verbessert die Faehigkeit mit Index idx, falls erlaubt: zieht Gold ab,
# hebt die Stufe im GameManager, wendet die Wirkung sofort auf den Spieler an,
# spielt eine Freischalt-Animation und gibt Feedback.
# =============================================================================
func _buy(idx: int) -> void:
	if _player == null:
		return
	var track: Dictionary = TRACKS[idx]
	var key: String = track.key

	if not GameManager.can_upgrade(key):
		Hud.show_ability_message("%s ist voll ausgebaut!" % track.name, 1.5)
		return

	var cost: int = GameManager.get_next_cost(key)
	if _player.coin_count < cost:
		Hud.show_ability_message("Du brauchst %d Gold dafuer." % cost, 2.0)
		return

	var was_level: int = GameManager.get_level(key)

	# Kauf durchfuehren
	_player.spend_coins(cost)
	var new_level: int = GameManager.add_level(key)
	_player.apply_upgrades()
	# Bei der ersten Health-Stufe (und jeder weiteren) die neuen Herzen auffuellen.
	if key == "health":
		_player.heal(GameManager.HEALTH_UPGRADE_BONUS)

	# Feedback + Freischalt-Animation auf der Karte.
	if was_level == 0:
		Hud.show_ability_message("%s freigeschaltet!" % track.name, 2.0)
	else:
		Hud.show_ability_message("%s verbessert – Stufe %d!" % [track.name, new_level], 2.0)
	_play_unlock_fx(idx)
	_refresh()


# =============================================================================
# _play_unlock_fx(idx)
# Kleine Freischalt-Animation: die Karte leuchtet kurz auf und macht einen
# "Pop" (kurz groesser, federt zurueck). Rein optisch.
# =============================================================================
func _play_unlock_fx(idx: int) -> void:
	var card: Dictionary = _cards[idx]
	var root: Control = card.root
	# Aufleuchten
	root.modulate = Color(2.0, 1.9, 1.2)
	var glow := create_tween()
	glow.tween_property(root, "modulate", Color.WHITE, 0.45)
	# Pop (Scale ueber den Mittelpunkt der Karte)
	root.pivot_offset = root.size * 0.5
	root.scale = Vector2(1.18, 1.18)
	var pop := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	pop.tween_property(root, "scale", Vector2.ONE, 0.5)
