# Ribera Verde (Godot) — 1.55 (lo pidió el usuario: «la puerta del sótano está inaccesible porque hay una carpa delante», «poder
# ordenar las carpas al gusto» y «un tubo de extracción de cada carpa hacia una de las ventanas»). Con CAL: las tres carpas son piezas
# de ORDENAR LA CASA en la fila de la pared; la C, de serie junto a la cama, deja libre la puerta del pasillo; se mueven y la de 2
# casillas ocupa 2; no se pueden dejar delante de la puerta; el tubo sale con el extractor puesto. Con --pintar <dir>, la casa.
#   $GODOT --headless --path godot --script res://tests/carpas_casa.gd   → «carpas_casa: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func monta() -> void:
	J.MAPS.home.carpasK = null
	J.montar_casa()

func celdas(h: Dictionary, o: String) -> Array:
	var l := []
	for y in int(h.h):
		for x in int(h.w):
			if h.o[y][x] == o:
				l.append([x, y])
	return l

func _corre() -> void:
	var dir := ""
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--pintar" and i + 1 < a.size():
			dir = a[i + 1]
	Juego.GUARDADO = "user://prueba-carpas-casa.json"
	Juego.AJUSTES = "user://prueba-carpas-casa-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.S = e.S
	var S = J.S
	S.flags.letter = true
	S.coloca = {}
	S.carpas = [{"t": "m100", "foco": "cfl", "filtro": true}, {"t": "m120", "foco": "cfl", "filtro": true}, {"t": "g150", "foco": "cfl", "filtro": true}]
	S.map = "home"
	J.enter_map("home", 5, 4, "down")
	J.build_ents()
	J.mode = "world"
	var h: Dictionary = J.MAPS.home
	monta()
	var dl: Array = J.delante_puertas("home")
	chk(dl.size() == 1 and h.o[dl[0][1]][dl[0][0]] == null, "delante de la puerta del pasillo, libre: %s" % [dl])
	var an: Dictionary = J.andable(h, h.o)
	chk(an.has("%d,%d" % [dl[0][0], dl[0][1]]), "se llega a la puerta del pasillo")
	chk(h.carpas.size() == 3, "las tres carpas en el mapa: %s" % [h.carpas])
	var C = h.carpas.filter(func(t): return t.ci == 2)
	chk(C.size() == 1 and C[0].x0 == 1 and C[0].x1 == 2 and C[0].y == 2, "la C, junto a la cama (1-2, 2): %s" % [C])
	chk(celdas(h, "carpa").size() == 5, "1 + 2 + 2 casillas de carpa: %s" % [celdas(h, "carpa")])
	for k in ["planta", "nevera"]:
		var p: Array = J.pos_pieza("home", k)
		chk(h.o[p[1]][p[0]] in ["plantDeco", "fridge"], "%s, recolocada en (%d, %d)" % [k, p[0], p[1]])
	# ordenar: la carpa B a otro sitio de la pared; delante de la puerta, no
	chk(J.cabe_pieza("home", "carpa1", 3, 2, null, false) != "", "la carpa B no cabe delante de la puerta (%s)" % J.cabe_pieza("home", "carpa1", 3, 2, null, false))
	chk(J.cabe_pieza("home", "carpa1", 10, 4, null, false) != "", "ni fuera de la fila de la pared")
	var libre := -1
	for x in range(17, -1, -1):
		if J.cabe_pieza("home", "carpa0", x, 2, null, false) == "" and x != 8:
			libre = x
			break
	chk(libre >= 0, "hay otro sitio en la pared para la carpa A")
	if libre >= 0:
		S.coloca.home = {"carpa0": [libre, 2]}
		J.rehace_orden("home")
		var A_ = h.carpas.filter(func(t): return t.ci == 0)
		chk(A_.size() == 1 and A_[0].x0 == libre, "la carpa A, movida a %d: %s" % [libre, A_])
		chk(h.o[2][libre] == "carpa" and h.o[2][8] != "carpa", "el mapa la sigue")
		chk(J.sitio(0).x == libre, "sitio(0) la sigue")
	# sin CAL, como antes
	Datos.CAL = false
	monta()
	var C0 = h.carpas.filter(func(t): return t.ci == 2)
	chk(C0.size() == 1 and C0[0].x0 == 2, "sin CAL, la C en su sitio de siempre (2)")
	Datos.CAL = true
	S.coloca = {}
	monta()
	if dir != "":
		J.P.x = 5; J.P.y = 4
		for q in 3:
			await process_frame
			J.pintor.redibuja(J.M.reloj)
			for r in 3:
				await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(dir.path_join("carpas-casa.png"))
	print("carpas_casa: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)
