# Ribera Verde (Godot) — 1.38: la escena de cada extracción encima de su barra (escena_extr.gd). Sobre la escena tiro-lavadora de
# las pantallas, cada tipo y cada paso con TIRO.esc: tiene que pintarse (distinto de la barra sola) y moverse (distinto a otra hora).
# Deja ext-<tipo>-<paso>-<a|b>.png en --salida.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --script res://tests/extracciones.gd --
#     --sin-arranque --salida <dir>
#   → «extracciones: N escenas, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func foto(e: Dictionary, T, now: float) -> Image:
	J.TIRO = T
	J.pintor.redibuja(now)
	for n in 3:
		await RenderingServer.frame_post_draw
	var im: Image = J.sv.get_texture().get_image()
	im.convert(Image.FORMAT_RGBA8)
	return im

func _corre() -> void:
	var dir := arg("--salida")
	Juego.GUARDADO = "user://prueba-extr.json"
	Juego.AJUSTES = "user://prueba-extr-ajustes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.AJUSTES))
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "tiro-lavadora":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.set_process(false)
	J.pintor.ambiente_on = false
	J.SW = int(e.sw)
	J.sv.size = Vector2i(J.SW, J.SH)
	J.S = e.S
	J.B = e.B
	J.VC = e.VC
	J.vfx = e.vfx
	J.ents = []
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.SOSP = e.SOSP
	for c in e.P:
		J.P[c] = e.P[c]
	J.mode = e.mode
	var now: float = e.now
	var fallos := []
	var tot := 0
	for t in J.D.EXTR:
		var n: int = J.D.EXTR[t].pasos.size() + (1 if t == "seco" else 0)
		for i in n:
			var T: Dictionary = e.TIRO.duplicate()
			T.merge({"esc": t, "paso": i, "n": n, "per": J.D.EXTR[t].per, "mov": float(J.D.EXTR[t].get("mov", 0)), "ritmo": float(J.D.EXTR[t].get("ritmo", 0))}, true)
			var sin_esc: Dictionary = T.duplicate()
			sin_esc.erase("esc")
			var base: Image = await foto(e, sin_esc, now)
			var a: Image = await foto(e, T, now)
			var b: Image = await foto(e, T, now + 1730)
			a.save_png(dir.path_join("ext-%s-%d-a.png" % [t, i]))
			b.save_png(dir.path_join("ext-%s-%d-b.png" % [t, i]))
			if a.get_data() == base.get_data():
				fallos.append("%s %d: no se pinta" % [t, i])
			if a.get_data() == b.get_data():
				fallos.append("%s %d: no se mueve" % [t, i])
			tot += 1
	for x in fallos:
		print("  FALLO ", x)
	print("extracciones: %d escenas, %d fallos" % [tot, fallos.size()])
	J.queue_free()
	quit(1 if fallos.size() else 0)
