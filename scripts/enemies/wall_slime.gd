# =============================================================================
# wall_slime.gd
# =============================================================================
# Der Wand-/Hindernis-Slime.
#
# Verhaelt sich wie jeder Slime (Verhalten kommt aus SlimeBase), ist aber als
# stationaeres Hindernis konfiguriert. Die Werte werden in der Szene
# (wall_slime.tscn) bzw. im Inspector eingestellt:
#   - gravity = 0          -> der Slime faellt nicht herunter (klebt an der Wand)
#   - speed = 20           -> langsamer als der Boden-Slime
#   - detection_range = 0  -> erkennt den Spieler nicht, laeuft also immer nur Patrouille
#   - Spritesheet: assets/sprites/slime_purple.png
# =============================================================================

extends SlimeBase
