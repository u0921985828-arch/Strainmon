# Landrace Hunters (Godot) — el suelo pintado una vez por mapa (pinta.gd `suelo`, 0.69.1; lo pidió el usuario: «optimizar los FPS
# para que vaya más fluido», en la web): en todos los mapas, con CAL, de día y de noche, la pantalla con el suelo guardado es la misma,
# píxel a píxel, que pintándolo casilla a casilla cada fotograma (SUELO_ON = false), también en la casilla que se pisa y al andar.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1560x720 --script res://tests/suelo_cache.gd
#     -- --sin-arranque   → «suelo_cache: N comprobaciones, 0 fallos»
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

func foto(t: float) -> Image:
	for q in 2:
		J.pintor.redibuja(t)
		await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func distintos(a: Image, b: Image) -> int:
	var c := 0
	for y in range(0, a.get_height(), 1):
		for x in range(0, a.get_width(), 1):
			if not a.get_pixel(x, y).is_equal_approx(b.get_pixel(x, y)):
				c += 1
	return c

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-suelo.json"
	Juego.AJUSTES = "user://prueba-suelo-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.oraculo = true   # sin _process: cada fotograma lo pinta la prueba, con el mismo reloj
	J.pintor.ambiente_on = false
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	for x in O:
		if x.k == "nave2":
			J.S = Datos.enteros(x).S.duplicate(true)
	var ns: Dictionary = J.new_state()
	for k in ns:
		if not J.S.has(k):
			J.S[k] = ns[k]
	J.migrate()
	J.queued.clear()
	J.pending.clear()
	J.ajusta()
	var mapas: Array = J.MAPS.keys()
	mapas.sort()
	for mk in mapas:
		var m: Dictionary = J.MAPS[mk]
		var px := clampi(int(m.w) / 2, 0, int(m.w) - 1)
		var py := clampi(int(m.h) / 2, 0, int(m.h) - 1)
		J.enter_map(mk, px, py, "down")
		J.mode = "world"
		J.ents = J.ents.filter(func(e): return not e.get("pat"))   # las patrullas se mueven solas
		for hora in [600, 1380]:
			J.S.min = hora
			var t: float = 123456.0 + hora
			J.pintor.SUELO_ON = true
			J.pintor._suelo_k = ""   # el suelo, pintado 3,1 s antes: lo que se mueve tiene que salir en su fotograma, no en el guardado
			await foto(t - 3100)
			var a: Image = await foto(t)
			var con: bool = J.pintor.suelo.visible
			J.pintor.SUELO_ON = false
			var b: Image = await foto(t)
			chk(con, "%s: sin el suelo guardado" % mk)
			var d := distintos(a, b)
			chk(d == 0, "%s a las %d: %d píxeles distintos" % [mk, hora / 60, d])
			if d and OS.get_cmdline_user_args().has("--fotos"):
				a.save_png("user://suelo-%s-con.png" % mk)
				b.save_png("user://suelo-%s-sin.png" % mk)
	J.pintor.SUELO_ON = true
	for f in fallos:
		print("FALLO ", f)
	print("suelo_cache: %d comprobaciones, %d fallos (%d mapas)" % [n, fallos.size(), mapas.size()])
	quit(1 if fallos.size() else 0)
