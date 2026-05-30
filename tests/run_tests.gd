# =============================================================================
# run_tests.gd
# =============================================================================
# Winziges, selbstgebautes Test-Programm (kein externes Addon noetig).
#
# So startest du es (Godot muss installiert sein):
#   godot --headless --path . --script res://tests/run_tests.gd
#
# Genau so laeuft es auch automatisch in der CI bei jedem Push/Pull Request.
#
# WARUM ueberhaupt Tests?
#   Tests sind kleine Pruefungen, die per Knopfdruck sagen "funktioniert noch"
#   oder "kaputt". So merkst du sofort, wenn eine Aenderung etwas anderes
#   zerschossen hat -- ohne jedes Mal das ganze Spiel von Hand durchzuspielen.
#
# Dieses Skript erweitert SceneTree und ist damit ein eigenstaendiges
# Mini-Programm: _initialize() laeuft einmal, dann beenden wir mit quit().
# Der Exit-Code (0 = alles gruen, 1 = mind. ein Fehler) sagt der CI Bescheid.
# =============================================================================

extends SceneTree

func _initialize() -> void:
	print("=== SobeGameStudios Tests ===\n")

	var t := Harness.new()

	# Jede Test-Datei ist eine kleine Klasse mit einer run(t)-Methode.
	# Neue Tests? Datei nach tests/ legen und hier in die Liste eintragen.
	var modules := [
		preload("res://tests/test_game_manager.gd").new(),
		preload("res://tests/test_player_constants.gd").new(),
	]

	for m in modules:
		m.run(t)

	t.report()
	# Exit-Code an die CI: 0 = bestanden, 1 = es gab Fehler.
	quit(1 if t.failed > 0 else 0)

# -----------------------------------------------------------------------------
# Harness – das kleine "Werkzeug", das jede Pruefung zaehlt und huebsch ausgibt.
# -----------------------------------------------------------------------------
class Harness:
	var passed := 0
	var failed := 0

	# check(bedingung, beschreibung): bestanden, wenn bedingung == true.
	func check(ok: bool, label: String) -> void:
		if ok:
			passed += 1
			print("  [OK]   " + label)
		else:
			failed += 1
			print("  [FAIL] " + label)

	func report() -> void:
		print("\n-----------------------------------------------")
		print("Ergebnis: %d bestanden, %d fehlgeschlagen" % [passed, failed])
		if failed == 0:
			print("Alles gruen. ✅")
		else:
			print("Es gibt Fehler. ❌  (siehe [FAIL] oben)")
