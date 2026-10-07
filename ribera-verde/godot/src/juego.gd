# Ribera Verde (Godot) — corte de prueba: la carpa 100×100 vista por dentro (vista C) y un ciclo de cultivo.
# Pantalla como 06b-pantalla.js: el juego a 160 px de alto y de 240 a 400 de ancho (según el móvil), escalado a píxeles enteros
# si se pierde menos de un 6 %; encima, a la resolución del móvil, la ficha de la plaza, los diálogos y los mandos flotantes.
# Controles como en el HTML: ◀ ▶ plaza, ▲ ▼ fila (desde la de atrás, ▲ el foco), A cuidar, B cancelar; START: dormir.
extends Control

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Vista = preload("res://src/vista.gd")

static var GUARDADO := "user://partida.json"   # las pruebas usan otro
const BOX := Color("#f8f8f0")
const INK := Color("#2c2c36")
const SOMBRA := Color("#e2dbd0")
const LINEA := Color("#46749a")
const LINEA2 := Color("#a9d2ec")
const ROJO := Color("#e04040")

signal hecho(i: int)

var S: Dictionary
var VC := {"ci": 0, "sel": 0, "ocupado": false}
var now := 0.0
var sw := 240
var u := 1.0      # px de pantalla por píxel del juego
var us := 1.0     # el de los diálogos (encoge para caber entre los mandos)
var modo := ""    # "", "say" o "menu"
var m_opts: Array = []
var m_sel := 0
var m_cancel := -1
var letra: FontFile
var negrita: FontFile

var sv := SubViewport.new()
var vista = Vista.new()
var pantalla := TextureRect.new()
var ficha := PanelContainer.new()
var ficha_txt := VBoxContainer.new()
var dlg := PanelContainer.new()
var dlg_txt := Label.new()
var dlg_mas := Control.new()
var menu_box := PanelContainer.new()
var menu_list := VBoxContainer.new()
var toast := PanelContainer.new()
var toast_txt := Label.new()
var toast_n := 0
var botones := {}
var rep := Timer.new()
var rep_b := ""

func _ready() -> void:
	letra = _fuente("atkinson-hyperlegible-latin-400-normal.woff2")
	negrita = _fuente("atkinson-hyperlegible-latin-700-normal.woff2")
	S = _carga()
	var pl: Array = Vista.geo(S, 0).pl
	VC.sel = pl[0].i if pl.size() else -1
	set_anchors_preset(PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color("#121519")
	fondo.set_anchors_preset(PRESET_FULL_RECT)
	add_child(fondo)
	sv.transparent_bg = false
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sv.add_child(vista)
	add_child(sv)
	pantalla.texture = sv.get_texture()
	pantalla.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pantalla.stretch_mode = TextureRect.STRETCH_SCALE
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(pantalla)
	ficha.add_child(ficha_txt)
	add_child(ficha)
	dlg_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg.add_child(dlg_txt)
	dlg_mas.draw.connect(func():
		var a := us * 4
		var y := (us * 2 if int(now / 300) % 2 else 0.0)
		dlg_mas.draw_colored_polygon(PackedVector2Array([Vector2(0, y), Vector2(2 * a, y), Vector2(a, y + us * 5)]), ROJO))
	dlg.add_child(dlg_mas)
	add_child(dlg)
	menu_box.add_child(menu_list)
	add_child(menu_box)
	toast_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_child(toast_txt)
	add_child(toast)
	for n in [dlg, menu_box, toast]:
		n.hide()
	_mandos()
	rep.one_shot = false
	rep.timeout.connect(func():
		rep.wait_time = .11
		if rep_b != "":
			press(rep_b))
	add_child(rep)
	get_viewport().size_changed.connect(ajusta)
	ajusta()
	_ficha()
	_toast("◀ ▶ ▲ ▼ eliges planta o foco · A la cuidas · START duermes", 2.8)

func _process(dt: float) -> void:
	now += dt * 1000
	vista.pinta(S, VC, now, sw)
	if dlg.visible:
		dlg_mas.queue_redraw()

func _fuente(f: String) -> FontFile:
	var o := FontFile.new()
	o.data = FileAccess.get_file_as_bytes("res://fuentes/" + f)
	o.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["sans-serif"])
	o.fallbacks = [sf]
	return o

# ---------- pantalla y mandos (06b-pantalla.js) ----------
func ajusta() -> void:
	var V := get_viewport_rect().size
	var dp := _dp()
	var rim := roundf(clampf(minf(V.x, V.y) * .008, 2 * dp, 5 * dp))
	var w := V.x - 2 * rim
	var h := V.y - 2 * rim
	var s := h / 160
	var k := floorf(s)
	if k >= 2 and k >= s * .94:
		s = k
	sw = clampi(int(floor(w / s / 2)) * 2, 240, 400)
	if sw * s > w:
		s = w / sw
	u = s
	sv.size = Vector2i(sw, 160)
	var cw := floorf(sw * s)
	var ch := floorf(160 * s)
	var x := roundf(rim + (w - cw) / 2)
	var y := roundf(rim + (h - ch) / 2)
	pantalla.position = Vector2(x, y)
	pantalla.size = Vector2(cw, ch)
	var H := V.y / dp
	var d := roundf(clampf(H * .34, 104, 150)) * dp
	var ab := roundf(d / dp * .44) * dp
	var m := roundf(clampf(H * .035, 8, 22)) * dp
	var pill := roundf(clampf(H * .07, 24, 34)) * dp
	var col := m + maxf(d, ab * 2.25) + m * .5
	us = clampf((V.x - 2 * col) / 240, minf(s, maxf(s * .5, 1.3 * dp)), s)
	var uiw := minf(cw, roundf(240 * us))
	# escena de 240 u en el centro: la ficha
	var ex := x + cw / 2 - 120 * u
	ficha.position = Vector2(ex + 3 * u, y + 3 * u)
	ficha.custom_minimum_size = Vector2(66 * u, 0)
	ficha.size = Vector2(66 * u, 0)
	ficha.add_theme_stylebox_override("panel", _caja(u, 3, 4))
	# mandos
	_pon(botones.up, Vector2(m + d / 3, V.y - m - d), Vector2(d / 3, d / 3))
	_pon(botones.left, Vector2(m, V.y - m - d * 2 / 3), Vector2(d / 3, d / 3))
	_pon(botones.right, Vector2(m + d * 2 / 3, V.y - m - d * 2 / 3), Vector2(d / 3, d / 3))
	_pon(botones.down, Vector2(m + d / 3, V.y - m - d / 3), Vector2(d / 3, d / 3))
	_pon(botones.mid, Vector2(m + d / 3, V.y - m - d * 2 / 3), Vector2(d / 3, d / 3))
	var abx := V.x - m - ab * 2.25
	var aby := V.y - m - ab * 1.6
	_pon(botones.B, Vector2(abx, aby + ab * .6), Vector2(ab, ab))
	_pon(botones.A, Vector2(abx + ab * 1.25, aby), Vector2(ab, ab))
	_pon(botones.START, Vector2(V.x - m - pill * 2.6, m), Vector2(pill * 2.6, pill))
	for b in ["up", "down", "left", "right"]:
		_estilo(botones[b], Color(24 / 255.0, 28 / 255.0, 34 / 255.0, .5), Color(70 / 255.0, 80 / 255.0, 96 / 255.0, .75), Color(1, 1, 1, .22), 8 * dp, d * .1, b)
	var mid: Panel = botones.mid
	var st := StyleBoxFlat.new()
	st.bg_color = Color(24 / 255.0, 28 / 255.0, 34 / 255.0, .5)
	mid.add_theme_stylebox_override("panel", st)
	for b in ["A", "B"]:
		_estilo(botones[b], Color(109 / 255.0, 44 / 255.0, 75 / 255.0, .55), Color(154 / 255.0, 74 / 255.0, 114 / 255.0, .85), Color(1, 210 / 255.0, 230 / 255.0, .4), ab / 2, ab * .36, "")
	_estilo(botones.START, Color(24 / 255.0, 28 / 255.0, 34 / 255.0, .55), Color(70 / 255.0, 80 / 255.0, 96 / 255.0, .75), Color(1, 1, 1, .22), pill / 2, pill * .42, "")
	# escenario de diálogos: 240 us centrado, debajo de START si le cae encima
	var ux := x + cw / 2 - uiw / 2
	var ut := 0.0
	var pr := Rect2(botones.START.position, botones.START.size)
	if pr.position.x < ux + uiw and pr.end.y > y:
		ut = pr.end.y - y + m * .4
	dlg.position = Vector2(ux + 3 * us, 0)
	dlg.size = Vector2(uiw - 6 * us, 0)
	dlg.custom_minimum_size = Vector2(uiw - 6 * us, 44 * us)
	dlg.set_meta("fondo", y + ch - 3 * us)
	dlg.add_theme_stylebox_override("panel", _caja(us, 6, 10))
	_letra(dlg_txt, letra, 10 * us, INK, 13.5)
	dlg_mas.custom_minimum_size = Vector2(us * 8, us * 7)
	dlg_mas.size_flags_horizontal = Control.SIZE_SHRINK_END
	dlg_mas.size_flags_vertical = Control.SIZE_SHRINK_END
	menu_box.set_meta("der", ux + uiw - 3 * us)
	menu_box.set_meta("fondo", y + ch - 49 * us)
	menu_box.set_meta("arriba", y + ut + 3 * us)
	menu_box.add_theme_stylebox_override("panel", _caja(us, 5, 7))
	toast.set_meta("centro", x + cw / 2)
	toast.position.y = y + 24 * us
	toast.add_theme_stylebox_override("panel", _caja(us, 4, 10))
	_letra(toast_txt, letra, 9 * us, INK, 12)
	_coloca()
	_ficha()

# px de pantalla por px CSS: por los ppp del móvil y, si el sistema no los da bien (escritorio, Xvfb), como un móvil en
# horizontal, que mide 360-430 px CSS de alto
func _dp() -> float:
	return maxf(1.0, maxf(DisplayServer.screen_get_dpi() / 160.0, get_viewport_rect().size.y / 430.0))

func _pon(c: Control, p: Vector2, s: Vector2) -> void:
	c.position = p
	c.size = s

# la caja de diálogo del HTML (.box): borde #46749a de 2 u, filete interior #a9d2ec de 1,5 u y fondo #f8f8f0, esquinas de 4 u
class Caja extends StyleBox:
	var capas := []
	func _init(k: float) -> void:
		for c in [[LINEA, 0.0, 4.0], [LINEA2, 2.0, 2.0], [BOX, 3.5, 1.0]]:
			var b := StyleBoxFlat.new()
			b.bg_color = c[0]
			b.set_corner_radius_all(roundi(c[2] * k))
			capas.append([b, roundf(c[1] * k)])
	func _draw(to_canvas_item: RID, rect: Rect2) -> void:
		for c in capas:
			c[0].draw(to_canvas_item, rect.grow(-c[1]))

func _caja(k: float, py: float, px: float) -> StyleBox:
	var b := Caja.new(k)
	b.content_margin_left = (px + 3.5) * k
	b.content_margin_right = (px + 3.5) * k
	b.content_margin_top = (py + 3.5) * k
	b.content_margin_bottom = (py + 3.5) * k
	return b

func _letra(l: Label, f: Font, px: float, c: Color, alto := 0.0) -> void:
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", maxi(6, roundi(px)))
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_shadow_color", SOMBRA)
	l.add_theme_constant_override("shadow_offset_x", maxi(1, roundi(px * .08)))
	l.add_theme_constant_override("shadow_offset_y", maxi(1, roundi(px * .08)))
	if alto:
		l.add_theme_constant_override("line_spacing", roundi(px * alto / 10 - f.get_height(roundi(px))))

func _mandos() -> void:
	for b in [["up", ""], ["down", ""], ["left", ""], ["right", ""], ["A", "A"], ["B", "B"], ["START", "START"]]:
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
		var k: String = b[0]
		n.button_down.connect(func():
			press(k)
			if k in ["up", "down", "left", "right"]:
				rep_b = k
				rep.start(.32))
		n.button_up.connect(func():
			if rep_b == k:
				rep_b = ""
				rep.stop())
		add_child(n)
		botones[k] = n
	var mid := Panel.new()
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mid)
	botones.mid = mid

func _estilo(n: Button, bg: Color, on: Color, borde: Color, r: float, px: float, lado: String) -> void:
	for e in [["normal", bg], ["hover", bg], ["pressed", on], ["disabled", bg]]:
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

# ---------- entrada ----------
const TECLAS := {KEY_UP: "up", KEY_DOWN: "down", KEY_LEFT: "left", KEY_RIGHT: "right", KEY_W: "up", KEY_S: "down", KEY_A: "left", KEY_D: "right",
	KEY_Z: "A", KEY_SPACE: "A", KEY_ENTER: "A", KEY_J: "A", KEY_X: "B", KEY_ESCAPE: "B", KEY_BACKSPACE: "B", KEY_K: "B", KEY_M: "START", KEY_TAB: "START"}

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and TECLAS.has(e.keycode):
		var b: String = TECLAS[e.keycode]
		if e.echo and not b in ["up", "down", "left", "right"]:
			return
		get_viewport().set_input_as_handled()
		press(b)

func _notification(w: int) -> void:
	if w == NOTIFICATION_WM_GO_BACK_REQUEST:
		press("B")
	elif w == NOTIFICATION_APPLICATION_PAUSED or w == NOTIFICATION_WM_CLOSE_REQUEST:
		if S:
			_guarda()

func press(b: String) -> void:
	if modo == "menu":
		if b == "up" or b == "down":
			m_sel = clampi(m_sel + (1 if b == "down" else -1), 0, m_opts.size() - 1)
			_pinta_menu()
		elif b == "A":
			hecho.emit(m_sel)
		elif b == "B":
			hecho.emit(m_cancel)
		return
	if modo == "say":
		if b == "A" or b == "B":
			hecho.emit(0)
		return
	if VC.ocupado:
		return
	if b == "A":
		VC.ocupado = true
		_ficha()
		if VC.sel < 0:
			await carpa_action()
		else:
			await pot_action(VC.sel)
		VC.ocupado = false
		_guarda()
		_ficha()
	elif b == "START":
		VC.ocupado = true
		_ficha()
		await dormir()
		VC.ocupado = false
		_ficha()
	elif b in ["up", "down", "left", "right"]:
		var s: int = VC.sel
		vc_mover(b)
		if s != VC.sel:
			_ficha()

# ◀ ▶ dentro de la fila; ▲ a la de atrás (desde la última, el foco); ▼ a la de delante
func vc_mover(b: String) -> void:
	var pl: Array = Vista.geo(S, VC.ci).pl
	var cur = null
	for q in pl:
		if q.i == VC.sel:
			cur = q
	var cerca := func(l: Array, x: float):
		var m = l[0]
		for q in l:
			if absf(q.x - x) < absf(m.x - x):
				m = q
		return m
	if cur == null:
		if b == "down":
			var fm := 0
			for q in pl:
				fm = maxi(fm, q.fila)
			VC.sel = cerca.call(pl.filter(func(q): return q.fila == fm), 120).i
		return
	if b == "left" or b == "right":
		var f := pl.filter(func(q): return q.fila == cur.fila)
		f.sort_custom(func(a, c): return a.x < c.x)
		var k := f.find(cur) + (-1 if b == "left" else 1)
		if k >= 0 and k < f.size():
			VC.sel = f[k].i
	elif b == "up":
		var f := pl.filter(func(q): return q.fila == cur.fila + 1)
		VC.sel = cerca.call(f, cur.x).i if f.size() else -1
	elif b == "down":
		var f := pl.filter(func(q): return q.fila == cur.fila - 1)
		if f.size():
			VC.sel = cerca.call(f, cur.x).i

# ---------- ficha de la plaza o del foco (vcInfo) ----------
func _ficha() -> void:
	for c in ficha_txt.get_children():
		ficha_txt.remove_child(c)
		c.queue_free()
	if VC.ocupado:
		ficha.hide()
		return
	var D := Datos.carga()
	var c: Dictionary = S.carpas[VC.ci]
	var L := []
	if VC.sel < 0:
		L.append(D.FOCOS[c.foco].n)
		L.append("Luz %s al día" % Datos.eur(Cultivo.luz_carpa(S, VC.ci)) if Cultivo.plantas_vivas(S, VC.ci) else "Apagado")
	else:
		var i: int = VC.sel
		var p = S.pots[i]
		L.append("Plaza %d · %d L" % [Cultivo.huecos(S)[i].j + 1, D.MACETAS[S.macetas[i]].l])
		if p == null:
			L.append("Vacía")
		else:
			L.append(Datos.strain(S, p.sid).n)
			if p.get("dead"):
				L.append("Seca")
			else:
				L.append("Cosecha lista" if p.prog >= 1 else "%s %d %%" % [Cultivo.stage_name(p), int(floor(p.prog * 100))])
				L.append("Agua %d %%" % Datos.jsround(p.water))
				L.append("Salud %d %%" % Datos.jsround(p.health))
			if p.pest and not p.get("dead"):
				L.append("!PLAGA")
	var t := Label.new()
	t.text = D.CARPAS[c.t].n
	_letra(t, negrita, 7 * u, LINEA)
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ficha_txt.add_child(t)
	var raya := ColorRect.new()
	raya.color = LINEA2
	raya.custom_minimum_size = Vector2(0, maxf(1, roundf(u)))
	ficha_txt.add_child(raya)
	ficha_txt.add_theme_constant_override("separation", 0)
	for l in L:
		var n := Label.new()
		var plaga: bool = l.begins_with("!")
		n.text = l.substr(1) if plaga else l
		_letra(n, negrita if plaga else letra, 6.5 * u, ROJO if plaga else INK)
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ficha_txt.add_child(n)
	ficha.size = Vector2(66 * u, 0)
	ficha.show()

# ---------- diálogos: say, ask y menú (07-interfaz) ----------
func _coloca() -> void:
	dlg.size.y = 0
	dlg.reset_size()
	dlg.size.x = dlg.custom_minimum_size.x
	if dlg.has_meta("fondo"):
		dlg.position.y = dlg.get_meta("fondo") - dlg.size.y
	menu_box.reset_size()
	if menu_box.has_meta("der"):
		menu_box.position.x = menu_box.get_meta("der") - menu_box.size.x
		var bajo: float = menu_box.get_meta("fondo")
		if dlg.visible:
			bajo = minf(bajo, dlg.position.y - 2 * us)
		menu_box.position.y = maxf(menu_box.get_meta("arriba"), bajo - menu_box.size.y)
	toast.reset_size()
	if toast.has_meta("centro"):
		toast.position.x = toast.get_meta("centro") - toast.size.x / 2

func say(t: String) -> void:
	dlg_txt.text = t
	dlg_mas.show()
	dlg.show()
	modo = "say"
	_coloca.call_deferred()
	await hecho
	modo = ""
	dlg.hide()

func ask(t: String, opts: Array) -> int:
	dlg_txt.text = t
	dlg_mas.hide()
	dlg.show()
	var i := await menu(opts, opts.size() - 1)
	dlg.hide()
	return i

func menu(opts: Array, cancel := -1, titulo := "") -> int:
	m_opts = opts
	m_sel = 0
	m_cancel = cancel
	menu_box.set_meta("titulo", titulo)
	_pinta_menu()
	menu_box.show()
	modo = "menu"
	_coloca.call_deferred()
	var i: int = await hecho
	modo = ""
	menu_box.hide()
	return i

func _pinta_menu() -> void:
	for c in menu_list.get_children():
		menu_list.remove_child(c)
		c.queue_free()
	menu_list.add_theme_constant_override("separation", 0)
	var tt: String = menu_box.get_meta("titulo", "")
	if tt != "":
		var t := Label.new()
		t.text = tt
		_letra(t, negrita, 8.5 * us, LINEA)
		menu_list.add_child(t)
	for j in m_opts.size():
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 0)
		var mk := Control.new()
		mk.custom_minimum_size = Vector2(10 * us, 14.5 * us)
		if j == m_sel:
			mk.draw.connect(func():
				var y0 := 14.5 * us / 2
				mk.draw_colored_polygon(PackedVector2Array([Vector2(0, y0 - 4 * us), Vector2(5 * us, y0), Vector2(0, y0 + 4 * us)]), Color("#404048")))
		f.add_child(mk)
		var l := Label.new()
		l.text = m_opts[j]
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(50 * us, 14.5 * us)
		_letra(l, letra, 10 * us, INK)
		f.add_child(l)
		var idx := j
		f.gui_input.connect(func(e):
			if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
				if m_sel == idx:
					hecho.emit(idx)
				else:
					m_sel = idx
					_pinta_menu())
		menu_list.add_child(f)
	_coloca.call_deferred()

func _toast(t: String, seg: float) -> void:
	toast_txt.text = t
	var fs := toast_txt.get_theme_font_size("font_size")
	toast_txt.custom_minimum_size.x = minf(letra.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 2, 210 * us)
	toast.show()
	toast_n += 1
	var n := toast_n
	_coloca.call_deferred()
	await get_tree().create_timer(seg).timeout
	if n == toast_n:
		toast.hide()

# ---------- cultivo (09-cultivo) ----------
func pot_action(i: int) -> void:
	var p = S.pots[i]
	if p == null:
		await plantar(i)
		return
	var s = Datos.strain(S, p.sid)
	if p.get("dead"):
		await say("La %s se ha secado del todo." % s.n)
		S.pots[i] = null
		await say("Retiras la planta muerta.")
		return
	if p.prog >= 1:
		var c := await ask("%s%s lista para cosechar.\nSalud %d%% · Agua %d%%" % [s.n, marca_feno(p.f), Datos.jsround(p.health), Datos.jsround(p.water)], ["Cosechar", "Esperar"])
		if c == 0:
			await harvest(i)
		return
	var opts := ["Regar"]
	if not p.fert:
		opts.append("Abonar")
	if p.pest:
		opts.append("Tratar plaga")
	opts.append_array(["Arrancar", "Salir"])
	var c := await ask("%s%s · %s %d%%\nAgua %d%% · Salud %d%%%s" % [s.n, marca_feno(p.f), Cultivo.stage_name(p), int(floor(p.prog * 100)), Datos.jsround(p.water), Datos.jsround(p.health), " · PLAGA" if p.pest else ""], opts)
	var op: String = opts[c]
	if op == "Regar":
		p.water = 100.0
		await say("Riegas la planta. Agua al 100%.")
	elif op == "Abonar":
		if S.items.fert > 0:
			S.items.fert -= 1
			p.fert = true
			await say("Echas una dosis de ABONO. Dará más cosecha.")
		else:
			await say("No te queda ABONO.")
	elif op == "Tratar plaga":
		if S.items.insect > 0:
			S.items.insect -= 1
			p.pest = false
			await say("Aplicas INSECTICIDA con guantes y mascarilla. Plaga eliminada.")
		else:
			await say("No tienes INSECTICIDA.")
	elif op == "Arrancar":
		if await ask("¿Seguro que quieres arrancarla?", ["Sí", "No"]) == 0:
			S.pots[i] = null
			await say("Arrancas la planta.")

func plantar(i: int) -> void:
	var own := []
	for k in S.seeds:
		if S.seeds[k] > 0:
			own.append(k)
	if own.is_empty():
		await say("Maceta vacía. No te quedan semillas.")
		return
	var items := []
	for k in own:
		items.append("%s ×%d" % [Datos.strain(S, k).n, S.seeds[k]])
	items.append("Cancelar")
	var j := await menu(items, -1, "¿QUÉ PLANTAS?")
	if j < 0 or j >= own.size():
		return
	var sid: String = own[j]
	S.seeds[sid] -= 1
	if S.seeds[sid] <= 0:
		S.seeds.erase(sid)
	S.pots[i] = Cultivo.nueva_planta(S, sid)
	await say("Has plantado %s." % Datos.strain(S, sid).n)

func clase_feno(f) -> String:
	if not f is Dictionary:
		return "normal"
	var D := Datos.carga()
	return "estrella" if f.t * f.y >= D.FENO_ESTRELLA else ("floja" if f.t * f.y <= D.FENO_FLOJO else "normal")

func marca_feno(f) -> String:
	var v = S.fenos.get(str(f.id)) if f is Dictionary and f.get("id") else null
	return " ★" if v == "estrella" else (" (floja)" if v == "floja" else "")

func harvest(i: int) -> void:
	var p: Dictionary = S.pots[i]
	var s = Datos.strain(S, p.sid)
	var f := Cultivo.factores(S, i)
	var fe: Dictionary = p.f if p.get("f") is Dictionary else {"t": 1, "y": 1}
	var cl := clase_feno(p.get("f"))
	var g := Cultivo.gramos_planta(S, p, f)
	var thc := Cultivo.thc_cosecha(S, p, f)
	var k: String = p.sid + ("*" if cl == "estrella" else "")
	var b: Dictionary = S.buds.get(k, {"g": 0, "thc": 0.0})
	b.thc = (b.thc * b.g + thc * g) / (b.g + g)
	b.g += g
	S.buds[k] = b
	if fe.get("id"):
		S.fenos[str(fe.id)] = cl
	S.pots[i] = null
	await say("Cosechas %d g de %s. THC: %s%%." % [g, s.n, Datos.pct(thc)])
	if cl == "estrella":
		await say("¡Fenotipo estrella! THC ×%s y cosecha ×%s sobre la media de la %s." % [str(fe.t).replace(".", ","), str(fe.y).replace(".", ","), s.n])
	elif cl == "floja":
		await say("Fenotipo flojo: THC ×%s y cosecha ×%s de la media." % [str(fe.t).replace(".", ","), str(fe.y).replace(".", ",")])

func carpa_action() -> void:
	var D := Datos.carga()
	var c: Dictionary = S.carpas[VC.ci]
	var C: Dictionary = D.CARPAS[c.t]
	var F: Dictionary = D.FOCOS[c.foco]
	await ask("%s · %d plantas · %s\n%d W/m² · luz %s al día con plantas" % [C.n, C.plazas, F.n, Datos.jsround(F.w / (C.cm[0] * C.cm[2] / 1e4)), Datos.eur(Cultivo.luz_carpa(S, VC.ci))], ["Salir"])

# START: la cama del HTML (bedAction): hasta las 7 o siesta de 3 h; el tiempo pasa hora a hora y cada día llega la luz
func dormir() -> void:
	var tot := 0.0
	for k in S.buds:
		tot += S.buds[k].g
	var c := await ask("Día %d · %02d:%02d · %s\nCosecha guardada: %d g" % [S.day, int(S.min) / 60, int(S.min) % 60, Datos.eur(S.money), tot], ["Dormir hasta las 7", "Siesta de 3 h", "Nada"])
	if c > 1:
		return
	var mins: int = 180 if c == 1 else ((7 * 60 - int(S.min) + 1440) % 1440 if (7 * 60 - int(S.min) + 1440) % 1440 else 1440)
	var luz := Cultivo.avanza(S, mins)
	_guarda()
	_toast("Has descansado%s · Partida guardada" % (" · Luz −" + Datos.eur(luz) if luz else ""), 1.8)

# ---------- partida ----------
func _carga() -> Dictionary:
	var s := Cultivo.nuevo_estado()
	s.seeds = {"ria": 3, "limon": 2, "txoko": 2, "niebla": 2}
	s.fenos = {}
	if FileAccess.file_exists(GUARDADO):
		var j = JSON.parse_string(FileAccess.get_file_as_string(GUARDADO))
		if j is Dictionary and j.has("pots"):
			s = j
			for k in ["day", "min", "money", "fenoN"]:
				s[k] = int(s[k])
			for k in s.seeds:
				s.seeds[k] = int(s.seeds[k])
			for k in s.items:
				s.items[k] = int(s.items[k])
	return s

func _guarda() -> void:
	var f := FileAccess.open(GUARDADO, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(S))
