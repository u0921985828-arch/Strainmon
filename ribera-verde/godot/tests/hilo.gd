# Ribera Verde (Godot) — el cuaderno azul de la tía Maite (hilo.gd, con CAL; lo pidió el usuario: «le falta historia, falta
# contexto»): Kiko, Delroy, los tres trozos en cualquier orden, la lata de la huerta y las tres elecciones; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/hilo.gd   → «hilo: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var LOG := []
var MENUS := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	MENUS.append(items.map(func(it): return it if it is String else str(it.get("label", ""))))
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
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
			print("  bloqueo")
			return false
	return true

# desde la parada del autobús y las salidas del mapa, andando
func alcance(mapa: String) -> Dictionary:
	var m: Dictionary = J.MAPS[mapa]
	var q := []
	if J.D.PARADAS.has(mapa):
		q.append([int(J.D.PARADAS[mapa].a[0]), int(J.D.PARADAS[mapa].a[1])])
	for mk in J.MAPS:   # donde te deja cada salida que lleva aquí
		for k in J.MAPS[mk].exits:
			var ex: Dictionary = J.MAPS[mk].exits[k]
			if ex.to == mapa:
				q.append([int(ex.x), int(ex.y)])
	var v := {}
	var i := 0
	while i < q.size():
		var c: Array = q[i]
		i += 1
		var kk := "%d,%d" % [c[0], c[1]]
		if v.has(kk) or not J.pisable(m, c[0], c[1]) or m.o[c[1]][c[0]]:
			continue
		v[kk] = true
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			q.append([c[0] + d[0], c[1] + d[1]])
	return v

func habla(id: String) -> bool:
	var e = null
	for x in J.ents:
		if x.id == id:
			e = x
	if e == null:
		return false
	return corre(func(): await J.npc_talk(e.def))


func habla_id(id: String) -> bool:
	return corre(func(): await J.npc_talk({"id": id, "map": J.S.map}))

func dia() -> bool:
	return corre(func(): J.hilo_dia())

func mundo(mapa: String, x: int, y: int) -> bool:
	J.enter_map(mapa, x, y, "down")
	J.mode = "world"
	return corre(func(): pass)

func dicho(t: String) -> bool:
	return LOG.any(func(l): return String(l).contains(t))

func nuevo(e: Dictionary) -> void:
	J.S = e.duplicate(true)
	J.S.erase("hilo")
	J.S.ch = 4
	J.S.flags.letter = 1
	J.S.flags.pagina = 1
	J.S.flags.lao = 1
	J.S.flags.txaro = 1
	J.S.money = 1000
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-hilo.json"
	Juego.AJUSTES = "user://prueba-hilo-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var S0: Dictionary = e.S
	# 1 · antes del capítulo 3, nada; en el 3, el SMS de Kiko al amanecer (una vez)
	nuevo(S0)
	J.S.ch = 2
	chk(dia() and J.hilo_p() == 0 and not J.hilo_visible(), "capítulo 2: sin hilo")
	J.S.ch = 3
	LOG = []
	chk(dia() and J.hilo_p() == 1, "capítulo 3: el paso 1")
	chk(mundo("town", 7, 12) and dicho("pásate por la tienda"), "el SMS de Kiko sale en la calle")
	chk(dia() and J.hilo_p() == 1, "el SMS, una sola vez")
	# 2 · OBJETIVO: la fila y su menú
	MENUS = []
	QUIERO = ["LA TÍA MAITE", "Volver", "Volver"]
	chk(corre(func(): await J.objetivo_menu()), "OBJETIVO abre")
	chk(MENUS.size() >= 2 and MENUS[0].has("LA TÍA MAITE") and MENUS[1].has("Un mensaje de Kiko"), "la fila LA TÍA MAITE y su paso: %s" % [MENUS.slice(0, 2)])
	# 3 · Kiko y Delroy
	J.S.map = "shop"
	LOG = []
	chk(habla_id("kiko") and J.hilo_p() == 2 and dicho("cuaderno"), "Kiko cuenta lo del cuaderno azul")
	var k2: int = LOG.size()
	chk(habla_id("kiko") and J.hilo_p() == 2 and not LOG.slice(k2).any(func(l): return String(l).contains("dos cuadernos")), "después, Kiko de siempre")
	chk(habla_id("delroy") and J.hilo_p() == 3 and dicho("Toño"), "Delroy: la noche del 98")
	# 4 · los tres trozos, en otro orden; sin lo de antes de cada uno, lo de siempre
	J.S.flags.erase("txaro")
	chk(habla_id("txaro") and not J.hilo().tr.has("txaro"), "Txaro sin lo del aceite: lo de siempre")
	J.S.flags.txaro = 1
	QUIERO = ["Tomarte el café"]
	chk(habla_id("txaro") and J.hilo().tr.has("txaro") and int(J.hilo().cor) == 1, "Txaro: el trozo y el café")
	var m0 := float(J.S.money)
	QUIERO = ["Encender"]
	chk(habla_id("bi_serora") and J.hilo().tr.has("serora") and is_equal_approx(float(J.S.money), m0 - 50) and int(J.hilo().cor) == 2, "la serora: la vela y 50 €")
	J.S.flags.erase("pagina")
	chk(habla_id("miren") and not J.hilo().tr.has("miren"), "Miren sin la página: lo de siempre")
	J.S.flags.pagina = 1
	chk(J.hilo_p() == 3 and J.hilo_trozos() == 2, "con dos trozos, todavía no")
	LOG = []
	QUIERO = ["Tienes prisa"]
	chk(habla_id("miren") and J.hilo_trozos() == 3 and J.hilo_p() == 4 and dicho("manzano") and int(J.hilo().cor) == 2, "Miren: el tercero y se juntan")
	chk(habla_id("miren") and J.hilo_p() == 4, "Miren otra vez: lo de siempre")
	# 5 · la lata: en otro mapa no; en la huerta, sí, y se elige
	chk(mundo("town", 7, 12) and J.hilo_p() == 4, "en la calle, nada")
	var s0: int = int(J.S.seeds.get("silver", 0))
	QUIERO = ["Contarlo"]
	chk(mundo("huerta", 15, 13) and J.hilo_p() == 5 and int(J.hilo().el) == 0 and int(J.S.seeds.get("silver", 0)) == s0 + 5, "la lata: 5 semillas y contarlo")
	chk(mundo("huerta", 15, 13) and J.hilo_p() == 5 and int(J.S.seeds.get("silver", 0)) == s0 + 5, "la lata, una vez")
	chk(habla_id("baltasar") and J.hilo_p() == 5, "con «contarlo», Baltasar, lo de siempre")
	var l0: int = int(J.S.seeds.get("lamb", 0))
	var r0 := float(J.S.rep)
	LOG = []
	chk(habla_id("delroy") and J.hilo_p() == 6 and int(J.S.seeds.get("lamb", 0)) == l0 + 3 and is_equal_approx(float(J.S.rep), r0 + 5), "Delroy lo cuelga: semillas y reputación")
	chk(mundo("town", 7, 12) and dicho("quedarte con la gente"), "el SMS del final, con corazón")
	MENUS = []
	QUIERO = ["Volver"]
	chk(corre(func(): await J.hilo_menu()) and MENUS.size() and MENUS[0].size() == 7 and J.hilo_derecha() == "6/6", "el menú, seis pasos hechos: %s" % [MENUS])
	# 6 · ir a por Baltasar
	nuevo(S0)
	J.S.hilo = {"p": 4, "tr": {"miren": 1, "serora": 1, "txaro": 1}, "cor": 0, "el": -1, "d": {}}
	QUIERO = ["Ir a por"]
	chk(mundo("huerta", 15, 13) and J.hilo_p() == 5 and int(J.hilo().el) == 1, "Baltasar elegido")
	chk(habla_id("delroy") and J.hilo_p() == 5, "con Baltasar, Delroy lo de siempre")
	var m1 := float(J.S.money)
	LOG = []
	chk(habla_id("baltasar") and J.hilo_p() == 6 and is_equal_approx(float(J.S.money), m1 + 3000), "Baltasar paga 3.000 €")
	chk(mundo("town", 7, 12) and dicho("Baltasar no regala nada") and dicho("Planta esas semillas"), "el SMS del final, sin corazón: %s" % [LOG])
	# 7 · guardártelo: se cierra en la huerta; la partida guardada y cargada sigue
	nuevo(S0)
	J.S.hilo = {"p": 4, "tr": {"miren": 1, "serora": 1, "txaro": 1}, "cor": 1, "el": -1, "d": {}}
	QUIERO = ["Guardártelo"]
	chk(mundo("huerta", 15, 13) and J.hilo_p() == 6 and int(J.hilo().el) == 2, "guardártelo: cerrado ahí")
	var js: Dictionary = JSON.parse_string(JSON.stringify(J.S))
	J.S = js
	chk(J.hilo_p() == 6 and J.hilo_derecha() == "6/6", "por JSON (floats), igual")
	# 8 · sin CAL, nada
	nuevo(S0)
	Datos.CAL = false
	J.S.ch = 4
	chk(dia() and not J.S.has("hilo") and not J.hilo_visible(), "sin CAL, sin hilo")
	J.S.map = "shop"
	LOG = []
	chk(habla_id("kiko") and not dicho("dos cuadernos"), "sin CAL, Kiko de siempre")
	Datos.CAL = true
	print("hilo: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
