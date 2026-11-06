# Ribera Verde (Godot) — Bilbao por dentro (lo pidió el usuario: «molaría poder acceder al teatro… y a la iglesia también… piensa
# en qué edificios podrían tener juego en la historia»; ciudad.gd, con CAL): el teatro (taquilla de 18:00 a 21:00, la función a las
# nueve y el entreacto, que apunta a alguien en la agenda), las iglesias (velas, cepillo, confesionario y un rato en el banco, que
# enfrían el calor), el mercado de la Ribera (puestos y barra: comer da vida y baja la borrachera) y sus horarios en la puerta.
#   $GODOT --headless --path godot --script res://tests/interiores_bilbao.gd   → «interiores_bilbao: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var D
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

# el hito de cada mapa (los de tools/pueblos.py)

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
	if QUIERO.size():
		var q: String = QUIERO.pop_front()
		for i in labels.size():
			if labels[i].begins_with(q):
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
			return false
	return true

func hace(q: Array, f: Callable) -> String:
	QUIERO = q
	LOG = []
	MENUS = []
	chk(corre(f), "bloqueo con %s" % [q])
	return " ".join(LOG)

# lo que se alcanza andando desde donde se llega: puertas y salidas de los otros mapas, la parada y las propias salidas
func alcance(k: String) -> Dictionary:
	var m: Dictionary = J.MAPS[k]
	var q := []
	for mk in J.MAPS:
		for t in ["doors", "exits"]:
			for d in J.MAPS[mk].get(t, {}).values():
				if d is Dictionary and d.get("to") == k:
					q.append(Vector2i(int(d.x), int(d.y)))
	if D.PARADAS.has(k):
		q.append(Vector2i(int(D.PARADAS[k].a[0]), int(D.PARADAS[k].a[1])))
	for e in m.exits:
		var p: PackedStringArray = e.split(",")
		q.append(Vector2i(int(p[0]), int(p[1]) - 1))
	var v := {}
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		var kk := "%d,%d" % [c.x, c.y]
		if v.has(kk) or not J.pisable(m, c.x, c.y) or m.o[c.y][c.x] != null and not J.MAPS[k].doors.has(kk):
			continue
		v[kk] = true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			q.append(c + d)
	return v

func puerta(mapa: String, to: String) -> Dictionary:
	for d in J.MAPS[mapa].doors.values():
		if d.get("to") == to:
			return d
	return {}

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-interiores.json"
	Juego.AJUSTES = "user://prueba-interiores-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "caja-dentro":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	D = J.D
	J.S = e.S
	J.S.ch = 8
	J.S.money = 500
	J.S.fijos = []
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · las puertas: cerradas fuera de hora, abiertas dentro
	for q in [["casco", "teatro-in", 300, 700], ["casco", "catedral-in", 300, 600], ["casco", "mercado-in", 960, 600], ["zorroza", "iglesiaz-in", 1230, 600], ["mendialde", "ermita-in", 1230, 600]]:
		J.enter_map(q[0], 2, 2, "down")
		var d := puerta(q[0], q[1])
		chk(not d.is_empty(), "%s: sin puerta a %s" % [q[0], q[1]])
		if d.is_empty():
			continue
		J.S.min = q[2]
		var t := hace([], func(): await J.entra_local(d))
		chk(J.S.map == q[0] and "Cerrado" in t, "%s a las %d: abierto (%s)" % [q[1], q[2], t])
		J.S.min = q[3]
		J.enter_map(q[0], 2, 2, "down")
		chk(corre(func(): await J.entra_local(d)), "entrar en " + q[1])
		chk(J.S.map == q[1], "%s: dentro (%s)" % [q[1], J.S.map])
	# 2 · el teatro: la taquilla, la función y el entreacto
	J.enter_map("teatro-in", 10, 12, "up")
	J.S.min = 700
	var t := hace(["Comprar"], func(): await J.talk_ciudad("bi_taquillera"))
	chk("abre a las seis" in t and int(J.ciu().get("ent", -1)) != int(J.S.day), "taquilla cerrada a las 11:40: %s" % t)
	J.S.min = 1100
	var m0 := float(J.S.money)
	hace(["Comprar"], func(): await J.talk_ciudad("bi_taquillera"))
	chk(float(J.S.money) == m0 - J.ENTRADA and int(J.ciu().ent) == int(J.S.day), "la entrada: %s" % J.S.money)
	t = hace([], func(): await J.funcion_teatro())
	chk(int(J.S.min) == J.FUNCION[1] and J.obra()[0] in t, "la función: %s %s" % [J.S.min, t])
	chk(J.S.fijos.size() == 1 and J.S.fijos[0].t == "vip", "el entreacto, a la agenda: %s" % [J.S.fijos])
	t = hace([], func(): await J.funcion_teatro())
	chk("Sin entrada" in t, "sin otra entrada: %s" % t)
	# 3 · la iglesia: el cepillo y el confesionario, una vez
	J.enter_map("catedral-in", 7, 12, "up")
	J.S.min = 700
	J.S.heat = 40
	m0 = float(J.S.money)
	hace(["Echar"], func(): await J.iglesia_obj("cepilloI"))
	chk(float(J.S.heat) == 35.0 and float(J.S.money) == m0 - J.CEPILLO, "el cepillo: %s %s" % [J.S.heat, J.S.money])
	t = hace(["Echar"], func(): await J.iglesia_obj("cepilloI"))
	chk(float(J.S.heat) == 35.0 and "ya has echado" in t, "el cepillo, otra vez: %s" % t)
	hace(["Confesarte"], func(): await J.iglesia_obj("confesI"))
	chk(float(J.S.heat) == 25.0, "el confesionario: %s" % J.S.heat)
	t = hace(["Confesarte"], func(): await J.iglesia_obj("confesI"))
	chk(float(J.S.heat) == 25.0 and "Hace nada" in t, "el confesionario, otra vez: %s" % t)
	chk(corre(func(): await J.rato_sentado()), "rato")
	chk(float(J.S.heat) == 22.0, "el banco: %s" % J.S.heat)
	t = hace(["Encender"], func(): await J.iglesia_obj("velasI"))
	chk("tía Maite" in t, "la vela: %s" % t)
	# 4 · el mercado: los puestos dan vida y bajan la borrachera
	J.enter_map("mercado-in", 10, 9, "up")
	J.S.min = 600
	J.S.hp = 1
	J.S.borr = 30.0
	hace(["Comprar"], func(): await J.puesto("ca"))
	chk(int(J.S.hp) == 11 and J.borr() <= 20.0 and J.borr() > 18.0, "el bocadillo: %s %s" % [J.S.hp, J.borr()])
	var gente: Array = J.ents.map(func(x): return x.get("id"))
	chk("bi_camarero" in gente and "bi_me_fr" in gente, "la gente del mercado: %s" % [gente])
	J.S.min = 1000
	J.enter_map("mercado-in", 10, 9, "up")
	gente = J.ents.map(func(x): return x.get("id"))
	chk(not ("bi_camarero" in gente), "a las 16:40, sin gente: %s" % [gente])
	# 5 · (revisión) a la hora de cerrar, a la calle: ni puestos ni barra ni velas sin nadie
	J.S.min = 950
	t = hace(["Comprar"], func(): await J.obj_ciudad("puestoCa"))
	chk(J.S.map == "casco" and "cerramos" in t, "el mercado cerrado te echa: %s %s" % [J.S.map, t])
	J.enter_map("catedral-in", 7, 12, "up")
	J.S.min = 1250
	m0 = float(J.S.money)
	hace(["Encender"], func(): await J.obj_ciudad("velasI"))
	chk(J.S.map == "casco" and float(J.S.money) == m0, "la iglesia cerrada te echa: %s" % J.S.map)
	# 6 · (revisión) en cada zona de Bilbao se entra en algo; en cada sitio de dentro, todo se alcanza y la salida vuelve a su puerta
	for k in D.BILBAO.MAPS:
		var ps: Array = J.MAPS[k].doors.values().filter(func(d): return d.get("gate"))
		chk(ps.size() >= 2, "%s: %d puertas" % [k, ps.size()])
		for d in ps:
			var IN: Dictionary = J.MAPS[d.to]
			var ex: Dictionary = IN.exits.values()[0]
			chk(ex.to == k and J.MAPS[k].doors.has("%d,%d" % [int(ex.x), int(ex.y) - 1]), "%s: la salida no vuelve a su puerta (%s)" % [d.to, ex])
			J.S.min = 600
			J.enter_map(k, int(ex.x), int(ex.y), "up")
			chk(corre(func(): await J.entra_local(d)), "entrar en " + d.to)
			chk(J.S.map == d.to, "%s: dentro (%s)" % [d.to, J.S.map])
			var v := alcance(d.to)
			for y in IN.h:
				for x in IN.w:
					var o = IN.o[y][x]
					if o == null or String(o).ends_with("2") and x > 0 and IN.o[y][x - 1] == String(o).left(-1):
						continue
					var junto := false
					for c in [Vector2i(x + 1, y), Vector2i(x - 1, y), Vector2i(x, y + 1), Vector2i(x, y - 1), Vector2i(x + 2, y), Vector2i(x + 1, y + 1)]:
						junto = junto or v.has("%d,%d" % [c.x, c.y])
					chk(junto, "%s: %s en (%d, %d) no se alcanza" % [d.to, o, x, y])
			for nn in D.BILBAO.NPC:
				if nn.map == d.to:
					var junto := false
					for c in [Vector2i(nn.x + 1, nn.y), Vector2i(nn.x - 1, nn.y), Vector2i(nn.x, nn.y + 1), Vector2i(nn.x, nn.y - 1), Vector2i(nn.x, nn.y + 2)]:
						junto = junto or v.has("%d,%d" % [c.x, c.y])
					chk(junto, "%s: %s no se alcanza" % [d.to, nn.id])
	# 7 · la estación: el tren, más barato que el autobús
	J.S.min = 700
	J.enter_map("zorrozae-in", 7, 9, "up")
	m0 = float(J.S.money)
	var pv: Dictionary = J.tren_viaje("puerto")
	chk(float(pv.eur) < float(J.viaje("zorroza", "puerto").eur) and int(pv.min) < int(J.viaje("zorroza", "puerto").min), "el tren: %s" % [pv])
	hace([String(D.PARADAS.puerto.n)], func(): await J.talk_ciudad("bi_taquillero_zorrozae"))
	chk(J.S.map == "puerto" and is_equal_approx(float(J.S.money), m0 - float(pv.eur)), "el tren a Puerto Viejo: %s %s" % [J.S.map, J.S.money])
	chk(int(J.P.x) == int(J.apeadero_de("puerto")[0]) and int(J.P.y) == int(J.apeadero_de("puerto")[1]), "el tren llega al apeadero, no a la parada: (%s, %s)" % [J.P.x, J.P.y])
	# 8 · Hacienda: declarar efectivo, una vez a la semana
	J.S.min = 600
	J.enter_map("hacienda-in", 7, 8, "up")
	J.S.money = 2000
	var b0 := float(J.S.banco)
	hace([Datos.eur(1000)], func(): await J.talk_ciudad("bi_funcionaria"))
	chk(float(J.S.money) == 1000.0 and is_equal_approx(float(J.S.banco), b0 + 700.0), "Hacienda: %s %s" % [J.S.money, J.S.banco])
	t = hace([Datos.eur(1000)], func(): await J.talk_ciudad("bi_funcionaria"))
	chk(float(J.S.money) == 1000.0 and "por semana" in t, "Hacienda, otra vez: %s" % t)
	# 9 · el almacén: el jornal; el molino: la cabezada
	J.S.min = 480
	J.enter_map("almacen-in", 7, 8, "up")
	m0 = float(J.S.money)
	J.S.hp = 10
	hace(["Descargar"], func(): await J.talk_ciudad("bi_capataz"))
	chk(float(J.S.money) == m0 + J.JORNAL.eur and int(J.S.min) == 480 + J.JORNAL.min and int(J.S.hp) == 7, "el jornal: %s %s %s" % [J.S.money, J.S.min, J.S.hp])
	t = hace(["Descargar"], func(): await J.talk_ciudad("bi_capataz"))
	chk(float(J.S.money) == m0 + J.JORNAL.eur and "ya has cobrado" in t, "el jornal, otra vez: %s" % t)
	J.S.min = 600
	J.enter_map("molino-in", 6, 7, "up")
	J.S.hp = 1
	hace(["Echar"], func(): await J.obj_ciudad("sacos"))
	chk(int(J.S.hp) == 7, "la cabezada: %s" % J.S.hp)
	t = hace([], func(): await J.obj_ciudad("ruedaM"))
	chk("marea" in t, "la rueda: %s" % t)
	# 10 · el teatro del Ensanche, con su obra y su entrada
	J.S.min = 1100
	J.enter_map("campose-in", 10, 12, "up")
	var o2: String = J.obra()[0]
	hace(["Comprar"], func(): await J.talk_ciudad("bi_taquillera_c"))
	chk(int(J.ciu().ent) == int(J.S.day) and J.ciu().entM == "campose-in", "la entrada del Ensanche: %s" % [J.ciu()])
	J.enter_map("teatro-in", 10, 12, "up")
	chk(J.obra()[0] != o2, "la misma obra en los dos teatros")
	t = hace([], func(): await J.funcion_teatro())
	chk("Sin entrada" in t, "la entrada del Ensanche vale en el otro: %s" % t)
	_fin()

func _fin() -> void:
	for x in fallos:
		print("  FALLO " + x)
	print("interiores_bilbao: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
