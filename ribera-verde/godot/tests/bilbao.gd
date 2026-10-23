# Ribera Verde (Godot) — Bilbao, zonas nuevas (lo pidió el usuario: «Los mapas del juego hazlos los más parecidos y realistas a
# Bilbao centro y sus barrios, Zorroza no puede faltar», y después «Añade como zonas nuevas / No quiero caos», el caos: «el
# mobiliario urbano, la distribución en el suelo de alcantarillas y demás»; tools/bilbao.py → BILBAO en datos.json, con CAL):
# La Punta, Zorroza (la parada «Bilbao»), Abando y el Casco Viejo, en fila por la calle de oeste a este; todo alcanzable; el mobiliario y lo del
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

const MAPAS := ["lapunta", "zorroza", "abando", "casco"]   # de oeste a este
const CALLE_Y := 14
# lo de cada sitio: edificios, suelos y objetos que tiene que tener
const TIENE := {
	"zorroza": {"b": ["torreZ", "torreZ2", "estacion", "iglesiaZ", "apeadero", "bloqueZ", "bloqueZ2"], "g": ["via", "viaE", "roadT", "hormigon", "water", "muelleP"], "o": ["parada", "baranda", "lamp", "bench", "papelera", "bolardo", "contenedores", "escZ", "ascensorZ", "fountain"]},
	"lapunta": {"b": ["ladrillo", "nave", "grua", "molino"], "g": ["hormigon", "muelleP", "roadT", "water"], "o": ["noray", "lamp", "bolardo", "contenedores", "crate"]},
	"abando": {"b": ["ensB", "ensB2", "chavarri", "carlton", "diputacion", "camposE", "torreBBVA", "abandoE", "concordia", "milagrosa"], "g": ["plaza", "roadT", "roadL", "roadR", "roadX", "walk", "water"], "o": ["platano", "fountain", "estatua", "lamp", "bolardo", "papelera"]},
	"casco": {"b": ["teatro", "catedral", "mercadoR", "sanNicolas", "plazaN", "plazaS", "plazaL", "plazaR", "sanAnton", "kiosko", "casco", "casco2", "casco3", "cascoB"], "g": ["adoq", "muelleP", "plaza", "water", "puenteV"], "o": ["baranda", "lamp", "bench", "papelera", "fountain", "bolardo"]},
}
const SEMBRADO := ["papelera", "bench", "lamp", "bolardo", "platano", "contenedores", "contenedores2", "metroB", "metroB2"]
# lo que no hace falta alcanzar (el borde, la barandilla, los árboles y el mobiliario de la calle)
const DECORADO := ["monte", "monte2", "seto", "tree", "tree2", "platano", "fence", "baranda", "lamp", "noray", "bench", "papelera", "bolardo", "contenedores", "fountain", "crate", "metroB", "estatua"]

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
	J.montar_aparcamiento(k)   # el aparcamiento con dos coches (tests/aparc_bilbao.gd)
	J.S.coches = {"utilitario": {"dia": 0, "p": 20000, "r": 999, "iv": 999, "en": k}, "berlina": {"dia": 0, "p": 40000, "r": 999, "iv": 999, "en": k}}
	J.S.map = k
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
		chk(nl == 0, "%s: %d piezas del mobiliario encerradas" % [k, nl] + str(_encerradas(m, v)))
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
		# 6. la forma del sitio de verdad (lo pidió el usuario: «la estructura del mapa que se parezca al lugar»)
		forma(k, m, v)
		# la plaza simétrica: lo de la izquierda, también a la derecha
		if dir != "":
			await plano(dir, k)
	# la costura de dos zonas seguidas: junto a la calle, agua en las dos o en ninguna (el mismo río, o ninguno)
	var fila := ["lapunta", "zorroza", "abando", "casco"]
	for i in range(1, fila.size()):
		var a: Dictionary = D.MAPS[fila[i - 1]]
		var b: Dictionary = D.MAPS[fila[i]]
		for y in [CALLE_Y - 1, CALLE_Y + 6]:
			chk(agua(a, int(a.w) - 1, y) == agua(b, 0, y), "%s | %s (fila %d): la costura casa" % [fila[i - 1], fila[i], y])
		chk(a.exits.has("%d,%d" % [int(a.w) - 1, CALLE_Y + 2]) and a.exits["%d,%d" % [int(a.w) - 1, CALLE_Y + 2]].to == fila[i], "%s → %s, por la derecha" % [fila[i - 1], fila[i]])
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

func bld(m: Dictionary, id: String) -> Dictionary:
	for b in m.blds:
		if String(b.id) == id:
			return b
	return {}

func agua(m: Dictionary, x: int, y: int) -> bool:
	return String(m.g[y][x]).begins_with("water")

func libre(m: Dictionary, x: int, y: int) -> bool:
	var g := String(m.g[y][x])
	return not (g.begins_with("roof") or g.begins_with("wall") or g.begins_with("water") or g.begins_with("via")) and m.o[y][x] == null

func forma(k: String, m: Dictionary, v: Dictionary) -> void:
	var W := int(m.w)
	var H := int(m.h)
	match k:
		"zorroza":   # la ría al norte; la vía ancha entre el paseo y el andén; la estrecha al pie de la ladera; la iglesia en su plaza
			chk(range(W).all(func(x): return agua(m, x, 0) and agua(m, x, 2)), "zorroza: la ría, arriba")
			chk(range(3, H).all(func(y): return not agua(m, 0, y) and not agua(m, 1, y)), "zorroza: sin el Kadagua (es de La Punta, al oeste): tierra firme de lado a lado")
			chk(range(W).all(func(x): return String(m.g[6][x]) == "via" and String(m.g[7][x]) == "via"), "zorroza: la vía ancha, doble y de lado a lado")
			chk(range(W).all(func(x): return String(m.g[32][x]) == "viaE"), "zorroza: la vía estrecha, abajo")
			var es: Dictionary = bld(m, "estacion")
			chk(es and int(es.y0) == 10, "zorroza: la estación, pegada al andén")
			chk(range(4, W - 1).all(func(x): return String(m.g[8][x]) == "hormigon" or m.o[8][x] != null), "zorroza: el andén, entre la vía y la estación")
			chk(m.o[24][29] == "fountain" and bld(m, "iglesiaZ"), "zorroza: la parroquia en su plaza con la fuente")
			chk(m.o[CALLE_Y + 4][12] == "parada", "zorroza: la parada en la avenida")
		"lapunta":   # la orilla en diagonal: la punta arriba a la izquierda, donde el Kadagua entra en la ría
			var prim := []
			for y in range(4, 14):
				var x0 := 0
				while x0 < W and agua(m, x0, y):
					x0 += 1
				prim.append(x0)
			var baja := true
			for i in range(1, prim.size()):
				baja = baja and prim[i] < prim[i - 1]
			chk(baja, "lapunta: la orilla, en diagonal %s" % [prim])
			var mo: Dictionary = bld(m, "molino")
			chk(mo and int(mo.x0) < 15 and int(mo.y0) <= 6, "lapunta: el molino, en la punta")
			chk(range(H).all(func(y): return agua(m, 0, y)), "lapunta: el Kadagua, al oeste de arriba abajo (la punta: no se sigue)")
			chk(not m.exits.keys().any(func(c): return int(String(c).split(",")[0]) == 0), "lapunta: sin salida al oeste")
			var nor := 0
			for x in W:
				nor += 1 if m.o[4][x] == "noray" else 0
			chk(nor >= 6, "lapunta: los norays del muelle (%d)" % nor)
		"abando":   # la plaza elíptica, la Gran Vía de la plaza a la ría, la torre más alta y la ría al este
			chk(range(H).all(func(y): return agua(m, W - 1, y) or (y >= CALLE_Y - 1 and y <= CALLE_Y + 6)), "abando: la ría, al este (salvo el puente)")
			chk(m.o[16][13] == "fountain" and m.o[16][49] == "estatua", "abando: la fuente en la plaza elíptica y la estatua en la redonda")
			var pl := 0
			for y in H:
				for x in range(0, 27):
					pl += 1 if String(m.g[y][x]) == "plaza" else 0
			chk(pl >= 120, "abando: la plaza elíptica, grande (%d)" % pl)
			var al := {}
			for b in m.blds:
				al[String(b.id)] = int(b.h)
			chk(al.get("torreBBVA", 0) > 0 and al.values().all(func(h): return h <= al.torreBBVA), "abando: la torre, la más alta")
			chk(range(13, W - 1).all(func(x): return libre(m, x, CALLE_Y) or m.o[CALLE_Y][x] != null), "abando: la Gran Vía, de la plaza a la ría")
			chk(range(59, W).all(func(x): return not agua(m, x, CALLE_Y)), "abando: el puente, que sigue en el Casco")
			# la retícula del Ensanche: calles de norte a sur que cruzan la Gran Vía de lado a lado del mapa, con manzanas entre ellas
			var calles := []
			for x in range(1, W - 1):
				var fuera := range(H).filter(func(y): return y < CALLE_Y - 2 or y > CALLE_Y + 7)   # la glorieta, aparte
				if fuera.all(func(y): return String(m.g[y][x]) in ["roadL", "roadX"]) and fuera.all(func(y): return String(m.g[y][x + 1]) in ["roadR", "roadX"]):
					calles.append(x)
			chk(calles.size() >= 3, "abando: calles de norte a sur que cruzan la Gran Vía %s" % [calles])
			var vg := 0   # la Gran Vía, cortada por las calles: en cada cruce, el asfalto sin bordillo
			for x in calles:
				vg += 1 if String(m.g[CALLE_Y + 2][x]) == "roadX" and String(m.g[CALLE_Y + 3][x + 1]) == "roadX" or String(m.g[CALLE_Y - 2][x]) == "roadX" else 0
			chk(vg == calles.size(), "abando: los cruces con la Gran Vía")
			var mz := 0   # manzanas: edificios entre dos calles, al norte y al sur
			for i in range(1, calles.size()):
				for b in m.blds:
					mz += 1 if int(b.x0) > int(calles[i - 1]) + 2 and int(b.x0) + int(b.w) <= int(calles[i]) - 1 else 0
			chk(mz >= 3, "abando: manzanas entre las calles (%d)" % mz)
			# las dos plazas, glorietas: el asfalto del cruce alrededor de la isleta, con la fuente y la estatua dentro
			for c in [[13, 16, "fountain"], [49, 16, "estatua"]]:
				var cx: int = c[0]
				var cy: int = c[1]
				var anillo := true
				var x0 := cx
				while x0 > 0 and String(m.g[cy][x0]) != "roadX":
					x0 -= 1
				var x1 := cx
				while x1 < W - 1 and String(m.g[cy][x1]) != "roadX":
					x1 += 1
				var y0 := cy
				while y0 > 0 and String(m.g[y0][cx]) != "roadX":
					y0 -= 1
				var y1 := cy
				while y1 < H - 1 and String(m.g[y1][cx]) != "roadX":
					y1 += 1
				for y in range(y0 + 1, y1):
					for x in range(x0 + 1, x1):
						anillo = anillo and not String(m.g[y][x]).begins_with("road")
				chk(m.o[cy][cx] == c[2] and anillo and x1 - x0 >= 3 and y1 - y0 >= 3 and String(m.g[y0][x0]) == "roadX" and String(m.g[y1][x1]) == "roadX", "abando: la %s en su isleta, con la glorieta alrededor (%d..%d, %d..%d)" % [c[2], x0, x1, y0, y1])
		"casco":   # la ría al oeste y al sur; el Arenal; las Siete Calles; la plaza porticada cerrada; el mercado en la orilla
			chk(range(0, 13).all(func(y): return agua(m, 0, y) and agua(m, 3, y)), "casco: la ría, al oeste")
			chk(range(0, 17).all(func(x): return agua(m, x, 38)), "casco: la ría, al sur")
			var siete := 0   # en la fila 22, los tramos libres entre manzanas, y cada uno libre de la calle a la Ribera
			var x := 14
			while x < W - 1:
				if libre(m, x, 22) and not libre(m, x - 1, 22) or (x == 14 and libre(m, x, 22)):
					var col := x
					if range(20, 31).all(func(y): return libre(m, col, y) or m.o[y][col] != null):
						siete += 1
				x += 1
			chk(siete >= 7, "casco: las Siete Calles, en paralelo (%d)" % siete)
			# entre las calles, manzanas de fachada seguida: de la fila 20 a la 29, todo casas salvo un solo cantón
			var mzs := 0
			var sueltas := 0
			for b in m.blds:
				if String(b.id) == "casco2":
					mzs += 1
					var cx := int(b.x0)
					var hueco := 0
					for y in range(20, 30):
						hueco += 0 if String(m.g[y][cx]).begins_with("roof") or String(m.g[y][cx]).begins_with("wall") else 1
					sueltas += 0 if hueco == 1 else 1
			chk(mzs >= 5 and sueltas == 0, "casco: las manzanas de las Siete Calles, seguidas y con un solo cantón (%d, %d sueltas)" % [mzs, sueltas])
			var B := {"30,10": true, "31,10": true}
			var vb: Dictionary = J.andable(m, m.o, B)
			chk(v.has("30,6") and not vb.has("30,6"), "casco: la plaza porticada, cerrada salvo por su paso")
			var me: Dictionary = bld(m, "mercadoR")
			chk(me and agua(m, int(me.x0) - 1, int(me.y0) + int(me.h) - 1), "casco: el mercado, en la orilla")
			chk(range(36, H - 1).all(func(y): return String(m.g[y][46]) == "puenteV" and agua(m, 49, y)), "casco: el puente, sobre la ría")
			var ar := 0
			for y in range(1, 13):
				ar += 1 if m.o[y][9] == null and not agua(m, 9, y) else 0
			chk(bld(m, "kiosko") and bld(m, "teatro") and int(bld(m, "teatro").y0) > int(bld(m, "kiosko").y0), "casco: el Arenal con el kiosko, y el teatro enfrente")

func _encerradas(m: Dictionary, v: Dictionary) -> Array:
	var r := []
	for y in int(m.h):
		for x in int(m.w):
			if m.o[y][x] in ["papelera", "bench", "lamp", "bolardo"] and not (v.has("%d,%d" % [x + 1, y]) or v.has("%d,%d" % [x - 1, y]) or v.has("%d,%d" % [x, y + 1]) or v.has("%d,%d" % [x, y - 1])):
				r.append(Vector2i(x, y))
	return r
