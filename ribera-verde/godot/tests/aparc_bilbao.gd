# Landrace Hunters (Godot) — Bilbao con aparcamiento (lo pidió el usuario: «En los nuevos mapas no hay parking, hay que estudiar el espacio jugable que no sea
# agobiante»): en cada zona nueva (Zorroza, La Punta, Abando, Casco Viejo), un aparcamiento de 3 × 4 (APARC, el mismo que BILBAO.APARC de tools/bilbao.py)
# en un hueco sin nada, con dos casillas libres alrededor y sin cortar el paso con las cuatro plazas llenas; en coche se va a cada zona y se aparca allí.
#   $GODOT --headless --path godot --script res://tests/aparc_bilbao.gd   → «aparc_bilbao: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

const MAPAS := ["zorroza", "lapunta", "abando", "casco"]
var J
var M
var MENUS := []
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
		if q != "" and labels[i] == q:
			k = i
	o = o.duplicate()
	o.initial = k
	return o

func _anda(m: Dictionary, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < int(m.w) and y < int(m.h) and J.pisable(m, x, y) and not J.tile_solid(m, x, y) and m.o[y][x] == null

func _llega(m: Dictionary, a: Vector2i, tapa: Dictionary) -> Dictionary:
	var vis := {a: 1}
	var q := [a]
	while q.size():
		var c: Vector2i = q.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var v: Vector2i = c + d
			if not vis.has(v) and not tapa.has(v) and J.pisable(m, v.x, v.y) and not J.tile_solid(m, v.x, v.y):
				vis[v] = 1
				q.append(v)
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
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-aparc-bilbao.json"
	Juego.AJUSTES = "user://prueba-aparc-bilbao-ajustes.json"
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
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D: Dictionary = J.D
	var S = J.S
	S.ch = 8
	S.min = 12 * 60
	S.money = 20000
	S.flags.conce = true
	# 1. el aparcamiento de cada zona, el de tools/bilbao.py, en un hueco sin nada y con aire alrededor
	var BA: Dictionary = D.get("BILBAO", {}).get("APARC", {})
	for k in MAPAS:
		chk(J.APARC.has(k) and BA.has(k) and int(J.APARC[k][0]) == int(BA[k][0]) and int(J.APARC[k][1]) == int(BA[k][1]), "%s: APARC = BILBAO.APARC (%s, %s)" % [k, J.APARC.get(k), BA.get(k)])
		if not J.APARC.has(k):
			continue
		var m: Dictionary = J.MAPS[k]
		var x0: int = int(J.APARC[k][0])
		var y0: int = int(J.APARC[k][1])
		var vacio := true
		for y in range(y0, y0 + 4):
			for x in range(x0, x0 + 3):
				vacio = vacio and _anda(m, x, y) and not m.blds.any(func(b): return b.id != "aparcamiento" and x >= int(b.x0) and x < int(b.x0) + int(b.w) and y >= int(b.y0) and y < int(b.y0) + int(b.h))
		chk(vacio, "%s: el hueco de 3 × 4, sin nada" % k)
		var aire := []   # la primera vuelta, libre del todo (sin farolas ni bancos pegados); la segunda, sin fachadas (el mobiliario, sí)
		var casa := []
		for y in range(y0 - 2, y0 + 6):
			for x in range(x0 - 2, x0 + 5):
				var dentro := x >= x0 and x < x0 + 3 and y >= y0 and y < y0 + 4
				var borde := x < 0 or y < 0 or x >= int(m.w) or y >= int(m.h)
				var uno := x >= x0 - 1 and x <= x0 + 3 and y >= y0 - 1 and y <= y0 + 4
				if dentro or borde:
					continue
				if uno and not _anda(m, x, y):
					aire.append(Vector2i(x, y))
				var g: String = String(m.g[y][x])
				if g.begins_with("roof") or g.begins_with("wall") or m.blds.any(func(b): return b.id != "aparcamiento" and x >= int(b.x0) and x < int(b.x0) + int(b.w) and y >= int(b.y0) and y < int(b.y0) + int(b.h)):
					casa.append(Vector2i(x, y))
		chk(aire.is_empty(), "%s: una casilla libre alrededor (estorban %s)" % [k, aire])
		chk(casa.is_empty(), "%s: ninguna fachada a dos casillas (%s)" % [k, casa])
		J.montar_aparcamiento(k)
		chk(m.blds.any(func(b): return b.id == "aparcamiento" and int(b.x0) == x0 and int(b.y0) == y0) and String(m.g[y0][x0]).begins_with("road"), "%s: dibujado" % k)
		var p0 := Vector2i(x0 + 2, y0)
		var tapa := {}
		for y in range(y0, y0 + 4):
			tapa[Vector2i(x0, y)] = 1
			tapa[Vector2i(x0 + 1, y)] = 1
		var antes := _llega(m, p0, {})
		var ahora := _llega(m, p0, tapa)
		chk(antes.size() > 200 and antes.keys().all(func(c): return tapa.has(c) or ahora.has(c)), "%s: con las cuatro plazas llenas se llega a todo (%d)" % [k, antes.size()])
	# 2. en coche: desde Zorroza, a cada zona; se aparca en la suya y te deja en el pasillo
	S.coches = {"utilitario": {"dia": 0, "p": 20000, "r": S.day + 365, "iv": S.day + 365, "en": "zorroza", "ap": S.day}}
	J.enter_map("zorroza", 4, 10, "down")
	J.mode = "world"
	for z in ["lapunta", "abando", "casco", "zorroza"]:
		var de: String = J.donde("utilitario")
		var nm: String = J.nombre_lugar(z)
		QUIERO = [nm]
		MENUS = []
		chk(corre(func(): await J.conducir("utilitario")), "de %s a %s" % [de, z])
		var ls: Array = MENUS[0] if MENUS.size() else []
		chk(MAPAS.all(func(q): return q == de or ls.has(J.nombre_lugar(q))), "desde %s salen las otras tres zonas: %s" % [de, ls])
		chk(S.map == z and J.donde("utilitario") == z, "llegas a %s y se queda allí (%s, %s)" % [z, S.map, J.donde("utilitario")])
		var ll: Array = J.llegada_parque(z, "utilitario")
		chk(J.P.x == int(ll[0]) and J.P.y == int(ll[1]) and J.P.x == int(J.APARC[z][0]) + 2, "%s: en el pasillo, junto a su plaza (%d, %d)" % [z, J.P.x, J.P.y])
		chk(J.coche_en(int(J.APARC[z][0]), int(J.APARC[z][1])) == "utilitario", "%s: en la primera plaza" % z)
	chk(int(J.tramo("lapunta", "casco", "utilitario").km) == J.BILBAO_KM and int(J.tramo("zorroza", "abando", "utilitario").km) == J.BILBAO_KM, "de una zona a otra, %d km por la calle" % J.BILBAO_KM)
	chk(J.tramo("abando", "puerto", "utilitario").km == J.tramo("zorroza", "puerto", "utilitario").km, "a los pueblos, como desde Zorroza")
	# 3. desde otro pueblo se llega a cualquiera de las cuatro
	S.coches.utilitario.en = "puerto"
	J.enter_map("puerto", 17, 9, "down")
	QUIERO = [J.nombre_lugar("abando")]
	MENUS = []
	chk(corre(func(): await J.conducir("utilitario")) and S.map == "abando" and J.donde("utilitario") == "abando", "de Puerto Viejo a Abando: %s" % S.map)
	var ls2: Array = MENUS[0] if MENUS.size() else []
	chk(MAPAS.all(func(q): return ls2.has(J.nombre_lugar(q))), "desde Puerto Viejo, las cuatro: %s" % [ls2])
	print("aparc_bilbao: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
