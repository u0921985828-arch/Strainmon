# Landrace Hunters (Godot) — U1/U2 de la fase 5 del plan de Google Play: con Datos.PLAY, de NUEVA PARTIDA a la primera semilla
# plantada en menos de 90 s, jugado con los mandos desde la carga como una persona. Cuenta los fotogramas (con --fixed-fps 60,
# 16,7 ms cada uno), las pulsaciones y las cajas de diálogo; el tiempo de una persona es el de la prueba más 2,5 s por caja
# (leerla) y 0,4 s por pulsación. Comprueba también la flecha del objetivo (en el armario), que la carga ya no dura 3,6 s, el SMS
# de Kiko, que Julen está en el piso y que el itinerario va por «Regar» al plantar.
#   xvfb-run … godot --path godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --resolution 1560x720
#     --script res://tests/ftue.gd [-- --salida <dir>]
extends SceneTree

const Datos = preload("res://src/datos.gd")
const UI = preload("res://src/ui.gd")
const TECLA := {"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT, "A": KEY_Z, "B": KEY_X, "START": KEY_M}
const LEER := 2.5    # s por caja de diálogo
const PULSAR := 0.4  # s por pulsación
var Juego
var J
var fallos := []
var cajas := []      # cada caja de diálogo distinta
var pulsos := 0
var fot := 0

func _initialize() -> void:
	Datos.PLAY = true
	_corre.call_deferred()

func check(que: String, ok: bool) -> void:
	print(("OK     " if ok else "FALLO  ") + que)
	if not ok:
		fallos.append(que)

func espera(n := 3) -> void:
	for k in n:
		fot += 1
		await process_frame

func hasta(f: Callable, n := 900) -> bool:
	for k in n:
		if f.call():
			return true
		await espera(1)
	return f.call()

func pulsa(b: String, n := 3) -> void:
	pulsos += 1
	for on in [true, false]:
		var e := InputEventKey.new()
		e.keycode = TECLA[b]
		e.physical_keycode = TECLA[b]
		e.pressed = on
		Input.parse_input_event(e)
		await espera(1)
	await espera(n)

# A en cada caja de diálogo (apuntándola) hasta que se cumpla f o salga un menú
func pasa(f: Callable, n := 3000) -> bool:
	for k in n:
		if f.call():
			return true
		if J.menu_box.visible:
			return false
		if J.dlg.visible and J.dlg_more.visible:
			if cajas.is_empty() or cajas[-1] != J.dlg_txt.text:
				cajas.append(J.dlg_txt.text)
			await pulsa("A", 2)
		else:
			await espera(1)
	return f.call()

func elige(op: String) -> bool:
	if not await pasa(func(): return J.menu_box.visible):
		return false
	for k in J.m_items.size():
		if J.m_items[J.m_i].label == op:
			break
		await pulsa("down")
	if J.m_items[J.m_i].label != op:
		return false
	await pulsa("A")
	return true

# U4: −40 % de cajas de texto en los cap. 1-3. Antes, las de la historia entera del oráculo (pasos 0-17, del prólogo a pagar el
# primer plazo); ahora, las del arranque corto (las de esta prueba y la pregunta del nombre) y las de los pasos 6-17 que no quita RECORTE
const PASOS_13 := 18
const PASOS_FTUE := 6
func recorte(ftue: int) -> void:
	var O: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/historia.json"))
	var antes := 0
	var ahora := ftue
	var quitadas := 0
	var re := RegEx.create_from_string("^([^:a-zñ]{2,40}): ")
	for i in PASOS_13:
		for l in O.pasos[i].log:
			if l.begins_with("\n===") or l.begins_with("  [menú]"):
				continue
			antes += 1
			if i < PASOS_FTUE:
				continue
			var m := re.search(l)
			var raw: String = (l.substr(m.get_end()) if m else l).replace("EDDIE", "{N}")
			if J.D.RECORTE.quita.has(raw):
				quitadas += 1
			else:
				ahora += 1
	check("cap. 1-3: %d cajas → %d (−%d %%; %d quitadas por RECORTE, el arranque en %d)" % [antes, ahora, roundi(100.0 * (antes - ahora) / antes), quitadas, ftue], ahora <= antes * 0.6)

# U5: OPCIONES de accesibilidad (TAMAÑO DE TEXTO, ZURDO, DALTÓNICO, SIN DESTELLOS)
func accesibilidad() -> void:
	var dp: float = J._dp()
	var tam := []
	for t in 3:
		J.aj.tam = t
		J.ajustes_aplica()
		await espera(2)
		tam.append(J.dlg_txt.get_theme_font_size("font_size"))
	check("TAMAÑO DE TEXTO S < M < L y nunca por debajo de 14 sp (%s px; 14 sp = %.0f px)" % [tam, 14 * dp], tam[0] <= tam[1] and tam[1] < tam[2] and tam.all(func(x): return x >= roundi(14 * dp)))
	J.aj.tam = 1
	var cx := func(b): return J.botones[b].get_global_rect().get_center().x
	var a0: float = cx.call("A")
	var u0: float = cx.call("up")
	J.aj.zurdo = true
	J.ajustes_aplica()
	await espera(2)
	var rs := ["A", "B", "START", "MOVIL", "SONIDO"].map(func(b): return J.botones[b].get_global_rect())
	rs.append(J.cruz)
	var solapa := false
	for i in rs.size():
		for k in range(i + 1, rs.size()):
			solapa = solapa or rs[i].intersects(rs[k])
	check("ZURDO: A/B a la izquierda, la cruceta a la derecha y nada se pisa", a0 > u0 and cx.call("A") < cx.call("up") and not solapa)
	var sal := OS.get_cmdline_user_args()
	if sal.size() > 1 and sal[0] == "--salida":
		root.get_texture().get_image().save_png(sal[1] + "/ftue-zurdo.png")
	J.aj.zurdo = false
	J.aj.dalt = true
	J.aj.calma = true
	J.ajustes_aplica()
	var V = load("res://src/vista.gd")
	check("DALTÓNICO y SIN DESTELLOS llegan a la vista", V.DALTONICO and V.CALMA)
	J.aj.dalt = false
	J.aj.calma = false
	J.ajustes_aplica()

func _corre() -> void:
	Juego = load("res://src/juego.gd")
	Juego.GUARDADO = "user://prueba-ftue.json"
	Juego.SALTAR = false   # 0.51: sin la pregunta de saltar el tutorial (tests/saltar.gd)
	for x in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.GUARDADO + x))
	UI.AJUSTES = "user://prueba-ftue-ajustes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(UI.AJUSTES))
	J = load("res://juego.tscn").instantiate()
	root.add_child(J)
	await espera(5)
	var f0 := fot
	if J.mode == "carga":
		await hasta(func(): return J.mode == "title", 600)
	check("la carga ya no dura 3,6 s (%.1f s)" % ((fot - f0) / 60.0), J.mode == "title" and (fot - f0) / 60.0 < 1.5)
	await hasta(func(): return J.dlg.visible, 120)   # el aviso de edad, con su pregunta
	await pasa(func(): return J.menu_box.visible, 600)
	if J.menu_box.visible and J.m_items[0].label.begins_with("TENGO 18"):
		await pulsa("A")
	await hasta(func(): return J.menu_box.visible and J.m_items.any(func(x): return x.label == "NUEVA PARTIDA"), 300)
	check("NUEVA PARTIDA en el título", await elige("NUEVA PARTIDA"))
	f0 = fot
	pulsos = 0
	cajas.clear()
	await pasa(func(): return J.menu_box.visible, 1200)
	check("Kiko pregunta el nombre (%d cajas antes)" % cajas.size(), J.menu_box.visible and J.m_items[0].label == "EDDIE")
	if fallos.size():
		quit(1)
		return
	await pulsa("A")
	for q in 3:   # MAESTRO [1]: chico o chica, el mes y el día del cumpleaños (lo primero de cada uno)
		await hasta(func(): return J.menu_box.visible, 300)
		await pulsa("A")
	var listo := func(): return J.mode == "world" and J.is_free() and J.pending.is_empty() and not J.P.moving and not J.dlg.visible
	await pasa(listo, 3000)
	var S: Dictionary = J.S
	var si: Dictionary = J.sitio(0)
	check("empieza en el piso, delante del armario y mirándolo (%s %d,%d %s)" % [S.map, J.P.x, J.P.y, J.P.dir], S.map == "home" and Vector2i(J.P.x, J.P.y) == Vector2i(int(si.x), int(si.y) + 1) and J.P.dir == "up")
	check("con 3 semillas de Skunk #1, el SMS de Kiko y Julen en el piso", S.seeds.get("ria", 0) == 3 and S.sms.size() >= 1 and S.sms[0].n == "KIKO" and J.julen_aqui() \
		and J.ents.any(func(e): return e.id == "julen"))
	check("la flecha del objetivo, en el armario (%s)" % J.objetivo_xy(), J.objetivo_xy() == Vector2i(int(si.x), int(si.y)))
	var sal := OS.get_cmdline_user_args()
	if sal.size() > 1 and sal[0] == "--salida":
		await hasta(func(): return not J.toast_box.visible, 400)
		await espera(2)
		root.get_texture().get_image().save_png(sal[1] + "/ftue-flecha.png")
	check("el objetivo: plantar", J.objective_text().contains("planta una semilla"))
	var cajas_ftue := cajas.size()
	# A delante del armario: la vista C; A en la plaza elegida, el menú de semillas; A, la primera
	await pulsa("A")
	await pasa(func(): return J.mode == "carpa" and J.VC and not J.VC.ocupado and J.handlers.size() == 1, 600)
	if J.VC and J.VC.sel < 0:
		await pulsa("down")
	await pulsa("A")
	await pasa(func(): return J.menu_box.visible, 300)
	check("menú de semillas: ¿QUÉ PLANTAS?", J.m_o.get("title") == "¿QUÉ PLANTAS?")
	await pulsa("A")
	await hasta(func(): return S.pots.any(func(p): return p is Dictionary), 300)
	var t := (fot - f0) / 60.0
	var persona := t + cajas.size() * LEER + pulsos * PULSAR
	check("plantada: %.1f s de prueba · %d cajas · %d pulsaciones → %.0f s para una persona (≤ 90)" % [t, cajas.size(), pulsos, persona], S.pots.any(func(p): return p is Dictionary) and persona <= 90)
	await pasa(func(): return J.mode == "carpa" and J.VC and not J.VC.ocupado and J.handlers.size() == 1, 600)
	var sg = J.itin_sig()
	check("el itinerario sigue por «%s»" % (sg.t if sg else "—"), sg != null and sg.id == "regar")
	recorte(cajas_ftue + 1)
	# U4: A mantenida pasa las cajas sola; el registro de diálogo en START
	var hecho := {"v": false}
	var charla := func():
		await J.talk("KIKO", ["Uno.", "Dos.", "Tres.", "Cuatro."])
		hecho.v = true
	charla.call()
	var f1 := fot
	var e := InputEventKey.new()
	e.keycode = KEY_Z
	e.physical_keycode = KEY_Z
	e.pressed = true
	Input.parse_input_event(e)
	await hasta(func(): return hecho.v, 600)
	var e2: InputEventKey = e.duplicate()
	e2.pressed = false
	Input.parse_input_event(e2)
	await espera(3)
	check("A mantenida: 4 cajas en %.1f s sin soltarla" % ((fot - f1) / 60.0), hecho.v and (fot - f1) / 60.0 < 3.0)
	check("el registro guarda la charla", J.registro.size() >= 4 and J.registro[-1] == "KIKO: Cuatro.")
	await pulsa("B")
	await pasa(func(): return J.mode == "world" and J.is_free() and J.pending.is_empty() and not J.dlg.visible, 900)
	await pulsa("START")
	var hay: bool = J.menu_box.visible and J.m_items.any(func(x): return x.label == "REGISTRO")
	if not hay:
		print("  modo %s · menú %s %s · libre %s" % [J.mode, J.menu_box.visible, J.m_items.map(func(x): return x.label), J.is_free()])
	check("START → REGISTRO", hay and await elige("REGISTRO"))
	await pulsa("B")
	await pulsa("B")
	await accesibilidad()
	print("ftue: %.0f s · %d fallos" % [persona, fallos.size()])
	quit(1 if fallos.size() else 0)
