# Partida al máximo · NEGOCIOS E IMPERIO (solo Godot, con Datos.CAL)
# Pone en S todo lo comprado y a tope de: la nave de Valdehierro (alquilada y comprada, focos, extracción, riego, madres, secadero,
# curado, despacho de lujo, bandejas de clones), KAIA (obras del muelle, flota, licencia, distribuidora legal, piso franco, almacén,
# sala de cultivo en fase 2), los seis locales con sus mejoras, la asociación con la presidencia, los clubs con carné y confianza,
# el bajo de las setas entero, Hiriburu (clubs VIP, barrios, concejal, pisos de venta) y la plantilla, la seguridad y el olor.
# NO toca: dinero, banco, vehículos, huerta, cultivo de casa, historia ni capítulos (otros agentes).
# Los nombres de campo salen de src/nave.gd, kaiacult.gd, gestion.gd, venta.gd, granja.gd, setas.gd, metro.gd y eventos.gd, y los
# estados perezosos se crean con su propia función (nave_nueva, navc, kc, aso, alm_club, metro_d, pisos_d).
extends RefCounted

const Cultivo = preload("res://src/cultivo.gd")

static func pon(J) -> void:
	var S: Dictionary = J.S
	var D = J.D
	_nave(J, S, D)
	_mar(J, S, D)
	_kaia_cult(J, S, D)
	_locales(J, S, D)
	_clubs(J, S, D)
	_setas(J, S, D)
	_metro(J, S, D)
	_plantilla(J, S, D)
	_seguridad(J, S, D)

# un fenotipo de verdad, con la función del juego (gasta S.fenoN como al plantar)
static func _feno(S: Dictionary, sid: String) -> Dictionary:
	return Cultivo.roll_feno(S, sid)

# una mesa recién plantada, igual que plantar_mesa (nave.gd) y kc_mesa (kaiacult.gd)
static func _mesa(J, S: Dictionary, D, sid: String, abo: int) -> Dictionary:
	var f := _feno(S, sid)
	var k: String = sid + ("*" if Cultivo.clase_feno(f) == "estrella" else "")
	return {"k": k, "f": f, "thc": J.thc_nave(sid, f), "y": f.y, "dia": int(S.day), "g": 0, "t": 0, "abo": abo,
		"p": float(D.NAVE.clon), "dn": 0, "am": 0, "ao": 0, "n": 0}

# ---------- 1 · la nave de Valdehierro ----------
static func _nave(J, S: Dictionary, D) -> void:
	if not (S.get("nave") is Dictionary):
		S.nave = J.nave_nueva()
	var N: Dictionary = S.nave
	N.r = int(S.day) + int(D.RECIBO.dias)
	N.d = int(S.day)   # tienda.gd tn_req("nave"): la marca de que la nave es tuya
	# alquilada con opción a compra y comprada a tocateja (comprar_nave)
	N.op = {"d": int(S.day), "pag": int(D.NAVE.compra.precio), "p": int(D.NAVE.compra.precio)}
	N.mia = true
	# los cuatro focos, LED de barras: 1.440 W a 0,85 g/W, lo que más da y lo que menos calienta
	var fs := []
	for i in int(D.NAVE.max):
		fs.append("led")
	N.f = fs
	# extracción y riego, el último nivel (nave «industrial»): dos de 315 mm con cuatro filtros y la fertirrigación
	N.ex = D.EXTR_NAVE.size() - 1
	N.rg = D.RIEGO_NAVE.size() - 1
	# el olor: carbón nuevo y el ozonizador en el conducto (en la sala quemaría los terpenos)
	N.cb = 100.0
	N.oz = "tubo"
	# la estantería del abono, llena de dosis de floración de las dos marcas
	N.ab = {"m": 200, "o": 200}
	# las cuatro mesas plantadas con MEATZA, cada una de su variedad
	var sids := ["ssh", "ww", "nl", "chronic"]
	var ms := []
	for i in int(D.NAVE.max):
		ms.append(_mesa(J, S, D, String(sids[i % sids.size()]), 1))
	N.m = ms
	# la carpa de las madres, llena: MADRES.max madres con el vigor al 100 % y sus esquejes listos
	var ma := []
	for i in int(D.MADRES.max):
		var sid: String = String(sids[i % sids.size()])
		var f := _feno(S, sid)
		ma.append({"k": sid + ("*" if Cultivo.clase_feno(f) == "estrella" else ""), "f": f, "v": 100, "e": int(D.MADRES.tope)})
	N.ma = ma
	# el carro de las bandejas de clones, montado y vacío (las corta el navero antes de pasar la mesa a 12/12)
	N.bc = []
	# el curado del secadero, ampliado (CURADO_NAVE: el doble de tarros)
	if J.has_method("navc"):
		var cu: Dictionary = J.navc()
		if not cu.is_empty():
			cu.mj = 1
	# el despacho de lujo, con la caja fuerte de alta capacidad (pide la nave a tope de extracción y riego)
	if not (S.get("desp") is Dictionary):
		S.desp = {"d": int(S.day), "money": 0, "buds": {}}

# ---------- 2 · el muelle, la flota, KAIA y el piso franco ----------
static func _mar(J, S: Dictionary, D) -> void:
	if not (S.get("mar") is Dictionary):
		S.mar = {"b": ["txalupa"], "rep": 0, "kg": 0.0, "env": [], "ped": null, "pd": 0, "paso": 0, "fin": 0, "n": 0}
	var M: Dictionary = S.mar
	M.d = int(S.day)   # tienda.gd tn_req("muelle")
	# la flota entera
	var bs := []
	for B in D.MAR.barcos:
		bs.append(String(B.k))
	M.b = bs
	M.bod = {}
	M.env = []
	# reputación para todas las rutas y para el último trabajo, y los kilos del rango más alto
	var rep := 0.0
	for rt in D.MAR.rutas:
		rep = maxf(rep, float(rt.rep))
	rep = maxf(rep, float(D.MAR.gran.rep))
	M.rep = rep
	var kg := 0.0
	for r in D.MAR.rangos:
		kg = maxf(kg, float(r[0]))
	M.kg = kg
	M.paso = 1          # el primer envío, hecho: abre el piso franco y los pisos de venta
	M.exp = 1
	M.n = 40
	M.pd = int(S.day) + int(D.MAR.ped.dias)
	M.ped = null
	# las cinco obras del muelle, terminadas y avisadas (pantalán, caseta, casas, KAIA y dique)
	var ob: Dictionary = M.get("ob", {}) if M.get("ob") is Dictionary else {}
	var oba: Dictionary = M.get("oba", {}) if M.get("oba") is Dictionary else {}
	for O in D.MAR.get("obras", []):
		ob[String(O.k)] = int(S.day)
		oba[String(O.k)] = int(S.day)
	M.ob = ob
	M.oba = oba
	M.alq = int(S.day) + 7   # el alquiler de las casas de los pescadores, cada semana
	# la ley y la licencia: la distribuidora legal y KAIA despachando el triple
	M.ley = int(S.day)
	M.lic = int(S.day)
	# el almacén de KAIA (alm_club: lo crea con sus estanterías vacías)
	if J.has_method("alm_club"):
		J.alm_club("muelle")
	# el piso franco de Gorka, con las dos mejoras (la furgoneta y la red de pisos): hasta FRANCO.dia[2] al día
	if not (S.get("franco") is Dictionary):
		S.franco = {"r": int(S.day) + int(D.FRANCO.per), "buds": {}, "caja": 0, "cal": 0.0, "niv": 0, "v": 0}
	var F: Dictionary = S.franco
	F.r = int(S.day) + int(D.FRANCO.per)
	F.niv = D.FRANCO.mej.size()
	F.cal = 0.0

# ---------- 2b · la sala de cultivo de KAIA, fase 2 ----------
# El cuadro de la sala solo da la fase 2 (la obra) cuando las carpas están vacías: la obra las desmonta y las vende de segunda mano
# (kaia_cult.gd kc_obra), así que «todas las carpas» y «la fase 2» no conviven. La fase 2 es el máximo: la carpa de sala de
# 1.300 × 700 con ocho mesas de flujo y reflujo, su riego y su drenaje, mejor que las siete carpas juntas.
static func _kaia_cult(J, S: Dictionary, D) -> void:
	if not J.has_method("kc") or not D.has("KAIA_CULT"):
		return
	var K: Dictionary = J.kc()
	if K.is_empty():
		return
	for ci in K.kits.size():
		K.kits[ci] = -1
	K.p = []
	K.pat = []
	K.f2 = int(S.day)   # la obra, acabada hoy
	# las ocho mesas de la sala, plantadas con MEATZA (kc_mesa)
	var sids := ["ssh", "ww", "nl", "chronic", "jack47", "criticaljack", "whiterhino", "superlemon"]
	var ms := []
	for i in D.KAIA_CULT.f2.mesas.size():
		ms.append(_mesa(J, S, D, String(sids[i % sids.size()]), 1))
	K.m = ms
	if S.get("coloca") is Dictionary:
		S.coloca.erase(String(D.KAIA_CULT.mapa))

# ---------- 3 · los seis locales y la asociación ----------
static func _locales(J, S: Dictionary, D) -> void:
	if not (S.get("loc") is Dictionary):
		S.loc = {}
	for k in D.LOCALES:
		if not (S.loc.get(k) is Dictionary):
			S.loc[k] = {"r": int(S.day) + int(D.RECIBO.dias), "caja": 0, "dia": 0, "tot": 0}
		var o: Dictionary = J.neg_o(k) if J.has_method("neg_o") else S.loc[k]
		o.r = int(S.day) + int(D.RECIBO.dias)
		o.cu = 100                                   # el local reluciendo
		o.st = int(D.NEGOCIO.st)                     # género para toda la semana
		o.mj = D.NEGOCIO.k[k].mj.size()              # las dos mejoras de cada negocio
	# la asociación: Delroy en la sala, la asamblea ganada y la presidencia
	var A: Dictionary = J.aso() if J.has_method("aso") else {}
	if not A.is_empty():
		A.v = maxi(int(A.get("v", 0)), int(D.ASO.visitas))
		A.tio = true
		A.asam = 0
		A.otra = 0
		A.pres = true
		A.votos = int(D.ASO.votos)
		if J.has_method("alm_club"):
			J.alm_club("rv")   # el almacén del club, con sus tres estanterías

# ---------- 3b · los clubs: carné y confianza al máximo ----------
static func _clubs(J, S: Dictionary, D) -> void:
	if not (S.get("clubs") is Dictionary):
		S.clubs = {}
	if not (S.get("rel") is Dictionary):
		S.rel = {}
	var mx: int = int(D.REL.max)
	for k in D.CLUBS:
		S.clubs[k] = true
		S.rel[k] = mx                   # el encargado
		if D.PRESI.has(k):
			S.rel["pres_" + k] = mx     # y el presidente del club
	for id in ["delroy", "arrieta", "koldo", "gorka", "txomin", "kiko", "inaki"]:
		S.rel[id] = mx

# ---------- 4 · el bajo de las setas, entero ----------
static func _setas(J, S: Dictionary, D) -> void:
	if not (S.get("setas") is Dictionary):
		S.setas = {"bandejas": [], "g": 0, "r": int(S.day) + int(D.RECIBO.dias)}
	var L: Dictionary = S.setas
	L.r = int(S.day) + int(D.RECIBO.dias)
	var ks: Array = D.CEPAS.v.keys()
	# el cuaderno con las doce cepas descubiertas y panes de micelio de todas
	L.cd = ks.duplicate()
	var panes := {}
	for k in ks:
		panes[String(k)] = 5
	L.panes = panes
	# las baldas llenas de bandejas recién puestas, una de cada cepa
	var nb: int = J.max_bandejas() if J.has_method("max_bandejas") else int(D.SETAS.max)
	var bs := []
	for i in nb:
		bs.append({"d": int(S.day), "hum": 100, "v": String(ks[i % ks.size()])})
	L.bandejas = bs
	L.fr = []
	# el equipo de la mesa y del secadero: deshidratador, encapsuladora y moldes
	L.dh = true
	L.enc = true
	L.mol = true
	# el armario, lleno: setas secas por cepa y cajas de microdosis y de comestibles
	var gv := {}
	var g := 0.0
	for k in ks:
		gv[String(k)] = 10.0
		g += 10.0
	L.gv = gv
	L.g = g
	L.mc = int(D.SETAS_PRO.lleno.mc[1])
	L.cc = int(D.SETAS_PRO.lleno.cc[1])
	# Ekaitz, el ayudante: cada mañana pulveriza, recoge y tiende a secar
	L.ay = int(S.day)

# ---------- 5 · Hiriburu y los pisos de venta ----------
static func _metro(J, S: Dictionary, D) -> void:
	if not D.has("METRO") or not J.has_method("metro_d"):
		return
	if not (S.get("metro") is Dictionary):
		S.metro = {}
	S.metro.d = int(S.day)   # la ciudad, abierta (la marca que pone metro_dia)
	var M: Dictionary = J.metro_d()
	# los dos clubs VIP, comprados y con las dos mejoras (reservados y seguridad en la puerta)
	for k in D.METRO.vip:
		if not (M.vip.get(k) is Dictionary):
			M.vip[k] = {"d": int(S.day), "mj": 0, "tot": 0, "ay": 0}
		var V: Dictionary = M.vip[k]
		V.mj = D.METRO.mej.size()
		V.erase("cl")        # sin precinto del Ayuntamiento
	# los cuatro barrios, tuyos del todo (METRO.ter.suyo)
	for b in M.ter:
		M.ter[b].c = int(D.METRO.ter.suyo)
	M.at = {}                                                  # ninguna banda esperándote
	M.sob = int(S.day) + int(D.METRO.concejal.per)             # el concejal, pagado
	# un piso de venta por pueblo, comprado, con la pureza y el precio al máximo
	if not J.has_method("pisos_d"):
		return
	var P: Dictionary = J.pisos_d()
	for k in D.PISOS9.k:
		if not (P.get(k) is Dictionary):
			P[k] = {"r": 0, "mia": true, "buds": {}, "caja": 0, "pur": 0, "px": 1, "cal": 0.0, "v": 0}
		var F: Dictionary = P[k]
		F.mia = true      # en propiedad: sin alquiler
		F.r = 0
		F.pur = 0         # PISOS9.pur[0]: «Pura», ×1,0
		F.px = D.PISOS9.px.size() - 1   # «Cara», lo que más paga el gramo

# ---------- 6 · la plantilla ----------
# PLANTILLA.max es 6 y nada deja contratar a más (venta.gd pedir_gente, gestion.gd plantilla_locales): con los seis se cubre lo que
# no funciona sin gente, una persona por mesa de la nave (sin navero la mesa no avanza), las madres y la sala de KAIA. El gerente,
# el contable, la calle y los lugartenientes de los pisos se reparten quitando a alguno de estos, desde MÓVIL → PLANTILLA.
static func _plantilla(J, S: Dictionary, D) -> void:
	var roles := []
	for i in int(D.NAVE.max):
		roles.append({"rol": "nave", "mesa": i})
	roles.append({"rol": "madres"})
	if D.has("KAIA_CULT"):
		roles.append({"rol": "kaia"})
	var n: int = mini(int(D.PLANTILLA.max), roles.size())
	var pl := []
	for i in n:
		var w := {"id": "pl%d" % (i + 1), "n": String(D.BARRIO[i % D.BARRIO.size()]),
			"lab": 5, "cui": 5, "lea": 5,   # habilidades a tope: eficiencia STAFF.ef al máximo
			"lt": 10,                       # lealtad 10: ni un chivato aguanta ahí (pon_lealtad)
			"sm": 2,                        # sueldo alto
			"t0": 1,                        # ya pasado el sorteo de chivato de staff_dia
			"rol": null}
		w.merge(roles[i], true)
		pl.append(w)
	S.plantilla = pl
	S.plN = maxi(int(S.get("plN", 0)), n)

# ---------- 6b · la seguridad de la nave y de los locales ----------
static func _seguridad(J, S: Dictionary, D) -> void:
	if not D.has("SEGURIDAD"):
		return
	if not (S.get("seg") is Dictionary):
		S.seg = {}
	var ks := ["nave"]
	for k in S.loc:
		ks.append(String(k))
	for k in ks:
		if not (S.seg.get(k) is Dictionary):
			S.seg[k] = {}
		for it in D.SEGURIDAD.items:
			S.seg[k][String(it.k)] = int(S.day)   # puerta blindada, alarma, perro y cámaras
