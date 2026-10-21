# Landrace Hunters (Godot) — la red de carreteras que se andan (lo pidió el usuario: «hay mapas que conectan ciertos pueblos, eso
# se tiene que ver reflejado en el mapa» y «no hay más caminos entre los demás pueblos? Habría que crearlos»; la red completa), con
# Datos.CAL: las siete carreteras de CARRETERAS (tools/carreteras.py) y la comarcal. Cada pueblo abre en su borde la salida a cada
# carretera cuando los dos pueblos tienen autobús; se va andando de un pueblo a otro por la carretera y se vuelve; cerrada o sin
# CAL, el borde como estaba.
#   $GODOT --headless --path godot --script res://tests/carreteras.gd   → «carreteras: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# se llega andando (sin pasar por lo sólido) de a a b en el mapa
func llega(m: Dictionary, a: Vector2i, b: Vector2i) -> bool:
	var vis := {a: true}
	var cola := [a]
	while cola.size():
		var p: Vector2i = cola.pop_back()
		if p == b:
			return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if vis.has(q) or J.tile_solid(m, q.x, q.y):
				continue
			vis[q] = true
			cola.append(q)
	return false

# de pie en la salida (x, y) y empujando hacia su lado: ¿a dónde se llega?
func anda(mapa: String, x: int, y: int, lado: String) -> String:
	J.enter_map(mapa, x, y, lado)
	J.mode = "world"
	var t0: float = M.reloj
	J.try_move(lado)
	while J.S.map == mapa or not J.is_free() or J.fade_tw_vivo():
		if M.reloj - t0 > 8000 or not M.paso():
			break
	return "%s|%d,%d" % [J.S.map, J.P.x, J.P.y]

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-carreteras.json"
	Juego.AJUSTES = "user://prueba-carreteras-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.oraculo = true
	J.gancho_menu = func(_i, o): return o
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D: Dictionary = J.D
	var S: Dictionary = J.S
	var C: Dictionary = D.CARRETERAS
	var ORIG: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://datos/datos.json")).MAPS   # los mapas sin tocar
	# 0 · cerradas (lo primero: el muelle del capítulo 8 abre para siempre su paso, que comparte casillas con la costera): antes de que haya autobús a los dos, ni salida ni borde abierto (el de siempre)
	S.ch = 0
	for p in C.puertas:
		J.enter_map(p, int(D.PARADAS[p].a[0]), int(D.PARADAS[p].a[1]), "down")
		var m: Dictionary = J.MAPS[p]
		for q in C.puertas[p]:
			var k := "%d,%d" % [int(q[0]), int(q[1])]
			if int(C.rutas[q[2]].ch) > 0:
				chk(not m.exits.has(k) or m.exits[k].to != q[2], "%s (%s): cerrada en el capítulo 0" % [p, k])
				chk(m.g[int(q[1])][int(q[0])] == ORIG[p].g[int(q[1])][int(q[0])] and m.o[int(q[1])][int(q[0])] == ORIG[p].o[int(q[1])][int(q[0])], "%s (%s): el borde de siempre" % [p, k])
	chk(C.rutas.values().any(func(R): return int(R.ch) == 0), "alguna, desde el principio (Ribera Verde y Mendialde)")
	S.ch = 9
	# 1 · siete carreteras, cada una un mapa de verdad entre dos pueblos, con salida por los dos extremos a esos pueblos
	chk(C.rutas.size() == 7, "siete carreteras (%d)" % C.rutas.size())
	var pares := {}
	for id in C.rutas:
		var R: Dictionary = C.rutas[id]
		var m: Dictionary = J.MAPS[id]
		var a := []
		for k in m.exits:
			a.append(String(m.exits[k].to))
		chk(a.has(R.a) and a.has(R.b) and a.size() == 4, "%s: sale a %s y a %s (%s)" % [id, R.a, R.b, a])
		pares[[R.a, R.b].duplicate()] = true
		chk(int(R.ch) == max(int(D.PARADAS[R.a].cap), int(D.PARADAS[R.b].cap)), "%s: se abre con los dos autobuses (cap. %d)" % [id, int(R.ch)])
		J.enter_map(id, 1, 6, "right")
		chk(llega(m, Vector2i(1, 6), Vector2i(int(m.w) - 2, 7)), "%s: se anda de punta a punta" % id)
		var filas := {}   # lo pidió el usuario: «molaría que los caminos no siempre sean rectos» y, después, «más tramos rectos»
		var curvas := 0
		var tramos := []   # [curva?, columnas seguidas]
		for x in int(m.w):
			var top := -1
			var es_cv := false
			for y in int(m.h):
				var t: String = m.g[y][x]
				if t.begins_with("cv"):
					curvas += 1
					es_cv = true
					chk(not J.tile_solid(m, x, y), "%s (%d, %d): la curva se pisa" % [id, x, y])
				elif top < 0 and t in ["roadT", "rotoT", "pista"]:
					top = y
			if top >= 0:
				filas[top] = true
			if tramos.is_empty() or tramos[-1][0] != es_cv:
				tramos.append([es_cv, 0])
			tramos[-1][1] += 1
		chk(id == "carr-general" or filas.size() >= 2, "%s: no es recta (filas %s)" % [id, filas.keys()])
		chk(curvas > 0 or id == "carr-general", "%s: la calzada en curva por piezas, también la pista (%d)" % [id, curvas])
		var rectos: Array = tramos.filter(func(q): return not q[0]).map(func(q): return q[1])
		chk(tramos.all(func(q): return not q[0] or q[1] % 4 == 0), "%s: cada curva, de 4 casillas de largo (%s)" % [id, tramos])
		chk(rectos.max() >= 8 and rectos.min() >= 3, "%s: tramos rectos largos (%s)" % [id, rectos])
		var sueltas := 0   # las vallas, seguidas; nada del campo pegado a la calzada (solo farolas y bancos, a propósito)
		for y in int(m.h):
			for x in int(m.w):
				var ob = m.o[y][x]
				if ob == "fence" and not (x > 0 and m.o[y][x - 1] == "fence") and not (x < int(m.w) - 1 and m.o[y][x + 1] == "fence"):
					sueltas += 1
				if ob != null and not String(ob).begins_with("monte") and not ob in ["lamp", "bench"]:
					for dy in [-2, -1, 1, 2]:
						if y + dy >= 0 and y + dy < int(m.h) and String(m.g[y + dy][x]).substr(0, 2) in ["ro", "pi", "cv"]:
							sueltas += 1
		chk(sueltas == 0, "%s: sin vallas sueltas ni estorbos pegados a la calzada (%d)" % [id, sueltas])
	# la S de las curvas: de 0 a 16 sin saltos de más de 1 px y con los escalones limpios (de largos a cortos y de cortos a largos)
	var P = preload("res://src/pinta.gd")
	var tab: PackedInt32Array = P._cv_tabla()
	var esc := []
	for i in tab.size():
		if i == 0 or tab[i] != tab[i - 1]:
			esc.append(0)
		esc[-1] += 1
	chk(tab.size() == 64 and tab[0] == 0 and tab[63] == 16, "la curva baja una fila en 64 px (%d, %d, %d)" % [tab.size(), tab[0], tab[-1]])
	var limpia := esc.size() == 17
	for i in range(1, esc.size()):
		if i <= 8 and esc[i] > esc[i - 1] or i > 8 and esc[i] < esc[i - 1]:
			limpia = false
	chk(limpia, "escalones limpios: %s" % [esc])
	var pueblos := ["town", "puerto", "valdehierro", "mendialde", "errotabarri", "ibarbide"]
	var con := {}
	for p in pares.keys() + [[D.CAMPO.puertas.keys()[0], D.CAMPO.puertas.keys()[1]]]:
		con[p[0]] = con.get(p[0], 0) + 1
		con[p[1]] = con.get(p[1], 0) + 1
	chk(pueblos.all(func(p): return con.get(p, 0) >= 2), "cada pueblo con dos caminos o más, con la comarcal (%s)" % [con])
	# 2 · en cada pueblo, la salida abierta, que se pisa y se llega a ella desde la parada del autobús
	for p in C.puertas:
		S.ch = 0   # el capítulo justo en que se abren (antes del muelle, que abre el borde de Puerto Viejo por su cuenta)
		for q in C.puertas[p]:
			S.ch = maxi(S.ch, int(C.rutas[q[2]].ch))
		J.enter_map(p, int(D.PARADAS[p].a[0]), int(D.PARADAS[p].a[1]), "down")
		var m: Dictionary = J.MAPS[p]
		for q in C.puertas[p]:
			var k := "%d,%d" % [int(q[0]), int(q[1])]
			var ex = m.exits.get(k)
			chk(ex != null and ex.to == q[2] and ex.lado == q[5], "%s (%s): la salida a %s" % [p, k, q[2]])
			chk(not J.tile_solid(m, int(q[0]), int(q[1])), "%s (%s): se pisa" % [p, k])
			chk(llega(m, Vector2i(int(D.PARADAS[p].a[0]), int(D.PARADAS[p].a[1])), Vector2i(int(q[0]), int(q[1]))), "%s (%s): se llega desde la parada" % [p, k])
	# 3 · andando: del pueblo a la carretera, de punta a punta y al otro pueblo; y la vuelta, a la misma salida
	for id in C.rutas:
		var R: Dictionary = C.rutas[id]
		for lado in [R.a, R.b]:
			var q: Array = []
			for x in C.puertas[lado]:
				if x[2] == id:
					q = x
					break
			var r1 := anda(lado, int(q[0]), int(q[1]), String(q[5]))
			chk(r1.begins_with(id + "|"), "%s → %s (%s)" % [lado, id, r1])
			var otro: String = R.b if lado == R.a else R.a
			var fin := int(J.MAPS[id].w) - 1 if otro == R.b else 0
			var r2 := anda(id, fin, 6, "right" if fin > 0 else "left")
			chk(r2.begins_with(otro + "|"), "%s → %s (%s)" % [id, otro, r2])
			var px: int = J.P.x
			var py: int = J.P.y
			chk(not J.tile_solid(J.MAPS[otro], px, py), "%s: se llega a una casilla libre (%d, %d)" % [otro, px, py])
	# 5 · sin CAL, ninguna
	S.ch = 9
	Datos.CAL = false
	var nada := 0
	for p in C.puertas:
		J.enter_map(p, int(D.PARADAS[p].a[0]), int(D.PARADAS[p].a[1]), "down")
		for q in C.puertas[p]:
			var k := "%d,%d" % [int(q[0]), int(q[1])]
			if J.MAPS[p].exits.has(k) and String(J.MAPS[p].exits[k].to).begins_with("carr-"):
				nada += 1
	chk(nada == 0, "sin CAL, sin carreteras (%d)" % nada)
	Datos.CAL = true
	for f in fallos:
		print("FALLO  ", f)
	print("carreteras: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
