# MAESTRO [4] (con Datos.CAL): la carretera comarcal entre Mendialde y Errotabarri (CAMPO), las landraces salvajes de su claro y el
# caserío abandonado como refugio (dormir y esconder lo que lleves; la redada no llega). La botritis, en granja.gd; el control de
# carretera, en eventos.gd (control_trafico).
# Cadena: … → eventos → campo → retencion → juego.
extends "res://src/eventos.gd"

func campo_ok() -> bool:
	return Datos.CAL and D.has("CAMPO") and S != null and int(S.ch) >= int(D.CAMPO.ch)

func campo_s() -> Dictionary:
	if not (S.get("campo") is Dictionary):
		S.campo = {"r": {}, "ref": {}}
	return S.campo

# las salidas de lado de Mendialde y Errotabarri a la comarcal (por la carretera y por la pista) y, en la comarcal, sus salvajes
func montar_campo(mapa: String) -> void:
	if not Datos.CAL or not D.has("CAMPO") or S == null:
		return
	var C: Dictionary = D.CAMPO
	if C.puertas.has(mapa):
		var m: Dictionary = MAPS[mapa]
		for q in C.puertas[mapa]:
			var k := "%d,%d" % [int(q[0]), int(q[1])]
			if campo_ok():
				var der: bool = int(q[0]) > 0
				m.exits[k] = {"to": C.mapa, "x": int(q[2]), "y": int(q[3]), "dir": "right" if der else "left", "lado": "right" if der else "left"}
			else:
				m.exits.erase(k)
	if mapa != C.mapa:
		return
	var mc: Dictionary = MAPS[C.mapa]
	for i in C.sitios.size():
		var s: Array = C.sitios[i]
		var w := salvaje(i)
		mc.o[int(s[1])][int(s[0])] = sprite_salvaje(w) if not w.is_empty() else null

# la red de carreteras (lo pidió el usuario: «no hay más caminos entre los demás pueblos? Habría que crearlos»; la red completa):
# siete carreteras que se andan como la comarcal (MAPS carr-*, de tools/carreteras.py), abiertas cuando sus dos pueblos tienen
# autobús (CARRETERAS.rutas[*].ch). En cada pueblo, la casilla del borde pasa a suelo sin estorbo y lleva a su carretera; sin CAL
# o sin abrir, el borde como estaba (CARR_ORIG)
static var CARR_ORIG := {}

func carretera_ok(id: String) -> bool:
	return Datos.CAL and D.has("CARRETERAS") and S != null and D.CARRETERAS.rutas.has(id) and int(S.ch) >= int(D.CARRETERAS.rutas[id].ch)

func montar_carreteras(mapa: String) -> void:
	if not D.has("CARRETERAS") or not MAPS.has(mapa):
		return
	var C: Dictionary = D.CARRETERAS
	if not C.puertas.has(mapa):
		return
	var m: Dictionary = MAPS[mapa]
	var abiertas := {}
	for q in C.puertas[mapa]:
		var k := "%d,%d" % [int(q[0]), int(q[1])]
		if carretera_ok(String(q[2])):
			abiertas[k] = true
			m.exits[k] = {"to": String(q[2]), "x": int(q[3]), "y": int(q[4]), "dir": "right" if int(q[3]) <= 1 else "left", "lado": String(q[5])}
		elif m.exits.has(k) and String(m.exits[k].to) == String(q[2]):
			m.exits.erase(k)
	for c in C.abre.get(mapa, []):   # [x, y, la salida que la abre]: la del norte de Errotabarri pasa por la fila 1
		var x := int(c[0])
		var y := int(c[1])
		var k := "%d,%d" % [x, y]
		var ko := mapa + "|" + k
		if abiertas.has("%d,%d" % [int(c[2]), int(c[3])]):
			if not CARR_ORIG.has(ko):
				CARR_ORIG[ko] = [m.g[y][x], m.o[y][x]]
			var dx := 1 if x == 0 else (-1 if x == int(m.w) - 1 else 0)
			var dy := 1 if y == 0 else (-1 if y == int(m.h) - 1 else 0)
			var g: String = String(m.g[y + dy][x + dx])
			m.g[y][x] = g if not SOLID_G.search(g) else "grass"
			m.o[y][x] = null
		elif CARR_ORIG.has(ko):
			m.g[y][x] = CARR_ORIG[ko][0]
			m.o[y][x] = CARR_ORIG[ko][1]
			CARR_ORIG.erase(ko)

# la planta salvaje del sitio i esta semana: {sid, t} (t: «sem», madura con semillas; «esq», en vegetativo, para esquejes) o {}.
# Según el clima: en invierno no hay; con tormenta o nieve, ese día no se ve; y lo recogido no vuelve hasta CAMPO.vuelve días
func salvaje(i: int) -> Dictionary:
	if not campo_ok():
		return {}
	var C: Dictionary = D.CAMPO
	var r = campo_s().r.get(str(i))
	if r != null and S.day - int(r) < int(C.vuelve):
		return {}
	if Datos.tiempo(S.day, 720).k in C.no:
		return {}
	var mes := float(Datos.fecha(S.day).m)   # los números de datos.json son float
	var t := "sem" if mes in C.sem else ("esq" if mes in C.esq else "")
	if t == "":
		return {}
	var wk: int = int(S.day) / 7
	if Datos.hash_str("salv%d_%d" % [wk, i]) % 100 >= int(float(C.p) * 100):
		return {}
	var B: Array = D._base.BANCO if D.has("_base") else D.BANCO
	return {"sid": String(B[Datos.hash_str("salvsid%d_%d" % [wk, i]) % B.size()][0]), "t": t}

func sprite_salvaje(w: Dictionary) -> String:
	var ind: float = float(Datos.ind_de(S, w.sid))
	return "hp%d-%d" % [0 if ind >= 70 else (1 if ind <= 30 else 2), 5 if w.t == "sem" else 3]   # i18n-no

func campo_obj(x: int, y: int, o) -> bool:
	if await huerta_obj(x, y, o):   # la huerta de la tía
		return true
	if not Datos.CAL or not D.has("CAMPO"):
		return false
	var C: Dictionary = D.CAMPO
	if S.map == C.mapa and o is String and o.begins_with("hp"):
		for i in C.sitios.size():
			if int(C.sitios[i][0]) == x and int(C.sitios[i][1]) == y:
				await recoger_salvaje(i)
				return true
	if S.map == C.refugio.map:
		if o == C.refugio.caja:
			await escondite()
			return true
		if o == "bedT" or o == "bedB":   # i18n-no
			await bed_action(K("Un camastro con una manta de lana. Aquí no te busca nadie."))
			return true
		if o == "table":
			await say(K("Una mesa de castaño con un candil. Alguien dejó un mapa de la comarca con los claros marcados en lápiz."))
			return true
		if o == "iwin":
			await say(K("Por la ventana, la carretera comarcal y el monte."))
			return true
	return false

func recoger_salvaje(i: int) -> void:
	var w := salvaje(i)
	if w.is_empty():
		return
	var s = strain(w.sid)
	if w.t == "sem":
		var C: Dictionary = D.CAMPO
		var nn: int = int(C.n[0]) + Datos.hash_str("salvn%d_%d" % [S.day, i]) % (int(C.n[1]) - int(C.n[0]) + 1)
		if await ask(T("Una {s} salvaje, madura y con semillas en los cogollos.", {"s": s.n}), [K("Recoger semillas"), K("Dejarla")]) != 0:
			return
		await gesto("cosechar")
		add_seeds(w.sid, nn)
		campo_s().r[str(i)] = S.day
		sfx("get")
		await say(T("Sacas {n} semillas puras de {s}. Van con las demás, para plantar o cruzar.", {"n": nn, "s": s.n}))
	else:
		if await ask(T("Una {s} salvaje en pleno crecimiento.", {"s": s.n}), [K("Sacar esqueje"), K("Dejarla")]) != 0:
			return
		if S.esquejes.size() >= 12:
			await say(K("El propagador está lleno: 12 esquejes. Planta alguno antes."))
			return
		await gesto("esqueje")
		S.esquejes.append({"sid": w.sid, "f": roll_feno(w.sid), "dia": S.day})
		discover(w.sid)
		campo_s().r[str(i)] = S.day
		sfx("get")
		await say(T("Cortas una punta de la {s} y la envuelves en papel húmedo. Plántala antes del {d}.", {"s": s.n, "d": Datos.fd(S.day + D.ESQUEJE_DIAS + 1, S.day)}))
	MAPS[S.map].o[int(D.CAMPO.sitios[i][1])][int(D.CAMPO.sitios[i][0])] = null

# el arcón del caserío: lo que escondes aquí no lo encuentran ni la redada ni Darko
func escondite() -> void:
	var R: Dictionary = campo_s().ref
	while true:
		var gl := 0.0
		for k in R:
			gl += float(R[k].g)
		var c: int = await ask(T("Un arcón de madera bajo unos sacos. Dentro: {g}.", {"g": g_txt(gl)}), [K("Esconder lo que llevo"), K("Sacarlo todo"), K("Nada")])
		if c == 0:
			var n_ := 0
			for k in S.buds.keys():
				if float(S.buds[k].g) >= 1:
					mover_lote(S.buds, R, k, float(S.buds[k].g))
					n_ += 1
			await say(K("Lo metes en el arcón y lo tapas con los sacos.") if n_ else K("No llevas cogollos encima."))
		elif c == 1:
			if R.is_empty():
				await say(K("El arcón está vacío."))
				continue
			for k in R.keys():
				mover_lote(R, S.buds, k, float(R[k].g))
			await say(K("Lo sacas todo del arcón y lo guardas en la mochila."))
		else:
			return

# ---------- la huerta abandonada de la tía (lo pidió el usuario: «encontrar la huerta abandonada de al lado de casa, en el pueblo,
# para poder cultivar ahí en exterior»; con Datos.CAL) ----------
# Detrás del garaje, entre las zarzas del monte (town 9,1), una cancilla: con A, te abres paso y queda una senda con la puerta a la
# huerta (MAPS.huerta, hecho aquí: 30 × 12, el monte alrededor y, dentro del seto, cuatro bancales y un camino; la huerta, de 16 × 10,
# en medio para que la cámara no vea fuera del mapa). Desbrozada (HUERTA.desbroce minutos), ocho sitios en tierra:
# se plantan, riegan, abonan, tratan y cosechan como las macetas (pot_action con hu), al raso: crecen con la temperatura del
# día (Datos.tiempo), en vegetativo dentro de HUERTA.veg (del 20 de abril al 5 de agosto) y florecen fuera; cuantos más días en
# vegetativo, más gramos (HUERTA.g, hasta HUERTA.cap). La lluvia las riega; la helada y la nieve les quitan salud; con lluvia en
# floración, la botritis. Sin luz que pagar ni olor en casa. S.huerta: {v: el día que la encontraste, l: el que la desbrozaste,
# p: las plantas de los sitios}
const HUERTA := {"mapa": "huerta", "w": 30, "h": 16, "seto": [5, 1, 24, 14], "camino": 14, "puerta": [9, 1], "senda": [[9, 0], [9, 2]], "llega": [15, 13], "sale": [9, 2],   # i18n-no
	"sitios": [[8, 6], [11, 6], [17, 6], [20, 6], [8, 11], [11, 11], [17, 11], [20, 11]], "bancales": [[7, 4, 13, 7], [16, 4, 22, 7], [7, 9, 13, 12], [16, 9, 22, 12]],
	"atrezo": [[8, 3, "bidonT"], [8, 13, "cuboS"], [21, 3, "manzano"], [21, 13, "crate"], [20, 13, "sacos"]],   # i18n-no
	"desbroce": 240, "riego": 30, "veg": [420, 805], "g": 250, "cap": 500, "veg_dias": 60,
	"agua": [.2, .2, .3, .35, .45, .6, .7, .7, .5, .35, .25, .2], "plaga": 1.2, "helada": 25, "nieve": 50}
var _town19 = null   # lo que había en town en la cancilla y la senda, para dejarlo como estaba sin CAL
# las mejoras (lo pidió el usuario: «Opción a comprar mejoras como tanques de agua de 1m3 o tanques azules de 100L dependiendo, también
# sistema de riego... Herramientas para trabajar la tierra o motoazada siguiente mejora... Habría que hacer los sprites»): en la
# tienda online, ya desbrozada, y al día siguiente en la huerta (S.huerta.ped, llega_huerta; S.huerta.m, lo que hay). Los bidones de
# 100 L y los depósitos de 1000 L (S.huerta.agua, los litros) se llenan con la manguera del garaje (caudal, L/min); el goteo con la
# placa solar riega cada planta al bajar de umbral con los litros de su tamaño (litros: de la plántula a la grande) mientras quede
# agua; las herramientas cavan un sitio vacío (herr.min) y la motoazada labra todos los vacíos (moto.min): la tierra trabajada
# (S.huerta.t: 0, 1 cavada, 2 labrada) da g más de cosecha hasta que el sitio se vacía. Dibujos en huerta_mej.py; x, dónde van.
const HUERTA_MEJ := {"bidon": {"p": 35, "l": 100, "max": 3, "x": [[9, 2], [10, 2], [11, 2]]}, "ibc": {"p": 95, "l": 1000, "max": 2, "x": [[17, 2], [19, 2]]},   # i18n-no
	"goteo": {"p": 150, "x": [[12, 2]]}, "herr": {"p": 60, "g": .15, "min": 45, "x": [[6, 8]]}, "moto": {"p": 490, "g": .3, "min": 40, "x": [[23, 8]]},   # i18n-no
	"amp": {"p": 1200, "dy": 10, "bancales": [[7, 14, 13, 17], [16, 14, 22, 17], [7, 19, 13, 22], [16, 19, 22, 22]],   # i18n-no
		"sitios": [[8, 16], [11, 16], [17, 16], [20, 16], [8, 21], [11, 21], [17, 21], [20, 21]]},
	"caudal": 15, "umbral": 50, "litros": [3, 17]}
const HUERTA_SPR := {"bidon": "bidonA", "goteo": "bombaS", "herr": "herrH", "moto": "motoA"}   # i18n-no

# la huerta ampliada (lo pidió el usuario: «Molaría que fuese ampliable en espacio la huerta, para poder plantar por lo menos el doble
# de plantas»): la obra de la tienda (HUERTA_MEJ.amp, al día siguiente) baja el seto amp.dy casillas por el monte de abajo y deja cuatro
# bancales más con ocho sitios más (16); los de siempre no se mueven (S.huerta.p y t van por su número) y la salida, la llegada y lo
# que había junto al seto de abajo bajan con él. huerta_def(): HUERTA, o la ampliada (hecha una vez)
var _huerta_a = null

func huerta_amp() -> bool:
	return Datos.CAL and S != null and S.get("huerta") is Dictionary and S.huerta.get("m") is Dictionary and int(S.huerta.m.get("amp", 0)) > 0

func huerta_def() -> Dictionary:
	if not huerta_amp():
		return HUERTA
	if _huerta_a == null:
		var A: Dictionary = HUERTA_MEJ.amp
		var dy: int = A.dy
		var y1: int = HUERTA.seto[3]
		var h: Dictionary = HUERTA.duplicate(true)
		h.h = int(HUERTA.h) + dy
		h.seto[3] = y1 + dy
		h.llega[1] = int(HUERTA.llega[1]) + dy
		h.sitios = h.sitios + A.sitios.duplicate(true)
		h.bancales = h.bancales + A.bancales.duplicate(true)
		for a in h.atrezo:
			if int(a[1]) == y1 - 1:
				a[1] = int(a[1]) + dy
		_huerta_a = h
	return _huerta_a

func huerta_s() -> Dictionary:
	if not (S.get("huerta") is Dictionary):
		S.huerta = {"v": 0, "l": 0, "p": []}
	var h: Dictionary = S.huerta
	while h.p.size() < huerta_def().sitios.size():
		h.p.append(null)
	if Datos.CAL:   # las mejoras
		for k in ["m", "ped", "agua", "t"]:   # i18n-no
			if not h.has(k):
				h[k] = {} if k == "m" else ([] if k == "ped" else (0.0 if k == "agua" else []))
		while h.t.size() < huerta_def().sitios.size():
			h.t.append(0)
	return h

func huerta_m(k: String) -> int:   # cuántos hay en la huerta
	return int(huerta_s().get("m", {}).get(k, 0))

func huerta_ped(k: String) -> int:   # cuántos llegan mañana
	return huerta_s().get("ped", []).filter(func(q): return q[0] == k).size()

func huerta_cap() -> int:   # los litros de los depósitos
	return huerta_m("bidon") * int(HUERTA_MEJ.bidon.l) + huerta_m("ibc") * int(HUERTA_MEJ.ibc.l)

func huerta_t(i: int) -> int:   # la tierra del sitio i: 0 sin trabajar, 1 cavada, 2 labrada
	var t: Array = huerta_s().get("t", [])
	return int(t[i]) if i >= 0 and i < t.size() else 0

func huerta_vista() -> bool:   # ¿la has encontrado?
	return Datos.CAL and S != null and S.get("huerta") is Dictionary and int(S.huerta.get("v", 0)) > 0

func huerta_lista() -> bool:   # ¿desbrozada?
	return huerta_vista() and int(S.huerta.get("l", 0)) > 0

# con CAL, los mapas de Bilbao (tools/bilbao.py, Datos._aplica_auto); si CAL cambia con la partida en marcha (las pruebas), el mapa
# vuelve a salir de D.MAPS en su sitio y lo que se montaba encima empieza de cero
func mapas_bilbao(k: String) -> void:
	if not D.get("BILBAO", {}).get("MAPS", {}).has(k) or not MAPS.has(k):
		return
	Datos.carga()
	var m: Dictionary = MAPS[k]
	if m.get("_bi") == Datos.CAL:
		return
	m.clear()
	m.merge(D.MAPS[k].duplicate(true))
	Datos.enteros(m)
	m._bi = Datos.CAL
	_arb0.erase(k)
	_arb_k.erase(k)
	_aparc0.erase(k)
	_neg0.erase(k)
	if k == "alto":
		_alto0 = null
	if k == GARAJE:
		_garaje0 = null
	for c in CARR_ORIG.keys():
		if String(c).begins_with(k + "|"):
			CARR_ORIG.erase(c)

func montar_huerta(k: String) -> void:
	if k == "town" and MAPS.has("town"):
		var m: Dictionary = MAPS.town
		var q: Array = HUERTA.puerta
		var cs: Array = [q] + HUERTA.senda   # la cancilla y la senda que lleva a ella, de tierra pisada
		if _town19 == null:
			_town19 = cs.map(func(c): return [m.g[c[1]][c[0]], m.o[c[1]][c[0]]])
		var kq := "%d,%d" % [q[0], q[1]]
		for i in cs.size():
			m.g[cs[i][1]][cs[i][0]] = "dirt" if huerta_vista() else _town19[i][0]   # i18n-no
			m.o[cs[i][1]][cs[i][0]] = null if huerta_vista() else _town19[i][1]
		if huerta_vista():
			m.doors[kq] = {"to": HUERTA.mapa, "x": int(huerta_def().llega[0]), "y": int(huerta_def().llega[1]), "dir": "up"}
		else:
			m.doors.erase(kq)
	if k == HUERTA.mapa:
		MAPS[HUERTA.mapa] = mapa_huerta()

# el mapa: el monte alrededor; dentro del seto (HUERTA.seto: x0, y0, x1, y1), una fila de monte arriba, el camino de tierra por el
# medio hasta la salida de abajo y los cuatro bancales (con zarzas y hierba alta hasta que la desbrozas; luego, la tierra arada con
# lo plantado)
func mapa_huerta() -> Dictionary:
	var HD := huerta_def()
	var W: int = HD.w
	var H: int = HD.h
	var x0: int = HD.seto[0]
	var y0: int = HD.seto[1]
	var x1: int = HD.seto[2]
	var y1: int = HD.seto[3]
	var cx: int = HD.camino
	var g := []
	var o := []
	for y in H:
		g.append([])
		o.append([])
		for x in W:
			g[y].append("grass")   # i18n-no
			# debajo del seto, hierba: el monte taparía lo de la última fila; y una casilla de hierba a cada lado del seto, que el
			# monte no lo tape
			var dentro: bool = x >= x0 - 1 and x <= x1 + 1 and y > y0
			o[y].append(null if dentro else ("monte" if (x * 7 + y * 3) % 5 < 3 else "monte2"))   # i18n-no
	# el seto de PixelLab por piezas (seto-huerta, pixellab_setos.py): los tramos de los lados con su remate arriba, las esquinas y el
	# tramo de abajo con sus remates junto al camino; dos variantes alternas para que no se vea la repetición
	for y in range(y0 + 1, y1):
		var v: String = "" if y == y0 + 1 else ("2" if y % 2 else "")   # i18n-no
		o[y][x0] = ("setoV0" if y == y0 + 1 else "setoV") + v   # i18n-no
		o[y][x1] = ("setoV0d" if y == y0 + 1 else "setoVd") + v   # i18n-no
	o[y1][x0] = "setoL"   # i18n-no
	o[y1][x1] = "setoR"   # i18n-no
	for x in range(x0 + 1, x1):
		o[y1][x] = "setoHd" if x == cx - 1 else ("setoHi" if x == cx + 2 else ("setoH2" if x % 2 else "setoH"))   # i18n-no
	for y in range(y0 + 1, H):
		g[y][cx] = "dirt"   # i18n-no
		g[y][cx + 1] = "dirt"   # i18n-no
		if y == y1:
			o[y][cx] = null
			o[y][cx + 1] = null
	var lista := huerta_lista()
	for b in HD.bancales:
		for y in range(int(b[1]), int(b[3]) + 1):
			for x in range(int(b[0]), int(b[2]) + 1):
				g[y][x] = "surco" if lista else "tallgrass"   # i18n-no
				if not lista and (x + y) % 2 == 0:
					o[y][x] = "bush"   # i18n-no
	for a in HD.atrezo:   # el bidón con la manguera del grifo del garaje, el cubo, el manzano, las herramientas y el compost
		o[int(a[1])][int(a[0])] = a[2]
	var m := {"name": HUERTA.mapa, "w": W, "h": H, "g": g, "o": o, "exits": {}, "doors": {}, "music": "town", "blds": [], "est": null}   # i18n-no
	for x in [cx, cx + 1]:
		m.doors["%d,%d" % [x, y1]] = {"to": "town", "x": int(HD.sale[0]), "y": int(HD.sale[1]), "dir": "down"}   # i18n-no
	if lista:
		m.o = o
		huerta_objs(m)
	return m

# las mejoras que hay, en su sitio (HUERTA_MEJ.x), el depósito de 1000 L con el agua por cuartos, y la tierra trabajada más oscura
func huerta_mejoras(m: Dictionary) -> void:
	if not Datos.CAL:
		return
	var cap := huerta_cap()
	var q: int = clampi(roundi(4.0 * float(huerta_s().agua) / cap), 0, 4) if cap > 0 else 0
	for k in ["bidon", "ibc", "goteo", "herr", "moto"]:   # i18n-no
		var xs: Array = HUERTA_MEJ[k].x
		for j in xs.size():
			m.o[int(xs[j][1])][int(xs[j][0])] = (("ibcD-%d" % q) if k == "ibc" else HUERTA_SPR[k]) if j < huerta_m(k) else null   # i18n-no
	for i in huerta_def().sitios.size():
		for c in huerta_bloque(i):
			m.g[int(c[1])][int(c[0])] = "surcoV" if huerta_t(i) > 0 else "surco"   # i18n-no

# lo pidió el usuario: «se plantan en el suelo pero se hacen más grandes cada planta y la distancia de una a otra es de una baldosa,
# en los bancales que has hecho en el mapa, bien centradas». Cada sitio es un bloque de 2 × 2 casillas (HUERTA.sitios, la de abajo a la
# izquierda), dos por bancal con una casilla libre en medio: la planta se pinta en esa casilla con el pie del tallo en el centro del
# bloque (huerta_pl.py) y las otras tres llevan hgx, sólido y sin dibujo, como la planta, que no se pisa. Y (lo dijo el usuario: «Me
# parece como que están fuera las plantas no?») una casilla de tierra alrededor de los dos bloques, bancales de 7 × 4: la mata entera
# (hasta 20 px a los lados del pie y 23 por encima) queda dentro del bancal
func gesto_sol() -> bool:   # el plano de cerca de la huerta, al sol y en la tierra (eventos.gd)
	return Datos.CAL and S != null and S.get("map") == HUERTA.mapa

func huerta_bloque(i: int) -> Array:
	var s: Array = huerta_def().sitios[i]
	var x: int = int(s[0])
	var y: int = int(s[1])
	return [[x, y], [x + 1, y], [x, y - 1], [x + 1, y - 1]]

func huerta_idx(x: int, y: int) -> int:   # el sitio cuyo bloque tiene la casilla (x, y), o -1
	var st: Array = huerta_def().sitios
	for i in st.size():
		if (x == int(st[i][0]) or x == int(st[i][0]) + 1) and (y == int(st[i][1]) or y == int(st[i][1]) - 1):
			return i
	return -1

# hg-<porte>-<fase> (huerta_pl.py): el porte por la variedad (y el fenotipo), la fase por el progreso; seca, hgs-… (pinta.gd la pinta
# parda); pinta.gd le pone el tono de hoja y el color de cogollo de su variedad, como a las de las mesas de la nave
func sprite_huerta(p):
	if not (p is Dictionary):
		return null
	var fa: int = 1 if p.prog < .12 else (2 if p.prog < .35 else (3 if p.prog < .65 else (4 if p.prog < 1 else 5)))
	return ("hgs-%s-%d" if p.get("dead") else "hg-%s-%d") % [Datos.porte_planta(S, p), fa]   # i18n-no

func huerta_objs(m = null) -> void:
	if m == null:
		if not MAPS.has(HUERTA.mapa) or not huerta_lista():
			return
		m = MAPS[HUERTA.mapa]
	for i in huerta_def().sitios.size():
		var s: Array = huerta_def().sitios[i]
		for c in huerta_bloque(i):
			m.o[int(c[1])][int(c[0])] = "hgx"   # i18n-no
		var sp = sprite_huerta(huerta_s().p[i])
		if sp != null:
			m.o[int(s[1])][int(s[0])] = sp
	huerta_mejoras(m)

func huerta_veg(dia: int) -> bool:   # ¿días largos? (dentro de HUERTA.veg, mes × 100 + día)
	var f := Datos.fecha(dia)
	var md: int = int(f.m) * 100 + int(f.d)
	return md >= int(HUERTA.veg[0]) and md <= int(HUERTA.veg[1])

# los factores de una planta de la huerta, como Cultivo.factores de una plaza: sin foco ni maceta, el sol y la tierra
func huerta_f(p, i := -1) -> Dictionary:
	var vd: float = float(p.get("vd", 0)) if p is Dictionary else 0.0
	var t: float = float(Datos.tiempo(S.day, S.min).t)
	var tg: int = huerta_t(i) if Datos.CAL else 0   # la tierra trabajada
	var mas: float = 0.0 if tg == 0 else float(HUERTA_MEJ.herr.g if tg == 1 else HUERTA_MEJ.moto.g)
	return {"g": float(HUERTA.g) * clampf(vd / float(HUERTA.veg_dias), .25, 1.0) * (1 + mas), "cap": float(HUERTA.cap), "crec": Cultivo.f_clima({"t": t, "hr": 50.0}), "thc": 0.0,
		"agua": float(HUERTA.agua[int(Datos.fecha(S.day).m) - 1]), "plaga": float(HUERTA.plaga), "hr": 50.0, "moho": 1.0, "ciclo": "veg" if huerta_veg(S.day) else "flor"}   # i18n-no

func huerta_hu(i: int) -> Dictionary:
	var s: Array = huerta_def().sitios[i]
	var p = huerta_s().p[i]
	return {"l": huerta_s().p, "v": [(int(s[0]) + 1) * 16, int(s[1]) * 16], "f": huerta_f(p, i)}   # el centro de la mata, en el pie

func plants_advance(mn: int) -> void:
	super(mn)
	huerta_avanza(mn)

# cada rato: crecen (Cultivo.plant_step), la lluvia las riega y cuentan los días en vegetativo
func huerta_avanza(mn: int) -> void:
	if not huerta_lista():
		return
	var L: Array = huerta_s().p
	var llueve: bool = Datos.tiempo(S.day, S.min).k in ["lluvia", "tormenta"]   # i18n-no
	var cambia := false
	var got: bool = Datos.CAL and huerta_m("goteo") > 0
	for i in L.size():
		var p = L[i]
		if not (p is Dictionary) or p.get("dead"):
			continue
		var a = sprite_huerta(p)
		if llueve:
			p.water = 100.0
		if p.prog >= .12 and p.prog < .65:
			p.vd = float(p.get("vd", 0)) + mn / 1440.0
		Cultivo.plant_step(S, p, mn / 60.0, huerta_f(p, i))
		if got and not llueve:
			huerta_gotea(p)
		cambia = cambia or sprite_huerta(p) != a
	var cap := huerta_cap()
	if Datos.CAL and huerta_m("ibc") > 0 and MAPS.has(HUERTA.mapa):   # el depósito de 1000 L, por cuartos
		var ix: Array = HUERTA_MEJ.ibc.x[0]
		cambia = cambia or MAPS[HUERTA.mapa].o[int(ix[1])][int(ix[0])] != "ibcD-%d" % clampi(roundi(4.0 * float(huerta_s().agua) / cap), 0, 4)   # i18n-no
	if cambia:
		huerta_objs()

# el goteo: si la tierra de la planta se ha secado (agua por debajo del umbral), los litros que le faltan, de los depósitos; si no
# llegan, lo que quede
func huerta_gotea(p: Dictionary) -> void:
	var h := huerta_s()
	if float(p.water) >= float(HUERTA_MEJ.umbral) or float(h.agua) <= 0:
		return
	var lp: float = float(HUERTA_MEJ.litros[0]) + float(HUERTA_MEJ.litros[1]) * clampf(float(p.prog), 0, 1)   # los litros de la planta llena
	var pide: float = (100.0 - float(p.water)) / 100.0 * lp
	var da: float = minf(pide, float(h.agua))
	p.water = float(p.water) + da / lp * 100.0
	h.agua = float(h.agua) - da

func new_day() -> void:
	super()
	llega_huerta()
	huerta_dia()

# lo pedido para la huerta, al día siguiente
func llega_huerta() -> void:
	if not Datos.CAL or not (S.get("huerta") is Dictionary) or S.huerta.get("ped", []).is_empty():
		return
	var h := huerta_s()
	var ll := []
	var quedan := []
	for q in h.ped:
		if int(q[1]) <= S.day:
			h.m[q[0]] = int(h.m.get(q[0], 0)) + 1
			ll.append(huerta_mej_art(String(q[0])))
		else:
			quedan.append(q)
	h.ped = quedan
	if ll.is_empty():
		return
	if MAPS.has(HUERTA.mapa):
		MAPS[HUERTA.mapa] = mapa_huerta()
	if huerta_amp():   # la llegada desde la cancilla, al camino de la huerta ampliada
		montar_huerta("town")   # i18n-no
	var L := [T("Te dejan en la huerta lo que pediste: {l}.", {"l": _lista(ll)})]
	queue("huerta", func():
		sfx("get")
		await say(L[0]), [["", L]])

func huerta_mej_n(k: String) -> String:
	return {"bidon": K("Bidón azul de 100 L"), "ibc": K("Depósito de 1000 L"), "goteo": K("Goteo con bomba solar"), "herr": K("Herramientas de huerta"), "moto": K("Motoazada"), "amp": K("Ampliar la huerta")}[k]   # i18n-no

func huerta_mej_art(k: String) -> String:
	return {"bidon": K("un bidón azul de 100 L"), "ibc": K("un depósito de 1000 L"), "goteo": K("el goteo con la bomba solar"), "herr": K("la laya, la azada y el rastrillo"), "moto": K("la motoazada"), "amp": K("la obra: el seto más abajo y cuatro bancales más")}[k]   # i18n-no

func huerta_mej_d(k: String) -> String:
	if k == "bidon":   # i18n-no
		return K("De polietileno, sobre dos bloques y con su grifo. Se llena con la manguera del garaje.")
	if k == "ibc":   # i18n-no
		return K("Un depósito de segunda mano, lavado, en su jaula de acero y su palé: una tonelada de agua para el verano.")
	if k == "goteo":   # i18n-no
		return K("Tubería con un gotero por planta, filtro, programador y bomba con placa solar: riega cada planta cuando la tierra se seca, mientras quede agua en los depósitos.")
	if k == "amp":   # i18n-no
		return T("Una cuadrilla desbroza el monte de abajo, baja el seto y hace cuatro bancales más: {n} sitios en vez de {a}. Al día siguiente, lista.", {"n": HUERTA.sitios.size() + HUERTA_MEJ.amp.sitios.size(), "a": HUERTA.sitios.size()})
	var p: int = Datos.jsround(float(HUERTA_MEJ[k].g) * 100)
	if k == "herr":   # i18n-no
		return T("Laya, azada y rastrillo para cavar cada sitio antes de plantar: la tierra suelta da un {p} % más de cosecha.", {"p": p})
	return T("De gasolina: labra todos los sitios vacíos de una vez y más hondo que a mano, un {p} % más de cosecha.", {"p": p})

# la tienda online → La huerta: con tarjeta y al día siguiente
func huerta_tienda() -> void:
	var ks := ["bidon", "ibc", "goteo", "herr", "moto", "amp"]   # i18n-no
	var i := 0
	while true:
		var items := []
		for k in ks:
			var M: Dictionary = HUERTA_MEJ[k]
			var ya := huerta_m(k)
			var pd := huerta_ped(k)
			var mx: int = int(M.get("max", 1))
			var falta := ""
			if k == "goteo" and huerta_m("bidon") + huerta_m("ibc") + huerta_ped("bidon") + huerta_ped("ibc") == 0:   # i18n-no
				falta = K("\nAntes hace falta un depósito.")
			if k == "moto" and huerta_m("herr") + huerta_ped("herr") == 0:   # i18n-no
				falta = K("\nAntes hacen falta las herramientas.")
			var lb := huerta_mej_n(k) + (" · %d/%d" % [ya + pd, mx] if mx > 1 else (T(" · en la huerta") if ya else "")) + (T(" · pedido") if pd else "")
			items.append({"label": lb, "right": Datos.eur(M.p), "disabled": ya + pd >= mx or falta != "", "desc": huerta_mej_d(k) + falta})
		items.append({"label": K("Volver")})
		i = await menu(items, {"cls": "full", "title": K("LA HUERTA"), "title2": T("Depósitos, riego, herramientas y obra · en la cuenta {e}", {"e": Datos.eur(S.banco)}), "desc": true, "initial": i})
		if i < 0 or i >= ks.size():
			return
		if items[i].disabled:
			continue
		var k: String = ks[i]
		if not await tarjeta(HUERTA_MEJ[k].p, K("Tienda online") + " · " + huerta_mej_n(k)):
			continue
		huerta_s().ped.append([k, S.day + 1])
		sfx("coin")
		toast(T("Pedido: {n} · llega mañana", {"n": huerta_mej_n(k)}), 1400)

# los sitios vacíos con la tierra por debajo de nv
func huerta_vacios(nv: int) -> Array:
	var r := []
	for i in huerta_def().sitios.size():
		if huerta_s().p[i] == null and huerta_t(i) < nv:
			r.append(i)
	return r

# cavar (1) o labrar (2) los sitios vs en mn minutos
func huerta_trabaja(vs: Array, nv: int, mn: int) -> void:
	await fade(1)
	advance_time(mn)
	for i in vs:
		huerta_s().t[i] = maxi(huerta_t(i), nv)
	huerta_objs()
	await fade(0)
	sfx("get")
	await say(K("Cavas a fondo, rompes los terrones y lo dejas rastrillado: la tierra, suelta y oscura.") if nv == 1 else K("La motoazada levanta la tierra a un palmo de hondo y la deja mullida."))

# al amanecer: la helada y la nieve de ayer (la mínima), y la botritis de las que florecen con lluvia
func huerta_dia() -> void:
	if not huerta_lista():
		return
	var ay := Datos.tiempo(S.day - 1, 360)
	var B: Dictionary = D.BOTRITIS if D.has("BOTRITIS") else {}
	var L: Array = huerta_s().p
	for i in L.size():
		var p = L[i]
		if not (p is Dictionary) or p.get("dead"):
			continue
		var dano := 0.0
		if ay.k == "nieve":   # i18n-no
			dano = float(HUERTA.nieve)
		elif int(ay.min) <= 0:
			dano = float(HUERTA.helada)
		if p.get("bot"):
			dano += float(B.get("dano", 0))
		elif B.size() and ay.k in ["lluvia", "tormenta"] and p.prog >= .65 and p.prog < 1 and int(p.get("prev", 0)) < S.day:   # i18n-no
			var pr: float = float(B.lluvia) * (1 - float(D.IVS.res) * Cultivo.iv_f(p.get("f"), 3)) * (1 - Cultivo.fam(S, "res"))
			if Datos.hash_str("hbot%d_%d_%s" % [S.day, i, p.sid]) % 1000 < int(pr * 1000):
				p.bot = S.day
		if dano > 0:
			p.health = maxf(0, float(p.health) - dano)
			if p.health <= 0:
				p.dead = true
	huerta_objs()

# A en la huerta o en la cancilla del pueblo
func huerta_obj(x: int, y: int, o) -> bool:
	if not Datos.CAL:
		return false
	if S.map == "town":   # i18n-no
		var q: Array = HUERTA.puerta
		if not huerta_vista() and y == int(q[1]) and (x == int(q[0]) or x == int(q[0]) + 1) and o in ["monte", "monte2"]:   # i18n-no
			if await ask(K("Detrás del garaje, entre las zarzas, asoma una cancilla vieja de madera. Al otro lado se ven bancales comidos por la hierba."), [K("Abrirte paso"), K("Dejarlo")]) != 0:
				return true
			await fade(1)
			huerta_s().v = S.day
			montar_huerta("town")
			advance_time(10)
			await fade(0)
			sfx("get")
			await say(K("Apartas las zarzas y empujas la cancilla: la huerta de la tía. Hace años que nadie la toca."))
			return true
		if o == "sign" and x == 1 and y == 8 and not huerta_vista():   # i18n-no
			await say(I18n.v(D.SIGNS.get("town:1,8", "")))
			await say(K("Alguien ha escrito a lápiz debajo: «La huerta de Maite, detrás del garaje»."))
			return true
		return false
	if S.map != HUERTA.mapa:
		return false
	if not huerta_lista():
		var en_bancal := false
		for b in huerta_def().bancales:
			en_bancal = en_bancal or (x >= int(b[0]) and x <= int(b[2]) and y >= int(b[1]) and y <= int(b[3]))
		if en_bancal:
			if await ask(T("Los bancales de la tía, comidos por las zarzas y la hierba. Limpiarlos te lleva unas {h} horas.", {"h": int(HUERTA.desbroce) / 60}), [K("Desbrozar"), K("Dejarlo")]) == 0:
				await fade(1)
				advance_time(int(HUERTA.desbroce))
				huerta_s().l = S.day
				MAPS[HUERTA.mapa] = mapa_huerta()
				await fade(0)
				sfx("get")
				await say(K("Arrancas las zarzas, cavas y dejas la tierra en surcos. Caben ocho plantas al sol."))
			return true
	var i := huerta_idx(x, y)
	if huerta_lista() and i >= 0:
		var antes = huerta_s().p[i]
		if antes == null and (huerta_m("moto") and huerta_t(i) < 2 or huerta_m("herr") and huerta_t(i) < 1):
			var ops := []
			if huerta_m("moto") and huerta_t(i) < 2:
				ops.append(K("Labrar con la motoazada"))
			if huerta_m("herr") and huerta_t(i) < 1:
				ops.append(K("Cavar la tierra"))
			ops.append_array([K("Plantar"), K("Salir")])
			var c: int = await ask(K("Un sitio vacío, con la tierra sin trabajar.") if huerta_t(i) == 0 else K("Un sitio vacío, con la tierra cavada a mano."), ops)
			var op: String = ops[c] if c >= 0 else "Salir"   # i18n-no
			if op == "Labrar con la motoazada":
				await huerta_trabaja(huerta_vacios(2), 2, int(HUERTA_MEJ.moto.min))
				return true
			if op == "Cavar la tierra":
				await huerta_trabaja([i], 1, int(HUERTA_MEJ.herr.min))
				return true
			if op != "Plantar":
				return true
		await pot_action(i, huerta_hu(i))
		if Datos.CAL and antes != null and huerta_s().p[i] == null:   # cosechada o arrancada: la tierra, otra vez sin trabajar
			huerta_s().t[i] = 0
		huerta_objs()
		return true
	if huerta_lista() and (o == "bidonA" or String(o).begins_with("ibcD-")):   # i18n-no
		var h := huerta_s()
		var cap := huerta_cap()
		var txt := T("Los depósitos de la huerta: {a} de {c} L.", {"a": int(h.agua), "c": cap}) + (K(" El goteo tira de aquí.") if huerta_m("goteo") else "")
		var falta: float = cap - float(h.agua)
		if falta < 1:
			await say(txt + K(" Están llenos."))
			return true
		var mn: int = maxi(10, ceili(falta / float(HUERTA_MEJ.caudal)))
		if await ask(txt + "\n" + T("Llenarlos con la manguera del garaje te lleva {m} min.", {"m": mn}), [K("Llenarlos"), K("Dejarlo")]) == 0:
			await fade(1)
			advance_time(mn)
			h.agua = float(cap)
			huerta_objs()
			await fade(0)
			sfx("sel")
			await say(T("Depósitos llenos: {c} L.", {"c": cap}))
		return true
	if huerta_lista() and o == "bombaS":   # i18n-no
		await say(T("La placa solar mueve la bomba del goteo: cada planta recibe agua cuando la tierra se seca, mientras quede en los depósitos ({a} de {c} L).", {"a": int(huerta_s().agua), "c": huerta_cap()}))
		return true
	if huerta_lista() and o == "herrH":   # i18n-no
		var vs := huerta_vacios(1)
		if vs.is_empty():
			await say(K("La laya, la azada y el rastrillo. No queda ningún sitio vacío sin cavar."))
			return true
		var mn: int = int(HUERTA_MEJ.herr.min) * vs.size()
		if await ask(T("La laya, la azada y el rastrillo. Cavar los {n} sitios vacíos te lleva {m} min.", {"n": vs.size(), "m": mn}) if vs.size() > 1 else T("La laya, la azada y el rastrillo. Cavar el sitio vacío te lleva {m} min.", {"m": mn}), [K("Cavar"), K("Dejarlo")]) == 0:
			await huerta_trabaja(vs, 1, mn)
		return true
	if huerta_lista() and o == "motoA":   # i18n-no
		var vs := huerta_vacios(2)
		if vs.is_empty():
			await say(K("La motoazada. No queda ningún sitio vacío por labrar."))
			return true
		if await ask(T("La motoazada. Labrar los {n} sitios vacíos te lleva {m} min.", {"n": vs.size(), "m": int(HUERTA_MEJ.moto.min)}) if vs.size() > 1 else T("La motoazada. Labrar el sitio vacío te lleva {m} min.", {"m": int(HUERTA_MEJ.moto.min)}), [K("Labrar"), K("Dejarlo")]) == 0:
			await huerta_trabaja(vs, 2, int(HUERTA_MEJ.moto.min))
		return true
	if o == "bidonT":   # i18n-no
		var vivas: Array = huerta_s().p.filter(func(p): return p is Dictionary and not p.get("dead"))
		if not huerta_lista() or vivas.is_empty():
			await say(K("Un bidón azul con una manguera que llega del grifo del garaje."))
			return true
		if await ask(T("Un bidón con la manguera del grifo del garaje. Regar las {n} plantas te lleva media hora.", {"n": vivas.size()}), [K("Regar todas"), K("Nada")]) == 0:
			await accion("regar")
			for p in vivas:
				p.water = 100.0
			advance_time(int(HUERTA.riego))
			huerta_objs()
			cuenta("riego")
			sfx("sel")
			await say(K("Riegas toda la huerta. Agua al 100%."))
		return true
	if o == "crate":   # i18n-no
		await say(K("Las herramientas de la tía: una azada con el mango partido, unas tijeras de podar y unos guantes de jardín gastados. Las buenas, en la tienda online."))
		return true
	if o == "sacos":   # i18n-no
		await say(K("Sacos de compost que la tía dejó hechos tierra. La huerta no necesita más."))
		return true
	if o == "cuboS":   # i18n-no
		await say(K("Un cubo con una pala de mano dentro."))
		return true
	if o == "manzano":   # i18n-no
		await say(K("Un manzano viejo que sigue dando manzanas pequeñas y ácidas."))
		return true
	return false
