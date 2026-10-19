# Ribera Verde (Godot) — 09-cultivo y la lógica de 09b-carpa: el tiempo (minuto a minuto y de golpe), el día nuevo con su
# factura y su olor, plantar, cuidar, sacar esquejes, cosechar, la cama, el PC (Genoteca y banco de semillas), la carta, la
# mesa de genética y la vista de carpa (VC: elegir plaza o foco y cuidar). Los números salen de Cultivo (src/cultivo.gd).
extends "res://src/calle.gd"

const Vista = preload("res://src/vista.gd")
const EscViaje = preload("res://src/escena_viaje.gd")

var VC = null    # carpa abierta: {ci, sel: plaza (índice de huecos) o −1 = el foco, ocupado}
var vc_texto := ""   # lo que se lee en la ficha (textContent de #vcInfo); "" si está oculta

# ---------- equipo ----------
func huecos() -> Array:
	return Cultivo.huecos(S)

func factores(i: int) -> Dictionary:
	return Cultivo.factores(S, i)

func gramos_planta(p: Dictionary, f: Dictionary) -> int:
	return Cultivo.gramos_planta(S, p, f)

func plantas_vivas(ci: int) -> bool:
	return Cultivo.plantas_vivas(S, ci)

func en_flor(ci: int) -> bool:
	var H := huecos()
	for i in H.size():
		var p = S.pots[i]
		if H[i].c == ci and p and not p.get("dead") and p.prog >= .65:
			return true
	return false

func olor_dia() -> int:
	var a := 0
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if c and en_flor(ci):   # (1.11) sin extractor, OLOR; con uno corto de caudal, 1
			a += int(D.OLOR) if Cultivo.kit_de(c) == "" else (1 if Cultivo.ext_carpa(S, ci) < D.OLOR_MAL else 0)
	return a

func luz_carpa(ci: int) -> int:
	return Cultivo.luz_carpa(S, ci)

func factura_luz() -> int:
	var e := 0
	for ci in S.carpas.size():
		if S.carpas[ci] and plantas_vivas(ci):
			e += luz_carpa(ci)
	return e + Cultivo.factura_sala(S) + factura_carro()   # y el carro de esquejes (1.11)

# el carro de esquejes (1.11, CARRO): con algún esqueje en las bandejas, los tubos T5 gastan luz a 18/6
func factura_carro() -> int:
	return Datos.jsround(D.CARRO.w * D.H_24 * 18 / 24.0 / 1000 * D.KWH) if S.bandejas.size() else 0

func carro_ya() -> bool:
	return "carro" in muebles_ya()

func kwh_foco(k: String) -> int:
	return Datos.jsround(D.FOCOS[k].w * D.H_LUZ / 1000)

static func signo(v: float) -> String:
	return ("+" if v >= 0 else "−") + str(absi(Datos.jsround(v)))

static func pc(t: String, f: float) -> String:
	return "" if absf(f - 1) < .001 else I18n.T(" · {t} {s}%", {"t": t, "s": signo((f - 1) * 100)})

func desc_foco(k: String) -> String:
	var F: Dictionary = D.FOCOS[k]
	return T("{w} W · ilumina {l}×{l} cm · {g} g/W ({ga} abonando){crece}{thc} · riego ×{agua}\nLuz: {kwh} kWh ({eur}) al día con plantas.", {"w": n(F.w), "l": n(F.lado), "g": Datos.coma(F.gpw),
		"ga": Datos.coma(Datos.jsround(F.gpw * 1.25 * 100) / 100.0), "crece": pc(K("crece"), F.crec), "thc": T(" · THC +{p}", {"p": Datos.pct(F.thc)}) if F.thc else "", "agua": Datos.coma(F.agua), "kwh": kwh_foco(k), "eur": Datos.eur(kwh_foco(k) * D.KWH)})

func desc_maceta(k: String) -> String:
	var Mc: Dictionary = D.MACETAS[k]
	return T("{l} L · hasta {cap} g por planta{rend}{crec} · riego ×{agua}{plaga}", {"l": n(Mc.l), "cap": n(Mc.cap), "rend": pc(K("cosecha"), Mc.rend), "crec": pc(K("crece"), Mc.crec), "agua": Datos.coma(Mc.agua), "plaga": T(" · menos plagas") if Mc.plaga < 1 else ""})

# ---------- tiempo ----------
func plants_advance(mn: int) -> void:
	Cultivo.plants_advance(S, mn)

func advance_time(mn: int) -> void:
	while mn > 0:
		var st := mini(60, mn)
		mn -= st
		S.min += st
		plants_advance(st)
		fisio_pasa(st)   # MAESTRO [2]
		if S.min >= 1440:
			S.min -= 1440
			new_day()

# fase 6: los objetivos diarios cuentan riegos, plantas y cosechas (retencion.gd)
func cuenta(_k: String) -> void:
	pass

func tick_minute() -> void:
	S.min += 1
	if S.min % 10 == 0:
		plants_advance(10)
		fisio_pasa(10)   # MAESTRO [2]
	if S.min % 30 == 0 and S.hp < S.hpMax:
		S.hp += 1
	if S.min >= 1440:
		S.min -= 1440
		new_day()
	if S.min % 30 == 0 and (D.ZONAS.has(S.map) or S.map == "home"):
		music(map_music())

func new_day() -> void:
	S.day += 1
	# la cuota de Molina (1.10): pasado el último día pagado, se acaba la protección (antes de la redada de esta noche)
	if S.protect and S.get("protHasta") and S.day > S.protHasta:
		S.protect = false
		var L := [K("Se acabó lo pagado."), K("Si quieres que mis agentes sigan mirando hacia otro lado, ya sabes dónde está la comisaría.")]
		queue("cuota", func(): await talk(K("SMS · MOLINA"), L), [[K("SMS · MOLINA"), L]])
	# la policía (1.11, NIVEL_POLI): con la orden de ayer, la redada; con 90 o más, la orden (y el aviso), o Molina la para
	if S.get("orden") and S.day > S.orden:
		queue("raid", raid_event)
	elif not S.get("orden") and S.heat >= D.NIVEL_POLI[3][0]:
		if S.protect:
			queue("raid", raid_event)
		else:
			S.orden = S.day
			queue("orden", aviso_orden)
	S.heat = max(0, S.heat - baja_calor())
	if Datos.CAL:
		sat_dia()
	var luz := factura_luz()
	var olor := olor_dia()
	var av := []
	var nf: float = pagar_recibo(luz, K("Luz")) if luz > 0 else 0.0    # 1.35: domiciliada; si no llega, de lo de fuera y de la caja (1.10)
	S.luz = {"d": S.day, "e": luz, "o": olor}
	if luz > 0:
		av.append(T("Factura de la luz: −{e} (te faltan {f})", {"e": Datos.eur(luz - nf), "f": Datos.eur(nf)}) if nf else T("Factura de la luz: −{e}", {"e": Datos.eur(luz - nf)}))
	if olor:
		S.heat = min(100, S.heat + olor)
		av.append(T("Olor a cogollo: calor +{n}", {"n": int(olor)}))
	var sec := 0
	for e in S.esquejes:
		if S.day - e.dia > D.ESQUEJE_DIAS:
			sec += 1
	if sec:
		S.esquejes = S.esquejes.filter(func(e): return S.day - e.dia <= D.ESQUEJE_DIAS)
		av.append(T("Se han secado {n} esquejes sin plantar", {"n": sec}) if sec > 1 else T("Se ha secado un esqueje sin plantar"))
	var seb := 0
	for e in S.bandejas:
		if S.day - e.dia > D.CARRO.dias:
			seb += 1
	if seb:
		S.bandejas = S.bandejas.filter(func(e): return S.day - e.dia <= D.CARRO.dias)
		av.append(T("Se han secado {n} esquejes en las bandejas", {"n": seb}) if seb > 1 else T("Se ha secado un esqueje en las bandejas"))
	curado_dia(av)   # el curado (1.29)
	botritis_dia()   # MAESTRO [4]
	if av.size() and mode == "world":
		toast("<br>".join(av), 1600)
	spawn_clients()
	recibir_pedido()
	recibir_envio()
	instalar_caja()
	llega_mueble()
	vencer_encargo()
	curro_dia()   # la gente (1.15)
	setas_dia()   # el bajo de las setas (1.20)
	recibos_dia()   # 1.35
	contable_dia()   # MAESTRO [6]: los contables meten la caja de mañana
	robos_dia()   # MAESTRO [6]: los robos en la nave y los locales, según su seguridad
	vida_dia()   # MAESTRO [7]: los fiados que vencen y los encargos que caducan
	conce_dia()   # 1.43
	vencer_encargo_club()
	if S.due > 0 and S.day > S.deadline:   # 1.10: también sin haber visto a Baltasar (el plazo corre desde Toño)
		queue("penalty", penalty_event)
	elif S.due > 0 and (S.deadline - S.day == 3 or S.deadline == S.day):   # 1.11: a 3 días y el último
		queue("plazo", recuerdo_plazo)
	queue("calor", heat_warn)   # 1.22: el olor de la noche también avisa
	if es_cumple(S.day) and int(S.get("cumpleY", 0)) != int(Datos.fecha(S.day).y):   # i18n-no
		queue("cumple", cumple_event)

# ---------- MAESTRO [4]: la botritis (BOTRITIS, con Datos.CAL) ----------
# Al amanecer, cada planta en flor de una carpa puede coger botritis: con lluvia o tormenta fuera (si la carpa no está sellada) y con la
# humedad de su carpa por encima de BOTRITIS.hr de noche. Con el preventivo (p.prev, hasta ese día), no. La tirada va por hash_str,
# no por Cultivo.azar (la historia y el ciclo no cambian). Con botritis, pierde BOTRITIS.dano de salud al día y la cosecha merma.
func prob_botritis(i: int, ci: int, llueve: bool) -> float:
	var B: Dictionary = D.BOTRITIS
	var p = S.pots[i]
	if not p or p.get("dead") or p.get("bot") or p.prog < .65 or p.prog >= 1 or int(p.get("prev", 0)) >= S.day:
		return 0.0
	var c = S.carpas[ci]
	var pr := 0.0
	if llueve and not c.get("sello"):
		pr += float(B.lluvia)
	if Cultivo.clima_carpa(S, ci, true).hr > float(B.hr):
		pr += float(B.hr_p) * (float(B.sello) if c.get("sello") else 1.0)
	return pr * (1 - float(D.IVS.res) * Cultivo.iv_f(p.get("f"), 3))

func botritis_dia() -> void:
	if not Datos.CAL or not D.has("BOTRITIS"):
		return
	var llueve: bool = Datos.tiempo(S.day, 720).k in ["lluvia", "tormenta"]
	var H := huecos()
	for i in mini(H.size(), S.pots.size()):
		var p = S.pots[i]
		if not p or p.get("dead"):
			continue
		if p.get("bot"):
			p.health = maxf(0, float(p.health) - float(D.BOTRITIS.dano))
			if p.health <= 0:
				p.dead = true
			continue
		var pr := prob_botritis(i, H[i].c, llueve)
		if pr > 0 and Datos.hash_str("bot%d_%d_%s" % [S.day, i, p.sid]) % 1000 < int(pr * 1000):
			p.bot = S.day

func botritis_merma(p: Dictionary, g: int) -> int:
	return maxi(1, Datos.jsround(g * (1 - float(D.BOTRITIS.merma)))) if Datos.CAL and p.get("bot") else g

# ---------- MAESTRO [1]: el cumpleaños (S.cumple {d, m}, con Datos.CAL) ----------
# El día del cumpleaños (el 29 de febrero, el 28 si el año no es bisiesto), al amanecer, tres regalos y eliges uno
# (PERSONAJE.cumple): legendario, una semilla que sale fenotipo estrella; épico, dos focos buenos; raro, diez consumibles
func es_cumple(dia: int) -> bool:
	var c = S.get("cumple")
	if not (Datos.CAL and c is Dictionary and c.has("m")):
		return false
	var f := Datos.fecha(dia)
	return int(f.m) == int(c.m) and int(f.d) == mini(int(c.d), Datos.dias_mes(int(f.y), int(c.m)))

func semilla_cumple() -> String:   # una landrace del banco, distinta cada año
	var B: Array = D.BANCO
	return String(B[(int(Datos.fecha(S.day).y) * 7 + S.day) % B.size()][0])

func cumple_event() -> void:
	S.cumpleY = int(Datos.fecha(S.day).y)
	var C: Dictionary = D.PERSONAJE.cumple
	var sid := semilla_cumple()
	var foco: String = C.epica.foco
	await talk(K("SMS · KIKO"), [K("¡Feliz cumpleaños, {N}! Te he guardado tres regalos en el armario. Elige uno.")])
	var it := [
		{"label": T("LEGENDARIO · 1 semilla ★ de {s}", {"s": strain(sid).n}), "desc": K("Sale fenotipo estrella seguro: más cogollo y más THC.")},
		{"label": T("ÉPICO · {n} focos {f}", {"n": int(C.epica.n), "f": D.FOCOS[foco].n}), "desc": K("Para las carpas: cámbialos desde la carpa.")},
		{"label": T("RARO · {n} consumibles", {"n": int(C.rara.fert + C.rara.ofertv + C.rara.ophm)}), "desc": T("{a} abonos de crecimiento, {b} de floración y {c} botes de pH−", {"a": int(C.rara.fert), "b": int(C.rara.ofertv), "c": int(C.rara.ophm)})}]
	var i: int = await menu(it, {"cls": "full", "title": K("CUMPLEAÑOS"), "cancel": false, "desc": true})
	if i == 0:
		add_seeds(sid, 1)
		var e: Dictionary = S.get("estrella", {})
		e[sid] = int(e.get(sid, 0)) + 1
		S.estrella = e
	elif i == 1:
		S.items["f_" + foco] = int(S.items.get("f_" + foco, 0)) + int(C.epica.n)
	else:
		for k in ["fert", "ofertv", "ophm"]:
			S.items[k] = int(S.items.get(k, 0)) + int(C.rara[k])
	sfx("coin")
	toast(K("Regalo de cumpleaños en la mochila"), 1600)

# la semilla del regalo legendario: la primera que se planta de esa variedad sale estrella (sin tocar el azar: se sube después)
func estrella_regalo(sid: String, f: Dictionary) -> void:
	var e = S.get("estrella")
	if not (Datos.CAL and e is Dictionary and int(e.get(sid, 0)) > 0):
		return
	e[sid] = int(e[sid]) - 1
	if e[sid] <= 0:
		e.erase(sid)
	var m: float = ceilf(sqrt(D.FENO_ESTRELLA) * 100) / 100.0
	f.t = maxf(float(f.t), m)
	f.y = maxf(float(f.y), m)

# ---------- fenotipo ----------
func tira_feno(sg: float) -> Dictionary:
	var m := func() -> float: return Datos.jsround(clampf(1 + sg * Cultivo.gauss(), .6, 1.5) * 100) / 100.0
	var t: float = m.call()
	return {"t": t, "y": m.call()}

func roll_feno(sid: String) -> Dictionary:
	return Cultivo.roll_feno(S, sid)

func feno_visto(f):
	if f is Dictionary and f.get("id"):
		return S.fenos.get(str(int(f.id)))
	return null

func marca_feno(f) -> String:
	var v = feno_visto(f)
	return " ★" if v == "estrella" else (T(" (floja)") if v == "floja" else "")

# número y nombre de cada planta (1.11, nomPlanta de 09-cultivo): la nº de su fenotipo o el nombre de S.fnom, que heredan sus esquejes
func nom_planta(f) -> String:
	if not (f is Dictionary and f.get("id")):
		return ""
	var k := str(int(f.id))
	var fn: Dictionary = S.get("fnom", {})
	return (" «%s»" % fn[k]) if fn.has(k) else T(" nº {k}", {"k": k})

func etiq(f) -> String:
	return nom_planta(f) + marca_feno(f)

func nombrar_planta(f: Dictionary) -> void:
	if not S.has("fnom"):
		S.fnom = {}
	var k := str(int(f.id))
	var v = await pedir_texto(T("Nombre de la planta (y sus esquejes)"), S.fnom.get(k, ""), 12)
	if v == null or (v == "" and not S.fnom.has(k)):
		return
	if v != "":
		S.fnom[k] = v
	else:
		S.fnom.erase(k)
	sfx("sel")
	await say(T("Ahora se llama «{v}». Sus esquejes, también.", {"v": v}) if v != "" else T("Sin nombre: vuelve a ser la nº {k}.", {"k": k}))

# un esqueje del propagador o de las bandejas del carro (l): ponerle nombre o tirarlo
func esqueje_accion(e: Dictionary, l: Array) -> void:
	var c: int = await ask(T("Esqueje de {s}{e}.", {"s": strain(e.sid).n, "e": etiq(e.f)}), [K("Nombrar"), K("Tirar"), K("Nada")])
	if c == 0:
		await nombrar_planta(e.f)
	elif c == 1:
		l.remove_at(l.find(e))
		sfx("sel")
		await say(K("Tiras el esqueje."))

# MAESTRO [5]: los 4 valores de la línea, de 1 a 31
func genes_txt(iv: Array) -> String:
	return T("Genes: potencia {a} · producción {b} · floración {c} · resistencia {d} (de 31).", {"a": int(iv[0]), "b": int(iv[1]), "c": int(iv[2]), "d": int(iv[3])})

# ---------- plantar y cuidar ----------
func _own() -> Array:
	var o := []
	for k in S.seeds:
		if S.seeds[k] > 0:
			o.append([k, S.seeds[k]])
	return o

func plantar(i: int) -> void:
	var own := _own()
	var esq := []   # [esqueje, 1 si es de las bandejas del carro]
	for e in S.esquejes:
		esq.append([e, 0])
	for e in S.bandejas:
		esq.append([e, 1])
	if own.is_empty() and esq.is_empty():
		await say(K("Maceta vacía. No tienes semillas: cómpralas en el growshop de Kiko."))
		return
	var items := []
	for o in own:
		var s = strain(o[0])
		items.append({"label": s.n, "right": "×" + n(o[1]), "sw": s.c, "ic": ic_cog(o[0]), "desc": strain_line(o[0]) + (("\n" + genes_txt(Cultivo.iv_linea(S, o[0]))) if Datos.CAL and S.items.get("analizador") else "")})
	for eb in esq:
		var e: Dictionary = eb[0]
		var s = strain(e.sid)
		var v = feno_visto(e.f)
		var dv := T("Fenotipo estrella: THC ×{t} y cosecha ×{y}.", {"t": Datos.coma(e.f.t), "y": Datos.coma(e.f.y)}) if v == "estrella" else (T("Fenotipo flojo: rinde menos que la media.") if v == "floja" else T("Su fenotipo se sabrá cuando coseches a la madre o a un clon suyo."))
		items.append({"label": T("Esqueje {s}{e}", {"s": s.n, "e": etiq(e.f)}), "right": K("bandeja") if eb[1] else K("esqueje"), "sw": s.c, "ic": ic_cog(e.sid),
			"desc": T("Clon enraizado: la misma planta que su madre, con su fenotipo.\n{dv}\nSe seca si no lo plantas antes del {d}.", {"dv": dv, "d": Datos.fd(e.dia + (D.CARRO.dias if eb[1] else D.ESQUEJE_DIAS) + 1, S.day)})})
	items.append({"label": K("Cancelar"), "desc": ""})
	var j: int = await menu(items, {"cls": "full", "title": K("¿QUÉ PLANTAS?"), "desc": true})
	if j < 0 or j >= own.size() + esq.size():
		return
	cuenta("plantar")
	if j >= own.size():
		var e: Dictionary = esq[j - own.size()][0]
		var l: Array = S.bandejas if esq[j - own.size()][1] else S.esquejes
		l.remove_at(l.find(e))
		S.pots[i] = {"sid": e.sid, "prog": .12, "water": 70, "health": 100, "fert": false, "pest": false, "f": e.f}   # ya enraizado: empieza de plántula
		sfx("sel")
		await accion("plantar")
		await say(T("Plantas el esqueje de {s}{e}.", {"s": strain(e.sid).n, "e": etiq(e.f)}))
		await pista_barras()
		return
	var sid: String = own[j][0]
	S.seeds[sid] -= 1
	if not S.seeds[sid]:
		S.seeds.erase(sid)
	S.pots[i] = {"sid": sid, "prog": 0, "water": 70, "health": 100, "fert": false, "pest": false, "f": roll_feno(sid)}
	estrella_regalo(sid, S.pots[i].f)
	sfx("sel")
	await accion("sembrar" if Datos.CAL else "plantar")   # 1.57.2: la semilla a la tierra
	await say(T("Has plantado {s}{e}.", {"s": strain(sid).n, "e": nom_planta(S.pots[i].f)}))
	await pista_barras()

# con la primera planta, qué dice su barra
func pista_barras() -> void:
	if S.flags.get("barras"):
		return
	S.flags.barras = true
	await say(K("Cada planta lleva su barra: arriba, el agua (roja: toca regar); abajo, la cosecha (dorada: lista)."))
	await say(K("Si le sale plaga, verás una «!» roja y manchas en las hojas. Trátala con INSECTICIDA."))

func sacar_esqueje(i: int) -> void:
	var p: Dictionary = S.pots[i]
	var s = strain(p.sid)
	if S.esquejes.size() >= 12:
		await say(K("El propagador está lleno: 12 esquejes. Planta alguno antes."))
		return
	S.esquejes.append({"sid": p.sid, "f": p.f if p.get("f") else roll_feno(p.sid), "dia": S.day})
	if not p.get("f"):
		p.f = S.esquejes[-1].f
	p.health = max(1, p.health - 5)
	await gesto("esqueje")   # 1.54
	sfx("sel")
	await say(T("Cortas una punta de la {s}{e} y la pones a enraizar.\nPlántala antes del {d}: es la misma planta.", {"s": s.n, "e": nom_planta(p.f), "d": Datos.fd(S.day + D.ESQUEJE_DIAS + 1, S.day)}))
	if carro_ya():
		await say(T("O pínchala en el carro: allí aguanta {n} días.", {"n": int(D.CARRO.dias)}))

func stage_name(p: Dictionary) -> String:
	return Cultivo.stage_name(p)

func pot_action(i: int) -> void:
	var p = S.pots[i]
	if p == null:
		if macetas_libres(i, false).size():
			var c: int = await ask(T("Plaza vacía con una maceta de {m}.", {"m": D.MACETAS[S.macetas[i]].n}), [K("Plantar"), K("Cambiar maceta"), K("Salir")])
			if c == 1:
				await cambiar_maceta(i)
				return
			if c != 0:
				return
		await plantar(i)
		return
	var s = strain(p.sid)
	if p.get("dead"):
		await say(T("La {s} se ha secado del todo.", {"s": s.n}))
		S.pots[i] = null
		await say(K("Retiras la planta muerta."))
		return
	if p.prog >= 1:
		var c: int = await ask(T("{s}{e} lista para cosechar.\nSalud {h}% · Agua {w}%", {"s": s.n, "e": etiq(p.get("f")), "h": Datos.jsround(p.health), "w": Datos.jsround(p.water)}), [K("Cosechar"), K("Nombrar"), K("Esperar")])
		if c == 0:
			await harvest(i)
		elif c == 1:
			if not p.get("f"):
				p.f = roll_feno(p.sid)
			await nombrar_planta(p.f)
		return
	var veg_k := []
	if p.prog < .65 and not _fv(p) > 0:
		for k in ["fertv", "ofertv"]:
			if S.items.get(k, 0) > 0:
				veg_k.append(k)
	var opts := [K("Regar")]
	if not p.fert or veg_k.size():
		opts.append(K("Abonar"))
	if p.pest:
		opts.append(K("Tratar plaga"))
	if Datos.CAL and p.get("bot"):
		opts.append(K("Tratar hongos"))
	elif Datos.CAL and D.has("BOTRITIS") and S.items.get("prevent", 0) > 0 and int(p.get("prev", 0)) < S.day:
		opts.append(K("Preventivo"))
	if p.prog >= .2 and p.prog < .65 and not (Datos.CAL and s.get("auto")):   # 1.52: las autos no se clonan
		opts.append(K("Sacar esqueje"))
	opts.append_array([K("Nombrar"), K("Arrancar"), K("Salir")])
	var c: int = await ask(T("{s}{e} · {st} {p}%\nAgua {w}% · Salud {h}%{pl}", {"s": s.n, "e": etiq(p.get("f")), "st": stage_name(p), "p": int(floor(p.prog * 100)), "w": Datos.jsround(p.water),
		"h": Datos.jsround(p.health), "pl": (T(" · PLAGA") if p.pest else "") + (T(" · BOTRITIS") if Datos.CAL and p.get("bot") else "")}), opts)
	var op: String = opts[c]
	if op == "Regar":
		var v := pos_plaza(i)
		await accion("regar", {"id": "vfx-gotas", "x": v[0], "y": v[1] - 6})
		p.water = 100
		S.flags.gRiego = 1
		cuenta("riego")
		sfx("sel")
		await say(K("Riegas la planta. Agua al 100%."))
	elif op == "Abonar":
		await abonar(p, veg_k)
	elif op == "Tratar plaga":
		if S.items.insect > 0:
			S.items.insect -= 1
			p.pest = false
			await gesto("tratar")   # 1.54
			sfx("sel")
			await say(K("Aplicas INSECTICIDA con guantes y mascarilla. Plaga eliminada."))
		else:
			await say(K("No tienes INSECTICIDA. Kiko lo vende."))
	elif op == "Tratar hongos":
		if S.items.get("fungi", 0) > 0:
			S.items.fungi -= 1
			p.erase("bot")
			await gesto("tratar")
			sfx("sel")
			await say(K("Quitas los cogollos con moho gris y aplicas el FUNGICIDA. Botritis parada."))
		else:
			await say(K("No tienes FUNGICIDA. Lo venden en el growshop."))
	elif op == "Preventivo":
		S.items.prevent -= 1
		p.prev = S.day + int(D.BOTRITIS.prev)
		await gesto("tratar")
		sfx("sel")
		await say(T("Aplicas el PREVENTIVO: la botritis no la coge en {n} días.", {"n": int(D.BOTRITIS.prev)}))
	elif op == "Sacar esqueje":
		await sacar_esqueje(i)
	elif op == "Nombrar":
		if not p.get("f"):
			p.f = roll_feno(p.sid)
		await nombrar_planta(p.f)
	elif op == "Arrancar":
		if await ask(K("¿Seguro que quieres arrancarla?"), [K("Sí"), K("No")]) == 0:
			S.pots[i] = null
			await say(K("Arrancas la planta."))

# tierra (1.10): como mucho LITROS_M2 litros por m² de suelo en cada carpa, sumando todas sus macetas
func litros_max(ci: int) -> int:
	var cm: Array = D.CARPAS[S.carpas[ci].t].cm
	return Datos.jsround(cm[0] * cm[2] / 1e4 * D.LITROS_M2)

func litros_carpa(ci: int) -> int:
	var a := 0
	var hu := huecos()
	for i in hu.size():
		if hu[i].c == ci:
			a += int(D.MACETAS.get(S.macetas[i], D.MACETAS.plastico7).l)
	return a

# macetas de repuesto que caben en la plaza i (y no son la que ya tiene): hasta CARPAS[t].lmax y, con tierra, sin pasar de litros_max
func macetas_libres(i: int, tierra := true) -> Array:
	var h: Dictionary = huecos()[i]
	var C: Dictionary = D.CARPAS[S.carpas[h.c].t]
	var sobra: int = litros_max(h.c) - litros_carpa(h.c) + int(D.MACETAS[S.macetas[i]].l)
	var o := []
	for k in D.MACETAS:
		if S.items.get("m_" + k, 0) > 0 and D.MACETAS[k].l <= C.lmax and k != S.macetas[i] and (not tierra or D.MACETAS[k].l <= sobra):
			o.append(k)
	return o

func cambiar_maceta(i: int) -> void:
	var l := macetas_libres(i)
	var ci: int = huecos()[i].c
	var tl := T("tierra {a} de {b} L", {"a": litros_carpa(ci), "b": litros_max(ci)})
	if l.is_empty():
		await say(T("No cabe más tierra en la carpa ({tl}).", {"tl": tl}) if macetas_libres(i, false).size() else K("No tienes otra maceta que quepa aquí."))
		return
	var it := []
	for k in l:
		it.append({"label": T("Maceta {m}", {"m": D.MACETAS[k].n}), "right": "×" + n(S.items["m_" + k]), "ic": icono("maceta"), "desc": desc_maceta(k)})
	var j: int = await menu(it, {"cls": "full", "title": K("CAMBIAR MACETA"), "title2": T("Ahora: {m} · {tl}", {"m": D.MACETAS[S.macetas[i]].n, "tl": tl}), "desc": true})
	if j < 0:
		return
	var k: String = l[j]
	S.items["m_" + k] -= 1
	S.items["m_" + S.macetas[i]] = S.items.get("m_" + S.macetas[i], 0) + 1
	S.macetas[i] = k
	sfx("sel")
	var h: Dictionary = huecos()[i]   # su garrafa, llena para la maceta nueva
	var gc: Dictionary = S.carpas[h.c]
	if gc.get("gar") != null and h.j < gc.gar.size():
		gc.gar[h.j] = null
	await say(T("Pones la maceta de {m}. La vieja va a la mochila.", {"m": D.MACETAS[k].n}))

func focos_libres(ci: int) -> Array:
	var o := []
	for k in D.FOCOS:
		if S.items.get("f_" + k, 0) > 0 and D.FOCOS[k].w <= D.CARPAS[S.carpas[ci].t].wmax and k != S.carpas[ci].foco:
			o.append(k)
	return o

func instalar_foco(ci: int, k: String) -> void:
	var c: Dictionary = S.carpas[ci]
	S.items["f_" + k] -= 1
	S.items["f_" + c.foco] = S.items.get("f_" + c.foco, 0) + 1
	c.foco = k
	sfx("sel")

func cambiar_foco(ci: int) -> void:
	var l := focos_libres(ci)
	if l.is_empty():
		await say(K("No tienes otro foco que aguante esta carpa."))
		return
	var it := []
	for k in l:
		it.append({"label": T("Foco {f}", {"f": D.FOCOS[k].n}), "right": "×" + n(S.items["f_" + k]), "ic": icono(Atlas.ico_foco(k)), "desc": desc_foco(k)})
	var j: int = await menu(it, {"cls": "full", "title": K("CAMBIAR FOCO"), "title2": T("Ahora: {f}", {"f": D.FOCOS[S.carpas[ci].foco].n}), "desc": true})
	if j < 0:
		return
	instalar_foco(ci, l[j])
	await say(T("Cuelgas el foco {f}. El viejo va a la mochila.", {"f": D.FOCOS[l[j]].n}))

# pl: femenino plural (las garrafas) · lo que le falta a la carpa (con goteo, las garrafas no)
static func falta_extra(c, k: String) -> bool:
	return c != null and not c.get(k) and not (k == "garrafas" and c.get("goteo"))

func extras_libres(ci: int) -> Array:
	var o := []
	for k in D.EXTRAS:
		if falta_extra(S.carpas[ci], k) and S.items.get("x_" + k, 0) > 0:
			o.append(k)
	return o

# abono, pH y EC (1.11, 09-cultivo): lo que aprovecha la dosis (con pH− y medidor, 1; a ojo, .75; sin pH−, .5) y su texto.
# Por marca (D.PRODUCTOS): el pH− que se gasta es el de su marca y, si no hay, el otro
func ph_item(bio):
	for k in (["ophm", "phm"] if bio else ["phm", "ophm"]):
		if S.items.get(k, 0) > 0:
			return k
	return null

func abono_q(bio = 0) -> float:
	return float(Cultivo.abo_de(bio).q[(2 if S.items.get("medidor", 0) else 1) if ph_item(bio) != null else 0])

# (09-cultivo: abonar): el de crecimiento (veg_k: los que hay, en vegetativo y sin él) o el de floración; con dos marcas, eliges
func abonar(p: Dictionary, veg_k: Array) -> void:
	var veg := veg_k.size() > 0
	var ks := veg_k
	if not veg:
		ks = []
		for x in ["fert", "ofert"]:
			if S.items.get(x, 0) > 0:
				ks.append(x)
	if ks.is_empty():
		await say(K("No te queda ABONO."))
		return
	var k: String = ks[0]
	if ks.size() > 1:
		var L := []
		for x in ks:
			L.append("%s ×%s" % [D.PRODUCTOS[x].n, n(S.items[x])])
		L.append(K("Nada"))
		var c: int = await ask(K("¿Qué abono le echas?"), L)
		if c < 0 or c >= ks.size():
			return
		k = ks[c]
	var bio: bool = true if D.PRODUCTOS[k].bio else false
	var ph = ph_item(bio)
	var q := abono_q(bio)
	if ph != null:
		S.items[ph] -= 1
		if not D.PRODUCTOS[ph].bio:
			p.min = 1
	S.items[k] -= 1
	if bio:
		p.org = 1
	else:
		p.min = 1
	if veg:
		p.fv = q
		if bio:
			p.fvo = 1
		S.flags.gVeg = 1
	else:
		p.fert = true
		p.fq = q
		if bio:
			p.fo = 1
		S.flags.gFlor = 1
	await gesto("abonar")   # 1.54
	sfx("sel")
	var pk := I18n.v(String(D.PRODUCTOS[k].n)).to_upper()
	var t := T("Echas una dosis de {p}. Crecerá más deprisa.", {"p": pk}) if veg else T("Echas una dosis de {p}. Dará más cosecha.", {"p": pk})
	if ph != null:
		t += (T("\nCon el medidor, lo aprovecha entero.") if Datos.PLAY else T("\nCon el medidor, el pH al {ph}: lo aprovecha entero.", {"ph": Datos.coma(D.ABONO.ph[2])})) if S.items.get("medidor", 0) else T("\nCorriges el pH a ojo, sin medidor: lo aprovecha casi todo.")
	elif bio:
		t += T("\nSin pH−, la tierra amortigua el agua del grifo: lo aprovecha al {p} %.", {"p": Datos.jsround(D.ABONO_BIO.q[0] * 100)})
	else:
		t += T("\nSin corrector, el agua del grifo bloquea {p} % del abono.", {"p": Datos.jsround((1 - D.ABONO.q[0]) * 100)}) if Datos.PLAY else T("\nSin pH−, el agua del grifo (pH {ph}) bloquea {p} % del abono.", {"ph": Datos.coma(D.ABONO.ph[0]), "p": Datos.jsround((1 - D.ABONO.q[0]) * 100)})
	await say(t)
	if ph != null and (true if D.PRODUCTOS[ph].bio else false) != bio:
		await say(T("No te queda pH− de su marca: gastas una dosis de {p}.", {"p": D.PRODUCTOS[ph].n}) + (T(" Con el mineral, el sustrato ya no está vivo.") if bio else ""))

func _fv(p: Dictionary) -> float:
	return float(p.fv) if p.get("fv") != null else 0.0

func abono_txt(p: Dictionary) -> String:
	var L := []
	if _fv(p) > 0:
		L.append(T("crecimiento bio") if p.get("fvo") else T("crecimiento"))
	if p.fert:
		L.append(T("floración bio") if p.get("fo") else T("floración"))
	var t := (T("Abonada ({a})", {"a": L[0]}) if L.size() == 1 else T("Abonada ({a} y {b})", {"a": L[0], "b": L[1]})) if L.size() else T("Sin abonar")
	if Cultivo.sustrato_vivo(p):
		t += T(" · sustrato vivo")
	if S.items.get("medidor", 0) and L.size():
		var ec := Datos.jsround((.4 + ((.4 if p.get("fvo") else .7) if _fv(p) > 0 else 0.0) + ((.5 if p.get("fo") else .9) if p.fert else 0.0)) * 10) / 10.0
		var iv := _ph_i(_fv(p), p.get("fvo")) if _fv(p) > 0 else 2   # cada dosis, con la q de su marca (phDe)
		var ifl := _ph_i(Cultivo.fq(p), p.get("fo")) if p.fert else 2
		t += T(" · riego {r}", {"r": [K("a ojo"), K("a medias"), K("bien")][mini(iv, ifl)]}) if Datos.PLAY else T(" · EC {ec} · pH {ph}", {"ec": Datos.coma(ec), "ph": Datos.coma(D.ABONO.ph[mini(iv, ifl)])})
	return t

func _ph_i(q: float, bio) -> int:
	var Q: Array = Cultivo.abo_de(bio).q
	return 2 if q >= float(Q[2]) else (1 if q >= float(Q[1]) else 0)

# el goteo llega lleno y las garrafas que hubiera vuelven a la mochila; las garrafas llegan llenas; un kit de extracción
# devuelve el que hubiera (1.11: lo devuelve poner_extra, para el mensaje)
func poner_extra(ci: int, k: String) -> String:
	var c: Dictionary = S.carpas[ci]
	var vk := Cultivo.kit_de(c) if D.KITS.has(k) else ""
	S.items["x_" + k] -= 1
	if vk != "":
		c[vk] = false
		S.items["x_" + vk] = S.items.get("x_" + vk, 0) + 1
	c[k] = true
	if k == "goteo":
		c.dep = Cultivo.goteo_l(S, ci)
		if c.get("garrafas"):
			c.garrafas = false
			c.erase("gar")
			S.items.x_garrafas = S.items.get("x_garrafas", 0) + 1
	if k == "garrafas":
		c.gar = []
	sfx("sel")
	return vk

# el temporizador de la carpa ci (vista de carpa, a la izquierda del foco): automático, 18/6 (madres) o 12/12 (floración)
func temporizador(ci: int) -> void:
	var c: Dictionary = S.carpas[ci]
	var k := Cultivo.ciclo_de(c)
	var Ks: Array = D.CICLOS.keys()
	var opts := []
	for x in Ks:
		opts.append(D.CICLOS[x].m)
	opts.append(K("Salir"))
	var j: int = await ask(T("Temporizador · {n}: {c}\nLuz {e} al día con plantas", {"n": D.CICLOS[k].n, "c": I18n.v(String(D.CICLOS[k].c)).to_lower(), "e": Datos.eur(luz_carpa(ci))}), opts)
	if j < 0 or j >= Ks.size() or Ks[j] == k:
		return
	if Ks[j] == "auto":
		c.erase("ciclo")
	else:
		c.ciclo = Ks[j]
	sfx("sel")
	await say(D.CICLOS[Ks[j]].d)

func carpa_action(ci: int) -> void:
	var c: Dictionary = S.carpas[ci]
	var C: Dictionary = D.CARPAS[c.t]
	var F: Dictionary = D.FOCOS[c.foco]
	var f := focos_libres(ci).size()
	var ex := extras_libres(ci)
	var gl := Cultivo.goteo_l(S, ci)
	var dep: float = (c.dep if c.get("dep") != null else float(gl)) if c.get("goteo") else 0.0
	var gar: bool = c.get("garrafas", false) and not c.get("goteo")
	var ga := Cultivo.garrafas_carpa(S, ci)
	var ll: bool = dep < gl if c.get("goteo") else (gar and ga[0] < ga[1])
	var opts := [K("Cambiar foco")] if f else []
	for k in ex:
		opts.append(T("Poner {x}", {"x": I18n.v(String(D.EXTRAS[k].c)).to_lower()}))
	if ll:
		opts.append(K("Rellenar depósito") if c.get("goteo") else K("Rellenar garrafas"))
	opts.append(K("Salir"))
	var gt: String = T(" · goteo {a} de {b} L", {"a": Datos.miles(floor(dep)), "b": Datos.miles(gl)}) if c.get("goteo") else (T(" · garrafas {a} de {b} L", {"a": int(floor(ga[0])), "b": int(ga[1])}) if gar else "")
	var k: int = await ask(T("{c} · {p} plantas · {f}\n{w} W/m² · luz {e} al día con plantas{gt}", {"c": C.n, "p": n(C.plazas), "f": F.n, "w": Datos.jsround(F.w / (C.cm[0] * C.cm[2] / 1e4)), "e": Datos.eur(luz_carpa(ci)), "gt": gt}), opts)
	if opts[k] == "Cambiar foco":
		await cambiar_foco(ci)
		return
	if opts[k] == "Rellenar depósito":
		c.dep = gl
		sfx("sel")
		await say(T("Llenas el depósito del goteo: {l} L.", {"l": Datos.miles(gl)}))
		return
	if opts[k] == "Rellenar garrafas":
		c.gar = []
		sfx("sel")
		await say(T("Llenas las garrafas: {l} L.", {"l": int(ga[1])}))
		return
	var ix := k - (1 if f else 0)
	if k < 0 or ix < 0 or ix >= ex.size():
		return
	var x: String = ex[ix]
	var vu: bool = x == "goteo" and c.get("garrafas", false)
	var vk := poner_extra(ci, x)
	var arm: bool = C.n.begins_with("Armario")
	var hx := {"x": I18n.v(String(D.EXTRAS[x].n)).to_lower(), "c": I18n.v(String(C.n)).to_lower()}
	var pon: String = (T("Pones las {x} en el {c}.", hx) if arm else T("Pones las {x} en la {c}.", hx)) if D.EXTRAS[x].get("pl") else (T("Pones el {x} en el {c}.", hx) if arm else T("Pones el {x} en la {c}.", hx))
	await say(pon + "\n" + I18n.v(String(D.EXTRAS[x].d)) + (T("\nLas garrafas vuelven a la mochila.") if vu else "") + (T("\nEl {k} vuelve a la mochila.", {"k": I18n.v(String(D.EXTRAS[vk].c)).to_lower()}) if vk != "" else ""))

# ---------- cosecha ----------
func semillas_cosecha(p: Dictionary) -> Dictionary:
	var cria: bool = Cultivo.gen_de(S, p.sid) < D.GEN_ESTABLE
	var fem := false
	for it in D.SHOP:
		if it.get("sid") == p.sid:
			fem = true
	var nn := 0
	if cria:
		nn = ri(2, 5)
	elif not fem or Cultivo.azar() < D.SEMILLA_HERMA:
		nn = ri(1, 3)
	return {"cria": cria, "fem": fem, "n": nn}

func harvest(i: int) -> void:
	var p: Dictionary = S.pots[i]
	cuenta("cosecha")
	var s = strain(p.sid)
	var f := factores(i)
	var fe: Dictionary = p.f if p.get("f") else {"t": 1, "y": 1}
	var cl := Cultivo.clase_feno(p.get("f"))
	var g := botritis_merma(p, gramos_planta(p, f))
	var thc := Cultivo.thc_cosecha(S, p, f)
	var v := pos_plaza(i)
	await accion("cosechar")
	await accion("oler", {"id": "vfx-brillo", "x": v[0], "y": v[1] - 12})
	var sc := semillas_cosecha(p)
	var cria: bool = sc.cria
	var fem: bool = sc.fem
	var nn: int = sc.n
	var lk: String = p.sid + "*" if cl == "estrella" else p.sid
	var sh = fe.get("sh") if Datos.CAL else null   # MAESTRO [5]: la rara, a su lote (×SHINY.x); sus semillas no la llevan
	if sh:
		lk += "!"
	add_buds(lk, g, thc)
	if nn:
		add_seeds(p.sid, nn)
		if Datos.CAL and fe.get("iv"):
			Cultivo.hereda_iv(S, p.sid, fe.iv)
	var sobra := mini(g, int(floor(peso_encima() - cap_mochila())))   # lo que no cabe encima, a la caja fuerte (1.36; antes, al arcón)
	var a_caja := mini(sobra, int(floor(D.CAJA[int(S.caja.nivel)].g - caja_g()))) if sobra >= 1 and S.get("caja") else 0
	if a_caja >= 1:
		mover_lote(S.buds, S.caja.buds, lk, a_caja)
	if p.get("f") and p.f.get("id"):
		S.fenos[str(int(p.f.id))] = cl
	S.pots[i] = null
	sfx("get")
	if S.rec.get(p.sid) == 1:   # una variedad de receta sacada en la mesa, cosechada (capítulo 4)
		S.rec[p.sid] = 2
	await say(T("Cosechas {g} g de {s}. THC: {t}%.", {"g": g, "s": s.n, "t": Datos.pct(thc)}))
	if sobra >= 1:
		var hm := {"m": I18n.v(String(D.MOCHILAS[int(S.items.get("bolsa", 0))].n)).to_lower(), "c": a_caja, "e": sobra - a_caja}
		if a_caja >= 1:
			await say(T("No te cabe todo en la {m}: {c} g van a la caja fuerte. Llevas {e} g de más: guárdalos en cuanto puedas.", hm) if sobra - a_caja >= 1 else T("No te cabe todo en la {m}: {c} g van a la caja fuerte.", hm))
		else:
			await say(T("No te cabe todo en la {m}: Llevas {e} g de más: guárdalos en cuanto puedas.", hm) if sobra - a_caja >= 1 else T("No te cabe todo en la {m}: ", hm))
	if cl == "estrella":
		sfx("enc")
		await say(T("¡Fenotipo estrella! THC ×{t} y cosecha ×{y} sobre la media de la {s}.", {"t": Datos.coma(fe.t), "y": Datos.coma(fe.y), "s": s.n}))
		await say(K("Va a un lote aparte (★). Si le sacaste esquejes, guárdalos: son esta misma planta."))
	elif cl == "floja":
		await say(T("Fenotipo flojo: THC ×{t} y cosecha ×{y} de la media.", {"t": Datos.coma(fe.t), "y": Datos.coma(fe.y)}))
	if sh:
		sfx("enc")
		var ct := K("cogollos morados") if sh == "morada" else (K("cogollos albinos") if sh == "albina" else K("cogollos dorados"))
		await say(T("¡Una planta rara, de {c}! Va a su lote y se paga {x} veces más.", {"c": ct, "x": int(D.SHINY.x)}))
		await say(K("Sus semillas no salen así: solo sus esquejes son esta misma planta. Si no le sacaste ninguno, se ha perdido."))
	if nn:
		var hs := {"n": nn, "s": s.n}
		if cria:
			await say(T("Las plantas de la línea se han polinizado entre ellas: recoges {n} semillas de {s}.", hs))
		elif not fem:
			await say(T("Son semillas regulares: algún macho ha polinizado unas flores. Recoges {n} semillas de {s}.", hs) if nn > 1 else T("Son semillas regulares: algún macho ha polinizado unas flores. Recoges {n} semilla de {s}.", hs))
		else:
			await say(T("Una flor hermafrodita ha polinizado unas pocas: recoges {n} semillas de {s}.", hs) if nn > 1 else T("Una flor hermafrodita ha polinizado unas pocas: recoges {n} semilla de {s}.", hs))
	if not S.items.get("tarros") and not S.flags.get("curado"):   # 1.29, una vez
		S.flags.curado = S.day
		if Datos.CAL:   # MAESTRO [5]: la hierba verde
			await say(T("Sale verde: recién cortada se paga poco, y no está seca del todo hasta los {d} días.", {"d": int(D.VERDE.dias)}))
			await say(K("Con unos tarros de curado (los vende Kiko), en la caja fuerte se cura y vale más cada semana en el tarro."))
		else:
			await say(T("Sale sin curar. Con unos tarros de curado (los vende Kiko), en la caja fuerte se cura en {d} días: algo más de THC y se vende más cara. Sin curar no pierde nada.", {"d": int(D.CURADO.dias)}))   # 1.36: ya no pierde THC; curando, sube
	S.flags.harvest1 = true
	await check_story()

# estabilizar: la línea cruzada consigo misma sube una generación (F1 → F2 → F3 → estable)
func estabilizar(k: String) -> void:
	var s = strain(k)
	var g := Cultivo.gen_de(S, k)
	if await ask(T("¿Estabilizar {s} (F{g})? Gastas 2 semillas y guardas 1.", {"s": s.n, "g": g}), [K("Estabilizar"), K("Cancelar")]) != 0:
		return
	S.seeds[k] -= 2
	if not S.seeds[k]:
		S.seeds.erase(k)
	await accion("cruzar", {"id": "vfx-polen", "x": P.px + 8, "y": P.py - 4})
	sfx("enc")
	await fade(1, true)
	await wait(450)
	await fade(0, true)
	var GE := int(D.GEN_ESTABLE)
	if g + 1 >= GE:
		S.gen.erase(k)
		sfx("get")
		add_seeds(k, 1)
		await say(T("{s} ya es una línea estable: todas sus plantas salen iguales.\nGuardas 1 semilla.", {"s": s.n}))
	else:
		S.gen[k] = g + 1
		add_seeds(k, 1)
		await say(T("Guardas 1 semilla F{f} de {s}: cultívala para tener más.\nFalta una generación para fijarla.", {"f": g + 1, "s": s.n}) if GE - g - 1 == 1 else T("Guardas 1 semilla F{f} de {s}: cultívala para tener más.\nFaltan {n} generaciones para fijarla.", {"f": g + 1, "s": s.n, "n": GE - g - 1}))

# ---------- cama ----------
# la cama del piso y, desde la 1.10, la de casa de ama (txt): allí no hay robo de Darko ni aviso de plagas (las plantas están en el piso).
# El aviso dice solo la luz pagada durmiendo (1.11): la factura es de un día entero, a medianoche (new_day); una siesta que no pasa de las 12, nada
func bed_action(txt := ""):
	var piso: bool = S.map == "home"
	var deco: bool = piso and con_deco().size() > 0
	var c: int = await ask(txt if txt else K("Tu cama. Todavía huele a la colonia de la tía."), [K("Dormir hasta las 7"), K("Siesta de 3 h")] + ([K("Cambiarte de ropa")] if piso else []) + ([K("Decorar la casa")] if deco else []) + [K("Nada")])
	if piso and c == 2:   # ropa y pelo (1.21)
		await vestirte()
		return
	if deco and c == 3:   # 1.27
		await decorar()
		return
	if c > 1:
		return
	await gesto("dormir", {"m": "siesta" if c == 1 else ""})   # 1.54
	await fade(1)
	var mins := 180 if c == 1 else Cultivo.minutos_cama(S, 0)
	var antes := []
	var d0: int = S.day
	for p in S.pots:
		antes.append([true if p.pest else false, true if p.get("dead") else false] if p else null)
	advance_time(mins)
	S.hp = S.hpMax
	build_ents()
	update_hud()
	await wait(500)
	await fade(0)
	var hoy = S.luz if S.get("luz") and S.day > d0 else null
	var diario: bool = piso and not S.flags.get("diario")   # el diario de la tía, bajo la almohada (1.25)
	if diario:
		S.flags.diario = S.day
	save()
	toast(T("Has descansado") + (T(" · Luz −{e}", {"e": Datos.eur(hoy.e)}) if hoy and hoy.e else "") + (T(" · Olor: calor +{o}", {"o": n(hoy.o)}) if hoy and hoy.o else "") + T(" · Partida guardada"), 1800)
	if not piso:
		return
	if diario:
		await almohada()
	if S.day > d0 and S.ch == 7 and not S.flags.get("robo") and (S.money > 1000 or gramos_flor() + nevera_r() / D.ROSIN.rend > 100):
		await robo_darko()   # la amenaza de Darko (1.10; 1.36: con lo de la nevera)
	await aviso_plaga(antes)

# la primera vez que duermes en el piso (1.25): el diario de la tía Maite, bajo la almohada (S.flags.diario; el recetario, en trama)
func almohada() -> void:
	await say(K("Das vueltas y más vueltas. Al ahuecar la almohada notas algo duro dentro de la funda."))
	sfx("get")
	await say(K("Un cuaderno de tapas verdes, gastado de tanto abrirlo: «Cuaderno de cultivo · M.». El diario de la tía Maite."))
	await say(K("Una página por cada variedad que conoció: lo que apuntó de ella, las recetas de sus cruces y dónde guardaba las semillas que no se venden."))
	await say(K("Lo tienes en START → GENOTECA. Algunas landraces no están en ningún banco: habrá que buscarlas."))

static func _lista(L: Array) -> String:
	return L[0] if L.size() == 1 else I18n.T("{a} y {b}", {"a": ", ".join(L.slice(0, -1)), "b": L[-1]})

# al despertar: las que han cogido plaga mientras dormías (y el insecticida que te queda), las que la siguen teniendo sin
# tratar, las que se han secado del todo (antes: [plaga, muerta] de cada plaza al acostarte) y las que florecen con moho porque
# su carpa pasa de HR_OK de noche (09c-sala; 1.11: clima_carpa)
func aviso_plaga(antes: Array) -> void:
	var nuevas := []
	var siguen := []
	var muertas := []
	var moho := []
	var H := huecos()
	var hum := []
	for ci in S.carpas.size():
		hum.append(S.carpas[ci] != null and Cultivo.clima_carpa(S, ci, true).hr > D.HR_OK[1])
	var nc := 0
	for c in S.carpas:
		if c:
			nc += 1
	var varias := nc > 1
	for i in S.pots.size():
		var p = S.pots[i]
		if not p:
			continue
		var a = antes[i] if i < antes.size() and antes[i] else [false, false]
		var nom := T("la {s} ({c}, plaza {p})", {"s": strain(p.sid).n, "c": D.CARPAS[S.carpas[H[i].c].t].n, "p": H[i].j + 1}) if varias else T("la {s} (plaza {p})", {"s": strain(p.sid).n, "p": H[i].j + 1})
		if p.get("dead"):
			if not a[1]:
				muertas.append(nom)
		else:
			if p.pest:
				(siguen if a[0] else nuevas).append(nom)
			if hum[H[i].c] and p.prog >= .65 and p.prog < 1:
				moho.append(nom)
	if nuevas.size():
		var k: int = S.items.insect
		sfx("bad")
		var hp := {"l": _lista(nuevas), "k": k}
		if nuevas.size() > 1:
			await say((T("¡Plaga en {l}! Trátalas con INSECTICIDA: te quedan {k}.", hp) if k > 1 else T("¡Plaga en {l}! Trátalas con INSECTICIDA: te queda {k}.", hp)) if k else T("¡Plaga en {l}! Trátalas con INSECTICIDA: no te queda; cómpralo en el growshop.", hp))
		else:
			await say((T("¡Plaga en {l}! Trátala con INSECTICIDA: te quedan {k}.", hp) if k > 1 else T("¡Plaga en {l}! Trátala con INSECTICIDA: te queda {k}.", hp)) if k else T("¡Plaga en {l}! Trátala con INSECTICIDA: no te queda; cómpralo en el growshop.", hp))
	if siguen.size():
		await say(T("Sigue la plaga en {l}: sin tratar, pierden salud cada hora.", {"l": _lista(siguen)}) if siguen.size() > 1 else T("Sigue la plaga en {l}: sin tratar, pierde salud cada hora.", {"l": _lista(siguen)}))
	if muertas.size():
		await say(T("Se han secado del todo {l}. Retíralas con A.", {"l": _lista(muertas)}) if muertas.size() > 1 else T("Se ha secado del todo {l}. Retírala con A.", {"l": _lista(muertas)}))
	if Datos.CAL:
		var bn := []
		var bs := []
		for i in S.pots.size():
			var p = S.pots[i]
			if p and not p.get("dead") and p.get("bot"):
				var nom := T("la {s} (plaza {p})", {"s": strain(p.sid).n, "p": H[i].j + 1}) if i < H.size() else String(strain(p.sid).n)
				(bn if int(p.bot) == S.day else bs).append(nom)
		if bn.size():
			sfx("bad")
			await say(T("Botritis en {l}: moho gris en los cogollos. Trátala con FUNGICIDA; el PREVENTIVO y el sellado de la carpa la evitan.", {"l": _lista(bn)}))
		if bs.size():
			await say(T("Sigue la botritis en {l}: pierde salud cada día y cosecharás menos.", {"l": _lista(bs)}))
	if moho.size():
		await say(T("Moho en {l}: de noche la carpa pasa del {h} % de humedad. Un extractor a su medida con intractor, un ventilador o un deshumidificador la bajan.", {"l": _lista(moho), "h": n(D.HR_OK[1])}))

# ---------- PC ----------
func pc_action():
	var o := [K("Genoteca")]
	if S.ch >= 2:
		o.append(K("Banco de semillas"))
	o.append_array([K("Notas de la tía"), K("Tienda online")])
	if S.ch >= 4 and S.get("caja") and S.caja.nivel == 1 and not S.caja.get("mejora"):
		o.append(K("Caja empotrada"))
	o.append_array([K("Guardar partida"), K("Apagar")])
	var c: String = o[await ask(K("El ordenador de la tía. Tiene su registro de cultivos de veinte años."), o)]
	if c == "Genoteca":
		await genoteca()
	elif c == "Banco de semillas":
		await banco_semillas()
	elif c == "Notas de la tía":
		await notas_tia()
	elif c == "Tienda online":
		await tienda_online()
	elif c == "Caja empotrada":
		await pedir_caja()
	elif c == "Guardar partida":
		await say(K("Partida guardada.") if save() else K("No se ha podido guardar la partida."))

# ---------- salón (12c-salon, 1.10): los muebles se compran por internet y llegan al día siguiente ----------
func por_hora(l: Array) -> String:
	return l[(int(S.day) * 24 + int(S.min) / 60) % l.size()]

func noticia() -> String:
	if S.heat >= 60:
		return K("Noticias: la policía busca un cultivo de interior en Ribera Verde. Los vecinos denuncian olor a marihuana en varios portales.")
	if S.heat >= 30:
		return K("Noticias: detenido en el puerto un hombre con dos kilos de marihuana escondidos en una furgoneta de reparto.")
	return K("Noticias: el tiempo. Nubes y claros en la costa y la ría en calma. Nada que contar en Ribera Verde.")

func mueble_action(k):
	if k == "carro":
		await carro_action()
		return
	if k == "sillon":
		var o := ([K("Leer el diario de la tía Maite")] if S.flags.get("diario") else []) + [K("Cambiar el tapizado"), K("Nada")]
		var oi: int = await ask(K("Tu sillón de lectura. La lámpara da una luz cálida."), o)
		var c: String = o[oi] if oi >= 0 and oi < o.size() else ""
		if c == "Cambiar el tapizado":
			await cambiar_deco(k)
			return
		if c != "Leer el diario de la tía Maite":
			return
		advance_time(30)
		update_hud()
		await recetario()
		return
	if k == "cuadro":
		var o := [K("Cambiar la lámina"), K("Nada")]
		var oi: int = await ask(T("En la pared del salón: {c}.", {"c": I18n.v(String(D.DECO.cuadro.v[deco_v("cuadro")])).to_lower()}), o)
		if oi == 0:
			await cambiar_deco(k)
		return
	if k == "sofa":
		var o := [K("Echar una cabezada (1 h)")]
		if "tv" in muebles_ya():
			o.append(K("Ver la tele"))
		o.append(K("Cambiar el tapizado"))
		o.append(K("Nada"))
		var oi: int = await ask(K("Tu sofá. Todavía huele a nuevo."), o)
		var c: String = o[oi] if oi >= 0 and oi < o.size() else ""
		if c == "Ver la tele":
			await mueble_action("tv")
			return
		if c == "Cambiar el tapizado":
			await cambiar_deco(k)
			return
		if c != "Echar una cabezada (1 h)":
			return
		await fade(1)
		advance_time(60)
		S.hp = min(S.hpMax, S.hp + 5)
		build_ents()
		update_hud()
		await wait(300)
		await fade(0)
		await say(K("Una cabezada en el sofá: +5 de vida."))
		return
	if k == "tv":
		var o := [K("Noticias"), K("Documental"), K("Nada")]
		var oi: int = await ask(K("La tele."), o)
		var c: String = o[oi] if oi >= 0 and oi < o.size() else ""
		if c == "Nada" or c == "":
			return
		var t := noticia() if c == "Noticias" else por_hora(D.DOCU)
		advance_time(60)
		update_hud()
		await say(t)
		return
	var o := [K("Jugar (2 h)"), K("Foro de cultivo"), K("Tienda online"), K("Apagar")]
	var oi: int = await ask(K("El PC gaming. Los ventiladores brillan de colores."), o)
	var c: String = o[oi] if oi >= 0 and oi < o.size() else ""
	if c == "Jugar (2 h)":
		var t := por_hora(D.JUEGOS)
		await fade(1)
		advance_time(120)
		build_ents()
		update_hud()
		await wait(300)
		await fade(0)
		await say(t)
	elif c == "Foro de cultivo":
		var t := por_hora(D.FORO)
		advance_time(30)
		update_hud()
		await say(T("Foro de cultivo · {t}", {"t": t}))
	elif c == "Tienda online":
		await tienda_online()

# personalizar la casa (1.16): elegir el tapizado o la lámina (DECO, 12c-salon)
func cambiar_deco(k: String) -> void:
	var Dk: Dictionary = D.DECO[k]
	var v := deco_v(k)
	var items := []
	for j in Dk.v.size():
		items.append({"label": T("{x} · ahora", {"x": Dk.v[j]}) if j == v else Dk.v[j]})
	items.append({"label": K("Volver")})
	var i: int = await menu(items, {"title": T("Cambiar {q}", {"q": Dk.q}), "initial": v})
	if i < 0 or i >= Dk.v.size() or i == v:
		return
	S.deco[k] = i
	sfx("sel")
	montar_casa()
	var art: String = D.MUEBLES[k].art
	var hc := {"q": Dk.q, "m": art.substr(3) if art.begins_with("el ") else art, "v": I18n.v(String(Dk.v[i])).to_lower()}
	await say(T("Cambias {q} del {m}: {v}.", hc) if art.begins_with("el ") else T("Cambias {q} de {m}: {v}.", hc))

# decorar la casa (1.27): en la cama del piso, lo que tiene DECO de lo que ya ha llegado
func con_deco() -> Array:
	return muebles_ya().filter(func(k): return D.DECO.has(k))

func decorar() -> void:
	var i := 0
	while true:
		var ks := con_deco()
		var items := []
		for k in ks:
			var a: String = D.MUEBLES[k].art
			items.append({"label": "%s: %s" % [a.left(1).to_upper() + a.substr(1), String(D.DECO[k].v[deco_v(k)]).to_lower()]})
		items.append({"label": K("Listo")})
		i = await menu(items, {"title": K("Decorar la casa"), "initial": i})
		if i < 0 or i >= ks.size():
			return
		await cambiar_deco(ks[i])

# reformas (1.27, REFORMA de 12c-salon): el suelo y las paredes, por la tienda online; el instalador o el pintor viene al día siguiente
func reformas() -> void:
	var i := 0
	while true:
		var items := []
		var ks := []
		for k in D.REFORMA:
			var R: Dictionary = D.REFORMA[k]
			var v := deco_v(k)
			var o = S.obra.get(k) if S.get("obra") is Dictionary else null
			for j in R.v.size():
				var en: bool = j == v
				var pd: bool = o != null and int(o.v) == j
				ks.append([k, j])
				items.append({"label": "%s: %s" % [I18n.v(String(R.n)), I18n.v(String(R.v[j][0]))] + (T(" · pedido") if pd else T(" · en casa") if en else ""), "right": Datos.eur(R.v[j][1]), "disabled": o != null or en,
					"desc": I18n.v(String(R.v[j][2])) + (T("\n{q} viene mañana.", {"q": R.quien}) if pd else T("\nYa hay una obra pedida: viene mañana.") if o != null else "" if en else T("\n{q} viene mañana.", {"q": R.quien}))})
		items.append({"label": K("Volver"), "desc": K("Pagas con lo que llevas y, si no llega, con la caja fuerte.")})
		i = await menu(items, {"cls": "full", "title": K("REFORMAS"), "title2": T("Suelo y paredes · tienes {e}", {"e": Datos.eur(S.money + caja_e())}), "desc": true, "initial": i})
		if i < 0 or i >= ks.size():
			return
		var k: String = ks[i][0]
		var j: int = ks[i][1]
		var R: Dictionary = D.REFORMA[k]
		var p = R.v[j][1]
		if not await tarjeta(p, K("Reforma") + " · " + String(R.n).to_lower()):   # 1.35: con tarjeta
			continue
		if not (S.get("obra") is Dictionary):
			S.obra = {}
		S.obra[k] = {"v": j, "dia": S.day + 1}
		sfx("coin")
		toast(T("Pedido: {a}, {b} · mañana", {"a": I18n.v(String(R.n)).to_lower(), "b": I18n.v(String(R.v[j][0])).to_lower()}), 1400)

# ropa y pelo (1.21, vestirte): desde la cama del piso, la camiseta, el pantalón, la gorra y el pelo (S.ropa[k], índice en ROPA[k].v)
func vestirte() -> void:
	while true:
		var ks: Array = D.ROPA.keys()
		var items := []
		for k in ks:
			items.append({"label": "%s: %s" % [I18n.v(String(D.ROPA[k].n)), I18n.v(String(D.ROPA[k].v[ropa_v(k)][0])).to_lower()]})
		items.append({"label": K("Listo")})
		var i: int = await menu(items, {"title": K("Ropa y pelo")})
		if i < 0 or i >= ks.size():
			return
		var k: String = ks[i]
		var R: Dictionary = D.ROPA[k]
		var v := ropa_v(k)
		var its := []
		for n in R.v.size():
			its.append({"label": T("{x} · ahora", {"x": R.v[n][0]}) if n == v else R.v[n][0]})
		its.append({"label": K("Volver")})
		var j: int = await menu(its, {"title": R.n, "initial": v})
		if j >= 0 and j < R.v.size() and j != v:
			S.ropa[k] = j
			sfx("sel")

func tienda_online() -> void:
	var i := 0
	while true:
		var ks: Array = D.MUEBLES.keys().filter(func(k): return not D.MUEBLES[k].get("grow"))
		var vs: Array = D.VEHICULOS.keys().filter(func(k): return not D.VEHICULOS[k].get("conce"))   # 1.43: la moto, en el concesionario
		var ya := muebles_ya()
		var items := []
		for k in ks:
			var m: Dictionary = D.MUEBLES[k]
			var en: bool = k in ya
			var pd: bool = not en and S.get("muebles") is Dictionary and float(S.muebles.get(k, 0)) > 0
			var al: bool = k == "cartel"   # el póster, al dormitorio (1.27)
			items.append({"label": I18n.v(String(m.n)) + (T(" · en casa") if en else T(" · pedido") if pd else ""), "right": Datos.eur(m.p), "disabled": en or pd,
				"desc": I18n.v(String(m.d)) + ("" if en else (T("\nLlega mañana: te lo suben a casa.") if al else T("\nLlega mañana: te lo suben al salón.")) if pd else (T("\nLlega mañana y te lo suben a casa.") if al else T("\nLlega mañana y te lo suben al salón.")))})
		for k in vs:   # el patinete y la bici (1.13)
			var v: Dictionary = D.VEHICULOS[k]
			var d = S.veh.get(k) if S.get("veh") is Dictionary else null
			var en: bool = d != null and float(d) <= S.day
			items.append({"label": I18n.v(String(v.n)) + (T(" · tuyo") if en else T(" · pedido") if d else ""), "right": Datos.eur(v.p), "disabled": d != null and float(d) > 0,
				"desc": I18n.v(String(v.d)) + ("" if en else T("\nLlega mañana: te lo dejan en el portal."))})
		var AR: Dictionary = D.NEVERA.arcon   # el arcón congelador (1.39): 5 kg más de extractos, en frío
		var ar = S.nevera.get("arcon") if S.get("nevera") != null else null
		items.append({"label": I18n.v(String(AR.n)) + (T(" · en casa") if ar == 1 else T(" · pedido") if ar != null else ""), "right": Datos.eur(AR.p), "disabled": ar != null,
			"desc": I18n.v(String(AR.d)) + (T("\nLa nevera de serie: {g}.", {"g": Datos.coma(D.NEVERA.g / 1000.0) + " kg"}) if ar == null else "")})
		items.append({"label": K("Reformas: suelo y paredes"), "desc": K("El suelo y las paredes del piso: el instalador o el pintor vienen al día siguiente.")})   # 1.27
		if Datos.CAL:   # 1.43.6: el camarote
			items.append({"label": K("El camarote: almacén"), "desc": K("Habilitar el camarote de arriba como almacén, las estanterías de tarros de cristal de 10 L y los sobres de humedad.")})
		var SO: Dictionary = D.SOTANO
		var sot_ok: bool = Datos.CAL and not Datos.PLAY and S.ch >= int(SO.ch)   # 1.51: el sótano de casa, para setas
		if sot_ok:
			var sd = S.sot.get("d") if S.get("sot") is Dictionary else null
			items.append({"label": I18n.v(String(SO.obra.n)) + (T(" · hecho") if sd != null and float(sd) <= S.day else T(" · mañana") if sd != null else ""), "right": Datos.eur(SO.obra.p), "disabled": sd != null, "desc": SO.obra.d})
		var ienv := -1
		if Datos.CAL and S.get("coches") is Dictionary and not S.coches.is_empty():   # MAESTRO [3]: la envasadora al vacío, para el maletero
			var VA: Dictionary = D.MALETERO.vacio
			var tv: bool = int(S.items.get("vacio", 0)) > 0
			ienv = items.size() - ks.size() - vs.size()
			items.append({"label": K("Envasadora al vacío") + (T(" · en casa") if tv else ""), "right": Datos.eur(VA.p), "disabled": tv,
				"desc": K("Para envasar lo del maletero en bolsas selladas: en un registro de tráfico se nota menos.")})
		items.append({"label": K("Salir"), "desc": K("Con tarjeta, de la cuenta del banco.")})
		i = await menu(items, {"cls": "full", "title": K("TIENDA ONLINE"), "title2": T("Muebles y transporte · en la cuenta {e}", {"e": Datos.eur(S.banco)}), "desc": true, "initial": i})
		if i == ks.size() + vs.size():
			if ar == null and await tarjeta(AR.p, K("Tienda online") + " · " + AR.n):
				nevera().arcon = -(S.day + 1)   # pedido: el día en que llega, en negativo; 1, en casa
				sfx("coin")
				toast(T("Pedido: {n} · llega mañana", {"n": AR.n}), 1400)
			continue
		if i == ks.size() + vs.size() + 1:
			await reformas()
			continue
		if Datos.CAL and i == ks.size() + vs.size() + 2:
			await camarote_tienda()
			continue
		if sot_ok and i == ks.size() + vs.size() + 3:
			if not (S.get("sot") is Dictionary) and await tarjeta(SO.obra.p, K("Tienda online") + " · " + SO.obra.n):
				S.sot = {"d": S.day + 1, "bandejas": [], "g": 0, "fr": []}
				sfx("coin")
				toast(T("Pedido: {n} · los obreros vienen mañana", {"n": SO.obra.n}), 1400)
			continue
		if ienv >= 0 and i == ks.size() + vs.size() + ienv:
			if await tarjeta(D.MALETERO.vacio.p, K("Tienda online") + " · " + K("Envasadora al vacío")):
				S.items.vacio = 1
				sfx("coin")
				toast(K("La envasadora, en casa: se usa desde el maletero."), 1400)
			continue
		if i < 0 or i >= ks.size() + vs.size():
			return
		var es_m: bool = i < ks.size()
		var k: String = ks[i] if es_m else vs[i - ks.size()]
		var m: Dictionary = D.MUEBLES[k] if es_m else D.VEHICULOS[k]
		if not await tarjeta(m.p, K("Tienda online") + " · " + m.n):   # 1.35: con tarjeta
			continue
		var cl: String = "muebles" if es_m else "veh"
		if not (S.get(cl) is Dictionary):
			S[cl] = {}
		S[cl][k] = S.day + 1
		sfx("coin")
		toast(T("Pedido: {n} · llega mañana", {"n": m.n}), 1400)

# el camarote (1.43.6, lo pidió el usuario: «habilitar el camarote de arriba… como almacén» con «botes más grandes de cristal con
# bóvedas de humedad»): la obra, las estanterías de 6 tarros de 10 L (hasta CAMAROTE.est.max) y las cajas de sobres al 62 %; todo
# con tarjeta y al día siguiente (llega_camarote)
func camarote_tienda() -> void:
	var CM: Dictionary = D.CAMAROTE
	var i := 0
	while true:
		var c := cam()
		var hecha: bool = c.has("d")
		var lista := cam_ya()
		var ne: int = c.get("e", []).size()
		var pend_e: int = ne - cam_est()
		var pend_s := 0
		for q in c.get("sp", []):
			pend_s += int(q[1])
		var items := [
			{"label": I18n.v(String(CM.obra.n)) + (T(" · hecho") if lista else T(" · mañana") if hecha else ""), "right": Datos.eur(CM.obra.p), "disabled": hecha, "desc": CM.obra.d},
			{"label": "%s · %d/%d%s" % [I18n.v(String(CM.est.n)), ne, int(CM.est.max), T(" · {n} mañana", {"n": pend_e}) if pend_e else ""], "right": Datos.eur(CM.est.p), "disabled": not hecha or ne >= int(CM.est.max),
				"desc": (CM.est.d % int(CM.tarro)) + ("" if hecha else T("\nAntes hay que habilitar el camarote."))},
			{"label": I18n.v(String(CM.sob.n)) + (T(" · quedan {n}", {"n": ceili(float(c.get("sob", 0)) - 1e-9)}) if float(c.get("sob", 0)) > 0 else "") + (T(" · {n} mañana", {"n": pend_s}) if pend_s else ""), "right": Datos.eur(CM.sob.p), "disabled": not hecha,
				"desc": (CM.sob.d % int(CM.dura)) + T("\nCon sobres, lo curado se afina en {d} días: se vende un {p} % más caro.", {"d": int(CM.af), "p": Datos.jsround(CM.extra * 100)})},
			{"label": K("Volver")}]
		i = await menu(items, {"cls": "full", "title": K("EL CAMAROTE"), "title2": T("Almacén · en la cuenta {e}", {"e": Datos.eur(S.banco)}), "desc": true, "initial": i})
		if i < 0 or i > 2:
			return
		var art: Dictionary = [CM.obra, CM.est, CM.sob][i]
		if not await tarjeta(art.p, K("Tienda online") + " · " + art.n):
			continue
		if not (S.get("cam") is Dictionary):
			S.cam = {"e": [], "sob": 0.0, "sp": [], "buds": {}}
		if i == 0:
			S.cam.d = S.day + 1
		elif i == 1:
			S.cam.e.append(S.day + 1)
		else:
			S.cam.sp.append([S.day + 1, int(CM.sob.u)])
		sfx("coin")
		toast(T("Pedido: {n} · los obreros vienen mañana", {"n": art.n}) if i == 0 else T("Pedido: {n} · llega mañana", {"n": art.n}), 1400)

func llega_camarote() -> void:
	if not Datos.CAL or not (S.get("cam") is Dictionary):
		return
	var av := []
	if S.cam.has("d") and int(S.cam.d) == S.day:
		av.append(K("Los obreros acaban el camarote: aislado, con pladur, tarima, luz y deshumidificador. Se sube por la escalera escamoteable de entre las carpas."))
	var ne: int = S.cam.e.filter(func(d): return int(d) == S.day).size()
	if ne:
		av.append(T("Llega la estantería de tarros de 10 L: te la suben al camarote. Caben ahora {kg} kg.", {"kg": Datos.coma(cam_cap() / 1000.0)}) if ne == 1 else T("Llegan {n} estanterías de tarros de 10 L: te las suben al camarote. Caben ahora {kg} kg.", {"n": ne, "kg": Datos.coma(cam_cap() / 1000.0)}))
	var quedan := []
	for q in S.cam.sp:
		if int(q[0]) <= S.day:
			S.cam.sob = float(S.cam.get("sob", 0)) + int(q[1])
			av.append(T("Llegan los sobres de humedad al 62 %: uno en cada tarro del camarote (quedan {n}).", {"n": ceili(S.cam.sob - 1e-9)}))
		else:
			quedan.append(q)
	S.cam.sp = quedan
	if av.size():
		montar_casa()
		queue("camarote", func():
			sfx("get")
			for t in av:
				await say(t), [["", av]])

func llega_mueble() -> void:
	llega_camarote()   # 1.43.6
	if Datos.CAL and S.get("sot") is Dictionary and int(S.sot.get("d", -1)) == S.day:   # 1.51: el sótano
		var L := [K("Los obreros acaban el sótano: sin trastos, impermeabilizado, con luz, desagüe y tres estanterías de rejilla. Se baja por la puerta del dormitorio. Las bandejas te las prepara Txomin.")]
		queue("sotano", func():
			sfx("get")
			await say(L[0]), [["", L]])
	if S.get("nevera") != null and S.nevera.get("arcon") != null and S.nevera.arcon != 1 and -int(S.nevera.arcon) <= S.day:   # el arcón (1.39)
		S.nevera.arcon = 1
		var L := [T("Llega el mensajero con el arcón congelador: te lo dejan enchufado al lado de la nevera. En frío caben ahora {kg}.", {"kg": Datos.coma(nevera_cap() / 1000.0) + " kg"})]
		queue("arcon", func():
			sfx("get")
			await say(L[0]), [["", L]])
	var ob := []   # las reformas (1.27)
	if S.get("obra") is Dictionary:
		for k in S.obra.keys():
			if S.obra[k].dia <= S.day:
				ob.append(k)
	if ob.size():
		for k in ob:
			S.deco[k] = S.obra[k].v
			S.obra.erase(k)
		montar_casa()
		queue("obra", func():
			sfx("get")
			for k in ob:
				var R: Dictionary = D.REFORMA[k]
				await say(T("{q} viene a primera hora: {n}, {v}.", {"q": R.quien, "n": R.nuevo, "v": I18n.v(String(R.v[deco_v(k)][0])).to_lower()})))
	var vs := []   # el patinete y la bici (1.13)
	if S.get("veh") is Dictionary:
		for k in D.VEHICULOS:
			if S.veh.get(k) == S.day:
				vs.append(D.VEHICULOS[k].art)
	if vs.size():
		var L := [T("Llega el mensajero con {l}. En la calle vas montado; con B, aún más rápido.", {"l": _lista(vs)})]
		queue("vehiculo", func():
			sfx("get")
			await say(L[0]), [["", L]])
	var l := []
	var on := []
	var gr := []
	if S.get("muebles") is Dictionary:
		for k in D.MUEBLES:
			if S.muebles.get(k) == S.day:
				l.append(D.MUEBLES[k].art)
				(gr if D.MUEBLES[k].get("grow") else on).append(D.MUEBLES[k].art)
	if l.is_empty():
		return
	montar_casa()
	# si estás donde lo montan, te apartas a la casilla libre más cercana (llegaMueble en el HTML)
	if S.map == "home" and tile_solid(MAPS.home, P.x, P.y):
		var ok := false
		for r in range(1, 4):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if ok or maxi(absi(dx), absi(dy)) != r or tile_solid(MAPS.home, P.x + dx, P.y + dy):
						continue
					var x: int = P.x + dx
					var y: int = P.y + dy
					P.x = x
					P.y = y
					P.px = x * 16.0
					P.py = y * 16.0
					P.fx = x
					P.fy = y
					P.moving = false
					S.x = x
					S.y = y
					ok = true
	queue("mueble", func():
		sfx("get")
		if on.size():
			await say(T("Llega el mensajero con {l}: te lo dejan montado en casa.", {"l": _lista(on)}) if D.MUEBLES.cartel.art in on else T("Llega el mensajero con {l}: te lo dejan montado en el salón.", {"l": _lista(on)}))   # el póster, en el dormitorio (1.27)
		if gr.size():
			await say(T("Kiko te sube {l} y te lo deja montado delante de las carpas.", {"l": _lista(gr)})))

# el carro de esquejes (1.11, carroAction): en la tabla de corte, los del propagador se pinchan en las bandejas, donde aguantan
# CARRO.dias desde ese día; se plantan desde la plaza vacía (plantar)
func carro_action() -> void:
	# (lo pidió el usuario): el carro se ve tal cual, dos bandejas de tacos (arriba y abajo) en vez de un menú; A en un taco
	# vacío pincha los del propagador y A en un esqueje lo nombra o lo tira
	var cap: int = D.CARRO.bandejas * D.CARRO.plazas
	var sel := mini(S.bandejas.size(), cap - 1)
	while true:
		var q = await elegir_carro(sel)
		if q == null:
			return
		sel = int(q)
		var nb: int = S.bandejas.size()
		if sel < nb:
			await esqueje_accion(S.bandejas[sel], S.bandejas)
			sel = mini(sel, maxi(0, S.bandejas.size()))
			continue
		if S.esquejes.is_empty():
			await say(K("Taco vacío. Saca esquejes de una madre en vegetativo y pínchalos aquí."))
			continue
		var m: int = mini(cap - nb, S.esquejes.size())
		for e in S.esquejes.slice(0, m):
			S.bandejas.append({"sid": e.sid, "f": e.f, "dia": S.day})
		S.esquejes = S.esquejes.slice(m)
		sfx("sel")
		await say(T("En la tabla de corte, corte en bisel y hormona: pinchas {n} esquejes.", {"n": m}) if m > 1 else T("En la tabla de corte, corte en bisel y hormona: pinchas 1 esqueje."))
		await say(T("En las bandejas aguantan hasta el {d}: plántalos cuando haya hueco.", {"d": Datos.fd(S.day + D.CARRO.dias, S.day)}))
		var r: int = S.esquejes.size()
		if r:
			await say(T("No caben {n}: se quedan en el propagador.", {"n": r}) if r > 1 else K("No cabe 1: se queda en el propagador."))
		sel = mini(S.bandejas.size(), cap - 1)

# la vista del carro (en trama.gd): el taco elegido (0-23: la bandeja de arriba, 0-11, y la de abajo, 12-23) o null
func elegir_carro(_i0 := 0):
	return null

# banco de semillas: las landraces en sobres de SOBRE semillas; el pedido llega al día siguiente (new_day)
func banco_semillas() -> void:
	var i := 0
	while true:
		var l := []
		for b in D.BANCO:
			if S.ch >= b[2]:
				l.append(b)
		var items := []
		for b in l:
			var s: Dictionary = D.STRAINS[b[0]]
			var np: int = S.pedido.count(b[0])
			items.append({"label": s.n + (T(" · pedida") if np else ""), "right": Datos.eur(b[1]), "sw": s.c, "ic": ic_cog(b[0]), "desc": strain_line(b[0]) + "\n" + I18n.v(String(s.h))})
		items.append({"label": K("Salir"), "desc": K("Los pedidos llegan mañana por la mañana.")})
		i = await menu(items, {"cls": "full", "title": K("BANCO DE SEMILLAS"), "title2": T("Sobres de {n} · en la cuenta {e}", {"n": n(D.SOBRE), "e": Datos.eur(S.banco)}), "desc": true, "initial": i})
		if i < 0 or i >= l.size():
			return
		var k: String = l[i][0]
		var pr := int(l[i][1])
		if not await tarjeta(pr, K("Banco de semillas")):   # 1.35: con tarjeta
			continue
		S.pedido.append(k)
		sfx("coin")
		toast(T("Pedido: {n} · llega mañana", {"n": D.STRAINS[k].n}), 1400)

func recibir_pedido() -> void:
	if S.pedido.is_empty():
		return
	var c := {}
	for k in S.pedido:
		c[k] = c.get(k, 0) + int(D.SOBRE)
	S.pedido = []
	var nl := []
	for k in c:
		S.seeds[k] = S.seeds.get(k, 0) + c[k]
		discover(k)
		nl.append("%s ×%d" % [D.STRAINS[k].n, c[k]])
	var L := [T("Llega el paquete del banco de semillas:\n{l} semillas.", {"l": ", ".join(nl)})]
	queue("pedido", func():
		sfx("get")
		await say(L[0])
		await check_story(), [["", L]])

func letter_action():
	if S.flags.get("letter"):
		await say(K("La carta de la tía Maite. «Cuida el armario. Y perdona lo de Baltasar.»"))
		return
	await say(K("Hay una carta encima de la mesa. Es de la tía Maite."))
	await talk(K("CARTA"), [K("«{N}: si lees esto, el piso es tuyo. Cuídalo.»"), K("«Al fondo del salón está mi armario de cultivo. Lo he tenido treinta años y nunca me ha fallado.»"),
		K("«Pásate por el growshop de Kiko, aquí al lado. Él te enseñará lo que yo no pude.»"), K("«Le debo dinero a Baltasar, el del bar El Ancla. No es buena gente. Lo siento.»")])
	S.flags.letter = true
	show_objective()

# ---------- el autobús de la comarca (1.10, paradaAction de 08-mundo) ----------
# en el poste de la parada: a dónde, cuánto y cuánto tarda; el reloj corre lo que dura el viaje. El primer viaje (del pueblo al
# piso: llegando()) lo paga ama y solo va a Ribera Verde
func viaje(a: String, b: String) -> Dictionary:
	return {"min": int(D.PARADAS[a].min + D.PARADAS[b].min), "eur": D.PARADAS[a].eur + D.PARADAS[b].eur}

# El viaje, de perfil, como pantalla de carga (escena_viaje.gd): el autobús o tu vehículo por la carretera; A o B lo pasan
var VIAJE_V = null   # {veh, de, a, min, h, t0}
var gancho_viaje := Callable()   # (vehículo, de, a) · las pruebas lo apuntan sin esperar
func anim_viaje(veh: String, de: String, a: String, mins: int) -> void:
	if not Datos.CAL:
		return
	if gancho_viaje.is_valid():
		gancho_viaje.call(veh, de, a)
		return
	VIAJE_V = {"veh": veh, "de": String(D.PARADAS[de].n) if D.PARADAS.has(de) else de, "a": String(D.PARADAS[a].n) if D.PARADAS.has(a) else a, "min": mins, "h": int(S.min), "t0": M.reloj}
	hud.hide()
	await fade(0)
	var pr := Motor.Prom.new()
	var st := {"fuera": false}
	var cierra := func():
		if not st.fuera:
			st.fuera = true
			pop()
		pr.res(0)
	push(func(b: String):
		if b == "A" or b == "B":
			cierra.call())
	M.timeout(cierra, EscViaje.DUR + 200)
	await Motor.espera(pr)
	await fade(1)
	VIAJE_V = null

func parada_action():
	var aqui: String = S.map
	var pa: Dictionary = D.PARADAS[aqui]
	var mios := coches_mios()   # 1.43: con un vehículo del concesionario, a dónde quieras y a cualquier hora
	if Datos.CAL:   # MAESTRO [3]: solo los que están en este pueblo (en Ribera Verde, en el garaje; en los demás, en el aparcamiento)
		mios = mios.filter(func(k): return donde(k) == aqui and aqui != GARAJE)   # en Ribera Verde se sale del garaje
	if mios.size() and not llegando():
		var ops: Array = [K("En autobús")]
		for k in mios:
			ops.append(T("En {v}", {"v": String(D.CONCE.v[k].art)}))
		if Datos.CAL:
			for k in mios:
				ops.append(T("Maletero {dv}", {"dv": de_art(String(D.CONCE.v[k].art))}))
		ops.append(K("Nada"))
		var c: int = await ask(T("PARADA DE {p}\n¿Cómo vas?", {"p": I18n.v(String(pa.n)).to_upper()}), ops)
		if c < 0 or c >= ops.size() - 1:
			return
		if c > mios.size():
			await maletero(mios[c - 1 - mios.size()])
			return
		if c > 0:
			await conducir(mios[c - 1])
			return
	if S.min < int(D.BUS_HORAS[0]) or S.min > int(D.BUS_HORAS[1]):   # fuera de horario: se puede esperar al primero (el reloj corre hasta las 7:00)
		if await ask(T("PARADA DE {p}\nEl primer autobús pasa a las 7:00 y el último, a las 21:00.", {"p": I18n.v(String(pa.n)).to_upper()}), [K("Esperar al de las 7:00"), K("Nada")]) != 0:
			return
		await fade(1)
		advance_time((int(D.BUS_HORAS[0]) - int(S.min) + 1440) % 1440)
		build_ents()
		update_hud()
		await wait(300)
		await fade(0)
		await say(K("Las siete. Llega el primer autobús, medio vacío."))
	var ama := llegando()
	var ds := []
	if ama:
		ds = ["town"]
	else:
		for k in D.PARADAS:
			if k != aqui and S.ch >= int(D.PARADAS[k].cap):   # las líneas, por capítulos (1.14)
				ds.append(k)
	var it := []
	for k in ds:
		var v := viaje(aqui, k)
		it.append({"label": D.PARADAS[k].n, "right": K("billete de ama") if ama else T("{e} · {m} min", {"e": Datos.eur(v.eur), "m": int(v.min)})})
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿A dónde vas?")})
	if i < 0 or i >= ds.size():
		return
	var k: String = ds[i]
	var v := viaje(aqui, k)
	if not ama:
		if S.money < v.eur:
			await say(T("El billete hasta {d} cuesta {e}. No te llega.", {"d": D.PARADAS[k].n, "e": Datos.eur(v.eur)}))
			return
		S.money -= v.eur
	sfx("door")
	await fade(1)
	await anim_viaje("bus", aqui, k, int(v.min))
	advance_time(v.min)
	var a: Array = D.PARADAS[k].a
	enter_map(k, int(a[0]), int(a[1]), a[2])
	if S.clientsDay != S.day:
		spawn_clients()
	update_hud()
	await wait(80)
	await fade(0)
	if ama:
		S.flags.llegada = true
		await say(K("Ribera Verde. El piso de la tía es el del tejado rojo, al otro lado de la calle."))
		show_objective()

# ---------- mesa de genética ----------
func _mk(l: Array) -> Array:
	var o := []
	for e in l:
		var s = strain(e[0])
		o.append({"label": s.n, "right": "×" + n(e[1]), "sw": s.c, "ic": ic_cog(e[0]), "desc": strain_line(e[0])})
	return o

# la mesa (1.35): las extracciones que puedes hacer (extr_ya; extraer, en trama), cruzar o nada
func lab_action():
	var L := extr_ya()
	if not L.is_empty():
		var c: int = await ask(K("La mesa de la tía. ¿Qué haces?"), L.map(func(t): return D.EXTR[t].v) + [K("Cruzar semillas"), K("Nada")])
		if c >= 0 and c < L.size():
			await extraer(L[c])
			return
		if c != L.size():
			return
	if not S.flags.get("lab"):
		await say(K("Una mesa con un microscopio viejo y frascos. Kiko sabrá qué hacer con esto."))
		return
	var GE := int(D.GEN_ESTABLE)
	var hay := false
	for e in _own():
		if e[1] >= 2 and Cultivo.gen_de(S, e[0]) < GE:
			hay = true
	if _own().size() < 2 and not hay:
		await say(K("MESA DE GENÉTICA: necesitas semillas de dos variedades distintas para cruzar, o 2 de una línea sin estabilizar."))
		return
	var l1 := _own()
	var a: int = await menu(_mk(l1), {"cls": "full", "title": K("CRUCE · MADRE"), "desc": true})
	if a < 0:
		return
	var A: String = l1[a][0]
	var l2 := _own().filter(func(e): return e[0] != A)
	var ga := Cultivo.gen_de(S, A)
	var it2 := _mk(l2)
	if ga < GE and S.seeds[A] >= 2:
		it2.push_front({"label": T("{s} · estabilizar", {"s": strain(A).n}), "right": T("F{a}→{b}", {"a": ga, "b": ("F%d" % (ga + 1)) if ga + 1 < GE else K("estable")}), "sw": strain(A).c, "ic": ic_cog(A),
			"desc": T("Cruzas dos plantas de la misma línea y guardas la mejor semilla. Gastas 2 y te quedas 1.\nEn la F{g} la variedad queda fijada: todas sus plantas salen iguales.", {"g": GE})})
	if it2.is_empty():
		await say(T("Para cruzar {s} necesitas semillas de otra variedad.", {"s": strain(A).n}))
		return
	var b: int = await menu(it2, {"cls": "full", "title": K("CRUCE · PADRE"), "title2": strain(A).n, "desc": true})
	if b < 0:
		return
	if it2.size() > l2.size() and b == 0:
		await estabilizar(A)
		return
	var Bk: String = l2[b - (it2.size() - l2.size())][0]
	if await ask(T("¿Cruzar {a} × {b}? Gastas 1 semilla de cada.", {"a": strain(A).n, "b": strain(Bk).n}), [K("Cruzar"), K("Cancelar")]) != 0:
		return
	S.seeds[A] -= 1
	S.seeds[Bk] -= 1
	for k in [A, Bk]:
		if not S.seeds[k]:
			S.seeds.erase(k)
	var r := Datos.cross_result(S, A, Bk)
	if Datos.CAL:   # MAESTRO [5]: la línea nueva, con lo mejor de las dos
		Cultivo.cruza_iv(S, A, Bk, r)
	var is_new: bool = not S.disc.get(r)
	var s = strain(r)
	if is_new and not D.SHOP.any(func(it): return it.get("sid") == r):   # la de tienda sigue estable
		S.gen[r] = 1
	if Datos.receta_de(S, A, Bk) and not S.rec.get(r):   # de receta, sacada en la mesa: falta cosecharla (capítulo 4)
		S.rec[r] = 1
	await accion("cruzar", {"id": "vfx-polen", "x": P.px + 8, "y": P.py - 4})
	sfx("enc")
	await fade(1, true)
	await wait(450)
	await fade(0, true)
	add_seeds(r, 2)
	if is_new:
		sfx("get")
		await say(T("Nueva variedad: {s}.", {"s": s.n}))
		await say(T("THC {t}% · ~{g} g/m² · {d} días.\nObtienes 2 semillas F1: la línea aún no es estable.", {"t": Datos.pct(s.thc), "g": int(gm2(s)), "d": Datos.coma(s.d)}))
		if r == "leyenda":
			await say(K("Te tiemblan las manos: es JACK HERER."))
			await talk(K("SMS · KIKO"), [K("¿Jack Herer? ¿De semilla propia? Llevo veinte años detrás de ella."), K("Tu tía estaría orgullosa. Estabilízala y guárdala bien: eso vale más que el piso.")])
	else:
		await say(T("Obtienes 2 semillas de {s}.", {"s": s.n}))
	await check_story()

# ---------- vista de carpa (09b-carpa) ----------
func vc_geo(ci: int) -> Dictionary:
	return Vista.geo(S, ci)

func maceta_px(k: String) -> Dictionary:
	var m: Array = D.MACETA_CM.get(k, D.MACETA_CM.plastico7)
	return {"w": Datos.jsround(m[0] * D.VB.M), "e": maxi(3, Datos.jsround(m[0] * D.VB.F)), "hb": Datos.jsround(m[1] * D.VB.M)}

# alto en px de la planta; en una plaza q, con el tope de alto de la plaza (q.ch)
func alto_planta(p: Dictionary, q = null) -> int:
	var Dp: Dictionary = D.PLANTA_CM[Datos.porte_planta(S, p)]
	var h := Datos.jsround(Dp.h[2 if p.get("dead") else Cultivo.plant_stage(p)] * D.VB.M)
	if q:
		h = mini(h, int(floor(q.ch * D.VB.M)))
	return h - (4 if p.get("dead") else 0)

# dónde lanzar un efecto sobre la plaza i (riego, cosecha): en la vista, sobre la planta; si no, sobre el jugador
func pos_plaza(i: int) -> Array:
	var q = null
	if VC:
		for o in vc_geo(VC.ci).pl:
			if o.i == i:
				q = o
	if q == null:
		return [P.px + 8, P.py + 2]
	if q.get("v"):
		return [q.x, q.y - q.v.tierra - (int(q.v.hp) >> 1)]
	var p = S.pots[i]
	var h := alto_planta(p, q) if p else 0
	return [q.x, q.y - maceta_px(S.macetas[i]).hb - Datos.jsround(h / 2.0)]

# la ficha de la izquierda: [título, líneas] (una línea con «!» delante va en rojo); vc_texto es lo que se lee en ella
func vc_ficha() -> void:
	if VC == null or VC.ocupado:
		vc_texto = ""
		vc_info_pon(null)
		return
	var c: Dictionary = S.carpas[VC.ci]
	var L := []
	if VC.sel == Vista.SEL_TEMP:
		var k := Cultivo.ciclo_de(c)
		L.append(T("Temporizador"))
		L.append(T("{n} · {c}", {"n": D.CICLOS[k].n, "c": D.CICLOS[k].c}))
		L.append(T("Luz {e} al día", {"e": Datos.eur(luz_carpa(VC.ci))}) if plantas_vivas(VC.ci) else T("Apagado"))
	elif VC.sel < 0:
		L.append(I18n.v(String(D.FOCOS[c.foco].n)))
		L.append(T("Luz {e} al día", {"e": Datos.eur(luz_carpa(VC.ci))}) if plantas_vivas(VC.ci) else T("Apagado"))
		for k in D.EXTRAS:
			if c.get(k):
				L.append(I18n.v(String(D.EXTRAS[k].c)))
	else:
		var i: int = VC.sel
		var p = S.pots[i]
		L.append(T("Plaza {p} · {l} L", {"p": huecos()[i].j + 1, "l": n(D.MACETAS[S.macetas[i]].l)}))
		if p == null:
			L.append(T("Vacía"))
		else:
			L.append(strain(p.sid).n + etiq(p.get("f")))
			if p.get("dead"):
				L.append(T("Seca"))
			else:
				L.append(T("Cosecha lista") if p.prog >= 1 else T("{s} {p} %", {"s": stage_name(p), "p": int(floor(p.prog * 100))}))
				L.append(T("Agua {p} %", {"p": Datos.jsround(p.water)}))
				L.append(T("Salud {p} %", {"p": Datos.jsround(p.health)}))
			if p.pest and not p.get("dead"):
				L.append("!" + T("PLAGA"))
	var t: String = I18n.v(String(D.CARPAS[c.t].n))
	vc_texto = t
	for l in L:
		vc_texto += l.substr(1) if l.begins_with("!") else l
	vc_info_pon([t, L])

func vc_mover(b: String) -> void:
	var pl: Array = vc_geo(VC.ci).pl
	var cur = null
	for q in pl:
		if q.i == VC.sel:
			cur = q
	var cerca := func(l: Array, x: float) -> Dictionary:
		var m: Dictionary = l[0]
		for q in l.slice(1):
			if absf(q.x - x) < absf(m.x - x):
				m = q
		return m
	if cur == null:
		if b == "left" and VC.sel == -1:
			VC.sel = Vista.SEL_TEMP
		elif b == "right" and VC.sel == Vista.SEL_TEMP:
			VC.sel = -1
		elif b == "down":
			var fm := -1
			for q in pl:
				fm = maxi(fm, q.fila)
			VC.sel = cerca.call(pl.filter(func(q): return q.fila == fm), 120).i
		return
	if b == "left" or b == "right":
		var f := pl.filter(func(q): return q.fila == cur.fila)
		f.sort_custom(func(a, c): return a.x < c.x)
		var k := -1
		for j in f.size():
			if f[j].i == cur.i:
				k = j
		k += -1 if b == "left" else 1
		if k >= 0 and k < f.size():
			VC.sel = f[k].i
		elif k < 0:
			VC.sel = Vista.SEL_TEMP
	elif b == "up":
		var f := pl.filter(func(q): return q.fila == cur.fila + 1)
		VC.sel = cerca.call(f, cur.x).i if f.size() else -1
	elif b == "down":
		var f := pl.filter(func(q): return q.fila == cur.fila - 1)
		if f.size():
			VC.sel = cerca.call(f, cur.x).i

func _vc_accion() -> void:
	if VC.sel == Vista.SEL_TEMP:
		await temporizador(VC.ci)
	elif VC.sel < 0:
		await carpa_action(VC.ci)
	else:
		await pot_action(VC.sel)
	if VC:
		VC.ocupado = false
	vc_ficha()

func abrir_carpa(ci):
	sfx("door")
	await fade(1)
	var pl: Array = vc_geo(ci).pl
	VC = {"ci": ci, "sel": pl[0].i if pl.size() else -1, "ocupado": false}
	mode = "carpa"
	update_hud()
	vc_ficha()
	await fade(0)
	if not S.flags.get("vista"):
		S.flags.vista = true
		toast(K("◀ ▶ ▲ ▼ eliges planta, foco o reloj · A la cuidas · B sales"), 2800)
	var pr := Motor.Prom.new()
	push(func(b: String):
		if VC.ocupado:
			return
		if b == "B":
			pop()
			pr.res()
			return
		if b == "A":
			VC.ocupado = true
			vc_ficha()
			_vc_accion()
			return
		if DV.has(b):
			var s0: int = VC.sel
			vc_mover(b)
			if s0 != VC.sel:
				sfx("tick")
				vc_ficha())
	await Motor.espera(pr)
	VC.ocupado = true
	vc_ficha()
	await fade(1)
	mode = "world"
	VC = null
	update_hud()
	revisa_misiones()   # 1.11: lo montado en la carpa cuenta ya
	await fade(0)

# ---------- virtuales: las definen trama y juego ----------
func save():
	return true
func genoteca():
	pass
func show_objective():
	pass
func raid_event():
	pass
func aviso_orden():
	pass
func recuerdo_plazo():
	pass
func penalty_event():
	pass

# ---------- el banco, los recibos y los locales (1.35, 11k-banco) ----------
# el efectivo (S.money) y la cuenta (S.banco): con tarjeta, lo que deja rastro; la luz, domiciliada; el cajero, con sus topes al día
func movimiento(t: String, e: float) -> void:
	S.mov.push_front({"d": S.day, "t": t, "e": roundi(e)})
	if S.mov.size() > int(D.CUENTA.mov):
		S.mov.resize(int(D.CUENTA.mov))

func cobro_banco(e: float, t: String) -> bool:
	if S.banco < e:
		return false
	S.banco -= e
	movimiento(t, -e)
	return true

func abono_banco(e: float, t: String) -> void:
	S.banco += e
	movimiento(t, e)

func pagar_recibo(e: float, t: String) -> float:
	var b: float = minf(S.banco, e)
	if b > 0:
		S.banco -= b
		movimiento(t, -b)
	return pagar_casa(e - b)

func tarjeta(e: float, t: String) -> bool:
	if cobro_banco(e, t):
		return true
	sfx("bad")
	await say(T("La tarjeta no pasa: en la cuenta tienes {e}. Ingresa efectivo en un cajero.", {"e": Datos.eur(S.banco)}))
	return false

func sacado() -> float:
	return float(S.saca.e) if S.get("saca") is Dictionary and S.saca.d == S.day else 0.0

func ingresado() -> float:
	return float(S.ingr.e) if S.get("ingr") is Dictionary and S.ingr.d == S.day else 0.0

func cantidad(t: String, mx: int) -> int:
	var v := []
	for x in D.CUENTA.pasos:
		if x < mx:
			v.append(int(x))
	if mx >= 1:
		v.append(mx)
	var ops := []
	for x in v:
		ops.append(Datos.eur(x))
	ops.append(K("Nada"))
	var i: int = await ask(t, ops)
	return v[i] if i >= 0 and i < v.size() else 0

func cajero() -> void:
	await acceso("pin", cifras_acceso("pin"))   # 1.53: la tarjeta y el PIN
	while true:
		var ops := [K("Sacar"), K("Ingresar"), K("Movimientos"), K("Salir")]
		var oi: int = await ask(T("CAJERO · en la cuenta tienes {e}.", {"e": Datos.eur(S.banco)}), ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "Sacar":
			var mx := int(floorf(minf(S.banco, D.CUENTA.sacar - sacado())))
			if mx < 1:
				sfx("bad")
				await say(K("No hay saldo.") if S.banco < 1 else T("Hoy ya has sacado {e}: es el tope del cajero.", {"e": Datos.eur(sacado())}))
				continue
			var e: int = await cantidad(T("¿Cuánto sacas? Hoy, hasta {e}.", {"e": Datos.eur(mx)}), mx)
			if not e:
				continue
			S.saca = {"d": S.day, "e": sacado() + e}
			S.banco -= e
			S.money += e
			movimiento(K("Cajero"), -e)
			sfx("coin")
			update_hud()
		elif op == "Ingresar":
			var mx := int(floorf(minf(S.money, D.CUENTA.ingreso - ingresado())))
			if mx < 1:
				sfx("bad")
				await say(K("No llevas efectivo.") if S.money < 1 else T("Hoy ya has ingresado {e}. Más, y el banco pregunta de dónde sale.", {"e": Datos.eur(ingresado())}))
				continue
			var e: int = await cantidad(T("¿Cuánto ingresas? Sin preguntas, hasta {e} al día.", {"e": Datos.eur(D.CUENTA.ingreso)}), mx)
			if not e:
				continue
			S.ingr = {"d": S.day, "e": ingresado() + e}
			S.money -= e
			S.banco += e
			movimiento(K("Ingreso en efectivo"), e)
			sfx("coin")
			update_hud()
		elif op == "Movimientos":
			await banca()
		else:
			return

func recibo_nave() -> float:
	return D.RECIBO.dias * D.NAVE.dia

func recibo_setas() -> float:
	var ay: float = float(D.SETAS_AY.sueldo) if Datos.CAL and S != null and S.get("setas") is Dictionary and S.setas.get("ay") else 0.0   # 1.51: el ayudante
	return D.RECIBO.dias * D.SETAS.dia + ay

func recibos() -> Array:
	var r := []
	if S.get("nave") != null and not S.nave.get("mia"):
		r.append([K("Nave de Valdehierro"), S.nave.r, recibo_nave(), "efectivo", r.size()])
	if S.get("setas") != null:
		r.append([K("Bajo de la Kale Zaharra"), S.setas.r, recibo_setas(), "efectivo", r.size()])
	for k in S.loc:
		r.append([D.LOCALES[k].n, S.loc[k].r, D.LOCALES[k].sem, "cuenta", r.size()])
	for k in D.CONCE.orden:   # 1.43.2: el seguro y el impuesto de circulación de cada vehículo, domiciliados, cada año
		if S.get("coches") is Dictionary and S.coches.has(k):
			if S.coches[k].get("r") != null:
				r.append([K("Seguro") + " · " + String(D.CONCE.v[k].n), S.coches[k].r, seguro_anio(k), "cuenta", r.size()])
			if S.coches[k].get("iv") != null:
				r.append([K("Impuesto de circulación") + " · " + String(D.CONCE.v[k].n), S.coches[k].iv, D.CONCE.v[k].ivtm, "cuenta", r.size()])
	if S.protect and S.get("protHasta"):
		r.append([K("Sargento Molina"), S.protHasta + 1, D.SOBORNO, "mano", r.size()])
	r.sort_custom(func(a, b): return a[1] < b[1] or a[1] == b[1] and a[4] < b[4])   # estable, como sort de JS
	return r

func como(k: String) -> String:
	return {"cuenta": K("de la cuenta"), "efectivo": K("en efectivo"), "mano": K("en mano, en la comisaría")}[k]

# F7: un rótulo guardado en partes «A · B» (los movimientos y los recibos): cada parte, en su idioma
static func tr_partes(t: String) -> String:
	var p := t.split(" · ")
	for j in p.size():
		p[j] = I18n.v(p[j])
	return " · ".join(p)

func banca() -> void:
	var it := []
	for r in recibos():
		it.append({"label": T("Recibo · {r}", {"r": tr_partes(r[0])}), "right": Datos.eur(r[2]), "desc": T("El {d}, {c}.", {"d": Datos.fd(r[1], S.day), "c": como(r[3])})})
	for m in S.mov:
		it.append({"label": tr_partes(m.t), "right": ("−" if m.e < 0 else "+") + Datos.eur(absf(m.e)), "desc": mayus(Datos.fd_larga(m.d)) + "."})
	it.append({"label": K("Salir"), "desc": T("Ingresos en efectivo: hasta {e} al día sin preguntas (hoy, {h}).", {"e": Datos.eur(D.CUENTA.ingreso), "h": Datos.eur(ingresado())})})
	await menu(it, {"cls": "full", "title": K("BANCA"), "title2": T("Saldo {e}", {"e": Datos.eur(S.banco)}), "desc": true})

# un recibo (o.r, el día): el aviso, el cobro (en efectivo, de lo que llevas y de la caja; o domiciliado) y la gracia; false si se pierde
func cobra(o: Dictionary, e: float, quien: String, banco: bool, t: String, per := 0, f := "r") -> bool:
	var N := K("SMS · ") + quien
	if S.day == o[f] - D.RECIBO.aviso:
		var tx: String = T("El {d} se carga el recibo de {t}: {e}. Saldo: {s}.", {"d": Datos.fd(o[f], S.day), "t": tr_partes(t), "e": Datos.eur(e), "s": Datos.eur(S.banco)}) if banco else T("El {d} paso a cobrar: {e}, en efectivo. Tenlo preparado.", {"d": Datos.fd(o[f], S.day), "e": Datos.eur(e)})
		queue("av" + t, func(): await talk(N, [tx]), [[N, [tx]]])
	if S.day < o[f]:
		return true
	var ok: bool = cobro_banco(e, K("Recibo") + " · " + t) if banco else (S.money + caja_e() >= e and pagar_casa(e) == 0)
	if ok:
		o[f] += per if per else int(D.RECIBO.dias)   # 1.43.2: el seguro y el impuesto, cada año (per; f, el campo de la fecha)
		return true
	if S.day < o[f] + (D.RECIBO.graciaB if banco else D.RECIBO.gracia):
		var hr := {"t": tr_partes(t), "e": Datos.eur(e), "d": Datos.fd(o[f] + D.RECIBO.graciaB, S.day)}
		var tx: String = (T("Recibo de {t} devuelto: {e}. Si el {d} no hay saldo, se cobra por apremio, con recargo.", hr) if f == "iv" else T("Recibo de {t} devuelto: {e}. Si el {d} no hay saldo, se rescinde el contrato.", hr)) if banco else K("He pasado a cobrar y no había nada. Vuelvo mañana; como no esté, cambio la cerradura.")
		queue("dv" + t, func(): await talk(N, [tx]), [[N, [tx]]])
		return true
	return false

func recibos_dia() -> void:
	for k in S.loc.keys():
		var L: Dictionary = D.LOCALES[k]
		var o: Dictionary = S.loc[k]
		if Datos.CAL:   # 1.45: lo que ha vendido el negocio (neg_venta), a la cuenta; la limpieza baja y el género se gasta
			neg_o(k)
			var v := neg_venta(k)
			o.ay = v
			o.vt = int(o.vt) + v
			if v > 0:
				abono_banco(v, K("Ventas") + " · " + L.n)
			o.cu = maxi(0, int(o.cu) - int(D.NEGOCIO.cu[1]))
			o.st = maxi(0, int(o.st) - 1)
		if o.caja > 0:   # lo de ayer, ya limpio
			var nt: int = roundi(o.caja * (1 - L.com))
			abono_banco(nt, K("Ingresos") + " · " + L.n)
			o.tot += nt
			o.caja = 0
		if not cobra(o, L.sem, K("BANCO"), true, L.n):
			S.loc.erase(k)
			var tx: String = T("Contrato de {n} rescindido por impago. La fianza no se devuelve.", {"n": L.n})
			queue("loc" + k, func(): await talk(K("SMS · BANCO"), [tx]), [[K("SMS · BANCO"), [tx]]])
	if S.protect and S.protHasta - S.day == D.RECIBO.aviso:
		var tx: String = T("Lo nuestro se acaba el {d}. Si quieres seguir, ya sabes dónde está la comisaría.", {"d": Datos.fd(S.protHasta, S.day)})
		queue("avMolina", func(): await talk(K("SMS · MOLINA"), [tx]), [[K("SMS · MOLINA"), [tx]]])   # i18n-no

# los locales (LOCALES): uno por pueblo, por lo pagado de la deuda; meter efectivo en la caja del negocio, que sale limpio mañana
func pagado_deuda() -> float:
	return D.DEUDA - S.debt

func local_de(m: String, x: int, y: int) -> String:
	for k in D.LOCALES:
		var L: Dictionary = D.LOCALES[k]
		if L.map == m and L.x == x and L.y == y:
			return k
	return ""

func del_neg(L: Dictionary) -> String:   # «las llaves del lavadero», «de la taberna»
	var t: String = L.neg
	return "del " + t.substr(3) if t.begins_with("el ") else ("de la " + t.substr(3) if t.begins_with("la ") else t)   # i18n-no

# F7: la frase según el artículo del negocio (L.neg: «el lavadero…», «la taberna»), con {n} sin el artículo
func por_neg(L: Dictionary, s_el: String, s_la: String, s_otro: String, a := {}) -> String:
	var t: String = L.neg
	var b: Dictionary = a.duplicate()
	if t.begins_with("el "):
		b.n = t.substr(3)
		return T(s_el, b)
	if t.begins_with("la "):
		b.n = t.substr(3)
		return T(s_la, b)
	b.n = t
	return T(s_otro, b)

func metido(o: Dictionary) -> float:
	return o.caja if o.dia == S.day else 0.0

func rotulo_local(k: String) -> void:
	var L: Dictionary = D.LOCALES[k]
	var N: String = String(L.n).to_upper()
	if not S.loc.has(k):
		if pagado_deuda() < L.pago:
			await say(T("SE ALQUILA. Debajo, a boli: «Preguntar en el bar El Ancla». El dueño es amigo de Don Baltasar: hasta que no le hayas pagado {e}, para ti no está.", {"e": Datos.eur(L.pago)}))
			return
		if await ask(T("SE TRASPASA: {n}, con el local. {f} de fianza y {s} cada {d} días, domiciliados. Por su caja pasa el efectivo que metas, hasta {t} al día: al día siguiente, en tu cuenta, menos un {c} % de gastos e impuestos.", {"n": L.neg, "f": Datos.eur(L.fianza), "s": Datos.eur(L.sem), "d": n(D.RECIBO.dias), "t": Datos.eur(L.tope), "c": roundi(L.com * 100)}), [K("Alquilarlo"), K("No")]) != 0:
			return
		if not await tarjeta(L.fianza + L.sem, K("Fianza") + " · " + L.n):
			return
		S.loc[k] = {"r": S.day + D.RECIBO.dias, "caja": 0, "dia": 0, "tot": 0}
		if Datos.CAL:
			neg_o(k)
		sfx("coin")
		update_hud()
		await got(por_neg(L, K("las llaves del {n}"), K("las llaves de la {n}"), K("las llaves {n}")))
		await say(T("{n}: el negocio sigue con su gente. Tú metes el efectivo en la caja y, a la mañana siguiente, sale en el banco como lo que ha hecho.", {"n": L.n}))
		if Datos.CAL:
			montar_locales(S.map)
			await say(K("Por dentro se lleva todo: la caja, el género, la limpieza y las mejoras. Lo que venda, si lo cuidas, también entra en la cuenta."))
		return
	if Datos.CAL:   # 1.45: el negocio se lleva desde dentro
		await say(T("{n} es tuyo: la caja, el género y la gente están dentro. Entra por la puerta.", {"n": mayus(I18n.v(String(L.neg)))}))
		return
	var o: Dictionary = S.loc[k]
	while true:
		var hoy: float = metido(o)
		var ops := [K("Meter efectivo"), K("Dejar el local"), K("Nada")]
		var oi: int = await ask(T("Hoy, {h} de {t} en caja · lavado en total, {o} · próximo recibo, el {d}.", {"h": Datos.eur(hoy), "t": Datos.eur(L.tope), "o": Datos.eur(o.tot), "d": Datos.fd(o.r, S.day)}), ops, N)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "Meter efectivo":
			var mx := int(floorf(minf(S.money, L.tope - hoy)))
			if mx < 1:
				sfx("bad")
				await say(K("No llevas efectivo.") if S.money < 1 else T("Hoy ya hay {e} en la caja: más, y Hacienda se fija.", {"e": Datos.eur(L.tope)}))
				continue
			var e: int = await cantidad(T("¿Cuánto metes en la caja? Hoy, hasta {e}.", {"e": Datos.eur(mx)}), mx)
			if not e:
				continue
			o.caja = hoy + e
			o.dia = S.day
			S.money -= e
			sfx("coin")
			update_hud()
			await say(por_neg(L, K("Mañana entran en la cuenta {e} como ingresos del {n}."), K("Mañana entran en la cuenta {e} como ingresos de la {n}."), K("Mañana entran en la cuenta {e} como ingresos {n}."), {"e": Datos.eur(roundi(o.caja * (1 - L.com)))}))
		elif op == "Dejar el local":
			if await ask(T("¿Dejas {n}? Te devuelven la fianza a la cuenta; lo de la caja de hoy se queda en el negocio.", {"n": L.neg}) if o.caja > 0 else T("¿Dejas {n}? Te devuelven la fianza a la cuenta.", {"n": L.neg}), [K("Dejarlo"), K("No")]) != 0:
				continue
			S.loc.erase(k)
			abono_banco(L.fianza, K("Fianza") + " · " + L.n)
			sfx("coin")
			update_hud()
			await say(T("Has dejado {n}.", {"n": L.neg}))
			return
		else:
			return

# ---------- los negocios por dentro (1.45, lo pidió el usuario; con Datos.CAL) ----------
# «que también funcione… dependiendo de cómo cuides el local»: S.loc[k] gana cu (la limpieza, 0-100: baja NEGOCIO.cu[1] al día),
# st (los días de género que quedan), mj (las mejoras compradas, 0-2), ay (lo que vendió ayer) y vt (lo vendido en total).
# Cada mañana, el negocio vende su base × limpieza × mejoras × género (sin género, NEGOCIO.sinGen) ± NEGOCIO.azar, y entra limpio
func neg_o(k: String) -> Dictionary:
	var o: Dictionary = S.loc[k]
	for c in [["cu", int(D.NEGOCIO.cu[0])], ["st", 0], ["mj", 0], ["ay", 0], ["vt", 0]]:
		if not o.has(c[0]):
			o[c[0]] = c[1]
	return o

func neg_tope(k: String) -> int:
	return roundi(float(D.LOCALES[k].tope) * (1 + float(D.NEGOCIO.mjT) * int(neg_o(k).mj)))

func neg_venta(k: String) -> int:
	var N: Dictionary = D.NEGOCIO.k[k]
	var o := neg_o(k)
	var f: float = (0.4 + 0.6 * int(o.cu) / 100.0) * (1 + float(D.NEGOCIO.mjF) * int(o.mj)) * (1.0 if int(o.st) > 0 else float(D.NEGOCIO.sinGen))
	var a: float = 1 + float(D.NEGOCIO.azar) * ((absi(hash("%s|%d" % [k, int(S.day)])) % 201) / 100.0 - 1)
	return roundi(float(N.base) * f * a)

func neg_cuidado(k: String) -> String:
	for c in D.NEGOCIO.cuTxt:
		if int(neg_o(k).cu) >= int(c[0]):
			return c[1]
	return ""

func neg_caja(k: String) -> void:
	var L: Dictionary = D.LOCALES[k]
	var N: Dictionary = D.NEGOCIO.k[k]
	var Tn: String = String(L.n).to_upper()
	while S.loc.has(k):
		var o := neg_o(k)
		var hoy: float = metido(o)
		var ops := [K("Meter efectivo"), K("Las cuentas"), K("Reponer género")]
		var mej := ""
		if int(o.mj) < N.mj.size():
			mej = T("Mejora: {m}", {"m": N.mj[int(o.mj)].n})
			ops.append(mej)
		if staff_ok():   # MAESTRO [6]
			ops.append(K("Seguridad"))
		ops += [K("Dejar el local"), K("Nada")]
		var oi: int = await ask(T("LA CAJA · hoy, {h} de {t} metidos · ayer vendió {a}.", {"h": Datos.eur(hoy), "t": Datos.eur(neg_tope(k)), "a": Datos.eur(int(o.ay))}), ops, Tn)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "Meter efectivo":
			var mx := int(floorf(minf(S.money, neg_tope(k) - hoy)))
			if mx < 1:
				sfx("bad")
				await say(K("No llevas efectivo.") if S.money < 1 else T("Hoy ya hay {e} en la caja: más, y Hacienda se fija.", {"e": Datos.eur(neg_tope(k))}))
				continue
			var e: int = await cantidad(T("¿Cuánto metes en la caja? Hoy, hasta {e}.", {"e": Datos.eur(mx)}), mx)
			if not e:
				continue
			o.caja = hoy + e
			o.dia = S.day
			S.money -= e
			sfx("coin")
			update_hud()
			await say(por_neg(L, K("Mañana entran en la cuenta {e} como ingresos del {n}."), K("Mañana entran en la cuenta {e} como ingresos de la {n}."), K("Mañana entran en la cuenta {e} como ingresos {n}."), {"e": Datos.eur(roundi(o.caja * (1 - L.com)))}))
		elif op == "Las cuentas":
			await say(T("Ayer vendió {a}; en total, {t}. Por la caja has lavado {l}.", {"a": Datos.eur(int(o.ay)), "t": Datos.eur(int(o.vt)), "l": Datos.eur(int(o.tot))}), Tn)
			await say(T("El local {c} ({p} %). Género para {g} días. Mejoras: {m} de {n}. El recibo, {e} el {d}.", {"c": neg_cuidado(k), "p": int(o.cu), "g": int(o.st), "m": int(o.mj), "n": N.mj.size(), "e": Datos.eur(L.sem), "d": Datos.fd(o.r, S.day)}), Tn)
		elif op == "Reponer género":
			await neg_genero(k)
		elif op == "Seguridad":
			await seguridad_local(k)
		elif mej != "" and op == mej:
			var M: Dictionary = N.mj[int(o.mj)]
			if await ask(T("{m}: {p}, con tarjeta. Vende un {a} % más y por la caja pasa un {b} % más al día.", {"m": M.n, "p": Datos.eur(M.p), "a": roundi(float(D.NEGOCIO.mjF) * 100), "b": roundi(float(D.NEGOCIO.mjT) * 100)}), [K("Hacerla"), K("No")], Tn) != 0:
				continue
			if not await tarjeta(M.p, K("Obra") + " · " + L.n):
				continue
			o.mj = int(o.mj) + 1
			montar_locales(S.map)
			build_ents()
			sfx("get")
			await say(T("Hecho: {m}.", {"m": I18n.v(String(M.n)).to_lower()}))
		elif op == "Dejar el local":
			if await ask(T("¿Dejas {n}? Te devuelven la fianza a la cuenta; las mejoras se quedan.", {"n": L.neg}), [K("Dejarlo"), K("No")]) != 0:
				continue
			S.loc.erase(k)
			abono_banco(L.fianza, K("Fianza") + " · " + L.n)
			sfx("coin")
			update_hud()
			await say(T("Has dejado {n}. Devuelves las llaves al salir.", {"n": L.neg}))
			return
		else:
			return

func neg_genero(k: String) -> void:
	var L: Dictionary = D.LOCALES[k]
	var N: Dictionary = D.NEGOCIO.k[k]
	var o := neg_o(k)
	var dias := int(D.NEGOCIO.st)
	var e: int = roundi(float(N.gen) * dias)
	if await ask(T("Género ({g}): queda para {s} días. Sin género vende un {p} % de lo normal. ¿Pides para {d} días por {e}, con tarjeta?", {"g": N.gn, "s": int(o.st), "p": roundi(float(D.NEGOCIO.sinGen) * 100), "d": dias, "e": Datos.eur(e)}), [K("Pedirlo"), K("No")]) != 0:
		return
	if not await tarjeta(e, K("Género") + " · " + L.n):
		return
	o.st = int(o.st) + dias
	sfx("coin")
	update_hud()
	toast(T("Género para {d} días", {"d": int(o.st)}), 1400)

func neg_limpiar(k: String) -> void:
	var o := neg_o(k)
	if await ask(T("El local {c} ({p} %). ¿Lo friegas y lo ordenas? Es una hora.", {"c": neg_cuidado(k), "p": int(o.cu)}), [K("Limpiar"), K("Nada")]) != 0:
		return
	await fade(1)
	advance_time(int(D.NEGOCIO.limpia))
	o.cu = 100
	update_hud()
	await wait(300)
	await fade(0)
	sfx("get")
	toast(K("El local reluce"), 1400)

func talk_neg(k: String) -> void:
	var N: Dictionary = D.NEGOCIO.k[k]
	var o := neg_o(k)
	var Tn: String = N.emp[2]
	var q: String = T("Ayer hicimos {e}.", {"e": Datos.eur(int(o.ay))}) + " " + T("El local {c}.", {"c": neg_cuidado(k)}) + (T(" Y nos estamos quedando sin {g}.", {"g": N.gn}) if int(o.st) <= 1 else "")
	var c: int = await ask(q, [K("La caja"), K("Nada")], Tn)
	if c == 0:
		await neg_caja(k)

func sprite_rotulo() -> String:
	for k in D.LOCALES:
		if D.LOCALES[k].map == S.map:
			return "rotuloL-%d" % (1 if S.loc.has(k) else 0)   # i18n-no
	return "rotuloL-0"   # i18n-no
