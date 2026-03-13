extends CanvasLayer

@onready var heart_container = $HBoxContainer
@onready var coin_label = $CoinLabel

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.coin_collected.connect(_on_coin_collected)
		_on_health_changed(player.current_health)
		_on_coin_collected(player.coin_count)

func _on_health_changed(new_health: int) -> void:
	var hearts = heart_container.get_children()
	for i in range(hearts.size()):
		hearts[i].color = Color.RED if i < new_health else Color(0.3, 0.3, 0.3)

func _on_coin_collected(new_count: int) -> void:
	coin_label.text = "Coins: " + str(new_count)
