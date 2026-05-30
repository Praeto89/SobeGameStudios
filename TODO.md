# TODO – offene Aufgaben (im Editor / von Hand zu erledigen)

Diese Punkte konnten **nicht automatisch** erledigt werden, weil sie den
laufenden Godot-Editor, ein Bildbearbeitungsprogramm oder einen Menschen am
echten Bildschirm brauchen. Sie sind so beschrieben, dass man sie ohne
Vorwissen abarbeiten kann.

> Erledigt? Häkchen setzen (`[x]`) und beim nächsten Commit mit hochladen.

---

## 1. Screenshots für die Anleitung einfügen ⭐ (wichtigster Punkt)

Die Doku verweist an mehreren Stellen auf Screenshots, die noch fehlen. In den
Dateien stehen dafür unsichtbare Platzhalter als Kommentar, z. B.:

```
<!-- 📷 docs/img/03_play_buttons.png – F5/F6-Buttons oben rechts markiert -->
```

**Warum von Hand?** Editor-Screenshots lassen sich nur am laufenden Godot
aufnehmen – das geht nicht automatisiert.

**Vorbereitung (einmalig):**
- Godot-Editor möglichst auf **Deutsch** stellen
  (*Editor → Editor-Einstellungen → Interface/Sprache*), damit Beschriftungen
  zur Doku passen.
- Ein Programm zum Markieren bereithalten (roter Rahmen/Pfeil reicht).

**Pro Screenshot:**
1. Im Editor die beschriebene Situation herstellen.
2. Screenshot machen, die wichtige Stelle **rot markieren**.
3. Als **PNG**, ca. **1000–1400 px** breit, mit dem **exakten Dateinamen**
   (siehe Liste) unter `docs/img/` speichern.
4. In der Doku den passenden `<!-- 📷 … -->`-Kommentar ersetzen durch:
   `![Beschreibung](docs/img/DATEINAME.png)`

**Diese 7 Bilder fehlen** (Details in [`docs/img/README.md`](docs/img/README.md)):

- [ ] `01_import.png` – Import-Dialog mit ausgewählter `project.godot` → *QUICKSTART Schritt 1*
- [ ] `02_filesystem_sandbox.png` – FileSystem-Dock, Pfad `scenes/levels/sandbox.tscn` markiert → *QUICKSTART Schritt 2*
- [ ] `03_play_buttons.png` – F5/F6-Play-Buttons oben rechts markiert → *QUICKSTART Schritt 3*
- [ ] `04_drag_coin.png` – `coin.tscn` wird ins 2D-Viewport gezogen → *QUICKSTART Schritt 4*
- [ ] `05_inspector_export.png` – Plattform angeklickt, Inspector mit `speed`/`distance` markiert → *QUICKSTART Schritt 5*
- [ ] `06_layout_overview.png` – ganzes Fenster mit beschrifteten Bereichen → *ORIENTIERUNG.md*
- [ ] `07_git_panel.png` – „Version Control"-Panel unten, Commit-Feld markiert → *CONTRIBUTING.md*

---

## 2. Im Editor prüfen, ob alles sauber lädt

Diese Sachen wurden in Textdateien (`.tscn`/`.gd`) geändert und sollten im
echten Editor einmal gegengeprüft werden:

- [ ] **Sandbox-Schild** kontrollieren: `scenes/levels/sandbox.tscn` öffnen,
      mit **F6** starten. Oben sollte jetzt eine Zeile
      „Steuerung: Pfeiltasten = Laufen | Leertaste = Springen | F1 = Hilfe"
      stehen, gut lesbar und nicht abgeschnitten. Falls der Text zu breit ist:
      den `Anleitung`-Label anklicken und `offset_right` etwas vergrößern.
- [ ] **Projekt einmal komplett importieren** (frisch geklont) und schauen, ob
      das Output-Panel **keine roten** Fehler zeigt.

---

## 3. Tests lokal einmal ausführen

Die Logik-Tests wurden geschrieben, konnten aber in der Entwicklungsumgebung
**nicht ausgeführt** werden (dort war kein Godot installiert). Bitte einmal
lokal bestätigen:

- [ ] Im Projektordner ausführen:
      `godot --headless --path . --script res://tests/run_tests.gd`
- [ ] Erwartet: am Ende `… bestanden, 0 fehlgeschlagen` und „Alles gruen."
- [ ] Falls ein Test rot ist: Meldung lesen, Ursache prüfen
      (Details in [`tests/README.md`](tests/README.md)).

> In der GitHub-CI laufen die Tests automatisch mit. Der **erste grüne CI-Lauf**
> auf `main` ist der eigentliche Beweis – einmal nachschauen schadet nicht.

---

## 4. Aufgabe A4 absichern (Heil-Methode)

[`AUFGABEN.md`](AUFGABEN.md) → A4 („Heil-Pickup") ruft `body.heal(1)` auf.

- [ ] In `scripts/player/player.gd` prüfen, ob es eine `heal(...)`-Methode gibt.
- [ ] Falls **nicht**: eine einfache Methode ergänzen, die die Leben um den Wert
      erhöht (max. `MAX_HEALTH`) und das `health_changed`-Signal sendet –
      analog zu `take_damage(...)`. So ist A4 für Schüler:innen wirklich lösbar.

---

## 5. Label „idee" anlegen (1 Klick)

Die Kategorie-Labels `asset`, `level`, `aufgabe` existieren bereits (an den
Issues #1–#4 vergeben). Das Label **`idee`** entsteht erst, wenn es zum ersten
Mal verwendet wird.

- [ ] Sobald das erste Ideen-Issue (Template „💡 Idee vorschlagen") angelegt
      wird, entsteht `idee` automatisch.
- [ ] Optional sofort anlegen: *Repo → Issues → Labels → New label* →
      Name `idee`.

---

## 6. Nice-to-have (später, optional)

- [ ] **Kurzes Demo-GIF** des Gameplays in die README oben einbetten
      (z. B. mit einem Bildschirmrekorder aufnehmen, ~5 s, als `docs/img/demo.gif`).
- [ ] **Mehr Starter-Issues** anlegen, wenn die ersten erledigt sind
      (Vorlagen unter `.github/ISSUE_TEMPLATE/`).
- [ ] **Englische Kurzfassung** der wichtigsten Begriffe ist im
      [`GLOSSAR.md`](GLOSSAR.md) – bei Bedarf später eine komplette
      EN-Übersetzung von QUICKSTART/README ergänzen.
- [ ] **Weitere Mini-Aufgaben** in `AUFGABEN.md` sammeln (Schüler-Vorschläge
      über das „Aufgabe"-Issue-Template).

---

_Diese Liste lebt – ergänze gern eigene Punkte. Erledigtes abhaken statt
löschen, dann sieht man den Fortschritt._
