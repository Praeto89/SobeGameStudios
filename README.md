# SobeGameStudios – 2D-Plattformer

Ein gemeinsames Lernprojekt in Godot 4.6. Ziel ist es, durch die Entwicklung eines eigenen Spiels grundlegende Konzepte der Spieleentwicklung zu erlernen: Physik, KI, Signale, Szenenmanagement und mehr.

> **Neu hier und noch nie mit Godot gearbeitet?**
> → Erst die Oberfläche kennenlernen: [ORIENTIERUNG.md](ORIENTIERUNG.md) (2 Min).
> → Dann [QUICKSTART.md](QUICKSTART.md) – in 10 Minuten zum ersten eigenen Beitrag, ganz ohne Code.
> → Danach [CONTRIBUTING.md](CONTRIBUTING.md) für gestufte Beitragspfade (Stufe 1 = Asset tauschen, Stufe 5 = eigenes Skript).
> → Lust auf eine konkrete Mini-Herausforderung? [AUFGABEN.md](AUFGABEN.md).
> → Englischer Fachbegriff unklar? [GLOSSAR.md](GLOSSAR.md). Klemmt etwas? [FAQ.md](FAQ.md).

---

## Starten

1. [Godot 4.6](https://godotengine.org/) herunterladen und installieren
2. Dieses Repository klonen oder herunterladen
3. In Godot: **Projekt importieren** → Ordner auswählen → `project.godot` öffnen
4. Auf **Spielen** (F5) drücken – die Main-Szene startet automatisch

---

## Steuerung

| Taste | Aktion |
|---|---|
| Pfeiltasten Links/Rechts | Laufen |
| Leertaste | Springen |
| SHIFT (halten) | Rollen (schadet Gegnern) |
| E (halten) | Charge-Dash aufladen und auslösen |
| Pfeiltaste Unten (in der Luft) | Schnellfall |

> **Tipp:** Springen kurz drücken = niedriger Sprung. Lang drücken = höherer Sprung.

---

## Abilities (freischaltbar per Pickup)

| Ability | Taste | Beschreibung |
|---|---|---|
| **Charge** | E halten | Kurzer Aufladevorgang, dann schneller Dash nach vorne |
| **Wallcrawl** | automatisch | An Wänden klettern + von der Wand abspringen |
| **Double Jump** | Leertaste (2x) | Zweiter Sprung in der Luft |

Pickups liegen im Level verteilt. Einmal aufgesammelt, ist die Ability dauerhaft aktiv.

---

## Projektstruktur

```
SobeGameStudios/
├── scripts/
│   ├── player/        player.gd  (Spieler-Controller)
│   ├── enemies/       green_slime.gd, wall_slime.gd, green_slime_spawner.gd
│   ├── pickups/       charge_ability.gd, doublejump_ability.gd, wallcrawl_ability.gd, coin.gd
│   ├── world/         green_platform.gd, green_platform_vertikal.gd, death.gd, fade_area.gd, portal.gd
│   ├── ui/            hud.gd
│   └── game_manager.gd  (Singleton / Autoload)
├── scenes/
│   ├── levels/        main.tscn, area_1.tscn, turm.tscn
│   ├── player/        player.tscn
│   ├── enemies/       green_slime.tscn, wall_slime.tscn, green_slime_spawner.tscn, …
│   ├── pickups/       charge_ability.tscn, doublejump_ability.tscn, coin.tscn, …
│   ├── world/         green_platform.tscn, death.tscn, fade_area.tscn, portal.tscn
│   └── ui/            hud.tscn, background_music.tscn
├── assets/
│   ├── sprites/       Charakter- und Welt-Sprites
│   ├── sounds/        Soundeffekte
│   ├── music/         Hintergrundmusik
│   ├── fonts/         Schriftarten
│   └── textures/      Tileset und Texturen
├── tests/             Automatische Logik-Tests (headless, ohne Addon)
├── Concepts & ideas/  Ideen + DESIGN.md (das „Warum" hinter dem Spiel)
└── project.godot      Godot-Projektkonfiguration
```

**Lern-Dokumente im Überblick:**

| Datei | Wofür |
|---|---|
| [ORIENTIERUNG.md](ORIENTIERUNG.md) | Die Godot-Oberfläche verstehen (Inspector, FileSystem …) |
| [QUICKSTART.md](QUICKSTART.md) | In 10 Minuten zum ersten Beitrag, ohne Code |
| [FAQ.md](FAQ.md) | Häufige Stolpersteine + schnelle Lösungen |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 5 Beitragsstufen (Asset → eigenes Skript) |
| [AUFGABEN.md](AUFGABEN.md) | Kleine Code-Herausforderungen mit Lösung |
| [BUGCHASE.md](BUGCHASE.md) | 5 eingebaute Bugs zum Suchen |
| [GLOSSAR.md](GLOSSAR.md) | Englische Fachbegriffe kurz erklärt |
| [Concepts & ideas/DESIGN.md](Concepts%20%26%20ideas/DESIGN.md) | Design-Entscheidungen und ihr „Warum" |
| [tests/README.md](tests/README.md) | Wie die Tests laufen und wie man eigene schreibt |
| [TODO.md](TODO.md) | Offene Aufgaben, die im Editor/von Hand zu erledigen sind (z. B. Screenshots) |

---

## Skript-Übersicht

| Datei | Beschreibung |
|---|---|
| `scripts/player/player.gd` | **Spieler-Controller** – Bewegung, Sprung, Abilities, Schaden, Tod |
| `scripts/game_manager.gd` | **Singleton** – speichert den Portal-Zustand zwischen Szenen |
| `scripts/world/portal.gd` | **Portal** – Teleportiert den Spieler (gleiche Szene oder Level-Wechsel) |
| `scripts/ui/hud.gd` | **HUD** – Zeigt Herzen und Münzen an, reagiert auf Spieler-Signale |
| `scripts/pickups/coin.gd` | **Münze** – Sammelbar, löst Signal aus, spielt Sound |
| `scripts/world/death.gd` | **Todeszone** – Löst Respawn aus wenn der Spieler eintritt |
| `scripts/enemies/green_slime.gd` | **Boden-Slime** – Patrouilliert, erkennt Spieler, kann sterben |
| `scripts/enemies/wall_slime.gd` | **Wand-Slime** – Wie Boden-Slime, aber ohne Schwerkraft |
| `scripts/enemies/green_slime_spawner.gd` | **Spawner** – Erzeugt Gegner in Intervallen bis zum Maximum |
| `scripts/world/green_platform.gd` | **Horizontale Plattform** – Pendelt links/rechts |
| `scripts/world/green_platform_vertikal.gd` | **Vertikale Plattform** – Pendelt auf/ab |
| `scripts/world/fade_area.gd` | **Fade-Bereich** – Blendet Plattform aus wenn Spieler dahinter steht |
| `scripts/pickups/charge_ability.gd` | **Pickup** – Schaltet Charge-Ability frei |
| `scripts/pickups/doublejump_ability.gd` | **Pickup** – Schaltet Double-Jump frei |
| `scripts/pickups/wallcrawl_ability.gd` | **Pickup** – Schaltet Wallcrawl-Ability frei |

---

## Lernkarte – welches Konzept lerne ich wo?

Du musst nicht alles auf einmal verstehen. Diese Karte zeigt, **welches
Konzept** an **welcher Stelle** im echten Code steckt – und eine kleine Sache,
die du dort ausprobieren kannst. Von oben (leicht) nach unten (anspruchsvoll).

| Konzept | Wo im Code | Probier es / Aufgabe |
|---|---|---|
| **`@export`-Werte tunen** | `world/green_platform.gd`, `enemies/green_slime.gd` | `speed`/`distance` im Inspector ändern (CONTRIBUTING Stufe 0/3) |
| **Game Feel / Konstanten** | `player/player.gd` (Bereich *DEIN SPIELFELD*) | Sprung „Mond" vs. „bleischwer" → [AUFGABEN.md](AUFGABEN.md) A5 |
| **Signale** | `player/player.gd` → `ui/hud.gd` | siehe Abschnitt *Signale* unten; ein HUD-Element anschließen |
| **Pickup-Muster** | `pickups/coin.gd`, `pickups/charge_ability.gd` | Goldmünze bauen → [AUFGABEN.md](AUFGABEN.md) A1 |
| **Bewegung & Achsen** | `world/green_platform.gd` | vertikal pendeln → [AUFGABEN.md](AUFGABEN.md) A2 |
| **Coroutine (`await`)** | `pickups/coin.gd`, `enemies/green_slime.gd` | Reihenfolge von Sound & `queue_free` → [BUGCHASE.md](BUGCHASE.md) Bug 3 |
| **State Machine (KI)** | `enemies/green_slime.gd` | Flucht-Zustand ergänzen → [AUFGABEN.md](AUFGABEN.md) A3 |
| **Singleton / Persistenz** | `game_manager.gd` | wie überleben Abilities den Szenenwechsel? |
| **Tests** | `tests/` | eigenen `t.check(...)` schreiben → `tests/README.md` |

> **Schwierigkeits-Tags im Code:** Viele Skripte tragen im Kopf einen Hinweis
> `Schwierigkeit: [EINSTEIGER]` oder `[FORTGESCHRITTEN]`. So siehst du auf einen
> Blick, was schon für dich greifbar ist. Such im Editor nach `[EINSTEIGER]`.

Fachbegriffe (Signal, Coroutine, State Machine …) sind im [GLOSSAR.md](GLOSSAR.md)
kurz erklärt.

---

## Ability-System

Abilities werden durch Pickup-Objekte im Level freigeschaltet. Jedes Pickup ist eine `Area2D`-Szene mit einem eigenen Skript (`charge_ability.gd`, `doublejump_ability.gd`, `wallcrawl_ability.gd`).

**Ablauf:**
1. Spieler betritt die Area des Pickups
2. Pickup-Skript ruft die entsprechende `unlock_*()` Methode auf dem Spieler auf
3. Spieler-Skript setzt das Ability-Flag auf `true`
4. Pickup entfernt sich selbst aus der Szene

```
Pickup-Area2D  →  body.unlock_charge()  →  Player.has_charge = true
```

---

## Gegner-System

### Slime-KI (green_slime.gd / wall_slime.gd)

```
Zustand 1: Patrouille
  → Läuft in eine Richtung
  → Dreht um wenn Wand getroffen

Zustand 2: Aktivierung (einmalig wenn Spieler nah)
  → Dreht sich zum Spieler
  → Spielt Aktivierungs-Animation

Tod (ausgelöst durch Roll oder Charge des Spielers)
  → Kollision deaktivieren
  → Todesanimation abspielen
  → Aus Szene entfernen
```

### Spawner (green_slime_spawner.gd)

- Erzeugt Gegner an seiner Position in einem einstellbaren Zeitintervall
- Respektiert eine maximale Gegneranzahl
- Gegner-Anzahl wird über die Godot-Gruppe `"enemy"` gezählt

---

## Signale

Godot-Signale sind wie Klingeln: jemand klingelt (emit_signal), jemand anderes
öffnet die Tür (_on_...). Sender und Empfänger kennen sich **nicht direkt** –
das hält den Code entkoppelt und wartbar.

```
Spieler nimmt Schaden
        │
        ▼
emit_signal("health_changed", 3)
        │
        └──► HUD._on_health_changed(3)
                     │
                     ▼
               Blade 4 wird rot + bricht
```

```
Spieler beruehrt Muenze
        │
        ▼
collect_coin()  →  emit_signal("coin_collected", 5)
        │
        └──► HUD._on_coin_collected(5)
                     │
                     ▼
               CoinLabel zeigt "Coins: 5"
```

| Signal | Sender | Empfänger | Beschreibung |
|---|---|---|---|
| `health_changed(new_health)` | Spieler | HUD | Lebenspunkte haben sich geändert |
| `coin_collected(new_count)` | Spieler | HUD | Münze wurde aufgesammelt |

---

## Debuggen lernen

Fehlersuche ist eine Kernkompetenz. Im [`BUGCHASE.md`](BUGCHASE.md) findest du
5 absichtliche Bugs mit Symptom-Beschreibung, Suchhilfe und aufklappbarer Lösung.
Ideal als Einstieg bevor du eigenen Code schreibst.

Wenn du selbst Hand anlegen willst, warten in [`AUFGABEN.md`](AUFGABEN.md)
kleine, klar umrissene Code-Herausforderungen – die passenden Marker
(`📝 AUFGABE`) stehen direkt im Code.

---

## Tests

Das Projekt hat kleine automatische Tests der Spiel-**Logik** (in `tests/`).
Sie laufen ohne Fenster und ohne Zusatz-Addon:

```
godot --headless --path . --script res://tests/run_tests.gd
```

Bei jedem Push/Pull Request laufen sie automatisch in der CI mit. Was sie prüfen
und wie du eigene Tests schreibst, steht in [`tests/README.md`](tests/README.md).

---

## Geplante Features

Die Design-Entscheidungen hinter dem Spiel (und ihr „Warum") sind in
[`Concepts & ideas/DESIGN.md`](Concepts%20%26%20ideas/DESIGN.md) zusammengefasst.
Rohe Ideen und Konzept-Skizzen des Teams liegen daneben im Ordner `Concepts & ideas/`:

- **Schwert-Angriff** – Nahkampf mit Dash-Komponente
- **Wall Jump** – Ist bereits implementiert als Teil von Wallcrawl
- **Schwert-Slot-System** – Equipment/Ability-Slots für austauschbare Fähigkeiten

---

## Assets & Lizenz

**Code:** MIT-Lizenz (siehe `LICENSE`)

**Assets** (Sprites, Sounds, Musik) sind unter der CC0-Lizenz (Public Domain) verfügbar.  
Details und Quellenangaben: `assets/LICENSE & CREDITS.txt`

| Asset-Typ | Quelle |
|---|---|
| Sprites | analogStudios, RottingPixels |
| Musik & Sounds | Brackeys / Sofia Thirslund |
| Schriftart | PixelOperator von Jayvee Enaguas |
