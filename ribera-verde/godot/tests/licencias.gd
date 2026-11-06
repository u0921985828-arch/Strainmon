# Landrace Hunters (Godot) — CRÉDITOS → LICENCIAS: que estén todas las de los terceros que viajan en el juego.
# La Apache 2.0 de las bibliotecas de Android obliga a incluir su aviso de copyright, y las OFL de las fuentes,
# su texto entero.
#   $GODOT --headless --path godot --script res://tests/licencias.gd   → «licencias: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var n := 0
var fallos: Array = []

func chk(ok: bool, que: String) -> void:
	n += 1
	if not ok:
		fallos.append(que)
		print("  FALLO ", que)

func _initialize() -> void:
	Datos.PLAY = true
	Datos.CAL = true
	_corre.call_deferred()

func _corre() -> void:
	Datos.carga()
	var J = Juego.new()
	J.oraculo = true
	root.add_child(J)
	await process_frame
	var t: String = J.licencias()
	# 1 · los archivos que se exportan
	for f in ["fuentes/OFL-PressStart2P.txt", "fuentes/OFL-AtkinsonHyperlegible.txt", "fuentes/LICENCIA-DejaVu.txt",
			"licencias/APACHE-2.0.txt", "licencias/AVISOS-ANDROID.txt"]:
		chk(FileAccess.file_exists("res://" + f), "existe " + f)
	var pre := FileAccess.get_file_as_string("res://export_presets.cfg")
	chk(pre.find("licencias/*.txt") >= 0, "las licencias van en el include_filter del export")
	# 2 · lo que sale en la pantalla
	for k in ["Godot Engine", "Press Start 2P", "Braille Institute", "Bitstream",
			"Play Billing", "Play Games", "AndroidX", "Sentry", "Apache License"]:
		chk(t.find(k) >= 0, "LICENCIAS dice «%s»" % k)
	chk(t.find("Permission is hereby granted") >= 0, "el texto de la MIT de Sentry")
	chk(t.find("Licensed under the Apache License") >= 0 or t.find("APPENDIX: How to apply") >= 0, "el texto entero de la Apache 2.0")
	chk(t.length() > 20000, "la pantalla trae los textos enteros (%d letras)" % t.length())
	# 3 · los créditos: solo WOLFCADE y los beta testers (lo pidió el usuario)
	var c: String = J.CREDITOS
	for k in ["WOLFCADE", "BETA TESTERS", "Kerman, Ibai, Adrián, Urko, Josu, Ander, Bitxone y Edorta"]:
		chk(c.find(k) >= 0, "CRÉDITOS nombra «%s»" % k)
	for k in ["Godot", "el generador de sprites", "Press Start 2P", "Atkinson", "DejaVu"]:
		chk(c.find(k) < 0, "CRÉDITOS no nombra a terceros: «%s» (va en LICENCIAS)" % k)
	chk(c.find("LICENCIAS") >= 0, "CRÉDITOS remite a CRÉDITOS · LICENCIAS")
	print("licencias: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() > 0 else 0)
