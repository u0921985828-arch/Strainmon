# Ribera Verde (Godot) — la sala de cultivo de KAIA (kaiacult.gd, con CAL; lo pidió el usuario: «incluso molaría tener un cultivo
# finalmente en la nueva asociación de KAIA» y «tiene que tener lógica con el suelo que hay al rededor y las zonas donde las colocas»):
# la puerta de KAIA, cerrada sin la licencia; dentro, el pasillo y la zona de cultivo; las carpas solo en la zona; plantar, crecer
# con el goteo y cosechar; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/kaia_cult.gd   → «kaia_cult: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
var LOG := []
var MENUS := []
var TIT := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	MENUS.append(items.map(func(it): return it if it is String else str(it.get("label", ""))))
	TIT.append(str(o.get("title", "")))
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
			break
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
			print("  bloqueo")
			return false
	return true

func dicho(t: String) -> bool:
	return LOG.any(func(l): return String(l).contains(t))

func mundo(mapa: String, x: int, y: int) -> bool:
	J.enter_map(mapa, x, y, "down")
	J.mode = "world"
	return corre(func(): pass)

func alcance_d(mapa: String, x0: int, y0: int) -> Dictionary:
	var m: Dictionary = J.MAPS[mapa]
	var q := [[x0, y0]]
	var v := {}
	var i := 0
	while i < q.size():
		var c: Array = q[i]
		i += 1
		var kk := "%d,%d" % [c[0], c[1]]
		if v.has(kk) or not J.pisable(m, c[0], c[1]) or m.o[c[1]][c[0]]:
			continue
		v[kk] = true
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			q.append([c[0] + d[0], c[1] + d[1]])
	return v

func delante(v: Dictionary, x: int, y: int) -> bool:
	return [[0, 1], [0, -1], [1, 0], [-1, 0]].any(func(d): return v.has("%d,%d" % [x + d[0], y + d[1]]))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-kaia-cult.json"
	Juego.AJUSTES = "user://prueba-kaia-cult-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D: Dictionary = J.D
	var KC: Dictionary = D.KAIA_CULT
	var C: String = KC.mapa
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	if not (J.S.get("mar") is Dictionary):
		J.S.mar = {}
	J.S.mar.erase("lic")
	J.S.erase("kc")
	# 1 · los datos: la sala, su puerta en KAIA y sus carpas
	chk(D.MAPS.has(C) and D.ORDEN_P.has(C) and D.ORDEN_P[C].piezas.size() == 3 and D.ORDEN_P[C].piezas.all(func(p): return p.zona == ["floorG"]), "la sala, con tres carpas que van en la zona")
	chk(D.PUERTAS_INT["club-muelle"].any(func(p): return p.to == C and int(p.x) == 15 and int(p.y) == 1 and p.llave == "kc"), "la puerta, en la pared de KAIA")
	chk(D.MAPS["club-muelle"].o[2][14] == "jukebox" and D.MAPS["club-muelle"].o[2][15] == null and D.ORDEN_P["club-muelle"].pie.any(func(c): return int(c[0]) == 15 and int(c[1]) == 2), "la gramola, a un lado; delante de la puerta, libre")
	var cm: Dictionary = D.MAPS[C]
	chk(range(2, cm.h).all(func(y): return cm.g[y][0] == "floorC_itsaso" and cm.g[y][2] == "floorC_itsaso" and cm.g[y][3] == "floorG" and cm.g[y][13] == "floorG"), "el pasillo con el suelo del club y la zona de cultivo con el del grow")
	# 2 · sin la licencia, cerrada
	chk(mundo("club-muelle", 15, 2) and J.MAPS["club-muelle"].o[1][15] == "puertaI", "en KAIA, la puerta")
	LOG = []
	chk(corre(func(): await J.object_action(15, 1)) and J.S.map == "club-muelle" and dicho("licencia"), "sin la licencia, cerrada")
	# 3 · con ella, dentro
	J.S.mar.lic = int(J.S.day)
	chk(corre(func(): await J.object_action(15, 1)) and J.S.map == C and J.P.x == 1 and J.P.y == 2, "con la licencia, dentro (%s %d,%d)" % [J.S.map, J.P.x, J.P.y])
	var m: Dictionary = J.MAPS[C]
	chk(m.o[2][6] == "carpaK0" and m.o[2][7] == "carpaM2" and m.o[2][9] == "carpaK1" and m.o[5][6] == "carpaK2", "las tres carpas, en su sitio")
	chk(J.sprite_local("carpaK0") == "carpaM-0", "la carpa, vacía (%s)" % J.sprite_local("carpaK0"))
	var v := alcance_d(C, 1, 2)
	for y in m.h:
		for x in m.w:
			if m.o[y][x] and m.o[y][x] != "carpaM2" and (y >= 2 or m.o[y][x] in ["ctrlN", "puertaI"]):   # lo de la pared encima de las carpas, solo se ve
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [m.o[y][x], x, y])
	# 4 · la regla de la zona: las carpas, solo en el suelo del grow
	chk(J.cabe_pieza(C, "kc0", 1, 4) == "zona" and J.cabe_pieza(C, "kc0", 2, 4) == "zona", "en el pasillo, no: «%s»" % J.cabe_pieza(C, "kc0", 2, 4))
	chk(J.cabe_pieza(C, "kc0", 3, 4) == "" and J.cabe_pieza(C, "kc0", 10, 4) == "", "en la zona, sí: «%s» «%s»" % [J.cabe_pieza(C, "kc0", 3, 4), J.cabe_pieza(C, "kc0", 10, 4)])
	chk(J.cabe_pieza("home", "carpa0", 8, 2) != "zona", "las carpas de casa, sin la regla")
	chk(str(D.ORDEN_MOTIVO.zona).contains("zona de cultivo"), "el motivo, dicho")
	# 5 · el cuadro: ordenar la sala, desde dentro
	TIT = []
	QUIERO = ["Ordenar la sala"]
	chk(corre(func(): await J.object_action(4, 1)) and TIT.has(D.ORDEN_P[C].n), "el cuadro ordena la sala (%s)" % [TIT])
	J.S.coloca = {C: {"kc0": [1, 3]}}
	J.aplica_orden(C)
	var p0: Array = J.pos_pieza(C, "kc0")
	chk(int(p0[0]) >= 3, "una carpa guardada en el pasillo vuelve a la zona (%s)" % [p0])
	J.S.coloca = {}
	J.MAPS[C].erase("opos")
	chk(mundo(C, 1, 2) and J.pos_pieza(C, "kc0") == [6, 2], "de serie, otra vez")
	# 6 · plantar en una plaza de la carpa
	J.S.seeds = {"txoko": 2}
	LOG = []
	QUIERO = ["Plaza 1", J.strain("txoko").n]
	chk(corre(func(): await J.object_action(6, 2)) and J.kc().p[0] is Dictionary and J.kc().p[0].sid == "txoko" and int(J.S.seeds.get("txoko", 0)) == 1, "plantada en la plaza 1")
	chk(J.sprite_local("carpaK0") == "carpaM-1" and J.sprite_local("carpaK1") == "carpaM-0", "la carpa 1, con una planta")
	QUIERO = ["Plaza 2", J.strain("txoko").n]
	chk(corre(func(): await J.object_action(7, 2)) and J.kc().p[1] is Dictionary and J.kc_plantadas(0) == 2, "por la otra mitad, la misma carpa")
	# 7 · crecen solas, con el goteo, también fuera de la sala
	chk(mundo("club-muelle", 15, 2), "fuera")
	var p: Dictionary = J.kc().p[0]
	p.water = 20.0
	J.plants_advance(60)
	chk(float(p.prog) > 0 and is_equal_approx(float(p.water), 100.0), "crece y el goteo la riega (prog %.3f, agua %d)" % [float(p.prog), int(p.water)])
	var h := 0
	while float(p.prog) < 1 and h < 24 * 200:
		J.plants_advance(60)
		h += 1
	chk(float(p.prog) >= 1 and not p.get("dead") and float(p.health) > 50, "lista en %d días (salud %d)" % [h / 24, int(p.health)])
	var sd: float = float(J.strain("txoko").d)
	chk(h / 24.0 >= sd * .5 and h / 24.0 <= sd * 2.5, "a su ritmo: %.1f días para %.1f" % [h / 24.0, sd])
	# 8 · cosechar
	chk(mundo(C, 1, 2), "dentro otra vez")
	var g0: float = 0.0
	for k in J.S.buds:
		g0 += float(J.S.buds[k].g)
	QUIERO = ["Plaza 1", "Cosechar"]
	LOG = []
	chk(corre(func(): await J.object_action(6, 2)) and J.kc().p[0] == null and dicho("Cosechas"), "cosechada")
	var g1: float = 0.0
	for k in J.S.buds:
		g1 += float(J.S.buds[k].g)
	chk(g1 - g0 >= 40, "con su LED, una buena planta: %d g" % int(g1 - g0))
	# 9 · los demás muebles hablan
	for q in [[13, 6, "depósito"], [12, 7, "goteo"], [6, 1, "filtros"]]:
		LOG = []
		chk(corre(func(): await J.object_action(q[0], q[1])) and dicho(q[2]), "%s, dicho" % q[2])
	# 10 · sin CAL, nada
	Datos.CAL = false
	chk(J.puertas_int("club-muelle").is_empty() and J.sprite_local("carpaK0") == "carpaK0" and not J.kc_hay(), "sin CAL, ni la puerta ni la sala")
	Datos.CAL = true
	print("kaia_cult: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
