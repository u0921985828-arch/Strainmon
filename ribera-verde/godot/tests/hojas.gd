# Ribera Verde (Godot) — 1.51: la hoja de cada variedad (lo pidió el usuario: «en el cannabis, dependiendo de la variedad o linaje,
# las hojas son diferentes»; hoja.gd y D.HOJA): sativas finas de 9 foliolos, índicas anchas de 7, y cada una con su tono.
#   $GODOT --headless --path godot --script res://tests/hojas.gd   → «hojas: N comprobaciones, 0 fallos»
#   con -- --lamina <png> deja la lámina de todas las hojas
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Hoja = preload("res://src/hoja.gd")

var n := 0
var fallos := []

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

# ancho medio de lo pintado en la mitad de arriba, por foliolo: lo fino de la hoja
func area(im: Image) -> int:
	var a := 0
	for y in Hoja.H:
		for x in Hoja.W:
			if im.get_pixel(x, y).a > 0:
				a += 1
	return a

func _initialize() -> void:
	var D: Dictionary = Datos.carga()
	var S := {}
	var ks: Array = D.STRAINS.keys()
	var lam := Image.create(Hoja.W * 10, Hoja.H * ceili(ks.size() / 10.0), false, Image.FORMAT_RGBA8)
	lam.fill(Color("#f4f2ea"))
	var vistas := {}
	for i in ks.size():
		var p := Hoja.params(D, S, ks[i])
		var im := Hoja.imagen(p)
		lam.blit_rect(im, Rect2i(0, 0, Hoja.W, Hoja.H), Vector2i((i % 10) * Hoja.W, (i / 10) * Hoja.H))
		vistas[ks[i]] = im
		chk(area(im) > 300, "%s: se ve (%d px)" % [ks[i], area(im)])
		var cs := {}
		for y in Hoja.H:
			for x in Hoja.W:
				if im.get_pixel(x, y).a > 0:
					cs[im.get_pixel(x, y).to_html()] = true
		chk(cs.size() <= 5, "%s: %d colores" % [ks[i], cs.size()])
	var thai := Hoja.params(D, S, "thai")
	var dur := Hoja.params(D, S, "durban")
	var afg := Hoja.params(D, S, "rif")
	chk(int(dur.f) > int(afg.f), "la sativa, más foliolos (%d > %d)" % [dur.f, afg.f])
	chk(Hoja.como(afg).contains("anchos") and Hoja.como(Hoja.params(D, S, "colgold")).contains("finos"), "la índica, ancha; la sativa, fina")
	chk(Hoja.grupo(0, true).begins_with("Sativa") and Hoja.grupo(1, true).begins_with("Índica") and Hoja.grupo(.5, false).begins_with("Híbrido equilibrado"), "los grupos")
	chk(Hoja.como(thai).contains("caídas"), "la tailandesa, de puntas caídas: %s" % Hoja.como(thai))
	var out := arg("--lamina")
	if out != "":
		lam.resize(lam.get_width() * 2, lam.get_height() * 2, Image.INTERPOLATE_NEAREST)
		lam.save_png(out)
	print("hojas: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
