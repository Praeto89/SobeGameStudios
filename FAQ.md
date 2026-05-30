# FAQ – wenn etwas klemmt

Die häufigsten Stolpersteine beim Einstieg – mit schneller Lösung. Findest du
deinen Fall nicht? In der Klasse nachfragen oder ein
[Issue](../../issues/new/choose) aufmachen.

> **Goldene Regel:** Wenn etwas nicht klappt, schau zuerst ins **Output-Panel**
> unten im Editor. Rote Zeilen sagen meistens genau, was los ist.
> (Wo das ist? → [ORIENTIERUNG.md](ORIENTIERUNG.md))

---

## Beim Öffnen

**„Beim ersten Öffnen erscheinen viele Meldungen / es dauert."**
Godot importiert beim ersten Mal alle Assets. Das ist normal – einmal warten,
danach geht's schnell.

**„Importing"-Fehler oder fehlende Ressourcen.**
Meist eine alte/halbe Kopie. Schließen, Ordner frisch klonen, `project.godot`
neu importieren. Hilft das nicht: den versteckten Ordner `.godot/` löschen und
neu importieren (der wird automatisch neu erzeugt).

---

## Beim Spielen

**„Das Spiel startet nicht / die falsche Szene startet."**
Du willst **deine** Szene testen? Dann **F6** (aktuelle Szene), nicht F5
(ganzes Spiel ab Main).

**„Der Spieler fällt durch den Boden."**
Der Boden braucht eine Kollisionsfläche (`CollisionPolygon2D`/`CollisionShape2D`),
nicht nur ein Bild. In der Sandbox ist der Boden groß genug – bau dort, oder
kopier den `Boden`-Node aus der Sandbox.

**„Der Spieler bleibt an unsichtbaren Wänden hängen."**
Eine Kollisionsfläche ist zu groß oder liegt falsch. Den betreffenden Node
anklicken und die Form in der 2D-Ansicht prüfen.

**„Portal sagt 'kein Partner gefunden'."**
`portal_id` und `target_portal_id` müssen zusammenpassen, und `target_scene`
muss auf die richtige Szene zeigen. Details:
`scenes/levels/student_levels/README.md`.

**„Die bewegliche Plattform bewegt sich nicht."**
`speed` steht auf 0? Oder `distance` ist sehr klein. Im Inspector prüfen
(Stufe 3 in [CONTRIBUTING.md](CONTRIBUTING.md)).

---

## Beim Bearbeiten

**„Meine Änderung ist nach dem Neustart weg."**
Vor dem Testen **Strg+S** drücken. Geänderte Szenen erkennst du am `(*)`
hinter dem Namen im Tab.

**„Ich habe etwas kaputt gemacht."**
**Strg+Z** macht Editor-Änderungen rückgängig. Noch nicht gespeichert? Szene
einfach ohne Speichern schließen – dann ist alles wie vorher.

**„Ich finde die `@export`-Werte nicht."**
Node in der Szene anklicken → rechts im **Inspector** runterscrollen. Im Code
stehen sie als `@export var …` (z. B. in `scripts/world/green_platform.gd`).

---

## Bei Git / Hochladen

**„Ich trau mich nicht ans Terminal."**
Musst du nicht – Godot hat einen eingebauten Git-Bereich. Anleitung:
[CONTRIBUTING.md → „Git ohne Terminal"](CONTRIBUTING.md#git-ohne-terminal-im-godot-editor).

**„Rotes ❌ bei meinem Pull Request (CI)."**
Kein Drama – das ist Teil des Lernens. Klick auf **Details** beim roten Häkchen,
dann zeigt die CI, welche Datei/Zeile Probleme macht (Syntaxfehler oder ein
fehlgeschlagener Test). Beheben, speichern, erneut pushen.

**„Merge-Konflikt."**
Meist, weil zwei Leute dieselbe Datei geändert haben. In der Klasse Bescheid
geben – das lösen wir gemeinsam. Vorbeugen: nur **deine eigenen** Dateien
ändern (eigener Slot!) und vor dem Start `git pull`.

---

## Beim Debuggen üben

Lust, Fehler gezielt zu suchen? In [BUGCHASE.md](BUGCHASE.md) gibt es 5
eingebaute Bugs mit Hinweisen und Lösung. Eine gute Übung, bevor du eigenen
Code schreibst.
