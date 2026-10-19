# Ribera Verde (Godot) — 1.43: el concesionario del barrio alto (lo pidió el usuario: una moto, un coche sin más, uno de gama media y
# un superdeportivo, a precios y con mecánicas realistas, con su local, el atrezo y los vehículos a la venta) y las bandejas de clones
# de la nave (lo pidió el usuario: «en la nave debería haber bandejas de clones»). Sin oráculo del HTML (congelado en la 1.37): parte
# del S de la pantalla caja-dentro.
#   $GODOT --headless --path godot --script res://tests/concesionario.gd   → «concesionario: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también conce-fuera.png, conce-dentro.png y nave-clones.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var D
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
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
	if QUIERO.size():
		var q: String = QUIERO.pop_front()
		for i in labels.size():
			if labels[i].begins_with(q):
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
			print("  bloqueo: fin %s libre %s pend %s modo %s" % [st.fin, J.is_free(), J.pending.size(), J.mode])
			return false
	return true

func haz(f: Callable, q: Array) -> String:
	QUIERO = q
	LOG = []
	MENUS = []
	chk(corre(f), "bloqueo con %s" % [q])
	return " ".join(LOG)

func dia(d: int) -> String:
	J.S.day = d
	LOG = []
	J.conce_dia()
	chk(corre(func(): pass), "cola del día %d" % d)
	return " ".join(LOG)

# se llega de a hasta b pisando solo lo que no es sólido
func llega(m: Dictionary, a: Vector2i, b: Vector2i) -> bool:
	var vis := {a: true}
	var q := [a]
	while q.size():
		var p: Vector2i = q.pop_front()
		if p == b:
			return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var c: Vector2i = p + d
			if vis.has(c) or c.x < 0 or c.y < 0 or c.x >= m.w or c.y >= m.h:
				continue
			vis[c] = true
			if c == b or not J.tile_solid(m, c.x, c.y):
				q.append(c)
	return false

func foto(dir: String, k: String) -> void:
	for q in 2:
		await process_frame
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join(k + ".png"))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-conce.json"
	Juego.AJUSTES = "user://prueba-conce-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "caja-dentro":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	D = J.D
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var C: Dictionary = D.CONCE
	# 0 · precios realistas (con IVA) y el impuesto de matriculación por emisiones, sobre el precio sin IVA
	var rangos := {"moto": [2500, 5000], "utilitario": [12000, 20000], "berlina": [28000, 45000], "deportivo": [200000, 400000]}
	for k in rangos:
		chk(C.v[k].p >= rangos[k][0] and C.v[k].p <= rangos[k][1], "precio de %s: %s" % [k, C.v[k].p])
	chk(J.iedmt("moto") == 0 and J.iedmt("utilitario") == 0, "IEDMT exento: %d %d" % [J.iedmt("moto"), J.iedmt("utilitario")])
	chk(J.iedmt("berlina") == roundi(34500 / 1.21 * .0475), "IEDMT de la berlina: %d" % J.iedmt("berlina"))
	chk(J.iedmt("deportivo") == roundi(245000 / 1.21 * .1475), "IEDMT del deportivo: %d" % J.iedmt("deportivo"))
	chk(J.total_coche("berlina") == 34500 + J.iedmt("berlina") + int(C.gastos), "total")
	chk(J.seguro_anio("utilitario") == 420, "seguro al año: %d" % J.seguro_anio("utilitario"))
	for k in C.orden:   # 1.43.2: impuesto de circulación al año y el taller por km, en cifras de verdad
		var Vk: Dictionary = C.v[k]
		chk(Vk.ivtm >= 5 and Vk.ivtm <= 300 and Vk.revKm >= 5000 and Vk.revKm <= 20000 and Vk.neuKm >= 10000 and Vk.neuKm <= 50000 and Vk.rev > 0 and Vk.neu > 0, "gastos de %s: %s" % [k, Vk])
	chk(J.ficha_coche("berlina").contains("Al año") and J.ficha_coche("berlina").contains("Sin billete"), "la ficha con los gastos")
	# 1 · abre con el capítulo y el dinero, con su SMS; el edificio en el barrio alto, y sin él, el barrio como estaba
	J.S.flags.erase("conce")
	J.S.coches = {}
	J.S.ch = 4
	J.S.money = 30000
	J.S.banco = 0
	var t := dia(100)
	chk(J.S.flags.get("conce") == null, "abierto en el capítulo 4")
	J.S.ch = 5
	J.S.money = 5000
	J.S.banco = 10000
	t = dia(101)
	chk(J.S.flags.get("conce") == null, "abierto con 15.000 €")
	J.S.banco = 16000
	t = dia(102)
	chk(J.S.flags.get("conce") == 102 and t.contains("AUTOS RIBERA"), "abre: " + t)
	var A: Dictionary = J.MAPS.alto
	var g0: String = A.g[3][28]
	J.enter_map("alto", 31, 9, "up")
	chk(A.g[3][28] == "roofT_conce" and A.g[8][31] == "door_conce" and A.doors.has("31,8") and A.doors.has("32,8"), "el edificio: %s %s" % [A.g[3][28], A.doors.keys()])
	chk(A.blds.any(func(b): return b.id == "conce") and A.o[7][31] == null and A.o[9][28] == "banderaK", "fachada, sin árboles y con banderas")
	chk(llega(A, Vector2i(31, 9), Vector2i(11, 29)) and llega(A, Vector2i(31, 9), Vector2i(36, 18)), "del concesionario a la calle y a la asociación")
	J.S.flags.erase("conce")
	J.montar_alto()
	chk(A.g[3][28] == g0 and not A.doors.has("31,8") and not A.blds.any(func(b): return b.id == "conce"), "sin abrir, el barrio alto de siempre")
	J.S.flags.conce = 102
	J.montar_alto()
	J.montar_alto()
	chk(A.blds.filter(func(b): return b.id == "conce").size() == 1, "montar dos veces, un edificio")
	# 2 · por dentro: la puerta lleva a la entrada; desde ella, Arantxa (al otro lado de la mesa) y cada vehículo
	var w: Dictionary = A.doors["31,8"]
	var K: Dictionary = J.MAPS.conce
	chk(w.to == "conce" and K.exits.has("%d,%d" % [w.x, w.y + 1]), "puerta y salida")
	J.enter_map("conce", int(w.x), int(w.y), "up")
	chk(J.ents.any(func(x): return x.id == "arantxa"), "Arantxa en su mesa")
	chk(llega(K, Vector2i(w.x, w.y), Vector2i(14, 5)), "hasta la mesa de Arantxa")
	for k in C.orden:
		var ok := false
		for y in K.h:
			for x in K.w:
				if K.o[y][x] == C.v[k].o and (llega(K, Vector2i(w.x, w.y), Vector2i(x, y + 1)) or llega(K, Vector2i(w.x, w.y), Vector2i(x - 1, y))):
					ok = true
		chk(ok, "se llega a " + k)
	# 3 · comprar: en efectivo, como mucho 1.000 €; el resto, de la cuenta, con el primer mes del seguro
	J.S.day = 110
	J.S.money = 5000
	J.S.banco = 1000
	t = haz(J.talk_conce, ["Utilitario", "Firmar", "Nada"])
	chk(not J.S.coches.has("utilitario") and t.contains("hacen falta"), "sin saldo: " + t)
	var tot: int = J.total_coche("utilitario")
	J.S.banco = 20000
	t = haz(J.talk_conce, ["Utilitario", "Firmar", "Nada"])
	chk(J.S.coches.has("utilitario") and int(J.S.money) == 4000 and int(J.S.banco) == 20000 - (tot - 1000) - J.seguro_anio("utilitario"), "comprado: %s %s %s" % [J.S.money, J.S.banco, J.S.coches])
	chk(int(J.S.coches.utilitario.dia) == 115 and not J.coche_ya("utilitario"), "llega en 5 días")
	chk(J.recibos().any(func(r): return r[0] == "Seguro · Utilitario" and int(r[1]) == 115 + 365 and r[3] == "cuenta"), "el seguro, en los recibos, al año")
	chk(J.recibos().any(func(r): return r[0] == "Impuesto de circulación · Utilitario" and int(r[1]) == 115 and int(r[2]) == 62), "el impuesto de circulación, en los recibos")
	chk(J.marcas_cal().any(func(x): return x.d == 115 + 365 and x.t.contains("Seguro")), "y en el calendario")
	var b1: int = int(J.S.banco)
	t = dia(115)
	chk(t.contains("matriculado") and J.coche_ya("utilitario"), "entregado: " + t)
	chk(int(J.S.banco) == b1 - 62 and int(J.S.coches.utilitario.iv) == 115 + 365, "el impuesto, al entregarlo: %s %s" % [J.S.banco, J.S.coches.utilitario])
	# 4 · de parada en parada: sin esperar al autobús, más rápido, con su gasolina
	J.S.ch = 5
	J.enter_map("town", 7, 12, "down")
	J.S.min = 23 * 60
	J.S.money = 100
	var tr: Dictionary = J.tramo("town", "puerto", "utilitario")
	chk(tr.min == roundi(25 * .55) and tr.eur == roundi(18 * 5.4 / 100 * 1.6), "tramo: %s" % [tr])
	Cultivo.fijo = .99   # sin control
	t = haz(J.parada_action, ["En el utilitario", "Puerto Viejo"])
	chk(J.S.map == "puerto" and int(J.S.money) == 100 - int(tr.eur), "en coche a Puerto Viejo, de noche, sin billete: %s %s" % [J.S.map, J.S.money])
	chk(int(J.S.coches.utilitario.km) == 18 and not t.contains("TALLER"), "los km: %s" % [J.S.coches.utilitario])
	# 4b · el taller por km: al pasar los 15.000, la revisión; a los 40.000, también los neumáticos
	J.S.coches.utilitario.km = 14990
	J.S.banco = 1000
	J.S.money = 100
	t = haz(J.parada_action, ["En el utilitario", "Ribera Verde"])
	chk(int(J.S.coches.utilitario.km) == 15008 and int(J.S.banco) == 1000 - 220 and t.contains("revisión") and not t.contains("neumáticos"), "la revisión: %s %s %s" % [J.S.banco, J.S.coches.utilitario, t])
	J.S.coches.utilitario.km = 39990
	J.S.banco = 1000
	t = haz(J.parada_action, ["En el utilitario", "Puerto Viejo"])
	chk(int(J.S.banco) == 1000 - 300 and t.contains("neumáticos") and not t.contains("revisión"), "los neumáticos: %s %s" % [J.S.banco, t])
	J.S.coches.utilitario.km = 18
	# 5 · control de tráfico: con algo encima y registro, te lo quitan
	J.S.buds = {"thai": {"g": 20, "thc": 18}}
	Cultivo.fijo = 0.0
	t = haz(func(): await J.control_trafico("utilitario"), [])
	chk(J.total_buds() == 0 and t.contains("requisan"), "control: " + t)
	Cultivo.fijo = -1
	# 6 · el seguro, cada año; sin saldo, devuelto y, pasada la gracia, anulado (y entonces, a la grúa en un control)
	J.S.banco = 1000
	J.S.coches.utilitario.iv = 999   # el impuesto, aparte (6b)
	t = dia(480)
	chk(int(J.S.banco) == 1000 - J.seguro_anio("utilitario") and int(J.S.coches.utilitario.r) == 845, "recibo cobrado: %s %s" % [J.S.banco, J.S.coches.utilitario])
	J.S.banco = 0
	t = dia(845)
	chk(J.S.coches.utilitario.r == 845 and t.contains("devuelto"), "devuelto: " + t)
	t = dia(845 + int(D.RECIBO.graciaB))
	chk(J.S.coches.utilitario.get("r") == null and t.contains("anulada"), "anulada: " + t)
	J.S.money = 0
	J.S.banco = 5000
	Cultivo.fijo = 0.0
	t = haz(func(): await J.control_trafico("utilitario"), [])
	Cultivo.fijo = -1
	chk(J.S.coches.utilitario.get("grua") and int(J.S.banco) == 5000 - int(C.sinSeguro) and not J.coches_mios().has("utilitario"), "sin seguro: grúa y multa: " + t)
	# 6b · el impuesto sin pagar: devuelto y, pasada la gracia, por apremio con recargo
	J.S.coches.utilitario.iv = int(J.S.day) + 1
	J.S.banco = 0
	J.S.money = 0
	t = dia(int(J.S.day) + 1)
	chk(t.contains("apremio") and t.contains("devuelto"), "impuesto devuelto: " + t)
	J.S.money = 500
	var iv0: int = int(J.S.coches.utilitario.iv)
	t = dia(iv0 + int(D.RECIBO.graciaB))
	chk(t.contains("Providencia") and int(J.S.money) == 500 - roundi(62 * 1.2) and int(J.S.coches.utilitario.iv) == iv0 + 365, "apremio: %s %s %s" % [J.S.money, J.S.coches.utilitario, t])
	J.S.banco = 5000
	J.enter_map("conce", 14, 5, "up")
	t = haz(J.talk_conce, ["Asegurar", "Nada"])
	chk(J.S.coches.utilitario.get("r") == J.S.day + 365 and J.coches_mios().has("utilitario"), "asegurado otra vez: " + t)
	# 7 · vender: lo que pierde al salir y cada mes
	J.S.day = 115 + 60
	J.S.coches.utilitario.iv = 999
	var v: int = J.valor_coche("utilitario")
	chk(v == roundi(15900 * (1 - .2 - .012 * 2)), "valor a los dos meses: %d" % v)
	var b0: int = int(J.S.banco)
	t = haz(J.talk_conce, ["Vender", "Utilitario", "Vender", "Nada"])
	chk(not J.S.coches.has("utilitario") and int(J.S.banco) == b0 + v, "vendido: %s %s" % [J.S.banco, J.S.coches])
	chk(not J.recibos().any(func(r): return r[0].begins_with("Seguro")), "sin seguro que pagar")
	# 8 · el superdeportivo: bajo pedido y, en el barrio, se habla
	J.S.banco = 400000
	J.S.money = 0
	var h0: int = int(J.S.heat)
	t = haz(J.talk_conce, ["Superdeportivo", "Firmar", "Nada"])
	chk(J.S.coches.has("deportivo") and int(J.S.coches.deportivo.dia) == J.S.day + 30 and int(J.S.heat) == mini(100, h0 + 15), "deportivo: %s" % [J.S.coches.get("deportivo")])
	# 9 · la moto: en la calle vas montado; no está en la tienda online
	J.S.banco = 10000
	t = haz(J.talk_conce, ["Scooter", "Firmar", "Nada"])
	J.S.day += 2
	J.S.conduce = "moto"   # MAESTRO [3]: conduces el que te entregan (conce_dia), no el mejor que tengas
	J.enter_map("town", 7, 12, "down")
	chk(J.vehiculo() == "moto" and J.paso_ms() < float(D.VEHICULOS.bici.paso[0]), "la moto en la calle: %s" % J.vehiculo())
	# 9b · los coches por la calle, a escala de juguete (más bajos que él de pie): el mejor que tengas; con la grúa, no
	J.S.day = int(J.S.coches.deportivo.dia)
	J.S.conduce = "deportivo"
	J.enter_map("town", 7, 12, "down")
	chk(J.vehiculo() == "deportivo" and J.paso_ms() < float(D.VEHICULOS.moto.paso[0]), "el deportivo en la calle: %s" % J.vehiculo())
	J.S.coches.deportivo.grua = true
	chk(J.vehiculo() != "deportivo", "el deportivo en la grúa, a pie: %s" % J.vehiculo())
	J.S.coches.deportivo.erase("grua")
	for k in ["utilitario", "berlina", "deportivo"]:
		var Vk: Dictionary = D.VEHICULOS[k]
		chk(int(Vk.sube) < 0 and int(Vk.corta) <= 24 and Vk.n == C.v[k].n and Atlas.anim_de("vehiculos", k + "-atras") and Atlas.anim_de("vehiculos", k + "-delante"), "%s: sentado y con su arte" % k)
	chk(float(D.VEHICULOS.utilitario.paso[0]) > float(D.VEHICULOS.berlina.paso[0]) and float(D.VEHICULOS.berlina.paso[0]) > float(D.VEHICULOS.deportivo.paso[0]), "más caro, más rápido")
	J.enter_map("conce", 14, 5, "up")
	chk(J.vehiculo() == null, "dentro, a pie")
	J.S.money = 0
	J.S.banco = 0
	QUIERO = ["Salir"]
	MENUS = []
	chk(corre(J.tienda_online), "tienda")
	chk(MENUS.size() and not MENUS[0].any(func(l): return l.begins_with("Scooter")), "la moto no, en la tienda online")
	# 10 · las bandejas de clones de la nave: antes de 12/12, la bandeja; enraíza en NAVE.raiz días; con la cosecha, vuelve a empezar
	J.S.nave = J.nave_nueva()
	J.S.plantilla = [{"n": "Itziar", "rol": "nave", "mesa": 0, "cui": 3, "lab": 3, "lea": 3}]
	J.S.nave.m[0] = {"k": "niebla", "f": {"y": 1.0, "t": 0}, "thc": 18.0, "y": 1.0, "dia": J.S.day, "g": 0, "t": 0, "abo": 0, "p": .55, "dn": 0, "am": 0, "ao": 0, "n": 0}
	J.enter_map("nave", 7, 6, "up")
	chk(J.S.nave.get("bc") == [] and J.MAPS.nave.o[2][8] == "clonN" and J.sprite_local("clonN") == "clonN-0", "el carro, vacío")
	Cultivo.fijo = .99
	J.nave_dia()
	chk(J.S.nave.bc.size() == 1 and J.S.nave.bc[0].m == 0 and J.S.nave.bc[0].k == "niebla" and J.sprite_local("clonN") == "clonN-1", "la bandeja: %s" % [J.S.nave.bc])
	chk(not J.bandeja_lista(J.S.nave.bc[0]), "aún sin raíces")
	J.corta_bandeja(0, J.S.nave.m[0])
	chk(J.S.nave.bc.size() == 1, "una por mesa: %s" % [J.S.nave.bc])
	J.S.day += int(D.NAVE.raiz)
	chk(J.bandejas_listas().size() == 1, "enraizada: %s %d" % [J.S.nave.get("bc"), J.S.day])
	J.S.nave.m[0].p = .999
	J.nave_dia()
	Cultivo.fijo = -1
	chk(J.S.nave.bc.is_empty() and J.S.nave.m[0].p == float(D.NAVE.clon) and J.S.nave.m[0].get("h") != null, "cosechada, vuelve a empezar con la bandeja: %s" % [J.S.nave.m[0]])
	t = haz(func(): await J.object_action(8, 2), [])
	chk(t.contains("Vacío"), "el carro vacío: " + t)
	# 11 · contra el HTML congelado (CAL = false), ni abre, ni bandejas
	Datos.CAL = false
	J.S.flags.erase("conce")
	dia(J.S.day + 1)
	chk(J.S.flags.get("conce") == null, "con CAL = false, no abre")
	Datos.CAL = true
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
		J.S.flags.conce = 102
		J.S.min = 12 * 60
		J.enter_map("alto", 31, 10, "up")
		await foto(dir, "conce-fuera")
		J.enter_map("conce", 8, 7, "up")
		await foto(dir, "conce-dentro")
		J.S.nave.bc = [{"m": 0, "k": "ria", "f": null, "d": J.S.day}, {"m": 1, "k": "ria", "f": null, "d": J.S.day}, {"m": 2, "k": "ria", "f": null, "d": J.S.day}]
		J.enter_map("nave", 8, 4, "up")
		await foto(dir, "nave-clones")
		J.enter_map("town", 7, 14, "right")
		var cs: Dictionary = J.S.coches
		J.S.coches = {"moto": cs.moto}
		J.S.conduce = "moto"
		await foto(dir, "moto")
		for k in ["utilitario", "berlina", "deportivo"]:
			J.S.coches = {k: {"dia": 0, "p": 1, "r": null}}
			J.S.conduce = k
			for dd in ["right", "down", "up"]:
				J.enter_map("town", 7, 14, dd)
				await foto(dir, "coche-%s-%s" % [k, dd])
		J.S.coches = {"berlina": {"dia": 0, "p": 1, "r": null, "pos": ["town", 6, 14, "right"]}, "moto": {"dia": 0, "p": 1, "r": null, "pos": ["town", 9, 14, "down"]}}   # MAESTRO [3]: aparcados, sin nadie
		J.S.conduce = null
		J.enter_map("town", 7, 15, "up")
		await foto(dir, "aparcados")
		J.S.coches = cs
	for x in fallos:
		print("  FALLO ", x)
	print("concesionario: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
