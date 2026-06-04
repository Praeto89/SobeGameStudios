# Effekte – einfach reinziehen 🎨

In diesem Ordner liegen **fertige Optik-Bausteine**. Du musst nichts
programmieren: Szene anklicken, ins Level ziehen, **F5** drücken – fertig.

## So geht Drag & Drop (ohne Code)

1. Öffne ein Level (z. B. `scenes/levels/sandbox.tscn`) per Doppelklick.
2. Im **FileSystem**-Panel unten links den Ordner **`effekte/`** öffnen.
3. Eine der **`.tscn`-Dateien** (siehe Tabelle) packen und in den **Szenen-Baum**
   links ziehen – am besten direkt auf den Wurzel-Knoten des Levels.
4. **F5** (oder F6 für genau diese Szene) drücken und staunen.
5. Gefällt's nicht? Im Szenen-Baum den Baustein anklicken und **Entf** drücken.

> Tipp: Den Baustein anklicken → rechts im **Inspector** an den Werten drehen
> (Farbe, Dichte, Tempo …). Nichts geht kaputt – **Strg+Z** macht alles rückgängig.

## Welche Bausteine gibt es?

| Datei (ins Level ziehen) | Was es macht |
|---|---|
| `cave_atmosphere.tscn` | Höhlen-Stimmung: Dunkelheit + Leuchten (Glow) + Staub |
| `cave_atmosphere_graded.tscn` | Wie oben, aber kühler/entsättigt (Ersatz, **nicht** zusätzlich) |
| `cave_fog.tscn` | Sanfte, ziehende Nebelschwaden (Partikel) |
| `cave_fog_shader.tscn` | Dichter, wabernder Nebel über dem ganzen Bild (Shader) |
| `vignette.tscn` | Dunkler Bildschirmrand, wird bei wenig Leben stärker |

> **Nur EIN „cave_atmosphere"** pro Level (normal **oder** graded) – sonst
> streiten sich zwei Umgebungen ums Bild.
> **`vignette.tscn`** braucht den Spieler im Level (verbindet sich automatisch).

## Die übrigen Dateien (nicht zum Reinziehen)

Diese gehören zu den Bausteinen, du musst sie aber nicht anfassen:

- `torch_flicker.gd` – lässt Lichter flackern/pulsieren (am Spieler & Pickups)
- `vignette.gd` – Steuerung der Schadens-Vignette
- `fog.gdshader`, `vignette.gdshader` – die Shader hinter Nebel & Vignette
- `light_soft.tres` – die weiche Licht-Form, die alle Lichter benutzen

---

Mehr Hintergrund, Tuning-Tipps und **Ideen zum Weiterbauen** (Screen-Shake,
Schatten, Lichtstrahlen …) stehen in **[../VISUALS.md](../VISUALS.md)**.
