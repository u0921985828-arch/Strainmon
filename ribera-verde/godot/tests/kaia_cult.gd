# Ribera Verde (Godot) — la sala de cultivo de KAIA (kaiacult.gd, con CAL; lo pidió el usuario: «incluso molaría tener un cultivo
# finalmente en la nueva asociación de KAIA», «tiene que tener lógica con el suelo que hay al rededor y las zonas donde las colocas» y
# «como en casa, cultivo con carpas, pero más grandes de primeras, con una inversión realista, después como en la nave en esa misma
# habitación, ya con posibilidad de poner a alguien a trabajar ahí y la inversión será más grande»): la puerta de KAIA, cerrada sin la
# licencia; dentro, el pasillo y la zona de cultivo; los kits de carpa de 240 × 240 por la cuenta, que llegan al día siguiente; las
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
	chk(D.MAPS.has(C) and int(D.MAPS[C].w) == 16 and int(D.MAPS[C].h) == 10 and PZ.size() == 4 and PZ.all(func(q): return q.zona == ["floorG"] and q.si == "kc" and q.o.size() == 6), "la sala de 16 × 10, con cuatro carpas de 3 × 2 que van en la zona")
	chk(D.PUERTAS_INT["club-muelle"].any(func(q): return q.to == C and int(q.x) == 15 and int(q.y) == 1 and q.llave == "kc"), "la puerta, en la pared de KAIA")
	chk(D.MAPS["club-muelle"].o[2][14] == "jukebox" and D.MAPS["club-muelle"].o[2][15] == null and D.ORDEN_P["club-muelle"].pie.any(func(c): return int(c[0]) == 15 and int(c[1]) == 2), "la gramola, a un lado; delante de la puerta, libre")
	var cm: Dictionary = D.MAPS[C]
	chk(range(2, cm.h).all(func(y): return cm.g[y][0] == "floorC_itsaso" and cm.g[y][2] == "floorC_itsaso" and cm.g[y][3] == "floorG" and cm.g[y][15] == "floorG"), "el pasillo con el suelo del club y la zona de cultivo con el del grow")
	var kp := 0
	for q in KC.kit.l:
		kp += int(q[1])
	chk(kp == int(KC.kit.p) and kp >= 2500 and kp <= 5000 and int(KC.plazas) == 9 and int(KC.nf) == 2 and D.FOCOS[KC.foco].w == 720, "el kit, a precio de tienda: %d €, nueve plazas y dos LED de 720 W" % kp)
	chk(int(KC.f2.p) > int(KC.max) * kp and KC.f2.mesas.size() == 6 and int(D.PLANTILLA.sueldo.kaia) > 0, "la obra, más inversión que las cuatro carpas: %d €" % int(KC.f2.p))
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
	QUIERO = ["Comprar un kit", "Comprarlo"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().kits.is_empty() and dicho("tarjeta no pasa"), "sin dinero en la cuenta, no")
	J.S.banco = 100000
	QUIERO = ["Comprar un kit", "Comprarlo"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().kits.size() == 1 and is_equal_approx(float(J.S.banco), 100000.0 - kp), "comprado, por la cuenta (%d €)" % int(J.S.banco))
	chk(mundo(C, 1, 2) and m.o[3][3] == null, "hoy no está")
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][3] == "carpaKG0" and m.o[2][3] == "carpaG2" and m.o[2][5] == "carpaG2" and m.o[3][5] == "carpaG2", "mañana, montada en su sitio, 3 × 2")
	chk(J.sprite_local("carpaKG0") == "carpaKG-0", "la carpa, vacía (%s)" % J.sprite_local("carpaKG0"))
	for i in 3:
		QUIERO = ["Comprar un kit", "Comprarlo"]
		corre(func(): await J.object_action(2, 1))
	LOG = []
	TIT = []
	QUIERO = []
	corre(func(): await J.object_action(2, 1))
	chk(J.kc().kits.size() == 4 and not MENUS.back().any(func(l): return str(l).begins_with("Comprar")), "cuatro como mucho")
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][7] == "carpaKG1" and m.o[3][11] == "carpaKG2" and m.o[7][3] == "carpaKG3", "las cuatro, en su sitio")
	var v := alcance_d(C, 1, 2)
	for y in m.h:
		for x in m.w:
			if m.o[y][x] and m.o[y][x] != "carpaG2" and m.o[y][x] != "mesaKC2":
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [m.o[y][x], x, y])
	# 5 · nada encima de nada: ni las carpas ni lo de la pared
	var sl: Array = J.solapes_de(J.cajas_obj(C, m.o))
	chk(sl.is_empty(), "las cuatro carpas, sin solapes: %s" % [sl.slice(0, 3)])
	# 6 · la regla de la zona y la del solape
	chk(J.cabe_pieza(C, "kc0", 0, 4) == "zona" and J.cabe_pieza(C, "kc0", 1, 4) == "zona", "en el pasillo, no: «%s»" % J.cabe_pieza(C, "kc0", 1, 4))
	chk(J.cabe_pieza(C, "kc0", 7, 6) == "", "en la zona libre, sí: «%s»" % J.cabe_pieza(C, "kc0", 7, 6))
	chk(J.cabe_pieza(C, "kc0", 7, 4) == "solapa", "delante de otra carpa, con el tubo encima de ella, no: «%s»" % J.cabe_pieza(C, "kc0", 7, 4))
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
	J.S.coloca = {C: {"kc0": [0, 4]}}
	J.aplica_orden(C)
	chk(int(J.pos_pieza(C, "kc0")[0]) >= 3, "una carpa guardada en el pasillo vuelve a la zona (%s)" % [J.pos_pieza(C, "kc0")])
	J.S.coloca = {}
	J.MAPS[C].erase("opos")
	chk(mundo(C, 1, 2) and int(J.pos_pieza(C, "kc0")[0]) == 3 and int(J.pos_pieza(C, "kc0")[1]) == 2, "de serie, otra vez (%s)" % [J.pos_pieza(C, "kc0")])
	# 7 · plantar en las plazas de una carpa, por cualquiera de sus casillas
	J.S.seeds = {"txoko": 3}
	QUIERO = ["Plaza 1", J.strain("txoko").n]
	MENUS = []
	LOG = []
	chk(corre(func(): await J.object_action(3, 3)) and J.kc().p[0] is Dictionary and J.kc().p[0].sid == "txoko" and int(J.S.seeds.get("txoko", 0)) == 2, "plantada en la plaza 1 (%s · %s · %s)" % [MENUS.slice(-3), J.kc().p.slice(0, 2), LOG.slice(-3)])
	chk(J.sprite_local("carpaKG0") == "carpaKG-1" and J.sprite_local("carpaKG1") == "carpaKG-0", "la carpa 1, con una planta")
	QUIERO = ["Plaza 9", J.strain("txoko").n]
	chk(corre(func(): await J.object_action(5, 2)) and J.kc().p[8] is Dictionary and J.kc_plantadas(0) == 2, "por la otra punta, la misma carpa, plaza 9")
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
	chk(corre(func(): await J.object_action(4, 3)) and J.kc().p[0] == null and dicho("Cosechas"), "cosechada")
	var g1 := 0.0
	for k in J.S.buds:
		g1 += float(J.S.buds[k].g)
	chk(g1 - g0 >= 60, "con sus dos LED, una buena planta: %d g" % int(g1 - g0))
	# 10 · la obra: con plantas, no; vacía, se paga, se venden las carpas y a los días, las mesas
	LOG = []
	QUIERO = ["Reformar la sala"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().get("f2") == null and dicho("Antes, cosecha"), "con plantas en las carpas, aún no")
	J.kc().p[8] = null
	var b0: float = float(J.S.banco)
	QUIERO = ["Reformar la sala", "Hacer la obra"]
	J.kc().kits.append(int(J.S.day) + 1)   # una carpa pagada que aún no ha llegado: primero que llegue, no se vende al 40 % sin montarla
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().get("f2") == null and dicho("espera a que llegue"), "con una carpa en camino, aún no")
	J.kc().kits.pop_back()
	QUIERO = ["Reformar la sala", "Hacer la obra"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().get("f2") != null and J.kc().kits.is_empty(), "la obra, en marcha")
	chk(is_equal_approx(float(J.S.banco), b0 - int(KC.f2.p) + roundi(kp * float(KC.f2.venta) * 4)), "por la cuenta, menos lo de las carpas de segunda mano (%d €)" % int(b0 - J.S.banco))
	chk(mundo(C, 1, 2) and not m.o.any(func(r): return r.any(func(c): return c != null and (str(c).begins_with("carpa") or str(c).begins_with("mesa")))), "en obras: ni carpas ni mesas")
	LOG = []
	chk(corre(func(): await J.object_action(2, 1)) and dicho("en obras"), "el cuadro lo dice")
	J.S.day += int(KC.f2.dias)
	chk(mundo(C, 1, 2) and KC.f2.mesas.all(func(q): return m.o[int(q[1])][int(q[0])] == "mesaKC" and m.o[int(q[1])][int(q[0]) + 1] == "mesaKC2"), "las seis mesas, montadas")
	chk(m.o[3][15] == "tanqueN" and m.o[8][15] == "riegoN", "el tanque y el programador")
	sl = J.solapes_de(J.cajas_obj(C, m.o))
	chk(sl.is_empty(), "las mesas, sin solapes: %s" % [sl.slice(0, 3)])
	v = alcance_d(C, 1, 2)
	for y in m.h:
		for x in m.w:
			if m.o[y][x] and m.o[y][x] != "mesaKC2":
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [m.o[y][x], x, y])
	chk(J.pos_pieza(C, "kc0") == [3, 2] and J.piezas_ya(C).is_empty(), "sin carpas que ordenar")
	# 11 · las mesas: plantar y, sin nadie, no avanzan
	QUIERO = ["Plantar", J.strain("txoko").n]
	chk(corre(func(): await J.object_action(4, 3)) and J.kc_me(0) is Dictionary and J.kc_me(0).k.begins_with("txoko"), "plantada la mesa 1")
	chk(J.mesa_de("mesaKC", 5, 3) != null and int(J.mesa_de("mesaKC", 5, 3).fm) == 1 and J.mesa_de("mesaKC", 5, 3).foco == "led", "en el mapa, con sus plantas y su foco")
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
	chk(mundo(C, 1, 2) and J.ents.any(func(e): return e.id == "kcw"), "de pie en la sala")
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
	chk(corre(func(): await J.object_action(4, 3)) and float(J.kc_me(0).g) < gm, "te lo llevas")
	# 13 · la sala de antes (tres carpas de 4 plazas de regalo) pasa a tres kits montados con sus plantas
	J.S.kc = {"p": [null, null, null, null, null, {"sid": "txoko", "prog": .3, "water": 50.0, "health": 100.0}]}
	chk(J.kc().kits.size() == 3 and J.kc().p[10] is Dictionary and J.kc().p.size() == 36, "la de antes, pasada")
	# 14 · sin CAL, nada
	Datos.CAL = false
	chk(J.puertas_int("club-muelle").is_empty() and J.sprite_local("carpaKG0") == "carpaKG0" and not J.kc_hay(), "sin CAL, ni la puerta ni la sala")
	Datos.CAL = true
	print("kaia_cult: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
