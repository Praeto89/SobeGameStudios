# Quickstart – die ersten 10 Minuten

Du hast Godot noch nie benutzt? Perfekt. Wir bauen jetzt zusammen dein erstes
eigenes Mini-Level. Kein Programmieren noetig, nur klicken und ziehen.

---

## Schritt 1: Projekt oeffnen (1 min)

1. [Godot 4.6](https://godotengine.org/) installieren
2. Repository klonen oder als ZIP herunterladen
3. Godot starten → **Projekt importieren** → die Datei `project.godot` waehlen → **Importieren & Bearbeiten**

Du siehst jetzt den Godot-Editor mit dem leeren Spiel.

---

## Schritt 2: Sandbox oeffnen (30 sek)

Im Editor links siehst du den **FileSystem**-Tab. Klick dich durch:

```
res://
└── scenes/
    └── levels/
        └── Sandbox.tscn      ← Doppelklick!
```

Du siehst eine Spielwiese mit Boden, Spieler, ein paar Muenzen und Plattformen.

---

## Schritt 3: Spielen (10 sek)

Druecke **F6**.

> **F6** = nur diese Szene starten
> **F5** = das ganze Spiel starten (Main-Szene)

Du laeufst mit Pfeiltasten und springst mit Leertaste. Probiere die Portale unten links (Galerie) und unten rechts (Hauptlevel) aus.

> **F1 druecken** – die Steuerung wird als Overlay eingeblendet. Nochmal F1 = wieder weg.

Spiel schliessen mit dem **X** oben rechts.

---

## Schritt 4: Etwas hinzufuegen (2 min)

Du bist wieder im Editor. Jetzt baust du etwas Eigenes in die Sandbox.

1. Im **FileSystem**-Tab links zu `scenes/pickups/` navigieren
2. **`coin.tscn`** mit der Maus packen und in die **2D-Ansicht** (das grosse Fenster in der Mitte) ziehen
3. An eine Stelle ueber dem Boden loslassen
4. **Strg+S** zum Speichern
5. **F6** zum Testen

Sammle deine neue Muenze ein. Klingelt's? Glueckwunsch, du hast etwas zum Spiel beigetragen.

---

## Schritt 5: Werte anpassen (1 min)

Klick eine der **green_platform**-Plattformen in der Szene an.
Rechts oeffnet sich der **Inspector**.

Scroll runter zu:
- `speed` (Geschwindigkeit) – probier mal **200**
- `distance` (wie weit sie pendelt) – probier mal **150**

**Strg+S**, dann **F6**. Schon eine richtige Achterbahn.

---

## Schritt 6: Dein eigener Slot in der Galerie (5 min)

Jetzt bekommst du deinen eigenen Bereich, der spaeter im Klassen-Spiel sichtbar ist.

1. Im Sandbox-Level ins linke Portal (**Galerie**) laufen
2. In der Galerie zu **Slot 1** (oder einem freien Slot) laufen
3. Du landest in einem leeren Level – das ist deins!
4. Zurueck in den Editor wechseln und `scenes/levels/student_levels/slot_1.tscn` oeffnen
5. Den `Hinweis`-Label anklicken und im Inspector `text` auf **"Slot 1 – DEIN NAME"** aendern
6. Prefabs reinziehen (siehe Schritt 4)
7. **Strg+S**

Eintragen welcher Slot belegt ist:
`scenes/levels/student_levels/README.md` oeffnen und in der Liste deinen Namen ergaenzen.

---

## Was kannst du noch reinziehen?

Alles aus diesen Ordnern funktioniert per Drag-and-Drop:

| Prefab | Pfad | Was es macht |
|---|---|---|
| Muenze | `scenes/pickups/coin.tscn` | Einsammelbar, gibt einen Punkt |
| Bewegliche Plattform | `scenes/world/green_platform.tscn` | Pendelt automatisch |
| Boden-Slime | `scenes/enemies/green_slime.tscn` | Patrouilliert, kann besiegt werden |
| Wand-Slime | `scenes/enemies/Wall Slime.tscn` | Klebt an Waenden |
| Gegner-Spawner | `scenes/enemies/geen_slime_spawner.tscn` | Spawnt regelmaessig Gegner |
| Charge-Ability | `scenes/pickups/charge_ability.tscn` | Schaltet Dash frei |
| Double-Jump | `scenes/pickups/doublejump_ability.tscn` | Schaltet 2. Sprung frei |
| Wallcrawl | `scenes/pickups/wallcrawl_ability.tscn` | Klettern an Waenden |
| Todeszone | `scenes/world/death.tscn` | Respawnt den Spieler |
| Portal | `scenes/world/portal.tscn` | Teleport (siehe README im Slot-Ordner) |

Bei jedem Prefab kannst du im Inspector die **@export**-Werte aendern
(Geschwindigkeit, Reichweite, Gegner-Anzahl etc.) – kein Code noetig.

---

## Aenderungen teilen

1. **Strg+S** in allen geaenderten Szenen
2. Im Terminal (oder ueber Godot's Git-Plugin): committen + pushen
3. Fertig – beim naechsten Klassen-Start sehen alle dein Level in der Galerie

---

## Was, wenn etwas nicht funktioniert?

- **Spieler faellt durch den Boden** – die Bodenflaeche ist zu klein oder die Wand fehlt. Sandbox-Boden ist gross genug.
- **Portal "kein Partner gefunden"** – `portal_id` und `target_portal_id` muessen zusammenpassen. Details in `scenes/levels/student_levels/README.md`.
- **Spiel startet nicht** – mit **F6** statt F5 nur die aktuelle Szene starten.

Tieferen Einstieg in Code findest du im Haupt-`README.md` und in den `.gd`-Dateien unter `scripts/`.
