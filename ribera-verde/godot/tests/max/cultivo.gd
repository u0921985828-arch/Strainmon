# Landrace Hunters — CULTIVO Y CASA al máximo (partida de pruebas).
#
# pon(J) deja comprado y montado todo lo del piso y el cultivo de casa, con los nombres de campo del juego:
#   · S.items: consumibles a tope, los aparatos únicos, y de repuesto una maceta (m_*), un foco (f_*) y un extra (x_*) de cada
#     clave real de D.MACETAS, D.FOCOS y D.EXTRAS (así con Datos.CAL entran tela35, tela50 y el kit de sellado, y sin CAL no).
#   · Las carpas de D.SITIOS, cada una la más grande que le cabe (D.SHOP, campo ci), con el mejor foco que aguanta su wmax, el
#     ventilador, el intractor, el mejor extractor con filtro (D.KITS), el goteo y el sellado; todas las plazas con la maceta más
#     grande que admite (CARPAS[t].lmax y litros_max) y sin plantas (S.pots a null).
#   · Caja empotrada (nivel 2), nevera con arcón, camarote con obra, sus estanterías y sobres, todos los muebles del salón y del
#     grow, las reformas de suelo y pared, la decoración, los aparatos de clima de la sala y la sala fría del sótano.
#
# No toca el dinero (S.money, S.banco, S.caja.money), ni semillas, ni lotes, ni la huerta, ni la nave, ni KAIA, ni las setas.
# Solo valores JSON puros. Después vuelve a montar el mapa de casa (montar_casa / montar_camarote).

# dosis y botes que se gastan: se dejan de sobra
const CONSUMIBLES := {
	"fert": 500, "fertv": 500, "phm": 1000,
	"ofert": 500, "ofertv": 500, "ophm": 1000,
	"insect": 50, "fungi": 50, "prevent": 50,
	"spray": 20, "bocata": 20,
	"papel": 500, "filtros": 500, "tabaco": 200, "mechero": 5,
}

# lo que es uno y basta: medición, análisis, curado, las cinco máquinas de extracción y lo de fumar
const UNICOS := ["medidor", "analizador", "tarros", "prensa", "tamiz", "ice", "lavadora", "estatica", "mallas00",
	"grinder", "pipa", "bong", "vapo", "vacio"]

const REPUESTO_MACETAS := 24   # por cada clave de D.MACETAS
const REPUESTO_FOCOS := 4      # por cada clave de D.FOCOS
const REPUESTO_EXTRAS := 4     # por cada clave de D.EXTRAS
const SOBRES_CAMAROTE := 240.0 # sobres de humedad al 62 % que quedan (uno por tarro cada CAMAROTE.dura días)


static func pon(J) -> void:
	var S: Dictionary = J.S
	var D: Dictionary = J.D
	var dia := int(S.day)
	_items(S, D)
	_carpas(J, S, D)
	_almacen(S, D, dia)
	_casa(S, D, dia)
	_remonta(J, S, D)


# ---------- 1 · la mochila: S.items ----------
static func _items(S: Dictionary, D: Dictionary) -> void:
	if not (S.get("items") is Dictionary):
		S.items = {}
	var it: Dictionary = S.items
	for k in D.NEW_STATE.items:   # ninguna clave de serie se queda sin estar
		if not it.has(k):
			it[k] = 0
	for k in CONSUMIBLES:
		it[k] = maxi(int(it.get(k, 0)), int(CONSUMIBLES[k]))
	for k in UNICOS:
		it[k] = maxi(int(it.get(k, 0)), 1)
	it.bolsa = D.MOCHILAS.size() - 1   # la maleta con ruedas
	for k in D.MACETAS:                # de repuesto, para cambiarlas en cualquier plaza
		it["m_" + String(k)] = maxi(int(it.get("m_" + String(k), 0)), REPUESTO_MACETAS)
	for k in D.FOCOS:
		it["f_" + String(k)] = maxi(int(it.get("f_" + String(k), 0)), REPUESTO_FOCOS)
	for k in D.EXTRAS:
		it["x_" + String(k)] = maxi(int(it.get("x_" + String(k), 0)), REPUESTO_EXTRAS)


# ---------- 2 · las tres carpas del piso ----------
# la más grande de cada sitio (D.SITIOS[ci].w manda: el armario de la fila A es de una casilla)
static func _carpa_max(D: Dictionary, ci: int, ahora: String) -> String:
	var t := ahora
	for x in D.SHOP:
		if not (x is Dictionary) or not x.has("carpa"):
			continue
		if int(x.get("ci", 0)) != ci:
			continue
		var k := String(x.carpa)
		if not D.CARPAS.has(k) or int(D.CARPAS[k].w) > int(D.SITIOS[ci].w):
			continue
		if t == "" or int(D.CARPAS[k].plazas) > int(D.CARPAS[t].plazas):
			t = k
		elif int(D.CARPAS[k].plazas) == int(D.CARPAS[t].plazas) and int(D.CARPAS[k].lmax) > int(D.CARPAS[t].lmax):
			t = k
	return t if t != "" else "p60"


# el mejor foco que aguanta la carpa: el que más gramos da (w × gpw) y, a igualdad, el de más THC
static func _foco_max(D: Dictionary, t: String) -> String:
	var mejor := ""
	for k in D.FOCOS:
		var F: Dictionary = D.FOCOS[k]
		if float(F.w) > float(D.CARPAS[t].wmax):
			continue
		if mejor == "":
			mejor = String(k)
			continue
		var M: Dictionary = D.FOCOS[mejor]
		var a := float(F.w) * float(F.gpw)
		var b := float(M.w) * float(M.gpw)
		if a > b or (a == b and float(F.thc) > float(M.thc)):
			mejor = String(k)
	return mejor if mejor != "" else "cfl"


# el extractor con filtro que más caudal mueve (D.KITS son los tres kits de EXTRAS)
static func _kit_max(D: Dictionary) -> String:
	var mejor := ""
	for k in D.KITS:
		if not D.EXTRAS.has(k):
			continue
		if mejor == "" or float(D.EXTRAS[k].m3) > float(D.EXTRAS[mejor].m3):
			mejor = String(k)
	return mejor


# la maceta más grande que cabe en la carpa: hasta CARPAS[t].lmax y sin pasar la tierra de la carpa (litros_max)
static func _maceta_max(J, D: Dictionary, ci: int) -> String:
	var C: Dictionary = D.CARPAS[J.S.carpas[ci].t]
	var tope := int(J.litros_max(ci))
	var mejor := "plastico7"
	for k in D.MACETAS:
		var l := int(D.MACETAS[k].l)
		if l > int(C.lmax) or l * int(C.plazas) > tope:
			continue
		if l > int(D.MACETAS[mejor].l):
			mejor = String(k)
	return mejor


static func _carpas(J, S: Dictionary, D: Dictionary) -> void:
	var kit := _kit_max(D)
	var cs := []
	for ci in D.SITIOS.size():
		var ahora := ""
		if S.get("carpas") is Array and ci < S.carpas.size() and S.carpas[ci] != null:
			ahora = String(S.carpas[ci].t)
		var t := _carpa_max(D, ci, ahora)
		var c := {"t": t, "foco": _foco_max(D, t)}
		for k in D.EXTRAS:            # el ventilador, el intractor, el goteo y el sellado; de los kits, solo el mejor
			var ke := String(k)
			if ke == "garrafas":      # con goteo las garrafas sobran (falta_extra)
				continue
			if D.KITS.has(ke) and ke != kit:
				continue
			c[ke] = true
		cs.append(c)                  # sin c.dep: el depósito del goteo se cuenta lleno (Cultivo.goteo_l)
	S.carpas = cs
	var hu: Array = J.huecos()        # con las carpas nuevas ya puestas
	var elegida := {}
	for ci in S.carpas.size():
		elegida[ci] = _maceta_max(J, D, ci)
	var mac := []
	var pots := []
	for h in hu:
		mac.append(String(elegida[int(h.c)]))
		pots.append(null)             # las plazas, vacías y listas para plantar
	S.macetas = mac
	S.pots = pots
	if not (S.get("esquejes") is Array):   # los clones no van en las plazas: solo se asegura el campo
		S.esquejes = []
	if not (S.get("bandejas") is Array):   # el carro de esquejes, vacío y listo
		S.bandejas = []


# ---------- 3 · dónde se guarda: caja fuerte, nevera y camarote ----------
static func _almacen(S: Dictionary, D: Dictionary, dia: int) -> void:
	if not (S.get("caja") is Dictionary):   # la caja de la tía, ya abierta
		S.caja = {"money": 0, "buds": {}, "nivel": 1}
	if not (S.caja.get("buds") is Dictionary):
		S.caja.buds = {}
	S.caja.nivel = D.CAJA.size() - 1        # la empotrada, instalada
	S.caja.erase("mejora")
	if not (S.get("nevera") is Dictionary):
		S.nevera = {"rosin": {}}
	if not (S.nevera.get("rosin") is Dictionary):
		S.nevera.rosin = {}
	S.nevera.arcon = 1                      # el arcón congelador, enchufado al lado
	if D.has("CAMAROTE"):
		if not (S.get("cam") is Dictionary):
			S.cam = {}
		var C: Dictionary = D.CAMAROTE
		S.cam.d = dia                       # la obra, hecha
		var e := []
		while e.size() < int(C.est.max):    # sus cuatro estanterías de tarros de 10 L
			e.append(dia)
		S.cam.e = e
		S.cam.sob = SOBRES_CAMAROTE
		S.cam.sp = []
		if not (S.cam.get("buds") is Dictionary):
			S.cam.buds = {}


# ---------- 4 · la casa: muebles, reformas, decoración, clima y sala fría ----------
static func _casa(S: Dictionary, D: Dictionary, dia: int) -> void:
	if not (S.get("muebles") is Dictionary):
		S.muebles = {}
	for k in D.MUEBLES:                     # el salón entero y el carro de esquejes del grow
		S.muebles[String(k)] = dia
	if not (S.get("deco") is Dictionary):
		S.deco = {}
	for k in D.REFORMA:                     # el suelo y las paredes, la última reforma de la lista
		S.deco[String(k)] = D.REFORMA[k].v.size() - 1
	for k in D.DECO:                        # tapizados, láminas y estampado, la última variante
		S.deco[String(k)] = D.DECO[k].v.size() - 1
	S.obra = {}                             # nada pendiente de obra
	if not (S.get("sala") is Dictionary):
		S.sala = {}
	for k in D.APARATOS:                    # termohigrómetro, calefactor, aire, humidificador y deshumidificador
		S.sala[String(k)] = true
	if D.has("SOTANO") and not (S.get("sot") is Dictionary):   # la sala fría se entra por el sótano
		S.sot = {"d": dia, "bandejas": [], "g": 0, "fr": []}
	if D.has("FRIA"):
		S.fria = {"d": dia}                 # las máquinas de extracción bajan a la sala fría


# ---------- 5 · volver a montar el mapa con todo puesto ----------
static func _remonta(J, S: Dictionary, D: Dictionary) -> void:
	if not (J.MAPS is Dictionary):
		return
	if J.MAPS.has("home"):
		J.MAPS.home.carpasK = ""
		J.montar_casa()
	if String(S.map) == "camarote" and J.MAPS.has("camarote"):
		J.montar_camarote()
	if D.has("FRIA") and String(S.map) == String(D.FRIA.mapa):
		J.bt_entra(String(S.map))
