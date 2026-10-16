# Ribera Verde (Godot) — 1.51: el muelle de Puerto Viejo, los envíos por mar y el piso franco (lo pidió el usuario: «distribución
# a gran escala por un piso franco… un mini puerto para hacer envíos, invertir en un barco, empezando por uno pequeño»; con CAL).
#   $GODOT --headless --path godot --script res://tests/muelle.gd   → «muelle: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también muelle-<sitio>.png
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
	J.toast_box.hide()
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("muelle-%s.png" % k))
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

func espera(c: Callable) -> bool:
	var t0: float = M.reloj
	while not (c.call() and J.is_free() and J.pending.is_empty()):
		if M.reloj - t0 > 60000 or not M.paso():
			return false
	return true

func lote() -> String:
	return str(J.venta_item(J.bud_lots(1)[0]).label)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-muelle.json"
	Juego.AJUSTES = "user://prueba-muelle-ajustes.json"
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
	S.ch = 8
	S.erase("mar")
	S.erase("franco")
	S.flags.erase("koldoSms")
	S.banco = 300000
	S.money = 20000
	S.heat = 0
	S.protect = false
	S.buds = {}
	var sid: String = J.D.STRAINS.keys()[0]
	J.add_buds(sid, 9000, 24)
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
	var R: Dictionary = D.MAR
	# 0 · los datos: cada barco con su noray en el muelle y en el agua
	var mu: Dictionary = J.MAPS.muelle
	for B in R.barcos:
		chk(mu.o[10][int(B.nor)] == "noray", "el noray de %s en (%d, 10)" % [B.k, B.nor])
		chk(int(B.x) + int(B.L) <= int(mu.w), "%s cabe en el muelle" % B.k)
		for j in int(B.L):
			chk(mu.g[int(B.y)][int(B.x) + j] == "water", "%s, en el agua (%d, %d): %s" % [B.k, int(B.x) + j, B.y, mu.g[int(B.y)][int(B.x) + j]])
	for i in R.rutas.size() - 1:
		chk(float(R.rutas[i + 1].rep) >= float(R.rutas[i].rep), "las rutas, por reputación")
	chk(float(R.gran.rep) >= float(R.rutas[int(R.gran.ruta)].rep), "el último trabajo va por una ruta abierta")
	chk(int(R.gran.kg) <= int(R.barcos[1].kg), "el último trabajo cabe en el pesquero")
	# 1 · Puerto Viejo: el paso al muelle solo desde el capítulo de MAR.ch, de lado
	S.ch = int(R.ch) - 1
	entra("puerto", 30, 11)
	chk(not J.MAPS.puerto.exits.has("%d,%d" % [int(R.puerto.x), int(R.puerto.y)]), "antes del capítulo %d, sin paso" % R.ch)
	S.ch = 8
	entra("puerto", 30, 11)
	chk(J.MAPS.puerto.exits.has("%d,%d" % [int(R.puerto.x), int(R.puerto.y)]), "el paso al muelle")
	var pz: Dictionary = J.MAPS.puerto.duplicate()
	var pa: Array = D.PARADAS.puerto.a
	pz.exits = {"%d,%d" % [pa[0], pa[1]]: {}}
	var v: Dictionary = J.andable(pz, pz.o, {})
	chk(v.has("%d,%d" % [int(R.puerto.x) - 1, int(R.puerto.y)]), "se llega andando al paso desde el autobús")
	entra("puerto", int(R.puerto.x) - 3, int(R.puerto.y), "right")
	await foto(dir, "puerto")
	J.P.x = int(R.puerto.x)
	J.P.y = int(R.puerto.y)
	J.try_move("down")
	chk(S.map == "puerto", "hacia abajo no se cruza")
	J.P.x = int(R.puerto.x)
	J.P.y = int(R.puerto.y)
	J.P.moving = false
	J.try_move("right")
	chk(espera(func(): return S.map == "muelle") and J.P.x == int(R.puerto.a[0]) and J.P.y == int(R.puerto.a[1]), "a la derecha, al muelle (%s %d,%d)" % [S.map, J.P.x, J.P.y])
	J.mode = "world"
	J.P.x = 0
	J.P.y = 8
	J.P.moving = false
	J.try_move("left")
	chk(espera(func(): return S.map == "puerto") and J.P.x == 38, "y a la izquierda, a Puerto Viejo (%s %d,%d)" % [S.map, J.P.x, J.P.y])
	# 2 · el SMS de Koldo y Koldo en el muelle, que da la txalupa
	corre(func(): await J.check_story())
	chk(S.flags.get("koldoSms"), "el SMS de Koldo")
	chk(S.sms.any(func(x): return x.n == "KOLDO" and x.t.contains("muelle")), "dice dónde")
	entra("muelle", 12, 9)
	chk(J.ents.any(func(x): return x.get("id") == "koldo"), "Koldo, en el muelle")
	chk(mu.doors.has("%d,%d" % [int(R.franco.x), int(R.franco.dy)]), "la puerta del piso franco")
	J.P.x = 3
	J.P.y = 9
	LOG.clear()
	chk(corre(func(): await J.mar_noray(3)) and S.get("mar") == null, "sin Koldo, el noray no carga")
	chk(corre(func(): await J.talk_koldo()) and S.mar is Dictionary and S.mar.b == ["txalupa"], "Koldo da la txalupa")
	chk(mu.o[int(R.barcos[0].y)][int(R.barcos[0].x)] == "barcoT", "la txalupa, amarrada")
	# 3 · la puerta del piso franco, cerrada hasta el primer envío
	entra("muelle", int(R.franco.x), int(R.franco.dy) + 1)
	chk(pisa_puerta(int(R.franco.x), int(R.franco.dy), int(R.franco.x), int(R.franco.dy) + 1) and S.map == "muelle", "sin envío, el portal no abre")
	# 4 · cargar en el noray: la ruta, el lote, cuánto y zarpar
	J.mode = "world"
	var B0: Dictionary = R.barcos[0]
	var cap: int = int(B0.kg) * 1000
	QUIERO = ["Burdeos", lote(), J._kg(cap), "Zarpar"]
	var g0: float = J.stock_franco() + S.buds[sid].g
	chk(corre(func(): await J.mar_noray(int(B0.nor))) and S.mar.env.size() == 1, "zarpa la txalupa: %s" % [S.mar.env])
	var en: Dictionary = S.mar.env[0] if S.mar.env.size() else {}
	chk(int(en.get("g", 0)) == cap and absf(S.buds[sid].g - (g0 - cap)) < .01, "se lleva %s del lote (%s)" % [J._kg(cap), en.get("g")])
	chk(int(en.get("d", 0)) == S.day + int(B0.dias), "llega a los %d días" % B0.dias)
	var esp: int = Datos.jsround(J.precio_mayor(24) * J.calidad(S.buds[sid]) * 1.5 * cap)
	chk(absi(int(en.get("e", 0)) - esp) <= 1, "lo que pagan: %s (%d)" % [en.get("e"), esp])
	QUIERO = []
	LOG.clear()
	chk(corre(func(): await J.mar_noray(int(B0.nor))) and " ".join(LOG).contains("en el mar"), "en el mar, no carga otra vez")
	# 5 · la llegada: transferencia de la conservera, reputación y Gorka
	en.mal = false
	var b0: float = S.banco
	S.day = int(en.d)
	LOG.clear()
	chk(corre(func(): J.mar_dia()) and S.mar.env.is_empty(), "llega")
	chk(absf(S.banco - b0 - float(en.e)) < 1, "a la cuenta: %s" % (S.banco - b0))
	chk(int(S.mar.paso) == 1 and float(S.mar.rep) >= 3 and absf(float(S.mar.kg) - 3) < .01, "reputación y kilos: %s" % [S.mar])
	chk(" ".join(LOG).contains("Gorka"), "el SMS de Gorka")
	chk(S.mar.ped is Dictionary, "y el pedido de la semana")
	# 6 · el piso franco: alquilar, el alijo, el reparto y la redada
	entra("muelle", int(R.franco.x), int(R.franco.dy) + 1)
	chk(pisa_puerta(int(R.franco.x), int(R.franco.dy), int(R.franco.x), int(R.franco.dy) + 1) and S.map == "franco", "ya abre el portal: %s" % S.map)
	J.mode = "world"
	J.build_ents()
	chk(not J.ents.any(func(x): return x.get("id") == "gorka"), "sin alquilar, no hay nadie")
	var m0: float = S.money
	QUIERO = ["Alquilar"]
	chk(corre(func(): await J.talk_gorka()) and S.franco is Dictionary and absf(m0 - S.money - float(D.FRANCO.alq)) < 1, "alquilado por %s" % Datos.eur(D.FRANCO.alq))
	J.build_ents()
	chk(J.ents.any(func(x): return x.get("id") == "gorka"), "Gorka, en el piso")
	var mal: Array = At.accesos(J, "franco").filter(func(t): return not t.begins_with("crate"))
	chk(mal.is_empty(), "en el piso franco se llega a todo: %s" % [mal])
	var vv: Dictionary = J.andable(J.MAPS.franco, J.MAPS.franco.o, {})
	chk(vv.has("1,3") or vv.has("2,3"), "se llega a las cajas del alijo")
	QUIERO = [lote(), "2 kg"]
	chk(corre(func(): await J.object_action(1, 2)) and absf(J.stock_franco() - 2000) < .01, "2 kg al alijo: %s" % J.stock_franco())
	await foto(dir, "franco")
	var c0: int = int(S.franco.caja)
	S.franco.r = S.day + 30
	chk(corre(func(): J.franco_dia()) and absf(J.stock_franco() - (2000 - int(D.FRANCO.dia[0]))) < .01 and int(S.franco.caja) > c0, "reparte %s al día: caja %s" % [J._kg(int(D.FRANCO.dia[0])), S.franco.caja])
	var esp2: int = Datos.jsround(J.precio_mayor(24) * J.calidad(S.buds[sid]) * float(D.FRANCO.px) * int(D.FRANCO.dia[0]) * (1 - float(D.FRANCO.com)))
	chk(absi(int(S.franco.caja) - esp2) <= 2, "lo que deja: %s (%d)" % [S.franco.caja, esp2])
	m0 = S.money
	var cj: int = int(S.franco.caja)
	QUIERO = ["Recoger"]
	chk(corre(func(): await J.talk_gorka()) and int(S.franco.caja) == 0 and absf(S.money - m0 - cj) < 1, "recoger la caja")
	S.franco.cal = 95.0
	LOG.clear()
	chk(corre(func(): J.franco_dia()) and J.stock_franco() == 0 and float(S.franco.cal) == float(D.FRANCO.cal.vuelve), "la redada vacía el alijo")
	chk(" ".join(LOG).contains("Han entrado"), "el SMS de la redada")
	S.franco.r = S.day
	S.money = 0
	S.caja = null
	var fr := false
	for i in 4:
		corre(func(): J.franco_dia())
		S.day += 1
		if S.get("franco") == null:
			fr = true
			break
	chk(fr, "sin pagar el alquiler, se pierde el piso")
	S.money = 20000
	# 7 · el pedido de la semana, con prima
	S.mar.ped = {"r": 0, "g": 500, "thc": 20, "d": S.day + 7}
	entra("muelle", int(B0.nor), 9)
	QUIERO = ["Burdeos", lote(), "500 g", "Zarpar"]
	chk(corre(func(): await J.mar_noray(int(B0.nor))) and S.mar.env.size() == 1 and S.mar.env[0].ped and S.mar.ped == null, "el pedido, cumplido: %s" % [S.mar.env])
	if S.mar.env.size():
		var e2: Dictionary = S.mar.env[0]
		var esp3: int = Datos.jsround(J.precio_mayor(24) * J.calidad(S.buds[sid]) * 1.5 * 500 * float(R.ped.bonus))
		chk(absi(int(e2.e) - esp3) <= 1, "con la prima: %s (%d)" % [e2.e, esp3])
		e2.mal = true
		var h0: int = int(S.heat)
		b0 = S.banco
		S.day = int(e2.d)
		LOG.clear()
		corre(func(): J.mar_dia())
		chk(S.banco == b0 and int(S.heat) == h0 + int(R.calor) and " ".join(LOG).contains("patrullera"), "la patrullera: sin pago y con calor")
	# 8 · comprar un barco
	b0 = S.banco
	QUIERO = ["Comprar un barco", "El pesquero", "Sí"]
	chk(corre(func(): await J.talk_koldo()) and "pesquero" in S.mar.b and absf(b0 - S.banco - float(R.barcos[1].p)) < 1, "el pesquero, por transferencia")
	entra("muelle", 12, 9)
	chk(mu.o[int(R.barcos[1].y)][int(R.barcos[1].x)] == "barcoP" and mu.o[int(R.barcos[1].y)][int(R.barcos[1].x) + 1] == "barcoP2", "el pesquero, amarrado")
	# 9 · el último trabajo
	S.mar.rep = float(R.gran.rep)
	QUIERO = ["El último trabajo"]
	chk(corre(func(): await J.talk_koldo()) and S.mar.get("gr"), "Koldo cuenta el último trabajo")
	J.add_buds(sid, 12000, 24)
	var B1: Dictionary = R.barcos[1]
	QUIERO = [R.rutas[int(R.gran.ruta)].n, lote(), J._kg(int(R.gran.kg) * 1000), "Zarpar"]
	S.heat = 100
	chk(corre(func(): await J.mar_noray(int(B1.nor))) and S.mar.env.size() == 1 and S.mar.env[0].gr and not S.mar.env[0].mal, "zarpa el último trabajo, sin patrullera: %s" % [S.mar.env])
	b0 = S.banco
	if S.mar.env.size():
		S.day = int(S.mar.env[0].d)
		var ee: float = float(S.mar.env[0].e)
		LOG.clear()
		corre(func(): J.mar_dia())
		chk(int(S.mar.fin) == S.day and absf(S.banco - b0 - ee - float(R.gran.premio)) < 1, "el muelle es tuyo: %s" % (S.banco - b0))
		chk(" ".join(LOG).contains("orgullosa"), "el SMS del final")
	QUIERO = []
	chk(corre(func(): await J.talk_koldo()) and not LOG.is_empty(), "Koldo, después")
	# 10 · la flota entera, en el muelle
	S.mar.b = ["txalupa", "pesquero", "atunero"]
	S.heat = 0
	entra("muelle", 12, 9)
	mal = At.accesos(J, "muelle").filter(func(t): return not t.begins_with("barco"))
	chk(mal.is_empty(), "en el muelle se llega a todo: %s" % [mal])
	for B in R.barcos:
		chk(mu.o[int(B.y)][int(B.x)] == B.o, "%s, amarrado" % B.k)
	await foto(dir, "muelle")
	entra("muelle", 27, 9, "down")
	await foto(dir, "muelle-atunero")
	print("muelle: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
