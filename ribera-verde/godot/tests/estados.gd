# Landrace Hunters (Godot) — MAESTRO [2]: la borrachera (S.borr) y el colocón (S.colo), de 0 a 100: beber y fumar los suben y
# bajan con las horas (FISIO.baja); borracho, el paso se tuerce y al soltar sigues una casilla (FISIO.inercia); de FISIO.vision
# para arriba, la pantalla en triple; a FISIO.tope en la calle, el desmayo; la sativa acelera y la policía te ve antes, la índica
# pesa, levanta menos sospechas y el laboratorio y el curado cunden; sin Datos.CAL, nada de esto.
#   $GODOT --headless --path godot --script res://tests/estados.gd   → «estados: N comprobaciones, 0 fallos»
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
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-estados.json"
	Juego.AJUSTES = "user://prueba-estados-ajustes.json"
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
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = J.D
	var S: Dictionary = J.S
	var F: Dictionary = D.FISIO
	S.erase("borr")
	S.erase("colo")
	S.erase("efe")
	# 1 · beber: la caña sube su borrachera, el café nada; con las horas baja (FISIO.baja[0] por hora) hasta irse
	chk(J.borr() == 0.0 and J.hud_fisio().is_empty(), "sin beber, sin borrachera ni filas en el HUD")
	J.beber_alc(float(J.BEBIDAS.bar[1][3]))
	chk(is_equal_approx(J.borr(), 10.0), "una caña: %s" % J.borr())
	J.beber_alc(float(J.BEBIDAS.bar[0][3]))
	chk(is_equal_approx(J.borr(), 10.0), "el café no sube")
	J.fisio_pasa(60)
	chk(is_equal_approx(J.borr(), 10.0 - float(F.baja[0])), "una hora después: %s" % J.borr())
	J.fisio_pasa(600)
	chk(not S.has("borr") and J.borr() == 0.0, "se pasa del todo")
	for i in 10:
		J.beber_alc(25)
	chk(J.borr() == float(F.tope), "tope %s" % J.borr())
	# beber sentado en el bar: lo cobra, pasa el rato y sube
	S.borr = 0.0
	J.enter_map("bar", 3, 3, "down")
	J.mode = "world"
	S.money = 100
	QUIERO = ["Una copa"]
	J.enter_map("disco", 5, 5, "down")
	chk(corre(func(): await J.beber_sentado("disco")), "pedir una copa")
	chk(is_equal_approx(J.borr(), 25.0) and is_equal_approx(float(S.money), 91.0), "la copa: %s %s" % [J.borr(), S.money])
	# 2 · el paso de borracho: por debajo de FISIO.inercia[0], recto; dentro, se tuerce y a veces sigues una casilla
	S.borr = float(F.inercia[0])
	chk(J.vaiven(0.5) == 0.0, "a %d, recto" % int(F.inercia[0]))
	J.P.erase("der")
	chk(not J.deriva(), "a %d, sin pasos de más" % int(F.inercia[0]))
	S.borr = float(F.inercia[1])
	chk(absf(J.vaiven(0.5)) == float(F.vaiven) and J.vaiven(0.0) == 0.0, "a %d, se tuerce %s px en medio del paso" % [int(F.inercia[1]), J.vaiven(0.5)])
	var nd := 0
	for i in 2000:
		S.steps = i
		J.P.erase("der")
		if J.deriva():
			nd += 1
	var E: float = 2000 * float(F.deriva)
	chk(absf(nd - E) <= 4 * sqrt(E) + 3, "pasos de más: %d de 2000 (esperados %.0f)" % [nd, E])
	J.P.der = 1
	chk(not J.deriva(), "una vez por soltar")
	# 3 · la vista: de FISIO.vision para arriba, el filtro; por debajo, la pantalla de siempre
	S.borr = float(F.vision)
	chk(J.vision_k() == 0.0, "a %d, sin filtro" % int(F.vision))
	J.vision_borracho()
	chk(J.pantalla.material == null, "sin material")
	S.borr = float(F.tope)
	chk(is_equal_approx(J.vision_k(), 1.0), "a tope, el filtro entero")
	J.vision_borracho()
	chk(J.pantalla.material is ShaderMaterial and J.vision_mat.shader.code.contains("TEXTURE"), "con el filtro de visión triple")
	S.borr = 80.0
	chk(J.vision_k() > 0 and J.vision_k() < 1, "a 80, a medias: %s" % J.vision_k())
	J.mode = "battle"
	chk(J.vision_k() > 0.0, "en combate, también el filtro (lo pidió el usuario)")
	J.mode = "carpa"
	chk(J.vision_k() == 0.0, "en la carpa, sin filtro")
	J.mode = "world"
	S.borr = 0.0
	J.vision_borracho()
	chk(J.pantalla.material == null, "se quita")
	# 4 · el desmayo: a tope en la calle, al dar un paso; te despiertas en la parada, 8 horas después, sin el 30 % ni la mitad
	J.enter_map("puerto", 10, 10, "down")
	S.money = 1000
	S.buds = {"ria": {"g": 20, "thc": 18}}
	S.rosin = {"ria~ice": {"g": 4, "thc": 60}}
	S.borr = float(F.tope)
	var d0: int = int(S.day) * 1440 + int(S.min)
	J.P.x = 10
	J.P.y = 10
	LOG = []
	chk(corre(func(): await J.desmayo()), "el desmayo")
	var A: Array = D.PARADAS.puerto.a
	chk(S.map == "puerto" and J.P.x == int(A[0]) and J.P.y == int(A[1]), "en la parada de Puerto Viejo: %s %d,%d" % [S.map, J.P.x, J.P.y])
	chk(int(S.day) * 1440 + int(S.min) - d0 == int(F.desmayo.h) * 60, "8 horas")
	chk(is_equal_approx(float(S.money), 700.0), "sin el 30 %%: %s" % S.money)
	chk(is_equal_approx(float(S.buds.ria.g), 10.0) and is_equal_approx(float(S.rosin["ria~ice"].g), 2.0), "la mitad de lo que llevabas")
	chk(J.borr() < float(F.vision), "despiertas sin ver triple: %s" % J.borr())
	chk(LOG.size() and String(LOG[-1]).contains("parada"), "te lo cuenta: %s" % [LOG])
	# en la calle, a tope, el paso te tumba; dentro de un bar, no
	S.borr = float(F.tope)
	J.enter_map("bar", 3, 3, "down")
	S.min = 600
	var mp0: String = S.map
	J.on_step_end()
	chk(S.map == mp0 and J.pending.is_empty(), "dentro de un bar no te desmayas")
	S.borr = 0.0
	# 5 · fumar: el colocón por los mg de THC (g × % × 10 × FISIO.colo); el perfil, de la variedad (S.efe.ind)
	J.enter_map("town", 10, 12, "down")
	var st_ind := {}
	var sat := ""
	var ind := ""
	for k in D.STRAINS:
		var iv := float(D.STRAINS[k].get("ind", 50))
		if iv <= 20 and sat == "":
			sat = k
		if iv >= 80 and ind == "":
			ind = k
	chk(sat != "" and ind != "", "una sativa (%s) y una índica (%s)" % [sat, ind])
	J.colocar(sat, 0.5 * 20 * 10)
	chk(is_equal_approx(J.colo(), 100 * float(F.colo)), "medio gramo al 20 %%: %s" % J.colo())
	chk(J.efecto() == "sativa", "se nota la sativa")
	var b0: float = 240.0
	chk(is_equal_approx(J.paso_ms(), b0 / float(F.sativa.vel)), "la sativa acelera: %s ms" % J.paso_ms())
	S.min = 600
	chk(J.vista_pat() == int(D.PAT.vista[0]) + int(F.sativa.vista), "la policía te ve antes: %d" % J.vista_pat())
	var hf: Array = J.hud_fisio()
	chk(hf.size() == 1 and String(hf[0][1]).contains("SATIVA"), "en el HUD: %s" % [hf])
	J.fisio_pasa(600)
	chk(J.colo() == 0.0 and not S.has("efe") and J.efecto() == "", "se pasa")
	J.colocar(ind, 0.5 * 20 * 10)
	chk(J.efecto() == "indica" and is_equal_approx(J.paso_ms(), b0 / float(F.indica.vel)) and J.vista_pat() == int(D.PAT.vista[0]), "la índica pesa y no te ven antes: %s" % J.paso_ms())
	J.colocar(sat, 0.2 * 20 * 10)
	var i2: float = float(S.efe.ind)
	chk(i2 < float(D.STRAINS[ind].ind) and i2 > float(D.STRAINS[sat].ind), "la mezcla, en medio: %s" % i2)
	J.colocar(ind, 1000)
	chk(J.colo() == float(F.tope), "tope")
	# por debajo de FISIO.efecto, no se nota
	S.colo = float(F.efecto) - 1
	chk(J.efecto() == "", "a %d, nada" % (int(F.efecto) - 1))
	# 6 · catar sube: con los cogollos y con un extracto
	S.erase("colo")
	S.erase("efe")
	S.buds = {ind: {"g": 5, "thc": 20}}
	chk(corre(func(): await J.catar(ind, 0.5)), "catar")
	chk(J.colo() > 0 and J.efecto() == "indica", "catar coloca: %s" % J.colo())
	# 7 · la índica: el curado de la mañana cunde (FISIO.indica.cura)
	S.items.tarros = 1
	if not (S.get("caja") is Dictionary):
		S.caja = {}
	S.caja.buds = {"a": {"g": 10, "thc": 20, "cu": 0.0}}
	S.ind_d = int(S.day)
	J.curado_dia([])
	chk(is_equal_approx(float(S.caja.buds.a.cu), 1.0 / float(D.CURADO.dias) * float(F.indica.cura)), "curado con la índica: %s" % S.caja.buds.a.cu)
	S.ind_d = int(S.day) - 5
	S.caja.buds = {"a": {"g": 10, "thc": 20, "cu": 0.0}}
	J.curado_dia([])
	chk(is_equal_approx(float(S.caja.buds.a.cu), 1.0 / float(D.CURADO.dias)), "sin ella, lo de siempre")
	# 8 · sin CAL: nada
	Datos.CAL = false
	S.borr = 90.0
	S.colo = 90.0
	S.efe = {"ind": 0}
	chk(J.borr() == 0.0 and J.colo() == 0.0 and J.efecto() == "" and J.vaiven(0.5) == 0.0 and J.vision_k() == 0.0, "sin CAL, como antes")
	chk(J.paso_ms() == 240.0, "sin CAL, el paso de siempre")
	J.beber_alc(30)
	chk(float(S.borr) == 90.0, "sin CAL, beber no sube")
	Datos.CAL = true
	print("estados: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  FALLO ", x)
	quit(1 if fallos.size() else 0)
