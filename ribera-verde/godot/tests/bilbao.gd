# Ribera Verde (Godot) — Bilbao, zonas nuevas (lo pidió el usuario: «Los mapas del juego hazlos los más parecidos y realistas a
# Bilbao centro y sus barrios, Zorroza no puede faltar», y después «Añade como zonas nuevas / No quiero caos», el caos: «el
# mobiliario urbano, la distribución en el suelo de alcantarillas y demás»; tools/bilbao.py → BILBAO en datos.json, con CAL):
# Zorroza (la parada «Bilbao»), La Punta, Abando y el Casco Viejo, en fila por la calle; todo alcanzable; el mobiliario y lo del
# suelo a ritmo fijo; y sin CAL, nada de Bilbao y los seis mapas de siempre como en datos.json.
#   $GODOT --headless --path godot --script res://tests/bilbao.gd   → «bilbao: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también bilbao-<mapa>.png, el mapa entero
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atrezo = preload("res://tests/atrezo.gd")
const Croquis = preload("res://src/croquis.gd")

var J
var n := 0
var fallos := []

const MAPAS := ["zorroza", "lapunta", "abando", "casco"]
const CALLE_Y := 9
# lo de cada sitio: edificios, suelos y objetos que tiene que tener
const TIENE := {
	"zorroza": {"b": ["torreZ", "torreZ2", "estacion"], "g": ["via", "viaX", "viaE", "viaEX", "roadT", "hormigon", "water"], "o": ["parada", "baranda", "lamp", "bench", "papelera", "bolardo", "contenedores"]},
	"lapunta": {"b": ["ladrillo", "nave", "grua"], "g": ["hormigon", "muelleP", "roadT", "water"], "o": ["noray", "lamp", "bolardo", "contenedores"]},
	"abando": {"b": ["ensB", "ensB2"], "g": ["plaza", "roadT", "walk"], "o": ["platano", "fountain", "lamp", "bolardo", "papelera"]},
	"casco": {"b": ["teatro", "catedral", "mercado", "casco", "casco2", "casco3"], "g": ["adoq", "muelleP", "plaza", "water"], "o": ["baranda", "lamp", "bench", "papelera", "fountain"]},
}
const SEMBRADO := ["papelera", "bench", "lamp", "bolardo", "platano", "contenedores", "contenedores2", "metroB", "metroB2"]
# lo que no hace falta alcanzar (el borde, la barandilla, los árboles y el mobiliario de la calle)
const DECORADO := ["monte", "monte2", "seto", "tree", "tree2", "platano", "fence", "baranda", "lamp", "noray", "bench", "papelera", "bolardo", "contenedores", "fountain", "crate", "metroB"]

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

# las x de una fila con ese objeto (o esa calcomanía)
func xs_o(m: Dictionary, y: int, o: String) -> Array:
	var r := []
	for x in int(m.w):
		if m.o[y][x] == o:
			r.append(x)
	return r

func xs_dec(m: Dictionary, y: int, d: String) -> Array:
	var r := []
	for x in int(m.w):
		if m.dec.get("%d,%d" % [x, y], "") == d:
			r.append(x)
	return r

# a ritmo: todas a la misma distancia (o a un múltiplo, donde se salta por un cruce)
func a_ritmo(xs: Array, paso: int) -> bool:
	for i in range(1, xs.size()):
		if (int(xs[i]) - int(xs[i - 1])) % paso != 0:
			return false
	return true

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
	var D: Dictionary = J.D
	chk(RAW.has("BILBAO") and RAW.BILBAO.MAPS.keys() == MAPAS, "BILBAO en datos.json con los %d mapas" % MAPAS.size())
	# 1. zonas nuevas: los seis mapas de siempre, tal cual
	for k in ["town", "alto", "astilleros", "ibarbide", "ensanche", "callejon"]:
		chk(JSON.stringify(D.MAPS[k].g) == JSON.stringify(RAW.MAPS[k].g) and JSON.stringify(D.MAPS[k].o) == JSON.stringify(RAW.MAPS[k].o), "%s: como siempre" % k)
	# 2. la parada, la zona, las patrullas, los clientes, la ronda y el coche
	chk(D.PARADAS.has("zorroza") and D.PARADAS.zorroza.n == "Bilbao", "la parada «Bilbao»")
	var pa: Dictionary = D.PARADAS.get("zorroza", {})
	if pa:
		chk(D.MAPS.zorroza.o[int(pa.y)][int(pa.x)] == "parada", "el poste de la parada en (%d, %d)" % [pa.x, pa.y])
		chk(D.MAPS.zorroza.o[int(pa.a[1])][int(pa.a[0])] == null, "la llegada del autobús, libre")
		chk(D.CONCE.km.has("zorroza"), "los km en coche")
	S.ch = int(pa.get("cap", 2))
	for k in MAPAS:
		chk(D.ZONAS.has(k) and D.PATRULLAS.has(k) and D.CLIENT_TILES.get(k, []).size() > 10 and D.RONDA.get(k, []).size() > 10 and D.LAMPS.has(k), "%s: zona, patrullas, clientes y ronda" % k)
		chk(Croquis.ZONA.get(k, "") == "town", "%s: en el croquis" % k)
	# los clientes salen en las cuatro (spawn de calle.gd, con su prefijo de id)
	S.day = 40
	S.clients = []
	J.spawn_clients()
	for k in MAPAS:
		chk(S.clients.any(func(c): return c.map == k), "%s: clientes en la calle" % k)
	S.ch = 8
	for k in MAPAS:
		J.enter_map(k, 1, CALLE_Y, "right")
		J.build_ents()
		J.mode = "world"
		var m: Dictionary = J.MAPS[k]
		var ids: Array = m.blds.map(func(b): return String(b.id))
		for b in TIENE[k].b:
			chk(b in ids, "%s: el edificio %s" % [k, b])
		for g in TIENE[k].g:
			chk(hay(m, "g", g), "%s: el suelo %s" % [k, g])
		for o in TIENE[k].o:
			chk(hay(m, "o", o), "%s: el objeto %s" % [k, o])
		# 3. de lado a lado: cada salida lleva a una casilla libre del de al lado, que tiene la suya de vuelta en la misma fila
		for c in m.exits:
			var q: Dictionary = m.exits[c]
			var m2: Dictionary = D.MAPS[q.to]
			var tx := int(q.x)
			var ty := int(q.y)
			chk(m2.o[ty][tx] == null and not String(m2.g[ty][tx]).begins_with("water"), "%s %s → %s (%d, %d): libre" % [k, c, q.to, tx, ty])
			var vuelta := false
			for c2 in m2.exits:
				vuelta = vuelta or (m2.exits[c2].to == k and int(String(c2).split(",")[1]) == ty)
			chk(vuelta, "%s %s: la vuelta desde %s" % [k, c, q.to])
		# 4. todo alcanzable desde las salidas: puertas, salidas, personas y lo que se usa (el decorado, aparte)
		var mal: Array = Atrezo.accesos(J, k).filter(func(t): return not String(t).get_slice(" ", 0) in DECORADO)
		chk(mal.is_empty(), "%s: no se alcanza %s" % [k, mal])
		var B := {}
		var v: Dictionary = J.andable(m, m.o, B)
		# de una salida se llega a todas (las otras, como suelo, para ver si se alcanzan)
		var m1: Dictionary = m.duplicate()
		var e0: String = m.exits.keys()[0]
		m1.exits = {e0: m.exits[e0]}
		var v1: Dictionary = J.andable(m1, m.o, B)
		for c in m.exits:
			chk(c == e0 or v1.has(c), "%s: la salida %s, alcanzable desde %s" % [k, c, e0])
		var nl := 0
		for y in int(m.h):
			for x in int(m.w):
				if m.o[y][x] in ["papelera", "bench", "lamp", "bolardo"] and not (v.has("%d,%d" % [x + 1, y]) or v.has("%d,%d" % [x - 1, y]) or v.has("%d,%d" % [x, y + 1]) or v.has("%d,%d" % [x, y - 1])):
					nl += 1
		chk(nl == 0, "%s: %d piezas del mobiliario encerradas" % [k, nl])
		# 5. sin caos: lo del suelo encima de suelo libre; en la calle, todo a ritmo y los de enfrente a la misma x
		for c in m.dec:
			var p: Array = String(c).split(",")
			chk(m.o[int(p[1])][int(p[0])] == null, "%s %s: %s debajo de un objeto" % [k, c, m.dec[c]])
		if k != "casco":
			var y1 := CALLE_Y + 1
			var y4 := CALLE_Y + 4
			var fa: Array = xs_o(m, y1, "lamp")
			chk(fa.size() >= 3 and fa == xs_o(m, y4, "lamp"), "%s: las farolas de las dos aceras, enfrentadas %s %s" % [k, fa, xs_o(m, y4, "lamp")])
			chk(a_ritmo(fa, 8), "%s: las farolas cada 8 %s" % [k, fa])
			var it: Array = xs_dec(m, CALLE_Y + 2, "imbT")
			chk(it.size() >= 3 and it == xs_dec(m, CALLE_Y + 3, "imbB") and a_ritmo(it, 8), "%s: los imbornales, a los dos lados y cada 8 %s" % [k, it])
			var ta: Array = xs_dec(m, CALLE_Y + 3, "tapa")
			chk(ta.size() >= 1 and a_ritmo(ta, 16), "%s: las tapas cada 16 %s" % [k, ta])
			var ce: Array = xs_dec(m, CALLE_Y + 2, "cebra")
			chk(ce.size() >= 2 and ce == xs_dec(m, CALLE_Y + 3, "cebra"), "%s: el paso de cebra entero %s" % [k, ce])
			for x in ce:
				var bol := false
				for xx in [x - 1, x + 1]:
					bol = bol or (m.o[y1][xx] == "bolardo" and m.o[y4][xx] == "bolardo")
				chk(bol, "%s: bolardos junto al paso de (%d)" % [k, x])
			var ar: Array = xs_o(m, y1, "platano")
			chk(a_ritmo(ar, 8) and ar == xs_o(m, y4, "platano"), "%s: los plátanos, cada 8 y enfrentados %s" % [k, ar])
		# cada banco, con su papelera al lado; ninguna papelera suelta
		for y in int(m.h):
			for x in int(m.w):
				if m.o[y][x] == "bench":
					chk(m.o[y][x + 1] == "papelera" or m.o[y][x - 1] == "papelera", "%s (%d, %d): el banco sin papelera" % [k, x, y])
				if m.o[y][x] == "papelera":
					chk(m.o[y][x - 1] == "bench" or m.o[y][x + 1] == "bench", "%s (%d, %d): papelera suelta" % [k, x, y])
				if m.o[y][x] == "contenedores":
					chk(m.o[y][x + 1] == "contenedores2", "%s (%d, %d): el contenedor, entero" % [k, x, y])
		# la plaza simétrica: lo de la izquierda, también a la derecha
		if dir != "":
			await plano(dir, k)
	# 6. sin CAL: nada de Bilbao (ni mapas, ni parada, ni zonas)
	Datos.CAL = false
	Datos.carga()
	for k in MAPAS:
		chk(not D.MAPS.has(k) and not D.ZONAS.has(k) and not D.PATRULLAS.has(k) and not D.CLIENT_TILES.has(k), "sin CAL, %s: fuera" % k)
	chk(not D.PARADAS.has("zorroza") and not D.CONCE.km.has("zorroza"), "sin CAL: sin la parada")
	for k in ["town", "ibarbide", "ensanche"]:
		chk(JSON.stringify(D.MAPS[k].g) == JSON.stringify(RAW.MAPS[k].g), "sin CAL, %s: como siempre" % k)
	Datos.CAL = true
	Datos.carga()
	chk(D.MAPS.has("casco") and D.PARADAS.has("zorroza"), "con CAL otra vez, Bilbao")
	print("bilbao: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
