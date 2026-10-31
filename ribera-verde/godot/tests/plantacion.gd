# Landrace Hunters (Godot) — los planos desde arriba de todos los esquemas de plantación (vista.gd plaza_rejilla y tresbolillo, con CAL;
# lo pidió el usuario: «Yo haría un plano desde arriba… para aprovechar el espacio y que desde la vista C se vean… lo mejor posible las
# plantas… En tres bolillos… en las que se pueda… haz todos los planos con todos los tipos de esquemas de plantación»): cada carpa de
# casa con cada maceta que admite (lmax) y cada carpa de KAIA con su kit y sus esquemas (KC_PATRON; la de 400 × 400, por las dos
# mitades de su vista); ninguna maceta fuera de la carpa ni encima de otra; las filas seguidas con las mismas plazas, corridas (las
# plantas de detrás caen entre las de delante, a TRES_MIN cm o más) salvo donde la maceta no deja; sin CAL, la rejilla de siempre.
# Con --salida DIR, un PNG por esquema (2 px por cm: el suelo, la línea de delante abajo, en gris la rejilla de antes y en verde las
# macetas) e índice en DIR/PLANTACION.md.
#   $GODOT --headless --path godot --script res://tests/plantacion.gd [-- --salida ../docs/plano/plantacion]   → «plantacion: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Vista = preload("res://src/vista.gd")

var n := 0
var fallos := []
var md := []
const PX := 2

func _initialize() -> void:
	Datos.PLAY = false
	Datos.CAL = true
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# las plazas de C con la maceta k: la rejilla y, con CAL, en tresbolillo
func plazas(C: Dictionary, k: String, tres: bool) -> Array:
	var pl := []
	var mac := []
	for j in int(C.plazas):
		var r := Vista.plaza_rejilla(C, j)
		r.i = j
		pl.append(r)
		mac.append(k)
	if tres:
		Vista.tresbolillo(pl, float(C.cm[0]), mac)
	return pl

func circulo(im: Image, cx: float, cy: float, r: float, c: Color, solo_borde := false) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
				continue
			var d := Vector2(x + .5 - cx, y + .5 - cy).length()
			if d <= r and (not solo_borde or d > r - 1.5):
				im.set_pixel(x, y, c)

# un esquema (C con la maceta k): comprobaciones y, con dir, su plano
func esquema(nom: String, C: Dictionary, k: String, dir: String, partes := 1) -> void:
	var D := Datos.carga()
	var dm := float(D.MACETA_CM[k][0])
	var W := float(C.cm[0])
	var Dp := float(C.cm[2])
	var pl := plazas(C, k, true)
	var r0 := plazas(C, k, false)
	var dentro := true
	var choca := []
	for a in pl:
		if a.cx - dm / 2 < -.01 or a.cx + dm / 2 > W + .01 or a.cy - dm / 2 < -.01 or a.cy + dm / 2 > Dp + .01:
			dentro = false
		for b in pl:
			if int(b.i) > int(a.i) and Vector2(a.cx - b.cx, a.cy - b.cy).length() < dm - .01:
				choca.append("%d-%d" % [a.i, b.i])
	chk(dentro, "%s: las macetas, dentro de la carpa" % nom)
	chk(choca.is_empty(), "%s: ninguna maceta encima de otra (%s)" % [nom, choca])
	# las filas seguidas con las mismas plazas: corridas, o la maceta no deja (de la rejilla a la pared, menos de TRES_MIN + la holgura)
	var F := {}
	for q in pl:
		if not F.has(q.fila):
			F[q.fila] = []
		F[q.fila].append(q.cx)
	var sep := 1e9
	var corrida := false
	for f in F:
		if F.has(f + 1) and F[f].size() == F[f + 1].size():
			var m := W
			for x0 in F[f]:
				for x1 in F[f + 1]:
					m = minf(m, absf(x0 - x1))
			sep = minf(sep, m)
			var cabe: bool = W / (2 * F[f].size()) - dm / 2 - Vista.TRES_HOLGURA >= Vista.TRES_MIN
			chk(m >= Vista.TRES_MIN - .01 if cabe else m < .01, "%s: filas %d y %d %s (%.1f cm)" % [nom, f, f + 1, "corridas" if cabe else "quietas, la maceta no deja", m])
			corrida = corrida or cabe
	var txt := "tresbolillo, las de detrás a %.0f cm de las de delante" % sep if corrida else ("las filas ya caen entre las de al lado" if sep == 1e9 and F.size() > 1 else ("una fila" if F.size() == 1 else "sin tresbolillo: la maceta no deja"))
	md.append("| %s | %s | %d | %d × %d | %s | ![](%s.png) |" % [nom, k, int(C.plazas) * partes, int(C.cols), int(C.filas), txt, nom])
	if dir == "":
		return
	var im := Image.create(int(W) * PX + 8, int(Dp) * PX * partes + 8 + (partes - 1) * 4, false, Image.FORMAT_RGBA8)
	im.fill(Color.html("#1c1d22"))
	for h in partes:   # la mitad del fondo, arriba
		var oy := 4 + (partes - 1 - h) * (int(Dp) * PX + 4)
		im.fill_rect(Rect2i(4, oy, int(W) * PX, int(Dp) * PX), Color.html("#d8d4c8"))
		im.fill_rect(Rect2i(4, oy + int(Dp) * PX - 3, int(W) * PX, 3), Color.html("#c04040") if h == 0 else Color.html("#8a8678"))   # delante
		for q in r0:
			circulo(im, 4 + q.cx * PX, oy + q.cy * PX, dm / 2 * PX, Color.html("#8a8678"), true)
		for q in pl:
			circulo(im, 4 + q.cx * PX, oy + q.cy * PX, dm / 2 * PX, Color.html("#3c8a3e"))
			circulo(im, 4 + q.cx * PX, oy + q.cy * PX, dm / 2 * PX, Color.html("#1e4a20"), true)
			circulo(im, 4 + q.cx * PX, oy + q.cy * PX, 2, Color.html("#f0e8c0"))
	im.save_png(dir.path_join(nom + ".png"))

func _corre() -> void:
	var D := Datos.carga()
	var dir := arg("--salida")
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
	# casa: cada carpa con cada maceta que admite
	for t in D.CARPAS:
		var C: Dictionary = D.CARPAS[t]
		for k in D.MACETA_CM:
			if D.MACETAS.has(k) and int(D.MACETAS[k].l) <= int(C.get("lmax", 0)) and k != "tela50":
				esquema("casa-%s-%s" % [t, k], C, k, dir)
	# KAIA: el kit y los esquemas (la de 400 × 400, por mitades de 400 × 200, como en su vista)
	for N in D.KAIA_CULT.niv:
		var mi := 2 if float(N.cm[1]) > 200 else 1
		var ls := [[String(D.KAIA_CULT.maceta), int(N.plazas)]]
		for q in D.get("KC_PATRON", {}).get(String(N.k), []):
			ls.append([String(q[0]), int(q[1])])
		for e in ls:
			var W := float(N.cm[0])
			var Dp := float(N.cm[1]) / mi
			var nv: int = int(e[1]) / mi
			var cols := maxi(1, roundi(sqrt(nv * W / Dp)))
			var C := {"cm": [W, float(N.cm[2]), Dp], "cols": cols, "filas": ceili(float(nv) / cols), "plazas": nv}
			esquema("kaia-%s-%s-%d" % [N.k, e[0], e[1]], C, e[0], dir, mi)
	# la de 100 × 100 con las de 7 L, en tresbolillo (antes, en rejilla: una detrás de otra)
	var C0: Dictionary = D.CARPAS.m100
	chk(plazas(C0, "plastico7", true).map(func(q): return q.cx) != plazas(C0, "plastico7", false).map(func(q): return q.cx), "la de 100 × 100, en tresbolillo")
	if dir != "":
		var f := FileAccess.open(dir.path_join("PLANTACION.md"), FileAccess.WRITE)
		f.store_string("# Esquemas de plantación, desde arriba\n\nSale de `tests/plantacion.gd --salida` (vista.gd `plaza_rejilla` y `tresbolillo`). 2 px por cm; abajo, en rojo, el lado de delante (el que se ve en la vista C); en gris, la rejilla de antes; en verde, las macetas. La carpa de 400 × 400 se ve por mitades: la del fondo, arriba.\n\n| Esquema | Maceta | Plazas | Rejilla (por mitad) | Disposición | Plano |\n|---|---|---|---|---|---|\n" + "\n".join(md) + "\n")
	print("plantacion: %d comprobaciones, %d fallos (%d esquemas)" % [n, fallos.size(), md.size()])
	for x in fallos:
		print("  FALLO: ", x)
	quit(1 if fallos.size() else 0)
