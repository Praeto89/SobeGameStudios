# Tests

Kleine automatische Prüfungen der Spiel-**Logik**. Sie laufen ohne Fenster
(„headless") und brauchen kein externes Addon – alles ist selbstgebaut und in
einfachem GDScript, damit du es lesen und verstehen kannst.

## Lokal ausführen

```
godot --headless --path . --script res://tests/run_tests.gd
```

Ausgabe ungefähr so:

```
=== SobeGameStudios Tests ===

GameManager:
  [OK]   reset_game setzt has_charge auf false
  ...
Player-Konstanten:
  [OK]   JUMP_VELOCITY ist negativ (Sprung geht nach oben)
  ...
Ergebnis: 11 bestanden, 0 fehlgeschlagen
Alles gruen. ✅
```

In der **CI** laufen die Tests automatisch bei jedem Push/Pull Request
(siehe `.github/workflows/godot-ci.yml`). Ein roter Lauf zeigt sofort, wenn
eine Änderung etwas kaputt gemacht hat.

## Einen eigenen Test schreiben

1. Neue Datei `tests/test_meinding.gd`:

   ```gdscript
   extends RefCounted

   func run(t) -> void:
       print("Mein Ding:")
       t.check(1 + 1 == 2, "Mathe funktioniert noch")
   ```

2. In `tests/run_tests.gd` in die `modules`-Liste eintragen:

   ```gdscript
   preload("res://tests/test_meinding.gd").new(),
   ```

3. Ausführen – fertig.

`t.check(bedingung, beschreibung)` ist bestanden, wenn die Bedingung `true` ist.

> Tipp: Tests sind selbst eine gute Übung. Schau dir `test_game_manager.gd` an –
> es testet eine frische Instanz, damit sich Tests nicht gegenseitig stören.
