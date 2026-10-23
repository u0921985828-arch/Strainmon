# Ribera Verde (Godot) — los pueblos de siempre, menos de regla y con sus sitios (lo pidió el usuario: «toca también los otros para
# que sean de jugabilidad, pues como estos… que no sea todo el mismo esquema de pueblo» y «más natural, que no sea tan cuadrado.
# Pero que los píxeles sean perfectos»; tools/pueblos.py → PUEBLOS en datos.json, con CAL): plazas, charcas y sendas en mancha,
# un hito por pueblo (lavadero, kiosko, grúa, frontón, ermita, faro, chimenea) que se mira y da juego, y la ermita de Mendialde
# por dentro con su serora. Sin CAL, los mapas como siempre. Tras la revisión: cada pueblo con su hito (la torre del reloj de
# Ibarbide, el quiosco de prensa del Ensanche y el colmenar de Errotabarri) y cada hito con algo que hacer; sin clientes bajo las
# copas de los árboles nuevos.
#   $GODOT --headless --path godot --script res://tests/pueblos.gd   → «pueblos: N comprobaciones, 0 fallos»
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
var ATLAS := ""
var fallos := []

# el hito de cada mapa (los de tools/pueblos.py)
const HITOS := {"town": ["lavadero"], "alto": ["kiosko"], "astilleros": ["gruaT"], "mendialde": ["fronton", "ermita"], "puerto": ["faro"],
	"valdehierro": ["chimenea"], "errotabarri": ["colmenas"], "ibarbide": ["reloj"], "ensanche": ["prensa"]}

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

func hitos(m: Dictionary) -> Array:
	return m.blds.filter(func(b): return b.has("hito"))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-pueblos.json"
	Juego.AJUSTES = "user://prueba-pueblos-ajustes.json"
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
	J.S.money = 5000
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var PU: Dictionary = D.PUEBLOS.MAPS
	ATLAS = FileAccess.get_file_as_string("res://arte/atlas.json")
	chk(PU.size() == 9, "9 pueblos: %s" % [PU.keys()])
	# 1 · con CAL: cada cambio puesto, cada hito con sus casillas y todo lo que se alcanzaba, alcanzable
	for k in PU:
		J.enter_map(k, int(J.MAPS[k].w) / 2, 1, "down")
		var m: Dictionary = J.MAPS[k]
		var mal := 0
		for c in PU[k].cambia:
			if m.g[int(c[1])][int(c[0])] != c[2] or m.o[int(c[1])][int(c[0])] != c[3]:
				mal += 1
		chk(mal == 0, "%s: %d casillas sin poner" % [k, mal])
		var hs: Array = hitos(m).map(func(b): return b.hito)
		chk(hs == HITOS[k], "%s: hitos %s" % [k, hs])
		var v: Dictionary = alcance(k)
		for b in hitos(m):
			var dentro := 0
			var junto := false
			for y in range(int(b.y0), int(b.y0) + int(b.h)):
				for x in range(int(b.x0), int(b.x0) + int(b.w)):
					if String(m.g[y][x]).begins_with("hito_") or String(m.g[y][x]).begins_with("door_"):
						dentro += 1
			for y in range(int(b.y0) - 1, int(b.y0) + int(b.h) + 1):
				for x in range(int(b.x0) - 1, int(b.x0) + int(b.w) + 1):
					if v.has("%d,%d" % [x, y]):
						junto = true
			chk(dentro == int(b.w) * int(b.h), "%s/%s: %d de %d casillas sólidas" % [k, b.hito, dentro, int(b.w) * int(b.h)])
			chk(junto, "%s/%s: no se llega al lado" % [k, b.hito])
			chk(ATLAS.contains('"edificio-%s"' % b.hito), "%s: sin sprite" % b.hito)
		# los clientes, solo donde se llega
		var ct: Array = D.CLIENT_TILES.get(k, [])
		var fuera := ct.filter(func(p): return not v.has("%d,%d" % [int(p[0]), int(p[1])]))
		chk(ct.size() > 0 and fuera.is_empty(), "%s: %d clientes fuera de alcance (de %d)" % [k, fuera.size(), ct.size()])
		var tap := 0   # bajo la copa de un árbol que pone pueblos.py, ninguno
		for c in PU[k].cambia:
			if str(c[3]) in ["tree", "tree2", "platano", "manzano"]:
				tap += ct.filter(func(p): return abs(int(p[0]) - int(c[0])) <= 1 and int(p[1]) < int(c[1]) and int(p[1]) >= int(c[1]) - 5).size()
		chk(tap == 0, "%s: %d clientes bajo las copas nuevas" % [k, tap])
	# 2 · sin CAL: los mapas como siempre
	Datos.CAL = false
	Datos.carga()
	for k in PU:
		J.enter_map(k, int(J.MAPS[k].w) / 2, 1, "down")
		var m: Dictionary = J.MAPS[k]
		var mal := 0
		for c in PU[k].cambia:
			if m.g[int(c[1])][int(c[0])] != c[4] or m.o[int(c[1])][int(c[0])] != c[5]:
				mal += 1
		chk(mal == 0, "sin CAL %s: %d casillas cambiadas" % [k, mal])
		chk(hitos(m).is_empty(), "sin CAL %s: hitos" % k)
		chk(not m.doors.values().any(func(d): return String(d.get("gate", "")) == "iglesia:ermita"), "sin CAL %s: la ermita" % k)
	Datos.CAL = true
	Datos.carga()
	# 3 · lo que hace cada hito
	J.enter_map("town", 26, 15, "right")
	J.S.borr = 20.0
	var t := hace(["Lavarte"], func(): await J.object_action(27, 15))
	chk(J.borr() < 20.0 and t.length() > 0, "lavadero: %s %s" % [J.borr(), t])
	J.enter_map("mendialde", 25, 22, "up")
	J.S.hp = 1
	t = hace(["Pelotear"], func(): await J.object_action(25, 21))
	chk(int(J.S.hp) == 4, "frontón: hp %s" % J.S.hp)
	J.enter_map("puerto", 36, 20, "right")
	J.S.heat = 30
	t = hace([], func(): await J.object_action(37, 20))
	chk(float(J.S.heat) == 28.0, "faro: calor %s" % J.S.heat)
	t = hace([], func(): await J.object_action(37, 20))
	chk(float(J.S.heat) == 28.0 and "Ya has estado" in t, "faro, otra vez el mismo día: %s" % t)
	# el kiosko: la banda los domingos a mediodía
	J.enter_map("alto", 14, 9, "up")
	var dom := int(J.S.day)
	while int(Datos.fecha(dom).s) != 6:
		dom += 1
	J.S.day = dom
	J.S.min = 750
	t = hace([], func(): await J.object_action(14, 8))
	chk("banda toca" in t, "kiosko el domingo: %s" % t)
	J.S.day = dom + 1
	t = hace([], func(): await J.object_action(14, 8))
	chk("jubilados" in t, "kiosko el lunes: %s" % t)
	t = hace([], func(): await J.object_action(14, 8))
	chk("Los domingos" in t, "kiosko el lunes, otra vez: %s" % t)
	# (revisión) cada hito, el suyo, y con algo que hacer
	var todos := []
	for k in PU:
		for b in PU[k].blds:
			chk(not (b.hito in todos), "hito repetido: %s" % b.hito)
			todos.append(b.hito)
	J.S.day = dom + 2
	J.S.min = 600
	J.enter_map("alto", 14, 9, "up")
	t = hace([], func(): await J.object_action(14, 8))
	chk("jubilados" in t and int(J.S.min) == 615, "kiosko entre semana: %s" % t)
	J.enter_map("astilleros", 28, 18, "up")
	var xp := int(J.S.pelea.xp)
	hace(["Darle"], func(): await J.object_action(28, 17))
	chk(int(J.S.pelea.xp) == xp + J.GRUA_XP, "la grúa: xp %s" % J.S.pelea.xp)
	hace(["Darle"], func(): await J.object_action(28, 17))
	chk(int(J.S.pelea.xp) == xp + J.GRUA_XP, "la grúa, otra vez: xp %s" % J.S.pelea.xp)
	J.enter_map("valdehierro", 27, 22, "up")
	var m0 := float(J.S.money)
	hace(["Rebuscar"], func(): await J.object_action(27, 21))
	chk(float(J.S.money) >= m0 + 5 and float(J.S.money) <= m0 + 15, "la chatarra: %s" % J.S.money)
	J.enter_map("ensanche", 21, 17, "up")
	m0 = float(J.S.money)
	t = hace(["Comprar"], func(): await J.object_action(21, 16))
	chk(float(J.S.money) == m0 - J.PERIODICO and "mañana" in t and "°C" in t, "el periódico: %s %s" % [J.S.money, t])
	J.enter_map("ibarbide", 21, 16, "up")
	J.S.min = 600
	hace(["Hasta las 14"], func(): await J.object_action(21, 15))
	chk(int(J.S.min) == 840, "el reloj: %s" % J.S.min)
	J.enter_map("errotabarri", 14, 6, "up")
	J.S.hp = 5
	hace(["Coger"], func(): await J.object_action(14, 5))
	chk(int(J.S.hp) == 11 or int(J.S.hp) == 3, "la miel: %s" % J.S.hp)
	J.enter_map("mendialde", 24, 11, "up")
	J.S.borr = 20.0
	hace(["Sentarte"], func(): await J.object_action(24, 10))
	chk(J.borr() < 20.0, "el pórtico de la ermita: %s" % J.borr())
	# lejos de un hito, nada
	J.enter_map("town", 5, 20, "up")
	chk(not J.hito_de(5, 19), "fuera de un hito")
	# 4 · la ermita: la puerta, la serora, las velas y el banco
	J.enter_map("mendialde", 25, 11, "up")
	var d: Dictionary = J.MAPS.mendialde.doors.get("25,10", {})
	chk(d.get("to") == "ermita-in" and d.get("gate") == "iglesia:ermita", "la puerta de la ermita: %s" % [d])
	J.S.min = 1300
	t = hace([], func(): await J.entra_local(d))
	chk(J.S.map == "mendialde" and "Cerrado" in t, "de noche, cerrada: %s %s" % [J.S.map, t])
	J.S.min = 600
	J.enter_map("mendialde", 25, 11, "up")
	chk(corre(func(): await J.entra_local(d)), "entrar")
	chk(J.S.map == "ermita-in", "dentro: %s" % J.S.map)
	var ser: Array = J.ents.filter(func(x): return x.get("id") == "bi_serora")
	chk(ser.size() == 1, "la serora")
	t = hace([], func(): await J.talk_ciudad("bi_serora"))
	chk("tu tía" in t.to_lower() or "Tu tía" in t, "la serora, la primera vez: %s" % t)
	t = hace([], func(): await J.talk_ciudad("bi_serora"))
	chk(not ("Tu tía" in t), "la serora, después: %s" % t)
	var ok := {}
	var IN: Dictionary = J.MAPS["ermita-in"]
	for y in IN.h:
		for x in IN.w:
			var o = IN.o[y][x]
			if o == null or ok.has(o) or o == "bancoI":
				continue
			ok[o] = 1
			t = hace(["No"], func(): await J.object_action(x, y))
			chk(t.length() > 0 or MENUS.size() > 0, "ermita: %s mudo" % o)
	J.S.heat = 20
	chk(corre(func(): await J.rato_sentado()), "rato")
	chk(float(J.S.heat) == 17.0, "un rato en la ermita baja el calor: %s" % J.S.heat)
	_fin()

func _fin() -> void:
	for x in fallos:
		print("  FALLO " + x)
	print("pueblos: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
