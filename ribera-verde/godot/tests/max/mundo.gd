# Landrace Hunters — partida al máximo: MUNDO, DINERO Y VEHÍCULOS
# Pone en J.S lo de esta área y solo lo de esta área: el dinero (efectivo y cuenta, topes del cajero sin
# gastar, nada vencido), el concesionario entero con el garaje (seguro, impuesto, revisión, neumáticos y
# depósito), la huerta de la tía (abierta, desbrozada, ampliada, con todas las mejoras y la tierra labrada),
# la ropa y el pelo, la confianza con toda la gente, los recados y la ruta de la tía, el billar, el estado
# físico limpio, el calor a 0 sin orden de registro y lo poco de Bilbao y los pueblos que se guarda en S.
# No toca cultivo de casa, carpas, items, nave, KAIA, locales, setas, historia, logros ni CannaDex.
# Todo lo que se guarda son valores JSON puros: números, cadenas, listas y diccionarios.

const EFECTIVO := 500000     # el efectivo que llevas encima (las multas y los apremios salen de aquí)
const BANCO := 5000000       # la cuenta (transferencias, recibos domiciliados y tarjeta)

static func pon(J) -> void:
	var S: Dictionary = J.S
	var D: Dictionary = J.D
	var hoy: int = int(S.day)
	var ayer: int = maxi(1, hoy - 1)   # «ya lo tenías»: nunca 0, que cuenta como «nada» en los avisos
	var anio: int = int(D.CONCE.anio)

	# ---------- 1. dinero ----------
	S.money = EFECTIVO
	S.banco = BANCO
	S.saca = null        # el tope de sacar del cajero, sin gastar hoy (sacado() = 0)
	S.ingr = null        # el tope de ingresar, sin gastar hoy (ingresado() = 0)
	S.vencidos = 0       # ningún plazo vencido: sin embargo a la vista
	if not (S.get("mov") is Array):
		S.mov = []       # los movimientos de la cuenta (CUENTA.mov como mucho)

	# ---------- 2. vehículos ----------
	# el patinete y la bici (S.veh[k] = el día en que los trajo el mensajero)
	if not (S.get("veh") is Dictionary):
		S.veh = {}
	for k in D.VEHICULOS:
		if not D.VEHICULOS[k].get("conce"):
			S.veh[k] = ayer

	# AUTOS RIBERA, abierto (si no, el edificio no se monta en el barrio alto)
	if S.get("flags") is Dictionary and S.flags.get("conce") == null:
		S.flags["conce"] = ayer

	# los cuatro del concesionario (CONCE.orden: moto, utilitario, berlina y deportivo), entregados y
	# aparcados en el garaje de casa, cada uno en su plaza (GARAJE_PLAZA)
	if not (S.get("coches") is Dictionary):
		S.coches = {}
	for k in D.CONCE.orden:
		var c: Dictionary = S.coches[k] if S.coches.get(k) is Dictionary else {}
		c["dia"] = ayer                                   # matriculado y entregado
		c["p"] = int(J.total_coche(k))                    # lo que pagaste (precio + IEDMT + gastos)
		c["r"] = hoy + anio                               # póliza en vigor, el recibo a un año
		c["iv"] = hoy + anio                              # impuesto de circulación pagado, el próximo a un año
		c["km"] = 0                                       # revisión y neumáticos nuevos (van por km)
		c["gas"] = float(int(J.TANQUE.get(k, 40)))        # depósito lleno
		c["en"] = String(J.GARAJE)                        # en Ribera Verde: dentro del garaje
		c.erase("grua")                                   # ninguno en el depósito de la grúa
		c.erase("ap")                                      # en el garaje no hay multa de aparcamiento
		S.coches[k] = c
	S.erase("volante")   # no te quedas a medio camino por una carretera

	# ---------- 3. la huerta de la tía ----------
	var HU: Dictionary = J.HUERTA
	var HM: Dictionary = J.HUERTA_MEJ
	var h: Dictionary = S.huerta if S.get("huerta") is Dictionary else {}
	h["v"] = ayer   # encontrada (la cancilla de detrás del garaje)
	h["l"] = ayer   # desbrozada
	# todas las mejoras, cada una a su tope (HUERTA_MEJ[k].max), y la obra de la ampliación hecha
	h["m"] = {"bidon": int(HM.bidon.get("max", 1)), "ibc": int(HM.ibc.get("max", 1)),
		"goteo": int(HM.goteo.get("max", 1)), "herr": int(HM.herr.get("max", 1)),
		"moto": int(HM.moto.get("max", 1)), "amp": int(HM.amp.get("max", 1))}
	h["ped"] = []   # nada pendiente de llegar
	# ampliada: los sitios de siempre y los ocho de la obra; vacíos y con la tierra labrada (t = 2)
	var sitios: int = int(HU.sitios.size()) + int(HM.amp.sitios.size())
	var ps := []
	var ts := []
	for i in sitios:
		ps.append(null)
		ts.append(2)
	h["p"] = ps
	h["t"] = ts
	# los depósitos llenos: los bidones de 100 L y los IBC de 1.000 L (huerta_cap)
	h["agua"] = float(int(HM.bidon.l) * int(h.m.bidon) + int(HM.ibc.l) * int(h.m.ibc))
	S.huerta = h

	# ---------- 4a. ropa y pelo ----------
	if not (S.get("ropa") is Dictionary):
		S.ropa = {}
	for k in D.ROPA:
		S.ropa[k] = clampi(int(S.ropa.get(k, 0)), 0, int(D.ROPA[k].v.size()) - 1)
	S.ropa["camiseta"] = clampi(5, 0, int(D.ROPA.camiseta.v.size()) - 1)   # la verde

	# ---------- 4b. confianza con toda la gente (REL.max) ----------
	var mx: int = int(D.REL.max)
	if not (S.get("rel") is Dictionary):
		S.rel = {}
	for id in D.GENTE:
		S.rel[id] = mx
	for k in D.CLUBS:
		S.rel[k] = mx                      # el encargado del club
		if D.PRESI.has(k):
			S.rel["pres_" + k] = mx        # y su presidente
	if S.get("fijos") is Array:
		for f in S.fijos:                  # los clientes de la agenda que ya tengas
			if f is Dictionary and f.get("id") is String:
				S.rel[f.id] = mx
	S.relDia = {}   # hablar hoy con quien sea sigue contando

	# ---------- 4c. los recados y la ruta de la tía ----------
	if not (S.get("sec") is Dictionary):
		S.sec = {}
	for sc in D.get("SECUNDARIAS", []):
		S.sec[String(sc.id)] = 2   # 2 = hecho (los seis con «tia», con su testimonio)
	if S.get("flags") is Dictionary and S.flags.get("rutaTia") == null:
		S.flags["rutaTia"] = ayer   # la ruta entera, cerrada

	# ---------- 4d. el billar ----------
	S.billar = {}   # las partidas del día (BILLAR.dia), sin gastar en ningún club
	S.b8aj = {}
	for k in D.BILLAR.hab:
		S.b8aj[k] = -float(J.B8_AJ_MAX)   # el rival, con el pulso más flojo que admite el ajuste

	# ---------- 4e. estado físico, calor y policía ----------
	S.erase("borr")    # ni borracho
	S.erase("colo")    # ni colocado
	S.erase("efe")     # sin perfil de lo fumado
	S.erase("ind_d")
	S.hp = int(S.hpMax)
	S.heat = 0         # calor a 0
	S.orden = 0        # sin orden de registro

	# ---------- 5. Bilbao y los pueblos ----------
	# lo único que se guarda en S son los usos del día (y los de cada semana): se vacían, así que hoy se
	# puede entrar a todo y hacerlo todo. El tren, las líneas de autobús y los aparcamientos no guardan
	# nada: van por el capítulo (PARADAS.cap) y se montan al entrar al mapa
	var C: Dictionary = S.ciudad if S.get("ciudad") is Dictionary else {}
	for k in ["ent", "entM", "vip", "cep", "conf", "rezo", "kiosko", "portico", "faro", "chatarra",
			"grua", "prensa", "miel", "hac", "siesta", "jornal"]:
		C.erase(k)
	S.ciudad = C
