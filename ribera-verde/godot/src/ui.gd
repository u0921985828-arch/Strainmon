# Ribera Verde (Godot) — la pantalla, los mandos y la interfaz del HTML (06-controles, 06b-pantalla, 07-interfaz, styles.css):
# el juego se pinta en un SubViewport de SW × 160 (SW de 240 a 400, como ajustarPantalla) y encima, a la resolución del móvil,
# van el HUD, la escena de 240 (título, cajas del combate y ficha de la carpa), los diálogos, los menús y los avisos (el
# escenario .ui, que encoge para caber entre los mandos), la carta final, el fundido, la cortinilla y los mandos flotantes.
# Los guiones son corrutinas: say/ask/menu esperan a una promesa (Motor.Prom) que resuelve el manejador de la pila (push/pop),
# como en el HTML. El reloj (M) es el bucle de eventos del navegador: setTimeout/setInterval y las esperas.
# Base de la cadena ui → mundo → granja → trama → juego: lo que se define más abajo se declara aquí vacío (virtual).
extends Control

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Motor = preload("res://src/motor.gd")
const Atlas = preload("res://src/atlas.gd")
const Sonido = preload("res://src/sonido.gd")

const BOX := Color("#f8f8f0")
const INK := Color("#2c2c36")
const SOMBRA := Color("#e2dbd0")
const LINEA := Color("#46749a")
const LINEA2 := Color("#a9d2ec")
const ROJO := Color("#e04040")
const GRIS := Color("#6a6a78")
const DIS := Color("#a6a6ae")

var M := Motor.new()
var D: Dictionary
var S = null
var mode := "boot"
var SW := 240
var oraculo := false            # pruebas sin pantalla: no se pinta ni suena nada
var gancho_menu := Callable()    # (items, o) → o · el piloto de las pruebas elige la opción
var gancho_texto := Callable()   # (texto, nombre) · transcripción
var gancho_toast := Callable()   # (html, ms)
var gancho_combate := Callable() # (tipo) · las pruebas cambian el combate por una función (window.battle en el HTML)

var handlers: Array = []
var held := {"up": false, "down": false, "left": false, "right": false, "A": false, "B": false}
var dir_order: Array = []
var sonido = null

# ---------- nodos ----------
var letra: FontFile
var negrita: FontFile
var display: FontFile
var sv := SubViewport.new()
var lienzo := Node2D.new()       # el canvas del juego (lo pinta juego.gd)
var pantalla := TextureRect.new()
var hud := PanelContainer.new()
var hud_txt := RichTextLabel.new()
var hud_bar := Control.new()
var escena := Control.new()
var titulo := Control.new()
var bE := PanelContainer.new()
var bP := PanelContainer.new()
var vc_info := PanelContainer.new()
var vc_info_col := VBoxContainer.new()
var toast_box := PanelContainer.new()
var toast_txt := RichTextLabel.new()
var dlg := PanelContainer.new()
var dlg_txt := Label.new()
var dlg_nm := PanelContainer.new()
var dlg_nm_txt := Label.new()
var dlg_more := Control.new()
var menu_box := PanelContainer.new()
var menu_col := VBoxContainer.new()
var name_box := PanelContainer.new()
var name_in := LineEdit.new()
var endcard := ColorRect.new()
var endcard_col := VBoxContainer.new()
var fade_el := ColorRect.new()
var wipe := Control.new()
var botones := {}

# medidas (06b-pantalla): u px de pantalla por píxel de juego; la pantalla en (sx, sy) de cw × ch; el escenario .ui de uiw
# a us por píxel, desde ut por debajo del borde de arriba
var u := 1.0
var us := 1.0
var uiw := 240.0
var ut := 0.0
var tt := 0.0
var bp_r := 0.0   # de la caja de vida del jugador al borde derecho de la escena (--bpr)
var scr := Rect2(0, 0, 240, 160)
var zona_cruz := Rect2()   # zonas de toque de la cruceta y de A/B, y la cruz que se ve
var zona_ab := Rect2()
var cruz := Rect2()

func _ready() -> void:
	D = Datos.carga()
	Atlas.carga()
	if oraculo:
		return
	letra = _fuente("atkinson-hyperlegible-latin-400-normal.woff2")
	negrita = _fuente("atkinson-hyperlegible-latin-700-normal.woff2")
	display = _fuente("press-start-2p-latin-400-normal.woff2", false)
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := ColorRect.new()
	fondo.color = Color("#121519")
	fondo.set_anchors_preset(PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	sv.transparent_bg = false
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sv.size = Vector2i(SW, 160)
	sv.add_child(lienzo)
	add_child(sv)
	pantalla.texture = sv.get_texture()
	pantalla.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pantalla.stretch_mode = TextureRect.STRETCH_SCALE
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pantalla)
	# HUD: el texto y, debajo, CALOR con su barra
	var hud_col := VBoxContainer.new()
	hud_col.add_theme_constant_override("separation", 0)
	hud_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_col)
	hud_col.add_child(hud_txt)
	hud_txt.bbcode_enabled = true
	hud_txt.fit_content = true
	hud_txt.autowrap_mode = TextServer.AUTOWRAP_OFF
	hud_txt.scroll_active = false
	hud_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_col.add_child(hud_bar)
	hud_bar.draw.connect(_pinta_hud_bar)
	add_child(hud)
	# escena de 240
	escena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escena.clip_contents = false
	add_child(escena)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo.draw.connect(_pinta_titulo)
	escena.add_child(titulo)
	for b in [bE, bP, vc_info]:
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		escena.add_child(b)
	vc_info.add_child(vc_info_col)
	vc_info_col.add_theme_constant_override("separation", 0)
	# avisos, diálogo, menú y nombre
	toast_txt.bbcode_enabled = true
	toast_txt.fit_content = true
	toast_txt.scroll_active = false
	toast_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_child(toast_txt)
	# con autowrap, el alto del texto se sabe un fotograma después: entonces se vuelve a colocar
	toast_txt.minimum_size_changed.connect(func(): coloca_toast.call_deferred())
	dlg_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_txt.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dlg.add_child(dlg_txt)
	dlg.mouse_filter = Control.MOUSE_FILTER_STOP
	dlg.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			press("A"))
	add_child(dlg)
	dlg_nm.add_child(dlg_nm_txt)
	dlg_nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dlg_nm)
	dlg_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_more.draw.connect(func():
		var y := (2 * us if int(M.reloj / 300) % 2 else 0.0)
		dlg_more.draw_colored_polygon(PackedVector2Array([Vector2(0, y), Vector2(8 * us, y), Vector2(4 * us, y + 5 * us)]), ROJO))
	add_child(dlg_more)
	add_child(toast_box)   # después del diálogo y antes del menú, como los z-index del HTML (diálogo 20, aviso 25, menú 30)
	menu_box.add_child(menu_col)
	menu_col.add_theme_constant_override("separation", 0)
	menu_box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(menu_box)
	var nc := VBoxContainer.new()
	name_box.add_child(nc)
	var nl := Label.new()
	nl.text = "¿Cómo te llamas?"
	nc.add_child(nl)
	name_in.max_length = 8
	nc.add_child(name_in)
	var ns := Label.new()
	ns.text = "Pulsa A para aceptar"
	nc.add_child(ns)
	add_child(name_box)
	endcard.color = Color("#0b1a12")
	endcard.add_child(endcard_col)
	endcard_col.alignment = BoxContainer.ALIGNMENT_CENTER
	endcard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(endcard)
	fade_el.color = Color(0, 0, 0, 0)
	fade_el.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_el)
	wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wipe.draw.connect(_pinta_wipe)
	add_child(wipe)
	for n in [hud, titulo, bE, bP, vc_info, toast_box, dlg, dlg_nm, dlg_more, menu_box, name_box, endcard, wipe]:
		n.hide()
	_mandos()
	sonido = Sonido.new()
	add_child(sonido)
	get_viewport().size_changed.connect(ajusta)
	ajusta()

func _fuente(f: String, suave := true) -> FontFile:
	var o := FontFile.new()
	o.data = FileAccess.get_file_as_bytes("res://fuentes/" + f)
	o.antialiasing = TextServer.FONT_ANTIALIASING_GRAY if suave else TextServer.FONT_ANTIALIASING_NONE
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["sans-serif"])
	o.fallbacks = [sf]
	return o

# ---------- pantalla y mandos (06b-pantalla.js) ----------
func _zona_segura() -> Array:
	if not OS.has_feature("mobile"):
		return [0.0, 0.0, 0.0, 0.0]
	var r := Rect2(DisplayServer.get_display_safe_area())
	var v := Rect2(Vector2(DisplayServer.window_get_position()), get_viewport_rect().size)
	return [maxf(0, r.position.x - v.position.x), maxf(0, v.end.x - r.end.x), maxf(0, r.position.y - v.position.y), maxf(0, v.end.y - r.end.y)]

# px de pantalla por px CSS: por los ppp del móvil y, si el sistema no los da bien (escritorio, Xvfb), como un móvil en
# horizontal, que mide 360-430 px CSS de alto
func _dp() -> float:
	return maxf(1.0, maxf(DisplayServer.screen_get_dpi() / 160.0, get_viewport_rect().size.y / 430.0))

func ajusta() -> void:
	if oraculo:
		return
	var V := get_viewport_rect().size
	var dp := _dp()
	var z := _zona_segura()
	var zl: float = z[0]
	var zr: float = z[1]
	var zt: float = z[2]
	var zb: float = z[3]
	var rim := roundf(clampf(minf(V.x, V.y) * .008, 2 * dp, 5 * dp))
	var w := V.x - zl - zr - 2 * rim
	var h := V.y - zt - zb - 2 * rim
	var s := h / 160
	var k := floorf(s)
	if k >= 2 and k >= s * .94:
		s = k
	var nsw := clampi(int(floor(w / s / 2)) * 2, 240, 400)
	if nsw * s > w:
		s = w / nsw
	u = s
	if nsw != SW:
		SW = nsw
		sv.size = Vector2i(SW, 160)
	var cw := floorf(SW * s)
	var ch := floorf(160 * s)
	var x := roundf(zl + rim + (w - cw) / 2)
	var y := roundf(zt + rim + (h - ch) / 2)
	scr = Rect2(x, y, cw, ch)
	pantalla.position = Vector2(x, y)
	pantalla.size = Vector2(cw, ch)
	# mandos en mm (geo_mandos): se calculan en px CSS, como el HTML, y se pasan a px de pantalla
	var us_min := minf(s, maxf(s * .5, 1.3 * dp))
	var G := geo_mandos(V.x / dp, V.y / dp, zl / dp, zr / dp, zt / dp, zb / dp, 120 * us_min / dp)
	for n in ["dpad", "cruz", "ab", "A", "B", "start", "movil", "sonido"]:
		G[n] = Rect2(G[n].position * dp, G[n].size * dp)
	var kp: float = G.k * dp
	us = clampf(G.med * dp / 120, us_min, s)
	uiw = minf(cw, roundf(240 * us))
	zona_cruz = G.dpad
	zona_ab = G.ab
	cruz = G.cruz
	var a: float = cruz.size.x / 3
	for b in ["up", "down", "left", "right"]:
		_estilo(botones[b], Color(24 / 255.0, 28 / 255.0, 34 / 255.0, .5), Color(70 / 255.0, 80 / 255.0, 96 / 255.0, .75), Color(1, 1, 1, .22), kp * 1.6, kp * 2.4, b)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(24 / 255.0, 28 / 255.0, 34 / 255.0, .5)
	botones.mid.add_theme_stylebox_override("panel", st)
	for b in ["A", "B"]:
		_estilo(botones[b], Color(109 / 255.0, 44 / 255.0, 75 / 255.0, .55), Color(154 / 255.0, 74 / 255.0, 114 / 255.0, .85), Color(1, 210 / 255.0, 230 / 255.0, .4), G.A.size.x / 2, kp * 3.8, "")
	for b in ["START", "MOVIL", "SONIDO"]:
		_estilo(botones[b], Color(24 / 255.0, 28 / 255.0, 34 / 255.0, .55), Color(70 / 255.0, 80 / 255.0, 96 / 255.0, .75), Color(1, 1, 1, .22), kp * 3.5, kp * 2.6, "")
	# después de la letra: un botón no encoge por debajo de lo que pide la letra que tenía (de una ventana más grande)
	_pon(botones.up, cruz.position + Vector2(a, 0), Vector2(a, a))
	_pon(botones.left, cruz.position + Vector2(0, a), Vector2(a, a))
	_pon(botones.right, cruz.position + Vector2(a * 2, a), Vector2(a, a))
	_pon(botones.down, cruz.position + Vector2(a, a * 2), Vector2(a, a))
	_pon(botones.mid, cruz.position + Vector2(a, a), Vector2(a, a))
	_pon(botones.A, G.A.position, G.A.size)
	_pon(botones.B, G.B.position, G.B.size)
	_pon(botones.START, G.start.position, G.start.size)
	_pon(botones.MOVIL, G.movil.position, G.movil.size)
	_pon(botones.SONIDO, G.sonido.position, G.sonido.size)
	# escenario de diálogos: 240 us centrado, debajo de SONIDO si le cae encima
	var ux := x + cw / 2 - uiw / 2
	ut = 0.0
	var so: Rect2 = G.sonido
	if so.position.x < ux + uiw and so.end.y > y:
		ut = roundf(so.end.y - y + kp * 1.5)
	# el rótulo del título (RIBERA VERDE: 212 u de ancho y 3 de sombra) baja si SONIDO le pisa la esquina (--tt en el HTML)
	tt = maxf(20 * s, roundf(so.end.y - y + kp * 1.5)) if so.position.x < x + cw / 2 + 109 * s and so.end.y > y + 20 * s else 20 * s
	# caja de vida del jugador en el combate (bP, abajo a la derecha de la escena, ~46 u de alto): a la izquierda de A, B y START
	# si le caen encima (--bpr en el HTML)
	var er := x + cw / 2 + 120 * s
	var bb := y + ch - 49 * s
	bp_r = 6 * s
	for n in ["A", "B", "start"]:
		var r: Rect2 = G[n]
		if r.position.y < bb + kp and r.end.y > bb - 46 * s - kp:
			bp_r = maxf(bp_r, er - r.position.x + kp)
	bp_r = roundf(minf(bp_r, 130 * s))
	for n in [fade_el, wipe, endcard]:
		_pon(n, scr.position, scr.size)
	_pon(escena, Vector2(x + cw / 2 - 120 * u, y), Vector2(240 * u, ch))
	_pon(titulo, Vector2.ZERO, escena.size)
	_estilos()
	if menu_redraw.is_valid():
		menu_redraw.call()
	_coloca()

# mandos en mm para el pulgar en reposo (geoMandos en 06b-pantalla, mismos números): en px CSS, con los rectángulos redondeados igual
const MM := 160 / 25.4
func geo_mandos(W: float, H: float, il: float, ir: float, it: float, ib: float, med: float) -> Dictionary:
	var c := (W + il - ir) / 2
	var ocupa := func(f: float) -> Array:
		var s := f * MM
		var m := f * f * f * MM
		return [il + 4 * m + 25 * s + 2, ir + 6.75 * m + 23.86 * s + 2, ib + 35.25 * s + it + 10 * s + MM]
	var cabe := func(o: Array) -> bool: return o[0] + med <= c and o[1] + med <= W - c and o[2] <= H
	var f := 1.0
	while f > .3 and not cabe.call(ocupa.call(f)):
		f -= .005
	var o: Array = ocupa.call(f)
	var s := f * MM
	var m := f * f * f * MM
	var R := func(x: float, y: float, w: float, h: float) -> Rect2: return Rect2(Datos.jsround(x), Datos.jsround(y), Datos.jsround(w), Datos.jsround(h))
	var cx := il + 4 * m + 12 * s
	var cy := H - ib - 18 * s
	var dx := maxf(il, cx - 15 * s)
	var dy := cy - 15 * s
	var ax := W - ir - 6.75 * m - 5.25 * s
	var ay := H - ib - 19 * s
	var bx := ax - 12.361 * s
	var by := ay + 6.573 * s
	var abx := bx - 6.25 * s
	var aby := ay - 7.75 * s
	var abr := minf(W - ir, ax + 7.75 * s)
	var abb := minf(H - ib, by + 7.75 * s)
	var stx := minf(ax, W - ir - 8 * s)
	return {"f": f, "k": s, "med": minf(c - o[0], W - o[1] - c),
		"dpad": R.call(dx, dy, cx + 13 * s - dx, minf(H - ib, cy + 15 * s) - dy), "cruz": R.call(cx - 12 * s, cy - 12 * s, 24 * s, 24 * s),
		"ab": R.call(abx, aby, abr - abx, abb - aby), "A": R.call(ax - 5.25 * s, ay - 5.25 * s, 10.5 * s, 10.5 * s), "B": R.call(bx - 5.25 * s, by - 5.25 * s, 10.5 * s, 10.5 * s),
		"start": R.call(stx - 7.5 * s, ay - 16.25 * s, 15 * s, 7 * s), "movil": R.call(cx - 7.5 * s, cy - 23 * s, 15 * s, 7 * s), "sonido": R.call(W - ir - 4.5 * m - 15 * s, it + 3 * s, 15 * s, 7 * s)}

# rectángulo del escenario .ui (en px de pantalla)
func ui_rect() -> Rect2:
	return Rect2(scr.position.x + scr.size.x / 2 - uiw / 2, scr.position.y + ut, uiw, scr.size.y - ut)

func _pon(c: Control, p: Vector2, s: Vector2) -> void:
	c.position = p
	c.size = s

# la caja del HTML (.box): borde #46749a de 2 u, filete interior #a9d2ec de 1,5 u y fondo #f8f8f0, esquinas de 4 u
class Caja extends StyleBox:
	var capas := []
	func _init(k: float) -> void:
		for c in [[LINEA, 0.0, 4.0], [LINEA2, 2.0, 2.0], [BOX, 3.5, 1.0]]:
			var b := StyleBoxFlat.new()
			b.bg_color = c[0]
			b.set_corner_radius_all(roundi(c[2] * k))
			capas.append([b, c[1] * k])
	func _draw(to_canvas_item: RID, rect: Rect2) -> void:
		for c in capas:
			c[0].draw(to_canvas_item, rect.grow(-c[1]))

func caja(k: float, py: float, px: float) -> StyleBox:
	var b := Caja.new(k)
	b.content_margin_left = (px + 2) * k
	b.content_margin_right = (px + 2) * k
	b.content_margin_top = (py + 2) * k
	b.content_margin_bottom = (py + 2) * k
	return b

func plana(c: Color, r: float, py := 0.0, px := 0.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(roundi(r))
	s.content_margin_left = px
	s.content_margin_right = px
	s.content_margin_top = py
	s.content_margin_bottom = py
	return s

func pon_letra(l: Control, f: Font, px: float, c: Color, alto := 0.0, sombra := true) -> void:
	l.add_theme_font_override("font" if l is Label or l is LineEdit else "normal_font", f)
	l.add_theme_font_size_override("font_size" if l is Label or l is LineEdit else "normal_font_size", maxi(5, roundi(px)))
	l.add_theme_color_override("font_color" if l is Label or l is LineEdit else "default_color", c)
	if sombra:
		l.add_theme_color_override("font_shadow_color", SOMBRA)
		l.add_theme_constant_override("shadow_offset_x", maxi(1, roundi(px * .08)))
		l.add_theme_constant_override("shadow_offset_y", maxi(1, roundi(px * .08)))
	if alto and l is Label:
		l.add_theme_constant_override("line_spacing", roundi(alto - f.get_height(maxi(5, roundi(px)))))

func _estilos() -> void:
	dlg.add_theme_stylebox_override("panel", caja(us, 6, 10))
	pon_letra(dlg_txt, letra, 10 * us, INK, 13.5 * us)
	dlg_nm.add_theme_stylebox_override("panel", plana(LINEA, 3 * us, 2.5 * us, 5 * us))
	pon_letra(dlg_nm_txt, negrita, 8 * us, Color.WHITE, 0, false)
	menu_box.add_theme_stylebox_override("panel", caja(us, 5, 7))
	toast_box.add_theme_stylebox_override("panel", caja(us, 4, 10))
	pon_letra(toast_txt, letra, 9 * us, INK)
	toast_txt.add_theme_font_override("bold_font", negrita)
	toast_txt.add_theme_constant_override("line_separation", roundi(12 * us - letra.get_height(roundi(9 * us))))
	hud.add_theme_stylebox_override("panel", plana(Color(16 / 255.0, 28 / 255.0, 22 / 255.0, .78), 3 * u, 2 * u, 4 * u))
	hud_txt.add_theme_font_override("normal_font", negrita)
	hud_txt.add_theme_font_size_override("normal_font_size", maxi(5, roundi(7.5 * u)))
	hud_txt.add_theme_color_override("default_color", Color("#eef8f0"))
	hud_txt.add_theme_constant_override("line_separation", roundi(9 * u - negrita.get_height(roundi(7.5 * u))))
	hud_bar.custom_minimum_size = Vector2(0, 9 * u)
	vc_info.add_theme_stylebox_override("panel", caja(u, 3, 4))
	for b in [bE, bP]:
		b.add_theme_stylebox_override("panel", caja(u, 3, 6))
	name_box.add_theme_stylebox_override("panel", caja(us, 8, 10))
	var nc: VBoxContainer = name_box.get_child(0)
	nc.add_theme_constant_override("separation", roundi(5 * us))
	pon_letra(nc.get_child(0), letra, 9 * us, INK)
	pon_letra(name_in, letra, 12 * us, INK, 0, false)
	name_in.custom_minimum_size = Vector2(110 * us, 0)
	pon_letra(nc.get_child(2), letra, 7 * us, GRIS, 0, false)
	if endcard.visible:
		_pinta_endcard()
	if vc_info.visible:
		vc_info_pinta()
	if bE.visible:
		bhud()

func _mandos() -> void:
	for b in [["up", ""], ["down", ""], ["left", ""], ["right", ""], ["A", "A"], ["B", "B"], ["START", "START"], ["MOVIL", "MÓVIL"], ["SONIDO", "SONIDO"]]:
		var n := Button.new()
		n.text = b[1]
		if b[1] == "":
			var dir: String = b[0]
			n.draw.connect(func():
				var c := n.size / 2
				var r := n.size.x * .16
				var v: Vector2 = {"up": Vector2(0, -1), "down": Vector2(0, 1), "left": Vector2(-1, 0), "right": Vector2(1, 0)}[dir]
				var t := Vector2(-v.y, v.x)
				n.draw_colored_polygon(PackedVector2Array([c + v * r, c - v * r * .7 + t * r, c - v * r * .7 - t * r]), Color(1, 1, 1, .88)))
		n.focus_mode = Control.FOCUS_NONE
		n.add_theme_font_override("font", negrita)
		n.add_theme_color_override("font_color", Color(1, 1, 1, .88))
		n.add_theme_color_override("font_pressed_color", Color(1, 1, 1, .95))
		n.add_theme_color_override("font_hover_color", Color(1, 1, 1, .88))
		n.add_theme_color_override("font_hover_pressed_color", Color(1, 1, 1, .95))
		n.toggle_mode = true
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(n)
		botones[b[0]] = n
	var mid := Panel.new()
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mid)
	botones.mid = mid

func _estilo(n: Button, bg: Color, on: Color, borde: Color, r: float, px: float, lado: String) -> void:
	for e in [["normal", bg], ["hover", bg], ["pressed", on], ["hover_pressed", on], ["disabled", bg]]:
		var s := StyleBoxFlat.new()
		s.bg_color = e[1]
		s.border_color = borde
		s.set_border_width_all(maxi(1, roundi(1.5 * _dp())))
		s.set_corner_radius_all(roundi(r))
		match lado:
			"up":
				s.corner_radius_bottom_left = 0
				s.corner_radius_bottom_right = 0
			"down":
				s.corner_radius_top_left = 0
				s.corner_radius_top_right = 0
			"left":
				s.corner_radius_top_right = 0
				s.corner_radius_bottom_right = 0
			"right":
				s.corner_radius_top_left = 0
				s.corner_radius_bottom_left = 0
		n.add_theme_stylebox_override(e[0], s)
	n.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	n.add_theme_font_size_override("font_size", maxi(8, roundi(px)))

# ---------- entrada (06-controles) ----------
const TECLAS := {KEY_UP: "up", KEY_DOWN: "down", KEY_LEFT: "left", KEY_RIGHT: "right", KEY_W: "up", KEY_S: "down", KEY_A: "left", KEY_D: "right",
	KEY_Z: "A", KEY_SPACE: "A", KEY_ENTER: "A", KEY_KP_ENTER: "A", KEY_J: "A", KEY_X: "B", KEY_ESCAPE: "B", KEY_BACKSPACE: "B", KEY_K: "B", KEY_SHIFT: "B",
	KEY_M: "START", KEY_TAB: "START", KEY_P: "MOVIL"}
const DIRS := ["up", "down", "left", "right"]

func set_held(b: String, v: bool) -> void:
	if held.has(b):
		held[b] = v
		if b in DIRS:
			dir_order.erase(b)
			if v:
				dir_order.append(b)

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not TECLAS.has(e.keycode):
		return
	if name_box.visible and name_in.has_focus():
		return
	var b: String = TECLAS[e.keycode]
	get_viewport().set_input_as_handled()
	if e.pressed:
		set_held(b, true)
		if e.echo and not b in DIRS:
			return
		press(b)
	else:
		set_held(b, false)

# los mandos con varios dedos a la vez, como los pointerdown del HTML: cada toque aprieta el mando que pisa hasta que se levanta.
# La cruceta, con un dedo: manda la flecha del ángulo desde el centro de la cruz (fuera de una zona muerta de 0,42 brazos) y, al
# deslizar sin levantarlo, pasa a la otra; A y B: el más cercano dentro de su zona. El ratón de verdad cuenta como un dedo más;
# el que Godot imita con el primer toque se descarta encima de los mandos
var dedos := {}
var dedos_cruz := {}   # dedo en la cruceta → flecha que aprieta ("" en la zona muerta)
var rep := {}     # mando → [id del retardo, id del intervalo]

func _input(e: InputEvent) -> void:
	var dedo = null
	if e is InputEventScreenTouch:
		dedo = e.index
	elif e is InputEventScreenDrag or (e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION):
		var d = e.index if e is InputEventScreenDrag else "raton"
		if dedos_cruz.has(d):
			get_viewport().set_input_as_handled()
			_cruz_a(d, e.position)
		return
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.device == InputEvent.DEVICE_ID_EMULATION:
			if zona_cruz.has_point(e.position) or mando_en(e.position) != "":
				get_viewport().set_input_as_handled()
			return
		dedo = "raton"
	else:
		return
	if e.pressed:
		if zona_cruz.has_point(e.position):
			get_viewport().set_input_as_handled()
			if dedos_cruz.is_empty():
				dedos_cruz[dedo] = ""
				_cruz_a(dedo, e.position)
			return
		var k := mando_en(e.position)
		if k != "":
			get_viewport().set_input_as_handled()
			dedos[dedo] = k
			aprieta(k, true)
	elif dedos_cruz.has(dedo):
		get_viewport().set_input_as_handled()
		var k: String = dedos_cruz[dedo]
		dedos_cruz.erase(dedo)
		if k != "":
			aprieta(k, false)
	elif dedos.has(dedo):
		get_viewport().set_input_as_handled()
		var k: String = dedos[dedo]
		dedos.erase(dedo)
		if not dedos.values().has(k):
			aprieta(k, false)

func dir_cruz(p: Vector2, actual: String) -> String:
	var v := p - cruz.get_center()
	if v.length() < cruz.size.x / 3 * .42:
		return actual
	if absf(v.x) > absf(v.y):
		return "left" if v.x < 0 else "right"
	return "up" if v.y < 0 else "down"

func _cruz_a(dedo, p: Vector2) -> void:
	var k: String = dedos_cruz[dedo]
	var n := dir_cruz(p, k)
	if n == k:
		return
	if k != "":
		aprieta(k, false)
	dedos_cruz[dedo] = n
	if n != "":
		aprieta(n, true)

func mando_en(p: Vector2) -> String:
	if zona_ab.has_point(p):
		return "A" if p.distance_to(botones.A.get_global_rect().get_center()) < p.distance_to(botones.B.get_global_rect().get_center()) else "B"
	for k in ["START", "MOVIL", "SONIDO"]:
		if botones[k].visible and botones[k].get_global_rect().has_point(p):
			return k
	return ""

# apretar o soltar un mando; las flechas se repiten (320 ms y luego cada 110, con algo abierto), como en 06-controles
func aprieta(k: String, on: bool) -> void:
	botones[k].set_pressed_no_signal(on)
	if k == "SONIDO":
		if on:
			audio_init()
			set_sound(not sonido_on())
		return
	set_held(k, on)
	if on:
		press(k)
		if k in DIRS:
			var r := [0, 0]
			r[0] = M.timeout(func():
				r[1] = M.intervalo(func():
					if handlers.size():
						press(k), 110), 320)
			rep[k] = r
	elif rep.has(k):
		M.quita(rep[k][0])
		M.quita(rep[k][1])
		rep.erase(k)

func suelta_todo() -> void:
	for d in dedos:
		aprieta(dedos[d], false)
	dedos.clear()
	for d in dedos_cruz:
		if dedos_cruz[d] != "":
			aprieta(dedos_cruz[d], false)
	dedos_cruz.clear()
	for b in held:
		held[b] = false
	dir_order.clear()

func push(fn: Callable) -> void:
	handlers.append(fn)

func pop() -> void:
	handlers.pop_back()

func press(b: String) -> void:
	audio_init()
	if handlers.size():
		handlers[-1].call(b)
		return
	world_press(b)

# ---------- sonido (05-audio, sonido.gd) ----------
func audio_init() -> void:
	if sonido and not oraculo:
		sonido.init()

func sfx(k: String) -> void:
	if sonido and not oraculo:
		sonido.sfx(k)

func music(n: String) -> void:
	if sonido and not oraculo:
		sonido.music(n)

func sonido_on() -> bool:
	return sonido.on if sonido else true

func set_sound(on: bool) -> void:
	if sonido:
		sonido.set_on(on)
		botones.SONIDO.text = "SONIDO" if on else "SILENCIO"
		botones.SONIDO.set_pressed_no_signal(not on)

# ---------- virtuales (las definen mundo, granja, trama y juego) ----------
func world_press(_b: String) -> void:
	pass

func update_hud() -> void:
	pass

# ---------- interfaz (07-interfaz) ----------
func wait(ms: float) -> void:
	await M.wait(ms)

func nm(t: String) -> String:
	return t.replace("{N}", S.name) if S else t

func type_text(text: String, name_ := "") -> void:
	if gancho_texto.is_valid():
		gancho_texto.call(text, name_)
	var p := Motor.Prom.new()
	var full := nm(text)
	var st := {"i": 0, "done": false, "iv": 0}
	if not oraculo:
		dlg.show()
		dlg_nm.visible = name_ != ""
		dlg_nm_txt.text = name_
		dlg_more.hide()
		dlg_txt.text = ""
		_coloca.call_deferred()
	var fin := func():
		M.quita(st.iv)
		if not oraculo:
			dlg_txt.text = full
		st.done = true
		pop()
		p.res()
	st.iv = M.intervalo(func():
		st.i += 1
		if not oraculo:
			dlg_txt.text = full.substr(0, st.i)
		if st.i % 3 == 0:
			sfx("blip")
		if st.i >= full.length():
			fin.call(), 20)
	push(func(b):
		if (b == "A" or b == "B") and not st.done:
			fin.call())
	await Motor.espera(p)

func say(text: String, name_ := "", keep := false) -> void:
	await type_text(text, name_)
	if not oraculo:
		dlg_more.show()
		_coloca.call_deferred()
	var p := Motor.Prom.new()
	push(func(b):
		if b == "A" or b == "B":
			pop()
			p.res())
	await Motor.espera(p)
	if not oraculo:
		dlg_more.hide()
		if not keep:
			dlg.hide()
			dlg_nm.hide()

# los SMS (1.10) se quedan en el móvil: S.sms, del último al primero, hasta SMS_MAX
func talk(name_: String, lines: Array) -> void:
	if S and S.get("sms") is Array and name_.begins_with("SMS · "):
		var t := []
		for l in lines:
			t.append(nm(l))
		S.sms.push_front({"d": S.day, "n": name_.substr(6), "t": "\n".join(t)})
		if S.sms.size() > D.SMS_MAX:
			S.sms.resize(int(D.SMS_MAX))
	for l in lines:
		await say(l, name_)

func ask(text: String, opts: Array, name_ := "") -> int:
	await type_text(text, name_)
	var i: int = await menu(opts, {"cls": "right", "cancel": true})
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	return opts.size() - 1 if i < 0 else i

var menu_redraw := Callable()
var m_items: Array = []
var m_o := {}
var m_i := 0
var m_top := 0

func menu(items_: Array, o := {}) -> int:
	if gancho_menu.is_valid():
		o = gancho_menu.call(items_, o)
	var items := []
	for it in items_:
		items.append({"label": it} if it is String else it)
	var p := Motor.Prom.new()
	var st := {"i": clampi(int(o.get("initial", 0)), 0, items.size() - 1)}
	var rows: int = o.get("rows", (5 if o.get("desc") else 8) if o.get("cls") == "full" else items.size())
	var draw := func():
		if oraculo:
			return
		m_items = items
		m_o = o
		m_i = st.i
		_pinta_menu(rows)
	if not oraculo:
		m_top = 0
		menu_box.show()
		if o.get("cls") == "full":
			hud.hide()
		draw.call()
		menu_redraw = draw
	var done := func(v: int):
		pop()
		menu_redraw = Callable()
		if not oraculo:
			menu_box.hide()
			update_hud()
			coloca_toast.call_deferred()
		p.res(v)
	var handler := func(b: String):
		var g: bool = o.get("cls") == "battle"
		var n := items.size()
		if b == "up":
			st.i = (st.i - 2 if st.i >= 2 else st.i) if g else posmod(st.i - 1, n)
			sfx("tick")
			draw.call()
		elif b == "down":
			st.i = (st.i + 2 if st.i + 2 < n else st.i) if g else (st.i + 1) % n
			sfx("tick")
			draw.call()
		elif g and b == "left":
			if st.i % 2:
				st.i -= 1
			draw.call()
		elif g and b == "right":
			if st.i % 2 == 0 and st.i + 1 < n:
				st.i += 1
			draw.call()
		elif b == "A":
			if items[st.i].get("disabled"):
				sfx("bump")
				return
			sfx("sel")
			done.call(st.i)
		elif b == "B" and o.get("cancel", true) != false:
			sfx("back")
			done.call(-1)
		elif b == "START" and o.get("startCloses"):
			done.call(-1)
	if not oraculo:
		menu_box.set_meta("clic", func(n: int):
			if n == st.i:
				handler.call("A")
			else:
				st.i = n
				draw.call())
	push(handler)
	return await Motor.espera(p)

# el menú en nodos: título, flechas y filas (las de un menú a toda altura caben con la descripción debajo), descripción
func _pinta_menu(rows: int) -> void:
	for c in menu_col.get_children():
		menu_col.remove_child(c)
		c.queue_free()
	var o := m_o
	var cls: String = o.get("cls", "right")
	var full := cls == "full"
	var g := cls == "battle"
	var fs := (9.5 if g else 10.0) * us
	var lh := 14.5 * us
	var vis := rows
	if full:
		# alto de la lista: lo que deja la descripción (como draw(vis) del HTML, que quita filas mientras no quepa)
		var R := ui_rect()
		var alto := R.size.y - 6 * us - 14 * us - 10 * us
		if o.get("title"):
			alto -= 8.5 * us * 1.3 + 5 * us
		if o.get("desc"):
			var dsc: String = m_items[m_i].get("desc", "")
			var dw := R.size.x - 6 * us - 18 * us
			var nl := letra.get_multiline_string_size(dsc, HORIZONTAL_ALIGNMENT_LEFT, dw, roundi(8.5 * us)).y
			var lineas := maxf(1, roundf(nl / letra.get_height(roundi(8.5 * us))))
			alto -= maxf(24 * us, lineas * 11.5 * us) + 7 * us
		while vis > 1 and vis * lh > alto:
			vis -= 1
	if m_i < m_top:
		m_top = m_i
	if m_i >= m_top + vis:
		m_top = m_i - vis + 1
	if not full:
		m_top = 0
		vis = m_items.size()
	if o.get("title"):
		var t := HBoxContainer.new()
		var a := Label.new()
		a.text = o.title
		pon_letra(a, negrita, 8.5 * us, LINEA, 0, false)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.add_child(a)
		if o.get("title2"):
			var b := Label.new()
			b.text = o.title2
			pon_letra(b, negrita, 8.5 * us, LINEA, 0, false)
			t.add_child(b)
		menu_col.add_child(t)
		var raya := ColorRect.new()
		raya.color = LINEA2
		raya.custom_minimum_size = Vector2(0, maxf(1, us))
		menu_col.add_child(raya)
		var hueco := Control.new()
		hueco.custom_minimum_size = Vector2(0, 3 * us)
		menu_col.add_child(hueco)
	if full:
		menu_col.add_child(_flecha("▲" if m_top > 0 else ""))
	var lista: Container = GridContainer.new() if g else VBoxContainer.new()
	if g:
		lista.columns = 2
	lista.add_theme_constant_override("separation", 0)
	lista.add_theme_constant_override("h_separation", 0)
	lista.add_theme_constant_override("v_separation", 0)
	if full:
		lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var maxw := (170 - 14 - 4) * us if cls == "right" else 1e9
	for k in range(m_top, mini(m_items.size(), m_top + vis)):
		var it: Dictionary = m_items[k]
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 0)
		f.custom_minimum_size = Vector2(0, lh)
		var mk := Control.new()
		mk.custom_minimum_size = Vector2(10 * us, lh)
		if k == m_i:
			mk.draw.connect(func():
				mk.draw_colored_polygon(PackedVector2Array([Vector2(0, 3.5 * us), Vector2(5 * us, 7.5 * us), Vector2(0, 11.5 * us)]), Color("#404048")))
		f.add_child(mk)
		var ic = it.get("ic")
		if ic:
			var tr := TextureRect.new()
			tr.texture = ic
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var lado := Atlas.ic_px(ic.get_width(), us)
			tr.custom_minimum_size = Vector2(lado, lado)
			tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			f.add_child(tr)
			var e := Control.new()
			e.custom_minimum_size = Vector2(2 * us, 0)
			f.add_child(e)
		elif it.get("sw"):
			var swc: String = it.sw
			var sw_ := Control.new()
			sw_.custom_minimum_size = Vector2(10 * us, lh)
			sw_.draw.connect(func():
				var y0 := (lh - 6 * us) / 2
				sw_.draw_rect(Rect2(-.8 * us, y0 - .8 * us, 7.6 * us, 7.6 * us), Color("#404048"))
				sw_.draw_rect(Rect2(0, y0, 6 * us, 6 * us), Color(swc)))
			f.add_child(sw_)
		var l := Label.new()
		l.text = it.label
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pon_letra(l, letra, fs, DIS if it.get("disabled") else INK)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lw := letra.get_string_size(it.label, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs)).x + 2
		var rw := 0.0
		var r: Label = null
		if it.get("right") != null:
			r = Label.new()
			r.text = str(it.right)
			r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pon_letra(r, letra, fs, GRIS)
			rw = letra.get_string_size(r.text, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs)).x + 2 + 10 * us
		if full or lw + rw + 22 * us > maxw:
			l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			l.custom_minimum_size = Vector2(minf(lw, maxf(20 * us, maxw - rw - 22 * us)), 0)
		f.add_child(l)
		if r:
			var e := Control.new()
			e.custom_minimum_size = Vector2(10 * us, 0)
			f.add_child(e)
			f.add_child(r)
		if g:
			f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := k
		f.mouse_filter = Control.MOUSE_FILTER_STOP
		f.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and menu_box.has_meta("clic"):
				menu_box.get_meta("clic").call(idx))
		lista.add_child(f)
	menu_col.add_child(lista)
	if full:
		menu_col.add_child(_flecha("▼" if m_top + vis < m_items.size() else ""))
	if o.get("desc"):
		var raya := ColorRect.new()
		raya.color = LINEA2
		raya.custom_minimum_size = Vector2(0, maxf(1, us))
		menu_col.add_child(raya)
		var hueco := Control.new()
		hueco.custom_minimum_size = Vector2(0, 3 * us)
		menu_col.add_child(hueco)
		var dl := Label.new()
		dl.text = m_items[m_i].get("desc", "")
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(0, 24 * us)
		pon_letra(dl, letra, 8.5 * us, INK, 11.5 * us)
		menu_col.add_child(dl)
	menu_box.set_meta("cls", cls)
	_coloca.call_deferred()

func _flecha(t: String) -> Label:
	var a := Label.new()
	a.text = t
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	a.custom_minimum_size = Vector2(0, 5 * us)
	a.clip_text = true
	pon_letra(a, letra, 6 * us, ROJO, 0, false)
	return a

# coloca diálogo, menú y aviso en el escenario .ui (en el HTML, el CSS)
func _coloca() -> void:
	if oraculo:
		return
	var R := ui_rect()
	if dlg.visible:
		dlg.custom_minimum_size = Vector2(R.size.x - 6 * us, 44 * us)
		dlg.size = Vector2(R.size.x - 6 * us, 0)
		# en el combate, el texto no pasa por debajo del menú de la derecha (118 de ancho): .dlg con padding-right 126 en el CSS
		var bt: bool = menu_box.visible and menu_box.get_meta("cls", "right") == "battle"
		dlg.get_theme_stylebox("panel").content_margin_right = ((126 if bt else 10) + 2) * us
		dlg.reset_size()
		dlg.size.x = R.size.x - 6 * us
		dlg.position = Vector2(R.position.x + 3 * us, R.end.y - 3 * us - dlg.size.y)
		dlg_nm.reset_size()
		dlg_nm.position = dlg.position + Vector2(6 * us, -12 * us)
		dlg_more.position = dlg.position + dlg.size - Vector2(8 * us + 8 * us, 4 * us + 5 * us)
		dlg_more.size = Vector2(8 * us, 7 * us)
	if menu_box.visible:
		var cls: String = menu_box.get_meta("cls", "right")
		menu_box.custom_minimum_size = Vector2(60 * us, 0)
		if cls == "full":
			menu_box.custom_minimum_size = R.size - Vector2(6 * us, 6 * us)
			menu_box.size = menu_box.custom_minimum_size
			menu_box.position = R.position + Vector2(3 * us, 3 * us)
		elif cls == "battle":
			menu_box.custom_minimum_size = Vector2(118 * us, 44 * us)
			menu_box.reset_size()
			menu_box.position = Vector2(R.end.x - 3 * us - menu_box.size.x, R.end.y - 3 * us - menu_box.size.y)
		else:
			menu_box.reset_size()
			if cls == "start":
				menu_box.position = Vector2(R.end.x - 3 * us - menu_box.size.x, R.position.y + 3 * us)
			else:
				menu_box.position = Vector2(R.end.x - 3 * us - menu_box.size.x, maxf(R.position.y + 3 * us, R.end.y - 49 * us - menu_box.size.y))
	if name_box.visible:
		name_box.reset_size()
		name_box.position = R.get_center() - name_box.size / 2
	if hud.visible:
		hud.reset_size()
		hud.position = scr.position + Vector2(3 * u, 3 * u)
	if vc_info.visible:
		vc_info.position = Vector2(3 * u, 3 * u)
		vc_info.size = Vector2(66 * u, 0)
		vc_info.reset_size()
		vc_info.size.x = 66 * u
	if bE.visible:
		bE.reset_size()
		bE.position = Vector2(6 * u, 8 * u)
		bP.reset_size()
		bP.position = Vector2(escena.size.x - bp_r - bP.size.x, escena.size.y - 49 * u - bP.size.y)
	coloca_toast()

# el aviso, sin pisar la ficha, el HUD ni SONIDO: de ancho, lo que quepa a la derecha de la ficha (el texto pasa a dos líneas);
# si choca con el HUD, a su derecha si cabe y, si no, debajo; con un menú a pantalla completa, encima de él y abajo (sobre la descripción)
func coloca_toast() -> void:
	if not toast_box.visible:
		return
	var R := ui_rect()
	var lo := R.position.x
	if vc_info.visible:
		lo = maxf(lo, escena.position.x + vc_info.position.x + vc_info.size.x + 3 * us)
	var hi := R.end.x
	var cajax := 2 * (10 + 2) * us
	var plano := toast_txt.get_parsed_text()
	var wl := 0.0
	for linea in plano.split("\n"):
		wl = maxf(wl, letra.get_string_size(linea, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(9 * us)).x + 2)
	wl = minf(wl, minf(210 * us - cajax, hi - lo - cajax))
	toast_txt.custom_minimum_size = Vector2(wl, 0)
	toast_txt.size = Vector2(wl, 0)
	toast_box.size = Vector2(wl + cajax, 0)
	toast_box.reset_size()
	toast_box.position.x = clampf(R.get_center().x - toast_box.size.x / 2, lo, maxf(lo, hi - toast_box.size.x))
	toast_box.position.y = R.position.y + 24 * us
	var full: bool = menu_box.visible and menu_box.get_meta("cls", "right") == "full"
	if full != (toast_box.get_index() > menu_box.get_index()):
		move_child(toast_box, menu_box.get_index())
	if full:
		toast_box.position.y = menu_box.position.y + menu_box.size.y - 6 * us - toast_box.size.y
		return
	if hud.visible:
		var H := Rect2(hud.position, hud.size)
		if H.intersects(Rect2(toast_box.position, toast_box.size)):
			if H.end.x + 3 * us + toast_box.size.x <= hi:
				toast_box.position.x = maxf(toast_box.position.x, H.end.x + 3 * us)
			else:
				toast_box.position.y = H.end.y + 2 * us
	var so := Rect2(botones.SONIDO.position, botones.SONIDO.size)
	if so.intersects(Rect2(toast_box.position, toast_box.size)):
		toast_box.position.y = maxf(toast_box.position.y, so.end.y + 2 * us)

# <small>…</small> (rótulo de arriba, en una línea aparte), <br>, <em> y las entidades de esc()
func html_bb(h: String) -> String:
	var t := h.replace("[", "[lb]")
	var re := RegEx.create_from_string("<small>(.*?)</small>")
	t = re.sub(t, "[font_size=%d][color=#46749a][b]$1[/b][/color][/font_size]\n" % roundi(7 * us), true)
	t = t.replace("<br>", "\n").replace("<em>", "[b][color=#e04040]").replace("</em>", "[/color][/b]")
	return t.replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", "\"").replace("&amp;", "&")

var toast_t := 0
func toast(html: String, ms := 2400.0) -> void:
	if gancho_toast.is_valid():
		gancho_toast.call(html, ms)
	if not oraculo:
		toast_txt.text = "[center]" + html_bb(html) + "[/center]"
		toast_box.show()
		coloca_toast.call_deferred()
	M.quita(toast_t)
	toast_t = M.timeout(func():
		if not oraculo:
			toast_box.hide(), ms)

static func esc(s) -> String:
	return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")

# el fundido de 07-interfaz (.fade, transición de 0,22 s) y su espera de 240 ms
var fade_tw: Tween
var fade_blanco := false
func fade_pon(to: float, white: bool, inmediato := false) -> void:
	if oraculo:
		return
	fade_blanco = white
	var c := Color.WHITE if white else Color.BLACK
	if fade_tw:
		fade_tw.kill()
	if inmediato:
		fade_el.color = Color(c, to)
		return
	fade_el.color = Color(c, fade_el.color.a)
	fade_tw = create_tween()
	fade_tw.tween_property(fade_el, "color:a", to, .22)

func fade(to: float, white := false) -> void:
	fade_pon(to, white)
	await wait(240)

# la cortinilla del combate (.wipe.go: de la raya del medio a toda la pantalla en 8 pasos, 0,45 s)
var wipe_t0 := -1.0
func wipe_go() -> void:
	wipe_t0 = M.reloj
	if not oraculo:
		wipe.show()

func wipe_fuera() -> void:
	wipe_t0 = -1.0
	if not oraculo:
		wipe.hide()

func _pinta_wipe() -> void:
	if wipe_t0 < 0:
		return
	var k := minf(8, floorf((M.reloj - wipe_t0) / 450.0 * 8)) / 8.0
	var h := wipe.size.y
	wipe.draw_rect(Rect2(0, h / 2 * (1 - k), wipe.size.x, h * k), Color.BLACK)

# ---------- HUD (14-render updateHUD) ----------
var hud_heat := 0
var hud_sosp := -1   # la barra de sospecha (1.10): -1 sin patrullas en el mapa
var hud_alarma := false
func hud_pon(t: String, heat: int, sosp := -1, alarma := false) -> void:
	if oraculo:
		return
	hud_txt.text = t
	hud_heat = heat
	hud_sosp = sosp
	hud_alarma = alarma
	hud.show()
	hud_bar.queue_redraw()
	_coloca.call_deferred()

func _pinta_hud_bar() -> void:
	var f := negrita
	var fs := roundi(7.5 * u)
	hud_bar.draw_string(f, Vector2(0, f.get_ascent(fs) + (9 * u - f.get_height(fs)) / 2), "CALOR", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#eef8f0"))
	var x := f.get_string_size("CALOR", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 3 * u
	var y := (9 * u - 3 * u) / 2
	hud_bar.draw_rect(Rect2(x, y, 34 * u, 3 * u), Color("#2e3a34"))
	hud_bar.draw_rect(Rect2(x, y, 34 * u * hud_heat / 100.0, 3 * u), Color("#f04040") if hud_heat >= 70 else Color("#f0a030"))
	var w := x + 34 * u
	if hud_sosp >= 0:
		var et := "¡ALARMA!" if hud_alarma else "SOSPECHA"
		hud_bar.draw_string(f, Vector2(0, 9 * u + f.get_ascent(fs) + (9 * u - f.get_height(fs)) / 2), et, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#eef8f0"))
		var x2 := f.get_string_size(et, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 3 * u
		hud_bar.draw_rect(Rect2(x2, 9 * u + y, 34 * u, 3 * u), Color("#2e3a34"))
		hud_bar.draw_rect(Rect2(x2, 9 * u + y, 34 * u * (100 if hud_alarma else hud_sosp) / 100.0, 3 * u), Color("#f04040") if hud_alarma else Color("#e8d040"))
		w = maxf(w, x2 + 34 * u)
	hud_bar.custom_minimum_size = Vector2(w, 18 * u if hud_sosp >= 0 else 9 * u)

# ---------- ficha de la carpa (vcInfo): [título, [líneas]] · una línea que empieza por «!» va en rojo ----------
var vc_lineas := []
func vc_info_pon(lineas) -> void:
	if oraculo:
		return
	if lineas == null:
		vc_info.hide()
		_coloca.call_deferred()
		return
	vc_lineas = lineas
	vc_info.show()
	vc_info_pinta()

func vc_info_pinta() -> void:
	for c in vc_info_col.get_children():
		vc_info_col.remove_child(c)
		c.queue_free()
	var t := Label.new()
	t.text = vc_lineas[0]
	pon_letra(t, negrita, 7 * u, LINEA)
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vc_info_col.add_child(t)
	var raya := ColorRect.new()
	raya.color = LINEA2
	raya.custom_minimum_size = Vector2(0, maxf(1, u))
	vc_info_col.add_child(raya)
	var h := Control.new()
	h.custom_minimum_size = Vector2(0, 1.5 * u)
	vc_info_col.add_child(h)
	for l in vc_lineas[1]:
		var n := Label.new()
		var rojo: bool = l.begins_with("!")
		n.text = l.substr(1) if rojo else l
		pon_letra(n, negrita if rojo else letra, 6.5 * u, ROJO if rojo else INK, 8.5 * u)
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		vc_info_col.add_child(n)
	_coloca.call_deferred()

# ---------- cajas del combate (13-combate bhudBuild/bhud): {e: [nombre, etiqueta, fracción, color], p: [nombre, g, fracción, color, num]} ----------
var bh := {}
func bhud_pon(datos) -> void:
	if oraculo:
		return
	if datos == null:
		bE.hide()
		bP.hide()
		return
	bh = datos
	bE.show()
	bP.show()
	bhud()

func bhud() -> void:
	if bh.is_empty():
		return
	for par in [[bE, bh.e, false], [bP, bh.p, true]]:
		var box: PanelContainer = par[0]
		var v: Array = par[1]
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.custom_minimum_size = Vector2((104 - 16) * u, 0)
		var fila := HBoxContainer.new()
		var a := Label.new()
		a.text = v[0]
		pon_letra(a, letra, 8.5 * u, INK, 11 * u)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(a)
		if par[2]:
			var g := Label.new()
			g.text = v[1]
			pon_letra(g, letra, 8.5 * u, INK, 11 * u)
			fila.add_child(g)
		col.add_child(fila)
		var hp := Control.new()
		hp.custom_minimum_size = Vector2(0, 11 * u)
		var etq: String = "VIDA" if par[2] else v[1]
		var fr: float = v[2]
		var cc: Color = v[3]
		hp.draw.connect(func():
			var fs := roundi(7.5 * u)
			hp.draw_string(negrita, Vector2(0, negrita.get_ascent(fs) + (11 * u - negrita.get_height(fs)) / 2), etq, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#d08a20"))
			var x := negrita.get_string_size(etq, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 3 * u
			var y := (11 * u - 3.5 * u) / 2
			var w := hp.size.x - x
			var sb := plana(Color("#3a3a44"), 2 * u)
			sb.draw(hp.get_canvas_item(), Rect2(x, y, w, 3.5 * u))
			if fr > 0:
				var sb2 := plana(cc, 2 * u)
				sb2.draw(hp.get_canvas_item(), Rect2(x + .6 * u, y + .6 * u, (w - 1.2 * u) * minf(1, fr), 2.3 * u)))
		col.add_child(hp)
		if par[2]:
			var n := Label.new()
			n.text = v[4]
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			pon_letra(n, letra, 8.5 * u, INK, 11 * u)
			col.add_child(n)
		box.add_child(col)
	_coloca.call_deferred()

# ---------- título (.title) ----------
func _pinta_titulo() -> void:
	var c := titulo
	var w := c.size.x
	var f := display
	var s1 := roundi(17 * u)
	var t1 := "RIBERA VERDE"
	var y := tt + f.get_ascent(s1)
	var x := (w - f.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1).x) / 2
	c.draw_string(f, Vector2(x + 3 * u, y + 3 * u), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("#10301c"))
	c.draw_string(f, Vector2(x + 1.5 * u, y + 1.5 * u), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("#2a7a40"))
	c.draw_string(f, Vector2(x, y), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("#ffe680"))
	var s2 := roundi(10 * u)
	var t2 := "genética de barrio"
	y += 17 * u * .15 + 5 * u + f.get_ascent(s2) + 2 * u
	x = (w - f.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, s2).x) / 2
	c.draw_string(f, Vector2(x + 3 * u, y + 3 * u), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color("#10301c"))
	c.draw_string(f, Vector2(x + 1.5 * u, y + 1.5 * u), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color("#2a7a40"))
	c.draw_string(f, Vector2(x, y), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color("#9cf0a8"))
	var s3 := roundi(8 * u)
	var t3 := "Cultiva · Cruza · Vende · Sobrevive"
	y += 6 * u + letra.get_ascent(s3) + 3 * u
	x = (w - letra.get_string_size(t3, HORIZONTAL_ALIGNMENT_LEFT, -1, s3).x) / 2
	c.draw_string(letra, Vector2(x + u, y + u), t3, HORIZONTAL_ALIGNMENT_LEFT, -1, s3, Color("#10301c"))
	c.draw_string(letra, Vector2(x, y), t3, HORIZONTAL_ALIGNMENT_LEFT, -1, s3, Color("#d8f0e0"))
	if int(M.reloj / 500) % 2 == 0:
		var s4 := roundi(9.5 * u)
		var t4 := "P U L S A   S T A R T"
		var y4 := c.size.y - 14 * u
		x = (w - negrita.get_string_size(t4, HORIZONTAL_ALIGNMENT_LEFT, -1, s4).x) / 2
		c.draw_string(negrita, Vector2(x + u, y4 + u), t4, HORIZONTAL_ALIGNMENT_LEFT, -1, s4, Color.BLACK)
		c.draw_string(negrita, Vector2(x, y4), t4, HORIZONTAL_ALIGNMENT_LEFT, -1, s4, Color.WHITE)

# ---------- carta final (.endcard): [título, línea, …] ----------
var endcard_t := []
func endcard_pon(t) -> void:
	if oraculo:
		return
	if t == null:
		endcard.hide()
		return
	endcard_t = t
	endcard.show()
	_pinta_endcard()

func _pinta_endcard() -> void:
	for c in endcard_col.get_children():
		endcard_col.remove_child(c)
		c.queue_free()
	endcard_col.position = Vector2(12 * u, 12 * u)
	endcard_col.size = endcard.size - Vector2(24 * u, 24 * u)
	endcard_col.add_theme_constant_override("separation", roundi(6 * u))
	for k in endcard_t.size():
		var l := Label.new()
		l.text = endcard_t[k]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(endcard_col.size.x, 0)
		if k == 0:
			pon_letra(l, display, 14 * u, Color("#ffe680"), 0, false)
		else:
			pon_letra(l, letra, 9 * u, Color("#e8f8ec") if k < endcard_t.size() - 1 else Color(.91, .97, .93, .7), 13 * u, false)
		endcard_col.add_child(l)

func _process_ui() -> void:
	if oraculo:
		return
	# el botón MÓVIL solo sirve andando por el mapa (verMovil en el HTML)
	botones.MOVIL.visible = mode == "world"
	if dlg_more.visible:
		dlg_more.queue_redraw()
	if titulo.visible:
		titulo.queue_redraw()
	if wipe.visible:
		wipe.queue_redraw()
