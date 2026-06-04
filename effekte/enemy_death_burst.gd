# =============================================================================
# enemy_death_burst.gd
# =============================================================================
# Partikel-Explosion beim Gegnertod. Drag&Drop als Kind eines Slimes in
# der jeweiligen Slime-Szene. Der Node MUSS "TodExplosion" heissen.
#
# Aufbau:
#   green_slime.tscn / wall_slime.tscn / ...
#   └── CharacterBody2D (Slime-Root)
#       └── TodExplosion   <- hierhin ziehen, Name NICHT aendern!
#
# Beim Tod loest slime_base.gd automatisch ausloesen() aus. Der Node trennt
# sich selbst vom sterbenden Gegner und bereinigt sich nach dem Burst.
# =============================================================================
extends CPUParticles2D

func ausloesen() -> void:
	# Vom sterbenden Gegner trennen und in die Szene einhaengen, damit
	# queue_free() des Gegners die Partikel nicht vorzeitig loescht.
	reparent(get_tree().current_scene)
	emitting = true
	await get_tree().create_timer(lifetime + 0.3).timeout
	queue_free()
