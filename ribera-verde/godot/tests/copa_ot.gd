# Ribera Verde (Godot) — la Copa de otoño por categorías (ESTUDIO, tanda 5; con CAL): los datos (5 categorías, 4 rivales); el día,
# el 17 de octubre desde el capítulo 7, con el jurado en la plaza; los rivales suben cada año hasta su tope; cada categoría pide lo
# suyo (curado, landrace, cruce propio, extracción); una muestra por categoría y año; el podio paga y da prestigio; tres oros, la
# Copa absoluta, una vez al año; el SMS a 3 días y el mismo día; el calendario; otro día, el jurado de siempre; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/copa_ot.gd   → «copa_ot: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")
const Cultivo = preload("res://src/cultivo.gd")
const I18n = preload("res://src/i18n.gd")

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
	var dis := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
		dis.append(not (it is String) and it.get("disabled", false))
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q) and not dis[i]:
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

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-copa_ot.json"
	Juego.AJUSTES = "user://prueba-copa_ot-ajustes.json"
	Datos.CAL = true
	Datos.carga()
	Atlas.carga()
	var D: Dictionary = Datos.carga()
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-noche":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	var TOAST := []
	J.gancho_toast = func(h, _ms): TOAST.append(h)
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	J.S.ch = 8
	J.S.erase("cot")
	J.S.min = 600
	var C: Dictionary = D.COPA_OT
	# 0 · los datos
	chk(C.cats.size() == 5 and C.rivales.size() == 4 and C.rivales.has("Semillas Ondarea"), "5 categorías y 4 rivales")
	# 1 · el día
	var d26 := Datos.dia_de(2026, 10, 17)
	J.S.day = d26
	chk(J.copa_ot_hoy(), "el 17 de octubre, la Copa")
	chk(J.npc_cond({"id": "jurado", "map": "town"}), "el jurado, en la plaza")
	J.S.day = d26 - 1
	chk(not J.copa_ot_hoy(), "el 16, no")
	J.S.day = Datos.dia_de(2027, 10, 17)
	chk(J.copa_ot_hoy(), "y el 17 de octubre del año siguiente")
	J.S.ch = 6
	chk(not J.copa_ot_hoy(), "antes del capítulo 7, no")
	J.S.ch = 8
	J.S.day = d26
	# 2 · los rivales suben cada año, hasta su tope
	var sube := true
	for c in C.cats:
		var a: Array = J.cot_rivales(String(c.k), 2026)
		var b: Array = J.cot_rivales(String(c.k), 2028)
		var z: Array = J.cot_rivales(String(c.k), 2070)
		for j in a.size():
			if not (float(b[j][1]) > float(a[j][1]) and float(z[j][1]) <= float(c.tope) and float(a[j][1]) >= float(c.r[0]) and float(a[j][1]) <= float(c.r[1]) + float(c.sube)):
				sube = false
	chk(sube, "los rivales: en su rango el primer año, más fuertes después, nunca por encima del tope")
	chk(J.cot_rivales("pot", 2026) == J.cot_rivales("pot", 2026), "los mismos rivales cada vez que miras")
	# 3 · cada categoría pide lo suyo
	J.S.buds = {}
	J.S.rosin = {}
	J.S.buds["thai"] = {"g": 30.0, "thc": 17.0, "cu": 1.0}
	J.S.buds["ria"] = {"g": 30.0, "thc": 31.0, "cu": 1.0}
	J.S.buds["limon"] = {"g": 30.0, "thc": 18.0, "dia": 1}
	var xs := Datos.cross_result(J.S, "thai", "afgano") if D.STRAINS.has("afgano") else Datos.cross_result(J.S, "thai", "ria")
	chk(J.S.custom.has(xs), "un cruce propio (%s)" % xs)
	J.S.buds[xs] = {"g": 30.0, "thc": 29.0, "cu": 1.0}
	J.S.rosin["ria"] = {"g": 5.0, "thc": 75.0}
	var ks := func(k): return J.cot_lotes(k).map(func(l): return l[0])
	chk(ks.call("pot").has("ria") and not ks.call("pot").has("limon"), "potencia: solo lo curado del todo")
	chk(ks.call("sab").has("limon"), "sabor: también lo sin curar")
	chk(ks.call("land") == ["thai"], "landrace pura: solo la landrace (%s)" % [ks.call("land")])
	chk(ks.call("cru") == [xs], "cruce propio: solo el tuyo (%s)" % [ks.call("cru")])
	chk(ks.call("ext") == ["ria"], "extracción: el rosin")
	# 4 · la nota de sabor
	var P: Dictionary = C.sab
	var y := 2026
	var ar: String = J.cot_aroma(y)
	var pt: float = J.cot_puntos("sab", {"thc": 20.0, "cu": 1.0, "af": 1, "ar": 1.0}, "thai", y)
	var esp := float(P.base) + float(P.cu) + float(P.af) + float(P.ar) + (float(P.aroma) if J.aroma_de("thai") == ar else 0.0)
	chk(is_equal_approx(pt, esp), "sabor: %s (esperado %s)" % [pt, esp])
	chk(J.cot_puntos("sab", {"thc": 20.0}, "thai", y) < pt, "sin curar, menos nota")
	# 5 · potencia: ganas el oro
	var m0 := float(J.S.money)
	var p0 := int(J.S.get("prest", 0))
	var r := {"v": false}
	QUIERO = ["Potencia", "Skunk"]
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("jurado")) and r.v, "el jurado, el día de la Copa")
	chk(int(J.cot_ano(y).get("pot", 0)) == 1 and is_equal_approx(float(J.S.money), m0 + 3000) and int(J.S.prest) == p0 + 2, "potencia, 1.º: 3.000 € y 2 de prestigio")
	chk(is_equal_approx(float(J.S.buds["ria"].g), 20.0), "se lleva 10 g")
	chk(dicho("Semillas Ondarea") and dicho("COPA DE OTOÑO"), "la tabla con los rivales")
	var dis := false
	for mm in MENUS:
		if mm.size() == 6 and mm[0] == "Potencia":
			dis = true
	chk(dis, "el menú de las categorías")
	# 6 · una muestra por categoría y año
	var g0 := float(J.S.buds["ria"].g)
	QUIERO = ["Potencia", "Skunk"]
	chk(corre(func(): r.v = await J.hilo_talk("jurado")) and is_equal_approx(float(J.S.buds["ria"].g), g0), "potencia otra vez, no")
	# 7 · fuera del podio: sin premio
	J.S.buds["thai"].thc = 10.0
	m0 = float(J.S.money)
	QUIERO = ["Landrace", "Thai"]
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("jurado")) and int(J.cot_ano(y).get("land", 0)) == 5 and is_equal_approx(float(J.S.money), m0) and dicho("fuera del podio"), "landrace floja: 5.º, nada")
	# 8 · tres oros: la Copa absoluta, una vez
	QUIERO = ["Cruce propio", J.strain(xs).n]
	chk(corre(func(): r.v = await J.hilo_talk("jurado")) and int(J.cot_ano(y).get("cru", 0)) == 1, "cruce propio, 1.º")
	m0 = float(J.S.money)
	QUIERO = ["Extracción", "Rosin"]
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("jurado")) and int(J.cot_ano(y).get("ext", 0)) == 1, "extracción, 1.º")
	chk(J.cot().abs == [2026] and is_equal_approx(float(J.S.money), m0 + 3000 + 5000) and dicho("ABSOLUTA"), "tres oros: la Copa absoluta y 5.000 € (%s)" % [J.cot().abs])
	chk(J.cot().tro.size() == 3, "tres trofeos (%d)" % J.cot().tro.size())
	# 9 · el SMS, a 3 días y el mismo día
	J.queued.clear()
	J.S.day = d26 - 3
	J.hilo_dia()
	chk(J.queued.has("copaot"), "a 3 días, el SMS")
	J.queued.clear()
	J.S.day = d26 - 2
	J.hilo_dia()
	chk(not J.queued.has("copaot"), "a 2 días, no")
	J.S.day = d26
	J.hilo_dia()
	chk(J.queued.has("copaot"), "el mismo día, también")
	J.queued.clear()
	J.S.ch = 6
	J.S.day = d26 - 3
	J.hilo_dia()
	chk(not J.queued.has("copaot"), "antes del capítulo 7, no")
	J.S.ch = 8
	# 10 · el calendario
	J.S.day = Datos.dia_de(2026, 7, 1)
	var mk: Array = J.marcas_cal().filter(func(m): return m.c == J.COT_COLOR)
	chk(mk.size() == 2 and mk.any(func(m): return m.d == Datos.dia_de(2027, 10, 17)), "en el calendario, este año y el que viene (%d)" % mk.size())
	# 11 · otro día, el jurado de siempre: no la Copa de otoño
	J.S.day = d26 + 1
	chk(corre(func(): r.v = await J.hilo_talk("jurado")) and not r.v, "otro día, no")
	# 12 · el año siguiente, otra vez todas
	J.S.day = Datos.dia_de(2027, 10, 17)
	chk(J.cot_ano(2027).is_empty(), "el año siguiente, de cero")
	# 13 · sin CAL, nada
	Datos.CAL = false
	Datos.carga()
	J.S.day = d26
	chk(not J.copa_ot_hoy() and corre(func(): r.v = await J.hilo_talk("jurado")) and not r.v, "sin CAL, no hay Copa de otoño")
	Datos.CAL = true
	Datos.carga()
	print("copa_ot: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for t in fallos:
		print("  FALLO: " + t)
	quit(1 if fallos.size() else 0)
