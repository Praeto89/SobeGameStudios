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
Das gemeinsame Slime-Verhalten lebt in `scripts/enemies/slime_base.gd`. Dort
gibt es eine extra Methode `_handle_extra_state(delta)`, die du in
`green_slime.gd` **überschreiben** kannst, ohne die ganze Hauptschleife zu
kopieren.

<details>
<summary>▸ Lösung</summary>

In `green_slime.gd` diese Methode ergänzen:

```gdscript
# Wird von SlimeBase jeden Frame VOR der Aktivierungs-/Patrouille-Logik gefragt.
# Gibt true zurueck, wenn der Slime in diesem Frame fluechtet.
func _handle_extra_state(_delta: float) -> bool:
	var dist := global_position.distance_to(player.global_position) if (player and is_instance_valid(player)) else INF
	if dist < 60.0:
		# weg vom Spieler laufen
		var flee_dir = sign(global_position.x - player.global_position.x)
		velocity.x = flee_dir * speed
		sprite.flip_h = flee_dir < 0
		sprite.play("patrol")
		return true   # "Ich uebernehme die Bewegung diesen Frame"
	return false      # sonst macht SlimeBase normal weiter
```

Tipp: `INF` ist "unendlich" – praktisch als Startwert für "noch keinen
Spieler gefunden". Das `return true/false` sagt der Basis-Klasse, ob sie
danach noch Patrouille/Aktivierung ausführen soll.
</details>

---

## A4 – Eigenes Pickup nach Vorlage (Stufe 4)

**Datei:** Neu anlegen, Vorlage `scripts/pickups/charge_ability.gd`

Baue ein Pickup, das den Spieler heilt (1 Herz auffüllt), statt eine Ability
freizuschalten.

> Es gibt bereits ein **fertiges Beispiel** dazu: `scripts/pickups/heal_pickup.gd`
> + `scenes/pickups/heal_pickup.tscn`. Versuch es trotzdem zuerst selbst –
> danach kannst du deine Lösung damit vergleichen oder eine eigene Variante
> bauen (z. B. ein Pickup, das den Spieler schneller macht).

**Konzept:** Vorhandenes Muster kopieren und anpassen + Methodenaufruf auf
dem Spieler.

<details>
<summary>▸ Lösung</summary>

Im Spieler gibt es bereits eine passende Methode `heal(amount)` (siehe
`scripts/player/player.gd`). Du brauchst also nur ein Pickup, das sie aufruft:

```gdscript
# heal_pickup.gd
extends Area2D
func _ready():
	body_entered.connect(_on_body_entered)
func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(1)   # 1 Herz auffuellen (begrenzt auf max. Leben)
		queue_free()
```

Wichtig: erst prüfen, ob die Methode existiert (`has_method`), sonst gibt es
einen Fehler, wenn ein anderer Körper das Pickup berührt.

> Zum Üben: Schau dir `heal()` im Spieler an – sie ist das Gegenstück zu
> `take_damage()` und begrenzt die Leben auf `max_health`.
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

## Lust auf Optik statt Logik?

Effekt-Aufgaben (Squash & Stretch, Partikel, Screen-Shake, Shader …) leben in
einer eigenen Sammlung: [VISUALS.md](VISUALS.md). Dort steht auch, welche
Effekte schon eingebaut sind und wo im Code sie sitzen.

---

Eigene Aufgabe gefunden, die hier fehlt? Trag sie als
[Issue](../../issues/new/choose) ein – so wächst die Sammlung.
