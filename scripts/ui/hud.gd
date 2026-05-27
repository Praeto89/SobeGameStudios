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
#   Frame 0 = Region (17, 0)   -> intakt
#   Frame 3 = Region (34, 16)  -> ganz zerbrochen
const _BLADE_FRAME_FULL := 0
const _BLADE_FRAME_BROKEN := 3

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
	for blade in _blades:
		blade.stop()
		blade.frame = _BLADE_FRAME_FULL
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
# Bei Schaden laeuft die "verlorene" Klinge animiert durch alle Zwischen-
# frames (intakt -> leicht -> stark beschaedigt -> zerbrochen). Bei Heilen
# (oder Initial) werden die Frames direkt gesetzt.
#
# new_health: Aktuelle Anzahl der Lebenspunkte
# =============================================================================
const _BLADE_BREAK_STEP := 0.08   # Sekunden zwischen den Zwischenframes

var _last_health: int = -1
var _blade_tweens: Array = []     # Laufende Schadensanimationen pro Blade

func _on_health_changed(new_health: int) -> void:
	# Laufende Animationen abbrechen, damit sie keine alten Frames mehr
	# setzen, wenn der Spieler zwischendurch geheilt wird.
	for t in _blade_tweens:
		if t != null and t.is_valid():
			t.kill()
	_blade_tweens.clear()

	if _last_health == -1 or new_health >= _last_health:
		# Initial-Aufruf oder Heilung -> alle Blades direkt setzen
		for i in range(_blades.size()):
			_blades[i].frame = _BLADE_FRAME_FULL if i < new_health else _BLADE_FRAME_BROKEN
	else:
		# Schaden: Blades innerhalb des neuen HP-Werts sind intakt,
		# Blades jenseits des alten HP-Werts sind schon zerbrochen,
		# die "frisch verlorenen" Blades dazwischen werden animiert.
		for i in range(_blades.size()):
			if i < new_health:
				_blades[i].frame = _BLADE_FRAME_FULL
			elif i >= _last_health:
				_blades[i].frame = _BLADE_FRAME_BROKEN
		for i in range(new_health, _last_health):
			_animate_blade_break(_blades[i])

	_last_health = new_health

# =============================================================================
# _animate_blade_break(blade)
# Laesst eine Klinge animiert zerbrechen: Frame 1 -> 2 -> 3 mit kurzen
# Pausen. Lambda-frei umgesetzt ueber tween_callback + bind, damit die
# Animation auch dann sauber laeuft, wenn der Spieler mehrfach hintereinander
# Schaden bekommt.
# =============================================================================
func _animate_blade_break(blade: AnimatedSprite2D) -> void:
	var tween = create_tween()
	# Frames 1, 2, 3 in Reihe abspielen
	for f in [1, 2, _BLADE_FRAME_BROKEN]:
		tween.tween_callback(_set_blade_frame.bind(blade, f))
		tween.tween_interval(_BLADE_BREAK_STEP)
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
