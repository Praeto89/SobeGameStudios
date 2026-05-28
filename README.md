# SobeGameStudios – 2D-Plattformer

Ein gemeinsames Lernprojekt in Godot 4.6. Ziel ist es, durch die Entwicklung eines eigenen Spiels grundlegende Konzepte der Spieleentwicklung zu erlernen: Physik, KI, Signale, Szenenmanagement und mehr.

> **Neu hier und noch nie mit Godot gearbeitet?**
> → Lies zuerst [QUICKSTART.md](QUICKSTART.md) – in 10 Minuten zum ersten eigenen Beitrag, ganz ohne Code.
> → Danach [CONTRIBUTING.md](CONTRIBUTING.md) für gestufte Beitragspfade (Stufe 1 = Asset tauschen, Stufe 5 = eigenes Skript).

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
├── Concepts & ideas/  Ideen und Design-Notizen des Teams
└── project.godot      Godot-Projektkonfiguration
```

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

Das Projekt nutzt Godot-Signale zur Kommunikation zwischen Spieler und UI:

| Signal | Sender | Empfänger | Beschreibung |
|---|---|---|---|
| `health_changed(new_health)` | Spieler | HUD | Lebenspunkte haben sich geändert |
| `coin_collected(new_count)` | Spieler | HUD | Münze wurde aufgesammelt |

---

## Geplante Features

Design-Ideen und Konzepte des Teams befinden sich im Ordner `Concepts & ideas/`:

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
