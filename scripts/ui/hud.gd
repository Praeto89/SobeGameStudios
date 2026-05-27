# =============================================================================
# hud.gd
# =============================================================================
# HUD (Heads-Up-Display) – die Spieler-Oberflaeche.
#
# Zeigt an:
#   - Lebenspunkte als Herz-Icons (rot = voll, grau = leer)
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

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var heart_container = $HBoxContainer  # Container mit den Herz-Sprites (ColorRect-Nodes)
@onready var coin_label = $CoinLabel           # Label-Node fuer den Muenzzaehler

# Referenz auf den aktuell verbundenen Player, damit wir bei Szenen-
# Wechseln nicht erneut mit derselben Instanz connecten.
var _connected_player: Node = null

# =============================================================================
# _ready()
# Verbindet sich initial mit dem Spieler und hoert auf neue Player-Nodes,
# damit nach einem Szenen-Wechsel automatisch neu verbunden wird.
# =============================================================================
func _ready() -> void:
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
# Faerbt die Herz-Icons: rot fuer volle Herzen, dunkelgrau fuer leere.
#
# new_health: Aktuelle Anzahl der Lebenspunkte
# =============================================================================
func _on_health_changed(new_health: int) -> void:
	var hearts = heart_container.get_children()
	for i in range(hearts.size()):
		# Herzen bis new_health sind rot (voll), der Rest ist grau (leer)
		hearts[i].color = Color.RED if i < new_health else Color(0.3, 0.3, 0.3)

# =============================================================================
# _on_coin_collected(new_count)
# Wird aufgerufen wenn der Spieler eine Muenze aufsammelt.
# Aktualisiert den Anzeigetext.
#
# new_count: Gesamtzahl der bisher gesammelten Muenzen
# =============================================================================
func _on_coin_collected(new_count: int) -> void:
	coin_label.text = "Coins: " + str(new_count)
