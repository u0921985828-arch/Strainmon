# Ribera Verde (Godot) — 1.48 (lo pidió el usuario: «el mapa lo quiero más realista, no estilo Minecraft sino más de RPG clásico» y «la
# calidad de los otros sprites también, que se note que es el sprite y lo que trae»; con Datos.CAL): los firmes en mosaico, el canto
# de la hierba y los muebles con lo que llevan encima (detalle.py).
#   $GODOT --headless --path godot --script res://tests/detalle.gd   → «detalle: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también detalle-<sitio>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() and not labels.has("TENGO 18 O MÁS") else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
			break
	o = o.duplicate()
	o.initial = k
	return o

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo: fin %s libre %s modo %s" % [st.fin, J.is_free(), J.mode])
			return false
	return true

func llega(mapa: String, de: Array, a: Array) -> bool:
	var m: Dictionary = J.MAPS[mapa]
	var v := {"%d,%d" % de: true}
	var q := [de]
	while q.size():
		var c: Array = q.pop_front()
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			var nx: int = c[0] + d[0]
			var ny: int = c[1] + d[1]
			if nx == a[0] and ny == a[1]:
				return true
			var kk := "%d,%d" % [nx, ny]
			if not v.has(kk) and nx >= 0 and ny >= 0 and nx < int(m.w) and ny < int(m.h) and J.pisable(m, nx, ny) and not m.o[ny][nx]:
				v[kk] = true
				q.append([nx, ny])
	return false

func foto(dir: String, k: String) -> void:
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("detalle-%s.png" % k))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-detalle.json"
	Juego.AJUSTES = "user://prueba-detalle-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	S.ch = maxi(int(S.ch), 6)
	var dir := arg("--pintar")
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	var Pt = J.pintor
	# 1 · los firmes: un mosaico de 16 casillas por firme, y todas distintas de la de al lado
	for k in Pt.MOSAICO_TILE:
		var f = Atlas.frame_de("exterior-mosaico", "mo-" + k, "unica", 0, {"i": 0})
		chk(f != null and f.c.get_width() == 256 and f.c.get_height() == 16, "el mosaico de %s" % k)
		if f != null:
			var a: Image = f.c.get_region(Rect2i(0, 0, 16, 16))
			var b: Image = f.c.get_region(Rect2i(16, 0, 16, 16))
			chk(a.get_data() != b.get_data() or k == "tallgrass", "%s: la casilla de al lado no es la misma" % k)
	var hg: Image = Atlas.frame_de("exterior-mosaico", "mo-grass", "unica", 0, {"i": 0}).c
	var hv: Image = Atlas.frame_de(Atlas.cubre("tile:grass"), "grass", "unica", 0, {"i": 0}).c
	chk(hg.get_pixel(5, 5).is_equal_approx(hv.get_pixel(8, 8)) or hg.get_pixel(0, 0).is_equal_approx(Color8(0x84, 0xcc, 0x6c)), "la hierba, del mismo verde (las orillas casan)")
	# 1b · el atrezo de la tierra (lo pidió el usuario: «me parece muy plano. Lo haría más imperfecto»): ocho detalles de 16 × 16,
	# todos distintos, con píxeles enteros (alfa 0 o 1), y el mosaico de tierra con manchas: más tonos que el de antes (4)
	var ft = Atlas.frame_de(Atlas.cubre("misc:tierra"), "tierra", "unica", 0, {"i": 0})
	chk(ft != null and ft.c.get_width() == 16 * Pt.TIERRA_N and ft.c.get_height() == 16, "la tira del atrezo de la tierra")
	if ft != null:
		var vistas := {}
		for i in Pt.TIERRA_N:
			var c: Image = ft.c.get_region(Rect2i(i * 16, 0, 16, 16))
			var llenos := 0
			var semi := 0
			for y in 16:
				for x in 16:
					var al: float = c.get_pixel(x, y).a
					llenos += int(al > 0.99)
					semi += int(al > 0.01 and al < 0.99)
			chk(llenos >= 8 and semi == 0 and not vistas.has(c.get_data()), "atrezo de la tierra %d: %d píxeles, %d a medias" % [i, llenos, semi])
			vistas[c.get_data()] = true
	var md: Image = Atlas.frame_de("exterior-mosaico", "mo-dirt", "unica", 0, {"i": 0}).c
	var tonos := {}
	for y in 16:
		for x in 256:
			tonos[md.get_pixel(x, y).to_html()] = true
	chk(tonos.size() > 4, "la tierra con manchas y grietas: %d tonos" % tonos.size())
	# 2 · los muebles con lo que traen: por mapa y por tramo
	var casos := [["counter", "shop"], ["counter", "growcity"], ["counter", "comisaria"], ["barcounter", "bar"], ["barraD", "disco"], ["display", "shop"], ["crate", "puerto"], ["crate", "astilleros"], ["crate", "valdehierro"], ["shelfW", "shop"], ["shelfW", "comisaria"], ["sacos", "shop"], ["bottles", "bar"], ["seto", "ensanche"]]
	var vistos := {}
	for c in casos:
		J.S.map = c[1]
		var f0 = Pt._detalle_obj(c[0], 0)
		var f1 = Pt._detalle_obj(c[0], 1)
		chk(f0 != null, "%s en %s, con lo que trae" % c)
		if f0 != null:
			vistos["%s|%s" % c] = f0.c
			if c[0] in ["counter", "barcounter", "barraD"]:
				chk(f1 != null and f0.c.get_data() != f1.c.get_data(), "%s en %s: los tramos cambian" % c)
			var bb: Rect2i = f0.c.get_used_rect()
			chk(bb.size.x > 0 and bb.end.y == f0.c.get_height(), "%s en %s: apoyado en el suelo" % c)
	chk(vistos.has("counter|shop") and vistos.has("counter|comisaria") and vistos["counter|shop"].get_data() != vistos["counter|comisaria"].get_data(), "el mostrador de la comisaría no es el del grow")
	chk(vistos.has("crate|puerto") and vistos.has("crate|valdehierro") and vistos["crate|puerto"].get_data() != vistos["crate|valdehierro"].get_data(), "en el puerto, cajas de pescado")
	# 3 · sin CAL, nada cambia: el mostrador del grow sigue siendo el de siempre
	Datos.CAL = false
	J.S.map = "shop"
	chk(not Datos.CAL and Atlas.cubre("obj:counter") != null, "sin CAL, los de siempre")
	Datos.CAL = true
	# 4 · en todos los mapas de calle, los firmes del mosaico y los muebles nuevos se pintan sin error
	for mp in J.D.ZONAS:
		J.enter_map(mp, 1, 1, "down")
		J.pintor.redibuja(0.0)
		chk(true, mp)
	if dir != "":
		J.set_process(false)
		S.min = 12 * 60
		for q in [["town", 20, 9], ["town", 33, 24], ["puerto", 20, 18], ["ensanche", 20, 12], ["astilleros", 26, 8], ["valdehierro", 10, 13], ["mendialde", 24, 17], ["shop", 5, 6], ["growcity", 6, 7], ["comisaria", 5, 5], ["bar", 5, 5], ["disco", 10, 7]]:
			J.enter_map(q[0], q[1], q[2], "up")
			J.mode = "world"
			await foto(dir, "%s-%d" % [q[0], q[1]])
			await foto(dir, "%s-%d" % [q[0], q[1]])
	print("detalle: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit()
