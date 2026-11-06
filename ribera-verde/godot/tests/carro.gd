# Ribera Verde (Godot) — 1.40: el carro de esquejes por dentro (lo pidió el usuario: «que no sea un menú»): dos bandejas de 12
# tacos, arriba y abajo; flechas eligen, A en un taco vacío pincha los del propagador, A en un esqueje lo nombra o lo tira, B cierra.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-carro.
#   $GODOT --headless --path godot --script res://tests/carro.gd   → «carro: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también carro-<caso>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Motor = preload("res://src/motor.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := ""
var TECLAS := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	for i in labels.size():
		if QUIERO != "" and labels[i].begins_with(QUIERO):
			k = i
	QUIERO = ""
	o = o.duplicate()
	o.initial = k
	return o

# las teclas de la prueba, una por intervalo; sin teclas, A (los textos) y, en la vista del carro, B
func _tecla() -> void:
	if not J.handlers.size():
		return
	if TECLAS.size():
		J.press(TECLAS.pop_front())
	else:
		J.press("B" if J.CARRO_V != null else "A")

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func clon(sid: String, dia: int) -> Dictionary:
	return {"sid": sid, "f": {"id": 9990 + n, "t": 1, "y": 1, "i": 50}, "dia": dia}

func pinta(dir: String, k: String, V: Dictionary) -> void:
	J.CARRO_V = V
	J._dlg_fijo(J.desc_carro(V), "CARRO DE ESQUEJES")
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	var im: Image = root.get_texture().get_image()
	im.save_png(dir.path_join("carro-%s.png" % k))
	J.CARRO_V = null

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-carro.json"
	Juego.AJUSTES = "user://prueba-carro-ajustes.json"
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-carro":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	var dir := arg("--pintar")
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	J.S.day = 12
	var d: int = J.S.day
	var D = J.D
	var cap: int = D.CARRO.bandejas * D.CARRO.plazas
	chk(cap == 24, "24 tacos: %d" % cap)
	# las vistas: vacío, a medias (con uno en su último día) y lleno
	if dir != "":
		await process_frame
		J.set_process(false)
		J.S.bandejas = []
		J.S.esquejes = [clon("limon", d), clon("purpura", d), clon("limon", d)]
		await pinta(dir, "vacio", {"i": 0})   # la primera, dos veces: el cuadro del texto se coloca en el siguiente fotograma
		await pinta(dir, "vacio", {"i": 0})
		J.S.bandejas = []
		for q in 13:
			J.S.bandejas.append(clon(["limon", "purpura", "cheese"][q % 3], d - (D.CARRO.dias if q == 4 else 0)))
		await pinta(dir, "medias", {"i": 4})
		await pinta(dir, "abajo", {"i": 13})
		J.S.bandejas = []
		for q in 24:
			J.S.bandejas.append(clon("limon", d))
		J.S.esquejes = []
		await pinta(dir, "lleno", {"i": 23})
		J.set_process(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(_tecla, 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · la rejilla: 6 por fila, dos filas por bandeja (0-11 arriba, 12-23 abajo); no se sale por los bordes
	var V := {"i": 0}
	chk(not J.mueve_carro(V, "left") and not J.mueve_carro(V, "up") and V.i == 0, "borde arriba-izquierda %d" % V.i)
	chk(J.mueve_carro(V, "right") and V.i == 1, "derecha %d" % V.i)
	chk(J.mueve_carro(V, "down") and V.i == 7, "abajo %d" % V.i)
	chk(J.mueve_carro(V, "down") and V.i == 13, "a la bandeja de abajo %d" % V.i)
	V.i = 23
	chk(not J.mueve_carro(V, "right") and not J.mueve_carro(V, "down") and V.i == 23, "borde abajo-derecha %d" % V.i)
	# 2 · el dibujo: 24 tacos, un esqueje por clon, el marco amarillo en el elegido y todo dentro de la pantalla
	J.S.bandejas = [clon("limon", d), clon("purpura", d - D.CARRO.dias)]
	J.S.esquejes = []
	var rs: Array = J.rects_carro({"i": 1})
	chk(rs.filter(func(r): return r[4] == "#30303a" and r[2] == 14).size() == 24, "tacos dibujados")
	chk(rs.filter(func(r): return r[4] == "#f8d040").size() == 4, "marco del elegido")
	chk(rs.filter(func(r): return r[4] == "#b8a050").size() > 0, "el del último día, amarillo")
	chk(rs.all(func(r): return r[0] >= 0 and r[1] >= 0 and r[0] + r[2] <= J.SW and r[1] + r[3] <= 120), "fuera de la pantalla: SW %d" % J.SW)
	chk(J.desc_carro({"i": 1}).contains("hoy es el último"), "texto del último día: " + J.desc_carro({"i": 1}))
	chk(J.desc_carro({"i": 5}).contains("2 de 24") and J.desc_carro({"i": 5}).contains("propagador está vacío"), "texto del taco vacío: " + J.desc_carro({"i": 5}))
	# 3 · A en un taco vacío pincha los del propagador (luego B cierra)
	J.S.bandejas = []
	J.S.esquejes = [clon("limon", d), clon("purpura", d), clon("limon", d)]
	TECLAS = ["A"]
	LOG = []
	MENUS = []
	chk(corre(J.carro_action), "pinchar bloqueado")
	chk(J.S.bandejas.size() == 3 and J.S.esquejes.is_empty() and J.S.bandejas.all(func(x): return x.dia == d), "pinchados: %d/%d" % [J.S.bandejas.size(), J.S.esquejes.size()])
	chk(" ".join(LOG).contains("pinchas 3 esquejes"), "aviso: %s" % [LOG])
	chk(J.CARRO_V == null and MENUS.all(func(m): return m.has("TENGO 18 O MÁS")), "sin menú: %s" % [MENUS])   # sin --sin-arranque, solo el aviso de edad
	# 4 · con el carro casi lleno, solo los que caben; el resto, al propagador
	J.S.bandejas = []
	for q in 22:
		J.S.bandejas.append(clon("limon", d))
	J.S.esquejes = [clon("purpura", d), clon("purpura", d), clon("purpura", d)]
	TECLAS = ["A"]
	LOG = []
	chk(corre(J.carro_action), "lleno bloqueado")
	chk(J.S.bandejas.size() == 24 and J.S.esquejes.size() == 1, "lleno: %d/%d" % [J.S.bandejas.size(), J.S.esquejes.size()])
	chk(" ".join(LOG).contains("No cabe 1"), "aviso lleno: %s" % [LOG])
	# 5 · A en un esqueje: su menú (nombrar o tirar); tirarlo lo saca de la bandeja
	J.S.bandejas = [clon("limon", d), clon("purpura", d)]
	J.S.esquejes = []
	MENUS = []
	TECLAS = ["left", "A"]
	QUIERO = "Tirar"
	chk(corre(J.carro_action), "esqueje bloqueado")
	chk(MENUS.size() >= 1, "sin el menú del esqueje")
	chk(J.S.bandejas.size() == 1 and J.S.bandejas[0].sid == "limon", "tirado: %s" % [J.S.bandejas.map(func(x): return x.sid)])
	# 6 · A en un taco vacío sin propagador: el aviso; B cierra sin tocar nada
	J.S.bandejas = []
	LOG = []
	TECLAS = ["A"]
	chk(corre(J.carro_action), "vacío bloqueado")
	chk(" ".join(LOG).contains("Taco vacío") and J.S.bandejas.is_empty(), "aviso vacío: %s" % [LOG])
	for x in fallos:
		print("  FALLO ", x)
	print("carro: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
