# Landrace Hunters (Godot) — la huerta ampliable (lo pidió el usuario: «Molaría que fuese ampliable en espacio la huerta, para poder
# plantar por lo menos el doble de plantas»), con Datos.CAL: la obra de la tienda online → La huerta (HUERTA_MEJ.amp), que llega al
# día siguiente; el seto baja por el monte de abajo, caben cuatro bancales más y el doble de sitios, los de siempre en su sitio y con
# lo plantado, cada sitio nuevo como los de siempre (2 × 2 en su bancal, simétricos, una baldosa libre), todo se alcanza a pie, la
# llegada y la salida abajo, el goteo llega a los nuevos y, sin CAL, la huerta de siempre.
#   $GODOT --headless --path godot --script res://tests/huerta_amp.gd   → «huerta_amp: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Pintor = preload("res://src/pinta.gd")

var J
var M
var MENUS := []
var ITEMS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	ITEMS.append(items)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
	o = o.duplicate()
	o.initial = k
	return o

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

# la fila de la tienda de la huerta que se vio la última, por su texto
func fila(lb: String) -> Dictionary:
	for k in range(ITEMS.size() - 1, -1, -1):
		for it in ITEMS[k]:
			if it is Dictionary and String(it.get("label", "")).begins_with(lb):
				return it
	return {}

# las casillas a las que se llega andando desde (x, y)
func a_pie(m: Dictionary, x: int, y: int) -> Dictionary:
	var vis := {Vector2i(x, y): true}
	var cola := [Vector2i(x, y)]
	while cola.size():
		var c: Vector2i = cola.pop_front()
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var v: Vector2i = c + dd
			if v.x < 0 or v.y < 0 or v.x >= int(m.w) or v.y >= int(m.h) or vis.has(v) or m.o[v.y][v.x] != null or J.tile_solid(m, v.x, v.y):
				continue
			vis[v] = true
			cola.append(v)
	return vis

func junto(vis: Dictionary, x: int, y: int) -> bool:
	for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if vis.has(Vector2i(x, y) + dd):
			return true
	return false

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-huerta-amp.json"
	Juego.AJUSTES = "user://prueba-huerta-amp-ajustes.json"
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
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = Datos.carga()
	var S: Dictionary = J.S
	S.mode = "world"
	J.mode = "world"
	var H: Dictionary = J.HUERTA
	var HM: Dictionary = J.HUERTA_MEJ
	S.banco = 5000.0
	S.day = Datos.dia_de(2026, 6, 1)
	S.min = 600
	S.huerta = {"v": 1, "l": 1, "p": []}
	var sid: String = String(D.BANCO[0][0])
	# 0 · sin la obra, la de siempre
	chk(J.huerta_def() == H and J.huerta_def().sitios.size() == 8, "sin obra, los 8 sitios de siempre")
	J.enter_map("town", 9, 3, "up")
	chk(int(J.MAPS.town.doors["9,1"].y) == int(H.llega[1]), "la cancilla lleva a la llegada de siempre: %s" % [J.MAPS.town.doors.get("9,1")])
	J.enter_map("huerta", int(H.llega[0]), int(H.llega[1]), "up")
	var m: Dictionary = J.MAPS.huerta
	chk(int(m.h) == int(H.h), "sin obra, %d filas" % int(m.h))
	# una planta en el sitio 0 y la tierra del 3 cavada, antes de la obra
	var p0: Dictionary = Cultivo.nueva_planta(S, sid)
	p0.prog = .5
	J.huerta_s().p[0] = p0
	J.huerta_s().t[3] = 1
	J.huerta_objs()
	# 1 · la tienda: la obra, con la huerta desbrozada
	QUIERO = ["La huerta"]
	ITEMS.clear()
	chk(corre(func(): await J.tienda_online()), "la tienda online → la huerta")
	var f := fila("Ampliar la huerta")
	chk(not f.is_empty() and f.get("disabled") == false, "la obra se puede pedir: %s" % [f])
	chk(String(f.get("desc", "")).contains("16 sitios"), "y dice cuántos caben: %s" % f.get("desc", ""))
	var b0: float = float(S.banco)
	QUIERO = ["La huerta", "Ampliar la huerta"]
	ITEMS.clear()
	chk(corre(func(): await J.tienda_online()), "pedir la obra")
	chk(is_equal_approx(b0 - float(S.banco), float(HM.amp.p)), "pagada con tarjeta: %s (quiero %s)" % [b0 - float(S.banco), HM.amp.p])
	chk(J.huerta_ped("amp") == 1, "pedida: %s" % [S.huerta.ped])
	chk(fila("Ampliar la huerta").get("disabled") == true, "una sola vez")
	chk(J.huerta_def().sitios.size() == 8 and int(J.MAPS.huerta.h) == int(H.h), "hoy, todavía la de siempre")
	# 2 · al día siguiente, ampliada
	S.day += 1
	J.llega_huerta()
	var A: Dictionary = J.huerta_def()
	chk(J.huerta_m("amp") == 1 and J.huerta_amp(), "llega la obra: %s" % [S.huerta.get("m")])
	chk(A.sitios.size() >= 2 * H.sitios.size(), "por lo menos el doble de sitios: %d" % A.sitios.size())
	chk(J.huerta_s().p.size() == A.sitios.size() and J.huerta_s().t.size() == A.sitios.size(), "las plantas y la tierra, por sitio: %d, %d" % [J.huerta_s().p.size(), J.huerta_s().t.size()])
	for i in H.sitios.size():
		chk(A.sitios[i] == H.sitios[i], "el sitio %d, donde estaba (%s)" % [i, A.sitios[i]])
	chk(J.huerta_s().p[0] == p0 and J.huerta_t(3) == 1, "lo plantado y lo cavado, igual")
	m = J.MAPS.huerta
	var y1: int = int(A.seto[3])
	chk(y1 == int(H.seto[3]) + int(HM.amp.dy) and int(m.h) == int(H.h) + int(HM.amp.dy), "el seto, %d casillas más abajo (%d) y el mapa, %d filas" % [HM.amp.dy, y1, int(m.h)])
	chk(str(m.o[y1][int(A.seto[0])]) == "setoL" and str(m.o[y1][int(A.seto[2])]) == "setoR", "las esquinas de abajo, en la fila %d" % y1)
	var viejo := 0
	for x in range(int(A.seto[0]) + 1, int(A.seto[2])):
		viejo += 1 if str(m.o[int(H.seto[3])][x]).begins_with("seto") else 0
	chk(viejo == 0, "el seto de antes, quitado (%d piezas)" % viejo)
	for x in range(int(A.seto[0]), int(A.seto[2]) + 1):
		chk(x in [int(A.camino), int(A.camino) + 1] or str(m.o[y1][x]).begins_with("seto"), "el seto de abajo, entero salvo el camino (%d: %s)" % [x, m.o[y1][x]])
	for y in range(int(A.seto[1]) + 1, y1):
		chk(str(m.o[y][int(A.seto[0])]).begins_with("setoV") and str(m.o[y][int(A.seto[2])]).begins_with("setoV"), "los lados, hasta abajo (fila %d)" % y)
	for x in [int(A.camino), int(A.camino) + 1]:
		chk(m.doors.has("%d,%d" % [x, y1]) and m.doors["%d,%d" % [x, y1]].to == "town", "la salida, abajo en %d" % x)
		chk(not m.doors.has("%d,%d" % [x, int(H.seto[3])]), "y no en la fila de antes")
	chk(m.g[int(A.llega[1])][int(A.llega[0])] == "dirt" and int(A.llega[1]) == y1 - 1, "la llegada, en el camino junto a la salida: %s" % [A.llega])
	chk(int(J.MAPS.town.doors["9,1"].y) == int(A.llega[1]), "la cancilla lleva a la llegada nueva: %s" % [J.MAPS.town.doors.get("9,1")])
	# 3 · los sitios nuevos, como los de siempre: 2 × 2 dentro de su bancal, dos por bancal, simétricos y con una baldosa libre
	var por_bancal := {}
	for i in A.sitios.size():
		var bl: Array = J.huerta_bloque(i)
		var dentro := -1
		for k in A.bancales.size():
			var b: Array = A.bancales[k]
			if bl.all(func(c): return int(c[0]) >= int(b[0]) and int(c[0]) <= int(b[2]) and int(c[1]) >= int(b[1]) and int(c[1]) <= int(b[3])):
				dentro = k
		chk(dentro >= 0, "sitio %d, dentro de un bancal (%s)" % [i, bl])
		if dentro >= 0:
			por_bancal[dentro] = por_bancal.get(dentro, []) + [i]
		for c in bl:
			chk(J.huerta_idx(int(c[0]), int(c[1])) == i, "la casilla %s es del sitio %d (%d)" % [c, i, J.huerta_idx(int(c[0]), int(c[1]))])
			chk(str(m.g[int(c[1])][int(c[0])]).begins_with("surco"), "sitio %d: tierra arada en %s (%s)" % [i, c, m.g[int(c[1])][int(c[0])]])
			chk(m.o[int(c[1])][int(c[0])] != null and J.tile_solid(m, int(c[0]), int(c[1])) or str(m.o[int(c[1])][int(c[0])]).begins_with("hg"), "sitio %d: no se pisa %s" % [i, c])
	for k in A.bancales.size():
		var b: Array = A.bancales[k]
		var ss: Array = por_bancal.get(k, [])
		chk(ss.size() == 2, "bancal %d: dos sitios (%s)" % [k, ss])
		if ss.size() == 2:
			var a: Array = A.sitios[ss[0]]
			var c: Array = A.sitios[ss[1]]
			var xa: int = mini(int(a[0]), int(c[0]))
			var xb: int = maxi(int(a[0]), int(c[0]))
			chk(xb - (xa + 2) == 1, "bancal %d: una baldosa libre entre las dos" % k)
			chk((xa + 1) * 16 + (xb + 1) * 16 == (int(b[0]) + int(b[2]) + 1) * 16, "bancal %d: simétricas" % k)
			chk(int(a[1]) * 16 == (int(b[1]) + int(b[3]) + 1) * 8, "bancal %d: el pie en la línea del medio" % k)
	var celdas := {}
	for b in A.bancales:   # ningún bancal encima de otro, ni del camino, ni del seto
		for y in range(int(b[1]), int(b[3]) + 1):
			for x in range(int(b[0]), int(b[2]) + 1):
				chk(not celdas.has(Vector2i(x, y)), "bancales solapados en %d,%d" % [x, y])
				celdas[Vector2i(x, y)] = true
				chk(x > int(A.seto[0]) and x < int(A.seto[2]) and y > int(A.seto[1]) and y < y1 and x != int(A.camino) and x != int(A.camino) + 1, "bancal dentro del seto y fuera del camino: %d,%d" % [x, y])
	# 4 · todo se alcanza a pie desde la llegada: los dieciséis sitios, el atrezo y las mejoras
	var vis := a_pie(m, int(A.llega[0]), int(A.llega[1]))
	for st in A.sitios:
		chk(junto(vis, int(st[0]), int(st[1])) or junto(vis, int(st[0]) + 1, int(st[1])) or junto(vis, int(st[0]), int(st[1]) - 1) or junto(vis, int(st[0]) + 1, int(st[1]) - 1), "se llega al sitio %s" % [st])
	for a in A.atrezo:
		chk(m.o[int(a[1])][int(a[0])] == a[2], "%s en su sitio %s" % [a[2], a])
		chk(junto(vis, int(a[0]), int(a[1])), "se llega a %s" % [a])
	# 5 · plantar en un sitio nuevo: el sitio 12, con su planta y en su casilla
	var s12: Array = A.sitios[12]
	J.huerta_s().p[12] = Cultivo.nueva_planta(S, sid)
	J.huerta_objs()
	chk(str(J.MAPS.huerta.o[int(s12[1])][int(s12[0])]).begins_with("hg-"), "la del sitio 12, dibujada en su casilla: %s" % J.MAPS.huerta.o[int(s12[1])][int(s12[0])])
	var hu: Dictionary = J.huerta_hu(12)
	chk(hu.v == [(int(s12[0]) + 1) * 16, int(s12[1]) * 16], "la vista del sitio 12, en el pie de su mata: %s" % [hu.v])
	var L0: int = J.huerta_s().p.filter(func(p): return p is Dictionary).size()
	J.huerta_avanza(60)
	chk(J.huerta_s().p.filter(func(p): return p is Dictionary).size() == L0, "crecen todas, también las nuevas")
	# 6 · el goteo llega a los dieciséis
	var tb: Dictionary = Pintor.tubos_huerta(A, HM, 0)
	chk(tb.g.size() == A.sitios.size(), "un gotero por sitio: %d" % tb.g.size())
	var filas := {}
	for st in A.sitios:
		filas[int(st[1]) * 16 - 1] = true
	chk(tb.h.filter(func(q): return filas.has(int(q[2]))).size() == filas.size(), "un ramal por fila de bancales (%d)" % filas.size())
	var baja: int = 0
	for q in tb.v:
		baja = maxi(baja, int(q[2]))
	chk(baja >= int(A.sitios[-1][1]) * 16 - 1, "la principal baja hasta la última fila (%d)" % baja)
	# 7 · guardar y cargar
	S.huerta = JSON.parse_string(JSON.stringify(S.huerta))
	J.enter_map("huerta", int(A.llega[0]), int(A.llega[1]), "up")
	chk(J.huerta_def().sitios.size() == A.sitios.size() and int(J.MAPS.huerta.h) == int(A.h), "tras cargar, ampliada")
	# 8 · sin CAL, la de siempre aunque esté la obra
	Datos.CAL = false
	chk(J.huerta_def() == H, "sin CAL, la de siempre")
	Datos.CAL = true
	print("huerta_amp: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for t in fallos:
		print("  FALLO: ", t)
	quit(1 if fallos.size() else 0)
