# Beleuchtung & Effekte (Untergrund-Look)

Das Spiel spielt im Untergrund. Damit das auch so **aussieht**, gibt es ein
kleines, wiederverwendbares Beleuchtungs-System. Diese Seite erklaert, woraus
es besteht, wie du es benutzt – und den **einen** Schritt, den du noch im
Godot-Editor von Hand machen musst (Tileset-Schatten).

> Hintergrund: warum 2D-Licht so funktioniert, steht kurz im
> [GLOSSAR.md](../GLOSSAR.md). Fachbegriffe sind hier bewusst auf Deutsch
> erklaert.

---

## Die Bausteine

| Datei | Was sie macht |
|---|---|
| `assets/effects/light_soft.tres` | Die weiche, runde **Licht-Form** (ein Verlauf von Weiss innen zu transparent aussen). Alle Lichter benutzen diese eine Datei. |
| `scripts/effects/torch_flicker.gd` | Laesst ein Licht **flackern** (Fackel) oder **pulsieren** (Portal/Pickup). |
| `scenes/effects/cave_atmosphere.tscn` | Der **Untergrund-Baustein**: Dunkelheit + Glow + Staub in einem. |

### `cave_atmosphere.tscn` enthaelt drei Knoten

1. **`CanvasModulate` ("Dunkelheit")** – taucht die ganze Szene in
   Hoehlen-Dunkel. Heller machen = die Farbwerte Richtung `1.0` schieben,
   pechschwarz = Richtung `0.0`.
2. **`WorldEnvironment` ("Glow")** – ein Bloom/Glow-Effekt, damit helle
   Dinge (Muenzen, Pickups, Portale) in der Dunkelheit **leuchten**.
3. **`CPUParticles2D` ("Staub")** – langsam schwebende Staubkoernchen fuer
   Atmosphaere.

---

## Wo das Licht herkommt

- **Spieler-Fackel:** `scenes/player/player.tscn` hat einen `PointLight2D`
  namens **TorchLight** mit dem Flacker-Skript. Weil jedes Level den Spieler
  instanziert, hat **jedes Level automatisch** dieses Licht.
- **Leuchtende Sammelobjekte:** Muenze, alle Ability-Pickups, Heal-Pickup und
  das Portal haben ein kleines, pulsierendes `Glow`-Licht. Auch das wirkt
  ueberall automatisch, weil es in den Prefab-Szenen steckt.

---

## So fuegst du den Untergrund-Look in ein Level ein

Bereits eingebaut in: `main`, `area_1`, `turm`, `sandbox`, `galerie`
sowie in die Schueler-Vorlage `_vorlage.tscn`.

Fuer ein **neues** Level (z. B. dein eigenes im `student_levels/`-Ordner):

1. Im **FileSystem**-Tab `scenes/effects/cave_atmosphere.tscn` finden.
2. Per **Drag & Drop** auf den Wurzel-Knoten deines Levels ziehen.
3. Fertig. Optional: den Knoten **`Dunkelheit`** anklicken und die Farbe
   heller/dunkler stellen, falls dein Level Text-Labels hat (siehe Galerie).

---

## Der eine Editor-Schritt: Tileset-Schatten

Die Spieler-Fackel kann **echte Schatten** werfen (`shadow_enabled` ist an),
und die Plattform-Szene `green_platform.tscn` hat dafuer schon einen
`LightOccluder2D`. Die **Tilemap-Waende** (TileMapLayer) werfen aber erst
Schatten, wenn das **Tileset** eine Occlusion-Ebene bekommt. Das laesst sich
nur im Editor einstellen:

1. Level oeffnen, den **TileMapLayer** anklicken.
2. Im Inspector das **TileSet** oeffnen (doppelklick auf die Ressource).
3. Unten bei **TileSet → Occlusion Layers** eine Ebene **hinzufuegen**.
4. Im **TileSet**-Editor (unten) zum Tab **Paint / Occlusion** wechseln und
   den Tiles ihre Occluder-Polygone zuweisen (bei vollen Bloecken einfach das
   ganze Quadrat).

> Ohne diesen Schritt sieht alles trotzdem gut aus – nur die Waende werfen
> dann eben keinen Schatten. Die Beleuchtung selbst funktioniert sofort.

---

## Schnell mal etwas aendern (gute erste Experimente)

| Was | Wo | Tipp |
|---|---|---|
| Hoehle heller/dunkler | `cave_atmosphere.tscn` → Knoten **Dunkelheit** → `color` | naeher an `1.0` = heller |
| Staerke des Leuchtens | `cave_atmosphere.tscn` → **Glow** → Environment → `glow_intensity` | 0 = aus |
| Fackel-Reichweite | `player.tscn` → **TorchLight** → `texture_scale` | groesser = weiteres Licht |
| Fackel-Flackern | **TorchLight** → `staerke` / `tempo` | `staerke = 0` = ruhiges Licht |
| Pickup-Pulsieren | jeweils Knoten **Glow** → `staerke` / `tempo` | `modus` = Flackern/Pulsieren |
| Mehr/weniger Staub | `cave_atmosphere.tscn` → **Staub** → `amount` | |
