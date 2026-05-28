# Schueler-Level

Jeder Slot ist ein eigenes Mini-Level, das ueber die **Galerie** erreichbar ist.

## Wie nehme ich einen Slot?

1. Oeffne `slot_1.tscn` (oder einen anderen freien Slot) im Godot-Editor
2. Baue dein Level (Prefabs aus `scenes/` ins Level ziehen)
3. **Strg+S** zum Speichern
4. Per Godot-Versionsverwaltung committen und pushen

> **Tipp:** Schreib in den `Hinweis`-Label deinen Namen rein, damit alle wissen wessen Level das ist.

## Welcher Slot ist frei?

- Slot 1 – frei
- Slot 2 – frei
- Slot 3 – frei
- Slot 4 – frei

Bitte Liste aktualisieren, wenn du einen Slot belegst.

## Mehr Slots brauchen?

1. Kopiere `_vorlage.tscn` zu `slot_5.tscn` (Datei-Manager, nicht im Editor)
2. Oeffne `slot_5.tscn` und **aendere die UID** in der ersten Zeile
   (sonst kollidiert sie mit der Vorlage – z. B. `uid://sl0t05klassezz5`)
3. Oeffne `scenes/levels/galerie.tscn`, dupliziere ein bestehendes `ToSlotX`-Portal
   und stelle ein:
   - `portal_id = "to_slot_5"`
   - `target_portal_id = "from_galerie"`
   - `target_scene = "res://scenes/levels/student_levels/slot_5.tscn"`
4. Setze ein Label "Slot 5" daneben.

## Wie funktioniert die Portal-Logik?

Jeder Slot enthaelt **ein** Portal `ReturnPortal`:

- `portal_id = "from_galerie"` – Spawn-Punkt wenn der Spieler aus der Galerie kommt
- `target_portal_id = "galerie_entry"` – Wohin geht's beim Betreten zurueck?
- `target_scene = "res://scenes/levels/galerie.tscn"`

Das passt zu den `ToSlotX`-Portalen in der Galerie, die alle
`target_portal_id = "from_galerie"` haben.
