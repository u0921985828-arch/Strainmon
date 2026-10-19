# Ribera Verde (Godot) — la pantalla, los mandos y la interfaz del HTML (06-controles, 06b-pantalla, 07-interfaz, styles.css):
# el juego se pinta en un SubViewport de SW × SH (SH = 180; SW de 240 a SW_MAX, como ajustarPantalla) y encima, a la resolución del móvil,
# van el HUD, la escena de 240 (título, cajas del combate y ficha de la carpa), los diálogos, los menús y los avisos (el
# escenario .ui, que encoge para caber entre los mandos), la carta final, el fundido, la cortinilla y los mandos flotantes.
# Los guiones son corrutinas: say/ask/menu esperan a una promesa (Motor.Prom) que resuelve el manejador de la pila (push/pop),
# como en el HTML. El reloj (M) es el bucle de eventos del navegador: setTimeout/setInterval y las esperas.
# Base de la cadena ui → mundo → granja → trama → juego: lo que se define más abajo se declara aquí vacío (virtual).
extends Control

const Datos = preload("res://src/datos.gd")
const I18n = preload("res://src/i18n.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Motor = preload("res://src/motor.gd")
const SH := 180   # 1.12: alto del juego; el ancho, de 240 a SW_MAX
const SW_MAX := 450
const Atlas = preload("res://src/atlas.gd")
const Sonido = preload("res://src/sonido.gd")
const VistaC = preload("res://src/vista.gd")
const Retrato = preload("res://src/retrato.gd")

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
var gancho_pedir := Callable()    # (texto, inicial, máx, cancela) → texto o null · las pruebas escriben en la caja de texto
var gancho_combate := Callable() # (tipo) · las pruebas cambian el combate por una función (window.battle en el HTML)
var gancho_billar := Callable()  # (texto) → de 0 a 1 · las pruebas cambian el tiro del billar (window.tiroBillar, 1.30)
var gancho_almacen := Callable() # (caja | nevera) → el elegido o null · las pruebas eligen en la vista de la caja y la nevera (1.36, window.elegirAlmacen)
var gancho_carro := Callable()   # () → el taco elegido o null · las pruebas eligen en la vista del carro de esquejes (1.40)
var gancho_bajo := Callable()    # (i) → la bandeja elegida o null · las pruebas eligen en las baldas del bajo de las setas (1.43.9)

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
var retrato := TextureRect.new()   # MAESTRO [8]: el retrato de quien habla (PortraitRect), dentro de la caja, a la izquierda
var retrato_l = null               # [look, mujer] de quien habla ahora
var habla_look = null              # el look de la persona con la que hablas en vivo (hablar_con)
var dlg_more := Control.new()
var menu_box := PanelContainer.new()
var menu_col := VBoxContainer.new()
var name_box := PanelContainer.new()
var name_in := LineEdit.new()
var name_lbl := Label.new()
var name_small := Label.new()
# E9 (fase 3): la caja de importar la partida, de varias líneas y con PEGAR (el portapapeles, solo al tocarlo)
var import_box := PanelContainer.new()
var import_te := TextEdit.new()
var import_pegar := Button.new()
var import_small := Label.new()
var name_mayus := false
var lector := PanelContainer.new()   # textos largos con scroll (créditos, licencias, privacidad): leer()
var lector_ttl := Label.new()
var lector_pie := Label.new()
var lector_sc := ScrollContainer.new()
var lector_txt := Label.new()
var lector_pags: Array[String] = []   # el texto entero, en páginas de ~3.500 letras (◀ ▶)
var lector_i := 0
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
var scr := Rect2(0, 0, 240, SH)
const CRUZ_HUECO := .16   # el hueco entre cada flecha y el cuadrado del medio, en brazos de la cruz (1.40)
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
	sv.size = Vector2i(SW, SH)
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
	hud_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE   # 1.50: el recuadro del dinero y lo que llevas encima
	hud_tab.draw.connect(_pinta_hud_tab)
	hud_col.add_child(hud_tab)
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
	retrato.name = "PortraitRect"   # i18n-no
	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	retrato.stretch_mode = TextureRect.STRETCH_SCALE
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(retrato)
	dlg_nm.visibility_changed.connect(func():
		if not dlg_nm.visible:
			retrato.hide())
	dlg.visibility_changed.connect(func():
		if not dlg.visible:
			retrato.hide())
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
	name_lbl.text = I18n.v("¿Cómo te llamas?")
	nc.add_child(name_lbl)
	name_in.max_length = 8
	nc.add_child(name_in)
	name_in.text_changed.connect(func(t: String):   # en mayúsculas (el nombre del jugador), como text-transform en el HTML
		if name_mayus and t != t.to_upper():
			var cc := name_in.caret_column
			name_in.text = t.to_upper()
			name_in.caret_column = cc)
	name_small.text = I18n.v("Pulsa A para aceptar")
	nc.add_child(name_small)
	name_in.focus_exited.connect(func():   # con la caja abierta, el foco se queda en ella (las teclas no vuelven al juego)
		if name_box.visible:
			name_in.grab_focus.call_deferred())
	add_child(name_box)
	var ic := VBoxContainer.new()
	import_box.add_child(ic)
	var it := Label.new()
	it.text = I18n.v("Pega aquí la partida exportada")
	ic.add_child(it)
	import_te.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	ic.add_child(import_te)
	var ih := HBoxContainer.new()
	ic.add_child(ih)
	import_pegar.text = I18n.v("PEGAR")
	import_pegar.focus_mode = Control.FOCUS_NONE
	import_pegar.pressed.connect(pegar_partida)
	ih.add_child(import_pegar)
	import_small.text = I18n.v("A: cargar · B: cancelar")
	ih.add_child(import_small)
	import_box.hide()
	add_child(import_box)
	var lc := VBoxContainer.new()
	var lt := HBoxContainer.new()
	lector.add_child(lc)
	lc.add_child(lt)
	lt.add_child(lector_ttl)
	lector_ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lt.add_child(lector_pie)
	lector_pie.text = I18n.v("▲▼ · B VOLVER")
	lc.add_child(lector_sc)
	lector_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lector_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lector_sc.add_child(lector_txt)
	lector_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lector_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lector.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(lector)
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
	for n in [hud, titulo, bE, bP, vc_info, toast_box, dlg, dlg_nm, retrato, dlg_more, menu_box, name_box, lector, endcard, wipe]:
		n.hide()
	_mandos()
	sonido = Sonido.new()
	add_child(sonido)
	ajustes_carga()
	get_viewport().size_changed.connect(ajusta)
	ajusta()

func _fuente(f: String, suave := true) -> FontFile:
	return _fuente_de(f, suave)

static func _fuente_de(f: String, suave := true) -> FontFile:
	var o := FontFile.new()
	o.data = FileAccess.get_file_as_bytes("res://fuentes/" + f)
	o.antialiasing = TextServer.FONT_ANTIALIASING_GRAY if suave else TextServer.FONT_ANTIALIASING_NONE
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["sans-serif"])
	# MAESTRO [10]: flechas, ▲▼◀▶, ★, ≈ y − de una letra de reserva propia (DejaVu, subconjunto), no de la del móvil
	var sim := FontFile.new()
	sim.data = FileAccess.get_file_as_bytes("res://fuentes/dejavu-sans-simbolos.woff2")
	sim.antialiasing = o.antialiasing
	o.fallbacks = [sim, sf]
	return o

# ---------- pantalla y mandos (06b-pantalla.js) ----------
# Para las pruebas de los mandos por móvil (tests/mandos_geo.gd): los ppp y la zona segura de un móvil de verdad
static var DPI_PRUEBA := 0.0
static var ZONA_PRUEBA := []
static func es_movil() -> bool:
	return DPI_PRUEBA > 0 or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

func _zona_segura() -> Array:
	if ZONA_PRUEBA.size() == 4:
		return ZONA_PRUEBA
	if not OS.has_feature("mobile"):
		return [0.0, 0.0, 0.0, 0.0]
	var r := Rect2(DisplayServer.get_display_safe_area())
	var v := Rect2(Vector2(DisplayServer.window_get_position()), get_viewport_rect().size)
	return [maxf(0, r.position.x - v.position.x), maxf(0, v.end.x - r.end.x), maxf(0, r.position.y - v.position.y), maxf(0, v.end.y - r.end.y)]

# px de pantalla por px CSS: por los ppp del móvil y, si el sistema no los da bien (escritorio, Xvfb), como un móvil en
# horizontal, que mide 360-430 px CSS de alto
func _dp(antes := false) -> float:
	if Datos.CAL and es_movil() and not antes:   # 1.57: en el móvil (y la tableta), por los ppp de verdad: los mandos, en mm, del tamaño del pulgar
		var dpi: float = DPI_PRUEBA if DPI_PRUEBA > 0 else float(DisplayServer.screen_get_dpi())
		var hh: float = get_viewport_rect().size.y
		if dpi >= 100:
			return clampf(dpi / 160.0, hh / 1000.0, hh / 280.0)
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
	var s := h / SH
	var k := floorf(s)
	if k >= 2 and (k >= s * .94 or Datos.CAL):   # R11: con CAL, siempre entera (a 720p, 3 y no 3,93: los píxeles no bailan), con borde
		s = k
	var nsw := clampi(int(floor(w / s / 2)) * 2, 240, SW_MAX)
	if nsw * s > w:
		s = w / nsw
	u = s
	if nsw != SW:
		SW = nsw
		sv.size = Vector2i(SW, SH)
	var cw := floorf(SW * s)
	var ch := floorf(SH * s)
	var x := roundf(zl + rim + (w - cw) / 2)
	var y := roundf(zt + rim + (h - ch) / 2)
	scr = Rect2(x, y, cw, ch)
	pantalla.position = Vector2(x, y)
	pantalla.size = Vector2(cw, ch)
	# mandos en mm (geo_mandos): se calculan en px CSS, como el HTML, y se pasan a px de pantalla
	var us_min := minf(s, maxf(s * .5, 1.3 * dp))
	var G: Dictionary = geo_mandos(V.x / dp, V.y / dp, zl / dp, zr / dp, zt / dp, zb / dp, 120 * us_min / dp)
	if Datos.CAL and es_movil():   # 1.57: en el móvil y la tableta (táctiles), por los pulgares, y nunca más pequeños que los de antes
		var da := _dp(true)
		var Ga: Dictionary = G if da == dp else geo_mandos(V.x / da, V.y / da, zl / da, zr / da, zt / da, zb / da, 120 * minf(s, maxf(s * .5, 1.3 * da)) / da)
		var fmin := maxf(Ga.A.size.x / (PUL.ab * MM), Ga.cruz.size.x / (PUL.cruz * MM)) * da / dp
		G = geo_pulgar(V.x / dp, V.y / dp, zl / dp, zr / dp, zt / dp, zb / dp, 120 * us_min / dp, fmin)
	pulgar_f = G.get("f", 1.0)
	for n in ["dpad", "cruz", "ab", "A", "B", "start", "movil", "sonido"]:
		G[n] = Rect2(G[n].position * dp, G[n].size * dp)
	if Datos.PLAY and aj.get("zurdo", false):   # U5: ZURDO, la cruceta a la derecha y A/B a la izquierda (en espejo)
		for n in ["dpad", "cruz", "ab", "A", "B", "start", "movil"]:
			var r: Rect2 = G[n]
			G[n] = Rect2(V.x - r.end.x, r.position.y, r.size.x, r.size.y)
	var kp: float = G.k * dp
	us = clampf(G.med * dp / 120, us_min, s)
	uiw = minf(cw, roundf(240 * us))
	zona_cruz = G.dpad
	zona_ab = G.ab
	cruz = G.cruz
	var a: float = cruz.size.x / 3
	# (lo pidió el usuario: «más ergonómicos, más espaciadas las flechas del cuadrado del medio»): cada flecha, una tecla suelta
	# con sus cuatro esquinas redondas, separada del cuadrado del medio por CRUZ_HUECO del brazo; el toque sigue siendo por ángulo
	var g: float = roundf(a * CRUZ_HUECO)
	for b in ["up", "down", "left", "right"]:
		_estilo(botones[b], Color(24 / 255.0, 28 / 255.0, 34 / 255.0, .5), Color(70 / 255.0, 80 / 255.0, 96 / 255.0, .75), Color(1, 1, 1, .22), kp * 1.6, kp * 2.4, "")
	var st := StyleBoxFlat.new()
	st.bg_color = Color(24 / 255.0, 28 / 255.0, 34 / 255.0, .35)
	st.border_color = Color(1, 1, 1, .14)
	st.set_border_width_all(maxi(1, roundi(1.5 * _dp())))
	st.set_corner_radius_all(roundi(kp * 1.2))
	botones.mid.add_theme_stylebox_override("panel", st)
	for b in ["A", "B"]:
		_estilo(botones[b], Color(109 / 255.0, 44 / 255.0, 75 / 255.0, .55), Color(154 / 255.0, 74 / 255.0, 114 / 255.0, .85), Color(1, 210 / 255.0, 230 / 255.0, .4), G.A.size.x / 2, kp * 3.8, "")
	for b in ["START", "MOVIL", "SONIDO"]:   # i18n-no
		_estilo(botones[b], Color(24 / 255.0, 28 / 255.0, 34 / 255.0, .55), Color(70 / 255.0, 80 / 255.0, 96 / 255.0, .75), Color(1, 1, 1, .22), kp * 3.5, kp * 2.6, "")
	# después de la letra: un botón no encoge por debajo de lo que pide la letra que tenía (de una ventana más grande)
	_pon(botones.up, cruz.position + Vector2(a, 0), Vector2(a, a - g))
	_pon(botones.left, cruz.position + Vector2(0, a), Vector2(a - g, a))
	_pon(botones.right, cruz.position + Vector2(a * 2 + g, a), Vector2(a - g, a))
	_pon(botones.down, cruz.position + Vector2(a, a * 2 + g), Vector2(a, a - g))
	_pon(botones.mid, cruz.position + Vector2(a + g, a + g), Vector2(a - 2 * g, a - 2 * g))
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
	# el rótulo del título (LANDRACE / HUNTERS en dos líneas: 144 u de ancho con la sombra) baja si SONIDO le pisa la esquina (--tt en el HTML), desde ye: la escena
	# de 240 × 160, abajo
	var ye := y + ch - 160 * s
	tt = maxf(4 * s, roundf(so.end.y - ye + kp * 1.5)) if so.position.x < x + cw / 2 + 73 * s and so.end.y > ye + 4 * s else 4 * s
	# caja de vida del jugador en el combate (bP, abajo a la derecha de la escena, ~46 u de alto): a la izquierda de A, B y START
	# si le caen encima (--bpr en el HTML)
	var er := x + cw / 2 + 120 * s
	var bb := y + ch - 49 * s
	bp_r = 6 * s
	for n in ["A", "B", "start", "cruz"]:
		var r: Rect2 = G[n]
		if r.position.y < bb + kp and r.end.y > bb - 46 * s - kp:
			bp_r = maxf(bp_r, er - r.position.x + kp)
	bp_r = roundf(minf(bp_r, 130 * s))
	for n in [fade_el, wipe, endcard]:
		_pon(n, scr.position, scr.size)
	_pon(escena, Vector2(x + cw / 2 - 120 * u, ye), Vector2(240 * u, 160 * u))
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

# (lo pidió el usuario: «que sean lo mejor para jugar con el móvil en horizontal, estudiando en qué zonas caen los dedos»): los
# mandos donde descansan los pulgares con el móvil cogido con las dos manos, en mm desde el canto de verdad del móvil (el pulgar no sabe
# de muescas) y sin salirse de la zona segura (muesca, isla, esquinas redondas, la barra de inicio de iOS):
#   - el pulgar apoya a unos 25 mm del canto y 20-30 mm del borde de abajo; gira desde la base (la esquina de abajo), así que A y B van
#     en diagonal, siguiendo su arco: B más abajo y hacia dentro, A más arriba y hacia fuera
#   - nada a menos de PUL.canto mm del canto de los lados (el gesto de Atrás de Android nace ahí) ni de PUL.abajo del de abajo (la barra
#     de inicio de iOS y los gestos de Android)
#   - teclas de 10 mm en la cruz (30 mm entera) y de 14 mm en A y B (Android pide 48 dp ≈ 7,6 mm e iOS 44 pt ≈ 7 mm; en un juego,
#     más), separadas para no pisar dos; y el toque, en una zona mayor que el dibujo (ZONA)
#   - START y MÓVIL, menos usados, juntos encima de A y B (MÓVIL al lado de START o, en una pantalla más cuadrada, encima), fuera del arco de descanso (a la izquierda, arriba, va el recuadro del HUD);
#     SONIDO, arriba a la derecha
# Si no cabe al lado de la escena de diálogos (un móvil pequeño), primero se arriman al canto (hasta su margen) y después encogen,
# hasta PUL.min (nunca por debajo de los de antes, geo_mandos: en la tableta salen más grandes, fmin); si ni así, se quedan en PUL.min y la caja del texto queda un poco por debajo de ellos
const PUL := {"cruz": 30.0, "cx": 25.0, "cy": 24.0, "ab": 14.0, "ax": 18.0, "ay": 28.0, "bdx": -17.5, "bdy": 8.5, "canto": 9.0, "abajo": 8.0,
	"tecla": [17.0, 9.0], "zona": 7.0, "min": 0.8}
var pulgar_f := 1.0   # el tamaño de los mandos por los pulgares (1: el de PUL)
func geo_pulgar(W: float, H: float, il: float, ir: float, it: float, ib: float, med: float, fmin := 0.0) -> Dictionary:
	var c := (W + il - ir) / 2
	var mide := func(f: float, fp: float, pila := false) -> Dictionary:   # f, el tamaño; fp, lo lejos del canto (1: donde descansa el pulgar; 0: al margen)
		var s := f * MM
		var hc: float = PUL.cruz * s / 2
		var ha: float = PUL.ab * s / 2
		var tw: float = PUL.tecla[0] * s
		var th: float = PUL.tecla[1] * s
		# la cruz: a cx del canto, sin pasar del margen del canto ni de la zona segura
		var mi := maxf(PUL.canto * MM, il + 2 * MM) + hc
		var cx := maxf(lerpf(mi, PUL.cx * MM, fp), mi)
		var ab := minf(H - PUL.abajo * MM, H - ib - 2 * MM) - hc
		var cy := minf(lerpf(ab, H - PUL.cy * MM, fp), ab)
		var md := minf(W - PUL.canto * MM, W - ir - 2 * MM) - ha
		var ax := minf(lerpf(md, W - PUL.ax * MM, fp), md)
		var aa := minf(H - PUL.abajo * MM, H - ib - 2 * MM) - ha - PUL.bdy * s
		var ay := minf(lerpf(aa, H - PUL.ay * MM, fp), aa)
		var bx: float = ax + PUL.bdx * s
		var by: float = ay + PUL.bdy * s
		var st := Vector2(ax - 2 * s, ay - ha - 4 * s - th / 2)
		var mv := Vector2(st.x, st.y - th - 3 * s) if pila else Vector2(st.x - tw - 3 * s, st.y)   # al lado de START o, si no cabe, encima
		var so := Rect2(W - ir - 3 * s - tw, it + 3 * s, tw, th)
		return {"s": s, "hc": hc, "ha": ha, "tw": tw, "th": th, "cx": cx, "cy": cy, "ax": ax, "ay": ay, "bx": bx, "by": by, "mv": mv, "st": st, "so": so,
			"izq": cx + hc + 2 * s, "der": W - minf(bx - ha, mv.x - tw / 2) + 2 * s, "arriba": mv.y - th / 2}
	var cabe := func(g: Dictionary) -> bool:
		return g.izq + med <= c and g.der + med <= W - c and g.arriba >= it + 1 * MM and g.arriba >= g.so.end.y + 2.5 * MM
	var f := maxf(1.0, fmin)
	var fp := 1.0
	var prueba := func(f: float, fp: float) -> Dictionary:   # MÓVIL al lado de START y, si así no cabe, encima
		var g1: Dictionary = mide.call(f, fp)
		return g1 if cabe.call(g1) else mide.call(f, fp, true)
	var g: Dictionary = prueba.call(f, fp)
	while fp > 0 and not cabe.call(g):
		fp = maxf(0, fp - .05)
		g = prueba.call(f, fp)
	while f > maxf(PUL.min, fmin) + .001 and not cabe.call(g):
		f -= .01
		g = prueba.call(f, fp)
	var s: float = g.s
	var R := func(x: float, y: float, w: float, h: float) -> Rect2: return Rect2(Datos.jsround(x), Datos.jsround(y), Datos.jsround(w), Datos.jsround(h))
	var z: float = PUL.zona * s
	var hc: float = g.hc
	var ha: float = g.ha
	var ab := Rect2(minf(g.ax, g.bx) - ha - z, g.ay - ha - z, absf(g.ax - g.bx) + 2 * ha + 2 * z, g.by - g.ay + 2 * ha + 2 * z)
	var m: float = minf(c - g.izq, W - g.der - c)
	var lim := maxf(0, minf(med, m))   # las zonas, sin entrar en el escenario de diálogos
	ab = ab.intersection(Rect2(c + lim, g.st.y + g.th / 2 + 1 * s, W - c - lim, H))   # y por debajo de START y MÓVIL (la zona manda al tocar)
	var dp := Rect2(g.cx - hc - z, g.cy - hc - z, 2 * hc + 2 * z, 2 * hc + 2 * z).intersection(Rect2(0, 0, c - lim, H))
	return {"f": f, "k": s, "med": m,
		"dpad": R.call(dp.position.x, dp.position.y, dp.size.x, dp.size.y), "cruz": R.call(g.cx - hc, g.cy - hc, 2 * hc, 2 * hc),
		"ab": R.call(ab.position.x, ab.position.y, ab.size.x, ab.size.y), "A": R.call(g.ax - ha, g.ay - ha, 2 * ha, 2 * ha), "B": R.call(g.bx - ha, g.by - ha, 2 * ha, 2 * ha),
		"start": R.call(g.st.x - g.tw / 2, g.st.y - g.th / 2, g.tw, g.th), "movil": R.call(g.mv.x - g.tw / 2, g.mv.y - g.th / 2, g.tw, g.th),
		"sonido": R.call(g.so.position.x, g.so.position.y, g.so.size.x, g.so.size.y)}

# rectángulo del escenario .ui (en px de pantalla)
# Lo que queda libre del lienzo (en píxeles del juego) por encima del cuadro del texto, para centrar ahí el calendario y el mapa
func alto_libre() -> int:
	if oraculo or not dlg.visible or u <= 0:
		return SH - 47
	return clampi(int(floor((dlg_nm.position.y if dlg_nm.visible else dlg.position.y) - scr.position.y) / u) - 1, 40, SH)

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
	var ft := fs_txt(10 * us)
	pon_letra(dlg_txt, letra, ft, INK, 13.5 * us * ft / (10 * us))
	dlg_nm.add_theme_stylebox_override("panel", plana(LINEA, 3 * us, 2.5 * us, 5 * us))
	pon_letra(dlg_nm_txt, negrita, 8 * us, Color.WHITE, 0, false)
	caja_menu = caja(us, 5, 7)
	menu_box.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if menu_box.get_meta("cls", "") == "titulo" else caja_menu)
	toast_box.add_theme_stylebox_override("panel", caja(us, 4, 10))
	var fo := fs_txt(9 * us)
	pon_letra(toast_txt, letra, fo, INK)
	toast_txt.add_theme_font_override("bold_font", negrita)
	toast_txt.add_theme_constant_override("line_separation", roundi(12 * us * fo / (9 * us) - letra.get_height(roundi(fo))))
	hud.add_theme_stylebox_override("panel", plana(Color(16 / 255.0, 28 / 255.0, 22 / 255.0, .78), HUD_R * u, HUD_PV * u, HUD_PH * u))
	hud_txt.add_theme_font_override("normal_font", negrita)
	hud_txt.add_theme_font_size_override("normal_font_size", maxi(5, roundi(HUD_FS * u)))
	hud_txt.add_theme_color_override("default_color", Color("#eef8f0"))
	hud_txt.add_theme_constant_override("line_separation", roundi(HUD_LH * u - negrita.get_height(roundi(HUD_FS * u))))
	hud_bar.custom_minimum_size = Vector2(0, HUD_LH * u)
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
	import_box.add_theme_stylebox_override("panel", caja(us, 8, 10))
	var ic: VBoxContainer = import_box.get_child(0)
	ic.add_theme_constant_override("separation", roundi(5 * us))
	pon_letra(ic.get_child(0), letra, 9 * us, INK)
	pon_letra(import_te, letra, 7 * us, INK, 0, false)
	import_te.custom_minimum_size = Vector2(160 * us, 40 * us)
	pon_letra(import_pegar, letra, 8 * us, INK, 0, false)
	import_pegar.custom_minimum_size = Vector2(48 * us, 16 * us)
	pon_letra(import_small, letra, 7 * us, GRIS, 0, false)
	lector.add_theme_stylebox_override("panel", caja(us, 5, 7))
	lector.get_child(0).add_theme_constant_override("separation", roundi(4 * us))
	pon_letra(lector_ttl, negrita, 9 * us, LINEA, 0, false)
	pon_letra(lector_pie, letra, 7 * us, GRIS, 0, false)
	var fl := fs_txt(9 * us)
	pon_letra(lector_txt, letra, fl, INK, 12.5 * us * fl / (9 * us), false)
	if endcard.visible:
		_pinta_endcard()
	if vc_info.visible:
		vc_info_pinta()
	if bE.visible:
		bhud()

func _mandos() -> void:
	for b in [["up", ""], ["down", ""], ["left", ""], ["right", ""], ["A", "A"], ["B", "B"], ["START", "START"], ["MOVIL", K("MÓVIL")], ["SONIDO", K("SONIDO")]]:   # START: igual en los dos idiomas · i18n-no
		var n := Button.new()
		n.text = I18n.v(b[1])
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
	KEY_M: "START", KEY_TAB: "START", KEY_P: "MOVIL"}   # i18n-no
const DIRS := ["up", "down", "left", "right"]

func set_held(b: String, v: bool) -> void:
	if held.has(b):
		held[b] = v
		if b in DIRS:
			dir_order.erase(b)
			if v:
				dir_order.append(b)

# R14: el mando de juego (la cruceta o el stick izquierdo, A/B, START y Y = MÓVIL)
const BOTONES_JOY := {JOY_BUTTON_DPAD_UP: "up", JOY_BUTTON_DPAD_DOWN: "down", JOY_BUTTON_DPAD_LEFT: "left", JOY_BUTTON_DPAD_RIGHT: "right",
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_START: "START", JOY_BUTTON_BACK: "B", JOY_BUTTON_Y: "MOVIL"}   # i18n-no
var stick := ""
func _joy(e: InputEvent) -> void:
	if (name_box.visible and name_in.has_focus()) or (import_box.visible and import_te.has_focus()):
		return
	if e is InputEventJoypadButton and BOTONES_JOY.has(e.button_index):
		var b: String = BOTONES_JOY[e.button_index]
		get_viewport().set_input_as_handled()
		set_held(b, e.pressed)
		if e.pressed:
			press(b)
	elif e is InputEventJoypadMotion and (e.axis == JOY_AXIS_LEFT_X or e.axis == JOY_AXIS_LEFT_Y):
		var v := Vector2(Input.get_joy_axis(e.device, JOY_AXIS_LEFT_X), Input.get_joy_axis(e.device, JOY_AXIS_LEFT_Y))
		var d := ""
		if v.length() > .5:
			d = ("right" if v.x > 0 else "left") if absf(v.x) > absf(v.y) else ("down" if v.y > 0 else "up")
		if d != stick:
			if stick != "":
				set_held(stick, false)
			stick = d
			if d != "":
				set_held(d, true)
				press(d)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventJoypadButton or e is InputEventJoypadMotion:
		_joy(e)
		return
	if not (e is InputEventKey) or not TECLAS.has(e.keycode):
		return
	if (name_box.visible and name_in.has_focus()) or (import_box.visible and import_te.has_focus()):
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
	if (name_box.visible or import_box.visible) and e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE:   # Esc = B en la caja de texto
		get_viewport().set_input_as_handled()
		press("B")
		return
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
			if Datos.CAL:   # 1.57: un dedo nuevo en la cruceta manda; el que se quedó colgado (sin soltar) se suelta
				for d0 in dedos_cruz.keys():
					if dedos_cruz[d0] != "":
						aprieta(dedos_cruz[d0], false)
				dedos_cruz.clear()
			if dedos_cruz.is_empty():
				dedos_cruz[dedo] = ""
				_cruz_a(dedo, e.position)
			return
		var k := mando_en(e.position)
		if k != "":
			get_viewport().set_input_as_handled()
			if Datos.CAL:   # 1.57: el mismo dedo (Android repite los números) o el mismo mando colgados, fuera
				if dedos.has(dedo) and dedos[dedo] != k:
					var k0: String = dedos[dedo]
					dedos.erase(dedo)
					if not dedos.values().has(k0):
						aprieta(k0, false)
				for d0 in dedos.keys():
					if dedos[d0] == k:
						dedos.erase(d0)
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

# Al deslizar de una flecha a la de al lado, la nueva tiene que ganar por CRUZ_HISTERESIS (unos 11° pasada la diagonal):
# el pulgar sobre la diagonal ya no hace zigzag
const CRUZ_HISTERESIS := 1.4
func dir_cruz(p: Vector2, actual: String) -> String:
	var v := p - cruz.get_center()
	if v.length() < cruz.size.x / 3 * .42:
		return actual
	var h := absf(v.x) > absf(v.y)
	if Datos.CAL and actual != "":
		var ah: bool = actual == "left" or actual == "right"
		if ah and not h and absf(v.y) < absf(v.x) * CRUZ_HISTERESIS:
			h = true
		elif not ah and h and absf(v.x) < absf(v.y) * CRUZ_HISTERESIS:
			h = false
	if h:
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
	# START, MÓVIL y SONIDO se tocan en 48 × 48 dp como poco (el mínimo de Android), aunque se vean más pequeños
	var m := 48 * _dp()
	for k in ["START", "MOVIL", "SONIDO"]:   # i18n-no
		var r: Rect2 = botones[k].get_global_rect()
		var gx := maxf(0, (m - r.size.x) / 2)
		var gy := maxf(0, (m - r.size.y) / 2)
		if botones[k].visible and (r.has_point(p) or r.grow_individual(gx, gy, gx, gy).has_point(p) and not tapa(p)):
			return k
	return ""

# lo que hay abierto en el escenario (menú, diálogo o lector) manda sobre el margen de 48 dp de los mandos
func tapa(p: Vector2) -> bool:
	for c in [menu_box, dlg, lector]:
		if c.visible and c.get_global_rect().has_point(p):
			return true
	return false

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
		vibra()
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

# Un toque corto del vibrador al apretar un mando (OPCIONES → VIBRACIÓN), en el móvil
func vibra() -> void:
	if Datos.CAL and aj.get("vibra", true) and not oraculo and OS.has_feature("mobile"):
		Input.vibrate_handheld(12)

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

# texto a mano (1.11, pedirTexto de 07-interfaz): el nombre del jugador, de una planta o de una variedad propia. A (o Intro) acepta;
# B (o Esc) cancela y da null. Solo letras, números, espacio y # ' . - (limpiaTexto)
static func limpia_texto(s: String, mx: int) -> String:
	return RegEx.create_from_string("[^\\p{L}\\p{N} #'.\\-]").sub(s, "", true).strip_edges().substr(0, mx)

func pedir_texto(txt: String, ini := "", mx := 12, mayus := false, cancela := true, crudo := false):   # crudo (1.22): el texto tal cual (la partida importada)
	if gancho_pedir.is_valid():
		return gancho_pedir.call(txt, ini, mx, cancela)
	var pr := Motor.Prom.new()
	name_lbl.text = I18n.v(txt)
	name_small.text = I18n.v("Pulsa A para aceptar y B para cancelar") if cancela else I18n.v("Pulsa A para aceptar")
	name_mayus = mayus
	name_in.max_length = mx
	name_in.text = ini
	name_box.show()
	_coloca()
	name_in.grab_focus.call_deferred()
	push(func(b: String):
		if b == "A" or (b == "B" and cancela):
			var v = (name_in.text.strip_edges() if crudo else limpia_texto(name_in.text, mx)) if b == "A" else null
			name_box.hide()
			name_in.release_focus()
			pop()
			pr.res(v))
	return await Motor.espera(pr)

const IMPORTA_MAX := 1000000   # E9: una partida guardada no llega a 1 MB

# E9: el texto de la partida que se importa, en una caja de varias líneas; A carga, B cancela (null)
func pedir_partida(txt: String):
	if gancho_pedir.is_valid():
		return gancho_pedir.call(txt, "", IMPORTA_MAX, true)
	var pr := Motor.Prom.new()
	import_te.text = ""
	import_small.text = I18n.v("A: cargar · B: cancelar")
	import_box.show()
	_coloca()
	import_te.grab_focus.call_deferred()
	push(func(b: String):
		if b == "A" or b == "B":
			var v = import_te.text.strip_edges() if b == "A" else null
			if v != null and v.length() > IMPORTA_MAX:
				import_small.text = I18n.v("Demasiado largo para ser una partida.")
				return
			import_box.hide()
			import_te.release_focus()
			import_te.text = ""
			pop()
			pr.res(v))
	return await Motor.espera(pr)

# PEGAR: el portapapeles, solo al tocarlo (Android 12+ avisa de cada lectura)
func pegar_partida() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		return
	var t := DisplayServer.clipboard_get().strip_edges()
	if t.length() > IMPORTA_MAX:
		import_small.text = I18n.v("Demasiado largo para ser una partida.")
		return
	import_te.text = t

func push(fn: Callable) -> void:
	handlers.append(fn)

# pop(fn): quita ese manejador aunque otro se haya puesto encima (E13); sin fn, el de arriba
func pop(fn := Callable()) -> void:
	if fn.is_valid() and handlers.has(fn):
		handlers.erase(fn)
	else:
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

func set_sound(on: bool, guarda := true) -> void:
	if sonido:
		sonido.set_on(on)
		botones.SONIDO.text = I18n.v("SONIDO") if on else I18n.v("SILENCIO")
		botones.SONIDO.set_pressed_no_signal(not on)
	aj.sonido = on
	if guarda:
		ajustes_guarda()

# ---------- ajustes de la app (solo Godot): el aviso de edad aceptado, el volumen de la música y de los efectos (de 0 a 4,
# de 25 en 25 %), la velocidad del texto y SONIDO; en un archivo aparte de la partida, que no los borra ----------
static var AJUSTES := "user://ajustes.json"   # las pruebas usan otro
var TEXTO_VEL := [I18n.K("NORMAL"), I18n.K("RÁPIDO"), I18n.K("AL MOMENTO")]   # F7: var, por K()
var aj := {"aviso": false, "musica": 4, "efectos": 4, "texto": 0, "sonido": true, "vibra": true, "ahorro": false, "tam": 1, "zurdo": false, "dalt": false, "calma": false, "avisos": false, "errores": false, "completo": false, "idioma": 0}
# U5 (fase 5, con Datos.PLAY): TAMAÑO DE TEXTO S/M/L, nunca por debajo de TXT_MIN sp
const TAM_TXT := [0.85, 1.0, 1.25]
const TAM_NOM := ["S", "M", "L"]
const TXT_MIN := 14.0
func fs_txt(px: float) -> float:
	if not Datos.PLAY:
		return px
	return maxf(px * TAM_TXT[clampi(int(aj.get("tam", 1)), 0, 2)], TXT_MIN * _dp())

func ajustes_carga() -> void:
	if oraculo:
		return
	var j = JSON.parse_string(FileAccess.get_file_as_string(AJUSTES)) if FileAccess.file_exists(AJUSTES) else null
	if j is Dictionary:
		for k in aj:
			if j.has(k) and (typeof(j[k]) == TYPE_BOOL) == (aj[k] is bool):
				aj[k] = j[k] if aj[k] is bool else clampi(int(j[k]), 0, 2 if k == "texto" else 4)
	ajustes_aplica()

func ajustes_aplica() -> void:
	if sonido:
		sonido.niveles(aj.musica / 4.0, aj.efectos / 4.0)
	VistaC.DALTONICO = Datos.PLAY and aj.get("dalt", false)
	VistaC.CALMA = Datos.PLAY and aj.get("calma", false)
	I18n.LANG = ["", "es", "en"][clampi(int(aj.get("idioma", 0)), 0, 2)]   # F7
	Datos.SOLO_NOMBRES = I18n.en()
	set_sound(aj.sonido, false)   # el botón SONIDO, ya en su idioma
	if botones.has("MOVIL"):   # F7: los botones, en el idioma elegido
		botones.MOVIL.text = I18n.v("MÓVIL")
	import_pegar.text = I18n.v("PEGAR")
	if Datos.PLAY and is_inside_tree() and not oraculo:   # el tamaño del texto y ZURDO cambian el sitio de todo
		ajusta()
	if is_inside_tree() and get_tree().current_scene == self:   # en el juego (no en las pruebas, que van a toda prisa)
		Engine.max_fps = 30 if aj.ahorro else 60   # R3: a 60 como mucho (a 120 Hz era el doble de trabajo) y 30 con AHORRO

func ajustes_guarda() -> void:
	if oraculo:
		return
	var f := FileAccess.open(AJUSTES + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(aj))
	f.close()
	DirAccess.rename_absolute(AJUSTES + ".tmp", AJUSTES)

# OPCIONES (título y menú START): la define juego.gd
func opciones(_desde_titulo := false) -> void:
	pass

# un texto largo a toda altura, con scroll (▲ ▼ de línea en línea, el dedo) y en páginas (◀ ▶) hasta A, B o START
# fase 6: el embudo del FTUE (retencion.gd)
func evento(_k: String) -> void:
	pass

func leer(t: String, texto: String) -> void:
	if oraculo:
		return
	t = I18n.v(t)
	lector_pags = paginas(I18n.v(texto))
	var ver := func(i: int):
		lector_i = clampi(i, 0, lector_pags.size() - 1)
		lector_ttl.text = t if lector_pags.size() == 1 else "%s · %d/%d" % [t, lector_i + 1, lector_pags.size()]
		lector_pie.text = I18n.v("▲▼ · B VOLVER") if lector_pags.size() == 1 else I18n.v("▲▼ ◀▶ · B VOLVER")
		lector_txt.text = lector_pags[lector_i]
		lector_sc.scroll_vertical = 0
	ver.call(0)
	lector.show()
	hud.hide()
	_coloca()
	var p := Motor.Prom.new()
	push(func(b: String):
		if b == "up" or b == "down":
			lector_sc.scroll_vertical += roundi(25 * us) * (-1 if b == "up" else 1)
		elif b == "left" or b == "right":
			var i := lector_i + (-1 if b == "left" else 1)
			if i >= 0 and i < lector_pags.size():
				sfx("sel")
				ver.call(i)
		elif b == "A" or b == "B" or b == "START":
			sfx("back")
			pop()
			lector.hide()
			lector_txt.text = ""
			lector_pags = []
			update_hud()
			p.res())
	await Motor.espera(p)

# parte un texto en páginas por los párrafos (y por las líneas si un párrafo no cabe)
static func paginas(texto: String, tope := 3500) -> Array[String]:
	var out: Array[String] = []
	var pag := ""
	for par in texto.split("\n\n"):
		var trozos: Array[String] = [par]
		if par.length() > tope:
			trozos = []
			var t := ""
			var lineas: Array[String] = []
			for l0 in par.split("\n"):
				# una línea sola más larga que la página (las licencias de Godot 4.7) se corta por el último espacio
				var l: String = l0
				while l.length() > tope:
					var c := l.rfind(" ", tope)
					c = c if c > 0 else tope
					lineas.append(l.substr(0, c))
					l = l.substr(c).strip_edges(true, false)
				lineas.append(l)
			for l in lineas:
				if t != "" and t.length() + l.length() + 1 > tope:
					trozos.append(t)
					t = ""
				t += ("\n" if t != "" else "") + l
			trozos.append(t)
		for tr in trozos:
			if pag != "" and pag.length() + tr.length() + 2 > tope:
				out.append(pag)
				pag = ""
			pag += ("\n\n" if pag != "" else "") + tr
	out.append(pag)
	return out

# ---------- virtuales (las definen mundo, granja, trama y juego) ----------
func world_press(_b: String) -> void:
	pass

func update_hud() -> void:
	pass

# ---------- interfaz (07-interfaz) ----------
func wait(ms: float) -> void:
	await M.wait(ms)

# F7: una frase con huecos con nombre y un literal que se ve (i18n.gd)
func T(s: String, a := {}) -> String:
	return I18n.T(s, a)

func K(s: String) -> String:
	return s

func nm(t: String) -> String:
	if I18n.en():   # F7: el idioma, con la clave aún con {N}
		t = I18n.v(t)
		return t.replace("{N}", S.name) if S else t
	return Datos.tp(t.replace("{N}", S.name) if S else t)

# U4 (fase 5, con Datos.PLAY): el registro de diálogo (las últimas REGISTRO_MAX cajas, START → REGISTRO), mantener A para
# avanzar rápido (el texto sale entero y la caja pasa sola tras RAPIDO_MS) y las líneas que sobran en los cap. 1-3 (RECORTE)
const REGISTRO_MAX := 80
const RAPIDO_MS := 300
var registro: Array = []

func recortada(text: String) -> bool:
	return Datos.PLAY and S != null and D.has("RECORTE") and int(S.get("ch", 1)) <= int(D.RECORTE.ch) and D.RECORTE.quita.has(text)

func type_text(text: String, name_ := "") -> void:
	if gancho_texto.is_valid():
		gancho_texto.call(text, name_)
	var p := Motor.Prom.new()
	var full := nm(text)
	if Datos.PLAY and not oraculo:
		registro.append((name_ + ": " if name_ != "" else "") + full)
		if registro.size() > REGISTRO_MAX:
			registro.pop_front()
	var st := {"i": 0, "n": 0, "done": false, "iv": 0, "h": Callable()}
	var paso: int = [1, 3, 100000][aj.texto]   # OPCIONES · TEXTO: normal, rápido (3 letras cada vez) o al momento
	if Datos.PLAY and held.get("A"):
		paso = 100000
	if not oraculo:
		dlg.show()
		dlg_nm.visible = name_ != ""
		dlg_nm_txt.text = I18n.v(name_)
		_pon_retrato(name_, full, 0)
		dlg_more.hide()
		dlg_txt.text = ""
		_coloca.call_deferred()
	var fin := func():
		M.quita(st.iv)
		if not oraculo:
			dlg_txt.text = full
			if retrato.visible and retrato_l != null:
				retrato.texture = Retrato.textura(retrato_l[0], retrato_l[1], Retrato.expresion(full), 0)
		st.done = true
		pop(st.h)
		p.res()
	st.iv = M.intervalo(func():
		st.i = mini(st.i + paso, full.length())
		if not oraculo:
			dlg_txt.text = full.substr(0, st.i)
		st.n += 1
		if st.n % 3 == 0:
			sfx("blip")
			if retrato.visible and retrato_l != null:   # la boca, al ritmo del texto
				retrato.texture = Retrato.textura(retrato_l[0], retrato_l[1], Retrato.expresion(full), (st.n / 3) % 2 if st.i < full.length() else 0)
		if st.i >= full.length():
			fin.call(), 20)
	st.h = func(b):
		if (b == "A" or b == "B") and not st.done:
			fin.call()
	push(st.h)
	await Motor.espera(p)

# MAESTRO [8]: el retrato (con Datos.CAL, fuera de las pruebas contra el HTML): quien habla por su nombre o con quien hablas en
# vivo (retrato_de, en mundo.gd), con el gesto por el tono de lo que dice (Retrato.expresion)
const RETRATO_W := 32

# el ancho del retrato en u: el del busto (64) o RETRATO_W el dibujado
func retrato_w() -> int:
	return retrato.texture.get_width() if retrato.texture else RETRATO_W

func retrato_de(_n: String):
	return null

func _pon_retrato(name_: String, full: String, boca: int) -> void:
	retrato_l = retrato_de(name_) if Datos.CAL and name_ != "" else null
	if retrato_l == null:
		retrato.hide()
		return
	retrato.texture = Retrato.textura(retrato_l[0], retrato_l[1], Retrato.expresion(full), boca)
	retrato.show()

func say(text: String, name_ := "", keep := false) -> void:
	if recortada(text):
		return
	await type_text(text, name_)
	if not oraculo:
		dlg_more.show()
		_coloca.call_deferred()
	var p := Motor.Prom.new()
	var st := {"t": 0, "iv": 0, "h": Callable(), "done": false}
	st.h = func(b):
		if (b == "A" or b == "B") and not st.done:
			st.done = true
			pop(st.h)
			p.res()
	push(st.h)
	if Datos.PLAY and not oraculo:   # A mantenida: la caja pasa sola
		st.iv = M.intervalo(func():
			st.t = st.t + 50 if held.get("A") else 0
			if st.t >= RAPIDO_MS and handlers.size() and handlers[-1] == st.h:
				st.h.call("A"), 50)
	await Motor.espera(p)
	if st.iv:
		M.quita(st.iv)
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
	if Datos.PLAY or I18n.en():   # la versión de Google Play: los textos que se ven, con sus cambios (Datos.tp); F7: y en su idioma
		var tr_ := func(s: String) -> String: return I18n.vt(s)
		for i in items.size():
			var it: Dictionary = items[i].duplicate()
			for k in ["label", "desc", "right"]:
				if it.get(k) is String:
					it[k] = tr_.call(it[k])
			items[i] = it
		o = o.duplicate()
		for k in ["title", "title2"]:
			if o.get(k) is String:
				o[k] = tr_.call(o[k])
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
		menu_box.set_meta("flecha", func(b: String): handler.call(b))   # 1.31: tocar ▲ o ▼
	push(handler)
	return await Motor.espera(p)

# los menús que no van a toda altura (1.31, filasMenu de 07-interfaz): si no caben entre el borde de arriba y el diálogo (o el de abajo,
# el de START), las filas que quepan, con las flechas ▲▼. En u, como en el HTML: fila 14,5; caja 14; título 19,5; flechas 10
func filas_menu(n: int, o: Dictionary) -> int:
	var d: float = ui_rect().size.y / us - (6 if o.get("cls") == "start" else 52) - 14 - (19.5 if o.get("title") else 0.0)
	return n if n * 14.5 <= d + .01 else maxi(1, floori((d - 10) / 14.5 + .01))

# el menú del título (1.35): un botón por fila, centrados; el elegido, en amarillo con su sombra verde y ◀ ▶. Se tocan como las filas
func _menu_titulo() -> void:
	var n := m_items.size()
	var hueco: float = ui_rect().end.y - 6 * us - _tit_fin() - 4 * us
	var h := clampf(48 * _dp(), TIT_H * us, maxf(TIT_H * us, (hueco - (n - 1) * TIT_SEP * us) / n))
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 0 if Datos.CAL else roundi(TIT_SEP * us))
	var fs := roundi(9.5 * us)
	var cal: bool = Datos.CAL   # 1.57.1 (lo pidió el usuario: «los botones de la UI principal más pequeños, más limpio»): la pastilla
	# se dibuja más pequeña (TIT_WV × TIT_HV) en el centro de su botón, que se sigue tocando en 48 dp de alto
	var hv := minf(h, TIT_HV * us) if cal else h
	var wv := roundf((TIT_WV if cal else TIT_W) * us)
	if cal:
		fs = roundi(7 * us)
	for k in n:
		var b := Control.new()
		b.custom_minimum_size = Vector2(wv, roundf(h))
		var sel := k == m_i
		var txt: String = m_items[k].label
		b.draw.connect(func():
			var r := Rect2(Vector2(0, roundf((b.custom_minimum_size.y - hv) / 2)), Vector2(b.custom_minimum_size.x, roundf(hv)))
			var rad := roundi(minf(r.size.y, 12 * us) / 2)
			var st := StyleBoxFlat.new()
			st.set_corner_radius_all(rad)
			if sel:
				var sh := StyleBoxFlat.new()
				sh.bg_color = Color("#10301c")
				sh.set_corner_radius_all(rad)
				sh.draw(b.get_canvas_item(), Rect2(r.position + Vector2(2, 2) * us, r.size))
				st.bg_color = Color("#ffe680")
				st.border_color = Color("#2a7a40")
				st.set_border_width_all(roundi(maxf(1, 1.5 * us)))
			else:
				st.bg_color = Color(16 / 255.0, 48 / 255.0, 28 / 255.0, .86)
				st.border_color = Color(156 / 255.0, 240 / 255.0, 168 / 255.0, .6)
				st.set_border_width_all(roundi(maxf(1, us)))
			st.draw(b.get_canvas_item(), r)
			var tw := negrita.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var y := r.position.y + (r.size.y + negrita.get_ascent(fs) - negrita.get_descent(fs)) / 2
			var col := Color("#10301c") if sel else Color("#e8f8ec")
			b.draw_string(negrita, Vector2((r.size.x - tw) / 2, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			if sel:
				var cy := r.get_center().y
				var a := (2.5 if cal else 3.5) * us
				b.draw_colored_polygon(PackedVector2Array([Vector2(8 * us, cy - a), Vector2(8 * us + a, cy), Vector2(8 * us, cy + a)]), col)
				b.draw_colored_polygon(PackedVector2Array([Vector2(r.size.x - 8 * us, cy - a), Vector2(r.size.x - 8 * us - a, cy), Vector2(r.size.x - 8 * us, cy + a)]), col))
		var idx := k
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and menu_box.has_meta("clic"):
				menu_box.get_meta("clic").call(idx))
		lista.add_child(b)
	menu_col.add_child(lista)

# el menú en nodos: título, flechas y filas (las de un menú a toda altura caben con la descripción debajo), descripción
func _pinta_menu(rows: int) -> void:
	for c in menu_col.get_children():
		menu_col.remove_child(c)
		c.queue_free()
	var o := m_o
	var cls: String = o.get("cls", "right")
	menu_box.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if cls == "titulo" else caja_menu)
	if cls == "titulo":   # 1.35: los botones del título
		_menu_titulo()
		menu_box.set_meta("cls", cls)
		_coloca.call_deferred()
		return
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
		if o.get("desc") or (Datos.CAL and _desc_sel(fs) != ""):   # 1.50: sin descripción, el nombre que no cabe
			var dsc: String = _desc_sel(fs)
			var dw := R.size.x - 6 * us - 18 * us
			var nl := letra.get_multiline_string_size(dsc, HORIZONTAL_ALIGNMENT_LEFT, dw, roundi(8.5 * us)).y
			var lineas := maxf(1, roundf(nl / letra.get_height(roundi(8.5 * us))))
			alto -= maxf(24 * us, lineas * 11.5 * us) + 7 * us
		if Datos.CAL and not o.has("rows"):   # las 5 filas eran las de la pantalla de 160 px: en una más alta, todas las que caben (sin hueco debajo)
			vis = m_items.size()
		while vis > 1 and vis * lh > alto:
			vis -= 1
	elif not g:
		vis = filas_menu(m_items.size(), o)
		if Datos.CAL and cls == "right" and not o.get("desc") and _desc_sel(fs) != "":   # 1.50: el nombre entero debajo ocupa unas dos filas
			var d: float = ui_rect().size.y / us - 52 - 14 - (19.5 if o.get("title") else 0.0) - 31
			if vis * 14.5 > d + .01:
				vis = maxi(1, floori((d - 10) / 14.5 + .01))
	else:
		vis = m_items.size()
	menu_box.set_meta("cabe", full and Datos.CAL and not o.has("rows") and vis >= m_items.size())
	var fl: bool = (full and not menu_box.get_meta("cabe")) or vis < m_items.size()
	if m_i < m_top:
		m_top = m_i
	if m_i >= m_top + vis:
		m_top = m_i - vis + 1
	if Datos.CAL:   # 1.50: si caben más filas (la descripción de ahora es más corta), sin hueco debajo de la última
		m_top = clampi(m_top, 0, maxi(0, m_items.size() - vis))
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
	if fl:
		menu_col.add_child(_flecha("▲" if m_top > 0 else "", "up"))
	var lista: Container = GridContainer.new() if g else VBoxContainer.new()
	if g:
		lista.columns = 2
	lista.add_theme_constant_override("separation", 0)
	lista.add_theme_constant_override("h_separation", 0)
	lista.add_theme_constant_override("v_separation", 0)
	if full and not menu_box.get_meta("cabe"):
		lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var maxw := (170 - 14 - 4) * us if cls == "right" else 1e9
	if Datos.CAL and cls == "right":   # 1.50: el menú de la derecha se ensancha hasta casi toda la pantalla antes de cortar
		maxw = maxf(maxw, ui_rect().size.x * .9 - 18 * us)
	elif Datos.CAL and full:   # 1.50: a toda pantalla, la fila no la ensancha (el nombre entero va abajo, en la descripción)
		maxw = ui_rect().size.x - 6 * us - 18 * us
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
			l.custom_minimum_size = Vector2(minf(lw, maxf(20 * us, maxw - rw - 22 * us - (12 * us if it.get("ic") or it.get("sw") else 0.0))), 0)
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
	if fl:
		menu_col.add_child(_flecha("▼" if m_top + vis < m_items.size() else "", "down"))
	if o.get("desc") or ((full or cls == "right") and Datos.CAL and _desc_sel(fs) != ""):
		var raya := ColorRect.new()
		raya.color = LINEA2
		raya.custom_minimum_size = Vector2(0, maxf(1, us))
		menu_col.add_child(raya)
		var hueco := Control.new()
		hueco.custom_minimum_size = Vector2(0, 3 * us)
		menu_col.add_child(hueco)
		var dl := Label.new()
		dl.text = _desc_sel(fs)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(0, 24 * us)
		pon_letra(dl, letra, 8.5 * us, INK, 11.5 * us)
		menu_col.add_child(dl)
	menu_box.set_meta("cls", cls)
	_coloca.call_deferred()

# la descripción de la fila elegida; 1.50: si su nombre no cabe en la fila, entero delante
func _desc_sel(fs: float) -> String:
	var it: Dictionary = m_items[m_i]
	var dsc: String = it.get("desc", "")
	var cls: String = m_o.get("cls", "right")
	if not Datos.CAL or not cls in ["full", "right"]:
		return dsc
	var lab := str(it.get("label", ""))
	var rt := str(it.right) if it.get("right") != null else ""
	var w := letra.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs)).x + 2 + (letra.get_string_size(rt, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs)).x + 12 * us if rt != "" else 0.0)
	var hay: float = (ui_rect().size.x - 6 * us - 18 * us if cls == "full" else maxf((170 - 14 - 4) * us, ui_rect().size.x * .9 - 18 * us)) - 10 * us - (12 * us if it.get("ic") or it.get("sw") else 0.0)
	if w <= hay:
		return dsc
	return lab + ("\n" + dsc if dsc != "" else "")

func _flecha(t: String, b := "") -> Label:
	var a := Label.new()
	a.text = t
	if t != "" and b != "":   # 1.31: se toca como la cruceta
		a.mouse_filter = Control.MOUSE_FILTER_STOP
		a.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and menu_box.has_meta("flecha"):
				menu_box.get_meta("flecha").call(b))
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
		var rw := retrato_w()
		dlg.get_theme_stylebox("panel").content_margin_left = ((10 + (rw + 4 if retrato.visible else 0)) + 2) * us
		dlg.reset_size()
		dlg.size.x = R.size.x - 6 * us
		dlg.position = Vector2(R.position.x + 3 * us, R.end.y - 3 * us - dlg.size.y)
		dlg_nm.reset_size()
		dlg_nm.position = dlg.position + Vector2(6 * us, -12 * us)
		if retrato.visible:
			retrato.size = Vector2(rw, rw) * us
			if rw > RETRATO_W:   # el busto, de pie sobre el canto de abajo de la caja y asomando por encima; el nombre, a su derecha
				retrato.position = dlg.position + Vector2(6 * us, dlg.size.y - (rw + 3) * us)
				dlg_nm.position.x += (rw + 4) * us
			else:
				retrato.position = dlg.position + Vector2(6 * us, maxf(6 * us, (dlg.size.y - rw * us) / 2))
		dlg_more.position = dlg.position + dlg.size - Vector2(8 * us + 8 * us, 4 * us + 5 * us)
		dlg_more.size = Vector2(8 * us, 7 * us)
		# La primera vez, el texto aún no sabe su ancho y el cuadro sale de toda la pantalla; se recoloca al fotograma siguiente
		if dlg.size.y > R.size.y * 0.6 and not get_tree().process_frame.is_connected(_coloca):
			get_tree().process_frame.connect(_coloca, CONNECT_ONE_SHOT)
	if menu_box.visible:
		var cls: String = menu_box.get_meta("cls", "right")
		menu_box.custom_minimum_size = Vector2(60 * us, 0)
		if cls == "full":
			menu_box.custom_minimum_size = R.size - Vector2(6 * us, 6 * us)
			if menu_box.get_meta("cabe", false):   # caben todas las filas: la caja, del alto de lo que lleva (sin aire debajo)
				menu_box.custom_minimum_size.y = 0
				menu_box.reset_size()
				menu_box.size.x = R.size.x - 6 * us
			else:
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
			elif cls == "titulo":   # 1.35: centrados, abajo, sin subir del lema
				menu_box.position = Vector2(roundf(R.get_center().x - menu_box.size.x / 2), maxf(_tit_fin() + 4 * us, R.end.y - 6 * us - menu_box.size.y))
			else:
				menu_box.position = Vector2(R.end.x - 3 * us - menu_box.size.x, maxf(R.position.y + 3 * us, R.end.y - 49 * us - menu_box.size.y))
	if lector.visible:   # como un menú a toda altura
		lector.custom_minimum_size = R.size - Vector2(6 * us, 6 * us)
		lector.size = lector.custom_minimum_size
		lector.position = R.position + Vector2(3 * us, 3 * us)
	if name_box.visible:
		name_box.reset_size()
		name_box.position = R.get_center() - name_box.size / 2
	if import_box.visible:
		import_box.reset_size()
		import_box.position = R.get_center() - import_box.size / 2
	if hud.visible:
		hud.reset_size()
		hud.position = scr.position + Vector2(HUD_M * u, HUD_M * u)
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
		if Datos.PLAY and bP.position.x < escena.size.x / 2:   # 1.58 (lo pidió el usuario): si A, B o START la echan encima del jugador, debajo de la del enemigo
			bP.position = Vector2(bE.position.x, bE.position.y + bE.size.y + 4 * u)
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
		toast_txt.text = "[center]" + html_bb(I18n.vt(html)) + "[/center]"
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
	if Datos.PLAY:   # fase 2 del plan (C6): la de la tienda, en persiana de 8 lamas verticales que se cierran a la vez
		var w := wipe.size.x / 8.0
		for i in 8:
			wipe.draw_rect(Rect2(i * w, 0, ceilf(w * k), h), Color.BLACK)
		return
	wipe.draw_rect(Rect2(0, h / 2 * (1 - k), wipe.size.x, h * k), Color.BLACK)

# ---------- HUD (14-render updateHUD) ----------
var hud_heat := 0
var hud_sosp := -1   # la barra de sospecha (1.10): -1 sin patrullas en el mapa
var hud_alarma := false
var hud_orden := false   # (1.11) con la orden de registro, la barra dice ORDEN
var hud_tab := Control.new()
var hud_filas := []   # 1.50: [[etiqueta, valor, color]] del recuadro; vacío, sin recuadro (sin Datos.CAL)
var hud_ultimo := []   # R15: lo último que se puso; si no cambia, nada
func hud_pon(t: String, heat: int, sosp := -1, alarma := false, orden := false, filas := []) -> void:
	if oraculo:
		return
	var a := [t, heat, sosp, alarma, orden, filas]
	if hud.visible and a == hud_ultimo:
		return
	hud_ultimo = a.duplicate(true)
	hud_txt.text = t
	hud_filas = filas
	hud_tab.visible = not filas.is_empty()
	hud_tab.queue_redraw()
	hud_heat = heat
	hud_orden = orden
	hud_sosp = sosp
	hud_alarma = alarma
	hud.show()
	hud_bar.queue_redraw()
	_coloca.call_deferred()

# el HUD (1.22, más pequeño): los mismos números que .hud en el CSS
const HUD_FS := 6.5   # letra
const HUD_LH := 7.5   # alto de línea
const HUD_M := 2.0    # margen a la pantalla
const HUD_PV := 1.5
const HUD_PH := 3.0
const HUD_R := 2.0
const HUD_BW := 28.0  # barra
const HUD_BH := 2.5
const HUD_GAP := 2.5

# El recuadro, etiqueta a la izquierda y cifra a la derecha, con una raya arriba y abajo
const HUD_TAB_SEP := 6.0   # entre la etiqueta más larga y la cifra más larga
func _pinta_hud_tab() -> void:
	var f := negrita
	var fs := roundi(HUD_FS * u)
	var lh := HUD_LH * u
	var we := 0.0
	var wv := 0.0
	for r in hud_filas:
		we = maxf(we, f.get_string_size(r[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		wv = maxf(wv, f.get_string_size(r[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var w := maxf(we + HUD_TAB_SEP * u + wv, HUD_BW * u + 40 * u)
	var pad := 1.5 * u
	var raya := Color(1, 1, 1, .22)
	hud_tab.draw_rect(Rect2(0, pad * .5, w, maxf(1, roundf(.5 * u))), raya)
	var y := pad
	for r in hud_filas:
		var by := y + f.get_ascent(fs) + (lh - f.get_height(fs)) / 2
		hud_tab.draw_string(f, Vector2(0, by), r[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#9fc0ac"))
		var vw := f.get_string_size(r[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		hud_tab.draw_string(f, Vector2(w - vw, by), r[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, r[2])
		y += lh
	hud_tab.draw_rect(Rect2(0, y + pad * .5 - maxf(1, roundf(.5 * u)), w, maxf(1, roundf(.5 * u))), raya)
	hud_tab.custom_minimum_size = Vector2(w, y + pad)

func _pinta_hud_bar() -> void:
	var f := negrita
	var fs := roundi(HUD_FS * u)
	var lh := HUD_LH * u
	var eti := I18n.v("ORDEN") if hud_orden else I18n.v("CALOR")
	hud_bar.draw_string(f, Vector2(0, f.get_ascent(fs) + (lh - f.get_height(fs)) / 2), eti, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#eef8f0"))
	var x := f.get_string_size(eti, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + HUD_GAP * u
	var y := (lh - HUD_BH * u) / 2
	hud_bar.draw_rect(Rect2(x, y, HUD_BW * u, HUD_BH * u), Color("#2e3a34"))
	hud_bar.draw_rect(Rect2(x, y, HUD_BW * u * hud_heat / 100.0, HUD_BH * u), Color("#f04040") if hud_heat >= 70 else Color("#f0a030"))
	var w := x + HUD_BW * u
	if hud_sosp >= 0:
		var et := "¡ALARMA!" if hud_alarma else "SOSPECHA"
		hud_bar.draw_string(f, Vector2(0, lh + f.get_ascent(fs) + (lh - f.get_height(fs)) / 2), et, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#eef8f0"))
		var x2 := f.get_string_size(et, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + HUD_GAP * u
		hud_bar.draw_rect(Rect2(x2, lh + y, HUD_BW * u, HUD_BH * u), Color("#2e3a34"))
		hud_bar.draw_rect(Rect2(x2, lh + y, HUD_BW * u * (100 if hud_alarma else hud_sosp) / 100.0, HUD_BH * u), Color("#f04040") if hud_alarma else Color("#e8d040"))
		w = maxf(w, x2 + HUD_BW * u)
	hud_bar.custom_minimum_size = Vector2(w, lh * 2 if hud_sosp >= 0 else lh)

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
		var etq: String = I18n.v("VIDA") if par[2] else v[1]
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
# (lo pidió el usuario): el rótulo, el lema y, debajo, los botones (el menú «titulo»); detrás, la partida de fondo (pinta.gd)
const LEMA := "Caza genéticas. Salda la deuda. Que no te pillen."
const TIT_W := 132.0   # los botones: de ancho, en u; de alto, 48 dp si caben (TIT_H como poco), con TIT_SEP entre ellos
const TIT_H := 17.0
const TIT_SEP := 4.0
const TIT_WV := 84.0   # 1.57.1: la pastilla, más pequeña
const TIT_HV := 12.0
var caja_menu: StyleBox = null

# dónde acaba el lema, en la pantalla (los botones no suben de ahí)
func _tit_fin() -> float:
	var s1 := roundi(17 * u)
	var s2 := roundi(8.5 * u)
	return titulo.get_global_rect().position.y + tt + display.get_ascent(s1) + 17 * u * 1.05 + 17 * u * .05 + 6 * u + negrita.get_height(s2) + 2 * u

func _pinta_titulo() -> void:
	var c := titulo
	var w := c.size.x
	var f := display
	var s1 := roundi(17 * u)
	var y := tt + f.get_ascent(s1) - 17 * u * 1.05
	var x := 0.0
	for t1 in ["LANDRACE", "HUNTERS"]:   # dos líneas (<br> en el HTML); el nombre del juego, igual en inglés · i18n-no
		y += 17 * u * 1.05
		x = (w - f.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1).x) / 2
		c.draw_string(f, Vector2(x + 3 * u, y + 3 * u), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("#10301c"))
		c.draw_string(f, Vector2(x + 1.5 * u, y + 1.5 * u), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("#2a7a40"))
		c.draw_string(f, Vector2(x, y), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("#ffe680"))
	var s2 := roundi(8.5 * u)
	y += 17 * u * .05 + 6 * u + negrita.get_ascent(s2)
	x = (w - negrita.get_string_size(LEMA, HORIZONTAL_ALIGNMENT_LEFT, -1, s2).x) / 2
	c.draw_string(negrita, Vector2(x + u, y + u), LEMA, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color("#10301c"))
	c.draw_string(negrita, Vector2(x, y), LEMA, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color("#9cf0a8"))
	if not menu_box.visible and not dlg.visible and int(M.reloj / 500) % 2 == 0:
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
