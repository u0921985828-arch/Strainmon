# Landrace Hunters (Godot) — las vallas conectan en x y en y (lo pidió el usuario: «Las vallas tienen que ser tanto en dirección
# izquierda y derecha como alante a atrás, como x, y, porque si no no conectan entre ellas cuando se cambia la dirección»), con
# Datos.CAL: en todos los mapas, cada valla de madera (fence) y cada barandilla (baranda) sale con la pieza de sus vecinas de la
# misma clase (tools/sprites/a-mano/vallas.py, pinta.gd mascara_valla), y dos vecinas se tocan en su borde común: la de arriba llega
# a su fila de abajo y la de abajo a su fila de arriba; las de los lados, a su columna. Sin CAL, el sprite de siempre.
#   $GODOT --headless --path godot --script res://tests/vallas.gd   → «vallas: N comprobaciones, 0 fallos»
#   con -- --pintar <dir>: vallas-<mapa>.png, las vallas de cada mapa con vertical montadas con sus piezas
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Atlas = preload("res://src/atlas.gd")
const Pintor = preload("res://src/pinta.gd")
const Juego = preload("res://src/juego.gd")

# 4. las vallas encima de lo que acotan (lo pidió el usuario: «tiene que estar acotado encima de las baldosas donde termina la
# acotación, no en las siguientes»): con CAL, las de los corrales y cercados, en su suelo; las sueltas, como estaban
const CERCADOS := {"valdehierro": ["dirt", 47], "mendialde": ["tallgrass", 29], "errotabarri": ["tallgrass", 22], "astilleros": ["dirt", 36]}   # Valdehierro, sin las 5 que abre el aparcamiento (APARC_OBRA) ni la que corta la vía del apeadero
const SUELTAS := ["town", "carr-valle", "carr-molino", "carr-acantilado", "puerto"]

var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func pieza(o: String, m: int):
	return Atlas.frame_de("vallas", "%s-%d" % [o, m], "unica", 0, {"i": 0})

# ¿hay algo pintado en la columna x (o la fila y) del sprite?
func col(im: Image, x: int) -> bool:
	for y in im.get_height():
		if im.get_pixel(x, y).a > 0:
			return true
	return false

func fila(im: Image, y: int) -> bool:
	for x in im.get_width():
		if im.get_pixel(x, y).a > 0:
			return true
	return false

func vallas_de(m: Dictionary) -> Array:
	var r := []
	for y in m.o.size():
		for x in m.o[y].size():
			if m.o[y][x] == "fence":
				r.append(Vector2i(x, y))
	return r

func dentro(D: Dictionary) -> void:
	Juego.GUARDADO = "user://prueba-vallas.json"
	Juego.AJUSTES = "user://prueba-vallas-ajustes.json"
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var J = Juego.new()
	root.add_child(J)
	for x in O:
		if x.k == "casa-extr":
			J.S = Datos.enteros(x).S
	J.oraculo = true
	J.S.ch = 9
	for k in CERCADOS:
		J.enter_map(k, 1, 1)
		var m: Dictionary = J.MAPS[k]
		var con: Array = m.g.duplicate(true)
		Datos.CAL = false   # el suelo sin las vallas encima (lo demás del mapa, montado con CAL)
		J.vallas_dentro(k)
		var sin: Array = m.g.duplicate(true)
		Datos.CAL = true
		J.vallas_dentro(k)
		chk(m.g == con, "%s: al volver a ponerlas, igual" % k)
		var vs := vallas_de(m)
		var en := vs.filter(func(c): return m.g[c.y][c.x] == CERCADOS[k][0])
		chk(vs.size() == CERCADOS[k][1] and en.size() == vs.size(), "%s: las %d vallas encima de %s (%d)" % [k, vs.size(), CERCADOS[k][0], en.size()])
		var fuera := 0   # solo cambian las casillas de valla
		for y in m.g.size():
			for x in m.g[y].size():
				if m.o[y][x] != "fence" and con[y][x] != sin[y][x]:
					fuera += 1
		chk(fuera == 0, "%s: fuera de las vallas, el suelo de siempre (%d cambiadas)" % [k, fuera])
		var cambia := vs.filter(func(c): return sin[c.y][c.x] != CERCADOS[k][0]).size()
		chk(k == "astilleros" or cambia > 0, "%s: había vallas fuera de lo acotado: %d" % [k, cambia])
		J.enter_map(k, 1, 1)
		chk(m.g == con, "%s: al volver a entrar, igual" % k)
	for k in SUELTAS:
		J.enter_map(k, 1, 1)
		chk(not J._val0.has(k), "%s: las vallas sueltas, en su sitio de siempre" % k)
	Datos.CAL = true

func _corre() -> void:
	Datos.CAL = true
	Atlas.carga()
	var D: Dictionary = Datos.carga()
	var dir := arg("--pintar")
	# 0. el seto de la calle, con el de PixelLab de la huerta (lo pidió el usuario: «el seto… hicimos otro ya»): cada seto de los
	# mapas sale con su pieza, el tramo alterno y el remate redondo en las puntas
	var vs := 0
	for k in D.MAPS:
		var mo: Array = D.MAPS[k].o
		for y in mo.size():
			for x in mo[y].size():
				if mo[y][x] != "seto":
					continue
				vs += 1
				var p: String = Pintor.seto_pieza(mo, x, y)
				var w: bool = x > 0 and mo[y][x - 1] == "seto"
				var e: bool = x + 1 < mo[y].size() and mo[y][x + 1] == "seto"
				var bien: bool = (p == "setoHi") == (e and not w) and (p == "setoHd") == (w and not e)
				chk(bien and Atlas.frame_de("seto-huerta", p, "unica", 0, {"i": 0}) != null, "%s (%d, %d): el seto con %s" % [k, x, y, p])
	chk(vs > 200, "setos en los mapas: %d" % vs)
	# 1. las 32 piezas, de 16 × 16, cada una tocando el borde de cada lado que conecta
	for o in Pintor.VALLAS:
		for m in 16:
			var f = pieza(o, m)
			chk(f != null, "%s-%d en el atlas" % [o, m])
			if f == null:
				continue
			var im: Image = f.c
			chk(im.get_width() == 16 and im.get_height() == 16, "%s-%d de 16 × 16" % [o, m])
			chk(not (m & 1) or fila(im, 0), "%s-%d: llega arriba" % [o, m])
			chk(not (m & 4) or fila(im, 15), "%s-%d: llega abajo" % [o, m])
			chk(not (m & 2) or col(im, 15), "%s-%d: llega a la derecha" % [o, m])
			chk(not (m & 8) or col(im, 0), "%s-%d: llega a la izquierda" % [o, m])
		# lo de delante y detrás, una franja en medio (no el sprite de lado)
		var v = pieza(o, 5)
		if v != null:
			chk(not col(v.c, 0) and not col(v.c, 15), "%s-5 (arriba y abajo): sin los lados" % o)
	# 2. en todos los mapas: la pieza de cada valla, por sus vecinas; y las vecinas se tocan
	var verticales := 0
	var con_vertical := []
	for k in D.MAPS:
		var mo: Array = D.MAPS[k].o
		for y in mo.size():
			for x in mo[y].size():
				var o = mo[y][x]
				if not o in Pintor.VALLAS:
					continue
				var m: int = Pintor.mascara_valla(mo, o, x, y)
				var q := 0
				q |= 1 if y > 0 and mo[y - 1][x] == o else 0
				q |= 2 if x + 1 < mo[y].size() and mo[y][x + 1] == o else 0
				q |= 4 if y + 1 < mo.size() and mo[y + 1][x] == o else 0
				q |= 8 if x > 0 and mo[y][x - 1] == o else 0
				chk(m == q, "%s (%d, %d): la pieza %d (es la %d)" % [k, x, y, m, q])
				if m & 4:
					verticales += 1
					if not k in con_vertical:
						con_vertical.append(k)
					var a = pieza(o, m)
					var b = pieza(o, Pintor.mascara_valla(mo, o, x, y + 1))
					if a != null and b != null:   # la de arriba y la de abajo, en la misma columna del borde
						var junta := false
						for c in 16:
							junta = junta or (a.c.get_pixel(c, 15).a > 0 and b.c.get_pixel(c, 0).a > 0)
						chk(junta, "%s (%d, %d) → (%d, %d): se tocan" % [k, x, y, x, y + 1])
	chk(verticales > 20, "vallas de delante a atrás en los mapas: %d" % verticales)
	for k in ["astilleros", "valdehierro", "mendialde", "errotabarri"]:
		chk(k in con_vertical, "%s: con valla en vertical" % k)
	# 3. pintadas: las de los mapas con vertical, montadas pieza a pieza (para mirarlas)
	if dir != "":
		for k in con_vertical:
			var mo: Array = D.MAPS[k].o
			var big := Image.create(mo[0].size() * 16, mo.size() * 16, false, Image.FORMAT_RGBA8)
			big.fill(Color(0.35, 0.55, 0.27))
			for y in mo.size():
				for x in mo[y].size():
					if mo[y][x] in Pintor.VALLAS:
						var f = pieza(mo[y][x], Pintor.mascara_valla(mo, mo[y][x], x, y))
						if f != null:
							var im: Image = f.c
							im.convert(Image.FORMAT_RGBA8)
							big.blend_rect(im, Rect2i(0, 0, 16, 16), Vector2i(x * 16, y * 16))
			big.save_png(dir.path_join("vallas-%s.png" % k))
	dentro(D)
	print("vallas: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
