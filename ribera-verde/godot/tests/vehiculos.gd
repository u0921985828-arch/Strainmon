# Landrace Hunters (Godot) — MAESTRO [3]: el vehículo en el garaje dibujado junto al piso de Ribera Verde (se sale desde su puerta); de la parada a otro pueblo, donde se queda en el
# aparcamiento dibujado junto a la parada (S.coches[k].en, APARC, plazas_parque) sin usarse por el mapa; el maletero por kg (MALETERO.kg) con la envasadora
# al vacío y el control de tráfico con el maletero; sin Datos.CAL, como antes.
#   $GODOT --headless --path godot --script res://tests/vehiculos.gd   → «vehiculos: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Motor = preload("res://src/motor.gd")

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

func _llega(m: Dictionary, a: Vector2i, tapa: Dictionary) -> Dictionary:   # las casillas a las que se llega andando desde a
	var vis := {a: 1}
	var q := [a]
	while q.size():
		var c: Vector2i = q.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not vis.has(n) and not tapa.has(n) and J.pisable(m, n.x, n.y) and not J.tile_solid(m, n.x, n.y):
				vis[n] = 1
				q.append(n)
	return vis

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s mov %s run %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode, J.P.moving, J.get("corriendo")])
			return false
	return true

const Atlas = preload("res://src/atlas.gd")

func _garaje_utilitario() -> void:   # A en la puerta del garaje (se entra) y A en el utilitario
	await J.object_action(10, 8)
	await J.object_action(1, 5)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-vehiculos.json"
	Juego.AJUSTES = "user://prueba-vehiculos-ajustes.json"
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
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = J.D
	var S = J.S
	S.money = 5000
	S.coches = {"utilitario": {"dia": 0, "p": 20000, "r": S.day + 365, "iv": S.day + 365}, "moto": {"dia": 0, "p": 4000, "r": S.day + 365, "iv": S.day + 365}}
	S.ch = 4
	# 1) con CAL, por el mapa siempre a pie: el vehículo está en el garaje (Ribera Verde) y no se pinta ni estorba
	J.enter_map("town", 3, 10, "down")
	J.mode = "world"
	chk(J.vehiculo() == null and J.donde("utilitario") == J.GARAJE, "a pie y el utilitario en el garaje: %s %s" % [J.vehiculo(), J.donde("utilitario")])
	chk(J.aparcados("town") == ["moto", "utilitario"] and J.coche_en(3, 11) == "", "en el garaje, no en la calle")
	# 1b) el garaje, dibujado junto al piso: 2 × 3 casillas a la derecha del portal, sólido, la puerta en la fila de la acera
	var t: Dictionary = J.MAPS.town
	var gb: Dictionary = J.GARAJE_B
	chk(t.blds.any(func(q): return q.id == "garaje" and int(q.x0) == 9 and int(q.y0) == 6) and Atlas.frame_de("edificio-garaje", "base", "unica", 0, {"i": 0}) != null, "el garaje en el mapa, con su fachada")
	var home: Dictionary = t.blds.filter(func(q): return q.id == "home")[0]
	chk(int(gb.x0) == int(home.x0) + int(home.w) and int(gb.y0) + int(gb.h) == int(home.y0) + int(home.h), "pegado al piso, a ras de su fachada")
	chk(J.tile_solid(t, 9, 7) and J.tile_solid(t, 10, 8) and t.o[8][9] == "garaje" and t.o[8][10] == "garaje", "sólido, con la puerta abajo")
	chk(t.o[8][1] == "sign" and String(D.SIGNS.get("town:1,8", "")).begins_with("Calle Ribera"), "el cartel del piso, al otro lado del portal")
	# la parada de Ribera Verde, solo el autobús: el coche sale del garaje
	QUIERO = ["Nada"]
	MENUS = []
	J.S.min = 600
	corre(func(): await J.parada_action())
	chk(not MENUS.any(func(mm): return mm.any(func(l): return String(l).begins_with("En el utilitario") or String(l).begins_with("Maletero"))), "en la parada de Ribera Verde, sin el coche: %s" % [MENUS])
	# 2) desde el garaje: viajar en él (gasolina) y se queda en el aparcamiento de la parada de destino
	J.P.x = 10
	J.P.y = 9
	J.P.fx = 10
	J.P.fy = 9
	J.P.dir = "up"
	QUIERO = ["Salir en el utilitario", "Puerto Viejo"]
	MENUS = []
	var c0: float = float(S.money) + float(S.banco)
	chk(corre(func(): await J.object_action(10, 8)) and S.map == "garaje", "A en la puerta: dentro del garaje (%s)" % S.map)
	var gm: Dictionary = J.MAPS.garaje
	chk(gm.w == 14 and gm.h == 10 and gm.o[5][1] == "expoU" and gm.o[5][5] == "expoU2" and gm.o[8][8] == "expoMo" and gm.o[5][8] == null, "los dos, aparcados en su plaza: %s %s" % [gm.o[5].slice(0, 6), gm.o[8].slice(8, 10)])
	chk(J.tile_solid(gm, 3, 5) or gm.o[5][3] != null, "el coche no se atraviesa")
	chk(corre(func(): await J.object_action(3, 5)), "A en el utilitario → Puerto Viejo")
	chk(MENUS.size() and MENUS[0].has("Salir en el utilitario") and MENUS[0].has("Abrir el maletero") and MENUS[0].any(func(l): return String(l).begins_with("Echar gasolina")) and not MENUS[0].any(func(l): return String(l).contains("abono")), "en el coche, salir, el maletero o la gasolina: %s" % [MENUS])
	chk(S.map == "puerto" and J.donde("utilitario") == "puerto" and J.donde("moto") == J.GARAJE and float(S.money) + float(S.banco) < c0, "llegas y se queda allí: %s %s" % [S.map, J.donde("utilitario")])
	chk(J.vehiculo() == null, "en Puerto Viejo, a pie")
	chk(int(S.coches.utilitario.get("ap", -1)) == int(S.day), "aparcado hoy: %s" % S.coches.utilitario.get("ap"))
	var pl: Array = J.plazas_parque("puerto")
	chk(pl.size() >= 1 and J.coche_en(pl[0].x, pl[0].y) == "utilitario", "en la primera plaza del aparcamiento: %s" % [pl])
	var m: Dictionary = J.MAPS.puerto
	chk(m.blds.any(func(q): return q.id == "aparcamiento" and int(q.x0) == pl[0].x and int(q.y0) == pl[0].y) and Atlas.frame_de("edificio-aparcamiento", "base", "unica", 0, {"i": 0}) != null, "el aparcamiento dibujado, con el coche en su primera plaza")
	chk(J.coche_en(pl[0].x + 1, pl[0].y) == "utilitario" and J.P.x == pl[0].x + 2 and J.P.y == pl[0].y, "la plaza es de 2 casillas y te deja en el pasillo, a su lado: %d,%d" % [J.P.x, J.P.y])
	var pa: Array = D.PARADAS.puerto.a
	chk(absi(pl[0].x - int(pa[0])) + absi(pl[0].y - int(pa[1])) >= 2, "no tapa la bajada del autobús")
	for mp in J.APARC:   # en cada pueblo: dibujado junto a la parada, en suelo libre, y con los coches en sus plazas no corta el paso
		J.montar_aparcamiento(mp)
		var mm: Dictionary = J.MAPS[mp]
		var q: Array = J.APARC[mp]
		var a: Array = D.PARADAS[mp].a if D.PARADAS.has(mp) else [int(q[0]) + 2, int(q[1])]   # Bilbao: sin parada, desde el pasillo (tests/aparc_bilbao.gd)
		var libre := true
		for y in range(q[1], q[1] + 4):
			for x in range(q[0], q[0] + 3):
				libre = libre and not J.tile_solid(mm, x, y) and J.pisable(mm, x, y)
		chk(libre and mm.blds.any(func(b): return b.id == "aparcamiento"), "aparcamiento en %s, libre" % mp)
		chk(not D.PARADAS.has(mp) or absi(int(q[0]) + 1 - int(a[0])) + absi(int(q[1]) + 2 - int(a[1])) <= 12, "en %s, junto a la parada" % mp)
		var tapa := {}
		for y in range(q[1], q[1] + 4):
			tapa[Vector2i(q[0], y)] = 1
			tapa[Vector2i(q[0] + 1, y)] = 1
		var antes := _llega(mm, Vector2i(int(a[0]), int(a[1])), {})
		var ahora := _llega(mm, Vector2i(int(a[0]), int(a[1])), tapa)
		chk(antes.keys().all(func(c): return tapa.has(c) or ahora.has(c)), "en %s, con las cuatro plazas llenas se llega a todo" % mp)
	# 3) el coche aparcado no se atraviesa; con A delante: viajar o el maletero; en autobús, se queda
	J.P.x = pl[0].x
	J.P.y = pl[0].y + 1
	J.P.fx = J.P.x
	J.P.fy = J.P.y
	J.try_move("up")
	chk(J.P.y == pl[0].y + 1, "no se atraviesa")
	QUIERO = ["Viajar", "Ribera Verde"]
	chk(corre(func(): await J.coche_menu("utilitario")), "coche_menu → Ribera Verde")
	chk(S.map == "garaje" and J.donde("utilitario") == J.GARAJE and [J.P.x, J.P.y] == J.llegada_garaje("utilitario").slice(0, 2), "de vuelta, al garaje por dentro, junto a su plaza: %s %d,%d" % [S.map, J.P.x, J.P.y])
	J.enter_map("town", 10, 9, "up")
	QUIERO = ["Puerto Viejo"]   # en Ribera Verde, la parada es solo del autobús
	chk(corre(func(): await J.parada_action()), "en autobús")
	chk(S.map == "puerto" and J.donde("utilitario") == J.GARAJE, "en autobús, el coche se queda en el garaje")
	QUIERO = ["En autobús", "Ribera Verde"]
	corre(func(): await J.parada_action())
	# 4) el maletero: capacidad en kg por vehículo, guardar y sacar
	chk(J.mal_kg("utilitario") == 150000.0 and J.mal_kg("moto") == 40000.0 and J.mal_kg("deportivo") == 30000.0, "MALETERO.kg")
	J.add_buds("ria", 100, 18.0)
	var b0: float = J.total_buds()
	chk(corre(func(): await J.guardar_mal("utilitario")), "guardar en el maletero")
	chk(absf(J.mal_g("utilitario") - b0) < 0.01 and J.total_buds() < 1, "guardado %.1f de %.1f" % [J.mal_g("utilitario"), b0])
	J.mal("moto").buds = {}
	J.add_buds("ria", 60, 18.0)
	J.S.coches.moto.mal.buds["x"] = {"g": 39990.0, "thc": 18.0}
	chk(corre(func(): await J.guardar_mal("moto")), "guardar en la moto llena")
	chk(J.mal_g("moto") <= 40000.0 and J.total_buds() >= 1, "no pasa de 40 kg: %.1f" % J.mal_g("moto"))
	J.S.coches.moto.mal.buds = {}
	J.S.buds = {}
	# 5) al vacío: sin envasadora no; con ella, todo
	S.items.erase("vacio")
	chk(corre(func(): await J.envasar("utilitario")) and not J.mal_vacio("utilitario"), "sin envasadora, nada")
	S.items.vacio = 1
	chk(corre(func(): await J.envasar("utilitario")) and J.mal_vacio("utilitario"), "envasado al vacío")
	# 6) el control: con el maletero; al vacío, la probabilidad × vacio.f
	var ctl: float = D.CONCE.control
	var vf: float = D.MALETERO.vacio.f
	D.CONCE.control = 1.0
	S.heat = 100
	D.MALETERO.vacio.f = 0.0
	chk(corre(func(): await J.control_trafico("utilitario")) and J.mal_g("utilitario") >= 100, "al vacío (f = 0), no lo notan: %.1f" % J.mal_g("utilitario"))
	D.MALETERO.vacio.f = 1.0
	chk(corre(func(): await J.control_trafico("utilitario")) and J.mal_g("utilitario") < 1, "registro: el maletero, requisado")
	chk(LOG.any(func(t): return "maletero" in String(t)), "lo dice el agente")
	D.CONCE.control = ctl
	D.MALETERO.vacio.f = vf
	# 7) el maletero desde el garaje (en la vista, el «+» de guardar y luego cerrar)
	var gal := [0]
	J.gancho_almacen = func(tt):
		gal[0] += 1
		if gal[0] > 1:
			return null
		var its: Array = J.items_almacen(tt)
		for i in its.size():
			if its[i].k == "+":
				return i
		return null
	J.enter_map("town", 10, 9, "up")
	J.add_buds("ria", 20, 18.0)
	QUIERO = ["Abrir el maletero", "+"]
	MENUS = []
	chk(corre(_garaje_utilitario), "garaje → A en el utilitario → maletero")
	chk(J.mal_g("utilitario") >= 1, "guardado desde el garaje: %.1f" % J.mal_g("utilitario"))
	J.S.buds = {}
	# y en Puerto Viejo, desde la parada (el coche, aparcado allí)
	S.coches.utilitario.en = "puerto"
	J.enter_map("puerto", int(D.PARADAS.puerto.a[0]), int(D.PARADAS.puerto.a[1]), "down")
	J.add_buds("ria", 20, 18.0)
	var g7: float = J.mal_g("utilitario")
	gal[0] = 0
	QUIERO = ["Maletero del utilitario", "+"]
	chk(corre(func(): await J.parada_action()), "parada de Puerto Viejo → maletero")
	chk(J.mal_g("utilitario") > g7, "guardado desde la parada: %.1f" % J.mal_g("utilitario"))
	S.coches.utilitario.erase("en")
	J.gancho_almacen = Callable()
	J.S.buds = {}
	# 7b) el maletero cura en botes (con los tarros, como la caja fuerte); lo envasado al vacío, no
	J.mal("utilitario").buds = {"ria": {"g": 30.0, "thc": 18.0, "dia": S.day}, "ak": {"g": 10.0, "thc": 18.0, "dia": S.day, "vac": true}}
	var tar0 = S.items.get("tarros")
	S.items.erase("tarros")
	var av := []
	J.curado_dia(av)
	chk(float(J.mal("utilitario").buds.ria.get("cu", 0)) == 0.0, "sin tarros, en el maletero no se cura")
	S.items.tarros = 1
	for d in int(D.CURADO.dias):
		J.curado_dia(av)
	chk(float(J.mal("utilitario").buds.ria.get("cu", 0)) >= 1.0 and float(J.mal("utilitario").buds.ria.thc) > 18.0, "con los tarros, curada en el maletero: %s" % [J.mal("utilitario").buds.ria])
	chk(float(J.mal("utilitario").buds.ak.get("cu", 0)) == 0.0, "lo envasado al vacío no se cura")
	chk(av.any(func(t): return "maletero del utilitario" in String(t)), "el aviso del curado: %s" % [av])
	if tar0 == null:
		S.items.erase("tarros")
	else:
		S.items.tarros = tar0
	J.mal("utilitario").buds = {}
	# 7c) el abono de floración al maletero y, en Valdehierro, a los tanques de la nave (cuenta en el peso del maletero)
	S.items.fert = 20
	S.items.ofert = 8
	S.coches.utilitario.en = "puerto"   # el abono, desde el aparcamiento (en el garaje, la gasolina: lo pidió el usuario)
	J.enter_map("puerto", int(D.PARADAS.puerto.a[0]), int(D.PARADAS.puerto.a[1]), "down")
	QUIERO = ["Cargar abono en el utilitario"]
	chk(corre(func(): await J.coche_menu("utilitario")), "aparcamiento → cargar el abono")
	chk(int(J.mal_ab("utilitario").m) == 20 and int(J.mal_ab("utilitario").o) == 8 and int(S.items.fert) == 0 and int(S.items.ofert) == 0, "el abono, en el maletero: %s" % [J.mal_ab("utilitario")])
	chk(absf(J.mal_peso("utilitario") - 28 * float(D.MALETERO.dosis)) < 0.01, "pesa: %.0f g" % J.mal_peso("utilitario"))
	var nave0 = S.get("nave")
	S.nave = J.nave_nueva()
	var abm: float = float(S.nave.ab.m)
	S.coches.utilitario.en = "valdehierro"
	J.enter_map("valdehierro", int(D.PARADAS.valdehierro.a[0]), int(D.PARADAS.valdehierro.a[1]), "down")
	QUIERO = ["Rellenar los tanques de la nave"]
	MENUS = []
	chk(corre(func(): await J.coche_menu("utilitario")), "en Valdehierro → rellenar los tanques")
	chk(float(S.nave.ab.m) == abm + 20 and float(S.nave.ab.o) == 8 and int(J.mal_ab("utilitario").m) == 0, "los tanques de la nave, rellenos: %s" % [S.nave.ab])
	S.coches.utilitario.en = "puerto"
	J.enter_map("puerto", 20, 9, "down")
	S.items.fert = 0
	MENUS = []
	QUIERO = ["Nada"]
	corre(func(): await J.coche_menu("utilitario"))
	chk(MENUS.size() and not MENUS[0].has("Rellenar los tanques de la nave"), "fuera de Valdehierro, no se rellena: %s" % [MENUS])
	chk(MENUS.size() and MENUS[0][2].begins_with("Echar gasolina") and MENUS[0].has("Viajar") and MENUS[0].has("Maletero"), "en el aparcamiento, también la gasolina: %s" % [MENUS])
	# 7c2) echar gasolina en el aparcamiento (lo pidió el usuario: «arregla lo de rellenar la gasolina»)
	S.coches.utilitario.gas = 10.0
	var ef0: float = float(S.money)
	S.money = maxf(ef0, 500.0)
	ef0 = float(S.money)
	QUIERO = ["Echar gasolina"]
	MENUS = []
	chk(corre(func(): await J.coche_menu("utilitario")), "aparcamiento → echar gasolina")
	chk(absf(J.gas_de("utilitario") - float(J.TANQUE.get("utilitario", 40))) < 0.11 and float(S.money) < ef0, "depósito lleno desde el aparcamiento: %.1f L, %.0f → %.0f €" % [J.gas_de("utilitario"), ef0, S.money])
	MENUS = []
	QUIERO = ["Nada"]
	corre(func(): await J.coche_menu("utilitario"))
	chk(MENUS.size() and MENUS[0][2] == "Echar gasolina (lleno)", "lleno: %s" % [MENUS])
	S.coches.utilitario.erase("en")
	S.nave = nave0
	# 7d) el estado de cada vehículo se guarda con la partida (S.coches: dónde está, km, maletero y abono), JSON puro
	J.mal("utilitario").buds = {"ria": {"g": 5.0, "thc": 18.0}}
	S.coches.utilitario.en = "puerto"
	var cj: String = JSON.stringify(S.coches)
	var cp = JSON.parse_string(cj)
	chk(cp is Dictionary and cp.utilitario.en == "puerto" and float(cp.utilitario.mal.buds.ria.g) == 5.0 and cp.utilitario.mal.has("ab"), "S.coches, JSON puro: %s" % cj.substr(0, 120))
	S.coches.utilitario.erase("en")
	J.mal("utilitario").buds = {}
	# 8) la envasadora, en la tienda online
	S.items.erase("vacio")
	S.banco = 1000
	QUIERO = ["Envasadora al vacío", "Salir"]
	chk(corre(func(): await J.tienda_online()), "tienda online")
	chk(S.items.get("vacio") and absf(float(S.banco) - (1000 - float(D.MALETERO.vacio.p))) < 0.01, "envasadora comprada: banco %s" % S.banco)
	# 8b) más de CONCE.multa.dias aparcado en otro pueblo: te pueden multar (cada día, CONCE.multa.p); en el garaje, nunca
	var MU: Dictionary = D.CONCE.multa
	var d0: int = int(S.day)
	S.coches.utilitario.en = "puerto"
	S.coches.utilitario.ap = d0
	var dinero := func(): return float(S.money) + float(S.banco) + float(S.caja.money if S.get("caja") is Dictionary else 0)
	var mo0 = S.money
	S.money = 100000
	var antes := 0
	var multas := 0
	for d in 200:
		S.day = d0 + d
		var x0: float = dinero.call()
		J.multa_aparcado("utilitario")
		if dinero.call() < x0 - 0.01:
			chk(absf(x0 - dinero.call() - float(MU.e)) < 0.01, "la multa es de %s" % MU.e)
			if d <= int(MU.dias):
				antes += 1
			multas += 1
	var E: float = (200 - int(MU.dias) - 1) * float(MU.p)
	chk(antes == 0 and absf(multas - E) <= 4 * sqrt(E) + 3, "multas: %d en 200 días (esperadas %.0f), %d antes de %d días" % [multas, E, antes, int(MU.dias)])
	chk(J.pending.size() or J.queued.size(), "con su SMS")
	S.coches.utilitario.erase("en")
	var x1: float = dinero.call()
	for d in 50:
		S.day = d0 + 300 + d
		J.multa_aparcado("utilitario")
	chk(absf(dinero.call() - x1) < 0.01 and not S.coches.utilitario.has("ap"), "en el garaje, sin multa")
	S.day = d0
	S.money = mo0
	# 9) sin CAL, como antes (1.43): montado por la calle en el mejor que tengas
	Datos.CAL = false
	J.enter_map("town", 3, 10, "down")
	chk(J.vehiculo() == "utilitario", "sin CAL, el mejor: %s" % J.vehiculo())
	chk(not t.blds.any(func(q): return q.id == "garaje") and t.o[8][9] == "sign" and t.o[8][1] == null and not J.tile_solid(t, 9, 7), "sin CAL, sin garaje y el cartel en su sitio")
	J.enter_map("puerto", 20, 9, "down")
	chk(not J.MAPS.puerto.blds.any(func(q): return q.id == "aparcamiento") and String(J.MAPS.puerto.g[10][17]) == "plaza", "sin CAL, sin aparcamiento")
	Datos.CAL = true
	print("vehiculos: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("FALLO ", f)
	quit()
