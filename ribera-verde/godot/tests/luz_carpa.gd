# Landrace Hunters (Godot) — la carpa por dentro con la luz de verdad (lo pidió el usuario: «el sprite de la carpa por dentro está
# iluminado completo y debería estar iluminado únicamente lo que ilumina la luz y lo que reflejan las paredes»), con Datos.CAL.
# Cada escena del oráculo, pintada sin CAL (como el HTML) y con CAL: fuera del haz y lejos de él, oscuro; dentro del haz, igual de
# claro que antes; cerca del haz, entre medias (el reflejo); apagada, toda a oscuras salvo la campana.
#   xvfb-run … --rendering-driver opengl3 --script res://tests/luz_carpa.gd -- --sin-arranque [--pintar <dir>]
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Vista = preload("res://src/vista.gd")
const Arte = preload("res://src/arte.gd")

var n_ok := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func ok(que: String, c: bool) -> void:
	if c:
		n_ok += 1
	else:
		fallos.append(que)

func estado(e: Dictionary) -> Dictionary:
	var S := Cultivo.nuevo_estado()
	S.carpas = [{"t": e.t, "foco": e.foco}]
	S.carpas[0].merge(e.get("x", {}).duplicate(true))
	S.macetas = e.macetas.duplicate()
	S.pots = []
	for p in e.pots:
		S.pots.append(p.duplicate(true) if p else null)
	S.custom = e.get("custom", {})
	S.gen = e.get("gen", {})
	return S

func pinta(e: Dictionary, cal: bool) -> Image:
	Datos.CAL = cal
	var sv := SubViewport.new()
	sv.size = Vector2i(240, 160)
	sv.transparent_bg = false
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var v = Vista.new()
	sv.add_child(v)
	v.pinta(estado(e), {"ci": 0, "sel": -9}, float(e.now))
	for n in 3:
		await RenderingServer.frame_post_draw
	var im := sv.get_texture().get_image()
	im.convert(Image.FORMAT_RGBA8)
	sv.queue_free()
	return im

func lum(c: Color) -> float:
	return .299 * c.r + .587 * c.g + .114 * c.b

# la media de luz de los píxeles de la lista
func media(im: Image, P: Array) -> float:
	var t := 0.0
	for p in P:
		t += lum(im.get_pixel(p.x, p.y))
	return t / maxf(1, P.size())

func _corre() -> void:
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/oraculo.json"))
	var dir := arg("--pintar")
	for e in O.escenas:
		if e.html == null:
			continue
		var S := estado(e)
		var g = Vista.geo(S, 0)
		if g.vc == null:
			continue
		var on := Cultivo.plantas_vivas(S, 0)
		var a: Image = await pinta(e, false)
		var b: Image = await pinta(e, true)
		if dir != "":
			var j := Image.create(484, 160, false, Image.FORMAT_RGBA8)
			j.blit_rect(a, Rect2i(0, 0, 240, 160), Vector2i.ZERO)
			j.blit_rect(b, Rect2i(0, 0, 240, 160), Vector2i(244, 0))
			j.resize(484 * 3, 480, Image.INTERPOLATE_NEAREST)
			j.save_png(dir.path_join("luz-%s.png" % e.k))
		# la máscara del haz: dentro (alfa), lejos (a más de 12 px de cualquier píxel del haz) y la pared (lo que no es negro sin CAL)
		var M = Arte.luz(g.c.t, g.vc) if on else null
		var dentro := []
		var lejos := []
		var todo := []
		for y in range(0, 160, 2):
			for x in range(0, 240, 2):
				if lum(a.get_pixel(x, y)) < .04:
					continue
				todo.append(Vector2i(x, y))
				if M == null:
					continue
				if M.get_pixel(x, y).a8:
					dentro.append(Vector2i(x, y))
					continue
				var cerca := false
				for dy in range(-12, 13, 3):
					for dx in range(-12, 13, 3):
						var X := x + dx
						var Y := y + dy
						if X >= 0 and X < 240 and Y >= 0 and Y < 160 and M.get_pixel(X, Y).a8:
							cerca = true
				if not cerca:
					lejos.append(Vector2i(x, y))
		if on:
			ok("%s: hay haz y sitio a oscuras" % e.k, dentro.size() > 50 and lejos.size() > 50)
			ok("%s: lejos del haz, oscuro (≤ 55 %% de antes)" % e.k, media(b, lejos) <= .55 * media(a, lejos))
			ok("%s: dentro del haz, igual de claro (≥ 92 %% de antes)" % e.k, media(b, dentro) >= .92 * media(a, dentro))
			ok("%s: el haz destaca (≥ 1,8 × lo de lejos)" % e.k, media(b, dentro) >= 1.8 * media(b, lejos))
		else:
			ok("%s: apagada, a oscuras (≤ 25 %% de antes)" % e.k, media(b, todo) <= .25 * media(a, todo))
	# sin CAL, como el HTML: la pared tal cual (la prueba C2 de prueba.gd lo compara píxel a píxel)
	Datos.CAL = true
	for f in fallos:
		print("FALLO  ", f)
	print("luz_carpa: %d comprobaciones, %d fallos" % [n_ok + fallos.size(), fallos.size()])
	quit(1 if fallos.size() else 0)
