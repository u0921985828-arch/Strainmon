# Landrace Hunters (Godot) — al volante por las carreteras (lo pidió el usuario: «por esos caminos sí que se puede utilizar tanto el
# coche como la moto, como el otro coche, como el superdeportivo, lo que sea»), con Datos.CAL: desde el garaje o el aparcamiento,
# «Por la carretera a…» (las abiertas), la gasolina y los km al salir, el vehículo en la carretera (solo por la calzada; la bici y el
# patinete, por donde quieras) y, al salir por un extremo, aparcado en ese pueblo; en Ribera Verde, en el garaje. Sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/volante.gd   → «volante: N comprobaciones, 0 fallos»
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
			return false
	return true

# de pie en la salida (x, y) de la carretera y empujando hacia su lado: ¿a dónde se llega?
func anda(mapa: String, x: int, y: int, lado: String) -> String:
	J.enter_map(mapa, x, y, lado)
	J.mode = "world"
	var t0: float = M.reloj
	J.try_move(lado)
	while J.S.map == mapa or not J.is_free() or J.fade_tw_vivo() or not J.pending.is_empty():
		if M.reloj - t0 > 20000 or not M.paso():
			break
	return "%s|%d,%d" % [J.S.map, J.P.x, J.P.y]

func al_garaje() -> void:   # delante de la puerta del garaje, mirando a ella
	J.enter_map("town", 10, 9, "up")
	J.mode = "world"
	J.P.fx = 10
	J.P.fy = 9

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-volante.json"
	Juego.AJUSTES = "user://prueba-volante-ajustes.json"
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
	var D: Dictionary = J.D
	var S: Dictionary = J.S
	var C: Dictionary = D.CARRETERAS
	S.money = 5000
	S.banco = 0
	S.min = 600
	S.erase("veh")
	S.coches = {}
	for k in ["moto", "utilitario", "berlina", "deportivo"]:
		S.coches[k] = {"dia": 0, "p": 1000, "r": S.day + 365, "iv": S.day + 365}
	# 1 · cerradas: con el capítulo 0, del garaje solo la carretera que ya está abierta (la del monte, a Mendialde)
	S.ch = 0
	al_garaje()
	QUIERO = ["Salir en el utilitario", "Nada"]
	MENUS = []
	corre(func(): await J.object_action(10, 8))
	var cm: Array = MENUS[-1] if MENUS.size() else []
	var rutas_town := {}   # las carreteras de Ribera Verde (cada una, con una o dos casillas de salida)
	for q in C.puertas.town:
		rutas_town[q[2]] = int(C.rutas[q[2]].ch)
	var abiertas: Array = rutas_town.keys().filter(func(id): return rutas_town[id] == 0)
	chk(cm.filter(func(l): return String(l).begins_with("Por la carretera a ")).size() == abiertas.size() and abiertas.size() >= 1, "capítulo 0: solo las abiertas (%s)" % [cm])
	chk(S.map == "town" and not S.has("volante"), "«Nada»: sigues en el pueblo")
	# 2 · del garaje, al volante por la carretera de la costa: la gasolina y los km al salir, y en la carretera, el utilitario
	S.ch = 9
	al_garaje()
	QUIERO = ["Salir en el utilitario", "Por la carretera a Puerto Viejo"]
	MENUS = []
	var c0: float = float(S.money) + float(S.banco)
	chk(corre(func(): await J.object_action(10, 8)), "garaje → carretera de la costa")
	cm = MENUS[-1] if MENUS.size() else []
	var por: Array = cm.filter(func(l): return String(l).begins_with("Por la carretera a "))
	chk(por.size() == rutas_town.size() and rutas_town.size() == 5, "del garaje, las %d carreteras de Ribera Verde, una vez cada una (%s)" % [rutas_town.size(), por])
	var eur: int = J.tramo_carretera("town", "puerto", "utilitario").eur
	chk(S.map == "carr-costa" and S.get("volante") is Dictionary and S.volante.k == "utilitario" and S.volante.de == "town", "en la carretera, al volante del utilitario (%s, %s)" % [S.map, S.get("volante")])
	chk(absf(c0 - float(S.money) - float(S.banco) - eur) < 0.01 and eur >= 1, "la gasolina, al salir: %d €" % eur)
	chk(int(S.coches.utilitario.get("km", 0)) == int(D.CONCE.km.puerto), "los km de la carretera: %s" % S.coches.utilitario.get("km"))
	chk(J.vehiculo() == "utilitario" and absf(J.paso_ms() - float(D.VEHICULOS.utilitario.paso[0])) < 0.01, "en la carretera, el utilitario y su paso (%s, %s)" % [J.vehiculo(), J.paso_ms()])
	var q0: Array = C.puertas.town.filter(func(q): return q[2] == "carr-costa")[0]
	chk(J.P.x == int(q0[3]) and J.P.y == int(q0[4]) and String(J.MAPS["carr-costa"].g[J.P.y][J.P.x]).substr(0, 2) in ["ro", "cv"], "llegas por el extremo de Ribera Verde, en la calzada (%d, %d)" % [J.P.x, J.P.y])
	# solo por la calzada: hacia la hierba, no se mueve
	var y0: int = J.P.y
	J.try_move("up")
	chk(J.P.y == y0, "el coche no se sale de la calzada (%d → %d)" % [y0, J.P.y])
	# 3 · por el otro extremo, a Puerto Viejo: aparcado en el aparcamiento de la parada, y a pie
	var r := anda("carr-costa", 0, 6, "left")
	chk(r.begins_with("puerto|"), "la carretera de la costa → Puerto Viejo (%s)" % r)
	chk(J.donde("utilitario") == "puerto" and not S.has("volante") and int(S.coches.utilitario.get("ap", -1)) == int(S.day), "aparcado en Puerto Viejo, hoy (%s, %s)" % [J.donde("utilitario"), S.get("volante")])
	var pl: Array = J.plazas_parque("puerto")
	chk(J.coche_en(pl[0].x, pl[0].y) == "utilitario" and J.P.x == pl[0].x + 2 and J.P.y == pl[0].y, "en su plaza y tú en el pasillo, a su lado (%d, %d)" % [J.P.x, J.P.y])
	chk(J.vehiculo() == null, "en el pueblo, a pie")
	# 4 · de Puerto Viejo a Valdehierro por la pista de los acantilados (8 km como poco) y de Valdehierro al garaje por el valle
	J.enter_map("puerto", int(D.PARADAS.puerto.a[0]), int(D.PARADAS.puerto.a[1]), "down")
	J.mode = "world"
	QUIERO = ["En el utilitario", "Por la carretera a Valdehierro"]
	MENUS = []
	chk(corre(func(): await J.parada_action()), "parada de Puerto Viejo → al volante")
	chk(S.map == "carr-acantilado" and J.vehiculo() == "utilitario", "en la pista de los acantilados (%s)" % S.map)
	r = anda("carr-acantilado", 0, 6, "left")
	chk(r.begins_with("valdehierro|") and J.donde("utilitario") == "valdehierro", "→ Valdehierro, aparcado allí (%s)" % r)
	chk(int(S.coches.utilitario.km) == int(D.CONCE.km.puerto) + 8, "de pueblo a pueblo sin pasar por Ribera Verde, 8 km: %s" % S.coches.utilitario.km)
	J.enter_map("valdehierro", int(D.PARADAS.valdehierro.a[0]), int(D.PARADAS.valdehierro.a[1]), "down")
	J.mode = "world"
	QUIERO = ["En el utilitario", "Por la carretera a Ribera Verde"]
	corre(func(): await J.parada_action())
	chk(S.map == "carr-valle", "parada de Valdehierro → la carretera del valle (%s)" % S.map)
	r = anda("carr-valle", int(J.MAPS["carr-valle"].w) - 1, 6, "right")
	chk(r.begins_with("town|") and J.donde("utilitario") == J.GARAJE and J.P.x == int(J.GARAJE_B.x0) + 1 and J.P.y == int(J.GARAJE_B.y0) + int(J.GARAJE_B.h), "→ Ribera Verde: al garaje, y sales por su puerta (%s)" % r)
	chk(J.aparcados("town").has("utilitario") and J.coche_en(J.P.x, J.P.y) == "", "en el garaje, no en la calle: %s" % [S.coches.utilitario])
	# 5 · la moto y el superdeportivo, igual; y la vuelta por el mismo extremo, al garaje
	for k in ["moto", "deportivo"]:
		al_garaje()
		var art: String = D.CONCE.v[k].art
		QUIERO = ["Salir en " + art, "Por la carretera a Mendialde"]
		corre(func(): await J.object_action(10, 8))
		chk(S.map == "carr-monte" and J.vehiculo() == k and absf(J.paso_ms() - float(D.VEHICULOS[k].paso[0])) < 0.01, "%s: en la carretera del monte, al volante (%s, %s)" % [k, S.map, J.vehiculo()])
		r = anda("carr-monte", 0, 6, "left")
		chk(r.begins_with("town|") and J.donde(k) == J.GARAJE and not S.has("volante"), "%s: de vuelta, al garaje (%s)" % [k, r])
	# 6 · sin dinero para la gasolina: no sales
	S.money = 0
	S.banco = 0
	al_garaje()
	QUIERO = ["Salir en la berlina", "Por la carretera a Ibarbide"]
	LOG = []
	corre(func(): await J.object_action(10, 8))
	chk(S.map == "town" and not S.has("volante") and LOG.any(func(t): return String(t).begins_with("Para la gasolina")), "sin gasolina, en el garaje (%s)" % S.map)
	S.money = 5000
	# 7 · a pie, en bici o en patinete: por la carretera también, y por donde quieras
	J.enter_map("carr-valle", 5, 6, "up")
	J.mode = "world"
	chk(J.vehiculo() == null, "a pie, a pie")
	S.veh = {"bici": S.day}
	chk(J.vehiculo() == "bici", "en bici por la carretera (%s)" % J.vehiculo())
	J.try_move("up")
	chk(J.P.y == 5, "en bici, también por la hierba (%d)" % J.P.y)
	S.veh = {"patinete": S.day}
	chk(J.vehiculo() == "patinete", "en patinete (%s)" % J.vehiculo())
	S.erase("veh")
	# 8 · sin CAL, nada: ni las opciones ni el coche en la carretera
	S.volante = {"k": "utilitario", "de": "town", "tl": ""}
	Datos.CAL = false
	chk(J.carreteras_de("town").is_empty() and J.vehiculo() == null, "sin CAL, sin carreteras al volante")
	Datos.CAL = true
	S.erase("volante")
	for f in fallos:
		print("FALLO  ", f)
	print("volante: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
