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

# 1.47 (lo pidió el usuario): el estanco de cada pueblo, papel, filtros, tabaco y mecheros (D.ESTANCO)
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

# 1.25: y MIREN.n2 de la de Laos (MIREN.s2, que no está en el banco; S.flags.lao: las partidas de antes, al volver a hablarle)
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

# 1.11: en los plazos, lo que llevas entre el bolsillo y la caja
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
	# 1.43.8 (lo pidió el usuario: «no existe mapa y sitio del bajo de las setas»; con Datos.CAL): nada te decía dónde estaba. Con
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

# ---------- menú START (12-menus) ----------
func start_menu():
	var i := 0
	while true:   # 1.10: con su icono y lo que hay en cada uno, y arriba el día, la hora y el dinero
		var ns: int = S.sms.size()
		var vivas := 0
		for p in S.pots:
			if p and not p.get("dead"):
				vivas += 1
		var desc := 0
		for k in D.DEX:
			if S.disc.get(k):
				desc += 1
		var it := [{"label": "GENOTECA", "right": "%d/%d" % [desc, D.DEX.size()], "ic": icono("cogollo")}, {"label": "MOCHILA", "right": _kg(int(floor(peso_encima()))), "ic": icono("bolsa")},
			{"label": "MÓVIL", "right": ("%d SMS" % ns) if ns else null, "ic": icono("movil")}, {"label": "PLANTAS", "right": str(vivas), "ic": icono("maceta")},
			{"label": "OBJETIVO", "right": "cap. %d" % S.ch, "ic": icono("trofeo")}, {"label": "GUARDAR", "ic": icono("guardar")},
			{"label": "OPCIONES", "ic": icono("altavoz")}, {"label": "SALIR", "ic": icono("salir")}]
		if Datos.PLAY:   # U4: el registro de diálogo
			it.insert(5, {"label": "REGISTRO", "right": str(registro.size()), "ic": icono("movil")})
		if Datos.PLAY and S.flags.get("demo4"):   # U11: la demo, acabada
			it.insert(0, {"label": "JUEGO COMPLETO", "right": "cap. %d" % int(D.COMPLETO.ch), "ic": icono("trofeo")})
		i = await menu(it, {"cls": "start", "initial": i, "startCloses": true, "title": "%s · %s" % [Datos.fd_hud(S.day), reloj_txt()], "title2": Datos.eur(S.money)})
		if i < 0 or it[i].label == "SALIR":
			return
		if it[i].label == "JUEGO COMPLETO":
			if await demo_menu():
				await cap4_sigue()
				return
			continue
		if it[i].label == "REGISTRO":
			await leer("REGISTRO", "\n\n".join(PackedStringArray(_registro_inv())) if registro.size() else "Todavía no has hablado con nadie.")
			continue
		var k: int = ["GENOTECA", "MOCHILA", "MÓVIL", "PLANTAS", "OBJETIVO", "GUARDAR", "OPCIONES"].find(it[i].label)
		var i0 := i
		i = k
		if i == 0:
			await genoteca()
		elif i == 1:
			await mochila()
		elif i == 2:
			await movil_menu()
		elif i == 3:
			await plantas()
		elif i == 4:
			await objetivo_menu()
		elif i == 5:
			await say("Partida guardada." if save() else "No se ha podido guardar la partida.")
		elif i == 6:
			await opciones()
			if get("relanza"):   # E10: la partida importada se abre al cerrar el menú
				return
		i = i0

# U4: el registro, de lo último a lo primero
func _registro_inv() -> Array:
	var r := registro.duplicate()
	r.reverse()
	return r

# exportar la partida (1.11, exportar de 12-menus): el JSON de S al portapapeles
var exportado := ""   # lo último copiado (las pruebas lo leen: sin pantalla no hay portapapeles)

func exportar() -> void:
	exportado = JSON.stringify(S, "", false, true)
	DisplayServer.clipboard_set(exportado)
	await say("Partida copiada al portapapeles. Pégala en una nota o en un correo para guardarla.")

# recetario (1.11): cada variedad de receta con sus maneras de sacarla (RECIPES, en cualquier orden; RECETA_ORD, madre × padre)
func recetas() -> Dictionary:
	var R := {}
	for h in D.RECIPES:
		var t: String = D.RECIPES[h]
		if not R.has(t):
			R[t] = []
		R[t].append({"k": Array(h.split("+")), "ord": false})
	for h in D.RECETA_ORD:
		var t: String = D.RECETA_ORD[h]
		if not R.has(t):
			R[t] = []
		R[t].append({"k": Array(h.split(">")), "ord": true})
	return R

func receta_txt(o: Dictionary) -> String:
	return (" × " if o.ord else " + ").join(PackedStringArray(o.k.map(func(k): return D.STRAINS[k].n))) + (", en ese orden" if o.ord else "")

# REGALO (12-menus, por datos.json): las semillas que se consiguen sin comprarlas

func donde_semilla(k: String) -> String:
	var l := []
	if D.REGALO.has(k):
		l.append(D.REGALO[k])
	for it in D.SHOP:
		if it.get("sid") == k:
			l.append("en el growshop de Kiko desde el cap. %s" % n(it.ch))
			break
	for b in D.BANCO:
		if b[0] == k:
			l.append("en el banco de semillas del PC desde el cap. %s" % n(b[2]))
			break
	if D.MISIONES.any(func(m): return m.get("s") is Dictionary and m.s.has(k)):
		l.append("de premio en una misión")
	if recetas().has(k):
		l.append("de su receta")
	return "Semillas: " + "; ".join(PackedStringArray(l)) + "."

# el diario de la tía Maite (1.16): su nota de cada variedad (DIARIO, de 12-menus; 1.25: todas)
func diario_txt(t: String) -> String:
	return ("«%s»\n" % D.DIARIO[t]) if D.DIARIO.has(t) else ""

# 1.25: todas las de la Genoteca, en su orden; las de receta abren lo que entra; las demás dicen dónde están sus semillas
func tipo_diario(t: String, R: Dictionary) -> String:
	if R.has(t):
		return ("%d recetas" % R[t].size()) if R[t].size() > 1 else "receta"
	return "tienda" if D.SHOP.any(func(it): return it.get("sid") == t) else "landrace"

func recetario():
	var R := recetas()
	var ts: Array = D.DEX
	var i := 0
	while true:
		var items := []
		var nd := 0
		for t in ts:
			if S.disc.get(t):
				nd += 1
			items.append({"label": ("✓ " if S.disc.get(t) else "  ") + D.STRAINS[t].n, "right": tipo_diario(t, R), "sw": D.STRAINS[t].c, "ic": ic_cog(t),
				"desc": diario_txt(t) + ("\no ".join(PackedStringArray(R[t].map(func(o): return receta_txt(o)))) if R.has(t) else donde_semilla(t))})
		if S.flags.get("pagina"):   # la página que falta (1.17)
			items.append({"label": "  La última página", "desc": "«%s»" % D.PAGINA})
		items.append({"label": "Volver", "desc": ""})
		i = await menu(items, {"cls": "full", "title": "DIARIO DE LA TÍA MAITE", "title2": "%d/%d" % [nd, ts.size()], "desc": true, "initial": i})
		if i == ts.size() and S.flags.get("pagina"):
			continue
		if i < 0 or i >= ts.size():
			return
		if not R.has(ts[i]):
			continue
		var t: String = ts[i]
		var ks := []
		for o in R[t]:
			for k in o.k:
				if not ks.has(k):
					ks.append(k)
		var it2 := []
		for k in ks:
			it2.append({"label": ("✓ " if S.disc.get(k) else "  ") + D.STRAINS[k].n, "right": ("×" + n(S.seeds[k])) if S.seeds.get(k) else "", "sw": D.STRAINS[k].c, "ic": ic_cog(k), "desc": donde_semilla(k)})
		it2.append({"label": "Volver", "desc": ""})
		await menu(it2, {"cls": "full", "title": D.STRAINS[t].n.to_upper(), "title2": "lo que entra", "desc": true})

# cambiar el nombre a una variedad propia (1.11): sin repetir el de otra
func renombrar_variedad(k: String) -> void:
	var C: Dictionary = S.custom[k]
	var v = await pedir_texto("Nuevo nombre de la variedad", C.n, Datos.NOM_MAX)
	if v == null or v == "" or v == C.n:
		return
	var l: String = v.to_lower()
	for d in D.DEX:
		if D.STRAINS[d].n.to_lower() == l:
			await say("Ya hay una variedad con ese nombre.")
			return
	for q in S.custom:
		if not is_same(S.custom[q], C) and S.custom[q].n.to_lower() == l:
			await say("Ya hay una variedad con ese nombre.")
			return
	var a: String = C.n
	C.n = v
	sfx("sel")
	await say("La %s pasa a llamarse %s." % [a, v])

func genoteca():
	var i := 0
	while true:
		i = await menu_genoteca(i)
		if i < 0:
			break

func menu_genoteca(i0: int) -> int:
	var DEX: Array = D.DEX
	var nr := 0
	for t in DEX:
		if S.disc.get(t):
			nr += 1
	var items := []
	if S.flags.get("diario"):   # sale bajo la almohada (1.25)
		items.append({"label": "DIARIO DE LA TÍA MAITE", "right": "%d/%d" % [nr, DEX.size()], "ic": icono("guardar"), "diario": 1, "desc": "Su cuaderno: las %d variedades, lo que apuntó de cada una, las recetas de los cruces y dónde conseguir las semillas." % DEX.size()})
	for j in DEX.size():
		var k: String = DEX[j]
		var s: Dictionary = D.STRAINS[k]
		var nn := "%02d" % (j + 1)
		if S.disc.get(k):
			items.append({"label": "%s %s" % [nn, s.n], "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "k": k, "desc": strain_line(k) + (("\n" + s.h) if s.get("h") else "") + (("\nCata: " + S.catas[k]) if S.catas.has(k) else "")})
		else:
			items.append({"label": nn + " ??????", "desc": "Sin descubrir."})
	var cust := []
	for k in S.custom:
		if S.disc.get(k):
			cust.append(k)
	for k in cust:
		var s: Dictionary = S.custom[k]
		items.append({"label": "★ " + s.n, "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "desc": strain_line(k) + "\nPulsa A para cambiarle el nombre.", "c": k})
	var nd := 0
	for k in DEX:
		if S.disc.get(k):
			nd += 1
	var i: int = await menu(items, {"cls": "full", "title": "GENOTECA", "title2": "%d/%d · %d propias" % [nd, DEX.size(), cust.size()], "desc": true, "initial": i0})
	var vistas := []   # 1.51: la ficha de cada variedad con su hoja, en el orden de la lista
	for k in DEX:
		if S.disc.get(k):
			vistas.append(k)
	vistas.append_array(cust)
	if i >= 0 and i < items.size() and items[i].get("diario"):
		await recetario()
	elif i >= 0 and i < items.size() and items[i].get("c"):
		if not Datos.CAL or await ask(S.custom[items[i].c].n, ["Ver la hoja", "Cambiar el nombre"]) == 1:
			await renombrar_variedad(items[i].c)
		else:
			await ficha_variedad(vistas, vistas.find(items[i].c))
	elif Datos.CAL and i >= 0 and i < items.size() and items[i].get("k"):
		await ficha_variedad(vistas, vistas.find(items[i].k))
	return i

# ---------- la ficha de la variedad (1.51, lo pidió el usuario: «dependiendo de la variedad o linaje, las hojas son diferentes») ----------
# una lámina con la hoja de abanico de la variedad (hoja.gd), su nombre y su grupo (sativa, híbrido de dominancia sativa,
# equilibrado, de dominancia índica, índica); izquierda y derecha pasan a la anterior y la siguiente; A o B cierran. FICHA_V = {l, i}
var FICHA_V = null
const COLOR_GRUPO := ["#c07a1e", "#8a9a2a", "#5a8a5a", "#7a4a8a", "#5a2a7a"]

func grupo_n(ind: float) -> int:
	var p := roundi(ind * 100)
	return 0 if p <= 10 else (1 if p < 40 else (2 if p <= 60 else (3 if p < 90 else 4)))

func desc_ficha(V: Dictionary) -> String:
	var k: String = V.l[V.i]
	var st = strain(k)
	var p := Hoja.params(D, S, k)
	var land: bool = st.get("tipo") == "landrace"
	var au := "Autofloreciente: florece por la edad, sin cambiar la luz. " if Datos.CAL and st.get("auto") else ""   # 1.52
	return "%s\n%s%s %s" % [Hoja.grupo(p.ind, land), au, Hoja.como(p), (st.get("o", "") + ".") if st.get("o") else ""]

func ficha_variedad(lista: Array, i0: int) -> void:
	if lista.is_empty() or i0 < 0:
		return
	FICHA_V = {"l": lista, "i": i0}
	var nom := func(): return str(strain(FICHA_V.l[FICHA_V.i]).n).to_upper()
	_dlg_fijo(desc_ficha(FICHA_V), nom.call())
	if gancho_menu.is_valid():   # las pruebas: se ve y se cierra
		FICHA_V = null
		return
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "B":
			pop()
			pr.res(null)
			return
		var d: int = {"left": -1, "right": 1}.get(b, 0)
		if d and FICHA_V.l.size() > 1:
			FICHA_V.i = (FICHA_V.i + d + FICHA_V.l.size()) % FICHA_V.l.size()
			sfx("sel")
			_dlg_fijo(desc_ficha(FICHA_V), nom.call()))
	await Motor.espera(pr)
	FICHA_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()

# la lámina (128 × 100): el papel, la hoja (Hoja.W × Hoja.H, la pinta pinta.gd en hoja_xy), el nombre y la franja del grupo
func rects_ficha(V: Dictionary) -> Array:
	var o := []
	var k: String = V.l[V.i]
	var x0: int = (SW - 128) >> 1
	var y0: int = maxi(2, (alto_libre() - 100) >> 1)
	o.append_array([[x0, y0, 128, 100, "#5a5040"], [x0 + 1, y0 + 1, 126, 98, "#f4f2ea"], [x0 + 3, y0 + 3, 122, 94, "#e8e4d6"], [x0 + 4, y0 + 4, 120, 92, "#f8f6ee"]])
	var g := grupo_n(Hoja.params(D, S, k).ind)
	o.append([x0 + 4, y0 + 4, 3, 92, COLOR_GRUPO[g]])
	var t: String = str(strain(k).n)
	if t.length() > 28:
		t = t.left(27) + "."
	Croquis.texto(o, x0 + 64 - (Croquis.ancho(t) >> 1), y0 + 74, t, "#22261e")
	var gt: String = ["SATIVA", "HIBRIDO SATIVA", "EQUILIBRADO", "HIBRIDO INDICA", "INDICA"][g]
	Croquis.texto(o, x0 + 64 - (Croquis.ancho(gt) >> 1), y0 + 83, gt, COLOR_GRUPO[g])
	if V.l.size() > 1:   # las flechas
		o.append_array([[x0 + 9, y0 + 36, 1, 5, "#8a8070"], [x0 + 8, y0 + 37, 1, 3, "#8a8070"], [x0 + 7, y0 + 38, 1, 1, "#8a8070"],
			[x0 + 118, y0 + 36, 1, 5, "#8a8070"], [x0 + 119, y0 + 37, 1, 3, "#8a8070"], [x0 + 120, y0 + 38, 1, 1, "#8a8070"]])
	return o

func hoja_xy() -> Vector2i:
	return Vector2i(((SW - 128) >> 1) + 32, maxi(2, (alto_libre() - 100) >> 1) + 6)



func mochila() -> void:
	var i := 0
	while true:
		var M: Dictionary = D.MOCHILAS[int(S.items.get("bolsa", 0))]
		var rows := [{"label": "Dinero", "right": Datos.eur(S.money), "ic": icono("billetes"), "desc": "Lo que llevas encima. Don Baltasar también lo cuenta."},
			{"label": M.n, "right": "%d de %s" % [int(floor(peso_encima())), _kg(int(M.g))], "ic": icono("bolsa"), "desc": "Cogollos y extractos que llevas encima. Lo que no cabe al cosechar va a la caja fuerte."}]
		if S.get("caja"):
			var CJ: Dictionary = D.CAJA[S.caja.nivel]
			rows.append({"label": "Caja fuerte", "right": "%s · %d g" % [Datos.eur(caja_e()), int(floor(caja_g()))], "ic": icono("billetes"),
				"desc": "%s, detrás del diploma. Caben %s y %s.\nLo que está dentro no lo llevas encima." % [CJ.n, Datos.eur(CJ.money), _kg(int(CJ.g))]})
		if nevera_r() >= .1:
			rows.append({"label": "Nevera", "right": Datos.coma(Datos.jsround(nevera_r() * 10) / 10.0) + " g", "ic": icono("cogollo"),
				"desc": "Los extractos, en frío, en casa (caben %s g). Un control en la calle no la ve; una redada se la lleva." % n(nevera_cap())})
		rows.append({"label": "Vida", "right": "%s/%s" % [n(S.hp), n(S.hpMax)], "desc": "Se recupera durmiendo, comiendo o con el tiempo."})
		if int(S.pelea.xp) > 0:
			rows.append({"label": "Pelea", "right": "nivel %d" % nivel_pelea(), "desc": ficha_pelea()})
		for k in D.PRODUCTOS:   # 1.23: por marca
			if k == "fert" or S.items.get(k, 0) > 0:
				rows.append({"label": D.PRODUCTOS[k].n, "right": "×" + n(S.items.get(k, 0)), "ic": icono("abono"), "desc": D.DESC_PROD[k]})
		if S.items.get("medidor", 0):
			rows.append({"label": "Medidor de pH y EC", "right": "×1", "desc": "Con él corriges el pH justo y ves la EC y el pH de cada maceta en PLANTAS."})
		if S.items.get("tarros"):
			rows.append({"label": "Tarros de curado", "right": "en casa", "desc": "Los cogollos en la caja fuerte y los extractos en la nevera se curan en %d días: suben un %d %% de THC y se venden un %d %% más caros." % [int(D.CURADO.dias), Datos.jsround(D.CURADO.thc * 100), Datos.jsround(D.CURADO.precio * 100)]})
		rows.append_array([{"label": "Insecticida (tratamientos)", "right": "×" + n(S.items.insect), "ic": icono("insecticida"), "desc": "Úsalo en una maceta con plaga."},
			{"label": "Spray de pimienta", "right": "×" + n(S.items.spray), "ic": icono("spray"), "desc": "Solo en combate."},
			{"label": "Bocata", "right": "×" + n(S.items.bocata), "ic": icono("bocadillo"), "desc": "Pulsa A para comerlo: +15 de vida.", "k": "bocata"}])
		for k in D.MACETAS:
			if S.items.get("m_" + k, 0) > 0:
				rows.append({"label": "Maceta " + D.MACETAS[k].n, "right": "×" + n(S.items["m_" + k]), "ic": icono("maceta"), "desc": desc_maceta(k) + "\nSe cambia en una plaza vacía de la carpa."})
		for k in D.FOCOS:
			if S.items.get("f_" + k, 0) > 0:
				rows.append({"label": "Foco " + D.FOCOS[k].n, "right": "×" + n(S.items["f_" + k]), "ic": icono(Atlas.ico_foco(k)), "desc": desc_foco(k) + "\nSe cuelga desde la vista de carpa: ▲ hasta el foco y A."})
		for k in D.EXTRAS:
			if S.items.get("x_" + k, 0) > 0:
				rows.append({"label": D.EXTRAS[k].n, "right": "×" + n(S.items["x_" + k]), "ic": icono(Atlas.ICX[k]), "desc": D.EXTRAS[k].d + "\nSe pone%s desde la vista de carpa: ▲ hasta el foco y A." % ("n" if D.EXTRAS[k].get("pl") else "")})
		for k in S.seeds:
			rows.append({"label": "Semilla " + strain(k).n, "right": "×" + n(S.seeds[k]), "sw": strain(k).c, "ic": icono("semillas"), "desc": strain_line(k) + "\nPulsa A para tirarlas.", "k": "s", "sid": k})
		for e in S.esquejes:
			rows.append({"label": "Esqueje " + strain(e.sid).n + etiq(e.f), "right": Datos.fd_corto(e.dia + D.ESQUEJE_DIAS), "sw": strain(e.sid).c, "ic": ic_cog(e.sid),
				"desc": "Enraizando en el propagador. Plántalo en una plaza vacía antes de que acabe el %s.\nPulsa A para ponerle nombre o tirarlo." % Datos.fd(e.dia + D.ESQUEJE_DIAS, S.day), "k": "e", "e": e})
		for k in S.buds:
			var b: Dictionary = S.buds[k]
			rows.append({"label": lot_nombre(k), "right": "%d g · %s%%" % [int(floor(b.g)), Datos.pct(b.thc)], "sw": strain(lot_sid(k)).c, "ic": ic_cog(lot_sid(k)),
				"desc": ("Cogollos de un fenotipo estrella, en lote aparte.\n" if k.ends_with("*") else "Cogollos listos para vender.\n") + ((cura_txt(b) + "\n") if cura_txt(b) else "") + ((S.catas[lot_sid(k)] + "\n") if S.catas.has(lot_sid(k)) else "") + strain(lot_sid(k)).o + "\nPulsa A para catarlo" + (", analizarlo" if S.items.get("analizador") else "") + " o tirarlo.", "k": "b", "key": k})
		for k in S.rosin:
			var b: Dictionary = S.rosin[k]
			var ro := rosin_item([k, b])
			ro.desc = D.EXTR[tipo_extr(k)].n + ": extracción sin disolventes. La compran los catadores.\n" + ((S.catas["r:" + k] + "\n") if S.catas.has("r:" + k) else "") + strain(lot_sid(k)).o + ("\nPulsa A para catarlo o tirarlo." if Datos.CAL else "\nPulsa A para tirarlo.")
			ro.k = "r"
			ro.key = k
			rows.append(ro)
		if Datos.CAL:   # 1.47: lo de fumar (el estanco y el grow)
			for q in [["papel", "Papel de liar", "hojas", "Una hoja por porro. En el estanco."], ["filtros", "Filtros", "", "Cada porro gasta uno. En el estanco."],
					["tabaco", "Tabaco de liar", "g", "Para mezclar: 0,7 g por porro y el porro lleva menos hierba. En el estanco."], ["mechero", "Mechero", "", "Para el porro, la pipa y el bong."],
					["grinder", "Grinder", "", "El porro te sale con 0,4 g de hierba en vez de 0,5."], ["pipa", "Pipa de cristal", "", "Sentado en un sofá o una silla: 0,2 g de cogollo o 0,1 de extracto."],
					["bong", "Bong de cristal", "", "Sentado: 0,3 g de cogollo o 0,1 de extracto."], ["vapo", "Vaporizador", "", "Sentado: 0,2 g de cogollo o 0,1 de extracto, sin mechero; en la calle huele menos."]]:
				var v := float(S.items.get(q[0], 0))
				if v > 0:
					rows.append({"label": q[1], "right": ("%s %s" % [n(floor(v * 10) / 10.0), q[2]]) if q[2] != "" else "×" + n(v), "ic": icono(q[0]), "desc": q[3]})
		if S.items.get("prensa"):
			rows.append({"label": "Prensa de rosin", "right": "en la mesa", "desc": "De 5 g de cogollo, 1 g de rosin con el triple de THC. Se usa en la mesa del piso."})
		if S.items.get("tamiz"):
			rows.append({"label": "Tamices de seda", "right": "en la mesa", "desc": "Dry sift: de la flor, el kief con algo más del doble de THC. Se usa en la mesa del piso."})
		if S.items.get("ice"):
			rows.append({"label": "Kit Ice-o-lator", "right": "en la mesa", "desc": "Agua con hielo y bolsas de malla: la resina más limpia. Se usa en la mesa del piso."})
		if S.items.get("mallas00"):   # 1.36
			rows.append({"label": "Mallas 00", "right": "en el piso", "desc": "La malla «doble cero» de la tía: dry sift de lo más fino, solo las cabezas. Se usa en los tamices del piso."})
		if S.items.get("lavadora"):
			rows.append({"label": "Lavadora de extracción", "right": "en el piso", "desc": "Ice-o-lator en grande: bate sola con las bolsas de malla. Está montada junto a la nevera."})
		if S.items.get("estatica"):
			rows.append({"label": "Máquina de static", "right": "en el piso", "desc": "La placa cargada levanta las cabezas de resina de la flor fría: la resina más pura."})
		i = await menu(rows, {"cls": "full", "title": "MOCHILA", "title2": "%d g encima" % int(floor(total_buds())) + ((" · %d g en la caja" % int(floor(caja_g()))) if S.get("caja") else ""), "desc": true, "initial": i})
		if i < 0:
			return
		if rows[i].get("k") == "bocata":
			if S.items.bocata > 0 and S.hp < S.hpMax:
				S.items.bocata -= 1
				S.hp = mini(S.hpMax, S.hp + 15)
				sfx("get")
				toast("Te comes el bocata. +15 de vida", 1200)
			else:
				sfx("bump")
		elif rows[i].get("k") == "e":
			await esqueje_accion(rows[i].e, S.esquejes)
		elif rows[i].get("k") == "b":   # la cata y el análisis (1.15)
			await lote_accion(rows[i].key)
		elif rows[i].get("k") == "r":   # 1.36: tirar un extracto; 1.47: o catarlo
			if Datos.CAL:
				await extr_accion(rows[i].key)
			else:
				await tirar_lote(rows[i].key, true)
		elif rows[i].get("k") == "s":   # tirar semillas (1.11)
			var sid: String = rows[i].sid
			var ns: int = int(S.seeds[sid])
			var o := ["Tirar 1", "Tirar todas", "Nada"] if ns > 1 else ["Tirar", "Nada"]
			var c: int = await ask("%s de %s." % [("%d semillas" % ns) if ns > 1 else "1 semilla", strain(sid).n], o)
			if c >= 0 and c < o.size() and o[c] != "Nada":
				var q: int = ns if o[c] == "Tirar todas" else 1
				S.seeds[sid] -= q
				if not S.seeds[sid]:
					S.seeds.erase(sid)
				sfx("sel")
				await say(("Tiras las %d semillas." % q) if q > 1 else "Tiras 1 semilla.")

func plantas() -> void:
	var rows := []
	var H := huecos()
	var cl := Cultivo.clima_sala(S, is_night())
	rows.append({"label": "Sala", "right": t_clima(cl) if S.sala.get("termo") else "¿?", "desc": sala_desc() if S.sala.get("termo") else "Sin termohigrómetro no sabes la temperatura ni la humedad de la sala. Kiko lo vende."})
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if not c:
			continue
		var C: Dictionary = D.CARPAS[c.t]
		var F: Dictionary = D.FOCOS[c.foco]
		var wm2 := Datos.jsround(F.w / (C.cm[0] * C.cm[2] / 1e4))
		rows.append({"label": C.n, "right": F.n, "ic": icono(Atlas.ico_carpa(c.t)), "desc": "%s plantas · foco %s, %d W/m²%s\nLuz: %s al día con plantas · hasta %s W, macetas de %s L y %d L de tierra (%d puestos).\n%s%s" % [n(C.plazas), F.n, wm2,
			" (poca luz: crecen más despacio y con menos THC)" if wm2 < D.W_M2 else "", Datos.eur(luz_carpa(ci)), n(C.wmax), n(C.lmax), litros_max(ci), litros_carpa(ci),
			Cultivo.ext_txt(S, ci), (" · dentro, de día " + t_clima(Cultivo.clima_carpa(S, ci, false))) if S.sala.get("termo") and plantas_vivas(ci) else ""]})
		for i in H.size():
			var h: Dictionary = H[i]
			if h.c != ci:
				continue
			var p = S.pots[i]
			var Mc: Dictionary = D.MACETAS[S.macetas[i]]
			if not p:
				rows.append({"label": "  %d · vacía" % (h.j + 1), "right": n(Mc.l) + " L", "ic": icono("maceta"), "desc": "Maceta de %s. Planta algo desde la carpa de tu piso." % Mc.n})
				continue
			var s = strain(p.sid)
			var desc := "Se ha secado. Retírala." if p.get("dead") else "%s · Agua %d%% · Salud %d%%\n%s%s · maceta de %s." % ["Lista para cosechar" if p.prog >= 1 else stage_name(p), Datos.jsround(p.water),
				Datos.jsround(p.health), "PLAGA: trátala con insecticida. " if p.pest else "", abono_txt(p), Mc.n]
			rows.append({"label": "  %d · %s%s" % [h.j + 1, s.n, etiq(p.get("f"))], "sw": s.c, "ic": ic_cog(p.sid),
				"right": "muerta" if p.get("dead") else ("LISTA" if p.prog >= 1 else "%d%%" % int(floor(p.prog * 100))), "desc": desc})
	var luz := factura_luz()
	var i := 0
	while true:
		i = await menu(rows, {"cls": "full", "title": "CULTIVO", "title2": ("Luz " + Datos.eur(luz) + "/día") if luz else "Luz apagada", "desc": true, "initial": i})
		if i < 0:
			break

# ---------- combate (13-combate) ----------
static func hp_col(f: float) -> Color:
	return Color("#58d080") if f > .5 else (Color("#f0c040") if f > .2 else Color("#f05050"))

func bhud_datos() -> Dictionary:
	var f: float = B.hp / float(B.hpMax) if B.kind == "thief" else S.heat / 100.0
	var pf: float = S.hp / float(S.hpMax)
	return {"e": [B.name, "VIDA" if B.kind == "thief" else "SOSP.", maxf(0, f), hp_col(f) if B.kind == "thief" else Color("#e05050")],
		"p": [S.name, "%d g" % int(floor(total_buds())), maxf(0, pf), hp_col(pf), "%s/%s · %s" % [n(S.hp), n(S.hpMax), Datos.eur(S.money)]]}

func bhud_build() -> void:
	bhud_pon(bhud_datos())

func bhud_act() -> void:
	if B:
		bhud_pon(bhud_datos())

# el texto de la caja sin esperar a nadie (las preguntas del combate, con el menú al lado)
func prompt(t: String) -> void:
	if oraculo:
		return
	dlg.show()
	dlg_nm.hide()
	dlg_more.hide()
	dlg_txt.text = nm(t)
	_coloca.call_deferred()

func grupo_combate(who: String):
	if not Atlas.ok or B == null:
		return null
	if who == "P":
		return Atlas.cubre("combate:espalda:player")
	if B.kind == "thief":
		var g = Atlas.cubre("combate:frente:darko") if B.get("jefe") else Atlas.grupo_look(B.get("look"))   # sin look (como en grupoLook), el del ladrón; Darko (1.17): su personaje es de 32 px; pelea con el suyo de combate (1.21)
		return g if g else Atlas.cubre("combate:frente:ladron")
	return Atlas.cubre("combate:frente:policia")

# lanza una animación de combate; devuelve su duración en ms
func b_anim(who: String, nn: String) -> float:
	var g = grupo_combate(who)
	if not g or Atlas.anim_de(g, nn) == null:
		return 0.0
	B["a" + who] = {"n": nn, "t0": M.reloj}
	return Atlas.duracion(g, nn)

func vfx_combate(id: String, x: float, y: float) -> void:
	if Atlas.ok:
		lanzar_vfx(id, x, y, M.reloj, "*", false)

func battle(kind):
	if gancho_combate.is_valid():
		return await gancho_combate.call(kind)
	lock += 1
	var res = null
	music(D.MUS_COMBATE.get(kind, "battle"))
	sfx("enc")
	for k in 3:
		fade_pon(.85, true, true)
		await wait(70)
		fade_pon(0, true, true)
		await wait(70)
	wipe_go()
	await wait(480)
	var ch: int = S.ch
	if kind == "thief":
		var nm_: String = pick(D.THIEVES)
		B = {"kind": kind, "name": nm_, "look": Datos.rand_look("th" + Datos.js_num(Cultivo.azar()), "thief"), "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	elif kind == "rival" or kind == "darko":
		B = rival_b(kind)
	else:
		B = {"kind": kind, "name": pick(D.COPS), "look": D.LOOKS.cop, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	if B.kind == "thief":
		# desde el capítulo 5 (1.10), ladrones más duros: +4 de vida y +1 a cada golpe; un rival (1.16), RIVAL.vida más y +1 a cada golpe
		var dd := 1 if ch >= 5 else 0
		var rr := 1 if B.has("rival") else 0
		B.hpMax = 12 + ch * 2 + ri(0, 4) + 4 * dd + int(D.RIVAL.vida) * rr + (int(D.DARKO.vida) if B.get("jefe") else 0)
		B.hp = B.hpMax
		B.atk = [2 + (ch >> 2) + dd + rr, 4 + (ch >> 1) + dd + rr]
	mode = "battle"
	update_hud()
	wipe_fuera()
	await wait(650)
	bhud_build()
	if B.get("jefe"):
		await say("Darko se quita la sudadera y la tira al suelo.")
		await say("«Ni Iñaki ni mi tío. Tú y yo.»", B.name)
	elif B.has("rival"):
		await say("%s se te planta delante." % B.rival)
		await say(pick(["«Te lo he dicho por las buenas.»", "«Aquí se vende lo mío.»", "«Vamos a arreglarlo.»"]), B.name)
	elif kind == "thief":
		await say("Un %s te corta el paso." % B.name.to_lower())
		await say(pick(["«La mochila. Dámela y no pasa nada.»", "«Eh, tú. Sé lo que llevas encima.»", "«Quieto. El dinero y lo que lleves.»"]), B.name)
	else:
		b_anim("E", "alto")
		await say("%s te da el alto." % B.name)
		await say(pick(["«Control rutinario. ¿Llevas algo encima?»", "«Documentación. Y vacía los bolsillos.»", "«Aquí huele a marihuana. ¿Es tuya?»"]), B.name)
	while not res:
		if B.kind == "thief":
			res = await thief_round()
		else:
			res = await cop_round()
	bhud_pon(null)
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
		menu_box.hide()
	await fade(1)
	mode = "world"
	B = null
	if res == "ko":
		advance_time(360)
		S.hp = S.hpMax
		enter_map("home", 2, 4, "down")
	else:
		music(map_music())
	update_hud()
	await fade(0)
	if res == "ko":
		await say("Te despiertas en casa con la cabeza vendada. Un vecino te encontró en el portal.")
	S.cool = 25
	heat_warn()
	lock -= 1
	return res

func el_b() -> String:
	return B.rival if B.has("rival") else "El " + B.name.to_lower()

func enemy_hits():
	# la carga de Darko (1.17): a veces coge la barra y el golpe siguiente vale el doble (CUBRIRSE lo deja en la mitad). La guardia o la
	# esquiva de esta ronda se gastan con ella (1.24): contra la barra hay que cubrirse o apartarse en la ronda del golpe
	if B.get("jefe") and not B.get("carga") and Cultivo.azar() < float(D.DARKO.carga):
		B.carga = 1
		B.cubre = 0
		B.esquiva = 0
		await say("%s coge una barra de hierro del suelo. El próximo golpe va a doler." % el_b())
		return null
	# ESQUIVAR (1.18): con suerte (prob_esquiva, los reflejos) no te toca y tu golpe siguiente no falla y hace PELEA.contra más
	# (B.contra); si no, te da entero. La amenaza fallida (B.furia) suma PELEA.furia al golpe
	if B.get("esquiva"):
		B.esquiva = 0
		if Cultivo.azar() < prob_esquiva():
			b_anim("E", "ataque")
			await say(("%s baja la barra y te apartas a tiempo." % el_b()) if B.get("carga") else ("%s se lanza y te apartas a tiempo." % el_b()))
			B.carga = 0
			B.furia = 0
			B.contra = 1
			return null
		await say("No te apartas a tiempo.")
	var dmg := (ri(int(B.atk[0]), int(B.atk[1])) + (int(D.PELEA.furia) if B.get("furia") else 0)) * (2 if B.get("carga") else 1)
	b_anim("E", "ataque")
	await say(("%s te da con la barra." % el_b()) if B.get("carga") else ("%s %s." % [el_b(), pick(["te golpea", "te empuja contra un portal", "te da una patada", "te tira al suelo"])]))
	B.carga = 0
	B.furia = 0
	var dd: int = int(ceil(dmg / 2.0)) if B.get("cubre") else dmg
	if B.get("cubre"):   # CUBRIRSE (1.16)
		B.cubre = 0
		await say("Te cubres: el golpe duele la mitad.")
	b_anim("P", "herido")
	vfx_combate("vfx-golpe", 64, 112)
	B.shakeP = 450.0
	sfx("hurt")
	S.hp = maxi(0, S.hp - dd)
	bhud_act()
	await wait(450)
	if S.hp <= 0:
		b_anim("P", "desmayo")
		await say("Pierdes el conocimiento.")
		var lost := 0
		for b in S.buds.values():
			var l := int(floor(b.g / 2))
			lost += l
			b.g -= l
		for k in S.buds.keys():
			if S.buds[k].g < .5:
				S.buds.erase(k)
		var lr := 0.0
		for k in S.rosin.keys():   # y la mitad del rosin (1.10)
			var qr: float = Datos.jsround(S.rosin[k].g * 5) / 10.0
			lr += qr
			use_rosin(k, qr)
		var lm := Datos.jsround(S.money * .3)
		S.money -= lm
		await say("Te roba %d g%s y %s." % [lost, (", " + rosin_txt(lr)) if lr > 0 else "", Datos.eur(lm)])
		return "ko"
	return null

func thief_round():
	prompt("¿Qué haces?")
	var c: int = await menu(["LUCHAR", "MOCHILA", "HABLAR", "HUIR"], {"cls": "battle", "cancel": false})
	if c == 0:
		prompt("Elige un golpe.")
		var m: int = await menu(["PUÑETAZO", "PATADA", "CUBRIRSE", "ESQUIVAR"], {"cls": "battle"})
		if m < 0:
			return null
		if m == 2:
			B.cubre = 1
			B.guardia = 1
			B.esquiva = 0
			await say("Te pones en guardia: el próximo golpe no fallará.")
			return await enemy_hits()
		if m == 3:   # ESQUIVAR (1.18)
			B.esquiva = 1
			B.cubre = 0
			await say("Te quedas atento para apartarte.")
			return await enemy_hits()
		var mv := {"n": "PATADA", "acc": .65, "d": [8, 12]} if m else {"n": "PUÑETAZO", "acc": .92, "d": [4, 7]}
		await wait(b_anim("P", "patada" if m else "golpe") * .6)
		await say("Le das una patada." if mv.n == "PATADA" else "Le das un puñetazo.")
		var g = B.get("guardia")
		var k = B.get("contra")
		B.guardia = 0
		B.contra = 0
		if g or k or Cultivo.azar() < minf(float(D.PELEA.accMax), mv.acc + int(S.pelea.ref) * float(D.PELEA.acc)):   # la fuerza suma al golpe y los reflejos, a la puntería (1.18)
			var d: int = ri(mv.d[0], mv.d[1]) + int(S.pelea.fue) + (int(D.PELEA.contra) if k else 0)
			if k:
				await say("Le pillas abierto.")
			b_anim("E", "herido")
			vfx_combate("vfx-golpe", 178, 40)
			B.flashE = 500.0
			sfx("hit")
			B.hp -= d
			bhud_act()
			await wait(500)
			if m and d >= 11:
				await say("Le has hecho daño de verdad.")
		else:
			await say("Fallas.")
	elif c == 1:
		prompt("¿Qué usas?")
		var it: int = await menu([{"label": "SPRAY ×%s" % n(S.items.spray), "ic": icono("spray")}, {"label": "BOCATA ×%s" % n(S.items.bocata), "ic": icono("bocadillo")}], {"cls": "battle"})
		if it < 0:
			return null
		if it == 0:
			if not S.items.spray:
				await say("No te queda SPRAY.")
				return null
			S.items.spray -= 1
			b_anim("P", "spray")
			vfx_combate("vfx-spray", 178, 48)
			await say("Le echas SPRAY DE PIMIENTA a la cara.")
			b_anim("E", "herido")
			B.flashE = 700.0
			sfx("hit")
			B.hp -= ri(12, 16)
			bhud_act()
			await wait(500)
			await say("No puede abrir los ojos.")
		else:
			if not S.items.bocata:
				await say("No te quedan BOCATAS.")
				return null
			S.items.bocata -= 1
			b_anim("P", "comer")
			S.hp = mini(S.hpMax, S.hp + 15)
			sfx("get")
			bhud_act()
			await say("Te comes un BOCATA. Recuperas vida.")
	elif c == 2:
		prompt("¿Qué le dices?")
		var h: int = await menu(["CALMAR", "AMENAZAR"], {"cls": "battle"})
		if h < 0:
			return null
		if h == 0:
			await say("%s: «Tranquilo. Somos del mismo barrio.»" % S.name)
			if not B.get("jefe") and Cultivo.azar() < clampf(.25 + S.rep / 300.0, .25, .7):
				await say("«Vale... Tú eres el de Maite. Olvídalo.»")
				return "talk"
			await say("«Aquí ya no hay nada que hablar.»" if B.get("jefe") else "«No me cuentes historias.»")
		else:   # AMENAZAR (1.18): funciona mejor cuanto más tocado está y cuanta más fuerza tienes; si falla, te pega con rabia
			await say("%s: «Lárgate ahora que puedes.»" % S.name)
			if not B.get("jefe") and Cultivo.azar() < prob_amenaza():
				await say(("%s se lo piensa mejor." if B.has("rival") else "%s se lo piensa mejor y se va.") % el_b())
				return "talk"
			B.furia = 1
			await say("«A mí no me amenaza nadie.»" if B.get("jefe") else "«¿A mí? Ahora vas a ver.»")
	elif c == 3:
		if Cultivo.azar() < minf(float(D.PELEA.huirMax), .5 + int(S.pelea.ref) * float(D.PELEA.huir)):
			sfx("door")
			await say("Consigues escapar.")
			return "flee"
		await say("Te corta el paso. No puedes escapar.")
	if B.hp <= 0:
		if B.get("jefe"):   # Darko (1.17) no huye: se queda en el suelo, y la reputación la da ajuste_darko
			b_anim("E", "herido")
			await say("%s cae al suelo, sin aire." % el_b())
		else:
			B.gone = true
			b_anim("E", "huir")
			await say("%s sale corriendo." % el_b())
		if B.has("rival"):
			if not B.get("jefe"):
				S.rep += int(D.RIVAL.rep)
			if S.hpMax < 60:
				S.hpMax += 2
				S.hp += 2
				bhud_act()
				await say("Aguantas más. VIDA máxima: %d." % S.hpMax)
			await experiencia()
			return "win"
		var loot: int = ri(20, 40) + S.ch * 10
		S.money += loot
		S.rep += 2
		sfx("coin")
		bhud_act()
		await say("Al huir se le cae la cartera: +%s." % Datos.eur(loot))
		if S.hpMax < 60:
			S.hpMax += 2
			S.hp += 2
			bhud_act()
			await say("Aguantas más. VIDA máxima: %d." % S.hpMax)
		await experiencia()
		return "win"
	return await enemy_hits()

# la experiencia (1.18): cada pelea ganada da PELEA.xp y con cada PELEA.nv subes un nivel y eliges FUERZA o REFLEJOS (13-combate.js)
func nivel_pelea() -> int:
	var x := int(S.pelea.xp)
	return D.PELEA.nv.filter(func(v): return x >= int(v)).size()

func prob_esquiva() -> float:
	return float(D.PELEA.esq0) + int(S.pelea.ref) * float(D.PELEA.esq)

func prob_amenaza() -> float:
	return clampf(float(D.PELEA.amen0) + (1 - float(B.hp) / float(B.hpMax)) * float(D.PELEA.amen) + int(S.pelea.fue) * float(D.PELEA.amenF), float(D.PELEA.amen0), float(D.PELEA.amenMax))

func experiencia() -> void:
	var P: Dictionary = S.pelea
	P.xp = int(P.xp) + int(D.PELEA.xp["darko" if B.get("jefe") else ("rival" if B.has("rival") else "thief")])
	var mx := int(D.PELEA.max)
	while nivel_pelea() > int(P.fue) + int(P.ref) and (int(P.fue) < mx or int(P.ref) < mx):
		sfx("get")
		await say("Subes a nivel %d de pelea." % (int(P.fue) + int(P.ref) + 1))
		var f := int(P.fue) < mx
		var r := int(P.ref) < mx
		var o := 0 if f else 1
		if f and r:   # sin cancelar: las dos son una elección
			await type_text("¿Qué entrenas?", "")
			o = await menu(["Fuerza", "Reflejos"], {"cls": "right", "cancel": false})
			if not oraculo:
				dlg.hide()
				dlg_nm.hide()
		if o == 0:
			P.fue = int(P.fue) + 1
			await say("FUERZA %d: cada golpe hace %d más." % [P.fue, P.fue])
		else:
			P.ref = int(P.ref) + 1
			await say("REFLEJOS %d: aciertas, esquivas y escapas mejor." % P.ref)

func ficha_pelea() -> String:   # la fila Pelea de la MOCHILA
	var P: Dictionary = S.pelea
	var nv := nivel_pelea()
	var s := "" if nv >= D.PELEA.nv.size() else " (nivel %d con %d)" % [nv + 1, int(D.PELEA.nv[nv])]
	return "Fuerza %d · reflejos %d · %d de experiencia%s.\nSube ganando peleas: un ladrón da %d, un rival %d." % [int(P.fue), int(P.ref), int(P.xp), s, int(D.PELEA.xp.thief), int(D.PELEA.xp.rival)]

# devuelve lo requisado en texto (cogollos y, si hay, rosin) y la multa
func confiscate(extra_fine := true) -> Array:
	var g := int(floor(total_buds()))
	var ro := total_rosin()
	var fine = min(S.money, int(D.MULTA_CALLE)) if extra_fine else 0
	if B:
		b_anim("E", "multa")
	S.buds = {}
	S.rosin = {}
	S.money -= fine
	S.heat = max(0, S.heat - 15)
	return ["%d g%s" % [g, (" y " + rosin_txt(ro)) if ro else ""], fine]

# el soborno (1.10) sube también con el dinero que llevas encima: un 5 %
func precio_soborno() -> int:
	return Datos.jsround(40 + S.heat * 4 + carga_sosp() * .5 + S.money * .05)

func cop_round():
	var cost := precio_soborno()
	prompt("¿Qué haces?")
	var c: int = await menu(["SOBORNAR", "HABLAR", "HUIR", "ENTREGAR"], {"cls": "battle", "cancel": false})
	if c == 0:
		if await ask("¿Ofrecerle %s con disimulo?" % Datos.eur(cost), ["Sí", "No"]) != 0:
			return null
		if S.money < cost:
			await say("No llevas tanto dinero encima.")
			return null
		if not S.protect and S.ch >= 3 and Cultivo.azar() < .15:
			await say("%s: «¿Me intentas sobornar a mí? Esto me lo quedo.»" % B.name)
			var r := confiscate()
			S.heat = min(100, S.heat + 20)
			sfx("bad")
			await say("Te requisan %s y te multan con %s." % [r[0], Datos.eur(r[1])])
			return "caught"
		S.money -= cost
		S.heat = max(0, S.heat - 10)
		sfx("coin")
		bhud_act()
		b_anim("E", "soborno")
		await say("%s se guarda el sobre. «Aquí no ha pasado nada.»" % B.name)
		return "bribe"
	if c == 1:
		await say("%s: «Solo estaba dando un paseo, agente.»" % S.name)
		if Cultivo.azar() < clampf(.3 + S.rep / 250.0 - S.heat / 300.0, .1, .85):
			await say("%s: «Bien. Circula.»" % B.name)
			return "talk"
		await say("%s: «No. Vacía los bolsillos.»" % B.name)
		var r := confiscate()
		sfx("bad")
		bhud_act()
		await say("Te requisan %s y te multan con %s." % [r[0], Datos.eur(r[1])])
		return "caught"
	if c == 2:
		if Cultivo.azar() < .45 + (.15 if is_night() else 0.0):
			sfx("door")
			S.heat = min(100, S.heat + 8)
			await say("Sales corriendo entre los coches y lo pierdes.")
			return "flee"
		b_anim("E", "perseguir")
		await say("%s te alcanza y te reduce en el suelo." % B.name)
		var r := confiscate()
		S.hp = maxi(1, S.hp - 5)
		sfx("hurt")
		bhud_act()
		await say("Te requisan %s y te multan con %s." % [r[0], Datos.eur(r[1])])
		return "caught"
	var r := confiscate(false)
	bhud_act()
	await say("Le entregas %s. «Buena decisión. Por esta vez, sin multa.»" % r[0])
	return "caught"

# ---------- la caja fuerte, el robo de Darko y los encargos de Baltasar (1.10, 11b-caja) ----------
# la caja: C, la de la tía Maite, detrás del diploma de la Copa de 1998 (la pista está en sus notas del ordenador): 20.000 € y
# 2 kg; B, la empotrada, por el ordenador desde el capítulo 4 (CAJA_P, la instala Kiko al día siguiente): 50.000 € y 2,5 kg.
# Lo que hay dentro no va encima: no cuenta para los encuentros ni te lo quitan un control, un ladrón o Darko. En una redada no la
# tocan (1.11: raid_event; solo pagan de ella la multa que no llegue de fuera). La luz y lo que se compra por el ordenador se pagan de fuera y, si no llega, de la caja
func diploma_action():
	if S.get("caja"):
		await caja_action()
		return
	if await ask("Un diploma enmarcado: «COPA DE RIBERA 1998 · 2º PREMIO: MAITE».", ["Mirar detrás", "Dejarlo"]) != 0:
		return
	await say("Detrás del marco hay una caja fuerte empotrada en la pared. Tiene una rueda de cuatro cifras.")
	var ops := ["1976", "1979", "1987", "1998"]
	var j: int = await ask("¿Qué combinación pruebas?", ops + ["Dejarlo"])
	if j < 0 or j >= ops.size():
		return
	await acceso("rueda", ops[j], int(ops[j]) == int(D.CAJA_ANIO))   # 1.53: las cuatro ruedas
	if int(ops[j]) != int(D.CAJA_ANIO):
		sfx("bump")
		await say("Clac. No se abre.")
		return
	S.caja = {"money": int(D.MAITE_CAJA), "buds": {}, "nivel": 1}
	sfx("get")
	await say("Clic. La caja se abre.")
	await say("Dentro hay %s y una nota de la tía: «Para ti, {N}. Lo que guardes aquí no te lo quita nadie en la calle»." % Datos.eur(D.MAITE_CAJA))
	await say("Caben %s y %s. Lo que está dentro no lo llevas encima." % [Datos.eur(D.CAJA[1].money), _kg(int(D.CAJA[1].g))])
	await sobre_caja()

# al fondo de la caja (1.25), un sobre con semillas de una landrace que no está en el banco (S.flags.cajaSem; las partidas de antes,
# la próxima vez que la abres)
func sobre_caja() -> void:
	S.flags.cajaSem = S.day
	await say("Al fondo de la caja hay un sobre de papel de estraza: «Oaxaca, 1979».")
	await semillas_tia("oaxaca", "Bien secas y a oscuras: siguen buenas.", 3)

# cuánto: los pasos que caben por debajo del máximo y el máximo; 0 si no eliges nada
func cuanto(txt: String, mx: float, pasos: Array, fmt: Callable):
	var ops := []
	for v in pasos:
		if v < mx:
			ops.append(v)
	ops.append(mx)
	var o := ops.map(fmt)
	o.append("Nada")
	var j: int = await ask(txt, o)
	return ops[j] if j >= 0 and j < ops.size() else 0

static func g_txt(g: float) -> String:
	return "%d g" % int(floor(g))

# 1.50: un lote de menos de 10 g, con su décima (0,4 g no es «0 g»); sin CAL, como g_txt
func g_lote(g: float) -> String:
	if Datos.CAL and g > 0 and g < 10 and absf(g - floor(g)) >= .05:
		return Datos.coma(floor(g * 10 + 1e-9) / 10.0) + " g"
	return g_txt(g)

# «300 € y 50 g», «300 €, 50 g y 2 g de rosin» o, sin cogollos, «300 € y 2 g de rosin»
func lo_que(e: float, g: float, r: float) -> String:
	var L := [Datos.eur(e)]
	if g >= 1 or r < .1:
		L.append(g_txt(g))
	if r >= .1:
		L.append(rosin_txt(r))
	return ", ".join(L.slice(0, -1)) + " y " + L[-1]

# lo que cabe todavía en la caja (1.36: solo cogollos; los extractos, en la nevera)
func _hueco(C: Dictionary) -> float:
	return C.g - caja_g()

# 1.36 (lo pidió el usuario): al abrirla, la caja por dentro (rects_almacen): los billetes abren el menú de siempre y un tarro, sacarlo
func caja_action():
	if int(S.caja.nivel) == 1:   # 1.53: la rueda de la tía o, la empotrada, su teclado
		await acceso("rueda", "%04d" % int(D.CAJA_ANIO))
	else:
		await acceso("clave", cifras_acceso("caja"))
	if not S.flags.get("cajaSem"):
		await sobre_caja()
	var i := 0
	while true:
		var e = await elegir_almacen("caja", i)
		if e == null:
			return
		i = e.i
		if e.k == "$":
			await caja_dinero()
			return
		if e.k == "+":   # GUARDAR (1.36)
			await guardar_almacen("caja")
			continue
		var g: float = minf(floor(e.b.g * 10) / 10.0, floor(libre_mochila()))
		if g < 1:
			await say("No te cabe nada más encima.")
			continue
		mover_lote(S.caja.buds, S.buds, e.k, g)
		sfx("sel")
		await say("Sacas %s de %s." % [g_txt(g), lot_nombre(e.k)])

func caja_dinero():   # el menú de siempre (cajaMenu en el HTML; caja_menu es el estilo del menú en ui.gd)
	while true:
		var C: Dictionary = D.CAJA[int(S.caja.nivel)]
		var ops := ["Guardar todo", "Guardar dinero", "Guardar cogollos", "Sacar dinero", "Sacar cogollos", "Sacar todo", "Cerrar"]   # 1.36: los extractos, en la nevera
		var oi: int = await ask("%s: %s (caben %s y %s).\nEncima: %s." % [C.n, lo_que(S.caja.money, caja_g(), 0), Datos.eur(C.money), _kg(int(C.g)),
			lo_que(S.money, total_buds(), 0)], ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Cerrar":
			return
		if op == "Guardar todo":
			var e: float = minf(S.money, C.money - S.caja.money)
			S.money -= e
			S.caja.money += e
			var g := 0.0
			var r := 0.0
			for k in S.buds.keys():
				var q: float = minf(S.buds[k].g, _hueco(C))
				if q < .5:   # menos de medio gramo no es un lote (mover_lote)
					break
				g += q
				mover_lote(S.buds, S.caja.buds, k, q)
			sfx("sel")
			await say("Guardas %s.%s" % [lo_que(e, g, r), " No cabe todo: el resto se queda fuera." if S.money >= 1 or total_buds() >= 1 else ""])
		elif op == "Sacar todo":   # los gramos, hasta el tope de la mochila (1.10)
			var e: float = S.caja.money
			var g := 0.0
			var r := 0.0
			S.money += e
			S.caja.money = 0
			for k in S.caja.buds.keys():
				var q: float = minf(S.caja.buds[k].g, floor(libre_mochila()))
				if q < .5:
					break
				g += q
				mover_lote(S.caja.buds, S.buds, k, q)
			sfx("sel")
			await say("Sacas %s.%s" % [lo_que(e, g, r), " No te cabe todo encima: el resto se queda en la caja." if caja_g() >= .5 else ""])
		elif op == "Guardar dinero" or op == "Sacar dinero":
			var mete := op == "Guardar dinero"
			var mx: float = minf(S.money, C.money - S.caja.money) if mete else float(S.caja.money)
			if mx < 1:
				await say(("No llevas dinero encima." if S.money < 1 else "No cabe más dinero.") if mete else "La caja no tiene dinero.")
				continue
			var e = await cuanto("¿Cuánto guardas?" if mete else "¿Cuánto sacas?", mx, [100, 500, 1000, 5000, 10000, 20000], func(v): return Datos.eur(v))
			if not e:
				continue
			S.money += -e if mete else e
			S.caja.money += e if mete else -e
			sfx("sel")
		else:
			var mete := op == "Guardar cogollos"
			var de: Dictionary = S.buds if mete else S.caja.buds
			var a: Dictionary = S.caja.buds if mete else S.buds
			var lots := []
			for k in de:
				lots.append([k, de[k]])
			if lots.is_empty():
				await say("No llevas cogollos encima." if mete else "La caja no tiene cogollos.")
				continue
			if mete and _hueco(C) < 1:
				await say("No caben más cogollos.")
				continue
			if not mete and libre_mochila() < 1:
				await say("No te cabe nada más encima.")
				continue
			var it := lots.map(lot_item)
			it.append({"label": "Nada"})
			var i: int = await menu(it, {"cls": "right", "title": "¿Qué guardas?" if mete else "¿Qué sacas?"})
			if i < 0 or i >= lots.size():
				continue
			var k: String = lots[i][0]
			var b: Dictionary = lots[i][1]
			var g = await cuanto("%s: ¿cuánto?" % lot_nombre(k), minf(b.g, _hueco(C)) if mete else minf(b.g, floor(libre_mochila())), [10, 50, 100, 500, 1000], func(v): return g_txt(v))
			if not g:
				continue
			mover_lote(de, a, k, g)
			sfx("sel")

# el ordenador: las notas de la tía (la pista de la combinación) y la caja empotrada
func notas_tia():
	await talk("NOTAS DE LA TÍA", ["«Veinte años de cultivos, apuntados día a día.»", "«Lo que no quiero llevar a la calle lo guardo detrás de mi premio. La combinación, el año en que lo gané.»"])

func pedir_caja():
	var C2: Dictionary = D.CAJA[2]
	if await ask("Caja empotrada: %s y %s. Kiko la instala mañana detrás del diploma, con lo que ya tengas dentro. %s." % [Datos.eur(C2.money), _kg(int(C2.g)), Datos.eur(D.CAJA_P)], ["Pedirla", "Nada"]) != 0:
		return
	if S.money + caja_e() < D.CAJA_P:
		sfx("bad")
		await say("No te llega el dinero.")
		return
	pagar_casa(D.CAJA_P)
	S.caja.mejora = 1
	sfx("coin")
	toast("Pedida: caja empotrada · llega mañana", 1400)

func instalar_caja():
	if not S.get("caja") or not S.caja.get("mejora"):
		return
	S.caja.erase("mejora")
	S.caja.nivel = 2
	queue("caja", func():
		sfx("get")
		await talk("SMS · KIKO", ["Ya está: la caja empotrada, detrás del diploma. Lo de la vieja lo tienes dentro.", "Caben %s y %s." % [Datos.eur(D.CAJA[2].money), _kg(int(D.CAJA[2].g))]]))

# el robo de Darko: la primera noche del capítulo 7 que duermes con más de 1.000 € o 100 g fuera de la caja (el rosin cuenta
# como la flor de la que sale: gramos_flor), se llevan la mitad
func robo_darko():
	S.flags.robo = true
	var e := int(floor(S.money / 2.0))
	var g := 0
	var r := 0.0
	for k in S.buds:
		var b: Dictionary = S.buds[k]
		var l := int(floor(b.g / 2.0))
		g += l
		b.g -= l
	for k in S.buds.keys():
		if S.buds[k].g < .5:
			S.buds.erase(k)
	for k in S.rosin.keys():   # y la mitad del rosin, como un ladrón
		var q: float = Datos.jsround(S.rosin[k].g * 5) / 10.0
		r += q
		use_rosin(k, q)
	var A: Dictionary = nevera()   # y la mitad de lo de la nevera (1.36; antes, del arcón)
	for k in A.rosin.keys():
		var q: float = Datos.jsround(A.rosin[k].g * 5) / 10.0
		r += q
		A.rosin[k].g = Datos.jsround((A.rosin[k].g - q) * 10) / 10.0
		if A.rosin[k].g < .1:
			A.rosin.erase(k)
	S.money -= e
	sfx("bad")
	await say("Te despierta un portazo. La cerradura está forzada y el piso, revuelto.")
	await say("Se han llevado %s.%s" % [lo_que(e, g, r), " La caja de detrás del diploma sigue cerrada." if S.get("caja") else ""])
	await talk("SMS · DARKO", ["Te dije que esto no se acababa ahí."])
	if not S.get("caja"):
		await say("Si la tía guardaba sus cosas en algún sitio, ahora te vendría bien saber dónde.")
	save()

# los encargos de Baltasar (capítulo 8): llevar ENCARGO[nivel del imperio] gramos al almacén de los astilleros, de noche, en 2 días,
# a PAGO_ENCARGO €/g. Si no llegas, reputación −10 y 5 días sin encargos
func encargo_baltasar(N: String):
	if S.get("encargo"):
		await say("Toño te espera en el almacén de los astilleros, de noche, con %s. Hasta el %s." % [_kg(int(S.encargo.g)), Datos.fd(S.encargo.hasta, S.day)], N)
		return
	if S.get("encVeto", 0) > S.day:
		await say("Me fallaste, {N}. Vuelve el %s." % Datos.fd(S.encVeto, S.day), N)
		return
	var g := int(D.ENCARGO[imperio_nivel()])
	var pe := int(D.PAGO_ENCARGO)
	await talk(N, ["Ya no me debes nada, {N}. Pero tengo trabajo, si lo quieres.", "%s en el almacén de los astilleros, de noche. Toño los recoge." % _kg(g),
		"Pago %d € el gramo: %s. Tienes %d días." % [pe, Datos.eur(g * pe), int(D.ENCARGO_DIAS)]])
	if cap_mochila() < g:   # 1.13
		var mi := 0
		while D.MOCHILAS[mi].g < g:
			mi += 1
		await say("No te caben en la %s. Hazte con una %s y vuelve." % [D.MOCHILAS[int(S.items.get("bolsa", 0))].n.to_lower(), D.MOCHILAS[mi].n.to_lower()], N)
		return
	if await ask("¿Aceptas el encargo?", ["Aceptar", "No"], N) != 0:
		await say("Tú sabrás. La oferta sigue en pie.", N)
		return
	S.encargo = {"g": g, "hasta": S.day + int(D.ENCARGO_DIAS)}
	await say("Toño estará allí cada noche hasta el %s. No le hagas esperar." % Datos.fd(S.encargo.hasta, S.day), N)
	show_objective()

func talk_tono_almacen():
	var N := "TOÑO"
	if S.get("encargo") == null:   # vencido con él delante (sigue en pantalla hasta el próximo build_ents)
		await say("El plazo se acabó. Don Baltasar ya te escribirá.", N)
		return
	var E: Dictionary = S.encargo
	if not is_night():
		await say("¿De día? ¿Tú estás loco? Vuelve de noche, a partir de las nueve.", N)
		return
	if total_buds() < E.g:
		await say("Don Baltasar dijo %s. Llevas %s. Vuelve con todo." % [_kg(int(E.g)), g_txt(total_buds())], N)
		return
	if await ask("¿Entregas %s? Toño se lleva primero los lotes más flojos." % _kg(int(E.g)), ["Entregar", "Todavía no"], N) != 0:
		return
	var q: float = E.g
	var ls := []
	for k in S.buds:
		ls.append([k, S.buds[k].thc, ls.size()])
	ls.sort_custom(func(a, b): return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))
	for l in ls:
		var k: String = l[0]
		var t: float = minf(q, S.buds[k].g)
		use_buds(k, t)
		q -= t
		if q <= 0:
			break
	var e: int = int(E.g) * int(D.PAGO_ENCARGO)
	S.money += e
	S.sales += e
	S.heat = min(100, S.heat + 3)
	S.rep += 2
	S.encargo = null
	sfx("coin")
	toast("+%s · encargo de Don Baltasar" % Datos.eur(e), 1600)
	await say("Contado. Don Baltasar estará contento.", N)
	await fade(1)
	build_ents()
	await fade(0)
	show_objective()
	await check_story()

func vencer_encargo():
	if not S.get("encargo") or S.day <= S.encargo.hasta:
		return
	S.encargo = null
	S.rep = max(0, S.rep - 10)
	S.encVeto = S.day + int(D.ENCARGO_VETO)
	var L := ["No apareciste. Don Baltasar no se olvida.", "Reputación −10. Nada de encargos hasta el %s." % Datos.fd(S.encVeto, S.day)]
	queue("encargo", func(): await talk("SMS · TOÑO", L), [["SMS · TOÑO", L]])

# ---------- la sala (1.10, 09c-sala): clima y arcón ----------
func t_clima(cl: Dictionary) -> String:
	return "%s °C · %s %%" % [Datos.coma(cl.t), n(cl.hr)]

func _mal(cl: Dictionary) -> String:
	var L := []
	if cl.t < D.T_OK[0]:
		L.append("frío")
	if cl.t > D.T_OK[1]:
		L.append("calor")
	if cl.hr < D.HR_OK[0]:
		L.append("seco")
	if cl.hr > D.HR_OK[1]:
		L.append("húmedo")
	return (" (" + ", ".join(L) + ")") if L.size() else ""

func sala_desc() -> String:
	var d := Cultivo.clima_sala(S, false)
	var nc := Cultivo.clima_sala(S, true)
	var ap := []
	for k in D.APARATOS:
		if k != "termo" and S.sala.get(k):
			ap.append(D.APARATOS[k].n)
	var mes: String = D.MESES[Cultivo.mes_de(int(S.day))]
	var fs := Cultivo.factura_sala(S)
	return "%s · de día %s%s · de noche %s%s\nBien: %s-%s °C y %s-%s %%. Aparatos: %s%s." % [mes.substr(0, 1).to_upper() + mes.substr(1), t_clima(d), _mal(d), t_clima(nc), _mal(nc),
		n(D.T_OK[0]), n(D.T_OK[1]), n(D.HR_OK[0]), n(D.HR_OK[1]), ", ".join(ap) if ap.size() else "ninguno", (" · " + Datos.eur(fs) + " al día") if fs else ""]

# ---------- el móvil (1.10, 12b-movil) ----------
func reloj_txt() -> String:
	return "%02d:%02d" % [int(S.min) / 60, int(S.min) % 60]

func movil_menu():
	ult_app = ""
	while true:
		var ops := ["Llamar"]
		if S.flags.get("kiko1"):
			ops.append("Pedir a Kiko")
		ops.append_array(["Mensajes", "Gente"])
		if S.ch >= int(D.PLANTILLA.ch):
			ops.append("Plantilla")
		ops.append_array(["Banca", "Tienda online", "Calendario", "Mapa", "Colgar"])   # 1.35: la banca (granja.gd); 1.42: el calendario y el mapa (croquis.gd)
		var ns: int = S.sms.size()
		var oi: int
		if Datos.CAL:   # 1.51 (lo pidió el usuario): la pantalla del móvil con sus aplicaciones, como la caja fuerte por dentro
			ops.pop_back()
			oi = await elegir_movil(ops, ops.find(ult_app))
			if oi >= 0:
				ult_app = ops[oi]
		else:
			oi = await ask("MÓVIL · %s, %s%s" % [Datos.fd_hud(S.day).to_lower(), reloj_txt(), (" · %d mensaje%s" % [ns, "s" if ns > 1 else ""]) if ns else ""], ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Colgar":
			return
		if op == "Calendario":
			await elegir_cal()
			continue
		if op == "Mapa":
			await elegir_mapa()
			continue
		if op == "Llamar":
			if await llamar():
				return
		elif op == "Pedir a Kiko":
			await pedir_kiko()
		elif op == "Tienda online":
			await tienda_online()
		elif op == "Banca":
			await banca()
		elif op == "Gente":   # 1.15
			await gente()
		elif op == "Plantilla":   # 1.19
			await plantilla()
		else:
			await mensajes()

# ---------- la pantalla del móvil (1.51, lo pidió el usuario: «que fuese una pantalla de un móvil, con el diseño del juego, estilo a
# cuando abres la caja fuerte»): la carcasa y las aplicaciones a mano (tools/sprites/a-mano/movil.py, misc:mv-*), arriba la hora, la
# cobertura y la batería, la hora en grande y una rejilla de 3 × 3; flechas, A abre y B cuelga. MOVIL_V = {ops, i}
var MOVIL_V = null
var ult_app := ""
const APP_MOVIL := {"Llamar": "llamar", "Pedir a Kiko": "kiko", "Mensajes": "sms", "Gente": "gente", "Plantilla": "plantilla", "Banca": "banca",
	"Tienda online": "tienda", "Calendario": "cal", "Mapa": "mapa"}
const CIFRAS := ["111101101101111", "010110010010111", "111001111100111", "111001111001111", "101101111001001", "111100111001111",
	"111100111101111", "111001010010010", "111101111101111", "111101111001111"]

func desc_movil(V: Dictionary) -> String:
	var op: String = V.ops[V.i]
	var ns: int = S.sms.size()
	var d: String = {"Llamar": "La agenda: Kiko, Toño, Iñaki y los clientes que te han comprado.", "Pedir a Kiko": "Lo del growshop, a casa mañana por la mañana (+%d %%)." % Datos.jsround((D.ENVIO - 1) * 100),
		"Mensajes": ("%d mensaje%s." % [ns, "s" if ns > 1 else ""]) if ns else "No hay mensajes.", "Gente": "La confianza con cada persona.",
		"Plantilla": "Tu gente: la calle, la casa y la nave.", "Banca": "En la cuenta, %s. Movimientos y recibos." % Datos.eur(S.get("banco", 0)),
		"Tienda online": "Con tarjeta; llega al día siguiente.", "Calendario": "El mes, con los días señalados.", "Mapa": "La comarca y las líneas de autobús."}.get(op, "")
	if Datos.CAL:   # 1.52: el tiempo de hoy
		var Ti := Datos.tiempo(int(S.day), int(S.min))
		return "%s · %s, %s\n%s · Fuera: %s, %d °C (máx. %d, mín. %d), %s.\nA: abrir · B: colgar." % [op, Datos.fd_hud(S.day).to_lower(), reloj_txt(), d, Ti.n.to_lower(), Ti.t, Ti.max, Ti.min, Ti.est]
	return "%s · %s, %s\n%s · A: abrir · B: colgar." % [op, Datos.fd_hud(S.day).to_lower(), reloj_txt(), d]

func mueve_movil(V: Dictionary, b: String) -> bool:
	var n: int = V.ops.size()
	var j: int = V.i + {"left": -1, "right": 1, "up": -3, "down": 3}.get(b, 0)
	if j < 0 or j >= n or j == V.i:
		return false
	V.i = j
	return true

func elegir_movil(ops: Array, i0 := 0) -> int:
	if gancho_menu.is_valid():   # las pruebas eligen por la etiqueta, como en el menú de siempre
		var i: int = await menu(ops + ["Colgar"], {"cls": "right", "cancel": true, "title": "MÓVIL"})
		return i if i >= 0 and i < ops.size() else -1
	MOVIL_V = {"ops": ops, "i": clampi(i0, 0, ops.size() - 1)}
	_dlg_fijo(desc_movil(MOVIL_V), "MÓVIL")
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B" or b == "START":   # E11 (fase 3): en mayúsculas, como lo manda press
			pop()
			pr.res(-1)
			return
		if b == "A":
			pop()
			pr.res(MOVIL_V.i)
			return
		if mueve_movil(MOVIL_V, b):
			sfx("sel")
			_dlg_fijo(desc_movil(MOVIL_V), "MÓVIL"))
	var e = await Motor.espera(pr)
	MOVIL_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	return int(e)

func _ancho_cifras(t: String, k := 1) -> int:
	var w := 0
	for ch in t:
		w += (2 if ch == ":" else 4) * k
	return w

# 1.52: el dibujo del tiempo, 13 × 9 (. vacío, s sol, n nube, m sombra de la nube, g gota, r rayo, b nieve, f niebla)
const ICONO_TIEMPO := {
	"sol": ["......s......", "..s...s...s..", "....sssss....", "...sssssss...", "ssssssssssss.", "...sssssss...", "....sssss....", "..s...s...s..", "......s......"],
	"nubes": ["...s..s......", ".....sss.....", "..ssssnnn....", "...ssnnnnn...", ".ssnnnnnnnnn.", "..nnnnnnnnnnn", "..nnnnnnnnnnn", "...mmmmmmmmm.", "............."],
	"lluvia": [".....nnn.....", "...nnnnnnn...", "..nnnnnnnnnn.", ".nnnnnnnnnnnn", ".nnnnnnnnnnnn", "..mmmmmmmmmm.", "..g..g..g..g.", ".g..g..g..g..", "............."],
	"niebla": ["....nnnnn....", "..nnnnnnnnn..", "..mmmmmmmmm..", ".............", "ffffffffffff.", ".............", ".ffffffffffff", ".............", "fffffffffff.."],
	"tormenta": [".....mmm.....", "...mmmmmmm...", "..mmmmmmmmmm.", ".mmmmmmmmmmmm", "..mmmmrmmmmm.", "....g.rr..g..", "...g..rrr.g..", "........r....", "........r...."],
	"nieve": [".....nnn.....", "...nnnnnnn...", "..nnnnnnnnnn.", ".nnnnnnnnnnnn", "..mmmmmmmmmm.", ".b...b...b...", "...b...b...b.", ".b...b...b...", "............."]}
const COLOR_TIEMPO := {"s": "#f8c030", "n": "#e4ecf4", "m": "#9aa8b8", "g": "#6ab0f0", "r": "#f8e060", "b": "#ffffff", "f": "#b8c4cc"}

func _icono_tiempo(o: Array, x: int, y: int, k: String) -> void:
	var F: Array = ICONO_TIEMPO.get(k, ICONO_TIEMPO.sol)
	for j in F.size():
		for i in F[j].length():
			var c: String = F[j][i]
			if c != ".":
				o.append([x + i, y + j, 1, 1, COLOR_TIEMPO[c]])

func _cifras(o: Array, x: int, y: int, t: String, c: String, k := 1) -> int:
	for ch in t:
		if ch == "-":
			o.append([x, y + 2 * k, 3 * k, k, c])
			x += 4 * k
			continue
		if ch == ":":
			o.append_array([[x, y + k, k, k, c], [x, y + 3 * k, k, k, c]])
			x += 2 * k
			continue
		var f: String = CIFRAS[int(ch)]
		for q in 15:
			if f[q] == "1":
				o.append([x + (q % 3) * k, y + (q / 3) * k, k, k, c])
		x += 4 * k
	return x

func rects_movil(V: Dictionary) -> Array:
	var o := []
	var x0: int = (SW - 80) >> 1
	var y0: int = maxi(2, (alto_libre() - 120) >> 1)
	o.append(["@", "mv-movil", x0, y0])
	var sx := x0 + 5
	var sy := y0 + 9
	_cifras(o, sx + 3, sy + 2, reloj_txt(), "#d8f0e0")
	for q in 4:   # la cobertura y la batería
		o.append([sx + 47 + q * 2, sy + 6 - q, 1, q + 1, "#d8f0e0"])
	o.append_array([[sx + 57, sy + 2, 9, 5, "#d8f0e0"], [sx + 58, sy + 3, 7, 3, "#0a1e14"], [sx + 58, sy + 3, 5, 3, "#7cd08a"], [sx + 66, sy + 3, 1, 3, "#d8f0e0"]])
	if Datos.CAL:   # 1.52: la hora ya está en el HUD; en grande, el tiempo de fuera con su dibujo
		var Ti := Datos.tiempo(int(S.day), int(S.min))
		var tt := str(Ti.t)
		var w := 13 + 4 + _ancho_cifras(tt, 2) + 5
		var x := sx + ((70 - w) >> 1)
		_icono_tiempo(o, x, sy + 11, Ti.k)
		x = _cifras(o, x + 17, sy + 10, tt, "#e8f8ec", 2)
		o.append_array([[x, sy + 10, 3, 1, "#e8f8ec"], [x, sy + 12, 3, 1, "#e8f8ec"], [x, sy + 11, 1, 1, "#e8f8ec"], [x + 2, sy + 11, 1, 1, "#e8f8ec"]])   # °
	else:
		var hh := reloj_txt()
		_cifras(o, sx + ((70 - 34) >> 1), sy + 10, hh, "#e8f8ec", 2)
	var ns: int = S.sms.size()
	for q in V.ops.size():
		var x: int = sx + 4 + (q % 3) * 22
		var y: int = sy + 23 + (q / 3) * 23
		o.append(["@", "mv-" + str(APP_MOVIL.get(V.ops[q], "sms")), x, y])
		if V.ops[q] == "Mensajes" and ns:
			o.append_array([[x + 12, y - 2, 7, 7, "#2a2a34"], [x + 13, y - 1, 5, 5, "#e03838"]])
			_cifras(o, x + 14, y - 1, str(mini(ns, 9)), "#ffffff")
		if q == V.i:
			_marco(o, x - 2, y - 2, 22, 22)
	return o

# devuelve true si ha venido un cliente (el móvil se cierra)
func llamar() -> bool:
	var C := []
	if S.flags.get("kiko1"):
		C.append({"label": "Kiko", "right": "growshop", "desc": "Consejos de cultivo. Los pedidos, desde «Pedir a Kiko».", "k": "kiko"})
	if S.flags.get("tono"):
		C.append({"label": "Toño", "right": "Don Baltasar", "desc": "Lo que debes y hasta cuándo.", "k": "tono"})
	if S.flags.get("inaki"):
		C.append({"label": "Iñaki", "right": "muelle", "desc": "Compra al por mayor.", "k": "inaki"})
	for f in S.fijos:
		C.append({"label": f.n, "right": etiqueta_ct(f.t, mujer_nombre(f.n)).to_lower(), "desc": "Ya ha venido hoy." if f.dia == S.day else "Te compró en la calle. Si estás fuera, viene a buscarte.", "f": f})
	if C.is_empty():
		await say("La agenda está vacía.")
		return false
	var items := C.duplicate()
	items.append({"label": "Nada"})
	var i: int = await menu(items, {"cls": "right", "title": "LLAMAR"})
	if i < 0 or i >= C.size():
		return false
	var c: Dictionary = C[i]
	match c.get("k", ""):
		"kiko":
			await talk("KIKO", [kiko_tip()])
			return false
		"tono":
			await talk("TOÑO", [("Te quedan %s hasta el %s. Don Baltasar no espera." % [Datos.eur(S.due), Datos.fd(S.deadline, S.day)]) if S.due > 0 else "Ahora mismo no debes nada. Que siga así."])
			return false
		"inaki":
			await talk("IÑAKI", ["Ahora estoy en la mar. A la vuelta hablamos." if S.ch < 3 else ("Hoy ya he cargado. Mañana sale otro barco." if S.mDay == S.day else "Al por mayor, de 100 g para arriba y hasta %s por carga. Pásate por el muelle." % _kg(mayor_dia()))])
			return false
	return await fijo_menu(c.f)   # 1.15: que venga, un regalo o que venda para ti

func llamar_fijo(f: Dictionary) -> bool:
	if f.dia == S.day:
		await say("%s ya ha venido hoy." % f.n)
		return false
	if not D.ZONAS.has(S.map):
		await say("%s: «¿Dónde estás? Quedamos en la calle»." % f.n)
		return false
	if SOSP.alarma:
		await say("%s: «¿Con la policía detrás? Ni de broma»." % f.n)
		return false
	var ct: Dictionary = D.CTYPES[f.t]
	S.heat = minf(100, S.heat + 1)
	await say("%s: «Vale, voy para allá»." % f.n)
	advance_time(int(D.LLAMADA_MIN))
	update_hud()
	if not S.fijos.any(func(x): return x.id == f.id):   # 1.22: se ha largado a medianoche mientras venía (curro_dia)
		return true
	f.dia = S.day
	await talk_client({"id": "tel-" + f.id, "fijo": true, "fid": f.id, "n": f.n.to_upper(), "map": S.map, "x": P.x, "y": P.y, "type": f.t, "want": ri(int(ct.g[0]), int(ct.g[1])),
		"minThc": mini(24, 15 + int(S.ch)) if f.t == "pij" or f.t == "vip" else 0})   # 1.30: el VIP de GAUA, como un pijo
	return true

# lo que Kiko manda a casa: lo del growshop que no son semillas, carpas ni la prensa, más caro; lo que ya está pedido no se repite
func precio_envio(it: Dictionary) -> int:
	return Datos.jsround(it.p * D.ENVIO)

func pedible(it: Dictionary) -> bool:
	return not it.get("sid") and not it.get("carpa") and not it.get("mueble") and it.get("item") != "prensa" and S.ch >= it.ch and shop_cond(it)   # shop_cond ya cuenta lo pedido

func pedir_kiko():
	var i := 0
	var ult := ""
	while true:
		var l := []
		for it in D.SHOP:
			if pedible(it):
				if it.lbl == ult:   # el cursor, en lo último pedido si sigue en la lista
					i = l.size()
				l.append(it)
		var items := []
		for it in l:
			var nn: int = S.envio.count(it.lbl)
			items.append({"label": it.lbl + ((" · ×%d" % nn) if nn else ""), "right": Datos.eur(precio_envio(it)), "desc": it.get("desc", "")})
		items.append({"label": "Salir", "desc": "Lo pedido llega mañana por la mañana a casa."})
		i = await menu(items, {"cls": "full", "title": "PEDIR A KIKO", "title2": "Envío a casa +%d %% · tienes %s" % [Datos.jsround((D.ENVIO - 1) * 100), Datos.eur(S.money)], "desc": true, "initial": i})
		if i < 0 or i >= l.size():
			return
		var it: Dictionary = l[i]
		var e := precio_envio(it)
		if S.money < e:
			sfx("bad")
			await say("No te llega el dinero.")
			continue
		S.money -= e
		S.envio.append(it.lbl)
		ult = it.lbl
		sfx("coin")
		toast("Pedido: " + it.lbl + " · llega mañana", 1400)

func recibir_envio():
	if S.envio.is_empty():
		return
	var c := {}
	for lbl in S.envio:
		var it = null
		for x in D.SHOP:
			if x.lbl == lbl:
				it = x
				break
		if it == null:
			continue
		c[lbl] = c.get(lbl, 0) + 1
		if it.get("item"):
			S.items[it.item] += int(it.get("n", 1))
		if it.get("maceta"):
			S.items["m_" + it.maceta] += 1
		if it.get("foco"):
			S.items["f_" + it.foco] += 1
		if it.get("extra"):
			S.items["x_" + it.extra] += 1
		if it.get("bolsa"):
			S.items.bolsa = maxi(int(S.items.get("bolsa", 0)), int(it.bolsa))
		if it.get("aparato"):
			S.sala[it.aparato] = true
	S.envio = []
	var L := []
	for lbl in c:
		L.append(("%s ×%d" % [lbl, c[lbl]]) if c[lbl] > 1 else lbl)
	var t := ", ".join(L)
	var av := ["Te he dejado el paquete en casa: %s." % t]
	queue("envio", func(): await talk("SMS · KIKO", av), [["SMS · KIKO", av]])

func mensajes():
	if S.sms.is_empty():
		await say("No tienes mensajes.")
		return
	var i := 0
	while true:
		var items := []
		for m in S.sms:
			items.append({"label": m.n, "right": Datos.fd_corto(m.d), "desc": m.t})
		i = await menu(items, {"cls": "full", "title": "MENSAJES", "title2": "%d de %s" % [S.sms.size(), n(D.SMS_MAX)], "desc": true, "initial": i})
		if i < 0:
			return

# =========================================================
# LA GENTE (1.15, 11e-gente): trabajadores, clubs y la cata (la confianza, en mundo.gd)
# =========================================================
func curro_dia() -> void:
	var C: Dictionary = S.curro
	var J: Dictionary = D.CURRO.jard
	var V: Dictionary = D.CURRO.vend
	if C.get("jard"):
		if S.money < J.sueldo:
			C.jard = null
			confia("begona", -10)
			var L := ["Sin cobrar no vuelvo, majo. Cuando tengas el dinero, hablamos."]
			queue("jard", func(): await talk("SMS · BEGOÑA", L), [["SMS · BEGOÑA", L]])
		else:
			S.money -= int(J.sueldo)
			cuidar_plantas()
			S.heat = min(100, S.heat + J.calor)
	var fin := []
	var vende := false
	for v in C.vend:
		var r := Cultivo.azar()
		var N: String = "SMS · " + v.n.to_upper()
		if r < V.pilla:
			fin.append(v)
			S.heat = min(100, S.heat + V.calorPilla)
			confia(v.id, -5)
			var L := ["Me ha parado la policía. Se han quedado con %s de %s. Lo siento." % [g_txt(v.g), lot_nombre(v.k)]]
			queue("vend" + v.id, func(): await talk(N, L), [[N, L]])
			continue
		if r < V.pilla + V.estafa * (D.REL.max - rel(v.id)) / D.REL.max:
			fin.append(v)
			S.fijos = S.fijos.filter(func(f): return f.id != v.id)
			S.rel[v.id] = 0
			var L := ["%s no contesta al móvil. Se ha largado con %s de %s." % [v.n, g_txt(v.g), lot_nombre(v.k)]]
			queue("vend" + v.id, func(): await say(L[0]), [["", L]])
			continue
		var g: int = mini(int(floor(v.g)), ri(int(V.g[0]), int(V.g[1])))
		var e := Datos.jsround(precio_calle(v.thc) * calidad(v) * D.ZONAS.town.precio * g * (1 - V.com))
		v.g -= g
		S.money += e
		S.sales += e
		S.heat = min(100, S.heat + V.calor)
		confia(v.id, 1)
		vende = true
		if v.g < 1:
			fin.append(v)
			var L := ["Vendidos los últimos %d g: %s en tu buzón. Si quieres que siga, déjame más." % [g, Datos.eur(e)]]
			queue("vend" + v.id, func(): await talk(N, L), [[N, L]])
		else:
			var L := ["Vendidos %d g: %s en tu buzón. Me quedan %s." % [g, Datos.eur(e), g_txt(v.g)]]
			queue("vend" + v.id, func(): await talk(N, L), [[N, L]])
	if fin.size():
		C.vend = C.vend.filter(func(v): return not fin.has(v))
	if vende:   # 1.22: lo vendido cuenta para la historia
		queue("historia", check_story)
	plantilla_dia()   # la plantilla (1.19)
	aso_dia()   # la asociación (1.32)
	mar_dia()   # 1.51: los envíos por mar y el piso franco
	franco_dia()

# regar, tratar las plagas con tu insecticida y rellenar garrafas y depósitos (Begoña y el gerente de la plantilla)
func cuidar_plantas() -> void:
	for p in S.pots:
		if p == null or p.get("dead"):
			continue
		p.water = 100
		if p.get("pest") and S.items.insect > 0:
			S.items.insect -= 1
			p.pest = false
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if c == null:
			continue
		if c.get("garrafas"):
			c.erase("gar")
		if c.get("goteo"):
			c.dep = Cultivo.goteo_l(S, ci)

func _vend_de(id: String):
	for v in S.curro.vend:
		if v.id == id:
			return v
	return null

# un cliente de la agenda, desde el móvil: que venga, un regalo (una vez al día), cómo va su venta o que venda para ti
func fijo_menu(f: Dictionary) -> bool:
	var v = _vend_de(f.id)
	var puede: bool = rel(f.id) >= D.REL.socio and S.curro.vend.size() < D.CURRO.vend.max
	var ops := ["Que venga"]
	if total_buds() >= D.REL.regaloG:
		ops.append("Regalarle %d g" % int(D.REL.regaloG))
	if v:
		ops.append("Cómo va la venta")
	elif puede:
		ops.append("Que venda para mí")
	ops.append("Nada")
	var oi: int = await ask("%s · %s · confianza %d (%s)" % [f.n, etiqueta_ct(f.t, mujer_nombre(f.n)).to_lower(), rel(f.id), rel_nivel(f.id)], ops)
	var op: String = ops[oi]
	if op == "Que venga":
		return await llamar_fijo(f)
	if op.begins_with("Regalarle"):
		if f.get("regalo") == S.day:
			await say("%s: «¿Otra vez? Gracias, pero hoy ya me has invitado»." % f.n)
			return false
		var lots := bud_lots(D.REL.regaloG)
		var it := lots.map(lot_item)
		it.append({"label": "Nada"})
		var i: int = await menu(it, {"cls": "right", "title": "¿Qué le regalas?"})
		if i < 0 or i >= lots.size():
			return false
		use_buds(lots[i][0], D.REL.regaloG)
		f.regalo = S.day
		confia(f.id, int(D.REL.regalo))
		sfx("get")
		await say("%s: «¡Gracias! Se lo cuento a todo el mundo»." % f.n)
		return false
	if op == "Cómo va la venta":
		await say("%s: «Me quedan %s de %s. Cada día vendo lo que puedo y te dejo el %d %% en el buzón»." % [f.n, g_txt(v.g), lot_nombre(v.k), Datos.jsround((1 - D.CURRO.vend.com) * 100)])
		return false
	if op == "Que venda para mí":
		return await contratar_vendedor(f)
	return false

func contratar_vendedor(f: Dictionary) -> bool:
	var V: Dictionary = D.CURRO.vend
	var lots := bud_lots(V.lotes[0])
	if lots.is_empty():
		await say("%s: «Cuando tengas %d g o más, hablamos»." % [f.n, int(V.lotes[0])])
		return false
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote le dejas?"})
	if i < 0 or i >= lots.size():
		return false
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var ops := []
	for g in V.lotes:
		if g <= floor(b.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g" % g)
	o.append("Nada")
	var j: int = await ask("%s vende a precio de calle y se queda el %d %%. ¿Cuánto le dejas?" % [f.n, Datos.jsround(V.com * 100)], o)
	if j < 0 or j >= ops.size():
		return false
	use_buds(k, ops[j])
	var vd := {"id": f.id, "n": f.n, "k": k, "thc": b.thc, "g": ops[j]}
	vd.merge(cura_de(b))
	S.curro.vend.append(vd)
	sfx("sel")
	await say("%s: «Hecho. Cada día te dejo lo vendido en el buzón»." % f.n)
	return false

# MÓVIL → GENTE: a quién conoces y cuánto se fía de ti
func gente() -> void:
	var rows := []
	for id in D.GENTE:
		if S.rel.has(id):
			rows.append({"label": D.GENTE[id], "right": "%d · %s" % [rel(id), "jardinera" if id == "begona" and S.curro.get("jard") else rel_nivel(id)], "desc": D.QUE_DA.get(id, "Hablar cada día suma confianza.")})
	for k in D.CLUBS:
		var P = D.PRESI.get(k)
		var no: String = (" Para que te compren, %d con %s y con %s %s." % [int(D.CLUB.confia), D.GENERO.enc.get(k, "el encargado") if Datos.CAL else "el encargado", P.a, P.t]) if P and not club_te_compra(k) else ""
		if S.rel.has(k):
			rows.append({"label": D.CLUBS[k].n, "right": "%d · %s" % [rel(k), rel_nivel(k)], "desc": ("Eres socio. Vender y cumplir los encargos suma." if S.clubs.get(k) else "Hazte socio para vender y comprar.") + no})
		if P and S.rel.has("pres_" + k):
			rows.append({"label": P.n, "right": "%d · %s" % [rel("pres_" + k), rel_nivel("pres_" + k)], "desc": "%s %s de %s. Hablar e invitarle suma.%s" % ["El" if P.a == "el" else "La", P.t, D.CLUBS[k].n, no]})
	for f in S.fijos:
		var v = _vend_de(f.id)
		rows.append({"label": f.n, "right": "%d · %s" % [rel(f.id), "vende para ti" if v else rel_nivel(f.id)],
			"desc": ("Le dejaste %s: le quedan %s." % [lot_nombre(v.k), g_txt(v.g)]) if v else "Cliente de la agenda. Buen precio y regalos suman; con %d vende para ti." % int(D.REL.socio)})
	if rows.is_empty():
		await say("Todavía no conoces a nadie.")
		return
	var i := 0
	while true:
		i = await menu(rows, {"cls": "full", "title": "GENTE", "title2": "%d persona%s" % [rows.size(), "s" if rows.size() > 1 else ""], "desc": true, "initial": i})
		if i < 0:
			return

# Begoña (la vecina): consejos, un regalo al día y, con confianza y desde el capítulo 3, la jardinera
const BEGONA_TIPS := ["Bajo una lámpara las plantas beben mucho. Riégalas a diario, majo.", "Si se te ponen amarillas las hojas de abajo, les falta agua o abono.", "Tu tía siempre tenía el piso oliendo a limón. Ahora sé por qué."]
func talk_begona():
	var N := "BEGOÑA"
	var J: Dictionary = D.CURRO.jard
	if S.curro.get("jard"):
		var c: int = await ask("¿Qué tal las plantas, majo? Paso cada mañana: %s al día." % Datos.eur(J.sueldo), ["Charlar", "Que lo deje", "Nada"], N)
		if c == 0:
			await say(pick(BEGONA_TIPS), N)
		elif c == 1:
			S.curro.jard = null
			await say("Como quieras. Si me necesitas, aquí estoy.", N)
		return
	var ops := ["Charlar"]
	if total_buds() >= D.REL.regaloG:
		ops.append("Regalarle %d g" % int(D.REL.regaloG))
	if S.ch >= J.ch and rel("begona") >= D.REL.amigo:
		ops.append("Contratarla")
	ops.append("Nada")
	var oi: int = await ask("Tu tía me dejaba cuidarle las plantas cuando se iba. Con confianza, se habla de todo." if S.ch >= J.ch and rel("begona") < D.REL.amigo else "Hola, majo. ¿Cómo van esas plantas?", ops, N)
	var op: String = ops[oi]
	if op == "Charlar":
		await say(pick(BEGONA_TIPS), N)
	elif op.begins_with("Regalarle"):
		if S.flags.get("regBeg") == S.day:
			await say("Hoy ya me has dado, majo. Mañana más.", N)
			return
		var lots := bud_lots(D.REL.regaloG)
		var it := lots.map(lot_item)
		it.append({"label": "Nada"})
		var i: int = await menu(it, {"cls": "right", "title": "¿Qué le das?"})
		if i < 0 or i >= lots.size():
			return
		use_buds(lots[i][0], D.REL.regaloG)
		S.flags.regBeg = S.day
		confia("begona", int(D.REL.regalo))
		sfx("get")
		await say("Ay, gracias. Para dormir, como hacía tu tía.", N)
	elif op == "Contratarla":
		if await ask("Te riego, relleno las garrafas y el depósito y, si tienes insecticida, trato las plagas. %s al día, cada mañana. ¿Hecho?" % Datos.eur(J.sueldo), ["Hecho", "Ahora no"], N) != 0:
			return
		S.curro.jard = {"dia": S.day}
		await say("Mañana empiezo. Ya sé dónde dejaba la llave tu tía.", N)

# los clubs cannábicos (CLUBS): el carné, vender un lote al día, comprar 10 g y encargos de semillas
func precio_club(thc: float) -> float:
	return 3 + thc * .15

# el carné (la cuota, una vez); 1.30: también en la puerta, la primera vez que entras (entra_local). true si eres socio
func carne_club(k: String) -> bool:
	var C: Dictionary = D.CLUBS[k]
	var N: String = C.n
	if await ask("%s%s. Dentro no se vende nada: lo tuyo entra por la puerta de atrás. La cuota son %s. ¿Te haces socio?" % [C.n, "" if k == "rv" else ", asociación de consumidores", Datos.eur(C.cuota)], ["Hacerme socio", "No"], N) != 0:
		return false
	if S.money < C.cuota:
		sfx("bad")
		await say("Sin la cuota no hay carné.", N)
		return false
	S.money -= int(C.cuota)
	S.clubs[k] = true
	S.rep += 1
	confia(k, 2)
	sfx("coin")
	await got("el carné de " + C.n)
	return true

# el encargado de cada club; 1.30: dentro, detrás de la vitrina del dispensario
func talk_club(k: String):
	var N: String = D.CLUBS[k].n
	if D.CLUBS[k].get("tuyo"):   # 1.52: el club KAIA, el tuyo
		await talk_kaia(N)
		return
	if not S.clubs.get(k):
		if not await carne_club(k):
			return
	var E = S.get("clubEnc")
	var ops := ["Vender al club", ("Comprar" if Datos.CAL else "Comprar %d g" % int(D.CLUB.compra)), "Entregar las semillas" if E and E.k == k else "Encargo de semillas"]
	if D.PRESI.has(k) and rel(k) < D.CLUB.confia and total_buds() >= D.REL.regaloG:
		ops.append("Invitar a %d g" % int(D.REL.regaloG))
	ops.append("Nada")
	var oi: int = await ask("¿Qué te trae?", ops, N)
	var op: String = ops[oi]
	if op == "Vender al club":
		await vender_club(k)
	elif op.begins_with("Comprar"):
		await comprar_club(k)
	elif op.begins_with("Invitar"):
		await invitar_club(k, k, N)
	elif op.begins_with("Entregar") or op.begins_with("Encargo"):
		await encargo_club(k)

# 1.34 (PRESI): fuera del barrio, un club solo te compra (lotes y encargos) si se fían de ti el encargado y su presidente
func club_te_compra(k: String) -> bool:
	return not D.PRESI.has(k) or (rel(k) >= D.CLUB.confia and rel("pres_" + k) >= D.CLUB.confia)

func no_compra(k: String) -> void:
	var P: Dictionary = D.PRESI[k]
	var e: bool = rel(k) < D.CLUB.confia
	var p: bool = rel("pres_" + k) < D.CLUB.confia
	var de: String = "%s, %s %s" % [P.n, P.a, P.t]
	await say("Aquí no compramos a cualquiera. Antes te tienes que ganar %s." % (("mi confianza y la de " + de) if e and p else ("mi confianza" if e else "la confianza de " + de)), D.CLUBS[k].n)

# invitar a probar REL.regaloG g (al encargado, id = k, o al presidente, "pres_" + k); si con eso ya se fían los dos, lo dicen
func invitar_club(id: String, k: String, N: String) -> void:
	if S.clubReg.get(id) == S.day:
		await say("Hoy ya me has invitado. Otro día.", N)
		return
	var lots := bud_lots(D.REL.regaloG)
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué le das a probar?"})
	if i < 0 or i >= lots.size():
		return
	var antes := club_te_compra(k)
	use_buds(lots[i][0], D.REL.regaloG)
	S.clubReg[id] = S.day
	confia(id, int(D.REL.regalo))
	sfx("get")
	await say("Mm. Esto no es de cualquiera. Gracias.", N)
	if not antes and club_te_compra(k):
		sfx("get")
		await say("Desde hoy, %s te compra. Lo tuyo, por la puerta de atrás." % D.CLUBS[k].n, N)

func talk_presi(k: String):
	var P: Dictionary = D.PRESI[k]
	var N: String = P.n.to_upper()
	var id: String = "pres_" + k
	var ops := ["Charlar"]
	if total_buds() >= D.REL.regaloG:
		ops.append("Invitar a %d g" % int(D.REL.regaloG))
	ops.append("Nada")
	var oi: int = await ask("Hombre, {N}. Lo tuyo tiene buena fama entre los socios." if rel(id) >= D.CLUB.confia else "Soy %s, %s %s del club. A ti todavía no te conozco." % [P.n, P.a, P.t], ops, N)
	var op: String = ops[oi]
	if op == "Charlar":
		await say(D.PRESI_TXT[(int(S.day) + D.PRESI.keys().find(k)) % D.PRESI_TXT.size()], N)
	elif op.begins_with("Invitar"):
		await invitar_club(id, k, N)

func vender_club(k: String) -> void:
	var C: Dictionary = D.CLUBS[k]
	var N: String = C.n
	if not club_te_compra(k):
		await no_compra(k)
		return
	var resto: float = resto_mer("club_" + k, D.MERCADO.club.tope) if Datos.CAL else 1e9   # 1.45: varios lotes al día, hasta el tope
	if (S.clubDia.get(k) == S.day and not Datos.CAL) or resto < 1:
		await say("Hoy ya hemos cerrado caja. Mañana.", N)
		return
	var VX: Dictionary = D.VENTA_EXTR
	var lots := lotes_venta(D.CLUB.g[0], VX.club_g[0])
	if lots.is_empty():
		await say("De %d g para arriba, entre %s y %s € el gramo según el THC. Una entrega al día." % [int(D.CLUB.g[0]), _dos(precio_club(12)), _dos(precio_club(30))] + (" Extracciones, de %d g para arriba." % int(VX.club_g[0]) if Datos.CAL else ""), N)
		return
	var it := lots.map(venta_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		return
	var l: Array = lots[i]
	var x := es_extr(l)
	var kk: String = l[0]
	var b: Dictionary = l[1]
	var pg := Datos.jsround((precio_extr(kk, b.thc, "club") if x else precio_club(b.thc)) * calidad(b) * (1.05 if b.get("ana") else 1.0) * 100) / 100.0
	var ops := []
	for g in (VX.club_g if x else D.CLUB.g):
		if g <= floor(b.g) and (g / D.ROSIN.rend if x else float(g)) <= resto:
			ops.append(int(g))
	if ops.is_empty():
		await say("Hoy ya no nos cabe tanto. Algo más pequeño, o mañana.", N)
		return
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(g * pg)])
	o.append("Nada")
	var j: int = await ask("%s a %s € el gramo%s. ¿Cuánto?" % [venta_nombre(l), _dos(pg), " (analizado)" if b.get("ana") else ""], o, N)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	var e := Datos.jsround(g * pg)
	usa_lote(l, g)
	S.money += e
	S.sales += e
	S.heat = min(100, S.heat + D.CLUB.calor)
	S.rep += 1
	S.clubDia[k] = S.day
	if Datos.CAL:
		suma_mer("club_" + k, g / D.ROSIN.rend if x else float(g))
	confia(k, 2)
	sfx("coin")
	await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
	toast("+%s · %d g %sal club" % [Datos.eur(e), g, ("de " + extr_nombre(kk, true).get_slice(" de ", 0) + " ") if x else ""], 1600)
	await say("Por la puerta de atrás, como siempre. Gracias.", N)
	await check_story()

func comprar_club(k: String) -> void:
	var C: Dictionary = D.CLUBS[k]
	var N: String = C.n
	if Datos.CAL:   # 1.45: el dispensario del club, con varias variedades y extracciones
		var pool: Array = C.sid.duplicate()
		for b in D.BANCO:
			if int(b[2]) <= int(S.ch) and not b[0] in pool:
				pool.append(b[0])
		await comprar_mercado("club_" + k, N, pool)
		return
	if S.clubCompra.get(k) == S.day:
		await say("Lo de hoy ya está repartido. Mañana hay más.", N)
		return
	var sid: String = C.sid[int(S.day) % C.sid.size()]
	var s: Dictionary = D.STRAINS[sid]
	var p := Datos.jsround(precio_calle(s.thc) * D.CLUB.compraF * D.CLUB.compra)
	if await ask("Hoy tenemos %s (%s %%): %d g por %s. ¿Te los llevas?" % [s.n, Datos.pct(s.thc), int(D.CLUB.compra), Datos.eur(p)], ["Comprar", "No"], N) != 0:
		return
	if S.money < p:
		sfx("bad")
		await say("Sin dinero no hay reparto.", N)
		return
	if libre_mochila() < D.CLUB.compra:
		await say("No te caben en la bolsa.", N)
		return
	S.money -= p
	S.clubCompra[k] = S.day
	confia(k, 1)
	add_buds(sid, D.CLUB.compra, s.thc, S.buds, 1)
	discover(sid)
	sfx("coin")
	toast("Comprado: %d g de %s" % [int(D.CLUB.compra), s.n], 1200)

func encargo_club(k: String) -> void:
	var N: String = D.CLUBS[k].n
	var E = S.get("clubEnc")
	var EN: Dictionary = D.CLUB.enc
	if E:
		if E.k != k:
			await say("Ya tienes un encargo pendiente en %s. Cumple ese primero." % D.CLUBS[E.k].n, N)
			return
		var s = strain(E.sid)
		var t: int = int(S.seeds.get(E.sid, 0))
		if t < E.n:
			await say("Nos faltan %d semillas de %s. Hasta el %s." % [int(E.n) - t, s.n, Datos.fd(E.hasta, S.day)], N)
			return
		S.seeds[E.sid] = t - int(E.n)
		if not S.seeds[E.sid]:
			S.seeds.erase(E.sid)
		S.money += int(E.pago)
		S.sales += int(E.pago)
		S.rep += 3
		confia(k, 5)
		S.clubEnc = null
		S.clubEncDia = S.day
		sfx("coin")
		toast("+%s · %d semillas de %s" % [Datos.eur(E.pago), int(E.n), s.n], 1600)
		await say("Las sembramos para los socios. Buen trabajo.", N)
		await check_story()
		return
	if not club_te_compra(k):
		await no_compra(k)
		return
	if S.clubEncDia == S.day:
		await say("Hoy ya no hay más encargos. Mañana.", N)
		return
	var cand := []
	for it in D.SHOP:
		if it.get("sid") and S.ch >= it.ch:
			cand.append([it.sid, Datos.jsround(it.p * EN.n * EN.f)])
	if S.ch >= 4:
		var vistos := []
		for h in D.RECIPES:
			var sr: String = D.RECIPES[h]
			if not vistos.has(sr):
				vistos.append(sr)
				if S.disc.get(sr):
					cand.append([sr, int(EN.receta) * int(EN.n)])
	var el: Array = pick(cand)
	var sid: String = el[0]
	var pago: int = el[1]
	var s: Dictionary = D.STRAINS[sid]
	if await ask("Los socios quieren %d semillas de %s. Pagamos %s, en %d días. ¿Te encargas?" % [int(EN.n), s.n, Datos.eur(pago), int(EN.dias)], ["Aceptar", "No"], N) != 0:
		await say("Si cambias de idea, aquí estamos.", N)
		return
	S.clubEnc = {"k": k, "sid": sid, "n": int(EN.n), "hasta": S.day + int(EN.dias), "pago": pago}
	await say("Hasta el %s. Las semillas, aquí." % Datos.fd(S.clubEnc.hasta, S.day), N)

func vencer_encargo_club() -> void:
	var E = S.get("clubEnc")
	if E == null or S.day <= E.hasta:
		return
	S.clubEnc = null
	S.rep = maxi(0, S.rep - 3)
	confia(E.k, -10)
	var Nc: String = "SMS · " + D.CLUBS[E.k].n
	var L := ["Se acabó el plazo de las semillas. Los socios no se olvidan."]
	queue("clubEnc", func(): await talk(Nc, L), [[Nc, L]])

# la cata (desde la mochila) y el analizador de THC
func nota_cata(sid: String, thc: float) -> String:
	var ind := Datos.ind_de(S, sid)
	var a: String = aroma_de(sid)
	var e := "relaja y pesa" if ind >= 65 else ("sube y despeja" if ind <= 35 else "equilibrado")
	var p: String = (Datos.pct(thc) + " % de THC") if S.items.get("analizador") else ("floja" if thc < 12 else ("media" if thc < 18 else ("fuerte" if thc < 24 else "muy fuerte")))
	return "Aroma %s%s · %s · %s" % [a, (" (" + D.TERPENOS[a] + ")") if S.items.get("analizador") else "", e, p]

func aroma_de(sid: String) -> String:
	return D.AROMAS[Datos.hash_str(sid) % D.AROMAS.size()]

func cbd_de(sid: String) -> float:   # CBD del 0,2 al 1 % según el % índica
	return Datos.jsround(20 + Datos.ind_de(S, sid) * 0.8) / 100.0

func catar(k: String, g := -1.0) -> void:
	var b = S.buds.get(k)
	if g < 0:
		g = D.CATA.g
	if b == null or b.g < g:
		return
	var sid := lot_sid(k)
	var thc: float = b.thc
	var cu := float(b.get("cu", 0))
	var fresca: bool = b.get("dia") != null
	use_buds(k, g)
	marca_cata(k, false, sid, thc)
	await gesto("fumar", {"m": "porro"})   # 1.54
	advance_time(int(D.CATA.min))
	update_hud()
	await say("Catas %s%s: %s." % [("" if g == D.CATA.g else (Datos.coma(g) + " g de ")), lot_nombre(k), S.catas[sid]] + (" Bien curada: suave y con todo el aroma." if cu >= 1 else (" Sin curar del todo: rasca y huele a verde." if cu or fresca else "")) + (cata_efecto(g, thc) if Datos.CAL else ""))   # 1.29

# 1.47 (lo pidió el usuario: «que se pueda probar todo tipo de cogollos y extracción… hasta un límite lógico claro»): catar cualquier
# lote, cogollos o extracto, en la cantidad que elijas hasta CATA_MAX de una vez (un porro bien cargado, 1 g; de extracto, 0,5 g)
const CATA_MAX := {"b": 1.0, "r": 0.5}
const CATA_PASOS := {"b": [0.1, 0.25, 0.5], "r": [0.1, 0.2, 0.3]}

func marca_cata(k: String, r: bool, sid: String, thc: float) -> void:
	var L: Dictionary = S.rosin if r else S.buds
	if L.has(k):
		L[k].cata = true
	S.catas[("r:" + k) if r else sid] = nota_cata(sid, thc)

func cata_efecto(g: float, thc: float) -> String:   # cuánto sube: los mg de THC que llevas encima
	var mg := g * thc * 10
	return "" if mg < 60 else (" Te deja tocado un buen rato." if mg < 150 else " Demasiado: te quedas un buen rato mirando a la pared.")

func cata_cuanto(k: String, r: bool):
	var b: Dictionary = (S.rosin if r else S.buds)[k]
	var mx: float = floor(minf(float(CATA_MAX["r" if r else "b"]), float(b.g)) * 100) / 100.0
	if mx < .1:
		return 0
	return await cuanto("¿Cuánto catas? (de una vez, %s g como mucho)" % Datos.coma(CATA_MAX["r" if r else "b"]), snappedf(mx, .01), CATA_PASOS["r" if r else "b"], func(q): return Datos.coma(q) + " g")

func catar_extr(k: String, g: float) -> void:
	var b = S.rosin.get(k)
	if b == null or b.g < g:
		return
	var sid := lot_sid(k)
	var thc: float = b.thc
	use_rosin(k, g)
	marca_cata(k, true, sid, thc)
	await gesto("fumar", {"m": "pipa"})   # 1.54
	advance_time(int(D.CATA.min))
	update_hud()
	await say("Catas %s g de %s: %s.%s" % [Datos.coma(g), extr_nombre(k, true), S.catas["r:" + k], (cata_efecto(g, thc) if Datos.CAL else "")])

func extr_accion(k: String) -> void:
	var b: Dictionary = S.rosin[k]
	var ops := ["Catar…", "Tirar", "Nada"]
	var oi: int = await ask("%s: %s g · %s %%%s" % [extr_nombre(k, true), Datos.coma(b.g), Datos.pct(b.thc), " · catado" if b.get("cata") else ""], ops)
	if oi == 0:
		var g = await cata_cuanto(k, true)
		if g:
			await catar_extr(k, g)
	elif oi == 1:
		await tirar_lote(k, true)

func analizar(k: String) -> void:
	var b = S.buds.get(k)
	if b == null or not S.items.get("analizador"):
		return
	b.ana = true
	sfx("get")
	var sid := lot_sid(k)
	await say("Analizado: %s · THC %s %% · CBD %s %% · terpeno principal, %s. Lo que va con análisis se vende mejor." % [lot_nombre(k), Datos.pct(b.thc), Datos.pct(cbd_de(sid)), D.TERPENOS[aroma_de(sid)]])

func lote_accion(k: String) -> void:
	var b: Dictionary = S.buds[k]
	var ops := ["Catar…" if Datos.CAL else "Catar %s g" % Datos.coma(D.CATA.g)]
	if S.items.get("analizador") and not b.get("ana"):
		ops.append("Analizar")
	ops.append_array(["Tirar", "Nada"])
	var oi: int = await ask("%s: %d g · %s %%%s%s%s" % [lot_nombre(k), int(floor(b.g)), Datos.pct(b.thc), cura_corto(b), " · catado" if b.get("cata") else "", " · analizado" if b.get("ana") else ""], ops)
	var op: String = ops[oi]
	if op == "Catar…":   # 1.47
		var g = await cata_cuanto(k, false)
		if g:
			await catar(k, g)
	elif op.begins_with("Catar"):
		await catar(k)
	elif op == "Analizar":
		await analizar(k)
	elif op == "Tirar":
		await tirar_lote(k, false)

# tirar un producto (1.36, lo pidió el usuario; como las semillas): cogollos o un extracto de los que llevas; el dinero, no
func tirar_lote(k: String, r: bool) -> void:
	var L: Dictionary = S.rosin if r else S.buds
	if not L.has(k):
		return
	var b: Dictionary = L[k]
	var mx: float = b.g if r else floor(b.g)
	var g = await cuanto("Tirar %s: ¿cuánto?" % (extr_nombre(k, true) if r else lot_nombre(k)), mx, [1, 5, 10, 50] if r else [10, 50, 100, 500, 1000],
		(func(q): return Datos.coma(q) + " g") if r else (func(q): return g_txt(q)))
	if not g:
		return
	if r:
		use_rosin(k, g)
	else:
		b.g -= g
		if b.g < .5:
			L.erase(k)
	sfx("sel")
	update_hud()
	await say("Tiras %s." % ((Datos.coma(g) + " g de " + extr_nombre(k, true)) if r else (g_txt(g) + " de " + lot_nombre(k))))

# los rivales (1.16, 13-combate): en las zonas de venta lejos de Darko, un camello que no quiere competencia. Cada venta en la calle
# de su zona le suma una (S.rivales[zona]); con RIVAL.umbral sale a buscarte: pelear, pagarle su cuota o irte
func nom_rival(R: Dictionary) -> String:
	return R.n.substr(0, 1) + R.n.substr(1).to_lower()

func cuota_rival(z: String) -> int:
	return Datos.jsround(D.RIVAL.cuota * D.ZONAS[z].precio)

func rival_b(kind := "rival") -> Dictionary:
	if kind == "darko":
		return {"kind": "thief", "rival": "Darko", "jefe": 1, "name": "DARKO", "look": D.LOOKS.darko, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	var R: Dictionary = D.RIVALES.get(S.map, D.RIVALES.alto)
	return {"kind": "thief", "rival": nom_rival(R), "name": R.n, "look": look_rival(R), "t": 0.0, "flashE": 0.0, "shakeP": 0.0}

# 1.43.3: el muñeco del rival, del sexo de su nombre (GENERO.rival)
func look_rival(R: Dictionary) -> Dictionary:
	var o := Datos.rand_look("rival" + R.n, "thief")
	if Datos.CAL and D.GENERO.rival.has(R.n):
		o.id = D.GENERO.rival[R.n]
	return o

func rival_venta(z):
	if S.ch < D.RIVAL.ch or not D.RIVALES.has(z) or float(S.rivalFuera.get(z, 0)) >= S.day:
		return
	S.rivales[z] = int(S.rivales.get(z, 0)) + 1
	if S.rivales[z] >= D.RIVAL.umbral:
		queue("rival", func(): await rival_event(z))

func rival_event(z: String) -> void:
	if S.map != z:   # si te has ido de su zona, te buscará en la próxima venta
		return
	var R: Dictionary = D.RIVALES[z]
	var N: String = R.n
	var nom := nom_rival(R)
	var c := cuota_rival(z)
	await talk(N, ["Eh, tú. Llevas %d ventas en %s." % [int(S.rivales[z]), R.sitio], R.frase, "O me pagas %s o lo arreglamos aquí." % Datos.eur(c)])
	var o: int = await ask("¿Qué haces?", ["Pelear", "Pagarle " + Datos.eur(c), "Irte"], N)
	if o == 0:
		var r = await battle("rival")
		if r == "win":
			S.rivalFuera[z] = S.day + int(D.RIVAL.dias)
			S.rivales[z] = 0
			sfx("get")
			await say("%s no volverá por %s en %d días. Mientras, sus clientes te pagan un %d %% más." % [nom, R.sitio, int(D.RIVAL.dias), Datos.jsround((D.RIVAL.f - 1) * 100)])
			return
		if r == "talk":
			S.rivales[z] = 0
			await say("%s: «Vale. Pero no te quiero ver tanto por aquí.»" % nom)
			return
		S.rivales[z] = 0 if r == "ko" else int(D.RIVAL.umbral) - int(D.RIVAL.vuelve)
		return
	if o == 1 and S.money >= c:
		S.money -= c
		S.rivales[z] = 0
		sfx("coin")
		update_hud()
		await say("%s se guarda el dinero. «Así me gusta. Hasta la próxima.»" % nom)
		return
	if o == 1:
		await say("No llevas tanto dinero encima.")
	S.rivales[z] = int(D.RIVAL.umbral) - int(D.RIVAL.vuelve)
	await say("Te apartas. %s se queda mirándote." % nom)

# ---------- la plantilla (1.19, 11f-plantilla): gente del barrio que trabaja para ti ----------
func ficha_gente(w: Dictionary) -> String:
	return "Labia %d · cuidado %d · lealtad %d" % [w.lab, w.cui, w.lea]

func gerente():
	for w in S.plantilla:
		if w.get("rol") == "gerente":
			return w
	return null

func naveros() -> Array:
	return S.plantilla.filter(func(w): return w.get("rol") == "nave")

# 1.34: con el de las madres (cuida_madres)
func de_la_nave() -> Array:
	return S.plantilla.filter(func(w): return w.get("rol") == "nave" or w.get("rol") == "madres")

# llevar a la gente (1.34, MANDO de 11f-plantilla): una prima (lealtad +1) y un curso (cuidado +1; a los de la calle, labia +1), hasta
# 5, cada uno una vez cada MANDO.dias días por persona (w.pr, w.cu1)
func curso_de(w: Dictionary) -> Array:
	return ["lab", "labia"] if w.get("rol") == "calle" else ["cui", "cuidado"]

func prima(w: Dictionary) -> void:
	var M: Dictionary = D.MANDO
	if w.get("pr") != null and S.day - int(w.pr) < int(M.dias):
		await say("A %s ya le diste una prima el %s. Hasta el %s, no." % [w.n, Datos.fd(int(w.pr), S.day), Datos.fd(int(w.pr) + int(M.dias), S.day).trim_prefix("día ")])
		return
	if w.lea >= 5:
		await say("%s ya te es leal del todo: una prima no le cambia nada." % w.n)
		return
	if S.money < M.prima:
		sfx("bad")
		await say("No te llega.")
		return
	S.money -= int(M.prima)
	w.pr = S.day
	w.lea = int(w.lea) + 1
	sfx("coin")
	update_hud()
	await say("%s: «Gracias, jefe. Aquí me tienes». Lealtad %d." % [w.n, int(w.lea)])

func curso(w: Dictionary) -> void:
	var M: Dictionary = D.MANDO
	var kn := curso_de(w)
	var k: String = kn[0]
	var nn: String = kn[1]
	if int(w[k]) >= 5:
		await say("%s ya tiene %s 5: no hay curso que le enseñe más." % [w.n, nn])
		return
	if w.get("cu1") != null and S.day - int(w.cu1) < int(M.dias):
		await say("%s hizo un curso el %s. Hasta el %s, no." % [w.n, Datos.fd(int(w.cu1), S.day), Datos.fd(int(w.cu1) + int(M.dias), S.day).trim_prefix("día ")])
		return
	if S.money < M.curso:
		sfx("bad")
		await say("No te llega.")
		return
	S.money -= int(M.curso)
	w.cu1 = S.day
	w[k] = int(w[k]) + 1
	sfx("coin")
	update_hud()
	await say("%s hace un curso %s. %s %d." % [w.n, "de venta: a tratar con la gente" if k == "lab" else "de cultivo: riego, plagas y poda", nn.substr(0, 1).to_upper() + nn.substr(1), int(w[k])])

# la mesa de cada trabajador de la nave (1.31: w.mesa, la suya mientras trabaje allí; antes, el orden de la plantilla): quién cuida la
# mesa i y la mesa que le toca al que llega (la primera plantada sin nadie y, si no, la primera libre)
func navero_de(i: int):
	for w in S.plantilla:
		if w.get("rol") == "nave" and w.get("mesa") != null and int(w.mesa) == i:
			return w
	return null

func mesa_libre() -> int:
	var L := []
	for i in int(D.NAVE.max):
		if navero_de(i) == null:
			L.append(i)
	for i in L:
		if S.nave.m[i]:
			return i
	return L[0]

func nave_g(w: Dictionary) -> int:
	return int(D.NAVE.g + D.NAVE.gC * (w.cui - 3))

func rol_txt(w: Dictionary) -> String:
	if w.get("rol") == "calle":
		return "calle · " + g_txt(w.g)
	return w.rol if w.get("rol") else "sin trabajo"

func rol_desc(w: Dictionary) -> String:
	var P: Dictionary = D.PLANTILLA
	match w.get("rol"):
		"calle":
			return "Vende %s en la calle: le quedan %s." % [lot_nombre(w.k), g_txt(w.g)]
		"gerente":
			return "Cuida el piso y cosecha a la caja fuerte por %s al día." % Datos.eur(P.sueldo.gerente)
		"nave":
			return "Cultiva la mesa %d de la nave por %s al día: con su cuidado, la cosecha da un %d %%." % [int(w.mesa) + 1, Datos.eur(P.sueldo.nave), Datos.jsround(100.0 * nave_g(w) / float(D.NAVE.g))]
		"madres":   # 1.34
			return "Cuida las madres de la nave por %s al día y les saca esquejes." % Datos.eur(P.sueldo.madres)
	return "Dale trabajo: calle, gerente, nave o las madres."

# deja el trabajo; lo que le quedaba del lote vuelve a la caja fuerte
func libre(w: Dictionary) -> void:
	if w.get("rol") == "calle" and w.g >= 1:
		add_buds(w.k, w.g, w.thc, S.caja.buds if S.get("caja") else S.buds, w.get("cu"), w.get("dia"), w.get("mc", 0))
	w.rol = null
	w.erase("k")
	w.erase("thc")
	w.erase("g")
	w.erase("cu")
	w.erase("mc")
	w.erase("dia")
	w.erase("mesa")

func plantilla() -> void:
	var P: Dictionary = D.PLANTILLA
	var i := 0
	while true:
		var L: Array = S.plantilla
		var rows := []
		for w in L:
			rows.append({"label": w.n, "right": rol_txt(w), "desc": ficha_gente(w) + ". " + rol_desc(w)})
		if L.size() < int(P.max):
			rows.append({"label": "Pedir gente a Patxi", "right": Datos.eur(P.sobre), "desc": "Patxi te manda a alguien del barrio que quiere currar. No sabes a quién hasta que llega."})
		var t2: String = "%d de %d" % [L.size(), int(P.max)] + ((" · nave " + g_txt(nave_stock())) if S.get("nave") != null else "")
		i = await menu(rows, {"cls": "full", "title": "PLANTILLA", "title2": t2, "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0:
			return
		if i >= L.size():
			await pedir_gente()
		else:
			await trabajo(L[i])

func pedir_gente() -> void:
	var P: Dictionary = D.PLANTILLA
	var libres := []
	for nb in D.BARRIO:
		if not S.plantilla.any(func(w): return w.n == nb):
			libres.append(nb)
	if S.money < P.sobre:
		sfx("bad")
		await say("Patxi cobra %s por el sobre. No te llega." % Datos.eur(P.sobre))
		return
	if libres.is_empty():
		await say("Patxi ya no conoce a nadie más que quiera currar.")
		return
	S.money -= int(P.sobre)
	var nm: String = pick(libres)
	S.plN = int(S.plN) + 1
	var w := {"id": "pl%d" % int(S.plN), "n": nm, "lab": ri(1, 5), "cui": ri(1, 5), "lea": ri(1, 5), "rol": null}
	var t: int = w.lab + w.cui + w.lea
	sfx("get")
	await talk("SMS · PATXI", ["Te mando a %s. %s" % [nm, "Vale oro." if t >= 12 else ("No es gran cosa, pero quiere currar." if t <= 6 else "Gente normal del barrio.")]])
	if await ask("%s: %s. ¿Le contratas?" % [nm, ficha_gente(w)], ["Contratar", "No"]) != 0:
		await say("%s se va por donde ha venido. El sobre ya es de Patxi." % nm)
		return
	S.plantilla.append(w)
	sfx("sel")
	await say("%s entra en tu plantilla. Dale trabajo desde aquí." % nm)

# un lote de los de encima para la calle: [clave, THC, gramos] o null
func lote_calle(w: Dictionary):
	var P: Dictionary = D.PLANTILLA
	var lots := bud_lots(P.lotes[0])
	if lots.is_empty():
		await say("Para la calle hace falta un lote de %d g o más encima." % int(P.lotes[0]))
		return null
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote le das?"})
	if i < 0 or i >= lots.size():
		return null
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var ops := []
	for g in P.lotes:
		if g <= floor(b.g):
			ops.append(int(g))
	var o2 := ops.map(func(g): return "%d g" % g)
	o2.append("Nada")
	var j: int = await ask("%s vende a precio de calle y se queda el %d %%. ¿Cuánto le das?" % [w.n, Datos.jsround(P.com * 100)], o2)
	if j < 0 or j >= ops.size():
		return null
	var thc: float = b.thc
	var c := cura_de(b)
	use_buds(k, ops[j])
	return [k, thc, ops[j], c]

func trabajo(w: Dictionary) -> void:
	var P: Dictionary = D.PLANTILLA
	var ops := []
	if w.get("rol") != "calle":
		ops.append("A la calle")
	if w.get("rol") != "gerente" and gerente() == null:
		ops.append("De gerente")
	if w.get("rol") != "nave" and S.get("nave") != null and naveros().size() < int(D.NAVE.max):
		ops.append("A la nave")
	if w.get("rol") != "madres" and S.get("nave") != null and cuida_madres() == null:   # 1.34
		ops.append("A las madres")
	if w.get("rol"):
		ops.append("Dejarlo libre")
	ops.append_array(["Prima · " + Datos.eur(D.MANDO.prima), "Curso · " + Datos.eur(D.MANDO.curso), "Despedir", "Nada"])
	var oi: int = await ask("%s · %s · %s" % [w.n, ficha_gente(w), rol_txt(w)], ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op == "A la calle":
		var r = await lote_calle(w)
		if r == null:
			return
		libre(w)
		w.rol = "calle"
		w.k = r[0]
		w.thc = r[1]
		w.g = r[2]
		w.merge(r[3], true)
		sfx("sel")
		await say("%s: «Hecho. Cada día te dejo lo vendido en el buzón»." % w.n)
	elif op == "De gerente":
		libre(w)
		w.rol = "gerente"
		sfx("sel")
		await say("%s: «Cada mañana me paso por el piso: riego, trato las plagas y lo que esté listo lo cosecho y lo dejo en la caja fuerte. %s al día»." % [w.n, Datos.eur(P.sueldo.gerente)])
	elif op == "A la nave":
		libre(w)
		w.mesa = mesa_libre()
		w.rol = "nave"
		sfx("sel")
		await say("%s: «Mañana empiezo en la mesa %d de la nave. %s al día»." % [w.n, int(w.mesa) + 1, Datos.eur(P.sueldo.nave)])
	elif op == "A las madres":
		libre(w)
		w.rol = "madres"
		sfx("sel")
		await say("%s: «Mañana empiezo con las madres de la nave: riego, poda y esquejes. %s al día»." % [w.n, Datos.eur(P.sueldo.madres)])
	elif op.begins_with("Prima"):
		await prima(w)
	elif op.begins_with("Curso"):
		await curso(w)
	elif op == "Dejarlo libre":
		var g: float = w.g if w.get("rol") == "calle" else 0.0
		libre(w)
		await say(("%s te deja lo que le quedaba en la caja fuerte: %s." % [w.n, g_txt(g)]) if g >= 1 else "%s se queda sin trabajo." % w.n)
	elif op == "Despedir":
		if await ask("¿Despides a %s?" % w.n, ["Despedir", "No"]) != 0:
			return
		var g: float = w.g if w.get("rol") == "calle" else 0.0
		libre(w)
		S.plantilla = S.plantilla.filter(func(x): return x != w)
		await say("%s se va." % w.n + ((" Lo que le quedaba, %s, está en la caja fuerte." % g_txt(g)) if g >= 1 else ""))

# el gerente, cada mañana: cuida las plantas y cosecha las que están listas a la caja fuerte (su sisa, por la lealtad); da los gramos
func cuidar_casa(w: Dictionary) -> int:
	cuidar_plantas()
	var tot := 0
	for i in S.pots.size():
		var p = S.pots[i]
		if p == null or p.get("dead") or p.prog < 1:
			continue
		var f := factores(i)
		var g := gramos_planta(p, f)
		var thc := Cultivo.thc_cosecha(S, p, f)
		var cl := Cultivo.clase_feno(p.get("f"))
		var sc := semillas_cosecha(p)
		var q: int = g - int(floor(g * D.PLANTILLA.sisa * (5 - w.lea)))
		if q >= 1:
			add_buds(p.sid + "*" if cl == "estrella" else p.sid, q, thc, S.caja.buds if S.get("caja") else S.buds)
		if sc.n:
			add_seeds(p.sid, sc.n)
		if p.get("f") and p.f.get("id"):
			S.fenos[str(int(p.f.id))] = cl
		if S.rec.get(p.sid) == 1:
			S.rec[p.sid] = 2
		S.pots[i] = null
		tot += q
	if tot:
		S.flags.harvest1 = true
		var N: String = "SMS · " + w.n.to_upper()
		var tt := tot
		var L := ["He cosechado %d g. Está en la caja fuerte." % tt]
		queue("gerente", func(): await talk(N, L), [[N, L]])
		queue("historia", check_story)
	return tot

# al amanecer (desde curro_dia): sueldos, el gerente, la calle y la nave
func plantilla_dia() -> void:
	var P: Dictionary = D.PLANTILLA
	var fuera := []
	var vende := false
	nave_alquiler()
	for w in S.plantilla:
		if w.get("rol") == null or not P.sueldo.has(w.rol):   # gerente, nave y madres (1.34)
			continue
		if S.money < P.sueldo[w.rol]:
			w.rol = null
			var N: String = "SMS · " + w.n.to_upper()
			queue("pl" + w.id, func(): await talk(N, ["Sin cobrar no curro. Cuando tengas el dinero, me llamas."]))
		else:
			S.money -= int(P.sueldo[w.rol])
	var ger = gerente()
	if ger != null:
		cuidar_casa(ger)
	for w in S.plantilla:
		if w.get("rol") != "calle":
			continue
		var N: String = "SMS · " + w.n.to_upper()
		var lote := lot_nombre(w.k)
		var r := Cultivo.azar()
		var pp: float = P.poli - P.poliC * (w.cui - 1)
		var pr: float = pp + P.robo - P.roboC * (w.cui - 1)
		var pf: float = pr + P.fuga * (5 - w.lea) / 4 * (.5 if ger != null else 1.0)
		var pt: float = pf + P.timo - P.timoL * (w.lab - 1)
		var m := ""
		if r < pp:
			S.heat = min(100, S.heat + P.calorPoli)
			m = "Me ha parado la policía. Se han quedado con %s de %s. Lo siento." % [g_txt(w.g), lote]
			w.g = 0
		elif r < pr:
			var q: int = int(ceil(w.g / 2.0))
			w.g -= q
			m = "Me han atracado en un portal. Se han llevado %s de %s." % [g_txt(q), lote] + ((" Me quedan %s." % g_txt(w.g)) if w.g >= 1 else "")
		elif r < pf:
			fuera.append(w)
			var gg: float = w.g
			var nm: String = w.n
			queue("pl" + w.id, func(): await say("%s no contesta al móvil. Se ha largado con %s de %s." % [nm, g_txt(gg), lote]))
			continue
		else:
			var q: int = mini(int(floor(w.g)), ri(int(P.g[0]), int(P.g[1])) * int(w.lab))
			w.g -= q
			if r < pt:
				m = "Me han pagado %d g con billetes falsos. No me he dado cuenta hasta el banco." % q
			else:
				var e := Datos.jsround(precio_calle(w.thc) * calidad(w) * D.ZONAS.town.precio * q * (1 - P.com))
				S.money += e
				S.sales += e
				S.heat = min(100, S.heat + P.calor)
				vende = true
				m = ("Vendidos %d g: %s en tu buzón. Me quedan %s." % [q, Datos.eur(e), g_txt(w.g)]) if w.g >= 1 else ("Vendidos los últimos %d g: %s en tu buzón. Dame más cuando quieras." % [q, Datos.eur(e)])
		if w.g < 1:
			libre(w)
		var mm := m
		queue("pl" + w.id, func(): await talk(N, [mm]))
	if fuera.size():
		S.plantilla = S.plantilla.filter(func(w): return not fuera.has(w))
	if vende:   # 1.22: lo vendido cuenta para la historia
		queue("historia", check_story)
	nave_dia()

# la nave: el alquiler, lo primero de la mañana (antes que los sueldos; sin él, Arrieta cambia la cerradura y se queda la fianza).
# 1.35: cada RECIBO.dias, en efectivo, con su aviso (cobra, granja.gd)
func nave_alquiler() -> void:
	var N = S.get("nave")
	if N == null or N.get("mia"):   # 1.42: comprada, sin alquiler
		return
	var r0: int = int(N.r)
	if cobra(N, recibo_nave(), "ARRIETA", false, "la nave"):
		if N.get("op") is Dictionary:
			if int(N.r) > r0:   # 1.42: la parte del alquiler que va a la compra
				N.op.pag = int(N.op.pag) + roundi(recibo_nave() * float(D.NAVE.compra.abono))
			if Datos.CAL and int(Datos.fecha(S.day).d) == 1:
				var tx := "Este mes puedes comprar la nave, hasta el %s: quedan %s y %s de gastos. Por transferencia, en el notario." % [Datos.fd(S.day + int(D.NAVE.compra.ventana) - 1, S.day), Datos.eur(resto_nave()), Datos.eur(gastos_nave())]
				queue("naveC", func(): await talk("SMS · ARRIETA", [tx]))
		elif Datos.CAL and S.get("aso") is Dictionary and S.aso.get("pres") and int(Datos.fecha(S.day).d) == 1 and not N.get("of"):
			N.of = true
			queue("naveC", func(): await talk("SMS · ARRIETA", ["Me han dicho que ahora presides la asociación del barrio. Si quieres, la nave te la alquilo con opción a compra: pásate y lo hablamos."]))
		return
	for w in de_la_nave():
		libre(w)
	S.nave = null
	queue("nave", func(): await talk("SMS · ARRIETA", ["No me has pagado la nave. Cambio la cerradura y me quedo la fianza."]))

# después de la calle, la redada (menos con cuidado) y el ciclo de cada mesa (1.41, lo pidió el usuario: por ciclos, como de verdad).
# Los clones de la madre enraízan, crecen a 18/6 y florecen a 12/12 al ritmo de su variedad (prog_mesa: 1/d al día, como en el piso,
# desde NAVE.clon); al acabar, el navero corta la mesa entera y la cuelga en el secadero (Me.h: {g, t, d}) y vuelve a empezar con
# los esquejes que sacó antes de pasar a flor. Lo de la cosecha: los W de sus focos × g/W (FOCO_NAVE.gpw) × la variedad y el
# fenotipo × el cuidado del navero (nave_g / NAVE.g) × el riego × el calor; el abono, por los días del ciclo que lo tuvo (Me.am,
# Me.ao de Me.dn). Lo colgado se seca NAVE.seca días y pasa a lo que se descuelga (Me.g, con su THC, Me.t, y el día de la cosecha, Me.cd)
func nave_dia() -> void:
	var N = S.get("nave")
	if N == null:
		return
	madres_dia()   # 1.34
	for Me in N.m:
		if Me and Me.get("h") != null and S.day - int(Me.h.d) >= int(D.NAVE.seca):
			if not (Me.g >= 1):   # lo que queda por debajo de 1 g no se recoge: cuenta como vacío
				Me.cd = int(Me.h.d)
			Me.t = Datos.jsround((Me.t * Me.g + Me.h.t * Me.h.g) / (Me.g + Me.h.g) * 10) / 10.0
			Me.g = Datos.jsround((Me.g + Me.h.g) * 10) / 10.0
			Me.erase("h")
	var W := naveros()
	if W.is_empty() or not N.m.any(func(x): return x != null):
		return
	var mc := 0
	for w in W:
		mc = maxi(mc, int(w.cui))
	if Cultivo.azar() < maxf(0, D.NAVE.redada - D.NAVE.redadaC * mc) * D.EXTR_NAVE[int(N.ex)].olor:   # 1.33: con los filtros, huele menos
		var ns: Array = de_la_nave().map(func(w): return w.n)
		var quien: String = (", ".join(PackedStringArray(ns.slice(0, -1))) + " y " + ns[-1]) if ns.size() > 1 else ns[0]
		var gg: float = nave_stock()
		S.nave = null
		S.plantilla = S.plantilla.filter(func(w): return w.get("rol") != "nave" and w.get("rol") != "madres")
		S.heat = min(100, S.heat + D.NAVE.calor)
		sfx("bad")
		queue("nave", func(): await say("La policía ha entrado en la nave de Valdehierro. Se lleva las plantas%s y a %s." % [(", " + g_txt(gg)) if gg >= 1 else "", quien]))
		return
	var R: Dictionary = D.RIEGO_NAVE[int(N.rg)]
	var so := sofoco_nave()
	for i in W.size():
		var Me = N.m[int(W[i].mesa)]
		if not Me:
			continue
		var p := prog_mesa(Me)
		Me.dn = int(Me.get("dn", 0)) + 1
		if Me.abo == 1 and N.ab.m >= R.dosis:
			N.ab.m = Datos.jsround((N.ab.m - R.dosis) * 10) / 10.0
			Me.am = int(Me.get("am", 0)) + 1
		elif Me.abo == 2 and N.ab.o >= R.dosis:
			N.ab.o = Datos.jsround((N.ab.o - R.dosis) * 10) / 10.0
			Me.ao = int(Me.get("ao", 0)) + 1
		var p0 := p
		p += 1.0 / float(strain(lot_sid(Me.k)).d)
		if Datos.CAL and N.has("bc") and p0 < FLOR_MESA and p >= FLOR_MESA:   # 1.43: antes de pasarla a 12/12, la bandeja de clones
			corta_bandeja(int(W[i].mesa), Me)
		if p < 1:
			Me.p = Datos.jsround(p * 1000) / 1000.0
			continue
		var c := cosecha_mesa(Me, int(W[i].mesa), W[i], so)
		if Me.get("h") != null:
			c.t = Datos.jsround((Me.h.t * Me.h.g + c.t * c.g) / (Me.h.g + c.g) * 10) / 10.0
			c.g = Datos.jsround((Me.h.g + c.g) * 10) / 10.0
		Me.h = {"g": c.g, "t": c.t, "d": S.day}
		if N.has("bc"):   # 1.43: la mesa vuelve a empezar con su bandeja (la de antes de la 1.43, con los clones que ya tenía)
			N.bc = N.bc.filter(func(b): return int(b.m) != int(W[i].mesa))
		Me.p = float(D.NAVE.clon)
		Me.n = int(Me.get("n", 0)) + 1
		Me.dn = 0
		Me.am = 0
		Me.ao = 0

# lo que va del ciclo de una mesa (0-1): Me.p o, en una mesa de antes de la 1.41 (por días), lo que llevaría desde que se plantó
func prog_mesa(Me: Dictionary) -> float:
	if Me.get("p") != null:
		return float(Me.p)
	return minf(.95, float(D.NAVE.clon) + float(S.day - Me.dia) / float(strain(lot_sid(Me.k)).d))

# la cosecha entera de la mesa i al final del ciclo: {g, t}
func cosecha_mesa(Me: Dictionary, i: int, w: Dictionary, so: float) -> Dictionary:
	var N: Dictionary = S.nave
	var F: Dictionary = D.FOCO_NAVE[N.f[i]]
	var R: Dictionary = D.RIEGO_NAVE[int(N.rg)]
	var dn := maxf(1, float(Me.get("dn", 1)))
	var am := float(Me.get("am", 0)) / dn
	var ao := float(Me.get("ao", 0)) / dn
	var g: float = float(F.w) * float(F.gpw) * float(strain(lot_sid(Me.k)).y) / float(D.Y_MEDIA) * float(Me.y) * nave_g(w) / float(D.NAVE.g) \
		* (1 + float(R.rend)) * so * (1 + float(D.ABONO.rend) * am + float(D.ABONO_BIO.rend) * ao)
	var thc: float = Me.thc + float(F.thc) + float(R.thc) + float(D.ABONO.thc) * am + float(D.ABONO_BIO.thc) * ao
	return {"g": Datos.jsround(g * 10) / 10.0, "t": Datos.jsround(thc * 10) / 10.0}

# los días que le quedan a la mesa hasta la cosecha
func cosecha_txt(Me: Dictionary) -> String:
	var d := dias_mesa(Me)
	return "cosecha mañana" if d == 1 else "cosecha en %d días" % d

func dias_mesa(Me: Dictionary) -> int:
	return maxi(1, ceili((1 - prog_mesa(Me)) * float(strain(lot_sid(Me.k)).d) - 1e-9))

# las madres de la nave, cada mañana (1.34, MADRES de 11j-locales): con quien las cuide, a 100 de vigor y con sus esquejes; sin nadie,
# se apagan y, a 0, se mueren
func madres_dia() -> void:
	var N: Dictionary = S.nave
	var c = cuida_madres()
	if N.ma.is_empty():
		return
	var muertas := 0
	var quedan := []
	for M in N.ma:
		if c != null:
			M.v = 100
			M.e = mini(int(D.MADRES.tope), int(M.e) + int(D.MADRES.esq) + (1 if c.cui >= 4 else 0))
			quedan.append(M)
			continue
		M.v = maxi(0, int(M.v) - int(D.MADRES.pierde))
		if M.v > 0:
			quedan.append(M)
		else:
			muertas += 1
	N.ma = quedan
	if muertas:
		var t: String = ("Sin nadie que las cuide, se han muerto %d madres de la nave." % muertas) if muertas > 1 else "Sin nadie que la cuide, se ha muerto una madre de la nave."
		queue("madres", func(): await say(t))

# Arrieta, el dueño de la nave de Valdehierro
func talk_nave() -> void:
	var A := "ARRIETA"
	var N = S.get("nave")
	if S.ch < int(D.NAVE.ch):
		await say("La nave no se alquila. Ahora mismo, no.", A)
		return
	if N == null:
		var e: float = D.NAVE.fianza + recibo_nave()   # 1.35: la fianza y la primera semana; después, cada RECIBO.dias, en efectivo
		if await ask("La nave está vacía: %s de fianza y %s cada %s días, en efectivo; el primero, ahora. Paso a cobrar y te aviso antes. Sin preguntas." % [Datos.eur(D.NAVE.fianza), Datos.eur(recibo_nave()), n(D.RECIBO.dias)], ["Alquilarla", "No"], A) != 0:
			return
		if S.money < e:
			sfx("bad")
			await say("Sin %s no hay llave." % Datos.eur(e), A)
			return
		S.money -= e
		S.nave = nave_nueva()
		sfx("coin")
		await got("la llave de la nave")
		await say("Dentro hay %d mesas de cultivo, una por persona. Pon a tu gente desde el móvil y planta tú lo que quieras." % int(D.NAVE.max), A)
		return
	var ops := ["Dejar la nave", "Nada"]
	var tc := ""   # 1.42: la opción a compra (lo pidió el usuario: siendo presidente de la asociación)
	if N.get("mia"):
		ops = ["Nada"]
		tc = " La nave es tuya."
	elif N.get("op") is Dictionary:
		ops.insert(0, "Comprarla")
		tc = " Opción a compra: llevas %s de %s." % [Datos.eur(N.op.pag), Datos.eur(N.op.p)]
	elif S.get("aso") is Dictionary and S.aso.get("pres"):
		ops.insert(0, "Opción a compra")
	var oi: int = await ask("La nave: %d de %d mesas plantadas · %d de %d trabajando. Lo demás, dentro.%s" % [N.m.filter(func(x): return x != null).size(), int(D.NAVE.max), naveros().size(), int(D.NAVE.max), tc], ops, A)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op == "Opción a compra":
		await opcion_nave()
		return
	if op == "Comprarla":
		await comprar_nave()
		return
	if op == "Dejar la nave":
		if await ask("¿Dejas la nave? Te devuelvo la fianza%s%s." % ["; lo que no recojas se queda aquí" if nave_stock() >= 1 else "", "; la opción a compra se pierde, y lo pagado para ella" if N.get("op") else ""], ["Dejarla", "No"], A) != 0:
			return
		for w in de_la_nave():
			libre(w)
		S.nave = null
		S.money += int(D.NAVE.fianza)
		sfx("coin")
		await say("Trato hecho. Si la quieres otra vez, ya sabes dónde estoy.", A)

# ---------- la nave con opción a compra (1.42, lo pidió el usuario: «cuando seas presidente de la asociación, alquilas con opción
# a compra la nave, por la tranquilidad; cada mes te da la opción de comprarla a tocateja, a un precio realista»). NAVE.compra:
# 320 m² en el polígono de Valdehierro a unos 690 €/m² (precio, fijo mientras dure); la prima de la opción (prima) y la mitad
# de cada alquiler (abono) se descuentan; se compra los primeros días de cada mes (ventana), por transferencia desde la cuenta, con
# los gastos de la compraventa (gastos: transmisiones, notario y registro). Comprada, no hay alquiler ni Arrieta que cambie la cerradura.
func resto_nave() -> int:
	var N = S.get("nave")
	if N == null or not N.get("op") is Dictionary:
		return int(D.NAVE.compra.precio)
	return maxi(0, int(N.op.p) - int(N.op.pag))

func gastos_nave() -> int:
	return roundi(float(D.NAVE.compra.precio) * float(D.NAVE.compra.gastos))

func ventana_nave() -> bool:
	return int(Datos.fecha(S.day).d) <= int(D.NAVE.compra.ventana)

# el primer día de la próxima ventana
func proxima_ventana() -> int:
	var f := Datos.fecha(S.day)
	var y: int = f.y
	var m: int = int(f.m) + 1
	if m > 12:
		m = 1
		y += 1
	return Datos.dia_de(y, m, 1)

func opcion_nave() -> void:
	var A := "ARRIETA"
	var C: Dictionary = D.NAVE.compra
	var t := "Te la vendo por %s (%d m², a unos %s el metro). Firmamos la opción: %s de prima, que se descuentan, y la mitad de cada alquiler va a la compra. El precio no se mueve. Los primeros %d días de cada mes, si quieres, la compras a tocateja con lo que falte, más los gastos (%s), en el notario y por transferencia." % [Datos.eur(C.precio), int(C.m2), Datos.eur(roundi(float(C.precio) / float(C.m2))), Datos.eur(C.prima), int(C.ventana), Datos.eur(gastos_nave())]
	if await ask(t, ["Firmar la opción", "No"], A) != 0:
		return
	if not cobro_banco(float(C.prima), "Prima de la opción · nave"):
		sfx("bad")
		await say("La prima, por transferencia: en tu cuenta no hay %s." % Datos.eur(C.prima), A)
		return
	S.nave.op = {"d": int(S.day), "pag": int(C.prima), "p": int(C.precio)}
	sfx("coin")
	update_hud()
	await say("Firmado. Quedan %s; la mitad de cada alquiler, a cuenta. El primer día de cada mes te mando un mensaje con lo que falta." % Datos.eur(resto_nave()), A)

func comprar_nave() -> void:
	var A := "ARRIETA"
	if not ventana_nave():
		await say("La compra, los primeros %d días de mes. El próximo, desde el %s." % [int(D.NAVE.compra.ventana), Datos.fd(proxima_ventana(), S.day)], A)
		return
	var tot: int = resto_nave() + gastos_nave()
	if await ask("Quedan %s y %s de gastos: %s, por transferencia. Te devuelvo la fianza de %s. ¿La compras?" % [Datos.eur(resto_nave()), Datos.eur(gastos_nave()), Datos.eur(tot), Datos.eur(D.NAVE.fianza)], ["Comprarla", "No"], A) != 0:
		return
	if not cobro_banco(float(tot), "Compra de la nave de Valdehierro"):
		sfx("bad")
		await say("En tu cuenta hay %s y hacen falta %s. El mes que viene, otra vez." % [Datos.eur(S.banco), Datos.eur(tot)], A)
		return
	S.nave.mia = true
	S.nave.op.pag = int(S.nave.op.p)
	S.money += int(D.NAVE.fianza)
	sfx("get")
	update_hud()
	await got("las escrituras de la nave")
	await say("Firmado en el notario. La nave es tuya: ni alquiler ni cerradura que cambiar. Suerte.", A)

# ---------- los locales (1.30, 11j-locales): los clubs por dentro, la nave y GAUA ----------
# la puerta de un local (on_step_end, mundo.gd): cerrada, te deja delante; el club, la primera vez, el carné; GAUA, la entrada
func entra_local(d: Dictionary):
	var gk: PackedStringArray = String(d.gate).split(":")
	var t: String = gk[0]
	if t == "club":
		var k: String = gk[1]
		if S.ch < int(D.CLUBS[k].ch):
			atras_puerta()
			await say("Una puerta sin rótulo, con un timbre. No abre nadie.")
			return
		if not S.clubs.get(k) and not D.CLUBS[k].get("tuyo"):
			atras_puerta()
			if not await carne_club(k):
				return
		if k == "rv":   # 1.32: la asociación
			await entra_aso(d)
			return
	elif t == "nave":
		if S.get("nave") == null:
			atras_puerta()
			await say("La persiana está echada con un candado. La llave la tiene Arrieta, el dueño.")
			return
	elif t == "franco":   # 1.51: el piso franco de Gorka, desde el primer envío
		if not mar_ok() or int(S.mar.paso) < 1:
			atras_puerta()
			await say("Un portal con el timbre sin nombre. No abre nadie.")
			return
	elif t == "sot":   # 1.51: la escalera del sótano
		if not sot_ya():
			P.x = int(P.fx)
			P.y = int(P.fy)
			P.px = P.x * 16.0
			P.py = P.y * 16.0
			P.dir = "left"
			S.x = P.x
			S.y = P.y
			S.dir = "left"
			await say(D.SOTANO.txt.cerrado)
			return
	elif t == "setas":   # 1.34: el bajo de Txomin
		if S.get("setas") == null or Datos.PLAY:
			atras_puerta()
			await say("Una puerta gris con un candado. No es la tuya." if Datos.PLAY else "La puerta del bajo de Txomin, con un candado. La llave te la da él, si lo alquilas.")
			return
	elif t == "neg":   # 1.45: los negocios alquilados
		if not S.loc.has(gk[1]):
			atras_puerta()
			await say("Cerrado. En el cristal, el cartel de SE TRASPASA.")
			return
	elif t == "disco":
		if S.ch < int(D.DISCO.ch) or not disco_abierta():
			atras_puerta()
			await say("%s abre de 23:00 a 6:00." % D.DISCO.n)
			return
		if not noche_ya():
			atras_puerta()
			if not await entrada_disco():
				return
	match t:   # 1.53: lo tuyo se abre con su llave, su candado o su clave
		"nave":
			await acceso("candado")
			await acceso("clave", cifras_acceso("nave"))
		"setas":
			await acceso("candado")
		"neg", "franco":
			await acceso("llave")
		"club":
			if D.CLUBS[gk[1]].get("tuyo"):
				await acceso("llave")
	await warp(d)

func atras_puerta() -> void:
	var y: int = P.y + 1
	P.fy = y
	P.y = y
	P.py = y * 16.0
	P.dir = "down"
	S.y = y
	S.dir = "down"

# lo que hay dentro de los locales (object_action, mundo.gd); false si no es de un local
func obj_local(x: int, y: int, o) -> bool:
	if o == null:
		return false
	var txt := ""
	if Datos.CAL and S.map == "muelle" and o == "noray":   # 1.51
		await mar_noray(x)
		return true
	if Datos.CAL and S.map == "franco" and o == "crate":
		await alijo_franco()
		return true
	if Datos.CAL and S.map == "muelle" and o in ["redes", "nasas"]:
		await say("Redes de la cofradía, remendadas mil veces." if o == "redes" else "Nasas para el bogavante, apiladas a secar.")
		return true
	if Datos.CAL and o in ["escaleraD", "escaleraD2"]:   # 1.47: la escalera al reservado de GAUA
		if not disco_abierta():
			await echar_disco()
		elif noche_gaua().mesa:
			await subir_vip()
		else:
			await say("Arriba está el reservado, con la cristalera encima de la pista. Sin mesa, no se sube: la RRPP te la vende.", "RRPP")
		return true
	if Datos.CAL and o in ["escaleraDB", "escaleraDB2"]:
		await bajar_vip()
		return true
	if S.map == "disco-vip":
		match o:
			"bottles":
				txt = "Las botellas buenas, las del reservado."
			"barraD":
				txt = "La barra del reservado. Pídele a la camarera."
			"neon":
				txt = "El neón de %s, también arriba." % D.DISCO.n
			"altavoz":
				txt = "Un altavoz: aquí arriba la música llega más limpia."
			"sofaV", "sofaV2", "mesaV":
				txt = "Tu mesa: sofá de terciopelo, cubitera y botella. Desde aquí se ve toda la pista por el cristal."
	if S.map == "cuarto-t":   # 1.51: el cuartucho del taller, detrás de su puerta
		if not S.loc.has("valde"):
			await say("Ya no es tuyo: devuelve las llaves al salir.")
			return true
		match o:
			"bedT", "bedB":
				await bed_action("La cama del cuartucho: un somier de 90, una manta de cuadros y la radio en la mesilla.")
				return true
			"armR":
				if await ask(D.NEGOCIO.k.valde.txt.armR, ["Cambiarte de ropa", "Nada"]) == 0:
					await vestirte()
				return true
			"mesaC":
				txt = "Una mesa de camping con un hornillo y una cafetera italiana."
			"mesita":
				txt = "La mesilla: la radio, un despertador y una revista de coches."
			"cuadro":
				txt = "Un calendario de un taller de neumáticos, de hace años."
	if S.map == "nave-h" or S.map == "nave-d":   # 1.51: la habitación y el despacho de la nave
		if S.get("nave") == null:
			await say("La nave ya no es tuya.")
			return true
		match o:
			"bedT", "bedB":
				await bed_action("La cama de la habitación de la nave: se oyen los extractores al otro lado de la pared.")
				return true
			"armR":
				if await ask("Un armario con ropa de faena y una muda limpia.", ["Cambiarte de ropa", "Nada"]) == 0:
					await vestirte()
				return true
			"escritorio", "escritorio2":
				await escritorio_nave()
				return true
			"estanteN":
				await estante_nave()
				return true
			"mesita":
				txt = "La mesilla, con un flexo y el cargador del móvil."
			"perchero":
				txt = "La percha: un mono de trabajo y un chubasquero."
			"cuadro":
				txt = "El plano de la nave, con las mesas, las tomas de agua y la luz."
			"crate":
				txt = "Cajas de archivo: facturas de la luz, del agua y del sustrato."
	if S.map.begins_with("loc-") and Datos.CAL:   # 1.45: los negocios por dentro
		var k: String = S.map.substr(4)
		var N: Dictionary = D.NEGOCIO.k[k]
		var ob: String = o.trim_suffix("2") if o.ends_with("2") and o.left(-1) in NEG_ANCHO else o
		if not S.loc.has(k):
			await say("Ya no es tuyo: devuelve las llaves al salir.")
			return true
		if ob == "cajaL":
			await neg_caja(k)
		elif ob == "fregona":
			await neg_limpiar(k)
		elif ob == N.go:
			if N.txt.has(ob):
				await say(N.txt[ob])
			await neg_genero(k)
		elif ob in ["bedT", "bedB"]:
			await bed_action("La cama del cuartucho: un somier de 90, una manta de cuadros y la radio en la mesilla.")
		elif ob == "armR":
			if await ask(N.txt.armR, ["Cambiarte de ropa", "Nada"]) == 0:
				await vestirte()
		else:
			await say(N.txt.get(ob, ATREZO_TXT.get(S.map, {}).get(ob, "Lo de %s." % D.LOCALES[k].neg)))   # 1.57.2: y el atrezo del taller
		return true
	if S.map == "nave" and o in ["bedT", "bedB"]:   # 1.45: el camastro de la nave
		await bed_action("El camastro de la nave, detrás de las mesas: se oyen los extractores toda la noche.")
		return true
	if S.map == "club-rv" and o == "almC":   # 1.45: el almacén del club
		await almacen_club()
		return true
	if S.map == "shop" or S.map == "growcity":   # los dos grows (1.34): lo nuevo de cada uno
		match o:
			"pizarra":
				txt = "En la pizarra de Kiko, a tiza: «%s»." % D.PIZARRA_KIKO[int(S.day) % D.PIZARRA_KIKO.size()]
			"sacos":
				txt = "Sacos de 50 litros: fibra de coco, perlita y tierra abonada."
			"macetasP":
				txt = "Macetas de tela apiladas, de 11, 18 y 25 litros."
			"botesW":
				txt = "Botes de abono por litros: MEATZA en azul, ORTUA BIO en verde."
			"neonG":
				txt = "Un neón verde: una hoja de siete puntas y GROW IBARBIDE debajo."
			"semillero":
				txt = "Un propagador con tapa: bandejas de alveolos con esquejes de muestra y su manta térmica."
			"carpaDemo", "carpaDemo2":
				txt = "La carpa de exposición: 120 × 120, con el LED de barras encendido y plantas de plástico dentro."
		if txt == "":
			return false
		await say(txt)
		return true
	if S.map.begins_with("club-"):
		var k: String = S.map.substr(5)
		var C: Dictionary = D.CLUBS[k]
		if o == "mesita" and D.ORDEN_P.has(S.map) and aso().pres:   # 1.37 (lo pidió el usuario): de presidente, desde una mesita se ordena el local
			if await ask(D.MUEBLE_CLUB[k].mesa, ["Ordenar el local", "Nada"]) == 0:
				await ordenar(S.map)
			return true
		match o:
			"tarros":
				txt = "Tarros de cristal con la etiqueta de cada variedad que ha pasado por el club."
			"pizarra":
				txt = "En la pizarra, a tiza: «Hoy, %s»." % strain(C.sid[int(S.day) % C.sid.size()]).n
			"cartelC":
				txt = "NORMAS DE %s\nSolo socios mayores de edad, con el carné a la vista. Lo que se retira, se consume dentro." % C.n
			"tacos":
				txt = "El taquero: seis tacos, la tiza y el triángulo."
			"vitrina":
				txt = "La vitrina del dispensario: tarros con muestras y una báscula de precisión."
			"mesita":   # 1.34: cada club, con los suyos
				txt = D.MUEBLE_CLUB[k].mesa
			"sofaF", "sofaF2", "sofaB", "sofaB2":
				txt = D.MUEBLE_CLUB[k].sofa
			"billar", "billar2":
				txt = "La mesa de billar, con el tapete recién cepillado. %s %s." % [D.BILLAR.n[k], "echa partidas" if Datos.PLAY else "juega con apuesta"]
			"poster":
				txt = "Un cartel antiguo de una feria del cáñamo."
			"fotoMaite", "fotoMaite2":   # 1.32 (1.33: de 2 casillas)
				txt = "%s, en un campo. En la placa: «Maite, presidenta fundadora»." % ("La tía Maite y Delroy, de jóvenes" if aso().tio else "La tía Maite, joven, con un hombre de rastas negras")
			"plantDeco":
				txt = "Una kentia en una maceta de barro."
		if txt == "" and D.DECO_CLUB.has(o):   # 1.34: lo que cuelga de sus paredes
			txt = D.DECO_CLUB[o]
	if S.map == "nave":
		if S.get("nave") == null:
			await say("La nave está vacía.")
			return true
		match o:
			"mesaN", "mesaN2":
				await mesa_nave(mesa_idx(x, y))   # 1.37: donde esté (12d-orden)
				return true
			"estanteN":
				await estante_nave()
				return true
			"secadero":
				await secadero_nave()
				return true
			"escritorio", "escritorio2":
				await escritorio_nave()
				return true
			"carpaM", "carpaM2":   # 1.34
				await carpa_madres()
				return true
			"clonN", "clonN2":   # 1.43
				await bandejas_nave()
				return true
			"tanqueN", "riegoN", "ctrlN":   # 1.52.1: el riego, que también se mueve desde aquí
				if puertas_int("nave").size():
					if await ask("El riego de la nave: %s." % D.RIEGO_NAVE[int(S.nave.rg)].n, ["Ordenar la nave", "Nada"]) == 0:
						await ordenar("nave")
					return true
			"crate":
				txt = "Sacos de sustrato y macetas apiladas."
	if S.map == "setas" or S.map == "sotano":   # 1.34: el bajo de las setas por dentro (1.51: y el sótano de casa)
		if SL() == null:
			await say("El sótano está a medio hacer: mañana acaban los obreros." if S.map == "sotano" else "El bajo ya no es tuyo. Txomin cambiará la cerradura.")
			return true
		match o:
			"baldaS":
				if Datos.CAL:   # 1.43.9: las baldas a la vista, con las setas creciendo
					await vista_bajo(2 * balda_i(x))
				else:
					await bajo_menu("")
				return true
			"humidS":
				if SL().bandejas.any(func(b): return not b.get("mala")):
					await pulverizar_bajo()
				else:
					await say("El pulverizador de mochila de Txomin. Con él se tienen húmedas las bandejas.")
				return true
			"secaS", "deshidS":
				if Datos.CAL:   # 1.44: lo que se seca, y cuándo pasa al armario
					txt = txt_secando(o)
				else:
					txt = ("En el secadero, %s de setas secas. Txomin te las compra en la puerta." % g_txt(SL().g)) if SL().g >= 1 else "El secadero está vacío. Lo que recojas se seca aquí."
			"armS":   # 1.44: el armario de almacén, por dentro
				await vista_armario()
				return true
			"mesaS":   # 1.44: la mesa de trabajo
				await mesa_setas()
				return true
			"tuboS":
				txt = "Una tubería vieja que suda. Por eso aquí la humedad nunca baja."
			"crate":
				txt = "Cajas de bandejas vacías de Txomin, apiladas."
			"cuboS":
				txt = "Un cubo y un cepillo. Lo que se echa a perder, fuera."
	if S.map == "conce":   # 1.43
		var C: Dictionary = D.CONCE
		for k in C.orden:
			if o == C.v[k].o or o == C.v[k].o + "2":
				await ficha_expo(k)
				return true
		match o:
			"rotuloK", "rotuloK2":
				txt = "AUTOS RIBERA. Debajo, más pequeño: «Concesionario · Taller · Financiación»."
			"preciosK":
				txt = "Precios con IVA. Aparte, la matriculación (el impuesto, según las emisiones) y %s de gestoría y placas." % Datos.eur(C.gastos)
			"catalogoK":
				txt = "Catálogos con las fichas técnicas: potencia, consumo, emisiones y la etiqueta medioambiental."
			"cafeK":
				txt = "Una cafetera de cápsulas y vasitos para los clientes. Huele a café y a coche nuevo."
			"ruedasK":
				txt = "Neumáticos de invierno, apilados. Con el coche se monta un juego en el taller."
			"mesaK", "mesaK2":
				txt = "La mesa de %s, con el ordenador y los contratos. Habla con ella." % "Arantxa"
			"plantDeco":
				txt = "Una planta de plástico con polvo."
	if S.map == "disco":
		match o:
			"bottles":
				txt = "Botellas de ginebra, ron y vodka, iluminadas desde abajo."
			"neon":
				txt = "El neón de %s: la luna rosa." % D.DISCO.n
			"altavoz":
				txt = "El altavoz retumba en el pecho."
			"cabina", "cabina2":
				txt = "La cabina del DJ: dos platos y la mesa de mezclas."
			"sofaV", "sofaV2", "mesaV":
				txt = "El reservado: sofá de terciopelo y una cubitera en la mesa."
			"cordon", "cordonF":
				txt = "El cordón del reservado. Lo abre la RRPP."
	if txt == "":
		return false
	await say(txt)
	return true

# 1.43.3: donde lleva el club una mujer (GENERO.enc), «la encargada»
func con_encargada(t: String, k: String) -> String:
	return t.replace("El encargado", "La encargada") if Datos.CAL and D.GENERO.enc.has(k) else t

# 1.34: los demás socios de cada club (GENTE_CLUB)
func talk_gente_club(k: String, j: int):
	var e = ents.filter(func(x): return x.id == "cg%d" % (j + 1))
	await say(con_encargada(D.GENTE_CLUB[(int(S.day) + j + D.CLUBS.keys().find(k)) % D.GENTE_CLUB.size()], k), "SOCIA" if Datos.CAL and e.size() and mujer_look(e[0].look) else "SOCIO")

# el sprite de lo que cambia en los locales (1.34, spriteLocal de 11j-locales): el secadero del bajo, con setas o vacío, y la carpa de
# las madres, con las que tenga; los demás, con estilo, el de su club (estiloLocal)
func sprite_local(o: String) -> String:
	if o == "secaS":
		if Datos.CAL:   # 1.44: con setas tendidas mientras se secan en la malla (sin deshidratador)
			return "secaS-%d" % (1 if SL() != null and not SL().get("dh") and SL().get("fr", []).size() else 0)
		return "secaS-%d" % (1 if SL() != null and SL().g >= 1 else 0)
	if o == "deshidS":
		return "deshidS-%d" % (1 if SL() != null and SL().get("fr", []).size() else 0)
	if o == "armS":
		return "armS-%d-%d-%d" % [lleno_arm("g"), lleno_arm("mc"), lleno_arm("cc")]
	if o == "mesaS":
		return "mesaS-%d-%d" % [1 if S.get("setas") != null and S.setas.get("enc") else 0, 1 if S.get("setas") != null and S.setas.get("mol") else 0]
	if o == "carpaM":
		return "carpaM-%d" % (S.nave.ma.size() if S.get("nave") != null and S.nave.has("ma") else 0)
	if o == "clonN":   # 1.43: el carro de bandejas de la nave, por lo lleno
		var nb: int = S.nave.bc.size() if S.get("nave") != null and S.nave.has("bc") else 0
		return "clonN-%d" % (0 if nb == 0 else 1 if nb <= 2 else 2)
	if o == "rotuloL":   # 1.35 (granja.gd)
		return sprite_rotulo()
	var e = MAPS[S.map].get("est") if MAPS.has(S.map) else null
	return (o + "-" + e) if e and D.ESTILO_OBJ.has(o) else o

# las bandejas de la balda x del bajo (1.34, bandejasBalda): las dos que le tocan (2x abajo, 2x + 1 arriba), en su fase
func bandejas_balda(x: int) -> Array:
	var r := []
	if SL() == null:
		return r
	var B: Array = SL().bandejas
	var bi := balda_i(x)
	for j in 2:
		if 2 * bi + j < B.size():
			r.append("bandejaS-%s-%d" % [fase_seta(B[2 * bi + j]), j])
	return r

# ---------- el club: el socio y el billar ----------
func talk_socio(k: String):
	var nn: String = D.SOCIO.n[k]
	var N := nn.to_upper()
	var c: int = await ask(pick(["¿Qué tal? Siéntate, hay sitio.", "Aquí se está tranquilo, ¿eh?"]), ["Charlar", "Compartir uno", "Nada"], N)
	if c == 0:
		await say(con_encargada(pick(D.SOCIO.charla), k), N)
		return
	if c != 1:
		return
	if S.porro.get(k) == S.day:
		await say("Hoy ya hemos compartido. Mañana, más.", N)
		return
	var lots := bud_lots(D.SOCIO.g)
	if lots.is_empty():
		await say("Cuando tengas algo encima, lo compartimos. Con %s vale." % g_txt(D.SOCIO.g), N)
		return
	var it: Array = lots.map(func(l): return lot_item(l))
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué compartes?"})
	if i < 0 or i >= lots.size():
		return
	var kk: String = lots[i][0]
	var thc: float = lots[i][1].thc
	use_buds(kk, D.SOCIO.g)
	S.porro[k] = S.day
	confia(k, int(D.SOCIO.rel))
	advance_time(int(D.SOCIO.min))
	update_hud()
	sfx("sel")
	await say("Compartes %s en el sofá. %s: «%s»" % [lot_nombre(kk), nn, "Esto es otra liga. Se lo cuento a los del club." if thc >= 20 else "Suave, de los de charlar. Gracias."])

# el billar (1.35, talkBillar de 11j-locales): una partida corta a la bola 8, con el tiro elegido (TIROS) y dos barras, la dirección
# y la fuerza; quien mete, sigue; gana quien mete la negra con las suyas dentro. MESA_B: la mesa que se ve mientras dura (pinta.gd)
var TIRO = null   # la barra mientras apuntas: {t0, f: "dir" o "fuerza", a}, en el reloj del juego (pinta.gd la dibuja)
var MESA_B = null

func fuerza_tiro(ms: float, per := -1.0) -> float:
	if per < 0:
		per = float(D.BILLAR.periodo)
	var f: float = fmod(ms, per) / per
	return f * 2 if f < .5 else 2 - f * 2

func resultado_tiro(d: float, f: float, a: float) -> String:
	if f >= float(D.BILLAR.falta):
		return "falta"
	return "dentro" if absf(d - D.BILLAR.centro) <= a and absf(f - D.BILLAR.centro) <= D.BILLAR.verde else "falla"

# un tiro: el texto y, con A, dónde estaba la barra (de 0 a 1; 1.31: arranca en un punto al azar, para que no baste con contar); las
# pruebas lo cambian (gancho_billar, ui.gd)
# 1.36, los minijuegos de las máquinas (o: mov y ritmo): con mov, el verde va y viene en mov ms (la static) y sale lo que se separa
# del verde, como si estuviera quieto en el centro; con ritmo, la barra acelera y frena (la lavadora: el tiempo, deformado)
func centro_tiro(T: Dictionary, now: float) -> float:
	var mv := float(T.get("mov", 0))
	return .5 + .32 * sin((now - T.t0) / mv * 2 * PI) if mv else float(D.BILLAR.centro)

func pos_tiro(T: Dictionary, now: float) -> float:
	var ms: float = now - T.t0
	var per := float(T.get("per", -1.0))
	if per < 0:
		per = float(D.BILLAR.periodo)
	var q := per * 1.6
	var rt := float(T.get("ritmo", 0))
	return fuerza_tiro(ms + rt * q / (2 * PI) * sin(ms / q * 2 * PI) if rt else ms, per)

func tiro_billar(txt: String, fase := "fuerza", a := 0.0, per := -1.0, nom := "BILLAR", o := {}) -> float:   # 1.35: per y nom, las extracciones
	if gancho_billar.is_valid():
		return float(gancho_billar.call(txt))
	if per < 0:
		per = float(D.BILLAR.periodo)
	await type_text(txt, nom)
	var pr := Motor.Prom.new()
	TIRO = {"t0": M.reloj - Cultivo.azar() * per, "f": fase, "a": a, "per": per, "mov": float(o.get("mov", 0)), "ritmo": float(o.get("ritmo", 0))}
	if o.has("esc"):   # 1.38: la escena de la extracción encima de la barra (escena_extr.gd)
		TIRO.esc = o.esc
		TIRO.paso = o.paso
		TIRO.n = o.n
	push(func(b: String):
		if b == "A":
			pop()
			pr.res(pos_tiro(TIRO, M.reloj) - centro_tiro(TIRO, M.reloj) + float(D.BILLAR.centro)))
	var p: float = await Motor.espera(pr)
	TIRO = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	sfx("hit")
	return p

# las extracciones (1.35, 11l-extraccion): una tanda de barras; la calidad q es la parte que entra, y sale rend × (0,6 + 0,4 q)
# del peso con thc × (0,9 + 0,1 q) veces el THC, hasta tope
func sale_extr(E: Dictionary, g: float, q: float) -> float:
	return maxf(.1, Datos.jsround(g * E.rend * (.6 + .4 * q) * 10) / 10.0)

func extraer(t: String):
	var E: Dictionary = D.EXTR[t]
	if t == "seco" and S.items.get("mallas00"):   # 1.36: con las mallas 00, el dry sift «doble cero»
		E = E.duplicate(true)
		E.merge(D.SECO00, true)
		E.pasos = D.EXTR.seco.pasos + [D.SECO00.paso]
	var kief: bool = E.de == "kief"
	var N: String = E.n.to_upper()
	var lots: Array = kief_lots(1) if kief else bud_lots(5)
	if lots.is_empty():
		await say("%s: necesitas %s como mínimo." % [N, "1 g de kief, del tamiz o del Ice-o-lator," if kief else "5 g de cogollos"])
		return
	var oil = null
	var kf = null
	if t == "moon":
		oil = mayor_lote(rosin_lots(D.MOON.oil).filter(func(l): return tipo_extr(l[0]) == "rosin"))
		kf = mayor_lote(kief_lots(D.MOON.kief))
		if oil == null or kf == null:
			await say("MOONROCK: necesitas rosin para bañar el cogollo y kief para rebozarlo.")
			return
	var it := lots.map(rosin_item if kief else lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "%s: ¿de qué?" % E.n})
	if i < 0 or i >= lots.size():
		return
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var tope := int(floor(b.g))
	if oil != null:
		tope = mini(tope, mini(int(floor(oil[1].g / D.MOON.oil + 1e-9)), int(floor(kf[1].g / D.MOON.kief + 1e-9))))
	if tope < 1:
		await say("MOONROCK: no te llega el rosin o el kief para un gramo.")
		return
	var base: Array = [1, 5, 25] if kief else ([1, 3, 10] if oil != null else [5, 25, 100])
	var ops: Array = base.filter(func(g): return g < tope)
	ops.append(tope)
	var tx := ops.map(func(g): return "%d g → %s g de %s" % [g, Datos.coma(sale_extr(E, g, 1)), E.n.to_lower()])
	tx.append("Nada")
	var j: int = await ask("%s: %d g. ¿Cuánto usas?" % [(E.n + " · " + lot_nombre(k)) if kief else lot_nombre(k), tope], tx)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	await say(E.d, N)
	var ok := 0
	for ip in E.pasos.size():
		var p: Array = E.pasos[ip]
		var d: float = await tiro_billar(p[0], "dir", p[1], E.per, N, E.merged({"esc": t, "paso": ip, "n": E.pasos.size()}, true))
		if absf(d - float(D.BILLAR.centro)) <= p[1]:
			ok += 1
	var q: float = float(ok) / E.pasos.size()
	var r := sale_extr(E, g, q)
	var thc: float = b.thc
	if oil != null:
		var o: float = Datos.jsround(g * D.MOON.oil * 10) / 10.0
		var m: float = Datos.jsround(g * D.MOON.kief * 10) / 10.0
		thc = (b.thc * g + oil[1].thc * o + kf[1].thc * m) / (g + o + m)
		use_rosin(oil[0], o)
		use_rosin(kf[0], m)
	thc = minf(E.tope, thc * E.thc * (.9 + .1 * q))
	if kief:
		use_rosin(k, g)
	else:
		use_buds(k, g)
	add_rosin(k if t == "rosin" else base_extr(k) + "~" + E.get("sale", t), r, thc)
	advance_time(E.min)
	sfx("get")
	await say("%s. %s de %s: %s g con un %s %% de THC." % ["Te sale perfecto" if q >= 1 else "Te sale bien, con algo de pérdida" if q >= .5 else "Te sale regular: pierdes bastante",
		E.n, lot_nombre(base_extr(k)), Datos.coma(r), Datos.pct(thc)])

func una_bola(m: int) -> String:
	return "una" if m == 1 else str(m)

func talk_billar(k: String):
	var B: Dictionary = D.BILLAR
	var nb: String = B.n[k]
	var N := nb.to_upper()
	var Db = S.billar.get(k)
	if not (Db is Dictionary and Db.d == S.day):
		Db = {"d": S.day, "n": 0}
		S.billar[k] = Db
	if Db.n >= B.dia:
		await say("Por hoy ya está bien. Mañana te doy la revancha.", N)
		return
	var ops: Array = ["Una partida"] if Datos.PLAY else B.apuestas.map(func(e): return "A " + Datos.eur(e))   # Google Play: sin apuestas
	ops.append("Nada")
	var c: int = await ask(("¿Una a la bola 8? %d lisas para ti, %d rayadas para mí y la negra al final: quien la meta, gana." if Datos.PLAY else "¿Una a la bola 8? %d lisas para ti, %d rayadas para mí y la negra al final: quien la meta se lleva la apuesta.") % [int(B.bolas), int(B.bolas)], ops, N)
	if c < 0 or c >= ops.size() - 1:
		return
	var e: int = 0 if Datos.PLAY else int(B.apuestas[c])
	if S.money < e:
		sfx("bad")
		await say("Sin dinero encima no se juega.", N)
		return
	Db.n += 1
	var V := {"yo": int(B.bolas), "el": int(B.bolas), "negra": 1}
	MESA_B = V
	var yo := true
	var mano := false
	var seguro := false
	var deja := 1.0
	var fin := ""
	await say("Sacas tú. Las tuyas, las lisas.")
	var t := 0
	while t < int(B.turnos) and fin == "":
		t += 1
		if yo:
			var extra := " Bola en mano: la colocas donde quieras." if mano else (" La blanca ha quedado bien." if deja > 1 else "")
			var i: int = await ask("Tu turno · te %s; a %s, %s.%s" % ["quedan %d" % V.yo if V.yo else "queda la negra", nb, str(V.el) if V.el else "la negra", extra], D.TIROS.map(func(x): return x.n))
			var T: Dictionary = D.TIROS[0 if i < 0 else i]
			if T.get("seguro"):
				seguro = true
				deja = 1.0
				mano = false
				yo = false
				await say("Escondes la blanca detrás de sus bolas. Le toca, y no lo tiene fácil.")
				continue
			var a: float = Datos.jsround(float(T.a) * deja * (float(B.manoX) if mano else 1.0) * 1000) / 1000.0
			deja = 1.0
			mano = false
			var d1 := await tiro_billar("%s: para la barra en el verde para apuntar." % T.n, "dir", a)
			var f1 := await tiro_billar("Ahora la fuerza: en el verde, dentro; pasada, se cuela la blanca.", "fuerza")
			var r := resultado_tiro(d1, f1, a)
			if r == "falta":
				if not V.yo:
					fin = "el"
					await say("La negra entra... y la blanca detrás. Falta sobre la negra: pierdes.")
					break
				mano = true
				yo = false
				await say("Demasiado fuerte: la blanca se cuela. Falta: %s juega con bola en mano." % nb)
				continue
			if r == "dentro":
				if not V.yo:
					V.negra = 0
					fin = "yo"
					await say("¡La negra, dentro!")
					break
				V.yo -= 1
				deja = float(T.get("deja", 1))
				await say(("¡Dentro! Te %s %d. Sigues tú." % ["quedan" if V.yo > 1 else "queda", V.yo]) if V.yo else "¡Dentro! Ya solo te queda la negra. Sigues tú.")
				continue
			yo = false
			await say("No entra. Le toca a %s." % nb)
			continue
		var p: float = float(B.hab[k]) + (float(B.mano) if mano else 0.0)
		var m := 0
		var falta := false
		if seguro:
			p *= float(B.seguro)
		mano = false
		seguro = false
		while true:
			var rr := Cultivo.azar()
			if rr < p:
				if not V.el:
					V.negra = 0
					fin = "el"
					break
				V.el -= 1
				m += 1
				p = float(B.hab[k])
				continue
			if rr > float(B.faltaR):
				falta = true
			break
		if fin != "":
			await say("%s %stira a la negra: dentro." % [nb, ("mete %s y " % una_bola(m)) if m else ""])
			break
		if falta and not V.el:
			fin = "yo"
			await say("%s tira a la negra y se le cuela la blanca. Falta sobre la negra: pierde." % nb)
			break
		if falta:
			mano = true
		yo = true
		var tx: String
		if m:
			tx = "mete " + una_bola(m) + (" y se le cuela la blanca: bola en mano para ti." if falta else " y falla.")
		else:
			tx = "cuela la blanca: bola en mano para ti." if falta else "falla."
		await say("%s %s" % [nb, tx])
	MESA_B = null
	if fin == "yo":
		S.money += e
		confia(k, 1)
		sfx("coin")
	elif fin == "el":
		S.money -= e
		sfx("bad")
	advance_time(int(B.min))
	update_hud()
	if Datos.PLAY:
		await say(("Ganas tú. %s: «La próxima, la revancha»." % nb) if fin == "yo" else ("Gana %s." % nb) if fin == "el" else "Se hace tarde y lo dejáis en tablas.")
	elif fin == "yo":
		await say("Ganas tú. %s te paga %s: «La próxima, la revancha»." % [nb, Datos.eur(e)])
	elif fin == "el":
		await say("Gana %s. Le pagas %s." % [nb, Datos.eur(e)])
	else:
		await say("Se hace tarde y lo dejáis en tablas. Nadie paga.")

# la mesa del billar mientras dura la partida (rectsMesaBillar de 11j-locales): [x, y, w, h, color] en la pantalla
func rects_mesa_billar(V: Dictionary) -> Array:
	var x0: int = (SW - 100) >> 1
	var y0 := 4
	var o := [[x0 - 1, y0 - 1, 102, 54, "#26262e"], [x0, y0, 100, 52, "#74502e"], [x0, y0, 100, 1, "#a46e40"], [x0 + 4, y0 + 4, 92, 44, "#2f7a46"]]
	for q in [[2, 2], [48, 2], [94, 2], [2, 46], [48, 46], [94, 46]]:
		o.append([x0 + q[0], y0 + q[1], 4, 4, "#121519"])
	var MB: Dictionary = D.MESA_BOLAS
	var bola := func(q, c: String, b: String) -> void:
		var x: int = int(q[0]) + x0 + 4
		var y: int = int(q[1]) + y0 + 4
		o.append([x + 1, y, 2, 4, c])
		o.append([x, y + 1, 4, 2, c])
		if b != "":
			o.append([x, y + 1, 4, 2, b])
	bola.call(MB.blanca, "#f8f8f0", "")
	for i in mini(int(V.yo), MB.yo.size()):
		bola.call(MB.yo[i], "#e0b84a", "")
	for i in mini(int(V.el), MB.el.size()):
		bola.call(MB.el[i], "#f8f8f0", "#e04040")
	if V.negra:
		bola.call(MB.negra, "#26262e", "")
	return o

# ---------- la nave: mesas, estantería, secadero y escritorio ----------
# S.nave: {m: las NAVE.max mesas (null, vacía, o {k: el lote, f: el fenotipo, thc, y: × cosecha, dia: el de plantar, g y t: lo que hay
# en el secadero y su THC medio, abo: 0 sin abono, 1 MEATZA, 2 ORTUA BIO}), ab: {m, o}: dosis de floración de cada marca en la estantería}
func nave_nueva() -> Dictionary:
	var m := []
	m.resize(int(D.NAVE.max))
	var fs := []
	for i in int(D.NAVE.max):
		fs.append("led")
	return {"m": m, "ab": {"m": 0, "o": 0}, "f": fs, "ex": 0, "rg": 0, "ma": [], "r": S.day + D.RECIBO.dias}   # 1.34: las madres (ma); 1.35: el día del recibo (r)

# el equipo de la nave (1.33, FOCO_NAVE, EXTR_NAVE, RIEGO_NAVE y NIVEL_NAVE de 11j-locales): el calor de los focos encendidos, lo que
# quita el que no saca la extracción y las dosis de la estantería, enteras
func calor_nave() -> float:
	var t := 0.0
	for i in S.nave.m.size():
		if S.nave.m[i]:
			t += float(D.FOCO_NAVE[S.nave.f[i]].calor)
	return t

func sofoco_nave() -> float:
	return maxf(.6, 1 - .08 * maxf(0, calor_nave() - float(D.EXTR_NAVE[int(S.nave.ex)].cap)))

func dosis_txt(x) -> String:
	return Datos.js_num(Datos.jsround(float(x) * 10) / 10.0).replace(".", ",")

func nivel_nave() -> String:
	return D.NIVEL_NAVE[int(S.nave.ex) + int(S.nave.rg)]

func nave_stock() -> float:
	var t := 0.0
	if S.get("nave") != null:
		for Me in S.nave.m:
			if Me:
				t += Me.g + (float(Me.h.g) if Me.get("h") != null else 0.0)
	return t

# lo que cuelga secándose en el secadero (1.41): g
func colgado_nave() -> float:
	var t := 0.0
	if S.get("nave") != null:
		for Me in S.nave.m:
			if Me and Me.get("h") != null:
				t += float(Me.h.g)
	return t

func fase_mesa(i: int) -> int:
	if S.get("nave") == null or i < 0 or i >= S.nave.m.size() or not S.nave.m[i]:
		return 0
	var Me: Dictionary = S.nave.m[i]
	if Me.get("p") == null:   # una mesa de antes de la 1.41 (las pantallas del HTML): por días
		var d: int = int(S.day - Me.dia)
		return 1 if d < 1 else (2 if d < 3 else (3 if d < D.NAVE.crece else 4))
	var p := float(Me.p)   # 1.41: por el ciclo, como las plantas del piso (plant_stage)
	return 1 if p < .35 else (2 if p < .65 else (3 if p < .85 else 4))

func thc_nave(sid: String, f) -> float:
	return Datos.jsround(strain(sid).thc * (f.t if f else 1.0) * D.NAVE.thc * 10) / 10.0

func mesa_txt(Me: Dictionary) -> String:
	return strain(lot_sid(Me.k)).n + etiq(Me.get("f"))

func mesa_nave(i: int) -> void:
	var N: Dictionary = S.nave
	var Me = N.m[i]
	var w = navero_de(i)
	var ops: Array = ["Arrancar y plantar" if Me else "Plantar"]
	if Me:
		ops.append("Abono")
	ops.append("Focos")
	ops.append("Nada")
	var que: String = (mesa_txt(Me) + " · " + D.FASE_MESA[fase_mesa(i)] + " · " + cosecha_txt(Me) + " · " + D.ABONO_MESA[int(Me.abo)]) if Me else "vacía"
	var oi: int = await ask("Mesa %d · %s · %s\n%s" % [i + 1, que, D.FOCO_NAVE[N.f[i]].n, ("La cuida " + w.n + ".") if w else "Nadie la cuida: pon a alguien de tu plantilla en la nave."], ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op == "Focos":
		await focos_nave(i)
	elif op == "Plantar" or op == "Arrancar y plantar":
		if Me and Me.get("h") != null:
			await say("Lo de esta mesa aún se está secando en el secadero: espera a descolgarlo.")
			return
		if Me and Me.g >= 1:
			await say("Antes, descuelga del secadero lo de esta mesa.")
			return
		await plantar_mesa(i)
	elif op == "Abono":
		var c: int = await ask("¿Qué abono le echa cada día? En la estantería: MEATZA ×%s · ORTUA BIO ×%s." % [dosis_txt(N.ab.m), dosis_txt(N.ab.o)], ["Sin abono", "MEATZA Floración", "ORTUA BIO Floración", "Nada"])
		if c < 3:
			Me.abo = c
			sfx("sel")

# una semilla o un esqueje de los tuyos, que se gasta (1.34, elegirPlanta: o, con madres, el clon de una madre de la nave, que no se
# gasta): {sid, f} o null
func elegir_planta(title: String, madres: bool):
	var own := _own()
	var esq := []   # [esqueje, 1 si es de las bandejas del carro]
	for e in S.esquejes:
		esq.append([e, 0])
	for e in S.bandejas:
		esq.append([e, 1])
	var ma: Array = S.nave.ma if madres and S.get("nave") != null else []
	var bc: Array = bandejas_listas() if madres else []   # 1.43: las bandejas de clones enraizados de la nave
	if own.is_empty() and esq.is_empty() and ma.is_empty() and bc.is_empty():
		await say("No llevas semillas ni esquejes.")
		return null
	var items := []
	for j in ma.size():
		var k := lot_sid(ma[j].k)
		var s = strain(k)
		items.append({"label": "Madre %d: %s%s" % [j + 1, s.n, etiq(ma[j].get("f"))], "right": "clon", "sw": s.c, "ic": ic_cog(k), "desc": "Un clon de la carpa de las madres: no se gasta nada."})
	for b in bc:
		var k := lot_sid(b.k)
		var s = strain(k)
		items.append({"label": "Bandeja: %s%s" % [s.n, etiq(b.get("f"))], "right": "%d clones" % int(D.NAVE.tacos), "sw": s.c, "ic": ic_cog(k), "desc": "Los clones enraizados del carro de bandejas: una mesa entera."})
	for o in own:
		var s = strain(o[0])
		items.append({"label": s.n, "right": "×" + n(o[1]), "sw": s.c, "ic": ic_cog(o[0]), "desc": strain_line(o[0])})
	for eb in esq:
		var s = strain(eb[0].sid)
		items.append({"label": "Esqueje " + s.n + etiq(eb[0].f), "right": "bandeja" if eb[1] else "esqueje", "sw": s.c, "ic": ic_cog(eb[0].sid), "desc": "Clon enraizado: sale con su fenotipo."})
	items.append({"label": "Cancelar", "desc": ""})
	var j: int = await menu(items, {"cls": "full", "title": title, "desc": true})
	if j < 0 or j >= items.size() - 1:
		return null
	if j < ma.size():
		return {"sid": lot_sid(ma[j].k), "f": ma[j].f}
	j -= ma.size()
	if j < bc.size():
		S.nave.bc.erase(bc[j])
		return {"sid": lot_sid(bc[j].k), "f": bc[j].get("f")}
	j -= bc.size()
	if j < own.size():
		var sid: String = own[j][0]
		S.seeds[sid] -= 1
		if not S.seeds[sid]:
			S.seeds.erase(sid)
		return {"sid": sid, "f": roll_feno(sid)}
	var e: Dictionary = esq[j - own.size()][0]
	var l: Array = S.bandejas if esq[j - own.size()][1] else S.esquejes
	l.remove_at(l.find(e))
	return {"sid": e.sid, "f": e.f}

# con una semilla o un esqueje, tu gente saca una madre y llena la mesa de clones: toda la mesa, con su fenotipo
func plantar_mesa(i: int) -> void:
	var p = await elegir_planta("¿QUÉ PLANTAS EN LA MESA?", true)
	if p == null:
		return
	var sid: String = p.sid
	var f: Dictionary = p.f
	S.nave.m[i] = {"k": sid + ("*" if Cultivo.clase_feno(f) == "estrella" else ""), "f": f, "thc": thc_nave(sid, f), "y": f.y, "dia": S.day, "g": 0, "t": 0, "abo": 0, "p": float(D.NAVE.clon), "dn": 0, "am": 0, "ao": 0, "n": 0}
	sfx("sel")
	await say("Mesa %d: %s%s. De la madre salen los clones para toda la mesa: enraízan, crecen a 18/6 y florecen a 12/12. Se cosecha entera en unos %d días y vuelve a empezar." % [i + 1, strain(sid).n, etiq(f), dias_mesa(S.nave.m[i])])

# la carpa de las madres (1.34, carpaMadres de 11j-locales): hasta MADRES.max madres (S.nave.ma: {k, f, v: el vigor, e: los esquejes
# listos}); se mete una con una semilla o un esqueje; los esquejes se recogen aquí, al propagador (S.esquejes, con su tope)
func cuida_madres():
	for w in S.plantilla:
		if w.get("rol") == "madres":
			return w
	return null

func madre_txt(M: Dictionary) -> String:
	return strain(lot_sid(M.k)).n + etiq(M.get("f"))

func carpa_madres() -> void:
	var N: Dictionary = S.nave
	var i := 0
	while true:
		var c = cuida_madres()
		var rows := []
		for j in N.ma.size():
			var M: Dictionary = N.ma[j]
			var k := lot_sid(M.k)
			var s = strain(k)
			rows.append({"label": "Madre %d · %s" % [j + 1, s.n], "right": ("%d esq." % int(M.e)) if M.e else ("%d %%" % int(M.v)), "sw": s.c, "ic": ic_cog(k),
				"desc": "%s. Vigor %d %%%s." % [madre_txt(M), int(M.v), (" · %d esquejes listos" % int(M.e)) if M.e else ""]})
		if N.ma.size() < int(D.MADRES.max):
			rows.append({"label": "Meter una madre", "right": "%d de %d" % [N.ma.size(), int(D.MADRES.max)], "desc": "Con una semilla o un esqueje: la madre de una genética que quieras guardar. De ella salen los esquejes y los clones de las mesas."})
		rows.append({"label": "Volver", "desc": ""})
		i = await menu(rows, {"cls": "full", "title": "LAS MADRES", "title2": ("Las cuida " + c.n) if c != null else "Nadie las cuida", "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0 or i == rows.size() - 1:
			return
		if i >= N.ma.size():
			var p = await elegir_planta("¿QUÉ MADRE METES?", false)
			if p == null:
				continue
			if Datos.CAL and strain(p.sid).get("auto"):   # 1.52
				await say("La %s es autofloreciente: florece por la edad y no se queda de madre. Sus esquejes florecerían enanos." % strain(p.sid).n)
				continue
			N.ma.append({"k": p.sid + ("*" if Cultivo.clase_feno(p.f) == "estrella" else ""), "f": p.f, "v": 100, "e": 0})
			sfx("sel")
			await say("La %s%s, a la carpa de las madres: a 18/6, siempre en crecimiento." % [strain(p.sid).n, etiq(p.f)] + ((" %s se encarga." % c.n) if c != null else " Sin nadie que la cuide, se va apagando: pon a alguien de tu plantilla en las madres."))
			continue
		var M: Dictionary = N.ma[i]
		var ops := []
		if M.e:
			ops.append("Recoger %d %s" % [int(M.e), "esquejes" if M.e > 1 else "esqueje"])
		ops.append_array(["Quitarla", "Nada"])
		var oi: int = await ask("Madre %d: %s · vigor %d %%." % [i + 1, madre_txt(M), int(M.v)] + ("" if M.e else ((" %s le saca esquejes cada mañana." % c.n) if c != null else " Nadie le saca esquejes.")), ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op.begins_with("Recoger"):
			var q: int = mini(int(M.e), int(D.MADRES.propagador) - S.esquejes.size())
			if q < 1:
				await say("El propagador está lleno: %d esquejes. Planta alguno antes." % int(D.MADRES.propagador))
				continue
			for j in q:
				S.esquejes.append({"sid": lot_sid(M.k), "f": M.f, "dia": S.day})
			M.e = int(M.e) - q
			sfx("get")
			await say("%s de la %s, al propagador. Plántalos antes del %s." % [("%d esquejes" % q) if q > 1 else "Un esqueje", madre_txt(M), Datos.fd(int(S.day) + int(D.ESQUEJE_DIAS) + 1, S.day)])
			continue
		if op == "Quitarla":
			if await ask("¿Quitas la madre de %s? Se tira." % madre_txt(M), ["Quitarla", "No"]) != 0:
				continue
			N.ma.remove_at(i)
			sfx("sel")

func talk_madres():
	var w = cuida_madres()
	if w == null:
		return
	var N: Dictionary = S.nave
	var dos: bool = int(D.MADRES.esq) + (1 if w.cui >= 4 else 0) > 1
	await say("La carpa está vacía. Tráeme una madre, una semilla o un esqueje de lo que quieras guardar, y te la cuido." if N.ma.is_empty()
		else "%s, a 18/6 y bien regadas. Cada mañana les saco %s; los tienes en la carpa." % [("%d madres" % N.ma.size()) if N.ma.size() > 1 else "Una madre", "dos esquejes" if dos else "un esqueje"], w.n.to_upper())

# los focos de la mesa i (1.33, focosNave): cambiarlos por los de otro tipo (los de antes se los queda Arrieta)
func focos_nave(i: int) -> void:
	var N: Dictionary = S.nave
	var k: String = N.f[i]
	var ks := []
	var ops := []
	for x in D.FOCO_NAVE:
		if x != k:
			ks.append(x)
			ops.append("%s · %s" % [D.FOCO_NAVE[x].n, Datos.eur(D.FOCO_NAVE[x].p)])
	ops.append("Nada")
	var c: int = await ask("Mesa %d: %s. %s\n¿Los cambias? Los de ahora se los queda Arrieta." % [i + 1, D.FOCO_NAVE[k].n, D.FOCO_NAVE[k].d], ops)
	if c < 0 or c >= ks.size():
		return
	var F: Dictionary = D.FOCO_NAVE[ks[c]]
	if S.money < F.p:
		sfx("bad")
		await say("No te llega.")
		return
	S.money -= F.p
	N.f[i] = ks[c]
	sfx("coin")
	update_hud()
	await say("Arrieta cuelga los %s en la mesa %d. %s" % [F.n, i + 1, F.d] + (" Con tanto foco, la nave se calienta: hará falta más extracción." if calor_nave() > float(D.EXTR_NAVE[int(N.ex)].cap) else ""))

# las mejoras de la nave (1.33, mejorasNave): la extracción y el riego, nivel a nivel
func _fila_mejora(L: Array, k: String, t: String) -> Dictionary:
	var a: Dictionary = L[int(S.nave[k])]
	var b = L[int(S.nave[k]) + 1] if int(S.nave[k]) + 1 < L.size() else null
	return {"label": "%s: %s" % [t, a.n], "right": Datos.eur(b.p) if b else "a tope", "desc": ("Siguiente: %s. %s" % [b.n, b.d]) if b else a.d}

func mejoras_nave() -> void:
	var N: Dictionary = S.nave
	var j := 0
	while true:
		j = await menu([_fila_mejora(D.EXTR_NAVE, "ex", "Extracción"), _fila_mejora(D.RIEGO_NAVE, "rg", "Riego"), {"label": "Volver", "desc": ""}], {"cls": "full", "title": "MEJORAS DE LA NAVE", "title2": "Nave " + nivel_nave(), "desc": true, "initial": j})
		if j < 0 or j > 1:
			return
		var L: Array = D.RIEGO_NAVE if j else D.EXTR_NAVE
		var k := "rg" if j else "ex"
		if int(N[k]) + 1 >= L.size():
			continue
		var b: Dictionary = L[int(N[k]) + 1]
		if await ask("%s: %s %s, montado hoy mismo." % [b.n, b.d, Datos.eur(b.p)], ["Comprar", "No"]) != 0:
			continue
		if S.money < b.p:
			sfx("bad")
			await say("No te llega.")
			continue
		S.money -= b.p
		N[k] = int(N[k]) + 1
		sfx("coin")
		update_hud()
		montar_nave()
		await say("Arrieta y los suyos montan %s. La nave ya es una nave %s." % [b.a, nivel_nave()])

func estante_nave() -> void:
	var N: Dictionary = S.nave
	var ops := []
	if S.items.get("fert", 0):
		ops.append("Dejar MEATZA ×%d" % int(S.items.fert))
	if S.items.get("ofert", 0):
		ops.append("Dejar ORTUA BIO ×%d" % int(S.items.ofert))
	if S.map == "nave" and puertas_int("nave").size():   # 1.52.1: el escritorio está en el despacho; la nave se ordena desde la nave
		ops.append("Ordenar la nave")
	ops.append("Nada")
	var oi: int = await ask("La estantería de los abonos: MEATZA FLORACIÓN ×%s · ORTUA BIO FLORACIÓN ×%s. Cada mesa con abono gasta %suna dosis al día." % [dosis_txt(N.ab.m), dosis_txt(N.ab.o), "menos de " if int(N.rg) >= 2 else ""], ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op.begins_with("Dejar MEATZA"):
		N.ab.m += S.items.fert
		S.items.fert = 0
		sfx("sel")
	elif op.begins_with("Dejar ORTUA"):
		N.ab.o += S.items.ofert
		S.items.ofert = 0
		sfx("sel")
	elif op == "Ordenar la nave":
		await ordenar("nave")

# descolgar del secadero lo que quepa en la mochila, mesa por mesa (cada una, su lote, sin curar y con el día de su cosecha, Me.cd: 1.31)
func secadero_nave() -> void:
	var cu := colgado_nave()
	if nave_stock() - cu < 1:
		if cu >= 1:
			await say("En el secadero cuelgan %s secándose: mañana se pueden descolgar." % g_txt(cu))
		else:
			await say("El secadero está vacío. Cada mesa se cosecha entera al final de su ciclo y se seca aquí %s." % ("un día" if int(D.NAVE.seca) == 1 else "%d días" % int(D.NAVE.seca)))
		return
	var lleva := 0
	var cabe := int(floor(libre_mochila()))
	for Me in S.nave.m:
		if not Me or Me.g < 1:
			continue
		var q: int = mini(int(floor(Me.g)), cabe - lleva)
		if q < 1:
			break
		add_buds(Me.k, q, Me.t, null, 0, Me.get("cd", S.day))
		Me.g = Datos.jsround((Me.g - q) * 10) / 10.0
		lleva += q
	if not lleva:
		await say("No te cabe nada más en la mochila.")
		return
	sfx("get")
	update_hud()
	await say("Descuelgas %s del secadero." % g_txt(lleva) + ((" Quedan %s: no te caben." % g_txt(nave_stock() - cu)) if nave_stock() - cu >= 1 else "") + ((" Siguen colgados %s, secándose." % g_txt(cu)) if cu >= 1 else ""))

func _filas_escritorio() -> Array:
	var N: Dictionary = S.nave
	var rows := []
	for i in N.m.size():
		var Me = N.m[i]
		var w = navero_de(i)
		var ab: String = D.ABONO_MESA[int(Me.abo)] if Me else ""
		rows.append({"label": "Mesa %d · %s" % [i + 1, strain(lot_sid(Me.k)).n if Me else "vacía"], "right": D.FASE_MESA[fase_mesa(i)] if Me else "",
			"desc": ("La cuida " + w.n if w else "Nadie la cuida") + ". " + D.FOCO_NAVE[N.f[i]].n + "." + ((" %s · %s · ciclo %d · en el secadero, %s%s." % [ab.substr(0, 1).to_upper() + ab.substr(1), cosecha_txt(Me), int(Me.get("n", 0)) + 1, g_txt(Me.g), (" y %s secándose" % g_txt(Me.h.g)) if Me.get("h") != null else ""]) if Me else "")})
	rows.append({"label": "Estantería", "right": "%s + %s dosis" % [dosis_txt(N.ab.m), dosis_txt(N.ab.o)], "desc": "MEATZA FLORACIÓN y ORTUA BIO FLORACIÓN: %suna dosis al día por mesa con abono." % ("menos de " if int(N.rg) >= 2 else "")})
	var E: Dictionary = D.EXTR_NAVE[int(N.ex)]
	var so := sofoco_nave()
	rows.append({"label": "Clima", "right": "%s de %s" % [n(calor_nave()), n(E.cap)], "desc": "El calor de los focos encendidos y lo que saca la extracción (%s)." % E.n + ((" Hace demasiado calor: las mesas dan un %d %% menos." % Datos.jsround((1 - so) * 100)) if so < 1 else "")})
	if S.map == "nave":   # 1.52.1 (lo pidió el usuario): solo con el escritorio en la nave; con el despacho, desde la estantería o el riego de la nave
		rows.append({"label": "Ordenar la nave", "right": "", "desc": "Mover las mesas y el tanque del riego: la manguera va del tanque a cada mesa por el suelo libre. Pulsa A."})   # 1.37 (12d-orden)
	rows.append({"label": "La gente", "right": "%d aquí" % de_la_nave().size(), "desc": "Quién cuida cada mesa y las madres: cambiarlos de mesa, una prima o un curso. Pulsa A."})   # 1.34
	rows.append({"label": "Mejoras", "right": "Nave " + nivel_nave(), "desc": "Extracción: %s. Riego: %s. Pulsa A para mejorarlas." % [E.n, D.RIEGO_NAVE[int(N.rg)].n]})
	return rows

func escritorio_nave() -> void:
	var i := 0
	while true:
		var rows := _filas_escritorio()
		i = await menu(rows, {"cls": "full", "title": "LA NAVE", "title2": "%s al día" % Datos.eur(D.NAVE.dia), "desc": true, "initial": i})
		var l: String = rows[i].label if i >= 0 else ""
		if l == "Mejoras":
			await mejoras_nave()
		elif l == "La gente":
			await gente_nave()
		elif l == "Ordenar la nave":
			await ordenar("nave")
		if i < 0:
			break

# la gente de la nave (1.34, genteNave): cada uno con su ficha y su sitio; a los de las mesas, cambiarlos de mesa (con el que la tenga,
# se cambian); a todos, una prima o un curso
func gente_nave() -> void:
	var i := 0
	while true:
		var W := de_la_nave()
		W.sort_custom(func(a, b):
			var ma := 1 if a.rol == "madres" else 0
			var mb := 1 if b.rol == "madres" else 0
			if ma != mb:
				return ma < mb
			return ma == 0 and int(a.mesa) < int(b.mesa))
		if W.is_empty():
			await say("En la nave no trabaja nadie. Pon a tu gente desde el móvil: MÓVIL → PLANTILLA.")
			return
		var rows := []
		for w in W:
			rows.append({"label": w.n, "right": "madres" if w.rol == "madres" else "mesa %d" % (int(w.mesa) + 1), "desc": ficha_gente(w) + ". " + rol_desc(w)})
		rows.append({"label": "Volver", "desc": ""})
		i = await menu(rows, {"cls": "full", "title": "LA GENTE DE LA NAVE", "title2": "%d trabajando" % W.size(), "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0 or i >= W.size():
			return
		var w: Dictionary = W[i]
		var ops := []
		if w.rol == "nave":
			ops.append("Cambiar de mesa")
		ops.append_array(["Prima · " + Datos.eur(D.MANDO.prima), "Curso · " + Datos.eur(D.MANDO.curso), "Nada"])
		var oi: int = await ask("%s · %s · %s" % [w.n, ficha_gente(w), "las madres" if w.rol == "madres" else "la mesa %d" % (int(w.mesa) + 1)], ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "Cambiar de mesa":
			var ms := []
			for j in int(D.NAVE.max):
				if j != int(w.mesa):
					ms.append(j)
			var lb := []
			for j in ms:
				var o = navero_de(j)
				lb.append("Mesa %d" % (j + 1) + ((" · con " + o.n) if o != null else ""))
			lb.append("Nada")
			var c: int = await ask("¿A qué mesa pasa %s?" % w.n, lb)
			if c < 0 or c >= ms.size():
				continue
			var o = navero_de(ms[c])
			if o != null:
				o.mesa = w.mesa
			w.mesa = ms[c]
			sfx("sel")
			await say("%s pasa a la mesa %d" % [w.n, int(w.mesa) + 1] + ((" y %s, a la %d." % [o.n, int(o.mesa) + 1]) if o != null else "."))
		elif op.begins_with("Prima"):
			await prima(w)
		elif op.begins_with("Curso"):
			await curso(w)

func talk_navero(i: int):
	var w = navero_de(i)
	if not w:
		return
	var Me = S.nave.m[i] if S.get("nave") != null else null
	var f := fase_mesa(i)
	var t: String
	if not Me:
		t = "Mi mesa está vacía. Plántame algo y la saco adelante."
	else:
		t = "La %s va bien: %s, %s. Cuando acaba la flor la corto entera, la cuelgo en el secadero y vuelvo a empezar con los esquejes que saqué antes de pasarla a 12/12." % [strain(lot_sid(Me.k)).n, D.FASE_MESA[f], cosecha_txt(Me)] + (" Se ha acabado el abono de la estantería." if Me.abo and float(S.nave.ab["m" if Me.abo == 1 else "o"]) < float(D.RIEGO_NAVE[int(S.nave.rg)].dosis) else "") \
			+ (" Y aquí dentro hace un calor que no veas: hace falta más extracción." if sofoco_nave() < 1 else "")
	await say(t, String(w.n).to_upper())

# ---------- GAUA ----------
# la noche empieza a las 23:00: lo de después de medianoche es de la noche del día anterior (S.noche: lo pagado y hecho esa noche)
func noche_id() -> int:
	return int(S.day) if S.min >= D.DISCO.abre else int(S.day) - 1

func disco_abierta() -> bool:
	return S.min >= D.DISCO.abre or S.min < D.DISCO.cierra

func noche_ya() -> bool:
	return S.get("noche") is Dictionary and int(S.noche.id) == noche_id()

func noche_gaua() -> Dictionary:
	if not noche_ya():
		S.noche = {"id": noche_id(), "copas": 0, "ronda": 0, "baile": 0, "mesa": 0}
	return S.noche

func entrada_disco() -> bool:
	var N := "PORTERO"
	if await ask("La entrada, %s. Se paga una vez por noche." % Datos.eur(D.DISCO.entrada), ["Pagar", "No"], N) != 0:
		return false
	if S.money < D.DISCO.entrada:
		sfx("bad")
		await say("Sin entrada no se pasa.", N)
		return false
	S.money -= int(D.DISCO.entrada)
	noche_gaua()
	sfx("coin")
	update_hud()
	return true

func echar_disco():
	await say("Las seis. Se encienden las luces y el portero echa a todo el mundo.", "PORTERO")
	await warp({"to": "ensanche", "x": 38, "y": 9, "dir": "down"})

func talk_gorila():
	await say("Abrimos a las once de la noche. Hasta las seis." if not disco_abierta() else ("Ya has pagado esta noche. Pasa." if noche_ya() else "La entrada, %s. En la puerta." % Datos.eur(D.DISCO.entrada)), "PORTERO")

# la barra, el DJ y la RRPP, solo con GAUA abierta (1.31): si te quedas quieto pasadas las seis, el portero te echa al hablar con ellos
func talk_barra():
	if not disco_abierta():
		await echar_disco()
		return
	var N := "CAMARERA"
	var X := noche_gaua()
	var c: int = await ask("¿Qué te pongo?", ["Una copa · " + Datos.eur(D.DISCO.copa), "Invitar a una ronda · " + Datos.eur(D.DISCO.ronda), "Nada"], N)
	if c == 0:
		if X.copas >= D.DISCO.copaMax:
			await say("Por hoy ya vale. Agua, si quieres.", N)
			return
		if S.money < D.DISCO.copa:
			sfx("bad")
			await say("Sin dinero no hay copa.", N)
			return
		S.money -= int(D.DISCO.copa)
		X.copas += 1
		if X.copas == 1:
			confia("gaua", 1)
		advance_time(10)
		sfx("coin")
		update_hud()
		await say(["Un gin-tonic con mucho hielo.", "Otra. La música sube.", "La tercera. Mejor que sea la última."][int(X.copas) - 1])
	elif c == 1:
		if X.ronda:
			await say("Ya has invitado esta noche. Con una, ya te conocen.", N)
			return
		if S.money < D.DISCO.ronda:
			sfx("bad")
			await say("No te llega para la ronda.", N)
			return
		S.money -= int(D.DISCO.ronda)
		X.ronda = 1
		S.rep += 1
		confia("gaua", 3)
		advance_time(10)
		sfx("coin")
		update_hud()
		await say("Invitas a la barra entera. Medio local brinda por ti.")

func talk_dj():
	if not disco_abierta():
		await echar_disco()
		return
	var c: int = await ask(pick(["¿Qué tal suena?", "Esta noche se llena."]), ["Bailar", "Pedir una canción", "Nada"], "DJ")
	if c == 0:
		await bailar()
	elif c == 1:
		sfx("sel")
		await say(pick(["Te la pongo después de esta.", "¿Esa? Hace años que no la pincho. Venga, va.", "Esa no la tengo. Te pongo algo parecido."]), "DJ")

# bailar (una vez por noche): media hora y, la mitad de las veces, alguien te pide el número (un pijo para la agenda)
func bailar() -> void:
	var X := noche_gaua()
	if X.baile:
		await say("Ya has bailado esta noche. Las piernas no dan para más.")
		return
	X.baile = 1
	await fade(1)
	advance_time(30)
	update_hud()
	await wait(200)
	await fade(0)
	confia("gaua", 2)
	var id := "gaua%d" % int(X.id)
	if S.fijos.size() < D.FIJOS_MAX and not S.fijos.any(func(f): return f.id == id) and Cultivo.azar() < D.DISCO.ligar:
		var nf := nombre_fijo(id)
		S.fijos.append({"id": id, "n": nf, "t": "pij", "dia": 0})
		sfx("get")
		await say("Bailas media hora sin parar. %s te pide el número: «Si tienes de lo bueno, llámame»." % nf)
		return
	await say("Bailas media hora sin parar. Sales de la pista con la camiseta empapada.")

# el reservado (una vez por noche): una hora y la RRPP te presenta a un cliente VIP (CTYPES.vip) para la agenda
func talk_rrpp():
	if not disco_abierta():
		await echar_disco()
		return
	var N := "RRPP"
	var X := noche_gaua()
	if X.mesa:
		await say("Disfruta del reservado. Si conoces a alguien que merezca la pena, me lo presentas.", N)
		return
	if S.fijos.size() >= D.FIJOS_MAX:   # 1.31: antes de cobrar
		await say("Tu agenda ya está llena. Cuando tengas sitio para alguien que importa, vuelve.", N)
		return
	if await ask("El reservado: sofá, mesa y botella, %s la noche. Ahí se sienta la gente que importa." % Datos.eur(D.DISCO.mesa), ["Reservar", "No"], N) != 0:
		return
	if S.money < D.DISCO.mesa:
		sfx("bad")
		await say("Para el reservado hace falta dinero. Otra noche.", N)
		return
	S.money -= int(D.DISCO.mesa)
	X.mesa = 1
	confia("gaua", 5)
	sfx("coin")
	await fade(1)
	advance_time(60)
	update_hud()
	await wait(200)
	await fade(0)
	var nv: String = D.DISCO.vip[int(S.vipN) % D.DISCO.vip.size()]
	var id := "vip%d" % int(S.vipN)
	S.vipN += 1
	S.fijos.append({"id": id, "n": nv, "t": "vip", "dia": 0})
	sfx("get")
	await say("Una hora en el reservado. La RRPP te presenta a %s: «Me han dicho que lo tuyo es de lo mejor. Llámame». Apuntas su número." % nv)
	if Datos.CAL:   # 1.47: el reservado, arriba
		await subir_vip()

# 1.47 (lo pidió el usuario): el reservado, arriba; desde la cristalera del suelo se ve la pista de abajo
func subir_vip() -> void:
	var C: Dictionary = D.DISCO_CAL
	await warp({"to": "disco-vip", "x": int(C.sube[0]), "y": int(C.sube[1]), "dir": "down"})

func bajar_vip() -> void:
	var C: Dictionary = D.DISCO_CAL
	await warp({"to": "disco", "x": int(C.baja[0]), "y": int(C.baja[1]), "dir": "down"})

func talk_vip(i: int) -> void:
	if not disco_abierta():
		await echar_disco()
		return
	await say(D.DISCO_CAL.vip[(i + S.day) % D.DISCO_CAL.vip.size()], "GENTE")

func talk_baila(i: int):
	await say(D.BAILA[i], "GENTE")

# ---------- LA ASOCIACIÓN (1.32, 11j-locales): la de la tía Maite, en el barrio alto (CLUBS.rv) ----------
# la segunda vez que entras (otro día), Delroy; presentarte (la asamblea) o refundarla; de presidente, el dispensario (ASO, DELROY)
# ---------- los mercados (1.45, lo pidió el usuario: «en el club se tiene que poder tanto comprar como vender extracciones y
# diferentes tipos de hierba, no solo una… a todos los mercados»; con Datos.CAL) ----------
# MERCADO[tipo] (club, mayor): cada mercado (id: club_<k>, inaki, lonja) saca cada día n cogollos y nx extracciones de su lista (pool),
# con lo que tiene de cada uno (st/stx gramos), y compra varios lotes al día hasta su tope (en gramos de flor: S.mer_v[id])
func tipo_mer(id: String) -> String:
	return "club" if id.begins_with("club_") else "mayor"

func pool_mayor() -> Array:
	var l := ["ria"]
	for b in D.BANCO:
		if int(b[2]) <= int(S.ch):
			l.append(b[0])
	return l

func resto_mer(id: String, tope: float) -> float:
	var v = S.get("mer_v", {}).get(id) if S.get("mer_v") is Dictionary else null
	return tope - (float(v.g) if v is Dictionary and int(v.d) == int(S.day) else 0.0)

func suma_mer(id: String, g: float) -> void:
	if not (S.get("mer_v") is Dictionary):
		S.mer_v = {}
	var v = S.mer_v.get(id)
	S.mer_v[id] = {"d": S.day, "g": (float(v.g) if v is Dictionary and int(v.d) == int(S.day) else 0.0) + g}

func mercado_lista(id: String, pool: Array) -> Array:
	if not (S.get("mer") is Dictionary):
		S.mer = {}
	var M = S.mer.get(id)
	if M is Dictionary and int(M.d) == int(S.day):
		return M.l
	var T: Dictionary = D.MERCADO[tipo_mer(id)]
	var h: int = absi(hash("%s|%d" % [id, int(S.day)]))
	var l := []
	var p := pool.duplicate()
	for i in int(T.n):
		if p.is_empty():
			break
		var sid: String = p[(h + i * 7919) % p.size()]
		p.erase(sid)
		l.append({"k": sid, "x": "", "g": int(T.st[0]) + (h / (i + 3)) % (int(T.st[1]) - int(T.st[0]) + 1), "thc": float(strain(sid).thc)})
	for i in int(T.nx):
		var sid: String = pool[(h / 7 + i * 104729) % pool.size()]
		var xt: String = D.MERCADO.x[(h / 13 + i * 3) % D.MERCADO.x.size()]
		var E: Dictionary = D.EXTR[xt]
		l.append({"k": sid, "x": xt, "g": int(T.stx[0]) + (h / (i + 5)) % (int(T.stx[1]) - int(T.stx[0]) + 1), "thc": minf(float(E.tope), Datos.jsround(float(strain(sid).thc) * float(E.thc) * 10) / 10.0)})
	S.mer[id] = {"d": S.day, "l": l}
	return l

func precio_mer(id: String, q: Dictionary) -> float:
	var T: Dictionary = D.MERCADO[tipo_mer(id)]
	var e: float = (precio_rosin(q.thc) * float(D.EXTR[q.x].px) * float(T.fx)) if q.x != "" else ((precio_calle(q.thc) if tipo_mer(id) == "club" else precio_mayor(q.thc)) * float(T.f))
	return Datos.jsround(e * 100) / 100.0

func nombre_mer(q: Dictionary) -> String:
	return (D.EXTR[q.x].n + " de " + strain(q.k).n) if q.x != "" else strain(q.k).n

func comprar_mercado(id: String, N: String, pool: Array) -> void:
	var T: Dictionary = D.MERCADO[tipo_mer(id)]
	var l: Array = mercado_lista(id, pool).filter(func(q): return int(q.g) >= int((T.gx if q.x != "" else T.g)[0]))
	if l.is_empty():
		await say("Hoy ya está todo repartido. Mañana entra más.", N)
		return
	var it := l.map(func(q): return {"label": nombre_mer(q), "right": "%d g · %s %% · %s €/g" % [int(q.g), Datos.pct(q.thc), _dos(precio_mer(id, q))], "sw": "#d89a18" if q.x != "" else strain(q.k).c, "ic": ic_cog(q.k),
		"desc": "%s: %d g a %s %% de THC, a %s el gramo." % [nombre_mer(q), int(q.g), Datos.pct(q.thc), _dos(precio_mer(id, q)) + " €"]})
	it.append({"label": "Nada", "desc": "No comprar nada hoy."})
	# 1.50: a lo ancho, con el nombre entero (en la columna de la derecha se cortaba: «Beldi», «Zam»…)
	var i: int = await menu(it, {"cls": "full", "title": "Hoy tenemos", "desc": true} if Datos.CAL else {"cls": "right", "title": "Hoy tenemos"})
	if i < 0 or i >= l.size():
		return
	var q: Dictionary = l[i]
	var pg := precio_mer(id, q)
	var ops := []
	for g in (T.gx if q.x != "" else T.g):
		if g <= int(q.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(Datos.jsround(g * pg))])
	o.append("Nada")
	var j: int = await ask("%s, al %s %% de THC. ¿Cuánto te llevas?" % [nombre_mer(q), Datos.pct(q.thc)], o, N)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	var e := Datos.jsround(g * pg)
	if S.money < e:
		sfx("bad")
		await say("Sin dinero no hay trato.", N)
		return
	if libre_mochila() < g:
		await say("No te cabe en la bolsa.", N)
		return
	S.money -= e
	q.g = int(q.g) - g
	if q.x != "":
		add_rosin(q.k if q.x == "rosin" else q.k + "~" + q.x, g, q.thc)
		discover(q.k)
	else:
		add_buds(q.k, g, q.thc, S.buds, 1)
	confia(id.substr(5) if id.begins_with("club_") else id, 1)
	update_hud()
	sfx("coin")
	toast("Comprado: %d g de %s" % [g, nombre_mer(q)], 1400)

# el almacén del club (1.45, de presidente): lo que dejas en sus estanterías (S.aso.al: buds y rosin, hasta MERCADO.alm.g de flor)
# lo retiran los socios del dispensario cada mañana (aso_dia), MERCADO.alm.dia g de flor al día, a precio de dispensario
func alm_club() -> Dictionary:
	var A := aso()
	if not (A.get("al") is Dictionary):
		A.al = {"buds": {}, "rosin": {}, "tot": 0}
	return A.al

func alm_g() -> float:
	var al := alm_club()
	var t := 0.0
	for k in al.buds:
		t += float(al.buds[k].g)
	for k in al.rosin:
		t += float(al.rosin[k].g) / D.ROSIN.rend
	return t

func almacen_club() -> void:
	var N: String = D.DELROY.n
	if not aso().pres:
		await say("El almacén del club, con llave. La tiene el presidente.")
		return
	while true:
		var al := alm_club()
		var ops := ["Guardar", "Sacar", "Nada"]
		var c: int = await ask("EL ALMACÉN DEL CLUB · %s de %s ocupados. Lo de aquí lo retiran los socios del dispensario, %d g al día; en total, %s." % [g_txt(alm_g()), g_txt(D.MERCADO.alm.g), int(D.MERCADO.alm.dia), Datos.eur(int(al.tot))], ops)
		if c == 0:
			var lots := lotes_venta(1, 1)
			if lots.is_empty():
				await say("No llevas nada encima.")
				continue
			var it := lots.map(venta_item)
			it.append({"label": "Nada"})
			var i: int = await menu(it, {"cls": "right", "title": "¿Qué guardas?"})
			if i < 0 or i >= lots.size():
				continue
			var lt: Array = lots[i]
			var x := es_extr(lt)
			var b: Dictionary = lt[1]
			var cabe: float = (float(D.MERCADO.alm.g) - alm_g()) * (D.ROSIN.rend if x else 1.0)
			var g: float = minf(float(b.g), floorf(cabe * 10) / 10.0)
			if g < .1:
				await say("Las estanterías están llenas.")
				continue
			var L: Dictionary = al.rosin if x else al.buds
			var k: String = lt[0]
			if L.has(k):
				L[k].thc = (float(L[k].thc) * float(L[k].g) + float(b.thc) * g) / (float(L[k].g) + g)
				L[k].g = float(L[k].g) + g
			else:
				L[k] = {"g": g, "thc": float(b.thc), "q": calidad(b)}
			usa_lote(lt, g)
			sfx("sel")
			toast("Al almacén: %s" % g_txt(g), 1200)
		elif c == 1:
			var it := []
			var ks := []
			for k in al.buds:
				ks.append([k, false])
				it.append({"label": lot_nombre(k), "right": g_txt(al.buds[k].g)})
			for k in al.rosin:
				ks.append([k, true])
				it.append({"label": extr_nombre(k), "right": g_txt(al.rosin[k].g)})
			if ks.is_empty():
				await say("El almacén está vacío.")
				continue
			it.append({"label": "Nada"})
			var i: int = await menu(it, {"cls": "right", "title": "¿Qué sacas?"})
			if i < 0 or i >= ks.size():
				continue
			var k: String = ks[i][0]
			var x: bool = ks[i][1]
			var b: Dictionary = (al.rosin if x else al.buds)[k]
			var g: float = minf(float(b.g), floorf(libre_mochila()))
			if g < .1:
				await say("No te cabe en la bolsa.")
				continue
			if x:
				add_rosin(k, g, b.thc)
			else:
				add_buds(k, g, b.thc)
			b.g = float(b.g) - g
			if b.g < .1:
				(al.rosin if x else al.buds).erase(k)
			sfx("sel")
			toast("Sacado: %s" % g_txt(g), 1200)
		else:
			return

func almacen_dia() -> void:
	var A := aso()
	if not A.pres or not (A.get("al") is Dictionary):
		return
	var al := alm_club()
	var r: float = float(D.MERCADO.alm.dia)
	var e := 0.0
	for x in [false, true]:
		var L: Dictionary = al.rosin if x else al.buds
		for k in L.keys():
			if r <= 0:
				break
			var b: Dictionary = L[k]
			var g: float = minf(float(b.g), r * (D.ROSIN.rend if x else 1.0))
			var pg: float = (precio_extr(k, b.thc, "club") if x else precio_club(b.thc)) * float(b.get("q", 1)) * float(D.ASO.f)
			e += g * pg
			r -= g / D.ROSIN.rend if x else g
			b.g = float(b.g) - g
			if b.g < .1:
				L.erase(k)
	if e > 0:
		var ee := Datos.jsround(e)
		al.tot = int(al.tot) + ee
		S.money += ee
		S.sales += ee
		queue("historia", check_story)

func aso() -> Dictionary:
	if not (S.get("aso") is Dictionary):
		S.aso = {"v": 0, "d": 0, "tio": false, "asam": 0, "otra": 0, "pres": false, "votos": 0, "lote": null}
	return S.aso

func delroy_aqui() -> bool:
	return int(aso().v) >= int(D.ASO.visitas)

func votos_aso() -> int:
	var O: Dictionary = D.ASO
	var n := 0
	for id in O.gente:
		if rel(id) >= int(D.REL.amigo):
			n += 1
	return mini(int(O.votos), int(O.base) + (int(O.delroy) if aso().tio else 0) + int(O.amigo) * n + int(floor(rel("rv") / float(O.relV))))

# la puerta (entra_local): cada día que entras cuenta una visita; la segunda, Delroy está dentro
func entra_aso(d: Dictionary) -> void:
	var A := aso()
	if int(A.d) != int(S.day):
		A.v = int(A.v) + 1
		A.d = S.day
	await warp(d)
	if delroy_aqui() and not A.tio:
		await say("Junto a la foto de la tía Maite, un hombre mayor con las rastas y la barba canas no te quita ojo.")

func talk_delroy() -> void:
	var A := aso()
	var N: String = D.DELROY.n
	if not A.tio:
		await talk(N, D.DELROY.revela)
		A.tio = true
		confia("delroy", 5)
	var c: int = await ask("¿Qué tal, presidente?" if A.pres else "Dime, sobrino.", ["Charlar", "El dispensario" if A.pres else "La presidencia", "Nada"], N)
	if c == 0:
		await say(pick(D.DELROY.charla), N)
	elif c == 1:
		if A.pres:
			await dispensario_aso()
		else:
			await presidencia_aso()

func presidencia_aso() -> void:
	var A := aso()
	var N: String = D.DELROY.n
	var O: Dictionary = D.ASO
	if A.asam:   # con la asamblea pendiente, todavía se puede refundar
		if await ask("La asamblea es el %s, por la mañana. Habla con la gente del barrio: cada amigo trae votos. O la refundas ya, por %s." % [Datos.fd(int(A.asam), S.day), Datos.eur(O.refunda)], ["Refundarla", "Nada"], N) != 0:
			return
	else:
		var c: int = await ask("Hacen falta %d votos de %d. Hoy tendrías %d. O pagas %s de deudas y registro y la refundas tú." % [int(O.mayoria), int(O.votos), votos_aso(), Datos.eur(O.refunda)], ["Presentarme", "Refundarla", "Nada"], N)
		if c == 0:
			if S.day < int(A.otra):
				await say("Hasta el %s no hay otra asamblea. Gánate al barrio mientras." % Datos.fd(int(A.otra), S.day), N)
				return
			A.asam = int(S.day) + int(O.dias)
			sfx("sel")
			await say("Apuntado. La asamblea, el %s. %s también se presenta." % [Datos.fd(int(A.asam), S.day), O.rival], N)
			return
		if c != 1:
			return
	if S.money < int(O.refunda):
		sfx("bad")
		await say("Sin los %s no hay refundación." % Datos.eur(O.refunda), N)
		return
	S.money -= int(O.refunda)
	A.pres = true
	A.asam = 0
	confia("delroy", 10)
	confia("rv", 10)
	update_hud()
	sfx("get")
	await say("Pagas las deudas de la gestora y el registro. La asociación vuelve a nacer, con tus estatutos. Maite estaría orgullosa.", N)

# el dispensario: un lote a la vez; dice cuánto queda y lo que llevas
func dispensario_aso() -> void:
	var A := aso()
	var N: String = D.DELROY.n
	var O: Dictionary = D.ASO
	var L = A.lote
	if L is Dictionary:
		await say("En el dispensario quedan %s de %s, a %s € el gramo. Llevas %s." % [g_txt(L.g), extr_nombre(L.k, true) if L.get("x") else lot_nombre(L.k), _dos(L.pg), Datos.eur(L.tot)], N)
		return
	var VX: Dictionary = D.VENTA_EXTR
	var lots := lotes_venta(O.g[0], VX.club_g[0])
	if lots.is_empty():
		await say("Déjame %d g o más y los socios lo retiran, %d g al día. El dinero, a tu buzón." % [int(O.g[0]), int(O.dia)], N)
		return
	var it := lots.map(venta_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		return
	var l: Array = lots[i]
	var x := es_extr(l)
	var k: String = l[0]
	var b: Dictionary = l[1]
	var pg := Datos.jsround((precio_extr(k, b.thc, "club") if x else precio_club(b.thc)) * calidad(b) * float(O.f) * 100) / 100.0
	var ops := []
	for g in (VX.club_g if x else O.g):
		if g <= floor(b.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(g * pg)])
	o.append("Nada")
	var j: int = await ask("%s a %s € el gramo para los socios. ¿Cuánto dejas?" % [venta_nombre(l), _dos(pg)], o, N)
	if j < 0 or j >= ops.size():
		return
	usa_lote(l, ops[j])
	A.lote = {"k": k, "g": ops[j], "pg": pg, "tot": 0}
	if x:   # 1.43.7: de una extracción retiran VENTA_EXTR.dia de lo de la flor
		A.lote.x = true
	sfx("sel")
	await say("Al dispensario. Cada mañana, %s para los socios." % g_txt(O.dia * (VX.dia if x else 1.0)), N)

# al amanecer (curro_dia): la asamblea, si toca, y lo que retiran los socios del dispensario
func aso_dia() -> void:
	var A := aso()
	var O: Dictionary = D.ASO
	if A.asam and S.day >= int(A.asam):
		var v := votos_aso()
		var gana := v >= int(O.mayoria)
		A.asam = 0
		A.votos = v
		if gana:
			A.pres = true
			confia("delroy", 10)
		else:
			A.otra = int(S.day) + int(O.espera)
		var t: String = ("¡%d votos de %d! Eres el presidente de la asociación, sobrino. Como tu tía." % [v, int(O.votos)]) if gana else ("%d votos de %d: gana %s. Gánate al barrio y preséntate otra vez desde el %s." % [v, int(O.votos), O.rival, Datos.fd(int(A.otra), S.day)])
		queue("aso", func(): await talk("SMS · DELROY", [t]))
	if Datos.CAL:
		almacen_dia()   # 1.45: lo del almacén del club
	var L = A.lote
	if not A.pres or not (L is Dictionary):
		return
	var g = min(L.g, O.dia * (D.VENTA_EXTR.dia if L.get("x") else 1.0))
	var e := Datos.jsround(g * L.pg)
	L.g -= g
	L.tot += e
	S.money += e
	S.sales += e
	queue("historia", check_story)
	if L.g < 1:
		A.lote = null
		queue("asoLote", func(): await talk("SMS · DELROY", ["Se acabó lo del dispensario: %s en total, en tu buzón." % Datos.eur(L.tot)]))

# ---------- el bajo de las setas (1.20, 11g-setas): el local clandestino de la Kale Zaharra ----------
# 1.51 (lo pidió el usuario: «antes de… alquilar el bajo… habilitar el sótano de la casa»): las setas, en el bajo de Txomin
# (S.setas) o en el sótano de casa (S.sot, la misma forma sin recibo); SL() es el de donde estás (o, con Txomin, el que eliges: _SOT)
var _SOT := false
func es_sot() -> bool:
	return S.map == "sotano" or _SOT

func sot_ya() -> bool:
	return Datos.CAL and S.get("sot") is Dictionary and float(S.sot.get("d", 1e9)) <= S.day

func SL():
	if es_sot():
		return S.sot if sot_ya() else null
	return S.get("setas")

# las estanterías del sitio (cada una, dos bandejas) en el orden del mapa, de arriba abajo y de izquierda a derecha
func _baldas() -> Array:
	var m = MAPS.get("sotano" if es_sot() else "setas")
	var r := []
	if m == null:
		return r
	for y in int(m.h):
		for x in int(m.w):
			if m.o[y][x] == "baldaS":
				r.append(x + 1000 * y)
	return r

func n_baldas() -> int:
	return maxi(1, _baldas().size())

func balda_i(x: int) -> int:
	for i in _baldas().size():
		if _baldas()[i] % 1000 == x:
			return i
	return 0

func max_bandejas() -> int:
	if es_sot():
		return int(D.SOTANO.max)
	return 2 * n_baldas() if Datos.CAL else int(D.SETAS.max)

func fase_seta(b: Dictionary) -> String:
	if b.get("mala"):
		return b.mala
	var d: int = int(S.day - b.d)
	return "colonizando" if d < D.SETAS.colon else ("fructificando" if d < D.SETAS.colon + D.SETAS.fruto else "lista")

# las cepas (1.46, lo pidió el usuario: «diferentes panes… juntar esos micelios y crear nuevas variedades… en un libro de recetas…
# que no se permita hacer ciertos cruces»; con Datos.CAL): cepas inventadas (CEPAS.v, cada una con su forma: cúpula, campana, plato o
# racimo), los panes de micelio (S.setas.panes {k: n}), lo descubierto (S.setas.cd) y lo seco por cepa (S.setas.gv {k: g}, que suma
# S.setas.g; lo que no tiene cepa es Txuria). Juntar dos panes solo prende si la pareja está en el cuaderno (CEPAS.r); unas formas
# se repelen (CEPAS.veta). Nada de método ni de dosis.
func cepa_de(b) -> String:
	var v = b.get("v") if b is Dictionary else null
	return str(v) if v != null and D.CEPAS.v.has(str(v)) else "txuria"

func receta_cepa(a: String, b: String) -> String:
	for r in D.CEPAS.r:
		if (r[0] == a and r[1] == b) or (r[0] == b and r[1] == a):
			return r[2]
	return ""

func veta_cepa(a: String, b: String) -> bool:
	var fa: String = D.CEPAS.v[a].f
	var fb: String = D.CEPAS.v[b].f
	for v in D.CEPAS.veta:
		if (v[0] == fa and v[1] == fb) or (v[0] == fb and v[1] == fa):
			return true
	return false

func gv_setas(L: Dictionary) -> Dictionary:
	var gv: Dictionary = L.get("gv", {}).duplicate() if L.get("gv") is Dictionary else {}
	var s := 0.0
	for k in gv:
		s += float(gv[k])
	if float(L.g) - s > 0.001:
		gv["txuria"] = float(gv.get("txuria", 0)) + float(L.g) - s
	return gv

func suma_gv(L: Dictionary, k: String, g: float) -> void:   # antes de sumarlo a L.g
	var gv := gv_setas(L)
	gv[k] = float(gv.get(k, 0)) + g
	L.gv = gv

func quita_gv(L: Dictionary, g: float) -> void:   # después de restarlo de L.g: de la cepa que más hay
	var gv := gv_setas(L)
	var t := 0.0
	for k in gv:
		t += float(gv[k])
	g = t - float(L.g)
	var ks: Array = gv.keys()
	ks.sort_custom(func(a, b): return gv[a] > gv[b] or (gv[a] == gv[b] and a < b))
	for k in ks:
		var q: float = minf(g, float(gv[k]))
		gv[k] = float(gv[k]) - q
		g -= q
		if gv[k] <= 0.001:
			gv.erase(k)
	L.gv = gv

func nom_cepa(k: String) -> String:
	return D.CEPAS.v[k].n

func cepa_ya(L: Dictionary, k: String) -> bool:
	return k == "txuria" or k in L.get("cd", [])

func descubre_cepa(L: Dictionary, k: String) -> void:
	if not L.get("cd") is Array:
		L.cd = []
	if not k in L.cd:
		L.cd.append(k)

# los panes de micelio que vende Txomin (CEPAS.v[k].pan)
func panes_txomin(T: String) -> void:
	var L: Dictionary = SL()
	while true:
		var ks := []
		var ops := []
		for k in D.CEPAS.v:
			var c: Dictionary = D.CEPAS.v[k]
			if c.has("pan"):
				ks.append(k)
				ops.append("%s · %s (%s)" % [c.n, D.CEPAS.fam[c.f], Datos.eur(c.pan)])
		ops.append("Nada")
		var oi: int = await ask("Panes de micelio, cada uno de su cepa. Con uno, te preparo una bandeja de esa cepa; juntando dos en la mesa, sale otra si está en el cuaderno.", ops, T)
		if oi < 0 or oi >= ks.size():
			return
		var k: String = ks[oi]
		var pz: int = int(D.CEPAS.v[k].pan)
		if S.money < pz:
			sfx("bad")
			await say("Sin %s no hay pan." % Datos.eur(pz), T)
			continue
		S.money -= pz
		if not L.get("panes") is Dictionary:
			L.panes = {}
		L.panes[k] = int(L.panes.get(k, 0)) + 1
		descubre_cepa(L, k)
		sfx("coin")
		await say("Un pan de %s: %s" % [nom_cepa(k), D.CEPAS.v[k].d], T)

# los panes que tienes, para elegir uno (sin el excluido): [[k, "Nombre (n)"]]
func mis_panes(L: Dictionary, sin := "") -> Array:
	var o := []
	var P: Dictionary = L.get("panes", {}) if L.get("panes") is Dictionary else {}
	for k in D.CEPAS.v:
		if int(P.get(k, 0)) > 0 and k != sin:
			o.append([k, "%s (%d)" % [nom_cepa(k), int(P[k])]])
	return o

# juntar dos micelios en la mesa de trabajo: solo si la pareja está en el cuaderno; sin gastar nada si no prende
func juntar_micelios() -> void:
	var L: Dictionary = S.setas
	var A := mis_panes(L)
	if A.is_empty():
		await say("No tienes panes de micelio. Txomin los vende en la puerta.")
		return
	var oa: int = await ask("Juntar micelios: el primer pan.", A.map(func(x): return x[1]) + ["Nada"])
	if oa < 0 or oa >= A.size():
		return
	var a: String = A[oa][0]
	var B := mis_panes(L, a)
	if B.is_empty():
		await say("Hace falta un pan de otra cepa para juntarlo con el de %s." % nom_cepa(a))
		return
	var ob: int = await ask("Juntar %s con…" % nom_cepa(a), B.map(func(x): return x[1]) + ["Nada"])
	if ob < 0 or ob >= B.size():
		return
	var b: String = B[ob][0]
	if veta_cepa(a, b):
		sfx("bad")
		await say("%s y %s no se juntan: un %s y una %s se repelen, las hifas no se tocan. No gastas nada." % [nom_cepa(a), nom_cepa(b), D.CEPAS.fam[D.CEPAS.v[a].f], D.CEPAS.fam[D.CEPAS.v[b].f]])
		return
	var r: String = receta_cepa(a, b)
	if r == "":
		sfx("bad")
		await say("No prende: %s con %s no está en el cuaderno. No gastas nada." % [nom_cepa(a), nom_cepa(b)])
		return
	L.panes[a] = int(L.panes[a]) - 1
	L.panes[b] = int(L.panes[b]) - 1
	L.panes[r] = int(L.panes.get(r, 0)) + int(D.CEPAS.sale)
	var nueva: bool = not cepa_ya(L, r)
	descubre_cepa(L, r)
	advance_time(int(D.CEPAS.min))
	update_hud()
	sfx("get")
	await say("Juntas los dos micelios en un pan nuevo y, al rato, prende: %d panes de %s.%s" % [int(D.CEPAS.sale), nom_cepa(r), (" ¡Nueva en tu cuaderno! " + D.CEPAS.v[r].d) if nueva else ""])

# el cuaderno de las cepas: cada una con su forma, de dónde sale y si ya la tienes; y lo que no se junta
func cuaderno_setas() -> void:
	var L: Dictionary = S.setas
	var ks: Array = D.CEPAS.v.keys()
	while true:
		var ops := []
		for k in ks:
			ops.append("%s%s · %s" % ["✓ " if cepa_ya(L, k) else "", nom_cepa(k), D.CEPAS.fam[D.CEPAS.v[k].f]])
		ops.append("Lo que no se junta")
		ops.append("Nada")
		var n_ya: int = ks.filter(func(k): return cepa_ya(L, k)).size()
		var oi: int = await ask("El cuaderno de las cepas: %d de %d." % [n_ya, ks.size()], ops)
		if oi < 0 or oi >= ks.size() + 1:
			return
		if oi == ks.size():
			var t := []
			for v in D.CEPAS.veta:
				t.append("un %s con una %s" % [D.CEPAS.fam[v[0]], D.CEPAS.fam[v[1]]] if v[1] == "campana" or v[1] == "cupula" else "%s con %s" % [D.CEPAS.fam[v[0]], D.CEPAS.fam[v[1]]])
			await say("No se juntan: %s; se repelen. Y lo que no está en el cuaderno no prende." % " ni ".join(PackedStringArray(t)))
			continue
		var k: String = ks[oi]
		var c: Dictionary = D.CEPAS.v[k]
		var de := "La vende Txomin (%s el pan)." % Datos.eur(c.pan) if c.has("pan") else ""
		for r in D.CEPAS.r:
			if r[2] == k:
				de = "Sale de juntar %s con %s." % [nom_cepa(r[0]), nom_cepa(r[1])]
		await say("%s · %s · %d.ª generación. %s %s Rinde ×%s y se paga ×%s." % [c.n, D.CEPAS.fam[c.f], int(c.gen), c.d if cepa_ya(L, k) else "Aún no la has tenido.", de, str(c.g), str(c.p)])

func setas_dia() -> void:
	if Datos.CAL and sot_ya():   # 1.51: el sótano de casa, sin recibo ni redada propia (la de casa se lo lleva)
		secar_setas(S.sot)
		_setas_bandejas(S.sot, "SMS · TXOMIN")
	var L = S.get("setas")
	if L == null:
		return
	var Z: Dictionary = D.SETAS
	if not cobra(L, recibo_setas(), "TXOMIN", false, "el bajo"):   # 1.35: cada RECIBO.dias (granja.gd)
		S.setas = null
		queue("setas", func(): await talk("SMS · TXOMIN", ["No me has pagado el bajo. Cambio la cerradura; lo de dentro y la fianza, para mí."]))
		return
	if Datos.CAL:
		secar_setas(L)   # 1.44: lo seco, al armario
		if L.get("ay") and int(L.ay) < S.day:   # 1.51: el ayudante, como un navero: pulveriza y recoge lo listo
			ayudante_setas(L)
	var vivas: Array = L.bandejas.filter(func(b): return not b.get("mala"))
	if vivas.is_empty():
		return
	if Cultivo.azar() < Z.redada:
		var gg: float = L.g
		S.setas = null
		S.heat = min(100, S.heat + Z.calorRedada)
		sfx("bad")
		queue("setas", func(): await say("La policía ha entrado en el bajo de la Kale Zaharra. Se lleva las bandejas%s." % ((" y " + g_txt(gg) + " de setas") if gg >= 1 else "")))
		return
	_setas_bandejas(L, "SMS · TXOMIN")

# lo que pasa cada noche en unas bandejas (el bajo o el sótano): se secan y alguna se echa a perder
func _setas_bandejas(L: Dictionary, quien: String) -> void:
	var Z: Dictionary = D.SETAS
	var malas := []
	for b in L.bandejas.filter(func(b): return not b.get("mala")):
		b.hum = maxf(0, b.hum - Z.seca)
		if not b.hum:
			b.mala = "seca"
			malas.append("seca")
			continue
		if fase_seta(b) != "lista" and Cultivo.azar() < Z.cont + (Z.contSeca if b.hum < 50 else 0.0):
			b.mala = "contaminada"
			malas.append("contaminada")
	if malas.size():
		var t: String = ("Se te han echado a perder %d bandejas. Tíralas." % malas.size()) if malas.size() > 1 else ("Una bandeja se te ha %s. Tírala." % ("secado" if malas[0] == "seca" else "contaminado"))
		if L == S.get("sot"):
			t = t.replace("Tíralas.", "Las del sótano: tíralas.").replace("Tírala.", "La del sótano: tírala.")
		queue("setas", func(): await talk(quien, [t]))

# 1.51 (lo pidió el usuario: «que se cultive como la nave»): Ekaitz, el ayudante del bajo grande, cada mañana: todo húmedo y lo listo, a secar
func ayudante_setas(L: Dictionary) -> void:
	var Z: Dictionary = D.SETAS
	var g := 0
	var quedan := []
	for b in L.bandejas:
		if b.get("mala"):
			continue   # las malas las deja: las tiras tú
		if fase_seta(b) == "lista":
			var x: int = roundi(ri(int(Z.g[0]), int(Z.g[1])) * float(D.CEPAS.v[cepa_de(b)].g))
			L.fr = L.get("fr", []) + [{"g": x, "d": S.day, "v": cepa_de(b)}]
			g += x
		else:
			b.hum = 100
			quedan.append(b)
	L.bandejas = quedan + L.bandejas.filter(func(b): return b.get("mala"))
	if g:
		queue("setas", func(): await talk("SMS · " + str(D.SETAS_AY.n).to_upper(), ["Bandejas pulverizadas. He recogido %d g y están secándose." % g]))

func talk_setero() -> void:
	var A: Dictionary = D.SETAS_AY
	var N: String = str(A.n).to_upper()
	if S.get("setas") == null:
		await say("Sin bajo no hay faena. Me vuelvo con mi tío.", N)
		return
	var L: Dictionary = S.setas
	var vivas: Array = L.bandejas.filter(func(b): return not b.get("mala"))
	var c: int = await ask("Todo en orden: %d bandejas vivas de %d. Cada mañana las pulverizo y recojo lo que esté listo." % [vivas.size(), max_bandejas()], ["Seguir así", "Despedirlo", "Nada"], N)
	if c == 1:
		if await ask("¿Seguro? Txomin no se lo va a tomar bien.", ["Despedirlo", "No"], N) == 0:
			L.erase("ay")
			build_ents()
			await say("Vale. Ahí te quedas con las bandejas.", N)
	elif c == 0:
		await say("Lo que tú digas, jefe.", N)

func talk_txomin() -> void:
	var T := "TXOMIN"
	var Z: Dictionary = D.SETAS
	if S.ch < int(Z.ch):
		await say("¿Setas? Eso era antes, chaval. Ahora solo paseo.", T)
		return
	if sot_ya():   # 1.51: las bandejas para el sótano de casa
		var cs: int = await ask("¿Para el sótano de tu casa o para mi bajo?", ["Para el sótano", "El bajo", "Nada"], T)
		if cs == 0:
			_SOT = true
			await bajo_menu(T)
			_SOT = false
			return
		if cs != 1:
			return
	if S.get("setas") == null:
		var e: float = Z.fianza + recibo_setas()
		if await ask("El bajo de mi casa: oscuro, húmedo y nadie pregunta. %s de fianza y %s cada %s días, en efectivo; el primero, ahora. Las bandejas te las preparo yo." % [Datos.eur(Z.fianza), Datos.eur(recibo_setas()), n(D.RECIBO.dias)] + (" Caben %d." % (2 * maxi(1, MAPS["setas-g"].o[2].filter(func(o): return o == "baldaS").size())) if Datos.CAL and MAPS.has("setas-g") else ""), ["Alquilarlo", "No"], T) != 0:
			return
		if S.money < e:
			sfx("bad")
			await say("Sin %s no hay llave." % Datos.eur(e), T)
			return
		S.money -= e
		S.setas = {"bandejas": [], "g": 0, "r": S.day + D.RECIBO.dias}
		sfx("coin")
		await got("la llave del bajo")
		await say("Compra las bandejas y tenlas húmedas. Lo demás lo hace el tiempo.", T)
		return
	await bajo_menu(T)

# pulverizar las bandejas vivas (SETAS.min): false si, pasada la medianoche, setas_dia ha cerrado el bajo (1.34, pulverizarBajo)
func pulverizar_bajo() -> bool:
	var L: Dictionary = SL()
	for b in L.bandejas:
		if not b.get("mala"):
			b.hum = 100
	advance_time(int(D.SETAS.min))
	update_hud()
	if SL() == null:
		return false
	sfx("sel")
	var v: Array = L.bandejas.filter(func(b): return not b.get("mala"))   # pasada la medianoche, setas_dia ya las ha secado (o echado a perder)
	var hv := 0.0
	for b in v:
		hv += b.hum
	await say(("Pulverizas las bandejas: humedad al %d %%." % Datos.jsround(hv / v.size())) if v.size() else "Pulverizas las bandejas.")
	return true

# las bandejas del bajo (1.34, bajoMenu): con Txomin, en la puerta (T), todo; dentro, en las baldas (T vacío), lo de las bandejas: ni
# comprar (las prepara él), ni venderle, ni dejar el bajo
func bajo_menu(T: String) -> void:
	var Z: Dictionary = D.SETAS
	var L: Dictionary = SL()
	while true:
		var B: Array = L.bandejas
		var cnt := {}
		for k in D.FASES_SETA:
			cnt[k] = 0
		for b in B:
			cnt[fase_seta(b)] += 1
		var hum: Array = B.filter(func(b): return not b.get("mala"))
		var partes := []
		for k in D.FASES_SETA:
			if cnt[k]:
				partes.append("%d %s" % [cnt[k], D.FASES_SETA[k][1 if cnt[k] > 1 else 0]])
		var est: String = ", ".join(PackedStringArray(partes)) if B.size() else "sin bandejas"
		var ops := []
		if T != "" and B.size() < max_bandejas():
			ops.append("Comprar bandeja (%s)" % Datos.eur(Z.bandeja))
		if T != "" and Datos.CAL:   # 1.46: los panes de micelio
			ops.append("Panes de micelio")
		if hum.size():
			ops.append("Pulverizar")
		if cnt.lista:
			ops.append("Recoger")
		if B.any(func(b): return b.get("mala")):
			ops.append("Tirar las malas")
		if T != "" and L.g >= 1:
			ops.append("Venderle " + g_txt(L.g))
		if T != "" and Datos.CAL and not es_sot():   # 1.44: el equipo del bajo y lo que haces en la mesa
			var ZP: Dictionary = D.SETAS_PRO
			if L.get("mc", 0):
				ops.append("Microdosis: %d %s" % [L.mc, "caja" if L.mc == 1 else "cajas"])
			if L.get("cc", 0):
				ops.append("Comestibles: %d %s" % [L.cc, "caja" if L.cc == 1 else "cajas"])
			if not L.get("dh"):
				ops.append("Deshidratador (%s)" % Datos.eur(ZP.deshid))
			if not L.get("enc"):
				ops.append("Encapsuladora (%s)" % Datos.eur(ZP.encap))
			if not L.get("mol"):
				ops.append("Moldes (%s)" % Datos.eur(ZP.moldes))
		if T != "" and Datos.CAL and not es_sot() and not L.get("ay"):   # 1.51: el ayudante, como los de la nave
			ops.append("Contratar a %s (%s)" % [D.SETAS_AY.n, Datos.eur(D.SETAS_AY.sueldo)])
		if T != "" and not es_sot():
			ops.append("Dejar el bajo")
		ops.append("Nada")
		var hm := 0.0
		for b in hum:
			hm += b.hum
		var oi: int = await ask(("El sótano: %s%s." if es_sot() else "El bajo: %s%s.") % [est, (" · humedad %d %%" % Datos.jsround(hm / hum.size())) if hum.size() else ""] + ("" if T != "" or B.size() else " Las bandejas las prepara Txomin, en la puerta."), ops, T)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Nada":
			return
		if op.begins_with("Comprar"):
			if S.money < Z.bandeja:
				sfx("bad")
				await say("Sin dinero no hay bandeja.", T)
				continue
			var v := "txuria"
			if Datos.CAL:   # 1.46: de qué cepa (Txuria, la de Txomin, o uno de tus panes)
				var P := mis_panes(L)
				var oc: int = 0
				if P.size():
					oc = await ask("¿De qué cepa? La Txuria la pongo yo; si no, uno de tus panes.", ["Txuria (la de Txomin)"] + P.map(func(x): return x[1]) + ["Nada"], T)
					if oc < 0 or oc > P.size():
						continue
				if oc > 0:
					v = P[oc - 1][0]
					L.panes[v] = int(L.panes[v]) - 1
			S.money -= int(Z.bandeja)
			B.append({"d": S.day, "hum": 100, "v": v} if Datos.CAL else {"d": S.day, "hum": 100})
			sfx("coin")
			await say("Lista para colonizar. En %d días la habrá cogido el micelio; %d más y a recoger." % [int(Z.colon), int(Z.fruto)], T)
		elif op.begins_with("Contratar"):
			var A: Dictionary = D.SETAS_AY
			if await ask("%s Cada %s días, %s más en el recibo del bajo." % [A.d, n(D.RECIBO.dias), Datos.eur(A.sueldo)], ["Contratarlo", "No"], T) != 0:
				continue
			L.ay = S.day
			sfx("coin")
			await say("Mañana empieza. Es de fiar: lo he criado yo.", T)
		elif op == "Panes de micelio":
			await panes_txomin(T)
		elif op == "Pulverizar":
			if not await pulverizar_bajo():   # si pasa de medianoche, setas_dia puede cerrar el bajo
				return
		elif op == "Recoger":
			var g := 0
			var quedan := []
			var pv := {}   # 1.46: lo recogido por cepa (rinde CEPAS.v[k].g)
			for b in B:
				if fase_seta(b) != "lista":
					quedan.append(b)
				else:
					var x: int = ri(int(Z.g[0]), int(Z.g[1]))
					if Datos.CAL:
						x = roundi(x * float(D.CEPAS.v[cepa_de(b)].g))
						pv[cepa_de(b)] = int(pv.get(cepa_de(b), 0)) + x
					g += x
			L.bandejas = quedan
			sfx("get")
			if Datos.CAL:   # 1.44: frescas, a secar; secas, al armario (secar_setas)
				var nf := []
				var tx := []
				for k in pv:
					nf.append({"g": pv[k], "d": S.day, "v": k})
					tx.append("%s %d g" % [nom_cepa(k), pv[k]])
				L.fr = L.get("fr", []) + nf
				await say("Recoges %d g de setas%s y las tiendes en %s: en %s, al armario." % [g, (" (" + ", ".join(PackedStringArray(tx)) + ")") if pv.size() > 1 or not pv.has("txuria") else "", "el deshidratador" if L.get("dh") else "la malla del secadero", "un día" if dias_secar(L) == 1 else "%d días" % dias_secar(L)])
			else:
				L.g += g
				await say("Recoges las setas y las dejas secando en el bajo: %d g." % g)
		elif op == "Tirar las malas":
			var k: int = B.filter(func(b): return b.get("mala")).size()
			L.bandejas = B.filter(func(b): return not b.get("mala"))
			await say(("Tiras %d bandejas." % k) if k > 1 else "Tiras la bandeja.")
		elif op.begins_with("Microdosis:") or op.begins_with("Comestibles:"):
			var kk: String = "mc" if op.begins_with("Micro") else "cc"
			var nn: int = int(L[kk])
			var e: int = nn * int(D.SETAS_PRO.p[kk])
			L[kk] = 0
			S.money += e
			S.sales += e
			S.heat = min(100, S.heat + D.SETAS_PRO.calor * nn)
			sfx("coin")
			toast("+%s · %d %s de %s" % [Datos.eur(e), nn, "caja" if nn == 1 else "cajas", "microdosis" if kk == "mc" else "comestibles"], 1600)
			await say("Esto se mueve solo. %s." % Datos.eur(e), T)
			await check_story()
		elif op.begins_with("Deshidratador") or op.begins_with("Encapsuladora") or op.begins_with("Moldes"):
			var kk: String = "dh" if op.begins_with("Desh") else ("enc" if op.begins_with("Enc") else "mol")
			var pz: int = int(D.SETAS_PRO[{"dh": "deshid", "enc": "encap", "mol": "moldes"}[kk]])
			if S.money < pz:
				sfx("bad")
				await say("Sin %s no hay trato." % Datos.eur(pz), T)
				continue
			S.money -= pz
			L[kk] = true
			sfx("coin")
			await say({"dh": "Te lo bajo yo y lo enchufo junto al secadero: lo que recojas, seco en un día.",
				"enc": "La encapsuladora, en la mesa de trabajo. Con setas secas del armario, cajas de microdosis.",
				"mol": "Los moldes y el chocolate, en la mesa de trabajo. Con setas secas del armario, cajas de comestibles."}[kk], T)
		elif op.begins_with("Venderle"):
			var g: int = int(floor(L.g))
			var e: int = g * int(Z.precio)
			if Datos.CAL:   # 1.46: cada cepa a su precio (CEPAS.v[k].p)
				var gv := gv_setas(L)
				var ev := 0.0
				for k in gv:
					ev += float(gv[k]) * float(Z.precio) * float(D.CEPAS.v[k].p if D.CEPAS.v.has(k) else 1)
				e = roundi(ev * g / maxf(float(L.g), 0.001))
			L.g -= g
			if Datos.CAL:
				quita_gv(L, g)
			S.money += e
			S.sales += e
			S.heat = min(100, S.heat + Z.calor)
			sfx("coin")
			toast("+%s · %d g de setas" % [Datos.eur(e), g], 1600)
			await say("Para mis clientes de siempre. %s." % Datos.eur(e), T)
			await check_story()
		elif op == "Dejar el bajo":
			if await ask("¿Dejas el bajo? Te devuelvo la fianza; lo que haya dentro se queda.", ["Dejarlo", "No"], T) != 0:
				continue
			S.setas = null
			S.money += int(Z.fianza)
			sfx("coin")
			await say("Como quieras. La puerta, cerrada al salir.", T)
			return


# ---------- la caja fuerte y la nevera por dentro (1.36, 11m-almacen) ----------
# Al abrirlas se ven por dentro (pinta.gd, _encima): en la caja, los fajos y los tarros de cogollos según lo lleno que está (por
# porcentajes); en la nevera, un piso por tipo de extracción (TIPOS_EXTR) con sus tarros de mayor a menor THC. Las flechas eligen
# (las filas corren en carrusel), A saca o abre el menú del dinero y B cierra. ALMACEN = {t: "caja" | "nevera", i: el elegido}
var ALMACEN = null

func por_thc(L: Dictionary) -> Array:
	var o := []
	for k in L:
		o.append([k, L[k]])
	o.sort_custom(func(a, b): return a[1].thc > b[1].thc or (a[1].thc == b[1].thc and a[0] < b[0]))
	return o

func items_almacen(t: String) -> Array:
	var o := []
	if t == "cam":   # 1.43.6: el camarote, GUARDAR y los tarros de 10 L (CAMAROTE.tarro g cada uno)
		o.append({"k": "+"})
		var tc := float(D.CAMAROTE.tarro)
		for l in por_thc(cam().get("buds", {})):
			var g: float = floor(l[1].g)
			var nt: int = maxi(1, ceili(g / tc - 1e-9))
			for q in nt:
				o.append({"k": l[0], "b": l[1], "r": 0, "q": q, "n": nt, "gj": g - tc * (nt - 1) if q == nt - 1 else tc})
		return o
	if t == "caja":
		o.append({"k": "$"})
		o.append({"k": "+"})   # GUARDAR, el primer tarro (vacío)
		# 1.41 (lo pidió el usuario: realista): cada lote, en los tarros de ALM.tarro g que llenaría de verdad (de 4 L, sin aplastar)
		var tg := float(D.ALM.tarro)
		for l in por_thc(S.caja.buds):
			var g: float = floor(l[1].g)
			var nt: int = maxi(1, ceili(g / tg - 1e-9))
			for q in nt:
				o.append({"k": l[0], "b": l[1], "r": 0, "q": q, "n": nt, "gj": g - tg * (nt - 1) if q == nt - 1 else tg})
		return o
	o.append({"k": "+", "s": -1, "j": 0})
	var tipos: Array = D.TIPOS_EXTR
	var todo := por_thc(nevera().rosin)
	for s in tipos.size():
		var j := 0
		for l in todo:
			if tipo_extr(l[0]) == tipos[s]:
				o.append({"k": l[0], "b": l[1], "r": 1, "s": s, "j": j})
				j += 1
	return o

func mueve_almacen(A: Dictionary, b: String) -> bool:
	var it := items_almacen(A.t)
	var nn := it.size()
	var i: int = A.i
	if not nn:
		return false
	var j := i
	var F := int(D.ALM.fila)
	if A.t == "cam":   # 1.43.6: seis por balda
		var FC := int(D.CAMAROTE.est.tarros)
		j = i + {"left": -1, "right": 1, "up": -FC, "down": FC}.get(b, 0)
		j = maxi(0, mini(nn - 1, j))
	elif A.t == "caja":
		if b == "left":
			j = i - 1
		elif b == "right":
			j = i + 1
		elif b == "up":
			j = 0 if i <= F else i - F
		elif b == "down":
			j = 1 if i == 0 else i + F
		j = maxi(0, mini(nn - 1, j))
	else:
		var c: Dictionary = it[i]
		if b == "left" and c.j > 0:
			j = i - 1
		elif b == "right" and i + 1 < nn and it[i + 1].s == c.s:
			j = i + 1
		elif b == "up" or b == "down":
			var d := -1 if b == "up" else 1
			var mejor := -1
			var s: int = c.s + d
			while s >= -1 and s < D.TIPOS_EXTR.size() and mejor < 0:
				var en := []
				for q in nn:
					if it[q].s == s:
						en.append(q)
				if en.size():
					mejor = en[mini(c.j, en.size() - 1)]
				s += d
			if mejor >= 0:
				j = mejor
	if j == i:
		return false
	A.i = j
	return true

func _pct_txt(p: float) -> String:
	return "%d %%" % Datos.jsround(p * 100)

func desc_almacen(A: Dictionary) -> String:
	var its := items_almacen(A.t)
	var it = its[A.i] if A.i < its.size() else null
	if A.t == "cam":   # 1.43.6
		var CM: Dictionary = D.CAMAROTE
		var so: float = float(cam().get("sob", 0))
		var sob_t := ("Sobres de humedad: %d (uno por tarro, %d días)." % [ceili(so - 1e-9), int(CM.dura)]) if so > 0 else "Sin sobres de humedad: lo curado no se afina."
		if it == null or it.k == "+":
			return "GUARDAR: llevas %s de cogollos y en el camarote caben %s más (%d tarros de 10 L). %s\nA: guardar · B: cerrar." % [g_txt(total_buds()), g_txt(maxf(0, cam_cap() - cam_g())), cam_est() * int(CM.est.tarros), sob_t]
		var tj: String = (" en %d tarros (este, el %d.º: %d g)" % [int(it.n), int(it.q) + 1, int(it.gj)]) if int(it.n) > 1 else ""
		var af := float(it.b.get("af", 0))
		return "%s: %s%s · %s %% THC%s%s.\nA: sacarlo · B: cerrar." % [lot_nombre(it.k), g_lote(it.b.g), tj, Datos.pct(it.b.thc), cura_corto(it.b),
			(" · afinada al 62 %%" if af >= 1 else (" · afinándose (%d %%)" % Datos.jsround(af * 100))) if af else ""]
	if A.t == "caja":
		var C: Dictionary = D.CAJA[int(S.caja.nivel)]
		var g := caja_g()
		if it != null and it.k == "+":
			return "GUARDAR: llevas %s de cogollos y en la caja caben %s más.%s\nA: guardar · B: cerrar." % [g_txt(total_buds()), g_txt(maxf(0, C.g - g)), (" Con los tarros se curan en %d días." % int(D.CURADO.dias)) if S.items.get("tarros") else ""]
		if it == null or it.k == "$":
			return "Dinero: %s de %s (%s). Tarros: %s de %s (%s).\nA: guardar o sacar · B: cerrar." % [Datos.eur(S.caja.money), Datos.eur(C.money), _pct_txt(S.caja.money / C.money), g_lote(g), _kg(int(C.g)), _pct_txt(g / C.g)]
		var tj: String = (" en %d tarros (este, el %d.º: %d g)" % [int(it.n), int(it.q) + 1, int(it.gj)]) if int(it.n) > 1 else ""
		return "%s: %s%s · %s %% THC%s.\nA: sacarlo · B: cerrar." % [lot_nombre(it.k), g_lote(it.b.g), tj, Datos.pct(it.b.thc), cura_corto(it.b)]
	var r := nevera_r()
	if it == null or it.k == "+":
		return "GUARDAR: llevas %s g de extractos y en la nevera caben %s g más.%s\nA: guardar · B: cerrar." % [Datos.coma(Datos.jsround(total_rosin() * 10) / 10.0), Datos.coma(maxf(0, floor((nevera_cap() - r) * 10 + 1e-9) / 10.0)),
			(" En los tarros, en frío, se curan en %d días." % int(D.CURADO.dias)) if S.items.get("tarros") else " Con tarros, se curarían en frío."]
	var cu := float(it.b.get("cu", 0))
	return "%s: %s g · %s %% THC · %s. Nevera: %s g de %d (%s).\nA: sacarlo · B: cerrar." % [extr_nombre(it.k), Datos.coma(it.b.g), Datos.pct(it.b.thc), "curado" if cu >= 1 else ("curándose" if cu else "sin curar"),
		Datos.coma(Datos.jsround(r * 10) / 10.0), int(nevera_cap()), _pct_txt(r / nevera_cap())]

func _dlg_fijo(t: String, nombre: String) -> void:
	if oraculo:
		return
	dlg.show()
	dlg_nm.visible = nombre != ""
	dlg_nm_txt.text = nombre
	dlg_more.hide()
	dlg_txt.text = nm(t)
	_coloca.call_deferred()

# la vista: hasta que eliges (A) o cierras (B: null); i0, el que sale elegido. Las pruebas la cambian (gancho_almacen, ui.gd)
func elegir_almacen(t: String, i0 := 0):
	if gancho_almacen.is_valid():
		var q = gancho_almacen.call(t)
		if q == null:
			return null
		var its := items_almacen(t)
		if int(q) >= its.size():
			return null
		var r: Dictionary = its[int(q)].duplicate()
		r.i = int(q)
		return r
	var nn := items_almacen(t).size()
	ALMACEN = {"t": t, "i": maxi(0, mini(nn - 1, i0))}
	var N := "CAJA FUERTE" if t == "caja" else "CAMAROTE" if t == "cam" else "NEVERA"
	_dlg_fijo(desc_almacen(ALMACEN), N)
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(null)
			return
		if b == "A":
			var its := items_almacen(t)
			if ALMACEN.i < its.size():
				pop()
				var r: Dictionary = its[ALMACEN.i].duplicate()
				r.i = ALMACEN.i
				pr.res(r)
			return
		if mueve_almacen(ALMACEN, b):
			sfx("sel")
			_dlg_fijo(desc_almacen(ALMACEN), N))
	var e = await Motor.espera(pr)
	ALMACEN = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	return e

# un tarro de w × h en (x, y), a escala k: por dentro, lo que lleva (den: alm-cog-p/-s o alm-x-<tipo>, almacen.py) a su nivel,
# de 1 a 4 cuartos de f (0-1), sobre el color c (el de la variedad, que asoma por los cogollos) o, en los botes, el v de detrás
# del cristal (en la nevera, el blanco); encima, el cristal y la tapa (spr: alm-tarro, alm-tarro-s o alm-bote; -g al doble) y la
# etiqueta de papel con el sello verde del curado (1.36.1; 1.36.2: cada cosa, como es)
func _tarro(o: Array, x: int, y: int, w: int, h: int, c: String, f: float, cu: bool, spr: String, den: String, k := 1, v := "#2a343a", suf := "") -> void:
	var g := "-g" if k > 1 else ""
	var n := clampi(int(ceil(f * 4.0 - 1e-9)), 1, 4)
	o.append([x + k, y + 4 * k, (w - 2) * k, (h - 5) * k, c if w >= 14 else v])
	o.append(["@", den + "-" + str(n) + g + suf, x + k, y + 4 * k])   # suf: «-xl», lo de dentro de los tarros de 10 L (1.43.6)
	o.append(["@", spr + g, x, y])
	if w >= 14:
		var yl: int = y + Datos.jsround(h / 2.0) * k
		o.append(["@", "alm-etiqueta" + g, x + 4 * k, yl])
		if cu:
			o.append([x + 11 * k, yl + k, 2 * k, 2 * k, "#3f8a46"])
	elif cu:
		o.append([x + (w - 3) * k, y + 4 * k, 2 * k, 2 * k, "#58c070"])

# lo de dentro de un lote: los cogollos pelados (manicurados) o sin pelar; el extracto por su tipo, y el rosin curado, cremoso
func _dentro_lote(k: String, b: Dictionary, r := false) -> String:
	if not r:
		return "alm-cog-" + ("p" if float(b.get("mc", 0)) >= 1 else "s")
	var t := tipo_extr(k)
	return "alm-x-" + t + ("-cu" if t == "rosin" and float(b.get("cu", 0)) >= 1 else "")

func _marco(o: Array, x: int, y: int, w: int, h: int) -> void:
	o.append_array([[x, y, w, 1, "#f8d040"], [x, y + h - 1, w, 1, "#f8d040"], [x, y, 1, h, "#f8d040"], [x + w - 1, y, 1, h, "#f8d040"]])

func _color_lote(k: String) -> String:
	var st = strain(lot_sid(k))
	return st.c if st else "#7aa63e"

func _barra_alm(o: Array, px: int, py: int, n: int, ic: String, f: float, c: String) -> void:
	var y := py + 66 + n * 10
	o.append(["@", "alm-ic-" + ic, px + 4, y - 1])
	o.append([px + 15, y, Datos.jsround(40 * maxf(0, minf(1, f))), 5, c])

# la ventana del elegido (lo pidió el usuario), a la derecha: en grande y con sus barras (panelAlmacen en 11m-almacen)
func panel_almacen(o: Array, A: Dictionary, px: int, py: int) -> void:
	var its := items_almacen(A.t)
	var it = its[A.i] if A.i < its.size() else null
	o.append(["@", "alm-panel", px, py])
	if it == null:
		return
	if A.t == "cam":   # 1.43.6: el tarro de 10 L y sus barras (lo afinado, con la gota)
		var so: float = float(cam().get("sob", 0))
		if it.k == "+":
			o.append(["@", "alm-mas-xl", px + 19, py + 16])
			_barra_alm(o, px, py, 0, "g", peso_encima() / cap_mochila(), "#e0a040")
			_barra_alm(o, px, py, 1, "cu", cam_g() / maxf(1.0, cam_cap()), "#d8b048")
			_barra_alm(o, px, py, 2, "hr", minf(1.0, so / float(maxi(1, cam_tarros()))), "#4e9ad8")
			return
		_tarro(o, px + 19, py + 16, 22, 31, _color_lote(it.k), float(it.gj) / float(D.CAMAROTE.tarro), float(it.b.get("cu", 0)) >= 1, "alm-tarro-xl-s" if it.k.contains("*") else "alm-tarro-xl", _dentro_lote(it.k, it.b), 1, "#2a343a", "-xl")
		_barra_alm(o, px, py, 0, "thc", it.b.thc / 30.0, "#e8d070")
		_barra_alm(o, px, py, 1, "cu", float(it.b.get("cu", 0)), "#58c070")
		_barra_alm(o, px, py, 2, "hr", float(it.b.get("af", 0)), "#4e9ad8")
		return
	var caja: bool = A.t == "caja"
	var C: Dictionary = D.CAJA[int(S.caja.nivel)] if caja else {}
	if it.k == "$":
		var nn: int = maxi(1, ceili(minf(1.0, S.caja.money / C.money) * 3)) if S.caja.money > 0 else 0
		for q in nn:
			o.append(["@", "alm-fajo-g", px + 15, py + 38 - q * 12])
		_barra_alm(o, px, py, 0, "eur", S.caja.money / C.money, "#7cc07a")
		_barra_alm(o, px, py, 1, "cu", caja_g() / C.g, "#d8b048")
		return
	if it.k == "+":
		o.append(["@", "alm-mas-g", px + 12, py + 8])
		_barra_alm(o, px, py, 0, "g", peso_encima() / cap_mochila(), "#e0a040")
		_barra_alm(o, px, py, 1, "cu", caja_g() / C.g if caja else nevera_r() / nevera_cap(), "#58b0e0")
		return
	if not it.r:
		_tarro(o, px + 12, py + 8, 18, 25, _color_lote(it.k), float(it.gj) / float(D.ALM.tarro), float(it.b.get("cu", 0)) >= 1, "alm-tarro-s" if it.k.contains("*") else "alm-tarro", _dentro_lote(it.k, it.b), 2)
		_barra_alm(o, px, py, 0, "thc", it.b.thc / 30.0, "#e8d070")
		_barra_alm(o, px, py, 1, "cu", float(it.b.get("cu", 0)), "#58c070")
		_barra_alm(o, px, py, 2, "mc", float(it.b.get("mc", 0)), "#a0c8f0")
		return
	var cap: float = float(D.NEVERA.bote)
	_tarro(o, px + 18, py + 20, 12, 12, D.COLOR_EXTR[tipo_extr(it.k)], it.b.g / cap, float(it.b.get("cu", 0)) >= 1, "alm-bote", _dentro_lote(it.k, it.b, true), 2)
	_barra_alm(o, px, py, 0, "thc", it.b.thc / 90.0, "#e8d070")
	_barra_alm(o, px, py, 1, "cu", float(it.b.get("cu", 0)), "#58c070")
	_barra_alm(o, px, py, 2, "g", it.b.g / cap, "#e0a040")

# la vista: la caja (168 × 100) o la nevera (152 × 120) y, a su derecha, la ventana del elegido (60 × 100), centradas juntas.
# Rectángulos [x, y, w, h, color] y sprites ["@", nombre, x, y] (misc:alm-*, con el ancla arriba a la izquierda)
func rects_almacen(A: Dictionary) -> Array:
	var o := []
	var it := items_almacen(A.t)
	var F := int(D.ALM.fila)
	if A.t == "cam":   # 1.43.6: el camarote (168 × 100), seis tarros de 10 L por balda y dos baldas a la vista
		var FC := int(D.CAMAROTE.est.tarros)
		var x0: int = (SW - 232) >> 1
		var y0 := 4
		o.append(["@", "alm-camarote", x0, y0])
		var fila0: int = 0 if A.i < FC else int(floor(float(A.i) / FC)) - 1
		for f in 2:
			var y: int = y0 + 6 + f * 46
			for c in FC:
				var q: int = (fila0 + f) * FC + c
				if q >= it.size():
					continue
				var Jt: Dictionary = it[q]
				var x: int = x0 + 7 + c * 26
				if Jt.k == "+":
					o.append(["@", "alm-mas-xl", x, y])
				else:
					_tarro(o, x, y, 22, 31, _color_lote(Jt.k), float(Jt.gj) / float(D.CAMAROTE.tarro), float(Jt.b.get("cu", 0)) >= 1, "alm-tarro-xl-s" if Jt.k.contains("*") else "alm-tarro-xl", _dentro_lote(Jt.k, Jt.b), 1, "#2a343a", "-xl")
				if q == A.i:
					_marco(o, x - 2, y - 2, 26, 35)
		if fila0 > 0:
			o.append_array([[x0 + 160, y0 + 3, 2, 1, "#f8d040"], [x0 + 159, y0 + 4, 4, 1, "#f8d040"]])
		if it.size() > (fila0 + 2) * FC:
			o.append_array([[x0 + 159, y0 + 88, 4, 1, "#f8d040"], [x0 + 160, y0 + 89, 2, 1, "#f8d040"]])
		o.append_array([[x0 + 8, y0 + 89, 140, 5, "#2a2d34"], [x0 + 9, y0 + 90, Datos.jsround(138 * minf(1.0, cam_g() / maxf(1.0, cam_cap()))), 3, "#d8b048"]])
		panel_almacen(o, A, x0 + 172, y0)
		return o
	if A.t == "caja":
		var C: Dictionary = D.CAJA[int(S.caja.nivel)]
		var x0: int = (SW - 232) >> 1
		var y0 := 4
		var pm := minf(1.0, S.caja.money / C.money)
		var pg := minf(1.0, caja_g() / C.g)
		o.append(["@", "alm-caja", x0, y0])
		var nf: int = maxi(1, ceili(pm * D.ALM.fajos)) if S.caja.money > 0 else 0
		for q in int(D.ALM.fajos):
			var x: int = x0 + 8 + (q % 3) * 17
			var y: int = y0 + 52 - int(q / 3) * 12
			if q < nf:
				o.append(["@", "alm-fajo", x, y])
			else:
				o.append([x, y + 6, 15, 2, "#22252c"])
		o.append_array([[x0 + 8, y0 + 70, 49, 6, "#2a2d34"], [x0 + 9, y0 + 71, Datos.jsround(47 * pm), 4, "#7cc07a"]])
		if A.i == 0:
			_marco(o, x0 + 6, y0 + 8, 53, 66)
		var jar := it.slice(1)
		var sel: int = A.i - 1
		var fila0: int = 0 if sel < F else int(floor(float(sel) / F)) - 1
		for f in 2:
			var y: int = y0 + 8 + f * 34
			for c in F:
				var q: int = (fila0 + f) * F + c
				if q >= jar.size():
					continue
				var Jt: Dictionary = jar[q]
				var x: int = x0 + 69 + c * 23
				if Jt.k == "+":
					o.append(["@", "alm-mas", x, y])
				else:
					_tarro(o, x, y, 18, 25, _color_lote(Jt.k), float(Jt.gj) / float(D.ALM.tarro), float(Jt.b.get("cu", 0)) >= 1, "alm-tarro-s" if Jt.k.contains("*") else "alm-tarro", _dentro_lote(Jt.k, Jt.b))
				if q == sel:
					_marco(o, x - 2, y - 2, 22, 29)
		if fila0 > 0:
			o.append_array([[x0 + 160, y0 + 8, 2, 1, "#f8d040"], [x0 + 159, y0 + 9, 4, 1, "#f8d040"]])
		if jar.size() > (fila0 + 2) * F:
			o.append_array([[x0 + 159, y0 + 71, 4, 1, "#f8d040"], [x0 + 160, y0 + 72, 2, 1, "#f8d040"]])
		o.append_array([[x0 + 68, y0 + 82, 92, 6, "#2a2d34"], [x0 + 69, y0 + 83, Datos.jsround(90 * pg), 4, "#d8b048"]])
		panel_almacen(o, A, x0 + 172, y0)
		return o
	var x0: int = (SW - 216) >> 1
	var y0 := 4
	var p := minf(1.0, nevera_r() / nevera_cap())
	var cs = it[A.i] if A.i < it.size() else null
	var P := int(D.ALM.piso)
	o.append_array([["@", "alm-nevera", x0, y0], ["@", "alm-guardar", x0 + 6, y0 + 5]])
	if cs != null and cs.k == "+":
		_marco(o, x0 + 5, y0 + 4, 46, 13)
	for s in D.TIPOS_EXTR.size():
		var e: String = D.TIPOS_EXTR[s]
		var y: int = y0 + 19 + s * 14
		var L := it.filter(func(x): return x.s == s)
		var off: int = maxi(0, cs.j - P + 1) if cs != null and cs.s == s else 0
		o.append_array([[x0 + 6, y + 2, 5, 10, D.COLOR_EXTR[e]], [x0 + 6, y + 2, 5, 1, "#ffffff"]])
		var vis := L.slice(off, off + P)
		for q in vis.size():
			var Jt: Dictionary = vis[q]
			var x: int = x0 + 15 + q * 15
			_tarro(o, x, y + 1, 12, 12, D.COLOR_EXTR[e], Jt.b.g / float(D.NEVERA.bote), float(Jt.b.get("cu", 0)) >= 1, "alm-bote", _dentro_lote(Jt.k, Jt.b, true), 1, "#c4d6dc")
			if cs != null and cs.s == s and Jt.j == cs.j:
				_marco(o, x - 2, y - 1, 16, 16)
		if off > 0:
			o.append_array([[x0 + 12, y + 6, 1, 3, "#f8a020"], [x0 + 11, y + 7, 1, 1, "#f8a020"]])
		if L.size() > off + P:
			o.append_array([[x0 + 136, y + 6, 1, 3, "#f8a020"], [x0 + 137, y + 7, 1, 1, "#f8a020"]])
	var hb := Datos.jsround(94 * p)
	o.append([x0 + 143, y0 + 20 + 94 - hb, 3, hb, "#58b0e0"])
	panel_almacen(o, A, x0 + 156, y0)
	return o

# GUARDAR (1.36, lo pidió el usuario): el primer tarro de la caja (los cogollos que llevas) y la fila de arriba de la nevera (los
# extractos): todo lo que quepa o un lote
func _hueco_alm(caja: bool) -> float:
	return floor(D.CAJA[int(S.caja.nivel)].g - caja_g()) if caja else floor((nevera_cap() - nevera_r()) * 10 + 1e-9) / 10.0

func guardar_almacen(t: String):
	if t == "cam":   # 1.43.6: el camarote, como la caja
		await _guardar_cam()
		return
	var caja := t == "caja"
	var L := bud_lots(1) if caja else rosin_lots(.1)
	var de: Dictionary = S.buds if caja else S.rosin
	var a: Dictionary = S.caja.buds if caja else nevera().rosin
	var mn := 1.0 if caja else .1
	if L.is_empty():
		await say("No llevas cogollos encima." if caja else "No llevas extractos encima.")
		return
	if _hueco_alm(caja) < mn:
		await say("En la caja no caben más cogollos." if caja else "En la nevera ya no cabe más.")
		return
	var j: int = await ask("¿Qué guardas en la caja?" if caja else "¿Qué guardas en la nevera?", ["Todos los cogollos" if caja else "Todos los extractos", "Un lote" if caja else "Un extracto", "Nada"])
	if j == 0:
		var q := 0.0
		for l in L:
			var g: float = minf(l[1].g, _hueco_alm(caja))
			if g < mn:
				break
			q += g
			if caja:
				mover_lote(de, a, l[0], g)
			else:
				mover_rosin(de, a, l[0], g)
		sfx("sel")
		var resto: bool = total_buds() >= 1 if caja else total_rosin() >= .1
		await say("Guardas %s en %s.%s" % [g_txt(q) if caja else Datos.coma(Datos.jsround(q * 10) / 10.0) + " g", "la caja" if caja else "la nevera", " No cabe todo: el resto se queda fuera." if resto else ""])
		return
	if j != 1:
		return
	var its := L.map(lot_item) if caja else L.map(rosin_item)
	its.append({"label": "Nada"})
	var i: int = await menu(its, {"cls": "right", "title": "¿Qué guardas?"})
	if i < 0 or i >= L.size():
		return
	var k: String = L[i][0]
	var b: Dictionary = L[i][1]
	var g
	if caja:
		g = await cuanto("%s: ¿cuánto?" % lot_nombre(k), minf(floor(b.g), _hueco_alm(caja)), [10, 50, 100, 500, 1000], func(v): return g_txt(v))
	else:
		g = await cuanto("%s: ¿cuánto?" % extr_nombre(k), minf(b.g, _hueco_alm(caja)), [1, 5, 10, 50], func(v): return Datos.coma(v) + " g")
	if not g:
		return
	if caja:
		mover_lote(de, a, k, g)
	else:
		mover_rosin(de, a, k, g)
	sfx("sel")

func _guardar_cam():
	var L := bud_lots(1)
	var hueco := func() -> float: return floor(cam_cap() - cam_g())
	if L.is_empty():
		await say("No llevas cogollos encima.")
		return
	if hueco.call() < 1:
		await say("En el camarote no caben más tarros: pide otra estantería en la tienda online." if cam_est() < int(D.CAMAROTE.est.max) else "El camarote está lleno.")
		return
	var j: int = await ask("¿Qué guardas en el camarote?", ["Todos los cogollos", "Un lote", "Nada"])
	if j == 0:
		var q := 0.0
		for l in L:
			var g: float = minf(l[1].g, hueco.call())
			if g < 1:
				break
			q += g
			mover_lote(S.buds, S.cam.buds, l[0], g)
		sfx("sel")
		await say("Guardas %s en los tarros del camarote.%s" % [g_txt(q), " No cabe todo: el resto se queda fuera." if total_buds() >= 1 else ""])
		return
	if j != 1:
		return
	var its := L.map(lot_item)
	its.append({"label": "Nada"})
	var i: int = await menu(its, {"cls": "right", "title": "¿Qué guardas?"})
	if i < 0 or i >= L.size():
		return
	var k: String = L[i][0]
	var g = await cuanto("%s: ¿cuánto?" % lot_nombre(k), minf(floor(L[i][1].g), hueco.call()), [10, 50, 100, 500, 1000], func(v): return g_txt(v))
	if not g:
		return
	mover_lote(S.buds, S.cam.buds, k, g)
	sfx("sel")

# el camarote (1.43.6): las estanterías de tarros de 10 L; GUARDAR el primero y, en los demás, sacar un lote
func camarote_action():
	if cam_est() == 0:
		await say("Aquí van las estanterías de los tarros de 10 L. Se piden en la tienda online.")
		return
	if not (S.cam.get("buds") is Dictionary):
		S.cam.buds = {}
	var i := 0
	while true:
		var e = await elegir_almacen("cam", i)
		if e == null:
			return
		i = e.i
		if e.k == "+":
			await guardar_almacen("cam")
			continue
		var g: float = minf(floor(e.b.g * 10) / 10.0, floor(libre_mochila()))
		if g < 1:
			await say("No te cabe nada más encima.")
			continue
		mover_lote(S.cam.buds, S.buds, e.k, g)
		sfx("sel")
		await say("Sacas %s de %s." % [g_txt(g), lot_nombre(e.k)])

# la nevera (1.36): en la vista, GUARDAR arriba y, en los pisos, sacar un extracto
func nevera_action():
	var i := 0
	while true:
		var e = await elegir_almacen("nevera", i)
		if e == null:
			return
		i = e.i
		if e.k == "+":
			await guardar_almacen("nevera")
			continue
		var g: float = minf(e.b.g, floor(libre_mochila() * 10 + 1e-9) / 10.0)
		if g < .1:
			await say("No te cabe nada más encima.")
			continue
		mover_rosin(nevera().rosin, S.rosin, e.k, g)
		sfx("sel")
		await say("Sacas %s g de %s." % [Datos.coma(g), extr_nombre(e.k, true)])

# la mesa de manicurar (1.36, junto a la de genética): tijeras, guantes y bandeja; pela un lote de los que llevas encima
func manicura_action():
	if "charas" in extr_ya():
		var j: int = await ask("La mesa de manicurar. ¿Qué haces?", ["Manicurar un lote", D.EXTR.charas.v, "Nada"])
		if j == 1:
			await extraer("charas")
			return
		if j != 0:
			return
	var lots := bud_lots(1).filter(func(l): return float(l[1].get("mc", 0)) < 1)
	if lots.is_empty():
		await say("La mesa de manicurar: tijeras de punta fina, guantes y una bandeja con rejilla. %s" % ["Lo que llevas ya está manicurado." if total_buds() >= 1 else "Trae cogollos para pelarlos."])
		return
	var its := lots.map(lot_item)
	its.append({"label": "Nada"})
	var i: int = await menu(its, {"cls": "right", "title": "Manicurar: ¿qué lote?"})
	if i < 0 or i >= lots.size():
		return
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var m: int = mini(int(D.MANICURA.max), maxi(15, Datos.jsround(b.g * (1 - float(b.get("mc", 0))) * D.MANICURA.min)))
	await say("Con las tijeras, cogollo a cogollo: fuera las hojitas con poca resina, que quede limpio y redondo.", "MANICURA")
	await gesto("manicurar")   # 1.54
	b.mc = 1
	advance_time(m)
	sfx("get")
	var dur: String = (("%d h" % int(m / 60)) + ((" %d min" % (m % 60)) if m % 60 else "")) if m >= 60 else "%d min" % m
	await say("%s: %s manicurados en %s. Se venden un %d %% más caros." % [lot_nombre(k), g_txt(b.g), dur, Datos.jsround(D.MANICURA.precio * 100)])

# un mueble por máquina (1.36), montado en el piso cuando la tienes (montar_casa)
func mueble_extr(o: String):
	var Mu: Dictionary = D.MUEBLE_EXTR[o]
	var ya := extr_ya()
	var L: Array = Mu.t.filter(func(t): return t in ya)
	if L.is_empty():
		await say(Mu.n + ".")
		return
	if L.size() == 1:
		await extraer(L[0])
		return
	var ops := L.map(func(t): return D.EXTR[t].v)
	ops.append("Nada")
	var j: int = await ask(Mu.n + ". ¿Qué haces?", ops)
	if j >= 0 and j < L.size():
		await extraer(L[j])

# ---------- ordenar (1.37, 12d-orden): mover una pieza con las flechas; A la deja si cabe y B la devuelve ----------
# mientras mueves, la pieza se ve en el mapa en el cursor (aunque no quepa); O y G, los objetos y el suelo sin ella
func _vista_orden(m: Dictionary, P_: Dictionary, O: Array, G: Array) -> void:
	for y in int(m.h):
		m.o[y] = O[y].duplicate()
		m.g[y] = G[y].duplicate()
	if P_.get("suelo"):
		var fs := ("-" + str(deco_v("suelo"))) if deco_v("suelo") else ""
		for y in int(m.h):
			for x in int(m.w):
				if str(m.g[y][x]).begins_with("alf"):
					m.g[y][x] = "floor" + fs
		var cs := celdas_p(P_, ORDEN.x, ORDEN.y)
		for j in cs.size():
			var c: Array = cs[j]
			if c[1] >= 0 and c[1] < int(m.h) and c[0] >= 0 and c[0] < int(m.w) and m.g[c[1]][c[0]] != "mat":
				m.g[c[1]][c[0]] = "alf" + str(deco_v("alfombra")) + "abcd"[j] + fs
		return
	for c in celdas_p(P_, ORDEN.x, ORDEN.y):
		if c[2] and c[1] >= 0 and c[1] < int(m.h) and c[0] >= 0 and c[0] < int(m.w):
			m.o[c[1]][c[0]] = c[2]
	if str(P_.get("si", "")) == "carpa":   # 1.55: la carpa se pinta donde la llevas
		for t in m.get("carpas", []):
			if "carpa%d" % int(t.ci) == P_.k:
				t.x1 = int(ORDEN.x) + int(t.x1) - int(t.x0)
				t.x0 = int(ORDEN.x)
				t.y = int(ORDEN.y)

func mover_pieza(mapa: String, k: String) -> bool:
	var m: Dictionary = MAPS[mapa]
	var P_ := pieza_de(mapa, k)
	if not m.get("opos", {}).has(k):
		return false
	var x0: int = int(m.opos[k][0])
	var y0: int = int(m.opos[k][1])
	if not P_.get("suelo"):
		for c in celdas_p(P_, x0, y0):
			m.o[c[1]][c[0]] = null
	var O := copia_o(m)
	var G: Array = m.g.map(func(r): return r.duplicate())
	ORDEN = {"mapa": mapa, "k": k, "x": x0, "y": y0, "no": ""}
	var xs := []
	var ys := []
	for o in P_.o:
		xs.append(int(o[0])); ys.append(int(o[1]))
	for g in P_.get("gente", []):
		xs.append(int(g[0])); ys.append(int(g[1]))
	var mx := [-int(xs.min()), int(m.w) - 1 - int(xs.max())]
	var my := [-int(ys.min()), int(m.h) - 1 - int(ys.max())]
	var muestra := func():
		ORDEN.no = cabe_pieza(mapa, k, ORDEN.x, ORDEN.y, O)
		_vista_orden(m, P_, O, G)
		_dlg_fijo("%s · %s\nFlechas: mover · A: dejar aquí · B: como estaba" % [P_.n, D.ORDEN_MOTIVO[ORDEN.no] if ORDEN.no != "" else "Aquí cabe."], D.ORDEN_P[mapa].n)
	muestra.call()
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(false)
			return
		if b == "A":
			if ORDEN.no != "":
				sfx("no")
				return
			pop()
			pr.res(true)
			return
		var d = {"left": [-1, 0], "right": [1, 0], "up": [0, -1], "down": [0, 1]}.get(b)
		if d == null:
			return
		var nx := clampi(ORDEN.x + d[0], mx[0], mx[1])
		var ny := clampi(ORDEN.y + d[1], my[0], my[1])
		if nx == ORDEN.x and ny == ORDEN.y:
			return
		ORDEN.x = nx
		ORDEN.y = ny
		sfx("sel")
		muestra.call())
	var r: bool = await Motor.espera(pr)
	var x: int = ORDEN.x
	var y: int = ORDEN.y
	ORDEN = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	for j in int(m.h):
		m.o[j] = O[j].duplicate()
		m.g[j] = G[j].duplicate()
	if not P_.get("suelo"):
		for c in celdas_p(P_, x0, y0):
			m.o[c[1]][c[0]] = c[2]
	if r:
		if not (S.get("coloca") is Dictionary):
			S.coloca = {}
		if not S.coloca.has(mapa):
			S.coloca[mapa] = {}
		S.coloca[mapa][k] = [x, y]
	rehace_orden(mapa)
	if r:
		sfx("get")
	return r

# después de mover: el mapa con lo elegido y la gente en su sitio
func rehace_orden(mapa: String) -> void:
	if mapa == "home":
		MAPS.home.carpasK = null
		montar_casa()
	elif mapa == "nave":
		montar_nave()
	else:
		montar_club(mapa)
	if S.map == mapa:
		coloca_gente(mapa)

# ORDENAR: la lista de lo que se puede mover, hasta Terminar
func ordenar(mapa: String) -> void:
	if not D.ORDEN_P.has(mapa) or S.map != mapa:   # 1.52.1 (lo pidió el usuario): una sala solo se ordena desde dentro de ella
		return
	var i := 0
	while true:
		var L := piezas_ya(mapa)
		var items: Array = L.map(func(P_): return {"label": P_.n})
		items.append({"label": "Terminar"})
		i = await menu(items, {"title": D.ORDEN_P[mapa].n, "initial": i, "cancel": true})
		if i < 0 or i >= L.size():
			return
		await mover_pieza(mapa, L[i].k)

# ---------- el carro de esquejes por dentro (1.40, lo pidió el usuario: «que no sea un menú») ----------
# dos bandejas de 12 tacos (6 × 2), la de arriba y la de abajo, con sus tubos T5 y su tapa; los esquejes de S.bandejas van por
# orden en los tacos (0-11 arriba, 12-23 abajo). Flechas eligen, A el taco, B cierra. CARRO_V = {i: el elegido}
var CARRO_V = null
const CARRO_W := 116
const CARRO_H := 108

func mueve_carro(V: Dictionary, b: String) -> bool:
	var P := int(D.CARRO.plazas)
	var F := P >> 1
	var nt: int = D.CARRO.bandejas * 2
	var i: int = V.i
	var R: int = i / F
	var c: int = i % F
	if b == "left":
		c -= 1
	elif b == "right":
		c += 1
	elif b == "up":
		R -= 1
	elif b == "down":
		R += 1
	if c < 0 or c >= F or R < 0 or R >= nt:
		return false
	V.i = R * F + c
	return true

func desc_carro(V: Dictionary) -> String:
	var cap: int = D.CARRO.bandejas * D.CARRO.plazas
	var nb: int = S.bandejas.size()
	if V.i < nb:
		var e: Dictionary = S.bandejas[V.i]
		var s = strain(e.sid)
		var hasta: int = int(e.dia) + int(D.CARRO.dias)
		return "Esqueje de %s%s: pinchado el %s, aguanta hasta el %s%s.\nA: nombrarlo o tirarlo · B: cerrar." % [s.n, etiq(e.f), Datos.fd(e.dia, S.day), Datos.fd(hasta, S.day), " (hoy es el último)" if hasta <= S.day else ""]
	var pr: int = S.esquejes.size()
	return "Taco vacío · %d de %d ocupados. %s\n%s · B: cerrar." % [nb, cap, ("En el propagador llevas %d." % pr) if pr else "El propagador está vacío.", "A: pinchar" if pr and nb < cap else "A: ver"]

func elegir_carro(i0 := 0):
	if gancho_carro.is_valid():
		return gancho_carro.call()
	var cap: int = D.CARRO.bandejas * D.CARRO.plazas
	CARRO_V = {"i": clampi(i0, 0, cap - 1)}
	_dlg_fijo(desc_carro(CARRO_V), "CARRO DE ESQUEJES")
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(null)
			return
		if b == "A":
			pop()
			pr.res(CARRO_V.i)
			return
		if mueve_carro(CARRO_V, b):
			sfx("sel")
			_dlg_fijo(desc_carro(CARRO_V), "CARRO DE ESQUEJES"))
	var e = await Motor.espera(pr)
	CARRO_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	return e

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

func _esqueje(o: Array, cx: int, y: int, hj: String, k := 1, seco := false, bm: Array = CLON) -> void:
	var c := {"X": hj if not seco else "#b8a050", "D": Color(hj).darkened(.35).to_html(false) if not seco else "#8a7a38", "T": "#4f7a32" if not seco else "#9a8a48",
		"L": Color(hj).lightened(.3).to_html(false) if not seco else "#d0bc70", "K": Color(hj).darkened(.55).to_html(false) if not seco else "#6a5c2c",
		"R": "#e8e0c8"}
	var w: int = bm[0].length() >> 1
	var y0: int = y - (bm.size() - 1) * k
	for r in bm.size():
		var l: String = bm[r]
		var a := 0
		while a < l.length():
			var ch := l[a]
			if not c.has(ch):
				a += 1
				continue
			var b := a
			while b < l.length() and l[b] == ch:
				b += 1
			o.append([cx + (a - w) * k, y0 + r * k, (b - a) * k, k, ("#" + c[ch]) if not c[ch].begins_with("#") else c[ch]])
			a = b

# el taco de turba en su alvéolo de la bandeja negra (x, y: la esquina del alvéolo; k: el tamaño del píxel)
func _taco(o: Array, cx: int, y: int, k := 1) -> void:
	o.append_array([[cx - 7 * k, y, 14 * k, 7 * k, "#141418"], [cx - 7 * k, y, 14 * k, k, "#30303a"], [cx - 5 * k, y + k, 10 * k, 3 * k, "#8a5a34"],
		[cx - 4 * k, y + k, 8 * k, k, "#a8743f"], [cx - 5 * k, y + 4 * k, 10 * k, 2 * k, "#6a4026"], [cx - k, y + 2 * k, 2 * k, k, "#4a2c18"]])

# el taco de turba en grande, suelto (como sale de la bandeja): 12 × 9, con la tierra de arriba y su textura
func _taco_g(o: Array, cx: int, y: int) -> void:
	o.append_array([[cx - 6, y, 12, 9, "#3a2a1e"], [cx - 6, y, 12, 2, "#5a4030"], [cx - 5, y + 1, 10, 1, "#6a4c38"], [cx - 6, y + 8, 12, 1, "#2a1e16"],
		[cx - 4, y + 4, 1, 1, "#4e3826"], [cx + 2, y + 3, 1, 1, "#4e3826"], [cx - 1, y + 6, 1, 1, "#4e3826"], [cx + 4, y + 6, 1, 1, "#4e3826"]])

func _hoja_de(sid: String) -> String:
	var s = strain(sid)
	return String(s.get("hj", "#57a33e")) if s else "#57a33e"

func rects_carro(V: Dictionary) -> Array:
	var o := []
	var x0: int = (SW - CARRO_W - 64) >> 1
	var y0 := 4
	var F := int(D.CARRO.plazas) >> 1
	var nb: int = S.bandejas.size()
	# el carro: patas, ruedas y las dos baldas
	o.append_array([[x0, y0, CARRO_W, CARRO_H, "#1c1e24"], [x0 + 1, y0 + 1, CARRO_W - 2, CARRO_H - 2, "#2a2d34"]])
	o.append_array([[x0 + 2, y0 + 2, 3, CARRO_H - 8, "#8a92a2"], [x0 + CARRO_W - 5, y0 + 2, 3, CARRO_H - 8, "#8a92a2"],
		[x0 + 3, y0 + 2, 1, CARRO_H - 8, "#b8bec8"], [x0 + CARRO_W - 4, y0 + 2, 1, CARRO_H - 8, "#b8bec8"]])
	o.append_array([[x0 + 1, y0 + CARRO_H - 6, 6, 5, "#26262e"], [x0 + CARRO_W - 7, y0 + CARRO_H - 6, 6, 5, "#26262e"],
		[x0 + 3, y0 + CARRO_H - 4, 2, 2, "#6c7482"], [x0 + CARRO_W - 5, y0 + CARRO_H - 4, 2, 2, "#6c7482"]])
	for t in int(D.CARRO.bandejas):
		var sy: int = y0 + 3 + t * 51
		var on: bool = nb > 0
		# los tubos T5 en su pantalla y su luz
		o.append_array([[x0 + 7, sy, CARRO_W - 14, 4, "#5a606c"], [x0 + 9, sy + 3, CARRO_W - 18, 2, "#f4f8ec" if on else "#9aa0a8"]])
		if on:
			o.append_array([[x0 + 7, sy + 5, CARRO_W - 14, 4, "rgba(250,255,230,0.18)"], [x0 + 7, sy + 9, CARRO_W - 14, 6, "rgba(250,255,230,0.08)"]])
		# la bandeja negra y, encima, la tapa transparente con su reflejo
		o.append_array([[x0 + 7, sy + 8, CARRO_W - 14, 41, "#16161c"], [x0 + 8, sy + 9, CARRO_W - 16, 39, "#26262e"], [x0 + 7, sy + 47, CARRO_W - 14, 2, "#3c3e48"]])
		o.append_array([[x0 + 8, sy + 6, CARRO_W - 16, 1, "rgba(210,236,255,0.55)"], [x0 + 8, sy + 6, 1, 10, "rgba(210,236,255,0.45)"],
			[x0 + CARRO_W - 9, sy + 6, 1, 10, "rgba(210,236,255,0.45)"], [x0 + 12, sy + 7, 10, 1, "rgba(255,255,255,0.5)"], [x0 + 26, sy + 7, 3, 1, "rgba(255,255,255,0.5)"]])
		for r in 2:
			for c in F:
				var s: int = t * F * 2 + r * F + c
				var cx: int = x0 + 10 + c * 16 + 7
				var cy: int = sy + 17 + r * 22
				_taco(o, cx, cy)
				if s < nb:
					var e: Dictionary = S.bandejas[s]
					_esqueje(o, cx, cy + 2, _hoja_de(e.sid), 1, int(e.dia) + int(D.CARRO.dias) <= S.day)
				if s == V.i:
					o.append_array([[cx - 8, cy - 13, 16, 1, "#f8d040"], [cx - 8, cy + 8, 16, 1, "#f8d040"], [cx - 8, cy - 13, 1, 22, "#f8d040"], [cx + 7, cy - 13, 1, 22, "#f8d040"]])
	# a la derecha, el elegido en grande, los días que le quedan y el propagador
	var px: int = x0 + CARRO_W + 4
	o.append_array([[px, y0, 60, CARRO_H, "#1c1e24"], [px + 1, y0 + 1, 58, CARRO_H - 2, "#2a2d34"], [px + 6, y0 + 4, 48, 62, "#20222a"]])
	var cx: int = px + 30
	if V.i < nb:
		var e: Dictionary = S.bandejas[V.i]
		var hasta: int = int(e.dia) + int(D.CARRO.dias)
		var seco: bool = hasta <= S.day
		# las raíces, por los días que lleva en la bandeja
		var ra: Array = RAICES.slice(0, clampi(2 * (int(S.day) - int(e.dia)), 0, RAICES.size()))
		if ra.size():
			_esqueje(o, cx, y0 + 52 + ra.size(), "#e8e0c8", 1, false, ra)
		_taco_g(o, cx, y0 + 44)
		_esqueje(o, cx, y0 + 45, _hoja_de(e.sid), 1, seco, CLON_G)
		var f := clampf(float(hasta - S.day + 1) / float(D.CARRO.dias + 1), 0.0, 1.0)
		o.append_array([[px + 6, y0 + 68, 48, 5, "#16161c"], [px + 6, y0 + 68, Datos.jsround(48 * f), 5, "#58c070" if f > .34 else "#e0a040"]])
	else:
		_taco_g(o, cx, y0 + 44)
	# el propagador: un esqueje por cada uno que espera
	o.append_array([[px + 6, y0 + 76, 48, 26, "#16161c"], [px + 7, y0 + 77, 46, 1, "rgba(210,236,255,0.45)"]])
	var pr: int = mini(S.esquejes.size(), 12)
	for q in pr:
		var e: Dictionary = S.esquejes[q]
		var ex: int = px + 10 + (q % 6) * 7
		var ey: int = y0 + 88 + (q / 6) * 11
		o.append_array([[ex - 2, ey, 5, 3, "#6a4026"], [ex - 2, ey, 5, 1, "#8a5a34"]])
		_esqueje(o, ex, ey, _hoja_de(e.sid), 1, false, CLON_MINI)
	return o

# ---------- el bajo de las setas a la vista (1.43.9, lo pidió el usuario: «que puedas entrar al bajo y veas las setas crecer») ----------
# las tres estanterías de rejilla del bajo con sus dos bandejas (2r abajo, 2r + 1 arriba, como bandejas_balda), dibujadas a mano por
# rectángulos: el micelio blanco que va cubriendo el sustrato día a día (y hora a hora), los primordios y las setas que crecen y abren
# el sombrero (genéricas, pardas: sin especie ni método), las gotas de la tapa por la humedad, lo contaminado y lo seco. A la
# derecha, la elegida en grande con su humedad y lo que le falta. A: lo de las bandejas (bajo_menu) · B: cerrar
var SETAS_V = null   # {i}: la bandeja elegida (0-5)
const BAJO_W := 208
const BAJO_H := 108

# lo que lleva la bandeja, en días con decimales (la hora cuenta: se ve crecer)
func t_seta(b: Dictionary) -> float:
	return float(S.day - b.d) + float(S.min) / 1440.0

# un número de 0 a 1 fijo por bandeja y sitio (las manchas del micelio y dónde sale cada seta)
func _hs(a: int, b: int, c: int) -> float:
	var h: int = (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
	return float(absi(h) % 1000) / 1000.0

func mueve_bajo(V: Dictionary, b: String) -> bool:
	var r: int = V.i >> 1
	var j: int = V.i & 1
	if b == "left":
		r -= 1
	elif b == "right":
		r += 1
	elif b == "up":
		j = 1
	elif b == "down":
		j = 0
	var n2: int = 2 * r + j
	if r < 0 or r >= n_baldas() or n2 == V.i:
		return false
	V.i = n2
	return true

func desc_bajo(V: Dictionary) -> String:
	var Z: Dictionary = D.SETAS
	var B: Array = SL().bandejas
	if V.i >= B.size():
		return "Hueco libre en la balda · %d de %d bandejas. Las prepara Txomin, en la puerta.\nB: cerrar." % [B.size(), max_bandejas()]
	var b: Dictionary = B[V.i]
	var f: String = fase_seta(b)
	var t := t_seta(b)
	var tot: int = int(Z.colon) + int(Z.fruto)
	var q := ""
	match f:
		"colonizando":
			q = "el micelio cubre el %d %% del sustrato" % Datos.jsround(100 * clampf(t / Z.colon, 0, 1))
		"fructificando":
			q = "las setas crecen: %d %%" % Datos.jsround(100 * clampf((t - Z.colon) / Z.fruto, 0, 1))
		"lista":
			q = "lista para recoger"
		"contaminada":
			q = "contaminada: hay que tirarla"
		"seca":
			q = "seca: hay que tirarla"
	var dd: String = (" · día %d de %d" % [mini(int(S.day - b.d) + 1, tot), tot]) if not b.get("mala") else ""
	return "Bandeja %d%s · %s%s · humedad %d %%.\nA: pulverizar, recoger o tirar · B: cerrar." % [V.i + 1, (" · " + nom_cepa(cepa_de(b))) if Datos.CAL else "", q, dd, Datos.jsround(b.hum)]

func elegir_bajo(i0 := 0):
	if gancho_bajo.is_valid():
		return gancho_bajo.call(i0)
	SETAS_V = {"i": clampi(i0, 0, 2 * n_baldas() - 1)}
	var tit := "EL SÓTANO" if es_sot() else "EL BAJO"
	_dlg_fijo(desc_bajo(SETAS_V), tit)
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(null)
			return
		if b == "A":
			pop()
			pr.res(SETAS_V.i)
			return
		if mueve_bajo(SETAS_V, b):
			sfx("sel")
			_dlg_fijo(desc_bajo(SETAS_V), tit))
	var e = await Motor.espera(pr)
	SETAS_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	return e

# la vista hasta B: con A sobre una bandeja, el menú de las bandejas (y se vuelve a las baldas); sobre un hueco, que las prepara Txomin
func vista_bajo(i0 := 0) -> void:
	var i := i0
	while SL() != null:
		var r = await elegir_bajo(i)
		if r == null:
			return
		i = int(r)
		if SL() == null:
			return
		if i < SL().bandejas.size():
			await bajo_menu("")
		else:
			await say("En ese hueco no hay bandeja. Las prepara Txomin: se las compras en la puerta.")

# una bandeja (19 × 15 unidades de u px) en x, y: la caja de plástico con la tapa, el sustrato, el micelio, las setas y las gotas
func _bandeja_seta(o: Array, b, x: int, y: int, u: int, sid: int) -> void:
	var R := func(cx: int, cy: int, w: int, h: int, c: String): o.append([x + cx * u, y + cy * u, w * u, h * u, c])
	R.call(0, 0, 19, 15, "rgba(200,222,222,0.16)")
	R.call(0, 1, 1, 14, "#8a9a9a")
	R.call(18, 1, 1, 14, "#8a9a9a")
	R.call(0, 14, 19, 1, "#6a7a7a")
	R.call(0, 0, 19, 1, "#d8e4e4")
	if b == null:
		R.call(1, 13, 17, 1, "#3a3e44")
		return
	var Z: Dictionary = D.SETAS
	var f: String = fase_seta(b)
	var t := t_seta(b)
	var mala = b.get("mala")
	# el sustrato
	R.call(1, 10, 17, 4, "#8a6a4a" if mala == "seca" else "#7a5a3a")
	R.call(1, 12, 17, 2, "#6a4a2e" if mala != "seca" else "#7a5a3c")
	# el micelio: celdas blancas por lo que lleva colonizado (entera desde que fructifica)
	var cov: float = 1.0 if f in ["fructificando", "lista"] else (clampf(t / Z.colon, 0, 1) if mala == null else 0.5)
	for cy in [10, 11, 12, 13]:
		for cx in range(1, 18):
			var h := _hs(sid, cx, cy)
			if h * (1.0 + (cy - 10) * 0.6) < cov:
				R.call(cx, cy, 1, 1, ("#f0eee6" if cy == 10 else "#e0dcd0") if mala != "seca" else "#b8a888")
	if mala == "contaminada":
		for k in 6:
			var cx: int = 2 + int(_hs(sid, k, 7) * 15)
			var cy: int = 10 + int(_hs(sid, k, 8) * 3)
			R.call(cx, cy, 2, 1, "#4a8a3a" if k % 2 else "#3a6a2a")
		R.call(2 + int(_hs(sid, 9, 9) * 14), 11, 1, 1, "#8a8a8a")
	elif mala == "seca":
		for cx in range(3, 17, 4):
			R.call(cx, 11, 1, 2, "#5a4030")
	else:
		# las setas: cinco, cada una a su ritmo; primordio (punto), tallo y sombrero que se abre
		var fr: float = 1.0 if f == "lista" else clampf((t - Z.colon) / Z.fruto, 0, 1) if f == "fructificando" else -1.0
		if fr >= 0:
			# 1.46: cada cepa con su forma y sus colores (CEPAS.v): cúpula (la de siempre), campana, plato o racimo
			var cp: Dictionary = D.CEPAS.v[cepa_de(b)] if Datos.CAL else D.CEPAS.v.txuria
			var C0: String = cp.c[0]
			var C1: String = cp.c[1]
			var C2: String = cp.c[2]
			var PI: String = cp.pie
			var fm: String = cp.f
			for k in 5:
				var cx: int = 2 + k * 3 + int(_hs(sid, k, 1) * 3)
				var dl: float = _hs(sid, k, 2) * 0.3
				var g: float = 1.0 if f == "lista" else clampf((fr - dl) / (1.0 - dl), 0, 1)
				var hs: int = int(round(g * (3 + int(_hs(sid, k, 3) * 4))))
				if g < 0.15:
					R.call(cx, 9, 1, 1, "#e8dcc0")
					continue
				var cw: int = 1 if g < 0.4 else (3 if g < 0.8 else 5)
				if fm == "campana":   # pie largo y fino, sombrero estrecho y alto
					hs += 2
					R.call(cx, 10 - hs, 1, hs, PI)
					var bw: int = mini(cw, 3)
					R.call(cx - (bw >> 1), 9 - hs, bw, 1, C0)
					R.call(cx - (bw >> 1), 8 - hs, bw, 1, C0)
					R.call(cx, 7 - hs, 1, 1, C1)
					if bw >= 3:
						R.call(cx - 1, 8 - hs, 1, 1, C2)
				elif fm == "plano":   # pie corto, plato ancho
					hs = maxi(1, hs - 1)
					R.call(cx, 10 - hs, 1, hs, PI)
					var pw: int = 1 if g < 0.4 else (3 if g < 0.7 else 5 if g < 0.9 else 7)
					R.call(cx - (pw >> 1), 9 - hs, pw, 1, C0)
					if pw >= 3:
						R.call(cx - (pw >> 1) + 1, 8 - hs, pw - 2, 1, C1)
						R.call(cx - (pw >> 1), 9 - hs, 1, 1, C2)
				elif fm == "racimo":   # tres sombreritos de un mismo pie, a distintas alturas
					hs = maxi(1, hs - 1)
					R.call(cx, 10 - hs, 1, hs, PI)
					R.call(cx, 9 - hs, 1, 1, C0)
					if g >= 0.4:
						R.call(cx - 1, 10 - hs, 1, 1, C2)
						R.call(cx + 1, 11 - hs, 1, 1, C0)
					if g >= 0.8:
						R.call(cx - 1, 9 - hs, 1, 1, C1)
						R.call(cx + 1, 10 - hs, 1, 1, C1)
				else:   # cúpula: la de siempre
					R.call(cx, 10 - hs, 1, hs, PI)
					R.call(cx - (cw >> 1), 9 - hs, cw, 1, C0)
					R.call(cx - maxi(0, (cw >> 1) - 1), 8 - hs, maxi(1, cw - 2), 1, C1)
					if cw >= 3:
						R.call(cx - (cw >> 1), 9 - hs, 1, 1, C2)
	# las gotas de la tapa: más cuanto más húmeda
	var nd: int = int(round(float(b.hum) / 100.0 * 9))
	for k in nd:
		R.call(1 + int(_hs(sid, k, 4) * 17), 1 + int(_hs(sid, k, 5) * 3), 1, 1, "rgba(225,242,255,0.75)")

func rects_bajo(V: Dictionary) -> Array:
	var o := []
	var x0: int = (SW - BAJO_W) >> 1
	var y0 := 4
	var B: Array = SL().bandejas if SL() != null else []
	# la pared del bajo y la bombilla
	o.append_array([[x0, y0, BAJO_W, BAJO_H, "#1a1814"], [x0 + 1, y0 + 1, BAJO_W - 2, BAJO_H - 2, "#24211c"],
		[x0 + 1, y0 + 1, 140, 30, "rgba(255,214,140,0.06)"], [x0 + 70, y0 + 1, 2, 3, "#3a3a40"], [x0 + 68, y0 + 4, 6, 4, "#ffe6a8"]])
	var nb := n_baldas()
	var pg: int = (V.i >> 1) / 3   # 1.51: de tres en tres estanterías (el bajo grande tiene nueve)
	if nb > 3:
		for q in ceili(nb / 3.0):
			o.append([x0 + 70 - 3 * ceili(nb / 3.0) + 6 * q, y0 + BAJO_H - 3, 4, 2, "#f8d040" if q == pg else "#5a5e66"])
	for r in 3:
		if 3 * pg + r >= nb:
			continue
		var rx: int = x0 + 4 + r * 46
		# la estantería: dos patas, la barra de arriba y dos baldas de rejilla
		o.append_array([[rx, y0 + 8, 2, 98, "#5a5e66"], [rx + 42, y0 + 8, 2, 98, "#5a5e66"], [rx + 1, y0 + 8, 1, 98, "#8a8e96"], [rx + 43, y0 + 8, 1, 98, "#8a8e96"],
			[rx, y0 + 8, 44, 2, "#8a8e96"]])
		for j in 2:
			var sy: int = y0 + (52 if j == 1 else 100)   # la cara de la balda: arriba (j = 1) y abajo (j = 0)
			o.append_array([[rx, sy, 44, 2, "#b8bcc4"], [rx, sy + 2, 44, 1, "#5a5e66"]])
			for gx in range(rx + 2, rx + 42, 3):
				o.append([gx, sy + 2, 1, 1, "#8a8e96"])
			var i: int = 2 * (3 * pg + r) + j
			var bx: int = rx + 3
			var by: int = sy - 31
			_bandeja_seta(o, B[i] if i < B.size() else null, bx, by, 2, i * 131 + (int(B[i].d) if i < B.size() else 0))
			if i < B.size() and not B[i].get("mala"):   # su humedad, debajo de la balda
				o.append_array([[bx, sy + 4, 38, 2, "#16161c"], [bx, sy + 4, Datos.jsround(38 * clampf(B[i].hum / 100.0, 0, 1)), 2, "#58a8e0" if B[i].hum >= 50 else "#e0a040"]])
			if i == V.i:
				o.append_array([[bx - 2, by - 2, 42, 1, "#f8d040"], [bx - 2, by + 30, 42, 1, "#f8d040"], [bx - 2, by - 2, 1, 33, "#f8d040"], [bx + 39, by - 2, 1, 33, "#f8d040"]])
	# a la derecha, la elegida en grande, su humedad y lo que lleva
	var px: int = x0 + 144
	o.append_array([[px, y0 + 4, 60, BAJO_H - 8, "#16161c"], [px + 1, y0 + 5, 58, BAJO_H - 10, "#20222a"]])
	var e = B[V.i] if V.i < B.size() else null
	_bandeja_seta(o, e, px + 1, y0 + 12, 3, V.i * 131 + (int(e.d) if e != null else 0))
	if e != null:
		var Z: Dictionary = D.SETAS
		var tot: float = Z.colon + Z.fruto
		var fp: float = 1.0 if e.get("mala") else clampf(t_seta(e) / tot, 0, 1)
		o.append_array([[px + 6, y0 + 66, 48, 4, "#0e0e12"], [px + 6, y0 + 66, Datos.jsround(48 * clampf(e.hum / 100.0, 0, 1)), 4, "#58a8e0" if e.hum >= 50 else "#e0a040"]])
		o.append_array([[px + 6, y0 + 76, 48, 4, "#0e0e12"], [px + 6, y0 + 76, Datos.jsround(48 * Z.colon / tot), 4, "#3a3830"],
			[px + 6, y0 + 76, Datos.jsround(48 * fp), 4, "#8a5a3a" if e.get("mala") else ("#e8e0d0" if fp < Z.colon / tot else "#c89060")]])
		o.append([px + 6 + Datos.jsround(48 * Z.colon / tot), y0 + 75, 1, 6, "#f0eee6"])
	return o

# ---------- el bajo entero (1.44, lo pidió el usuario: «donde se cultivan, se secan, almacenan y se crean microdosis y comestibles») ----
# Lo recogido se tiende a secar (S.setas.fr: [{g, d}]) en la malla (SETAS_PRO.seca días) o en el deshidratador (sech); seco, pasa al
# armario (S.setas.g, al amanecer en setas_dia). En la mesa de trabajo, con la encapsuladora (enc) o los moldes (mol), un lote de
# SETAS_PRO.lote g secos hace una caja de microdosis (mc) o de comestibles (cc); Txomin lo compra en la puerta. Nada de método ni de
# dosis: cajas y lotes. La redada (setas_dia) se lo lleva todo.
var ARM_V = null   # {}: el armario abierto

func dias_secar(L: Dictionary) -> int:
	return int(D.SETAS_PRO.sech if L.get("dh") else D.SETAS_PRO.seca)

func secar_setas(L = null) -> int:
	if L == null:
		L = SL()
	if L == null or not L.has("fr"):
		return 0
	var q := []
	var g := 0
	for f in L.fr:
		if int(S.day - f.d) >= dias_secar(L):
			g += int(f.g)
			if Datos.CAL:
				suma_gv(L, cepa_de(f), int(f.g))   # 1.46: lo seco, por cepa
		else:
			q.append(f)
	L.fr = q
	L.g += g
	return g

func txt_secando(o: String) -> String:
	var L: Dictionary = SL()
	var dh: bool = L.get("dh", false)
	if o == "secaS" and dh:
		return "La malla del secadero, sin usar: ahora secas en el deshidratador."
	var fr: Array = L.get("fr", [])
	var nm: String = "el deshidratador" if o == "deshidS" else "la malla del secadero"
	if fr.is_empty():
		return "%s está %s. Lo que recojas se seca aquí y pasa al armario." % [nm[0].to_upper() + nm.substr(1), "vacío" if o == "deshidS" else "vacía"]
	var g := 0
	var d: int = 1 << 30
	for f in fr:
		g += int(f.g)
		d = mini(d, int(f.d) + dias_secar(L))
	return "En %s, %s de setas secándose; las primeras pasan al armario el %s." % [nm, g_txt(g), Datos.fd(d, S.day)]

# lo lleno de cada piso del armario: 0 vacío, 1 a medias, 2 lleno (SETAS_PRO.lleno)
func lleno_arm(k: String) -> int:
	if S.get("setas") == null:
		return 0
	var v: float = float(S.setas.get(k, 0))
	var u: Array = D.SETAS_PRO.lleno[k]
	return 0 if v < float(u[0]) else (1 if v < float(u[1]) else 2)

func mesa_setas() -> void:
	var Z: Dictionary = D.SETAS_PRO
	while S.get("setas") != null:
		var L: Dictionary = S.setas
		var ops := []
		if L.get("enc"):
			ops.append("Microdosis (%d g)" % int(Z.lote))
		if L.get("mol"):
			ops.append("Comestibles (%d g + %s)" % [int(Z.lote), Datos.eur(Z.choco)])
		if Datos.CAL:   # 1.46: juntar micelios y el cuaderno de las cepas
			ops.append_array(["Juntar micelios", "El cuaderno"])
		if ops.is_empty():
			await say("La mesa de trabajo, con la báscula. Para las microdosis falta la encapsuladora y para los comestibles, los moldes: te los consigue Txomin, en la puerta.")
			return
		ops.append("Nada")
		var oi: int = await ask("La mesa de trabajo. En el armario, %s de setas secas." % g_txt(L.g), ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Nada":
			return
		if op == "Juntar micelios":
			await juntar_micelios()
			continue
		if op == "El cuaderno":
			await cuaderno_setas()
			continue
		var mc: bool = op.begins_with("Micro")
		if L.g < Z.lote:
			sfx("bad")
			await say("Hacen falta %d g de setas secas del armario." % int(Z.lote))
			continue
		if not mc and S.money < Z.choco:
			sfx("bad")
			await say("Sin %s no hay chocolate." % Datos.eur(Z.choco))
			continue
		L.g -= Z.lote
		if Datos.CAL:
			quita_gv(L, Z.lote)
		if not mc:
			S.money -= int(Z.choco)
		var kk: String = "mc" if mc else "cc"
		L[kk] = int(L.get(kk, 0)) + 1
		advance_time(int(Z.min[kk]))
		update_hud()
		sfx("get")
		await say("Llenas las cápsulas con la encapsuladora y cierras la cajita: una caja de microdosis, al armario." if mc else "Fundes el chocolate, llenas los moldes y, cuando enfría, los encajas: una caja de comestibles, al armario.")

func desc_armario() -> String:
	var L: Dictionary = S.setas
	var fr: Array = L.get("fr", [])
	var g := 0
	for f in fr:
		g += int(f.g)
	var cv := ""
	if Datos.CAL and L.g >= 1:   # 1.46: lo seco, por cepa
		var gv := gv_setas(L)
		var t := []
		for k in gv:
			if gv[k] >= 1:
				t.append("%s %s" % [nom_cepa(k), g_txt(gv[k])])
		cv = " (" + ", ".join(PackedStringArray(t)) + ")"
	return "Setas secas: %s%s · microdosis: %d · comestibles: %d.%s\nB: cerrar." % [g_txt(L.g), cv, int(L.get("mc", 0)), int(L.get("cc", 0)), (" Secándose, %s." % g_txt(g)) if g else ""]

func vista_armario() -> void:
	if gancho_bajo.is_valid():
		gancho_bajo.call(-1)
		return
	ARM_V = {}
	_dlg_fijo(desc_armario(), "EL ARMARIO")
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "B":
			pop()
			pr.res(null))
	await Motor.espera(pr)
	ARM_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()

# el armario por dentro: tres baldas de acero; arriba los botes de cristal (uno por cada 50 g), en medio las cajitas de las
# microdosis y abajo las cajas de los comestibles (hasta lo que cabe a la vista)
func rects_armario() -> Array:
	var o := []
	var L: Dictionary = S.setas if S.get("setas") != null else {}
	var w := 150
	var h := 108
	var x0: int = (SW - w) >> 1
	var y0 := 4
	o.append_array([[x0, y0, w, h, "#4a4e56"], [x0 + 2, y0 + 2, w - 4, h - 4, "#2e3036"], [x0, y0, w, 2, "#ccd0d6"], [x0, y0, 2, h, "#a8acb4"]])
	for j in 3:
		var sy: int = y0 + 34 + j * 34
		o.append_array([[x0 + 2, sy - 2, w - 4, 2, "#a8acb4"], [x0 + 2, sy, w - 4, 1, "#4a4e56"]])
	# los botes: 12 × 18 con la tapa negra y lo seco dentro
	var nb: int = mini(int(ceil(float(L.get("g", 0)) / 50.0)), 10)
	for k in nb:
		var bx: int = x0 + 6 + k * 14
		var by: int = y0 + 13
		o.append_array([[bx, by + 2, 12, 17, "#cfe2e6"], [bx + 9, by + 2, 3, 17, "#a6c0c6"], [bx, by, 12, 3, "#2a2a30"],
			[bx, by + 9, 12, 10, "#8a6a4a"], [bx + 2, by + 10, 2, 2, "#a8865a"], [bx + 6, by + 13, 3, 2, "#6a4a2a"], [bx + 3, by + 16, 2, 2, "#6a4a2a"]])
	# las cajitas de las microdosis: 9 × 13, blancas con la banda azul
	for k in mini(int(L.get("mc", 0)), 13):
		var bx: int = x0 + 5 + k * 11
		var by: int = y0 + 53
		o.append_array([[bx, by, 9, 13, "#f0f0ea"], [bx + 7, by, 2, 13, "#c8c8c0"], [bx, by + 3, 9, 2, "#4a7ac0"]])
	# las cajas de los comestibles: 16 × 9, cartón crema con la tapa de chocolate, de dos en dos
	for k in mini(int(L.get("cc", 0)), 16):
		var bx: int = x0 + 6 + (k % 8) * 17
		var by: int = y0 + 93 - (k / 8) * 10
		o.append_array([[bx, by, 16, 9, "#e8d8b8"], [bx, by, 16, 2, "#6a3a20"], [bx + 6, by + 4, 4, 2, "#8a4a28"]])
	return o

# ---------- el calendario y el mapa de la comarca (1.42, lo pidió el usuario; croquis.gd) ----------
var CAL_V = null    # {y, m}: el mes que se ve
var MAPA_V = null   # {i}: el pueblo elegido (Croquis.ORDEN)

# los días señalados: el plazo de Don Baltasar, los recibos, los encargos y la asamblea
func marcas_cal() -> Array:
	var r := []
	if S.get("due", 0) > 0 and S.get("deadline"):
		r.append({"d": int(S.deadline), "c": "#d03028", "t": "plazo de Don Baltasar (%s)" % Datos.eur(S.due)})
	for o in recibos():
		r.append({"d": int(o[1]), "c": "#3060c0", "t": "recibo de %s" % o[0]})
	if S.get("encargo") is Dictionary and S.encargo.get("hasta"):
		r.append({"d": int(S.encargo.hasta), "c": "#308040", "t": "encargo de Toño"})
	if S.get("clubEnc") is Dictionary and S.clubEnc.get("hasta"):
		r.append({"d": int(S.clubEnc.hasta), "c": "#308040", "t": "encargo del club"})
	if S.get("nave") != null and S.nave.get("op") is Dictionary and not S.nave.get("mia"):
		r.append({"d": int(S.day) if ventana_nave() else proxima_ventana(), "c": "#d08020", "t": "se puede comprar la nave"})
	if S.get("aso") is Dictionary and int(S.aso.get("asam", 0)):
		r.append({"d": int(S.aso.asam), "c": "#a050b0", "t": "asamblea de la asociación"})
	r.sort_custom(func(a, b): return a.d < b.d)
	return r

func elegir_cal() -> void:
	var f := Datos.fecha(int(S.day))
	CAL_V = {"y": int(f.y), "m": int(f.m)}
	var mk := marcas_cal()
	_dlg_fijo(Croquis.desc_cal(CAL_V, int(S.day), mk), "CALENDARIO")
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "B":
			pop()
			pr.res(null)
			return
		if Croquis.mueve_cal(CAL_V, b):
			sfx("sel")
			_dlg_fijo(Croquis.desc_cal(CAL_V, int(S.day), mk), "CALENDARIO"))
	await Motor.espera(pr)
	CAL_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()

func elegir_mapa() -> void:
	var aqui := Croquis.pueblo_de(S.map)
	MAPA_V = {"i": Croquis.ORDEN.find(aqui)}
	_dlg_fijo(Croquis.desc_mapa(D, int(S.ch), MAPA_V, aqui), "")   # 1.43: sin pestaña, que no pise el croquis
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "B":
			pop()
			pr.res(null)
			return
		if Croquis.mueve_mapa(MAPA_V, b):
			sfx("sel")
			_dlg_fijo(Croquis.desc_mapa(D, int(S.ch), MAPA_V, aqui), ""))   # 1.43: sin pestaña, que no pise el croquis
	await Motor.espera(pr)
	MAPA_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()

# ---------- las bandejas de clones de la nave (1.43, lo pidió el usuario: «en la nave debería haber bandejas de clones») ----------
# Antes de pasar una mesa a 12/12 (FLOR_MESA), su navero le corta los esquejes a las plantas en crecimiento y los pincha en una bandeja
# de D.NAVE.tacos tacos (S.nave.bc: {m: la mesa, k, f, d: el día del corte}), con su tapa, bajo los T5 del carro; enraízan en NAVE.raiz
# días (al ritmo del juego, como las mesas: un ciclo entero son unos pocos días) y, cuando la mesa se cosecha, vuelve a empezar con ellos. Las enraizadas también se plantan a mano en una mesa vacía
const FLOR_MESA := .65
const BANDEJAS_NAVE := 4

func corta_bandeja(i: int, Me: Dictionary) -> void:
	var N: Dictionary = S.nave
	if N.bc.size() >= BANDEJAS_NAVE or N.bc.any(func(b): return int(b.m) == i):
		return
	N.bc.append({"m": i, "k": Me.k, "f": Me.get("f"), "d": int(S.day)})

func bandeja_lista(b: Dictionary) -> bool:
	return int(S.day) - int(b.d) >= int(D.NAVE.raiz)

func bandejas_listas() -> Array:
	if S.get("nave") == null or not S.nave.has("bc"):
		return []
	return S.nave.bc.filter(func(b): return bandeja_lista(b))

func bandejas_nave() -> void:
	var N: Dictionary = S.nave
	if not N.has("bc") or N.bc.is_empty():
		await say("El carro de las bandejas de clones: dos baldas con sus tubos T5 y sus tapas. Vacío. Antes de pasar cada mesa a 12/12, quien la cuida le corta %d esquejes y aquí echan raíces en %s; con ellos, la mesa vuelve a empezar." % [int(D.NAVE.tacos), "un día" if int(D.NAVE.raiz) == 1 else "%d días" % int(D.NAVE.raiz)])
		return
	var rows := []
	for b in N.bc:
		var k := lot_sid(b.k)
		var s = strain(k)
		var faltan: int = int(D.NAVE.raiz) - (int(S.day) - int(b.d))
		rows.append({"label": "Mesa %d · %s" % [int(b.m) + 1, s.n], "right": "enraizada" if faltan <= 0 else ("%d d" % faltan), "sw": s.c, "ic": ic_cog(k),
			"desc": "%d esquejes de %s%s, cortados el %s, en tacos de turba con su tapa. %s" % [int(D.NAVE.tacos), s.n, etiq(b.get("f")), Datos.fd(int(b.d), S.day),
				"Ya tienen raíces: la mesa %d vuelve a empezar con ellos al cosecharse." % (int(b.m) + 1) if faltan <= 0 else "Les faltan %s para echar raíces." % ("un día" if faltan == 1 else "%d días" % faltan)]})
	rows.append({"label": "Volver", "desc": ""})
	await menu(rows, {"cls": "full", "title": "BANDEJAS DE CLONES", "title2": "%d de %d" % [N.bc.size(), BANDEJAS_NAVE], "desc": true})

# ---------- el concesionario (1.43, lo pidió el usuario) ----------
# AUTOS RIBERA abre en el barrio alto (montar_alto) con el capítulo CONCE.ch y CONCE.patri entre efectivo y cuenta. Precios con IVA;
# aparte, el impuesto de matriculación (IEDMT: por los g de CO2/km, sobre el precio sin IVA) y los gastos de gestoría y placas. En
# efectivo, como mucho CONCE.efe (Ley 11/2021); el resto, por transferencia. El seguro, domiciliado cada mes (recibos). La entrega,
# a los días de matricularlo; el deportivo, bajo pedido. Se revende con la depreciación (CONCE.dep). Con un vehículo vas de parada en
# parada a cualquier hora (conducir): con su gasolina y, a veces, un control de tráfico; la moto, además, por la calle (vehiculo)
func coches_mios() -> Array:
	var r := []
	for k in D.CONCE.orden:
		if coche_ya(k) and not S.coches[k].get("grua"):
			r.append(k)
	return r

func iedmt(k: String) -> int:
	var V: Dictionary = D.CONCE.v[k]
	if V.get("exenta"):
		return 0
	for t in D.CONCE.iedmt:
		if float(V.co2) <= float(t[0]):
			return roundi(float(V.p) / 1.21 * float(t[1]))
	return 0

func total_coche(k: String) -> int:
	return int(D.CONCE.v[k].p) + iedmt(k) + int(D.CONCE.gastos)

func seguro_anio(k) -> int:   # 1.43.2: la póliza, al año
	return int(D.CONCE.v[k].seg)

# lo que te paga el concesionario por el tuyo: el precio, menos lo que pierde al salir (dep.ya) y cada mes (dep.mes), hasta dep.min
func valor_coche(k: String) -> int:
	var c: Dictionary = S.coches[k]
	var dp: Dictionary = D.CONCE.dep
	var meses: int = maxi(0, int(S.day) - int(c.dia)) / int(D.CONCE.mes)
	return roundi(float(D.CONCE.v[k].p) * maxf(float(dp.min), 1.0 - float(dp.ya) - float(dp.mes) * meses))

func ficha_coche(k: String) -> String:
	var V: Dictionary = D.CONCE.v[k]
	var ie := iedmt(k)
	return "%s\n%s l/100 km · %d g CO2/km. Total %s (matriculación %s, gastos %s). Entrega en %d días.\nAl año: seguro %s e impuesto de circulación %s. Revisión cada %s km (%s) y neumáticos cada %s km (%s). Sin billete de autobús: solo la gasolina." % [V.d, Datos.coma(V.l), int(V.co2),
		Datos.eur(total_coche(k)), Datos.eur(ie) if ie else "exenta", Datos.eur(D.CONCE.gastos), int(V.entrega),
		Datos.eur(V.seg), Datos.eur(V.ivtm), Datos.miles(V.revKm), Datos.eur(V.rev), Datos.miles(V.neuKm), Datos.eur(V.neu)]

func _art_m(k: String) -> String:   # «la moto» → «a»; «el utilitario» → «o»
	return "a" if String(D.CONCE.v[k].art).begins_with("la ") else "o"

func ficha_expo(k: String) -> void:
	var V: Dictionary = D.CONCE.v[k]
	if S.get("coches") is Dictionary and S.coches.has(k):
		await say("%s, como %s tuy%s." % [mayus(V.art), V.art, _art_m(k)])
		return
	if await ask("%s · %s.\n%s" % [V.n, Datos.eur(V.p), V.d], ["Hablar con Arantxa", "Nada"]) == 0:
		await comprar_coche(k)

func talk_conce():
	var C: Dictionary = D.CONCE
	var i := 0
	while true:
		var it := []
		var tuyos := []
		var sin := []
		for k in C.orden:
			var V: Dictionary = C.v[k]
			var c = S.coches.get(k) if S.get("coches") is Dictionary else null
			if c != null and coche_ya(k):
				tuyos.append(k)
				if c.get("r") == null:
					sin.append(k)
			it.append({"label": V.n + (" · tuy" + _art_m(k) if c != null and coche_ya(k) else " · pedid" + _art_m(k) if c != null else ""), "right": Datos.eur(V.p), "desc": ficha_coche(k)})
		it.append({"label": "Vender", "disabled": tuyos.is_empty(), "desc": "Te lo recompran: pierde un %d %% al salir del concesionario y un %s %% cada mes, hasta el %d %% de lo que valía." % [roundi(C.dep.ya * 100), Datos.coma(C.dep.mes * 100), roundi(C.dep.min * 100)]})
		it.append({"label": "Asegurar", "disabled": sin.is_empty(), "desc": "Sin seguro no se puede circular: la multa es de %s y el vehículo, a la grúa." % Datos.eur(C.sinSeguro)})
		it.append({"label": "Nada", "desc": "Precios con IVA. Aparte, la matriculación por emisiones y %s de gestoría y placas." % Datos.eur(C.gastos)})
		i = await menu(it, {"cls": "full", "title": C.n, "title2": "Cuenta %s · efectivo %s" % [Datos.eur(S.banco), Datos.eur(S.money)], "desc": true, "initial": i})
		var no: int = C.orden.size()
		if i < 0 or i >= no + 2:
			if S.get("coches") is Dictionary and not S.coches.is_empty():
				await say("Cualquier cosa, aquí estamos. Y ojo con la ITV.", "ARANTXA")
			return
		if i < no:
			await comprar_coche(C.orden[i])
		elif i == no:
			await vender_coche(tuyos)
		else:
			await asegurar_coche(sin)

func comprar_coche(k: String) -> void:
	var A := "ARANTXA"
	var C: Dictionary = D.CONCE
	var V: Dictionary = C.v[k]
	if S.get("coches") is Dictionary and S.coches.has(k):
		await say(("%s ya es tuy%s." % [mayus(V.art), _art_m(k)]) if coche_ya(k) else ("%s está en camino: te aviso por SMS." % mayus(V.art)), A)
		return
	var tot := total_coche(k)
	var sm := seguro_anio(k)
	var efe: int = mini(mini(int(S.money), int(C.efe)), tot)
	var tr: int = tot - efe
	if await ask("%s: %s en total. %s en efectivo, que más no deja la ley, y %s por transferencia; el seguro, %s al año, domiciliado. ¿Lo firmas?" % [V.n, Datos.eur(tot), Datos.eur(efe), Datos.eur(tr), Datos.eur(sm)], ["Firmar", "No"], A) != 0:
		return
	if S.banco < tr + sm:
		sfx("bad")
		await say("Con la transferencia y el primer año del seguro hacen falta %s en tu cuenta, y hay %s. Lo dejamos reservado si quieres." % [Datos.eur(tr + sm), Datos.eur(S.banco)], A)
		return
	S.money -= efe
	cobro_banco(tr, C.n + " · " + V.n)
	cobro_banco(sm, "Seguro · " + V.n)
	if not (S.get("coches") is Dictionary):
		S.coches = {}
	S.coches[k] = {"dia": int(S.day) + int(V.entrega), "p": tot, "r": int(S.day) + int(V.entrega) + int(C.anio), "iv": int(S.day) + int(V.entrega), "km": 0}
	if V.calor:
		S.heat = mini(100, int(S.heat) + int(V.calor))
	sfx("coin")
	update_hud()
	await say("Firmado. %s, a tu nombre: en %d días está matriculad%s y te aviso por SMS.%s" % [mayus(V.art), int(V.entrega), _art_m(k), " Lo traen bajo pedido de fábrica." if k == "deportivo" else ""], A)

func vender_coche(l: Array) -> void:
	var A := "ARANTXA"
	var it := []
	for k in l:
		it.append({"label": D.CONCE.v[k].n, "right": Datos.eur(valor_coche(k)), "desc": "Pagaste %s y lleva %s km. Te damos %s, por transferencia." % [Datos.eur(S.coches[k].p), Datos.miles(S.coches[k].get("km", 0)), Datos.eur(valor_coche(k))]})
	it.append({"label": "Nada", "desc": ""})
	var j: int = await menu(it, {"cls": "full", "title": "VENDER", "desc": true})
	if j < 0 or j >= l.size():
		return
	var k: String = l[j]
	var v := valor_coche(k)
	if await ask("Por %s te damos %s. ¿Trato hecho?" % [D.CONCE.v[k].art, Datos.eur(v)], ["Vender", "No"], A) != 0:
		return
	S.coches.erase(k)
	abono_banco(v, D.CONCE.n + " · venta")
	sfx("coin")
	update_hud()
	await say("Hecho: %s en tu cuenta. El seguro se da de baja hoy." % Datos.eur(v), A)

func asegurar_coche(l: Array) -> void:
	var k: String = l[0]
	var sm := seguro_anio(k)
	if not cobro_banco(sm, "Seguro · " + D.CONCE.v[k].n):
		sfx("bad")
		await say("El año de póliza son %s, de la cuenta, y no hay." % Datos.eur(sm), "ARANTXA")
		return
	S.coches[k].r = int(S.day) + int(D.CONCE.anio)
	S.coches[k].erase("grua")
	sfx("coin")
	await say("Póliza en vigor: %s al año, domiciliado.%s" % [Datos.eur(sm), " Y te saco %s del depósito de la grúa." % D.CONCE.v[k].art], "ARANTXA")

# cada mañana: la apertura (con el capítulo y el dinero), las entregas y el seguro de cada uno; sin pagar, la póliza se anula
func conce_dia() -> void:
	if not Datos.CAL:   # contra el HTML congelado (1.37), nada
		return
	var C: Dictionary = D.CONCE
	if S.flags.get("conce") == null and int(S.ch) >= int(C.ch) and float(S.money) + float(S.banco) >= float(C.patri):
		S.flags.conce = S.day
		if S.map == "alto":
			montar_alto()
		queue("conce", func(): await talk("SMS · " + C.n, [C.txt.abre]))
	if not (S.get("coches") is Dictionary):
		return
	for k in C.orden:
		var c = S.coches.get(k)
		if c == null:
			continue
		var V: Dictionary = C.v[k]
		if int(c.dia) == int(S.day):
			var tx: String = "%s ya está matriculad%s y con el seguro en vigor. Desde cualquier parada de autobús puedes ir en %s, a la hora que quieras.%s" % [mayus(V.art), _art_m(k), "ella" if _art_m(k) == "a" else "él", " Y en la calle, montado." if k == "moto" else " Y en la calle, al volante." if D.VEHICULOS.has(k) else ""]
			queue("coche" + k, func(): await talk("SMS · " + C.n, [tx]))
		if c.get("r") != null and not cobra(c, seguro_anio(k), "ASEGURADORA", true, "seguro de " + String(V.art), int(C.anio)):
			c.r = null
			var tx2: String = "Póliza anulada por impago: %s ya no tiene seguro. Sin seguro no se puede circular." % V.art
			queue("seg" + k, func(): await talk("SMS · ASEGURADORA", [tx2]))
		if c.get("iv") == null:   # de antes de la 1.43.2
			c.iv = maxi(int(c.dia), int(S.day))
		if not cobra(c, float(V.ivtm), "AYUNTAMIENTO", true, "impuesto de circulación de " + String(V.art), int(C.anio), "iv"):   # sin pagar, por apremio con recargo
			var e: float = roundf(float(V.ivtm) * (1.0 + float(C.recargo)))
			pagar_recibo(e, "Apremio · IVTM · " + String(V.n))
			c.iv = int(c.iv) + int(C.anio)
			var tx3: String = "Providencia de apremio: el impuesto de circulación de %s, con un %d %% de recargo, %s, cobrado de lo que tienes." % [V.art, roundi(float(C.recargo) * 100), Datos.eur(e)]
			queue("iv" + k, func(): await talk("SMS · AYUNTAMIENTO", [tx3]))

# de parada en parada con tu vehículo (CONCE.km de cada una; CONCE.v[k].t del tiempo del autobús, sin esperas)
func tramo(a: String, b: String, k: String) -> Dictionary:
	var V: Dictionary = D.CONCE.v[k]
	var km: int = int(D.CONCE.km[a]) + int(D.CONCE.km[b])
	return {"km": km, "min": maxi(5, roundi(viaje(a, b).min * float(V.t))), "eur": maxi(1, roundi(km * float(V.l) / 100.0 * float(D.CONCE.litro)))}

func conducir(k):
	var aqui: String = S.map
	var ds := []
	for x in D.PARADAS:
		if x != aqui and S.ch >= int(D.PARADAS[x].cap):
			ds.append(x)
	var it := []
	for x in ds:
		var t := tramo(aqui, x, k)
		it.append({"label": D.PARADAS[x].n, "right": "%d min · %s" % [t.min, Datos.eur(t.eur)]})
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿A dónde vas?"})
	if i < 0 or i >= ds.size():
		return
	var x: String = ds[i]
	var t := tramo(aqui, x, k)
	if S.money >= t.eur:   # la gasolina: en efectivo o con tarjeta
		S.money -= t.eur
	elif not cobro_banco(t.eur, "Gasolinera"):
		sfx("bad")
		await say("Para la gasolina hacen falta %s y no te llega." % Datos.eur(t.eur))
		return
	var taller := kilometros(k, int(t.km))
	sfx("door")
	await fade(1)
	await anim_viaje(k, aqui, x, int(t.min))
	advance_time(t.min)
	var a: Array = D.PARADAS[x].a
	enter_map(x, int(a[0]), int(a[1]), a[2])
	if S.clientsDay != S.day:
		spawn_clients()
	update_hud()
	await wait(80)
	await fade(0)
	if taller != "":
		sfx("bad")
		await talk("SMS · TALLER", [taller])
	await control_trafico(k)

# 1.43.2: los km de cada vehículo; al pasar cada CONCE.v[k].revKm, la revisión (aceite y filtros), y cada neuKm, los neumáticos
func kilometros(k: String, km: int) -> String:
	var V: Dictionary = D.CONCE.v[k]
	var c: Dictionary = S.coches[k]
	var a: int = int(c.get("km", 0))
	c.km = a + km
	var tx := []
	for q in [["rev", "revKm", "la revisión de %s km (aceite y filtros)"], ["neu", "neuKm", "neumáticos nuevos a los %s km"]]:
		var n: int = int(c.km) / int(V[q[1]]) - a / int(V[q[1]])
		if n > 0:
			var e: float = float(V[q[0]]) * n
			var f := pagar_recibo(e, "Taller · " + String(V.n))
			tx.append("%s: %s%s" % [String(q[2]) % Datos.miles(int(c.km) / int(V[q[1]]) * int(V[q[1]])), Datos.eur(e), (" (te quedan a deber %s)" % Datos.eur(f)) if f > 0 else ""])
	return ("%s, en el taller. " % mayus(V.art) + ". ".join(tx) + ".") if tx.size() else ""

# el control de tráfico (CONCE.control; el deportivo, el triple): el seguro y, si te registran, lo que lleves encima
func control_trafico(k: String) -> void:
	var C: Dictionary = D.CONCE
	if Cultivo.azar() >= float(C.control) * (3.0 if k == "deportivo" else 1.0):
		return
	var V: Dictionary = C.v[k]
	sfx("bad")
	await say("Control de tráfico a la entrada. «Buenas. Carné, permiso de circulación y el seguro de %s.»" % V.art, "AGENTE")
	if S.coches[k].get("r") == null:
		var f: float = pagar_recibo(float(C.sinSeguro), "Multa · sin seguro")
		S.coches[k].grua = true
		await say("Sin seguro en vigor: denuncia de %s%s y %s, a la grúa hasta que lo asegures." % [Datos.eur(C.sinSeguro), (" (te faltan %s)" % Datos.eur(f)) if f > 0 else "", V.art], "AGENTE")
	if total_buds() < 1 and total_rosin() <= 0:
		await say("«Todo en orden. Circule.»", "AGENTE")
		return
	if Cultivo.azar() >= .5 + float(S.heat) / 200.0:
		await say("Te mira un rato. «Circule.»", "AGENTE")
		return
	var r := confiscate()
	S.heat = mini(100, int(S.heat) + 10)
	update_hud()
	await say("«¿Y este olor?» Te registran %s: te requisan %s y te multan con %s." % [V.art, r[0], Datos.eur(r[1])], "AGENTE")

# ---------- 1.51: el muelle de Puerto Viejo, los envíos por mar y el piso franco ----------
# (lo pidió el usuario: «distribución a gran escala por un piso franco o una persona… un mini puerto para hacer envíos, invertir en un
# barco, empezando por uno pequeño… algo adictivo cuando ya lo tienes todo, continuando la trama»). Desde el capítulo MAR.ch: Koldo, el
# amigo de la tía Maite, te da su txalupa; los envíos zarpan del noray de cada barco hacia las rutas que abre la reputación; el
# primero que llega abre el piso franco de Gorka, que reparte por tierra lo que le dejes; cada semana, un pedido con prima, y al
# final, el último trabajo de Koldo. Lo de cada día, en mar_dia y franco_dia (desde curro_dia).

func mar_ok() -> bool:
	return Datos.CAL and D.has("MAR") and S.get("mar") is Dictionary

# «la txalupa…» → «La txalupa…» (capitalize() pone en mayúscula cada palabra)
static func may1(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)

func barco_k(k: String) -> Dictionary:
	for B in D.MAR.barcos:
		if B.k == k:
			return B
	return {}

func rutas_mar() -> Array:
	var o := []
	for i in D.MAR.rutas.size():
		if float(S.mar.rep) >= float(D.MAR.rutas[i].rep):
			o.append(i)
	return o

func rango_mar() -> String:
	var r: String = D.MAR.rangos[0][1]
	for x in D.MAR.rangos:
		if float(S.mar.kg) >= float(x[0]):
			r = x[1]
	return r

func en_mar(k: String):
	for e in S.mar.env:
		if e.b == k:
			return e
	return null

func cap_mar() -> int:
	var c := 0
	for k in S.mar.b:
		c = maxi(c, int(barco_k(k).kg))
	return c

func _ped_txt(p: Dictionary) -> String:
	return "%s a %s, de %d %% de THC o más, antes del %s" % [_kg(int(p.g)), D.MAR.rutas[int(p.r)].n, int(p.thc), Datos.fd(int(p.d), S.day)]

func talk_koldo() -> void:
	var R: Dictionary = D.MAR
	var N := "KOLDO"
	if S.get("mar") == null:
		await talk(N, ["Tú eres el sobrino de Maite. Tienes su cara cuando se reía de los guardias.",
			"En los ochenta, tu tía y yo traíamos semillas de fuera en mi txalupa. Las primeras landraces de la comarca llegaron por este muelle.",
			"La txalupa sigue ahí, en el primer noray. Se llama Maite: se la puse yo. Ahora es tuya.",
			"Cargas en el noray, eliges la ruta y zarpas. A la vuelta, te pagan por transferencia de una conservera, %s: limpio." % R.empresa,
			"Pequeño al principio: %s como mucho. Y no menos de %s por viaje, que el gasoil no es gratis." % [_kg(int(barco_k("txalupa").kg) * 1000), _kg(int(R.min))]])
		S.mar = {"b": ["txalupa"], "rep": 0, "kg": 0.0, "env": [], "ped": null, "pd": 0, "paso": 0, "fin": 0, "n": 0}
		confia("koldo", 10)
		montar_muelle(S.map)
		build_ents()
		sfx("get")
		return
	var i := 0
	while true:
		var M_: Dictionary = S.mar
		var ops := ["Los envíos en el mar", "El pedido de la semana", "Las rutas", "Comprar un barco"]
		if R.has("obras"):
			ops.append("Las obras del muelle")
		if int(M_.get("ley", 0)) > 0:
			ops.append("La distribuidora" if M_.get("lic") else "La licencia")
		var gran: bool = not M_.get("fin") and float(M_.rep) >= float(R.gran.rep) and ("pesquero" in M_.b or "atunero" in M_.b)
		if gran:
			ops.append("El último trabajo")
		ops.append("Nada")
		i = await ask("%s · %s exportados · reputación %d." % [rango_mar(), _kg(int(float(M_.kg) * 1000)), int(M_.rep)], ops, N)
		var l: String = ops[i] if i >= 0 else "Nada"
		if l == "Nada":
			await say("Ondo ibili. Que el mar te sea leve.", N)
			return
		if l == "Los envíos en el mar":
			if M_.env.is_empty():
				await say("Ahora mismo no tienes nada en el mar. Se carga en el noray de cada barco.", N)
			else:
				var L := []
				for e in M_.env:
					L.append("%s, a %s con %s: llega el %s." % [may1(barco_k(e.b).n), R.rutas[int(e.r)].n, _kg(int(e.g)), Datos.fd(int(e.d), S.day)])
				await talk(N, L)
		elif l == "El pedido de la semana":
			if M_.ped is Dictionary:
				await say("Esta semana piden %s. Si lo cumples, pagan un %d %% más." % [_ped_txt(M_.ped), Datos.jsround((float(R.ped.bonus) - 1) * 100)], N)
			elif int(M_.paso) < 1:
				await say("Primero, un viaje que salga bien. Luego te presento a la gente de fuera.", N)
			else:
				await say("Esta semana no hay pedido. Los lunes suelen llamar.", N)
		elif l == "Las rutas":
			var L := []
			for j in R.rutas.size():
				var rt: Dictionary = R.rutas[j]
				L.append(("%s: %d %s más de viaje, pagan ×%s." % [rt.n, int(rt.d), "día" if int(rt.d) == 1 else "días", Datos.coma(float(rt.px))]) if float(M_.rep) >= float(rt.rep) else ("%s: con reputación %d." % [rt.n, int(rt.rep)]))
			await talk(N, L)
		elif l == "Comprar un barco":
			await comprar_barco(N)
		elif l == "Las obras del muelle":
			await obras_muelle(N)
		elif l == "La licencia":
			await licencia_mar(N)
		elif l == "La distribuidora":
			await vender_legal(N)
		elif l == "El último trabajo":
			await say("Un armador de %s quiere %s en un solo viaje, y lo paga como nadie. Es el trabajo que tu tía y yo nunca nos atrevimos a hacer. Si sale, el muelle es tuyo." % [R.rutas[int(R.gran.ruta)].n, _kg(int(R.gran.kg) * 1000)], N)
			M_.gr = 1

func comprar_barco(N: String) -> void:
	var ops := []
	var bs := []
	for B in D.MAR.barcos:
		if not B.k in S.mar.b:
			ops.append("%s · %s" % [may1(B.n), Datos.eur(B.p)])
			bs.append(B)
	if bs.is_empty():
		await say("Ya tienes la flota entera. Ni la cofradía tiene tantos.", N)
		return
	ops.append("Nada")
	var j: int = await ask("Barcos de segunda mano de la cofradía. Se pagan por transferencia.", ops, N)
	if j < 0 or j >= bs.size():
		return
	var B: Dictionary = bs[j]
	if B.get("req") and not obra_ya(B.req):
		await say("%s no cabe en el muelle tal como está. Antes, %s: %s" % [may1(B.n), obra_k(B.req).n, obra_k(B.req).txt], N)
		return
	if not await confirm("%s: %s, carga hasta %s, %d días de viaje. ¿Lo compras?" % [may1(B.n), Datos.eur(B.p), _kg(int(B.kg) * 1000), int(B.dias)]):
		return
	if not cobro_banco(float(B.p), "Compra · " + B.n):
		await say("En la cuenta no llega. Con el banco no se discute.", N)
		return
	S.mar.b.append(B.k)
	montar_muelle("muelle")
	sfx("get")
	await say("Hecho. Lo amarro en su noray esta misma tarde.", N)

func confirm(t: String) -> bool:
	return await ask(t, ["Sí", "No"]) == 0

# A en el noray: el barco de ese amarre
func mar_noray(x: int) -> void:
	var B := {}
	for b in D.MAR.barcos:
		if int(b.nor) == x:
			B = b
	if B.is_empty():
		await say("Un noray de hierro, gastado por los cabos.")
		return
	if S.get("mar") == null:
		await say("Un noray de la cofradía. Koldo, el viejo de la acera, sabe de quién es cada amarre.")
		return
	if not B.k in S.mar.b:
		await say("Amarre libre. Aquí cabe %s: Koldo lo vende por %s." % [B.n, Datos.eur(B.p)])
		return
	var e = en_mar(B.k)
	if e != null:
		await say("%s está en el mar, camino de %s. Vuelve el %s." % [may1(B.n), D.MAR.rutas[int(e.r)].n, Datos.fd(int(e.d), S.day)])
		return
	await cargar_envio(B)

func cargar_envio(B: Dictionary) -> void:
	var R: Dictionary = D.MAR
	var rs := rutas_mar()
	var ops := []
	for j in rs:
		var rt: Dictionary = R.rutas[j]
		ops.append({"label": rt.n, "right": "×" + Datos.coma(float(rt.px)), "desc": "%d días de viaje con %s." % [int(B.dias) + int(rt.d), B.n]})
	ops.append({"label": "Nada"})
	var ir: int = await menu(ops, {"cls": "right", "title": "¿A dónde?", "desc": true})
	if ir < 0 or ir >= rs.size():
		return
	var ri_: int = rs[ir]
	var carga := []   # [k, g, thc, calidad]
	var tot := 0
	var cap: int = int(B.kg) * 1000
	while true:
		var lots := bud_lots(1)
		lots = lots.filter(func(l): return carga.all(func(c): return c[0] != l[0]))
		var it := lots.map(venta_item)
		if tot >= int(R.min):
			it.append({"label": "Zarpar (%s)" % _kg(tot)})
		it.append({"label": "Nada"})
		var i: int = await menu(it, {"cls": "right", "title": "La carga · %s de %s" % [_kg(tot), _kg(cap)]})
		if i >= 0 and i < lots.size():
			var l: Array = lots[i]
			var g = await cuanto("¿Cuánto de %s?" % lot_nombre(l[0]), mini(int(floor(l[1].g)), cap - tot), [250, 500, 1000, 2000, 5000, 10000, 20000], func(v): return _kg(int(v)))
			if g > 0:
				carga.append([l[0], int(g), float(l[1].thc), calidad(l[1])])
				tot += int(g)
			if tot >= cap:
				await say("La bodega va llena.")
			continue
		if i == lots.size() and tot >= int(R.min):
			break
		return
	if tot < int(R.min):
		return
	var rt: Dictionary = R.rutas[ri_]
	var P_ = S.mar.ped
	var ped: bool = P_ is Dictionary and int(P_.r) == ri_ and tot >= int(P_.g) and S.day <= int(P_.d) and carga.all(func(c): return c[2] >= float(P_.thc))
	var gr: bool = S.mar.get("gr") and not S.mar.get("fin") and ri_ == int(R.gran.ruta) and tot >= int(R.gran.kg) * 1000
	var e := 0.0
	for c in carga:
		e += precio_mayor(c[2]) * c[3] * float(rt.px) * c[1]
		use_buds(c[0], c[1])
	if ped:
		e *= float(R.ped.bonus)
		S.mar.ped = null
	var pm: float = float(B.r) + float(rt.r) + float(S.heat) / 1000.0
	if obra_ya("caseta"):   # 1.52: la caseta de la cofradía vigila el muelle
		pm *= float(obra_k("caseta").r)
	var mal: bool = Cultivo.azar() < pm and not gr
	S.mar.env.append({"b": B.k, "r": ri_, "g": tot, "e": Datos.jsround(e), "d": S.day + int(B.dias) + int(rt.d), "mal": mal, "ped": ped, "gr": gr})
	sfx("get")
	update_hud()
	await say("Sueltas amarras. %s sale hacia %s con %s: llega el %s." % [may1(B.n), rt.n, _kg(tot), Datos.fd(S.day + int(B.dias) + int(rt.d), S.day)] + (" Es el pedido de la semana." if ped else "") + (" El último trabajo de Koldo." if gr else ""))

func mar_dia() -> void:
	if not mar_ok():
		return
	var R: Dictionary = D.MAR
	var M_: Dictionary = S.mar
	var quedan := []
	for e in M_.env:
		if S.day < int(e.d):
			quedan.append(e)
			continue
		var B := barco_k(e.b)
		var dest: String = R.rutas[int(e.r)].n
		if e.mal:
			S.heat = mini(100, int(S.heat) + int(R.calor))
			queue("mar" + e.b, func(): await talk("SMS · KOLDO", ["Malas noticias: la patrullera paró a %s antes de %s. Se han quedado la carga; el barco lo saco yo con la cofradía. Tranquilo unos días." % [B.n, dest]]))
			continue
		abono_banco(float(e.e), "Transferencia · " + R.empresa)
		S.sales += int(e.e)
		M_.kg = float(M_.kg) + float(e.g) / 1000.0
		M_.rep = float(M_.rep) + float(e.g) / 1000.0 + (float(R.ped.rep) if e.ped else 0.0)
		M_.n = int(M_.n) + 1
		var lin := ["%s ha llegado a %s. %s ha transferido %s." % [may1(B.n), dest, R.empresa, Datos.eur(e.e)] + (" Con la prima del pedido." if e.ped else "")]
		if int(M_.paso) < 1:
			M_.paso = 1
			M_.pd = S.day
			lin.append("Ya tienes nombre fuera. Mi sobrino Gorka mueve cantidad por tierra: tiene un piso franco en el muelle, la puerta de la casa amarilla. Pásate.")
		if e.get("gr"):
			M_.fin = S.day
			abono_banco(float(R.gran.premio), "Prima · " + R.empresa)
			lin.append("Lo has hecho. Treinta años soñándolo y lo has hecho tú. Me retiro: el muelle es tuyo, y la cofradía ya lo sabe.")
			lin.append("Maite estaría orgullosa. Y un poco celosa.")
		queue("mar" + e.b, func(): await talk("SMS · KOLDO", lin))
	M_.env = quedan
	obras_dia()
	# el pedido de la semana: desde el primer viaje, cada 7 días
	if int(M_.paso) >= 1 and S.day >= int(M_.get("pd", 0)):
		var rs := rutas_mar()
		var r: int = rs[ri(0, rs.size() - 1)]
		var g: int = clampi(ri(1, cap_mar()), 1, 40) * 1000
		M_.ped = {"r": r, "g": maxi(g, int(R.min)), "thc": ri(int(R.ped.thc[0]), int(R.ped.thc[1])), "d": S.day + int(R.ped.dias)}
		M_.pd = S.day + int(R.ped.dias)
		var P_: Dictionary = M_.ped
		queue("marPed", func(): await talk("SMS · KOLDO", ["Pedido de la semana: %s. Pagan un %d %% más." % [_ped_txt(P_), Datos.jsround((float(R.ped.bonus) - 1) * 100)]]))

# el piso franco de Gorka: lo que dejas en el alijo, lo reparte por tierra cada mañana
func talk_gorka() -> void:
	var FR: Dictionary = D.FRANCO
	var N := "GORKA"
	var F = S.get("franco")
	if not F is Dictionary:
		await say("Así que tú eres el de la txalupa. Koldo dice que eres de fiar.", N)
		var j: int = await ask("El piso es %s al mes, en efectivo. Lo que me dejes en las cajas, lo reparto yo por tierra, al por mayor: %s al día, y me quedo el %d %%." % [Datos.eur(FR.alq), _kg(int(FR.dia[0])), Datos.jsround(float(FR.com) * 100)], ["Alquilar el piso", "Nada"], N)
		if j != 0:
			return
		if S.money < float(FR.alq):
			await say("Sin el primer mes por delante, nada.", N)
			return
		S.money -= float(FR.alq)
		S.franco = {"r": S.day + int(FR.per), "buds": {}, "caja": 0, "cal": 0.0, "niv": 0, "v": 0}
		confia("gorka", 5)
		update_hud()
		sfx("get")
		await say("Trato. Las cajas de la izquierda son el alijo: deja ahí el género y pasa a por la caja cuando quieras.", N)
		return
	while true:
		var ops := ["Cómo va", "Recoger la caja (%s)" % Datos.eur(F.caja)]
		var nv: int = int(F.niv)
		if nv < FR.mej.size():
			ops.append("%s · %s" % [FR.mej[nv].n, Datos.eur(FR.mej[nv].p)])
		ops.append("Dejar el piso")
		ops.append("Nada")
		var i: int = await ask("Reparto hasta %s al día. En el alijo hay %s." % [_kg(int(FR.dia[nv])), _kg(int(stock_franco()))], ops, N)
		var l: String = ops[i] if i >= 0 else "Nada"
		if l == "Nada":
			return
		if l == "Cómo va":
			var cal: int = int(F.cal)
			await say("Ayer moví %s. La calle está %s. El alquiler, el %s." % [_kg(int(F.get("v", 0))), "tranquila" if cal < 40 else ("caliente" if cal < 70 else "que arde: afloja o nos cae una"), Datos.fd(int(F.r), S.day)], N)
		elif l.begins_with("Recoger"):
			if int(F.caja) < 1:
				await say("Hoy no hay nada que recoger.", N)
			else:
				S.money += int(F.caja)
				await say("Aquí tienes: %s, contados." % Datos.eur(F.caja), N)
				F.caja = 0
				update_hud()
				sfx("get")
		elif l == "Dejar el piso":
			if await confirm("¿Dejas el piso franco? Lo que haya en el alijo y en la caja te lo llevas tú."):
				for k in F.buds.keys():
					mover_lote(F.buds, S.buds, k, F.buds[k].g)
				S.money += int(F.caja)
				S.franco = null
				update_hud()
				await say("Tú sabrás. Si vuelves, aquí estoy.", N)
				return
		elif nv < FR.mej.size():
			var mj: Dictionary = FR.mej[nv]
			if not await confirm("%s: %s. %s" % [mj.n, Datos.eur(mj.p), mj.d]):
				continue
			if S.money < float(mj.p):
				await say("Eso va en efectivo, y no lo llevas.", N)
				continue
			S.money -= float(mj.p)
			F.niv = nv + 1
			update_hud()
			sfx("get")
			await say("Hecho. %s" % mj.d, N)

func stock_franco() -> float:
	var t := 0.0
	var F = S.get("franco")
	if F is Dictionary:
		for k in F.buds:
			t += float(F.buds[k].g)
	return t

# las cajas del alijo, en el piso franco
func alijo_franco() -> void:
	var F = S.get("franco")
	if not F is Dictionary:
		await say("Cajas de fruta vacías. Aquí se guarda el género, si alquilas el piso: habla con Gorka.")
		return
	var FR: Dictionary = D.FRANCO
	while true:
		var lots := bud_lots(1)
		var it := lots.map(venta_item)
		it.append({"label": "Nada"})
		var i: int = await menu(it, {"cls": "right", "title": "Al alijo · %s de %s" % [_kg(int(stock_franco())), _kg(int(FR.cap))]})
		if i < 0 or i >= lots.size():
			return
		var l: Array = lots[i]
		var mx: int = mini(int(floor(l[1].g)), int(FR.cap - stock_franco()))
		if mx < 1:
			await say("El alijo está lleno.")
			return
		var g = await cuanto("¿Cuánto de %s dejas?" % lot_nombre(l[0]), mx, [100, 250, 500, 1000, 2000, 5000], func(v): return _kg(int(v)))
		if g > 0:
			mover_lote(S.buds, F.buds, l[0], g)
			sfx("get")
			update_hud()

func franco_dia() -> void:
	var F = S.get("franco")
	if not Datos.CAL or not F is Dictionary:
		return
	var FR: Dictionary = D.FRANCO
	if not cobra(F, float(FR.alq), "GORKA", false, "el piso franco", int(FR.per)):
		S.franco = null
		queue("franco", func(): await talk("SMS · GORKA", ["Sin alquiler no hay piso. Lo del alijo cubre lo que debes. Si vuelves con dinero, hablamos."]))
		return
	var cap: int = int(FR.dia[int(F.niv)])
	var ks: Array = F.buds.keys()
	ks.sort_custom(func(a, b): return float(F.buds[a].thc) > float(F.buds[b].thc))
	var v := 0
	for k in ks:
		if v >= cap:
			break
		var b: Dictionary = F.buds[k]
		var g: int = mini(int(floor(b.g)), cap - v)
		if g < 1:
			continue
		var e := Datos.jsround(precio_mayor(b.thc) * calidad(b) * float(FR.px) * g * (1 - float(FR.com)))
		F.caja = int(F.caja) + e
		S.sales += e
		b.g -= g
		v += g
		if b.g < .5:
			F.buds.erase(k)
	F.v = v
	F.cal = maxf(0, minf(100, float(F.cal) + v * float(FR.cal.g)) - float(FR.cal.baja))
	if F.cal >= float(FR.cal.redada):
		var perdido: float = stock_franco()
		var caja: int = int(F.caja)
		F.buds = {}
		F.caja = 0
		F.cal = float(FR.cal.vuelve)
		queue("franco", func(): await talk("SMS · GORKA", ["Han entrado en el piso. Yo estaba fuera. Se han llevado %s y %s de la caja. Habrá que aflojar." % [_kg(int(perdido)), Datos.eur(caja)]]))

# ---------- 1.52: las obras del muelle, el club KAIA y la ley ----------
# (lo pidió el usuario: «el barrio del puerto viejo… comenzar destartalado… ir reformándolo poco a poco, edificio por edificio… para
# meter un barco más grande se tiene que reformar el espacio… montar otro club ahí… una legalización del cannabis en España que
# abriría un mercado mucho mayor»). Las obras (MAR.obras) se pagan por el banco y se acaban a los d días (S.mar.ob: el día en que
# acaba cada una; S.mar.oba: las ya avisadas); el pesquero pide el pantalán y el atunero, el dique; las casas dan alquiler cada
# semana; el club KAIA despacha lo que le dejas (S.mar.kaia); MAR.legal.dias después de abrirlo, la ley (S.mar.ley): con la
# licencia (S.mar.lic), la distribuidora compra hasta MAR.legal.dia al día, sin calor y por el banco, y KAIA despacha más.

func obra_k(k: String) -> Dictionary:
	for O in D.MAR.get("obras", []):
		if O.k == k:
			return O
	return {}

func obras_muelle(N: String) -> void:
	var R: Dictionary = D.MAR
	var M_: Dictionary = S.mar
	if not (M_.get("ob") is Dictionary):
		M_.ob = {}
	while true:
		var it := []
		for O in R.obras:
			var r: String = "hecha" if obra_ya(O.k) else ("en obras" if M_.ob.has(O.k) else Datos.eur(O.p))
			var falta: String = (" Antes, %s." % obra_k(O.req).n) if O.get("req") and not obra_ya(O.req) else ""
			it.append({"label": may1(O.n), "right": r, "desc": O.txt + falta})
		it.append({"label": "Nada"})
		var i: int = await menu(it, {"cls": "right", "title": "Las obras del muelle", "desc": true})
		if i < 0 or i >= R.obras.size():
			return
		var O: Dictionary = R.obras[i]
		if obra_ya(O.k):
			await say("%s ya está como nueva." % may1(O.n), N)
			continue
		if M_.ob.has(O.k):
			await say("Los de la obra acaban %s el %s." % [O.n, Datos.fd(int(M_.ob[O.k]), S.day)], N)
			continue
		if O.get("req") and not obra_ya(O.req):
			await say("Primero %s. Sin eso, aquí no entra ni el camión." % obra_k(O.req).n, N)
			continue
		if not await confirm("%s: %s por transferencia, %d días de obra. ¿Adelante?" % [may1(O.n), Datos.eur(O.p), int(O.d)]):
			continue
		if not cobro_banco(float(O.p), "Obra · " + O.n):
			await say("En la cuenta no llega. Los de la obra cobran por adelantado.", N)
			continue
		M_.ob[O.k] = int(S.day) + int(O.d)
		sfx("coin")
		update_hud()
		await say("Mañana mismo empiezan con %s. Acaban el %s." % [O.n, Datos.fd(int(M_.ob[O.k]), S.day)], N)

# al amanecer (mar_dia): las obras que acaban, los alquileres, lo que despacha KAIA y la ley
func obras_dia() -> void:
	var R: Dictionary = D.MAR
	var M_: Dictionary = S.mar
	if not R.has("obras") or not (M_.get("ob") is Dictionary):
		return
	if not (M_.get("oba") is Dictionary):
		M_.oba = {}
	var nueva := false
	for O in R.obras:
		if obra_ya(O.k) and not M_.oba.has(O.k):
			M_.oba[O.k] = int(S.day)
			nueva = true
			if O.k == "casas":
				M_.alq = int(S.day) + 7
			var t: String = "Terminada %s. %s" % [O.n, O.txt]
			queue("obra" + O.k, func(): await talk("SMS · KOLDO", [t]))
	if nueva and S.map == "muelle":
		montar_muelle("muelle")
		build_ents()
	if obra_ya("casas") and int(S.day) >= int(M_.get("alq", 0)):
		abono_banco(float(obra_k("casas").alq), "Alquileres · muelle")
		M_.alq = int(S.day) + 7
	var L = M_.get("kaia")
	if L is Dictionary:
		var g = min(L.g, kaia_dia() * (D.VENTA_EXTR.dia if L.get("x") else 1.0))
		var e := Datos.jsround(g * L.pg)
		L.g -= g
		L.tot += e
		if M_.get("lic"):
			abono_banco(e, "KAIA · dispensario")
		else:
			S.money += e
		S.sales += e
		queue("historia", check_story)
		if L.g < 1:
			M_.kaia = null
			var tot = L.tot
			queue("kaia", func(): await talk("SMS · KAIA", ["Se acabó lo del dispensario: %s en total." % Datos.eur(tot)]))
	var LG: Dictionary = R.legal
	if M_.oba.has("club") and not M_.get("ley") and int(S.day) >= int(M_.oba.club) + int(LG.dias):
		M_.ley = int(S.day)
		queue("ley", func(): await talk("SMS · KOLDO", [LG.txt, "Ya es otra película, sobrino: con la licencia, %s te compra hasta %s al día, sin patrulleras y por el banco. Ven a verme." % [LG.n, _kg(int(LG.dia))]]))

func kaia_dia() -> float:
	return float(D.MAR.kaia.dia) * (float(D.MAR.legal.kaia) if S.mar.get("lic") else 1.0)

# el club KAIA, el tuyo: la encargada y el dispensario que llenas tú
func talk_kaia(N: String) -> void:
	var K: Dictionary = D.MAR.kaia
	var M_: Dictionary = S.mar
	var L = M_.get("kaia")
	if L is Dictionary:
		await say("Tu club, jefe. En el dispensario quedan %s de %s, a %s € el gramo. Llevamos %s." % [g_txt(L.g), extr_nombre(L.k, true) if L.get("x") else lot_nombre(L.k), _dos(L.pg), Datos.eur(L.tot)], N)
		return
	var VX: Dictionary = D.VENTA_EXTR
	var lots := lotes_venta(K.g[0], VX.club_g[0])
	if lots.is_empty():
		await say("Bienvenido a KAIA. Aquí el dispensario lo llenas tú: déjame %d g o más y los socios retiran %s al día." % [int(K.g[0]), g_txt(kaia_dia())], N)
		return
	var it := lots.map(venta_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		return
	var l: Array = lots[i]
	var x := es_extr(l)
	var k: String = l[0]
	var b: Dictionary = l[1]
	var pg := Datos.jsround((precio_extr(k, b.thc, "club") if x else precio_club(b.thc)) * calidad(b) * float(K.f) * 100) / 100.0
	var ops := []
	for g in (VX.club_g if x else K.g):
		if g <= floor(b.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(g * pg)])
	o.append("Nada")
	var j: int = await ask("%s a %s € el gramo para los socios. ¿Cuánto dejas?" % [venta_nombre(l), _dos(pg)], o, N)
	if j < 0 or j >= ops.size():
		return
	usa_lote(l, ops[j])
	M_.kaia = {"k": k, "g": ops[j], "pg": pg, "tot": 0}
	if x:
		M_.kaia.x = true
	sfx("sel")
	await say("Al dispensario. Cada mañana, %s para los socios." % g_txt(kaia_dia() * (VX.dia if x else 1.0)), N)

# la licencia, cuando ya hay ley
func licencia_mar(N: String) -> void:
	var LG: Dictionary = D.MAR.legal
	if not await confirm("La licencia de cultivo y distribución: %s por transferencia. Con ella, %s te compra hasta %s al día, sin calor. ¿La sacas?" % [Datos.eur(LG.lic), LG.n, _kg(int(LG.dia))]):
		return
	if not cobro_banco(float(LG.lic), "Licencia · cannabis"):
		await say("En la cuenta no llega. El ministerio no fía.", N)
		return
	S.mar.lic = int(S.day)
	sfx("get")
	await say("Con papeles. Treinta años escondiéndonos y ahora te dan un sello. Maite se partiría de risa.", N)

# la distribuidora legal: hasta MAR.legal.dia al día, por el banco y sin calor
func vender_legal(N: String) -> void:
	var LG: Dictionary = D.MAR.legal
	var M_: Dictionary = S.mar
	if int(M_.get("lgd", -1)) != int(S.day):
		M_.lgd = int(S.day)
		M_.lgg = 0
	var resto: int = int(LG.dia) - int(M_.lgg)
	if resto < 100:
		await say("Por hoy, %s no quiere más. Mañana, otros %s." % [LG.n, _kg(int(LG.dia))], N)
		return
	var lots := bud_lots(100)
	if lots.is_empty():
		await say("%s compra de 100 g para arriba, en cogollo curado o sin curar." % LG.n, N)
		return
	var it := lots.map(venta_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "%s · hoy, hasta %s" % [LG.n, _kg(resto)]})
	if i < 0 or i >= lots.size():
		return
	var l: Array = lots[i]
	var g = await cuanto("¿Cuánto de %s?" % lot_nombre(l[0]), mini(int(floor(l[1].g)), resto), [100, 250, 500, 1000, 2000, 5000], func(v): return _kg(int(v)))
	if g <= 0:
		return
	var e := Datos.jsround(precio_mayor(float(l[1].thc)) * calidad(l[1]) * float(LG.f) * int(g))
	use_buds(l[0], int(g))
	M_.lgg = int(M_.lgg) + int(g)
	abono_banco(e, "Venta · " + LG.n)
	S.sales += e
	sfx("coin")
	update_hud()
	queue("historia", check_story)
	await say("%s de %s, con factura: %s a la cuenta." % [_kg(int(g)), lot_nombre(l[0]), Datos.eur(e)], N)

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

# las cifras de una cerradura de teclado (siempre las mismas para cada cosa y cada partida)
func cifras_acceso(k: String) -> String:
	return "%04d" % (absi(("%s|%s" % [S.name, k]).hash()) % 10000)

# cuándo acaba cada parte: [la llave entra o la tarjeta, la primera cifra, la última cifra, el clic, el final]
func tiempos_acceso(V: Dictionary) -> Dictionary:
	var k: String = V.k
	if GESTOS.has(k):   # 1.54
		return {"fin": float(GESTOS[k])}
	var n: int = maxi(1, str(V.c).length())
	match k:
		"llave", "candado":
			return {"entra": 420.0, "gira": 760.0, "fin": 1000.0}
		"clave":
			return {"t1": 150.0, "clic": 150.0 + n * ACC_TECLA + 60, "fin": 150.0 + n * ACC_TECLA + 360}
		"pin":
			return {"entra": 400.0, "t1": 450.0, "clic": 450.0 + n * ACC_TECLA + 60, "fin": 450.0 + n * ACC_TECLA + 360}
		"rueda":
			return {"para": 350.0, "cada": 220.0, "clic": 350.0 + (n - 1) * 220 + 60, "fin": 350.0 + (n - 1) * 220 + 400}
	return {"fin": 600.0}

func acceso(k: String, c := "", ok := true) -> void:
	if not Datos.CAL:
		return
	if gancho_acceso.is_valid():
		gancho_acceso.call(k, c, ok)
		return
	var V := {"k": k, "c": c, "ok": ok, "t0": M.reloj}
	var T := tiempos_acceso(V)
	var pr := Motor.Prom.new()
	var st := {"fuera": false}
	var cierra := func():
		if not st.fuera:
			st.fuera = true
			pop()
		pr.res(0)
	var suena := func(ms: float, s: String):
		M.timeout(func():
			if not pr.listo:
				sfx(s), ms)
	match k:
		"llave", "candado":
			suena.call(T.entra, "tick")
			suena.call(T.gira, "llave")
		"clave", "pin":
			for i in str(c).length():
				suena.call(T.t1 + i * ACC_TECLA, "tecla")
			suena.call(T.clic, "sel" if ok else "bad")
		"rueda":
			for i in str(c).length():
				suena.call(T.para + i * T.cada, "tick")
			suena.call(T.clic, "llave" if ok else "clac")
	ACCESO_V = V
	push(func(b: String):
		if b == "A" or b == "B":
			cierra.call())
	M.timeout(cierra, T.fin + 250)
	await Motor.espera(pr)
	ACCESO_V = null

func _glifo(R: Array, ch: String, x: int, y: int, s: int, col: String) -> void:
	var g: String = ACC_GLIFO.get(ch, "")
	var w: int = 5 if g.length() == 25 else 3
	if w == 5:
		x -= s
	for i in g.length():
		if g[i] == "1":
			R.append([x + (i % w) * s, y + (i / w) * s, s, s, col])

static func _suave(a: float) -> float:
	a = clampf(a, 0, 1)
	return a * a * (3 - 2 * a)

# los rectángulos [x, y, w, h, color] del momento t (ms desde que empezó)
func rects_acceso(V: Dictionary, now: float) -> Array:
	var R := []
	var t: float = now - float(V.t0)
	var T := tiempos_acceso(V)
	var x0: int = (SW - ACC_W) >> 1
	var y0: int = (SH - ACC_H) >> 1
	var cx: int = x0 + (ACC_W >> 1)
	var cy: int = y0 + (ACC_H >> 1)
	var k: String = V.k
	var c: String = str(V.c)
	if GESTOS.has(k):   # 1.54: el plano de detalle de cada acción; 1.54.1, de sprites, a 144 × 96
		_gs = Rect2i((SW - GS_W) >> 1, (SH - GS_H) >> 1, GS_W, GS_H)
		R.append([_gs.position.x - 2, _gs.position.y - 2, GS_W + 4, GS_H + 4, "#26262e"])
		_gesto_rects(R, V, t)
		return R
	R.append([x0 - 2, y0 - 2, ACC_W + 4, ACC_H + 4, "#26262e"])
	match k:
		"llave":   # la puerta de madera, el escudo de latón y la llave que entra por la derecha y gira
			R.append([x0, y0, ACC_W, ACC_H, "#6a4a30"])
			for xx in range(x0 + 11, x0 + ACC_W, 12):
				R.append([xx, y0, 1, ACC_H, "#5a3c26"])
			R.append([cx - 8, cy - 22, 16, 44, "#b08a3a"])
			R.append([cx - 8, cy - 22, 16, 1, "#d8b860"])
			R.append([cx - 8, cy - 22, 1, 44, "#d8b860"])
			R.append([cx - 8, cy + 21, 16, 1, "#7a5a20"])
			R.append([cx + 7, cy - 22, 1, 44, "#7a5a20"])
			R.append([cx - 5, cy - 18, 10, 6, "#8a6a28"])   # el pomo, encima
			R.append([cx - 3, cy - 6, 6, 5, "#101010"])
			R.append([cx - 1, cy - 2, 2, 7, "#101010"])
			_llave_h(R, t, T, cx + 2, cy - 4, "#6a4a30")
		"candado":   # la persiana de chapa y el candado: la llave sube por debajo, gira y salta el arco
			R.append([x0, y0, ACC_W, ACC_H, "#7a7e86"])
			for yy in range(y0 + 3, y0 + ACC_H, 5):
				R.append([x0, yy, ACC_W, 1, "#5e626a"])
			R.append([x0, cy - 6, ACC_W, 4, "#9a9ea6"])   # el pasador
			var lift: int = Datos.jsround(_suave((t - T.gira) / 160.0) * 6) if V.ok else 0
			R.append([cx - 8, cy - 15 - lift, 16, 3, "#b8bcc4"])
			R.append([cx - 8, cy - 15 - lift, 3, 13, "#b8bcc4"])
			R.append([cx + 5, cy - 15 - lift, 3, 13 + (lift if lift else 0), "#b8bcc4"])
			R.append([cx - 7, cy - 15 - lift, 1, 13, "#e0e4ec"])
			R.append([cx - 10, cy - 2, 20, 18, "#c09838"])
			R.append([cx - 10, cy - 2, 20, 2, "#e0c060"])
			R.append([cx - 10, cy + 14, 20, 2, "#806020"])
			R.append([cx - 1, cy + 7, 3, 5, "#101010"])
			_llave_v(R, t, T, cx - 1, cy + 12, "#7a7e86")
		"clave", "pin":
			_teclado(R, V, t, T, cx, y0 + (14 if k == "pin" else 6))
		"rueda":   # la puerta de la caja: cuatro ruedas que se paran en su cifra y la manilla que gira
			R.append([x0, y0, ACC_W, ACC_H, "#3a4048"])
			R.append([x0 + 5, y0 + 5, ACC_W - 10, ACC_H - 10, "#5a6068"])
			R.append([x0 + 5, y0 + 5, ACC_W - 10, 1, "#7a8088"])
			R.append([x0 + 5, y0 + 5, 1, ACC_H - 10, "#7a8088"])
			var n := c.length()
			var wx: int = cx - (n * 16 - 4) / 2
			for i in n:
				var para: float = T.para + i * T.cada
				var d: int = int(c[i])
				if t < para:
					d = (d + int((para - t) / 60.0) + 1) % 10
				R.append([wx + i * 16, cy - 22, 12, 16, "#101418"])
				R.append([wx + i * 16, cy - 22, 12, 1, "#000000"])
				_glifo(R, str(d), wx + i * 16 + 3, cy - 19, 2, "#e8e0c0" if t >= para else "#a09880")
			var led: String = "#c03030"
			if t >= T.clic:
				led = "#40e060" if V.ok else ("#ff4040" if int(t / 120.0) % 2 == 0 else "#601010")
			R.append([x0 + ACC_W - 16, y0 + 10, 5, 5, led])
			var gi: float = _suave((t - T.clic) / 220.0) if V.ok else 0.0
			var mx: int = cx + (Datos.jsround(sin(t / 30.0)) if not V.ok and t >= T.clic and t < T.clic + 300 else 0)
			R.append([mx - 5, cy + 6, 10, 10, "#a0a4ac"])
			R.append([mx - 3, cy + 8, 6, 6, "#7a8088"])
			if gi < .34:   # la manilla, de pie
				R.append([mx - 1, cy - 1, 3, 24, "#c8ccd4"])
			elif gi < .67:   # en diagonal
				for q in 6:
					R.append([mx - 8 + q * 3, cy + 18 - q * 3, 3, 3, "#c8ccd4"])
			else:   # tumbada: abierta
				R.append([mx - 12, cy + 10, 24, 3, "#c8ccd4"])
	if (k == "llave" or k == "candado") and t >= T.gira and t < T.gira + 220:   # el clic
		var py: int = cy - 4 if k == "llave" else cy + 9
		for q in [[-8, 0, 3, 1], [6, 0, 3, 1], [0, -8, 1, 3], [0, 6, 1, 3], [-6, -6, 2, 2], [5, -6, 2, 2]]:
			R.append([cx + q[0], py + q[1], q[2], q[3], "#f8e070"])
	return R

# la llave de lado: entra hasta la punta (px) y la cabeza gira (se ve de canto)
func _llave_h(R: Array, t: float, T: Dictionary, px: int, py: int, fondo: String) -> void:
	var kx: int = px + Datos.jsround((1 - _suave(t / T.entra)) * 18)
	var a: float = _suave((t - T.entra) / (T.gira - T.entra)) * PI / 2
	var bx: int = kx + 20
	R.append([maxi(kx, px), py, bx - maxi(kx, px), 3, "#c8ccd4"])
	R.append([maxi(kx, px), py + 2, bx - maxi(kx, px), 1, "#8a8e98"])
	if a < PI / 4:
		for o in [3, 7, 11, 15]:
			if kx + o >= px:
				R.append([kx + o, py + 3, 2, 2, "#a8acb4"])
	var bw: int = maxi(2, Datos.jsround(10 * cos(a)))
	R.append([bx + 5 - (bw >> 1), py - 4, bw, 11, "#c8ccd4"])
	if bw > 5:
		R.append([bx + 5 - 2, py, 4, 3, fondo])

# la llave de abajo arriba (el candado)
func _llave_v(R: Array, t: float, T: Dictionary, px: int, py: int, fondo: String) -> void:
	var ky: int = py + Datos.jsround((1 - _suave(t / T.entra)) * 7) - 4
	var a: float = _suave((t - T.entra) / (T.gira - T.entra)) * PI / 2
	var by: int = ky + 14
	R.append([px, maxi(ky, py), 3, by - maxi(ky, py), "#c8ccd4"])
	var bw: int = maxi(2, Datos.jsround(9 * cos(a)))
	R.append([px + 1 - (bw >> 1), by, bw, 9, "#c8ccd4"])
	if bw > 5:
		R.append([px - 1, by + 3, 4, 3, fondo])

# el teclado: pantalla con asteriscos, el piloto y 12 teclas; con la tarjeta (pin), la ranura arriba
func _teclado(R: Array, V: Dictionary, t: float, T: Dictionary, cx: int, ty: int) -> void:
	var x0: int = (SW - ACC_W) >> 1
	var y0: int = (SH - ACC_H) >> 1
	R.append([x0, y0, ACC_W, ACC_H, "#4a4e56" if V.k == "pin" else "#8a7e6a"])
	R.append([cx - 24, ty, 48, 62, "#d0d0c8"])
	R.append([cx - 24, ty, 48, 1, "#f0f0e8"])
	R.append([cx - 24, ty + 61, 48, 1, "#909088"])
	var c: String = str(V.c)
	if V.k == "pin":   # la tarjeta entra por la ranura
		var vis: int = Datos.jsround(14 - _suave(t / T.entra) * 11)
		R.append([cx - 14, ty + 1, 28, 2, "#101010"])
		R.append([cx - 12, ty + 1 - vis, 24, vis, "#3070c0"])
		if vis > 6:
			R.append([cx - 8, ty + 1 - vis + 2, 5, 4, "#d0b040"])
	R.append([cx - 20, ty + 5, 32, 11, "#183018"])
	var hechas: int = clampi(int(floor((t - T.t1) / ACC_TECLA)) + 1, 0, c.length()) if t >= T.t1 else 0
	for i in hechas:
		_glifo(R, "·", cx - 18 + i * 6, ty + 9, 1, "#80f080")
	var led: String = "#c03030"
	if t >= T.clic:
		led = "#40e060" if V.ok else ("#ff4040" if int(t / 120.0) % 2 == 0 else "#601010")
	R.append([cx + 15, ty + 8, 5, 5, led])
	var pulsa := ""
	if t >= T.t1 and t < T.t1 + c.length() * ACC_TECLA and fmod(t - T.t1, ACC_TECLA) < 150:
		pulsa = c[int((t - T.t1) / ACC_TECLA)]
	var teclas := "123456789*0#"
	for i in 12:
		var bx: int = cx - 19 + (i % 3) * 14
		var by: int = ty + 20 + (i / 3) * 10
		var ch: String = teclas[i]
		var p: bool = ch == pulsa
		R.append([bx, by + (1 if p else 0), 11, 8, "#58d080" if p else "#b8b8c0"])
		if not p:
			R.append([bx, by + 7, 11, 1, "#80808a"])
		_glifo(R, ch, bx + 4, by + 2 + (1 if p else 0), 1, "#303038")

# ---------- cada acción, de cerca (1.54, lo pidió el usuario: «que todas las acciones del juego sean más realistas, acompañadas de algo
# gráfico»). Como la llave de la 1.53 (mismo recuadro, ACCESO_V, A o B lo pasan), un plano de detalle de lo que haces: regar, tratar la
# plaga, abonar, plantar, sacar un esqueje, cosechar, manicurar, polinizar, fumar (porro, pipa, bong o vaporizador), vender y pagar
const GESTOS := {"regar": 1200, "tratar": 1200, "abonar": 1200, "plantar": 1200, "sembrar": 1200, "esqueje": 1200, "cosechar": 1300, "manicurar": 1300,
	"polen": 1200, "fumar": 1400, "vender": 1200, "pagar": 1300, "dormir": 1300}
const GESTO_SON := {"regar": [[150, "agua"], [550, "agua"]], "tratar": [[250, "agua"], [600, "agua"]], "abonar": [[200, "agua"]],
	"plantar": [[350, "tick"], [900, "tick"]], "sembrar": [[450, "tick"], [900, "tick"]], "esqueje": [[450, "tijera"]], "cosechar": [[450, "tijera"], [850, "tick"]],
	"manicurar": [[250, "tijera"], [500, "tijera"], [750, "tijera"], [1000, "tijera"]], "polen": [[450, "tick"], [700, "tick"]],
	"fumar": [[100, "chispa"]], "vender": [[600, "coin"]], "pagar": [[200, "tick"], [400, "tick"], [600, "tick"], [800, "tick"], [1000, "coin"]]}

func gesto(k: String, o := {}) -> void:
	if not Datos.CAL or not GESTOS.has(k):
		return
	if gancho_acceso.is_valid():
		gancho_acceso.call(k, str(o.get("m", "")), true)
		return
	var V := {"k": k, "c": str(o.get("m", "")), "ok": true, "t0": M.reloj}
	var pr := Motor.Prom.new()
	var st := {"fuera": false}
	var cierra := func():
		if not st.fuera:
			st.fuera = true
			pop()
		pr.res(0)
	for s in GESTO_SON.get(k, []):
		var nm_: String = s[1]
		M.timeout(func():
			if not pr.listo:
				sfx(nm_), float(s[0]))
	ACCESO_V = V
	push(func(b: String):
		if b == "A" or b == "B":
			cierra.call())
	M.timeout(cierra, float(GESTOS[k]) + 200)
	await Motor.espera(pr)
	ACCESO_V = null

# ---------- 1.54.1 (lo pidió el usuario: «eso no son sprites en condiciones en el mismo estilo que los muebles del juego»): el plano de
# cerca, 144 × 96 a escala de la vista C, compuesto con los sprites de tools/sprites/a-mano/gestos.py (la planta, la maceta y la pared
# de la carpa, de la vista C); entradas ['@', sprite, x, y, recorte] que pinta.gd recorta al panel
const GS_W := 144
const GS_H := 96
var _gs := Rect2i()

func _gsp(R: Array, n: String, x: float, y: float) -> void:
	R.append(["@", n, _gs.position.x + Datos.jsround(x), _gs.position.y + Datos.jsround(y), _gs])

func _gsr(R: Array, x: float, y: float, w: int, h: int, c: String) -> void:
	var r := Rect2i(_gs.position.x + Datos.jsround(x), _gs.position.y + Datos.jsround(y), w, h).intersection(_gs)
	if r.size.x > 0 and r.size.y > 0:
		R.append([r.position.x, r.position.y, r.size.x, r.size.y, c])

static func _mv(a: float, b: float, f: float) -> float:
	return a + (b - a) * _suave(f)

# la maceta de tela con su planta (v: vegetativa, f: en flor, "": sin planta) en el suelo de la carpa
func _gs_maceta(R: Array, pl: String, moja := false) -> void:
	if pl != "":
		_gsp(R, "gs-planta-" + pl, 36, -29)
	_gsp(R, "gs-maceta-m" if moja else "gs-maceta", 40, 60)

func _gesto_rects(R: Array, V: Dictionary, t: float) -> void:
	var k: String = V.k
	var c: String = str(V.c)
	match k:
		"regar":   # la regadera entra, se inclina y el agua cae del pitorro a la tierra, que se oscurece
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "v", t > 600)
			var x: float = _mv(150, 70, t / 300.0) if t < 1000 else _mv(70, 150, (t - 1000) / 200.0)
			_gsp(R, "gs-regadera-1" if t >= 300 and t < 1000 else "gs-regadera-0", x, 18)
			if t > 320 and t < 1000:   # del pitorro (76, 48) a la tierra
				for d in 9:
					var f: float = fmod((t - 320) / 280.0 + d / 9.0, 1.0)
					_gsr(R, 75 - f * 8 + (d % 3), 48 + f * 15, 1, 2, "#8ac8f8" if d % 2 else "#5aa0e0")
		"tratar":   # el pulverizador: dos apretones, la bruma hacia la planta y los bichos que caen
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "v")
			for i in 3:
				if t < 650 + i * 120:
					_gsp(R, "gs-bicho", [46, 60, 42][i], [26, 38, 46][i])
			var apr: bool = (t > 250 and t < 450) or (t > 600 and t < 800)
			_gsp(R, "gs-spray-1" if apr else "gs-spray-0", _mv(150, 80, t / 220.0), 14)
			for p in [250.0, 600.0]:
				var f: float = (t - p) / 500.0
				if f > 0 and f < 1:
					_gsp(R, "gs-bruma-%d" % mini(2, int(f * 3)), 70 - f * 24, 16 + f * 6)
		"abonar":   # la botella baja, se inclina y el chorro ámbar cae a la tierra
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "v")
			if t < 250:
				_gsp(R, "gs-botella-0", 34, _mv(-24, 30, t / 250.0))
			elif t < 1000:
				_gsp(R, "gs-botella-1", 30, 39)
				if t > 300:
					var largo: int = mini(12, int((t - 300) / 25.0))
					_gsr(R, 51, 50, 1, largo, "#d89a3a")
					_gsr(R, 52, 51, 1, maxi(0, largo - 2), "#a86a1a")
			else:
				_gsp(R, "gs-botella-0", 34, _mv(30, -24, (t - 1000) / 200.0))
		"plantar":   # la plántula baja a la maceta, la tierra se aprieta con la mano; 1.57.2: dentro de la maceta, delante del canto de atrás
			_gsp(R, "gs-f-carpa", 0, 0)
			_gsp(R, "gs-maceta", 40, 60)
			_gsp(R, "gs-brote", 36, _mv(-90, -28, t / 600.0))
			if t > 600:   # la tierra alrededor del tallo
				for i in 6:
					_gsr(R, 49 + i * 3 + (1 if i > 2 else 0), 67 + (i % 2), 2, 1, "#3e2c1e" if i % 2 else "#56402a")
			if t > 750:
				_gsp(R, "gs-mano", 58, 38 + Datos.jsround(sin((t - 750) / 90.0) * 2))
		"sembrar":   # 1.57.2 (lo pidió el usuario: «sería mejor echar una semilla al sembrar»): los dedos bajan con la semilla, la sueltan,
			# cae a la tierra y la mano la tapa
			_gsp(R, "gs-f-carpa", 0, 0)
			_gsp(R, "gs-maceta", 40, 60)
			var hy: float = _mv(-26, 36, t / 400.0) if t < 650 else _mv(36, -26, (t - 650) / 200.0)
			if t < 450:
				_gsp(R, "gs-semilla", 51, hy + 16)
			elif t < 900:
				_gsp(R, "gs-semilla", 51, _mv(52, 62, (t - 450) / 200.0))
			if t < 850:
				_gsp(R, "gs-pinza-1" if t >= 420 else "gs-pinza-0", 44, hy)
			if t > 900:   # tapada: un montoncito de tierra
				_gsr(R, 53, 66, 5, 1, "#56402a")
				_gsr(R, 52, 67, 7, 1, "#3e2c1e")
			if t > 820 and t < 1150:
				_gsp(R, "gs-mano", 46, 44 + Datos.jsround(sin((t - 820) / 90.0) * 2))
		"esqueje":   # las tijeras cortan una rama y el esqueje va al vaso de agua
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "v")
			_gsp(R, "gs-vaso", 104, 62)
			if t < 500:
				_gsp(R, "gs-tijeras-1" if t > 420 else "gs-tijeras-0", _mv(150, 66, t / 300.0), 30)
			else:
				var f: float = (t - 500) / 500.0
				_gsp(R, "gs-esqueje", _mv(56, 102, f), _mv(26, 48, f) - sin(clampf(f, 0, 1) * PI) * 10)
				_gsp(R, "gs-tijeras-1", _mv(66, 150, f), 30)
		"cosechar":   # las tijeras cortan la cola de arriba y se la llevan
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "f")
			if t < 500:
				_gsp(R, "gs-tijeras-1" if t > 420 else "gs-tijeras-0", _mv(150, 60, t / 300.0), 12)
			else:
				var f: float = (t - 500) / 600.0
				_gsp(R, "gs-cola", _mv(40, 100, f), _mv(2, 8, f) - sin(clampf(f, 0, 1) * PI) * 6)
				_gsp(R, "gs-tijeras-1", _mv(60, 150, f), 12)
		"manicurar":   # la cola en la mesa, cuatro tijeretazos, las hojitas caen y queda pelada
			_gsp(R, "gs-f-mesa", 0, 0)
			_gsp(R, "gs-cola-p" if t > 650 else "gs-cola", 56, 34)
			var P := [[78, 36], [34, 44], [80, 50], [32, 32]]
			for i in 4:
				var ts: float = 250 + i * 250
				if t > ts:
					_gsp(R, "gs-hojita", P[i][0] + 2 - i, minf(74, P[i][1] + 8 + (t - ts) * .08))
			var j: int = clampi(int((t - 125) / 250.0), 0, 3)
			var cerr: bool = absf(t - (250 + j * 250)) < 60
			_gsp(R, "gs-tijeras-1" if cerr else "gs-tijeras-0", P[j][0] - 8, P[j][1] - 4)
		"polen":   # el pincel da vueltas sobre la cola de arriba y suelta el polen
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "f")
			for i in 10:
				var ti: float = 150 + i * 90
				if t > ti:
					_gsr(R, 48 + (i * 7) % 16, minf(60, 18 + (t - ti) * .03 + (i % 3)), 1, 1, "#f0d040" if i % 2 else "#e0b020")
			_gsp(R, "gs-pincel", 55 + cos(t / 150.0) * 8, -4 + sin(t / 150.0) * 4)
		"fumar":
			_gesto_fumar(R, c, t)
		"vender":   # la mano del cliente con el billete y la tuya con la bolsita; se cambian y se van
			_gsp(R, "gs-f-calle", 0, 0)
			if t < 650:
				_gsp(R, "gs-mano-billete", _mv(-48, 28, t / 400.0), 30)
				_gsp(R, "gs-bolsita", _mv(144, 70, t / 400.0), 40)
			else:
				var f: float = (t - 700) / 400.0
				_gsp(R, "gs-bolsita-c", _mv(28, -48, f), 30)
				_gsp(R, "gs-billete-m", _mv(70, 144, f), 40)
		"pagar":   # del fajo salen cinco billetes, uno a uno, al montón, y la mano lo empuja
			_gsp(R, "gs-f-mesa", 0, 0)
			_gsp(R, "gs-fajo", 14, 40)
			for i in 5:
				var ti: float = 150 + i * 200
				if t > ti:
					var f: float = (t - ti) / 180.0
					_gsp(R, "gs-billete", _mv(16, 84 + (i % 2) * 3, f), _mv(38, 42 - i * 2, f))
			if t > 1000:
				_gsp(R, "gs-mano", _mv(144, 104, (t - 1000) / 200.0), 28)
		"dormir":   # en la cama, de noche (o la siesta, de día); respira y suben las zetas
			_gsp(R, "gs-f-cama-d" if c == "siesta" else "gs-f-cama-n", 0, 0)
			_gsp(R, "gs-dormido-%d" % (1 if fmod(t, 1000) > 500 else 0), 16, 30)   # 1.55.1: de lado, tapado, el pecho sube y baja
			for i in 3:
				var f: float = fmod(t / 900.0 + i / 3.0, 1.0)
				_gsp(R, "gs-z", 50 + f * 16 + sin(f * 6) * 2, 36 - f * 30)

# fumar: el porro, la pipa o el bong, el mechero los enciende, la brasa y el humo; el vaporizador, su piloto y el vapor
func _gesto_fumar(R: Array, m: String, t: float) -> void:
	if m == "":
		m = "porro"
	_gsp(R, "gs-f-cuarto", 0, 0)
	var x: float = _mv(144, 60, t / 150.0)
	var punta := Vector2(x + 4, 55)   # la punta del porro o la cazoleta de la pipa, que entran con la mano
	match m:
		"porro":
			_gsp(R, "gs-porro", x, 44)
		"pipa":
			punta = Vector2(x + 10, 55)
			_gsp(R, "gs-pipa", x, 49)
		"vapo":
			_gsp(R, "gs-vapo-1" if t > 300 and int(t / 250.0) % 2 else "gs-vapo-0", x, 44)
		"bong":
			punta = Vector2(63, 64)
			_gsp(R, "gs-bong", 56, 40)
			if t > 450:
				for i in 4:
					var f: float = fmod(t / 400.0 + i / 4.0, 1.0)
					_gsp(R, "gs-burbuja", 74 + (i * 3) % 9, 82 - f * 8)
	if m != "vapo":
		if t > 150 and t < 500:
			_gsp(R, "gs-mechero-1", punta.x - 11, punta.y + 1)
		elif t <= 150:
			_gsp(R, "gs-mechero-0", punta.x - 11, _mv(100, punta.y + 1, t / 150.0))
		if t > 300:   # la brasa
			_gsr(R, punta.x - 1, punta.y - 1, 2, 2, "#ffb040" if int(t / 150.0) % 2 else "#f86a20")
	var sale := Vector2(80, 44) if m == "bong" else punta   # el humo del bong sale por arriba del tubo
	for i in 3:
		var ti: float = 450 + i * 300
		if t > ti:
			var f: float = (t - ti) / 900.0
			if f < 1:
				_gsp(R, "gs-humo-%d" % mini(2, int(f * 3)), sale.x - 12 - f * 6, sale.y - 14 - f * 36)
