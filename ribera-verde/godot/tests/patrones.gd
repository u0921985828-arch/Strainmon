# Ribera Verde (Godot) — los esquemas de macetas de las carpas (con CAL; lo pidió el usuario: «Posibilidad de poner x de cierto tamaño,
# elegir por patrones igual, cuando ya tienes ciertas macetas para completar todo el esquema de la carpa te ofrece poner X cantidad
# dependiendo de cada maceta»): la maceta de 50 L (MACETA50) y KC_PATRON; en KAIA, cada carpa con su esquema (kc_pat, kc_esquema):
# con las macetas que tienes o pidiendo las que faltan, con la carpa vacía, las plazas de las demás en su sitio, la luz repartida al
# mismo ritmo, el dibujo a escala y, al vender las carpas, las tuyas a la mochila (las del kit, no); la de 50 L, solo con la licencia;
# en casa, completar las plazas vacías con las macetas que tienes (completa_macetas) sin pasar de la tierra, también desde una plaza
# que ya lleva esa maceta; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/patrones.gd   → «patrones: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var LOG := []
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

func dicho(t: String) -> bool:
	return LOG.any(func(l): return String(l).contains(t))

func mundo(mapa: String, x: int, y: int) -> bool:
	J.enter_map(mapa, x, y, "down")
	J.mode = "world"
	return corre(func(): pass)

func it_m(k: String) -> int:
	return int(J.S.items.get("m_" + k, 0))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-patrones.json"
	Juego.AJUSTES = "user://prueba-patrones-ajustes.json"
	Datos.CAL = true
	Datos.carga()
	Atlas.carga()
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
	var D: Dictionary = J.D
	var KC: Dictionary = D.KAIA_CULT
	var C: String = KC.mapa
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	if J.S.get("nave") is Dictionary:
		if not J.S.nave.has("ma"):
			J.S.nave.ma = []
		if not J.S.nave.has("r"):
			J.S.nave.r = int(J.S.day) + 30
	# 1 · los datos: la de 50 L, solo con CAL y solo en KAIA; los esquemas, en rejilla y sin pasar de la tierra del suelo
	chk(D.MACETAS.has("tela50") and int(D.MACETAS.tela50.l) == 50 and D.MACETA_CM.has("tela50") and D.SHOP.filter(func(s): return s.get("maceta") == "tela50").size() == 1, "la de 50 L, en la tienda una vez")
	var ms: Array = D.SHOP.map(func(s): return str(s.get("maceta", "")))
	chk(ms.find("tela50") == ms.find("tela35") + 1, "detrás de la de 35 L")
	chk(D.CARPAS.values().all(func(c): return int(c.lmax) < 50), "ninguna carpa de casa la admite")
	for N in KC.niv:
		var P: Array = D.KC_PATRON[N.k]
		var suelo: float = float(N.cm[0]) * float(N.cm[1]) / 1e4 * float(D.LITROS_M2)
		chk(P.map(func(q): return q[0]) == ["tela25", "tela35", "tela50"] and P.all(func(q): return int(q[1]) * int(D.MACETAS[q[0]].l) <= suelo), "%s: 25, 35 y 50 L, sin pasar de %d L: %s" % [N.n, int(suelo), P])
		var m2 := float(N.cm[0]) * float(N.cm[1]) / 1e4
		chk(int(P[0][1]) == roundi(4 * m2) and int(P[1][1]) == roundi(2.25 * m2) and int(P[2][1]) == roundi(m2), "%s: 4 × 4, 3 × 3 y 2 × 2 cada 2 × 2 m" % N.n)
	Datos.CAL = false
	Datos.carga()
	chk(not D.MACETAS.has("tela50") and D.SHOP.filter(func(s): return s.get("maceta") == "tela50").is_empty(), "sin CAL, no está")
	Datos.CAL = true
	Datos.carga()
	chk(D.MACETAS.has("tela50") and D.SHOP.filter(func(s): return s.get("maceta") == "tela50").size() == 1, "con CAL otra vez, una")
	# 2 · KAIA: dos carpas de 200 × 200 con el kit de serie (4 de 35 L)
	if not (J.S.get("mar") is Dictionary):
		J.S.mar = {}
	var t50: Dictionary = D.SHOP.filter(func(s): return s.get("maceta") == "tela50")[0]
	J.S.mar.erase("lic")
	chk(not J.shop_cond(t50), "la de 50 L, sin la licencia de KAIA, no se vende")
	J.S.mar.lic = int(J.S.day)
	chk(J.shop_cond(t50), "con la licencia, sí")
	J.S.kc = {"niv": 0, "kits": [0, 0], "p": []}
	J.S.banco = 1000
	for k in ["tela25", "tela35", "tela50"]:
		J.S.items["m_" + k] = 0
	J.kc()
	chk(J.kc().p.size() == 4 * 4 + 2 * 8 + 16 and J.kc_n(0) == 4 and J.kc_pat(0).m == "tela35" and J.kc_off(1) == 4, "de serie, como antes: 4 plazas por carpa (%d)" % J.kc().p.size())
	chk(J.kc_tengo(0, "tela35") == 0 and J.kc_puedes(0) == "", "las 4 del kit no cuentan como tuyas")
	chk(mundo(C, 1, 2) and J.MAPS[C].o[3][13] == "carpaKS0", "dentro, la carpa 1")
	J.S.seeds = {"txoko": 5}
	QUIERO = ["Plaza 1", J.strain("txoko").n]
	MENUS = []
	chk(corre(func(): await J.object_action(13, 3)) and J.kc().p[0] is Dictionary, "plantada en la carpa 1")
	chk(MENUS.size() and MENUS[0].size() == 6 and MENUS[0][4] == "Esquema de la carpa", "la carpa: 4 plazas, el esquema y salir (%s)" % [MENUS[0] if MENUS.size() else []])
	var planta: Dictionary = J.kc().p[0].duplicate(true)
	J.kc().p[4] = planta.duplicate(true)   # la carpa 2, plaza 1
	J.kc().p[4].sid = "ria"
	QUIERO = ["Esquema de la carpa", "16 macetas de 25 L"]
	MENUS = []
	LOG = []
	chk(corre(func(): await J.object_action(13, 3)) and J.kc_n(0) == 4 and dicho("Antes, cosecha"), "con plantas, el esquema no cambia")
	chk(MENUS.size() >= 2 and MENUS[1] == ["16 macetas de 25 L", "9 macetas de 35 L", "4 macetas de 50 L", "Salir"], "los tres esquemas (%s)" % [MENUS])
	J.kc().p[0] = null
	# 3 · 16 de 25 L sin tener ninguna: se piden las 16 por la cuenta y las 4 de 35 L, a la mochila
	var pr: float = J.kc_precio_maceta("tela25")
	QUIERO = ["Esquema de la carpa", "16 macetas de 25 L", "Pedirlas y ponerlas"]
	LOG = []
	chk(corre(func(): await J.object_action(13, 3)) and J.kc_pat(0).m == "tela25" and J.kc_n(0) == 16, "16 de 25 L (%s · %s)" % [J.kc_pat(0), LOG.slice(-2)])
	chk(pr > 0 and is_equal_approx(float(J.S.banco), 1000.0 - 16 * pr) and it_m("tela25") == 0 and it_m("tela35") == 0, "pagadas por la cuenta (%d €) y las 4 del kit, no a la mochila (%d)" % [int(1000 - J.S.banco), it_m("tela35")])
	chk(J.kc().p.size() == 16 + 3 * 4 + 2 * 8 + 16 and J.kc_off(1) == 16 and J.kc().p[16] is Dictionary and J.kc().p[16].sid == "ria" and J.kc_plantadas(1) == 1 and J.kc_ci(16) == 1 and J.kc_ci(15) == 0, "la planta de la carpa 2, en su plaza (%d plazas)" % J.kc().p.size())
	MENUS = []
	QUIERO = ["Plaza 16", J.strain("txoko").n]
	chk(corre(func(): await J.object_action(14, 2)) and J.kc().p[15] is Dictionary and J.kc_plantadas(0) == 1 and MENUS.size() and MENUS[0].size() == 18, "la carpa 1, con 16 plazas: plantada la 16 (%d filas)" % [MENUS[0].size() if MENUS.size() else 0])
	chk(J.sprite_local("carpaKS0") == "kcs-1" and J.sprite_local("carpaKS1") == "kcs-1", "el dibujo, a escala: %s %s" % [J.sprite_local("carpaKS0"), J.sprite_local("carpaKS1")])
	for j in 15:
		J.kc().p[j] = planta.duplicate(true)
	chk(J.kc_dibujo(0) == 4 and J.sprite_local("carpaKS0") == "kcs-4", "llena, las cuatro del dibujo")
	for j in 15:
		J.kc().p[j] = null
	# 4 · la luz, repartida, al mismo ritmo
	var f16: Dictionary = J.kc_f(0)
	var f4: Dictionary = J.kc_f(1)
	chk(is_equal_approx(float(f16.g) * 16 / (float(f4.g) * 4), float(D.MACETAS.tela25.rend) / float(D.MACETAS.tela35.rend)), "los mismos gramos por carpa, por la maceta: %.1f g × 16 y %.1f g × 4" % [float(f16.g), float(f4.g)])
	chk(is_equal_approx(float(f16.crec) / float(f4.crec), float(D.MACETAS.tela25.crec) / float(D.MACETAS.tela35.crec)), "al mismo ritmo: el esquema no acelera (×%.3f)" % (float(f16.crec) / float(f4.crec)))
	chk(is_equal_approx(float(J.kc_hu(15).f.crec), float(f16.crec)) and is_equal_approx(float(J.kc_hu(16).f.crec), float(f4.crec)), "cada plaza, con su carpa")
	var p15: Dictionary = J.kc().p[15]
	var p16: Dictionary = J.kc().p[16]
	var a15 := float(p15.prog)
	var a16 := float(p16.prog)
	J.plants_advance(600)
	chk(float(p15.prog) > a15 and float(p16.prog) > a16 and is_equal_approx(float(p15.water), 100.0), "crecen las dos, con el goteo")
	# 5 · lo que ya tienes: te ofrece completar el esquema, y sin pagar
	J.kc().p[16] = null
	J.S.items.m_tela35 = 9
	LOG = []
	MENUS = []
	QUIERO = ["Salir"]
	corre(func(): await J.kc_lista(1))
	chk(J.kc_puedes(1) == "9 de 35 L", "la carpa 2: con 9 de 35 L en la mochila, puedes 9 de 35 L («%s»)" % J.kc_puedes(1))
	var b0: float = float(J.S.banco)
	QUIERO = ["Esquema de la carpa", "9 macetas de 35 L", "Ponerlas"]
	chk(corre(func(): await J.kc_lista(1)) and J.kc_n(1) == 9 and J.kc_pat(1).m == "tela35" and is_equal_approx(float(J.S.banco), b0) and it_m("tela35") == 0, "9 de 35 L con las tuyas, sin pagar; las del kit, no (quedan %d)" % it_m("tela35"))
	chk(J.kc().p.size() == 16 + 9 + 4 + 4 + 2 * 8 + 16 and J.kc_off(2) == 25 and J.kc().p[15] is Dictionary, "las plazas: 16 + 9 + 4 + 4")
	QUIERO = ["Esquema de la carpa", "9 macetas de 35 L"]
	LOG = []
	chk(corre(func(): await J.kc_lista(1)) and dicho("ya lleva ese esquema"), "el mismo, no")
	J.S.banco = 0
	QUIERO = ["Esquema de la carpa", "4 macetas de 50 L", "Pedirlas y ponerlas"]
	LOG = []
	chk(corre(func(): await J.kc_lista(1)) and J.kc_n(1) == 9 and dicho("tarjeta no pasa"), "sin dinero, se queda como estaba")
	J.S.banco = 100000
	# 6 · al pasar al nivel siguiente, las carpas de ahora se quedan con su esquema (conviven) y llega la de 4 × 2, de serie
	J.kc().p[15] = null
	QUIERO = ["Pasar a la", "Comprarla"]
	LOG = []
	var c4: int = J.kc_base(1)
	chk(corre(func(): await J.object_action(2, 1)) and int(J.kc().niv) == 1 and J.kc_n(0) == 16 and J.kc_n(1) == 9 and J.kc_pedida(c4) and J.kc_n(c4) == 8, "a las de 4 × 2: las de 2 × 2 siguen con su esquema y la nueva, de serie (%d plazas)" % J.kc().p.size())
	chk(it_m("tela25") == 0 and it_m("tela35") == 0 and J.kc_pat(0).m == "tela25" and J.kc_pat(1).m == "tela35", "nada a la mochila: las macetas, en sus carpas (%d, %d)" % [it_m("tela25"), it_m("tela35")])
	chk(J.kc_patrones(c4).map(func(q): return q[1]) == [32, 18, 8], "en la de 4 × 2: 32, 18 y 8")
	# 7 · una partida de antes, sin esquemas: las plazas como siempre
	J.S.kc = {"niv": 0, "kits": [0, 0, 0], "p": [null, null, null, null, null, planta.duplicate(true)]}
	J.kc()
	chk(J.kc().p.size() == 4 * 4 + 2 * 8 + 16 and J.kc_ci(5) == 1 and J.kc_plantadas(1) == 1 and J.kc_plantadas(0) == 0, "de antes, la planta en la carpa 2")
	# 8 · en casa: completar las plazas vacías con las macetas que tienes, sin pasar de la tierra
	J.S.erase("kc")
	J.S.carpas = [{"t": "m120", "foco": "cfl"}]
	J.S.pots = [null, null, null, null, null, null]
	J.S.macetas = ["plastico7", "plastico7", "plastico7", "plastico7", "plastico7", "plastico7"]
	J.S.items.m_tela25 = 5
	J.S.items.m_plastico7 = 0
	chk(J.completa_macetas(0).is_empty(), "con 5 de 25 L para 6 plazas, no se ofrece")
	J.S.items.m_tela25 = 6
	var cm: Array = J.completa_macetas(0)
	chk(cm.size() == 1 and cm[0][0] == "tela25" and cm[0][1].size() == 6, "con 6, sí: %s" % [cm])
	QUIERO = ["Completar con macetas", "6 macetas de"]
	MENUS = []
	LOG = []
	chk(corre(func(): await J.carpa_action(0)) and J.S.macetas.all(func(k): return k == "tela25") and it_m("tela25") == 0 and it_m("plastico7") == 6, "las seis de 25 L puestas y las de 7 L, a la mochila (%s)" % [MENUS])
	chk(J.litros_carpa(0) == 150 and J.litros_carpa(0) <= J.litros_max(0) and dicho("150 de 150 L"), "150 de 150 L de tierra")
	J.S.macetas = ["plastico7", "plastico7", "plastico7", "plastico7", "plastico7", "plastico7"]
	J.S.pots[0] = planta.duplicate(true)
	J.S.items.m_tela25 = 5
	cm = J.completa_macetas(0)
	chk(cm.size() == 1 and cm[0][1] == [1, 2, 3, 4, 5], "con una planta, las cinco vacías: %s" % [cm])
	QUIERO = ["Completar la carpa", "5 macetas de"]
	LOG = []
	chk(corre(func(): await J.pot_action(1)) and J.S.macetas == ["plastico7", "tela25", "tela25", "tela25", "tela25", "tela25"] and J.litros_carpa(0) == 132, "desde una plaza vacía, completar la carpa (%s)" % [J.S.macetas])
	J.S.items.m_tela11 = 1
	cm = J.completa_macetas(0)
	chk(cm.size() == 1 and cm[0][0] == "plastico7", "con lo que queda, solo volver a las de 7 L (1 de 11 L no llega): %s" % [cm])
	# 8b · desde una plaza vacía que ya lleva la maceta con la que se completa, también se ofrece
	J.S.pots = [null, null, null, null, null, null]
	J.S.macetas = ["plastico7", "tela25", "plastico7", "plastico7", "plastico7", "plastico7"]
	for k in J.S.items.keys():
		if String(k).begins_with("m_"):
			J.S.items[k] = 0
	J.S.items.m_tela25 = 5
	chk(J.macetas_libres(1, false).is_empty() and J.completa_macetas(0).size() == 1, "la plaza 2 ya en 25 L y nada más que cambiarle")
	QUIERO = ["Completar la carpa", "5 macetas de"]
	LOG = []
	chk(corre(func(): await J.pot_action(1)) and J.S.macetas.all(func(k): return k == "tela25") and it_m("tela25") == 0, "desde esa plaza, completar la carpa (%s)" % [J.S.macetas])
	# 9 · sin CAL, en casa no se ofrece
	J.S.macetas = ["plastico7", "plastico7", "plastico7", "plastico7", "plastico7", "plastico7"]
	J.S.pots[0] = null
	J.S.items.m_tela25 = 6
	Datos.CAL = false
	Datos.carga()
	MENUS = []
	QUIERO = ["Salir"]
	corre(func(): await J.carpa_action(0))
	chk(MENUS.is_empty() or not MENUS.back().has("Completar con macetas"), "sin CAL, no se ofrece")
	chk(J.S.macetas.all(func(k): return k == "plastico7"), "y nada cambia")
	Datos.CAL = true
	Datos.carga()
	print("patrones: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
