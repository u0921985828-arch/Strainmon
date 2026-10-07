# Ribera Verde (Godot) — un ciclo de cultivo entero jugado con los botones, como lo haría una persona:
# plantar las 4 plazas, dormir (START) y regar hasta que estén listas, y cosechar. Guarda capturas de la pantalla del juego.
# Comprueba también las barras de cada planta, el aviso de plaga al despertar, los daños encima de la planta (y que tratada
# vuelve a ser la de siempre) y que el aviso de arriba no pisa la ficha ni START.
#   xvfb-run … godot --path godot --rendering-driver opengl3 --resolution 1560x720 --script res://tests/ciclo.gd -- --salida <dir> [--azar N]
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Vista = preload("res://src/vista.gd")
const Arte = preload("res://src/arte.gd")
var J
var dir := ""
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func espera(n := 3) -> void:
	for k in n:
		await process_frame

func pulsa(b: String, n := 3) -> void:
	J.press(b)
	await espera(n)

# un dedo (índice) en el centro de un mando, como lo manda Android (Godot imita el ratón con el primero)
func toque(dedo: int, b: String, on: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = dedo
	e.position = J.botones[b].get_global_rect().get_center()
	e.pressed = on
	Input.parse_input_event(e)
	await espera(3)

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

func rect(c: Control) -> Rect2:
	return Rect2(c.position, c.size)

# el aviso de arriba, sin pisar la ficha ni START y dentro de la pantalla del juego, con la ventana de cada tamaño; si no
# hay aviso, el más largo de los que salen al dormir
const TAMANOS := [Vector2i(1560, 720), Vector2i(2400, 1080), Vector2i(1280, 960), Vector2i(1024, 768), Vector2i(2560, 1600), Vector2i(800, 600)]
func check_aviso(cuando: String) -> void:
	var era: Vector2i = root.size
	var txt: String = J.toast_txt.text if J.toast.visible else "Has descansado · Luz −25,00 € · Partida guardada"
	var mal := []
	for t in TAMANOS:
		root.size = t
		if not J.toast.visible:
			J._toast(txt, 1.8)
		await espera(4)
		var r := rect(J.toast)
		var ok: bool = root.get_visible_rect().size == Vector2(t) and J.toast.visible and not (J.ficha.visible and r.intersects(rect(J.ficha))) and not r.intersects(rect(J.botones.START)) and rect(J.pantalla).encloses(r)
		if not ok:
			mal.append("%dx%d" % [t.x, t.y])
	root.size = era
	await espera(4)
	check("el aviso no pisa la ficha ni START y cabe en la pantalla (%s; mal en: %s)" % [cuando, ", ".join(mal)], mal.is_empty())

func color(im: Image, x: int, y: int) -> String:
	return im.get_pixel(x, y).to_html(false)

# la planta de la plaza i: con plaga lleva los daños encima (solo cambia el color de unos píxeles suyos, no la silueta)
func danos(i: int) -> Array:
	var g = Vista.geo(J.S, 0)
	var v: Dictionary
	for q in g.pl:
		if q.i == i:
			v = q.v
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

func check(que: String, ok: bool) -> void:
	print(("OK     " if ok else "FALLO  ") + que)
	if not ok:
		fallos.append(que)

func _corre() -> void:
	var a := OS.get_cmdline_user_args()
	if a.find("--salida") >= 0:
		dir = a[a.find("--salida") + 1]
	var Juego = load("res://src/juego.gd")
	Juego.GUARDADO = "user://prueba-ciclo.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.GUARDADO))
	J = load("res://juego.tscn").instantiate()
	root.add_child(J)
	await espera(10)
	await foto("0-inicio")
	await check_aviso("al empezar")
	Cultivo.pm = int(a[a.find("--azar") + 1]) if a.find("--azar") >= 0 else 4242   # el azar del Park-Miller: la prueba sale siempre igual
	var S: Dictionary = J.S
	# plantar: A en cada plaza vacía → menú de semillas → la primera que quede → aviso
	for k in 4:
		var plazas := [0, 1, 3, 2]   # ▶ en la fila de delante; ▲ a la de atrás y ◀
		await pulsa("A")
		if k == 0:
			await foto("1-semillas")
			# el menú va en bucle, como el del HTML
			await pulsa("up")
			var vuelta: bool = J.m_sel == J.m_opts.size() - 1
			await pulsa("down")
			check("menú en bucle: ▲ en la primera pasa a la última y ▼ vuelve", vuelta and J.m_sel == 0)
		await pulsa("A")
		if k == 0:
			# tocar la caja de diálogo es A
			var c: Vector2 = J.dlg.get_global_rect().get_center()
			var antes: String = J.dlg_txt.text
			for pulsado in [true, false]:
				var e := InputEventMouseButton.new()
				e.button_index = MOUSE_BUTTON_LEFT
				e.pressed = pulsado
				e.position = c
				e.global_position = c
				root.push_input(e)
				await espera(2)
			check("tocar la caja de diálogo es A", not J.dlg.visible or J.dlg_txt.text != antes)
			check("con la primera planta, la pista de las barras", J.modo == "say" and J.dlg_txt.text.contains("barra"))
			while J.modo == "say":
				await pulsa("A")
		else:
			await pulsa("A")
		if k == 0:
			await pulsa("right")
		elif k == 1:
			await pulsa("up")
		elif k == 2:
			await pulsa("left")
	var n := 0
	for p in S.pots:
		if p:
			n += 1
	check("4 plantas plantadas", n == 4)
	# una barra encima de cada planta, sin pisarse y con sitio para el cursor; en la pantalla: el marco, el agua al 70 % en azul
	# (10 de 14) y la cosecha vacía
	await espera(3)
	await RenderingServer.frame_post_draw
	var bs: Array = Vista.barras(S, Vista.geo(S, 0), J.VC.sel)
	var pisan := false
	for e in bs:
		for f in bs:
			if e != f and e.caja.intersects(f.caja):
				pisan = true
	check("una barra encima de cada planta (%d), sin pisarse" % bs.size(), bs.size() == 4 and not pisan)
	var im: Image = J.sv.get_texture().get_image()
	var ox: int = (J.sw - 240) >> 1
	var pinta := true
	var fsel := Vista.fila_sel(Vista.geo(S, 0), J.VC.sel)
	var claras := 0
	for b in bs:
		var x: int = ox + b.r.position.x
		var y: int = b.r.position.y
		if b.fila < fsel:
			# delante de la fila elegida, en transparencia como su planta: ni el marco ni el agua con su color lleno
			claras += 1
			pinta = pinta and color(im, x + 1, y) != "26262e" and color(im, x + 1, y + 2) != "4a92e0"
			continue
		pinta = pinta and color(im, x + 1, y) == "26262e" and color(im, x + 1, y + 2) == "4a92e0" and color(im, x + 10, y + 2) == "4a92e0"
		pinta = pinta and color(im, x + 11, y + 2) == "4a4a56" and color(im, x + 1, y + 5) == "4a4a56" and color(im, x + 14, y + 5) == "4a4a56"
	check("en la pantalla, cada barra con el agua al 70 %% y la cosecha vacía (%d en transparencia, delante de la elegida)" % claras, pinta and claras < bs.size())
	# Atrás con un menú abierto es B (y no cierra el juego)
	await pulsa("A")
	var abierto: bool = J.modo == "menu"
	J._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await espera(3)
	check("Atrás con un menú abierto lo cierra", abierto and J.modo == "" and not J.VC.ocupado)
	# varios dedos a la vez: con uno en la cruceta, otro en A abre el menú de la planta; al soltar, nada se queda apretado
	await toque(0, "left", true)
	await toque(1, "A", true)
	var con_dos: bool = J.modo == "menu" and J.botones.left.button_pressed and J.botones.A.button_pressed
	await toque(1, "A", false)
	await toque(0, "left", false)
	check("con un dedo en la cruceta, A responde", con_dos and not J.botones.left.button_pressed and not J.botones.A.button_pressed and J.rep_b == "")
	await pulsa("B")
	# el ratón de verdad (escritorio) también aprieta los mandos: A abre el menú y B lo cierra
	await clic("A")
	var con_raton: bool = J.modo == "menu"
	await clic("B")
	check("con el ratón, A abre el menú y B lo cierra", con_raton and J.modo == "")
	check("semillas gastadas: quedan 5", S.seeds.values().reduce(func(x, y): return x + y, 0) == 5)
	await foto("2-plantadas")
	# cada mañana, plaza por plaza: la seca se retira, la lista se cosecha y las demás se tratan si tienen plaga y se riegan;
	# luego START → dormir hasta las 7. Hasta que no quede ninguna (como mucho 8 noches)
	var noches := 0
	var avisos := 0
	var plagas := 0
	var tratadas := 0
	var vistas := {}
	var cosechadas := 0
	var muertas := 0
	while noches < 8 and S.pots.any(func(p): return p != null):
		for paso in ["", "right", "down", "left"]:
			if paso != "":
				await pulsa(paso)
			var p = S.pots[J.VC.sel]
			if p == null:
				continue
			if p.get("dead"):
				await pulsa("A")
				await pulsa("A")
				await pulsa("A")
				muertas += 1
			elif p.prog >= 1:
				if cosechadas == 0:
					await foto("5-lista")
				await pulsa("A")
				await pulsa("A")
				while J.modo == "say":
					await pulsa("A")
				cosechadas += 1
			else:
				if p.pest and S.items.insect > 0:
					var d := danos(J.VC.sel)
					check("con plaga, daños encima de la planta (%d px) sin cambiar su silueta" % d[0], d[0] > 0 and d[1])
					# la que se pinta ahora es la dañada (su textura ya está hecha y no es la sana)
					var kd := Vista.clave_planta(S, p, Vista.geo(S, 0).pl.filter(func(q): return q.i == J.VC.sel)[0].v)
					check("con plaga, en pantalla la textura dañada", kd != d[2] and Arte.texs.has(kd) and Arte.texs[kd].get_image().get_data() != d[3].get_data())
					if tratadas == 0:
						await foto("4b-plaga")
					await pulsa("A")
					while J.m_opts[J.m_sel] != "Tratar plaga":
						await pulsa("down")
					await pulsa("A")
					await pulsa("A")
					await espera(3)
					var k := Vista.clave_planta(S, p, Vista.geo(S, 0).pl.filter(func(q): return q.i == J.VC.sel)[0].v)
					var igual: bool = k == d[2] and Arte.texs.has(k) and Arte.texs[k].get_image().get_data() == d[3].get_data()
					check("tratada, la planta vuelve a ser la de siempre", not p.pest and igual)
					tratadas += 1
				await pulsa("A")    # Regar es la primera opción
				if noches == 2 and paso == "":
					await foto("4-preguntar")
				await pulsa("A")
				await pulsa("A")
		if not S.pots.any(func(p): return p != null):
			break
		await pulsa("up")
		if noches == 0:
			await pulsa("up")
			check("▲ desde la fila de atrás elige el foco", J.VC.sel == -1)
			await foto("6-foco")
			await pulsa("down")
		var con_plaga := []
		var secas := []
		for p in S.pots:
			con_plaga.append(p != null and p.pest)
			secas.append(p != null and p.get("dead", false))
		await pulsa("START")
		await pulsa("A")
		noches += 1
		await espera(4)
		# al despertar, el aviso de las que han cogido plaga esta noche, con su nombre
		var nuevas := []
		for i in S.pots.size():
			var p = S.pots[i]
			if p and p.pest and not p.get("dead") and not con_plaga[i]:
				nuevas.append(Datos.strain(S, p.sid).n)
		var nuevas_secas := []
		for i in S.pots.size():
			var p = S.pots[i]
			if p and p.get("dead") and not secas[i]:
				nuevas_secas.append(Datos.strain(S, p.sid).n)
		var aviso := ""
		var aviso_s := ""
		while J.modo == "say":
			if J.dlg_txt.text.begins_with("¡Plaga en "):
				aviso = J.dlg_txt.text
			if J.dlg_txt.text.contains("secado del todo"):
				aviso_s = J.dlg_txt.text
			await pulsa("A")
		plagas += nuevas.size()
		if aviso != "":
			avisos += 1
		check("noche %d: %d con plaga nueva y %s" % [noches, nuevas.size(), "aviso" if aviso != "" else "sin aviso"], (aviso != "") == (nuevas.size() > 0) and nuevas.all(func(m): return aviso.contains(m)))
		check("noche %d: %d secas nuevas y %s" % [noches, nuevas_secas.size(), "aviso" if aviso_s != "" else "sin aviso"], (aviso_s != "") == (nuevas_secas.size() > 0) and nuevas_secas.all(func(m): return aviso_s.contains(m)))
		await check_aviso("al despertar")
		for p in S.pots:
			if p:
				vistas[9 if p.get("dead") else Cultivo.plant_stage(p)] = true
		print("noche %d: " % noches, S.pots.map(func(p): return "-" if p == null else "%s %.2f a%d s%d%s%s" % [p.sid, p.prog, p.water, p.health, " P" if p.pest else "", " M" if p.get("dead") else ""]))
		if noches == 1 or noches == 2:
			await foto("3-noche%d" % noches)
	check("ha pasado por plántula, vegetativo, floración y lista", vistas.has(1) and vistas.has(2) and vistas.has(3) and vistas.has(4))
	# con la semilla de siempre tiene que salir; con otra (--azar) puede no haber plaga, y entonces solo se dice
	var hubo := plagas > 0 and avisos > 0 and tratadas > 0
	var que := "ha habido plaga (%d), aviso (%d) y tratamiento (%d)" % [plagas, avisos, tratadas]
	if a.find("--azar") >= 0 and not hubo:
		print("INFO   " + que)
	else:
		check(que, hubo)
	check("%d cosechadas y %d secas retiradas" % [cosechadas, muertas], cosechadas >= 3 and cosechadas + muertas == 4)
	var g0 := 0.0
	for k in S.buds:
		g0 += S.buds[k].g
	var vacias: bool = S.pots.all(func(p): return p == null)
	check("carpa vacía y %d g en el bote" % g0, vacias and g0 > 0)
	check("partida guardada", FileAccess.file_exists(J.GUARDADO) and not FileAccess.file_exists(J.GUARDADO + ".tmp"))
	var g = JSON.parse_string(FileAccess.get_file_as_string(J.GUARDADO))
	check("guardada con las semillas en su orden (%s)" % ", ".join(S.seeds.keys()), g is Dictionary and g.seeds.keys() == S.seeds.keys())
	await foto("7-cosecha")
	print("ciclo: %d noches, %d fallos" % [noches, fallos.size()])
	quit(1 if fallos.size() else 0)
