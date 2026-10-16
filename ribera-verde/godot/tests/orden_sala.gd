# Ribera Verde (Godot) — 1.52.1: una sala se ordena solo desde dentro de ella (lo pidió el usuario: «cómo va a estar el mueble de
# ordenar una sala en otra»). Con CAL, en cada mapa con ORDEN_P y en las salas de al lado (PUERTAS_INT), A en cada mueble: el menú de
# ordenar un mapa solo sale estando en ese mapa, y cada mapa ordenable tiene en él un mueble que lo ordena.
#   $GODOT --headless --path godot --script res://tests/orden_sala.gd   → «orden_sala: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var n := 0
var fallos := []
var VISTO := []   # [mapa en el que estás, título del menú, etiquetas]

func _initialize() -> void:
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# elige «Ordenar …» si lo hay; si no, B (y lo último, por si el menú no se cancela)
func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	VISTO.append([J.S.map, str(o.get("title", "")), labels])
	var k := labels.size() - 1
	var hay := false
	for i in labels.size():
		if labels[i].begins_with("Ordenar"):
			k = i
			hay = true
			break
	if not hay:
		M.timeout(func(): J.press("B"), 5)
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

func entra(mapa: String) -> void:
	J.enter_map(mapa, 1, 2, "up")
	J.build_ents()
	J.mode = "world"

func titulos() -> Dictionary:   # título de ORDEN_P → mapa
	var T := {}
	for mk in J.D.ORDEN_P:
		T[J.D.ORDEN_P[mk].n] = mk
	return T

# A en cada mueble del mapa (sin puertas ni camas): devuelve los mapas que se han ordenado desde aquí
func prueba_mapa(mapa: String) -> Array:
	entra(mapa)
	var T := titulos()
	var m: Dictionary = J.MAPS[mapa]
	var hechos := []
	var vistos := {}
	for y in int(m.h):
		for x in int(m.w):
			var o = m.o[y][x]
			if o == null or vistos.has(o) or str(o).begins_with("puerta") or str(o) in ["bedT", "bedB", "door", "exit"]:
				continue
			vistos[o] = true
			VISTO.clear()
			J.S.map = mapa
			J.P.x = x
			J.P.y = mini(y + 1, int(m.h) - 1)
			corre(func(): await J.object_action(x, y))
			if J.S.map != mapa:   # una puerta que no se llama puerta: de vuelta
				entra(mapa)
			for v in VISTO:
				if T.has(v[1]):
					chk(v[0] == T[v[1]], "%s: «%s» abierto desde %s (%s)" % [mapa, v[1], v[0], o])
					if v[0] == T[v[1]] and not hechos.has(T[v[1]]):
						hechos.append(T[v[1]])
				for l in v[2]:
					if str(l).begins_with("Ordenar "):
						var bueno: bool = ("casa" in l and mapa == "home") or ("nave" in l and mapa == "nave") or ("local" in l and J.D.ORDEN_P.has(mapa))
						chk(bueno, "%s: el mueble %s ofrece «%s»" % [mapa, o, l])
	return hechos

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-orden-sala.json"
	Juego.AJUSTES = "user://prueba-orden-sala-ajustes.json"
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
	S.ch = maxi(int(S.ch), 6)
	S.banco = 50000
	S.money = 20000
	S.protect = false
	S.flags.letter = true
	if not S.nave.has("ma"):
		S.nave.ma = []
	if S.get("aso") is Dictionary:
		S.aso.pres = true
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D: Dictionary = J.D
	# 1 · ordenar una sala estando en otra no abre nada
	entra("nave-d")
	VISTO.clear()
	var ok := corre(func(): await J.ordenar("nave"))
	chk(ok and not VISTO.any(func(v): return titulos().has(v[1])), "ordenar la nave desde el despacho no abre el menú (%s %s)" % [ok, VISTO])
	# 2 · el escritorio del despacho ya no ofrece ordenar la nave
	J.S.map = "nave-d"
	chk(not J._filas_escritorio().any(func(r): return r.label == "Ordenar la nave"), "el escritorio del despacho, sin «Ordenar la nave»")
	# 3 · cada mapa ordenable y sus salas de al lado: A en cada mueble
	var mapas := []
	for mk in D.ORDEN_P:
		if not mapas.has(mk):
			mapas.append(mk)
		for p in D.PUERTAS_INT.get(mk, []):
			if not mapas.has(p.to):
				mapas.append(p.to)
	for mk in D.PUERTAS_INT:
		if not mapas.has(mk):
			mapas.append(mk)
	for mk in mapas:
		var h := prueba_mapa(mk)
		if D.ORDEN_P.has(mk):
			chk(h.has(mk), "%s: un mueble de dentro lo ordena (%s)" % [mk, h])
		chk(h.all(func(q): return q == mk), "%s: solo se ordena a sí mismo (%s)" % [mk, h])
	print("orden_sala: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)
