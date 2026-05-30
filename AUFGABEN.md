# Aufgaben – kleine Programmier-Herausforderungen

Hier findest du kleine, klar umrissene Aufgaben direkt am echten Code. Im
Code selbst stehen kurze Marker wie `# AUFGABE (A2)` – die Erklärung und eine
mögliche Lösung findest du hier unter der passenden Nummer.

**So gehst du vor:**

1. Such dir eine Aufgabe aus, die zu deiner Stufe passt (siehe
   [CONTRIBUTING.md](CONTRIBUTING.md)).
2. Öffne die genannte Datei und suche den `# AUFGABE`-Marker.
3. Versuche es **erst selbst**. Erst danach die Lösung aufklappen.
4. Teste mit **F6** (aktuelle Szene) und schau ins Output-Panel.

> Lösungen sind eingeklappt (`▸ Lösung`). Aufklappen per Klick.

---

## A1 – Münze mit höherem Wert (Stufe 4)

**Datei:** `scripts/pickups/coin.gd`

Im Moment zählt jede Münze genau 1 Coin. Baue eine Münze, deren Wert du im
Inspector einstellen kannst (z. B. eine "Goldmünze" = 5 Coins).

**Konzept:** `@export`-Variable + Schleife.

<details>
<summary>▸ Lösung</summary>

```gdscript
# Oben bei den Variablen ergänzen:
@export var wert := 1   # Wie viele Coins diese Münze zählt

# In _on_body_entered, statt einmal collect_coin():
for i in wert:
    body.collect_coin()
```

Danach im Inspector `wert` auf 5 setzen – fertig ist die Goldmünze.
</details>

---

## A2 – Plattform vertikal bewegen (Stufe 4/5)

**Datei:** `scripts/world/green_platform.gd`

Die Plattform pendelt links/rechts (`position.x`). Lass eine Kopie stattdessen
auf und ab pendeln.

**Konzept:** Koordinatenachsen – `x` ist waagrecht, `y` ist senkrecht
(größer = weiter unten!).

<details>
<summary>▸ Lösung</summary>

```gdscript
# start_x -> start_y, und in _physics_process:
func _ready():
    start_y = position.y

func _physics_process(delta):
    position.y += speed * direction * delta
    if abs(position.y - start_y) > distance:
        direction *= -1
```

Es gibt dafür schon `green_platform_vertikal.gd` zum Abgucken –
vergleiche deine Lösung damit!
</details>

---

## A3 – Slime mit Flucht-Verhalten (Stufe 5)

**Datei:** `scripts/enemies/green_slime.gd`

Der Slime patrouilliert und greift an. Gib ihm einen neuen Zustand: wenn der
Spieler **sehr nah** ist (z. B. < 60 px), läuft der Slime **weg** statt hin.

**Konzept:** Zustandsautomat (State Machine) – einen neuen Zustand ergänzen.

<details>
<summary>▸ Lösung</summary>

```gdscript
# In _physics_process, vor der Aktivierungs-/Patrouille-Logik:
var dist := global_position.distance_to(player.global_position) if (player and is_instance_valid(player)) else INF
if dist < 60.0:
    # weg vom Spieler laufen
    var flee_dir = sign(global_position.x - player.global_position.x)
    velocity.x = flee_dir * speed
    sprite.flip_h = flee_dir < 0
    sprite.play("patrol")
    move_and_slide()
    return
```

Tipp: `INF` ist "unendlich" – praktisch als Startwert für "noch keinen
Spieler gefunden".
</details>

---

## A4 – Eigenes Pickup nach Vorlage (Stufe 4)

**Datei:** Neu anlegen, Vorlage `scripts/pickups/charge_ability.gd`

Baue ein Pickup, das den Spieler heilt (1 Herz auffüllt), statt eine Ability
freizuschalten.

**Konzept:** Vorhandenes Muster kopieren und anpassen + Methodenaufruf auf
dem Spieler.

<details>
<summary>▸ Lösung</summary>

Im Spieler braucht es eine Heil-Methode (falls noch nicht vorhanden) – schau in
`player.gd` nach `take_damage`/`health` und ergänze sinngemäß:

```gdscript
# heal_pickup.gd
extends Area2D
func _ready():
    body_entered.connect(_on_body_entered)
func _on_body_entered(body):
    if body.is_in_group("player") and body.has_method("heal"):
        body.heal(1)
        queue_free()
```

Wichtig: erst prüfen, ob die Methode existiert (`has_method`), sonst gibt es
einen Fehler, wenn ein anderer Körper das Pickup berührt.
</details>

---

## A5 – Gefühl tunen, ohne Code (Stufe 3)

**Datei:** `scripts/player/player.gd` (Bereich „DEIN SPIELFELD")

Keine neue Logik – nur Werte. Finde Konstanten, mit denen sich der Sprung
„schwerelos" (Mond) anfühlt, und ein zweites Set, das sich „bleischwer" anfühlt.
Schreib dir die Werte auf.

**Konzept:** Wie Zahlen das „Game Feel" bestimmen. Immer nur **einen** Wert auf
einmal ändern.

<details>
<summary>▸ Idee</summary>

Mond: `GRAVITY = 500`, `JUMP_VELOCITY = -300`, `MAX_FALL_SPEED = 400`
Schwer: `GRAVITY = 4000`, `JUMP_VELOCITY = -600`, `FALL_GRAVITY = 6000`

Es gibt kein „richtig" – Hauptsache, du verstehst, **welcher** Wert **was**
bewirkt.
</details>

---

Eigene Aufgabe gefunden, die hier fehlt? Trag sie als
[Issue](../../issues/new/choose) ein – so wächst die Sammlung.
