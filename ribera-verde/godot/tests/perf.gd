# Landrace Hunters (Godot) — medidas de rendimiento de la fase 4 del plan de Google Play (R1-R15): arranque, draw calls y redibujos
# por fotograma en la calle (town), en una carpa con sus plantas y con el menú START abierto, la memoria tras recorrer todas las
# escenas de tests/pantallas.json varias veces y la escala de la pantalla a 720p. No compara con nada: escribe las cifras.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 --script res://tests/perf.gd --
#     --sin-arranque [--salida <archivo>]   → «perf: …»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var redib := 0   # veces que se ha pintado la capa 0 del lienzo

func _initialize() -> void:
	Datos.PLAY = true
	Datos.CAL = false   # los estados de pantallas.json son del HTML congelado
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func escena(O: Array, k: String) -> Dictionary:
	for x in O:
		if x.k == k:
			return Datos.enteros(x)
	return {}

# como en tests/pantallas.gd
func monta(e: Dictionary) -> void:
	J.SW = int(e.sw)
	J.sv.size = Vector2i(J.SW, J.SH)
	J.S = e.S
	J.B = e.B
	J.VC = e.VC
	J.TIRO = e.get("TIRO")
	J.MESA_B = e.get("MESA_B")
	J.ALMACEN = e.get("ALMACEN")
	J.ORDEN = e.get("ORDEN")
	J.vfx = e.vfx
	J.ents = []
	if e.mode == "world" or e.mode == "carpa":
		J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
		J.SOSP = e.SOSP
	for c in e.P:
		J.P[c] = e.P[c]
	J.mode = e.mode

# n fotogramas de verdad: draw calls (todo lo que pinta el fotograma), redibujos del lienzo y tiempo de proceso medios
func mide(n: int) -> Dictionary:
	for k in 5:
		await process_frame
	var dc := 0.0
	var tp := 0.0
	var r0 := redib
	var t0 := Time.get_ticks_usec()
	for k in n:
		await RenderingServer.frame_post_draw
		dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		tp += Performance.get_monitor(Performance.TIME_PROCESS) * 1000
	return {"dc": dc / n, "redib": float(redib - r0) / n, "proc_ms": tp / n, "frame_ms": (Time.get_ticks_usec() - t0) / 1000.0 / n}

func _corre() -> void:
	var sal := arg("--salida")
	Juego.GUARDADO = "user://prueba-perf.json"
	Juego.AJUSTES = "user://prueba-perf-ajustes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.AJUSTES))
	var L := []
	var t0 := Time.get_ticks_msec()
	Datos.carga()
	J = Juego.new()
	root.add_child(J)
	await process_frame
	var t_arr := Time.get_ticks_msec() - t0
	L.append("arranque (datos, atlas, fuentes, sonido y primer fotograma): %d ms" % t_arr)
	J.pintor.ambiente_on = false
	J.pintor.c0.draw.connect(func(): redib += 1)
	var O: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var m0 := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	L.append("memoria estática tras arrancar: %.1f MB" % m0)

	# la calle (town)
	var e: Dictionary = escena(O, "calle-plaza")
	e.sw = 320
	monta(e)
	var r := await mide(120)
	L.append("town: %.0f draw calls/fotograma · %.2f redibujos/fotograma · proceso %.2f ms · fotograma %.2f ms" % [r.dc, r.redib, r.proc_ms, r.frame_ms])

	# el menú START abierto en la calle
	J.run(J.start_menu)
	r = await mide(120)
	L.append("town con el menú START: %.0f draw calls/fotograma · %.2f redibujos/fotograma · proceso %.2f ms" % [r.dc, r.redib, r.proc_ms])
	while J.handlers.size():
		J.press("B")
		for k in 3:
			await process_frame

	# una carpa con todas sus plazas plantadas
	e = escena(O, "carpa-c-g150")
	e.sw = 320
	var viva = null
	for p in e.S.pots:
		if p:
			viva = p
	var nv := 0
	for i in e.S.pots.size():
		if e.S.pots[i] == null:
			e.S.pots[i] = viva.duplicate(true)
		nv += 1
	monta(e)
	r = await mide(120)
	L.append("carpa g150 con %d plantas: %.0f draw calls/fotograma · %.2f redibujos/fotograma · proceso %.2f ms" % [nv, r.dc, r.redib, r.proc_ms])

	# la memoria: todas las escenas, 4 vueltas (lo que crece entre la 1.ª y la 4.ª es lo que no se desaloja)
	var mem := []
	for v in 4:
		for x in O:
			var s: Dictionary = Datos.enteros(x)
			if s.mode != "world" and s.mode != "carpa":
				continue
			monta(s)
			for k in 3:
				await process_frame
		mem.append(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	L.append("memoria estática tras cada vuelta por las escenas: %s MB (+%.1f %% de la 1.ª a la 4.ª)" % [", ".join(mem.map(func(x): return "%.1f" % x)), (mem[3] - mem[0]) / mem[0] * 100])

	# la escala a 720p: px de pantalla por px de juego
	J.mode = "world"
	Datos.CAL = true   # como en el juego
	J.ajusta()
	L.append("escala a %s: %.3f (%s)" % [J.get_viewport_rect().size, J.u, "entera" if J.u == floorf(J.u) else "fraccionaria"])
	L.append("max_fps: %d" % Engine.max_fps)

	for l in L:
		print("  " + l)
	if sal != "":
		var f := FileAccess.open(sal, FileAccess.WRITE)
		f.store_string("\n".join(L) + "\n")
		f.close()
	print("perf: %d medidas" % L.size())
	J.queue_free()
	quit(0)
