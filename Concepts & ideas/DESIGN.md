# Design-Entscheidungen – das „Warum" hinter dem Spiel

Dieses Dokument erklärt **warum** das Spiel so gebaut ist, wie es ist. Der Code
zeigt das *Wie*; hier geht es um die Gedanken dahinter. Solche Design-Doku ist
oft lehrreicher als der Code selbst – sie zeigt, dass jede Entscheidung
Alternativen hatte.

> Die rohen Brainstorming-Notizen liegen daneben (`ideas.txt`, die `.txt`- und
> `.xcf`-Konzepte). Dieses Dokument fasst die getroffenen Entscheidungen zusammen.

---

## 1. Game Feel zuerst

Ein Plattformer steht und fällt mit dem Sprung-Gefühl. Deshalb hat der Spieler
bewusst mehr Bewegungs-Komfort als „nur Schwerkraft + Sprung":

- **Variable Sprunghöhe** – kurz tippen = kleiner Hüpfer, halten = hoher Sprung.
- **Coyote Time** – kurz nach dem Plattformrand springt man noch. Ohne das
  fühlt sich ein verpasster Sprung „ungerecht" an.
- **Jump Buffer** – ein Sprung kurz vor der Landung wird gemerkt.
- **Erhöhte Fall-Gravity** – fallen geht schneller als steigen. Das fühlt sich
  „knackiger" an als symmetrische Schwerkraft.

**Lernziel:** Gutes Spielgefühl entsteht nicht aus realistischer Physik, sondern
aus vielen kleinen „Schummeleien" zugunsten des Spielers. Alle Werte dazu stehen
gesammelt im Bereich *DEIN SPIELFELD* in `scripts/player/player.gd`.

---

## 2. Abilities als freischaltbare Bausteine

Charge, Wallcrawl und Double Jump sind **nicht** von Anfang an aktiv, sondern
werden per Pickup freigeschaltet.

**Warum so?**
- Es schafft eine Progression („ich werde stärker").
- Technisch ist jede Ability ein eigenes, kleines, kopierbares Muster
  (Pickup-Szene + `unlock_*()`-Methode). Das macht sie zur idealen Vorlage für
  eigene Beiträge (Stufe 4).

**Warum lebt der Ability-Zustand im `GameManager`?**
Beim Szenenwechsel wird der Spieler **neu** erzeugt – lokale Flags wären weg.
Der `GameManager` ist ein Autoload und überlebt den Wechsel, also merkt er sich
dort, was schon freigeschaltet ist. Gleiches gilt für Leben, Münzen und besiegte
Gegner.

---

## 3. Signale statt direkter Verdrahtung

Der Spieler kennt das HUD **nicht**. Er ruft nicht `hud.update_health()` auf,
sondern *sendet* `health_changed(...)`. Das HUD hört zu.

**Warum so?**
- Der Spieler funktioniert auch ohne HUD (z. B. in einer Test-Szene).
- Man kann beliebig viele Zuhörer ergänzen (HUD, Sound, Statistik), ohne den
  Spieler zu ändern.

**Trade-off:** Bei vielen Signalen wird der Fluss schwerer nachvollziehbar.
Deshalb sind die Signale in `README.md` mit Diagrammen dokumentiert.

---

## 4. Persistenz über stabile IDs

Eingesammelte Münzen und besiegte Gegner sollen nach einem Szenenwechsel nicht
wieder auftauchen. Dafür bekommt jeder fest platzierte Node eine stabile ID
(`<szene>::<node_name>`), die im `GameManager` in einer Liste gesammelt wird.

**Warum nur fest platzierte Nodes?** Zur Laufzeit *gespawnte* Gegner bekommen
automatische Namen, die nicht stabil sind – die werden bewusst nicht
persistiert (siehe `green_slime.gd`, `is_spawned`).

---

## 5. Bewegliche Plattformen als `AnimatableBody2D`

Plattformen bewegen sich in `_physics_process` und erben von `AnimatableBody2D`
(nicht `Node2D`). Nur so nimmt Godot den darauf stehenden Spieler korrekt mit.

**Lernziel:** Die Wahl des Node-Typs ist eine Design-Entscheidung mit Folgen –
nicht jedes „bewegt sich" ist gleich.

---

## 6. Lernbarkeit ist ein Design-Ziel

Dieses Repo soll nicht nur ein Spiel sein, sondern ein **Lernort**. Daraus
folgen bewusste Entscheidungen:

- Werte sind als `@export` oder Konstanten **sichtbar** und mit
  „probier: X oder Y"-Hinweisen versehen.
- Kommentare erklären das **Warum**, nicht nur das Was.
- Es gibt absichtliche Bugs (`BUGCHASE.md`) und Mini-Aufgaben (`AUFGABEN.md`).
- Eine `sandbox.tscn` bietet einen sicheren Spielplatz.

---

## Offene Ideen (noch nicht entschieden)

Siehe die Konzept-Dateien daneben:

- **Schwert-Angriff** (`sword dash concept text.txt`) – Nahkampf mit Dash.
- **Schwert-Slot-System** (`Sword slot concept text.txt`) – austauschbare
  Ability-Slots als Equipment.

Wer eines davon umsetzen will: erst hier (oder als Issue) skizzieren, *warum*
und *wie* – dann bauen.
