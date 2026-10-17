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
	# 1.55.3: el tubo de cada carpa a su ventana, sin tramos de techo encima de otro y sin una ventana detrás de su carpa
	var vt: Array = J.pintor.ventanas_tubos(h)
	chk(vt.size() == 3, "tres tubos: %s" % [vt.map(func(q): return [q[1], q[2]])])
	var vs := {}
	for q in vt:
		vs[q[2]] = true
		chk(q[2] < q[0].x0 * 16 - 4 or q[2] > (q[0].x1 + 1) * 16 + 4, "la ventana de la carpa %d (%d), no detrás de ella" % [q[0].ci, q[2]])
		for q2 in vt:
			if q2 != q:
				chk(maxi(mini(q[1], q[2]), mini(q2[1], q2[2])) >= mini(maxi(q[1], q[2]), maxi(q2[1], q2[2])), "los tubos de techo de %d y %d no se pisan" % [q[0].ci, q2[0].ci])
	chk(vs.size() == 3, "una ventana por carpa: %s" % [vs.keys()])
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
	# 1.55.1: todos los muebles de la casa se ordenan; delante de la puerta y la escalera del camarote, nada
	S.coloca = {}
	monta()
	var ks: Array = J.piezas_ya("home").map(func(P_): return P_.k)
	for k in ["cama", "pc", "lab", "nevera", "mesa", "planta", "trim", "carpa0", "carpa1", "carpa2"]:
		chk(k in ks, "se ordena: %s" % k)
	var CM: Dictionary = J.D.CAMAROTE
	var prohib := [[3, 2], [int(CM.x), int(CM.y)], [int(CM.vuelta[0]), int(CM.vuelta[1])]]
	for P_ in J.piezas_ya("home"):
		for c in prohib:
			for o in P_.o:
				var x: int = c[0] - int(o[0])
				var y: int = c[1] - int(o[1])
				chk(J.cabe_pieza("home", P_.k, x, y, null, false) != "", "%s no se puede dejar tapando (%d, %d)" % [P_.k, c[0], c[1]])
	for c in prohib:
		chk(h.o[c[1]][c[0]] == null, "(%d, %d), libre" % [c[0], c[1]])
	var hueco := []
	for x in range(1, 17):
		if J.cabe_pieza("home", "cama", x, 4, null, false) == "":
			hueco = [x, 4]
			break
	chk(hueco.size() == 2, "la cama cabe en otro sitio")
	if hueco.size() == 2:
		S.coloca.home = {"cama": hueco}
		J.rehace_orden("home")
		chk(h.o[4][hueco[0]] == "bedT" and h.o[5][hueco[0]] == "bedB" and h.o[2][0] != "bedT", "la cama, movida a %s" % [hueco])
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
		# 1.57 (lo pidió el usuario: «en las curvas o giros del tubo no se deben cortar»): por el centro del tubo, del codo de la
		# carpa al de la ventana, ni una raya del canto; y la esquina de fuera de cada codo, redonda (sin tubo)
		var im: Image = J.sv.get_texture().get_image()
		var cam: Vector2i = J.pintor.cam
		var canto := Color("#2a2a34")
		var tubos: Array = J.pintor.ventanas_tubos(h)
		var seguido := tubos.size() > 0
		var redondo := true
		var cuerpo := [Color("#e4e8ee"), Color("#b4b8c0"), Color("#8a8e98"), Color("#9aa0a8")]
		var es_tubo := func(x: int, y: int) -> bool:
			if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
				return false
			var c: Color = im.get_pixel(x, y)
			for k in cuerpo:
				if c.is_equal_approx(k):
					return true
			return false
		for q in tubos:
			var xl: int = mini(q[1], q[2]) - cam.x
			var xr: int = maxi(q[1], q[2]) - cam.x
			var yc: int = -cam.y
			# por dentro del tubo (sin pasar por el canto), del medio del techo a las dos bajadas, doblando los codos (con dos tramos que
			# se pisan, el canto de la bajada lo corta antes de llegar)
			var visto := {}
			var pila := [Vector2i((xl + xr) / 2, yc + 2)]
			while pila.size():
				var p: Vector2i = pila.pop_back()
				if visto.has(p) or not es_tubo.call(p.x, p.y) or p.y > yc + 12:
					continue
				visto[p] = true
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					pila.append(p + d)
			var baja := func(x: int) -> bool:
				for y in range(yc + 3, yc + 13):
					for dx in [-1, 0, 1]:
						if visto.has(Vector2i(x + dx, y)):
							return true
				return false
			seguido = seguido and baja.call(xl) and baja.call(xr)
			for c in [im.get_pixel(xl - 2, yc), im.get_pixel(xr + 2, yc)]:
				redondo = redondo and not c.is_equal_approx(canto) and not es_tubo.call(-1, -1) and not cuerpo.has(c)
		chk(seguido, "los tubos (%d), seguidos por los codos, sin cortes" % tubos.size())
		chk(redondo, "los codos, redondos por fuera")
	print("carpas_casa: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)
