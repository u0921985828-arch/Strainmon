# Landrace Hunters (Godot) — MAESTRO [7] (con Datos.CAL): gustos y arquetipos, la manera de hablar por zona, las charlas con memoria y
# los encargos, fiar y cobrar, los pedidos por efecto y aroma, los combates con armas y estados y las tiendas por secciones y marcas.
#   $GODOT --headless --path godot --script res://tests/vida.gd   → «vida: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
	o = o.duplicate()
	o.initial = k
	return o

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 120000 or not M.paso():
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func log_tiene(t: String) -> bool:
	for x in LOG:
		if String(x).find(t) >= 0:
			return true
	return false

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-vida.json"
	Juego.AJUSTES = "user://prueba-vida-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = Datos.carga()
	var S: Dictionary = J.S
	S.ch = 6
	S.day = 40
	S.rep = 30
	S.money = 5000.0
	S.map = "town"
	J.mode = "world"
	var G7: Dictionary = D.GENTE7
	# 1 · la manera de hablar por zona: el pueblo, el centro y el barrio, cada una con lo suyo
	chk(J.zona_habla("mendialde") == "rural" and J.zona_habla("ensanche") == "centro" and J.zona_habla("town") == "obrero" and J.zona_habla("puerto") == "obrero", "zonas")
	for z in ["rural", "centro", "obrero"]:
		for k in ["hola", "si", "no", "chisme"]:
			chk(G7.jerga[z][k].size() >= 3, "jerga %s %s" % [z, k])
	chk(G7.jerga.rural.hola.has(J.jerga("hola", "x", "mendialde")) and G7.jerga.centro.hola.has(J.jerga("hola", "x", "ensanche")), "jerga por mapa")
	chk(not G7.jerga.rural.hola.has(J.jerga("hola", "x", "ensanche")) or G7.jerga.centro.hola.has(J.jerga("hola", "x", "ensanche")), "jerga del centro")
	# 2 · gustos y arquetipos: fijos por persona, de los que hay
	var efs := {}
	var ars := {}
	for i in 200:
		var g: Dictionary = J.gusto_de("p%d" % i)
		efs[g.ef] = 1
		ars[g.ar] = 1
		chk(J.gusto_de("p%d" % i) == g, "gusto fijo")
	chk(efs.size() == 3 and ars.size() == D.AROMAS.size(), "gustos repartidos")
	chk(J.arq_de({"type": "est", "fid": "a"}) in ["estudiante", "pandillero"] and J.arq_de({"type": "cur", "fid": "a"}) in ["currela", "abuelo"] and J.arq_de({"type": "tur", "fid": "a"}) == "turista", "arquetipos por tipo")
	chk(J.gusto_txt("p1").begins_with("Le va la "), "gusto en texto")
	# 3 · el pedido por efecto y aroma: casa y paga más; si no casa, cuela peor
	var q := ""
	for i in 500:
		var id := "fx%d" % i
		var c0 := {"fid": id, "type": "cur"}
		var p0: Dictionary = J.pedido_de(c0)
		if not p0.is_empty() and J._h("fiar|%s|%d" % [id, 40]) % 100 < 30 and J._h("paga|%s|%d" % [id, 40]) % 100 < int(float(G7.arqs[J.arq_de(c0)].paga) * 100) \
				and D.STRAINS.keys().any(func(k): return not D.STRAINS[k].get("auto") and J.ef_de(k) == p0.ef and J.aroma_de(k) == p0.ar):
			q = id
			break
	chk(q != "", "hay un pedido fiable")
	var c := {"id": "cl-" + q, "fid": q, "n": "PACO", "type": "cur", "want": 5, "minThc": 0, "map": "town", "x": 5, "y": 5}
	var p: Dictionary = J.pedido_de(c)
	var sid := ""
	var otro := ""
	for k in D.STRAINS:
		if D.STRAINS[k].get("auto"):
			continue
		if J.ef_de(k) == p.ef and J.aroma_de(k) == p.ar and sid == "":
			sid = k
		elif J.ef_de(k) != p.ef and otro == "":
			otro = k
	chk(sid != "" and otro != "", "cepas para el pedido")
	J.add_buds(sid, 30, float(p.thc) + 2)
	J.add_buds(otro, 30, 25)
	chk(J.casa_pedido(p, sid, S.buds[sid]) and not J.casa_pedido(p, otro, S.buds[otro]), "casa el pedido")
	chk(is_equal_approx(J.cal_precio(c, sid, S.buds[sid]), 1.0 + float(G7.pedido.plus)) and J.cal_precio(c, otro, S.buds[otro]) == 1.0, "precio del pedido")
	chk(J.cal_acc(c, otro, S.buds[otro], 1, .9) < .9 and J.cal_acc(c, sid, S.buds[sid], 1, .9) == .9 and J.cal_acc(c, otro, S.buds[otro], 0, 1.0) == 1.0, "lo que cuela")
	chk(J.cal_busco(c).begins_with("Busco 5 g de una "), "busca por efecto")
	# 4 · la venta entera con un fijo: pide lo suyo, se lo fías y te regala algo
	S.fijos = [{"id": q, "n": "Paco", "t": "cur", "dia": -1}]
	S.clients = [c]
	var din := float(S.money)
	var it0: Dictionary = S.items.duplicate()
	LOG.clear()
	QUIERO = [J.lot_nombre(sid), "Rebaja", "Fiárselo", "Paso"]
	chk(corre(func(): await J.talk_client(c)), "venta sin bloqueo")
	chk(float(S.money) == din, "fiado: no cobras")
	chk(J.fiados().size() == 1 and String(J.fiados()[0].id) == q, "fiado apuntado")
	var regalo := false
	for k in ["papel", "mechero", "bocata", "spray"]:
		if int(S.items.get(k, 0)) > int(it0.get(k, 0)):
			regalo = true
	chk(regalo and log_tiene("Justo lo que buscaba"), "regalo del pedido")
	chk(int(J.mem(q).n) == 1 and String(J.mem(q).s) == sid, "memoria")
	# 5 · al vencer, paga (al buzón) o no, según su arquetipo
	var f: Dictionary = J.fiados()[0]
	var e5 := int(f.e)
	S.day = int(f.d) + int(G7.arqs[String(f.arq)].tarde)
	din = float(S.money)
	chk(corre(func(): J.vida_dia()), "vida_dia sin bloqueo")
	chk(J.fiados().is_empty() and float(S.money) == din + e5 and int(J.mem(q).fav) == 1, "paga lo fiado")
	# y el favor: la próxima vez te cuenta un chisme y baja el calor
	S.heat = 30.0
	LOG.clear()
	chk(corre(func(): await J.cal_saludo(c, "PACO")), "saludo sin bloqueo")
	chk(float(S.heat) == 30.0 - float(G7.fiar.favor) and log_tiene("Por fiarme"), "chisme por el favor")
	LOG.clear()
	chk(corre(func(): await J.cal_saludo(c, "PACO")), "saludo 2")
	chk(log_tiene("de la otra vez"), "se acuerda de la cepa")
	# 6 · los que no pagan: perdonar, exigir (en la calle) y amenazar
	S.fiado = [{"id": "d1", "n": "Uno", "arq": "currela", "e": 100, "d": 30, "dia": 25, "imp": true},
		{"id": "d2", "n": "Dos", "arq": "abuelo", "e": 80, "d": 30, "dia": 25, "imp": true},
		{"id": "d3", "n": "Tres", "arq": "abuelo", "e": 60, "d": 30, "dia": 25, "imp": true}]
	var rep0 := int(S.rep)
	QUIERO = ["Perdonarle"]
	chk(corre(func(): await J.deuda(S.fiado[0])), "perdonar")
	chk(J.fiado_de("d1") == null and int(S.rep) == rep0 + int(G7.fiar.rep), "perdonado")
	S.map = "home"
	QUIERO = ["Exigirle"]
	chk(corre(func(): await J.deuda(J.fiado_de("d2"))), "exigir en casa")
	chk(J.fiado_de("d2") != null and not J.fiado_de("d2").has("ult") and log_tiene("quedar en la calle"), "exigir solo en la calle")
	S.map = "town"
	din = float(S.money)
	var paga: bool = J._h("exige|d2|%d" % int(S.day)) % 100 < int(float(G7.fiar.exige) * 100)   # el jubilado no pelea
	QUIERO = ["Exigirle"]
	chk(corre(func(): await J.deuda(J.fiado_de("d2"))), "exigir")
	chk((paga and J.fiado_de("d2") == null and float(S.money) == din + 96) or (not paga and J.fiado_de("d2") != null), "exigir con intereses")
	S.heat = 10.0
	QUIERO = ["Amenazarle"]
	chk(corre(func(): await J.deuda(J.fiado_de("d3"))), "amenazar")
	chk(float(S.heat) == 10.0 + float(G7.fiar.calor), "amenazar da calor")
	if J.fiado_de("d3") != null:
		LOG.clear()
		QUIERO = ["Amenazarle"]
		chk(corre(func(): await J.deuda(J.fiado_de("d3"))), "otra vez")
		chk(log_tiene("Ya has hablado hoy"), "una vez al día")
	# en GENTE, arriba, las deudas
	S.fiado = [{"id": "d9", "n": "Nueve", "arq": "currela", "e": 50, "d": 30, "dia": 25, "imp": true}]
	MENUS.clear()
	QUIERO = ["Deudas", "Volver"]
	chk(corre(func(): await J.gente()), "gente")
	chk(MENUS.size() >= 2 and String(MENUS[0][0]) == "Deudas" and String(MENUS[1][0]) == "Nueve", "deudas en gente")
	# 7 · los encargos: se ofrecen en una charla, se entregan llamando desde el pueblo y caducan
	S.fiado = []
	S.encargo7 = null
	var sal := ""
	for i in 500:
		if J._h("encargo|e%d|%d" % [i, int(S.day)]) % 100 < 30:
			sal = "e%d" % i
			break
	QUIERO = ["Me animo"]
	chk(corre(func(): await J.ofrece_encargo("PACO", sal)), "ofrece encargo")
	var E = S.get("encargo7")
	chk(E is Dictionary and String(E.pu) != "town" and int(E.g) >= 5 and int(E.e) > 0, "encargo apuntado")
	if E is Dictionary:
		chk(J.cal_llamar_filas().size() == 1, "encargo en LLAMAR")
		S.map = "town"
		LOG.clear()
		chk(corre(func(): await J.entrega_encargo(E)), "entrega lejos")
		chk(S.encargo7 != null and log_tiene("Llámame cuando estés"), "solo en su pueblo")
		S.map = String(E.pu)
		var se := ""
		for k in D.STRAINS:
			if not D.STRAINS[k].get("auto") and J.ef_de(k) == String(E.ef) and not S.buds.has(k):
				se = k
				break
		J.add_buds(se, 40, 20)
		din = float(S.money)
		QUIERO = [J.lot_nombre(se)]
		chk(corre(func(): await J.entrega_encargo(E)), "entrega")
		chk(S.encargo7 == null and float(S.money) == din + int(E.e), "encargo cobrado")
		S.encargo7 = {"q": "x", "n": "X", "pu": "puerto", "g": 5, "ef": "indica", "d": int(S.day) - 1, "e": 100}
		chk(corre(func(): J.vida_dia()), "caduca")
		chk(S.encargo7 == null, "encargo caducado")
	S.map = "town"
	# las charlas sentado: una al día por persona
	S.charla7 = {}
	LOG.clear()
	QUIERO = ["Paso"]
	chk(corre(func(): await J.cal_charla({"id": "np1", "def": {"n": "x"}})), "charla")
	var nl := LOG.size()
	chk(nl >= 1 and int(S.charla7.np1) == int(S.day), "charla con chisme")
	chk(corre(func(): await J.cal_charla({"id": "np1", "def": {"n": "x"}})), "charla 2")
	chk(LOG.size() == nl, "una charla al día")
	# 8 · los combates: armas, golpes con nombre, aturdido y sangrado
	J.B = {"kind": "thief", "name": "Ladrón", "hp": 40, "hpMax": 40, "atk": [2, 4], "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	S.items.erase("bate")
	S.items.erase("cadena")
	chk(J.arma_d() == 0 and J.armas_venta().size() == 2, "sin armas")
	S.items.bate = 1
	chk(J.arma_d() == 3 and J.golpe_txt("PUÑETAZO").find("bate") >= 0 and J.armas_venta().size() == 1, "con el bate")
	var cu := [0]
	chk(corre(func():
		for i in 200:
			J.B.aturde = 0
			await J.tras_golpe()
			cu[0] += int(J.B.get("aturde", 0))), "tras golpe")
	var at: int = cu[0]
	chk(at > 20 and at < 90, "aturde a veces con el bate (%d/200)" % at)
	J.B.aturde = 1
	var r1 := [false]
	chk(corre(func(): r1[0] = await J.aturdido()), "aturdido")
	chk(r1[0] and not J.B.aturde, "pierde su turno")
	S.items.erase("bate")
	S.items.cadena = 1
	cu[0] = 0
	chk(corre(func():
		for i in 100:
			J.B.sangra = 0
			await J.tras_golpe()
			cu[0] += 1 if int(J.B.get("sangra", 0)) > 0 else 0), "cadena")
	var sg: int = cu[0]
	chk(sg > 10 and sg < 60, "sangra a veces con la cadena (%d/100)" % sg)
	J.B.sangra = 2
	J.B.hp = 30
	S.hp = 1
	J.B.psangra = 2
	chk(corre(func(): await J.sangra_tick()), "sangra tick")
	chk(J.B.hp == 30 - int(D.COMBATE7.sangra.d) and J.B.sangra == 1 and S.hp == 1 and J.B.psangra == 1, "sangrado (tú no caes)")
	J.B.navaja = true
	J.B.psangra = 0
	cu[0] = 0
	chk(corre(func():
		for i in 100:
			J.B.psangra = 0
			await J.corte()
			cu[0] += 1 if int(J.B.psangra) > 0 else 0), "navaja")
	var cortes: int = cu[0]
	chk(cortes > 15 and cortes < 60, "la navaja corta a veces (%d/100)" % cortes)
	chk(J.recibe_txt().find("{b}") < 0 and J.recibe_txt().length() > 5, "lo que recibes")
	J.B = null
	# una pelea entera con los golpes nuevos (sin gancho de combate)
	S.items.bate = 1
	S.hp = 200
	S.hpMax = 200
	QUIERO = []
	for i in 80:
		QUIERO.append_array(["LUCHAR", "PUÑETAZO"])
	var res := [null]
	LOG.clear()
	chk(corre(func(): res[0] = await J.battle("thief")), "pelea sin bloqueo")
	chk(res[0] != null and log_tiene("Con el bate"), "pelea con el bate (%s)" % str(res[0]))
	# 9 · las tiendas por secciones, tipos y marcas
	var L := []
	for it in D.SHOP:
		if J.shop_cond(it):
			L.append(it)
	var ft: Dictionary = J.filtra_tienda(L, {"c": "", "s": "", "m": ""})
	chk(ft.filas.size() >= 5 and String(ft.filas[0].label).begins_with("▸ ") and ft.list.size() == L.size(), "secciones")
	var fl: Dictionary = J.filtra_tienda(L, {"c": "luz", "s": "", "m": ""})
	chk(fl.list.size() > 0 and fl.list.all(func(x): return J.cat_de(x)[0] == "luz") and String(fl.filas[0].label).begins_with("◂ "), "solo la luz")
	var fs: Dictionary = J.filtra_tienda(L, {"c": "luz", "s": "LED", "m": ""})
	chk(fs.list.all(func(x): return J.cat_de(x)[1] == "LED") and J.marca_de(fs.list[0]) != "", "tipo y marca")
	S.ch = 6
	MENUS.clear()
	QUIERO = ["▸ Luz", "Salir"]
	chk(corre(func(): await J.shop(D.TIENDAS.kiko)), "tienda con filtro")
	chk(MENUS.size() >= 2 and String(MENUS[1][0]).begins_with("◂ ") and MENUS[1].size() < MENUS[0].size(), "la tienda filtra")
	var T: Dictionary = D.TIENDAS.est.duplicate()
	MENUS.clear()
	din = float(S.money)
	QUIERO = ["Mechero de gasolina", "Salir"]
	chk(corre(func(): await J.shop(T)), "estanco")
	chk(MENUS[0].has("Papel de arroz (50 hojas)") and float(S.money) == din - 14, "estanco con más surtido")
	chk(J.carta("bar").size() == J.BEBIDAS.bar.size() + D.CARTA.bar.size() and J.carta("disco").size() == J.BEBIDAS.disco.size() + 2, "la carta")
	S.items.erase("bate")
	S.items.erase("cadena")
	din = float(S.money)
	QUIERO = ["Bate de madera", "Nada"]
	chk(corre(func(): await J.talk_bixente()), "chatarrería")
	chk(int(S.items.get("bate", 0)) == 1 and float(S.money) == din - 45, "el bate de Bixente")
	# 10 · sin CAL, como antes
	Datos.CAL = false
	chk(J.cal_precio(c, sid, S.buds[sid]) == 1.0 and J.cal_busco(c) == "" and J.filtra_tienda(L, {"c": "", "s": "", "m": ""}).filas.is_empty() and J.carta("bar").size() == J.BEBIDAS.bar.size() and J.armas_venta().size() >= 0, "sin CAL")
	Datos.CAL = true
	print("vida: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  FALLO: " + x)
	quit(1 if fallos.size() else 0)
