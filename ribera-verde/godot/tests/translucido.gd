# Ribera Verde (Godot) — lo que tapa al protagonista, translúcido (pinta.gd tapa_pj, _con_alfa; lo pidió el usuario: «tabiques y
# objetos translúcidos, como en los Sims, cuando tapan al personaje»; con CAL): lo alto que se pinta delante de él (su pie más abajo)
# y le pisa el cuerpo se pinta a TAPA_ALFA; detrás de él, al lado o lejos, entero; sin CAL, como antes.
#   $GODOT --headless --path godot --script res://tests/translucido.gd   → «translucido: N comprobaciones, 0 fallos»
#   con ventana y -- --sin-arranque --fotos <dir>: detrás de un árbol, con y sin CAL (tapa-cal.png, tapa-sin.png)
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

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-translucido.json"
	Juego.AJUSTES = "user://prueba-translucido-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	var fotos := arg("--fotos")
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.S = e.S.duplicate(true)
	J.queued.clear()
	J.pending.clear()
	var Pn = J.pintor
	# un mapa de la calle con algo alto (un árbol) con una casilla libre detrás, a la izquierda y delante
	var hallado := {}
	for mk in ["town", "mendialde", "puerto", "valdehierro"]:
		if not J.MAPS.has(mk) or hallado.size():
			continue
		J.enter_map(mk, 1, 1, "down")
		J.mode = "world"
		var m: Dictionary = J.MAPS[mk]
		for c in J.cajas_obj(mk, m.o):
			var im: Image = c.c
			if im.get_height() >= 40 and c.y >= 2 and c.y + 1 < int(m.h) and J.pisable(m, c.x, c.y - 1) and not m.o[c.y - 1][c.x] and J.pisable(m, c.x, c.y + 1) and not m.o[c.y + 1][c.x]:
				hallado = {"m": mk, "c": c}
				break
	chk(hallado.size() > 0, "un árbol con sitio detrás y delante: %s" % [hallado.get("m")])
	if hallado.size():
		var c: Dictionary = hallado.c
		Pn.cam = Vector2i.ZERO
		var P = J.P
		P.px = c.x * 16
		P.py = (c.y - 1) * 16
		chk(J.pintor.tapa_pj(c.c, c.px, c.py, c.y * 16), "detrás de %s (%d, %d): lo tapa, translúcido" % [c.o, c.x, c.y])
		P.py = (c.y + 1) * 16
		chk(not Pn.tapa_pj(c.c, c.px, c.py, c.y * 16), "delante: entero")
		P.py = c.y * 16
		chk(not Pn.tapa_pj(c.c, c.px, c.py, c.y * 16), "en su misma fila: entero (él va delante)")
		P.px = c.x * 16 + 64
		P.py = (c.y - 1) * 16
		chk(not Pn.tapa_pj(c.c, c.px, c.py, c.y * 16), "lejos: entero")
		P.px = c.x * 16
		Datos.CAL = false
		chk(not Pn.tapa_pj(c.c, c.px, c.py, c.y * 16), "sin CAL: entero")
		Datos.CAL = true
		J.SENT = {"x": c.x, "y": c.y - 1, "d": "sur"}
		chk(not Pn.tapa_pj(c.c, c.px, c.py, c.y * 16), "sentado: entero")
		J.SENT = null
		# una mesa con plantas: lo de encima (hasta TAPA_ALTO px) también tapa, aunque la mesa sola no llegue
		var P2 = J.P
		P2.px = 5 * 16
		P2.py = 4 * 16
		var mx: int = 5 * 16 - 8
		var my: int = 5 * 16 - 4
		chk(Pn.tapa_encima(mx, my, 32, 6 * 16) and not Pn.tapa_encima(mx + 96, my, 32, 6 * 16) and not Pn.tapa_encima(mx, my, 32, 3 * 16), "las plantas de una mesa: detrás, translúcidas; lejos o delante, no")
		Datos.CAL = false
		chk(not Pn.tapa_encima(mx, my, 32, 6 * 16), "sin CAL, tampoco")
		Datos.CAL = true
		# el alfa, solo mientras se pinta lo que tapa
		var vistos := []
		Pn._con_alfa(true, func(): vistos.append(Pn.alfa))
		Pn._con_alfa(false, func(): vistos.append(Pn.alfa))
		chk(vistos == [Pn.TAPA_ALFA, 1.0] and Pn.alfa == 1.0, "a TAPA_ALFA y vuelta a 1 (%s)" % [vistos])
		# la mesa y sus plantas, en una sola capa: lo de encima tapa del todo a lo de debajo y la capa entera va a TAPA_ALFA
		var ra := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		ra.fill(Color.RED)
		var ve := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		ve.fill(Color.GREEN)
		var capa: Image = Pn.capa_unica(10, 20, 16, 16, func():
			Pn._img(ra, 10, 20)
			Pn._img(ve, 12, 22)
			Pn._rect(20, 30, 2, 2, Color.BLUE))
		chk(capa.get_pixel(3, 3) == Color.GREEN and capa.get_pixel(0, 0) == Color.RED and capa.get_pixel(10, 10) == Color.BLUE and capa.get_pixel(15, 0).a == 0.0 and Pn._capt == null,
			"capa única: lo de encima opaco sobre la mesa, sin mezclarse (%s %s %s)" % [capa.get_pixel(3, 3), capa.get_pixel(0, 0), capa.get_pixel(10, 10)])
		var hoja: Image = Image.create(4, 4, false, Image.FORMAT_LA8)
		hoja.fill(Color(1, 1, 1, 1))
		var capa2: Image = Pn.capa_unica(0, 0, 8, 8, func(): Pn._img(hoja, -2, -2))
		chk(capa2.get_pixel(1, 1) == Color.WHITE and capa2.get_pixel(2, 2).a == 0.0, "otro formato y fuera de la caja: recortado")
		# una textura por capa y fotograma, y la que se cambia de tamaño sigue viva hasta el siguiente (si no, rectángulo blanco)
		Pn._capt_n = 0
		var t1: ImageTexture = Pn._capt_tex(ra)
		var t2: ImageTexture = Pn._capt_tex(ve)
		Pn._capt_n = 0
		Pn._capt_viejo.clear()
		Pn._capt_tex(ra)
		var t3: ImageTexture = Pn._capt_tex(ra)
		chk(t1 != t2 and t3 != t2 and t2 in Pn._capt_viejo and Vector2i(t3.get_size()) == Vector2i(8, 8), "capas del fotograma: sin reutilizar ni liberar a destiempo")
		# lo que va solo (árbol, farola), sin capa: su alfa de siempre
		chk(Pn._con_alfa_capa.get_argument_count() == 6, "capa solo para la mesa")
		if fotos != "":
			J.oraculo = false
			J.enter_map(hallado.m, c.x, c.y - 1, "up")
			J.mode = "world"
			for k in ["cal", "sin"]:
				Datos.CAL = k == "cal"
				for q in 3:
					await process_frame
					J.pintor.redibuja(0.0)
					for r in 4:
						await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(fotos.path_join("tapa-%s.png" % k))
			Datos.CAL = true
	print("translucido: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
