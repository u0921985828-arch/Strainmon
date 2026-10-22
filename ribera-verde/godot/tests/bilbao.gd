# Ribera Verde (Godot) — los mapas de Bilbao (lo pidió el usuario: «Los mapas del juego hazlos los más parecidos y realistas a Bilbao
# centro y sus barrios, Zorroza no puede faltar»; tools/bilbao.py → BILBAO en datos.json, con CAL): Zorroza, Zazpi Landa, La Punta, el
# Casco Viejo, Abando y el cantón, con lo suyo (la estación y la vía, las torres, las grúas, la catedral, el teatro, el mercado, la
# Ribera, las casas del Ensanche, los plátanos y el metro), todo alcanzable, y sin CAL como en datos.json.
#   $GODOT --headless --path godot --script res://tests/bilbao.gd   → «bilbao: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también bilbao-<mapa>.png, el mapa entero
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atrezo = preload("res://tests/atrezo.gd")

var J
var n := 0
var fallos := []

const MAPAS := ["town", "alto", "astilleros", "ibarbide", "ensanche", "callejon"]
# lo de cada sitio: edificios, suelos y objetos que tiene que tener con CAL
const TIENE := {
	"town": {"b": ["estacion"], "g": ["via", "viaX", "muelleP", "hormigon"], "o": ["baranda"]},
	"alto": {"b": ["torreZ", "torreZ2", "comisaria"], "g": ["plaza"], "o": []},
	"astilleros": {"b": ["grua", "nave", "ladrillo"], "g": ["muelleP", "hormigon"], "o": ["noray"]},
	"ibarbide": {"b": ["catedral", "teatro", "mercado", "growcity"], "g": ["adoq", "muelleP", "water"], "o": ["baranda"]},
	"ensanche": {"b": ["ensB", "ensB2"], "g": ["plaza"], "o": ["platano", "metroB"]},
	"callejon": {"b": ["casco3"], "g": ["adoq"], "o": []},
}
# dónde se entra (una casilla de acera de cada uno)
const DESDE := {"town": [17, 12], "alto": [11, 19], "astilleros": [2, 20], "ibarbide": [20, 9], "ensanche": [6, 12], "callejon": [10, 15]}
# lo que no hace falta alcanzar: el borde de monte, los setos, la barandilla, los árboles y el resto del atrezo de la calle
const DECORADO := ["monte", "monte2", "seto", "tree", "tree2", "platano", "fence", "baranda", "lamp", "noray", "banderaK"]

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func hay(m: Dictionary, capa: String, que: String) -> bool:
	for r in m[capa]:
		if que in r:
			return true
	return false

# el mapa entero a PNG, por trozos de pantalla
func plano(dir: String, k: String) -> void:
	var m: Dictionary = J.MAPS[k]
	J.mode = "world"
	J.ents = []
	var mw: int = int(m.w) * 16
	var mh: int = int(m.h) * 16
	var big := Image.create(mw, mh, false, Image.FORMAT_RGBA8)
	var sw: int = J.SW
	var xs := []
	var x := 0
	while true:
		xs.append(mini(x, mw - sw))
		if x + sw >= mw:
			break
		x += sw
	var ys := []
	var y := 0
	while true:
		ys.append(mini(y, mh - 180))
		if y + 180 >= mh:
			break
		y += 180
	for cy in ys:
		for cx in xs:
			J.P.px = cx - 8 + sw / 2.0
			J.P.py = cy - 8 + 90.0
			for q in 2:
				await process_frame
				J.pintor.redibuja(0.0)
				await RenderingServer.frame_post_draw
			var im: Image = J.sv.get_texture().get_image()
			im.convert(Image.FORMAT_RGBA8)
			big.blit_rect(im, Rect2i(0, 0, sw, 180), Vector2i(cx, cy))
	big.save_png(dir.path_join("bilbao-%s.png" % k))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-bilbao.json"
	Juego.AJUSTES = "user://prueba-bilbao-ajustes.json"
	Datos.CAL = true
	var RAW: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://datos/datos.json"))
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	var S = J.S
	S.ch = 8
	S.min = 12 * 60
	S.flags.conce = true
	J.oraculo = true
	var dir := arg("--pintar")
	if dir != "":
		J.oraculo = false
		J.set_process(false)
	chk(RAW.has("BILBAO") and RAW.BILBAO.MAPS.keys().size() == MAPAS.size(), "BILBAO en datos.json con los %d mapas" % MAPAS.size())
	for k in MAPAS:
		var m: Dictionary = J.MAPS[k]
		var m0: Dictionary = RAW.MAPS[k]
		J.enter_map(k, DESDE[k][0], DESDE[k][1], "up")
		J.build_ents()
		J.mode = "world"
		m = J.MAPS[k]
		chk(int(m.w) == int(m0.w) and int(m.h) == int(m0.h), "%s: del mismo tamaño" % k)
		var ids: Array = m.blds.map(func(b): return String(b.id))
		for b in TIENE[k].b:
			chk(b in ids, "%s: el edificio %s" % [k, b])
		for g in TIENE[k].g:
			chk(hay(m, "g", g), "%s: el suelo %s" % [k, g])
		for o in TIENE[k].o:
			chk(hay(m, "o", o), "%s: el objeto %s" % [k, o])
		# las puertas y salidas de siempre, en su sitio y con el mismo suelo
		for d in m0.doors.keys() + m0.exits.keys():
			var p: Array = d.split(",")
			chk(m.doors.has(d) or m.exits.has(d), "%s: la puerta o salida %s" % [k, d])
			chk(String(m.g[int(p[1])][int(p[0])]) == String(m0.g[int(p[1])][int(p[0])]), "%s: el suelo de la puerta %s" % [k, d])
		# lo de siempre que se nombra (carteles, cajeros, paradas, rótulos, la fuente): en datos.json, la misma cosa en la misma casilla
		var mb: Dictionary = RAW.BILBAO.MAPS[k]
		for y in int(m0.h):
			for x in int(m0.w):
				var o0 = m0.o[y][x]
				if o0 in ["sign", "cajero", "parada", "rotuloL", "fountain"]:
					chk(mb.o[y][x] == o0, "%s (%d, %d): el %s" % [k, x, y, o0])
		# todo alcanzable desde las puertas y salidas (andable sale de m.exits: aquí, también de las puertas): objetos (salvo el
		# decorado), personas, puertas y salidas
		var ex0: Dictionary = m.exits
		m.exits = ex0.merged(m.doors)
		var mal: Array = Atrezo.accesos(J, k).filter(func(t): return not String(t).get_slice(" ", 0) in DECORADO)
		chk(mal.is_empty(), "%s: no se alcanza %s" % [k, mal])
		var B := {}
		for q in J.ents:
			B["%d,%d" % [q.x, q.y]] = true
		var v: Dictionary = J.andable(m, m.o, B)
		for d in m.doors.keys() + m.exits.keys():
			var p: Array = d.split(",")
			var x := int(p[0])
			var y := int(p[1])
			var ok := false
			for xx in [x - 1, x, x + 1]:   # la puerta doble: por cualquiera de sus dos hojas
				if xx != x and not (m.doors.has("%d,%d" % [xx, y]) or m.exits.has("%d,%d" % [xx, y])):
					continue
				for dd in [[0, 0], [0, -1], [-1, 0], [1, 0], [0, 1]]:
					ok = ok or v.has("%d,%d" % [xx + dd[0], y + dd[1]])
			chk(ok, "%s: la puerta o salida %s, alcanzable" % [k, d])
		m.exits = ex0
		if dir != "":
			await plano(dir, k)
	# sin CAL: los de siempre (los edificios y los suelos de datos.json); y con CAL otra vez, los de Bilbao
	Datos.CAL = false
	for k in MAPAS:
		J.enter_map(k, 1, 1)
		var m: Dictionary = J.MAPS[k]
		var ids: Array = m.blds.map(func(b): return String(b.id))
		var ids0: Array = RAW.MAPS[k].blds.map(func(b): return String(b.id))
		chk(ids.slice(0, ids0.size()) == ids0, "sin CAL, %s: los edificios de siempre" % k)
		chk(not hay(m, "g", "adoq") and not hay(m, "g", "muelleP") and not hay(m, "g", "via") and not hay(m, "o", "platano"), "sin CAL, %s: nada de Bilbao" % k)
	Datos.CAL = true
	J.enter_map("ibarbide", 1, 1)
	chk(J.MAPS.ibarbide.blds.any(func(b): return b.id == "catedral"), "con CAL otra vez, la catedral")
	print("bilbao: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
