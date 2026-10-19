# Ribera Verde (Godot) — 11-historia, 12-menus y 13-combate: la tienda de Kiko, los personajes, la deuda, los capítulos y el
# imperio, el menú START (Genoteca, mochila, cultivo) y los combates con ladrones y policía. Mismo guion, mismo orden de azar.
extends "res://src/granja.gd"

const Croquis = preload("res://src/croquis.gd")

const Hoja = preload("res://src/hoja.gd")

var cap_hasta := 0.0       # el rótulo del capítulo dura 2,8 s: el objetivo que se pida mientras tanto sale al acabar

var endcard_on := false

# ---------- tienda ----------
func shop_cond(it: Dictionary) -> bool:
	if it.get("uno"):   # 1.47: el grinder, la pipa, el bong y el vaporizador, uno
		return not S.items.get(it.item)
	if it.get("item") == "prensa":   # la prensa de rosin (1.10), una
		return not S.items.get("prensa")
	if it.get("item") == "analizador":   # el analizador de cannabinoides y terpenos (1.15), uno
		return not S.items.get("analizador") and not S.envio.has(it.lbl)
	if it.get("item") in ["medidor", "tarros", "tamiz", "ice", "lavadora", "estatica"]:   # 1.35: los tamices y el kit Ice-o-lator, uno; 1.36: la lavadora y la static   # el medidor de pH y EC (1.11) y los tarros de curado (1.29), uno
		return not S.items.get(it.item) and not S.envio.has(it.lbl)
	if it.get("aparato"):   # los aparatos de la sala (1.10), uno de cada; lo pedido por el móvil no se vuelve a vender
		return not S.sala.get(it.aparato) and not S.envio.has(it.lbl)
	if it.get("mueble"):   # el carro de esquejes (1.11), uno
		return not (S.get("muebles") is Dictionary and S.muebles.has(it.mueble))
	if it.get("bolsa"):   # la bolsa de deporte y la maleta (1.10)
		return bolsa_ya() < it.bolsa
	if it.get("extra"):
		var k: String = it.extra
		var nc := 0
		for c in S.carpas:
			if falta_extra(c, k):
				nc += 1
		return nc > S.items.get("x_" + k, 0) + S.envio.count(it.lbl)
	match it.get("carpa", ""):
		"p80":
			return S.carpas[0].t == "p60"
		"m100":
			return S.carpas.size() < 2 or S.carpas[1] == null
		"g150":
			return S.carpas.size() > 1 and S.carpas[1] != null and S.carpas[1].t == "m100"
		"m120":
			return S.carpas.size() > 1 and S.carpas[1] != null and (S.carpas.size() < 3 or S.carpas[2] == null)
	return true

func precio_sobre(it: Dictionary, nf: Array) -> int:
	return Datos.jsround(it.p * nf[0] * nf[1])

func comprar_semillas(it: Dictionary) -> bool:
	var l: Array = D.SOBRES.duplicate()
	if S.ch >= 3:
		l.append(D.GRANEL)
	var o := []
	for nf in l:
		var nn := int(nf[0])
		o.append("%s · %s" % ["1 semilla" if nn == 1 else ("Bolsa de %d" % nn if nn >= 50 else "Sobre de %d" % nn), Datos.eur(precio_sobre(it, nf))])
	o.append("Nada")
	var j: int = await ask("Semillas feminizadas de %s. ¿Cuántas?" % D.STRAINS[it.sid].n, o, "KIKO")
	if j < 0 or j >= l.size():
		return false
	var e := precio_sobre(it, l[j])
	if S.money < e:
		sfx("bad")
		await say("No te llega el dinero.", "KIKO")
		return false
	S.money -= e
	sfx("coin")
	add_seeds(it.sid, int(l[j][0]))
	toast("Comprado: %d × %s" % [int(l[j][0]), D.STRAINS[it.sid].n], 1200)
	return true

# carpa comprada (en un sitio libre) o ampliada (mismo sitio): cada plaza conserva su planta y su maceta por (carpa, plaza)
func comprar_carpa(t: String, ci: int) -> void:
	var antes := []
	for h in huecos():
		antes.append("%d:%d" % [h.c, h.j])
	var pots: Array = S.pots
	var mac: Array = S.macetas
	if ci < S.carpas.size() and S.carpas[ci]:
		S.carpas[ci].t = t
	else:
		while S.carpas.size() <= ci:
			S.carpas.append(null)
		S.carpas[ci] = {"t": t, "foco": "cfl"}
	var np := []
	var nm_ := []
	for h in huecos():
		var j := antes.find("%d:%d" % [h.c, h.j])
		np.append(pots[j] if j >= 0 and j < pots.size() and pots[j] else null)
		nm_.append(mac[j] if j >= 0 and j < mac.size() and mac[j] else "plastico7")
	S.pots = np
	S.macetas = nm_

const IC := {"fert": "abono", "fertv": "abono", "phm": "abono", "ofert": "abono", "ofertv": "abono", "ophm": "abono", "insect": "insecticida", "spray": "spray", "bocata": "bocadillo"}

# las tiendas (1.14, D.TIENDAS): GROWSHOP KIKO y GROW IBARBIDE (ANE: un 10 % más barato y un capítulo antes, sin semillas, muebles ni
# aparatos: su ok() del JS, aquí a mano)
func tienda_ok(T: Dictionary, it: Dictionary) -> bool:
	return T.N != "ANE" or not (it.get("sid") or it.get("mueble") or it.get("aparato"))

func precio_t(T: Dictionary, it: Dictionary) -> int:
	return Datos.jsround(it.p * T.f * (.95 if T.N == "KIKO" and rel("kiko") >= D.REL.amigo else 1.0))   # 1.15: con confianza, Kiko hace un 5 %

# (lo pidió el usuario): el estanco de cada pueblo, papel, filtros, tabaco y mecheros (D.ESTANCO)
func talk_estanco(k: String) -> void:
	var E: Dictionary = D.ESTANCO.k[k]
	await say(pick(["Buenas. ¿Qué te pongo?", "Hola, majo. Dime.", "Buenas. Tabaco, papel, mecheros… lo que quieras."]), E.N)
	var T: Dictionary = D.TIENDAS.est.duplicate()
	T.t = E.t
	T.N = E.N
	await shop(T)

func shop(T: Dictionary = {}) -> void:
	if T.is_empty():
		T = D.TIENDAS.kiko
	var i := 0
	while true:
		var list := []
		var fuente: Array = D[T.lista].items if T.has("lista") else D.SHOP
		if Datos.CAL and not T.has("lista"):   # 1.47 (lo pidió el usuario): las pipas y demás, en el grow, en sus vitrinas
			fuente = fuente + D.PARAFERNALIA
		for it in fuente:
			if S.ch + T.ch >= it.ch and tienda_ok(T, it) and shop_cond(it):
				list.append(it)
		var items := []
		for it in list:
			var ic = null
			if it.get("sid"):
				ic = icono("semillas")
			elif it.get("ic"):   # 1.31: las garrafas
				ic = icono(it.ic)
			elif it.get("item"):
				ic = icono(IC[it.item]) if IC.has(it.item) else null
			elif it.get("maceta"):
				ic = icono("maceta")
			elif it.get("foco"):
				ic = icono(Atlas.ico_foco(it.foco))
			elif it.get("extra"):
				ic = icono(Atlas.ICX[it.extra])
			elif it.get("carpa"):
				ic = icono(Atlas.ico_carpa(it.carpa))
			items.append({"label": it.lbl, "right": Datos.eur(precio_t(T, it)) + ("/u" if it.get("sid") else ""), "sw": D.STRAINS[it.sid].c if it.get("sid") else null, "ic": ic,
				"desc": strain_line(it.sid) if it.get("sid") else it.get("desc", "")})
		items.append({"label": "Salir", "desc": "Volver al mostrador."})
		i = await menu(items, {"cls": "full", "title": T.t, "title2": "Tienes " + Datos.eur(S.money), "desc": true, "initial": i})
		if i < 0 or i >= list.size():
			break
		var it: Dictionary = list[i]
		if it.get("sid"):
			if await comprar_semillas(it) and T.N == "KIKO":
				confia("kiko", 1)
			await check_story()
			continue
		var p := precio_t(T, it)
		if S.money < p:
			sfx("bad")
			await say("No te llega el dinero.", T.N)
			continue
		S.money -= p
		sfx("coin")
		if T.N == "KIKO":
			confia("kiko", 1)
		await entregar(it, T.N)
		await check_story()
	await say("Ten cuidado ahí fuera.", T.N)

# lo comprado (en una tienda o en la chatarrería): a la mochila, a la sala o puesto en una carpa, si quieres
func entregar(it: Dictionary, N: String) -> void:
	if it.get("item"):
		S.items[it.item] = int(S.items.get(it.item, 0)) + int(it.get("n", 1))
	if it.get("maceta"):
		S.items["m_" + it.maceta] += 1
	if it.get("bolsa"):
		S.items.bolsa = int(it.bolsa)
	if it.get("aparato"):
		S.sala[it.aparato] = true
	if not it.get("foco") and not it.get("carpa") and not it.get("extra") and not it.get("mueble"):
		toast("Comprado: " + it.lbl, 1200)
	if it.get("mueble"):
		if not (S.get("muebles") is Dictionary):
			S.muebles = {}
		S.muebles[it.mueble] = S.day + 1
		await say("Mañana te lo subo al piso y te lo monto junto a las carpas.", N)
	if it.get("carpa"):
		comprar_carpa(it.carpa, int(it.ci))
		await say(D.DICHO_CARPA[it.carpa], N)
	if it.get("extra"):
		S.items["x_" + it.extra] += 1
		var ok := []
		for ci in S.carpas.size():
			if falta_extra(S.carpas[ci], it.extra):
				ok.append(ci)
		var pl: bool = D.EXTRAS[it.extra].get("pl", false)
		if ok.is_empty():
			await say("Ya tienes unas en cada carpa. Te las guardo en la mochila." if pl else "Ya tienes uno en cada carpa. Te lo guardo en la mochila.", N)
		else:
			var o := []
			for ci in ok:
				o.append(D.CARPAS[S.carpas[ci].t].n)
			o.append("Luego")
			var c: int = await ask("¿Te las pongo ya?" if pl else "¿Te lo pongo ya?", o, N)
			if c >= 0 and c < ok.size():
				var vu: bool = it.extra == "goteo" and S.carpas[ok[c]].get("garrafas", false)
				var vk := poner_extra(ok[c], it.extra)
				toast(("Puestas: " if pl else "Puesto: ") + it.lbl, 1200)
				if vu:
					await say("Las garrafas de esa carpa vuelven a la mochila.", N)
				if vk != "":
					await say("El %s que tenías vuelve a tu mochila." % D.EXTRAS[vk].c.to_lower(), N)
	if it.get("foco"):
		S.items["f_" + it.foco] += 1
		var ok := []
		for ci in S.carpas.size():
			var cc = S.carpas[ci]
			if cc and D.FOCOS[it.foco].w <= D.CARPAS[cc.t].wmax:
				ok.append(ci)
		if ok.is_empty():
			await say("Ese foco calienta demasiado para tus carpas. Guárdalo hasta que tengas una más grande.", N)
		else:
			var o := []
			for ci in ok:
				o.append("%s (%s)" % [D.CARPAS[S.carpas[ci].t].n, D.FOCOS[S.carpas[ci].foco].n])
			o.append("Luego")
			var c: int = await ask("¿Lo cuelgo ya? El que quites va a tu mochila.", o, N)
			if c >= 0 and c < ok.size():
				instalar_foco(ok[c], it.foco)
				toast("Instalado: " + it.lbl, 1200)

func kiko_tip() -> String:
	var t: Array = D.KIKO_TIPS
	var l: Array = t[mini(3, maxi(0, S.ch - 1))].duplicate()
	if S.ch > 3:
		l.append_array(t[1])
	return pick(l)

# ---------- personajes ----------
func talk_kiko():
	var N := "KIKO"
	if not S.flags.get("kiko1"):
		await talk(N, ["{N}, pasa. Te pareces a tu tía.", "Maite y yo cultivamos juntos desde que cerraron los astilleros. Ella tenía mano; yo, paciencia.", "Para empezar, toma esto."])
		add_seeds("ria", 3)
		await got("3 semillas de SKUNK #1")
		S.items.fert += 2
		await got("2 dosis de MEATZA FLORACIÓN")
		await talk(N, ["La Skunk #1 aguanta casi todo: errores de riego, plagas, frío. Es la mejor para aprender.", "Planta en las macetas del armario de tu tía y riega cuando baje el agua.",
			"El abono da más cogollo. Si ves araña roja, insecticida: lo tengo aquí.", "Cuando esté lista, cosecha. Son feminizadas: casi nunca dan semilla, pero si sale alguna, guárdala.",
			"Las plantas siguen creciendo mientras duermes.", "Te iré mandando al móvil lo que te hace falta para salir adelante. Lo tienes en START, en OBJETIVO.",
			"Mi hijo Julen te espera en el piso. Sabe más que yo de esto: te ayudará hasta tu primera cosecha."])
		S.flags.kiko1 = true
		show_objective()
		return
	if S.ch == 4 and not S.flags.get("lab"):
		await talk(N, ["Ya me han contado que has pagado a Baltasar. Bien hecho.", "Te he montado en el piso mi equipo de polinización: pinceles, bolsas de papel y una lupa."])
		S.flags.lab = true
		await got("la MESA DE GENÉTICA")
		add_seeds("rif", 3)
		await got("3 semillas de AFGHANI")
		await talk(N, ["Me las trajo un amigo de Mazar-i-Sharif en los ochenta. Las he ido renovando desde entonces.", "En la mesa polinizas una variedad con otra: gastas una semilla de cada y obtienes 2 del cruce.",
			"Algunos cruces dan variedades conocidas. Otros, híbridos que solo tendrás tú.", "Apúntalo todo en la GENOTECA. Las mejores genéticas salen de cruzar cruces.",
			"Empieza por las conocidas: saca dos de receta en la mesa y cosecha una planta de cada. Patxi, el de la plaza, se sabe unas cuantas."])
		show_objective()
		await check_story()
		return
	var alguna := false
	for p in S.pots:
		if p:
			alguna = true
	if S.seeds.is_empty() and not alguna and not total_buds() and not total_rosin() and not caja_g() and not cam_g() and not nevera_r() and S.money + caja_e() < 15:   # lo de la caja y la nevera también cuenta (1.10; 1.36: sin arcón)
		await say("¿Sin semillas y sin dinero? Toma. Ya me lo pagarás.", N)
		add_seeds("ria", 2)
		await got("2 semillas de SKUNK #1")
	var c: int = await ask("¿Qué necesitas?", ["Comprar", "Un consejo", "Nada"], N)
	if c == 0:
		await shop()
	elif c == 1:
		await say(kiko_tip(), N)
	else:
		await say("Ten cuidado ahí fuera.", N)

func talk_josune():
	var N := "JOSUNE"
	var c: int = await ask("¡Kaixo! ¿Qué te pongo?", ["Pintxo · 4 €", "Kalimotxo · 3 €", "¿Algún rumor?", "Nada"], N)
	if c == 0 or c == 1:
		var cost := 3 if c else 4
		var hp := 6 if c else 12
		if S.money < cost:
			await say("Aquí no se fía.", N)
			return
		S.money -= cost
		S.hp = mini(S.hpMax, S.hp + hp)
		sfx("coin")
		await say("Un kalimotxo. Recuperas algo de vida." if c else "Pintxo de tortilla, recién hecha. Recuperas vida.", N)
		return
	if c == 2:
		await say(pick(["Dicen que alguien escondía cosas en los arbustos del parque.", "Iñaki, el del muelle, trae semillas de sus viajes.", "Txaro está con la quimio. Lo está pasando muy mal.",
			"Darko es sobrino de Baltasar. Por eso nadie le dice nada.", "El sargento Molina cobra por mirar hacia otro lado. Lo sabe todo el barrio."]), N)

func talk_patxi():
	S.patxi = S.get("patxi", 0) + 1
	var R: Array = D.RECIPE_HINTS
	await say("Cuando tengas una mesa de genética, ven a verme. Algo sé de cruces." if S.ch < 4 else "Cuarenta años cultivando en el monte. Te digo una cosa: " + R[S.patxi % R.size()], "PATXI")

func talk_txaro():
	var N := "ABUELA TXARO"
	if S.flags.get("txaro") and (S.flags.get("txaro2") or S.ch < 4):
		await say(pick(["Ya duermo de un tirón. Gracias, de verdad.", "Tu tía me ayudaba igual. No se lo contábamos a nadie."]), N)
		return
	# segunda misión (1.10), en su casa desde el capítulo 4: 10 g de una índica (70 % o más)
	if S.flags.get("txaro"):
		await talk(N, ["El aceite me ha devuelto el sueño. Gracias, de verdad.", "Pero el dolor no se va. El médico dice que, para eso, mejor una índica: relaja más.",
			"¿Me traerías 10 gramos de una índica? De las de hoja ancha."])
		var li := bud_lots(10).filter(func(l): return Datos.ind_de(S, lot_sid(l[0])) >= 70)
		if li.is_empty():
			await say("Cuando tengas 10 gramos de una índica, ven a verme. Aquí estaré.", N)
			return
		var it2 := li.map(lot_item)
		it2.append({"label": "Ahora no"})
		var i2: int = await menu(it2, {"cls": "right", "title": "¿Qué le das?"})
		if i2 < 0 or i2 >= li.size():
			await say("No pasa nada. Aquí estaré.", N)
			return
		use_buds(li[i2][0], 10)
		S.rep += 5
		confia("txaro", 10)
		await say("Toma, las últimas de mi Paco. Las trajo de Chitral, en las montañas de Pakistán.", N)
		add_seeds("chitral", 3)
		await got("3 semillas de CHITRAL KUSH")
		S.items.bocata += 3
		await got("3 × BOCATA")
		S.flags.txaro2 = true
		return
	await talk(N, ["Tú vives en el piso de Maite. Tu tía me ayudaba con... ya sabes.", "Desde la quimio apenas duermo y no tengo hambre. Las pastillas no me hacen nada.",
		"Me vendrían bien 5 gramos, para hacer aceite como me enseñó ella. ¿Me los das?"])
	var lots := bud_lots(5)
	if lots.is_empty():
		await say("Cuando tengas 5 gramos, acuérdate de mí.", N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Ahora no"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué le das?"})
	if i < 0 or i >= lots.size():
		await say("No pasa nada. Aquí estaré.", N)
		return
	use_buds(lots[i][0], 5)
	confia("txaro", 10)
	await say("Gracias. Toma: las trajo mi Paco de Pakistán en el setenta y seis. Nunca supe qué hacer con ellas.", N)
	add_seeds("hindu", 2)
	await got("2 semillas de HINDU KUSH")
	S.items.bocata += 3
	await say("Y llévate estos bocadillos, que comes poco.", N)
	await got("3 × BOCATA")
	S.flags.txaro = true
	await say("Me voy a casa a preparar el aceite. Vivo en la casa gris, al lado del bar. Pásate cuando quieras.", N)
	if S.map == "town":
		await fade(1)
		build_ents()
		await fade(0)

# Iñaki: 10 g para el viaje, una vez al día; desde el capítulo 3 también compra al por mayor
func talk_inaki():
	var N := "IÑAKI"
	if S.ch >= 3:
		var ops := ["10 g para el viaje", "Venta al por mayor"] + (["Comprarle al por mayor"] if Datos.CAL else []) + ["Nada"]   # 1.45: también vende
		var c: int = await ask("Aupa. ¿Qué traes?", ops, N)
		if c == 1:
			await venta_mayor(N)
			return
		if ops[c] == "Comprarle al por mayor":
			await comprar_mercado("inaki", N, pool_mayor())
			return
		if c != 0:
			return
	if S.iDay == S.day:
		await say("Ya me has vendido hoy. Mañana más, que el barco sale temprano.", N)
		return
	await say("Aupa. Me voy tres semanas a la mar. ¿Tienes 10 g para el viaje? Pago bien.", N)
	var lots := bud_lots(10)
	if lots.is_empty():
		await say("Pues nada. Si consigues 10 g, aquí estaré.", N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué le vendes?"})
	if i < 0 or i >= lots.size():
		return
	var sid: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var amt := Datos.jsround(precio_calle(b.thc) * calidad(b) * 1.2 * 10)
	if await ask("Te doy %d € por 10 g de %s. ¿Hecho?" % [amt, lot_nombre(sid)], ["Hecho", "No"], N) != 0:
		return
	use_buds(sid, 10)
	S.money += amt
	S.sales += amt
	S.heat = min(100, S.heat + 3)
	S.iDay = S.day
	S.rep += 2
	confia("inaki", 1)
	sfx("coin")
	if not S.flags.get("inaki"):
		S.flags.inaki = true
		await say("Toma. Me las dio un marinero de Malaui en Mombasa, en el último viaje.", N)
		add_seeds("malawi", 2)
		await got("2 semillas de MALAWI GOLD")
	else:
		await say("Eskerrik asko. Hasta la vuelta.", N)
	await check_story()

func mayor_dia() -> int:
	return int(D.IMPERIO[imperio_nivel() if S.ch >= 8 else 0].mayor)

static func _kg(g: int) -> String:
	return (Datos.coma(g / 1000.0) + " kg") if g >= 1000 else "%d g" % g

static func _dos(x: float) -> String:
	return Datos.to_fixed(x, 2).replace(".", ",")

func venta_mayor(N: String) -> void:
	var resto: float = resto_mer("inaki", mayor_dia()) if Datos.CAL else float(mayor_dia())   # 1.45: varias cargas al día, hasta el tope
	if (S.mDay == S.day and not Datos.CAL) or resto < 1:
		await say("Hoy ya he cargado. Mañana sale otro barco.", N)
		return
	var VX: Dictionary = D.VENTA_EXTR
	var lots := lotes_venta(100, VX.min)
	if lots.is_empty():
		await say("Al por mayor, de 100 g para arriba. Pago entre %s y %s € el gramo, según lo bueno que sea. Hasta %s por carga." % [_dos(precio_mayor(12)), _dos(precio_mayor(30)), _kg(mayor_dia())] + (" Extracciones, de %d g para arriba." % int(VX.min) if Datos.CAL else ""), N)
		return
	var it := lots.map(venta_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		await say("Otro día.", N)
		return
	var l: Array = lots[i]
	var x := es_extr(l)
	var k: String = l[0]
	var b: Dictionary = l[1]
	var pg := Datos.jsround((precio_extr(k, b.thc, "mayor") if x else precio_mayor(b.thc)) * calidad(b) * (1.05 if rel("inaki") >= D.REL.amigo else 1.0) * 100) / 100.0   # 1.15: con confianza, un 5 % más
	var ops := []
	if x:   # 1.43.7: la carga, en gramos de flor (1 g de extracción ↔ 1 / ROSIN.rend)
		ops = ops_extr(b, resto * D.ROSIN.rend, VX.g)
	else:
		var tope := mini(int(floor(b.g)), int(resto))
		for g in [100, 250, 500, 1000, 2000, 5000, 10000]:
			if g < tope:
				ops.append(g)
		ops.append(tope)
	var o := []
	for g in ops:
		o.append("%s · %s" % [_kg(g), Datos.eur(g * pg)])
	o.append("Nada")
	var j: int = await ask("%s a %s € el gramo. ¿Cuánto cargas?" % [venta_nombre(l), _dos(pg)], o, N)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	var e := Datos.jsround(g * pg)
	usa_lote(l, g)
	S.money += e
	S.sales += e
	S.mDay = S.day
	if Datos.CAL:
		suma_mer("inaki", g / D.ROSIN.rend if x else float(g))
	S.heat = min(100, S.heat + 2 + (g / D.ROSIN.rend if x else g) / 100.0)   # 1.10: antes, por cada 250 g
	S.rep += 1
	confia("inaki", 1)
	sfx("coin")
	await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
	toast("+%s · %s %sal por mayor" % [Datos.eur(e), _kg(g), (extr_nombre(k, true).get_slice(" de ", 0) + " ") if x else ""], 1600)
	await say("Cargado. Esta noche sale en el barco.", N)
	heat_warn()
	await check_story()

# ---------- la comarca con función (1.14, 11d-comarca) ----------
# Ibarbide: GROW IBARBIDE (TIENDAS.ane). Puerto Viejo: la lonja (NEREA), al por mayor a un 15 % más que Iñaki, hasta 500 g y cada
# 3 días. Valdehierro: la chatarrería del solar (BIXENTE), 3 piezas de segunda mano al día a mitad de precio. Errotabarri: el
# molino (ANDONI), 20 g de cogollo por 3 semillas de una landrace del banco que aún no tengas, una vez por semana
func talk_ane():
	var N := "ANE"
	await say("¿Qué te hace falta hoy?" if S.flags.get("ane") else "Kaixo. Esto es GROW IBARBIDE: el equipo, un 10 % más barato que en el barrio, y lo nuevo antes que nadie.", N)
	S.flags.ane = true
	await shop(D.TIENDAS.ane)

# las 3 piezas del día: las mismas para todos (_hash_t del día), sin repetir
func chatarra_dia() -> Array:
	var l: Array = D.CHATARRA.piezas.duplicate()
	var r := []
	for i in int(D.CHATARRA.n):
		var j := _hash_t(S.day, i + 7) % l.size()
		r.append(l[j])
		l.remove_at(j)
	return r

func talk_bixente():
	var N := "BIXENTE"
	if S.ch < int(D.CHATARRA.ch):
		await say("Compro chatarra y vendo lo que se puede aprovechar. Vuelve cuando cultives en serio.", N)
		return
	var i := 0
	while true:
		var ch = S.get("chatarra")
		var ya: Array = ch.v if ch is Dictionary and int(ch.d) == S.day else []
		var l := []
		for lbl in chatarra_dia():
			if ya.has(lbl):
				continue
			for it in D.SHOP:
				if it.lbl == lbl:
					if S.ch >= int(it.ch) and shop_cond(it):   # solo lo de su capítulo
						l.append(it)
					break
		if l.is_empty():
			await say("Hoy no me queda nada que te sirva. Mañana entra más.", N)
			return
		var items := []
		for it in l:
			items.append({"label": it.lbl, "right": Datos.eur(Datos.jsround(it.p * D.CHATARRA.f)), "desc": it.get("desc", "") + "\nDe segunda mano: funciona, pero sin garantía."})
		items.append({"label": "Nada", "desc": "Cada día entran tres piezas."})
		i = await menu(items, {"cls": "full", "title": "CHATARRERÍA DEL SOLAR", "title2": "Tienes " + Datos.eur(S.money), "desc": true, "initial": i})
		if i < 0 or i >= l.size():
			await say("Lo que entra, sale. Si lo quieres, no tardes.", N)
			return
		var it: Dictionary = l[i]
		var p := Datos.jsround(it.p * D.CHATARRA.f)
		if S.money < p:
			sfx("bad")
			await say("Sin dinero no hay trato.", N)
			continue
		S.money -= p
		sfx("coin")
		if not (ch is Dictionary and int(ch.d) == S.day):
			S.chatarra = {"d": S.day, "v": []}
		S.chatarra.v.append(it.lbl)
		await entregar(it, N)
		await check_story()

func talk_nerea():
	var N := "NEREA"
	var L: Dictionary = D.LONJA
	if S.ch < int(L.ch):
		await say("De madrugada se subasta el pescado. Lo otro, cuando te conozca más gente.", N)
		return
	if Datos.CAL:   # 1.45: la lonja también vende, y carga varios lotes hasta su tope por barco
		var c: int = await ask("¿Vienes a cargar o a llevarte algo?", ["Venderle", "Comprarle", "Nada"], N)
		if c == 1:
			await comprar_mercado("lonja", N, pool_mayor())
			return
		if c != 0:
			return
	var resto: float = float(L.g) - (float(S.mer_v.lonja.g) if Datos.CAL and S.get("mer_v") is Dictionary and S.mer_v.has("lonja") and S.get("lonja") and int(S.mer_v.lonja.d) == int(S.lonja) else 0.0)
	if S.get("lonja") and S.day < int(S.lonja) + int(L.dias) and (not Datos.CAL or resto < 1 or S.day != int(S.lonja)):
		await say("Los barcos de fuera vuelven el %s. Tráelo entonces." % Datos.fd(int(S.lonja) + int(L.dias), S.day), N)
		return
	if not (S.get("lonja") and S.day < int(S.lonja) + int(L.dias)):
		resto = float(L.g)
	var VX: Dictionary = D.VENTA_EXTR
	var lots := lotes_venta(100, VX.min)
	if lots.is_empty():
		await say("Cargo para los barcos de fuera: de 100 a %d g, un %d %% por encima de lo que paga Iñaki. Cada %d días." % [int(L.g), Datos.jsround((L.f - 1) * 100), int(L.dias)] + (" Extracciones, de %d g para arriba." % int(VX.min) if Datos.CAL else ""), N)
		return
	var it := lots.map(venta_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		await say("Otro día.", N)
		return
	var l: Array = lots[i]
	var x := es_extr(l)
	var k: String = l[0]
	var b: Dictionary = l[1]
	var pg := Datos.jsround((precio_extr(k, b.thc, "mayor") if x else precio_mayor(b.thc)) * calidad(b) * L.f * 100) / 100.0
	var ops := []
	if x:
		ops = ops_extr(b, resto * D.ROSIN.rend, VX.g)
	else:
		var tope := mini(int(floor(b.g)), int(resto))
		for g in [100, 250]:
			if g < tope:
				ops.append(g)
		ops.append(tope)
	var o := []
	for g in ops:
		o.append("%s · %s" % [_kg(g), Datos.eur(g * pg)])
	o.append("Nada")
	var j: int = await ask("%s a %s € el gramo. ¿Cuánto cargas?" % [venta_nombre(l), _dos(pg)], o, N)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	var e := Datos.jsround(g * pg)
	usa_lote(l, g)
	S.money += e
	S.sales += e
	if Datos.CAL:
		if not (S.get("mer_v") is Dictionary):
			S.mer_v = {}
		var u: float = float(S.mer_v.lonja.g) if S.mer_v.has("lonja") and int(S.mer_v.lonja.d) == int(S.day) and int(S.get("lonja", -1)) == int(S.day) else 0.0
		S.mer_v.lonja = {"d": S.day, "g": u + (g / D.ROSIN.rend if x else float(g))}
	S.lonja = S.day
	S.heat = min(100, S.heat + 2 + (g / D.ROSIN.rend if x else g) / 100.0)
	S.rep += 1
	sfx("coin")
	await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
	toast("+%s · %s en la lonja" % [Datos.eur(e), _kg(g)], 1600)
	await say("Hecho. Sale con el pesquero de las cinco.", N)
	heat_warn()
	await check_story()

# la landrace del trueque: la primera del banco (las de su capítulo) que no tienes en la Genoteca; si no, una según el día. 1.26: también
# las que no se venden (REGALO), ya descubiertas, y antes que nada una de esas de la que no te queden semillas: que no se pierdan
func landrace_trueque() -> String:
	var r := []
	for k in D.REGALO:
		if S.disc.get(k) and str(D.STRAINS[k].o).begins_with("Landrace") and not D.BANCO.any(func(b): return b[0] == k):
			r.append(k)
	var l := []
	for b in D.BANCO:
		if S.ch >= int(b[2]):
			l.append(b[0])
	l.append_array(r)
	for k in l:
		if not S.disc.get(k):
			return k
	for k in r:
		if not S.seeds.get(k):
			return k
	return l[S.day % l.size()]

# Darko (1.17): en el capítulo 8, el ajuste de cuentas en sus esquinas de los astilleros. Pelea como un rival con DARKO.vida más
# y la carga (enemy_hits). Si le ganas, se va (S.flags.darkoFin = el día): ni él ni sus chicos vuelven por los astilleros
func ajuste_darko() -> void:
	var N := "DARKO"
	await talk(N, ["Mírate. Cargas en el barco de Iñaki y mi tío te llama socio.", "A mí me trata como a un recadero. Y todo empezó contigo.", "Esto lo arreglamos tú y yo. Aquí y ahora."])
	if await ask("¿Peleas con Darko?", ["Pelear", "Ahora no"], N) != 0:
		await say("Ya sabes dónde estoy. Mis chicos también.", N)
		return
	var r = await battle("darko")
	if r == "ko":
		return
	if r != "win":
		await say("Corre, corre. Aquí te espero.", N)
		return
	S.flags.darkoFin = S.day
	S.rep += int(D.DARKO.rep)
	sfx("get")
	await talk(N, ["Vale. Vale. Ya está.", "Las esquinas son tuyas. Yo me largo de aquí una temporada."])
	await fade(1)
	build_ents()
	await fade(0)
	await talk("SMS · DON BALTASAR", ["Me han contado lo de mi sobrino.", "Se va a trabajar a un pesquero de fuera. Le vendrá bien.", "Tú y yo seguimos como siempre."])

# Miren (1.17): la amiga de la tía Maite, en Errotabarri desde el capítulo MIREN.ch. Le llevas MIREN.g g de la variedad que
# cultivaban juntas (MIREN.sid) y te da la página que falta del diario (S.flags.pagina, PAGINA) y MIREN.n semillas
func talk_miren():
	var N := "MIREN"
	var M: Dictionary = D.MIREN
	var v: String = String(D.STRAINS[M.sid].n).to_upper()
	if S.flags.get("pagina") and not S.flags.get("lao"):
		await lao_miren(N)
		return
	if S.flags.get("pagina"):
		await say(pick(["Tu tía subía cada otoño con un táper de cogollos y se quedaba a dormir.", "Del caserío no me echó nadie gracias a ella. Eso no se olvida.", "Cuando la Haze te salga sola, acuérdate de nosotras."]), N)
		return
	if not S.flags.get("miren"):
		S.flags.miren = S.day
		await talk(N, ["¿Tú eres el de Maite? Tienes sus ojos.", "Me llamo Miren. Tu tía y yo cultivábamos juntas en este caserío, hace treinta años.", "Su diario tiene una página arrancada. Me la dio la última vez que subió.", "Tráeme %d g de %s, la que hacíamos las dos, y es tuya." % [int(M.g), v]])
		return
	var ks: Array = S.buds.keys().filter(func(k): return lot_sid(k) == M.sid)
	ks.sort_custom(func(a, b): return not a.ends_with("*") and b.ends_with("*"))   # primero lo que no es estrella
	var tot := 0.0
	for k in ks:
		tot += float(S.buds[k].g)
	if tot < float(M.g):
		await say("¿Me traes los %d g de %s? Sin prisa: aquí estoy." % [int(M.g), v], N)
		return
	if await ask("¿Le das %d g de %s?" % [int(M.g), v], ["Dárselos", "Todavía no"], N) != 0:
		await say("Cuando quieras.", N)
		return
	var q := float(M.g)
	for k in ks:
		var t: float = minf(q, float(S.buds[k].g))
		use_buds(k, t)
		q -= t
		if q <= 0:
			break
	S.flags.pagina = S.day
	add_seeds(M.s, int(M.n))
	await talk(N, ["Huele igual que entonces.", "Toma. La página que falta, y unas semillas de su Haze."])
	await got("la última página del diario y %d semillas de %s" % [int(M.n), String(D.STRAINS[M.s].n).to_upper()])
	await lao_miren(N)
	await say("Léela en casa, con calma.", N)

# Y MIREN.n2 de la de Laos (MIREN.s2, que no está en el banco; S.flags.lao: las partidas de antes, al volver a hablarle)
func lao_miren(N: String) -> void:
	var M: Dictionary = D.MIREN
	S.flags.lao = S.day
	add_seeds(M.s2, int(M.n2))
	await say("Y esto también era de las dos. La de Laos: la guardábamos para la Amnesia.", N)
	await got("%d semillas de %s" % [int(M.n2), String(D.STRAINS[M.s2].n).to_upper()])

func talk_andoni():
	var N := "ANDONI"
	var T: Dictionary = D.TRUEQUE
	if S.ch < int(T.ch):
		await say("El molino muele los domingos. Si te interesan las semillas viejas, vuelve más adelante.", N)
		return
	if S.get("trueque") and S.day < int(S.trueque) + int(T.dias):
		await say("Hasta el %s no tengo más semillas para cambiar." % Datos.fd(int(S.trueque) + int(T.dias), S.day), N)
		return
	var k := landrace_trueque()
	await say("Mi abuelo guardaba semillas en botes de cristal, junto a la harina. Tengo de %s." % D.STRAINS[k].n, N)
	var lots := bud_lots(int(T.g))
	if lots.is_empty():
		await say("Te doy %d por %d g de lo tuyo. Cuando los tengas, aquí estoy." % [int(T.n), int(T.g)], N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "%d semillas por %d g" % [int(T.n), int(T.g)]})
	if i < 0 or i >= lots.size():
		await say("Tú verás. El bote no se mueve de aquí.", N)
		return
	use_buds(lots[i][0], int(T.g))
	add_seeds(k, int(T.n))
	S.trueque = S.day
	await got("%d semillas de %s" % [int(T.n), String(D.STRAINS[k].n).to_upper()])
	await say("Cuídalas. Ya no quedan muchas así.", N)

func talk_cop():
	if carga_sosp() > 0 and not S.protect:
		await say("¿Y ese olor? Quieto ahí.", "AGENTE")
		await battle("police")
		return
	await say(pick(["Circule.", "Todo tranquilo por aquí. Que siga así.", "De noche hay robos en el parque. Tenga cuidado."]), "AGENTE")

func talk_darko():
	var N := "DARKO"
	if S.ch == 6:
		await talk(N, ["¿Vienes a la Copa? Mi AMNESIA HAZE dio un 26,8 % de THC en el laboratorio.", "Nadie en Ribera ha pasado del 26. No vas a ser tú el primero."])
		return
	if S.ch >= int(D.DARKO.ch):   # el ajuste de cuentas (1.17)
		await ajuste_darko()
		return
	if S.ch >= 7:   # en los astilleros (1.10)
		await talk(N, ["¿Has dormido bien últimamente?" if S.flags.get("robo") else "Mi tío dice que ya no le debes nada. A mí, sí.", "Estas esquinas son mías. Si vendes aquí, mis chicos te lo van a recordar."])
		return
	S.flags.darko1 = true
	await talk(N, ["Así que tú te has quedado el piso de Maite.", "Soy DARKO. La hierba de este barrio la muevo yo.", "Vende lo tuyo si quieres, pero lejos de mis esquinas.", "No me hagas repetirlo."])
	await fade(1)
	build_ents()
	await fade(0)

# la cuota de Molina (1.10): SOBORNO cada CUOTA_DIAS días (S.protHasta, el último día cubierto; new_day la da por acabada).
# La primera vez, en la plaza; después, en la comisaría del barrio alto
func talk_molina():
	var N := "SARGENTO MOLINA"
	var sob := int(D.SOBORNO)
	var cd := int(D.CUOTA_DIAS)
	var plaza: bool = S.map == "town"
	if not S.flags.get("molina1"):
		S.flags.molina1 = true
		await talk(N, ["Así que eres tú quien vende en la plaza.", "Podría detenerte ahora mismo. O podemos entendernos.", "Por %s cada %d días, mis patrullas no pasan por tu calle. Y nada de registros en tu piso." % [Datos.eur(sob), cd]])
	elif S.protect:
		await say("Estás cubierto hasta el %s. %s" % [Datos.fd(S.protHasta, S.day), ("Te quedan %s días." % n(S.protHasta - S.day)) if S.protHasta > S.day else "Se acaba HOY."], N)
	var c: int = await ask("¿Pagar ya los diez días siguientes?" if S.protect else "¿Aceptas el trato del sargento?", ["Pagar " + Datos.eur(sob), "No"], N)
	if c == 0:
		if S.money < sob:
			await say("¿Con qué dinero? Vuelve cuando lo tengas.", N)
		else:
			S.money -= sob
			S.protHasta = int(max(S.day, S.protHasta if S.protect else 0)) + cd
			S.protect = true
			sfx("coin")
			await say("Bien. Mis agentes mirarán hacia otro lado hasta el %s." % Datos.fd(S.protHasta, S.day), N)
	elif not S.protect:
		S.heat = min(100, S.heat + 10)
		await say("Tú sabrás. Mis agentes van a estar muy atentos.", N)
		heat_warn()
	if plaza:
		await say("Si me necesitas, estoy en la comisaría del barrio alto.", N)
		await fade(1)
		build_ents()
		await fade(0)

func talk_jurado():
	var N := "JURADO"
	await talk(N, ["Esto es la COPA DE RIBERA, la de la asociación cannábica del barrio.", "Para competir, trae 20 g de una sola variedad. Se analizan en laboratorio.", "Marca a batir: DARKO, con AMNESIA HAZE, 26,8 % de THC."])
	var lots := bud_lots(20)
	if lots.is_empty():
		await say("Vuelve cuando tengas 20 g de algo.", N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Todavía no"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué presentas?"})
	if i < 0 or i >= lots.size():
		return
	var sid: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var thc := Datos.jsround(b.thc * 10) / 10.0
	var name_ := lot_nombre(sid).replace(" ★", "")
	use_buds(sid, 20)
	await fade(1)
	await wait(500)
	await fade(0)
	await say("Resultado del laboratorio. AMNESIA HAZE de Darko: 26,8 % de THC.", N)
	await say("%s de {N}: %s %% de THC." % [name_, Datos.pct(thc)], N)
	if thc > float(D.COPA_THC):
		sfx("get")
		await say("Nueva marca. {N} gana la COPA DE RIBERA.", N)
		S.money += int(D.PREMIO_COPA)
		S.rep += 20
		await got(Datos.eur(D.PREMIO_COPA) + " y el trofeo de la Copa")
		await talk("DARKO", ["Esto no se acaba aquí.", "Mi tío se va a enterar."])
		S.flags.copa = true
		S.due = S.debt
		S.deadline = S.day + dias_plazo(7)
		if Datos.PLAY:
			S.due0 = S.due
		cerrar_copa()
		await chapter(7)   # el plazo, antes: chapter() guarda
		show_objective()
	else:
		sfx("bad")
		await say("Gana DARKO. La Copa sigue abierta: vuelve con algo más potente.", N)

func talk_baltasar():
	var N := "DON BALTASAR"
	if S.ch < 3:
		await say("¿Y tú quién eres? No tengo nada que hablar contigo.", N)
		return
	# el plazo corre desde que Toño te avisa (1.10): si tardas más de 2 días en venir, «Llegas tarde»
	if S.ch == 3 and not S.flags.get("metB"):
		var tarde: bool = S.flags.has("tono") and S.day - S.flags.tono > 2
		await talk(N, ["Llegas tarde, {N}. Toño te dijo «hoy»." if tarde else "Siéntate, {N}. Vamos al grano.", "Tu tía Maite me debía %s. Las deudas no se mueren con la gente." % Datos.eur(D.DEUDA).replace(" €", " euros"),
			"Me los vas a pagar a plazos. El primero, %s%s." % [Datos.eur(S.due), ", con los intereses de tu retraso" if S.due > D.PLAZOS["3"] else ""],
			"Tienes hasta el %s. Si no, Toño te hará una visita. Y Toño cobra intereses." % Datos.fd(S.deadline, S.day)])
		S.flags.metB = true
		show_objective()
		return
	if S.ch >= 8:
		await encargo_baltasar(N)
		return
	if S.ch == 4:
		await say("Tranquilo. Ya te avisaré cuando toque el siguiente pago.", N)
		return
	if S.ch == 6:
		await say("Primero, la Copa. Darko te espera en la plaza.", N)
		return
	var left: int = S.deadline - S.day
	await say("Me debes %s para el %s. %s" % [Datos.eur(S.due), Datos.fd(S.deadline, S.day), ("Te quedan %d días." % left) if left > 0 else "Es HOY."], N)
	if S.money < S.due:
		await say("Vuelve cuando tengas el dinero.", N)
		return
	if await ask("¿Pagar ahora?", ["Pagar", "Todavía no"], N) != 0:
		return
	await gesto("pagar")   # 1.54
	S.money -= S.due
	S.debt -= S.due
	var paid = S.due
	S.due = 0
	sfx("coin")
	toast("Pagado: " + Datos.eur(paid), 1500)
	if S.ch == 3:
		await talk(N, ["Puntual. Así me gusta.", "Quedan %s. Ya te avisaré del siguiente plazo." % Datos.eur(S.debt).replace(" €", "")])
		if Datos.PLAY and await demo_corta():   # U11 (fase 6): la demo acaba aquí sin el juego completo
			return
		await cap4_sigue()
	elif S.ch == 5:
		await talk(N, ["Me sorprendes, {N}.", "Quedan %s. Te propongo algo." % Datos.eur(S.debt).replace(" €", ""), "La COPA DE RIBERA se juega estos días en la plaza. Premio: %s." % Datos.eur(D.PREMIO_COPA),
			"Mi sobrino Darko compite. No ha perdido nunca.", "Gana la Copa y, con el premio y lo que vendas, me pagas lo que queda. Si puedes."])
		await chapter(6)
		show_objective()
	elif S.ch == 7:
		await talk(N, ["%s. Contados." % Datos.eur(paid), "Deuda saldada. Lo de tu tía queda cerrado.", "Una cosa más, {N}: si algún día quieres trabajar para mí, ya sabes dónde estoy."])
		S.debt = 0
		S.imp0 = S.sales
		S.impN = 0
		await ending()

# ---------- capítulos, objetivo e imperio ----------
# líneas de autobús nuevas (1.14): las paradas se abren por capítulos (PARADAS.cap); al abrirse, un SMS de la compañía
func lineas_nuevas() -> void:
	var L := []
	for k in D.PARADAS:
		if int(D.PARADAS[k].cap) == S.ch:
			L.append(D.PARADAS[k].n)
	if L.size():
		await talk("SMS · AUTOBUSES DE LA COMARCA", ["Nueva línea desde Ribera Verde: %s." % _lista(L), "Salidas de %d:%02d a %d:%02d, en la parada de la calle Ribera." % [int(D.BUS_HORAS[0]) / 60, int(D.BUS_HORAS[0]) % 60, int(D.BUS_HORAS[1]) / 60, int(D.BUS_HORAS[1]) % 60]])

# el capítulo 4 tras el primer plazo (fase 6: también desde START · JUEGO COMPLETO, al comprar después)
func cap4_sigue() -> void:
	await chapter(4)
	await talk("SMS · KIKO", ["Pásate por el growshop. Tengo algo para ti."])
	await lineas_nuevas()
	show_objective()

# fase 6 (retencion.gd): la demo, los objetivos diarios y Play Games
func demo_corta() -> bool:
	return false

func demo_menu() -> bool:
	return false

func diario_revisa() -> void:
	pass

func diarios_txt() -> String:
	return ""

func diario_menu() -> void:
	pass

func logro_play(_id: String) -> void:
	pass

func chapter(nn: int) -> void:
	S.ch = nn
	evento("cap_%d" % nn)
	sfx("get")
	toast("<small>CAPÍTULO %d</small>%s" % [nn, D.CH_TITLES[str(nn)]], 2800)
	cap_hasta = M.reloj + 2800
	build_ents()
	await wait(400)
	save()

func objective_text() -> String:
	match int(S.ch):
		1:
			if llegando():
				return "Coge el autobús en la plaza de Mendialde hasta Ribera Verde."
			if not S.flags.get("letter"):
				return "Lee la carta que hay en la mesa." if S.map == "home" else "Entra en el piso de la tía Maite, enfrente de la parada, y lee la carta que hay en la mesa."
			if not S.flags.get("kiko1"):
				return "Visita el growshop de Kiko, al lado de casa."
			var sg = itin_sig()   # 1.23: el paso del itinerario
			return sg.d if sg != null and not S.flags.get("harvest1") else "Planta y consigue tu primera cosecha."
		2:
			var mv := int(D.META_VENTAS)
			return "Gana %d € vendiendo (%d/%d)." % [mv, mini(mv, Datos.jsround(S.sales)), mv]
		3:
			return (("Ve al bar El Ancla antes de que acabe el %s: Don Baltasar quiere %s." % [Datos.fd(S.deadline, S.day), Datos.eur(S.due)]) if not S.flags.get("metB") else "Paga %s a Don Baltasar antes de que acabe el %s." % [Datos.eur(S.due), Datos.fd(S.deadline, S.day)]) + llevas()
		4:
			return "Kiko quiere verte en el growshop." if not S.flags.get("lab") else "Saca en la mesa 2 variedades de receta y cosecha una planta de cada (%d/2)." % rec_count()
		5:
			return "Paga %s a Don Baltasar antes de que acabe el %s." % [Datos.eur(S.due), Datos.fd(S.deadline, S.day)] + llevas()
		6:
			return "Gana la Copa: 20 g con más de 26,8% de THC al jurado de la plaza."
		7:
			return "Paga los últimos %s a Don Baltasar antes de que acabe el %s." % [Datos.eur(S.due), Datos.fd(S.deadline, S.day)] + llevas()
	if S.get("encargo"):
		return "Encargo de Don Baltasar: lleva %s al almacén de los astilleros, de noche, antes de que acabe el %s." % [_kg(int(S.encargo.g)), Datos.fd(S.encargo.hasta, S.day)]
	var nv := imperio_nivel()
	var I: Array = D.IMPERIO
	var nd := 0
	for k in D.DEX:
		if S.disc.get(k):
			nd += 1
	var gen := "Genoteca %d/%d" % [nd, D.DEX.size()]
	if nv + 1 < I.size():
		var sig: Dictionary = I[nv + 1]
		return "Tu imperio · %s. Facturado desde la deuda: %s de %s para ser %s. %s." % [I[nv].n, Datos.eur(minf(sig.meta, facturado())), Datos.eur(sig.meta), sig.n.to_lower(), gen]
	return "Tu imperio · %s. Completa la %s." % [I[nv].n, gen]

# En los plazos, lo que llevas entre el bolsillo y la caja
func llevas() -> String:
	return " Llevas %s." % Datos.eur(S.money + caja_e())

func show_objective():
	var d := cap_hasta - M.reloj
	if d > 0:
		M.timeout(show_objective, d)
		return
	toast("<small>OBJETIVO</small>" + esc(objective_text()), 3200)

# ---------- misiones guiadas (1.11, 11c-misiones.js): textos y regalos del HTML (D.MISIONES); aquí, lo que mira cada una ----------
var mision_aviso: Array = []

func _con_foco() -> Array:
	return S.carpas.filter(func(c): return c is Dictionary and D.FOCOS.has(str(c.get("foco"))))

func mision_ok(id: String) -> bool:
	match id:
		"caja":
			return true if S.get("caja") else false
		"luz":
			return _con_foco().any(func(c): return c.foco != "cfl")
		"carpa":
			return S.carpas.filter(func(c): return c is Dictionary).size() >= 2
		"olor":
			return S.carpas.any(func(c): return Cultivo.kit_de(c) != "")
		"inaki":
			return true if S.flags.get("inaki") else false
		"mayor":
			return float(S.get("mDay", 0)) > 0
		"potencia":
			return _con_foco().any(func(c): return float(D.FOCOS[c.foco].w) >= 400)
		"led":
			return _con_foco().any(func(c): return D.FOCOS[c.foco].tipo == "led" and float(D.FOCOS[c.foco].w) >= 480)
		"seis":
			return S.carpas.any(func(c): return c is Dictionary and int(D.CARPAS[c.t].plazas) >= 6)
		"potente":   # 1.28: la Copa
			return D.POTENTES.any(func(k): return int(S.rec.get(k, 0)) > 0)
		"flor27":
			var H := huecos()
			for i in S.pots.size():
				var p = S.pots[i]
				if p is Dictionary and not p.get("dead") and Cultivo.fq(p) >= 1 and i < H.size() and S.carpas[H[i].c].foco == "led720":
					return true
			return false
		"copa27":
			return bud_lots(20).any(func(l): return Datos.jsround(l[1].thc * 10) / 10.0 > float(D.COPA_THC))
	return false

# ganada la Copa, las misiones que falten del capítulo 6, sin aviso ni regalo
func cerrar_copa() -> void:
	for m in D.MISIONES:
		if int(m.ch) == 6 and not S.misiones.has(m.id):
			S.misiones[m.id] = 0

func misiones_ver() -> Array:
	if not S.flags.get("kiko1"):
		return []
	return D.MISIONES.filter(func(m): return m.ch <= S.ch)

func mision_sig():
	for m in misiones_ver():
		if not S.misiones.has(m.id):
			return m
	return null

func premio_txt(m: Dictionary) -> Array:
	var r := []
	var p = m.get("p")
	if p:
		for k in p:
			r.append("%d %s" % [int(p[k]), D.PREMIO_N[k]])
	var s = m.get("s")
	if s:
		for k in s:
			r.append("%d semillas de %s" % [int(s[k]), strain(k).n.to_upper()])
	return r

# run() la llama al acabar cada guion: marca las cumplidas, da el regalo y encola el SMS
func revisa_misiones() -> void:
	revisa_itinerario()   # 1.23
	for m in misiones_ver():
		if not S.misiones.has(m.id) and mision_ok(m.id):
			S.misiones[m.id] = S.day
			mision_aviso.append(m.id)
			var p = m.get("p")
			if p:
				for k in p:
					S.items[k] += int(p[k])
			var s = m.get("s")
			if s:
				for k in s:
					add_seeds(k, int(s[k]))
	if mision_aviso.size():
		queue("mision", aviso_mision)
	revisa_logros()   # 1.27

func aviso_mision():
	while mision_aviso.size():
		var id: String = mision_aviso.pop_front()
		var m: Dictionary = {}
		for x in D.MISIONES:
			if x.id == id:
				m = x
		sfx("get")
		toast("<small>MISIÓN CUMPLIDA</small>" + m.t, 2400)
		await talk("SMS · KIKO", m.sms)
		for t in premio_txt(m):
			await got(t)
	var sg = mision_sig()
	var h := con_logro(("<small>MISIÓN</small>" + sg.t) if sg else "")
	if h != "":
		toast(h, 3200)

# ---------- logros (1.27, 11i-logros.js): textos del HTML (D.LOGROS); aquí, lo que mira cada uno ----------
var logro_aviso: Array = []

func logro_ok(id: String) -> bool:
	var F: Dictionary = S.flags
	var disc := func(l): return l.all(func(k): return true if S.disc.get(k) else false)
	match id:
		"venta":
			return S.sales > 0
		"cosecha":
			return true if F.get("harvest1") else false
		"diario":
			return true if F.get("diario") else false
		"estrella":
			return S.fenos.values().has("estrella")
		"receta":
			return rec_count() >= 1
		"recetas10":
			return rec_count() >= 10
		"jack":
			return S.rec.get("leyenda") == 2
		"mitad":
			return D.DEX.filter(func(k): return S.disc.get(k)).size() >= ceili(D.DEX.size() / 2.0)
		"genoteca":
			return disc.call(D.DEX)
		"landraces":
			return disc.call(D.LANDRACES)
		"tia":
			return disc.call(D.TIA_DEJO)
		"rosin":
			return S.rosin.size() > 0 or nevera_r() > 0
		"cata":
			return S.catas.size() > 0
		"club":
			return S.clubs.values().any(func(v): return true if v else false)
		"presidente":   # 1.32
			return S.get("aso") is Dictionary and S.aso.get("pres") == true
		"goteo":
			return S.carpas.any(func(c): return c is Dictionary and c.get("goteo"))
		"carpas":
			return S.carpas.filter(func(c): return c is Dictionary).size() >= 3
		"plazo":
			return S.ch >= 4
		"libre":
			return S.debt <= 0
		"ventas10":
			return S.sales >= 10000
		"ventas100":
			return S.sales >= 100000
		"rival":
			return S.rivalFuera.size() > 0
		"darko":
			return true if F.get("darkoFin") else false
		"plantilla":
			return S.plantilla.size() > 0
		"nave":
			return true if S.get("nave") else false
		"ruedas":
			return S.get("veh") is Dictionary and S.veh.values().any(func(d): return d and d <= S.day)
		"casa":
			return deco_v("suelo") > 0 or deco_v("pared") > 0
	return false

func logros_n() -> int:
	return D.LOGROS.filter(func(l): return S.logros.has(l.id)).size()

func revisa_logros() -> void:
	diario_revisa()   # fase 6
	for l in D.LOGROS:
		if not S.logros.has(l.id) and logro_ok(l.id):
			S.logros[l.id] = S.day
			logro_aviso.append(l.id)
			logro_play(l.id)
	if logro_aviso.size():
		queue("logro", aviso_logro)

func logro_txt() -> String:
	var l := []
	for id in logro_aviso:
		for x in D.LOGROS:
			if x.id == id:
				l.append(esc(x.t))
	logro_aviso.clear()
	if l.is_empty():
		return ""
	sfx("get")
	return "<small>%s · %d/%d</small>%s" % ["LOGROS" if l.size() > 1 else "LOGRO", logros_n(), D.LOGROS.size(), " · ".join(l)]

# el aviso h (del itinerario o de la misión, en la cola mientras corre) con los logros debajo, si el otro no viene después
func con_logro(h: String) -> String:
	if queued.has("itin") and queued.has("mision"):
		return h
	var l := logro_txt()
	return ((h + "<br>") if h != "" else "") + l if l != "" else h

func aviso_logro():
	if queued.has("itin") or queued.has("mision"):   # lo dirán ellos
		return
	var l := logro_txt()
	if l != "":
		toast(l, 2600)

# START → OBJETIVO → LOGROS
func logros_menu():
	var it := []
	for l in D.LOGROS:
		var h: bool = S.logros.has(l.id)
		it.append({"label": l.t, "right": ((Datos.fd_corto(S.logros[l.id])) if S.logros[l.id] else "HECHO") if h else null, "desc": l.d})
	it.append({"label": "Volver", "desc": ""})
	await menu(it, {"cls": "full", "title": "LOGROS", "title2": "%d de %d" % [logros_n(), D.LOGROS.size()], "desc": true})

# el plazo (1.11): Toño avisa cuando quedan 3 días y el último, con lo que llevas
func recuerdo_plazo():
	var nd := int(S.deadline - S.day)   # los días, como los cuenta Baltasar (talk_baltasar)
	var ll: float = S.money + caja_e()
	await talk("SMS · TOÑO", [("Don Baltasar quiere %s antes de que acabe el %s. Te quedan %d días." % [Datos.eur(S.due), Datos.fd(S.deadline, S.day), nd]) if nd > 0 else "Hoy es el último día para los %s de Don Baltasar." % Datos.eur(S.due)])
	await say(("Llevas %s entre el bolsillo y la caja: te faltan %s." % [Datos.eur(ll), Datos.eur(S.due - ll)]) if ll < S.due else "Llevas %s entre el bolsillo y la caja: ya lo tienes.%s Ve al bar El Ancla." % [Datos.eur(ll), " Saca lo que falte de la caja y" if S.money < S.due else ""])

# START → OBJETIVO: el del capítulo, las misiones (con lo que hay que hacer abajo) y la deuda
# (1.23: y el ITINERARIO hasta el primer plazo, hasta el capítulo 4; con A, sus pasos)
func objetivo_menu():
	while true:
		var iti: bool = S.ch <= 4
		var it := [{"label": "CAPÍTULO %d" % S.ch, "desc": "%s\n%s" % [D.CH_TITLES.get(str(S.ch), ""), objective_text()]}]
		if iti:
			it.append(itin_row())
		var ini := 0
		var mv := misiones_ver()
		for i in mv.size():
			var hecha: bool = S.misiones.has(mv[i].id)
			it.append({"label": mv[i].t, "right": "HECHA" if hecha else null, "desc": mv[i].d})
			if not hecha and ini == 0:
				ini = i + 1 + (1 if iti else 0)
		if iti and itin_sig() != null:
			ini = 1
		var plazo := ("Plazo: %s antes de que acabe el %s. Llevas %s.\n" % [Datos.eur(S.due), Datos.fd(S.deadline, S.day), Datos.eur(S.money + caja_e())]) if S.due > 0 else ""
		if Datos.CAL:   # 1.51
			var rv := recados_ver()
			it.append({"label": "RECADOS", "right": "%d/%d" % [rv.filter(func(sc): return sec_estado(sc.id) == 2).size(), rv.size()], "desc": "Lo que te piden por la comarca, según el capítulo. Pulsa A para verlos."})
		if Datos.PLAY:   # fase 6
			it.append({"label": "DIARIOS", "right": diarios_txt(), "desc": "Tres objetivos al día; cada uno da un abono. Pulsa A para verlos."})
		it.append({"label": "LOGROS", "right": "%d/%d" % [logros_n(), D.LOGROS.size()], "desc": "Lo que llevas conseguido en la partida. Pulsa A para verlos."})   # 1.27
		it.append({"label": "DEUDA", "right": Datos.eur(S.debt), "desc": plazo + "Ventas %s · Reputación %s · Calor %d %%" % [Datos.eur(S.sales), n(S.rep), Datos.jsround(S.heat)]})
		it.append({"label": "Volver", "desc": ""})
		var i: int = await menu(it, {"cls": "full", "title": "OBJETIVO", "title2": "cap. %d" % S.ch, "desc": true, "initial": ini})
		if iti and i == 1:
			await itinerario_menu()
			continue
		if i >= 0 and it[i].label == "DIARIOS":
			await diario_menu()
			continue
		if i == it.size() - 3:   # 1.27
			await logros_menu()
			continue
		if Datos.CAL and i == it.size() - (5 if Datos.PLAY else 4):   # 1.51
			await recados_menu()
			continue
		return

# ---------- los recados (1.51, lo pidió el usuario: «que haya misiones por el mapa, dependiendo del capítulo en el que estés») ----------
# D.SECUNDARIAS: gente con su «!» por la comarca desde su capítulo; piden gramos (con un THC, una índica o una landrace), extracto,
# algo de la mochila o llevar un paquete a otra persona (b). S.sec[id]: 1 en marcha (el paquete encima), 2 hecho
const ZONA_N := {"town": "Ribera Verde", "alto": "el barrio alto", "astilleros": "los astilleros", "puerto": "Puerto Viejo", "valdehierro": "Valdehierro",
	"mendialde": "Mendialde", "errotabarri": "Errotabarri", "ibarbide": "el Casco Viejo", "ensanche": "el Ensanche", "callejon": "la Kale Zaharra"}

func sec_estado(id: String) -> int:
	return int(S.get("sec", {}).get(id, 0)) if S.get("sec") is Dictionary else 0

func sec_def(id: String):
	for sc in D.get("SECUNDARIAS", []):
		if sc.id == id:
			return sc
	return null

func sec_marca(eid: String) -> bool:
	var b := eid.begins_with("secb_")
	var st := sec_estado(eid.substr(5 if b else 4))
	return st == 1 if b else st == 0

func sec_pon(id: String, v: int) -> void:
	if not (S.get("sec") is Dictionary):
		S.sec = {}
	S.sec[id] = v

func sec_lotes(sc: Dictionary) -> Array:
	var P_: Dictionary = sc.pide
	if P_.tipo == "extr":
		return rosin_lots(float(P_.g))
	var l := bud_lots(float(P_.g), float(P_.get("thc", 0)))
	if P_.get("ind"):
		l = l.filter(func(x): return Datos.ind_de(S, lot_sid(x[0])) >= int(P_.ind))
	if P_.get("land"):
		l = l.filter(func(x): return D.STRAINS.has(lot_sid(x[0])) and D.STRAINS[lot_sid(x[0])].get("tipo") == "landrace")
	return l

func sec_premio(sc: Dictionary) -> void:
	var R: Dictionary = sc.premio
	S.money += float(R.get("e", 0))
	S.rep += int(R.get("rep", 0))
	S.heat = minf(100, S.heat + float(R.get("calor", 0)))
	sfx("coin")
	await got(Datos.eur(R.get("e", 0)))
	if R.has("seeds"):
		add_seeds(R.seeds[0], int(R.seeds[1]))
		await got("%d semillas de %s" % [int(R.seeds[1]), D.STRAINS[R.seeds[0]].n.to_upper()])
	sec_pon(sc.id, 2)
	toast("Recado hecho: " + sc.t, 1600)

func talk_sec(eid: String) -> void:
	var b := eid.begins_with("secb_")
	var sc = sec_def(eid.substr(5 if b else 4))
	if sc == null:
		return
	var st := sec_estado(sc.id)
	var N: String = (sc.b if b else sc.a).n
	if st == 2:
		await say(sc.ya, N)
		return
	if b:   # el que recibe el paquete
		await talk(N, sc.get("txtb", ["Trae."]))
		await talk(N, sc.fin)
		await sec_premio(sc)
		update_hud()
		return
	if st == 1:
		await say("Ya sabes: a %s, en %s. Date prisa." % [sc.b.n.to_lower(), ZONA_N.get(sc.b.map, sc.b.map)], N)
		return
	await talk(N, sc.txt)
	var P_: Dictionary = sc.pide
	if P_.tipo == "lleva":
		if await ask("¿Llevas el paquete?", ["Sí, dámelo", "Ahora no"], N) != 0:
			await say("Tú verás. Aquí sigo.", N)
			return
		sec_pon(sc.id, 1)
		await got("el paquete para " + sc.b.n.to_lower())
		return
	if P_.tipo == "item":
		if int(S.items.get(P_.item, 0)) < int(P_.n):
			await say("No llevas nada. Si vuelves con algo, aquí estaré.", N)
			return
		if await ask("¿Se lo das?", ["Sí", "Ahora no"], N) != 0:
			return
		S.items[P_.item] = int(S.items[P_.item]) - int(P_.n)
		await talk(N, sc.fin)
		await sec_premio(sc)
		update_hud()
		return
	var L := sec_lotes(sc)
	if L.is_empty():
		await say("Cuando tengas lo que te pido, vuelve.", N)
		return
	var items: Array = L.map(rosin_item if P_.tipo == "extr" else lot_item)
	items.append({"label": "Ahora no"})
	var i: int = await menu(items, {"cls": "right", "title": "¿Qué le das?"})
	if i < 0 or i >= L.size():
		await say("No pasa nada. Aquí estaré.", N)
		return
	if P_.tipo == "extr":
		use_rosin(L[i][0], float(P_.g))
	else:
		use_buds(L[i][0], float(P_.g))
	await talk(N, sc.fin)
	await sec_premio(sc)
	update_hud()

# en START → OBJETIVO: los de tu capítulo y los hechos
func recados_ver() -> Array:
	return D.get("SECUNDARIAS", []).filter(func(sc): return int(S.ch) >= int(sc.ch))

func recados_menu() -> void:
	var it := []
	for sc in recados_ver():
		var st := sec_estado(sc.id)
		var donde: String = ZONA_N.get(sc.a.map if st != 1 else sc.b.map, "")
		it.append({"label": sc.t, "right": "HECHO" if st == 2 else ("EN MARCHA" if st == 1 else donde), "desc": sc.d + (("\nLleva el paquete a %s (%s)." % [sc.b.n.to_lower(), donde]) if st == 1 else "")})
	if it.is_empty():
		it.append({"label": "Nada todavía", "desc": "Los recados salen por la comarca según el capítulo: busca a la gente con el «!»."})
	it.append({"label": "Volver", "desc": ""})
	await menu(it, {"cls": "full", "title": "RECADOS", "desc": true})

# ---------- Julen y el itinerario (1.23, 11h-guia.js): textos del HTML (D.ITINERARIO, D.JULEN, D.MINERAL_ORG); aquí, lo que mira cada paso ----------
var itin_aviso: Array = []

func itin_ok(id: String) -> bool:
	var F: Dictionary = S.flags
	var h1: bool = true if F.get("harvest1") else false
	match id:
		"bus":
			return not llegando()
		"carta":
			return true if F.get("letter") else false
		"kiko":
			return true if F.get("kiko1") else false
		"julen":
			return (true if F.get("julen1") else false) or h1
		"plantar":
			return S.pots.any(func(p): return p is Dictionary) or h1
		"regar":   # o riego automático
			return (true if F.get("gRiego") else false) or h1 or (S.pots.any(func(p): return p is Dictionary) and S.carpas.any(func(c): return c is Dictionary and (true if (c.get("goteo") or c.get("garrafas")) else false)))
		"veg":   # ya en flor, no toca
			return (true if (F.get("gVeg") or F.get("gFlor") or F.get("harvest1")) else false) or S.pots.any(func(p): return p is Dictionary and (p.prog >= .65 or (true if (p.get("fv") or p.get("fert")) else false)))   # p.fv, p.fert: partidas de antes de gVeg
		"flor":
			return (true if F.get("gFlor") else false) or h1 or S.pots.any(func(p): return p is Dictionary and (true if p.get("fert") else false))
		"cosecha":
			return h1
		"vender":
			return S.sales > 0
		"ventas":
			return S.ch >= 3
		"baltasar":
			return (true if F.get("metB") else false) or S.ch >= 4
		"juntar":
			return S.ch >= 4 or (S.ch == 3 and S.due > 0 and S.money + caja_e() >= S.due)
		"pagar":
			return S.ch >= 4
	return false

func itin_hecho(p: Dictionary) -> bool:
	return S.itin.has(p.id) or itin_ok(p.id)

func itin_sig():
	for p in D.ITINERARIO:
		if not itin_hecho(p):
			return p
	return null

func itin_n() -> int:
	return D.ITINERARIO.filter(func(p): return itin_hecho(p)).size()

func julen_aqui() -> bool:
	return S.map == "home" and (true if S.flags.get("julen1") else false) and not S.flags.get("harvest1")   # ya te ha saludado y sigue en el piso

# lo que toca ahora, con lo que te falta para hacerlo
func paso_cultivo() -> String:
	var sg = itin_sig()
	if sg == null:
		return pick(D.JULEN.tips)
	var sin := func(ks: Array) -> bool: return not ks.any(func(k): return S.items.get(k, 0) > 0)
	var t: String = sg.d
	if sg.id == "plantar" and not S.seeds.values().any(func(v): return v > 0):
		t += " Si no te quedan semillas, mi aita tiene."
	elif (sg.id == "veg" and sin.call(["fertv", "ofertv"])) or (sg.id == "flor" and sin.call(["fert", "ofert"])):
		t += " No te queda: mi aita lo vende en el growshop."
	elif (sg.id == "veg" or sg.id == "flor") and sin.call(["phm", "ophm"]):
		t += " Y te falta pH−: lo tiene mi aita."
	return t

func talk_julen():
	var N := "JULEN"
	if not S.flags.get("julen1"):
		await talk(N, D.JULEN.tarde if S.flags.get("harvest1") else D.JULEN.hola)
		S.items.ofertv += 2
		await got("2 dosis de ORTUA BIO CRECIMIENTO")
		S.items.ophm += 4
		await got("4 dosis de pH− ORTUA BIO")
		await talk(N, D.JULEN.ph + D.MINERAL_ORG + ([] if S.flags.get("harvest1") else D.JULEN.aqui))
		S.flags.julen1 = true
		return
	if not S.flags.get("harvest1"):
		var c: int = await ask("¿Qué pasa?", ["¿Qué hago ahora?", "Mineral u orgánico", "Nada"], N)
		if c == 0:
			await say(paso_cultivo(), N)
		elif c == 1:
			await talk(N, D.MINERAL_ORG)
		else:
			await say("Aquí estoy si me necesitas.", N)
		return
	var c: int = await ask("¿Qué tal la cosecha?", ["Un consejo", "Mineral u orgánico", "Nada"], N)
	if c == 0:
		await say(pick(D.JULEN.tips), N)
	elif c == 1:
		await talk(N, D.MINERAL_ORG)
	else:
		await say("Agur. Saluda a las plantas de mi parte.", N)

# run() → revisa_misiones → aquí: apunta los pasos hechos y avisa del último (y del siguiente); si Julen está delante, lo comenta
func revisa_itinerario() -> void:
	if not S.has("itin"):
		return
	var I: Array = D.ITINERARIO
	for i in I.size():
		if not S.itin.has(I[i].id) and itin_ok(I[i].id):
			S.itin[I[i].id] = S.day
			if i >= int(D.ITIN_MUDO):
				itin_aviso.append(I[i].id)
	if itin_aviso.size():
		queue("itin", aviso_itin)

func aviso_itin():
	var ids := itin_aviso.duplicate()
	itin_aviso.clear()
	var p: Dictionary = {}
	for x in D.ITINERARIO:
		if x.id == ids[-1]:
			p = x
	var sg = itin_sig()
	toast(con_logro("<small>ITINERARIO · %d/%d</small>%s" % [itin_n(), D.ITINERARIO.size(), p.t] + ("<br>Ahora: " + sg.t if sg != null else "")), 2800)
	var j := ids.map(func(id): return D.JULEN.ok.get(id)).filter(func(x): return x != null)
	if julen_aqui() and j.size():
		await say(j[-1], "JULEN")

# START → OBJETIVO → ITINERARIO
func itin_row() -> Dictionary:
	var sg = itin_sig()
	var I: Array = D.ITINERARIO
	var i: int = I.find(sg) if sg != null else -1
	var desc := "Hecho: el primer plazo, pagado."
	if sg != null:
		desc = "Ahora: %s. %s" % [sg.t, sg.d] + (("\nDespués: %s." % I[i + 1].t) if i + 1 < I.size() else "")
	return {"label": "ITINERARIO", "right": "%d/%d" % [itin_n(), I.size()], "itin": 1, "desc": desc}

func itinerario_menu():
	var sg = itin_sig()
	var I: Array = D.ITINERARIO
	var it := []
	for p in I:
		it.append({"label": p.t, "right": "HECHO" if itin_hecho(p) else ("AHORA" if p == sg else null), "desc": p.d})
	it.append({"label": "Volver", "desc": ""})
	await menu(it, {"cls": "full", "title": "ITINERARIO", "title2": "%d/%d" % [itin_n(), I.size()], "desc": true, "initial": maxi(0, I.find(sg) if sg != null else 0)})

func facturado() -> float:
	return maxf(0, S.sales - S.get("imp0", 0))

func imperio_nivel() -> int:
	var nv := 0
	for i in D.IMPERIO.size():
		if facturado() >= D.IMPERIO[i].meta:
			nv = i
	return nv

func check_story():
	if S.ch == 1 and S.flags.get("harvest1"):
		if S.flags.get("julen1"):   # 1.23: se vuelve al growshop (antes del capítulo, que lo quita del piso)
			await talk("JULEN", D.JULEN.adios)
		await chapter(2)
		spawn_clients()
		await talk("SMS · KIKO", ["Primera cosecha. Bien hecho.", "La gente que busca material lleva un $ encima. Puedes venderles en la calle.", "Cuanto más vendas, más se fijará la policía: es el CALOR. Y de noche hay quien roba."])
		await lineas_nuevas()
		show_objective()
	if S.ch == 2 and S.sales >= D.META_VENTAS:
		S.due = int(D.PLAZOS["3"])   # el plazo, desde ya (1.10)
		S.deadline = S.day + dias_plazo(3)
		if Datos.PLAY:
			S.due0 = S.due
		S.flags.tono = S.day
		await chapter(3)
		await say("Un hombre enorme en chándal te corta el paso.")
		await talk("TOÑO", ["Tú vives en el piso de Maite, ¿no?", "Don Baltasar quiere verte. En el bar El Ancla. Hoy.", "Y ve contando: tienes %s días para el primer pago." % dias_letra(dias_plazo(3)), "No me hagas venir a buscarte."])
		await lineas_nuevas()
		show_objective()
	if S.ch >= 8 and imperio_nivel() > S.get("impN", 0):
		S.impN = imperio_nivel()
		var r: Dictionary = D.IMPERIO[S.impN]
		sfx("get")
		toast("<small>TU IMPERIO</small>" + r.n, 2800)
		await talk("SMS · IÑAKI", ["Se corre la voz: %s vendidos desde que pagaste a Baltasar." % Datos.eur(facturado()), "Desde hoy te cargo hasta %s al día en el barco." % _kg(int(r.mayor))])
		show_objective()
	if S.ch == 4 and S.flags.get("lab") and rec_count() >= 2:
		S.due = int(D.PLAZOS["5"])
		S.deadline = S.day + dias_plazo(5)
		if Datos.PLAY:
			S.due0 = S.due
		await chapter(5)
		await talk("SMS · TOÑO", ["Don Baltasar quiere %s en %s días." % [Datos.eur(D.PLAZOS["5"]), dias_letra(dias_plazo(5))], "Otra cosa: un tal SARGENTO MOLINA pregunta por ti en la plaza."])
		show_objective()
	# (lo pidió el usuario: «no existe mapa y sitio del bajo de las setas»; con Datos.CAL): nada te decía dónde estaba. Con
	# Ibarbide abierta, una vez, el SMS de Julen con el sitio (también en MÓVIL → Mapa y en el cartel de la Kale Zaharra)
	if Datos.CAL and not Datos.PLAY and S.ch >= int(D.SETAS.ch) and S.get("setas") == null and not S.flags.get("setasSms"):
		S.flags.setasSms = S.day
		await talk("SMS · JULEN", D.SETAS_SITIO.sms)
	if Datos.CAL and D.has("MAR") and S.ch >= int(D.MAR.ch) and S.get("mar") == null and not S.flags.get("koldoSms"):   # 1.51: el muelle
		S.flags.koldoSms = S.day
		await talk("SMS · KOLDO", ["Soy Koldo, del muelle de Puerto Viejo. Fui amigo de tu tía Maite: tengo una cosa suya para ti.", "Al final de la plaza del puerto, a la derecha, el muelle de la cofradía. Estoy en la acera, delante de los barcos."])

# E5 (fase 3): todo lo que cambia, antes del primer aviso (guardada a medias, no se cuenta dos veces)
# U3 (fase 5, con Datos.PLAY): el recargo, sobre lo que pedía el plazo (sin interés compuesto) y hasta RESCATE.tope; el primer impago de la partida,
# el rescate de Toño (RESCATE: la mitad de recargo y más días a cambio de un recado); el embargo, como mucho uno por capítulo
func dias_plazo(ch: int) -> int:
	if Datos.PLAY and D.has("PLAZO_DIAS"):
		return int(D.PLAZO_DIAS[str(ch)])
	return 10 if ch == 5 else 7

func dias_letra(n: int) -> String:
	return {7: "siete", 10: "diez", 14: "catorce", 16: "dieciséis", 20: "veinte"}.get(n, str(n))

func penalty_event():
	var play: bool = Datos.PLAY and D.has("RESCATE")
	var base: float = float(S.get("due0", S.due)) if play else float(S.due)
	var rescate: bool = play and not S.flags.get("rescate")
	var it := Datos.jsround(base * D.INTERES * (float(D.RESCATE.interes) if rescate else 1.0) / 100) * 100
	if play:   # los recargos de un plazo, como mucho RESCATE.tope de lo que pedía
		it = maxi(0, mini(it, int(base * (1 + float(D.RESCATE.get("tope", 9.0)))) - int(S.due)))
	S.vencidos += 1
	S.hp = maxi(1, S.hp - 15)
	S.due += it
	S.debt += it
	S.deadline = S.day + (int(D.RESCATE.dias) if rescate else 5)
	var embarga = null
	if rescate:
		S.flags.rescate = true
		S.vencidos -= 1
	elif S.vencidos >= 3 and not (play and int(S.get("emb_ch", 0)) == int(S.ch)):
		S.vencidos = 0
		if play:
			S.emb_ch = S.ch
		embarga = embargo_aplica()
	if rescate:
		await say("TOÑO te estaba esperando.")
		await talk("TOÑO", ["Don Baltasar dice que llegas tarde. Por ser la primera vez, te deja arreglarlo.", "Le llevas un paquete a Puerto Viejo y te da %d días más. Solo son %s de recargo." % [int(D.RESCATE.dias), Datos.eur(it)]])
		sfx("hurt")
		await say("La deuda del plazo sube a %s. Nuevo límite: %s." % [Datos.eur(S.due), Datos.fd(S.deadline, S.day)])
		return
	await say("TOÑO te estaba esperando.")
	await talk("TOÑO", ["Don Baltasar dice que llegas tarde.", "Son %s más de intereses. Y esto, para que no se te olvide." % Datos.eur(it)])
	sfx("hurt")
	await say("La deuda del plazo sube a %s. Nuevo límite: %s." % [Datos.eur(S.due), Datos.fd(S.deadline, S.day)])
	if embarga != null:
		await embargo(embarga)

# al tercer plazo vencido (1.10), Toño se lleva la carpa más grande del fondo o de junto a la cama (B o C), con su foco, sus
# extras y sus plantas; sin ninguna de las dos, la mitad del dinero que llevas encima
func area_carpa(ci: int) -> float:
	var cm: Array = D.CARPAS[S.carpas[ci].t].cm
	return cm[0] * cm[2]

func quitar_carpa(ci: int) -> void:
	var antes := []
	for h in huecos():
		antes.append("%d:%d" % [int(h.c), int(h.j)])
	var pots: Array = S.pots
	var mac: Array = S.macetas
	S.carpas[ci] = null
	var np := []
	var nm := []
	for h in huecos():
		var j := antes.find("%d:%d" % [int(h.c), int(h.j)])
		np.append(pots[j] if j >= 0 and pots[j] else null)
		nm.append(mac[j] if j >= 0 and mac[j] else "plastico7")
	S.pots = np
	S.macetas = nm
	montar_casa()

func embargo_aplica() -> Dictionary:   # E5: lo que se lleva, antes de decirlo
	var ci := -1
	for c in [1, 2]:
		if c < S.carpas.size() and S.carpas[c] and (ci < 0 or area_carpa(c) > area_carpa(ci)):
			ci = c
	if ci >= 0:
		var nc: String = D.CARPAS[S.carpas[ci].t].n
		quitar_carpa(ci)
		return {"nc": nc}
	var e := int(floor(S.money / 2.0))
	S.money -= e
	return {"e": e}

func embargo(em = null) -> void:
	if em == null:
		em = embargo_aplica()
	await talk("TOÑO", ["Tres plazos tarde. Don Baltasar se cobra en especie."])
	sfx("bad")
	if em.has("nc"):
		await say("TOÑO se lleva tu %s, con su foco y sus plantas." % em.nc)
	else:
		await say("TOÑO te vacía los bolsillos: se lleva %s." % Datos.eur(em.e))

# el aviso de la orden de registro (1.11): un día antes de la redada
func aviso_orden():
	sfx("bad")
	var L := ["Me dice uno de la comisaría que mañana entran en tu piso con orden de registro.", "Esta noche, el dinero y los cogollos a la caja o fuera de casa. Las plantas no se pueden esconder."]
	if S.ch >= 5:
		L.append("O paga a Molina, que aún estás a tiempo.")
	await talk("SMS · KIKO", L)

# la redada (1.11): lo de fuera y las plantas, siempre; la caja fuerte, nunca. La multa (multa_redada) sale de lo de fuera y, si no
# llega, de la caja. Lo de encima, solo si estás en casa (1.13)
func raid_event():
	S.orden = 0
	if S.protect:
		S.heat = 50
		await talk("SMS · MOLINA", ["Esta noche había orden de entrada en tu piso. La he parado.", "Baja el ritmo."])
		return
	# E4 (fase 3): todo lo que se llevan, antes del primer aviso (si se cierra la app a medias, la redada ya ha pasado)
	var casa: bool = S.map == "home" or S.map == "camarote"
	var ne: int = S.esquejes.size() + S.bandejas.size()
	var gc := int(floor(cam_g()))   # 1.43.6: el camarote no está escondido: se lo llevan
	var g := int(floor(total_buds() if casa else 0.0)) + gc   # lo de encima y la nevera (1.36; la caja fuerte, no)
	var ro: float = (total_rosin() if casa else 0.0) + nevera_r()
	var hs := huecos()
	var npl := 0
	for p in S.pots:
		if p and not p.get("dead"):
			npl += 1
	var eq := []
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if c == null:
			continue
		var con := false
		for i in hs.size():
			if hs[i].c == ci and S.pots[i] and not (true if S.pots[i].get("dead") else false):
				con = true
		if not con:
			continue
		for k in D.EXTRAS:
			if c.get(k):
				var nm: String = D.EXTRAS[k].n.to_lower()
				if not eq.has(nm):
					eq.append(nm)
				c.erase(k)
				if k == "goteo":
					c.erase("dep")
				if k == "garrafas":
					c.erase("gar")
	var np := []
	for p in S.pots:
		np.append(null)
	S.pots = np
	if casa:
		S.buds = {}
		S.rosin = {}
	if S.get("nevera") != null:
		S.nevera.rosin = {}
	if gc:
		S.cam.buds = {}
	S.esquejes = []
	S.bandejas = []
	S.heat = D.CALOR_REDADA
	var multa := multa_redada(npl, g + Datos.jsround(ro / D.ROSIN.rend))   # el rosin, como la flor de la que sale
	var fine: float = multa - pagar_casa(multa)
	var gs := -1.0
	if sot_ya() and (S.sot.bandejas.size() or float(S.sot.g) >= 1 or S.sot.get("fr", []).size()):   # 1.51: el sótano, también
		gs = float(S.sot.g)
		for f in S.sot.get("fr", []):
			gs += float(f.g)
		S.sot.bandejas = []
		S.sot.g = 0
		S.sot.fr = []
		S.sot.erase("gv")
	music("redada")
	sfx("bad")
	await say("REDADA. La policía entra en tu piso con una orden de registro.")
	var lo := []
	if npl:
		lo.append("todas las plantas")
	if ne:
		lo.append("los esquejes" if ne > 1 else "el esqueje")
	if g:
		lo.append(("%d g (%d del camarote)" % [g, gc]) if gc else "%d g" % g)
	if ro:
		lo.append(rosin_txt(ro))
	await say("%s. Multa: %s%s." % [("Se llevan " + _lista(lo)) if lo.size() else "No encuentran nada que llevarse", Datos.eur(multa), (" (pagas %s: no tienes más)" % Datos.eur(fine)) if fine < multa else ""])
	if eq.size():
		await say("Y el equipo de las carpas con plantas: " + ", ".join(eq) + ".")
	if gs >= 0:
		await say("Bajan al sótano: se llevan las bandejas%s." % ((" y " + g_txt(gs) + " de setas") if gs >= 1 else ""))
	await say("La caja de detrás del diploma ni la ven. Las semillas no son delito: se quedan." if S.get("caja") != null else "Las semillas no son delito: se quedan.")
	await say("Toca empezar de nuevo. Y vender menos una temporada.")
	music(map_music())

func ending() -> void:
	await fade(1)
	music("final")
	endcard_on = true
	endcard_pon(["DEUDA SALDADA", "Has saldado los %s de tu tía Maite en %s días." % [Datos.eur(D.DEUDA), n(S.day)], "Variedades: %d · Ventas totales: %s" % [disc_count(), Datos.eur(S.sales)],
		"Ahora empieza tu imperio: cuanto más factures, más carga Iñaki en el barco.\n¿Completarás la GENOTECA? ¿Conseguirás la JACK HERER?", "Pulsa A"])
	await fade(0)
	sfx("get")
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "START":
			pop()
			pr.res())
	await Motor.espera(pr)
	await fade(1)
	endcard_on = false
	endcard_pon(null)
	music(map_music())
	await fade(0)
	await chapter(8)
	show_objective()

# exportar la partida (1.11, exportar de 12-menus): el JSON de S al portapapeles
var exportado := ""   # lo último copiado (las pruebas lo leen: sin pantalla no hay portapapeles)

# ---------- la ficha de la variedad (1.51, lo pidió el usuario: «dependiendo de la variedad o linaje, las hojas son diferentes») ----------
# una lámina con la hoja de abanico de la variedad (hoja.gd), su nombre y su grupo (sativa, híbrido de dominancia sativa,
# equilibrado, de dominancia índica, índica); izquierda y derecha pasan a la anterior y la siguiente; A o B cierran. FICHA_V = {l, i}
var FICHA_V = null

const COLOR_GRUPO := ["#c07a1e", "#8a9a2a", "#5a8a5a", "#7a4a8a", "#5a2a7a"]

# ---------- combate (13-combate) ----------
static func hp_col(f: float) -> Color:
	return Color("#58d080") if f > .5 else (Color("#f0c040") if f > .2 else Color("#f05050"))

static func g_txt(g: float) -> String:
	return "%d g" % int(floor(g))

# ---------- la pantalla del móvil (1.51, lo pidió el usuario: «que fuese una pantalla de un móvil, con el diseño del juego, estilo a
# cuando abres la caja fuerte»): la carcasa y las aplicaciones a mano (tools/sprites/a-mano/movil.py, misc:mv-*), arriba la hora, la
# cobertura y la batería, la hora en grande y una rejilla de 3 × 3; flechas, A abre y B cuelga. MOVIL_V = {ops, i}
var MOVIL_V = null

var ult_app := ""

const APP_MOVIL := {"Llamar": "llamar", "Pedir a Kiko": "kiko", "Mensajes": "sms", "Gente": "gente", "Plantilla": "plantilla", "Banca": "banca",
	"Tienda online": "tienda", "Calendario": "cal", "Mapa": "mapa"}

const CIFRAS := ["111101101101111", "010110010010111", "111001111100111", "111001111001111", "101101111001001", "111100111001111",
	"111100111101111", "111001010010010", "111101111101111", "111101111001111"]

# El dibujo del tiempo, 13 × 9 (. vacío, s sol, n nube, m sombra de la nube, g gota, r rayo, b nieve, f niebla)
const ICONO_TIEMPO := {
	"sol": ["......s......", "..s...s...s..", "....sssss....", "...sssssss...", "ssssssssssss.", "...sssssss...", "....sssss....", "..s...s...s..", "......s......"],
	"nubes": ["...s..s......", ".....sss.....", "..ssssnnn....", "...ssnnnnn...", ".ssnnnnnnnnn.", "..nnnnnnnnnnn", "..nnnnnnnnnnn", "...mmmmmmmmm.", "............."],
	"lluvia": [".....nnn.....", "...nnnnnnn...", "..nnnnnnnnnn.", ".nnnnnnnnnnnn", ".nnnnnnnnnnnn", "..mmmmmmmmmm.", "..g..g..g..g.", ".g..g..g..g..", "............."],
	"niebla": ["....nnnnn....", "..nnnnnnnnn..", "..mmmmmmmmm..", ".............", "ffffffffffff.", ".............", ".ffffffffffff", ".............", "fffffffffff.."],
	"tormenta": [".....mmm.....", "...mmmmmmm...", "..mmmmmmmmmm.", ".mmmmmmmmmmmm", "..mmmmrmmmmm.", "....g.rr..g..", "...g..rrr.g..", "........r....", "........r...."],
	"nieve": [".....nnn.....", "...nnnnnnn...", "..nnnnnnnnnn.", ".nnnnnnnnnnnn", "..mmmmmmmmmm.", ".b...b...b...", "...b...b...b.", ".b...b...b...", "............."]}

const COLOR_TIEMPO := {"s": "#f8c030", "n": "#e4ecf4", "m": "#9aa8b8", "g": "#6ab0f0", "r": "#f8e060", "b": "#ffffff", "f": "#b8c4cc"}

# Begoña (la vecina): consejos, un regalo al día y, con confianza y desde el capítulo 3, la jardinera
const BEGONA_TIPS := ["Bajo una lámpara las plantas beben mucho. Riégalas a diario, majo.", "Si se te ponen amarillas las hojas de abajo, les falta agua o abono.", "Tu tía siempre tenía el piso oliendo a limón. Ahora sé por qué."]

# los clubs cannábicos (CLUBS): el carné, vender un lote al día, comprar 10 g y encargos de semillas
func precio_club(thc: float) -> float:
	return 3 + thc * .15

# (lo pidió el usuario: «que se pueda probar todo tipo de cogollos y extracción… hasta un límite lógico claro»): catar cualquier
# lote, cogollos o extracto, en la cantidad que elijas hasta CATA_MAX de una vez (un porro bien cargado, 1 g; de extracto, 0,5 g)
const CATA_MAX := {"b": 1.0, "r": 0.5}

const CATA_PASOS := {"b": [0.1, 0.25, 0.5], "r": [0.1, 0.2, 0.3]}

# ---------- la plantilla (1.19, 11f-plantilla): gente del barrio que trabaja para ti ----------
func ficha_gente(w: Dictionary) -> String:
	return "Labia %d · cuidado %d · lealtad %d" % [w.lab, w.cui, w.lea]

# el billar (1.35, talkBillar de 11j-locales): una partida corta a la bola 8, con el tiro elegido (TIROS) y dos barras, la dirección
# y la fuerza; quien mete, sigue; gana quien mete la negra con las suyas dentro. MESA_B: la mesa que se ve mientras dura (pinta.gd)
var TIRO = null   # la barra mientras apuntas: {t0, f: "dir" o "fuerza", a}, en el reloj del juego (pinta.gd la dibuja)

var MESA_B = null

func disco_abierta() -> bool:
	return S.min >= D.DISCO.abre or S.min < D.DISCO.cierra

# ---------- el bajo de las setas (1.20, 11g-setas): el local clandestino de la Kale Zaharra ----------
# (lo pidió el usuario: «antes de… alquilar el bajo… habilitar el sótano de la casa»): las setas, en el bajo de Txomin
# (S.setas) o en el sótano de casa (S.sot, la misma forma sin recibo); SL() es el de donde estás (o, con Txomin, el que eliges: _SOT)
var _SOT := false

func es_sot() -> bool:
	return S.map == "sotano" or _SOT

func nom_cepa(k: String) -> String:
	return D.CEPAS.v[k].n

# ---------- la caja fuerte y la nevera por dentro (1.36, 11m-almacen) ----------
# Al abrirlas se ven por dentro (pinta.gd, _encima): en la caja, los fajos y los tarros de cogollos según lo lleno que está (por
# porcentajes); en la nevera, un piso por tipo de extracción (TIPOS_EXTR) con sus tarros de mayor a menor THC. Las flechas eligen
# (las filas corren en carrusel), A saca o abre el menú del dinero y B cierra. ALMACEN = {t: "caja" | "nevera", i: el elegido}
var ALMACEN = null

# ---------- el carro de esquejes por dentro (1.40, lo pidió el usuario: «que no sea un menú») ----------
# dos bandejas de 12 tacos (6 × 2), la de arriba y la de abajo, con sus tubos T5 y su tapa; los esquejes de S.bandejas van por
# orden en los tacos (0-11 arriba, 12-23 abajo). Flechas eligen, A el taco, B cierra. CARRO_V = {i: el elegido}
var CARRO_V = null

const CARRO_W := 116

const CARRO_H := 108

# un esqueje en su taco, dibujado a mano a 1 px (k: el tamaño del píxel), como la referencia del usuario: el tallo largo, dos hojas
# de cannabis abiertas a los lados (X, del color de hoja de la variedad; D, los peciolos y el arranque, más oscuros), el brote
# de arriba y dos brotes en el tallo (L, más claros; T, el tallo); cx: el tallo; y: donde el tallo entra en el taco.
# El del último día, amarillento (seco)
const CLON := [
	"......L.L......",
	"...X..LLL..X...",
	".X.XX.LLL.XX.X.",
	"..XXX..L..XXX..",
	"XX.DXX.L.XXD.XX",
	"..XXDDXTXDDXX..",
	".XX...DTD...XX.",
	"X......T......X",
	".....L.T.......",
	"....LLLT.......",
	".....L.T.L.....",
	".......TLLL....",
	".......T.L.....",
	".......T.......",
	".......T......."]

const CLON_MINI := ["..X..", "X.X.X", ".XXX.", "..T.."]

# el elegido, en grande (48 × 40, 1 px): cuatro hojas de cannabis de 7 dedos, las dos de atrás en sombra (K), y dos brotes;
# lo saca tools/sprites/a-mano/esqueje.py (L haz, X hoja, D nervio y envés, K sombra, T tallo)
const CLON_G := [
	"...............................D................",
	"................D.............DX...D............",
	"............D...DX.....XL.....DX..DX............",
	"............DX..DX.....XL...X.DX.DX.............",
	".............DX.DX.D...XL...DXDXDDX..DD.........",
	".........DX..DKXDXDXL..XL..XDXDXDXDDDX..........",
	"..........DXXXDXDXDXDL.XL.XDXDDXXDDXX...........",
	"...........DDXXKDDXDXDLXLXXLDDKDDDX..L....X.....",
	".....L....X..DDDKDDXXXLXLXL.DDDDDDDDXL..XXL.....",
	".....XLL..XLXXXDKDXXLLXXXLXXX.TKDDXXXL.XXL......",
	"......XLL.XLDDDDDT..XXXDXXLL.T..XXDXXLXXL.......",
	".......XLLXLLXDD..T...XXTL..TT...XLXXLXLL.......",
	".......XXLXLLXL....T....T...T.....XXLXLL.XXXXXX.",
	".XXLLLL.XXLXXL......T...T..T......XXXDXXXXLLL...",
	"...XXXLLLLDXXL.......T..T.T........XDXXLLL......",
	"......XXXXXDD.........T.TT.....TTTTTDXXXX.......",
	".......LLLLDDTTTTTTTTT.TTTTTTT.....LXXLLXXXX....",
	"....LLLXXXLDX..........TT..........LXLX.LLLXX...",
	"...LXXXX.LXLX...........T..........LXLLX....LL..",
	"..XX....LXXLX...........T...........X.LDX.......",
	".......LDX.L............T.XL.XL........LX.......",
	".......LX...............T.XLXL..................",
	"........................T.XXXX..................",
	"........................T.TDLL..................",
	"........................TT......................",
	"........................T.......................",
	".................XL.XL..T.......................",
	"..................XLXL..T.......................",
	"..................LLDL..T.......................",
	"..................XXXT..T.......................",
	"......................TTT.......................",
	"........................T.......................",
	"........................T.......................",
	"........................T.......................",
	"........................T.......................",
	"........................T.......................",
	"........................T.......................",
	"........................T.......................",
	"........................T.......................",
	"........................T......................."]

# las raíces que asoman por debajo del taco, una fila más cada medio día en la bandeja
const RAICES := [
	"..R..R..R...",
	".R..R.R..R..",
	"R..R...R..R.",
	"..R..R...R..",
	".R..R..R...R",
	"R......R...."]

# ---------- el bajo de las setas a la vista (1.43.9, lo pidió el usuario: «que puedas entrar al bajo y veas las setas crecer») ----------
# las tres estanterías de rejilla del bajo con sus dos bandejas (2r abajo, 2r + 1 arriba, como bandejas_balda), dibujadas a mano por
# rectángulos: el micelio blanco que va cubriendo el sustrato día a día (y hora a hora), los primordios y las setas que crecen y abren
# el sombrero (genéricas, pardas: sin especie ni método), las gotas de la tapa por la humedad, lo contaminado y lo seco. A la
# derecha, la elegida en grande con su humedad y lo que le falta. A: lo de las bandejas (bajo_menu) · B: cerrar
var SETAS_V = null   # {i}: la bandeja elegida (0-5)

const BAJO_W := 208

const BAJO_H := 108

# ---------- el bajo entero (1.44, lo pidió el usuario: «donde se cultivan, se secan, almacenan y se crean microdosis y comestibles») ----
# Lo recogido se tiende a secar (S.setas.fr: [{g, d}]) en la malla (SETAS_PRO.seca días) o en el deshidratador (sech); seco, pasa al
# armario (S.setas.g, al amanecer en setas_dia). En la mesa de trabajo, con la encapsuladora (enc) o los moldes (mol), un lote de
# SETAS_PRO.lote g secos hace una caja de microdosis (mc) o de comestibles (cc); Txomin lo compra en la puerta. Nada de método ni de
# dosis: cajas y lotes. La redada (setas_dia) se lo lleva todo.
var ARM_V = null   # {}: el armario abierto

# ---------- el calendario y el mapa de la comarca (1.42, lo pidió el usuario; croquis.gd) ----------
var CAL_V = null    # {y, m}: el mes que se ve

var MAPA_V = null   # {i}: el pueblo elegido (Croquis.ORDEN)

# ---------- las bandejas de clones de la nave (1.43, lo pidió el usuario: «en la nave debería haber bandejas de clones») ----------
# Antes de pasar una mesa a 12/12 (FLOR_MESA), su navero le corta los esquejes a las plantas en crecimiento y los pincha en una bandeja
# de D.NAVE.tacos tacos (S.nave.bc: {m: la mesa, k, f, d: el día del corte}), con su tapa, bajo los T5 del carro; enraízan en NAVE.raiz
# días (al ritmo del juego, como las mesas: un ciclo entero son unos pocos días) y, cuando la mesa se cosecha, vuelve a empezar con ellos. Las enraizadas también se plantan a mano en una mesa vacía
const FLOR_MESA := .65

const BANDEJAS_NAVE := 4

# «la txalupa…» → «La txalupa…» (capitalize() pone en mayúscula cada palabra)
static func may1(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)

# ---------- abrir con llave, candado, teclado o rueda (1.53, lo pidió el usuario: «simulando teclear una clave o meter una llave, como
# animación… que ese toque a la A sea más realista o acompañado de algo gráfico»). Con CAL: un momento en el centro de la pantalla
# (rects_acceso, pinta.gd) con su sonido; A o B lo pasan. Tipos: llave (cerradura de una puerta), candado (persiana o puerta con
# candado), clave (teclado de alarma o de la caja empotrada), pin (cajero: la tarjeta y el PIN) y rueda (la caja de la tía, 4 cifras)
var ACCESO_V = null   # {k: tipo, c: las cifras, ok, t0}

var gancho_acceso := Callable()   # (tipo, cifras, ok) · las pruebas lo apuntan sin esperar

const ACC_W := 104

const ACC_H := 84

const ACC_TECLA := 230   # ms por cifra

const ACC_GLIFO := {"0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111",
	"4": "101101111001001", "5": "111100111001111", "6": "111100111101111", "7": "111001010010010", "8": "111101111101111",
	"9": "111101111001111", "Z": "111001010100111", "*": "101010111010101", "#": "0101011111010101111101010", "·": "111111111"}

static func _suave(a: float) -> float:
	a = clampf(a, 0, 1)
	return a * a * (3 - 2 * a)

# ---------- cada acción, de cerca (1.54, lo pidió el usuario: «que todas las acciones del juego sean más realistas, acompañadas de algo
# gráfico»). Como la llave de la 1.53 (mismo recuadro, ACCESO_V, A o B lo pasan), un plano de detalle de lo que haces: regar, tratar la
# plaga, abonar, plantar, sacar un esqueje, cosechar, manicurar, polinizar, fumar (porro, pipa, bong o vaporizador), vender y pagar
const GESTOS := {"regar": 1200, "tratar": 1200, "abonar": 1200, "plantar": 1200, "sembrar": 1200, "esqueje": 1200, "cosechar": 1300, "manicurar": 1300,
	"polen": 1200, "fumar": 1400, "vender": 1200, "pagar": 1300, "dormir": 1300}

const GESTO_SON := {"regar": [[150, "agua"], [550, "agua"]], "tratar": [[250, "agua"], [600, "agua"]], "abonar": [[200, "agua"]],
	"plantar": [[350, "tick"], [900, "tick"]], "sembrar": [[450, "tick"], [900, "tick"]], "esqueje": [[450, "tijera"]], "cosechar": [[450, "tijera"], [850, "tick"]],
	"manicurar": [[250, "tijera"], [500, "tijera"], [750, "tijera"], [1000, "tijera"]], "polen": [[450, "tick"], [700, "tick"]],
	"fumar": [[100, "chispa"]], "vender": [[600, "coin"]], "pagar": [[200, "tick"], [400, "tick"], [600, "tick"], [800, "tick"], [1000, "coin"]]}

# ---------- (lo pidió el usuario: «eso no son sprites en condiciones en el mismo estilo que los muebles del juego»): el plano de
# cerca, 144 × 96 a escala de la vista C, compuesto con los sprites de tools/sprites/a-mano/gestos.py (la planta, la maceta y la pared
# de la carpa, de la vista C); entradas ['@', sprite, x, y, recorte] que pinta.gd recorta al panel
const GS_W := 144

const GS_H := 96

var _gs := Rect2i()

static func _mv(a: float, b: float, f: float) -> float:
	return a + (b - a) * _suave(f)

# F8: lo que vive en los módulos de después de la cadena (menus, policia, movil, venta, nave, setas, eventos), declarado aquí para quien lo llama antes
func SL():
	pass

func _dlg_fijo(t: String, nombre: String) -> void:
	pass

func _marco(o: Array, x: int, y: int, w: int, h: int) -> void:
	pass

func alijo_franco() -> void:
	pass

func almacen_club() -> void:
	pass

func aso() -> Dictionary:
	return {}

func aso_dia() -> void:
	pass

func bajar_vip() -> void:
	pass

func bajo_menu(T: String) -> void:
	pass

func balda_i(x: int) -> int:
	return 0

func bandejas_listas() -> Array:
	return []

func bandejas_nave() -> void:
	pass

func carpa_madres() -> void:
	pass

func comprar_mercado(id: String, N: String, pool: Array) -> void:
	pass

func corta_bandeja(i: int, Me: Dictionary) -> void:
	pass

func cuanto(txt: String, mx: float, pasos: Array, fmt: Callable):
	pass

func elegir_almacen(t: String, i0 := 0):
	pass

func elegir_cal() -> void:
	pass

func elegir_mapa() -> void:
	pass

func encargo_baltasar(N: String):
	pass

func entra_aso(d: Dictionary) -> void:
	pass

func entrada_disco() -> bool:
	return false

func escritorio_nave() -> void:
	pass

func estante_nave() -> void:
	pass

func extr_accion(k: String) -> void:
	pass

func fase_seta(b: Dictionary) -> String:
	return ""

func ficha_expo(k: String) -> void:
	pass

func ficha_pelea() -> String:   # la fila Pelea de la MOCHILA
	return ""

func franco_dia() -> void:
	pass

func gente() -> void:
	pass

func guardar_almacen(t: String):
	pass

func libre(w: Dictionary) -> void:
	pass

func llamar() -> bool:
	return false

func lleno_arm(k: String) -> int:
	return 0

func lote_accion(k: String) -> void:
	pass

func mar_dia() -> void:
	pass

func mar_noray(x: int) -> void:
	pass

func mar_ok() -> bool:
	return false

func mesa_nave(i: int) -> void:
	pass

func mesa_setas() -> void:
	pass

func mochila() -> void:
	pass

func nave_nueva() -> Dictionary:
	return {}

func nave_stock() -> float:
	return 0.0

func nivel_pelea() -> int:
	return 0

func noche_gaua() -> Dictionary:
	return {}

func noche_ya() -> bool:
	return false

func plantas() -> void:
	pass

func plantilla() -> void:
	pass

func plantilla_dia() -> void:
	pass

func pool_mayor() -> Array:
	return []

func pulverizar_bajo() -> bool:
	return false

func reloj_txt() -> String:
	return ""

func resto_mer(id: String, tope: float) -> float:
	return 0.0

func rival_b(kind := "rival") -> Dictionary:
	return {}

func sala_desc() -> String:
	return ""

func secadero_nave() -> void:
	pass

func sofoco_nave() -> float:
	return 0.0

func sot_ya() -> bool:
	return false

func subir_vip() -> void:
	pass

func suma_mer(id: String, g: float) -> void:
	pass

func t_clima(cl: Dictionary) -> String:
	return ""

func talk_kaia(N: String) -> void:
	pass

func tirar_lote(k: String, r: bool) -> void:
	pass

func trabajo(w: Dictionary) -> void:
	pass

func txt_secando(o: String) -> String:
	return ""

func vista_armario() -> void:
	pass

func vista_bajo(i0 := 0) -> void:
	pass

