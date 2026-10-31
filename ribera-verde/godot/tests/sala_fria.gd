# Ribera Verde (Godot) — la sala fría del sótano (salafria.gd, con CAL; lo pidió el usuario: una sala fría para las extracciones «en el
# sótano del piso», con las máquinas allí y que rindan más): la puerta (3, 1) del sótano, cerrada sin la obra; la obra por la tienda
# online (con la tarjeta, al día siguiente; en Play, con el sótano incluido); las máquinas que tienes dejan el piso y se montan en la
# sala, en su sitio, sin solaparse y al alcance; lo que se saca allí rinde FRIA.rend más; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/sala_fria.gd   → «sala_fria: N comprobaciones, 0 fallos»
#   (con -- --fotos <dir> y ventana, la captura de la sala)
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
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
	J.build_ents()
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

func puerta_sotano() -> bool:
	J.P.x = 3
	J.P.y = 2
	J.P.fx = 0
	J.P.fy = -1
	return corre(func(): await J.object_action(3, 1))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-sala-fria.json"
	Juego.AJUSTES = "user://prueba-sala-fria-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	var fotos := ""
	var a := OS.get_cmdline_user_args()
	if a.has("--fotos"):
		fotos = a[a.find("--fotos") + 1]
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	var S = J.S
	var D: Dictionary = J.D
	S.ch = maxi(int(S.ch), 6)
	S.banco = 50000
	S.money = 20000
	S.protect = false
	S.erase("fria")
	S.sot = {"d": int(S.day) - 1, "bandejas": [], "g": 0, "fr": []}
	for it in ["prensa", "tamiz", "ice", "lavadora", "estatica"]:
		S.items[it] = 1
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 0 · los datos: la sala, su puerta y la vuelta, y un rendimiento por extracción
	chk(J.MAPS.has("fria") and D.FRIA.mapa == "fria", "el mapa de la sala fría")
	chk(D.PUERTAS_INT.sotano.any(func(p): return p.to == "fria" and p.get("llave") == "fria" and int(p.x) == 3 and int(p.y) == 1), "la puerta del sótano, con su llave")
	chk(D.PUERTAS_INT.fria.any(func(p): return p.to == "sotano"), "y la de vuelta")
	chk(D.EXTR.keys().all(func(t): return D.FRIA.rend.has(t) and float(D.FRIA.rend[t]) >= 1.0), "un rendimiento por cada extracción: %s" % [D.EXTR.keys()])
	chk(D.MUEBLE_EXTR.keys().all(func(k): return D.FRIA.pos.has(k)), "un sitio por cada máquina")
	chk(int(D.FRIA.p) == D.FRIA.l.reduce(func(s, x): return s + int(x[1]), 0), "el precio, la suma de la obra")
	# 1 · sin la obra: la puerta, cerrada, y las máquinas en el piso
	var pl: Array = J.pos_pieza("home", "lavadora")
	chk(mundo("home", 3, 3) and J.MAPS.home.o[int(pl[1])][int(pl[0])] == "lavadora", "sin la obra, la lavadora en el piso: %s" % [pl])
	chk(J.pieza_ya(J.pieza_de("home", "lavadora")) if not J.pieza_de("home", "lavadora").is_empty() else true, "y en ORDENAR LA CASA")
	chk(mundo("sotano", 3, 2), "en el sótano")
	LOG = []
	chk(puerta_sotano() and S.map == "sotano" and dicho("Con una obra"), "sin la obra, la puerta no abre y lo dice: %s · %s" % [S.map, LOG])
	# 2 · la obra por la tienda online, con la tarjeta
	chk(J.fria_venta() and J.fria_precio() == int(D.FRIA.p), "en la tienda, a %d €" % J.fria_precio())
	var b0: float = S.banco
	QUIERO = [String(D.FRIA.n), "Salir"]
	chk(corre(func(): await J.tienda_online()) and S.get("fria") is Dictionary and int(S.fria.d) == int(S.day) + 1, "pedida: %s" % [S.get("fria")])
	chk(is_equal_approx(b0 - S.banco, float(D.FRIA.p)), "por la cuenta: %s" % (b0 - S.banco))
	chk(not J.fria_ya() and J.fria_item().disabled, "hoy, aún no, y no se pide otra vez")
	LOG = []
	chk(puerta_sotano() and S.map == "sotano" and dicho("mañana acaban"), "a medio hacer: %s" % [LOG])
	S.day += 1
	LOG = []
	chk(corre(func(): await J.llega_mueble()) and J.fria_ya(), "al día siguiente, hecha")
	chk(corre(func(): await J.idle()) if J.has_method("idle") else true, "el aviso")
	# 3 · las máquinas, fuera del piso y en la sala
	chk(mundo("home", 3, 3), "en casa")
	for k in D.MUEBLE_EXTR:
		chk(not J.MAPS.home.o.any(func(f): return f.has(k)), "%s, ya no en el piso" % k)
	chk(J.piezas_ya("home").all(func(P_): return str(P_.get("si", "")) != "extr"), "ni en ORDENAR LA CASA")
	chk(mundo("sotano", 3, 2) and puerta_sotano() and S.map == "fria" and J.P.x == 1 and J.P.y == 2, "con la obra, a la sala fría: %s %d,%d" % [S.map, J.P.x, J.P.y])
	var m: Dictionary = J.MAPS.fria
	for k in D.FRIA.pos:
		var q: Array = D.FRIA.pos[k]
		chk(m.o[int(q[1])][int(q[0])] == k, "%s, en su sitio de la sala" % k)
	chk(m.o[1][6] == "frioF" and m.o[3][5] == "mesaF", "el evaporador y la mesa")
	var sl: Array = J.solapes_de(J.cajas_obj("fria", m.o))
	chk(sl.is_empty(), "nada encima de nada: %s" % [sl])
	var v := alcance_d("fria", 1, 2)
	for k in D.FRIA.pos:
		var q: Array = D.FRIA.pos[k]
		chk(delante(v, int(q[0]), int(q[1])), "%s, al alcance" % k)
	chk(delante(v, 5, 3) and delante(v, 6, 1), "la mesa y el evaporador, al alcance")
	LOG = []
	chk(corre(func(): await J.object_action(6, 1)) and dicho("°C"), "A en el evaporador: %s" % [LOG])
	QUIERO = ["Nada", "Nada", "Volver"]
	chk(corre(func(): await J.object_action(1, 5)), "A en la lavadora, su menú")
	# sin las máquinas, la sala sin ellas
	S.items.erase("estatica")
	chk(mundo("fria", 1, 2) and J.MAPS.fria.o[5][5] == null, "sin la static, su sitio vacío")
	S.items.estatica = 1
	chk(mundo("fria", 1, 2) and J.MAPS.fria.o[5][5] == "staticM", "y con ella, otra vez")
	# 4 · el rendimiento en frío
	var Ei: Dictionary = D.EXTR.ice
	var r0: float = J.sale_extr(Ei, 25, 1)
	J._fria_t = "ice"
	var r1: float = J.sale_extr(Ei, 25, 1)
	J._fria_t = "charas"
	var r2: float = J.sale_extr(D.EXTR.charas, 25, 1)
	J._fria_t = ""
	chk(is_equal_approx(r1, Datos.jsround(r0 * float(D.FRIA.rend.ice) * 10) / 10.0) and r1 > r0, "el hielo rinde más en frío: %s → %s" % [r0, r1])
	chk(is_equal_approx(r2, J.sale_extr(D.EXTR.charas, 25, 1)), "el charas, igual")
	S.map = "home"
	var visto := {"t": "?"}
	var t0 = J.get("_fria_t")
	chk(t0 == "", "fuera de la extracción, sin frío")
	# las máquinas, abajo: en la mesa de la tía, solo lo que se hace a mano
	var ya_casa: Array = J.extr_ya()
	S.map = "fria"
	var ya_fria: Array = J.extr_ya()
	S.map = "home"
	chk("lava" in ya_fria and not ("lava" in ya_casa) and not ("rosin" in ya_casa) and ("charas" in ya_casa), "las máquinas, solo en la sala fría: casa %s · fría %s" % [ya_casa, ya_fria])
	# 5 · en Play, el sótano va con la obra
	Datos.PLAY = true
	S.erase("fria")
	S.erase("sot")
	chk(J.fria_venta() and J.fria_precio() == int(D.FRIA.p_play) and J.fria_item().desc.contains("sótano"), "en Play, a %d € con el sótano" % J.fria_precio())
	chk(corre(func(): await J.fria_tienda()) and S.get("sot") is Dictionary and S.get("fria") is Dictionary, "y lo habilita: %s" % [S.get("sot")])
	Datos.PLAY = false
	S.erase("fria")
	S.erase("sot")
	chk(not J.fria_venta(), "fuera de Play, sin sótano no se vende")
	# 6 · sin CAL, nada
	Datos.CAL = false
	S.fria = {"d": 0}
	chk(not J.fria_ya() and not J.fria_venta(), "sin CAL, ni hecha ni en venta")
	chk(J.pieza_ya({"si": "extr", "k": "lavadora"}), "sin CAL, las máquinas en el piso")
	Datos.CAL = true
	visto.t = ""
	if fotos != "":
		S.erase("fria")
		S.sot = {"d": 0, "bandejas": [], "g": 0, "fr": []}
		S.fria = {"d": 0}
		J.oraculo = false
		mundo("fria", 4, 3)
		for q in 3:
			await process_frame
			J.pintor.redibuja(0.0)
			for r in 4:
				await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(fotos.path_join("sala-fria.png"))
		J.oraculo = true
	print("sala_fria: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
