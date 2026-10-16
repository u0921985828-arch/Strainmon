# Ribera Verde (Godot) — 1.51: los recados por la comarca según el capítulo (lo pidió el usuario: «que haya misiones por el mapa,
# dependiendo del capítulo en el que estés»; D.SECUNDARIAS, con CAL): cada uno en una casilla libre y alcanzable, con su «!», y hechos.
#   $GODOT --headless --path godot --script res://tests/recados.gd   → «recados: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
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

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-recados.json"
	Juego.AJUSTES = "user://prueba-recados-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var R: Array = J.D.SECUNDARIAS
	chk(R.size() >= 10, "diez recados: %d" % R.size())
	var caps := {}
	for sc in R:
		caps[int(sc.ch)] = true
	chk(range(2, 9).all(func(c): return caps.has(c)), "uno o más por capítulo, del 2 al 8: %s" % [caps.keys()])
	# 1 · cada persona, en una casilla libre y alcanzable desde la entrada del mapa
	S.ch = 9
	for sc in R:
		for ab in ["a", "b"]:
			if not sc.has(ab):
				continue
			var p: Dictionary = sc[ab]
			chk(J.D.LOOKS.has(p.look), "%s: el muñeco %s" % [sc.id, p.look])
			var m: Dictionary = J.MAPS[p.map]
			chk(J.pisable(m, int(p.x), int(p.y)) and m.o[int(p.y)][int(p.x)] == null, "%s.%s: casilla libre en %s (%d, %d): %s %s" % [sc.id, ab, p.map, p.x, p.y, m.g[int(p.y)][int(p.x)], m.o[int(p.y)][int(p.x)]])
			chk(not J.D.NPCDEF.any(func(d): return d.map == p.map and int(d.x) == int(p.x) and int(d.y) == int(p.y)), "%s.%s: no pisa a nadie" % [sc.id, ab])
			var v: Dictionary = alcance(p.map)
			var ok: bool = v.has("%d,%d" % [int(p.x), int(p.y)]) and m.o[int(p.y)][int(p.x)] == null
			if not ok:   # la casilla buena más cerca
				var mejor := ""
				var dm := 999
				for k in v:
					var c: PackedStringArray = k.split(",")
					var dd: int = absi(int(c[0]) - int(p.x)) + absi(int(c[1]) - int(p.y))
					if dd < dm and not J.D.NPCDEF.any(func(d): return d.map == p.map and int(d.x) == int(c[0]) and int(d.y) == int(c[1])):
						dm = dd
						mejor = k
				print("  %s.%s → %s" % [sc.id, ab, mejor])
			chk(ok, "%s.%s: se llega (%s %d, %d)" % [sc.id, ab, p.map, p.x, p.y])
	# 2 · el «!» y los capítulos
	S.ch = 2
	S.sec = {}
	J.enter_map("town", 7, 12, "down")
	J.build_ents()
	J.mode = "world"
	chk(J.ents.any(func(x): return x.id == "sec_jubilado") and J.sec_marca("sec_jubilado"), "el jubilado, con su «!», en el capítulo 2")
	S.ch = 1
	J.build_ents()
	J.mode = "world"
	chk(not J.ents.any(func(x): return x.id == "sec_jubilado"), "en el capítulo 1, todavía no")
	S.ch = 2
	J.build_ents()
	J.mode = "world"
	# 3 · gramos: sin nada, no; con 3 g, hecho
	S.buds = {}
	var m0 := float(S.money)
	chk(habla("sec_jubilado") and J.sec_estado("jubilado") == 0, "sin hierba, nada")
	S.buds = {"ria": {"g": 5.0, "thc": 12.0, "dia": S.day}}
	QUIERO = ["Skunk"]
	chk(habla("sec_jubilado") and J.sec_estado("jubilado") == 2 and is_equal_approx(float(S.buds.ria.g), 2.0) and is_equal_approx(float(S.money), m0 + 45), "3 g y 45 € (%s, %s)" % [S.buds, S.money])
	chk(not J.sec_marca("sec_jubilado"), "hecho: sin «!»")
	# 4 · el paquete: de Valdehierro a Ribera Verde
	S.ch = 3
	J.enter_map("valdehierro", 15, 11, "down")
	J.build_ents()
	J.mode = "world"
	QUIERO = ["Sí, dámelo"]
	chk(habla("sec_paquete") and J.sec_estado("paquete") == 1, "el paquete, encima")
	J.enter_map("town", 7, 12, "down")
	J.build_ents()
	J.mode = "world"
	var m1 := float(S.money)
	chk(J.ents.any(func(x): return x.id == "secb_paquete") and J.sec_marca("secb_paquete"), "la vecina espera, con su «!»")
	chk(habla("secb_paquete") and J.sec_estado("paquete") == 2 and is_equal_approx(float(S.money), m1 + 150), "entregado: 150 €")
	J.build_ents()
	J.mode = "world"
	chk(not J.ents.any(func(x): return x.id == "secb_paquete"), "la vecina, ya no")
	# 5 · una landrace pura (la estudiante) y un extracto (la molinera)
	S.ch = 4
	J.enter_map("ibarbide", 10, 20, "down")
	J.build_ents()
	J.mode = "world"
	S.buds = {"ria": {"g": 5.0, "thc": 12.0}, "hindu": {"g": 3.0, "thc": 14.0}}
	QUIERO = ["Hindu"]
	chk(habla("sec_estudiante") and J.sec_estado("estudiante") == 2 and S.buds.ria.g == 5.0, "la landrace: %s" % [S.buds])
	J.enter_map("errotabarri", 7, 13, "down")
	J.build_ents()
	J.mode = "world"
	S.rosin = {"ria": {"g": 2.0, "thc": 60.0}}
	var se0: int = int(S.seeds.get("hindu", 0))
	QUIERO = ["Rosin"]
	chk(habla("sec_molinera") and J.sec_estado("molinera") == 2 and is_equal_approx(float(S.rosin.ria.g), 1.0) and int(S.seeds.get("hindu", 0)) == se0 + 2, "el extracto y 2 semillas")
	# 6 · en OBJETIVO
	QUIERO = ["RECADOS"]
	LOG = []
	chk(corre(func(): await J.recados_menu()), "el menú de recados")
	print("recados: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
