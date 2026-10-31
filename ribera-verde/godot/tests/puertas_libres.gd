# Landrace Hunters (Godot) — ni la puerta ni su rótulo, tapados (lo dijo el usuario: «el letrero de club… seguramente algún letrero
# o algo tapará las puertas de varios lugares»): en todos los mapas de calle, con los sprites de verdad (`cajas_obj` de calle.gd, lo
# que el pintor pondría), ningún objeto del mapa —farolas, carteles, señales, contenedores, bancos…— deja píxeles opacos sobre el
# hueco de una puerta que se entra ni sobre la franja de encima, donde va el rótulo del local (el CLUB, la T del estanco).
# Lo que sí puede estar delante: lo que el propio edificio trae (su puerta y su rótulo) y la gente, que se mueve.
#   $GODOT --headless --path godot --script res://tests/puertas_libres.gd -- --sin-arranque
#   -- --lista: cada estorbo, mapa por mapa
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

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

# el rectángulo que tiene que quedar libre: la puerta (16 px por casilla, 32 de alto) y los 32 px de encima, donde va el rótulo del
# local (el CLUB de los clubs, la T del estanco, el letrero de la panadería…)
func _hueco(b: Dictionary) -> Rect2i:
	var w: int = 32 if b.get("ancha") else 16
	var x: int = int(b.doorX) * 16 + int(b.get("dx", 0))
	var yb: int = (int(b.y0) + int(b.h)) * 16
	return Rect2i(x, yb - 64, w, 64)

# los píxeles opacos de un sprite dentro del rectángulo
func _pisa(e: Dictionary, r: Rect2i) -> int:
	var c: Image = e.c
	var x0: int = int(e.px)
	var y0: int = int(e.py)
	var q := Rect2i(x0, y0, c.get_width(), c.get_height()).intersection(r)
	if q.size.x <= 0 or q.size.y <= 0:
		return 0
	var k := 0
	for y in range(q.position.y, q.position.y + q.size.y):
		for x in range(q.position.x, q.position.x + q.size.x):
			if c.get_pixel(x - x0, y - y0).a8 > 32:
				k += 1
	return k

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-puertas-libres.json"
	Juego.AJUSTES = "user://prueba-puertas-libres-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.oraculo = true
	J.S.ch = 9
	var ns: Dictionary = J.new_state()
	for k in ns:
		if not J.S.has(k):
			J.S[k] = ns[k]
	await process_frame
	var lista: bool = "--lista" in OS.get_cmdline_user_args()
	var mapas := 0
	var estorbos := 0
	for mid in J.MAPS.keys():
		if not J.D.ZONAS.has(mid):   # solo la calle: dentro no hay fachadas
			continue
		J.enter_map(mid, 1, 1)
		var m: Dictionary = J.MAPS[mid]
		mapas += 1
		var cajas: Array = J.cajas_obj(mid, m.o)
		# las fachadas de los demás edificios, que se pintan en orden y pueden comerse el rótulo del vecino
		var fach := []
		for b in m.get("blds", []):
			var gr: String = "edificio-" + String(b.get("fachada", b.id))
			var f = Atlas.frame_de(gr, "base", "unica", 0, {"i": 0})
			if f != null:
				fach.append({"o": gr, "x": int(b.x0), "y": int(b.y0), "c": f.c, "px": int(b.x0) * 16, "py": int(b.y0) * 16, "b": b})
		for b in m.get("blds", []):
			if b.get("doorX") == null:
				continue   # los locales con gate llevan su doorX al montarlos (montar_locales)
			var r := _hueco(b)
			var malos := []
			for q in cajas:
				var k := _pisa(q, r)
				if k > 4:   # un par de píxeles de una esquina no tapan nada
					malos.append("%s en (%d, %d): %d px" % [q.o, int(q.x), int(q.y), k])
			for q in fach:   # otra fachada encima de esta puerta o de su rótulo
				if q.b == b or int(q.b.y0) < int(b.y0):   # la suya no; las de detrás se pintan antes
					continue
				var k := _pisa(q, r)
				if k > 4:
					malos.append("la fachada %s en (%d, %d): %d px" % [q.o, int(q.x), int(q.y), k])
			if lista and malos.size():
				print("%s · %s (puerta %d): %s" % [mid, b.id, int(b.doorX), malos])
			estorbos += malos.size()
			chk(malos.is_empty(), "%s · %s, puerta en %d: %s" % [mid, b.id, int(b.doorX), malos.slice(0, 3)])
	chk(mapas >= 8, "mapas de calle mirados: %d" % mapas)
	for f in fallos:
		print("FALLO  ", f)
	print("puertas_libres: %d comprobaciones, %d fallos (%d estorbos en %d mapas)" % [n, fallos.size(), estorbos, mapas])
	quit(1 if fallos.size() else 0)
