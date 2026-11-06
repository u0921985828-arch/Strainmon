# Landrace Hunters (Godot) — el garaje por dentro (lo pidió el usuario: «un garage por dentro, grande como el taller, pero que estén
# aparcados ahí los vehículos, A en cada vehículo para salir, abrir el maletero es un menú como el del dispensario, pero con forma de
# maletero de coche, o cargar gasolina del coche, no abono»), con Datos.CAL: A en la puerta del garaje entra al mapa de 14 × 10 con
# cada vehículo en su plaza; A en cada uno, salir, el maletero (la vista con forma de maletero) o llenar el depósito con las
# garrafas; el viaje gasta primero del depósito; se vuelve a su plaza; todo alcanzable; guardar y cargar dentro. Sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/garaje.gd [-- --sin-arranque --salida DIR]   → «garaje: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Atlas = preload("res://src/atlas.gd")

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
			print("  bloqueo: fin %s libre %s pend %s modo %s" % [st.fin, J.is_free(), J.pending.size(), J.mode])
			return false
	return true

func dicho(t: String) -> bool:
	return LOG.any(func(l): return String(l).contains(t))

func foto(dir: String, k: String, A = null) -> void:
	if dir == "":
		return
	J.oraculo = false
	J.toast_box.hide()
	J.ALMACEN = A
	if A != null:
		J._dlg_fijo(J.desc_almacen(A), "MALETERO")
	else:
		J.dlg.hide()
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("garaje-%s.png" % k))
	J.ALMACEN = null
	J.oraculo = true

func llega(m: Dictionary, a: Vector2i) -> Dictionary:   # las casillas a las que se llega andando desde a
	var vis := {a: 1}
	var q := [a]
	while q.size():
		var c: Vector2i = q.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nn: Vector2i = c + d
			if nn.x >= 0 and nn.y >= 0 and nn.x < int(m.w) and nn.y < int(m.h) and not vis.has(nn) and J.pisable(m, nn.x, nn.y) and not J.tile_solid(m, nn.x, nn.y):
				vis[nn] = 1
				q.append(nn)
	return vis

func junto(vis: Dictionary, x: int, y: int) -> bool:   # ¿se puede llegar al lado de (x, y)?
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if vis.has(Vector2i(x, y) + d):
			return true
	return false

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-garaje.json"
	Juego.AJUSTES = "user://prueba-garaje-ajustes.json"
	Datos.CAL = true
	var dir := arg("--salida")
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
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
	var D = J.D
	var S = J.S
	S.mode = "world"
	J.mode = "world"
	S.ch = 9
	S.min = 600
	S.money = 2000.0
	S.banco = 5000.0
	S.heat = 0
	Cultivo.fijo = .99   # sin controles de tráfico ni caídas
	# 0 · vacío: A en la puerta, dentro, y te lo dice
	S.coches = {}
	J.enter_map("town", 10, 9, "up")
	LOG = []
	chk(corre(func(): await J.object_action(10, 8)), "A en la puerta del garaje")
	chk(S.map == "garaje" and J.P.x == int(J.GARAJE_SALE[0]) and J.P.y == 8, "dentro, junto al portón (%s %d,%d)" % [S.map, J.P.x, J.P.y])
	chk(dicho("Está vacío"), "vacío, te lo dice: %s" % [LOG])
	var m: Dictionary = J.MAPS.garaje
	chk(int(m.w) == 14 and int(m.h) == 10 and m.g[0][0] == "iwT_taller" and m.g[1][5] == "iwB_taller" and String(m.g[4][2]).begins_with("floorTc"), "14 × 10, a la medida de cuatro plazas: paredes y hormigón")
	var lineas := true
	for y in J.GARAJE_LINEA:   # cada línea, de punta a punta de las plazas y sin cruzar el pasillo
		for x in int(m.w):
			lineas = lineas and (m.g[y][x] == "floorGl") == (not x in J.GARAJE_SALE)
	chk(lineas, "las líneas de las plazas: enteras y sin cruzar el pasillo")
	chk(not m.g.any(func(r): return r.has("floorTcR")), "ninguna línea suelta a lo alto")
	for k in J.GARAJE_PLAZA:   # cada plaza, cerrada por su línea de atrás y la de delante, y el vehículo dentro
		var pl: Array = J.GARAJE_PLAZA[k]
		var y0 := int(pl[1])
		chk(J.GARAJE_LINEA.has(y0 + 1) and J.GARAJE_LINEA.has(y0 - 2) and int(pl[0]) + int(pl[3]) <= int(m.w) and (int(pl[0]) + int(pl[3]) <= int(J.GARAJE_SALE[0]) or int(pl[0]) > int(J.GARAJE_SALE[1])), "la plaza de %s, entre dos líneas a 3 m y fuera del pasillo" % k)
	chk(not m.o.any(func(r): return r.any(func(o): return o != null and String(o).begins_with("expo") or o == "gS")), "sin vehículos, plazas vacías")
	for k in ["grifoG", "garrafasG"]:
		chk(Atlas.frame_de("garaje-alto", k, "unica", 0, {"i": 0}) != null, "sprite %s" % k)
	chk(Atlas.frame_de("garaje-coche", "gS", "unica", 0, {"i": 0}) != null, "sprite gS")
	# 1 · los cuatro, en su plaza
	for k in D.CONCE.orden:
		S.coches[k] = {"dia": 0, "p": 1000, "r": S.day + 365, "iv": S.day + 365}
	J.enter_map("garaje", 7, 8, "up")
	m = J.MAPS.garaje
	for k in D.CONCE.orden:
		var pl: Array = J.GARAJE_PLAZA[k]
		var ok: bool = m.o[int(pl[1])][int(pl[0])] == pl[2]
		for j in range(1, int(pl[3])):
			ok = ok and m.o[int(pl[1])][int(pl[0]) + j] == String(pl[2]) + "2"
		chk(ok and J.coche_garaje(int(pl[0]) + int(pl[3]) - 1, int(pl[1])) == k, "%s en su plaza %s" % [k, pl])
		chk(J.tile_solid(m, int(pl[0]), int(pl[1])) or not J.pisable(m, int(pl[0]), int(pl[1])), "%s no se atraviesa" % k)
	chk(J.coche_en(1, 5) == "" and J.aparcados("garaje").is_empty(), "en el garaje no se pintan los de la calle")
	# 2 · todo alcanzable desde el portón: el lado de cada vehículo, cada cosa del atrezo y la salida
	var vis := llega(m, Vector2i(int(J.GARAJE_SALE[0]), 8))
	for k in D.CONCE.orden:
		var pl: Array = J.GARAJE_PLAZA[k]
		chk(junto(vis, int(pl[0]), int(pl[1])) and vis.has(Vector2i(int(J.llegada_garaje(k)[0]), int(J.llegada_garaje(k)[1]))), "se llega a %s y a su sitio de bajar" % k)
	for a in J.GARAJE_ATREZO:
		chk(junto(vis, int(a[0]), int(a[1])) or int(a[1]) <= 1, "se llega a %s" % a[2])
		chk(String(J.ATREZO_TXT.garaje.get(a[2], "")) != "", "%s tiene su texto" % a[2])
	for x in J.GARAJE_SALE:
		chk(vis.has(Vector2i(x, 8)) and m.exits.has("%d,9" % x) and m.exits["%d,9" % x].to == "town", "el portón (%d, 9) sale a la calle" % x)
	# 3 · A en un vehículo: salir, el maletero o la gasolina; nada de abono
	S.items.fert = 4
	QUIERO = ["Nada"]
	MENUS = []
	chk(corre(func(): await J.object_action(3, 5)), "A en el utilitario")
	var mm: Array = MENUS[0] if MENUS.size() else []
	chk(mm.size() == 4 and mm[0] == "Salir en el utilitario" and mm[1] == "Abrir el maletero" and String(mm[2]).begins_with("Echar gasolina (45 L") and mm[3] == "Nada", "el menú del coche: %s" % [mm])
	chk(not mm.any(func(l): return String(l).contains("abono")), "sin abono")
	# 4 · la gasolina: lo que falta del depósito, en efectivo; lleno, no
	var e0: float = float(S.money)
	var cu: int = ceili(45 * float(D.CONCE.litro))
	QUIERO = ["Echar gasolina"]
	LOG = []
	chk(corre(func(): await J.object_action(1, 5)), "echar gasolina")
	chk(absf(J.gas_de("utilitario") - 45.0) < 0.01 and absf(e0 - float(S.money) - cu) < 0.01 and dicho("45 L"), "depósito lleno, %d € (%s, %s)" % [cu, J.gas_de("utilitario"), S.money])
	QUIERO = ["Echar gasolina"]
	LOG = []
	MENUS = []
	corre(func(): await J.object_action(1, 5))
	chk(MENUS.size() and MENUS[0][2] == "Echar gasolina (lleno)" and dicho("ya está lleno") and absf(e0 - float(S.money) - cu) < 0.01, "lleno: no se cobra: %s" % [MENUS])
	S.money = 0
	S.banco = 0
	QUIERO = ["Echar gasolina"]
	LOG = []
	corre(func(): await J.object_action(10, 5))
	chk(J.gas_de("berlina") == 0.0 and dicho("Para la gasolina"), "sin dinero, no se llena")
	S.money = 2000.0
	S.banco = 5000.0
	# 5 · salir con el depósito lleno: el viaje no se paga (gasta del depósito) y vuelve a su plaza
	var tr: Dictionary = J.tramo("town", "puerto", "utilitario")
	chk(tr.eur == 0, "con el depósito lleno, a Puerto Viejo sin pagar (%s)" % [tr])
	e0 = float(S.money) + float(S.banco)
	QUIERO = ["Salir en el utilitario", "Puerto Viejo"]
	chk(corre(func(): await J.object_action(2, 5)), "salir en el utilitario")
	var l1: float = 45.0 - int(D.CONCE.km.puerto) * float(D.CONCE.v.utilitario.l) / 100.0
	chk(S.map == "puerto" and J.donde("utilitario") == "puerto" and absf(float(S.money) + float(S.banco) - e0) < 0.01 and absf(J.gas_de("utilitario") - snappedf(l1, 0.1)) < 0.01, "en Puerto Viejo, del depósito (%s L)" % J.gas_de("utilitario"))
	J.enter_map("garaje", 7, 8, "up")
	chk(J.MAPS.garaje.o[5][1] == null and J.coche_garaje(1, 5) == "", "su plaza, vacía mientras está fuera")
	S.coches.utilitario.gas = 0.5   # casi vacío: se paga lo que falta
	J.enter_map("puerto", int(D.PARADAS.puerto.a[0]), int(D.PARADAS.puerto.a[1]), "down")
	var falta: float = int(D.CONCE.km.puerto) * float(D.CONCE.v.utilitario.l) / 100.0 - 0.5
	chk(J.tramo("puerto", "town", "utilitario").eur == maxi(1, roundi(falta * float(D.CONCE.litro))), "casi vacío, se paga lo que falta")
	QUIERO = ["En el utilitario", "Ribera Verde"]
	chk(corre(func(): await J.parada_action()), "de vuelta en el utilitario")
	var lg: Array = J.llegada_garaje("utilitario")
	chk(S.map == "garaje" and J.P.x == int(lg[0]) and J.P.y == int(lg[1]) and J.MAPS.garaje.o[5][1] == "expoU" and J.gas_de("utilitario") == 0.0, "a su plaza del garaje, y bajas al lado (%s %d,%d)" % [S.map, J.P.x, J.P.y])
	# 6 · el maletero: la vista con forma de maletero, del color de cada vehículo
	for k in D.CONCE.orden:
		J.MAL_K = k
		var R: Array = J.rects_almacen({"t": "mal", "i": 0})
		var col: String = J.MAL_COLOR[k][1]
		var dentro := true
		for r in R:
			if r[0] is String:
				continue
			dentro = dentro and int(r[0]) >= 0 and int(r[0]) + int(r[2]) <= J.SW and int(r[1]) >= 0
		chk(R.any(func(r): return not (r[0] is String) and r[4] == col) and dentro, "el maletero %s, con su color y en pantalla" % k)
		chk(R.any(func(r): return not (r[0] is String) and r[4] == "#f0f0ea") == (k != "moto"), "%s: matrícula sin letras (la moto, el baúl)" % k)
	J.add_buds(D.STRAINS.keys()[0], 20, 18.0)
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
	QUIERO = ["Abrir el maletero"]
	chk(corre(func(): await J.object_action(3, 5)), "A en el utilitario → el maletero")
	chk(J.mal_g("utilitario") >= 1, "guardado en el maletero desde el garaje: %.1f" % J.mal_g("utilitario"))
	J.gancho_almacen = Callable()
	# 7 · salir andando por el portón, a la calle delante del garaje
	J.enter_map("garaje", 7, 9, "down")
	chk(corre(func(): await J.warp(J.MAPS.garaje.exits["7,9"])), "salir por el portón")
	chk(S.map == "town" and J.P.x == int(J.GARAJE_B.x0) + 1 and J.P.y == int(J.GARAJE_B.y0) + int(J.GARAJE_B.h), "en la calle, delante de la puerta (%s %d,%d)" % [S.map, J.P.x, J.P.y])
	# 8 · caso reservado: guardar dentro y cargar (el mapa se rehace con los que hay)
	J.enter_map("garaje", 7, 8, "up")
	if dir != "":
		S.coches.utilitario.gas = 30.0
		await foto(dir, "dentro")
		J.MAL_K = "utilitario"
		await foto(dir, "maletero", {"t": "mal", "i": 0})
		J.MAL_K = "deportivo"
		await foto(dir, "maletero-deportivo", {"t": "mal", "i": 0})
		J.MAL_K = "moto"
		await foto(dir, "maletero-moto", {"t": "mal", "i": 0})
	J.save()
	var s2 = JSON.parse_string(FileAccess.get_file_as_string(Juego.GUARDADO))
	J.MAPS.erase("garaje")
	J.S = Datos.enteros(s2)
	J.migrate()
	J.enter_game()
	chk(J.S.map == "garaje" and J.MAPS.has("garaje") and J.MAPS.garaje.o[5][1] == "expoU" and J.MAPS.garaje.o[8][1] == "gS", "guardado y cargado dentro del garaje (%s)" % J.S.map)
	# 9 · sin CAL: ni se entra ni hay mapa
	Datos.CAL = false
	J.MAPS.erase("garaje")
	J.enter_map("town", 10, 9, "up")
	chk(J.MAPS.town.o[8][10] != "garaje" and not J.MAPS.has("garaje"), "sin CAL, sin garaje por dentro")
	Datos.CAL = true
	for f in fallos:
		print("  FALLO " + f)
	print("garaje: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
