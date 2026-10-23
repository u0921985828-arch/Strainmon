# Ribera Verde (Godot) — el combate en su lado (lo pidió el usuario: «El combate está al revés, a la izquierda arriba el enemigo, a la
# derecha abajo el personaje» y «si te atacan desde la derecha, el sprite te tendría que defender a la izquierda»; con Datos.CAL):
# la escena en espejo (lado_x: el enemigo con los pies en x 62 y el protagonista en x 176), los efectos donde cae el golpe, y cada
# golpe que dibuja el juego (_comb_frame) hacia el rival: el del protagonista hacia la izquierda y el del enemigo hacia la derecha;
# al huir, el enemigo corre hacia la izquierda. Sin CAL, todo como siempre (el oráculo).
#   $GODOT --headless --path godot --script res://tests/combate_lado.gd   → «combate_lado: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

# hacia dónde pega cada animación tal como salió de PixelLab (vista en tools/sprites/pixellab_combate.py → art/procesado), en el
# fotograma del golpe: el protagonista de espaldas («north») y los enemigos de frente («south»)
const PIXELLAB := [["m", "P", "golpe", "dch", 3], ["m", "P", "patada", "dch", 3], ["m", "P", "spray", "dch", 4],
	["f", "P", "golpe", "izq", 1], ["f", "P", "patada", "dch", 3], ["f", "P", "spray", "dch", 3],
	["ladron1", "E", "ataque", "dch", 3], ["ladron2", "E", "ataque", "izq", 3], ["ladron3", "E", "ataque", "dch", 3], ["darko", "E", "ataque", "dch", 3]]

var J
var S
var D
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func igual(a: Image, b: Image) -> bool:
	return a.get_size() == b.get_size() and a.get_data() == b.get_data()

# el combate con este luchador; quién hace qué, desde hace t ms
func monta(c: Array, a: String, t: float) -> void:
	S.sexo = "f" if c[0] == "f" else "m"
	J.B = {"kind": "thief", "look": {"id": c[0] if c[1] == "E" else "ladron1"}, "jefe": c[0] == "darko", "t": 5000, "flashE": 0, "shakeP": 0}
	J.B["a" + c[1]] = {"n": a, "t0": J.pintor.now - t}

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-combate-lado.json"
	Juego.AJUSTES = "user://prueba-combate-lado-ajustes.json"
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "combate-ladron":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.set_process(false)
	J.S = e.S
	S = J.S
	D = J.D
	J.mode = "battle"
	J.pintor.now = 100000.0
	chk(Atlas.ok, "sin atlas")
	# 1 · los sitios: con CAL, en espejo (el enemigo arriba a la izquierda, el protagonista abajo a la derecha); sin CAL, los de siempre
	Datos.CAL = true
	chk(J.lado_x(154 + 24) == 62 and J.lado_x(40 + 24) == 176, "con CAL, los pies: enemigo %s, protagonista %s (quiero 62 y 176)" % [J.lado_x(178), J.lado_x(64)])
	Datos.CAL = false
	chk(J.lado_x(178) == 178 and J.lado_x(64) == 64, "sin CAL, los pies se mueven: %s, %s" % [J.lado_x(178), J.lado_x(64)])
	# 2 · los efectos, donde cae el golpe; el espray, desde la derecha (en espejo)
	for cal in [true, false]:
		Datos.CAL = cal
		J.B = {"kind": "thief", "t": 5000}
		J.vfx = []
		J.vfx_combate("vfx-golpe", 178, 40)
		J.vfx_combate("vfx-golpe", 64, 112)
		J.vfx_combate("vfx-spray", 178, 48)
		chk(J.vfx.size() == 3, "%s: %d efectos" % ["con CAL" if cal else "sin CAL", J.vfx.size()])
		if J.vfx.size() == 3:
			var xs := [J.vfx[0].x, J.vfx[1].x, J.vfx[2].x]
			chk(xs == ([62.0, 176.0, 62.0] if cal else [178.0, 64.0, 178.0]), "%s: los efectos en x %s" % ["con CAL" if cal else "sin CAL", xs])
			chk((J.vfx[2].get("esp") == true) == cal, "%s: el espray %sen espejo" % ["con CAL" if cal else "sin CAL", "no " if cal else ""])
	# 3 · cada golpe que dibuja el juego, hacia el rival
	for c in PIXELLAB:
		var quiero := "izq" if c[1] == "P" else "dch"
		for cal in [true, false]:
			Datos.CAL = cal
			var fps: float = 8.0
			monta(c, "idle", 0)
			var g = J.grupo_combate(c[1])
			var A = Atlas.anim_de(g, c[2])
			chk(A != null, "%s %s: sin «%s»" % [c[0], g, c[2]])
			if A == null:
				continue
			fps = A.fps if A.get("fps") else 8.0
			monta(c, c[2], (c[4] + .5) * 1000.0 / fps)
			var f = J.pintor._comb_frame(c[1])
			var dir := "north" if c[1] == "P" else "south"
			var tal = Atlas.frame_de(g, c[2], dir, 0, {"i": c[4]})
			var esp = Atlas.frame_de(g, c[2], dir, 0, {"i": c[4], "esp": true})
			chk(f != null and f.i == c[4], "%s %s/%s: fotograma %s (quiero %d)" % [c[0], g, c[2], f.i if f else "-", c[4]])
			if f == null:
				continue
			if cal:   # tal como salió, si ya pega hacia el rival; si no, en espejo
				var bien: Image = tal.c if c[3] == quiero else esp.c
				chk(igual(f.c, bien), "%s %s/%s: no pega hacia la %s" % [c[0], g, c[2], "izquierda" if quiero == "izq" else "derecha"])
			else:   # sin CAL, el de siempre y sin espejo
				chk(not g.ends_with("-r") and igual(f.c, tal.c), "%s sin CAL: %s/%s cambia" % [c[0], g, c[2]])
	# 4 · el enemigo huye hacia la izquierda: su «east», en espejo
	for k in ["ladron1", "ladron2", "ladron3", "darko"]:
		Datos.CAL = true
		monta([k, "E"], "huir", 60)
		J.B.gone = true
		var g = J.grupo_combate("E")
		var f = J.pintor._comb_frame("E")
		var esp = Atlas.frame_de(g, "huir", "east", 0, {"i": f.i if f else 0, "esp": true})
		chk(f != null and igual(f.c, esp.c), "%s: al huir no corre hacia la izquierda" % k)
	# 5 · y el de pie, como su golpe: el protagonista (chico) y el ladrón 2, en espejo; la caída, no (cae lejos del enemigo)
	Datos.CAL = true
	for c in [["m", "P", "idle", true], ["m", "P", "desmayo", false], ["f", "P", "idle", false], ["ladron2", "E", "idle", true], ["ladron1", "E", "idle", false]]:
		monta(c, c[2], 10)
		var g = J.grupo_combate(c[1])
		chk(J.comb_espejo(g, c[2]) == c[3], "%s %s/%s: %sen espejo" % [c[0], g, c[2], "no " if c[3] else ""])
	Datos.CAL = false
	print("combate_lado: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
