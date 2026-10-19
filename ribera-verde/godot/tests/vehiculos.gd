# Landrace Hunters (Godot) — MAESTRO [3]: el vehículo en el garaje dibujado junto al piso de Ribera Verde (se sale desde su puerta); de la parada a otro pueblo, donde se queda en el
# aparcamiento de la parada (S.coches[k].en, plazas_parque) sin usarse por el mapa; el maletero por kg (MALETERO.kg) con la envasadora
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
	chk(corre(func(): await J.object_action(10, 8)), "garaje → Puerto Viejo en el utilitario")
	chk(MENUS.size() and MENUS[0].has("Maletero de la moto") and MENUS[0].has("Salir en la moto"), "en el garaje, los dos: %s" % [MENUS])
	chk(S.map == "puerto" and J.donde("utilitario") == "puerto" and J.donde("moto") == J.GARAJE and float(S.money) + float(S.banco) < c0, "llegas y se queda allí: %s %s" % [S.map, J.donde("utilitario")])
	chk(J.vehiculo() == null, "en Puerto Viejo, a pie")
	var pl: Array = J.plazas_parque("puerto")
	chk(pl.size() >= 1 and J.coche_en(pl[0].x, pl[0].y) == "utilitario", "en la primera plaza del aparcamiento: %s" % [pl])
	var m: Dictionary = J.MAPS.puerto
	chk(String(m.g[pl[0].y][pl[0].x]) != "walk" and not J.tile_solid(m, pl[0].x, pl[0].y), "la plaza, fuera de la acera (en Puerto Viejo, en la plaza: no hay calzada cerca): %s" % m.g[pl[0].y][pl[0].x])
	var pa: Array = D.PARADAS.puerto.a
	chk(absi(pl[0].x - int(pa[0])) + absi(pl[0].y - int(pa[1])) >= 2, "no tapa la bajada del autobús")
	for mp in D.PARADAS:
		chk(J.plazas_parque(mp).size() >= 2, "aparcamiento en %s: %d plazas" % [mp, J.plazas_parque(mp).size()])
	# 3) el coche aparcado no se atraviesa; con A delante: viajar o el maletero; en autobús, se queda
	J.P.x = pl[0].x
	J.P.y = pl[0].y + 1
	J.P.fx = J.P.x
	J.P.fy = J.P.y
	J.try_move("up")
	chk(J.P.y == pl[0].y + 1, "no se atraviesa")
	QUIERO = ["Viajar", "Ribera Verde"]
	chk(corre(func(): await J.coche_menu("utilitario")), "coche_menu → Ribera Verde")
	chk(S.map == "town" and J.donde("utilitario") == J.GARAJE and J.P.x == 10 and J.P.y == 9, "de vuelta, al garaje, en su puerta: %d,%d" % [J.P.x, J.P.y])
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
	QUIERO = ["Maletero del utilitario", "+"]
	MENUS = []
	chk(corre(func(): await J.object_action(10, 8)), "garaje → maletero")
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
	# 8) la envasadora, en la tienda online
	S.items.erase("vacio")
	S.banco = 1000
	QUIERO = ["Envasadora al vacío", "Salir"]
	chk(corre(func(): await J.tienda_online()), "tienda online")
	chk(S.items.get("vacio") and absf(float(S.banco) - (1000 - float(D.MALETERO.vacio.p))) < 0.01, "envasadora comprada: banco %s" % S.banco)
	# 9) sin CAL, como antes (1.43): montado por la calle en el mejor que tengas
	Datos.CAL = false
	J.enter_map("town", 3, 10, "down")
	chk(J.vehiculo() == "utilitario", "sin CAL, el mejor: %s" % J.vehiculo())
	chk(not t.blds.any(func(q): return q.id == "garaje") and t.o[8][9] == "sign" and t.o[8][1] == null and not J.tile_solid(t, 9, 7), "sin CAL, sin garaje y el cartel en su sitio")
	Datos.CAL = true
	print("vehiculos: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("FALLO ", f)
	quit()
