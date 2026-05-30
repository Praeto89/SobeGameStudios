# Mitmachen

Dieses Projekt ist ein gemeinsames Lern-Spiel der Klasse. Du musst nicht
programmieren koennen, um etwas beizutragen – such dir einfach die Stufe aus,
die zu deinem aktuellen Wissen passt. Jede Stufe ist ein abgeschlossener Beitrag.

> Noch nie mit Godot gearbeitet? Erst [QUICKSTART.md](QUICKSTART.md) lesen,
> dann hier weitermachen.

---

## Stufe 0 – Im Editor tunen, kein Code, kein Git (5 Minuten)

Kein Schreiben, kein Git, kein Terminal. Nur klicken und ausprobieren.

1. Godot oeffnen, `scenes/levels/sandbox.tscn` doppelklicken
2. Eine **Plattform** in der Szene anklicken → rechts im **Inspector** scrollen
3. `speed` auf **200** setzen → **Strg+S** → **F6**
4. Beobachten: die Plattform rast jetzt. Zurueck auf 50 → wieder langsam.

Funktioniert auch mit dem **Slime**:
- Slime in der Szene anklicken → Inspector → `detection_range` auf **500** → F6  
- Der Slime reagiert jetzt schon von weit weg auf den Spieler.

**Was du dabei lernst:** Jeder `@export`-Wert im Code ist direkt im Editor
aenderbar. Das ist Godots Weg, Daten von Logik zu trennen.

> Wenn du nichts kaputt machen willst: Strg+Z setzt jede Aenderung zurueck.
> Oder einfach die Szene ohne Speichern schliessen – dann ist alles wie vorher.

---

## Stufe 1 – Assets austauschen (kein Code)

Tausche ein Sprite, einen Sound oder die Musik aus. Du brauchst nur einen
Bildbearbeiter oder eine fertige Grafik.

1. Eigene PNG/OGG/WAV-Datei nach `assets/sprites/` bzw. `assets/sounds/` legen
2. Im Godot-Editor das Original (z. B. `assets/sprites/coin.png`) anklicken
3. Im Inspector den Pfad durch deine neue Datei ersetzen –
   **oder** die alte Datei einfach mit gleichem Namen ueberschreiben
4. Speichern (Strg+S), pushen

**Tipps:**
- Sprites am besten in der gleichen Pixelgroesse wie das Original
- Lizenzhinweis ergaenzen in `assets/LICENSE & CREDITS.txt`

---

## Stufe 2 – Eigenes Level bauen (kein Code)

Bau ein eigenes Mini-Level in einem freien Slot.

1. `scenes/levels/student_levels/README.md` oeffnen, freien Slot reservieren
2. `slot_1.tscn` (oder den von dir gewaehlten) oeffnen
3. Prefabs aus dem FileSystem-Tab reinziehen:
   - `scenes/pickups/coin.tscn` – Muenze
   - `scenes/world/green_platform.tscn` – bewegliche Plattform
   - `scenes/enemies/green_slime.tscn` – Gegner
   - `scenes/pickups/charge_ability.tscn` etc. – Abilities
4. F6 zum Testen, Strg+S zum Speichern

**Tipps:**
- Mehrere Plattformen uebereinander = Parkour
- Den `Hinweis`-Label in der Szene mit deinem Namen beschriften

---

## Stufe 3 – Werte tunen (Inspector, kein Code)

Aenderungen an Verhalten ohne Code zu schreiben.

1. Eine Plattform in einem Level anklicken (z. B. in Sandbox)
2. Rechts im **Inspector** scrollen bis zu den **@export**-Werten:
   - `speed` – Geschwindigkeit
   - `distance` – wie weit sie pendelt
3. Werte aendern, Strg+S, F6 zum Testen

Funktioniert auch bei:
- **Gegner-Spawner** (`scenes/enemies/green_slime_spawner.tscn`): Spawn-Intervall, Max-Gegner
- **Portal** (`scenes/world/portal.tscn`): Cooldown, Ziel-IDs

**Wo finde ich die `@export`-Werte im Code?**
- `scripts/world/green_platform.gd` – `@export var speed`, `@export var distance`
- `scripts/world/portal.gd` – `@export var cooldown_duration` etc.

---

## Stufe 4 – Eigenes Pickup nach Vorlage (etwas Code)

Du willst ein neues Pickup, das eine bestehende Mechanik wiederverwendet?
Kopier eine vorhandene Datei und passe sie an.

1. `scripts/pickups/coin.gd` und `scenes/pickups/coin.tscn` kopieren
   (z. B. nach `gem.gd` / `gem.tscn`)
2. In `gem.gd` aendern, was beim Aufsammeln passieren soll
   (z. B. zwei Muenzen statt einer)
3. In `gem.tscn`:
   - Sprite austauschen
   - Skript-Verknuepfung auf `gem.gd` aendern
4. Pickup ins Level ziehen, testen

**Beispiele zum Abgucken:**
- `scripts/pickups/coin.gd` – einfachstes Pickup
- `scripts/pickups/charge_ability.gd` – Pickup mit Methodenaufruf auf Spieler
- `scripts/pickups/doublejump_ability.gd` – noch ein Pickup-Muster

---

## Stufe 5 – Eigenes Skript (Code)

Eine neue Spielmechanik, die es noch nicht gibt? Eigenes Skript.

1. Im Editor: Rechtsklick im FileSystem auf `scripts/world/` → **Neues Skript**
2. `extends Node2D` (oder das, was du erweitern willst)
3. Im passenden Ordner ablegen: `enemies/`, `pickups/`, `world/`, `ui/`, `player/`
4. Mit `@onready var` Node-Referenzen holen, `signal` fuer HUD-Updates nutzen

**Vorlagen zum Abgucken:**
- `scripts/world/green_platform.gd` – animierte Bewegung im `_physics_process`
- `scripts/enemies/green_slime.gd` – KI-Zustaende
- `scripts/world/portal.gd` – `body_entered`-Signal, Szenen-Wechsel

**Signal-Konvention im Projekt:**
- Spieler sendet `health_changed(new_health)` und `coin_collected(new_count)`
- HUD haengt sich automatisch dran (siehe `scripts/ui/hud.gd`)

---

## Git-Workflow

Egal welche Stufe – so kommen deine Aenderungen ins gemeinsame Spiel:

1. Eigener Branch fuer dein Feature (Konflikte vermeiden):
   ```
   git checkout -b feature/dein-name-was-du-baust
   ```
2. Aenderungen machen, in Godot speichern (Strg+S)
3. Im Terminal:
   ```
   git status                    # was hat sich geaendert?
   git add <deine-dateien>       # gezielt, nicht "git add ."
   git commit -m "feat: was ich gemacht habe"
   git push -u origin feature/dein-name-was-du-baust
   ```
4. Auf GitHub einen **Pull Request** erstellen → andere koennen draufschauen
   (eine Vorlage mit „Was habe ich gelernt?" wird automatisch eingefuegt)
5. Nach Review: in `main` mergen

**Bitte nicht:**
- Direkt auf `main` pushen (ausser Lehrer:in sagt OK)
- Fremde Slot-Levels veraendern
- Grosse Binaerdateien (>5 MB) ohne Ruecksprache committen

---

## Debuggen lernen

Fehlersuche ist eine Kernkompetenz. In [`BUGCHASE.md`](BUGCHASE.md) findest du
5 eingebaute Bugs mit Symptom-Beschreibung, Suchhilfe und aufklappbarer Loesung.
Empfehlung: Versuche jeden Bug selbst zu finden, bevor du die Loesung anschaust.

Lust, selbst etwas zu bauen? In [`AUFGABEN.md`](AUFGABEN.md) gibt es kleine,
klar umrissene Code-Herausforderungen (Stufe 3–5) – die Marker `📝 AUFGABE`
stehen direkt im passenden Skript.

---

## Wer hilft mir?

- README im jeweiligen Ordner (`scenes/levels/student_levels/README.md` usw.)
- Kommentare in den `.gd`-Dateien – die sind ausfuehrlich auf Deutsch, oft mit WARUM-Erklaerungen
- F1 im laufenden Spiel = Steuerungs-Hilfe
- [`BUGCHASE.md`](BUGCHASE.md) – Bugs finden und verstehen
- In der Klasse: nachfragen!
