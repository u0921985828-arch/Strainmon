# Landrace Hunters (Godot) — ningún árbol encima de un edificio (lo preguntó el usuario: «los árboles no pueden estar encima de los
# edificios, ¿no?»), con Datos.CAL: en todos los mapas con edificios, ningún píxel de un árbol, manzano o mata del monte se pinta
# encima de un edificio. Los de detrás o al lado (el pie por encima de la última fila del edificio) van en m.tras (se pintan antes que
# los edificios); los de delante cuya copa taparía la fachada no están. Sin CAL, los mapas como estaban.
#   $GODOT --headless --path godot --script res://tests/arboles_edificios.gd   → «arboles_edificios: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")
const Pintor = preload("res://src/pinta.gd")

const ALTOS := ["tree", "tree2", "manzano", "monte", "monte2"]

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# los píxeles del edificio (en el mapa, en px) → [su id, la fila de debajo de su última fila]
func edificios(m: Dictionary) -> Dictionary:
	var r := {}
	for b in m.get("blds", []):
		var f = Atlas.frame_de("edificio-" + String(b.get("fachada", b.id)), "base", "unica", 0, {"i": 0})
		if f == null:
			continue
		var im: Image = f.c
		for y in im.get_height():
			for x in im.get_width():
				if im.get_pixel(x, y).a > 0:
					r[Vector2i(int(b.x0) * 16 + x, int(b.y0) * 16 + y)] = [String(b.id), int(b.y0) + int(b.h)]
	return r

# los edificios que pisa el objeto alto de (tx, ty), como se pinta (pinta.gd: desfase, espejo y ancla)
func pisa(m: Dictionary, bp: Dictionary, tx: int, ty: int) -> Array:
	var o: String = m.o[ty][tx]
	var d: Dictionary = Pintor.desfase(o, tx, ty)
	var f = Atlas.frame_de(Atlas.cubre("obj:" + o), o, "unica", 0, {"i": 0, "esp": d.esp})
	var r := []
	if f == null:
		return r
	var im: Image = f.c
	var x0: int = tx * 16 + 8 + int(d.dx) - int(f.cel.ancla[0])
	var y0: int = ty * 16 + 15 + int(d.dy) - int(f.cel.ancla[1])
	for y in im.get_height():
		for x in im.get_width():
			if im.get_pixel(x, y).a > 0:
				var q = bp.get(Vector2i(x0 + x, y0 + y))
				if q != null and not r.has(q):
					r.append(q)
	return r

func cuenta_altos(m: Dictionary) -> int:
	var c := 0
	for fila in m.o:
		for o in fila:
			if o in ALTOS:
				c += 1
	return c

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-arboles.json"
	Juego.AJUSTES = "user://prueba-arboles-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.oraculo = true
	J.S.ch = 9
	var antes := 0   # con CAL, cuántos árboles había encima de un edificio con los mapas sin tocar (datos.json)
	var D0: Dictionary = J.D.MAPS
	for mid in D0:
		var bp := edificios(D0[mid])
		if bp.is_empty():
			continue
		for ty in int(D0[mid].h):
			for tx in int(D0[mid].w):
				if D0[mid].o[ty][tx] in ALTOS and pisa(D0[mid], bp, tx, ty).size():
					antes += 1
	chk(antes >= 100, "con los mapas de datos.json, los árboles encima de un edificio que había: %d" % antes)
	var mapas := 0
	var detras := 0
	var quitados := 0
	for mid in J.MAPS.keys():
		var m: Dictionary = J.MAPS[mid]
		if m.get("blds", []).is_empty() or mid.begins_with("carr-"):
			continue
		J.enter_map(mid, 1, 1)
		m = J.MAPS[mid]
		var bp := edificios(m)
		if bp.is_empty():
			continue
		mapas += 1
		var tras: Dictionary = m.get("tras", {})
		var mal := []
		for ty in int(m.h):
			for tx in int(m.w):
				if not (m.o[ty][tx] in ALTOS):
					continue
				var q := pisa(m, bp, tx, ty)
				if q.is_empty():
					continue
				var delante: bool = q.any(func(b): return ty >= int(b[1]))
				if delante or not tras.has("%d,%d" % [tx, ty]):
					mal.append("%s %d,%d %s" % [m.o[ty][tx], tx, ty, q])
				else:
					detras += 1
		chk(mal.is_empty(), "%s: árboles encima de un edificio: %s" % [mid, mal.slice(0, 6)])
		quitados += J._arb0.get(mid, []).size()
	chk(mapas >= 12, "mapas con edificios revisados: %d" % mapas)
	chk(detras >= 50, "los de detrás, que se pintan antes que los edificios: %d" % detras)
	chk(quitados > 0 and quitados <= 60, "los de delante que tapaban la fachada, quitados: %d" % quitados)
	# los que siguen: el árbol de la esquina de Astilleros (delante de la nave de ladrillo) ya no está; la mata del borde del Ensanche,
	# detrás del bloque del club, sí, y detrás (con los mapas de Bilbao, la de (4, 1) queda bajo la casa del Ensanche: la de (11, 1))
	J.enter_map("astilleros", 1, 1)
	chk(J.MAPS.astilleros.o[10][2] == null, "Astilleros (2, 10): el árbol delante de la fachada, quitado (%s)" % J.MAPS.astilleros.o[10][2])
	J.enter_map("ensanche", 1, 1)
	chk(J.MAPS.ensanche.o[1][11] in ALTOS and J.MAPS.ensanche.get("tras", {}).has("11,1"), "Ensanche (11, 1): la mata de detrás del bloque, detrás")
	# sin CAL: como estaban
	Datos.CAL = false
	for mid in ["astilleros", "ensanche", "ibarbide", "mendialde"]:
		J.enter_map(mid, 1, 1)
		chk(cuenta_altos(J.MAPS[mid]) == cuenta_altos(D0[mid]) and not J.MAPS[mid].has("tras"), "sin CAL, %s como en datos.json" % mid)
	Datos.CAL = true
	print("arboles_edificios: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
