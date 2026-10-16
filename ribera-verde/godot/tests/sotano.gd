# Ribera Verde (Godot) — 1.51: el sótano de casa, el bajo grande de Txomin y las puertas de dentro (lo pidió el usuario: «habilitar
# el sótano de la casa… una puerta en la casa, luego un mapa pequeño como un mini pasillito», «el bajo… más grande y que se cultive como
# la nave», y en el taller y en la nave, puertas a la habitación y al despacho; con CAL).
#   $GODOT --headless --path godot --script res://tests/sotano.gd   → «sotano: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también sotano-<sitio>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const At = preload("res://tests/atrezo.gd")

var J
var M
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	if q == "<B>":
		M.timeout(func(): J.press("B"), 5)
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

func foto(dir: String, k: String) -> void:
	if dir == "":
		return
	J.oraculo = false
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("sotano-%s.png" % k))
	J.oraculo = true

func entra(mapa: String, x: int, y: int, dir := "up") -> void:
	J.enter_map(mapa, x, y, dir)
	J.build_ents()
	J.mode = "world"

func pisa_puerta(x: int, y: int, fx: int, fy: int) -> bool:
	var P = J.P
	P.x = x
	P.y = y
	P.fx = fx
	P.fy = fy
	var d = J.MAPS[J.S.map].doors.get("%d,%d" % [x, y])
	if d == null:
		return false
	return corre(func(): await J.entra_local(d))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-sotano.json"
	Juego.AJUSTES = "user://prueba-sotano-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	S.ch = maxi(int(S.ch), 6)
	S.erase("setas")
	S.erase("sot")
	S.banco = 50000
	S.money = 20000
	S.protect = false
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
	var D: Dictionary = J.D
	# 0 · los datos: cada puerta lleva a un sitio con otra puerta que vuelve a la casilla de delante
	for mk in D.PUERTAS_INT:
		chk(J.MAPS.has(mk), "mapa %s" % mk)
		for p in D.PUERTAS_INT[mk]:
			chk(J.MAPS.has(p.to), "%s → %s" % [mk, p.to])
			var vuelta: Array = D.PUERTAS_INT.get(p.to, []).filter(func(q): return q.to == mk and int(q.tx) == int(p.x) and int(q.ty) == int(p.y) + 1)
			chk(vuelta.size() == 1, "%s (%d, %d): la puerta de vuelta desde %s" % [mk, p.x, p.y, p.to])
	# 1 · la puerta del piso, el pasillo y la escalera cerrada sin la obra
	entra("home", 3, 3)
	chk(J.MAPS.home.o[1][3] == "puertaI", "la puerta del pasillo, en el dormitorio: %s" % J.MAPS.home.o[1][3])
	chk(J.MAPS.home.o[2][3] == null, "delante, libre")
	chk(J.reserva_orden("home").has([3, 2]), "ordenar no la tapa")
	await foto(dir, "casa")
	J.P.x = 3
	J.P.y = 2
	chk(corre(func(): await J.object_action(3, 1)) and S.map == "pasillo" and J.P.x == 1 and J.P.y == 2, "A en la puerta: al pasillo (%s %d,%d)" % [S.map, J.P.x, J.P.y])
	J.mode = "world"
	chk(J.MAPS.pasillo.g[2][6] == "bajS1" and J.MAPS.pasillo.g[3][6] == "bajS2", "el hueco de la escalera")
	await foto(dir, "pasillo")
	LOG.clear()
	chk(pisa_puerta(6, 2, 5, 2) and S.map == "pasillo" and J.P.x == 5, "sin obra, la escalera no baja: %s %d" % [S.map, J.P.x])
	chk(LOG.any(func(t): return "obra" in t), "y lo dice: %s" % [LOG])
	# 2 · la obra por la tienda online, al día siguiente
	QUIERO = ["Habilitar el sótano", "Salir"]
	var b0: float = S.banco
	chk(corre(func(): await J.tienda_online()), "la tienda online")
	chk(S.get("sot") is Dictionary and int(S.sot.d) == S.day + 1 and S.banco == b0 - float(D.SOTANO.obra.p), "pedida: %s · %s" % [S.get("sot"), b0 - S.banco])
	chk(not J.sot_ya(), "hoy, aún no")
	S.day += 1
	LOG.clear()
	J.llega_mueble()
	chk(J.sot_ya(), "mañana, hecha")
	chk(corre(func(): await J.idle()) if J.has_method("idle") else true, "los avisos")
	chk(pisa_puerta(6, 3, 5, 3) and S.map == "sotano" and J.P.x == 4 and J.P.y == 5, "con la obra, al sótano: %s %d,%d" % [S.map, J.P.x, J.P.y])
	J.mode = "world"
	chk(J.MAPS.sotano.exits.has("4,6") and J.MAPS.sotano.g[6][4] == "escS", "los peldaños de subida")
	chk(J.es_sot() and J.SL() == S.sot and J.n_baldas() == 3 and J.max_bandejas() == int(D.SOTANO.max), "el sótano: %d baldas, %d bandejas" % [J.n_baldas(), J.max_bandejas()])
	chk(J.light_cfg() != null if J.has_method("light_cfg") else true, "su bombilla")
	# 3 · las bandejas, de Txomin
	entra("callejon", 17, 9)
	QUIERO = ["Para el sótano", "Comprar bandeja", "Nada"]
	chk(corre(func(): await J.talk_txomin()), "Txomin")
	chk(S.sot.bandejas.size() == 1 and S.get("setas") == null and not J._SOT, "una bandeja para el sótano y ningún bajo: %s" % [S.sot])
	chk(J.SL() == null, "fuera del sótano, sin bajo")
	entra("sotano", 4, 5)
	var Z: Dictionary = D.SETAS
	S.sot.bandejas[0].d = S.day - int(Z.colon) - int(Z.fruto)
	chk(J.bandejas_balda(0).size() == 1 and J.fase_seta(S.sot.bandejas[0]) == "lista", "en la balda, lista: %s" % [J.bandejas_balda(0)])
	J.SETAS_V = {"i": 0}
	chk(J.rects_bajo(J.SETAS_V).size() > 50, "a la vista")
	J.SETAS_V = null
	QUIERO = ["Recoger"]
	chk(corre(func(): await J.bajo_menu("")), "recoger")
	chk(S.sot.bandejas.is_empty() and S.sot.fr.size() == 1, "a secar: %s" % [S.sot.fr])
	var gfr: int = int(S.sot.fr[0].g)
	for d in int(D.SETAS_PRO.seca):
		S.day += 1
		J.setas_dia()
	chk(int(S.sot.g) == gfr and S.sot.fr.is_empty(), "seco en el sótano: %s" % [S.sot])
	entra("callejon", 17, 9)
	QUIERO = ["Para el sótano", "Venderle", "Nada"]
	var m0: float = S.money
	chk(corre(func(): await J.talk_txomin()), "venderle lo del sótano")
	chk(S.money > m0 and float(S.sot.g) < 1, "vendido: %s" % (S.money - m0))
	# la redada de casa se lo lleva
	S.sot.bandejas = [{"d": S.day, "hum": 100, "v": "txuria"}]
	S.sot.g = 30
	entra("home", 3, 3)
	LOG.clear()
	chk(corre(func(): await J.raid_event()), "redada")
	chk(S.sot.bandejas.is_empty() and float(S.sot.g) == 0, "se lleva el sótano: %s" % [S.sot])
	chk(LOG.any(func(t): return "sótano" in t), "y lo dice")
	# vuelta: del sótano al pasillo y a casa
	entra("sotano", 4, 6, "down")
	J.P.x = 4
	J.P.y = 6
	chk(corre(func(): await J.warp(J.MAPS.sotano.exits["4,6"])) and S.map == "pasillo", "subir")
	J.P.x = 1
	J.P.y = 2
	chk(corre(func(): await J.object_action(1, 1)) and S.map == "home" and J.P.x == 3 and J.P.y == 2, "y a casa")
	# 4 · el bajo grande de Txomin, con su ayudante
	entra("callejon", 17, 9)
	QUIERO = ["El bajo", "Alquilarlo"]
	chk(corre(func(): await J.talk_txomin()) and S.get("setas") is Dictionary, "alquilar el bajo")
	entra("setas", 5, 4)
	chk(int(J.MAPS.setas.w) == 18 and J.n_baldas() == 9 and J.max_bandejas() == 18, "el bajo, más grande: %d × %d, %d baldas" % [J.MAPS.setas.w, J.MAPS.setas.h, J.n_baldas()])
	chk(J.balda_i(2) == 2 and J.balda_i(11) == 3 and J.balda_i(16) == 8, "las estanterías, en orden")
	chk(J.MAPS.setas.o[2][3] == "armS" and J.MAPS.setas.o[5][7] == "mesaS", "el armario y la mesa, donde estaban")
	var V := {"i": 4}
	chk(J.mueve_bajo(V, "right") and V.i == 6, "a la segunda estantería de la derecha: %s" % V)
	var mx := {"i": 16}
	chk(J.mueve_bajo(mx, "right") == false, "la última no sigue")
	var rr: Array = J.rects_bajo({"i": 12})
	chk(rr.filter(func(r): return r is Array and r.size() == 5 and r[4] == "#f8d040" and r[2] == 4).size() == 1, "la página que se ve, marcada")
	entra("callejon", 17, 9)
	QUIERO = ["El bajo"] + ["Comprar bandeja"].duplicate()
	for k in 7:
		QUIERO += ["Comprar bandeja"]
	QUIERO += ["Nada"]
	chk(corre(func(): await J.talk_txomin()), "ocho bandejas")
	chk(S.setas.bandejas.size() == 8, "caben más de seis: %d" % S.setas.bandejas.size())
	QUIERO = ["El bajo", "Contratar", "Contratarlo", "Nada"]
	chk(corre(func(): await J.talk_txomin()) and S.setas.get("ay") != null, "el ayudante: %s" % S.setas.get("ay"))
	chk(J.recibo_setas() == D.RECIBO.dias * D.SETAS.dia + D.SETAS_AY.sueldo, "cobra con el recibo")
	for i in 4:
		S.setas.bandejas[i].d = S.day - int(Z.colon) - int(Z.fruto)
	for b in S.setas.bandejas:
		b.hum = 40
	S.day += 1
	S.setas.r = S.day + 99
	J.setas_dia()
	chk(S.get("setas") != null and S.setas.bandejas.size() == 4 and S.setas.get("fr", []).size() == 4, "recoge lo listo: %d bandejas, %d a secar" % [S.setas.bandejas.size() if S.get("setas") else -1, S.setas.get("fr", []).size() if S.get("setas") else -1])
	chk(S.setas.bandejas.all(func(b): return b.get("mala") or b.hum >= 100 - Z.seca), "y pulveriza: %s" % [S.setas.bandejas.map(func(b): return b.hum)])
	entra("setas", 5, 4)
	chk(J.ents.any(func(x): return x.id == "setero"), "en el bajo, trabajando")
	chk(J.MAPS.setas.o[int(D.SETAS_AY.mesa[1])][int(D.SETAS_AY.mesa[0])] == "mesita", "su mesa")
	var mal := At.accesos(J, "setas")
	chk(mal.is_empty(), "en el bajo se llega a todo: %s" % [mal])
	await foto(dir, "bajo")
	J.SETAS_V = {"i": 8}
	await foto(dir, "bajo-vista")
	J.SETAS_V = null
	QUIERO = ["Seguir así"]
	var st = null
	for x in J.ents:
		if x.id == "setero":
			st = x
	chk(st != null and corre(func(): await J.npc_talk(st.def)), "hablar con Unai")
	# 5 · el taller: el cuartucho, detrás de su puerta
	if not S.loc.has("valde"):
		S.loc["valde"] = {}
	J.neg_o("valde") if J.has_method("neg_o") else null
	entra("loc-valde", 7, 8)
	var tv: Dictionary = J.MAPS["loc-valde"]
	chk(tv.o[1][18] == "puertaM", "la puerta del cuartucho")
	var resto := []
	for y in int(tv.h):
		for x in int(tv.w):
			if tv.o[y][x] in ["tabique", "bedT", "bedB", "mesaC", "mesita", "armR"]:
				resto.append([x, y, tv.o[y][x]])
	chk(resto.is_empty(), "el taller, sin la habitación: %s" % [resto])
	mal = At.accesos(J, "loc-valde")
	chk(mal.is_empty(), "en el taller se llega a todo: %s" % [mal])
	await foto(dir, "taller")
	J.P.x = 18
	J.P.y = 2
	chk(corre(func(): await J.object_action(18, 1)) and S.map == "cuarto-t", "al cuartucho")
	J.build_ents()
	mal = At.accesos(J, "cuarto-t")
	chk(mal.is_empty(), "en el cuartucho se llega a todo: %s" % [mal])
	chk(corre(func(): await J.object_action(3, 2)) and LOG.size(), "la mesa del cuartucho")
	await foto(dir, "cuarto")
	J.P.x = 1
	J.P.y = 2
	chk(corre(func(): await J.object_action(1, 1)) and S.map == "loc-valde" and J.P.x == 18, "y al taller")
	# 6 · la nave: el despacho y la habitación
	entra("nave", 6, 6)
	var nv: Dictionary = J.MAPS.nave
	chk(nv.o[1][12] == "puertaM" and nv.o[1][14] == "puertaM", "las dos puertas de la nave")
	chk(not nv.o[2].has("escritorio") and not (nv.o[6][17] == "bedT"), "ni escritorio ni camastro en la nave")
	chk(J.reserva_orden("nave").has([12, 2]) and J.reserva_orden("nave").has([14, 2]), "ordenar la nave no las tapa")
	mal = At.accesos(J, "nave").filter(func(t): return not t.begins_with("filtroN"))   # los filtros cuelgan de la pared, no se usan
	chk(mal.is_empty(), "en la nave se llega a todo: %s" % [mal])
	await foto(dir, "nave")
	J.P.x = 12
	J.P.y = 2
	chk(corre(func(): await J.object_action(12, 1)) and S.map == "nave-d", "al despacho")
	J.build_ents()
	mal = At.accesos(J, "nave-d")
	chk(mal.is_empty(), "en el despacho se llega a todo: %s" % [mal])
	QUIERO = ["<B>"]
	chk(corre(func(): await J.object_action(3, 2)), "el escritorio, en el despacho")
	await foto(dir, "despacho")
	J.P.x = 1
	J.P.y = 2
	chk(corre(func(): await J.object_action(1, 1)) and S.map == "nave" and J.P.x == 12, "a la nave")
	J.P.x = 14
	chk(corre(func(): await J.object_action(14, 1)) and S.map == "nave-h", "a la habitación")
	J.build_ents()
	mal = At.accesos(J, "nave-h")
	chk(mal.is_empty(), "en la habitación se llega a todo: %s" % [mal])
	await foto(dir, "habitacion")
	J.P.x = 1
	J.P.y = 2
	chk(corre(func(): await J.object_action(1, 1)) and S.map == "nave" and J.P.x == 14, "y vuelta")
	for k in ["pasillo", "sotano"]:
		entra(k, 4, 2 if k == "pasillo" else 5)
		mal = At.accesos(J, k)
		chk(mal.is_empty(), "%s: se llega a todo: %s" % [k, mal])
	print("sotano: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
