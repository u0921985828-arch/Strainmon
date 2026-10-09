# Ribera Verde (Godot) — una partida nueva jugada con los mandos desde el título, como lo haría una persona: título → NUEVA
# PARTIDA → la intro (con el nombre escrito a mano) → el prólogo (del caserío de Mendialde a la parada y el autobús) → el piso. Allí el menú START (Genoteca, Mochila, Móvil, Plantas, Objetivo,
# Guardar, Sonido y Salir), un paseo por la calle (la salida del felpudo y la puerta del portal) y, con lo que vendería Kiko
# (semillas, insecticida, la carpa de 100 y un foco de sodio: la tienda la recorre historia.gd), un ciclo de cultivo entero:
# andar hasta la carpa, abrirla (vista C con el CFL; desde la 1.10 todo el equipo tiene arte), colgar el foco de sodio, plantar las 4 plazas, cuidarlas cada mañana,
# volver a la cama a dormir y cosechar. Con la cosecha encima, a la calle: un agente de patrulla la ve, la sospecha llena la
# barra, salta la alarma y el jugador escapa corriendo por el portal. Al final, CONTINUAR desde el título carga la partida tal cual.
# Comprueba también los mandos (teclado, dedos en los mandos, varios a la vez, el ratón y Atrás), los menús en bucle, tocar el
# diálogo, el sonido (síntesis, música de cada sitio y SONIDO), el HUD, la ficha, las barras de cada planta (en transparencia
# las de delante de la elegida), el aviso de plaga y el de las secas de cada noche, los daños y que tratada vuelve a ser la de
# siempre, y que el aviso de arriba no pisa la ficha, el HUD ni START con 6 tamaños de ventana. Capturas `juego-*.png`.
#   xvfb-run … godot --path godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --resolution 1560x720
#     --script res://tests/ciclo.gd -- --salida <dir> [--azar N]
# Con --fixed-fps cada fotograma son 16,7 ms del reloj del juego: el tiempo que pasa andando, y con él el azar, sale siempre
# igual (--azar N cambia la semilla del Park-Miller, 4242 por defecto).
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Vista = preload("res://src/vista.gd")
const Arte = preload("res://src/arte.gd")
const UI = preload("res://src/ui.gd")
const DV := {"up": Vector2i(0, -1), "down": Vector2i(0, 1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0)}
const TECLA := {"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT, "A": KEY_Z, "B": KEY_X, "START": KEY_M}
var Juego
var J
var dir := ""
var fallos := []
var textos := []   # cada diálogo entero que ha salido, en orden

func _initialize() -> void:
	_corre.call_deferred()

func espera(n := 3) -> void:
	for k in n:
		await process_frame

# hasta que se cumpla f, como mucho n fotogramas
func hasta(f: Callable, n := 900) -> bool:
	for k in n:
		if f.call():
			return true
		await process_frame
	return f.call()

# una tecla, como el teclado del ordenador (06-controles: Z es A, X es B, M es START)
func tecla(b: String, on: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = TECLA[b]
	e.physical_keycode = TECLA[b]
	e.pressed = on
	Input.parse_input_event(e)

func pulsa(b: String, n := 3) -> void:
	tecla(b, true)
	await process_frame
	tecla(b, false)
	await espera(n)

# un dedo (índice) en el centro de un mando, como lo manda Android (Godot imita el ratón con el primero)
func toque(dedo: int, b: String, on: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = dedo
	e.position = J.botones[b].get_global_rect().get_center()
	e.pressed = on
	Input.parse_input_event(e)
	await espera(3)

# el dedo, sin levantarlo, del centro del mando a al del b en 6 pasos
func arrastra(dedo: int, a: String, b: String) -> void:
	var p0: Vector2 = J.botones[a].get_global_rect().get_center()
	var p1: Vector2 = J.botones[b].get_global_rect().get_center()
	for i in range(1, 7):
		var e := InputEventScreenDrag.new()
		e.index = dedo
		e.position = p0.lerp(p1, i / 6.0)
		Input.parse_input_event(e)
		await espera(1)
	await espera(2)

func clic(b: String) -> void:
	for on in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = J.botones[b].get_global_rect().get_center()
		e.global_position = e.position
		e.pressed = on
		Input.parse_input_event(e)
		await espera(3)

func foto(nombre: String) -> void:
	if dir == "":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("juego-%s.png" % nombre))

func check(que: String, ok: bool, si_falla := "") -> void:
	print(("OK     " if ok else "FALLO  ") + que + ("" if ok or si_falla == "" else "  → " + si_falla))
	if not ok:
		fallos.append(que)

func rect(c: Control) -> Rect2:
	return Rect2(c.position, c.size)

# ---------- diálogos y menús ----------
# A en cada diálogo (el primero acaba el texto a máquina, el segundo pasa) hasta que se cumpla f o salga un menú; apunta en
# textos cada diálogo entero. false si sale un menú antes
func pasa(f: Callable, n := 3000) -> bool:
	for k in n:
		if f.call():
			return true
		if J.menu_box.visible:
			return false
		if J.dlg.visible:
			if J.dlg_more.visible and (textos.is_empty() or textos[-1] != J.dlg_txt.text):
				textos.append(J.dlg_txt.text)
			await pulsa("A", 2)
		else:
			await process_frame
	return f.call()

func libre() -> bool:
	return await pasa(func(): return J.is_free() and J.pending.is_empty() and not J.P.moving)

func vista_libre() -> bool:
	return await pasa(func(): return J.mode == "carpa" and J.VC and not J.VC.ocupado and J.handlers.size() == 1)

# A hasta que salga el menú (el texto de una pregunta se escribe a máquina) y se baja hasta la opción
func elige(op: String) -> bool:
	if not await pasa(func(): return J.menu_box.visible):
		return false
	for k in J.m_items.size():
		if J.m_items[J.m_i].label == op:
			break
		await pulsa("down")
	if J.m_items[J.m_i].label != op:
		print("  (menú sin «%s»: %s)" % [op, J.m_items.map(func(x): return x.label)])
		return false
	await pulsa("A")
	return true

func etiquetas() -> Array:
	return J.m_items.map(func(x): return x.label) if J.menu_box.visible else []

# ---------- andar ----------
# el camino más corto por casillas libres (sin pisar puertas que no sean el destino)
func camino(dest: Vector2i) -> Array:
	var m: Dictionary = J.MAPS[J.S.map]
	var ini := Vector2i(J.P.x, J.P.y)
	var prev := {ini: ""}
	var cola := [ini]
	while cola.size():
		var c: Vector2i = cola.pop_front()
		if c == dest:
			break
		for d in DV:
			var v: Vector2i = c + DV[d]
			if prev.has(v) or J.tile_solid(m, v.x, v.y) or J.ent_at(v.x, v.y):
				continue
			if v != dest and m.doors.has("%d,%d" % [v.x, v.y]):
				continue
			prev[v] = d
			cola.append(v)
	if not prev.has(dest):
		return []
	var o := []
	var c := dest
	while c != ini:
		o.push_front(prev[c])
		c -= DV[prev[c]]
	return o

# con el dedo en la cruceta: cada tramo recto con el mando apretado hasta pisar su última casilla (con B, corriendo)
func anda(dest: Vector2i, corre := false) -> bool:
	await libre()
	var ds := camino(dest)
	if ds.is_empty() and Vector2i(J.P.x, J.P.y) != dest:
		return false
	if corre:
		await toque(1, "B", true)
	var rapido := true
	var i := 0
	while i < ds.size():
		var d: String = ds[i]
		var fin := Vector2i(J.P.x, J.P.y)
		while i < ds.size() and ds[i] == d:
			fin += DV[d]
			i += 1
		await toque(0, d, true)
		await hasta(func(): return Vector2i(J.P.x, J.P.y) == fin, 600)
		if corre:
			rapido = rapido and J.P.dur == 130.0
		await toque(0, d, false)
		await hasta(func(): return not J.P.moving, 120)
	if corre:
		await toque(1, "B", false)
		check("con B apretado, corre (130 ms por casilla)", rapido)
	return Vector2i(J.P.x, J.P.y) == dest

# mirar hacia d sin moverse (hacia una casilla sólida: si no, el dedo se suelta antes de los 90 ms del giro)
func mira(d: String) -> void:
	if J.P.dir == d:
		return
	await toque(0, d, true)
	await hasta(func(): return J.P.dir == d, 30)
	await toque(0, d, false)
	await hasta(func(): return not J.P.moving, 60)

# ---------- carpa ----------
func geo() -> Dictionary:
	return Vista.geo(J.S, J.VC.ci)

func plaza(i: int):
	for q in geo().pl:
		if q.i == i:
			return q
	return null

# con las flechas hasta la plaza i: primero la fila y luego de lado
func ir_a(i: int) -> bool:
	for k in 8:
		if J.VC.sel == i:
			return true
		var t = plaza(i)
		var c = plaza(J.VC.sel)
		if c == null:
			await pulsa("down")
		elif t.fila > c.fila:
			await pulsa("up")
		elif t.fila < c.fila:
			await pulsa("down")
		else:
			await pulsa("right" if t.x > c.x else "left")
	return J.VC.sel == i

func abre_carpa() -> bool:
	await pulsa("A")
	return await vista_libre()

func color(im: Image, x: int, y: int) -> String:
	return im.get_pixel(x, y).to_html(false)

# la planta de la plaza i en la vista C: con plaga lleva los daños encima (solo cambia el color de unos píxeles suyos, no la silueta)
func danos(i: int) -> Array:
	var v: Dictionary = plaza(i).v
	var p: Dictionary = J.S.pots[i]
	var sano := p.duplicate(true)
	sano.pest = false
	var a := Vista.img_planta(J.S, p, v)
	var b := Vista.img_planta(J.S, sano, v)
	var n := 0
	var silueta := true
	for y in a.get_height():
		for x in a.get_width():
			var c := a.get_pixel(x, y)
			var d := b.get_pixel(x, y)
			if c.a8 != d.a8:
				silueta = false
			elif c != d:
				n += 1
	return [n, silueta, Vista.clave_planta(J.S, sano, v), b]

# el aviso de arriba, sin pisar la ficha, SONIDO ni START y dentro de la pantalla del juego, con la ventana de cada tamaño;
# si no hay aviso, el más largo de los que salen al dormir
const TAMANOS := [Vector2i(1560, 720), Vector2i(2400, 1080), Vector2i(1280, 960), Vector2i(1024, 768), Vector2i(2560, 1600), Vector2i(800, 600)]
func check_aviso(cuando: String) -> void:
	var era: Vector2i = root.size
	var txt: String = J.toast_txt.get_parsed_text() if J.toast_box.visible else "Has descansado · Luz −25,00 € · Partida guardada"
	var mal := []
	var mal_m := []
	for t in TAMANOS:
		root.size = t
		if not J.toast_box.visible:
			J.toast(txt, 1800)
		await espera(4)
		var r := rect(J.toast_box)
		var fi := Rect2(J.escena.position + J.vc_info.position, J.vc_info.size)
		var ok: bool = root.get_visible_rect().size == Vector2(t) and J.toast_box.visible and not (J.vc_info.visible and r.intersects(fi)) \
			and not r.intersects(rect(J.botones.START)) and not r.intersects(rect(J.botones.MOVIL)) and not r.intersects(rect(J.botones.SONIDO)) and rect(J.pantalla).encloses(r)
		if not ok:
			mal.append("%dx%d" % [t.x, t.y])
			print("  aviso %s · ficha %s · START %s · SONIDO %s · pantalla %s" % [r, fi if J.vc_info.visible else "-", rect(J.botones.START), rect(J.botones.SONIDO), rect(J.pantalla)])
		# los mandos (1.10, en mm): dentro de la ventana y sin pisar el escenario de diálogos
		var v := Rect2(Vector2.ZERO, Vector2(t))
		var zonas := [J.zona_cruz, J.zona_ab, rect(J.botones.START), rect(J.botones.MOVIL), rect(J.botones.SONIDO)]
		if not zonas.all(func(z): return v.encloses(z) and not z.intersects(J.ui_rect())) or rect(J.botones.MOVIL).intersects(J.zona_cruz):
			mal_m.append("%dx%d" % [t.x, t.y])
			print("  mandos %s · escenario %s" % [zonas, J.ui_rect()])
		# la caja de vida del combate (bP) no queda debajo de A, B ni START (bp_r, como --bpr en el HTML)
		var bp_era: bool = J.bP.visible
		if not bp_era:
			J.bhud_pon({"e": ["TIRONERO", "VIDA", 1.0, Color("#58d080")], "p": ["ANDER", "12 g", 1.0, Color("#58d080"), "20/20 · 1300 €"]})
			await espera(2)
		var bp: Rect2 = J.bP.get_global_rect()
		if [J.botones.A, J.botones.B, J.botones.START].any(func(b): return b.get_global_rect().intersects(bp)) or not J.escena.get_global_rect().encloses(bp):
			mal_m.append("%dx%d (caja de vida)" % [t.x, t.y])
			print("  caja de vida %s · A %s · START %s" % [bp, J.botones.A.get_global_rect(), J.botones.START.get_global_rect()])
		if not bp_era:
			J.bhud_pon(null)
			J.bh = {}
	root.size = era
	await espera(4)
	check("el aviso no pisa la ficha, SONIDO ni START y cabe en la pantalla (%s; mal en: %s)" % [cuando, ", ".join(mal)], mal.is_empty())
	check("los mandos caben y no pisan el escenario de diálogos ni la caja de vida del combate (%s; mal en: %s)" % [cuando, ", ".join(mal_m)], mal_m.is_empty())

# lo más alto de una onda (16 bits con signo)
func pico(w: AudioStreamWAV) -> int:
	var d := w.data
	var m := 0
	for k in range(0, d.size() - 1, 2 * 37):
		m = maxi(m, absi(d.decode_s16(k)))
	return m

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func _corre() -> void:
	dir = arg("--salida", dir)
	Juego = load("res://src/juego.gd")
	Juego.GUARDADO = "user://prueba-ciclo.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.GUARDADO))
	UI.AJUSTES = "user://prueba-ajustes.json"   # el primer arranque: sin el aviso de edad aceptado
	DirAccess.remove_absolute(ProjectSettings.globalize_path(UI.AJUSTES))
	Cultivo.pm = int(arg("--azar", "4242"))   # el azar del Park-Miller: la prueba sale siempre igual
	J = load("res://juego.tscn").instantiate()
	root.add_child(J)
	await espera(10)
	await titulo_e_intro()
	await prologo()
	await menu_start()
	await paseo()
	await ciclo()
	await patrulla()
	await continuar()
	print("ciclo: %d fallos" % fallos.size())
	quit(1 if fallos.size() else 0)

# ---------- título, intro y nombre ----------
func titulo_e_intro() -> void:
	check("arranca en el título", J.mode == "title" and J.titulo.visible and J.pintor.modo == "title" and not J.hud.visible)
	# el primer arranque: el aviso de edad (+18) con su pregunta; aceptado, se guarda en los ajustes y no vuelve a salir
	textos.clear()
	var hay_aviso: bool = await hasta(func(): return J.dlg.visible, 60)
	await foto("0a-aviso")
	await pasa(func(): return false, 400)
	check("primer arranque: el aviso de edad (%s) y la pregunta (%s)" % [" / ".join(textos), ", ".join(etiquetas())], hay_aviso and textos.size() >= 1 and textos[0].contains("18 años") \
		and etiquetas() == ["TENGO 18 O MÁS", "SALIR"])
	await pulsa("A")
	await hasta(func(): return J.lock == 0 and J.handlers.is_empty(), 120)
	var aj = JSON.parse_string(FileAccess.get_file_as_string(UI.AJUSTES)) if FileAccess.file_exists(UI.AJUSTES) else {}
	check("aceptado, se guarda en los ajustes", J.aj.aviso and aj is Dictionary and aj.get("aviso") == true and J.mode == "title")
	await foto("0-titulo")
	await pulsa("A")
	await hasta(func(): return J.menu_box.visible, 120)
	check("sin partida guardada, el título: NUEVA PARTIDA, OPCIONES y CRÉDITOS (%s)" % ", ".join(etiquetas()), etiquetas() == ["NUEVA PARTIDA", "OPCIONES", "CRÉDITOS"])
	# CRÉDITOS: los créditos, las licencias enteras (Godot y las fuentes) y la privacidad, en un texto con scroll
	await elige("CRÉDITOS")
	await hasta(func(): return J.menu_box.visible and J.m_o.get("title") == "CRÉDITOS", 60)
	check("CRÉDITOS: %s" % ", ".join(etiquetas()), etiquetas() == ["CRÉDITOS", "LICENCIAS", "PRIVACIDAD", "VOLVER"])
	await elige("CRÉDITOS")
	await hasta(func(): return J.lector.visible, 60)
	await espera(3)
	await foto("0b-creditos")
	check("los créditos: autor, versión, fuentes y aviso de ficción", J.lector.visible and J.lector_txt.text.contains("Un juego de Eddie") and J.lector_txt.text.contains("0.5.0") \
		and J.lector_txt.text.contains("Open Font License") and J.lector_txt.text.contains("FICCIÓN") and J.lector.get_global_rect().encloses(J.lector_sc.get_global_rect()))
	await pulsa("B")
	await elige("LICENCIAS")
	await hasta(func(): return J.lector.visible, 60)
	await espera(3)
	var y0: int = J.lector_sc.scroll_vertical
	await pulsa("down")
	var baja: bool = J.lector_sc.scroll_vertical > y0
	var n: int = J.lector_pags.size()
	var todo := "\n\n".join(J.lector_pags)
	await pulsa("right")
	var pasa: bool = J.lector_i == 1 and J.lector_sc.scroll_vertical == 0 and J.lector_ttl.text.ends_with("2/%d" % n)
	await pulsa("left")
	pasa = pasa and J.lector_i == 0
	await foto("0c-licencias")
	var mayor := 0
	for pg in J.lector_pags:
		mayor = maxi(mayor, pg.length())
	check("LICENCIAS: la MIT de Godot, las OFL y las de terceros enteras, en %d páginas de %d letras como mucho; ▼ baja y ▶ ◀ pasan de página" % [n, mayor], todo.contains("Permission is hereby granted") \
		and todo.contains("SIL OPEN FONT LICENSE") and todo.contains("FreeType") and n > 1 and mayor <= 3500 and baja and pasa)
	J._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await espera(3)
	check("Atrás cierra las licencias", not J.lector.visible and J.menu_box.visible)
	await elige("VOLVER")
	# OPCIONES: la música de 25 en 25 % (y vuelta a 0 y a 100), el texto y SONIDO; se guardan al momento
	await hasta(func(): return J.menu_box.visible and etiquetas().has("OPCIONES"), 60)
	await elige("OPCIONES")
	await hasta(func(): return J.menu_box.visible and J.m_o.get("title") == "OPCIONES", 60)
	check("OPCIONES: %s" % ", ".join(etiquetas()), etiquetas() == ["MÚSICA", "EFECTOS", "TEXTO", "SONIDO", "VOLVER"] and J.m_items[0].right == "100 %")
	await elige("MÚSICA")
	await hasta(func(): return J.menu_box.visible, 60)
	var so0 = J.sonido
	var m0: bool = J.aj.musica == 0 and J.m_items[0].right == "0 %"
	await pulsa("A")
	await espera(3)
	var m1: bool = J.aj.musica == 1 and is_equal_approx(so0.vm, .25)
	for k in 3:
		await pulsa("A")
		await espera(3)
	aj = JSON.parse_string(FileAccess.get_file_as_string(UI.AJUSTES))
	check("MÚSICA: 100 → 0 → 25 … → 100 %, y se guarda", m0 and m1 and J.aj.musica == 4 and J.m_items[0].right == "100 %" and aj.get("musica") == 4.0)
	await elige("TEXTO")
	await hasta(func(): return J.menu_box.visible, 60)
	var rapido: bool = J.m_items[2].right == "RÁPIDO" and J.aj.texto == 1
	await pulsa("A")
	await espera(3)
	var momento: bool = J.m_items[2].right == "AL MOMENTO"
	await pulsa("A")
	await espera(3)
	check("TEXTO: normal → rápido → al momento → normal", rapido and momento and J.aj.texto == 0)
	await elige("VOLVER")
	await hasta(func(): return J.menu_box.visible and etiquetas().has("NUEVA PARTIDA"), 60)
	await elige("NUEVA PARTIDA")
	check("NUEVA PARTIDA empieza una", J.mode == "intro" or await hasta(func(): return J.mode == "intro", 120))
	# el sonido se pone en marcha con la primera tecla (como el AudioContext del navegador): los efectos y las canciones
	# sintetizados, no en silencio, y la música de la intro
	var so = J.sonido
	var oye := true
	var mudos := []
	for k in so.efectos:
		if pico(so.efectos[k]) < 100:
			mudos.append(k)
	for k in so.temas:
		if pico(so.temas[k]) < 100:
			mudos.append(k)
	oye = mudos.is_empty()
	if not oye:
		print("  en silencio: ", mudos, " · ", mudos.map(func(k): return pico(so.efectos[k] if so.efectos.has(k) else so.temas[k])))
	check("sonido: %d efectos y %d canciones sintetizados, ninguno en silencio" % [so.efectos.size(), so.temas.size()], so.listo and so.efectos.size() == 12 and so.temas.size() == J.D.TUNES.size() and oye)
	await hasta(func(): return so.actual == "home", 60)
	check("en la intro suena la música de casa", so.actual == "home" and so.musica.playing and so.musica.stream == so.temas.home)
	# tocar la caja de diálogo es A: acaba el texto que se está escribiendo
	await hasta(func(): return J.dlg.visible and J.dlg_txt.text.length() > 3, 300)
	var antes: String = J.dlg_txt.text
	var c: Vector2 = J.dlg.get_global_rect().get_center()
	for on in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = on
		e.position = c
		e.global_position = c
		root.push_input(e)
		await espera(2)
	check("tocar la caja de diálogo es A (acaba el texto: «%s…» → %d letras)" % [antes, J.dlg_txt.text.length()], J.dlg_txt.text.begins_with(antes) and J.dlg_txt.text.length() > antes.length() + 10 and J.dlg_more.visible)
	await foto("1-intro")
	# el nombre: menú en bucle (▲ en la primera pasa a la última y ▼ vuelve) y «Otro...» con el teclado
	check("la intro llega al menú del nombre", await pasa(func(): return J.menu_box.visible, 400) and etiquetas() == ["EDDIE", "ÁLEX", "LUR", "ANDER", "Otro..."])
	await pulsa("up")
	var vuelta: bool = J.m_i == 4
	await pulsa("down")
	check("menú en bucle: ▲ en la primera pasa a la última y ▼ vuelve", vuelta and J.m_i == 0)
	await pulsa("up")
	await pulsa("A")
	await hasta(func(): return J.name_box.visible and J.name_in.has_focus(), 60)
	check("«Otro...» abre la caja del nombre con el cursor dentro", J.name_box.visible and J.name_in.has_focus())
	for ch in "Naia":
		var e := InputEventKey.new()
		e.keycode = OS.find_keycode_from_string(ch.to_upper())
		e.unicode = ch.unicode_at(0)
		for on in [true, false]:
			e.pressed = on
			Input.parse_input_event(e.duplicate())
			await espera(1)
	await foto("2-nombre")
	var e := InputEventKey.new()
	e.keycode = KEY_ENTER
	for on in [true, false]:
		e.pressed = on
		Input.parse_input_event(e.duplicate())
		await espera(2)
	check("el nombre escrito, en mayúsculas («%s»)" % J.S.name, J.S.name == "NAIA" and not J.name_box.visible)
	textos.clear()
	await libre()
	check("Kiko te llama por tu nombre", textos.any(func(t): return t.begins_with("NAIA. Hacía años")))
	check("la partida empieza en el caserío de Mendialde (el prólogo), capítulo 1, en (2,4) y sin el título", J.mode == "world" and J.S.map == "casa-ama" and J.S.ch == 1 and Vector2i(J.P.x, J.P.y) == Vector2i(2, 4) \
		and not J.titulo.visible and J.pintor.modo == "world")
	check("HUD: «%s»" % J.hud_txt.text.replace("\n", " · "), J.hud.visible and J.hud_txt.text.begins_with("DÍA 1 · 08:") and J.hud_txt.text.contains("150 €"))
	check("guardada al empezar el capítulo", FileAccess.file_exists(Juego.GUARDADO))
	await hasta(func(): return J.toast_box.visible and J.toast_txt.get_parsed_text().contains("OBJETIVO"), 400)
	await foto("3-caserio")
	await check_aviso("el objetivo")

# ---------- el prólogo (1.10): del caserío a la parada de Mendialde, el autobús de ama hasta Ribera Verde y el portal del piso ----------
func prologo() -> void:
	check("el objetivo del prólogo: el autobús", J.objective_text().contains("autobús"))
	var m: Dictionary = J.MAPS["casa-ama"]
	var ex: Vector2i
	for k in m.exits:
		var p: PackedStringArray = k.split(",")
		ex = Vector2i(int(p[0]), int(p[1]))
	check("andando hasta la puerta del caserío (%d,%d)" % [ex.x, ex.y], await anda(ex))
	await toque(0, "down", true)
	await hasta(func(): return J.S.map == "mendialde", 120)
	await toque(0, "down", false)
	await libre()
	check("▼ en la puerta sale a Mendialde con la música de la calle", J.S.map == "mendialde" and J.sonido.actual == "town")
	var pa: Dictionary = J.D.PARADAS.mendialde
	check("andando hasta la parada (%d,%d)" % [pa.a[0], pa.a[1]], await anda(Vector2i(int(pa.a[0]), int(pa.a[1]))))
	await mira("left")
	await foto("3c-mendialde")
	await pulsa("A")
	var t0: int = J.S.min
	check("A en la parada: «¿A dónde vas?» solo con Ribera Verde (billete de ama)", await pasa(func(): return J.menu_box.visible) and etiquetas() == ["Ribera Verde", "Nada"]
		and J.m_items[0].right == "billete de ama")
	await elige("Ribera Verde")
	textos.clear()
	await libre()
	check("el autobús deja en Ribera Verde (7,12), sin pagar y con el reloj 40 min más tarde", J.S.map == "town" and Vector2i(J.P.x, J.P.y) == Vector2i(7, 12) and J.S.money == 150
		and J.S.min - t0 >= 40 and J.S.min - t0 < 46 and J.S.flags.get("llegada") == true and textos.any(func(t): return t.begins_with("Ribera Verde. El piso")))
	var puerta := Vector2i(-1, -1)
	for k in J.MAPS.town.doors:
		if J.MAPS.town.doors[k].to == "home":
			var p: PackedStringArray = k.split(",")
			puerta = Vector2i(int(p[0]), int(p[1]))
	await anda(puerta)
	await libre()
	check("por el portal, al piso: el objetivo es ya la carta", J.S.map == "home" and J.objective_text() == "Lee la carta que hay en la mesa.")
	await foto("3-piso")

# ---------- menú START ----------
func menu_start() -> void:
	await pulsa("START")
	await foto("3b-start")
	var l := etiquetas()
	check("START abre el menú (%s)" % ", ".join(l), l == ["GENOTECA", "MOCHILA", "MÓVIL", "PLANTAS", "OBJETIVO", "GUARDAR", "OPCIONES", "SALIR"])
	await elige("GENOTECA")
	check("Genoteca: %d filas, todas sin descubrir" % J.m_items.size(), J.m_items.size() == J.D.DEX.size() and J.m_items.all(func(x): return x.label.ends_with("??????")))
	await pulsa("B")
	await elige("MOCHILA")
	check("Mochila: dinero, la mochila (1 kg), vida y lo de siempre", J.m_items.size() == 7 and J.m_items[0].right == "150 €" and J.m_items[1].right == "0 de 1 kg")
	await pulsa("B")
	await elige("PLANTAS")
	check("Plantas: la sala (sin termohigrómetro), el armario con su foco y sus 2 plazas vacías", J.m_items.size() == 4 and J.m_items[0].label == "Sala" and J.m_items[0].right == "¿?" and J.m_items[1].label == "Armario 60×60" and J.m_items[2].label.ends_with("vacía"))
	await pulsa("B")
	textos.clear()
	await elige("OBJETIVO")
	await pasa(func(): return J.menu_box.visible and not J.dlg.visible)
	check("Objetivo: el capítulo y la carta", textos.size() == 2 and textos[0].begins_with("CAPÍTULO 1") and textos[0].contains("carta"))
	# OPCIONES · SONIDO apaga la música y los efectos (y lo dice el mando de arriba); otra vez, los enciende
	await pasa(func(): return J.menu_box.visible)
	var ini: bool = J.m_items.size() == 8 and J.m_items.all(func(x): return x.get("ic") != null)
	await elige("OPCIONES")
	await hasta(func(): return J.menu_box.visible and J.m_o.get("title") == "OPCIONES", 60)
	var sin_borrar: bool = not etiquetas().has("BORRAR PARTIDA")
	await elige("SONIDO")
	var so = J.sonido
	await hasta(func(): return J.menu_box.visible, 60)
	var calla: bool = not so.on and so.musica.volume_db == -80.0 and J.botones.SONIDO.text == "SILENCIO" and J.m_items[3].right == "NO"
	await elige("SONIDO")
	await hasta(func(): return J.menu_box.visible, 60)
	check("OPCIONES en el menú START (con su icono, como todas las filas; sin BORRAR PARTIDA): SONIDO apaga y enciende", ini and sin_borrar and calla and so.on and so.musica.volume_db == 0.0 and J.botones.SONIDO.text == "SONIDO")
	await elige("VOLVER")
	await hasta(func(): return J.menu_box.visible and etiquetas().has("GUARDAR"), 60)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.GUARDADO))
	textos.clear()
	await elige("GUARDAR")
	await pasa(func(): return J.menu_box.visible and not J.dlg.visible)
	check("Guardar: «Partida guardada.» y el archivo", textos == ["Partida guardada."] and FileAccess.file_exists(Juego.GUARDADO))
	await elige("SALIR")
	check("SALIR cierra el menú", await libre() and not J.menu_box.visible)
	# START otra vez lo cierra (startCloses)
	await pulsa("START")
	var abierto: bool = J.menu_box.visible
	await pulsa("START")
	check("START con el menú abierto lo cierra", abierto and await libre())
	# el mando SONIDO, con el dedo
	await toque(0, "SONIDO", true)
	await toque(0, "SONIDO", false)
	var off: bool = not so.on and J.botones.SONIDO.text == "SILENCIO"
	await toque(0, "SONIDO", true)
	await toque(0, "SONIDO", false)
	check("el mando SONIDO apaga y enciende", off and so.on and J.botones.SONIDO.text == "SONIDO")
	# START se toca en 48 × 48 dp aunque se vea más bajo (el mínimo de Android): un dedo justo encima de su borde lo aprieta
	var r: Rect2 = J.botones.START.get_global_rect()
	var dp: float = J._dp()
	var g: float = (48 * dp - r.size.y) / 2   # lo que crece por arriba
	var fuera := Vector2(r.get_center().x, r.position.y - minf(2 * dp, g / 2))
	check("START se toca en 48 dp de alto (%.0f px de %.0f; un dedo en y %.0f, encima del borde %.0f)" % [r.size.y, 48 * dp, fuera.y, r.position.y], g < 1 or (J.mando_en(fuera) == "START" and fuera.y < r.position.y))
	# Atrás andando por el mapa es la pausa (el menú START), no sale del juego; Atrás otra vez la cierra
	J._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await hasta(func(): return J.menu_box.visible, 30)
	var pausa: bool = J.menu_box.visible and etiquetas().has("GUARDAR")
	J._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check("Atrás andando abre la pausa (el menú START) y Atrás otra vez la cierra", pausa and await libre() and not J.menu_box.visible)
	# volver a la app andando por el mapa: en pausa
	J._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await hasta(func(): return J.menu_box.visible, 30)
	var pausa2: bool = J.menu_box.visible and etiquetas().has("GUARDAR")
	await pulsa("B")
	check("al volver a la app, en pausa (el menú START)", pausa2 and await libre())

# ---------- un paseo: el felpudo, la calle y el portal ----------
func paseo() -> void:
	var m: Dictionary = J.MAPS.home
	var ex: Vector2i
	for k in m.exits:
		var p: PackedStringArray = k.split(",")
		ex = Vector2i(int(p[0]), int(p[1]))
	check("andando con el dedo hasta el felpudo (%d,%d)" % [ex.x, ex.y], await anda(ex))
	var t0 := Vector2i(J.P.x, J.P.y)
	await toque(0, "down", true)
	await hasta(func(): return J.S.map == "town", 120)
	await toque(0, "down", false)
	await libre()
	var w: Dictionary = m.exits["%d,%d" % [ex.x, ex.y]]
	check("▼ en el felpudo sale a la calle (%d,%d) con su música" % [w.x, w.y], t0 == ex and J.S.map == "town" and Vector2i(J.P.x, J.P.y) == Vector2i(w.x, w.y) and J.sonido.actual == "town")
	await foto("4-calle")
	var puerta := Vector2i(-1, -1)
	for k in J.MAPS.town.doors:
		if J.MAPS.town.doors[k].to == "home":
			var p: PackedStringArray = k.split(",")
			puerta = Vector2i(int(p[0]), int(p[1]))
	await anda(puerta)
	await libre()
	check("por el portal, de vuelta al piso, con su música", J.S.map == "home" and J.sonido.actual == "home" and J.P.dir == "up")
	# contra la pared no se mueve
	await anda(Vector2i(3, 2))
	await toque(0, "up", true)
	await espera(30)
	await toque(0, "up", false)
	check("contra la pared, no se mueve", J.P.y == 2 and not J.P.moving)

# ---------- el ciclo ----------
func ciclo() -> void:
	var S: Dictionary = J.S
	# lo que vendería Kiko: 9 semillas, insecticida, la carpa de 100 en el hueco B y un foco de sodio de 400 W
	S.seeds = {"ria": 4, "limon": 3, "txoko": 2}
	S.items.insect = 2
	S.items.f_sodio400 = 1
	J.comprar_carpa("m100", 1)
	J.montar_casa()
	var sitio: Dictionary = J.D.SITIOS[1]
	var frente := Vector2i(int(sitio.x), int(sitio.y) + 1)
	check("andando (corriendo) hasta delante de la carpa de 100", await anda(frente, true))
	await mira("up")
	check("A delante de la carpa la abre: vista C con el CFL, la ficha y el HUD fuera", await abre_carpa() and J.VC.ci == 1 and J.pintor.modo == "carpaC" and J.vc_info.visible and not J.hud.visible)
	await check_aviso("al abrir la carpa")
	await foto("5-vista-c-cfl")
	# el foco: ▲ hasta arriba, A → Cambiar foco → Sodio 400 W
	await ir_a(geo().pl.filter(func(q): return q.fila == 1)[0].i)
	await pulsa("up")
	check("▲ desde la fila de atrás elige el foco", J.VC.sel == -1 and J.vc_texto.begins_with("Carpa 100×100" + J.D.FOCOS.cfl.n))
	await pulsa("A")
	await elige("Cambiar foco")
	await elige("Foco " + J.D.FOCOS.sodio400.n)
	await vista_libre()
	await espera(2)
	check("con el foco de sodio colgado, sigue la vista C", S.carpas[1].foco == "sodio400" and S.items.f_cfl == 1 and J.pintor.modo == "carpaC")
	# plantar: A en cada plaza vacía → menú de semillas → la primera que quede
	var orden := []
	for q in geo().pl:
		orden.append(q)
	orden.sort_custom(func(x, y): return x.fila < y.fila or (x.fila == y.fila and (x.x < y.x if x.fila == 0 else x.x > y.x)))
	for k in orden.size():
		await ir_a(orden[k].i)
		await pulsa("A")
		await hasta(func(): return J.menu_box.visible, 120)
		if k == 0:
			await foto("6-semillas")
			check("menú de semillas: ¿QUÉ PLANTAS?", J.m_o.get("title") == "¿QUÉ PLANTAS?" and etiquetas().has("Cancelar"))
			await pulsa("up")
			var vuelta: bool = J.m_i == J.m_items.size() - 1
			await pulsa("down")
			check("menú en bucle también aquí", vuelta and J.m_i == 0)
		await pulsa("A")
		if k == 0:
			textos.clear()
			await pasa(func(): return J.dlg_txt.text.contains("barra") and J.dlg_more.visible, 300)
			check("con la primera planta, la pista de las barras", textos.size() == 1 and textos[0].begins_with("Has plantado") and J.dlg_txt.text.begins_with("Cada planta lleva su barra"))
		await vista_libre()
	var n := 0
	for i in J.huecos().size():
		if S.pots[i] and J.huecos()[i].c == 1:
			n += 1
	check("4 plantas plantadas", n == 4)
	await ir_a(orden[3].i)
	# una barra encima de cada planta, sin pisarse y con sitio para el cursor; en la pantalla: el marco, el agua al 70 % en azul
	# (10 de 14) y la cosecha vacía
	await espera(3)
	await RenderingServer.frame_post_draw
	var bs: Array = Vista.barras(S, geo(), J.VC.sel)
	var pisan := false
	for e in bs:
		for f in bs:
			if e != f and e.caja.intersects(f.caja):
				pisan = true
	check("una barra encima de cada planta (%d), sin pisarse" % bs.size(), bs.size() == 4 and not pisan)
	var im: Image = J.sv.get_texture().get_image()
	var ox: int = (J.SW - 240) >> 1
	var pinta := true
	var fsel := Vista.fila_sel(geo(), J.VC.sel)
	var claras := 0
	for b in bs:
		var x: int = ox + b.r.position.x
		var y: int = b.r.position.y
		if b.fila < fsel:
			claras += 1
			pinta = pinta and color(im, x + 1, y) != "26262e" and color(im, x + 1, y + 2) != "4a92e0"
			continue
		pinta = pinta and color(im, x + 1, y) == "26262e" and color(im, x + 1, y + 2) == "4a92e0" and color(im, x + 10, y + 2) == "4a92e0"
		pinta = pinta and color(im, x + 11, y + 2) == "4a4a56" and color(im, x + 1, y + 5) == "4a4a56" and color(im, x + 14, y + 5) == "4a4a56"
	check("en la pantalla, cada barra con el agua al 70 %% y la cosecha vacía (%d en transparencia, delante de la elegida)" % claras, pinta and claras == 2)
	await foto("7-plantadas")
	# Atrás con un menú abierto es B (y no sale de la carpa)
	await pulsa("A")
	var abierto: bool = await pasa(func(): return J.menu_box.visible, 120) or J.menu_box.visible
	J._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await espera(3)
	check("Atrás con un menú abierto lo cierra", abierto and await vista_libre() and not J.menu_box.visible)
	# varios dedos a la vez: con uno en la cruceta, otro en A abre la planta; al soltar, nada se queda apretado
	var s0: int = J.VC.sel
	await toque(0, "left", true)
	await toque(1, "A", true)
	var con_dos: bool = J.VC.ocupado and J.dlg.visible and J.botones.left.button_pressed and J.botones.A.button_pressed
	await toque(1, "A", false)
	await toque(0, "left", false)
	check("con un dedo en la cruceta, A responde", con_dos and not J.botones.left.button_pressed and not J.botones.A.button_pressed and J.rep.is_empty())
	await pasa(func(): return J.menu_box.visible, 120)
	await pulsa("B")
	await vista_libre()
	await ir_a(s0)
	# el ratón de verdad (escritorio) también aprieta los mandos: A abre la planta y B cierra su menú
	await clic("A")
	var con_raton: bool = J.VC.ocupado
	await pasa(func(): return J.menu_box.visible, 120)
	await clic("B")
	check("con el ratón, A abre la planta y B cierra su menú", con_raton and await vista_libre())
	check("semillas gastadas: quedan 5", S.seeds.values().reduce(func(x, y): return x + y, 0) == 5)
	# la primera noche se sale con Atrás (B sin nada abierto); las demás, con B
	J._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check("Atrás en la carpa sin nada abierto sale al piso (y no cierra el juego)", await libre() and J.mode == "world" and J.VC == null and J.hud.visible and not J.vc_info.visible)
	# cada noche: a la cama (dormir hasta las 7) y vuelta a la carpa; cada mañana, plaza por plaza: la seca se retira, la lista
	# se cosecha y las demás se tratan si tienen plaga y se riegan. Hasta que no quede ninguna (como mucho 10 noches)
	var cama := Vector2i(1, 3)
	var noches := 0
	var avisos := 0
	var plagas := 0
	var tratadas := 0
	var danadas := 0
	var vistas := {}
	var modos := {"carpaC": "al colgar el foco de sodio"}
	var cosechadas := 0
	var muertas := 0
	var en_carpa := func():
		for i in J.huecos().size():
			if J.huecos()[i].c == 1 and S.pots[i] != null:
				return true
		return false
	while noches < 10 and en_carpa.call():
		var con_plaga := []
		var secas := []
		for p in S.pots:
			con_plaga.append(p != null and p.pest)
			secas.append(p != null and p.get("dead", false))
		var ok_cama := await anda(cama)
		await mira("left")
		await pulsa("A")
		textos.clear()
		var duerme := await elige("Dormir hasta las 7")
		var dia: int = S.day
		await libre()
		noches += 1
		check("noche %d: a la cama andando y a dormir hasta las 7 del día %d" % [noches, S.day], ok_cama and duerme and S.min >= 7 * 60 and S.min <= 7 * 60 + 2 and S.day == dia + 1,
			"cama %s · dormir %s · %d:%02d · día %d → %d · %s" % [ok_cama, duerme, S.min / 60, S.min % 60, dia, S.day, " | ".join(textos)])
		# al despertar, el aviso de las que han cogido plaga esta noche y el de las que se han secado, con su nombre
		var nuevas := []
		var nuevas_secas := []
		for i in S.pots.size():
			var p = S.pots[i]
			if p and p.pest and not p.get("dead") and not con_plaga[i]:
				nuevas.append(Datos.strain(S, p.sid).n)
			if p and p.get("dead") and not secas[i]:
				nuevas_secas.append(Datos.strain(S, p.sid).n)
		var aviso := ""
		var aviso_s := ""
		for t in textos:
			if t.begins_with("¡Plaga en "):
				aviso = t
			if t.contains("secado del todo"):
				aviso_s = t
		plagas += nuevas.size()
		if aviso != "":
			avisos += 1
		check("noche %d: %d con plaga nueva y %s" % [noches, nuevas.size(), "aviso" if aviso != "" else "sin aviso"], (aviso != "") == (nuevas.size() > 0) and nuevas.all(func(m): return aviso.contains(m)))
		check("noche %d: %d secas nuevas y %s" % [noches, nuevas_secas.size(), "aviso" if aviso_s != "" else "sin aviso"], (aviso_s != "") == (nuevas_secas.size() > 0) and nuevas_secas.all(func(m): return aviso_s.contains(m)))
		if noches == 1:
			await check_aviso("al despertar")
		print("noche %d: " % noches, S.pots.map(func(p): return "-" if p == null else "%s %.2f a%d s%d%s%s" % [p.sid, p.prog, p.water, p.health, " P" if p.pest else "", " M" if p.get("dead") else ""]))
		# vuelta a la carpa
		var ok_vuelta := await anda(frente)
		await mira("up")
		check("noche %d: de vuelta a la carpa andando" % noches, ok_vuelta and await abre_carpa())
		modos[J.pintor.modo] = "al abrir tras la noche %d" % noches
		if noches == 1 or noches == 2:
			await foto("8-noche%d" % noches)
		for q in orden:
			var i: int = q.i
			var p = S.pots[i]
			if p == null:
				continue
			await ir_a(i)
			vistas[9 if p.get("dead") else Cultivo.plant_stage(p)] = true
			if p.get("dead"):
				await pulsa("A")
				await vista_libre()
				muertas += 1
			elif p.prog >= 1:
				if cosechadas == 0:
					await foto("9-lista")
				await pulsa("A")
				await elige("Cosechar")
				await vista_libre()
				cosechadas += 1
			else:
				if p.pest and S.items.insect > 0:
					if geo().vc:
						var d := danos(i)
						check("con plaga, daños encima de la planta (%d px) sin cambiar su silueta" % d[0], d[0] > 0 and d[1])
						var kd := Vista.clave_planta(S, p, plaza(i).v)
						check("con plaga, en pantalla la textura dañada", kd != d[2] and Arte.texs.has(kd) and Arte.texs[kd].get_image().get_data() != d[3].get_data())
						if tratadas == 0:
							await foto("9b-plaga")
						await pulsa("A")
						await elige("Tratar plaga")
						await vista_libre()
						await espera(3)
						var k := Vista.clave_planta(S, p, plaza(i).v)
						var igual: bool = k == d[2] and Arte.texs.has(k) and Arte.texs[k].get_image().get_data() == d[3].get_data()
						check("tratada, la planta vuelve a ser la de siempre", not p.pest and igual)
						danadas += 1
					else:
						await pulsa("A")
						await elige("Tratar plaga")
						await vista_libre()
						check("tratada (vista B)", not p.pest)
					tratadas += 1
				await pulsa("A")
				await elige("Regar")
				await vista_libre()
				check("regada al 100 %", p.water == 100)
		modos[J.pintor.modo] = "al salir tras la noche %d" % noches
		await pulsa("B")
		await libre()
	check("ha pasado por plántula, vegetativo, floración y lista", vistas.has(1) and vistas.has(2) and vistas.has(3) and vistas.has(4))
	# con el atlas, la vista C siempre (también con plaga, secas y muertas); la B queda para cuando falta el arte
	check("siempre la vista C (%s)" % ", ".join(modos.keys().map(func(k): return "%s %s" % [k, modos[k]])), modos.has("carpaC") and not modos.has("carpa"))
	# con la semilla de siempre tiene que salir; con otra (--azar) puede no haber plaga, y entonces solo se dice
	var a := OS.get_cmdline_user_args()
	var hubo := plagas > 0 and avisos > 0 and tratadas > 0
	var que := "ha habido plaga (%d), aviso (%d) y tratamiento (%d, %d con los daños en la vista C)" % [plagas, avisos, tratadas, danadas]
	if a.find("--azar") >= 0 and not hubo:
		print("INFO   " + que)
	else:
		check(que, hubo)
	check("%d cosechadas y %d secas retiradas" % [cosechadas, muertas], cosechadas >= 3 and cosechadas + muertas == 4)
	var g0 := 0.0
	for k in S.buds:
		g0 += S.buds[k].g
	check("carpa vacía y %d g en el bote" % g0, not en_carpa.call() and g0 > 0)
	check("con la primera cosecha, el capítulo 2 y el SMS de Kiko", S.ch == 2 and S.flags.get("harvest1"))
	check("partida guardada", FileAccess.file_exists(Juego.GUARDADO) and not FileAccess.file_exists(Juego.GUARDADO + ".tmp"))
	await foto("10-cosecha")
	print("ciclo: %d noches" % noches)

# ---------- patrulla (1.10): con la cosecha encima, el jugador a 6 casillas del portal y un agente 3 más allá; la sospecha sube,
# salta la alarma y, corriendo con B por delante del agente, el portal la deja en la calle ----------
func patrulla() -> void:
	# deslizar en la cruceta (1.10): sin levantar el dedo, de ◀ a ▲ cambia de flecha; al soltar, nada se queda apretado
	await libre()
	await toque(0, "left", true)
	var ini: bool = J.held.left and J.botones.left.button_pressed
	await arrastra(0, "left", "up")
	var tras: bool = J.held.up and not J.held.left and J.botones.up.button_pressed and not J.botones.left.button_pressed
	await toque(0, "up", false)
	await hasta(func(): return not J.P.moving, 120)
	check("deslizando el dedo por la cruceta de ◀ a ▲ cambia de flecha sin levantarlo", ini and tras and not J.held.up and not J.held.left and J.rep.is_empty())
	var m: Dictionary = J.MAPS.home
	var ex: Vector2i
	for k in m.exits:
		var p: PackedStringArray = k.split(",")
		ex = Vector2i(int(p[0]), int(p[1]))
	await anda(ex)
	await toque(0, "down", true)
	await hasta(func(): return J.S.map == "town", 120)
	await toque(0, "down", false)
	await libre()
	var puerta := Vector2i(-1, -1)
	for k in J.MAPS.town.doors:
		if J.MAPS.town.doors[k].to == "home":
			var p: PackedStringArray = k.split(",")
			puerta = Vector2i(int(p[0]), int(p[1]))
	var pats: Array = J.ents.filter(func(e): return e.get("pat"))
	check("capítulo %d en el barrio: %d agente(s) de patrulla" % [J.S.ch, pats.size()], J.S.ch >= 2 and pats.size() == J.n_patrullas() and pats.size() >= 1)
	if pats.is_empty():
		return
	# una recta de calle de 9 casillas desde el portal: el jugador a 6, el agente a 9 mirándolo, quieto hasta la alarma
	var mt: Dictionary = J.MAPS.town
	var t := Vector2i(J.P.x, J.P.y)
	var lado := Vector2i(-1, -1)
	var sitio := Vector2i(-1, -1)
	var mira_a := ""
	for d in ["left", "right", "down", "up"]:
		var ok := sitio.x < 0
		for i in range(1, 10):
			var v: Vector2i = t + DV[d] * i
			ok = ok and v.x >= 0 and v.y >= 0 and v.x < mt.w and v.y < mt.h and J.re_calle().search(mt.g[v.y][v.x]) != null and not J.tile_solid(mt, v.x, v.y) \
				and not mt.doors.has("%d,%d" % [v.x, v.y]) and not mt.exits.has("%d,%d" % [v.x, v.y])
		if ok:
			lado = t + DV[d] * 6
			sitio = t + DV[d] * 9
			mira_a = {"down": "up", "up": "down", "left": "right", "right": "left"}[d]
	check("recta de calle junto al portal para la persecución: el jugador a (%d,%d), el agente a (%d,%d)" % [lado.x, lado.y, sitio.x, sitio.y], sitio.x >= 0)
	if sitio.x < 0:
		return
	var e: Dictionary = pats[0]
	for o in pats:   # quietos lejos mientras el jugador se aparta del portal
		o.merge({"espera": 1e9}, true)
	await anda(lado)
	for o in pats.slice(1):
		o.merge({"x": 1, "y": 1, "fx": 1, "fy": 1, "px": 16.0, "py": 16.0, "moving": false, "espera": 1e9, "caza": false}, true)
	e.merge({"x": sitio.x, "y": sitio.y, "fx": sitio.x, "fy": sitio.y, "px": sitio.x * 16.0, "py": sitio.y * 16.0, "dir": mira_a, "moving": false, "espera": 1e9, "caza": false}, true)
	J.reset_sosp()
	var f0 := Engine.get_process_frames()
	check("con %d g encima y el agente mirando, la sospecha sube" % int(J.total_buds()), await pasa(func(): return J.SOSP.v >= 40, 900))
	check("HUD al momento: la barra enseña la sospecha de este fotograma (%d %%, sospecha %.2f)" % [J.hud_sosp, J.SOSP.v], J.hud_sosp == int(floor(J.SOSP.v + .5)))
	J.update_hud()
	await foto("12-sospecha")
	check("HUD: la barra de SOSPECHA (%d %%)" % J.hud_sosp, J.hud.visible and J.hud_sosp >= 40 and not J.hud_alarma)
	check("se llena: ¡ALTO, POLICÍA! y el agente corre a por el jugador", await pasa(func(): return J.SOSP.alarma != null, 1500) and e.caza)
	print("patrulla: alarma en %d fotogramas" % (Engine.get_process_frames() - f0))
	var a0 := Vector2i(e.x, e.y)
	check("HUD al momento: ¡ALARMA! en el fotograma de la alarma", J.hud_alarma)
	J.update_hud()
	await foto("13-alarma")
	check("HUD: ¡ALARMA!", J.hud_alarma)
	# el «¡alto!» (PAT.alto): quieto hasta que se le acaba la espera, para que dé tiempo a reaccionar; luego corre
	f0 = Engine.get_process_frames()
	check("«¡alto!»: el agente se queda quieto antes de correr", await hasta(func(): return e.espera <= 0, 120) and Vector2i(e.x, e.y) == a0)
	print("patrulla: «¡alto!» de %d fotogramas desde la foto" % (Engine.get_process_frames() - f0))
	f0 = Engine.get_process_frames()
	check("corriendo (B) 6 casillas hasta el portal con el agente detrás", await anda(puerta, true))
	await libre()
	var corre := absi(e.x - a0.x) + absi(e.y - a0.y)
	print("patrulla: huida en %d fotogramas; el agente corre %d casillas" % [Engine.get_process_frames() - f0, corre])
	check("el agente persigue (%d casillas) y no alcanza al que corre" % corre, corre >= 3 and J.mode == "world")
	check("dentro del portal, la alarma y la sospecha se quedan en la calle", J.S.map == "home" and J.SOSP.alarma == null and J.SOSP.v == 0 and J.mode == "world")

# ---------- CONTINUAR: el juego de nuevo desde el título carga la partida guardada ----------
func continuar() -> void:
	await anda(Vector2i(4, 4))
	await pulsa("START")
	await elige("GUARDAR")
	await pasa(func(): return J.menu_box.visible and not J.dlg.visible)
	# lo guardado, con el menú aún abierto (el reloj del juego no corre): al cerrarlo puede pasar un minuto antes de mirarlo
	var S: Dictionary = J.S
	var esperado := {"name": S.name, "day": float(S.day), "min": float(S.min), "ch": float(S.ch), "seeds": S.seeds.keys(), "buds": S.buds.keys(), "money": float(S.money), "x": int(J.P.x), "y": int(J.P.y)}
	await elige("SALIR")
	await libre()
	J.queue_free()
	await espera(3)
	J = load("res://juego.tscn").instantiate()
	root.add_child(J)
	await espera(10)
	await pulsa("A")
	await hasta(func(): return J.menu_box.visible, 120)
	check("con partida guardada, el título pregunta, sin el aviso de edad otra vez (%s)" % ", ".join(etiquetas()), etiquetas() == ["CONTINUAR", "NUEVA PARTIDA", "OPCIONES", "CRÉDITOS"] and not J.dlg.visible)
	await pulsa("A")
	await libre()
	var T: Dictionary = J.S
	var hay := {"name": T.name, "day": float(T.day), "min": float(T.min), "ch": float(T.ch), "seeds": T.seeds.keys(), "buds": T.buds.keys(), "money": float(T.money), "x": int(J.P.x), "y": int(J.P.y)}
	check("CONTINUAR carga la partida tal cual (nombre, día, hora, capítulo, semillas y lotes en su orden, dinero y sitio)", hay == esperado and J.mode == "world")
	if hay != esperado:
		print("  guardado: ", esperado, "\n  cargado:  ", hay)
	await foto("11-continuar")
