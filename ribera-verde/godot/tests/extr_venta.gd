# Ribera Verde (Godot) — 1.43.7: las extracciones se venden donde los cogollos (lo pidió el usuario): al por mayor (Iñaki y la
# lonja), en los clubs y en el dispensario de la asociación, a precio_rosin × su px × VENTA_EXTR[canal]; las cantidades, el tope
# en gramos de flor, el calor, lo que retiran los socios cada mañana y, sin Datos.CAL, solo cogollos como antes.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-extr.
#   $GODOT --headless --path godot --script res://tests/extr_venta.gd   → «extr_venta: N comprobaciones, 0 fallos»
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
			print("  bloqueo: fin %s libre %s pend %s modo %s" % [st.fin, J.is_free(), J.pending.size(), J.mode])
			return false
	return true

# el precio del gramo como lo cuenta el juego (a céntimos)
func pg(k: String, b: Dictionary, canal: String, f := 1.0) -> float:
	return Datos.jsround(J.precio_rosin(b.thc) * float(J.D.EXTR[J.tipo_extr(k)].px) * float(J.D.VENTA_EXTR[canal]) * J.calidad(b) * f * 100) / 100.0

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-extr-venta.json"
	Juego.AJUSTES = "user://prueba-extr-venta-ajustes.json"
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
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = J.D
	var VX: Dictionary = D.VENTA_EXTR
	var S = J.S
	S.protect = true
	S.heat = 0
	S.rel = S.get("rel", {})
	S.rel.inaki = 0
	var sid := "ria"
	# 1 · Iñaki: los cogollos y, detrás, las extracciones de encima; una de dry sift, 25 g a la mitad de precio_rosin × px
	S.buds = {sid: {"g": 300.0, "thc": 15.0}}
	S.rosin = {sid + "~seco": {"g": 60.0, "thc": 40.0}, sid: {"g": 5.0, "thc": 60.0}}
	S.mDay = 0
	MENUS = []
	QUIERO = ["Dry sift", "25 g"]
	var m0: int = S.money
	var b: Dictionary = S.rosin[sid + "~seco"].duplicate()
	var p := pg(sid + "~seco", b, "mayor")
	chk(corre(func(): await J.venta_mayor("IÑAKI")), "Iñaki bloqueado")
	chk(MENUS.size() >= 2 and MENUS[0].size() == 3 and MENUS[0][0].begins_with(J.lot_nombre(sid)) and MENUS[0][1].begins_with("Dry sift"), "lotes de Iñaki: %s" % [MENUS])
	chk(MENUS.size() >= 2 and MENUS[1][0] == "10 g · %s" % Datos.eur(10 * p) and MENUS[1].has("25 g · %s" % Datos.eur(25 * p)) and MENUS[1][MENUS[1].size() - 2].begins_with("60 g"), "cantidades: %s" % [MENUS])
	chk(S.money - m0 == Datos.jsround(25 * p), "Iñaki paga %d, no %d (%s €/g)" % [S.money - m0, Datos.jsround(25 * p), p])
	chk(absf(S.rosin[sid + "~seco"].g - 35.0) < 1e-6 and S.buds[sid].g == 300.0, "lo que queda: %s %s" % [S.rosin, S.buds])
	chk(absf(S.heat - (2 + 25 / D.ROSIN.rend / 100.0)) < 1e-6, "calor %s" % S.heat)
	chk(S.mDay == S.day, "la carga del día")
	chk(p > J.precio_mayor(b.thc) and p < J.precio_rosin(b.thc), "al por mayor, entre la flor y la calle: %s" % p)
	# 2 · el rosin de 5 g no llega al mínimo
	chk(not MENUS[0].any(func(t): return t.begins_with("Rosin")), "rosin por debajo de %d g: %s" % [int(VX.min), MENUS[0]])
	# 3 · la lonja: el rosin, con su 15 % más; el tope, en gramos de flor
	S.rosin = {sid: {"g": 150.0, "thc": 60.0, "cu": 1.0}}
	S.lonja = null
	S.ch = maxi(int(S.ch), int(D.LONJA.ch))
	MENUS = []
	QUIERO = ["Rosin", "100 g"]
	m0 = S.money
	b = S.rosin[sid].duplicate()
	p = pg(sid, b, "mayor", D.LONJA.f)
	chk(corre(J.talk_nerea), "lonja bloqueada")
	chk(MENUS.size() >= 2 and MENUS[1][MENUS[1].size() - 2].begins_with("100 g"), "tope de la lonja (%d g de flor): %s" % [int(D.LONJA.g), MENUS])
	chk(S.money - m0 == Datos.jsround(100 * p), "la lonja paga %d, no %d" % [S.money - m0, Datos.jsround(100 * p)])
	chk(J.calidad(b) > 1.0 and absf(S.rosin[sid].g - 50.0) < 1e-6 and S.lonja == S.day, "lonja: %s" % [S.rosin])
	# 4 · el club: tres cuartos de precio_rosin × px, de 10, 25 o 50 g, una entrega al día
	S.clubs = S.get("clubs", {})
	S.clubs.rv = true
	S.clubDia = {}
	S.rosin = {sid + "~hash": {"g": 40.0, "thc": 35.0}}
	MENUS = []
	QUIERO = ["Hachís", "25 g"]
	m0 = S.money
	b = S.rosin[sid + "~hash"].duplicate()
	p = pg(sid + "~hash", b, "club")
	chk(corre(func(): await J.vender_club("rv")), "club bloqueado")
	chk(MENUS.size() >= 2 and MENUS[1] == ["10 g · %s" % Datos.eur(10 * p), "25 g · %s" % Datos.eur(25 * p), "Nada"], "cantidades del club: %s" % [MENUS])
	chk(S.money - m0 == Datos.jsround(25 * p) and absf(S.rosin[sid + "~hash"].g - 15.0) < 1e-6 and S.clubDia.rv == S.day, "club: %d %s" % [S.money - m0, S.rosin])
	chk(p > J.precio_club(b.thc), "el club paga más el extracto: %s" % p)
	# 5 · el dispensario de la asociación: el lote de rosin y lo que retiran los socios cada mañana
	var A: Dictionary = J.aso()
	A.pres = true
	A.lote = null
	A.asam = 0
	S.rosin = {sid: {"g": 30.0, "thc": 60.0}}
	MENUS = []
	QUIERO = ["Rosin", "25 g"]
	b = S.rosin[sid].duplicate()
	p = pg(sid, b, "club", D.ASO.f)
	chk(corre(J.dispensario_aso), "dispensario bloqueado")
	chk(A.lote is Dictionary and A.lote.get("x") and A.lote.g == 25 and absf(A.lote.pg - p) < 1e-6 and absf(S.rosin[sid].g - 5.0) < 1e-6, "lote: %s" % [A.lote])
	m0 = S.money
	J.aso_dia()
	var dia: float = D.ASO.dia * VX.dia
	chk(S.money - m0 == Datos.jsround(dia * p) and absf(A.lote.g - (25 - dia)) < 1e-6, "los socios retiran %s: %d %s" % [dia, S.money - m0, A.lote])
	LOG = []
	chk(corre(J.dispensario_aso), "dispensario (lleno) bloqueado")
	chk(" ".join(LOG).contains("rosin de " + J.lot_nombre(sid)), "lo que queda: %s" % [LOG])
	# 6 · el dispensario de cogollos, como antes: 20 g al día
	A.lote = {"k": sid, "g": 100, "pg": 5.0, "tot": 0}
	m0 = S.money
	J.aso_dia()
	chk(S.money - m0 == Datos.jsround(D.ASO.dia * 5.0) and A.lote.g == 100 - D.ASO.dia, "cogollos del dispensario: %s" % [A.lote])
	# 7 · sin Datos.CAL (las pruebas contra el HTML): ni lotes ni textos nuevos
	Datos.CAL = false
	S.buds = {}
	S.rosin = {sid: {"g": 200.0, "thc": 60.0}}
	S.mDay = 0
	MENUS = []
	LOG = []
	chk(corre(func(): await J.venta_mayor("IÑAKI")), "Iñaki sin CAL bloqueado")
	chk(MENUS.is_empty() and LOG.size() == 1 and not LOG[0].contains("Extracciones"), "sin CAL: %s %s" % [MENUS, LOG])
	S.clubDia = {}
	MENUS = []
	chk(corre(func(): await J.vender_club("rv")), "club sin CAL bloqueado")
	chk(MENUS.is_empty() and S.rosin[sid].g == 200.0, "club sin CAL: %s" % [MENUS])
	Datos.CAL = true
	for x in fallos:
		print("  FALLO ", x)
	print("extr_venta: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
