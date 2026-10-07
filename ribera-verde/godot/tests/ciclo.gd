# Ribera Verde (Godot) — un ciclo de cultivo entero jugado con los botones, como lo haría una persona:
# plantar las 4 plazas, dormir (START) y regar hasta que estén listas, y cosechar. Guarda capturas de la pantalla del juego.
#   xvfb-run … godot --path godot --rendering-driver opengl3 --resolution 1560x720 --script res://tests/ciclo.gd -- --salida <dir>
extends SceneTree

const Cultivo = preload("res://src/cultivo.gd")
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

func foto(nombre: String) -> void:
	if dir == "":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("juego-%s.png" % nombre))

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
	Cultivo.pm = 4242   # el azar del Park-Miller: la prueba sale siempre igual
	var S: Dictionary = J.S
	# plantar: A en cada plaza vacía → menú de semillas → la primera que quede → aviso
	for k in 4:
		var plazas := [0, 1, 3, 2]   # ▶ en la fila de delante; ▲ a la de atrás y ◀
		await pulsa("A")
		if k == 0:
			await foto("1-semillas")
		await pulsa("A")
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
	check("semillas gastadas: quedan 5", S.seeds.values().reduce(func(x, y): return x + y, 0) == 5)
	await foto("2-plantadas")
	# cada mañana, plaza por plaza: la seca se retira, la lista se cosecha y las demás se tratan si tienen plaga y se riegan;
	# luego START → dormir hasta las 7. Hasta que no quede ninguna (como mucho 8 noches)
	var noches := 0
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
					await pulsa("A")
					while J.m_opts[J.m_sel] != "Tratar plaga":
						await pulsa("down")
					await pulsa("A")
					await pulsa("A")
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
		await pulsa("START")
		await pulsa("A")
		noches += 1
		await espera(4)
		for p in S.pots:
			if p:
				vistas[9 if p.get("dead") else Cultivo.plant_stage(p)] = true
		print("noche %d: " % noches, S.pots.map(func(p): return "-" if p == null else "%s %.2f a%d s%d%s%s" % [p.sid, p.prog, p.water, p.health, " P" if p.pest else "", " M" if p.get("dead") else ""]))
		if noches == 1 or noches == 2:
			await foto("3-noche%d" % noches)
	check("ha pasado por plántula, vegetativo, floración y lista", vistas.has(1) and vistas.has(2) and vistas.has(3) and vistas.has(4))
	check("%d cosechadas y %d secas retiradas" % [cosechadas, muertas], cosechadas >= 3 and cosechadas + muertas == 4)
	var g0 := 0.0
	for k in S.buds:
		g0 += S.buds[k].g
	var vacias: bool = S.pots.all(func(p): return p == null)
	check("carpa vacía y %d g en el bote" % g0, vacias and g0 > 0)
	check("partida guardada", FileAccess.file_exists(J.GUARDADO))
	await foto("7-cosecha")
	print("ciclo: %d noches, %d fallos" % [noches, fallos.size()])
	quit(1 if fallos.size() else 0)
