# Ribera Verde (Godot) — 1.45: los negocios por dentro (lo pidió el usuario: «que tú puedas acceder a ese sitio y controlarlo desde
# ahí… tanto el taller como los demás negocios»; «un cuartucho donde haya una cama…»; «en el club… comprar como vender extracciones y
# diferentes tipos de hierba… a todos los mercados»): la puerta de cada local en la calle (gate neg:k) y su interior (loc-<k>) con la
# caja, el género, la fregona, las mejoras y la gente; lo que vende cada mañana según cómo lo cuides (recibos_dia); la cama del
# cuartucho del taller y el camastro de la nave; el almacén del club; y los mercados (club, Iñaki, lonja) que compran y venden.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla valdehierro.
#   $GODOT --headless --path godot --script res://tests/negocios.gd   → «negocios: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también neg-<k>.png y neg-calle-<k>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var MENUS := []
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
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() and not labels.has("TENGO 18 O MÁS") else ""
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
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func llega(mapa: String, de: Array, a: Array) -> bool:
	var m: Dictionary = J.MAPS[mapa]
	var v := {"%d,%d" % de: true}
	var q := [de]
	while q.size():
		var c: Array = q.pop_front()
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			var nx: int = c[0] + d[0]
			var ny: int = c[1] + d[1]
			if nx == a[0] and ny == a[1]:
				return true
			var kk := "%d,%d" % [nx, ny]
			if not v.has(kk) and nx >= 0 and ny >= 0 and nx < int(m.w) and ny < int(m.h) and J.pisable(m, nx, ny) and not m.o[ny][nx]:
				v[kk] = true
				q.append([nx, ny])
	return false

func foto(dir: String, k: String) -> void:
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("neg-%s.png" % k))

func alquila(k: String, mj := 0) -> void:
	J.S.loc[k] = {"r": J.S.day + 60, "caja": 0, "dia": 0, "tot": 0}
	J.neg_o(k).mj = mj

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-negocios.json"
	Juego.AJUSTES = "user://prueba-negocios-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "valdehierro":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	var D: Dictionary = J.D
	var NG: Dictionary = D.NEGOCIO
	S.loc = {}
	S.banco = 200000
	S.money = 20000
	S.heat = 0
	S.ch = maxi(int(S.ch), 5)
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
		for k in NG.k:
			alquila(k, 2)
			var L: Dictionary = D.LOCALES[k]
			var N: Dictionary = NG.k[k]
			J.enter_map(L.map, int(N.x), int(N.dy) + 3, "up")
			J.mode = "world"
			await foto(dir, "calle-" + k)
			await foto(dir, "calle-" + k)
			J.enter_map("loc-" + k, int(N.mat[0]), int(N.h) - 2, "up")
			J.mode = "world"
			await foto(dir, k)
			await foto(dir, k)
		S.loc = {}
		J.set_process(true)
	J.enter_map("valdehierro", 23, 8, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · la puerta de cada local en su calle, con gate neg:k; sin Datos.CAL, la calle como estaba
	for k in NG.k:
		var L: Dictionary = D.LOCALES[k]
		var N: Dictionary = NG.k[k]
		Datos.CAL = false
		J.enter_map(L.map, int(N.x), int(N.dy) + 1, "up")
		var m: Dictionary = J.MAPS[L.map]
		chk(not m.doors.has("%d,%d" % [int(N.x), int(N.dy)]), "%s: sin CAL, sin puerta" % k)
		Datos.CAL = true
		J.enter_map(L.map, int(N.x), int(N.dy) + 1, "up")
		for j in (2 if N.ancha else 1):
			var dd = m.doors.get("%d,%d" % [int(N.x) + j, int(N.dy)])
			chk(dd is Dictionary and dd.gate == "neg:" + k and dd.to == "loc-" + k and m.g[int(N.dy)][int(N.x) + j] == N.tile, "%s: la puerta %d %s" % [k, j, dd])
		chk(m.blds.any(func(b): return b.get("doorX") == int(N.x) and b.get("puerta") == N.puerta), "%s: el edificio con su puerta" % k)
		# la puerta, la de la fachada: cerrada, sus píxeles son los de la base en el mismo sitio (estilo, tamaño y lugar); abierta, distinta
		for b in m.blds:
			if b.get("doorX") == int(N.x) and Atlas.ok:
				var fb = Atlas.frame_de("edificio-" + b.get("fachada", b.id), "base", "unica", 0, {"i": 0})
				var f0 = Atlas.frame_de("edificio-" + N.puerta, "puerta", "unica", 0, {"i": 0})
				var f3 = Atlas.frame_de("edificio-" + N.puerta, "puerta", "unica", 0, {"i": -1})
				var ox: int = int(N.x) * 16 - 8 + int(N.dx) - int(b.x0) * 16
				var oy: int = (int(N.dy) + 1) * 16 - 32 - int(b.y0) * 16
				var igual: bool = fb != null and f0 != null and ox >= 0 and ox + f0.c.get_width() <= fb.c.get_width()
				var dif := 0
				if igual:
					for yy in f0.c.get_height():
						for xx in f0.c.get_width():
							if f0.c.get_pixel(xx, yy) != fb.c.get_pixel(ox + xx, oy + yy):
								igual = false
							if f3 and f3.c.get_pixel(xx, yy) != f0.c.get_pixel(xx, yy):
								dif += 1
				chk(igual and dif > 60, "%s: la puerta cerrada calca la fachada en (%d, %d) y se abre (%d px)" % [k, ox, oy, dif])
		chk(llega(L.map, [int(N.x), int(N.dy) + 1], [int(N.x), int(N.dy)]), "%s: se llega a la puerta" % k)
		chk(llega(L.map, [int(N.x), int(N.dy) + 1], [int(L.x), int(L.y)]), "%s: se llega al rótulo" % k)
	# 2 · cerrado si no es tuyo; abierto si lo es
	J.enter_map("valdehierro", 23, 7, "up")
	var dv: Dictionary = J.MAPS.valdehierro.doors["23,7"]
	LOG = []
	chk(corre(func(): await J.entra_local(dv)) and S.map == "valdehierro" and LOG.any(func(t): return t.contains("SE TRASPASA")), "cerrado: %s %s" % [S.map, LOG])
	alquila("valde")
	J.enter_map("valdehierro", 23, 7, "up")
	chk(corre(func(): await J.entra_local(dv)) and S.map == "loc-valde", "dentro del taller: %s" % S.map)
	# 3 · por dentro: con las dos mejoras, se llega a todo desde la entrada, y la gente está
	for k in NG.k:
		alquila(k, 2)
		var N: Dictionary = NG.k[k]
		J.enter_map("loc-" + k, int(N.mat[0]), int(N.h) - 2, "up")
		var m: Dictionary = J.MAPS["loc-" + k]
		var de := [int(N.mat[0]), int(N.h) - 2]
		var obs: Array = N.o.duplicate()
		for q in N.mj:
			obs += q.o
		for q in obs:
			chk(m.o[int(q[1])][int(q[0])] == q[2], "%s: %s en %s" % [k, q[2], q])
			if q[2] != "tabique":   # la cama se coge por los pies (bedB)
				chk(llega("loc-" + k, de, [int(q[0]), int(q[1]) + (1 if q[2] == "bedT" else 0)]), "%s: se llega a %s" % [k, q])
		chk(m.o[int(N.emp[4])][int(N.emp[3])] == null and llega("loc-" + k, de, [int(N.emp[3]), int(N.emp[4])]), "%s: la gente" % k)
		chk(J.npc_cond({"id": N.emp[0]}) if J.has_method("npc_cond") else true, "%s: %s sale" % [k, N.emp[0]])
		alquila(k, 0)
		J.enter_map("loc-" + k, int(N.mat[0]), int(N.h) - 2, "up")
		for q in N.mj[0].o:
			chk(m.o[int(q[1])][int(q[0])] != q[2] or N.o.any(func(r): return r[0] == q[0] and r[1] == q[1]), "%s: sin mejora, sin %s" % [k, q])
		S.loc.erase(k)
	# 4 · la caja: meter efectivo (hasta el tope), el género, una mejora; la fregona
	alquila("valde")
	J.enter_map("loc-valde", 7, 7, "up")
	var o: Dictionary = S.loc.valde
	var N: Dictionary = NG.k.valde
	var L: Dictionary = D.LOCALES.valde
	var m0: int = S.money
	QUIERO = ["Meter efectivo", Datos.eur(J.neg_tope("valde")), "Nada"]
	chk(corre(func(): await J.obj_local(9, 5, "cajaL")), "caja bloqueada")
	chk(o.caja == J.neg_tope("valde") and m0 - S.money == int(L.tope) and int(o.dia) == int(S.day), "meter: %s %d" % [o, m0 - S.money])
	var b0: float = S.banco
	QUIERO = ["Reponer género", "Pedirlo", "Nada"]
	chk(corre(func(): await J.obj_local(9, 5, "cajaL")), "género bloqueado")
	chk(int(o.st) == int(NG.st) and b0 - S.banco == int(N.gen) * int(NG.st), "género: %s %d" % [o.st, b0 - S.banco])
	b0 = S.banco
	QUIERO = ["Pedirlo"]
	chk(corre(func(): await J.obj_local(1, 2, "recambT")), "género por el estante")
	chk(int(o.st) == 2 * int(NG.st), "género del estante: %s" % o.st)
	QUIERO = ["Mejora", "Hacerla", "Nada"]
	b0 = S.banco
	chk(corre(func(): await J.obj_local(9, 5, "cajaL")), "mejora bloqueada")
	chk(int(o.mj) == 1 and b0 - S.banco == int(N.mj[0].p) and J.MAPS["loc-valde"].o[6][2] == "elevT", "mejora: %s %d" % [o.mj, b0 - S.banco])
	chk(J.neg_tope("valde") == roundi(float(L.tope) * (1 + float(NG.mjT))), "el tope con mejora")
	o.cu = 30
	var t0: int = int(S.min) + 1440 * int(S.day)
	QUIERO = ["Limpiar"]
	chk(corre(func(): await J.obj_local(0, 7, "fregona")), "fregona bloqueada")
	chk(int(o.cu) == 100 and int(S.min) + 1440 * int(S.day) - t0 == int(NG.limpia), "limpio: %s" % o.cu)
	LOG = []
	QUIERO = ["La caja", "Las cuentas", "Nada"]
	chk(corre(func(): await J.talk_neg("valde")) and LOG.any(func(t): return t.contains("Ayer hicimos")) and LOG.any(func(t): return t.contains("Ayer vendió")), "la gente y las cuentas: %s" % [LOG])
	chk(corre(func(): await J.obj_local(2, 3, "elevT2")) and LOG[-1] == N.txt.elevT, "la mitad del elevador")
	# 5 · lo que vende cada mañana: cuidado > descuidado > sin género; a la cuenta, con lo lavado
	o.cu = 100
	var v1: int = J.neg_venta("valde")
	o.cu = 0
	var v2: int = J.neg_venta("valde")
	var st0: int = int(o.st)
	o.st = 0
	var v3: int = J.neg_venta("valde")
	o.st = st0
	chk(v1 > v2 and v2 > v3 and v3 > 0, "cuidado: %d %d %d" % [v1, v2, v3])
	var a := []
	for d in 40:
		S.day += d
		a.append(J.neg_venta("valde"))
		S.day -= d
	chk(a.min() >= roundi(v2 * (1 - NG.azar)) - 1 and a.max() <= roundi(v2 * (1 + NG.azar)) + 1 and a.min() != a.max(), "el azar: %s" % [a])
	o.cu = 100
	o.r = S.day + 30
	b0 = S.banco
	var vt: int = J.neg_venta("valde")
	var caja: float = o.caja
	J.recibos_dia()
	chk(int(o.ay) == vt and int(o.vt) == vt and S.banco - b0 == vt + roundi(caja * (1 - L.com)) and int(o.cu) == 100 - int(NG.cu[1]) and int(o.st) == st0 - 1, "la mañana: %s %d" % [o, S.banco - b0])
	chk(S.mov.any(func(x): return str(x).contains("Ventas · " + L.n)), "el movimiento de ventas")
	Datos.CAL = false
	b0 = S.banco
	o.caja = 0
	J.recibos_dia()
	chk(S.banco == b0, "sin CAL, no vende")
	Datos.CAL = true
	# 6 · dormir en el cuartucho del taller, cambiarse en su armario
	var d0: int = S.day
	QUIERO = ["Dormir"]
	chk(corre(func(): await J.obj_local(15, 2, "bedT")) and S.day == d0 + 1, "la cama del cuartucho: %d" % S.day)
	MENUS = []
	QUIERO = ["Nada"]
	chk(corre(func(): await J.obj_local(15, 6, "armR")) and MENUS[0].has("Cambiarte de ropa"), "el armario: %s" % [MENUS])
	# 7 · el rótulo, con el local alquilado, manda dentro; dejarlo devuelve la fianza
	LOG = []
	chk(corre(func(): await J.rotulo_local("valde")) and LOG.any(func(t): return t.contains("Entra por la puerta")), "rótulo: %s" % [LOG])
	b0 = S.banco
	QUIERO = ["Dejar el local", "Dejarlo"]
	chk(corre(func(): await J.neg_caja("valde")) and not S.loc.has("valde") and S.banco - b0 == int(L.fianza), "dejarlo")
	# 8 · el camastro de la nave
	for x in O:
		if x.k == "nave":
			var en: Dictionary = Datos.enteros(x)
			S.nave = en.S.nave
	J.migrate()
	S = J.S
	J.enter_map("nave", 7, 6, "up")
	var mn: Dictionary = J.MAPS.nave
	chk(mn.o[6][17] == "bedT" and mn.o[7][17] == "bedB", "el camastro: %s %s" % [mn.o[6][17], mn.o[7][17]])
	chk(llega("nave", [7, 6], [17, 6]), "se llega al camastro")
	d0 = S.day
	QUIERO = ["Dormir"]
	chk(corre(func(): await J.obj_local(17, 7, "bedB")) and S.day == d0 + 1, "dormir en la nave")
	Datos.CAL = false
	J.enter_map("nave", 7, 6, "up")
	chk(mn.o[6][17] != "bedT", "sin CAL, sin camastro")
	Datos.CAL = true
	# 9 · el almacén del club (de presidente): guardar, sacar y lo que retiran los socios cada mañana
	var A: Dictionary = J.aso()
	A.pres = true
	J.enter_map("club-rv", 6, 6, "up")
	var mc: Dictionary = J.MAPS["club-rv"]
	var pa := []
	for y in int(mc.h):
		for x in int(mc.w):
			if mc.o[y][x] == "almC":
				pa = [x, y]
	chk(pa.size() == 2, "el almacén en el club")
	if pa.size() == 2:
		chk(llega("club-rv", [6, 6], pa), "se llega al almacén")
	S.buds = {"kali": {"g": 300.0, "thc": 20.0, "dia": S.day - 9, "cu": 1}}
	S.rosin = {}
	QUIERO = ["Guardar", "Kali", "Nada"]
	chk(corre(func(): await J.almacen_club()), "almacén bloqueado")
	chk(not S.buds.has("kali") and absf(J.alm_g() - 300) < .01, "guardado: %s %s" % [S.buds, J.alm_club()])
	QUIERO = ["Sacar", "Kali", "Nada"]
	chk(corre(func(): await J.almacen_club()) and S.buds.has("kali") and J.alm_g() < 300, "sacado: %s" % [S.buds])
	J.alm_club().buds = {"kali": {"g": 100.0, "thc": 20.0, "q": 1.0}}
	var mm: int = S.money
	J.almacen_dia()
	chk(absf(J.alm_g() - (100 - float(D.MERCADO.alm.dia))) < .01 and S.money - mm == Datos.jsround(float(D.MERCADO.alm.dia) * J.precio_club(20.0) * float(D.ASO.f)), "los socios: %s %d" % [J.alm_club(), S.money - mm])
	A.pres = false
	LOG = []
	chk(corre(func(): await J.almacen_club()) and LOG.any(func(t): return t.contains("presidente")), "sin ser presidente")
	# 10 · los mercados: el club vende varias variedades y extracciones; compra varios lotes al día hasta su tope
	var pool := ["ria", "kali", "cheese"]
	var l: Array = J.mercado_lista("club_rv", pool)
	var TC: Dictionary = D.MERCADO.club
	chk(l.size() == int(TC.n) + int(TC.nx) and l.filter(func(q): return q.x != "").size() == int(TC.nx), "la lista: %s" % [l])
	chk(J.mercado_lista("club_rv", pool) == l, "la misma lista en el día")
	var q0: Dictionary = l[0]
	S.money = 50000
	mm = S.money
	var g0: float = float(S.buds.get(q0.k, {"g": 0}).g)
	QUIERO = [J.nombre_mer(q0), "%d g" % int(TC.g[0])]
	chk(corre(func(): await J.comprar_mercado("club_rv", "CLUB", pool)), "compra bloqueada")
	chk(float(S.buds[q0.k].g) - g0 == int(TC.g[0]) and mm - S.money == Datos.jsround(int(TC.g[0]) * J.precio_mer("club_rv", q0)), "comprado: %s %d" % [S.buds.get(q0.k), mm - S.money])
	var qx: Dictionary = l[int(TC.n)]
	var kx: String = qx.k if qx.x == "rosin" else qx.k + "~" + qx.x
	QUIERO = [J.nombre_mer(qx), "%d g" % int(TC.gx[0])]
	chk(corre(func(): await J.comprar_mercado("club_rv", "CLUB", pool)) and S.rosin.has(kx), "extracción comprada: %s %s" % [kx, S.rosin])
	S.buds = {"kali": {"g": 500.0, "thc": 20.0, "dia": S.day - 9, "cu": 1}}
	mm = S.money
	for i in 3:
		QUIERO = ["Kali", "%d g" % int(D.CLUB.g[0])]
		chk(corre(func(): await J.vender_club("rv")), "venta al club %d" % i)
	var vend: float = 500.0 - float(S.buds.kali.g)
	chk(vend == 3 * int(D.CLUB.g[0]) and S.money > mm, "varias ventas al club: %s %d %s" % [vend, S.money - mm, MENUS.slice(-3)])
	LOG = []
	S.buds.kali.g = 500.0
	S.mer_v.club_rv.g = float(TC.tope)
	chk(corre(func(): await J.vender_club("rv")) and LOG.any(func(t): return t.contains("cerrado caja")) and float(S.buds.kali.g) == 500.0, "el tope del club")
	# Iñaki y la lonja también venden y cargan varias veces al día
	S.ch = maxi(int(S.ch), 3)
	S.mDay = -1
	QUIERO = ["Venta al por mayor", "Kali", "100 g"]
	chk(corre(J.talk_inaki), "Iñaki 1")
	QUIERO = ["Venta al por mayor", "Kali", "100 g"]
	chk(corre(J.talk_inaki) and float(S.buds.kali.g) == 300.0, "Iñaki dos cargas el mismo día: %s" % S.buds.kali.g)
	MENUS = []
	QUIERO = ["Comprarle", "Nada"]
	chk(corre(J.talk_inaki) and MENUS.size() >= 2 and MENUS[1].size() == int(D.MERCADO.mayor.n) + int(D.MERCADO.mayor.nx) + 1, "Iñaki vende: %s" % [MENUS])
	S.lonja = null
	QUIERO = ["Venderle", "Kali", "100 g"]
	chk(corre(J.talk_nerea) and float(S.buds.kali.g) == 200.0, "lonja 1: %s" % S.buds.kali.g)
	QUIERO = ["Venderle", "Kali", "100 g"]
	chk(corre(J.talk_nerea) and float(S.buds.kali.g) == 100.0, "lonja 2, el mismo día: %s" % S.buds.kali.g)
	S.day += 1
	LOG = []
	QUIERO = ["Venderle"]
	chk(corre(J.talk_nerea) and float(S.buds.kali.g) == 100.0 and LOG.any(func(t): return t.contains("vuelven")), "lonja al día siguiente: %s" % [LOG.slice(-1)])
	MENUS = []
	QUIERO = ["Comprarle", "Nada"]
	chk(corre(J.talk_nerea) and MENUS.size() >= 2 and MENUS[1].size() == int(D.MERCADO.mayor.n) + int(D.MERCADO.mayor.nx) + 1, "la lonja vende: %s" % [MENUS])
	for x in fallos:
		print("  FALLO ", x)
	print("negocios: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
