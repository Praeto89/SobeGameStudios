# Glossar – Fachbegriffe kurz erklärt

Der Code und die Doku sind auf Deutsch, aber viele Fachbegriffe in der
Spieleentwicklung sind englisch. Hier die wichtigsten – mit der englischen
Schreibweise (die du in der Godot-Doku und in Tutorials findest) und einer
kurzen Erklärung.

| Begriff (engl.) | Deutsch / Bedeutung |
|---|---|
| **Node** | Baustein einer Szene. Alles in Godot ist ein Node (Spieler, Plattform, Sound …). |
| **Scene** (`.tscn`) | Eine Sammlung von Nodes, die zusammen eine Einheit bilden (z. B. der Spieler). Wiederverwendbar wie ein Bauteil. |
| **Signal** | Eine „Klingel": ein Node meldet ein Ereignis (`emit`), andere reagieren darauf – ohne sich direkt zu kennen. |
| **Autoload / Singleton** | Ein Node, der das ganze Spiel über existiert und in jeder Szene erreichbar ist (hier: `GameManager`). |
| **`@export`** | Markiert eine Variable, damit sie im Godot-**Inspector** sichtbar und ohne Code änderbar ist. |
| **`@onready`** | Eine Variable, die erst gesetzt wird, wenn der Node fertig in der Szene ist (z. B. Verweise auf Kind-Nodes). |
| **State Machine** | Zustandsautomat. Ein Objekt ist immer in genau einem Zustand (z. B. Slime: *Patrouille* / *Aktivierung* / *Tod*). |
| **Coroutine** (`await`) | Hält eine Funktion an, bis etwas fertig ist (z. B. eine Animation), **ohne** das ganze Spiel zu blockieren. |
| **Delta** | Zeit (in Sekunden) seit dem letzten Frame. Damit läuft Bewegung gleich schnell, egal wie schnell der PC ist. |
| **Velocity** | Geschwindigkeit als Vektor (x = waagrecht, y = senkrecht). |
| **Gravity** | Schwerkraft – zieht Objekte nach unten (erhöht `velocity.y`). |
| **Coyote Time** | Kurze Gnadenfrist: nach dem Verlassen einer Plattform kann man noch springen. Fühlt sich fairer an. |
| **Jump Buffer** | Ein Sprung, der kurz **vor** dem Landen gedrückt wurde, wird gemerkt und beim Aufkommen ausgeführt. |
| **Knockback** | Rückstoß – der Impuls, der einen Charakter bei einem Treffer wegschubst. |
| **Hitbox** | Bereich, der Schaden austeilt oder erkennt (in Godot oft eine `Area2D`). |
| **Pickup** | Einsammelbares Objekt (Münze, Ability). |
| **Prefab** | Eine fertige, wiederverwendbare Szene zum Reinziehen (Godot nennt das einfach „Szene"). |
| **Tween** | Eine weiche Wertänderung über Zeit (z. B. ein Element ein-/ausblenden). |
| **Headless** | Godot ohne Fenster starten – z. B. für die CI/Tests auf dem Server. |
| **CI** (Continuous Integration) | Automatische Prüfung bei jedem Push/PR (hier: Syntax-Check + Tests). |
| **Commit / Push / Pull Request** | Git-Begriffe: Änderung sichern / hochladen / zum Review vorschlagen. Siehe [CONTRIBUTING.md](CONTRIBUTING.md). |

> Ein Begriff fehlt dir? Trag ihn als [Issue](../../issues/new/choose) ein
> oder ergänz ihn direkt per Pull Request.
