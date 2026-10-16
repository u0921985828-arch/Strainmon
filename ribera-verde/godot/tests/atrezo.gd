# Ribera Verde (Godot) — 1.51: el atrezo de las casas y los sitios donde hablas con alguien (lo pidió el usuario: «la casa de Txaro es
# la casa con menos atrezo que hay en el mundo»; ATREZO en mundo.gd, con CAL): cada cosa en su sitio, con su texto, y nada corta el paso.
#   $GODOT --headless --path godot --script res://tests/atrezo.gd   → «atrezo: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también atrezo-<mapa>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var n := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func foto(dir: String, k: String) -> void:
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("atrezo-%s.png" % k))

# lo que se alcanza desde la salida: cada objeto y cada persona, con una casilla andable al lado
static func accesos(J_, mapa: String) -> Array:
	var m: Dictionary = J_.MAPS[mapa]
	var B := {}
	for e in J_.ents:
		B["%d,%d" % [e.x, e.y]] = true
	var v: Dictionary = J_.andable(m, m.o, B)
	var mal := []
	var junto := func(x: int, y: int) -> bool:
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			if v.has("%d,%d" % [x + d[0], y + d[1]]):
				return true
		return false
	for y in int(m.h):
		for x in int(m.w):
			var o = m.o[y][x]
			if o and not o in ["iwin", "crate"] and not junto.call(x, y) and not (o == "bedT" and junto.call(x, y + 1)):
				var dos: bool = x > 0 and str(o).ends_with("2") and m.o[y][x - 1] == str(o).left(-1) and junto.call(x - 1, y)
				var uno: bool = x + 1 < int(m.w) and m.o[y][x + 1] == str(o) + "2" and junto.call(x + 1, y)
				if not dos and not uno:
					mal.append("%s (%d, %d)" % [o, x, y])
	for e in J_.ents:
		if not junto.call(e.x, e.y):
			mal.append("persona %s (%d, %d)" % [e.get("id", "?"), e.x, e.y])
	return mal

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-atrezo.json"
	Juego.AJUSTES = "user://prueba-atrezo-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	S.ch = maxi(int(S.ch), 6)
	S.flags.txaro = true
	J.oraculo = true
	var dir := arg("--pintar")
	if dir != "":
		J.oraculo = false
		J.set_process(false)
	for k in J.ATREZO:
		var m: Dictionary = J.MAPS[k]
		var ex: Array = m.exits.keys()[0].split(",")
		J.enter_map(k, int(ex[0]), int(ex[1]) - 1, "up")
		J.build_ents()
		J.mode = "world"
		var puestos := 0
		for a in J.ATREZO[k]:
			if m.o[a[1]][a[0]] == a[2]:
				puestos += 1
			var t: String = J.ATREZO_TXT[k].get(a[2], "")
			chk(t != "" or J.asiento_de(a[2]) != "", "%s: %s sin texto" % [k, a[2]])
		chk(puestos == J.ATREZO[k].size(), "%s: puestos %d de %d" % [k, puestos, J.ATREZO[k].size()])
		var cuenta := 0
		for r in m.o:
			for c in r:
				if c:
					cuenta += 1
		chk(cuenta >= 12, "%s: %d cosas" % [k, cuenta])
		var mal := accesos(J, k)
		chk(mal.is_empty(), "%s: no se alcanza %s" % [k, mal])
		J.enter_map(k, int(ex[0]), int(ex[1]) - 1, "up")
		chk(J.ATREZO[k].all(func(a): return m.o[a[1]][a[0]] == a[2]), "%s: otra vez, igual" % k)
		if dir != "":
			await foto(dir, k)
	print("atrezo: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
