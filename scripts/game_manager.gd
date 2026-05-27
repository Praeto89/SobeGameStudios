# GameManager.gd
# -------------------------------------------------------
# Als Autoload-Singleton einrichten:
#   Projekt > Projekteinstellungen > Autoload
#   Skript: res://GameManager.gd  |  Name: GameManager
# -------------------------------------------------------
extends Node

## ID des Portals, aus dem der Spieler zuletzt kam.
## Wird genutzt, um beim Szenenwechsel das Spawn-Portal zu finden.
var came_from_portal_id: String = ""

# -------------------------------------------------------
# Persistente Ability-Flags
# -------------------------------------------------------
# Diese Variablen ueberleben Szenen-Wechsel (Autoload bleibt am Leben).
# Beim Szenen-Wechsel wird der Player neu instanziiert -> ohne diese
# Flags waeren alle Abilities im neuen Level wieder weg.
# Der Player liest die Flags in _ready() und schreibt sie in unlock_*().
var has_charge: bool = false
var has_wallcrawl: bool = false
var has_double_jump: bool = false
