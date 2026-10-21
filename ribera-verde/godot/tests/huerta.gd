# Landrace Hunters (Godot) — la huerta abandonada de la tía (lo pidió el usuario: «encontrar la huerta abandonada de al lado de
# casa, en el pueblo, para poder cultivar ahí en exterior»), con Datos.CAL: la cancilla detrás del garaje (town 9, 1), el mapa
# «huerta», desbrozar, plantar en sus ocho sitios, la temporada al raso (vegetativo hasta el 5 de agosto y flor después; más
# gramos cuanto antes se planta), la lluvia que riega, la helada y la nieve, regar todas con el bidón, la planta seca y la cosecha.
# Sin CAL, el pueblo como estaba.
#   $GODOT --headless --path godot --script res://tests/huerta.gd   → «huerta: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Pintor = preload("res://src/pinta.gd")

var J
var M
var MENUS := []
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

func dicho(t: String) -> bool:
	for l in LOG:
		if String(l).contains(t):
			return true
	return false

# los gramos de sid encima y en la caja fuerte
func gramos_de(sid: String) -> float:
	var g := 0.0
	for L in [J.S.buds, J.S.caja.get("buds", {}) if J.S.get("caja") is Dictionary else {}]:
		for k in L.keys():
			if String(k).begins_with(sid):
				g += float(L[k].g)
	return g

func minutos() -> int:
	return int(J.S.day) * 1440 + int(J.S.min)

# un día en el que el tiempo de las 6 cumple f (de d0 en adelante, hasta un año)
func dia_que(d0: int, f: Callable) -> int:
	for d in range(d0, d0 + 366):
		if f.call(Datos.tiempo(d, 360)):
			return d
	return -1

# la temporada de la planta de la huerta i, a mano, de hora en hora hasta el día d1: sin otros sucesos del día; regada y sin plaga
func temporada(d1: int) -> void:
	var S: Dictionary = J.S
	while int(S.day) < d1:
		for h in 24:
			S.min = h * 60
			for p in J.huerta_s().p:
				if p is Dictionary:
					p.water = 100.0
					p.pest = false
					p.health = 100.0
			J.huerta_avanza(60)
		S.day += 1
		S.min = 0

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-huerta.json"
	Juego.AJUSTES = "user://prueba-huerta-ajustes.json"
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
	S.erase("huerta")
	var H: Dictionary = J.HUERTA
	var q: Array = H.puerta
	var D0: Dictionary = D.MAPS.town
	# 0 · sin CAL, el pueblo como estaba
	Datos.CAL = false
	J.enter_map("town", 9, 2, "up")
	chk(J.MAPS.town.o[q[1]][q[0]] == D0.o[q[1]][q[0]] and not J.MAPS.town.doors.has("%d,%d" % [q[0], q[1]]), "sin CAL: la mata del monte en (9, 1) y sin puerta")
	Datos.CAL = true
	# 1 · la pista en el cartel del portal y la cancilla
	J.enter_map("town", 9, 2, "up")
	chk(J.MAPS.town.o[q[1]][q[0]] in ["monte", "monte2"], "con CAL, sin encontrarla: la mata en (9, 1) (%s)" % J.MAPS.town.o[q[1]][q[0]])
	LOG.clear()
	chk(corre(func(): await J.object_action(1, 8)), "el cartel del portal")
	chk(dicho("La huerta de Maite"), "el cartel dice dónde está la huerta: %s" % [LOG])
	LOG.clear()
	QUIERO = ["Dejarlo"]
	chk(corre(func(): await J.object_action(q[0], q[1])), "la cancilla: dejarlo")
	chk(not J.huerta_vista() and J.MAPS.town.o[q[1]][q[0]] != null, "dejarlo: sigue sin abrir")
	QUIERO = ["Abrirte paso"]
	chk(corre(func(): await J.object_action(q[0] + 1, q[1])), "la cancilla: abrirte paso (desde la casilla de al lado)")
	chk(J.huerta_vista() and int(S.huerta.v) == int(S.day), "encontrada hoy (v = %s)" % S.huerta.get("v"))
	chk(J.MAPS.town.g[q[1]][q[0]] == "dirt" and J.MAPS.town.o[q[1]][q[0]] == null, "en (9, 1), tierra sin estorbo")
	var pu = J.MAPS.town.doors.get("%d,%d" % [q[0], q[1]])
	chk(pu != null and pu.to == "huerta" and int(pu.x) == int(H.llega[0]) and int(pu.y) == int(H.llega[1]), "la puerta a la huerta: %s" % [pu])
	for c in H.senda:
		chk(J.MAPS.town.g[c[1]][c[0]] == "dirt" and J.MAPS.town.o[c[1]][c[0]] == null, "la senda de tierra en %s" % [c])
	chk(dicho("la huerta de la tía"), "lo dice al abrirla")
	LOG.clear()
	chk(corre(func(): await J.object_action(1, 8)), "el cartel, otra vez")
	chk(not dicho("La huerta de Maite"), "encontrada, el cartel ya no lo dice")
	# 2 · la huerta abandonada
	var ll: Vector2i = Vector2i(int(H.llega[0]), int(H.llega[1]))
	J.enter_map("huerta", ll.x, ll.y, "up")
	var m: Dictionary = J.MAPS.huerta
	chk(int(m.w) == 30 and int(m.h) == 12 and m.g.size() == 12 and m.g[0].size() == 30, "el mapa de 30 × 12")
	var bordes := 0
	for y in 12:
		for x in 30:
			if (x < int(H.seto[0]) or x > int(H.seto[2]) or y <= int(H.seto[1])) and not (m.o[y][x] in ["monte", "monte2"]):
				bordes += 1
			if x >= int(H.seto[0]) and x <= int(H.seto[2]) and y > int(H.seto[3]) and m.o[y][x] != null:
				bordes += 1
	chk(bordes == 0, "alrededor de la huerta, el monte, y debajo del seto nada que tape la última fila (%d casillas mal)" % bordes)
	var zarzas := 0
	for b in H.bancales:
		for y in range(int(b[1]), int(b[3]) + 1):
			for x in range(int(b[0]), int(b[2]) + 1):
				zarzas += 1 if m.o[y][x] == "bush" else 0
				chk(m.g[y][x] == "tallgrass", "abandonada: hierba alta en (%d, %d)" % [x, y])
	chk(zarzas >= 16, "abandonada: zarzas en los bancales (%d)" % zarzas)
	var ys: int = int(H.seto[3])
	for x in [int(H.camino), int(H.camino) + 1]:
		var sd = m.doors.get("%d,%d" % [x, ys])
		chk(sd != null and sd.to == "town" and int(sd.x) == 9 and int(sd.y) == 2, "la salida de abajo (%d, %d) vuelve a la cancilla: %s" % [x, ys, sd])
	# todo lo que se usa, alcanzable a pie desde la entrada (como test-accesos)
	var vis := {ll: true}
	var cola := [ll]
	while cola.size():
		var c: Vector2i = cola.pop_front()
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var v: Vector2i = c + dd
			if v.x < 0 or v.y < 0 or v.x >= 30 or v.y >= 12 or vis.has(v) or m.o[v.y][v.x] != null or J.tile_solid(m, v.x, v.y):
				continue
			vis[v] = true
			cola.append(v)
	var junto := func(x: int, y: int) -> bool:
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if vis.has(Vector2i(x, y) + dd):
				return true
		return false
	for o in H.atrezo:
		chk(junto.call(o[0], o[1]) and m.o[o[1]][o[0]] == o[2], "se llega a %s" % [o])
	for st in H.sitios:
		chk(junto.call(st[0], st[1]), "se llega al sitio %s" % [st])
	chk(vis.has(Vector2i(int(H.camino), ys)), "se llega a la salida")
	var bi: Array = H.atrezo[0]
	LOG.clear()
	chk(corre(func(): await J.object_action(bi[0], bi[1])), "el bidón, abandonada")
	chk(dicho("grifo del garaje"), "el bidón, con la manguera del garaje")
	# 3 · desbrozar
	var t0 := minutos()
	QUIERO = ["Desbrozar"]
	chk(corre(func(): await J.object_action(int(H.bancales[0][0]), int(H.bancales[0][1]))), "desbrozar")
	chk(J.huerta_lista(), "desbrozada")
	chk(minutos() - t0 >= int(H.desbroce), "desbrozar lleva %d min (%d)" % [int(H.desbroce), minutos() - t0])
	m = J.MAPS.huerta
	var surcos := 0
	var quedan := 0
	for b in H.bancales:
		for y in range(int(b[1]), int(b[3]) + 1):
			for x in range(int(b[0]), int(b[2]) + 1):
				surcos += 1 if m.g[y][x] == "surco" else 0
				quedan += 1 if m.o[y][x] == "bush" else 0
	chk(surcos == 40 and quedan == 0, "desbrozada: 40 casillas de surco (%d) y ninguna zarza (%d)" % [surcos, quedan])
	# 4 · plantar en abril (el día 1 es el 20 de abril)
	var sid: String = String(D.BANCO[0][0])
	S.seeds = {sid: 3}
	S.day = 1
	S.min = 8 * 60
	QUIERO = [J.strain(sid).n]
	var s0: Array = H.sitios[0]
	chk(corre(func(): await J.object_action(s0[0], s0[1])), "plantar en el sitio 0")
	var p0 = J.huerta_s().p[0]
	chk(p0 is Dictionary and p0.sid == sid and int(S.seeds.get(sid, 0)) == 2, "plantada la %s (%s)" % [sid, p0])
	chk(String(J.MAPS.huerta.o[s0[1]][s0[0]]).begins_with("hg-") and String(J.MAPS.huerta.o[s0[1]][s0[0]]).ends_with("-1"), "se ve la plántula: %s" % J.MAPS.huerta.o[s0[1]][s0[0]])
	var pr0: float = float(p0.prog)
	J.plants_advance(60)
	chk(float(p0.prog) > pr0, "crece con el reloj del juego (plants_advance): %s → %s" % [pr0, p0.prog])
	# 5 · la temporada: hasta julio, en vegetativo; el 1 de julio, otra en el sitio 1
	var jul: int = Datos.dia_de(2026, 7, 1)
	temporada(jul)
	chk(J.huerta_veg(S.day) and J.huerta_f(p0).ciclo == "veg", "el 1 de julio, días largos: vegetativo")
	chk(float(p0.prog) < .65 and float(p0.prog) >= .6, "en vegetativo no florece (prog %s)" % p0.prog)
	QUIERO = [J.strain(sid).n]
	var s1: Array = H.sitios[1]
	chk(corre(func(): await J.object_action(s1[0], s1[1])), "plantar en julio en el sitio 1")
	var p1 = J.huerta_s().p[1]
	chk(p1 is Dictionary, "plantada en julio")
	p1.f = p0.f.duplicate(true)   # el mismo fenotipo, para comparar solo la temporada
	var ago: int = Datos.dia_de(2026, 8, 6)
	temporada(ago)
	chk(not J.huerta_veg(S.day) and J.huerta_f(p0).ciclo == "flor", "el 6 de agosto, días cortos: floración")
	temporada(ago + 30)
	chk(float(p0.prog) >= 1 and float(p1.prog) >= 1, "a primeros de septiembre, las dos listas (%s, %s)" % [p0.prog, p1.prog])
	var ga: int = Cultivo.gramos_planta(S, p0, J.huerta_f(p0))
	var gj: int = Cultivo.gramos_planta(S, p1, J.huerta_f(p1))
	chk(ga > gj, "plantada en abril da más que en julio (%d g frente a %d g)" % [ga, gj])
	print("  huerta: abril %d g, julio %d g (vd %.0f y %.0f días)" % [ga, gj, float(p0.vd), float(p1.vd)])
	chk(ga > int(D.MACETAS.plastico7.cap), "al sol, más que una maceta de 7 L (%d g)" % ga)
	chk(ga <= int(H.cap), "como mucho %d g (%d)" % [int(H.cap), ga])
	chk(String(J.MAPS.huerta.o[s0[1]][s0[0]]).ends_with("-5"), "lista, con cogollos: %s" % J.MAPS.huerta.o[s0[1]][s0[0]])
	# 6 · la lluvia riega y el bidón también
	var dl := dia_que(S.day, func(t): return t.k == "lluvia")
	chk(dl > 0, "hay un día de lluvia")
	S.day = dl
	S.min = 720
	if Datos.tiempo(S.day, S.min).k == "lluvia":
		p1.water = 10.0
		J.huerta_avanza(10)
		chk(float(p1.water) > 95, "con lluvia, regada (%s)" % p1.water)
	p0.water = 10.0
	p1.water = 10.0
	S.day = dia_que(S.day, func(t): return t.k == "sol")
	S.min = 600
	t0 = minutos()
	QUIERO = ["Regar todas"]
	chk(corre(func(): await J.object_action(bi[0], bi[1])), "el bidón: regar todas")
	chk(float(p0.water) > 95 and float(p1.water) > 95, "regadas todas (%s, %s)" % [p0.water, p1.water])
	chk(minutos() - t0 >= int(H.riego), "regar todas lleva media hora (%d)" % (minutos() - t0))
	# 7 · cosechar la de abril
	var g0 := gramos_de(sid)
	QUIERO = ["Cosechar"]
	chk(corre(func(): await J.object_action(s0[0], s0[1])), "cosechar la de abril")
	var gt := gramos_de(sid)
	chk(J.huerta_s().p[0] == null and gt - g0 >= ga * .5, "cosechada: %s g de %s (esperaba unos %d)" % [gt - g0, sid, ga])
	chk(J.MAPS.huerta.o[s0[1]][s0[0]] == "hgx", "el sitio, vacío (sólido y sin dibujo)")
	# 8 · la helada y la nieve (al amanecer, por la mínima de ayer)
	J.huerta_s().p[2] = Cultivo.nueva_planta(S, sid)
	var p2 = J.huerta_s().p[2]
	p2.prog = .3
	var dh := dia_que(Datos.dia_de(2026, 11, 1), func(t): return int(t.min) <= 0 and t.k != "nieve")
	chk(dh > 0, "hay un día de helada en invierno")
	S.day = dh + 1
	p2.health = 100.0
	J.huerta_dia()
	chk(is_equal_approx(float(p2.health), 100.0 - float(H.helada)), "la helada le quita %d de salud (%s)" % [int(H.helada), p2.health])
	var dn := dia_que(Datos.dia_de(2026, 11, 1), func(t): return t.k == "nieve")
	if dn > 0:
		S.day = dn + 1
		p2.health = 100.0
		J.huerta_dia()
		chk(is_equal_approx(float(p2.health), 100.0 - float(H.nieve)), "la nieve le quita %d (%s)" % [int(H.nieve), p2.health])
	var dt := dia_que(Datos.dia_de(2026, 6, 1), func(t): return int(t.min) > 0 and t.k == "sol")
	S.day = dt + 1
	p2.health = 100.0
	J.huerta_dia()
	chk(is_equal_approx(float(p2.health), 100.0), "sin helada ni nieve, nada (%s)" % p2.health)
	# 9 · seca: parda, y se retira
	p2.dead = true
	J.huerta_objs()
	var s2: Array = H.sitios[2]
	var so: String = String(J.MAPS.huerta.o[s2[1]][s2[0]])
	chk(so.begins_with("hgs-"), "la muerta, hgs: %s" % so)
	var Atlas = load("res://src/atlas.gd")
	Atlas.carga()
	var fr = Atlas.frame_de(Atlas.cubre("obj:hg-" + so.substr(4)), "hg-" + so.substr(4), "unica", 0, {"i": 0})
	chk(fr != null, "su dibujo, el de hg-" + so.substr(4))
	if fr != null:
		var im: Image = Pintor._seca(fr.c)
		var verdes := 0
		for y in im.get_height():
			for x in im.get_width():
				var c := im.get_pixel(x, y)
				if c.a > 0 and c.g > c.r:
					verdes += 1
		chk(verdes == 0 and im.get_size() == fr.c.get_size(), "parda: ningún píxel verde (%d)" % verdes)
	QUIERO = []
	chk(corre(func(): await J.object_action(s2[0], s2[1])), "retirar la seca")
	chk(J.huerta_s().p[2] == null and J.MAPS.huerta.o[s2[1]][s2[0]] == "hgx", "retirada")
	# 10 · guardada y cargada (JSON), sigue igual
	var cp = JSON.parse_string(JSON.stringify(S.huerta))
	S.huerta = cp
	J.enter_map("huerta", ll.x, ll.y, "up")
	chk(String(J.MAPS.huerta.o[s1[1]][s1[0]]).begins_with("hg-"), "tras guardar y cargar, la de julio sigue: %s" % J.MAPS.huerta.o[s1[1]][s1[0]])
	chk(J.MAPS.huerta.g[int(H.bancales[0][1])][int(H.bancales[0][0])] == "surco", "y desbrozada")
	# 11 · al raso: el tiempo y la noche
	S.map = "huerta"
	chk(J.pintor._al_raso() if J.get("pintor") else true, "la huerta, al raso")
	# 12 · sin CAL, el pueblo como estaba
	Datos.CAL = false
	J.enter_map("town", 9, 2, "down")
	chk(J.MAPS.town.o[q[1]][q[0]] == D0.o[q[1]][q[0]] and not J.MAPS.town.doors.has("%d,%d" % [q[0], q[1]]), "sin CAL, otra vez la mata y sin puerta")
	for c in H.senda:
		chk(J.MAPS.town.g[c[1]][c[0]] == D0.g[c[1]][c[0]] and J.MAPS.town.o[c[1]][c[0]] == D0.o[c[1]][c[0]], "sin CAL, %s como estaba" % [c])
	S.day = Datos.dia_de(2026, 7, 1)
	var pp: float = float(p1.prog)
	J.plants_advance(60)
	chk(float(p1.prog) == pp, "sin CAL, la huerta no crece")
	Datos.CAL = true
	print("huerta: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
