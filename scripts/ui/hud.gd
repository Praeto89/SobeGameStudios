# =============================================================================
# hud.gd
# =============================================================================
# HUD (Heads-Up-Display) – die Spieler-Oberflaeche.
#
# Zeigt an:
#   - Lebenspunkte als animierte Schwert-Klingen (healthbar.tscn)
#       4 Blade-Segmente; pro fehlendem Leben wird ein Segment "zerbrochen"
#   - Anzahl gesammelter Muenzen als Text-Label
#
# Wird als Autoload (Singleton) geladen -> existiert in jedem Level,
# ohne dass die Szene das HUD manuell instanziieren muss.
# Bei Szenen-Wechseln wird die neue Player-Instanz automatisch erkannt
# (siehe _on_node_added).
#
# Voraussetzung: Der Spieler muss in der Gruppe "player" sein.
# =============================================================================

extends CanvasLayer

# Frame-Index im Blade-SpriteFrames fuer "Klinge intakt" bzw. "Klinge zerbrochen".
# Atlas-Layout (siehe healthbar.tscn):
#   Frame 0 = Klingen-Mittelteil intakt
#   Frame 1 = Schwertspitze intakt
#   Frame 2 = Klingen-Mittelteil zerbrochen
#   Frame 3 = Schwertspitze zerbrochen
# Blade 1-3 sind Mittelteile, Blade 4 ist die Spitze (am rechten Ende).
const _BLADE_FRAMES := [
	[0, 2],   # Blade 1 - Mittelteil
	[0, 2],   # Blade 2 - Mittelteil
	[0, 2],   # Blade 3 - Mittelteil
	[1, 3],   # Blade 4 - Schwertspitze
]

# Layout-Werte der Klingen-Segmente, abgelesen aus healthbar.tscn:
# Mittelteile stehen ab x=-62 im Abstand von 60; die Spitze sitzt 10px weiter.
# Werden gebraucht, um beim Health-Upgrade dynamisch weitere Segmente zu setzen.
const _BLADE_START_X := -62.0
const _BLADE_SPACING := 60.0
const _BLADE_TIP_EXTRA := 10.0
const _BLADE_Y := 30.0

# Aktuelles Frame-Layout (Mittelteil [0,2] / Spitze [1,3]) pro Segment.
# Startet als Kopie von _BLADE_FRAMES und waechst/schrumpft mit der maximalen
# Lebenszahl des Spielers (siehe _ensure_blade_count).
var _blade_frames: Array = _BLADE_FRAMES.duplicate(true)

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var _hilt: AnimatedSprite2D = $"Healthbar/HBoxContainer/Hilt"
@onready var _blades: Array = [
	$"Healthbar/HBoxContainer/Blade 1",
	$"Healthbar/HBoxContainer/Blade 2",
	$"Healthbar/HBoxContainer/Blade 3",
	$"Healthbar/HBoxContainer/Blade 4",
]
@onready var coin_label: Label = $CoinLabel

# Referenz auf den aktuell verbundenen Player, damit wir bei Szenen-
# Wechseln nicht erneut mit derselben Instanz connecten.
var _connected_player: Node = null

# =============================================================================
# _ready()
# Stoppt die automatischen Sprite-Animationen (sonst flackern die Blades
# endlos durch alle Frames) und verbindet sich mit dem Spieler.
# =============================================================================
func _ready() -> void:
	# WICHTIG fuer das Pause-Menue: das HUD muss auch dann noch laufen, wenn das
	# Spiel pausiert ist (get_tree().paused = true) -- sonst koennte man die
	# Pause per ESC nicht wieder aufheben und die Pause-Buttons waeren tot.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Animationen anhalten -- wir setzen die Frames manuell je nach HP
	_hilt.stop()
	_hilt.frame = 0
	for i in range(_blades.size()):
		_blades[i].stop()
		_blades[i].frame = _blade_frames[i][0]   # initial: intakt-Frame der jeweiligen Blade-Position
	# WARUM node_added statt den Player direkt zu referenzieren?
	# Das HUD ist ein Autoload-Singleton – es existiert ueber Szenen-Wechsel
	# hinweg. Der Player aber wird bei jedem Levelwechsel neu erzeugt. Wir
	# koennen also nicht einmalig $Player speichern; wir muessen WARTEN bis
	# der neue Player zum Szenenbaum hinzugefuegt wird, und ihn dann neu
	# verbinden. node_added feuert fuer jeden neuen Node – wir pruefen dann
	# ob es ein Player ist.
	get_tree().node_added.connect(_on_node_added)
	_connect_to_player()

# =============================================================================
# _on_node_added(node)
# Wird vom SceneTree fuer JEDEN neu hinzugefuegten Node aufgerufen.
# Wenn es sich um einen Player handelt (und nicht den schon verbundenen),
# wird die Verbindung erneuert -- typischer Fall: change_scene_to_file
# hat eine neue Szene mit eigenem Player erzeugt.
# =============================================================================
func _on_node_added(node: Node) -> void:
	if node.is_in_group(GameConstants.GROUP_PLAYER) and node != _connected_player:
		_connect_to_player()

# =============================================================================
# _connect_to_player()
# Findet den aktuellen Player im SceneTree, verbindet seine Signale mit
# dem HUD und aktualisiert die Anzeige sofort. Vorhandene Verbindungen
# werden vorher sauber getrennt.
# =============================================================================
func _connect_to_player() -> void:
	var player = get_tree().get_first_node_in_group(GameConstants.GROUP_PLAYER)
	if player == null or player == _connected_player:
		return
	# Alte Verbindungen loesen, falls der vorherige Player noch existiert
	if _connected_player != null and is_instance_valid(_connected_player):
		if _connected_player.health_changed.is_connected(_on_health_changed):
			_connected_player.health_changed.disconnect(_on_health_changed)
		if _connected_player.coin_collected.is_connected(_on_coin_collected):
			_connected_player.coin_collected.disconnect(_on_coin_collected)
	_connected_player = player
	player.health_changed.connect(_on_health_changed)
	player.coin_collected.connect(_on_coin_collected)
	# HUD sofort mit den aktuellen Werten befuellen (kein leeres HUD beim Start).
	# _on_health_changed passt dabei selbst die Anzahl der Klingen-Segmente an
	# das (ggf. per Upgrade erhoehte) Lebens-Maximum an.
	_on_health_changed(player.current_health)
	_on_coin_collected(player.coin_count)

# =============================================================================
# _ensure_blade_count(count)
# Stellt sicher, dass genau "count" Klingen-Segmente existieren. Beim Health-
# Upgrade waechst das Lebens-Maximum (z. B. 4 -> 6), also brauchen wir mehr
# Segmente. Fehlende werden als Kopie eines vorhandenen Segments erzeugt,
# ueberzaehlige entfernt. Danach werden Frames (Mittelteil/Spitze) und
# Positionen aller Segmente neu gesetzt -- die Spitze bleibt das letzte Segment.
# =============================================================================
func _ensure_blade_count(count: int) -> void:
	if count < 1 or _blades.is_empty():
		return
	if count == _blades.size():
		return
	var hbox: Node = _blades[0].get_parent()
	var template: AnimatedSprite2D = _blades[0]
	# Fehlende Segmente hinzufuegen (Vorlage: erstes vorhandenes Segment)
	while _blades.size() < count:
		var blade := AnimatedSprite2D.new()
		blade.sprite_frames = template.sprite_frames
		blade.scale = template.scale
		blade.stop()
		hbox.add_child(blade)
		_blades.append(blade)
	# Ueberzaehlige Segmente entfernen
	while _blades.size() > count:
		var extra: AnimatedSprite2D = _blades.pop_back()
		extra.queue_free()
	# Frames + Positionen neu vergeben: nur das letzte Segment ist die Spitze.
	_blade_frames.clear()
	for i in range(count):
		var is_tip := i == count - 1
		_blade_frames.append([1, 3] if is_tip else [0, 2])
		var x := _BLADE_START_X + i * _BLADE_SPACING + (_BLADE_TIP_EXTRA if is_tip else 0.0)
		_blades[i].position = Vector2(x, _BLADE_Y)
		_blades[i].stop()
		_blades[i].frame = _blade_frames[i][0]

# =============================================================================
# _on_health_changed(new_health)
# Wird aufgerufen wenn der Spieler Schaden nimmt oder geheilt wird.
# Setzt jedes Blade-Segment auf "intakt" oder "zerbrochen" je nach HP --
# Mittelteile und Spitze nutzen unterschiedliche Atlas-Frames (siehe
# _BLADE_FRAMES). Bei Schaden gibt es zusaetzlich ein rotes Aufblitzen
# als visuelles Feedback.
#
# new_health: Aktuelle Anzahl der Lebenspunkte
# =============================================================================
const _BLADE_FLASH_HOLD := 0.08    # Sekunden bis Frame zu "zerbrochen" wechselt
const _BLADE_FLASH_FADE := 0.3     # Sekunden bis das rote Aufblitzen ausfadet

var _last_health: int = -1
var _blade_tweens: Array = []      # Laufende Schadensanimationen pro Blade

func _on_health_changed(new_health: int) -> void:
	# Segment-Anzahl an das aktuelle Lebens-Maximum des Spielers angleichen
	# (relevant nach dem Health-Upgrade: aus 4 Segmenten werden z. B. 6).
	if _connected_player != null and is_instance_valid(_connected_player):
		_ensure_blade_count(_connected_player.max_health)

	# Laufende Animationen abbrechen, damit sie keine alten Frames mehr
	# setzen, wenn der Spieler zwischendurch geheilt wird.
	for t in _blade_tweens:
		if t != null and t.is_valid():
			t.kill()
	_blade_tweens.clear()

	var damage_taken := _last_health != -1 and new_health < _last_health

	# Frames direkt setzen (intakt fuer "noch lebend", zerbrochen fuer "verloren").
	# Modulate reset, falls vorher durch einen Flash veraendert.
	for i in range(_blades.size()):
		var intact_frame: int = _blade_frames[i][0]
		var broken_frame: int = _blade_frames[i][1]
		_blades[i].frame = intact_frame if i < new_health else broken_frame
		_blades[i].modulate = Color.WHITE

	# Bei Schaden: rotes Aufblitzen + verzoegerter Frame-Wechsel auf den
	# "frisch verlorenen" Blades, damit man den Treffer visuell wahrnimmt.
	if damage_taken:
		for i in range(new_health, min(_last_health, _blades.size())):
			_animate_blade_break(_blades[i], _blade_frames[i][0], _blade_frames[i][1])

	_last_health = new_health

# =============================================================================
# _animate_blade_break(blade, intact_frame, broken_frame)
# Spielt einen kurzen Schadens-Effekt fuer ein einzelnes Klingen-Segment:
#   1. Klinge ist noch intakt, faerbt sich rot
#   2. Nach _BLADE_FLASH_HOLD wechselt der Frame zum zerbrochenen Zustand
#   3. Die rote Faerbung fadet ueber _BLADE_FLASH_FADE zurueck zu Weiss
# =============================================================================
func _animate_blade_break(blade: AnimatedSprite2D, intact_frame: int, broken_frame: int) -> void:
	# Startet im intakten Zustand, leuchtend rot
	blade.frame = intact_frame
	blade.modulate = Color(2.5, 0.6, 0.6)
	var tween = create_tween()
	tween.tween_interval(_BLADE_FLASH_HOLD)
	tween.tween_callback(_set_blade_frame.bind(blade, broken_frame))
	tween.tween_property(blade, "modulate", Color.WHITE, _BLADE_FLASH_FADE)
	_blade_tweens.append(tween)

func _set_blade_frame(blade: AnimatedSprite2D, frame_idx: int) -> void:
	if is_instance_valid(blade):
		blade.frame = frame_idx

# =============================================================================
# _on_coin_collected(new_count)
# Wird aufgerufen wenn der Spieler eine Muenze aufsammelt.
# Aktualisiert den Anzeigetext.
#
# new_count: Gesamtzahl der bisher gesammelten Muenzen
# =============================================================================
func _on_coin_collected(new_count: int) -> void:
	coin_label.text = "Gold: " + str(new_count)

# =============================================================================
# show_ability_message(text, duration)
# Zeigt kurz einen Schriftzug an (typisch beim Aufsammeln einer Ability).
# Wird vom HUD selbst gezeichnet -- die Pickups rufen einfach
#   Hud.show_ability_message("...")
# auf. Mehrere Aufrufe stapeln sich nicht; ein vorhandener Hinweis wird
# durch den neuen ersetzt.
#
# text:     Der anzuzeigende Schriftzug (mehrzeilig moeglich mit "\n")
# duration: Gesamtdauer in Sekunden inkl. Ein-/Ausblenden (Default 3.0)
# =============================================================================
const _ABILITY_FADE_TIME := 0.4   # Sekunden fuer Ein- und Ausblendung

var _ability_label: Label = null
var _ability_tween: Tween = null

func show_ability_message(text: String, duration: float = 3.0) -> void:
	# Vorhandene Nachricht stoppen und entfernen
	if _ability_tween != null and _ability_tween.is_valid():
		_ability_tween.kill()
	if _ability_label != null and is_instance_valid(_ability_label):
		_ability_label.queue_free()
	# Neues Label aufbauen -- volle Bildschirmbreite, mittig oben unter dem HBox
	_ability_label = Label.new()
	_ability_label.text = text
	_ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Per Anchor zentriert oben einsetzen
	_ability_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_ability_label.offset_top = 90
	_ability_label.offset_bottom = 200
	# Visuelles Styling: groesserer Text mit dunklem Outline gegen jeden BG
	_ability_label.add_theme_font_size_override("font_size", 28)
	_ability_label.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
	_ability_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_ability_label.add_theme_constant_override("outline_size", 6)
	_ability_label.modulate.a = 0.0
	add_child(_ability_label)
	# Ein-/Halte-/Ausblenden via Tween
	var hold_time = max(0.0, duration - 2.0 * _ABILITY_FADE_TIME)
	_ability_tween = create_tween()
	_ability_tween.tween_property(_ability_label, "modulate:a", 1.0, _ABILITY_FADE_TIME)
	_ability_tween.tween_interval(hold_time)
	_ability_tween.tween_property(_ability_label, "modulate:a", 0.0, _ABILITY_FADE_TIME)
	_ability_tween.tween_callback(_ability_label.queue_free)

# =============================================================================
# Help-Overlay (F1)
# =============================================================================
# Einblendbares Hilfe-Panel mit Steuerung und Tipps. Wird beim ersten
# F1-Druck erzeugt und kann jederzeit ein-/ausgeblendet werden.
# Liegt im HUD, weil das HUD autoloaded ist und damit in jedem Level
# verfuegbar bleibt.
# =============================================================================

const _HELP_TEXT := "STEUERUNG\n\n  Pfeiltasten:     Laufen\n  Leertaste:       Springen (kurz/lang fuer Sprunghoehe)\n  X:               Boden-Attacke (immer verfuegbar)\n  Pfeil unten:     Schnellfall (in der Luft)\n\nKAUFBARE FÄHIGKEITEN (im Tor mit Gold)\n  Dash/Roll:       SHIFT (schadet Gegnern)\n  Luft-Attacke:    X in der Luft (Sturzschlag)\n  Charge-Dash:     E halten + loslassen\n  Doppelsprung:    Leertaste 2x\n  Wallcrawl:       automatisch an Waenden\n\nFÄHIGKEITEN-LADEN (weisses Tor)\n  Betreten + Tasten 1-8:  Gold gegen Faehigkeiten tauschen\n  Jede Faehigkeit: kaufen + 2x verbessern (Stufe 1-3)\n\nGOLD\n  Gegner und Truhen lassen Gold (Muenzen) fallen\n\nHILFE\n  F1:   dieses Fenster ein-/ausblenden\n  ESC:  Pause-Menue (Weiter / Neustart / Hauptmenue)"

var _help_panel: PanelContainer = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			toggle_help()
			get_viewport().set_input_as_handled()
			return
	# ESC / "ui_cancel": Pause-Menue ein-/ausblenden -- aber nur im laufenden
	# Spiel (also wenn ein Spieler in der Szene ist). In Menue/Abspann gibt es
	# keinen Spieler, dort kuemmern sich diese Szenen selbst um ESC.
	if event.is_action_pressed("ui_cancel"):
		if get_tree().get_first_node_in_group(GameConstants.GROUP_PLAYER) != null:
			toggle_pause()
			get_viewport().set_input_as_handled()

func toggle_help() -> void:
	if _help_panel == null:
		_create_help_panel()
	_help_panel.visible = not _help_panel.visible

func _create_help_panel() -> void:
	_help_panel = PanelContainer.new()
	_help_panel.set_anchors_preset(Control.PRESET_CENTER)
	_help_panel.offset_left = -260.0
	_help_panel.offset_top = -200.0
	_help_panel.offset_right = 260.0
	_help_panel.offset_bottom = 200.0
	_help_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_help_panel.add_child(margin)

	var label := Label.new()
	label.text = _HELP_TEXT
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	margin.add_child(label)

	add_child(_help_panel)
	_help_panel.visible = false

# =============================================================================
# Pause-Menue (ESC)
# =============================================================================
# Haelt das Spiel an (get_tree().paused) und blendet ein Menue mit den Optionen
# Weiter / Level neu starten / Hauptmenue ein. Wird beim ersten ESC erzeugt und
# danach nur noch ein-/ausgeblendet. Liegt -- wie das Hilfe-Panel -- im HUD,
# weil das HUD autoloaded ist und damit in jedem Level vorhanden bleibt.
# =============================================================================

const _MENU_SCENE := "res://scenes/ui/main_menu.tscn"

var _pause_panel: Control = null
var _resume_button: Button = null

func toggle_pause() -> void:
	if _pause_panel == null:
		_create_pause_panel()
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	_pause_panel.visible = should_pause
	if should_pause and _resume_button != null:
		_resume_button.grab_focus()

func _create_pause_panel() -> void:
	# Halbtransparenter, bildschirmfuellender Hintergrund -- dunkelt das Spiel ab
	# und faengt Maus-Klicks ab, damit man nicht "durch" das Menue klickt.
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.6)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Muss auch im pausierten Zustand verarbeitet werden (Buttons!).
	panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	box.add_child(title)

	_resume_button = _make_pause_button("Weiter")
	_resume_button.pressed.connect(toggle_pause)
	box.add_child(_resume_button)

	var restart_button := _make_pause_button("Level neu starten")
	restart_button.pressed.connect(_on_pause_restart)
	box.add_child(restart_button)

	var menu_button := _make_pause_button("Hauptmenue")
	menu_button.pressed.connect(_on_pause_to_menu)
	box.add_child(menu_button)

	_pause_panel = panel
	add_child(_pause_panel)
	_pause_panel.visible = false

func _make_pause_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 0)
	b.add_theme_font_size_override("font_size", 26)
	# Buttons muessen waehrend der Pause klickbar bleiben.
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	return b

func _on_pause_restart() -> void:
	# Pause aufheben und das aktuelle Level frisch laden (Fortschritt/Upgrades
	# bleiben, weil sie im GameManager liegen -- nur die Szene wird neu gebaut).
	get_tree().paused = false
	_pause_panel.visible = false
	get_tree().reload_current_scene()

func _on_pause_to_menu() -> void:
	get_tree().paused = false
	_pause_panel.visible = false
	get_tree().change_scene_to_file(_MENU_SCENE)
