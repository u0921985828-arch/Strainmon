# Landrace Hunters (Godot) — el tallo y la tierra de cada planta, a la vista en la vista C (vista.gd a_la_vista, con CAL; lo pidió el
# usuario: «Pues lo mismo con las plantas, lo que viene siendo el tallo y la tierra, ¿no? Tiene que estar a la vista»): se compone en el
# orden de pintado lo que pinta cada plaza (garrafa, maceta y planta) y, de cada planta, los píxeles de su tierra (zona_tierra) y del pie
# de su tallo (zona_tallo) que pisa otra; toda la que tenga alguno va en a_la_vista (se repinta encima). En la carpa de 200 × 200 de
# KAIA con 16 macetas de 25 L y en las de casa llenas (con garrafas), con la fila elegida de delante y de detrás; sin CAL, nada (las
# pantallas del HTML); las barras, fuera de la tierra y del tallo de las demás.
#   $GODOT --headless --path godot --script res://tests/tallo_vista.gd [-- --sin-arranque --salida DIR]   → «tallo_vista: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Atlas = preload("res://src/atlas.gd")
const Vista = preload("res://src/vista.gd")
const Arte = preload("res://src/arte.gd")

var J
var M
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			return false
	return true

func abre(ci: int, h := 0) -> Dictionary:
	var st := {"fin": false}
	var co := func():
		await J.run(func(): await J.kc_vista(ci, h))
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while J.mode != "carpa" and M.reloj - t0 < 20000 and M.paso():
		pass
	for i in 40:
		M.paso()
	return st

func cierra(st: Dictionary) -> bool:
	J.press("B")
	var t0: float = M.reloj
	while not st.fin and M.reloj - t0 < 20000 and M.paso():
		pass
	for i in 10:
		M.paso()
	return st.fin and J.mode == "world"

func foto(dir: String, k: String) -> void:
	if dir == "":
		return
	var o0: bool = J.oraculo
	J.oraculo = false
	J.toast_box.hide()
	J.dlg.hide()
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("tallo-%s.png" % k))
	J.oraculo = o0

func planta(sid: String, prog: float, agua := 80.0) -> Dictionary:
	var p: Dictionary = Cultivo.nueva_planta(J.S, sid)
	p.prog = prog
	p.water = agua
	return p

# los píxeles opacos de im puestos en o: de la plaza i; los que caen en zonas, suyos para mirar
func pon(im: Image, o: Vector2i, i: int, due: Dictionary, zonas: Array, mio: Array) -> void:
	for y in im.get_height():
		for x in im.get_width():
			if im.get_pixel(x, y).a8 == 0:
				continue
			var v := o + Vector2i(x, y)
			due[v] = i
			for z in zonas:
				if z.has_point(v):
					mio.append(v)
					break

# de cada plaza (de la fila elegida y de detrás), cuántos px de su tierra y de su tallo pisa otra
func tapado(S: Dictionary, g: Dictionary, fsel: int) -> Dictionary:
	var due := {}
	var mio := {}
	for q in Vista.orden(g):
		if q.fila < fsel:   # en transparencia: no tapa
			continue
		var zt: Rect2i = Vista.zona_tierra(q)
		var zs: Rect2i = Vista.zona_tallo(S, q)
		var arriba := Rect2i(zs.position, Vector2i(zs.size.x, maxi(0, zt.position.y - zs.position.y)))
		var mi: Image = Arte.foto(q.v.m.n)
		var m := []
		var gs = Vista.garrafa_sp(S, q)
		if gs:
			pon(Arte.foto(gs.n), Vector2i(q.x - 16 + int(Arte.caja(mi)[1]) - 1 - 24, q.y - 3 - 47), q.i, due, [], m)
		pon(mi, Vector2i(q.x - 16, q.y - 31), q.i, due, [zt], m)
		var t: ImageTexture = Vista.tex_planta(S, q)
		if t:
			var p: Dictionary = S.pots[q.i]
			var im: Image = Arte.recolor(Arte.aplasta(Arte.altura(q.v.p.n, q.v.hp)[1], q.v.hp), Datos.carga().VC_SECA) if q.v.muerta else Vista.img_planta(S, p, q.v)
			pon(im, Vector2i(q.x - (t.get_width() >> 1), q.y - int(q.v.tierra) - t.get_height() + 1), q.i, due, [zt, arriba], m)
		mio[q.i] = m
	var o := {}
	for i in mio:
		var c := 0
		for v in mio[i]:
			if due[v] != i:
				c += 1
		o[i] = c
	return o

# todas las filas como elegida: la que tenga su tierra o su tallo pisado, en a_la_vista; las barras, fuera de las zonas de las demás
var TOTAL := 0
func mira(que: String) -> void:
	var S: Dictionary = J.S
	for ci in S.carpas.size():
		var g: Dictionary = Vista.geo(S, ci)
		if g.is_empty() or g.vc == null:
			continue
		var filas := {}
		for q in g.pl:
			filas[q.fila] = q.i
		for fsel in filas:
			var tp := tapado(S, g, fsel)
			var lista := Vista.a_la_vista(S, g, fsel).map(func(q): return q.i)
			var malos := []
			for i in tp:
				TOTAL += tp[i]
				if tp[i] > 0 and not lista.has(i):
					malos.append("%d (%d px)" % [i, tp[i]])
			chk(malos.is_empty(), "%s, carpa %d, fila %d elegida: tierra o tallo pisados y sin repintar: %s" % [que, ci, fsel, malos])
			var zonas := []
			for q in g.pl:
				if q.fila >= fsel:
					zonas.append([q.i, Vista.zona_tierra(q), Vista.zona_tallo(S, q)])
			var pisan := []
			for b in Vista.barras(S, g, int(filas[fsel])):
				for z in zonas:
					if z[0] != b.i and (b.r.intersects(z[1]) or z[2].has_area() and b.r.intersects(z[2])):
						pisan.append("%d sobre %d" % [b.i, z[0]])
			chk(pisan.is_empty(), "%s, carpa %d, fila %d elegida: barras encima de la tierra o el tallo de otra: %s" % [que, ci, fsel, pisan])
			Datos.CAL = false
			chk(Vista.a_la_vista(S, g, fsel).is_empty(), "%s, carpa %d: sin CAL, nada (como el HTML)" % [que, ci])
			Datos.CAL = true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-tallo-vista.json"
	Juego.AJUSTES = "user://prueba-tallo-vista-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	var dir := arg("--salida")
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	J.oraculo = true
	J.gancho_menu = func(_it, o): return o
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D: Dictionary = J.D
	var C: String = D.KAIA_CULT.mapa
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	if not (J.S.get("mar") is Dictionary):
		J.S.mar = {}
	J.S.mar.lic = int(J.S.day)
	if J.S.get("nave") is Dictionary:
		if not J.S.nave.has("ma"):
			J.S.nave.ma = []
		if not J.S.nave.has("r"):
			J.S.nave.r = int(J.S.day) + 30
	J.S.min = 12 * 60
	# 1 · casa, todas las plazas con planta (de plántula a cosecha, alguna sin agua y una muerta) y la 1.ª carpa con garrafas
	var sids := ["txoko", "ria", "limon", "kali", "purpura", "mango"]
	for i in J.S.pots.size():
		J.S.pots[i] = planta(sids[i % sids.size()], .08 + .87 * float(i % 7) / 6, 0.0 if i % 5 == 4 else 80.0)
	if J.S.pots.size() > 2:
		J.S.pots[2].dead = true
	var casa: Dictionary = J.S.duplicate(true)
	mira("casa")
	if J.S.carpas.size():
		J.S.carpas[0].garrafas = true
		J.S.carpas[0].goteo = false
		mira("casa con garrafas")
	J.S = casa
	# 2 · KAIA, la carpa de 200 × 200 con 16 de 25 L, todas plantadas, y la de 4 × 2 con sus 8
	J.S.kc = {"niv": 0, "kits": [0, 0, 0, 0], "p": []}
	J.kc()
	J.kc_pon_pat(0, {"m": "tela25", "n": 16})
	for j in 16:
		J.kc().p[j] = planta(sids[j % sids.size()], .1 + .85 * float((j * 5) % 16) / 15, 0.0 if j % 6 == 5 else 80.0)
	J.enter_map(C, 4, 5, "up")
	J.mode = "world"
	corre(func(): pass)
	var st := abre(0)
	chk(J.mode == "carpa" and J.S.pots.size() == 16, "la carpa de KAIA con 16 plazas por dentro (%s, %d)" % [J.mode, J.S.pots.size()])
	var t0 := TOTAL
	mira("KAIA 16 de 25 L")
	chk(TOTAL > t0, "en la de 16, algo pisa la tierra o el tallo de otra (%d px): la prueba mira algo" % (TOTAL - t0))
	var g: Dictionary = Vista.geo(J.S, 0)
	chk(Vista.a_la_vista(J.S, g, 0).size() > 0, "en la de 16, plantas que se repintan (%d)" % Vista.a_la_vista(J.S, g, 0).size())
	J.VC.sel = 0
	await foto(dir, "kaia16-delante")
	for q in g.pl:
		if q.fila == 1:
			J.VC.sel = q.i
			break
	await foto(dir, "kaia16-fila1")
	chk(cierra(st), "fuera de la vista")
	print("tallo_vista: %d comprobaciones, %d fallos (%d px tapados)" % [n, fallos.size(), TOTAL])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
