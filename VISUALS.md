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

### V11 – Schatten & gezielte Lichter
**Baut auf:** `cave_atmosphere.tscn` + `torch_flicker.gd`

`LightOccluder2D` an Plattformen, damit die Spieler-Laterne echte Schatten wirft.
Zusätzliche `PointLight2D` an wichtigen Stellen (Portale, Pickups).

### V12 – Schadens-Vignette
**Neu:** `CanvasLayer` mit Vollbild-Shader

Wenn die Lebenspunkte niedrig sind, dunkelt/rötet sich der Bildschirmrand.
Anknüpfpunkt: das `health_changed`-Signal des Spielers (siehe README → *Signale*).

---

## Mitmachen

Eine eigene Effekt-Idee, die hier fehlt? Trag sie als
[Issue](../../issues/new/choose) ein oder ergänze sie in dieser Datei – so
wächst die Sammlung. Beim Umsetzen gilt: **erst die Logik nicht anfassen**, nur
Optik obendrauf.
