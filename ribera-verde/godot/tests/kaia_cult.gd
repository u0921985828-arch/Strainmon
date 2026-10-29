# Ribera Verde (Godot) — la sala de cultivo de KAIA (kaiacult.gd, con CAL; lo pidió el usuario: «incluso molaría tener un cultivo
# finalmente en la nueva asociación de KAIA», «tiene que tener lógica con el suelo que hay al rededor y las zonas donde las colocas» y
# «como en casa, cultivo con carpas, pero más grandes de primeras, con una inversión realista, después como en la nave en esa misma
# habitación, ya con posibilidad de poner a alguien a trabajar ahí y la inversión será más grande»): la puerta de KAIA, cerrada sin la
# licencia; dentro, el pasillo y la zona de cultivo; las carpas por niveles (4 de 2 × 2, 2 de 4 × 2 y 1 de 4 × 4) por la cuenta, que
# llegan al día siguiente, y el paso de un nivel al siguiente con las de antes de segunda mano; las
# carpas solo en la zona y sin montarse encima de nada; plantar, crecer con el goteo y cosechar; la obra de la sala con las mesas y
# quien las lleva, que cortan, secan y llenan el almacén de KAIA; nada encima de nada; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/kaia_cult.gd   → «kaia_cult: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Atlas = preload("res://src/atlas.gd")

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
	Atlas.carga()
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
	if J.S.get("nave") is Dictionary:   # la nave de la partida de las pantallas (la 1.37), con lo que nave_dia lee ahora
		if not J.S.nave.has("ma"):
			J.S.nave.ma = []
		if not J.S.nave.has("r"):
			J.S.nave.r = int(J.S.day) + 30
	J.S.erase("kc")
	# 1 · los datos: la sala, su puerta en KAIA, sus carpas y la obra
	var PZ: Array = D.ORDEN_P[C].piezas
	chk(D.MAPS.has(C) and int(D.MAPS[C].w) == 16 and int(D.MAPS[C].h) == 10 and PZ.size() == 7 and PZ.all(func(q): return q.zona == ["floorG"] and q.si == "kc"), "la sala de 16 × 10, con las siete carpas de los tres niveles, que van en la zona")
	var NV: Array = KC.niv
	chk(NV.size() == 3 and NV.map(func(q): return [int(q.max), int(q.tam[0]), int(q.tam[1])]) == [[4, 2, 2], [2, 4, 2], [1, 4, 4]] and PZ.all(func(q): return q.o.size() == int(NV[["s", "m", "l"].find(str(q.k).substr(2, 1))].tam[0]) * int(NV[["s", "m", "l"].find(str(q.k).substr(2, 1))].tam[1])), "los niveles: 4 de 2 × 2, 2 de 4 × 2 y 1 de 4 × 4, cada pieza de su tamaño")
	chk(D.PUERTAS_INT["club-muelle"].any(func(q): return q.to == C and int(q.x) == 15 and int(q.y) == 1 and q.llave == "kc"), "la puerta, en la pared de KAIA")
	chk(D.MAPS["club-muelle"].o[2][14] == "jukebox" and D.MAPS["club-muelle"].o[2][15] == null and D.ORDEN_P["club-muelle"].pie.any(func(c): return int(c[0]) == 15 and int(c[1]) == 2), "la gramola, a un lado; delante de la puerta, libre")
	var cm: Dictionary = D.MAPS[C]
	chk(range(2, cm.h).all(func(y): return cm.g[y][0] == "floorC_itsaso" and cm.g[y][2] == "floorC_itsaso" and cm.g[y][3] == "floorG" and cm.g[y][15] == "floorG"), "el pasillo con el suelo del club y la zona de cultivo con el del grow")
	var kps := []
	for N in NV:
		var kq := 0
		for q in N.kit.l:
			kq += int(q[1])
		kps.append(kq)
		var wl: float = float(D.FOCOS[KC.foco].w) * float(N.nf)
		chk(kq == int(N.kit.p) and D.FOCOS[KC.foco].w == 720 and wl / (float(N.cm[0]) * float(N.cm[1]) / 1e4) >= 300 and wl / (float(N.cm[0]) * float(N.cm[1]) / 1e4) <= float(D.W_M2), "%s: el kit a precio de tienda (%d €), %d LED de 720 W (%d W/m²)" % [N.n, kq, int(N.nf), int(wl / (float(N.cm[0]) * float(N.cm[1]) / 1e4))])
	var kp: int = kps[0]
	chk(kps[0] < kps[1] and kps[1] < kps[2] and int(NV[0].plazas) * 4 == int(NV[1].plazas) * 2 and int(NV[1].plazas) * 2 == int(NV[2].plazas), "cada nivel, más inversión por carpa y las mismas plazas en total: %s" % [kps])
	chk(int(KC.f2.p) > kps[2] and KC.f2.mesas.size() == 8 and int(D.PLANTILLA.sueldo.kaia) > 0, "la obra, más inversión que la carpa grande: %d €" % int(KC.f2.p))
	chk(cm.o[1][2] == "ctrlN" and D.ORDEN_RESERVA[C].any(func(c): return int(c[0]) == 2 and int(c[1]) == 2), "el cuadro en la pared del pasillo, con su casilla de delante reservada")
	# 2 · sin la licencia, cerrada
	chk(mundo("club-muelle", 15, 2) and J.MAPS["club-muelle"].o[1][15] == "puertaI", "en KAIA, la puerta")
	LOG = []
	chk(corre(func(): await J.object_action(15, 1)) and J.S.map == "club-muelle" and dicho("licencia"), "sin la licencia, cerrada")
	# 3 · con ella, dentro: vacía, sin carpas
	J.S.mar.lic = int(J.S.day)
	chk(corre(func(): await J.object_action(15, 1)) and J.S.map == C and J.P.x == 1 and J.P.y == 2, "con la licencia, dentro (%s %d,%d)" % [J.S.map, J.P.x, J.P.y])
	var m: Dictionary = J.MAPS[C]
	chk(not m.o.any(func(r): return r.any(func(c): return c != null and str(c).begins_with("carpa"))), "vacía: las carpas se compran")
	# 4 · el cuadro: un kit, por la cuenta, llega mañana
	J.S.banco = 0
	LOG = []
	QUIERO = ["Comprar:", "Comprarlo"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().kits.all(func(d): return int(d) < 0) and dicho("tarjeta no pasa"), "sin dinero en la cuenta, no")
	J.S.banco = 100000
	QUIERO = ["Comprar:", "Comprarlo"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().kits.filter(func(d): return int(d) >= 0).size() == 1 and is_equal_approx(float(J.S.banco), 100000.0 - kp), "comprado, por la cuenta (%d €)" % int(J.S.banco))
	chk(mundo(C, 1, 2) and m.o[3][13] == null, "hoy no está")
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][13] == "carpaKS0" and m.o[2][13] == "carpaG2" and m.o[2][14] == "carpaG2" and m.o[3][14] == "carpaG2" and m.o[4][13] == null, "mañana, montada en su sitio, 2 × 2")
	chk(J.sprite_local("carpaKS0") == "kcs-0", "la carpa, vacía (%s)" % J.sprite_local("carpaKS0"))
	chk(not MENUS.is_empty(), "el cuadro, con menú")
	TIT = []
	QUIERO = []
	MENUS = []
	corre(func(): await J.object_action(2, 1))
	chk(MENUS.size() and not MENUS.back().any(func(l): return str(l).begins_with("Montar la carpa de sala")) and MENUS.back().any(func(l): return str(l).begins_with("Pasar a la Carpa 400×200")), "en el primer nivel, pasar al siguiente, no la reforma: %s" % [MENUS.back() if MENUS.size() else []])
	for i in 3:
		QUIERO = ["Comprar:", "Comprarlo"]
		corre(func(): await J.object_action(2, 1))
	LOG = []
	TIT = []
	QUIERO = []
	corre(func(): await J.object_action(2, 1))
	chk(J.kc().kits.filter(func(d): return int(d) >= 0).size() == 4 and not MENUS.back().any(func(l): return str(l).begins_with("Comprar:")), "cuatro como mucho")
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][13] == "carpaKS0" and m.o[7][13] == "carpaKS1" and m.o[8][8] == "carpaKS2" and m.o[8][11] == "carpaKS3", "las cuatro, en su sitio")
	var v := alcance_d(C, 1, 2)
	for y in m.h:
		for x in m.w:
			if m.o[y][x] and m.o[y][x] != "carpaG2" and m.o[y][x] != "mesaKC2":
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [m.o[y][x], x, y])
	# 5 · nada encima de nada: ni las carpas ni lo de la pared
	var sl: Array = J.solapes_de(J.cajas_obj(C, m.o))
	chk(sl.is_empty(), "las cuatro carpas, sin solapes: %s" % [sl.slice(0, 3)])
	# 6 · la regla de la zona y la del solape
	chk(J.cabe_pieza(C, "kcs0", 0, 4) == "zona" and J.cabe_pieza(C, "kcs0", 1, 4) == "zona", "en el pasillo, no: «%s»" % J.cabe_pieza(C, "kcs0", 1, 4))
	chk(J.cabe_pieza(C, "kcs0", 4, 5) == "", "en la zona libre, sí: «%s»" % J.cabe_pieza(C, "kcs0", 4, 5))
	chk(J.cabe_pieza(C, "kcs0", 8, 5) == "solapa", "delante de otra carpa, con el tubo encima de ella, no: «%s»" % J.cabe_pieza(C, "kcs0", 8, 5))
	chk(str(D.ORDEN_MOTIVO.zona).contains("zona de cultivo") and str(D.ORDEN_MOTIVO.solapa).contains("encima"), "los motivos, dichos")
	chk(J.cabe_pieza("home", "carpa0", 8, 2) != "zona", "las carpas de casa, sin la regla")
	mundo("club-muelle", 14, 3)
	var gr := []
	for y in int(J.MAPS["club-muelle"].h):
		for x in int(J.MAPS["club-muelle"].w):
			if J.MAPS["club-muelle"].o[y][x] == "jukebox":
				gr.append([x, y])
	chk(gr == [[14, 2]], "KAIA montado, una sola gramola, en (14, 2): %s" % [gr])
	mundo(C, 1, 2)
	TIT = []
	QUIERO = ["Ordenar la sala"]
	chk(corre(func(): await J.object_action(2, 1)) and TIT.has(D.ORDEN_P[C].n), "el cuadro ordena la sala (%s)" % [TIT])
	J.S.coloca = {C: {"kcs0": [0, 4]}}
	J.aplica_orden(C)
	chk(int(J.pos_pieza(C, "kcs0")[0]) >= 3, "una carpa guardada en el pasillo vuelve a la zona (%s)" % [J.pos_pieza(C, "kcs0")])
	J.S.coloca = {}
	J.MAPS[C].erase("opos")
	chk(mundo(C, 1, 2) and int(J.pos_pieza(C, "kcs0")[0]) == 13 and int(J.pos_pieza(C, "kcs0")[1]) == 2, "de serie, otra vez (%s)" % [J.pos_pieza(C, "kcs0")])
	# 7 · plantar en las plazas de una carpa, por cualquiera de sus casillas
	J.S.seeds = {"txoko": 3}
	QUIERO = ["Plaza 1", J.strain("txoko").n]
	MENUS = []
	LOG = []
	chk(corre(func(): await J.object_action(13, 3)) and J.kc().p[0] is Dictionary and J.kc().p[0].sid == "txoko" and int(J.S.seeds.get("txoko", 0)) == 2, "plantada en la plaza 1 (%s · %s · %s)" % [MENUS.slice(-3), J.kc().p.slice(0, 2), LOG.slice(-3)])
	chk(J.sprite_local("carpaKS0") == "kcs-1" and J.sprite_local("carpaKS1") == "kcs-0", "la carpa 1, con una planta")
	QUIERO = ["Plaza 4", J.strain("txoko").n]
	chk(corre(func(): await J.object_action(14, 2)) and J.kc().p[3] is Dictionary and J.kc_plantadas(0) == 2, "por la otra punta, la misma carpa, plaza 4")
	# 8 · crecen solas, con el goteo, también fuera de la sala
	chk(mundo("club-muelle", 15, 2), "fuera")
	if not (J.kc().p[0] is Dictionary):
		for f in fallos:
			print("  ✗ " + f)
		quit(1)
		return
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
	# 9 · cosechar
	chk(mundo(C, 1, 2), "dentro otra vez")
	var g0 := 0.0
	for k in J.S.buds:
		g0 += float(J.S.buds[k].g)
	QUIERO = ["Plaza 1", "Cosechar"]
	LOG = []
	chk(corre(func(): await J.object_action(13, 3)) and J.kc().p[0] == null and dicho("Cosechas"), "cosechada")
	var g1 := 0.0
	for k in J.S.buds:
		g1 += float(J.S.buds[k].g)
	chk(g1 - g0 >= 60, "con sus dos LED, una buena planta: %d g" % int(g1 - g0))
	# 9b · los niveles conviven (lo pidió el usuario: «ir completando con las diferentes medidas la sala, con espacio para pasar entre
	# ellas»): pasar al siguiente compra la primera del tamaño nuevo y las de antes se quedan, con sus plantas
	var bn: float = float(J.S.banco)
	QUIERO = ["Pasar a la", "Comprarla"]
	chk(corre(func(): await J.object_action(2, 1)) and int(J.kc().niv) == 1 and int(J.kc().kits[4]) == int(J.S.day) + 1 and J.kc_kits() == 4 and J.kc().p[3] is Dictionary, "a las de 4 × 2: una pedida y las cuatro de 2 × 2 siguen (%s)" % [J.kc().kits])
	chk(is_equal_approx(float(J.S.banco), bn - kps[1]), "por la cuenta, solo la nueva (%d €)" % int(bn - J.S.banco))
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][3] == "carpaKM0" and m.o[2][6] == "carpaG2" and m.o[3][7] == null and m.o[3][13] == "carpaKS0" and J.sprite_local("carpaKM0") == "kcm-0", "mañana, la de 4 × 2 en su sitio, con las de antes")
	QUIERO = ["Comprar: Carpa 400×200", "Comprarlo"]
	corre(func(): await J.object_action(2, 1))
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][8] == "carpaKM1" and J.solapes_de(J.cajas_obj(C, m.o)).is_empty(), "las dos de 4 × 2, sin solapes")
	var o5: int = J.kc_off(5)
	QUIERO = ["Plaza 8", J.strain("txoko").n]
	J.S.seeds = {"txoko": 3}
	chk(corre(func(): await J.object_action(11, 2)) and J.kc().p[o5 + 7] is Dictionary and J.kc_plantadas(5) == 1, "la segunda, por su otra punta, plaza 8")
	J.kc().p[o5 + 7] = null
	QUIERO = ["Pasar a la", "Comprarla"]
	corre(func(): await J.object_action(2, 1))
	J.S.day += 1
	chk(int(J.kc().niv) == 2 and mundo(C, 1, 2) and m.o[8][3] == "carpaKL0" and m.o[5][6] == "carpaG2" and J.kc_kits() == 7 and J.solapes_de(J.cajas_obj(C, m.o)).is_empty(), "la de 4 × 4 con las seis de antes, sin solapes")
	MENUS = []
	QUIERO = []
	corre(func(): await J.object_action(2, 1))
	chk(MENUS.size() and not MENUS.back().any(func(l): return str(l).begins_with("Comprar") or str(l).begins_with("Pasar")) and MENUS.back().any(func(l): return str(l).begins_with("Montar la carpa de sala")), "con la sala llena, ya solo la carpa de sala: %s" % [MENUS.back() if MENUS.size() else []])
	v = alcance_d(C, 1, 2)
	for y in m.h:
		for x in m.w:
			if m.o[y][x] and m.o[y][x] != "carpaG2":
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [m.o[y][x], x, y])
	# 10 · la carpa de sala (lo pidió el usuario: «que la sala sea previamente una carpa»): con plantas, no; vacía, se paga, se venden
	# las siete de segunda mano y, a los días, la carpa que ocupa toda la zona, que se entra, con las 8 mesas dentro
	LOG = []
	QUIERO = ["Montar la carpa de sala"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().get("f2") == null and dicho("Antes, cosecha"), "con plantas en las carpas, aún no")
	J.kc().p[3] = null
	var b0: float = float(J.S.banco)
	QUIERO = ["Montar la carpa de sala", "Hacer la obra"]
	J.kc().kits.append(int(J.S.day) + 1)   # una carpa pagada que aún no ha llegado: primero que llegue, no se vende al 40 % sin montarla
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().get("f2") == null and dicho("espera a que llegue"), "con una carpa en camino, aún no")
	J.kc().kits.pop_back()
	QUIERO = ["Montar la carpa de sala", "Hacer la obra"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().get("f2") != null and J.kc_kits() == 0, "la obra, en marcha")
	var ven := 0
	for ci in 7:
		ven += roundi(kps[[0, 0, 0, 0, 1, 1, 2][ci]] * float(KC.f2.venta))
	chk(is_equal_approx(float(J.S.banco), b0 - int(KC.f2.p) + ven), "por la cuenta, menos las siete de segunda mano (%d €)" % int(b0 - J.S.banco))
	chk(mundo(C, 1, 2) and not m.o.any(func(r): return r.any(func(c): return c != null and (str(c).begins_with("carpa") or str(c).begins_with("mesa")))), "en obras: ni carpas ni mesas")
	LOG = []
	chk(corre(func(): await J.object_action(2, 1)) and dicho("en obras"), "el cuadro lo dice")
	J.S.day += int(KC.f2.dias)
	var CX: Dictionary = KC.f2.carpa
	chk(mundo(C, 1, 2) and m.o[int(CX.def[1]) + int(CX.tam[1]) - 1][int(CX.def[0])] == "carpaKX" and m.o[int(CX.def[1])][int(CX.def[0]) + int(CX.tam[0]) - 1] == "carpaG2", "la carpa de sala, en toda la zona")
	sl = J.solapes_de(J.cajas_obj(C, m.o))
	chk(sl.is_empty(), "la carpa de sala, sin solapes: %s" % [sl.slice(0, 3)])
	v = alcance_d(C, 1, 2)
	chk(delante(v, int(CX.puerta[0]), int(CX.puerta[1]) - 1) or delante(v, int(CX.puerta[0]), int(CX.puerta[1])), "se llega a su puerta")
	chk(J.pos_pieza(C, "kcs0") == [13, 2] and J.piezas_ya(C).is_empty(), "sin carpas que ordenar")
	var SA: String = KC.f2.sala
	chk(corre(func(): await J.object_action(int(CX.puerta[0]), int(CX.puerta[1]) - 1)) and J.S.map == SA and J.P.x == int(KC.f2.entra[0]) and J.P.y == int(KC.f2.entra[1]), "se entra en la carpa de sala (%s %d,%d)" % [J.S.map, J.P.x, J.P.y])
	var ms: Dictionary = J.MAPS[SA]
	chk(KC.f2.mesas.all(func(q): return ms.o[int(q[1])][int(q[0])] == "mesaKP" and ms.o[int(q[1])][int(q[0]) + 1] == "mesaKP2"), "las ocho mesas, montadas")
	chk(ms.o[8][0] == "tanqueN" and ms.o[1][11] == "riegoN" and ms.o[8][12] == "drenKS" and ms.o[1][1] == "ctrlN", "el tanque, el programador, el depósito de drenaje y el cuadro")
	sl = J.solapes_de(J.cajas_obj(SA, ms.o))
	chk(sl.is_empty(), "las mesas, sin solapes: %s" % [sl.slice(0, 3)])
	v = alcance_d(SA, int(KC.f2.entra[0]), int(KC.f2.entra[1]))
	for y in ms.h:
		for x in ms.w:
			if ms.o[y][x] and ms.o[y][x] != "mesaKP2":
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [ms.o[y][x], x, y])
	LOG = []
	chk(corre(func(): await J.object_action(12, 8)) and dicho("drenaje"), "el depósito de recogida lo dice")
	chk(mundo(SA, int(KC.f2.sale[0]), int(KC.f2.sale[1]) - 1), "dentro")
	# 11 · las mesas: plantar y, sin nadie, no avanzan
	QUIERO = ["Plantar", J.strain("txoko").n]
	chk(corre(func(): await J.object_action(1, 3)) and J.kc_me(0) is Dictionary and J.kc_me(0).k.begins_with("txoko"), "plantada la mesa 1")
	chk(J.mesa_de("mesaKP", 2, 3) != null and int(J.mesa_de("mesaKP", 2, 3).fm) == 1 and J.mesa_de("mesaKP", 2, 3).foco == "led", "en el mapa, con sus plantas y su foco")
	var p0 := float(J.kc_me(0).p)
	J.nave_dia()
	chk(is_equal_approx(float(J.kc_me(0).p), p0), "sin nadie que la lleve, no avanza")
	# 12 · quien lleva la sala
	var w := {"id": "plk", "n": "Iker", "lab": 3, "cui": 4, "lea": 4, "rol": null}
	J.S.plantilla = [w]
	chk(J.ops_staff(w).has("A la sala de KAIA"), "en la plantilla, la opción")
	corre(func(): await J.staff_op(w, "A la sala de KAIA"))
	chk(w.rol == "kaia" and J.kc_cultiva() == w and J.rol_txt(w) == "sala de KAIA" and J.rol_desc(w).contains("KAIA"), "a la sala")
	chk(J.local_staff(w) == "kaia" and J.nombre_local(J.local_staff(w)) == "La sala de KAIA", "en la plantilla, en su sala y no «Sin trabajo»: %s" % J.local_staff(w))
	chk(not J.ops_staff({"id": "x", "n": "Ane", "lab": 1, "cui": 1, "lea": 1, "rol": null}).has("A la sala de KAIA"), "uno solo")
	chk(mundo(SA, int(KC.f2.entra[0]), int(KC.f2.entra[1])) and J.ents.any(func(e): return e.id == "kcw"), "de pie en la sala")
	LOG = []
	chk(corre(func(): await J.npc_talk({"id": "kcw"})) and dicho("mesas"), "habla de las mesas")
	var mo0: float = float(J.S.money)
	J.S.money = 1000
	J.plantilla_dia()
	chk(is_equal_approx(float(J.S.money), 1000.0 - J.sueldo_w(w)) and J.sueldo_w(w) > 0, "cobra su sueldo (%d €)" % J.sueldo_w(w))
	J.S.money = mo0
	var d := 0
	while J.kc_me(0).get("h") == null and d < 200:
		J.S.day += 1
		J.nave_dia()
		d += 1
	chk(J.kc_me(0).get("h") != null and float(J.kc_me(0).h.g) >= 500 and int(J.kc_me(0).n) == 1, "cortada entera en %d días: %d g" % [d, int(J.kc_me(0).h.g)])
	chk(d >= int(J.strain("txoko").d) * .5, "a su ritmo")
	var a0: float = J.alm_g("muelle")
	J.S.day += int(D.NAVE.seca)
	J.nave_dia()
	chk(J.kc_me(0).get("h") == null and J.alm_g("muelle") > a0, "seca, al almacén de KAIA (%d g)" % int(J.alm_g("muelle") - a0))
	# lo que no cabe en el almacén, en la mesa, para llevártelo
	J.kc_me(0).h = {"g": float(D.MERCADO.alm.g) * 2, "t": 20.0, "d": J.S.day}
	J.S.day += int(D.NAVE.seca)
	J.nave_dia()
	chk(J.alm_g("muelle") <= float(D.MERCADO.alm.g) + .1 and float(J.kc_me(0).g) >= 1, "lo que no cabe, en la mesa (%d g)" % int(J.kc_me(0).g))
	var gm := float(J.kc_me(0).g)
	QUIERO = ["Llevarte lo seco"]
	chk(corre(func(): await J.object_action(1, 3)) and float(J.kc_me(0).g) < gm, "te lo llevas")
	# 12b · con las plantas crecidas, la copa no sube hasta el foco: pierde filas enteras y deja FOCO_AIRE px (la nave, con techo, igual)
	var At = load("res://src/atlas.gd")
	var Ar = load("res://src/arte.gd")
	var tope_ok := 0
	for q in D.KAIA_CULT.f2.mesas:
		var md = J.mesa_de("mesaKP", int(q[0]), int(q[1]))
		var ym: int = int(q[1]) * 16 + 15
		var tope: int = int(md.get("techo", 0)) + int(D.FOCO_POLEA) + 12 + int(D.FOCO_AIRE) + 1
		for fm in [2, 3, 4]:
			for po in ["i", "h", "s"]:
				var f = At.frame_de(At.cubre("obj:mesaN"), "plantasN-%d-%s" % [fm, po], "unica", 0, {"i": 0})
				if f == null:
					continue
				var o = J.pintor.copa_bajo_foco(f, ym, md)
				var top: int = ym - 47 + Ar.fila_arriba(o.c)
				var top0: int = ym - 47 + Ar.fila_arriba(f.c)
				chk(top >= tope and (top0 < tope or o.c == f.c) and o.c.get_size() == f.c.get_size(), "KAIA (%d, %d) %d-%s: la punta en %d, el foco hasta %d" % [q[0], q[1], fm, po, top, tope])
				chk(o.c.get_pixel(24, 46) == f.c.get_pixel(24, 46) and o.c.get_pixel(24, 47) == f.c.get_pixel(24, 47), "la base del tallo se queda")
				if top0 < tope:
					tope_ok += 1
	chk(tope_ok > 0, "la sativa en flor tocaba el foco antes")
	var mdn = {"foco": "led", "techo": 0}
	var fs = At.frame_de(At.cubre("obj:mesaN"), "plantasN-4-s", "unica", 0, {"i": 0})
	chk(J.pintor.copa_bajo_foco(fs, 4 * 16 + 15, mdn) == fs, "en la nave caben enteras")
	Datos.CAL = false
	chk(J.pintor.copa_bajo_foco(fs, 3 * 16 + 15, mdn) == fs, "sin CAL, como antes")
	Datos.CAL = true
	# 13 · las salas de antes: la de las tres carpas de regalo y la de los kits de 240 × 240, al nivel de las de 4 × 2 con sus plantas
	J.S.kc = {"p": [null, null, null, null, null, {"sid": "txoko", "prog": .3, "water": 50.0, "health": 100.0}]}
	chk(int(J.kc().niv) == 1 and J.kc_kits() == 2 and J.kc_tiene(4) and J.kc_tiene(5) and J.kc().p[J.kc_off(4)] is Dictionary and J.kc().p.size() == J.kc_off(J.kc_ns()), "la primera, pasada, en las de 4 × 2")
	var vj := []
	for i in 36:
		vj.append({"sid": "txoko", "prog": .3, "water": 50.0, "health": 100.0} if i == 30 else null)
	for i in 17:   # 18 plantas: caben 16
		vj[i] = {"sid": "txoko", "prog": .3, "water": 50.0, "health": 100.0}
	J.S.kc = {"kits": [0, 0, 0, int(J.S.day) + 1], "p": vj}
	var bco: float = J.S.banco
	var smv: int = int(J.S.seeds.get("txoko", 0))
	J.queued.clear()
	chk(int(J.kc().niv) == 1 and J.kc().kits == [-1, -1, -1, -1, 0, 0, -1] and J.kc().p[J.kc_off(4)] is Dictionary and J.kc_plantadas(4) == 8 and J.kc_plantadas(5) == 8, "la de los kits, pasada (%d + %d)" % [J.kc_plantadas(4), J.kc_plantadas(5)])
	chk(is_equal_approx(J.S.banco - bco, 2 * J.KC_KIT_VIEJO) and int(J.S.seeds.get("txoko", 0)) - smv == 2 and J.queued.has("kcmig"), "lo que no cabe, devuelto: %s € y %d semillas" % [J.S.banco - bco, int(J.S.seeds.get("txoko", 0)) - smv])
	J.queued.clear()
	J.pending.clear()
	# cada nivel rinde más por plaza que el de antes
	var gs := []
	for nv in 3:
		J.S.kc = {"niv": nv, "kits": [], "p": []}
		var cb: int = J.kc_base(nv)
		gs.append(float(J.kc_f(cb).g) * int(J.kc_Nc(cb).plazas) * int(J.kc_Nc(cb).max))
	chk(gs[0] < gs[1] and gs[1] < gs[2], "lleno, cada nivel rinde más: %s" % [gs])
	J.S.kc = {"kits": [], "p": [], "f2": 3, "m": []}
	chk(int(J.kc().niv) == 0 and J.kc().get("f2") == 3, "la reformada, igual")
	# 14 · sin CAL, nada
	Datos.CAL = false
	chk(J.puertas_int("club-muelle").is_empty() and J.sprite_local("carpaKS0") == "carpaKS0" and not J.kc_hay(), "sin CAL, ni la puerta ni la sala")
	Datos.CAL = true
	print("kaia_cult: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
