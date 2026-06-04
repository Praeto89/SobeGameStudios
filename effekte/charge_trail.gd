# =============================================================================
# charge_trail.gd
# =============================================================================
# Geist-Spur waehrend des Charge-Dashs. Drag&Drop als Kind des Spielers
# (CharacterBody2D) in player.tscn.
#
# Aufbau:
#   player.tscn
#   └── CharacterBody2D (Spieler-Root)
#       └── ChargeSpur   <- hierhin ziehen
#
# Erzeugt halbdurchsichtige Kopien des Spieler-Sprites, die langsam ausblenden.
# Farbe und Timing sind im Inspector frei einstellbar.
# =============================================================================
extends Node2D

@export var geist_intervall := 0.05         ## Probier: 0.02 (dicht) bis 0.15 (luftig)
@export var geist_alpha     := 0.45         ## Probier: 0.2 (fast unsichtbar) bis 0.8 (stark)
@export var geist_farbe     := Color(0.4, 0.7, 1.0)  ## Probier: rot fuer Roll-Spur, gelb fuer Blitz
@export var geist_dauer     := 0.20         ## Probier: 0.1 (schnell) bis 0.5 (lang nachleuchtend)

var _timer   := 0.0
var _spieler: CharacterBody2D
var _sprite:  AnimatedSprite2D

func _ready() -> void:
	_spieler = get_parent() as CharacterBody2D
	if _spieler:
		_sprite = _spieler.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _process(delta: float) -> void:
	if _spieler == null or _sprite == null or not _spieler.is_charging:
		_timer = 0.0
		return
	_timer += delta
	if _timer >= geist_intervall:
		_timer = 0.0
		_spawn_geist()

func _spawn_geist() -> void:
	var frames := _sprite.sprite_frames
	if frames == null:
		return
	var textur := frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if textur == null:
		return

	var geist             := Sprite2D.new()
	geist.texture          = textur
	geist.flip_h           = _sprite.flip_h
	geist.scale            = _sprite.scale * _spieler.scale
	geist.global_position  = _sprite.global_position
	geist.modulate         = Color(geist_farbe.r, geist_farbe.g, geist_farbe.b, geist_alpha)
	geist.z_index          = -1
	get_tree().current_scene.add_child(geist)

	var tw := geist.create_tween()
	tw.tween_property(geist, "modulate:a", 0.0, geist_dauer)
	tw.tween_callback(geist.queue_free)
