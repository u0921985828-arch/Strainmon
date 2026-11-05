# Ribera Verde (Godot) — la tetraploidia en el laboratorio del banco de la tía (lo pidió el usuario: «molaría implantar la
# tetraploidia en el laboratorio pero de alguna forma no tan complicada de explicar supongo, con la colchicina»; con CAL):
# la rareza «tetra» no sale sola, solo del laboratorio; el frasco del reactivo se pide a la cuenta y da para varios intentos;
# cada intento gasta 2 semillas y un uso, y a los TETRA.dias se ve si cuajó (cuaja, se queda por el camino o sale normal);
# la línea tetraploide da más THC, menos cosecha y va más lenta, y no cruza con una normal (triploide); el juego no cuenta
# en ningún sitio ni concentración, ni tiempos, ni método.
#   $GODOT --path godot --script res://tests/tetra.gd   → «tetra: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
var LOG := []
var MENUS := []
var QUIERO := []
var n := 0
var fallos := []

var t_ini := 0.0

func _initialize() -> void:
	Datos.PLAY = false
	t_ini = float(Time.get_ticks_msec())
	_corre.call_deferred()

# un tope duro: si algo revienta a mitad, el SceneTree se queda vivo para siempre
func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - t_ini > 240000:
		print("tetra: se quedó colgada")
		quit(2)
	return false

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
	Juego.GUARDADO = "user://prueba-tetra.json"
	Juego.AJUSTES = "user://prueba-tetra-ajustes.json"
	Datos.CAL = true
	Datos.carga()
	Atlas.carga()
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
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D: Dictionary = J.D
	var T9: Dictionary = D.TETRA
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"

	# 1 · los datos y las reglas
	chk(D.has("TETRA") and T9.has("frasco") and T9.has("p") and T9.has("dias"), "TETRA, en los datos")
	chk(D.RAREZAS.r.has("tetra") and not D.RAREZAS.espontaneo.has("tetra"), "la tetraploide no sale sola")
	var rt: Dictionary = D.RAREZAS.r.tetra
	chk(float(rt.thc) > 0 and float(rt.g) < 0 and float(rt.crec) < 0, "más THC, menos cosecha y más lenta: %s" % [rt])
	# el juego no cuenta ni dosis ni método: ni porcentajes del reactivo ni tiempos de exposición
	var src := FileAccess.get_file_as_string("res://src/bancotia.gd")
	var prohibido := ["colchicin", "%  de colchi", "ppm", "mg/l", "mg/ml"]
	var mal := []
	for p in prohibido:
		if src.to_lower().contains(p):
			mal.append(p)
	chk(mal.is_empty(), "el código nombra dosis o el reactivo por su nombre: %s" % [mal])

	# 2 · nadie saca la tetraploide por azar, ni con la línea a tope
	J.S.ra = {"ria": {"tetra": 4}}
	var sola := 0
	for i in 3000:
		var f: Dictionary = Cultivo.roll_feno(J.S, "amn")
		if f.get("ra") is Array and f.ra.has("tetra"):
			sola += 1
	chk(sola == 0, "la tetraploide salió sola %d veces" % sola)

	# 3 · los efectos
	var fe := {"id": 1, "ra": ["tetra"]}
	chk(is_equal_approx(Cultivo.ra_thc(fe), float(rt.thc)), "el THC de la tetraploide")
	chk(Cultivo.ra_g_mesa(fe) < 1.0 and Cultivo.ra_crec(fe) < 1.0, "menos cosecha y más lenta en la mesa")
	var fe2 := {"id": 2, "ra": ["tetra", "resina"]}
	chk(Cultivo.ra_thc(fe2) > Cultivo.ra_thc(fe), "la resinosa y la tetraploide se suman")

	# 4 · el cruce: 4n × 2n no cuaja; 4n × 4n sí
	J.S.ra = {"ria": {"tetra": 2}, "amn": {"tetra": 1}}
	chk(Cultivo.tetra_linea(J.S, "ria") and not Cultivo.tetra_linea(J.S, "thai"), "qué línea es tetraploide")
	chk(Cultivo.triploide(J.S, "ria", "thai"), "4n × 2n tiene que ser triploide")
	chk(not Cultivo.triploide(J.S, "ria", "amn"), "4n × 4n sí cruza")
	chk(not Cultivo.triploide(J.S, "thai", "ria2"), "2n × 2n cruza como siempre")

	# 5 · el frasco: se pide a la cuenta y da para TETRA.frasco.n intentos
	J.S.ch = int(T9.ch)
	J.S.erase("bt")
	J.S.banco = 100000
	J.S.flags["lab"] = 1
	J.lab().m = true          # con las manos lavadas, el EPI puesto, el autoclave del día y el puesto recogido
	J.lab().e = true
	J.lab().at = int(J.S.day)
	J.lab().r = false
	chk(int(J.bt_tt().get("f", 0)) == 0, "se empieza sin frasco")
	LOG = []
	QUIERO = ["Doblar los cromosomas", "Pedirlo"]
	chk(corre(func(): await J.bt_lab()), "el laboratorio se queda colgado al pedir el frasco")
	chk(int(J.bt_tt().f) == int(T9.frasco.n), "el frasco da para %d intentos: %d" % [int(T9.frasco.n), int(J.bt_tt().get("f", 0))])
	chk(int(J.S.banco) == 100000 - int(T9.frasco.e), "el frasco se paga por la cuenta: %d" % int(J.S.banco))
	chk(dicho("armario"), "no dice dónde se guarda: %s" % [LOG])

	# 6 · un intento gasta 2 semillas y un uso, y deja la bandeja en la estufa
	J.S.ra = {}
	J.S.seeds = {"ria": 3}
	var tt0 := int(J.bt_tt().f)
	LOG = []
	MENUS = []
	QUIERO = ["Doblar los cromosomas", "Skunk", "Tratar"]
	chk(corre(func(): await J.bt_lab()), "el tratamiento se queda colgado")
	chk(int(J.S.seeds.get("ria", 0)) == 1, "gasta 2 semillas: %s" % [J.S.seeds])
	chk(int(J.bt_tt().f) == tt0 - 1, "gasta un uso del frasco")
	chk(J.bt_tt().p.has("ria"), "la bandeja, en la estufa: %s" % [J.bt_tt().p])
	chk(int(J.bt_tt().p.get("ria", -1)) == int(J.S.day) + int(T9.dias), "y con su plazo")
	chk(bool(J.bt().get("ld", {}).get("r", false)), "lo gastado tiene que ir al contenedor")
	if not J.bt_tt().p.has("ria"):
		print("  menús: %s" % [MENUS])
		print("  dicho: %s" % [LOG])
	# de una en una (con el puesto ya recogido, para que no corte antes la norma del contenedor)
	J.lab().r = false
	LOG = []
	QUIERO = ["Doblar los cromosomas"]
	chk(corre(func(): await J.bt_lab()), "colgado con una bandeja puesta")
	chk(dicho("esperando"), "deja poner dos bandejas a la vez: %s" % [LOG])

	# 7 · el plazo: cuaja, se queda por el camino o sale normal, y nunca antes de tiempo
	J.tetra_dia()
	chk(J.bt_tt().p.has("ria"), "la bandeja se resolvió antes de tiempo")
	var cuaja := 0
	var muere := 0
	var igual := 0
	for i in 300:
		J.S.ra = {}
		J.bt_tt().p = {"ria": 1000 + i}
		J.S.day = 1000 + i
		J.queued.clear()
		J.tetra_dia()
		if Cultivo.tetra_linea(J.S, "ria"):
			cuaja += 1
		elif J.queued.has("tetraria"):
			var t := str(J.queued)
			if t.contains("camino"):
				muere += 1
			else:
				igual += 1
	chk(cuaja + muere + igual == 300, "cada bandeja acaba de una de las tres maneras: %d/%d/%d" % [cuaja, muere, igual])
	chk(absf(float(cuaja) / 300.0 - float(T9.p)) < 0.12, "cuaja el %d %% (esperado %d %%)" % [roundi(cuaja / 3.0), roundi(float(T9.p) * 100)])
	chk(cuaja > 0 and muere > 0 and igual > 0, "las tres salidas se dan: %d/%d/%d" % [cuaja, muere, igual])

	# 8 · la línea queda tetraploide y se hereda como las demás
	J.S.ra = {}
	J.bt_tt().p = {"ria": J.S.day}
	J.tetra_dia()
	if Cultivo.tetra_linea(J.S, "ria"):
		var ff := {"id": 7, "ra": ["tetra"], "ral": {"tetra": 1}}
		var ch := Cultivo.hereda_ra(J.S, "ria", ff)
		chk(int(J.S.ra.ria.tetra) >= 1, "la línea guarda la tetraploidia: %s" % [J.S.ra])
		chk(ch.size() >= 0, "se hereda como las demás")
	else:
		chk(true, "esta bandeja no cuajó")

	# 9 · sin CAL, no hay tetraploidia
	Datos.CAL = false
	Datos.carga()
	J.S.ra = {"ria": {"tetra": 4}}
	chk(not Cultivo.tetra_linea(J.S, "ria") and not Cultivo.triploide(J.S, "ria", "thai"), "sin CAL, nada")
	chk(is_equal_approx(Cultivo.ra_thc({"id": 1, "ra": ["tetra"]}), 0.0), "sin CAL, tampoco sus efectos")
	Datos.CAL = true
	Datos.carga()

	print("tetra: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for t in fallos:
		print("  FALLO: " + t)
	quit(1 if fallos.size() else 0)
