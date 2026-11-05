# Partida al máximo — HISTORIA, GENÉTICA Y PROGRESO (Landrace Hunters, Godot).
# pon(J) deja el estado de partida J.S con el capítulo 8, la deuda saldada, el imperio arriba, toda la CannaDex
# descubierta y cosechada con semillas de sobra y las líneas fijadas, las misiones, el itinerario, los logros y los
# recados hechos, el cuaderno azul cerrado y los Actos II y III resueltos, el banco de la tía abierto, LA TIENDA con
# semillas doradas, la revista al día, las landraces de caza dadas, las rarezas buenas fijadas y la pelea al tope.
# Solo toca lo de esta área: nada de carpas, plantas, dinero, mochila, nave, KAIA, clubs, coches ni policía.
extends RefCounted

const Datos = preload("res://src/datos.gd")

# las rarezas que se fijan: solo las que suman (aroma, +25 % de precio; resina, +1,5 de THC).
# Fuera «enana» (−10 % de cosecha), «doble» (rebrote que ocupa la plaza otro ciclo) y «tetra» (una línea
# tetraploide no cuaja semilla con una normal: dejaría recetas sin poder cruzarse).
const RA_BUENAS := ["aroma", "resina"]

# las personas del hilo de la tía y de la caza: confianza al tope, que es lo que piden sus escenas
const GENTE := ["kiko", "julen", "delroy", "miren", "txaro", "patxi", "inaki", "andoni", "bixente", "arrieta",
	"txomin", "koldo", "baltasar", "bi_serora", "bi_me_es", "bi_me_fl", "bi_me_ve", "bi_capataz"]

static func pon(J) -> void:
	var S: Dictionary = J.S
	var D: Dictionary = J.D
	var hoy := int(S.get("day", 1))

	# ---------- 1. capítulo, deuda, reputación, ventas e imperio ----------
	S.ch = 8
	S.debt = 0
	S.due = 0
	S.deadline = 0
	S.vencidos = 0
	S.rep = 200.0
	S.sales = 500000.0
	S.plazoS = S.sales                     # la marca del último plazo (plazo_due)
	S.imp0 = 250000.0                      # facturado desde la deuda = sales − imp0 = 250.000: la meta más alta de IMPERIO
	S.impN = D.IMPERIO.size() - 1          # «Mayorista del norte»
	S.prest = 60                           # prestigio de la CannaCup y de la Copa de otoño (clubs VIP de Hiriburu)
	S.hpMax = 60                           # el tope que da subir de nivel peleando (policia.gd)
	S.hp = S.hpMax
	S.pelea = {"xp": int(D.PELEA.nv[D.PELEA.nv.size() - 1]), "fue": int(D.PELEA.max), "ref": int(D.PELEA.max)}

	# ---------- 2. genética: CannaDex entera, semillas, líneas fijadas, IVs al tope ----------
	if not (S.get("disc") is Dictionary):
		S.disc = {}
	if not (S.get("seeds") is Dictionary):
		S.seeds = {}
	if not (S.get("cult") is Dictionary):
		S.cult = {}
	if not (S.get("catas") is Dictionary):
		S.catas = {}
	if not (S.get("iv") is Dictionary):
		S.iv = {}
	for sid in D.STRAINS:                  # las 104: las 87 de D.DEX y las 17 de D.AUTO.dex
		S.disc[sid] = true
		S.seeds[sid] = maxi(int(S.seeds.get(sid, 0)), 50)
		S.cult[sid] = hoy                  # cosechada: completa las 10 FAMILIAS y sus bonos
		S.iv[sid] = [31, 31, 31, 31]       # los 4 valores ocultos (IVS.n) en su máximo
		S.catas[sid] = J.nota_cata(sid, float(D.STRAINS[sid].thc))
	S.gen = {}                             # vacío = toda línea en GEN_ESTABLE (F4): nada por estabilizar
	S.custom = S.get("custom", {})

	# las variedades de receta, sacadas en la mesa y cosechadas (S.rec = 2): capítulo 4, logros «recetas10» y «jack»
	if not (S.get("rec") is Dictionary):
		S.rec = {}
	for h in D.RECIPES:
		S.rec[String(D.RECIPES[h])] = 2
	for h in D.RECETA_ORD:
		S.rec[String(D.RECETA_ORD[h])] = 2
	if D.has("AUTO"):
		for h in D.AUTO.recipes:
			S.rec[String(D.AUTO.recipes[h])] = 2

	# fenotipos conocidos (S.fenos: id → clase) y el contador
	if not (S.get("fenos") is Dictionary):
		S.fenos = {}
	S.fenoN = maxi(int(S.get("fenoN", 0)), 120)
	for i in range(1, 121):
		if not S.fenos.has(str(i)):
			S.fenos[str(i)] = "estrella" if i % 5 == 0 else ("floja" if i % 17 == 0 else "normal")

	# rarezas heredables fijadas en todas las líneas (nivel RAREZAS.fija = todas las plantas la sacan)
	if D.has("RAREZAS"):
		if not (S.get("ra") is Dictionary):
			S.ra = {}
		var fija := int(D.RAREZAS.fija)
		for sid in D.STRAINS:
			if not (S.ra.get(sid) is Dictionary):
				S.ra[sid] = {}
			for k in RA_BUENAS:
				S.ra[sid][k] = maxi(int(S.ra[sid].get(k, 0)), fija)
			S.ra[sid].erase("tetra")
		# el cuaderno de fenotipos de la GENOTECA (S.album)
		if not (S.get("album") is Array):
			S.album = []
		if S.album.is_empty():
			var ks: Array = D.STRAINS.keys()
			ks.sort()
			for j in mini(12, ks.size()):
				S.album.append({"id": j + 1, "sid": String(ks[j]), "ra": RA_BUENAS.duplicate(), "sh": "", "d": hoy, "m": "home"})

	# ---------- 3. misiones, itinerario, logros, recados y banderas de historia ----------
	if not (S.get("misiones") is Dictionary):
		S.misiones = {}
	for m in D.MISIONES:
		S.misiones[String(m.id)] = 0       # 0 = hecha sin aviso ni regalo, como en migrate()
	if not (S.get("itin") is Dictionary):
		S.itin = {}
	for p in D.ITINERARIO:
		S.itin[String(p.id)] = 0
	if not (S.get("logros") is Dictionary):
		S.logros = {}
	for l in D.LOGROS:
		S.logros[String(l.id)] = 0         # los 27
	if not (S.get("sec") is Dictionary):
		S.sec = {}
	for sc in D.get("SECUNDARIAS", []):
		S.sec[String(sc.id)] = 2           # los diez recados y los seis de la ruta de la tía, entregados

	if not (S.get("flags") is Dictionary):
		S.flags = {}
	var F: Dictionary = S.flags
	for k in ["llegada", "letter", "kiko1", "julen1", "harvest1", "barras", "vista", "inaki", "ane", "lab",
			"metB", "copa", "cupVip", "darko1", "molina1", "txaro", "txaro2", "notaAma", "taper", "pagina"]:
		F[k] = true
	F.gVeg = 1
	F.gRiego = 1
	F.gFlor = 1
	F.diario = 1                           # el diario de la tía, bajo la almohada: el recetario entero
	F.naveVer = 1
	F.rastroP = 1
	F.robo = true
	for k in ["curado", "nevera", "cajaSem", "lao", "miren", "tono", "darkoFin", "rutaTia", "setasSms", "koldoSms"]:
		F[k] = hoy
	if F.get("conce") == null:
		F.conce = hoy                      # AUTOS RIBERA abierto (el edificio se monta al entrar en «alto»)

	# la gente del hilo y de la caza, al tope de confianza (REL.max)
	if not (S.get("rel") is Dictionary):
		S.rel = {}
	for id in GENTE:
		S.rel[id] = maxi(int(S.rel.get(id, 0)), int(D.REL.max))

	# la CannaCup y la Copa de otoño: oro en cada edición que ya ha pasado por calendario
	var y0 := int(Datos.fecha(1).y)
	var y1 := int(Datos.fecha(hoy).y)
	if not (S.get("cup") is Dictionary):
		S.cup = {"ed": {}, "tro": []}
	if not (S.cup.get("ed") is Dictionary):
		S.cup.ed = {}
	if not (S.cup.get("tro") is Array):
		S.cup.tro = []
	for y in range(y0, y1 + 1):
		for mm in D.CUP.meses:
			var dc := Datos.dia_de(y, int(mm), int(D.CUP.dia))
			if dc >= 1 and dc <= hoy:
				var ed := y * 100 + int(mm)
				if not S.cup.ed.has(str(ed)):
					S.cup.ed[str(ed)] = 1
					S.cup.tro.append({"ed": ed, "pl": 1, "k": "leyenda"})
	if D.has("COPA_OT"):
		if not (S.get("cot") is Dictionary):
			S.cot = {"y": {}, "tro": [], "abs": []}
		if not (S.cot.get("y") is Dictionary):
			S.cot.y = {}
		if not (S.cot.get("tro") is Array):
			S.cot.tro = []
		if not (S.cot.get("abs") is Array):
			S.cot.abs = []
		var sids := {"pot": "leyenda", "sab": "leyenda", "land": "panama", "cru": "silver", "ext": "leyenda"}
		for y in range(y0, y1 + 1):
			var do_ := Datos.dia_de(y, int(D.COPA_OT.m), int(D.COPA_OT.d))
			if do_ < 1 or do_ > hoy:
				continue
			if not (S.cot.y.get(str(y)) is Dictionary):
				S.cot.y[str(y)] = {}
			for c in D.COPA_OT.cats:
				var kc := String(c.k)
				if not S.cot.y[str(y)].has(kc):
					S.cot.y[str(y)][kc] = 1
					S.cot.tro.append({"y": y, "k": kc, "pl": 1, "s": String(sids.get(kc, "leyenda"))})
			if not (y in S.cot.abs):
				S.cot.abs.append(y)        # tres oros el mismo año: la Copa absoluta

	# ---------- 4. el cuaderno azul y los Actos ----------
	# hilo: paso 6 (cerrado), los tres trozos, las tres cortesías y la elección 0 (contarlo en la asociación),
	# que es la que destapa más contenido después: la ayuda de Delroy en el Acto II y la prueba «asamblea» en el III
	var hd := {}
	for q in range(1, 7):
		hd[str(q)] = hoy
	S.hilo = {"p": 6, "tr": {"miren": hoy, "serora": hoy, "txaro": hoy}, "cor": 3, "el": 0, "d": hd}
	if not (S.get("ciudad") is Dictionary):
		S.ciudad = {}
	S.ciudad.serora = true                 # la serora ya te dio el sobre de la tía

	# Acto II: las cinco pistas y la acusación acertada (Unai Garro, de Semillas Ondarea). No se deshace: es su final
	S.a2 = {"p": 3, "pi": {"pc": hoy, "catedral": hoy, "teatro": hoy, "hacienda": hoy, "muelle": hoy},
		"acu": "garro", "d": {"1": hoy, "2": hoy, "3": hoy}}

	# Acto III: oposición presentada con las seis pruebas y ganada (gan 1). Se deja en el paso 3 a propósito:
	# el paso 4 es el final de la historia (y «vender» o «la caída» se llevan la Haze del 98). Garro llama al
	# amanecer siguiente y los tres finales buenos quedan disponibles (banco abierto, Haze en mano, Miren a 100)
	S.a3 = {"p": 3, "d": {"1": hoy, "2": hoy, "3": hoy},
		"pr": ["cuaderno", "fijada", "banco", "correo", "asamblea", "ruta"], "gan": 1, "fin": "", "ll": 0}

	# ---------- 5. banco de la tía, LA TIENDA, revista y caza ----------
	if D.has("BANCO_TIA"):
		if not (S.get("bt") is Dictionary):
			S.bt = {"c": {}}
		var B: Dictionary = S.bt
		if not (B.get("c") is Dictionary):
			B.c = {}
		for c in D.BANCO_TIA.col:
			B.c[String(c.id)] = hoy        # las seis colecciones: cámara fría, laboratorio, catas, archivo, socios y la placa
		B.v = hoy
		B.vis = hoy
		B.fin = hoy                        # el banco del barrio, abierto: habilita el final «el banco de la tía»
		if D.has("TETRA"):                 # la tetraploidia, disponible: frasco lleno y ninguna línea tratada
			B.tt = {"f": int(D.TETRA.frasco.n), "p": {}}

	if D.has("TIENDA"):
		if not (S.get("tn") is Dictionary):
			S.tn = {"sd": 0, "c": {}, "g": {}, "r": 0}
		var T0: Dictionary = S.tn
		if not (T0.get("c") is Dictionary):
			T0.c = {}
		if not (T0.get("g") is Dictionary):
			T0.g = {}
		T0.sd = maxi(int(T0.get("sd", 0)), 9999)
		T0.r = 1                           # el regalo de quien compró el juego completo, ya dado
		var cot0: Dictionary = S.cot if S.get("cot") is Dictionary else {}
		var n_oro: int = (cot0.get("tro") as Array).size() if cot0.get("tro") is Array else 0
		var n_abs: int = (cot0.get("abs") as Array).size() if cot0.get("abs") is Array else 0
		var n_ra: int = S.album.size() if S.get("album") is Array else 0
		T0.g = {"cap": 8 * 8, "logro": 2 * D.LOGROS.size(), "revista": 24, "copa98": 25,
			"copa": 10 * n_oro, "copaabs": 30 * n_abs, "rareza": 3 * n_ra, "diario": 120}
		T0.obra = 1                        # las reformas de suelo y pared, pagadas (reforma_pagada)
		# de los extras de un solo uso solo se marcan como comprados los que aquí se aplican de verdad:
		# marcarlos sin su efecto diría «Ya lo tienes» y dejaría al jugador sin ello
		T0.c["eobra"] = 1
		T0.c["elab"] = 1                   # el banco de la tía, arriba
		if S.get("nevera") is Dictionary:
			S.nevera.arcon = 1
			T0.c["earcon"] = 1
		if S.get("items") is Dictionary:
			S.items.tarros = maxi(int(S.items.get("tarros", 0)), 1)
			T0.c["ctarros"] = 1
		if F.get("conce") != null:
			T0.c["econce"] = 1
		if S.get("cam") is Dictionary and S.cam.has("d"):
			T0.c["ecam"] = 1
		if S.get("desp") is Dictionary and not S.desp.is_empty():
			T0.c["edesp"] = 1
		if S.get("huerta") is Dictionary and S.huerta.has("v"):
			T0.c["ehuerta"] = 1
		if S.get("mar") is Dictionary and int(S.mar.get("d", 0)) > 0:
			T0.c["ekaia"] = 1

	if D.has("REVISTA"):
		if not (S.get("rev") is Dictionary):
			S.rev = {"col": [], "tec": [], "sus": 0, "nw": [], "reg": []}
		var R: Dictionary = S.rev
		if not (R.get("col") is Array):
			R.col = []
		if not (R.get("tec") is Array):
			R.tec = []
		if not (R.get("nw") is Array):
			R.nw = []
		if not (R.get("reg") is Array):
			R.reg = []
		var n1 := maxi(int(D.REVISTA.cab.col), J.rev_num(hoy))   # los 12 de la colección y, si va por delante, hasta el del mes
		for n in range(1, n1 + 1):
			if not R.col.has(n):
				R.col.append(n)
			if not R.reg.has(n):
				R.reg.append(n)            # el sobre del mes de cada número, ya despegado
		for tc in D.REVISTA.tec:
			if not R.tec.has(String(tc.k)):
				R.tec.append(String(tc.k)) # las doce técnicas aprendidas: cada bono a su tope (REVISTA.tope)
		R.sus = maxi(int(R.get("sus", 0)), int(D.REVISTA.cab.susn))

	if D.has("CAZA"):                      # las diecisiete landraces que da la gente, ya dadas (una vez por partida)
		if not (S.get("caza") is Dictionary):
			S.caza = {}
		for e in D.CAZA.l:
			S.caza[String(e.k)] = hoy
