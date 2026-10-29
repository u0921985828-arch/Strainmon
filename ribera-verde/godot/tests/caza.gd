# Ribera Verde (Godot) — las landraces por estación y por gente y las fiestas fijas (ESTUDIO, tanda 4; con CAL): los datos (17
# por gente, con REGALO y la Malana 30, todas landraces reales); las fiestas por la fecha, este año y el que viene, en el
# calendario, con su SMS la víspera y su aviso al llegar; cada persona da la suya una vez, solo en su estación, su tiempo, su fiesta
# y con su confianza; la feria, por dinero; Bilbao, con horario; el recetario dice quién; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/caza.gd   → «caza: N comprobaciones, 0 fallos»
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

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-caza.json"
	Juego.AJUSTES = "user://prueba-caza-ajustes.json"
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
	J.S.ch = maxi(int(J.S.ch), 8)
	J.S.erase("caza")
	J.S.min = 600
	# 0 · los datos: 17 por gente, sin repetir REGALO; con las de REGALO y la Malana del Acto II, 30
	var L: Array = D.CAZA.l
	var ks: Array = L.map(func(x): return x.k)
	var reg: Array = (D.REGALO.keys() as Array).filter(func(k): return D.STRAINS.has(k) and D.STRAINS[k].tipo == "landrace")
	chk(ks.size() == 17 and ks.all(func(k): return D.STRAINS[k].tipo == "landrace" and not reg.has(k) and k != "malana"), "17 landraces nuevas (%s)" % [ks])
	var todas := {}
	for k in ks + reg + ["malana"]:
		todas[k] = 1
	chk(todas.size() == 30, "30 que se cazan (%d)" % todas.size())
	chk(L.all(func(x): return CAZA_TXT(J, x)), "cada una con su texto y su pista")
	# 1 · las fiestas, por la fecha
	var feria := Datos.dia_de(2026, 5, 15)
	chk(J.fiesta_de(feria).get("k") == "feria" and J.fiesta_de(feria + 2).get("k") == "feria" and J.fiesta_de(feria + 3).is_empty() and J.fiesta_de(feria - 1).is_empty(), "la feria: del 15 al 17 de mayo")
	chk(J.fiesta_de(Datos.dia_de(2026, 8, 14)).get("k") == "barrio" and J.fiesta_de(Datos.dia_de(2026, 8, 18)).get("k") == "barrio" and J.fiesta_de(Datos.dia_de(2026, 8, 19)).is_empty(), "las del barrio: del 14 al 18 de agosto")
	chk(J.fiesta_de(Datos.dia_de(2026, 9, 8)).get("k") == "romeria" and J.fiesta_de(Datos.dia_de(2027, 9, 8)).get("k") == "romeria", "la romería, el 8 de septiembre de cada año")
	J.S.day = Datos.dia_de(2026, 7, 1)
	var mk: Array = J.marcas_cal().filter(func(m): return m.c == J.CAZA_COLOR)
	chk(mk.size() == 18 and mk.any(func(m): return m.d == Datos.dia_de(2027, 5, 16)), "en el calendario, este año y el que viene (%d)" % mk.size())
	# 2 · la víspera, el SMS; el primer día, no; al llegar, el aviso una vez
	J.S.day = feria - 1
	J.queued.clear()
	J.hilo_dia()
	chk(J.queued.has("fiestaferia"), "la víspera de la feria, el SMS")
	J.queued.clear()
	J.S.day = feria
	J.hilo_dia()
	chk(not J.queued.has("fiestaferia"), "el primer día, ya no")
	TOAST.clear()
	J.hilo_entra("mercado-in")
	J.hilo_entra("mercado-in")
	chk(TOAST.size() == 1 and String(TOAST[0]).contains("Feria de semillas"), "al llegar, el aviso, una vez (%s)" % [TOAST])
	J.hilo_entra("town")
	chk(TOAST.size() == 1, "en otro sitio, no")
	# 3 · la feria: por dinero, con horario, una vez
	var r := {"v": false}
	J.S.money = 10.0
	var s0 := int(J.S.seeds.get("kashmir", 0))
	QUIERO = ["Comprar"]
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("bi_me_es")) and r.v and int(J.S.seeds.get("kashmir", 0)) == s0 and not J.caza().has("kashmir"), "sin dinero, nada")
	J.S.money = 100.0
	QUIERO = ["No"]
	chk(corre(func(): r.v = await J.hilo_talk("bi_me_es")) and r.v and int(J.S.seeds.get("kashmir", 0)) == s0, "«No»: nada")
	QUIERO = ["Comprar"]
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("bi_me_es")) and r.v and int(J.S.seeds.get("kashmir", 0)) == s0 + 3 and is_equal_approx(float(J.S.money), 60.0) and dicho("Cachemira"), "comprada: 3 semillas por 40 €")
	chk(corre(func(): r.v = await J.hilo_talk("bi_me_es")) and not r.v, "una vez por partida")
	J.S.min = 1300
	J.S.map = "mercado-in"
	chk(J.ciudad_cerrada() and corre(func(): r.v = await J.hilo_talk("bi_me_fl")) and not r.v, "con el mercado cerrado, nada")
	J.S.map = "home"
	J.S.min = 600
	J.S.day = feria + 3
	chk(corre(func(): r.v = await J.hilo_talk("bi_me_fl")) and not r.v, "acabada la feria, nada")
	# 4 · las fiestas del barrio: Txaro
	J.S.day = Datos.dia_de(2026, 8, 15)
	var p0 := int(J.S.seeds.get("punto", 0))
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("txaro")) and r.v and int(J.S.seeds.get("punto", 0)) == p0 + 3 and dicho("Punto Rojo"), "Txaro, en las fiestas: Punto Rojo")
	J.S.erase("caza")
	J.S.day = Datos.dia_de(2026, 8, 20)
	chk(corre(func(): r.v = await J.hilo_talk("txaro")) and not r.v, "sin fiestas, Txaro no")
	# 5 · por estación y confianza: Julen en verano, siendo amigos
	J.S.day = Datos.dia_de(2026, 7, 10)
	J.S.rel["julen"] = 5
	chk(corre(func(): r.v = await J.hilo_talk("julen")) and not r.v, "Julen sin confianza, no")
	J.S.rel["julen"] = 20
	J.S.day = Datos.dia_de(2026, 11, 10)
	chk(corre(func(): r.v = await J.hilo_talk("julen")) and not r.v, "Julen en otoño, no")
	J.S.day = Datos.dia_de(2026, 7, 10)
	chk(corre(func(): r.v = await J.hilo_talk("julen")) and r.v and J.caza().has("mich"), "Julen en verano, amigos: Michoacán")
	# 6 · el temporal: Koldo, solo con tormenta
	var dt := -1
	var ds := -1
	for d in range(Datos.dia_de(2026, 6, 1), Datos.dia_de(2026, 10, 1)):
		var k: String = String(Datos.tiempo(d, 600).k)
		if k == "tormenta" and dt < 0:
			dt = d
		if k == "sol" and ds < 0:
			ds = d
	chk(dt > 0 and ds > 0, "hay días de tormenta y de sol")
	var mar0 = J.S.get("mar")
	J.S.mar = {}
	J.S.day = ds
	chk(corre(func(): r.v = await J.hilo_talk("koldo")) and not r.v, "Koldo con sol, no")
	J.S.day = dt
	chk(corre(func(): r.v = await J.hilo_talk("koldo")) and r.v and J.caza().has("zamal"), "Koldo con temporal: Zamal")
	J.S.mar = mar0
	# 7 · Miren, después de lo suyo
	J.S.day = Datos.dia_de(2027, 4, 10)
	J.S.rel["miren"] = 30
	J.S.flags.erase("lao")
	chk(corre(func(): r.v = await J.hilo_talk("miren")) and not r.v, "Miren, antes de la Luang Prabang, no")
	J.S.flags.lao = true
	chk(corre(func(): r.v = await J.hilo_talk("miren")) and r.v and J.caza().has("nepal"), "Miren, después: Nepalese")
	# 8 · el recetario dice quién
	chk(J.donde_semilla("swazi").contains("Arrieta") and J.donde_semilla("swazi").contains("banco de semillas"), "el recetario: %s" % J.donde_semilla("swazi"))
	# 9 · cuando no le toca, lo de siempre: npc_talk sigue (el cuaderno azul, ya cerrado)
	J.S.hilo = {"p": 6, "tr": {"miren": 1, "serora": 1, "txaro": 1}, "cor": 2, "el": 0, "d": {"6": int(J.S.day)}}
	MENUS = []
	chk(corre(func(): await J.npc_talk({"id": "kiko"})) and MENUS.size() > 0, "Kiko, lo de siempre")
	# 10 · sin CAL, nada
	Datos.CAL = false
	Datos.carga()
	J.S.erase("caza")
	J.S.day = Datos.dia_de(2026, 8, 15)
	chk(J.fiesta_de(int(J.S.day)).is_empty() and not J.donde_semilla("punto").contains("Txaro"), "sin CAL, ni fiestas ni pistas")
	chk(corre(func(): r.v = await J.hilo_talk("txaro")) and not r.v and not J.S.has("caza"), "sin CAL, Txaro no da nada")
	Datos.CAL = true
	Datos.carga()
	print("caza: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for t in fallos:
		print("  FALLO: " + t)
	quit(1 if fallos.size() else 0)

static func CAZA_TXT(J, x: Dictionary) -> bool:
	return x.t.size() > 0 and String(x.pista) != "" and J.CAZA_N.has(String(x.q))
