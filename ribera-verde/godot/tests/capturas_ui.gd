# Landrace Hunters (Godot) — F7: la interfaz entera (mandos, cajas, menús) en un móvil apaisado, en castellano o en inglés, para ver
# que el texto no se sale: el combate, START, OPCIONES, un diálogo, la tienda, la Genoteca, la mochila y el móvil. No es una prueba
# (tools/tests.sh no la corre); comprueba que ninguna etiqueta de los menús se corta y saca las 8 capturas.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 2000x900 \
#     --script res://tests/capturas_ui.gd -- --salida <dir> --idioma en   → «capturas_ui: 8 pantallas, 0 cortes»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

const PANTALLAS := ["combate", "start", "opciones", "dialogo", "tienda", "genoteca", "mochila", "movil", "objetivo", "carpa", "pregunta", "aviso"]

var J
var cortes := []

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func _initialize() -> void:
	Datos.PLAY = true
	Datos.CAL = true
	_corre.call_deferred()

func espera(n: int) -> void:
	for i in n:
		await process_frame

func _corre() -> void:
	var dir := arg("--salida")
	var idioma := arg("--idioma", "es")
	DirAccess.make_dir_recursive_absolute(dir)
	Datos.carga()
	Juego.GUARDADO = "user://prueba-capui.json"
	Juego.AJUSTES = "user://prueba-capui-ajustes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.AJUSTES))
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var n := 0
	for p in PANTALLAS:
		J = Juego.new()
		J.oraculo = false
		root.add_child(J)
		await espera(3)
		J.aj.idioma = 2 if idioma == "en" else 1
		if arg("--dpi") != "":   # los ppp de un móvil (mandos_geo): los mandos a su tamaño real
			J.DPI_PRUEBA = float(arg("--dpi"))
		J.ajustes_aplica()
		J.S = J.new_game_estado() if J.has_method("new_game_estado") else J.S
		for x in O:
			if x.k == ("combate-ladron" if p == "combate" else "casa-a"):
				_monta(Datos.enteros(x))
		await espera(2)
		match p:
			"combate":
				J.mode = "battle"
				J.B.hp = 30
				J.B.hpMax = 30
				J.bhud_pon(J.bhud_datos())
				J.thief_round()
			"start":
				J.start_menu()
			"opciones":
				J.opciones()
			"dialogo":
				J.talk("KIKO", [J.K("Lo primero, el agua. La del grifo hay que corregirla: si no, la planta no aprovecha el abono.")])
			"tienda":
				J.shop()
			"genoteca":
				J.genoteca()
			"mochila":
				J.mochila()
			"movil":
				J.movil_menu()
			"objetivo":
				J.objetivo_menu()
			"carpa":                     # la vista de carpa: la ficha de la izquierda y el cursor sobre la pantalla de 240
				J.abrir_carpa(0)
			"pregunta":                  # un diálogo con opciones (el caso más apretado: texto + menú a la vez)
				J.ask("¿Le compras el carro de esquejes a Kiko por 240 €?", [J.K("Sí, me lo llevo"), J.K("Ahora no")], "KIKO")
			"aviso":                     # el aviso de arriba (toast), con el HUD al lado
				J.toast("Has llegado al capítulo 2: ya puedes vender en la calle.", 60000.0)
		await espera(90)
		_mira_cortes(p)
		if p == "combate" and Datos.PLAY:   # 1.58: la caja del jugador no tapa al jugador (lo de la izquierda) ni pisa la del enemigo
			var rp: Rect2 = J.bP.get_global_rect()
			var re: Rect2 = J.bE.get_global_rect()
			var es: Rect2 = J.escena.get_global_rect()
			# el jugador está de pie abajo (pies en la fila 142 de 160, 64 px de alto): la caja, entera por encima de su cintura
			if rp.end.y > es.position.y + es.size.y * .6 or rp.intersects(re):
				cortes.append("combate: la caja de EDDIE en %s tapa al jugador o a la del enemigo (%s)" % [rp, re])
			# con CAL, el combate en su lado (el enemigo arriba a la izquierda, hasta la columna 94; el protagonista abajo a la derecha, con la
			# gorra en la fila 86): las dos cajas, a la derecha del enemigo y por encima de la gorra
			var k := es.size.x / 240
			if Datos.CAL and (minf(rp.position.x, re.position.x) < es.position.x + 96 * k or maxf(rp.end.y, re.end.y) > es.position.y + 86 * k):
				cortes.append("combate: las cajas (%s, %s) tapan al enemigo o al protagonista (escena %s)" % [re, rp, es])
		_mira_hueco(p)
		_mira_maquetado(p)
		_mira_centrado(p)
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		_mira_botones(p, img)
		img.save_png(dir.path_join("ui-%d-%s-%s.png" % [n + 1, p, idioma]))
		n += 1
		J.queue_free()
		await espera(2)
	print("capturas_ui: %d pantallas, %d cortes%s" % [n, cortes.size(), (": " + "; ".join(cortes)) if cortes.size() else ""])
	quit(0)

# una etiqueta cortada: su texto ocupa más de lo que mide (Label con clip o recorte) o se sale de la pantalla
func _mira_cortes(p: String) -> void:
	var vp := root.get_visible_rect()
	for c in _todos(J):
		if not (c is Label or c is RichTextLabel) or not c.is_visible_in_tree() or c.get("text") == "":
			continue
		var r: Rect2 = c.get_global_rect()
		if r.size.x <= 0:
			continue
		if c is Label:
			var f: Font = c.get_theme_font("font")
			var fs: int = c.get_theme_font_size("font_size")
			var w := 0.0
			for l in String(c.text).split("\n"):
				w = maxf(w, f.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
			if c.autowrap_mode == TextServer.AUTOWRAP_OFF and w > r.size.x + 1:
				cortes.append("%s: «%s» %d > %d" % [p, c.text, w, r.size.x])
		if r.end.x > vp.end.x + 1 or r.position.x < -1:
			cortes.append("%s: «%s» fuera de la pantalla" % [p, String(c.text).left(30)])

# 0.72, el repaso del maquetado: el menú no pisa el diálogo, el HUD no sale con un menú que ya dice lo mismo, las etiquetas de una
# lista arrancan todas en la misma columna y la marca de «sigue la lista» se ve y se toca
func _mira_maquetado(p: String) -> void:
	if J.menu_box.visible and J.dlg.visible:
		var rm: Rect2 = J.menu_box.get_global_rect()
		var rd: Rect2 = J.dlg.get_global_rect()
		if J.menu_box.get_meta("cls", "right") != "battle" and rm.intersects(rd):
			cortes.append("%s: el menú %s pisa el diálogo %s" % [p, rm, rd])
	if J.menu_box.visible and J.menu_box.get_meta("cls", "right") in ["full", "start"] and J.hud.visible:
		cortes.append("%s: el HUD sale con el menú abierto, que ya dice la fecha y el dinero" % p)
	for c in J.menu_col.get_children():
		if not (c is VBoxContainer):
			continue
		var xs := {}
		for fila in c.get_children():
			if not (fila is HBoxContainer):
				continue
			for n in fila.get_children():
				if n is Label and String(n.text).strip_edges() != "" and String(n.text) != "▸" and n.size_flags_horizontal == Control.SIZE_EXPAND_FILL:
					xs[roundi(n.get_global_rect().position.x)] = true
					break
		if xs.size() > 1:
			cortes.append("%s: las etiquetas de la lista arrancan en %s" % [p, xs.keys()])
	# el icono de una fila y su texto, a la misma altura (lo pidió el usuario: «que esté alineado con el icono que tenga»)
	for n in _todos(J.menu_col):
		if not (n is HBoxContainer):
			continue
		var tx: TextureRect = null
		var lb: Label = null
		for c2 in n.get_children():
			if c2 is TextureRect and tx == null:
				tx = c2
			elif c2 is Label and lb == null and String(c2.text).strip_edges() != "":
				lb = c2
		if tx == null or lb == null or not tx.is_visible_in_tree():
			continue
		var cy_ic: float = tx.get_global_rect().get_center().y
		var cy_tx: float = lb.get_global_rect().get_center().y
		if absf(cy_ic - cy_tx) > 1.0 * J.us:
			cortes.append("%s: el icono de «%s» a %.1f u de su texto" % [p, lb.text, (cy_ic - cy_tx) / J.us])
	# La ficha del diálogo (marco + cinta del nombre), anclada al pie de la caja y con el mismo margen
	# por la izquierda; el busto que no cabe asoma por arriba y el saliente sube a rodearlo (lo pidió el usuario)
	if J.dlg.visible and J.retrato.visible:
		var rf: Rect2 = J.retrato_marco.get_global_rect()
		if J.dlg_nm.visible:
			rf = rf.merge(J.dlg_nm.get_global_rect())
		var rc: Rect2 = J.dlg.get_global_rect()
		var aba: float = rc.end.y - rf.end.y
		var arr: float = rf.position.y - rc.position.y
		var izq: float = rf.position.x - rc.position.x
		# 0.84 (lo dijo el usuario: «ese aire encima del Sprite del personaje queda mal»): con el cuadro justo la ficha
		# sigue al pie, con el mismo margen que por la izquierda; cuando el cuadro da de sí más que ella, se centra y el
		# aire se reparte arriba y abajo en vez de amontonarse encima del busto
		if absf(aba - izq) > 1.5 * J.us and absf(arr - aba) > 1.5 * J.us:
			cortes.append("%s: la ficha, a %.1f u del techo, %.1f del pie y %.1f de la izquierda" % [p, arr / J.us, aba / J.us, izq / J.us])
		if rf.position.y < rc.position.y - 0.5 and not J.dlg_sal.visible:
			cortes.append("%s: el busto asoma %.1f u del cuadro sin el saliente del contorno" % [p, (rc.position.y - rf.position.y) / J.us])
		if J.dlg_sal.visible:
			var sg: Rect2 = J.dlg_sal.get_global_rect()
			if sg.position.x > rc.position.x + 0.5 or sg.position.y > rf.position.y - 2 * J.us or sg.end.x < rf.end.x + 2 * J.us:
				cortes.append("%s: el saliente no rodea la ficha (%s / %s)" % [p, sg, rf])
	# la cabecera de un menú con dos textos (la fecha y el dinero del START): nunca pegados
	for c in J.menu_col.get_children():
		if not (c is HBoxContainer) or c.get_child_count() != 2:
			continue
		var i0: Label = c.get_child(0) as Label
		var i1: Label = c.get_child(1) as Label
		if i0 == null or i1 == null:
			continue
		var f0: Font = i0.get_theme_font("font")
		var an: float = f0.get_string_size(i0.text, HORIZONTAL_ALIGNMENT_LEFT, -1, i0.get_theme_font_size("font_size")).x
		var hueco: float = i1.get_global_rect().position.x - (i0.get_global_rect().position.x + an)
		if hueco < 2 * J.us:
			cortes.append("%s: la cabecera «%s» y «%s» a %.1f u" % [p, i0.text, i1.text, hueco / J.us])
	for c in J.menu_col.get_children():
		if c is Label and String(c.text) in ["▲", "▼"] and c.size.y < 8 * J.us - .5:
			cortes.append("%s: la marca «%s» mide %.1f u de alto (mínimo 8)" % [p, c.text, c.size.y / J.us])

# un menú con más filas de las que enseña no deja debajo de la última un hueco donde cabría otra (lo vio el usuario en la tienda)
func _mira_hueco(p: String) -> void:
	if not J.menu_box.visible:
		return
	var lh: float = 14.5 * J.us
	for c in J.menu_col.get_children():
		if c is VBoxContainer and c.get_child_count() > 0 and c.get_child_count() < J.m_items.size():
			var libre: float = c.size.y - c.get_combined_minimum_size().y
			if libre >= lh - .5:
				cortes.append("%s: hueco de %.1f filas debajo de la última (%d de %d)" % [p, libre / lh, c.get_child_count(), J.m_items.size()])
	var aire: float = J.menu_col.size.y - J.menu_col.get_combined_minimum_size().y
	if J.menu_box.get_meta("cls", "") == "full" and aire >= lh - .5:   # caben todas: la caja, sin aire debajo
		cortes.append("%s: %.1f filas de aire en la caja" % [p, aire / lh])

func _todos(n: Node) -> Array:
	var r := [n]
	for c in n.get_children():
		r.append_array(_todos(c))
	return r

func _monta(e: Dictionary) -> void:
	# el ancho de la escena, el de la pantalla (ajusta), no el de la del oráculo (240): si no, se pinta a la izquierda y las cajas, que
	# van por la escena centrada, parecen fuera
	J.S = e.S
	J.B = e.B
	J.VC = e.VC
	J.vfx = e.vfx
	J.ents = []
	if e.mode == "world" or e.mode == "carpa":
		J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	for c in e.P:
		J.P[c] = e.P[c]
	J.mode = e.mode

# 0.74 (lo pidió el usuario: «todos los textos, centrados y maquetados correctamente, en botones, cuadros
# de texto y demás»): el texto de un botón, centrado en él; un Label centrado, con su texto dentro; y el
# contenido de cada caja, con el mismo aire a izquierda y derecha.
func _mira_centrado(p: String) -> void:
	for n in _todos(J):
		if n is Button and n.is_visible_in_tree() and String(n.text).strip_edges() != "":
			var f: Font = n.get_theme_font("font")
			var fs: int = n.get_theme_font_size("font_size")
			var r: Rect2 = n.get_global_rect()
			var an: float = f.get_string_size(n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if an > r.size.x + 1:
				cortes.append("%s: el botón «%s» no da para su texto (%d > %d)" % [p, n.text, an, r.size.x])
				continue
		if n is Label and n.is_visible_in_tree() and String(n.text).strip_edges() != "" \
				and n.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and n.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var f2: Font = n.get_theme_font("font")
			var fs2: int = n.get_theme_font_size("font_size")
			var an2: float = f2.get_string_size(n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
			var r2: Rect2 = n.get_global_rect()
			if an2 > r2.size.x + 1:
				cortes.append("%s: el texto centrado «%s» no cabe (%d > %d)" % [p, n.text, an2, r2.size.x])
	# las cajas: su contenido, con el mismo aire a los dos lados
	for par2 in [["diálogo", J.dlg], ["menú", J.menu_box], ["aviso", J.toast_box], ["nombre", J.name_box], ["ficha", J.vc_info]]:
		var caja: Control = par2[1]
		if caja == null or not caja.is_visible_in_tree() or caja.get_child_count() == 0:
			continue
		var rc: Rect2 = caja.get_global_rect()
		# el rectángulo que envuelve todo lo que lleva dentro (el diálogo, p. ej., lleva retrato y texto)
		var rh := Rect2()
		var hay := false
		for c3 in caja.get_children():
			if c3 is Control and (c3 as Control).is_visible_in_tree() and c3 != J.retrato:   # el busto va en el hueco que le reserva el margen
				rh = (c3 as Control).get_global_rect() if not hay else rh.merge((c3 as Control).get_global_rect())
				hay = true
		if not hay:
			continue
		# lo que lleva dentro respeta el margen de la caja a los dos lados (ni pegado ni desbordado); el texto
		# de párrafo no tiene por qué llenarla, así que solo se mira el mínimo, no la simetría
		var ai: float = rh.position.x - rc.position.x
		var ad: float = rc.end.x - rh.end.x
		var sb2: StyleBox = caja.get_theme_stylebox("panel")
		var mi: float = (sb2.content_margin_left if sb2 and sb2.content_margin_left >= 0.0 else 0.0)
		var md: float = (sb2.content_margin_right if sb2 and sb2.content_margin_right >= 0.0 else 0.0)
		if ai < mi - 1.0 or ad < md - 1.0:
			cortes.append("%s: la caja del %s, con %.1f u a la izquierda y %.1f a la derecha (margen %.1f/%.1f)" % [p, par2[0], ai / J.us, ad / J.us, mi / J.us, md / J.us])

# el texto de los mandos, centrado de verdad en su pastilla: se mide la tinta clara dentro del botón en la
# imagen ya pintada y se compara con el centro del botón (lo pidió el usuario: «todos los textos, centrados»)
func _mira_botones(p: String, img: Image) -> void:
	for k in ["SONIDO", "START", "A", "B"]:   # los de pastilla oscura: MÓVIL va sobre el mapa y la medida por color no vale
		var b: Button = J.botones.get(k)
		if b == null or not b.is_visible_in_tree() or String(b.text).strip_edges() == "":
			continue
		var r: Rect2i = Rect2i(b.get_global_rect())
		r = r.grow(-roundi(6 * J.us)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		if r.size.x < 4 or r.size.y < 4:
			continue
		var x0 := 1 << 30
		var x1 := -1
		var y0 := 1 << 30
		var y1 := -1
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := img.get_pixel(x, y)
				# la letra es casi blanca y sin color; el icono del botón B y la pastilla, no
				if c.a > .5 and (c.r + c.g + c.b) / 3.0 > .8 and maxf(maxf(c.r, c.g), c.b) - minf(minf(c.r, c.g), c.b) < .12:
					x0 = mini(x0, x); x1 = maxi(x1, x); y0 = mini(y0, y); y1 = maxi(y1, y)
		if x1 < 0:
			cortes.append("%s: el botón %s sin texto a la vista" % [p, k])
			continue
		if OS.get_environment("LH_DBG") != "" and p == "start":
			# el rectángulo de la pastilla que se ve (lo que no es fondo del mapa), para comparar con el del botón
			var r2 := Rect2i(b.get_global_rect()).grow(roundi(6 * J.us)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			var a0 := 1 << 30; var a1 := -1; var b0 := 1 << 30; var b1 := -1
			for y in range(r2.position.y, r2.end.y):
				for x in range(r2.position.x, r2.end.x):
					var c2 := img.get_pixel(x, y)
					if (c2.r + c2.g + c2.b) / 3.0 < .3:
						a0 = mini(a0, x); a1 = maxi(a1, x); b0 = mini(b0, y); b1 = maxi(b1, y)
			print("DBG %s botón %s pastilla x %d-%d y %d-%d · texto x %d-%d y %d-%d" % [k, b.get_global_rect(), a0, a1, b0, b1, x0, x1, y0, y1])
		var cx: float = (x0 + x1 + 1) / 2.0
		var cy: float = (y0 + y1 + 1) / 2.0
		var rc := b.get_global_rect()
		# tolerancia: 3/4 del píxel de la rejilla de la letra (1 px de rejilla = cuerpo / 10), que es lo que
		# puede bailar al redondear la línea base y el píxel de separación entre letras
		var tol: float = maxf(1.0, .75 * b.get_theme_font_size("font_size") / 10.0)
		if absf(cx - rc.get_center().x) > tol:
			cortes.append("%s: el texto de %s, %.1f px fuera del centro a lo ancho (tope %.1f)" % [p, k, cx - rc.get_center().x, tol])
		if absf(cy - rc.get_center().y) > tol:
			cortes.append("%s: el texto de %s, %.1f px fuera del centro a lo alto (tope %.1f)" % [p, k, cy - rc.get_center().y, tol])
