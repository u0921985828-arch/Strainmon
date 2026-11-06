# Landrace Hunters (Godot) — las mejoras de la huerta de la tía (lo pidió el usuario: «Opción a comprar mejoras como tanques de agua
# de 1m3 o tanques azules de 100L dependiendo, también sistema de riego... Herramientas para trabajar la tierra o motoazada siguiente
# mejora... Habría que hacer los sprites y eso»), con Datos.CAL: la fila de la tienda online (solo con la huerta desbrozada), lo que
# pide cada mejora, la entrega al día siguiente con sus dibujos en la huerta, llenar los depósitos con la manguera, el goteo de la
# placa solar (litros por planta, a medias si no llega, nada con lluvia ni sin agua, unos 90-140 L al día de julio con ocho
# grandes), cavar y labrar (la tierra oscura, más cosecha, otra vez sin trabajar al cosechar) y guardar y cargar.
#   $GODOT --headless --path godot --script res://tests/huerta_mej.gd   → «huerta_mej: N comprobaciones, 0 fallos»
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

func dicho(t: String) -> bool:
	for l in LOG:
		if String(l).contains(t):
			return true
	return false

func minutos() -> int:
	return int(J.S.day) * 1440 + int(J.S.min)

func dia_que(d0: int, f: Callable) -> int:
	for d in range(d0, d0 + 366):
		if f.call(Datos.tiempo(d, 360)) and f.call(Datos.tiempo(d, 720)):
			return d
	return -1

# el menú de la tienda de la huerta que se vio el último, por su título
func fila(lb: String) -> Dictionary:
	for k in range(ITEMS.size() - 1, -1, -1):
		for it in ITEMS[k]:
			if it is Dictionary and String(it.get("label", "")).begins_with(lb):
				return it
	return {}

func luz(im: Image) -> float:
	var t := 0.0
	var c := 0
	for y in im.get_height():
		for x in im.get_width():
			var p := im.get_pixel(x, y)
			if p.a > 0:
				t += p.r + p.g + p.b
				c += 1
	return t / maxf(1, c)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-huerta-mej.json"
	Juego.AJUSTES = "user://prueba-huerta-mej-ajustes.json"
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
	# 0 · sin huerta, o sin desbrozar, o sin CAL: la tienda no la ofrece
	S.erase("huerta")
	MENUS.clear()
	chk(corre(func(): await J.tienda_online()), "la tienda online sin huerta")
	chk(not MENUS[0].any(func(l): return String(l).begins_with("La huerta")), "sin huerta, no hay fila de la huerta: %s" % [MENUS[0]])
	S.huerta = {"v": 1, "l": 0, "p": []}
	MENUS.clear()
	chk(corre(func(): await J.tienda_online()), "la tienda online sin desbrozar")
	chk(not MENUS[0].any(func(l): return String(l).begins_with("La huerta")), "sin desbrozar, tampoco")
	S.huerta.l = 1
	Datos.CAL = false
	MENUS.clear()
	chk(corre(func(): await J.tienda_online()), "la tienda online sin CAL")
	chk(not MENUS[0].any(func(l): return String(l).begins_with("La huerta")), "sin CAL, tampoco")
	Datos.CAL = true
	J.enter_map("huerta", int(H.llega[0]), int(H.llega[1]), "up")
	var m: Dictionary = J.MAPS.huerta
	for k in ["bidon", "ibc", "goteo", "herr", "moto"]:
		for c in HM[k].x:
			chk(m.o[c[1]][c[0]] == null, "sin comprar nada, %s vacío en %s (%s)" % [k, c, m.o[c[1]][c[0]]])
	# 1 · la tienda: lo que pide cada una
	QUIERO = ["La huerta"]
	ITEMS.clear()
	chk(corre(func(): await J.tienda_online()), "la tienda online → la huerta")
	chk(fila("Goteo con bomba solar").get("disabled") == true, "el goteo, sin depósito, no se puede: %s" % fila("Goteo"))
	chk(fila("Motoazada").get("disabled") == true, "la motoazada, sin herramientas, no se puede")
	chk(fila("Bidón azul de 100 L").get("disabled") == false and fila("Depósito de 1000 L").get("disabled") == false and fila("Herramientas de huerta").get("disabled") == false, "lo demás, sí")
	chk(String(fila("Goteo").get("desc", "")).contains("depósito"), "el goteo dice que hace falta un depósito")
	var b0: float = float(S.banco)
	QUIERO = ["La huerta", "Bidón azul", "Depósito de 1000", "Goteo", "Herramientas", "Motoazada", "Bidón azul", "Bidón azul"]
	ITEMS.clear()
	chk(corre(func(): await J.tienda_online()), "comprar en la tienda de la huerta")
	var pagado: float = b0 - float(S.banco)
	var esper: float = 3 * HM.bidon.p + HM.ibc.p + HM.goteo.p + HM.herr.p + HM.moto.p
	chk(is_equal_approx(pagado, esper), "pagado con tarjeta %s (esperaba %s)" % [pagado, esper])
	chk(J.huerta_ped("bidon") == 3 and J.huerta_ped("ibc") == 1 and J.huerta_ped("goteo") == 1 and J.huerta_ped("herr") == 1 and J.huerta_ped("moto") == 1, "pedidos: %s" % [S.huerta.ped])
	chk(fila("Bidón azul de 100 L").get("disabled") == true and String(fila("Bidón azul de 100 L").label).contains("3/3"), "como mucho 3 bidones: %s" % fila("Bidón azul").get("label"))
	chk(fila("Goteo con bomba solar").get("disabled") == true and fila("Motoazada").get("disabled") == true, "una de cada")
	for c in HM.bidon.x:
		chk(J.MAPS.huerta.o[c[1]][c[0]] == null, "hoy no llega nada (%s)" % [c])
	# 2 · al día siguiente, en la huerta
	S.day += 1
	J.llega_huerta()
	chk(J.huerta_m("bidon") == 3 and J.huerta_m("ibc") == 1 and J.huerta_m("goteo") == 1 and J.huerta_m("herr") == 1 and J.huerta_m("moto") == 1 and S.huerta.ped.is_empty(), "llegan: %s" % [S.huerta.m])
	chk(J.queued.has("huerta"), "con su aviso")
	m = J.MAPS.huerta
	for c in HM.bidon.x:
		chk(m.o[c[1]][c[0]] == "bidonA", "el bidón en %s (%s)" % [c, m.o[c[1]][c[0]]])
	chk(m.o[HM.ibc.x[0][1]][HM.ibc.x[0][0]] == "ibcD-0", "el depósito de 1000 L, vacío: %s" % m.o[HM.ibc.x[0][1]][HM.ibc.x[0][0]])
	chk(m.o[HM.ibc.x[1][1]][HM.ibc.x[1][0]] == null, "solo uno: el segundo sitio, libre")
	chk(m.o[HM.goteo.x[0][1]][HM.goteo.x[0][0]] == "bombaS" and m.o[HM.herr.x[0][1]][HM.herr.x[0][0]] == "herrH" and m.o[HM.moto.x[0][1]][HM.moto.x[0][0]] == "motoA", "la bomba, las herramientas y la motoazada")
	var Atlas = load("res://src/atlas.gd")
	Atlas.carga()
	for s in ["bidonA", "ibcD-0", "ibcD-1", "ibcD-2", "ibcD-3", "ibcD-4", "herrH", "motoA", "bombaS"]:
		chk(Atlas.frame_de(Atlas.cubre("obj:" + s), s, "unica", 0, {"i": 0}) != null, "el dibujo de %s, en el atlas" % s)
	# todo se alcanza a pie desde la entrada
	var ll := Vector2i(int(H.llega[0]), int(H.llega[1]))
	var vis := {ll: true}
	var cola := [ll]
	while cola.size():
		var c: Vector2i = cola.pop_front()
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var v: Vector2i = c + dd
			if v.x < 0 or v.y < 0 or v.x >= int(m.w) or v.y >= int(m.h) or vis.has(v) or m.o[v.y][v.x] != null or J.tile_solid(m, v.x, v.y):
				continue
			vis[v] = true
			cola.append(v)
	var junto := func(x: int, y: int) -> bool:
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if vis.has(Vector2i(x, y) + dd):
				return true
		return false
	for k in ["bidon", "goteo", "herr", "moto"]:
		chk(junto.call(HM[k].x[0][0], HM[k].x[0][1]), "se llega a %s" % k)
	chk(junto.call(HM.ibc.x[0][0], HM.ibc.x[0][1]), "se llega al depósito")
	for st in H.sitios:
		chk(junto.call(st[0], st[1]), "con todo puesto, se llega al sitio %s" % [st])
	for a in H.atrezo:
		chk(junto.call(a[0], a[1]), "y a %s" % [a])
	# 3 · llenarlos con la manguera del garaje
	var cap: int = J.huerta_cap()
	chk(cap == 3 * int(HM.bidon.l) + int(HM.ibc.l), "caben %d L" % cap)
	var t0 := minutos()
	QUIERO = ["Llenarlos"]
	LOG.clear()
	var ib: Array = HM.ibc.x[0]
	chk(corre(func(): await J.object_action(ib[0], ib[1])), "A en el depósito")
	chk(is_equal_approx(float(S.huerta.agua), float(cap)), "llenos: %s L" % S.huerta.agua)
	chk(minutos() - t0 >= ceili(cap / float(HM.caudal)), "llenar %d L lleva %d min (%d)" % [cap, ceili(cap / float(HM.caudal)), minutos() - t0])
	chk(J.MAPS.huerta.o[ib[1]][ib[0]] == "ibcD-4", "el depósito, lleno: %s" % J.MAPS.huerta.o[ib[1]][ib[0]])
	LOG.clear()
	chk(corre(func(): await J.object_action(HM.bidon.x[0][0], HM.bidon.x[0][1])), "A en un bidón, lleno")
	chk(dicho("Están llenos"), "ya están llenos: %s" % [LOG])
	# 4 · cavar un sitio y labrar con la motoazada
	var s0: Array = H.sitios[0]
	t0 = minutos()
	QUIERO = ["Cavar la tierra"]
	MENUS.clear()
	chk(corre(func(): await J.object_action(s0[0], s0[1])), "A en un sitio vacío: cavar")
	chk(MENUS.size() and MENUS[0].has("Labrar con la motoazada") and MENUS[0].has("Cavar la tierra") and MENUS[0].has("Plantar"), "las opciones del sitio vacío: %s" % [MENUS])
	chk(J.huerta_t(0) == 1 and J.huerta_t(1) == 0, "cavado solo el sitio 0: %s" % [S.huerta.t])
	chk(minutos() - t0 >= int(HM.herr.min), "cavar lleva %d min (%d)" % [int(HM.herr.min), minutos() - t0])
	chk(J.MAPS.huerta.g[s0[1]][s0[0]] == "surcoV" and J.MAPS.huerta.g[H.sitios[1][1]][H.sitios[1][0]] == "surco", "la tierra cavada, oscura; la otra, no")
	var sid: String = String(D.BANCO[0][0])
	var pr = Cultivo.nueva_planta(S, sid)
	var g0: float = float(J.huerta_f(pr, 1).g)
	chk(is_equal_approx(float(J.huerta_f(pr, 0).g), g0 * (1 + float(HM.herr.g))), "cavada, un %d %% más (%s frente a %s)" % [int(HM.herr.g * 100), J.huerta_f(pr, 0).g, g0])
	t0 = minutos()
	var mo: Array = HM.moto.x[0]
	QUIERO = ["Labrar"]
	chk(corre(func(): await J.object_action(mo[0], mo[1])), "A en la motoazada: labrar")
	chk(S.huerta.t.all(func(t): return int(t) == 2), "labrados todos los sitios vacíos: %s" % [S.huerta.t])
	chk(minutos() - t0 >= int(HM.moto.min) and minutos() - t0 < int(HM.moto.min) + 30, "labrar todo lleva %d min (%d)" % [int(HM.moto.min), minutos() - t0])
	chk(is_equal_approx(float(J.huerta_f(pr, 3).g), g0 * (1 + float(HM.moto.g))), "labrada, un %d %% más" % int(HM.moto.g * 100))
	chk(is_equal_approx(float(J.huerta_f(pr).g), g0), "sin sitio, como antes")
	# plantar en la labrada: sin preguntar por la tierra
	S.seeds = {sid: 9}
	QUIERO = [J.strain(sid).n]
	MENUS.clear()
	chk(corre(func(): await J.object_action(s0[0], s0[1])), "plantar en la labrada")
	chk(J.huerta_s().p[0] is Dictionary and not MENUS.any(func(l): return l.has("Cavar la tierra")), "plantada, sin la pregunta de la tierra")
	chk(J.huerta_t(0) == 2, "la tierra sigue labrada con la planta")
	# 5 · el goteo
	var jul := dia_que(Datos.dia_de(2026, 7, 1), func(t): return t.k == "sol")
	chk(jul > 0, "un día de sol en julio")
	S.day = jul
	S.min = 600
	var p0: Dictionary = J.huerta_s().p[0]
	p0.prog = .8
	p0.water = 30.0
	p0.pest = false
	S.huerta.agua = 1000.0
	J.huerta_avanza(10)
	var lp: float = float(HM.litros[0]) + float(HM.litros[1]) * .8
	chk(float(p0.water) > 99, "el goteo la riega: agua %s" % p0.water)
	chk(float(S.huerta.agua) < 1000 and float(S.huerta.agua) > 1000 - lp, "con los litros de su tamaño (%s L gastados, como mucho %s)" % [1000 - float(S.huerta.agua), lp])
	p0.water = 70.0
	var a0: float = float(S.huerta.agua)
	J.huerta_avanza(10)
	chk(is_equal_approx(float(S.huerta.agua), a0), "por encima del umbral, nada (%s)" % S.huerta.agua)
	p0.water = 30.0
	S.huerta.agua = 2.0
	J.huerta_avanza(1)
	chk(float(S.huerta.agua) == 0.0 and float(p0.water) > 30 and float(p0.water) < 50, "si no llega, a medias: agua %s, quedan %s L" % [p0.water, S.huerta.agua])
	p0.water = 30.0
	J.huerta_avanza(10)
	chk(float(p0.water) < 30, "sin agua en los depósitos, se seca (%s)" % p0.water)
	var dl := dia_que(Datos.dia_de(2026, 7, 1), func(t): return t.k == "lluvia")
	if dl > 0:
		S.day = dl
		S.min = 720
		S.huerta.agua = 500.0
		p0.water = 30.0
		J.huerta_avanza(10)
		chk(is_equal_approx(float(S.huerta.agua), 500.0) and float(p0.water) > 99, "con lluvia, riega el cielo y no se gasta (%s L)" % S.huerta.agua)
	# un día de julio con ocho grandes: lo que gasta
	S.day = jul
	for i in H.sitios.size():
		var q = Cultivo.nueva_planta(S, sid)
		q.prog = .9
		q.water = 100.0
		J.huerta_s().p[i] = q
	S.huerta.agua = 1100.0
	for h in 24:
		S.min = h * 60
		for q in J.huerta_s().p:
			q.pest = false
			q.health = 100.0
			q.prog = .9
		J.huerta_avanza(60)
	var gasto: float = 1100.0 - float(S.huerta.agua)
	print("  goteo: %.0f L en un día de julio con ocho grandes" % gasto)
	chk(gasto >= 60 and gasto <= 140, "un día de julio, entre 60 y 140 L (%.0f)" % gasto)
	chk(J.huerta_s().p.all(func(q): return float(q.water) >= 40), "y ninguna se seca")
	chk(J.MAPS.huerta.o[ib[1]][ib[0]] == "ibcD-%d" % roundi(4.0 * float(S.huerta.agua) / cap), "el depósito, por cuartos: %s (%s L)" % [J.MAPS.huerta.o[ib[1]][ib[0]], S.huerta.agua])
	# 6 · cosechar: la tierra, otra vez sin trabajar
	for i in range(1, H.sitios.size()):
		J.huerta_s().p[i] = null
	p0 = J.huerta_s().p[0]
	p0.prog = 1.0
	QUIERO = ["Cosechar"]
	chk(corre(func(): await J.object_action(s0[0], s0[1])), "cosechar la del sitio 0")
	chk(J.huerta_s().p[0] == null and J.huerta_t(0) == 0, "cosechada: la tierra, sin trabajar (%s)" % [S.huerta.t])
	chk(J.MAPS.huerta.g[s0[1]][s0[0]] == "surco", "y otra vez el surco de siempre")
	chk(J.huerta_t(1) == 2, "las demás siguen labradas")
	# 7 · las herramientas a mano: los vacíos sin cavar
	QUIERO = ["Cavar"]
	var he: Array = HM.herr.x[0]
	t0 = minutos()
	chk(corre(func(): await J.object_action(he[0], he[1])), "A en las herramientas")
	chk(J.huerta_t(0) == 1 and J.huerta_t(1) == 2, "cava el que estaba sin trabajar y no estropea los labrados: %s" % [S.huerta.t])
	chk(minutos() - t0 >= int(HM.herr.min), "%d min" % (minutos() - t0))
	# 8 · guardar y cargar
	S.huerta = JSON.parse_string(JSON.stringify(S.huerta))
	J.enter_map("huerta", ll.x, ll.y, "up")
	m = J.MAPS.huerta
	chk(m.o[HM.bidon.x[2][1]][HM.bidon.x[2][0]] == "bidonA" and String(m.o[ib[1]][ib[0]]).begins_with("ibcD-") and m.o[mo[1]][mo[0]] == "motoA", "tras cargar, todo en su sitio")
	chk(m.g[s0[1]][s0[0]] == "surcoV" and J.huerta_t(0) == 1, "y la tierra cavada")
	# 9 · el dibujo de la tierra cavada, más oscuro
	var a := Pintor.surco_img(10, 4)
	var b := Pintor.surco_img(10, 4, true)
	chk(luz(b) < luz(a) * .8, "la tierra cavada, más oscura (%.2f frente a %.2f)" % [luz(b), luz(a)])
	var opaco := 0
	for y in 16:
		for x in 16:
			opaco += 1 if b.get_pixel(x, y).a > 0 else 0
	chk(opaco >= 140, "la mancha cavada, casi toda la casilla (%d px)" % opaco)
	chk(b.get_pixel(8, 8).a > 0 and b.get_pixel(8, 9).a > 0, "y el centro, cavado")
	# 10 · la caja de herramientas de la tía lo dice
	LOG.clear()
	var cr: Array = H.atrezo[3]
	chk(corre(func(): await J.object_action(cr[0], cr[1])), "las herramientas de la tía")
	chk(dicho("mango partido"), "la azada, con el mango partido: %s" % [LOG])
	print("huerta_mej: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
