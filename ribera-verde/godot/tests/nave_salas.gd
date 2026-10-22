# Ribera Verde (Godot) — la nave por salas (lo pidió el usuario: «las estanterías de curado están en medio de la nave»): con
# Datos.CAL la nave queda para el cultivo, el secadero y las estanterías del curado van a su sala (nave-s, por la puerta 14)
# y la habitación se entra desde el despacho (puerta en (7, 1)); sin CAL, la nave de siempre con el secadero en (6, 2).
#   $GODOT --headless --path godot --script res://tests/nave_salas.gd   → «nave_salas: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const At = preload("res://tests/atrezo.gd")

var J
var M
var MENUS := []
var LOG := []
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
	o = o.duplicate()
	o.initial = labels.size() - 1
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
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s log %s menus %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode, LOG, MENUS])
			return false
	return true

func cuenta(mapa: String, o: String) -> int:
	var c := 0
	for fila in J.MAPS[mapa].o:
		for x in fila:
			if x == o:
				c += 1
	return c

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-nave-salas.json"
	Juego.AJUSTES = "user://prueba-nave-salas-ajustes.json"
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
	J.S.erase("desp")
	J.S.nave.erase("cur")
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	J.gancho_almacen = func(_t): return null
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = J.D
	var CU: Dictionary = D.CURADO_NAVE
	# 1 · con CAL: la nave sin secadero ni estanterías; la sala con los dos
	J.enter_map("nave", 9, 4, "up")
	chk(cuenta("nave", "secadero") == 0 and cuenta("nave", "estanteC") == 0, "la nave con secadero %d estanterías %d" % [cuenta("nave", "secadero"), cuenta("nave", "estanteC")])
	chk(J.MAPS["nave"].o[1][14] == "puertaM", "puerta del secadero en la nave: %s" % J.MAPS["nave"].o[1][14])
	J.enter_map("nave-s", 1, 2, "up")
	J.mode = "world"
	var sc: Array = CU.secadero
	chk(J.MAPS["nave-s"].o[int(sc[1])][int(sc[0])] == "secadero", "secadero en la sala")
	chk(cuenta("nave-s", "estanteC") == int(CU.est), "estanterías de serie en la sala %d" % cuenta("nave-s", "estanteC"))
	# como el camarote (lo pidió el usuario): 10 × 6, con el suelo y las paredes de la nave y una baldosa libre entre estanterías
	var mS: Dictionary = J.MAPS["nave-s"]
	chk(int(mS.w) == int(J.MAPS["camarote"].w) and int(mS.h) == int(J.MAPS["camarote"].h), "nave-s %dx%d" % [mS.w, mS.h])
	chk(mS.g[0][4] == "iwT_nave" and mS.g[1][4] == "iwB_nave" and mS.g[3][4] == "floorN", "suelo y paredes de la nave: %s %s %s" % [mS.g[0][4], mS.g[1][4], mS.g[3][4]])
	for i in CU.sitio.size() - 1:
		var a0: Array = CU.sitio[i]
		var a1: Array = CU.sitio[i + 1]
		chk(int(a0[1]) == int(a1[1]) and int(a1[0]) - int(a0[0]) == 2 and mS.o[int(a0[1])][int(a0[0]) + 1] == null, "hueco entre %s y %s" % [a0, a1])
	var ac: Array = At.accesos(J, "nave-s")
	chk(ac.is_empty(), "accesos nave-s: %s" % [ac])
	# A en el secadero y en una estantería
	LOG = []
	chk(corre(func(): await J.obj_local(int(sc[0]), int(sc[1]), "secadero")), "secadero bloqueado")
	chk(LOG.any(func(t): return t.contains("secadero") or t.contains("seca")) or MENUS.size(), "secadero sin respuesta: %s" % [LOG])
	var est: Array = []
	for q in CU.sitio:
		if J.MAPS["nave-s"].o[int(q[1])][int(q[0])] == "estanteC" and est.is_empty():
			est = q
	chk(corre(func(): await J.obj_local(int(est[0]), int(est[1]), "estanteC")), "estantería bloqueada")
	# la ampliación: el doble de estanterías, todas en la sala y accesibles
	J.navc()["mj"] = 1
	J.enter_map("nave-s", 1, 2, "up")
	chk(cuenta("nave-s", "estanteC") == 2 * int(CU.est), "con la ampliación %d" % cuenta("nave-s", "estanteC"))
	ac = At.accesos(J, "nave-s")
	chk(ac.is_empty(), "accesos nave-s ampliada: %s" % [ac])
	J.enter_map("nave", 9, 4, "up")
	chk(cuenta("nave", "estanteC") == 0, "la nave sigue libre con la ampliación")
	# 2 · el despacho (de lujo) con la puerta de la habitación y su paso libre
	J.S.desp = {"money": 0, "buds": {}}
	J.enter_map("nave-d", 3, 3, "up")
	var md = J.MAPS["nave-d"]
	chk(md.o[1][7] == "puertaM", "puerta de la habitación en el despacho: %s" % md.o[1][7])
	chk(not J.tile_solid(md, 7, 2), "delante de la puerta, libre")
	# el cuadro del lujo cuelga en la pared, encima del escritorio: se ve, no se toca
	# los monitores, dentro de la pared (lo pidió el usuario: «la tele está encima de la pared»): el sprite de 48 con la base en la
	# fila 1 empieza 16 px por encima del canto de la pared; ahí, nada
	var im: Image = J.Atlas.frame("%s/monD/unica/00" % J.Atlas.cubre("obj:monD"))
	var alto := 0
	for y in 17:
		for x in im.get_width():
			if im.get_pixel(x, y).a > 0.0:
				alto += 1
	chk(im.get_height() == 48 and alto == 0, "monitores por encima de la pared: %d px" % alto)
	ac = At.accesos(J, "nave-d").filter(func(t): return not String(t).begins_with("cuadro"))
	chk(ac.is_empty(), "accesos nave-d: %s" % [ac])
	J.enter_map("nave-h", 1, 2, "up")
	chk(J.MAPS["nave-h"].o[1][1] == "puertaM", "puerta del despacho en la habitación")
	ac = At.accesos(J, "nave-h")
	chk(ac.is_empty(), "accesos nave-h: %s" % [ac])
	# 3 · sin CAL, la nave de siempre: el secadero en (6, 2)
	Datos.CAL = false
	J.MAPS["nave"] = D.MAPS["nave"].duplicate(true)   # la partida sin CAL empieza con los mapas de datos.json
	J.enter_map("nave", 9, 4, "up")
	chk(J.MAPS["nave"].o[2][6] == "secadero", "sin CAL, secadero en (6, 2): %s" % J.MAPS["nave"].o[2][6])
	chk(cuenta("nave", "estanteC") == 0, "sin CAL, sin estanterías")
	Datos.CAL = true
	print("nave_salas: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
