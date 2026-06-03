# =============================================================================
# green_slime.gd
# =============================================================================
# Der gruene Boden-Slime – der "Standard"-Gegner des Spiels.
#
# Das komplette Verhalten (Patrouille, Erkennung, Aktivierung, Tod, Persistenz)
# kommt aus der gemeinsamen Basis-Klasse SlimeBase (scripts/enemies/slime_base.gd).
# Dieser Slime stellt nur seine Werte im Editor ein:
#   - speed = 80, gravity = 800, detection_range = 200 (Standard aus SlimeBase)
#   - Spritesheet: assets/sprites/slime_green.png
#
# Wird vom Spieler getoedet durch: Roll, Attacke oder Charge-Ability.
#
# 📝 AUFGABE (A3, Stufe 5): Gib dem Slime einen "Flucht"-Zustand, wenn der
#    Spieler sehr nah ist (laeuft weg statt hin). Dafuer ist in SlimeBase die
#    ueberschreibbare Methode _handle_extra_state() vorgesehen.
#    Loesung: AUFGABEN.md -> A3
# =============================================================================

extends SlimeBase

# 💡 A3-Startpunkt: Diese Methode aus SlimeBase hier ueberschreiben.
#    Beispiel-Geruest (auskommentiert) – siehe AUFGABEN.md fuer die Loesung:
#
# func _handle_extra_state(_delta: float) -> bool:
# 	# Hier deine Flucht-Logik einbauen und true zurueckgeben,
# 	# wenn der Slime in diesem Frame fluechtet.
# 	return false
