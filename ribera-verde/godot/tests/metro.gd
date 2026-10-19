# Ribera Verde (Godot) — MAESTRO [9]: la red de pisos de venta (desde el primer envío por mar: alquilar o comprar, el
# lugarteniente de la plantilla, la pureza y el precio, lo que vende cada mañana, la sisa, el calor y la redada) y la ciudad de la
# autopista (Hiriburu: se abre por el patrimonio neto, se va con tu vehículo y su peaje, los clubs VIP, el concejal y las bandas por
# los barrios). Sin Datos.CAL, nada de esto. Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla nave2.
#   $GODOT --headless --path godot --script res://tests/metro.gd   → «metro: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

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

# las casillas a las que se llega andando desde (x0, y0) en el mapa m (sin pisar sólidos ni objetos)
func alcanza(m: Dictionary, x0: int, y0: int) -> Dictionary:
	var vis := {Vector2i(x0, y0): true}
	var cola := [Vector2i(x0, y0)]
	while cola.size():
		var p: Vector2i = cola.pop_front()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if q.x < 0 or q.y < 0 or q.x >= int(m.w) or q.y >= int(m.h) or vis.has(q):
				continue
			if J.tile_solid(m, q.x, q.y) or m.o[q.y][q.x] != null:
				continue
			vis[q] = true
			cola.append(q)
	return vis

func junto(vis: Dictionary, x: int, y: int) -> bool:   # se puede hablar o usar (x, y) desde una casilla de al lado
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if vis.has(Vector2i(x, y) + d):
			return true
	return false

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-metro.json"
	Juego.AJUSTES = "user://prueba-metro-ajustes.json"
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
	var S: Dictionary = J.S
	S.ch = 8
	S.erase("mar")
	S.erase("pisos")
	S.erase("metro")
	J.enter_map("town", 10, 10, "down")
	J.mode = "world"
	var D = J.D
	var R: Dictionary = D.PISOS9
	var MT: Dictionary = D.METRO
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	J.gancho_combate = func(_k): return "win"
	J.gancho_viaje = func(_v, _de, _a): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)

	# 1 · sin el primer envío por mar, ni pisos ni app
	chk(not J.pisos_ok(), "pisos sin envío")
	MENUS = []
	QUIERO = ["Colgar"]
	chk(corre(J.movil_menu), "móvil bloqueado")
	chk(MENUS.size() and not MENUS[0].has("Pisos"), "app sin envío: %s" % [MENUS])
	S.mar = {"paso": 1}
	chk(J.pisos_ok(), "pisos con el envío")
	MENUS = []
	QUIERO = ["Colgar"]
	chk(corre(J.movil_menu), "móvil bloqueado (2)")
	chk(MENUS.size() and MENUS[0].has("Pisos"), "app con el envío: %s" % [MENUS])
	chk(J.Atlas.cubre("misc:mv-pisos") != null, "icono mv-pisos")
	Datos.CAL = false
	Datos.carga()
	chk(not J.pisos_ok() and not J.D.PARADAS.has("metropoli") and not J.D.ZONAS.has("metropoli"), "sin CAL: nada")
	Datos.CAL = true
	Datos.carga()
	chk(J.D.PARADAS.has("metropoli") and J.D.ZONAS.has("metropoli") and J.D.CLIENT_TILES.has("metropoli") and J.D.CONCE.km.has("metropoli"), "con CAL: la ciudad en las tablas")
	var L: Array = J.pisos_lista()
	chk(L.has("town") and L.has("ibarbide") and not L.has("metropoli"), "lista %s" % [L])

	# 2 · alquilar (efectivo) y comprar (cuenta)
	S.money = int(R.k.town.alq) - 1
	QUIERO = ["Alquilarlo"]
	chk(corre(func(): await J.piso_menu("town")), "alquilar bloqueado (sin dinero)")
	chk(not J.pisos_d().has("town"), "alquilado sin dinero")
	S.money = 50000
	QUIERO = ["Alquilarlo"]
	chk(corre(func(): await J.piso_menu("town")), "alquilar bloqueado")
	chk(J.pisos_d().has("town") and S.money == 50000 - int(R.k.town.alq) and not J.pisos_d().town.mia, "alquilado %s %s" % [J.pisos_d().get("town"), S.money])
	S.banco = int(R.k.puerto.p) + 100
	QUIERO = ["Comprarlo"]
	chk(corre(func(): await J.piso_menu("puerto")), "comprar bloqueado")
	chk(J.pisos_d().has("puerto") and J.pisos_d().puerto.mia and int(S.banco) == 100, "comprado %s %s" % [J.pisos_d().get("puerto"), S.banco])

	# 3 · el lugarteniente, de la plantilla
	var w := {"id": "lt1", "n": "PRUEBA", "lab": 4, "cui": 3, "lea": 4}
	S.plantilla = S.get("plantilla", []).filter(func(x): return x.get("rol") != null)
	S.plantilla.append(w)
	QUIERO = ["Lugarteniente", "PRUEBA", "Nada"]
	chk(corre(func(): await J.piso_menu("town")), "lugarteniente bloqueado")
	chk(w.get("rol") == "lugar" and w.get("pv") == "town" and J.lt_de("town") == w, "lugarteniente %s" % [w])
	chk(J.rol_txt(w).contains("piso") and J.rol_desc(w).contains("piso"), "rol " + J.rol_txt(w))

	# 4 · dejar género: solo en el pueblo
	var sid: String = D.DEX[0]
	S.buds = {sid: {"g": 2000.0, "thc": 18.0, "dia": S.day}}
	J.enter_map("puerto", int(D.PARADAS.puerto.a[0]), int(D.PARADAS.puerto.a[1]), "down")
	MENUS = []
	QUIERO = ["Nada"]
	chk(corre(func(): await J.piso_menu("town")), "piso fuera bloqueado")
	chk(MENUS.size() and not MENUS[0].has("Dejar género"), "dejar género desde fuera: %s" % [MENUS])
	J.enter_map("town", 10, 10, "down")
	QUIERO = ["Dejar género", J.lot_nombre(sid), "1 kg", "Nada", "Nada"]
	chk(corre(func(): await J.piso_menu("town")), "dejar género bloqueado")
	chk(int(J.stock_piso(J.pisos_d().town)) == 1000 and int(J.total_buds()) == 1000, "almacén %s fuera %s" % [J.stock_piso(J.pisos_d().town), J.total_buds()])

	# 5 · cada mañana vende: más con barato, el rebajado rinde más gramos
	var F: Dictionary = J.pisos_d().town
	F.px = 1
	F.pur = 0
	var st0: float = J.stock_piso(F)
	J.pisos_dia()
	var v1: int = int(F.v)
	var c1: int = int(F.caja)
	var cap: int = int(round((float(R.dia) + float(R.lab) * 4) * float(R.px[1][2])))
	chk(v1 == cap and c1 > 0 and absf(st0 - J.stock_piso(F) - v1) < 1, "venta pura: %d g (%d) %d €" % [v1, cap, c1])
	F.px = 0
	F.caja = 0
	J.pisos_dia()
	chk(int(F.v) > v1, "barato vende más: %d > %d" % [F.v, v1])
	F.px = 1
	F.pur = 2
	var st1: float = J.stock_piso(F)
	J.pisos_dia()
	chk(st1 - J.stock_piso(F) < float(F.v) - 1, "rebajado: gasta %s para %s g" % [st1 - J.stock_piso(F), F.v])
	F.pur = 0
	# el alquiler: cobra a los 30 días (cobra) y el comprado no paga
	chk(int(F.r) == int(S.day) + int(R.per), "plazo %s" % F.r)
	# recoger la caja (solo aquí)
	var cj: int = int(F.caja)
	var m0: int = int(S.money)
	QUIERO = ["Recoger la caja", "Nada"]
	chk(corre(func(): await J.piso_menu("town")), "recoger bloqueado")
	chk(int(S.money) == m0 + cj and int(F.caja) == 0, "caja recogida %s → %s" % [m0, S.money])

	# 6 · la redada: a partir de PISOS9.cal.redada se pierde el almacén y la caja, y detienen al lugarteniente
	F.cal = float(R.cal.redada) + float(R.cal.baja)
	F.caja = 777
	J.pisos_dia()
	chk(J.stock_piso(F) == 0 and int(F.caja) == 0 and not S.plantilla.has(w) and J.lt_de("town") == null, "redada: %s %s" % [J.stock_piso(F), F.caja])
	chk(float(F.cal) == float(R.cal.vuelve), "calor tras la redada %s" % F.cal)
	# sin lugarteniente no vende y el calor baja
	J.pisos_dia()
	chk(int(F.v) == 0 and float(F.cal) < float(R.cal.vuelve), "sin lugarteniente %s %s" % [F.v, F.cal])
	# la sisa del poco leal: por hash, nunca más de lo vendido
	var w2 := {"id": "lt2", "n": "SISA", "lab": 2, "cui": 2, "lea": 1}
	S.plantilla.append(w2)
	w2.rol = "lugar"
	w2.pv = "puerto"
	J.pisos_d().puerto.buds = {sid: {"g": 5000.0, "thc": 18.0, "dia": S.day}}
	var s := 0
	for q in 8:
		J.pisos_d().puerto.caja = 0
		J.pisos_d().puerto.cal = 0.0
		J.pisos_dia()
		s += int(J.pisos_d().puerto.caja)
		S.day += 1
	chk(s > 0, "puerto vende %d" % s)
	# dejar el piso desde fuera con género: no; en el pueblo, todo vuelve
	J.pisos_d().puerto.caja = 50
	J.enter_map("puerto", int(D.PARADAS.puerto.a[0]), int(D.PARADAS.puerto.a[1]), "down")
	var g0: float = J.total_buds()
	var stp: float = J.stock_piso(J.pisos_d().puerto)
	QUIERO = ["Dejar el piso", "Sí"]
	chk(corre(func(): await J.piso_menu("puerto")), "dejar el piso bloqueado")
	chk(not J.pisos_d().has("puerto") and absf(J.total_buds() - g0 - stp) < 1 and w2.get("rol") == null and not w2.has("pv"), "dejado: %s %s" % [J.total_buds(), w2])
	# el alquiler sin pagar: se pierde el piso
	J.enter_map("town", 10, 10, "down")
	S.money = 0
	S.banco = 0
	J.pisos_d().town.r = S.day
	for q in 3:
		J.pisos_dia()
		S.day += 1
	chk(not J.pisos_d().has("town"), "sin pagar el alquiler: %s" % [J.pisos_d().keys()])

	# 7 · la ciudad: por el patrimonio neto
	S.money = 1000
	S.banco = 0
	S.debt = 0
	J.metro_dia()
	chk(not J.metro_ya(), "ciudad cerrada con poco")
	S.banco = int(MT.umbral)
	J.metro_dia()
	chk(J.metro_ya(), "ciudad abierta con %s" % J.patrimonio())
	chk(J.pisos_lista().has("metropoli"), "piso en la ciudad")
	# conducir: la ciudad sale en la lista y el tramo lleva el peaje
	S.coches = {"utilitario": {"km": 0, "r": 1, "dia": 0, "en": "ibarbide"}}
	J.enter_map("ibarbide", int(D.PARADAS.ibarbide.a[0]), int(D.PARADAS.ibarbide.a[1]), "down")
	var t0: Dictionary = J.tramo("ibarbide", "metropoli", "utilitario")
	var t1: Dictionary = J.tramo("ibarbide", "town", "utilitario")
	chk(int(t0.eur) >= int(MT.peaje) + 1 and int(t0.km) == int(MT.km) + int(D.CONCE.km.ibarbide), "tramo %s" % [t0])
	chk(int(t1.eur) < int(t0.eur), "sin peaje fuera de la ciudad")
	MENUS = []
	QUIERO = ["Hiriburu"]
	S.money = 5000
	chk(corre(func(): await J.conducir("utilitario")), "conducir bloqueado")
	chk(MENUS.size() and MENUS[0].has("Hiriburu") and S.map == "metropoli" and S.coches.utilitario.en == "metropoli", "a la ciudad: %s %s" % [MENUS, S.map])
	chk(J.coche_en(int(MT.aparc[0]), int(MT.aparc[1])) == "utilitario", "aparcado en la ciudad")
	# el mapa: puertas, gente, cajero y parada al alcance desde el aparcamiento
	var m: Dictionary = J.MAPS.metropoli
	var vis := alcanza(m, int(MT.aparc[0]) + 2, int(MT.aparc[1]))
	for k in m.doors:
		var p: PackedStringArray = k.split(",")
		chk(junto(vis, int(p[0]), int(p[1])) or vis.has(Vector2i(int(p[0]), int(p[1]) + 1)), "puerta %s" % k)
	chk(junto(vis, int(MT.concejal.x), int(MT.concejal.y)), "concejal")
	for f in MT.fac:
		chk(junto(vis, int(MT.fac[f].x), int(MT.fac[f].y)), "banda " + f)
		chk(m.o[int(MT.fac[f].y)][int(MT.fac[f].x)] == null and not J.tile_solid(m, int(MT.fac[f].x), int(MT.fac[f].y)), "sitio de la banda " + f)
	chk(junto(vis, 20, 9) and junto(vis, 2, 23), "cajero y parada")
	chk(vis.size() > 300, "casillas %d" % vis.size())
	for t in MT.ct:
		chk(not J.tile_solid(m, int(t[0]), int(t[1])) and m.o[int(t[1])][int(t[0])] == null, "cliente en %s" % [t])
	J.build_ents()
	var ids: Array = J.ents.map(func(x): return x.id)
	chk(ids.has("m9_concejal") and ids.has("m9_fac_puente") and ids.has("m9_fac_gris"), "gente %s" % [ids])
	for d in J.metro_npcs("metropoli") + J.metro_npcs("vip-zen") + J.metro_npcs("vip-ila"):
		chk(D.LOOKS.has(String(d.look)), "look " + String(d.look))
	# la parada de la ciudad: con tu vehículo, la autopista; el de línea a Ibarbide
	MENUS = []
	QUIERO = ["Nada"]
	chk(corre(J.parada_action), "parada bloqueada")
	chk(MENUS.size() and MENUS[0].any(func(l): return l.begins_with("Autobús de línea")), "parada: %s" % [MENUS])

	# 8 · los clubs VIP: comprar en la puerta (cuenta), la noche a la cuenta, las mejoras
	var zen: Dictionary = MT.vip.zen
	S.banco = int(zen.p) - 1
	QUIERO = ["Comprarlo"]
	var r0 = [null]
	chk(corre(func(): r0[0] = await J.vip_puerta("zen")), "puerta bloqueada")
	chk(not J.metro_d().vip.has("zen") and r0[0] == false, "comprado sin dinero")
	S.banco = int(zen.p) + 100000
	QUIERO = ["Comprarlo"]
	chk(corre(func(): r0[0] = await J.vip_puerta("zen")), "puerta bloqueada (2)")
	chk(J.metro_d().vip.has("zen") and int(S.banco) == 100000, "comprado %s" % S.banco)
	chk(corre(func(): r0[0] = await J.vip_puerta("zen")) and r0[0] == true, "entrar con la llave")
	J.enter_map("vip-zen", 9, 8, "up")
	var mv: Dictionary = J.MAPS["vip-zen"]
	var vv := alcanza(mv, 9, 8)
	chk(junto(vv, 9, 2) and vv.has(Vector2i(9, 9)) or mv.exits.has("9,9"), "encargado y salida")
	J.build_ents()
	chk(J.ents.any(func(x): return x.id == "m9_vip_zen"), "encargado dentro")
	chk(corre(func(): await J.obj_local(16, 1, "poster")), "objeto del club bloqueado")
	# la noche: a la cuenta, más con control del barrio
	S.heat = 0
	J.metro_d().sob = S.day + 99   # con el concejal, la clausura casi nunca
	var b0: int = int(S.banco)
	var bien := false
	for q in 5:
		S.day += 1
		J.metro_dia()
		if int(S.banco) > b0:
			bien = true
	chk(bien and int(J.metro_d().vip.zen.tot) > 0, "la noche a la cuenta %s → %s" % [b0, S.banco])
	var e0: int = J.vip_noche("zen")
	J.metro_d().ter.erdi.c = 100
	chk(J.vip_noche("zen") > e0, "con el barrio, más")
	J.metro_d().ter.erdi.c = 0
	QUIERO = ["Reservados", "Sí", "Nada"]
	chk(corre(func(): await J.talk_vip9("zen")), "mejora bloqueada")
	chk(int(J.metro_d().vip.zen.mj) == 1 and J.vip_noche("zen") > e0, "reservados %s" % [J.metro_d().vip.zen])

	# 9 · la clausura: sin concejal cae alguna vez en 200 días; con el sobre, bastantes menos
	var cuenta := func(sob: bool) -> int:
		var nc := 0
		for q in 200:
			J.metro_d().vip.zen.cl = 0
			J.metro_d().sob = (S.day + 5) if sob else 0
			S.heat = 60
			J.metro_dia()
			if int(J.metro_d().vip.zen.get("cl", 0)) > S.day:
				nc += 1
			S.day += 1
		return nc
	var sin: int = cuenta.call(false)
	var con: int = cuenta.call(true)
	chk(sin > 0 and con < sin, "clausuras sin %d con %d" % [sin, con])
	# precintado: no se entra
	J.metro_d().vip.zen.cl = S.day + 3
	chk(corre(func(): r0[0] = await J.vip_puerta("zen")) and r0[0] == false, "precinto")
	J.metro_d().vip.zen.cl = 0
	# el concejal: el sobre en efectivo
	J.enter_map("metropoli", 23, 10, "up")
	J.metro_d().sob = 0
	S.money = int(MT.concejal.sobre) + 10
	QUIERO = ["Darle el sobre"]
	chk(corre(J.talk_concejal), "concejal bloqueado")
	chk(int(J.metro_d().sob) == S.day + int(MT.concejal.per) and int(S.money) == 10, "sobre %s %s" % [J.metro_d().sob, S.money])

	# 10 · las bandas: pelear (gancho_combate), pactar, el empuje y la espera al llegar
	QUIERO = ["Plantarles cara en Erdialdea"]
	chk(corre(func(): await J.talk_fac("gris")), "banda bloqueada")
	chk(J.control("erdi") == int(MT.ter.pelea), "control tras ganar %d" % J.control("erdi"))
	J.gancho_combate = func(_k): return "ko"
	QUIERO = ["Plantarles cara en Erdialdea"]
	chk(corre(func(): await J.talk_fac("gris")), "banda bloqueada (ko)")
	chk(J.control("erdi") == int(MT.ter.pelea) - int(MT.ter.pierde), "control tras perder %d" % J.control("erdi"))
	J.gancho_combate = func(_k): return "win"
	S.money = int(MT.ter.pacto_e)
	QUIERO = ["Pactar"]
	chk(corre(func(): await J.talk_fac("puente")), "pacto bloqueado")
	chk(S.money == 0 and (J.control("ibai") == int(MT.ter.pacto) or J.control("gelt") == int(MT.ter.pacto)), "pacto %d %d" % [J.control("ibai"), J.control("gelt")])
	var emp := false
	for q in 40:
		S.day += 1
		J.metro_dia()
		if J.metro_d().at.size():
			emp = true
			break
	chk(emp, "las bandas empujan")
	var b: String = J.metro_d().at.keys()[0] if J.metro_d().at.size() else "erdi"
	var c0: int = J.control(b)
	QUIERO = ["Plantarles cara"]
	chk(corre(J.metro_llegada), "llegada bloqueada")
	chk(J.metro_d().at.is_empty() and J.control(b) > c0, "pelea al llegar %d → %d" % [c0, J.control(b)])
	chk(J.rival_b("rival").name != MT.fac.gris.jefe, "rival de siempre sin banda")
	J.rival_fac = "gris"
	chk(J.rival_b("rival").name == MT.fac.gris.jefe, "jefe de la banda")
	J.rival_fac = ""

	# 11 · una partida de antes (sin pisos ni metro) pasa el día sin errores
	S.erase("pisos")
	S.erase("metro")
	J.pisos_dia()
	J.metro_dia()
	chk(J.pisos_d().is_empty(), "partida vieja")

	print("metro: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
