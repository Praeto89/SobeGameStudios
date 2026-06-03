# =============================================================================
# purple_slime_wall.gd
# =============================================================================
# Der lila Wand-Slime – die "aktive" Variante des Wand-Slimes.
#
# Verhalten kommt komplett aus SlimeBase. Konfiguriert als schwebender Slime,
# der den Spieler aber bemerkt und auf ihn zustuermt:
#   - gravity = 0          -> schwebt an der Wand
#   - speed = 35           -> etwas flotter
#   - detection_range = 150 -> reagiert auf den Spieler (Aktivierungs-Animation)
#   - Spritesheet: assets/sprites/slime_purple.png
#
# Die konkreten Werte sind in purple_slime_wall.tscn bzw. im Inspector gesetzt
# und koennen dort gefahrlos getunt werden.
# =============================================================================

extends SlimeBase
