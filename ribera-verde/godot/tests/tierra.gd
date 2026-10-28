# Ribera Verde (Godot) — la tierra de cada carpa (lo pidió el usuario: «en este armario molaría que entrasen 150 L de tierra,
# para que entren las 6 de 25 L»; con Datos.CAL): litros_max nunca por debajo de las plazas × su maceta más grande. Y la maceta de
# tela de 35 L (MACETA35: «en la siguiente carpa más grande, deberían de entrar macetas algo más grandes»): en la tienda, en la de
# 150 × 100 (6 × 35 = 210 L), no en la de 120, en las carpas de KAIA y con su dibujo en la vista C; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/tierra.gd   → «tierra: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-tierra.json"
	Juego.AJUSTES = "user://prueba-tierra-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	var S: Dictionary = J.S
	var D: Dictionary = J.D
	# 1 · todas las carpas: caben sus plazas con la maceta más grande; la de 120, 150 L
	Datos.carga()
	var antes := {"p60": 36, "p80": 64, "m100": 100, "m120": 144, "g150": 150}
	for t in D.CARPAS:
		S.carpas[0].t = t
		var C: Dictionary = D.CARPAS[t]
		var l: int = J.litros_max(0)
		chk(l >= int(C.plazas) * int(C.lmax), "%s: %d L para %d × %d" % [t, l, C.plazas, C.lmax])
		chk(l == maxi(int(antes[t]), int(C.plazas) * int(C.lmax)), "%s: %d L (antes %d)" % [t, l, antes[t]])
	S.carpas[0].t = "m120"
	chk(J.litros_max(0) == 150, "la de 120: 150 L (%d)" % J.litros_max(0))
	# 2 · la de 120 con cinco de 25 L y una de 11: la sexta de 25 cabe
	Datos.CAL = true
	var hu: Array = J.huecos()
	var mias := []
	for i in hu.size():
		if hu[i].c == 0:
			mias.append(i)
	S.carpas = [S.carpas[0]] if mias.size() else S.carpas
	hu = J.huecos()
	mias.clear()
	for i in hu.size():
		if hu[i].c == 0:
			mias.append(i)
	while S.macetas.size() < hu.size():
		S.macetas.append("plastico7")
	while S.pots.size() < hu.size():
		S.pots.append(null)
	chk(mias.size() == 6, "seis plazas en la de 120 (%d)" % mias.size())
	for j in mias.size():
		S.macetas[mias[j]] = "tela25" if j < 5 else "tela11"
	S.items["m_tela25"] = 1
	var ul: int = mias[mias.size() - 1]
	chk(J.macetas_libres(ul).has("tela25"), "la sexta de 25 L cabe (%d de %d L)" % [J.litros_carpa(0), J.litros_max(0)])
	S.macetas[ul] = "tela25"
	chk(J.litros_carpa(0) == 150 and J.litros_carpa(0) <= J.litros_max(0), "seis de 25 L: %d L" % J.litros_carpa(0))
	# 3 · sin CAL, como antes (144 L: la sexta de 25 no cabe)
	Datos.CAL = false
	chk(J.litros_max(0) == 144, "sin CAL, 144 L (%d)" % J.litros_max(0))
	S.macetas[ul] = "tela11"
	chk(not J.macetas_libres(ul).has("tela25"), "sin CAL, la sexta de 25 no cabe")
	Datos.CAL = true
	Datos.carga()
	# 4 · la de 35 L: en la tienda, en la de 150 (6 × 35 = 210 L) y en KAIA; en la de 120, no
	chk(D.MACETAS.has("tela35") and int(D.MACETAS.tela35.l) == 35, "la maceta de 35 L")
	chk(D.SHOP.filter(func(it): return it.get("maceta") == "tela35").size() == 1, "una vez en la tienda")
	chk(int(D.CARPAS.g150.lmax) == 35 and int(D.CARPAS.m120.lmax) == 25, "lmax: 150 → 35, 120 → 25")
	chk(D.KAIA_CULT.maceta == "tela35", "KAIA, con la de 35 L")
	S.items["m_tela35"] = 6
	chk(not J.macetas_libres(ul).has("tela35"), "en la de 120 no cabe la de 35")
	S.carpas[0].t = "g150"
	chk(J.litros_max(0) == 210, "la de 150: 210 L (%d)" % J.litros_max(0))
	hu = J.huecos()
	mias.clear()
	for i in hu.size():
		if hu[i].c == 0:
			mias.append(i)
	while S.macetas.size() < hu.size():
		S.macetas.append("plastico7")
	while S.pots.size() < hu.size():
		S.pots.append(null)
	chk(mias.size() == 6, "seis plazas en la de 150 (%d)" % mias.size())
	for j in mias.size():
		S.macetas[mias[j]] = "tela35" if j < 5 else "tela11"
	chk(J.macetas_libres(mias[5]).has("tela35"), "la sexta de 35 L cabe (%d de %d L)" % [J.litros_carpa(0), J.litros_max(0)])
	S.macetas[mias[5]] = "tela35"
	chk(J.litros_carpa(0) == 210, "seis de 35 L: %d L" % J.litros_carpa(0))
	var Vista = load("res://src/vista.gd")
	chk(Vista.vc_sprite("maceta-c-tela35-", 40 * .78, true) != null and D.VC_TIERRA.has("maceta-c-tela35-28"), "su dibujo en la vista C")
	var Cultivo = load("res://src/cultivo.gd")
	var S2: Dictionary = Cultivo.nuevo_estado()
	S2.carpas = [{"t": "g150", "foco": "led720"}]
	S2.macetas = []
	S2.pots = []
	for i in 6:
		S2.macetas.append("tela35")
		S2.pots.append({"sid": "ria", "prog": .8, "water": 70.0, "health": 100.0, "fert": false, "pest": false, "f": {"id": 1, "t": 1, "y": 1, "i": 50}})
	var g = Vista.geo(S2, 0)
	chk(g.vc != null and g.pl.size() == 6 and g.pl.all(func(q): return q.v != null and String(q.v.m.n) == "maceta-c-tela35-28"), "la vista C de la de 150 con seis de 35 L")
	# 5 · sin CAL, ni la maceta ni el tope nuevo, y vuelta
	Datos.CAL = false
	Datos.carga()
	chk(not D.MACETAS.has("tela35") and int(D.CARPAS.g150.lmax) == 25 and D.KAIA_CULT.maceta == "tela25" and D.SHOP.filter(func(it): return it.get("maceta") == "tela35").is_empty(), "sin CAL, como antes")
	Datos.CAL = true
	Datos.carga()
	chk(D.MACETAS.has("tela35") and D.SHOP.filter(func(it): return it.get("maceta") == "tela35").size() == 1, "con CAL otra vez, una vez")
	print("tierra: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit()
