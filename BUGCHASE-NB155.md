# Bug Chase – Fehler finden ist auch Programmieren

Fehlersuche (Debugging) ist eine der wichtigsten Faehigkeiten in der
Spieleentwicklung. Hier findest du absichtlich eingebaute Bugs zum Entdecken
und Beheben – ohne dass etwas kaputt geht, weil es eine eigene Sandbox ist.

> **So geht's:** Lies die Symptom-Beschreibung, oeffne das angegebene Skript
> im Godot-Editor, finde den Fehler – und dann fix ihn. Loesungen stehen
> am Ende dieser Datei (erst versuchen, dann spicken!).

---

## Bug 1 – Der unsichtbare Sprung (Einsteiger)

**Symptom:** Der Spieler springt gar nicht mehr, egal wie oft du Leertaste drueckst.

**Suche in:** `scripts/player/player.gd`

**Hinweis:** Schau dir `JUMP_VELOCITY` an. Was passiert wenn der Wert positiv statt
negativ ist? In Godot zeigt die Y-Achse **nach unten** – ein positiver Wert
drueckt den Spieler also in den Boden statt nach oben.

**Zum Ausprobieren:** Aendere `JUMP_VELOCITY = -400.0` kurz auf `JUMP_VELOCITY = 400.0`
und druecke F5. Was passiert?

---

## Bug 2 – Der hyperaktive Slime (Einsteiger)

**Symptom:** Der gruene Slime rast mit Lichtgeschwindigkeit durch das Level.

**Suche in:** `scripts/enemies/slime_base.gd` (gemeinsames Slime-Verhalten)
oder direkt im Inspector

**Hinweis:** `@export var speed` – was ist ein sinnvoller Wert?
Klick den Slime im Editor an → Inspector → schau was dort steht.

**Zum Ausprobieren:** Setze `speed` im Inspector auf 5000. F6. Dann wieder
auf 80 zuruecksetzen.

---

## Bug 3 – Muenze hoert nie auf zu spielen (Fortgeschritten)

**Symptom:** Der Sammel-Sound einer Muenze laeuft nach dem Einsammeln
weiter, obwohl die Muenze verschwunden ist.

**Suche in:** `scripts/pickups/coin.gd`

**Hinweis:** Schau dir die Reihenfolge der Aktionen in `_on_body_entered` an.
Was passiert wenn `queue_free()` aufgerufen wird bevor `audio.finished` abgewartet wird?

**Zum Ausprobieren:** Tausche die Zeilen
```
await audio.finished
queue_free()
```
zu
```
queue_free()
await audio.finished
```
und sammle eine Muenze ein. Was passiert?

---

## Bug 4 – Portal-Ping-Pong (Fortgeschritten)

**Symptom:** Der Spieler wird endlos zwischen zwei Portalen hin- und hergepingt.

**Suche in:** `scripts/world/portal.gd`

**Hinweis:** Schau dir `_start_cooldown()` an. Was wuerde passieren wenn das
Partner-Portal (`portal._start_cooldown()`) nicht aufgerufen wird?

**Zum Ausprobieren:** Kommentiere in `_teleport_in_scene()` die Zeile
`portal._start_cooldown()` aus und laufe durch ein Portal. Was passiert?

---

## Bug 5 – Das gefrorene Spiel (Fortgeschritten)

**Symptom:** Nach dem Tod laeuft das Spiel ewig in Zeitlupe.

**Suche in:** `scripts/player/player.gd`, Funktion `_die()`

**Hinweis:** `Engine.time_scale = 0.5` setzt das Spiel auf halbe Geschwindigkeit.
Wo wird es wieder auf 1.0 zurueckgesetzt? Was wuerde passieren, wenn die
Death-Animation unterbrochen wird (z. B. durch schnellen Szenenwechsel)?

Das ist kein zum-Ausprobieren-Bug – zu riskant. Aber schau dir die
`_exit_tree()`-Funktion an, die genau diesen Fall abfaengt.

---

## Loesungen (erst selbst versuchen!)

<details>
<summary>Bug 1 – Loesung anzeigen</summary>

`JUMP_VELOCITY` muss negativ sein, weil Godots Y-Achse nach unten zeigt.
`-400.0` drueckt nach oben, `+400.0` drueckt nach unten in den Boden.
Zurueck auf `-400.0` setzen.

</details>

<details>
<summary>Bug 2 – Loesung anzeigen</summary>

`speed` auf einen sinnvollen Wert zwischen 50 und 200 setzen.
Der Default-Wert im Skript ist 80 – das ist ein guter Ausgangspunkt.

</details>

<details>
<summary>Bug 3 – Loesung anzeigen</summary>

`await audio.finished` muss VOR `queue_free()` stehen. Wird der Node
zuerst freigegeben, wird auch der AudioStreamPlayer2D sofort geloescht –
der Sound wird abrupt abgeschnitten. Das `await` haelt die Funktion an,
bis der Sound fertig ist, ohne das Spiel zu blockieren (Coroutine!).

</details>

<details>
<summary>Bug 4 – Loesung anzeigen</summary>

Ohne `portal._start_cooldown()` hat das Ziel-Portal nach der Teleportation
keine Abklingzeit. Der Spieler landet drin und loest es sofort erneut aus –
Endlosschleife. Das Partner-Portal muss ebenfalls kurz gesperrt werden.

</details>

<details>
<summary>Bug 5 – Loesung anzeigen</summary>

`_exit_tree()` wird aufgerufen wenn der Node aus dem Szenenbaum entfernt wird.
Falls der Spieler waehrend der Death-Zeitlupe aus der Szene entfernt wird
(Levelwechsel), kommt das `await` in `_die()` nie zurueck – `Engine.time_scale`
bliebe bei 0.5 haengen. `_exit_tree()` setzt es als Sicherheitsnetz zurueck.

</details>
