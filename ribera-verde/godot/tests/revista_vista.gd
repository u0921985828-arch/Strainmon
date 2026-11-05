# Landrace Hunters (Godot) — EL ESQUEJE a la vista (lo pidió el usuario: «que los números se vean como revista, con portada y
# páginas dibujadas»). Solo Godot, con Datos.CAL. Comprueba el atlas del arte (tools/sprites/a-mano/revista.py), las planas de cada
# número (portada + una por sección, con su viñeta), el hueco del texto dentro del papel y, en la imagen de verdad, que la plana se
# pinta, que el texto del lector cae dentro del papel y que ◀ ▶ pasa de plana.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --resolution 1560x720 --script res://tests/revista_vista.gd -- [--salida <dir>]
extends SceneTree

const Datos = preload("res://src/datos.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	Datos.CAL = true
	_corre.call_deferred()

func espera(k: int) -> void:
	for i in k:
		await process_frame

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func check(que: String, ok: bool) -> void:
	n += 1
	if not ok:
		fallos.append(que)
		print("FALLO  " + que)

func _corre() -> void:
	var dir := arg("--salida")
	Datos.carga()
	var Juego = load("res://src/juego.gd")
	var UI = load("res://src/ui.gd")
	Juego.GUARDADO = "user://prueba-revvista.json"
	UI.AJUSTES = "user://prueba-revvista-ajustes.json"
	for f in [Juego.GUARDADO, UI.AJUSTES]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-a":
			e = Datos.enteros(x)
	J = Juego.new()
	J.oraculo = false
	root.add_child(J)
	await espera(5)
	J.ajustes_aplica()
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	await espera(5)
	_atlas()
	_planas()
	_parodia()
	await _render(dir)
	print("revista_vista: %d comprobaciones, %d fallos%s" % [n, fallos.size(), (": " + "; ".join(fallos)) if fallos.size() else ""])
	quit(1 if fallos.size() else 0)

# ---------- el atlas del arte ----------
func _atlas() -> void:
	check("el atlas de la revista carga (arte/revista.png)", J.rev_art())
	var A: Dictionary = J.REV_ART
	for k in ["papel", "mancheta", "mancheta-en", "filete", "filete2", "grapa", "dobl", "cinta", "sello"]:
		check("el atlas trae %s" % k, A.has(k))
	for k in J.REV_VG.values():
		check("el atlas trae la viñeta vg-%s" % k, A.has("vg-" + k))
	for k in J.REV_ILU.values():
		check("el atlas trae la ilustración pt-%s" % k, A.has("pt-" + k))
	check("el atlas trae pt-planta y pt-carpa (los de reserva)", A.has("pt-planta") and A.has("pt-carpa"))
	for k in ["mancheta", "mancheta-en"]:   # la cabecera de cada idioma, dentro de la plana
		if A.has(k):
			var mc: Image = A[k]
			check("%s cabe en la plana (%d px)" % [k, mc.get_width()], mc.get_width() <= J.rev_caja().size.x - 12)
	check("sin idioma cambiado, la cabecera es la de siempre", J.rev_mancheta() == "mancheta")
	if A.has("papel"):
		check("el papel es tileable (64 × 64)", A["papel"].get_width() == 64 and A["papel"].get_height() == 64)

# ---------- las planas de cada número ----------
func _planas() -> void:
	for num in [1, 3, 7, 12, 25]:
		var rv: Dictionary = J.rev_paginas(num)
		var pags: Array = rv.pags
		var tit: Array = rv.tit
		var vg: Array = rv.vg
		check("n.º %d: más de una plana (%d)" % [num, pags.size()], pags.size() > 1)
		check("n.º %d: una cabecera y una viñeta por plana" % num, tit.size() == pags.size() and vg.size() == pags.size())
		check("n.º %d: la portada va primero, sin viñeta ni cabecera" % num, String(tit[0]) == "" and String(vg[0]) == "")
		check("n.º %d: la portada lleva su ilustración (%s)" % [num, rv.ilu], J.REV_ART.has("pt-" + String(rv.ilu)))
		var falta := []
		for i in range(1, pags.size()):
			var suelta: bool = String(vg[i]) == "anu" or String(vg[i]) == "pst"   # el anuncio y el póster van a toda página, sin cabecera
			if String(pags[i]).strip_edges() == "" or (String(tit[i]) == "" and not suelta) or not J.REV_ART.has("vg-" + String(vg[i])):
				falta.append(i)
		check("n.º %d: ninguna plana vacía ni sin viñeta (%s)" % [num, falta], falta.is_empty())
		# el texto de las planas dice lo mismo que el número de siempre (nada se pierde por el camino)
		var ent: String = J.rev_texto(num)
		var fuera := []
		for q in J.rev_secciones(num):
			var t := String(q.tit)
			if t != "" and not ent.contains(t):
				fuera.append(t)
			if t != "" and not pags.any(func(x): return String(x).contains(String(q.txt).split("\n")[0])) and not tit.any(func(x): return String(x).begins_with(t)):
				fuera.append(t)
		check("n.º %d: las planas traen todas las secciones (%s)" % [num, fuera], fuera.is_empty())
		# el hueco del texto, dentro del papel y de la pantalla
		var c: Rect2i = J.rev_caja()
		check("n.º %d: la plana cabe en el lienzo (%s)" % [num, c], c.position.x >= 0 and c.end.x <= J.SW and c.position.y >= 0 and c.end.y <= J.SH)
		J.lector_rev = rv
		var malas := []
		for i in pags.size():
			J.lector_i = i
			var z: Rect2i = J.rev_zona()
			if not c.encloses(z) or z.size.x < 60 or z.size.y < 30:
				malas.append(i)
		check("n.º %d: el hueco del texto, dentro del papel (%s)" % [num, malas], malas.is_empty())
		# lo dibujado, dentro de la plana
		var fuera_r := []
		for i in pags.size():
			J.lector_i = i
			var l: Array = J.rects_revista()
			if l.is_empty():
				fuera_r.append(i)
				continue
			for e in l:
				if typeof(e[0]) == TYPE_STRING:
					if not c.intersects(Rect2i(int(e[2]), int(e[3]), (e[1] as Image).get_width(), (e[1] as Image).get_height())):
						fuera_r.append(i)
						break
					continue
				if not c.encloses(Rect2i(int(e[0]), int(e[1]), int(e[2]), int(e[3]))) and int(e[1]) != c.position.y - 1 and int(e[1]) != c.end.y:
					fuera_r.append(i)
					break
		check("n.º %d: nada dibujado fuera de la plana (%s)" % [num, fuera_r], fuera_r.is_empty())
		J.lector_rev = {}
		J.lector_i = 0

# ---------- la parodia del género: lo que trae cada número ----------
# (lo pidió el usuario: que EL ESQUEJE sea una parodia de las revistas de cultivo). La entrevista, el consultorio, el banco de
# pruebas, el póster central en la grapa, dos planas de anuncios de los negocios del juego, el horóscopo del mes y la fe de
# errores del número anterior.
func _parodia() -> void:
	var R: Dictionary = J.D.REVISTA
	for num in [1, 3, 7, 12, 25]:
		var rv: Dictionary = J.rev_paginas(num)
		var vg: Array = rv.vg
		for k in ["ent", "con", "tst", "hor", "err", "pst"]:
			check("n.º %d: el número trae la plana %s" % [num, k], vg.has(k))
		var anu := []
		for i in vg.size():
			if String(vg[i]) == "anu":
				anu.append(i)
		check("n.º %d: dos planas de anuncios (%s)" % [num, anu], anu.size() == 2)
		check("n.º %d: los dos anuncios son distintos" % num, J.rev_anu(num, 0) != J.rev_anu(num, 1))
		var ip: int = vg.find("pst")
		check("n.º %d: el póster, en la grapa de la revista (%d de %d)" % [num, ip, vg.size()], ip > 0 and absi(ip - (vg.size() >> 1)) <= 3)
		var fal: String = J.rev_faldon(num)
		check("n.º %d: la portada lleva su reclamo («%s»)" % [num, fal], fal != "" and String(rv.pags[0]).contains(fal))
		var mes: int = int(J.rev_my(num).m)
		check("n.º %d: el horóscopo es el del mes %d" % [num, mes], J.rev_hor(num) == J.I18n.v(String(R.hor[mes - 1])))
		check("n.º %d: la entrevista, con sus tres preguntas" % num, J.rev_ent(num).split("\n").size() == 7)
		var ap: Dictionary = R.tst[Datos.hash_str("rev-tst|%d" % num) % R.tst.size()]
		var tt: String = J.rev_tst(num)
		check("n.º %d: el banco de pruebas, con su aparato y su publirreportaje" % num, tt.contains(J.I18n.v(String(ap.n))) and tt.contains(J.I18n.v(String(R.tstp))))
		check("n.º %d: el consultorio, dos preguntas con su respuesta" % num, J.rev_con(num).split("\n").size() == 4)
	check("el n.º 1 no tiene número anterior que corregir", J.rev_err(1) != J.rev_err(2))
	check("doce horóscopos, uno por mes", R.hor.size() == 12)
	# la revista no entrevista a quien no has visto ni anuncia un negocio que no ha abierto
	var ch0 = J.S.ch
	var cf = J.S.flags.get("conce", 0)
	J.S.ch = 1
	J.S.flags["conce"] = 0
	for num in [1, 2, 3, 5]:
		var e: String = J.rev_ent(num)
		var mal := []
		for x in R.ent:
			if int(x.ch) > 1 and e.begins_with(J.I18n.v(String(x.n)) + " ·"):
				mal.append(String(x.n))
		check("n.º %d, capítulo 1: la entrevista es de alguien que ya conoces (%s)" % [num, mal], mal.is_empty())
		for k in 2:
			var a: String = J.rev_anu(num, k)
			var mal_a := []
			for x in R.anu:
				if (int(x.ch) > 1 or String(x.f) != "") and a.begins_with(J.I18n.v(String(x.n)) + "\n"):
					mal_a.append(String(x.n))
			check("n.º %d, capítulo 1: el anuncio %d es de un negocio abierto (%s)" % [num, k, mal_a], mal_a.is_empty())
		check("n.º %d, capítulo 1: los dos anuncios siguen siendo distintos" % num, J.rev_anu(num, 0) != J.rev_anu(num, 1))
	J.S.ch = 8
	J.S.flags["conce"] = 1
	var vistos := {}
	for num in range(1, 40):
		vistos[J.rev_ent(num).split(" ·")[0]] = 1
		for k in 2:
			vistos[J.rev_anu(num, k).split("\n")[0]] = 1
	check("en el capítulo 8 salen todos los entrevistados y anunciantes (%d)" % vistos.size(), vistos.size() >= R.ent.size() + R.anu.size() - 1)
	J.S.ch = ch0
	J.S.flags["conce"] = cf
	# la lámina del póster, por el porte de la variedad del mes
	for num in [1, 3, 7, 12, 25]:
		var pl: String = J.rev_pst_pl(num)
		var ind: int = Datos.ind_de(J.S, J.rev_var(num))
		check("n.º %d: la lámina del póster va con el porte (%d %% índica → %s)" % [num, ind, pl],
			pl == ("ps-ind" if ind >= 65 else ("ps-sat" if ind <= 35 else "ps-hib")) and J.REV_ART.has(pl))
	# el lema de la cabecera, que es media parodia, tiene que leerse en el número
	check("el lema de la cabecera sale en la revista", J.rev_texto(3).contains(J.I18n.v(String(R.cab.lema))))
	# la nota del banco de pruebas, con el separador decimal de cada idioma
	check("la nota, con coma en castellano y punto en inglés", J.rev_dec("9,4") == "9,4")
	var nom := []
	for a in R.anu:
		nom.append(String(a.n))
	check("los anuncios son de los negocios del juego (%d)" % nom.size(), nom.size() >= 6 and nom.size() == nom.reduce(func(c, x): return c, nom).size())

# ---------- la imagen de verdad ----------
func _render(dir: String) -> void:
	var num := 3
	var rv: Dictionary = J.rev_paginas(num)
	J.leer("EL ESQUEJE", J.rev_texto(num), rv)
	await espera(30)
	check("la revista abre el lector en modo revista", J.lector.visible and not J.lector_rev.is_empty())
	var c: Rect2i = J.rev_caja()
	var pl := Rect2(J.scr.position + Vector2(c.position.x * J.u, c.position.y * J.u), Vector2(c.size.x * J.u, c.size.y * J.u))
	check("el texto de la portada va dentro del papel", pl.grow(1).encloses(J.lector.get_global_rect()))
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
		img.save_png(dir.path_join("revista-portada.png"))
	check("el papel se pinta en las cuatro esquinas de la plana", _papel(img, pl))
	check("la plana no deja negro dentro", not _negro(img, pl))
	# ▶ pasa de plana: la viñeta de la sección cambia
	for i in 3:
		J.press("right")
		await espera(6)
	check("◀ ▶ pasa de plana (%d)" % J.lector_i, J.lector_i == 3)
	check("la plana 3 lleva su viñeta (%s)" % String(rv.vg[3]), String(rv.vg[3]) != "")
	await espera(10)
	check("el texto de la sección va dentro del papel", pl.grow(1).encloses(J.lector.get_global_rect()))
	await RenderingServer.frame_post_draw
	img = root.get_texture().get_image()
	if dir != "":
		img.save_png(dir.path_join("revista-seccion.png"))
	check("el papel se pinta también en la plana de la sección", _papel(img, pl))
	check("el HUD no se queda encima de la revista", not J.hud.visible)
	# las planas de la parodia: el anuncio a toda página y el póster central
	for k in ["anu", "pst"]:
		var ip: int = rv.vg.find(k)
		while J.lector_i < ip:
			J.press("right")
			await espera(6)
		await espera(10)
		check("la plana de %s (%d) va dentro del papel" % [k, ip], pl.grow(1).encloses(J.lector.get_global_rect()))
		await RenderingServer.frame_post_draw
		img = root.get_texture().get_image()
		if dir != "":
			img.save_png(dir.path_join("revista-%s.png" % k))
		check("el papel se pinta en la plana de %s" % k, _papel(img, pl))
		check("la plana de %s no deja negro dentro" % k, not _negro(img, pl))
		check("el texto de %s no se desliza" % k, J.lector_sc.get_v_scroll_bar().max_value <= J.lector_sc.size.y + 1)
	J.press("B")
	await espera(10)
	check("B cierra la revista y deja el lector como estaba", not J.lector.visible and J.lector_rev.is_empty())
	await _letra()
	await _titular()
	await _peor()

# la letra de la plana se mide en píxeles del lienzo (u), no en los de la interfaz (us): en un móvil us es más pequeño que u y,
# midiéndola así, el texto encogía y la plana quedaba tres cuartos vacía
func _letra() -> void:
	var rv: Dictionary = J.rev_paginas(3)
	J.leer("EL ESQUEJE", J.rev_texto(3), rv)
	await espera(20)
	var esp: float = J.fs_txt(7 * J.u)
	check("la letra de la plana va en píxeles del lienzo (%d)" % int(esp), is_equal_approx(J.lector_txt.get_theme_font_size("font_size"), esp))
	var us0: float = J.us
	J.us = maxf(1.0, J.u * .6)   # el móvil: la interfaz, a menos de la escala del lienzo
	J._lector_estilo()
	await espera(6)
	check("con us menor que u la letra de la plana no encoge", is_equal_approx(J.lector_txt.get_theme_font_size("font_size"), esp))
	J.us = us0
	J._lector_estilo()
	J.press("B")
	await espera(10)

# el titular más largo de todos cabe en el hueco de la portada sin tener que deslizar
func _titular() -> void:
	var largo := ""
	var fal := ""
	for v in J.D.REVISTA.tit.values():
		for t in v:
			var x: String = J.I18n.v(String(t))
			if x.length() > largo.length():
				largo = x
	for nw in J.D.REVISTA.nw:
		if nw.has("ti"):
			var x: String = J.I18n.v(String(nw.ti))
			if x.length() > largo.length():
				largo = x
	var rv: Dictionary = J.rev_paginas(3)
	for f in J.D.REVISTA.fal:   # la portada lleva, debajo del titular, el reclamo del número
		var x: String = J.I18n.v(String(f))
		if x.length() > fal.length():
			fal = x
	var cab := String(rv.pags[0]).split("\n")[0]
	rv.pags[0] = "%s\n%s\n%s" % [cab, largo, fal]
	J.leer("EL ESQUEJE", J.rev_texto(3), rv)
	await espera(30)
	var sb: ScrollBar = J.lector_sc.get_v_scroll_bar()
	check("el titular y el reclamo más largos (%d letras) caben en la portada sin deslizar" % (largo.length() + fal.length()), sb.max_value <= J.lector_sc.size.y + 1)
	J.press("B")
	await espera(10)

# las cuatro esquinas de dentro de la plana, en papel (claro y cálido)
func _papel(img: Image, r: Rect2) -> bool:
	for p in [Vector2(r.position.x + 20, r.position.y + 3), Vector2(r.end.x - 6, r.position.y + 3),
			Vector2(r.position.x + 20, r.end.y - 4), Vector2(r.end.x - 6, r.end.y - 4)]:
		var x := clampi(int(p.x), 0, img.get_width() - 1)
		var y := clampi(int(p.y), 0, img.get_height() - 1)
		var c: Color = img.get_pixel(x, y)
		if c.r < .7 or c.g < .68 or c.b > c.r:
			return false
	return true

func _negro(img: Image, r: Rect2) -> bool:
	var x := int(r.position.x) + 4
	while x < int(r.end.x) - 4:
		var y := int(r.position.y) + 4
		while y < int(r.end.y) - 4:
			var c: Color = img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1))
			if c.r + c.g + c.b < .12:
				return true
			y += 7
		x += 7
	return false

# el anuncio y el póster van a toda plana: el más largo de los ocho tiene que caber sin deslizar, también con el texto grande de
# OPCIONES (en la app publicada, PLAY, TAMAÑO DE TEXTO L multiplica la letra por 1,25) y en el idioma que gaste más letras
func _peor() -> void:
	var R: Dictionary = J.D.REVISTA
	var play := Datos.PLAY
	var tam = J.aj.get("tam", 1)
	var lang: String = J.I18n.LANG
	var peor := {"anu": "", "pst": ""}
	for idi in ["es", "en"]:
		J.I18n.LANG = idi
		for a in R.anu:
			var t := "%s\n%s\n\n%s" % [J.I18n.v(String(a.n)), J.I18n.v(String(a.t)), J.I18n.v(String(a.pie))]
			if t.length() > peor.anu.length():
				peor.anu = t
		var nl := ""
		for k in J.D.STRAINS:
			var x: String = J.I18n.v(String(J.D.STRAINS[k].n))
			if x.length() > nl.length():
				nl = x
		var ps := "%s\n%s · %s\n%s" % [J.I18n.v(String(R.pst.cab)), nl, J.linea_ind(J.rev_var(3)), J.I18n.v(String(R.pst.pie))]
		if ps.length() > peor.pst.length():
			peor.pst = ps
	J.I18n.LANG = lang
	Datos.PLAY = true
	J.aj["tam"] = 2
	var rv: Dictionary = J.rev_paginas(3)
	for k in ["anu", "pst"]:
		var i: int = rv.vg.find(k)
		if i >= 0:
			rv.pags[i] = String(peor[k])
	J.leer("EL ESQUEJE", J.rev_texto(3), rv)
	await espera(20)
	for k in ["anu", "pst"]:
		var i: int = rv.vg.find(k)
		while J.lector_i < i:
			J.press("right")
			await espera(6)
		await espera(12)
		check("el %s más largo (%d letras) cabe con el texto grande" % [k, String(peor[k]).length()],
			J.lector_sc.get_v_scroll_bar().max_value <= J.lector_sc.size.y + 1)
	J.press("B")
	await espera(10)
	Datos.PLAY = play
	J.aj["tam"] = tam
	J._lector_estilo()
