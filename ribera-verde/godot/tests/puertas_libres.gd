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

# 2 · el rótulo pintado en la propia fachada, tampoco (lo dijo el usuario: «pues el letrero es importante»): el sprite de la puerta
# cubre las 32 últimas filas del edificio en 32 px de ancho, y lo que repinta (el dintel subido por puertas_altas.py) se comía la
# mitad baja del CLUB. Aquí, por cada fachada con rótulo, su caja (en px de la base) no toca ese rectángulo y, pegando la puerta
# cerrada encima, no cambia ni un píxel del rótulo. Si se mueve un rótulo en tools/sprites/a-mano/locales.py, cámbiala aquí.
const ROTULOS := {
	"club-itsaso": [24, 50, 19, 9],      # la placa de latón, encima de la puerta
	"club-fundicion": [55, 49, 19, 9],   # la placa crema con su aplique
	"club-kalea": [41, 54, 19, 9],       # la placa en el estuco, sobre el portal
	"asociacion": [7, 81, 44, 10],       # ASOCIACIÓN, a la izquierda de su portal
	"club-ensanche": [25, 72, 15, 5],    # CLUB, en el toldo
	"disco": [8, 71, 45, 7],             # GAUA en neón, con su luna
}

func _rotulos() -> void:
	for mid in J.MAPS.keys():
		var m: Dictionary = J.MAPS[mid]
		for b in m.get("blds", []):
			var k: String = String(b.get("puerta", b.id))
			if b.get("doorX") == null or not ROTULOS.has(k):
				continue
			var fa = Atlas.frame_de("edificio-" + String(b.get("fachada", b.id)), "base", "unica", 0, {"i": 0})
			var pu = Atlas.frame_de("edificio-" + k, "puerta", "unica", 0, {"i": 0})
			if fa == null or pu == null:
				continue
			var c: Image = fa.c
			var q: Image = pu.c
			var px: int = int(b.doorX - b.x0) * 16 - 8 + int(b.get("dx", 0))
			var py: int = c.get_height() - 32
			var ro: Array = ROTULOS[k]
			var rr := Rect2i(int(ro[0]), int(ro[1]), int(ro[2]), int(ro[3]))
			chk(not rr.intersects(Rect2i(px, py, q.get_width(), q.get_height())),
				"%s: el rótulo %s cae en el rectángulo de la puerta (%d, %d)" % [k, rr, px, py])
			var tapa := 0
			var pinta := 0
			for y in range(rr.position.y, rr.end.y):
				for x in range(rr.position.x, rr.end.x):
					if x < 0 or y < 0 or x >= c.get_width() or y >= c.get_height():
						continue
					if c.get_pixel(x, y).a8 > 32:
						pinta += 1
					var sx: int = x - px
					var sy: int = y - py
					if sx >= 0 and sy >= 0 and sx < q.get_width() and sy < q.get_height() and q.get_pixel(sx, sy).a8 > 32:
						tapa += 1
			chk(pinta > rr.size.x * rr.size.y / 2, "%s: el rótulo no está donde dice ROTULOS (%d px pintados)" % [k, pinta])
			chk(tapa == 0, "%s: su puerta tapa %d px del rótulo" % [k, tapa])
			break   # una vez por fachada: el sprite es el mismo en todos los mapas

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
	_rotulos()
	for f in fallos:
		print("FALLO  ", f)
	print("puertas_libres: %d comprobaciones, %d fallos (%d estorbos en %d mapas)" % [n, fallos.size(), estorbos, mapas])
	quit(1 if fallos.size() else 0)
