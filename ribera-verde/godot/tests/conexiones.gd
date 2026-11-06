# Ribera Verde (Godot) — de un mapa de fuera a otro se llega por su lado (lo pidió el usuario: «si yo voy del camino de izquierda a
# derecha, no puedo aparecer a la derecha del pueblo, tendré que aparecer a la izquierda. Eso tiene que estar bien conectado»; con
# Datos.CAL): cada salida por el borde de un mapa de fuera (pueblos, Bilbao, carreteras, la comarcal…) lleva al borde de enfrente
# del otro —por la derecha, a su izquierda; por la izquierda, a su derecha; por arriba, abajo; por abajo, arriba; si el otro tiene
# la entrada arriba o abajo, por ese borde— y la vuelta, por donde se llegó. Las carreteras van de lado a lado: se entra en ellas por arriba o por abajo en la punta de ese pueblo.
#   $GODOT --headless --path godot --script res://tests/conexiones.gd   → «conexiones: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var D
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func fuera(k: String) -> bool:
	return D.ZONAS.has(k) or k.begins_with("carr-")

# por qué borde sale (o "" si no está en un borde)
func borde(m: Dictionary, x: int, y: int) -> String:
	if x == 0:
		return "left"
	if x == int(m.w) - 1:
		return "right"
	if y == 0:
		return "up"
	if y == int(m.h) - 1:
		return "down"
	return ""

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-conexiones.json"
	Juego.AJUSTES = "user://prueba-conexiones-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "caja-dentro":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	D = J.D
	J.S = e.S
	J.S.ch = 8
	J.mode = "world"
	# todo abierto: las carreteras por capítulo, el paso del muelle
	var mapas := []
	for k in J.MAPS:
		if fuera(k):
			mapas.append(k)
	for k in mapas:
		J.enter_map(k, int(J.MAPS[k].w) / 2, int(J.MAPS[k].h) / 2, "down")
	var vistas := 0
	var ida := {}
	for k in mapas:
		var m: Dictionary = J.MAPS[k]
		for t in ["exits", "doors"]:
			for kk in m.get(t, {}):
				var d = m[t][kk]
				if not (d is Dictionary) or not fuera(String(d.get("to", ""))) or not J.MAPS.has(String(d.to)):
					continue
				var p: PackedStringArray = String(kk).split(",")
				var sx := int(p[0])
				var sy := int(p[1])
				var b := borde(m, sx, sy)
				if b == "":
					continue
				var to: String = d.to
				var dm: Dictionary = J.MAPS[to]
				var ax := int(d.x)
				var ay := int(d.y)
				var w := int(dm.w)
				var h := int(dm.h)
				vistas += 1
				ida["%s>%s" % [k, to]] = b
				var ok := true
				if to.begins_with("carr-"):   # en la carretera, a una de sus dos puntas
					ok = ax <= 2 or ax >= w - 3
					if b == "right":
						ok = ax <= 2
					elif b == "left":
						ok = ax >= w - 3
				elif b == "right":   # a su izquierda; o, si la entrada es por arriba o por abajo, por ese borde (un giro, no un salto)
					ok = ax <= 2 or ay <= 2 or ay >= h - 3
				elif b == "left":
					ok = ax >= w - 3 or ay <= 2 or ay >= h - 3
				elif b == "up":
					ok = ay >= h - 3
				elif b == "down":
					ok = ay <= 2
				chk(ok, "%s (%d, %d) sale por %s y llega a %s (%d, %d) de %d × %d" % [k, sx, sy, b, to, ax, ay, w, h])
	# y la vuelta, por el lado contrario (de lado a lado)
	const OP := {"left": "right", "right": "left", "up": "down", "down": "up"}
	for q in ida:
		var ab: PackedStringArray = String(q).split(">")
		var vuelta: String = ab[1] + ">" + ab[0]
		if not ida.has(vuelta):
			continue
		var b1: String = ida[q]
		var b2: String = ida[vuelta]
		if b1 in ["left", "right"] and b2 in ["left", "right"]:
			chk(b2 == OP[b1], "%s sale por %s y la vuelta, por %s" % [q, b1, b2])
	chk(vistas >= 40, "salidas de borde vistas: %d" % vistas)
	# las carreteras: el pueblo de la izquierda no sale por su izquierda ni el de la derecha por su derecha
	for c in D.CARRETERAS.rutas:
		var r: Dictionary = D.CARRETERAS.rutas[c]
		for q in D.CARRETERAS.puertas[r.a]:
			if q[2] == c:
				chk(String(q[5]) != "left", "%s: %s, a la izquierda, sale por su izquierda" % [c, r.a])
		for q in D.CARRETERAS.puertas[r.b]:
			if q[2] == c:
				chk(String(q[5]) != "right", "%s: %s, a la derecha, sale por su derecha" % [c, r.b])
	for x in fallos:
		print("  FALLO " + x)
	print("conexiones: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
