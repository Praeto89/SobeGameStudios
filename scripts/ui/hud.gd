# =============================================================================
# hud.gd
# =============================================================================
# HUD (Heads-Up-Display) – die Spieler-Oberflaeche.
#
# Zeigt an:
#   - Lebenspunkte als animierte Schwert-Klingen (Healthbar.tscn)
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
# Atlas-Layout (siehe Healthbar.tscn):
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
	# Animationen anhalten -- wir setzen die Frames manuell je nach HP
	_hilt.stop()
	_hilt.frame = 0
	for i in range(_blades.size()):
		_blades[i].stop()
		_blades[i].frame = _BLADE_FRAMES[i][0]   # initial: intakt-Frame der jeweiligen Blade-Position
	# Bei jedem neu hinzugefuegten Player-Node neu connecten
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
	if node.is_in_group("player") and node != _connected_player:
		_connect_to_player()

# =============================================================================
# _connect_to_player()
# Findet den aktuellen Player im SceneTree, verbindet seine Signale mit
# dem HUD und aktualisiert die Anzeige sofort. Vorhandene Verbindungen
# werden vorher sauber getrennt.
# =============================================================================
func _connect_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
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
	# HUD sofort mit den aktuellen Werten befuellen (kein leeres HUD beim Start)
	_on_health_changed(player.current_health)
	_on_coin_collected(player.coin_count)

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
		var intact_frame: int = _BLADE_FRAMES[i][0]
		var broken_frame: int = _BLADE_FRAMES[i][1]
		_blades[i].frame = intact_frame if i < new_health else broken_frame
		_blades[i].modulate = Color.WHITE

	# Bei Schaden: rotes Aufblitzen + verzoegerter Frame-Wechsel auf den
	# "frisch verlorenen" Blades, damit man den Treffer visuell wahrnimmt.
	if damage_taken:
		for i in range(new_health, _last_health):
			_animate_blade_break(_blades[i], _BLADE_FRAMES[i][0], _BLADE_FRAMES[i][1])

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
	coin_label.text = "Coins: " + str(new_count)

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

const _HELP_TEXT := "STEUERUNG\n\n  Pfeiltasten:     Laufen\n  Leertaste:       Springen (kurz/lang fuer Sprunghoehe)\n  SHIFT:           Rollen (schadet Gegnern)\n  E (halten):      Charge-Dash aufladen + loslassen\n  Pfeil unten:     Schnellfall (in der Luft)\n\nABILITIES (per Pickup freigeschaltet)\n  Double-Jump:     Leertaste 2x\n  Wallcrawl:       automatisch an Waenden\n\nHILFE\n  F1:  dieses Fenster ein-/ausblenden"

var _help_panel: PanelContainer = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			toggle_help()
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

