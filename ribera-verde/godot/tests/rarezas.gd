# Ribera Verde (Godot) — las rarezas heredables y el cuaderno de fenotipos (ESTUDIO, tanda 2; con CAL): 1 de cada 50 plantas sale
# con un rasgo raro (enana, doble cosecha, aroma único, resinosa) sin tenerlo su línea; sus semillas lo pasan a la línea (nivel 1:
# 25 de cada 100) y cada generación cosechada de una que lo saca sube un nivel hasta fijarlo (4: todas); el cruce se lleva los de
# las dos un nivel por debajo; sus efectos (más deprisa y menos gramos, el rebrote, el lote que se paga más, el THC); el cuaderno
# con cada planta rara, el día y el sitio; las partidas viejas; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/rarezas.gd   → «rarezas: N comprobaciones, 0 fallos»
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

func cosechado() -> int:   # los gramos de la última «Cosechas N g»
	for j in range(LOG.size() - 1, -1, -1):
		var l := String(LOG[j])
		if l.begins_with("Cosechas "):
			return int(l.get_slice(" ", 1))
	return -1

# cuántas de nn plantas de la línea sid sacan el rasgo k (o cualquiera, con k = "")
func cuenta(sid: String, k: String, nn: int) -> int:
	var c := 0
	for j in nn:
		var f: Dictionary = Cultivo.roll_feno(J.S, sid)
		if f.get("ra") is Array and (k == "" or f.ra.has(k)):
			c += 1
	return c

func planta(sid: String, ra: Array, id: int) -> Dictionary:
	var p := {"sid": sid, "prog": 1.0, "water": 100.0, "health": 100.0, "fert": false, "pest": false, "f": {"id": id, "t": 1.0, "y": 1.0, "i": 50.0, "iv": [16, 16, 16, 16]}}
	if ra.size():
		p.f.ra = ra.duplicate()
	return p

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-rarezas.json"
	Juego.AJUSTES = "user://prueba-rarezas-ajustes.json"
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
	var R: Dictionary = D.RAREZAS
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	J.S.erase("ra")
	J.S.erase("album")
	# 1 · los datos
	chk(R.orden == ["enana", "doble", "aroma", "resina"] and R.orden.all(func(k): return R.r.has(k) and R.r[k].has("n") and R.r[k].has("d")), "los cuatro rasgos, con su nombre y lo que hacen")
	chk(R.niv.size() == int(R.fija) + 1 and float(R.niv[-1]) == 1.0 and is_equal_approx(float(R.p), 0.02), "1 de cada 50 y, fijado, todas")
	# 2 · la tirada: 1 de cada 50 sin la línea; con ella, la de su nivel
	var N := 5000
	var c0 := cuenta("ria", "", N)
	chk(c0 > N * 0.012 and c0 < N * 0.028, "sin la línea, unas 100 de 5000 con un rasgo: %d" % c0)
	chk(not (J.S.get("ra") is Dictionary) or not J.S.ra.has("ria"), "tirar no cambia la línea")
	J.S.ra = {"ria": {}}
	for L in range(1, int(R.fija) + 1):
		J.S.ra.ria.enana = L
		var c := cuenta("ria", "enana", 2000)
		var esp: float = (float(R.niv[L]) + (1 - float(R.niv[L])) * float(R.p) / 4) * 2000
		chk(absf(c - esp) < 90, "nivel %d: %d de 2000 enanas (unas %d)" % [L, c, roundi(esp)])
	J.S.ra = {}
	# 3 · los efectos
	var f: Dictionary = J.factores(0).duplicate()
	f.plaga = 0.0
	var a := planta("ria", [], 1)
	var b := planta("ria", ["enana"], 2)
	for p in [a, b]:
		p.prog = .4
	Cultivo.plant_step(J.S, a, 1.0, f)
	Cultivo.plant_step(J.S, b, 1.0, f)
	chk(is_equal_approx((b.prog - .4) / (a.prog - .4), 1 + float(R.r.enana.crec)), "la enana crece un 15 %% más deprisa (×%.3f)" % ((b.prog - .4) / (a.prog - .4)))
	a.prog = 1.0
	b.prog = 1.0
	var ga := Cultivo.gramos_planta(J.S, a, f)
	var gb := Cultivo.gramos_planta(J.S, b, f)
	chk(absi(gb - roundi(ga * (1 + float(R.r.enana.g)))) <= 1, "y rinde un 10 %% menos (%d g y %d g)" % [ga, gb])
	var rs := planta("ria", ["resina"], 3)
	chk(is_equal_approx(Cultivo.thc_cosecha(J.S, rs, f), minf(35, Cultivo.thc_cosecha(J.S, a, f) + float(R.r.resina.thc))), "la resinosa, 1,5 puntos más de THC")
	# 4 · cosechar una de doble cosecha y aroma único, de una línea en cría (con semillas)
	J.S.map = "home"
	J.S.gen["ria"] = 1
	J.S.buds.erase("ria")
	for j in J.S.pots.size():
		J.S.pots[j] = null
	J.S.pots[0] = planta("ria", ["doble", "aroma"], 9001)
	chk(J.ra_txt(J.S.pots[0]).contains("Rasgo raro: Doble cosecha y Aroma único"), "su ficha lo dice: «%s»" % J.ra_txt(J.S.pots[0]).strip_edges())
	LOG = []
	chk(corre(func(): await J.harvest(0)), "cosecha")
	var g1 := cosechado()
	var p0 = J.S.pots[0]
	chk(p0 is Dictionary and int(p0.get("rb", 0)) == 1 and is_equal_approx(float(p0.prog), float(R.r.doble.vuelve)), "la doble rebrota: vuelve a vegetativo (%s)" % [p0])
	chk(dicho("la planta rebrota") and dicho("Rasgo raro: Doble cosecha") and dicho("Rasgo raro: Aroma único"), "y lo cuenta")
	chk(J.S.ra.get("ria", {}).get("doble") == 1 and J.S.ra.ria.get("aroma") == 1, "sus semillas, a la línea: nivel 1 (%s)" % [J.S.ra])
	chk(dicho("25 de cada 100"), "con lo que saldrá")
	var lt: Dictionary = J.S.buds.get("ria", J.S.caja.buds.get("ria", {}) if J.S.get("caja") is Dictionary else {})
	chk(is_equal_approx(float(lt.get("ar", 0)), 1.0), "el lote, de aroma único (%s)" % [lt])
	var sin: Dictionary = lt.duplicate()
	sin.erase("ar")
	chk(is_equal_approx(J.calidad(lt, true) / J.calidad(sin, true), 1 + float(R.r.aroma.x)), "y se paga un 25 % más")
	chk(J.S.album.size() == 1 and int(J.S.album[0].id) == 9001 and J.S.album[0].sid == "ria" and J.S.album[0].ra == ["doble", "aroma"] and int(J.S.album[0].d) == int(J.S.day) and J.S.album[0].m == "home", "al cuaderno, con el día y el sitio (%s)" % [J.S.album])
	# la segunda: más pequeña, y se acaba
	J.S.pots[0].prog = 1.0
	J.S.pots[0].health = 100.0
	J.S.pots[0].water = 100.0
	chk(J.ra_txt(J.S.pots[0]).contains("Rebrotada"), "rebrotada, en su ficha")
	LOG = []
	chk(corre(func(): await J.harvest(0)), "segunda cosecha")
	var g2 := cosechado()
	chk(J.S.pots[0] == null and not dicho("la planta rebrota"), "la segunda no rebrota")
	chk(absi(g2 - roundi(g1 * float(R.r.doble.g2))) <= 1, "la segunda, del 60 %% (%d g y %d g)" % [g1, g2])
	chk(J.S.ra.ria.doble == 2 and J.S.ra.ria.aroma == 2 and dicho("50 de cada 100"), "otra generación: nivel 2 (%s)" % [J.S.ra])
	chk(J.S.album.size() == 1, "la misma planta, una vez en el cuaderno")
	# sin semillas (línea estable de tienda, sin hermafrodita) el rasgo no pasa
	J.S.gen.erase("ria")
	J.S.pots[0] = planta("ria", ["resina"], 9002)
	Cultivo.pm = 7
	LOG = []
	chk(corre(func(): await J.harvest(0)), "cosecha sin semillas")
	if not dicho("semillas"):
		chk(not J.S.ra.ria.has("resina") and dicho("Sin semillas de esta planta"), "sin semillas, la línea no la aprende")
	chk(J.S.album.size() == 2, "pero va al cuaderno")
	# 5 · hasta fijarlo, y no más
	var fe := {"ra": ["doble"]}
	var ch := []
	for j in 4:
		ch = Cultivo.hereda_ra(J.S, "ria", fe)
	chk(J.S.ra.ria.doble == int(R.fija) and ch.is_empty(), "fijada en la 4.ª generación y ahí se queda (%s)" % [J.S.ra.ria])
	chk(cuenta("ria", "doble", 300) == 300, "fijada, todas la sacan")
	# 6 · el cruce, un nivel por debajo
	J.S.ra = {"aa": {"enana": 3}, "bb": {"resina": 1, "enana": 1}}
	Cultivo.cruza_ra(J.S, "aa", "bb", "cc")
	chk(J.S.ra.get("cc") == {"enana": 2, "resina": 1}, "el cruce se lleva las de las dos, un nivel por debajo (%s)" % [J.S.ra.get("cc")])
	# 7 · el aroma viaja con el lote y se reparte por gramos
	var de := {"x": {"g": 20.0, "thc": 18.0, "ar": 1.0}}
	var al := {}
	J.mover_lote(de, al, "x", 10.0)
	chk(is_equal_approx(float(al.x.get("ar", 0)), 1.0), "mover medio lote, con su aroma")
	J.junta_lote(al.x, 10.0, 18.0, 0, null)
	chk(is_equal_approx(float(al.x.ar), 0.5), "juntado con otro sin él, la mitad (%s)" % [al.x])
	# 8 · el cuaderno en la CannaDex
	MENUS = []
	QUIERO = ["CUADERNO DE FENOTIPOS", "Volver", "Volver"]
	chk(corre(func(): await J.cannadex()) and MENUS.size() >= 2 and MENUS[1].size() == 3 and String(MENUS[1][1]).begins_with(J.strain("ria").n), "el cuaderno, en la CannaDex: %s" % [MENUS])
	# 9 · una partida de antes, sin rarezas ni cuaderno
	J.S.erase("ra")
	J.S.erase("album")
	var fv: Dictionary = Cultivo.roll_feno(J.S, "ria")
	chk(fv.has("t") and not J.S.has("ra"), "de antes: se tira como siempre")
	J.apunta_album(planta("ria", ["enana"], 9100))
	chk(J.S.album.size() == 1, "y el cuaderno se crea al primer rasgo")
	# 10 · sin CAL, nada
	Datos.CAL = false
	Datos.carga()
	J.S.ra = {"ria": {"enana": 4}}
	var sc := 0
	for j in 200:
		if Cultivo.roll_feno(J.S, "ria").has("ra"):
			sc += 1
	chk(sc == 0, "sin CAL, nadie sale con rasgos")
	J.S.pots[0] = planta("ria", ["doble"], 9200)
	LOG = []
	corre(func(): await J.harvest(0))
	chk(J.S.pots[0] == null and not dicho("Rasgo raro"), "y una planta con rasgos no rebrota ni lo dice")
	Datos.CAL = true
	Datos.carga()
	print("rarezas: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for t in fallos:
		print("  FALLO: " + t)
	quit(1 if fallos.size() else 0)
