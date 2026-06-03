# Orientierung – die Godot-Oberfläche verstehen

Bevor du loslegst: ein kurzer Rundgang durch den Godot-Editor. Wenn dir Begriffe
wie „Inspector" oder „FileSystem-Dock" nichts sagen – hier wird's klar. Du
musst nichts auswendig lernen, komm einfach zurück, wenn du etwas suchst.

> Fachbegriffe (Node, Signal, …) stehen kurz erklärt im [GLOSSAR.md](GLOSSAR.md).

---

## Das Fenster auf einen Blick

```
┌───────────────┬───────────────────────────────────────┬──────────────────┐
│               │   [2D] [3D] [Script] [AssetLib]        │                  │
│   Szene-Baum  │                                        │    Inspector     │
│  (oben links) │                                        │   (rechts)       │
│               │                                        │                  │
│  Player       │          2D-ANSICHT / VIEWPORT         │  Eigenschaften   │
│  Boden        │      (hier siehst du dein Level)       │  des angeklickten│
│  coin1        │                                        │  Nodes – hier    │
│  green_platf… │      ▶  F5 / F6 zum Starten            │  sind die        │
│               │                                        │  @export-Werte!  │
├───────────────┤                                        │                  │
│  FileSystem   │                                        │                  │
│ (unten links) │                                        │                  │
│               ├────────────────────────────────────────┴──────────────────┤
│  res://       │   Output  |  Debugger  |  Audio  ...                        │
│   scenes/     │   (unten) – hier erscheinen FEHLER in Rot                   │
│   scripts/    │                                                             │
│   assets/     │                                                             │
└───────────────┴─────────────────────────────────────────────────────────────┘
```

(Das ist die Standard-Anordnung. Verschiebbar – aber fang erst mal so an.)

---

## Die wichtigsten Bereiche

### 1. FileSystem-Dock (unten links)
Alle Dateien des Projekts – wie ein Datei-Explorer. Hier findest du Szenen
(`.tscn`), Skripte (`.gd`), Bilder, Sounds.
- **Doppelklick** auf eine `.tscn` → öffnet die Szene.
- **Ziehen** einer `.tscn` in die 2D-Ansicht → fügt sie ins Level ein (Prefab).

### 2. Szene-Baum / „Scene"-Dock (oben links)
Zeigt die Bausteine (**Nodes**) der gerade offenen Szene als Baum.
- **Klick** auf einen Node → er wird im Inspector (rechts) angezeigt.
- Jeder Node ist ein Teil: Spieler, Boden, eine Münze …

### 3. Inspector (rechts) ← **hier passiert dein Tuning**
Zeigt alle Eigenschaften des angeklickten Nodes. Ganz wichtig: hier stehen die
**`@export`-Werte** (z. B. `speed`, `distance`). Ändern = sofort wirksam, **ohne
Code**. Das ist Stufe 0/3 in [CONTRIBUTING.md](CONTRIBUTING.md).

### 4. 2D-Ansicht / Viewport (Mitte)
Dein Level, so wie du es baust. Mit den Tabs oben (**2D / 3D / Script /
AssetLib**) wechselst du die Ansicht. Wir arbeiten fast nur in **2D** und
**Script**.

### 5. Output-Panel (unten) ← **hier stehen Fehler**
Nach dem Start erscheinen hier Meldungen. **Rote** Zeilen = Fehler. Wenn etwas
nicht klappt: zuerst hier schauen. Siehe auch [FAQ.md](FAQ.md).

---

## Die wichtigsten Tasten

| Taste | Was passiert |
|---|---|
| **F5** | Ganzes Spiel starten (ab der Main-Szene) |
| **F6** | Nur die **aktuell offene** Szene starten (zum Testen) |
| **F1** | *Im laufenden Spiel:* Steuerungs-Hilfe ein-/ausblenden |
| **Strg + S** | Aktuelle Szene speichern |
| **Strg + Z** | Letzte Änderung rückgängig (im Editor) |
| **Maus-Rad** | In der 2D-Ansicht zoomen |
| **Mittlere Maustaste (halten)** | 2D-Ansicht verschieben |

> Faustregel: **F6** zum Testen deiner Szene, **Strg+S** vorher nicht vergessen,
> bei Problemen ins **Output-Panel** schauen.

---

## Wie geht's weiter?

1. [QUICKSTART.md](QUICKSTART.md) – in 10 Minuten dein erstes Mini-Level.
2. [CONTRIBUTING.md](CONTRIBUTING.md) – die 5 Beitragsstufen.
3. Klemmt etwas? → [FAQ.md](FAQ.md).
