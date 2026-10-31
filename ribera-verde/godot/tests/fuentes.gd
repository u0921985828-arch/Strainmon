# Landrace Hunters (Godot) — MAESTRO [10]: las letras del juego, con todos sus glifos.
# Todo el texto del juego está en español y en inglés (i18n/strings.csv) y en los datos (datos/datos.json): acentos, ñ, ü, ¿, ¡, el
# euro, las flechas y los símbolos de los menús. Aquí se comprueba, carácter por carácter de esos textos de verdad, que cada letra
# del juego (o su reserva propia, DejaVu) lo sabe dibujar; si no, en el móvil saldría una caja o un hueco. Y que ninguno se pinta
# como la caja de «no tengo este glifo» (se compara con un carácter del área privada, que no existe en ninguna fuente).
#   godot --headless --script res://tests/fuentes.gd
extends SceneTree

const Ui = preload("res://src/ui.gd")

var n_ok := 0
var fallos := []

func ok(que: String, c: bool) -> void:
	if c:
		n_ok += 1
	else:
		fallos.append(que)

# los caracteres que el juego pinta de verdad: los textos y los datos, sin los de control
func chars_del_juego() -> Dictionary:
	var c := {}
	for f in ["res://i18n/strings.csv", "res://datos/datos.json"]:
		var t := FileAccess.get_file_as_string(f)
		for i in t.length():
			var u := t.unicode_at(i)
			if u >= 32 and u != 127:
				c[u] = true
	return c

# los símbolos de la interfaz, que no salen en los textos pero se dibujan igual (menús, barras, listas)
const UI_CHARS := "▲▼◀▶★≈−·—«»€¿¡ñÑáéíóúüÁÉÍÓÚÜ…✓"

func _initialize() -> void:
	var sim := FontFile.new()
	sim.data = FileAccess.get_file_as_bytes("res://fuentes/dejavu-sans-simbolos.woff2")
	var F := {
		"letra": Ui._fuente_de("atkinson-hyperlegible-latin-400-normal.woff2"),
		"negrita": Ui._fuente_de("atkinson-hyperlegible-latin-700-normal.woff2"),
		"display": Ui._fuente_de("press-start-2p-latin-400-normal.woff2", false),
	}
	# 1 · cada letra del juego trae su reserva propia (DejaVu) antes que la del móvil, que puede no estar
	for k in F:
		var fb: Array = F[k].fallbacks
		ok("%s: con reserva propia y del sistema" % k, fb.size() == 2 and fb[0] is FontFile and fb[1] is SystemFont)
		ok("%s: la reserva propia trae datos" % k, (fb[0] as FontFile).data.size() > 1000)
	# 2 · los caracteres de los textos y los datos del juego, en la letra o en su reserva
	var C := chars_del_juego()
	for i in UI_CHARS.length():
		C[UI_CHARS.unicode_at(i)] = true
	ok("hay caracteres que comprobar (%d)" % C.size(), C.size() > 80)
	for k in F:
		var falta := []
		for u2 in C:
			var u: int = u2
			if not F[k].has_char(u) and not sim.has_char(u):
				falta.append(char(u))
		ok("%s: ningún glifo sin dibujar (%d)" % [k, falta.size()], falta.is_empty())
		if not falta.is_empty():
			print("   %s, le faltan: %s" % [k, "".join(falta)])
	# 3 · lo que sí se dibuja no sale como la caja de «sin glifo» (U+E000, del área privada, no existe en ninguna fuente)
	var sin_glifo := 0xE000
	for k in F:
		var f: FontFile = F[k]
		var s := 16
		var caja := f.get_char_size(sin_glifo, s)
		var malos := []
		for t in ["ñ", "á", "¿", "¡", "ü", "€"]:
			var u: int = (t as String).unicode_at(0)
			if f.get_char_size(u, s) == caja and not f.has_char(u) and not sim.has_char(u):
				malos.append(t)
		ok("%s: ñ, acentos, ¿ ¡ y € no salen como caja" % k, malos.is_empty())
	# 4 · las letras van dentro del juego exportado: son recursos importados y el preset no las deja fuera
	var cfg := FileAccess.get_file_as_string("res://export_presets.cfg")
	var exc := (cfg.split("exclude_filter=\"")[1] as String).split("\"")[0] if cfg.contains("exclude_filter=\"") else ""
	var inc := (cfg.split("include_filter=\"")[1] as String).split("\"")[0] if cfg.contains("include_filter=\"") else ""
	ok("el preset no excluye las letras", not exc.contains("fuentes"))
	# MAESTRO [10]: las letras, nombradas en el preset aunque vayan ya como recurso importado (si un día se exporta por lista, siguen entrando)
	for e in ["woff2", "ttf", "otf"]:
		ok("el preset nombra fuentes/*.%s" % e, inc.contains("fuentes/*." + e))
	for f in ["atkinson-hyperlegible-latin-400-normal.woff2", "atkinson-hyperlegible-latin-700-normal.woff2",
			"press-start-2p-latin-400-normal.woff2", "dejavu-sans-simbolos.woff2"]:
		ok("%s, importada (va en el paquete)" % f, FileAccess.file_exists("res://fuentes/" + f + ".import"))
	for f in fallos:
		print("FALLO  ", f)
	print("fuentes: %d comprobaciones, %d fallos" % [n_ok + fallos.size(), fallos.size()])
	quit(1 if fallos.size() else 0)
