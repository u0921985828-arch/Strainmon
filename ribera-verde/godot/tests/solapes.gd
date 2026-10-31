# Landrace Hunters (Godot) — ningún mueble se pinta encima de otro (lo pidió el usuario: «No quiero que ningún objeto de pared o
# suelo se superponga sobre otro. Queda mal y descuidado»), con Datos.CAL: en cada interior (los mapas que no son de calle), con lo
# que el pintor pondría (pinta.gd, `mide`: el sprite de verdad, con sprite_local, e-, d- y su ancla), ningún píxel opaco de un objeto
# cae encima de un píxel opaco de otro de otra casilla. Lo que no cuenta, porque es un solo mueble o va así a propósito: los árboles y el
# monte de fuera (sus copas se cruzan), las piezas seguidas de un mismo mueble en una fila (la barra, el banco largo, las butacas) y
# un asiento pegado a su mesa (la silla metida bajo la mesa, el sofá detrás de la mesita). Las carpas del piso (_carpa_mapa), también.
#   $GODOT --headless --path godot --script res://tests/solapes.gd   → «solapes: N comprobaciones, 0 fallos»
#   -- --lista: todos los solapes, mapa por mapa
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# los solapes de un mapa, con lo que el juego mira al ordenar (calle.gd cajas_obj y solapes_de)
func solapes(mid: String) -> Array:
	return J.solapes_de(J.cajas_obj(mid, J.MAPS[mid].o))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-solapes.json"
	Juego.AJUSTES = "user://prueba-solapes-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.oraculo = true
	J.S.ch = 9
	var ns: Dictionary = J.new_state()
	for k in ns:   # lo que la partida de las pantallas (la 1.37) aún no traía
		if not J.S.has(k):
			J.S[k] = ns[k]
	if not (J.S.get("loc") is Dictionary):
		J.S.loc = {}
	for k in J.D.NEGOCIO.k:   # los locales con todas sus mejoras compradas: lo que añaden, tampoco encima de nada
		if not (J.S.loc.get(k) is Dictionary):
			J.S.loc[k] = {}
		J.S.loc[k].mj = J.D.NEGOCIO.k[k].mj.size()
	if not (J.S.get("mar") is Dictionary):
		J.S.mar = {}
	if J.S.get("aso") is Dictionary and J.S.aso.get("al") is Dictionary and not J.S.aso.al.has("buds"):
		J.S.aso.erase("al")   # el almacén del club de la partida vieja, de antes de la 1.45
	var lista: bool = "--lista" in OS.get_cmdline_user_args()
	var solo := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mapa="):
			solo = a.substr(7)
	var mapas := 0
	var total := 0
	for mid in J.MAPS.keys():
		if J.D.ZONAS.has(mid) or mid.begins_with("carr-") or (solo != "" and mid != solo):
			continue
		J.enter_map(mid, 1, 1)
		mapas += 1
		var s := solapes(mid)
		total += s.size()
		if lista and s.size():
			print("%s (%d): %s" % [mid, s.size(), s])
		chk(s.is_empty(), "%s: %d solapes: %s" % [mid, s.size(), s.slice(0, 4)])
	if solo == "" or solo == "home":   # el piso con todas las máquinas de las extracciones montadas, en su fila de abajo
		for E in J.D.MUEBLE_EXTR.values():
			J.S.items[E.item] = 1
		J.enter_map("home", 1, 1)
		var s := solapes("home")
		total += s.size()
		if lista and s.size():
			print("home con las máquinas (%d): %s" % [s.size(), s])
		chk(s.is_empty(), "home con las máquinas: %d solapes: %s" % [s.size(), s.slice(0, 4)])
	if solo == "" or solo == "home":   # una partida de antes con la carpa grande, donde la dejó la versión anterior: al cargar, nada se mueve
		var t0 = J.S.carpas[0].t
		for q in [["m120", {"carpa0": [5, 2], "lab": [6, 3]}], ["g150", {"carpa0": [12, 2], "lab": [6, 4]}]]:
			J.S.carpas[0].t = q[0]
			J.S.coloca = {"home": q[1].duplicate(true)}
			J.MAPS["home"].erase("opos")
			J.enter_map("home", 1, 4)
			chk(J.S.coloca.home == q[1] and J.MAPS["home"].opos.carpa0 == q[1].carpa0, "home con la carpa %s: %s" % [q[0], J.S.coloca])
		J.S.carpas[0].t = t0
	chk(mapas >= 40 or solo != "", "interiores revisados: %d" % mapas)
	print("solapes: %d comprobaciones, %d fallos (%d solapes en %d mapas)" % [n, fallos.size(), total, mapas])
	for f in fallos:
		print("  ✗ " + f)
	quit(1 if fallos.size() else 0)
