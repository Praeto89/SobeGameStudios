# =============================================================================
# hud.gd
# =============================================================================
# HUD (Heads-Up-Display) – die Spieler-Oberflaeche.
#
# Zeigt an:
#   - Lebenspunkte als Herz-Icons (rot = voll, grau = leer)
#   - Anzahl gesammelter Muenzen als Text-Label
#
# Funktionsweise:
#   Das Skript verbindet sich beim Start mit den Signalen des Spielers.
#   Wenn der Spieler Schaden nimmt oder Muenzen sammelt, sendet er ein Signal
#   und das HUD aktualisiert sich automatisch.
#
# Voraussetzung: Der Spieler muss in der Gruppe "player" sein.
# =============================================================================

extends CanvasLayer

# -----------------------------------------------------------------------------
# Node-Referenzen
# -----------------------------------------------------------------------------
@onready var heart_container = $HBoxContainer  # Container mit den Herz-Sprites (ColorRect-Nodes)
@onready var coin_label = $CoinLabel           # Label-Node fuer den Muenzzaehler

# =============================================================================
# _ready()
# Verbindet sich mit den Signalen des Spielers.
# Ruft die Update-Funktionen einmalig auf, damit das HUD direkt
# den richtigen Anfangszustand anzeigt.
# =============================================================================
func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
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
