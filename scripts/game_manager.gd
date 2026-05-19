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
