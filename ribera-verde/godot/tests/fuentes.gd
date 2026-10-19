# Landrace Hunters (Godot) — MAESTRO [10]: que las tres letras del juego (Atkinson normal y negrita, Press Start 2P) tengan
# todos los caracteres de los textos en castellano y en inglés (ñ, tildes, ¿¡, €, «», ·…) o, si no, una de reserva propia que
# los tenga, sin depender de la del sistema; y que los .woff2 y las licencias vayan en la exportación.
#   $GODOT --headless --path godot --script res://tests/fuentes.gd   → «fuentes: N comprobaciones, 0 fallos»
extends SceneTree

var n := 0
var fallos := []
const FIJOS := "ñÑáéíóúüÁÉÍÓÚÜ¿¡€«»·ºª°–—…“”‘’"

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _initialize() -> void:
	var cs := {}
	for ch in FIJOS:
		cs[ch] = true
	var f := FileAccess.open("res://i18n/strings.csv", FileAccess.READ)
	while f and not f.eof_reached():
		for ch in f.get_line():
			cs[ch] = true
	var dj := FileAccess.get_file_as_string("res://datos/datos.json")
	var dd = JSON.parse_string(dj)
	_junta(dd, cs)
	var ui = load("res://src/ui.gd")
	for nom in ["atkinson-hyperlegible-latin-400-normal.woff2", "atkinson-hyperlegible-latin-700-normal.woff2", "press-start-2p-latin-400-normal.woff2"]:
		chk(FileAccess.file_exists("res://fuentes/" + nom), "falta " + nom)
		var o: Font = ui._fuente_de(nom, false)
		var fbs: Array = o.fallbacks
		o.fallbacks = fbs.filter(func(x): return x is FontFile)   # la del sistema no cuenta: en el móvil no se sabe cuál es
		var falta := []
		for ch in cs:
			var c: int = ch.unicode_at(0)
			if c < 32 or c in [0xFEFF, 0x200B, 0x2028]:
				continue
			if not _tiene(o, c):
				falta.append(ch)
		chk(not o.has_char("Ж".unicode_at(0)), nom + ": has_char no distingue (la prueba no mide nada)")
		chk(falta.is_empty(), "%s sin %d glifos: %s" % [nom, falta.size(), "".join(PackedStringArray(falta.slice(0, 40)))])
	var ep := FileAccess.get_file_as_string("res://export_presets.cfg")
	chk(ep.find("fuentes/*") >= 0, "export sin fuentes/*")
	print("fuentes: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  FALLO ", x)
	quit(1 if fallos.size() else 0)

func _tiene(o: Font, c: int) -> bool:
	if o.has_char(c):
		return true
	for fb in o.fallbacks:
		if fb is FontFile and _tiene(fb, c):
			return true
	return false

func _junta(v, cs: Dictionary) -> void:
	if v is String:
		for ch in v:
			cs[ch] = true
	elif v is Array:
		for x in v:
			_junta(x, cs)
	elif v is Dictionary:
		for k in v:
			_junta(k, cs)
			_junta(v[k], cs)
