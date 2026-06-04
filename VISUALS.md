# Visuals & Effekte – was das Spiel „saftig" macht

„Game Feel" entsteht selten durch neue Sprites – meist durch **kleine optische
Reaktionen**: ein Aufblitzen bei einem Treffer, ein Stauchen bei der Landung,
ein Funken beim Einsammeln. Diese Datei sammelt alle Effekt-Ideen des Projekts
an einem Ort:

- ✅ **Schon eingebaut** – wo es im Code lebt und wie es funktioniert.
- 🟢🟡🔴 **Offene Ideen** – als kleine Aufgaben, gestaffelt nach Schwierigkeit
  (🟢 Einsteiger · 🟡 Mittel · 🔴 Fortgeschritten), genau wie in
  [AUFGABEN.md](AUFGABEN.md).

> **Grundregel für Effekte:** Sie sind *optisch* und dürfen die **Spiel-Logik
> nicht verändern**. Ein Squash skaliert nur das `AnimatedSprite2D` – die
> Kollision (eigener `CollisionShape2D`-Knoten) bleibt unberührt. So kann nie
> etwas am Gameplay „kaputtgehen".

> **Drei Werkzeuge tauchen immer wieder auf:**
> - **Tween** – animiert einen Wert weich von A nach B (`create_tween()`).
> - **`modulate`** – färbt/verblasst einen Node. Werte **größer als 1**
>   *leuchten* dank des Glow-Environments (siehe unten).
> - **Partikel** (`CPUParticles2D`) – viele kleine Sprites für Staub, Funken …
>
> Fachbegriffe sind im [GLOSSAR.md](GLOSSAR.md) erklärt.

---

## ✅ Schon eingebaut

| Effekt | Wo im Code | Kurz erklärt |
|---|---|---|
| **Höhlen-Atmosphäre** | `scenes/effects/cave_atmosphere.tscn` | `CanvasModulate` (Dunkelheit) + `WorldEnvironment` (Glow/Bloom) + schwebender Staub (`CPUParticles2D`). Per Drag&Drop in ein Level ziehen. |
| **2D-Licht & Flackern** | `scripts/effects/torch_flicker.gd` | `PointLight2D` mit zwei Modi: *Flackern* (Spieler-Laterne) und *Pulsieren* (Portale/Pickups). |
| **Nebel / Dunst** | `scenes/effects/cave_fog.tscn` | Große, weiche, treibende Partikel = ziehende Nebelschwaden. Per Drag&Drop ins Level (gern mit `cave_atmosphere` kombiniert). |
| **Schatten (Licht-Occlusion)** | `scenes/player/player.tscn` (`TorchLight`, `shadow_enabled`) + `scenes/world/green_platform.tscn` (`LightOccluder2D`) | Die Laterne wirft echte Schatten – **aber bisher nur an Objekten mit Occluder** (Plattform). Das statische Terrain wirft noch keine → siehe V13/V14. |
| **HUD: Herz bricht** | `scripts/ui/hud.gd` | Bei Schaden blitzt das Herz rot auf (`modulate`-Tween) und bricht ins nächste Frame. |
| **Squash & Stretch** | `scripts/player/player.gd` → `_play_squash()` | Absprung = hoch & schmal, Landung = breit & flach. Federt elastisch zurück. Nur ab `LANDING_SQUASH_MIN_SPEED` Fallgeschwindigkeit. |
| **Treffer-Blitz (Spieler)** | `scripts/player/player.gd` → `_flash_hit()` | Spieler leuchtet bei einem Treffer kurz rot auf (`HIT_FLASH_COLOR`). |
| **Treffer-Blitz (Gegner)** | `scripts/enemies/slime_base.gd` → `die()` | Slime leuchtet beim Tod kurz weiß auf, bevor die Todesanimation läuft. |
| **Münz-Pop** | `scripts/pickups/coin.gd` | Münze wird beim Einsammeln kurz größer und blendet aus, statt hart zu verschwinden. |
| **Portal-Fade** | `scripts/world/portal.gd` | Spieler wird beim Teleport kurz halbtransparent. |
| **Plattform-Fade** | `scripts/world/fade_area.gd` | Plattform blendet aus, wenn der Spieler dahinter steht. |
| **Tod-Zeitlupe** | `scripts/player/player.gd` → `_die()` | `Engine.time_scale = 0.5` für einen dramatischen Moment beim Sterben. |

> **Selbst tunen:** Die Effekt-Konstanten stehen im Spieler-Skript unter
> *„Effekt-Konstanten (Game Feel)"*. Probier z. B. `LANDING_SQUASH_SCALE` von
> `(1.25, 0.75)` auf `(1.5, 0.5)` – die Landung wird viel „matschiger".
> Eine kleine Absicherung dieser Werte steckt in
> `tests/test_player_constants.gd`.

---

## 🟢 Einsteiger – nur Tween & `modulate`

### V1 – Heil-Pickup pulsieren lassen
**Datei:** `scripts/pickups/heal_pickup.gd`

Damit das Heil-Pickup auffällt, soll es sanft „atmen" (Helligkeit pulsieren).

<details>
<summary>▸ Idee</summary>

Es gibt schon eine fertige Lösung dafür: häng den Knoten an `torch_flicker.gd`
(Modus *Pulsieren*) oder mach es im Skript per Endlos-Tween:

```gdscript
func _ready():
	var t = create_tween().set_loops()
	t.tween_property($Sprite2D, "modulate", Color(1.4, 1.4, 1.4), 0.6)
	t.tween_property($Sprite2D, "modulate", Color.WHITE, 0.6)
```
</details>

### V2 – Münz-Zähler im HUD „bouncen"
**Datei:** `scripts/ui/hud.gd`

Wenn eine Münze gesammelt wird, soll das Coin-Label kurz aufpoppen
(`scale` 1.0 → 1.3 → 1.0 per Tween), damit man die Belohnung „spürt".

### V3 – Schwebende Pickups
**Datei:** beliebiges Pickup-Skript

Lass Ability-Pickups sanft auf- und abschweben (`position.y` per Endlos-Tween,
`set_trans(Tween.TRANS_SINE)`). Macht sie lebendig, ohne neue Grafik.

---

## 🟡 Mittel – Partikel & wiederverwendbare Bausteine

### V4 – Landungs- & Roll-Staub
**Neu:** kleine `CPUParticles2D`-Szene, getriggert vom Spieler

Beim Landen (es gibt bereits die Erkennung in `player.gd`, Abschnitt *12. Effekt:
Landungs-Squash*) und beim Roll eine kurze Staubwolke ausstoßen.

<details>
<summary>▸ Wegweiser</summary>

1. Eine Szene `scenes/effects/dust_puff.tscn` mit `CPUParticles2D` bauen
   (`one_shot = true`, `emitting = true`, kurze `lifetime`).
2. Im Spieler dort, wo schon `_play_squash(LANDING_SQUASH_SCALE, …)` aufgerufen
   wird, eine Instanz an der Fußposition spawnen.
3. Tipp: `emitting`-Partikel räumen sich nicht selbst auf – einen kleinen Timer
   oder `finished`-Connect zum `queue_free()` nutzen.
</details>

### V5 – Sterbe-Partikel für Slimes
**Datei:** `scripts/enemies/slime_base.gd` → `die()`

Statt nur der Todesanimation kleine Schleim-Spritzer ausstoßen. Andockpunkt ist
das weiße Aufleuchten in `die()` – direkt davor/dabei Partikel spawnen.

### V6 – Charge/Dash-Schweif
**Datei:** `scripts/player/player.gd` (Charge-Block)

Während des Charge-Dashs einen Nachzieh-Effekt zeigen: entweder ein `Line2D`,
das der Position folgt, oder regelmäßig kurzlebige, halbtransparente Kopien des
Sprites („Ghosting").

### V7 – Screen-Shake
**Neu:** wiederverwendbares Skript an der `Camera2D` des Spielers

Eine Methode `shake(stärke, dauer)`, die `Camera2D.offset` für kurze Zeit
zufällig versetzt und auslaufen lässt. Aufrufen bei: Tod, harter Landung,
Charge-Impact.

<details>
<summary>▸ Skizze</summary>

```gdscript
extends Camera2D
var _amount := 0.0
func shake(staerke: float, dauer: float) -> void:
	_amount = staerke
	create_tween().tween_property(self, "_amount", 0.0, dauer)
func _process(_d):
	offset = Vector2(randf_range(-_amount, _amount), randf_range(-_amount, _amount))
```
</details>

---

## 🔴 Fortgeschritten – Shader & Environment

### V8 – Parallax-Hintergrund
**Neu:** `ParallaxBackground` + mehrere `ParallaxLayer` in den Levels

Mehrere Hintergrund-Ebenen, die sich unterschiedlich schnell mitbewegen → Tiefe.

### V9 – Treffer-Aufleuchten per Shader
**Neu:** `*.gdshader` auf dem `AnimatedSprite2D`

Sauberer als `modulate`: ein `shader_parameter` `flash_amount` (0–1) mischt das
Sprite Richtung Weiß. Aus dem Code per `material.set_shader_parameter(...)`
animiert. Würde `_flash_hit()` im Spieler ersetzen/ergänzen.

### V10 – Dissolve-Effekt beim Gegner-Tod
**Neu:** Dissolve-Shader

Slime löst sich anhand einer Rauschtextur auf, statt einfach zu verschwinden.

### V11 – Gezielte Lichter & Pickup-Glow
**Baut auf:** `cave_atmosphere.tscn` + `torch_flicker.gd`

Zusätzliche `PointLight2D` an wichtigen Stellen (Portale, Pickups – teils schon
vorhanden) bewusster setzen, damit die Höhle „Sehenswürdigkeiten" bekommt.

### V12 – Schadens-Vignette
**Neu:** `CanvasLayer` mit Vollbild-Shader

Wenn die Lebenspunkte niedrig sind, dunkelt/rötet sich der Bildschirmrand.
Anknüpfpunkt: das `health_changed`-Signal des Spielers (siehe README → *Signale*).

---

## 🌫️ Nebel, Schatten & Occlusion – im Detail

Drei oft genannte Effekte, die in der Höhle besonders viel hermachen.

### V13 – Terrain wirft Schatten (TileMap-Occlusion) ⭐
**Wo:** TileSet der Level (`scenes/levels/*.tscn` → `TileMapLayer`/`TileMap`)

**Das wichtigste Occlusion-Thema.** Die Spieler-Laterne hat `shadow_enabled`,
und einzelne Objekte (bewegliche Plattform) werfen schon Schatten. Das
**statische Terrain** aber **nicht** – die Laterne scheint durch massiven Fels.
Grund: das TileSet hat keine Occlusion-Ebene.

<details>
<summary>▸ Wegweiser (Editor)</summary>

1. TileSet öffnen (TileMapLayer anklicken → unten *TileSet*-Tab).
2. Unter *TileSet → Occlusion Layers* eine Ebene hinzufügen.
3. Im *TileSet*-Tab pro (solidem) Tile das Occluder-Polygon malen – meist deckt
   es einfach das ganze Tile ab.
4. F5 → die Laterne wirft jetzt überall im Level Schatten.

Tipp: Nur an *soliden* Tiles Occluder setzen, nicht an Hintergrund-Deko.
</details>

### V14 – Occluder an statischen Wänden (area_1)
**Wo:** `scenes/levels/area_1.tscn` (`StaticBody2D` mit `CollisionPolygon2D`)

Wo die Welt aus `CollisionPolygon2D` statt einem TileSet besteht, neben jeden
Wand-Polygon einen `LightOccluder2D` mit deckungsgleichem `OccluderPolygon2D`
legen – Vorlage: `scenes/world/green_platform.tscn`.

### V15 – „Echter" Nebel per Shader
**Neu:** `assets/effects/fog.gdshader` auf einer Vollbild-`ColorRect`
(in einem `CanvasLayer`)

Der Partikel-Nebel (V✅ `cave_fog.tscn`) ist günstig und reicht oft. Für dichten,
wabernden Bodennebel ist ein Shader mit scrollendem Rauschen schöner.

<details>
<summary>▸ Shader-Skizze (GDShader, Godot 4)</summary>

```glsl
shader_type canvas_item;
uniform vec4 fog_color : source_color = vec4(0.7, 0.74, 0.85, 1.0);
uniform float speed = 0.03;
uniform float density = 0.5;

// einfaches Wert-Rauschen
float hash(vec2 p){ return fract(sin(dot(p, vec2(41.0, 289.0))) * 43758.5453); }
float noise(vec2 p){
    vec2 i = floor(p); vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1,0)), u.x),
               mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x), u.y);
}
void fragment(){
    vec2 uv = UV * 3.0 + vec2(TIME * speed, TIME * speed * 0.3);
    float n = noise(uv) * 0.6 + noise(uv * 2.0) * 0.4;
    COLOR = vec4(fog_color.rgb, n * density);
}
```

Die `ColorRect` im `CanvasLayer` auf Bildschirmgröße ziehen und dieses Material
zuweisen. `density`/`speed` im Inspector tunen.
</details>

---

## 🎬 Post-Processing – das ganze Bild filtern

Diese Effekte liegen als Vollbild-Shader auf einem `CanvasLayer` ganz oben und
färben/verzerren das fertige Bild.

### V16 – Color Grading (Stimmung per Reglern)
**Wo:** `WorldEnvironment` in `cave_atmosphere.tscn` (hat bisher nur Glow)

`Environment → Adjustments` aktivieren und an *Brightness*, *Contrast* und
*Saturation* drehen. Eine entsättigte, leicht bläuliche Höhle wirkt sofort
kälter und bedrohlicher – ganz ohne Code.

### V17 – Lichtstrahlen / „God Rays"
**Neu:** additive Licht-Kegel oder Shader

Weiche, leicht durchscheinende Lichtstrahlen, die von oben in die Höhle fallen
(z. B. an Deckenöffnungen). Einfachste Variante: ein langgezogenes, sehr
transparentes Licht-Sprite mit `blend_mode = add`.

### V18 – Retro-Look: CRT / Scanlines / Chromatische Aberration
**Neu:** Vollbild-`*.gdshader` auf `CanvasLayer`

Leichte Scanlines, Bildröhren-Wölbung oder ein winziger Farbversatz an den
Rändern geben dem Pixel-Look einen bewussten Retro-Charme. Sparsam einsetzen –
sonst wird es schnell anstrengend.

### V19 – Hitzeflimmern / Verzerrung
**Neu:** lokaler Verzerr-Shader (Screen-UV + Rauschen)

Über Lava/heißen Zonen das Bild leicht wabern lassen. Technisch verwandt mit dem
Nebel-Shader (V15), nutzt aber `SCREEN_TEXTURE`/`screen_uv` zum Verschieben.

### V20 – Wetter: Regen / Schnee / Funken
**Neu:** `CPUParticles2D`-Szene (wie `cave_fog.tscn`)

Fallende Tropfen oder Glut-Funken als Drag&Drop-Baustein – dieselbe Technik wie
Nebel und Staub, nur andere Richtung/Form/Farbe.

---

## Mitmachen

Eine eigene Effekt-Idee, die hier fehlt? Trag sie als
[Issue](../../issues/new/choose) ein oder ergänze sie in dieser Datei – so
wächst die Sammlung. Beim Umsetzen gilt: **erst die Logik nicht anfassen**, nur
Optik obendrauf.
