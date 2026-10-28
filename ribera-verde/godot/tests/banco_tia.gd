# Ribera Verde (Godot) — el banco de semillas de la tía (bancotia.gd, con CAL; ESTUDIO tanda 1, lo pidió el usuario: «mete mano a
# las mejoras que hablamos»): la lata abre el cuarto de atrás de la asociación; las colecciones destapan sus muebles y cada uno
# abre lo suyo; con la Haze del 98 fijada, el final; OBJETIVO del capítulo 8, el banco; las partidas de antes entran; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/banco_tia.gd   → «banco_tia: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

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
	Juego.GUARDADO = "user://prueba-banco-tia.json"
	Juego.AJUSTES = "user://prueba-banco-tia-ajustes.json"
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
	var D: Dictionary = J.D
	var B: Dictionary = D.BANCO_TIA
	var MP: String = B.mapa
	# 1 · los datos: seis colecciones sin repetir variedad, el cuarto y las dos puertas
	var sids := []
	for c in B.col:
		sids.append_array(c.s)
	chk(B.col.size() == 6 and sids.size() == 31 and sids.all(func(s): return D.STRAINS.has(s) and sids.count(s) == 1), "seis colecciones, 31 variedades sin repetir")
	chk(B.col.all(func(c): return B.zonas.has(c.z)), "cada colección, su mueble")
	chk(D.MAPS.has(MP) and D.PUERTAS_INT.has(MP) and D.PUERTAS_INT["club-rv"].any(func(p): return p.to == MP and int(p.x) == 9 and int(p.y) == 1 and p.llave == "banco"), "el cuarto y la puerta de la asociación, junto a la foto")
	var pb: Dictionary = {}
	for p in D.PUERTAS_INT["club-rv"]:
		if p.to == MP:
			pb = p
	# 2 · antes de la lata: la puerta, cerrada; sin fila en OBJETIVO
	nuevo(S0)
	J.S.hilo = {"p": 4, "tr": {"miren": 1, "serora": 1, "txaro": 1}, "cor": 0, "el": -1, "d": {}}
	J.S.erase("bt")
	J.S.seeds.erase("silver")
	J.S.disc.erase("silver")
	J.S.gen.erase("silver")
	chk(mundo("club-rv", 9, 2) and J.MAPS["club-rv"].o[1][9] == "puertaI", "la puerta, en la pared de la asociación")
	LOG = []
	chk(corre(func(): await J.object_action(9, 1)) and J.S.map == "club-rv" and dicho("cerrada con llave"), "sin la lata, cerrada: %s" % [LOG])
	MENUS = []
	QUIERO = ["Volver"]
	chk(corre(func(): await J.objetivo_menu()) and MENUS.size() and not MENUS[0].has("EL BANCO DE LA TÍA"), "OBJETIVO, sin el banco")
	# 3 · la lata: la llave y la Haze sin fijar
	LOG = []
	QUIERO = ["Guardártelo"]
	chk(mundo("huerta", 15, 13) and J.hilo_p() == 6 and J.bt_abierto(), "la lata abre el banco")
	chk(dicho("cuarto de atrás") and Cultivo.gen_de(J.S, "silver") == 1, "la llave y la Haze del 98 en F1 (%d)" % Cultivo.gen_de(J.S, "silver"))
	# 4 · el cuarto: la puerta lleva, el fichero y lo tapado
	chk(mundo("club-rv", 9, 2), "en la asociación")
	LOG = []
	chk(corre(func(): await J.object_action(9, 1)) and J.S.map == MP and J.P.x == 1 and J.P.y == 2 and dicho("banco de semillas"), "dentro, con la presentación (%s %d,%d)" % [J.S.map, J.P.x, J.P.y])
	var m: Dictionary = J.MAPS[MP]
	chk(m.o[3][6] == "btFichero" and m.o[3][7] == "btFichero2", "el fichero")
	chk(B.zonas.keys().all(func(z): return z == "placa" or m.o[int(B.zonas[z].y)][int(B.zonas[z].x)] == ("puertaLabP" if B.zonas[z].get("puerta") else "btTapado")), "todo tapado, y el laboratorio precintado")
	chk(m.o[1][6] == null, "sin la placa")
	var v := alcance_d(MP)
	for z in B.zonas:
		if z == "placa":
			continue
		var Z: Dictionary = B.zonas[z]
		chk(delante(v, int(Z.x), int(Z.y)) and (Z.get("puerta") or delante(v, int(Z.x) + 1, int(Z.y))), "%s: se llega" % z)
	chk(delante(v, 6, 3), "el fichero: se llega")
	# 5 · entregar: sin semillas, no; con ellas, se destapa
	LOG = []
	QUIERO = ["Las del Kush", "Volver"]
	chk(corre(func(): await J.object_action(6, 3)) and not J.bt_hecha("kush") and dicho("Te faltan"), "sin semillas, no")
	for sid in J.bt_col("kush").s:
		J.S.seeds[sid] = 2
	J.S.seeds.rif = 3
	QUIERO = ["Las del Kush", "Entregar", "Volver"]
	chk(corre(func(): await J.object_action(6, 3)) and J.bt_hecha("kush"), "entregada")
	chk(int(J.S.seeds.get("rif", 0)) == 1 and not J.S.seeds.has("hindu"), "las semillas, al banco")
	chk(m.o[2][3] == "btCamara" and m.o[2][4] == "btCamara2", "la cámara fría, destapada")
	QUIERO = ["Las del Kush", "Volver"]
	chk(corre(func(): await J.object_action(6, 3)) and J.bt_n() == 1, "una vez")
	# 6 · la cámara fría: una semilla cada siete días
	QUIERO = [J.strain("hindu").n]
	chk(corre(func(): await J.object_action(3, 2)) and int(J.S.seeds.get("hindu", 0)) == 1, "la cámara da una de lo guardado")
	LOG = []
	QUIERO = [J.strain("hindu").n]
	chk(corre(func(): await J.object_action(4, 2)) and int(J.S.seeds.get("hindu", 0)) == 1 and dicho("cada 7 días"), "el mismo día, no")
	J.S.day = int(J.S.day) + 7
	QUIERO = [J.strain("hindu").n]
	chk(corre(func(): await J.object_action(3, 2)) and int(J.S.seeds.get("hindu", 0)) == 2, "a los siete días, otra")
	# 7 · el laboratorio: estabilizar con una
	var da := func(id: String):
		for sid in J.bt_col(id).s:
			J.S.seeds[sid] = int(J.S.seeds.get(sid, 0)) + int(J.bt_col(id).get("k", B.k))
		QUIERO = [String(J.bt_col(id).n), "Entregar", "Volver"]
		return corre(func(): await J.object_action(6, 3)) and J.bt_hecha(id)
	LOG = []
	chk(corre(func(): await J.object_action(8, 1)) and J.S.map == MP and dicho("precintada"), "el laboratorio, precintado hasta su colección")
	chk(da.call("costa") and m.o[1][8] == "puertaLab", "la costa: la puerta del laboratorio")
	LOG = []
	QUIERO = ["La Haze", "Volver"]
	chk(corre(func(): await J.object_action(6, 3)) and dicho("último cajón"), "la Haze del 98, la última")
	await laboratorio()
	# 8 · la sala de catas: un análisis al día
	chk(da.call("africa") and m.o[5][8] == "btCata", "África: la sala de catas")
	J.S.buds = {"ria": {"g": 30.0, "thc": 14.0, "dia": int(J.S.day)}}
	QUIERO = ["Skunk"]
	chk(corre(func(): await J.object_action(8, 5)) and J.S.buds.ria.get("ana") == true, "el lote, analizado")
	# 9 · el archivo: una receta que no tienes
	chk(da.call("sierra") and m.o[2][9] == "btArchivo", "la sierra: el archivo")
	LOG = []
	chk(corre(func(): await J.object_action(9, 2)) and dicho("de ahí sale"), "una receta de la tía: %s" % [LOG])
	# 10 · los socios: un sobre de una landrace que no tienes
	chk(da.call("asia") and m.o[5][5] == "btMostrador", "Asia: el mostrador")
	var falta: Array = D.LANDRACES.filter(func(s): return not J.S.disc.get(s) and not D.REGALO.has(s))
	var antes := {}
	for s in falta:
		antes[s] = int(J.S.seeds.get(s, 0))
	chk(corre(func(): await J.object_action(5, 5)) and (falta.is_empty() or falta.any(func(s): return int(J.S.seeds.get(s, 0)) == antes[s] + 2)), "el sobre de los socios, de una que no tenías (%d sin encontrar)" % falta.size())
	# 11 · OBJETIVO en el capítulo 8: el banco, no el imperio
	J.S.ch = 8
	J.S.erase("encargo")
	var ot: String = J.objective_text()
	chk(ot.contains("5/6") and ot.contains("Haze") and not ot.contains("imperio"), "OBJETIVO: %s" % ot)
	# 12 · la Haze del 98: sin fijar, no; fijada, el final
	J.S.seeds.silver = 5
	LOG = []
	QUIERO = ["La Haze", "Volver"]
	chk(corre(func(): await J.object_action(6, 3)) and not J.bt_hecha("haze") and dicho("Te faltan"), "sin fijar, no")
	J.S.gen.erase("silver")
	var r0 := float(J.S.rep)
	var p0 := int(J.S.get("prest", 0))
	LOG = []
	chk(da.call("haze") and J.bt().has("fin"), "la Haze fijada: el banco entero")
	chk(m.o[1][6] == "btPlaca" and float(J.S.rep) >= r0 + int(B.rep) and int(J.S.prest) == p0 + int(B.prest) and dicho("es del barrio"), "la placa, la reputación y el prestigio")
	chk(J.objective_text().contains("abierto"), "OBJETIVO, abierto")
	LOG = []
	chk(delante(v, 6, 1) and corre(func(): await J.object_action(6, 1)) and dicho("ramo"), "la placa se toca desde delante")
	MENUS = []
	QUIERO = ["EL BANCO DE LA TÍA", "Volver", "Volver"]
	chk(corre(func(): await J.objetivo_menu()) and MENUS.size() >= 2 and MENUS[0].has("EL BANCO DE LA TÍA") and J.bt_derecha() == "6/6", "OBJETIVO → EL BANCO DE LA TÍA, 6/6")
	# 13 · la partida por JSON (floats): igual
	J.S = JSON.parse_string(JSON.stringify(J.S))
	chk(J.bt_n() == 6 and J.bt_espera("saca", 7) >= 0, "por JSON, igual")
	# 14 · una partida de antes con la lata ya abierta (sin S.bt): la llave, también
	nuevo(S0)
	J.S.hilo = {"p": 6, "tr": {"miren": 1, "serora": 1, "txaro": 1}, "cor": 0, "el": 0, "d": {}}
	J.S.erase("bt")
	chk(mundo("club-rv", 9, 2) and corre(func(): await J.object_action(9, 1)) and J.S.map == MP, "partida de antes: se entra")
	# 15 · sin CAL, nada
	nuevo(S0)
	Datos.CAL = false
	chk(mundo("club-rv", 9, 2), "sin CAL, la asociación")
	chk(J.puertas_int("club-rv").is_empty() and J.bt_objetivo() == "" and not J.bt_abierto(), "sin CAL, sin banco (%s)" % [J.MAPS["club-rv"].o[1][9]])
	Datos.CAL = true
	print("banco_tia: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)

# lo andable del cuarto desde la puerta
# 7 · el laboratorio (lo pidió el usuario: «debe parecer un laboratorio de verdad… las normas que tienes que tener en un laboratorio
# real»): la sala aparte, su equipo, la línea amarilla con el EPI, las manos antes que los guantes, nada de catar, sereno, el
# autoclave de cada día, lo usado al contenedor, estabilizar con una y el EPI que no sale
func anda(d: String) -> bool:
	J.P.moving = false
	J.try_move(d)
	var ok := corre(func(): pass)
	J.P.moving = false   # el paso, ya dado (la prueba no anda el fotograma)
	return ok

func laboratorio() -> void:
	var MP: String = J.D.BANCO_TIA.mapa
	var L: String = J.D.LAB.mapa
	LOG = []
	chk(corre(func(): await J.object_action(8, 1)) and J.S.map == L and J.P.x == 1 and J.P.y == 2 and dicho("línea amarilla"), "dentro del laboratorio, con su presentación (%s)" % J.S.map)
	var lm: Dictionary = J.MAPS[L]
	var hay := {}
	for r in lm.o:
		for o in r:
			if o:
				hay[String(o).trim_suffix("2")] = true
	for k in ["labNormas", "labPercha", "labPila", "labDucha", "labLavaojos", "labExtintor", "labBotiquin", "labFlujo", "labAutoclave", "labEstufa", "labNevera", "labMicro", "labBalanza", "labResiduos"]:
		chk(hay.has(k), "en el laboratorio: %s" % k)
	chk(lm.g[2][int(J.D.LAB.linea)] == "floorLabL" and lm.g[7][int(J.D.LAB.linea)] == "floorLabL", "la línea amarilla, de pared a pared")
	var v := alcance_d(L)
	for y in lm.h:
		for x in lm.w:
			if lm.o[y][x] and not String(lm.o[y][x]).ends_with("2"):
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [lm.o[y][x], x, y])
	# la línea amarilla, sin nada
	J.P.x = 4
	J.P.y = 3
	LOG = []
	chk(anda("right") and J.P.x == 4 and dicho("sin lavarte las manos"), "sin lavarte ni el EPI, no se pasa la línea")
	LOG = []
	chk(corre(func(): await J.object_action(2, 2)) and not J.lab().get("e") and dicho("Antes de los guantes"), "los guantes, después de las manos")
	chk(corre(func(): await J.object_action(3, 2)) and J.lab().get("m") == true, "las manos, lavadas")
	LOG = []
	chk(anda("right") and J.P.x == 4 and dicho("Ahora la bata"), "con las manos, pero sin el EPI, tampoco")
	chk(corre(func(): await J.object_action(2, 2)) and J.lab().get("e") == true, "la bata, las gafas y los guantes")
	LOG = []
	chk(corre(func(): await J.object_action(3, 2)) and dicho("Con los guantes puestos"), "con los guantes no se lavan las manos")
	chk(anda("right") and J.P.x == 5, "con el EPI, se pasa la línea")
	# nada de catar dentro, y sereno
	J.S.buds = {"ria": {"g": 30.0, "thc": 14.0, "dia": int(J.S.day)}}
	LOG = []
	chk(corre(func(): await J.catar("ria", .5)) and is_equal_approx(float(J.S.buds.ria.g), 30.0) and dicho("no se fuma"), "en el laboratorio no se cata")
	J.S.colo = 60.0
	LOG = []
	QUIERO = ["Esterilizar"]
	chk(corre(func(): await J.object_action(9, 2)) and not J.lab().has("at") and dicho("colocado"), "colocado, no se trabaja")
	J.S.colo = 0.0
	# el autoclave, antes de la cabina
	J.S.gen.txoko = 1
	J.S.seeds.txoko = 1
	LOG = []
	QUIERO = [J.strain("txoko").n, "Estabilizar"]
	chk(corre(func(): await J.object_action(6, 2)) and Cultivo.gen_de(J.S, "txoko") == 1 and dicho("sin esterilizar"), "sin el autoclave, la cabina no")
	var mn0 := int(J.S.day) * 1440 + int(J.S.min)
	QUIERO = ["Esterilizar"]
	chk(corre(func(): await J.object_action(9, 2)) and int(J.lab().get("at", -1)) == int(J.S.day) and int(J.S.day) * 1440 + int(J.S.min) - mn0 == int(J.D.LAB.esteril), "el autoclave: esterilizado, media hora")
	LOG = []
	QUIERO = [J.strain("txoko").n, "Estabilizar"]
	chk(corre(func(): await J.object_action(6, 2)) and Cultivo.gen_de(J.S, "txoko") == 1 and dicho("Cada generación"), "sin cosechar la línea, no")
	J.cult_apunta("txoko")
	QUIERO = [J.strain("txoko").n, "Cancelar"]
	chk(corre(func(): await J.object_action(7, 2)) and Cultivo.gen_de(J.S, "txoko") == 1 and not J.bt().has("lab"), "cancelar no gasta el día")
	QUIERO = [J.strain("txoko").n, "Estabilizar"]
	LOG = []
	var ok_e := corre(func(): await J.object_action(6, 2))
	chk(ok_e and Cultivo.gen_de(J.S, "txoko") == 2 and int(J.S.seeds.get("txoko", 0)) == 1 and J.lab().get("r") == true, "estabilizada con una: F%d, %d semillas, lo usado sin tirar" % [Cultivo.gen_de(J.S, "txoko"), int(J.S.seeds.get("txoko", 0))])
	LOG = []
	QUIERO = [J.strain("txoko").n, "Estabilizar"]
	chk(corre(func(): await J.object_action(6, 2)) and Cultivo.gen_de(J.S, "txoko") == 2 and dicho("mañana"), "una vez al día")
	J.S.day = int(J.S.day) + 1
	J.cult_apunta("txoko")
	LOG = []
	QUIERO = [J.strain("txoko").n, "Estabilizar"]
	chk(corre(func(): await J.object_action(6, 2)) and Cultivo.gen_de(J.S, "txoko") == 2 and dicho("sin recoger"), "lo de ayer, sin tirar: no")
	chk(corre(func(): await J.object_action(11, 6)) and not J.lab().get("r"), "lo usado, al contenedor amarillo")
	LOG = []
	QUIERO = [J.strain("txoko").n, "Estabilizar"]
	chk(corre(func(): await J.object_action(6, 2)) and Cultivo.gen_de(J.S, "txoko") == 2 and dicho("sin esterilizar"), "otro día, otra vez el autoclave")
	QUIERO = ["Esterilizar"]
	corre(func(): await J.object_action(9, 2))
	QUIERO = [J.strain("txoko").n, "Estabilizar"]
	chk(corre(func(): await J.object_action(6, 2)) and Cultivo.gen_de(J.S, "txoko") == 3, "con todo en regla, la F3 (F%d)" % Cultivo.gen_de(J.S, "txoko"))
	J.S.day = int(J.S.day) + 1
	LOG = []
	QUIERO = [J.strain("txoko").n, "Estabilizar"]
	corre(func(): await J.object_action(11, 6))
	QUIERO = ["Esterilizar"]
	corre(func(): await J.object_action(9, 2))
	QUIERO = [J.strain("txoko").n, "Estabilizar"]
	chk(corre(func(): await J.object_action(6, 2)) and Cultivo.gen_de(J.S, "txoko") == 3 and dicho("Cada generación"), "al día siguiente, sin otra cosecha, no")
	LOG = []
	chk(corre(func(): await J.object_action(0, 1)) and dicho("LAS NORMAS") or dicho("1. Antes de pasar"), "el cartel de las normas")
	# el EPI no sale del laboratorio
	J.P.x = 1
	J.P.y = 2
	LOG = []
	chk(corre(func(): await J.object_action(1, 1)) and J.S.map == MP and J.P.x == 8 and J.P.y == 2 and not J.lab().get("e") and dicho("El EPI no sale"), "al salir, el EPI se queda en la antesala (%s)" % J.S.map)
	J.lab().m = true
	chk(corre(func(): await J.object_action(8, 1)) and J.S.map == L and not J.lab().get("m") and not J.lab().get("e"), "al volver a entrar, otra vez las manos y el EPI")
	J.P.x = 1
	J.P.y = 2
	corre(func(): await J.object_action(1, 1))
	chk(J.S.map == MP, "de vuelta en el cuarto")

func alcance_d(mapa: String) -> Dictionary:
	var m: Dictionary = J.MAPS[mapa]
	var q := [[1, 2]]
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

func delante(v: Dictionary, x: int, y: int) -> bool:
	return [[0, 1], [0, -1], [1, 0], [-1, 0]].any(func(d): return v.has("%d,%d" % [x + d[0], y + d[1]]))
