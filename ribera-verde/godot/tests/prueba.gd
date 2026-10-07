# Ribera Verde (Godot) — prueba del corte contra el HTML (tests/oraculo.json, lo saca tools/godot.js)
#   C1 (sin ventana):  godot --headless --path godot --script res://tests/prueba.gd
#      datos, tono y porte de cada variedad, factores de cada carpa, geometría de la vista C y ciclos de cultivo hora a hora
#      con el mismo azar (Park-Miller): 0 diferencias.
#   C2 (con pantalla, p. ej. xvfb-run … --rendering-driver opengl3):  … --script res://tests/prueba.gd -- --pintar <dir> [--oraculo f]
#      pinta cada escena a 240 × 160 y la compara píxel a píxel con <dir>/html-<escena>.png (godot-<escena>.png y dif-<escena>.png)
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Vista = preload("res://src/vista.gd")

var n_ok := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func igual(que: String, a, b, tol := 0.0) -> void:
	var ok: bool
	if (a is float or a is int) and (b is float or b is int):
		ok = absf(float(a) - float(b)) <= tol
	elif a is Dictionary and b is Dictionary:
		ok = a.size() == b.size()
		for k in a:
			ok = ok and b.has(k) and str(a[k]) == str(b[k])
	else:
		ok = (a == null and b == null) or (a != null and b != null and str(a) == str(b))
	if ok:
		n_ok += 1
	elif fallos.size() < 40:
		fallos.append("%s: godot %s ≠ html %s" % [que, a, b])
	else:
		fallos.append("")

func estado(e: Dictionary) -> Dictionary:
	var S := Cultivo.nuevo_estado()
	S.carpas = [{"t": e.t, "foco": e.foco}]
	S.macetas = e.macetas.duplicate()
	S.pots = []
	for p in e.pots:
		S.pots.append(p.duplicate(true) if p else null)
	S.custom = e.get("custom", {})
	S.gen = e.get("gen", {})
	return S

func _corre() -> void:
	var O = JSON.parse_string(FileAccess.get_file_as_string(arg("--oraculo", "res://tests/oraculo.json")))
	var dir := arg("--pintar")
	if dir != "":
		await _pinta(O, dir)
		return
	var D := Datos.carga()
	# tono de la hoja y porte
	for h in O.get("hojas", []):
		var p := {"sid": h.sid}
		if h.i != null:
			p.f = {"i": h.i}
		var hj := Datos.hoja_planta({}, p)
		igual("hoja %s %s" % [h.sid, h.i], hj, h.hoja)
		igual("porte %s %s" % [h.sid, h.i], Datos.porte_planta({}, p), h.porte)
		igual("tonos %s" % hj, Datos.vc_tonos(hj), h.tonos)
	# factores
	for f in O.get("factores", []):
		var S := Cultivo.nuevo_estado()
		S.carpas = [{"t": f.t, "foco": f.foco, "goteo": f.x == 1, "vent": f.x == 1}]
		S.macetas = []
		for j in int(D.CARPAS[f.t].plazas):
			S.macetas.append(f.m)
		var r := Cultivo.factores(S, 0)
		for k in f.f:
			igual("factores %s %s %s %d %s" % [f.t, f.foco, f.m, f.x, k], r[k], f.f[k], 1e-12)
	# geometría de la vista C
	for e in O.escenas:
		var S := estado(e)
		var g = Vista.geo(S, 0)
		var H = e.html
		if H == null:
			igual("vista C %s" % e.k, g.vc, null)
			continue
		if g.vc == null:
			igual("vista C %s" % e.k, null, "vista C")
			continue
		for k in ["Z", "w", "xl", "tipo"]:
			igual("%s %s" % [e.k, k], g.vc[k], H[k], 1e-12)
		igual("%s foco" % e.k, g.vc.foco.n, H.foco)
		igual("%s on" % e.k, Cultivo.plantas_vivas(S, 0), H.on)
		igual("%s plazas" % e.k, g.pl.size(), H.pl.size())
		for j in mini(g.pl.size(), H.pl.size()):
			var q: Dictionary = g.pl[j]
			var h: Dictionary = H.pl[j]
			var p = S.pots[q.i]
			var Arte = load("res://src/arte.gd")
			var mio := {"i": q.i, "col": q.col, "fila": q.fila, "cx": q.cx, "cy": q.cy, "cw": q.cw, "ch": q.ch, "x": q.x, "y": q.y, "alto": q.alto,
				"maceta": q.v.m.n, "tierra": q.v.tierra, "hp": q.v.hp, "esp": q.v.get("esp"), "planta": q.v.p.n if q.v.p else null,
				"foto": Arte.altura(q.v.p.n, q.v.hp)[2] if q.v.p else null,
				"hoja": Datos.hoja_planta(S, p) if p else null, "porte": Datos.porte_planta(S, p) if p else null}
			for k in h:
				igual("%s plaza %d %s" % [e.k, j, k], mio[k], h[k], 1e-9)
	# ciclos de cultivo con el azar del oráculo
	for k in O.get("ciclos", {}):
		var c: Dictionary = O.ciclos[k]
		Cultivo.pm = int(c.seed)
		var S := Cultivo.nuevo_estado()
		S.carpas = [{"t": c.t, "foco": c.foco}]
		S.macetas = c.macetas.duplicate()
		S.pots = []
		for m in c.macetas:
			S.pots.append(null)
		for i in c.sids.size():
			S.pots[i] = Cultivo.nueva_planta(S, c.sids[i])
		for i in S.pots.size():
			if S.pots[i]:
				igual("%s feno %d" % [k, i], S.pots[i].f, c.fenos[i])
		var n := 0
		for h in int(c.horas):
			if h % 24 == 0:
				for i in S.pots.size():
					var p = S.pots[i]
					if p and not p.get("dead"):
						if c.rega and p.water < c.rega:
							p.water = 100.0
						if i == 1 and p.pest:
							p.pest = false
			if h == 30 and S.pots[0]:
				S.pots[0].fert = true
			Cultivo.plants_advance(S, 60)
			if h % 12 == 11:
				var t: Array = c.tiras[n]
				n += 1
				for i in S.pots.size():
					var p = S.pots[i]
					if p == null:
						continue
					var o := {"prog": p.prog, "water": p.water, "health": p.health, "pest": p.pest, "dead": p.get("dead", false), "st": Cultivo.plant_stage(p), "etapa": Cultivo.stage_name(p)}
					for x in o:
						igual("%s h%d plaza %d %s" % [k, h, i, x], o[x], t[i][x], 1e-9)
		for i in S.pots.size():
			var p = S.pots[i]
			var es = c.cosecha[i]
			if p == null or p.get("dead") or p.prog < 1:
				igual("%s cosecha %d" % [k, i], null, es)
				continue
			var f := Cultivo.factores(S, i)
			igual("%s gramos %d" % [k, i], Cultivo.gramos_planta(S, p, f), es.g if es else null)
			igual("%s thc %d" % [k, i], Cultivo.thc_cosecha(S, p, f), es.thc if es else null, 1e-12)
		igual("%s fenoN" % k, S.fenoN, c.fenoN)
		igual("%s azar siguiente" % k, Cultivo.azar(), c.sigue, 1e-15)
		Cultivo.pm = -1
	_fin("C1")

func _fin(que: String) -> void:
	var malos := fallos.filter(func(f): return f != "")
	for f in malos:
		print("FALLO  ", f)
	if fallos.size() > malos.size():
		print("… y %d más" % (fallos.size() - malos.size()))
	print("%s: %d comprobaciones, %d diferencias" % [que, n_ok + fallos.size(), fallos.size()])
	quit(1 if fallos.size() else 0)

# C2: cada escena en un SubViewport de 240 × 160, comparada con la del HTML. Sin la luz, idéntica salvo en lo que se pinta
# translúcido (la fila de delante de la elegida al 35 % y la marca del cursor), donde el canvas mezcla en 8 bits y la GPU en coma
# flotante: ahí, ±TOL_ALFA. Con la luz (el «overlay», que dobla esas diferencias), cada canal como mucho a TOL del HTML
const TOL := 4
const TOL_ALFA := 2

# rectángulos de lo translúcido: maceta y planta (con su balanceo de ±1 px y la plaga) de las filas de delante de la elegida y la
# marca del cursor
func translucido(e: Dictionary) -> Array:
	var g = Vista.geo(estado(e), 0)
	var fsel := 0
	for q in g.pl:
		if q.i == int(e.sel):
			fsel = q.fila
	var o := []
	for q in g.pl:
		if q.fila < fsel:
			o.append(Rect2i(q.x - 21, 0, 42, q.y + 1))
		if q.i == int(e.sel):
			o.append(Rect2i(q.x - 7, q.y, 14, 2))
	return o

func _pinta(O: Dictionary, dir: String) -> void:
	var tot := 0
	for e in O.escenas:
		if e.html == null:
			continue
		for sin_luz in [true, false]:
			var k: String = e.k + ("-sinluz" if sin_luz else "")
			var sv := SubViewport.new()
			sv.size = Vector2i(240, 160)
			sv.transparent_bg = false
			sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(sv)
			var v = Vista.new()
			sv.add_child(v)
			v.pinta(estado(e), {"ci": 0, "sel": int(e.sel)}, float(e.now))
			if sin_luz:
				v.luz.visible = false
			for n in 3:
				await RenderingServer.frame_post_draw
			var im := sv.get_texture().get_image()
			im.convert(Image.FORMAT_RGBA8)
			im.save_png(dir.path_join("godot-%s.png" % k))
			var ref := Image.load_from_file(dir.path_join("html-%s.png" % k))
			ref.convert(Image.FORMAT_RGBA8)
			var dif := Image.create(240, 160, false, Image.FORMAT_RGBA8)
			var tr := translucido(e)
			var n := 0
			var mx := 0
			var fuera := 0
			for y in 160:
				for x in 240:
					var a := im.get_pixel(x, y)
					var b := ref.get_pixel(x, y)
					var d := maxi(absi(a.r8 - b.r8), maxi(absi(a.g8 - b.g8), absi(a.b8 - b.b8)))
					if d:
						n += 1
						mx = maxi(mx, d)
						if sin_luz and not tr.any(func(r): return r.has_point(Vector2i(x, y))):
							fuera += 1
						dif.set_pixel(x, y, Color(1, 0, 0) if d > 1 else Color(1, 1, 0))
					else:
						dif.set_pixel(x, y, Color(b.r, b.g, b.b).darkened(.7))
			dif.save_png(dir.path_join("dif-%s.png" % k))
			print("%-24s píxeles distintos %5d · diferencia máxima %d%s" % [k, n, mx, " · fuera de lo translúcido %d" % fuera if sin_luz else ""])
			igual("%s diferencia máxima" % k, mx, mini(mx, TOL_ALFA if sin_luz else TOL))
			if sin_luz:
				igual("%s píxeles distintos fuera de lo translúcido" % k, fuera, 0)
			tot += 1
			sv.queue_free()
	_fin("C2 (%d pinturas)" % tot)
