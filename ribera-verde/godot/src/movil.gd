# F8 (de trama.gd): el móvil y su pantalla (llamadas, SMS, tienda online, banca, GENTE).
extends "res://src/policia.gd"

# ---------- el móvil (1.10, 12b-movil) ----------
func reloj_txt() -> String:
	return "%02d:%02d" % [int(S.min) / 60, int(S.min) % 60]

func movil_menu():
	ult_app = ""
	while true:
		var ops := [K("Llamar")]
		if S.flags.get("kiko1"):
			ops.append(K("Pedir a Kiko"))
		ops.append_array([K("Mensajes"), K("Gente")])
		if S.ch >= int(D.PLANTILLA.ch):
			ops.append(K("Plantilla"))
		ops.append_array([K("Banca"), K("Tienda online"), K("Calendario"), K("Mapa"), K("Colgar")])   # 1.35: la banca (granja.gd); 1.42: el calendario y el mapa (croquis.gd)
		var ns: int = S.sms.size()
		var oi: int
		if Datos.CAL:   # 1.51 (lo pidió el usuario): la pantalla del móvil con sus aplicaciones, como la caja fuerte por dentro
			ops.pop_back()
			oi = await elegir_movil(ops, ops.find(ult_app))
			if oi >= 0:
				ult_app = ops[oi]
		else:
			var A := {"d": Datos.fd_hud(S.day).to_lower(), "h": reloj_txt(), "n": ns}
			oi = await ask((T("MÓVIL · {d}, {h} · {n} mensajes", A) if ns > 1 else T("MÓVIL · {d}, {h} · {n} mensaje", A)) if ns else T("MÓVIL · {d}, {h}", A), ops)
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

func desc_movil(V: Dictionary) -> String:
	var op: String = V.ops[V.i]
	var ns: int = S.sms.size()
	var d: String = {"Llamar": K("La agenda: Kiko, Toño, Iñaki y los clientes que te han comprado."), "Pedir a Kiko": T("Lo del growshop, a casa mañana por la mañana (+{n} %).", {"n": Datos.jsround((D.ENVIO - 1) * 100)}),
		"Mensajes": (T("{n} mensajes.", {"n": ns}) if ns > 1 else T("{n} mensaje.", {"n": ns})) if ns else K("No hay mensajes."), "Gente": K("La confianza con cada persona."),
		"Plantilla": K("Tu gente: la calle, la casa y la nave."), "Banca": T("En la cuenta, {e}. Movimientos y recibos.", {"e": Datos.eur(S.get("banco", 0))}),
		"Tienda online": K("Con tarjeta; llega al día siguiente."), "Calendario": K("El mes, con los días señalados."), "Mapa": K("La comarca y las líneas de autobús.")}.get(op, "")
	if Datos.CAL:   # 1.52: el tiempo de hoy
		var Ti := Datos.tiempo(int(S.day), int(S.min))
		return T("{op} · {f}, {h}\n{d} · Fuera: {n}, {t} °C (máx. {mx}, mín. {mn}), {e}.\nA: abrir · B: colgar.", {"op": op, "f": Datos.fd_hud(S.day).to_lower(), "h": reloj_txt(), "d": d, "n": Ti.n.to_lower(), "t": int(Ti.t), "mx": int(Ti.max), "mn": int(Ti.min), "e": Ti.est})
	return T("{op} · {f}, {h}\n{d} · A: abrir · B: colgar.", {"op": op, "f": Datos.fd_hud(S.day).to_lower(), "h": reloj_txt(), "d": d})

func mueve_movil(V: Dictionary, b: String) -> bool:
	var n: int = V.ops.size()
	var j: int = V.i + {"left": -1, "right": 1, "up": -3, "down": 3}.get(b, 0)
	if j < 0 or j >= n or j == V.i:
		return false
	V.i = j
	return true

func elegir_movil(ops: Array, i0 := 0) -> int:
	if gancho_menu.is_valid():   # las pruebas eligen por la etiqueta, como en el menú de siempre
		var i: int = await menu(ops + [K("Colgar")], {"cls": "right", "cancel": true, "title": K("MÓVIL")})
		return i if i >= 0 and i < ops.size() else -1
	MOVIL_V = {"ops": ops, "i": clampi(i0, 0, ops.size() - 1)}
	_dlg_fijo(desc_movil(MOVIL_V), I18n.v("MÓVIL"))
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
			_dlg_fijo(desc_movil(MOVIL_V), I18n.v("MÓVIL")))
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
		C.append({"label": K("Kiko"), "right": K("growshop"), "desc": K("Consejos de cultivo. Los pedidos, desde «Pedir a Kiko»."), "k": "kiko"})
	if S.flags.get("tono"):
		C.append({"label": K("Toño"), "right": K("Don Baltasar"), "desc": K("Lo que debes y hasta cuándo."), "k": "tono"})
	if S.flags.get("inaki"):
		C.append({"label": K("Iñaki"), "right": K("muelle"), "desc": K("Compra al por mayor."), "k": "inaki"})
	for f in S.fijos:
		C.append({"label": f.n, "right": etiqueta_ct(f.t, mujer_nombre(f.n)).to_lower(), "desc": K("Ya ha venido hoy.") if f.dia == S.day else K("Te compró en la calle. Si estás fuera, viene a buscarte."), "f": f})
	if C.is_empty():
		await say(K("La agenda está vacía."))
		return false
	var items := C.duplicate()
	items.append({"label": K("Nada")})
	var i: int = await menu(items, {"cls": "right", "title": K("LLAMAR")})
	if i < 0 or i >= C.size():
		return false
	var c: Dictionary = C[i]
	match c.get("k", ""):
		"kiko":
			await talk(K("KIKO"), [kiko_tip()])
			return false
		"tono":
			await talk(K("TOÑO"), [T("Te quedan {e} hasta el {f}. Don Baltasar no espera.", {"e": Datos.eur(S.due), "f": Datos.fd(S.deadline, S.day)}) if S.due > 0 else K("Ahora mismo no debes nada. Que siga así.")])
			return false
		"inaki":
			await talk(K("IÑAKI"), [K("Ahora estoy en la mar. A la vuelta hablamos.") if S.ch < 3 else (K("Hoy ya he cargado. Mañana sale otro barco.") if S.mDay == S.day else T("Al por mayor, de 100 g para arriba y hasta {kg} por carga. Pásate por el muelle.", {"kg": _kg(mayor_dia())}))])
			return false
	return await fijo_menu(c.f)   # 1.15: que venga, un regalo o que venda para ti

func llamar_fijo(f: Dictionary) -> bool:
	if f.dia == S.day:
		await say(T("{n} ya ha venido hoy.", {"n": f.n}))
		return false
	if not D.ZONAS.has(S.map):
		await say(T("{n}: «¿Dónde estás? Quedamos en la calle».", {"n": f.n}))
		return false
	if SOSP.alarma:
		await say(T("{n}: «¿Con la policía detrás? Ni de broma».", {"n": f.n}))
		return false
	var ct: Dictionary = D.CTYPES[f.t]
	S.heat = minf(100, S.heat + 1)
	await say(T("{n}: «Vale, voy para allá».", {"n": f.n}))
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
			items.append({"label": T("{l} · ×{n}", {"l": it.lbl, "n": nn}) if nn else it.lbl, "right": Datos.eur(precio_envio(it)), "desc": it.get("desc", "")})
		items.append({"label": K("Salir"), "desc": K("Lo pedido llega mañana por la mañana a casa.")})
		i = await menu(items, {"cls": "full", "title": K("PEDIR A KIKO"), "title2": T("Envío a casa +{n} % · tienes {e}", {"n": Datos.jsround((D.ENVIO - 1) * 100), "e": Datos.eur(S.money)}), "desc": true, "initial": i})
		if i < 0 or i >= l.size():
			return
		var it: Dictionary = l[i]
		var e := precio_envio(it)
		if S.money < e:
			sfx("bad")
			await say(K("No te llega el dinero."))
			continue
		S.money -= e
		S.envio.append(it.lbl)
		ult = it.lbl
		sfx("coin")
		toast(T("Pedido: {l} · llega mañana", {"l": it.lbl}), 1400)

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
		L.append(("%s ×%d" % [I18n.v(lbl), c[lbl]]) if c[lbl] > 1 else I18n.v(lbl))
	var t := ", ".join(L)
	var av := [T("Te he dejado el paquete en casa: {t}.", {"t": t})]
	queue("envio", func(): await talk(K("SMS · KIKO"), av), [[K("SMS · KIKO"), av]])

func mensajes():
	if S.sms.is_empty():
		await say(K("No tienes mensajes."))
		return
	var i := 0
	while true:
		var items := []
		for m in S.sms:
			items.append({"label": m.n, "right": Datos.fd_corto(m.d), "desc": m.t})
		i = await menu(items, {"cls": "full", "title": K("MENSAJES"), "title2": T("{a} de {b}", {"a": S.sms.size(), "b": n(D.SMS_MAX)}), "desc": true, "initial": i})
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
			var L := [K("Sin cobrar no vuelvo, majo. Cuando tengas el dinero, hablamos.")]
			queue("jard", func(): await talk(K("SMS · BEGOÑA"), L), [[K("SMS · BEGOÑA"), L]])
		else:
			S.money -= int(J.sueldo)
			cuidar_plantas()
			S.heat = min(100, S.heat + J.calor)
	var fin := []
	var vende := false
	for v in C.vend:
		var r := Cultivo.azar()
		var N: String = T("SMS · {n}", {"n": v.n.to_upper()})
		if r < V.pilla:
			fin.append(v)
			S.heat = min(100, S.heat + V.calorPilla)
			confia(v.id, -5)
			var L := [T("Me ha parado la policía. Se han quedado con {g} de {l}. Lo siento.", {"g": g_txt(v.g), "l": lot_nombre(v.k)})]
			queue("vend" + v.id, func(): await talk(N, L), [[N, L]])
			continue
		if r < V.pilla + V.estafa * (D.REL.max - rel(v.id)) / D.REL.max:
			fin.append(v)
			S.fijos = S.fijos.filter(func(f): return f.id != v.id)
			S.rel[v.id] = 0
			var L := [T("{n} no contesta al móvil. Se ha largado con {g} de {l}.", {"n": v.n, "g": g_txt(v.g), "l": lot_nombre(v.k)})]
			queue("vend" + v.id, func(): await say(L[0]), [["", L]])
			continue
		var g: int = mini(int(floor(v.g)), ri(int(V.g[0]), int(V.g[1])))
		var e := Datos.jsround(precio_calle(v.thc) * calidad(v, true) * D.ZONAS.town.precio * g * (1 - V.com))
		v.g -= g
		S.money += e
		S.sales += e
		S.heat = min(100, S.heat + V.calor)
		confia(v.id, 1)
		vende = true
		if v.g < 1:
			fin.append(v)
			var L := [T("Vendidos los últimos {g} g: {e} en tu buzón. Si quieres que siga, déjame más.", {"g": g, "e": Datos.eur(e)})]
			queue("vend" + v.id, func(): await talk(N, L), [[N, L]])
		else:
			var L := [T("Vendidos {g} g: {e} en tu buzón. Me quedan {q}.", {"g": g, "e": Datos.eur(e), "q": g_txt(v.g)})]
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
	var ops := [K("Que venga")]
	var reg := T("Regalarle {n} g", {"n": int(D.REL.regaloG)})
	if total_buds() >= D.REL.regaloG:
		ops.append(reg)
	if v:
		ops.append(K("Cómo va la venta"))
	elif puede:
		ops.append(K("Que venda para mí"))
	ops.append(K("Nada"))
	var oi: int = await ask(T("{n} · {t} · confianza {c} ({v})", {"n": f.n, "t": etiqueta_ct(f.t, mujer_nombre(f.n)).to_lower(), "c": rel(f.id), "v": rel_nivel(f.id)}), ops)
	var op: String = ops[oi]
	if op == "Que venga":
		return await llamar_fijo(f)
	if op == reg:
		if f.get("regalo") == S.day:
			await say(T("{n}: «¿Otra vez? Gracias, pero hoy ya me has invitado».", {"n": f.n}))
			return false
		var lots := bud_lots(D.REL.regaloG)
		var it := lots.map(lot_item)
		it.append({"label": K("Nada")})
		var i: int = await menu(it, {"cls": "right", "title": K("¿Qué le regalas?")})
		if i < 0 or i >= lots.size():
			return false
		use_buds(lots[i][0], D.REL.regaloG)
		f.regalo = S.day
		confia(f.id, int(D.REL.regalo))
		sfx("get")
		await say(T("{n}: «¡Gracias! Se lo cuento a todo el mundo».", {"n": f.n}))
		return false
	if op == "Cómo va la venta":
		await say(T("{n}: «Me quedan {g} de {l}. Cada día vendo lo que puedo y te dejo el {p} % en el buzón».", {"n": f.n, "g": g_txt(v.g), "l": lot_nombre(v.k), "p": Datos.jsround((1 - D.CURRO.vend.com) * 100)}))
		return false
	if op == "Que venda para mí":
		return await contratar_vendedor(f)
	return false

func contratar_vendedor(f: Dictionary) -> bool:
	var V: Dictionary = D.CURRO.vend
	var lots := bud_lots(V.lotes[0])
	if lots.is_empty():
		await say(T("{n}: «Cuando tengas {g} g o más, hablamos».", {"n": f.n, "g": int(V.lotes[0])}))
		return false
	var it := lots.map(lot_item)
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Qué lote le dejas?")})
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
	o.append(K("Nada"))
	var j: int = await ask(T("{n} vende a precio de calle y se queda el {p} %. ¿Cuánto le dejas?", {"n": f.n, "p": Datos.jsround(V.com * 100)}), o)
	if j < 0 or j >= ops.size():
		return false
	use_buds(k, ops[j])
	var vd := {"id": f.id, "n": f.n, "k": k, "thc": b.thc, "g": ops[j]}
	vd.merge(cura_de(b))
	S.curro.vend.append(vd)
	sfx("sel")
	await say(T("{n}: «Hecho. Cada día te dejo lo vendido en el buzón».", {"n": f.n}))
	return false

# MÓVIL → GENTE: a quién conoces y cuánto se fía de ti
func gente() -> void:
	var rows := []
	for id in D.GENTE:
		if S.rel.has(id):
			rows.append({"label": D.GENTE[id], "right": T("{r} · {t}", {"r": rel(id), "t": K("jardinera") if id == "begona" and S.curro.get("jard") else rel_nivel(id)}), "desc": D.QUE_DA.get(id, K("Hablar cada día suma confianza."))})
	for k in D.CLUBS:
		var P = D.PRESI.get(k)
		var no := ""
		if P and not club_te_compra(k):
			var A := {"c": int(D.CLUB.confia), "e": D.GENERO.enc.get(k, K("el encargado")) if Datos.CAL else K("el encargado"), "t": P.t, "a": P.a}
			no = T(" Para que te compren, {c} con {e} y con el {t}.", A) if P.a == "el" else (T(" Para que te compren, {c} con {e} y con la {t}.", A) if P.a == "la" else T(" Para que te compren, {c} con {e} y con {a} {t}.", A))
		if S.rel.has(k):
			rows.append({"label": D.CLUBS[k].n, "right": T("{r} · {t}", {"r": rel(k), "t": rel_nivel(k)}), "desc": (T("Eres socio. Vender y cumplir los encargos suma.") if S.clubs.get(k) else T("Hazte socio para vender y comprar.")) + no})
		if P and S.rel.has("pres_" + k):
			var A := {"t": P.t, "c": D.CLUBS[k].n, "no": no}
			rows.append({"label": P.n, "right": T("{r} · {t}", {"r": rel("pres_" + k), "t": rel_nivel("pres_" + k)}), "desc": T("El {t} de {c}. Hablar e invitarle suma.{no}", A) if P.a == "el" else T("La {t} de {c}. Hablar e invitarle suma.{no}", A)})
	for f in S.fijos:
		var v = _vend_de(f.id)
		rows.append({"label": f.n, "right": T("{r} · {t}", {"r": rel(f.id), "t": K("vende para ti") if v else rel_nivel(f.id)}),
			"desc": T("Le dejaste {l}: le quedan {g}.", {"l": lot_nombre(v.k), "g": g_txt(v.g)}) if v else T("Cliente de la agenda. Buen precio y regalos suman; con {n} vende para ti.", {"n": int(D.REL.socio)})})
	if rows.is_empty():
		await say(K("Todavía no conoces a nadie."))
		return
	var i := 0
	while true:
		i = await menu(rows, {"cls": "full", "title": K("GENTE"), "title2": T("{n} personas", {"n": rows.size()}) if rows.size() > 1 else T("{n} persona", {"n": rows.size()}), "desc": true, "initial": i})
		if i < 0:
			return

func talk_begona():
	var N := K("BEGOÑA")
	var J: Dictionary = D.CURRO.jard
	if S.curro.get("jard"):
		var c: int = await ask(T("¿Qué tal las plantas, majo? Paso cada mañana: {e} al día.", {"e": Datos.eur(J.sueldo)}), [K("Charlar"), K("Que lo deje"), K("Nada")], N)
		if c == 0:
			await say(pick(BEGONA_TIPS), N)
		elif c == 1:
			S.curro.jard = null
			await say(K("Como quieras. Si me necesitas, aquí estoy."), N)
		return
	var ops := [K("Charlar")]
	var reg := T("Regalarle {n} g", {"n": int(D.REL.regaloG)})
	if total_buds() >= D.REL.regaloG:
		ops.append(reg)
	if S.ch >= J.ch and rel("begona") >= D.REL.amigo:
		ops.append(K("Contratarla"))
	ops.append(K("Nada"))
	var oi: int = await ask(K("Tu tía me dejaba cuidarle las plantas cuando se iba. Con confianza, se habla de todo.") if S.ch >= J.ch and rel("begona") < D.REL.amigo else K("Hola, majo. ¿Cómo van esas plantas?"), ops, N)
	var op: String = ops[oi]
	if op == "Charlar":
		await say(pick(BEGONA_TIPS), N)
	elif op == reg:
		if S.flags.get("regBeg") == S.day:
			await say(K("Hoy ya me has dado, majo. Mañana más."), N)
			return
		var lots := bud_lots(D.REL.regaloG)
		var it := lots.map(lot_item)
		it.append({"label": K("Nada")})
		var i: int = await menu(it, {"cls": "right", "title": K("¿Qué le das?")})
		if i < 0 or i >= lots.size():
			return
		use_buds(lots[i][0], D.REL.regaloG)
		S.flags.regBeg = S.day
		confia("begona", int(D.REL.regalo))
		sfx("get")
		await say(K("Ay, gracias. Para dormir, como hacía tu tía."), N)
	elif op == "Contratarla":
		if await ask(T("Te riego, relleno las garrafas y el depósito y, si tienes insecticida, trato las plagas. {e} al día, cada mañana. ¿Hecho?", {"e": Datos.eur(J.sueldo)}), [K("Hecho"), K("Ahora no")], N) != 0:
			return
		S.curro.jard = {"dia": S.day}
		await say(K("Mañana empiezo. Ya sé dónde dejaba la llave tu tía."), N)

# el carné (la cuota, una vez); 1.30: también en la puerta, la primera vez que entras (entra_local). true si eres socio
func carne_club(k: String) -> bool:
	var C: Dictionary = D.CLUBS[k]
	var N: String = C.n
	var A := {"c": C.n, "q": Datos.eur(C.cuota)}
	if await ask(T("{c}. Dentro no se vende nada: lo tuyo entra por la puerta de atrás. La cuota son {q}. ¿Te haces socio?", A) if k == "rv" else T("{c}, asociación de consumidores. Dentro no se vende nada: lo tuyo entra por la puerta de atrás. La cuota son {q}. ¿Te haces socio?", A), [K("Hacerme socio"), K("No")], N) != 0:
		return false
	if S.money < C.cuota:
		sfx("bad")
		await say(K("Sin la cuota no hay carné."), N)
		return false
	S.money -= int(C.cuota)
	S.clubs[k] = true
	S.rep += 1
	confia(k, 2)
	sfx("coin")
	await got(T("el carné de {c}", {"c": C.n}))
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
	var lc: String = K("Comprar") if Datos.CAL else T("Comprar {n} g", {"n": int(D.CLUB.compra)})
	var li := T("Invitar a {n} g", {"n": int(D.REL.regaloG)})
	var ops := [K("Vender al club"), lc, K("Entregar las semillas") if E and E.k == k else K("Encargo de semillas")]
	if D.PRESI.has(k) and rel(k) < D.CLUB.confia and total_buds() >= D.REL.regaloG:
		ops.append(li)
	ops.append(K("Nada"))
	var oi: int = await ask(K("¿Qué te trae?"), ops, N)
	var op: String = ops[oi]
	if op == "Vender al club":
		await vender_club(k)
	elif op == lc:
		await comprar_club(k)
	elif op == li:
		await invitar_club(k, k, N)
	elif op.begins_with("Entregar") or op.begins_with("Encargo"):
		await encargo_club(k)

# (PRESI): fuera del barrio, un club solo te compra (lotes y encargos) si se fían de ti el encargado y su presidente
func club_te_compra(k: String) -> bool:
	return not D.PRESI.has(k) or (rel(k) >= D.CLUB.confia and rel("pres_" + k) >= D.CLUB.confia)

func no_compra(k: String) -> void:
	var P: Dictionary = D.PRESI[k]
	var e: bool = rel(k) < D.CLUB.confia
	var p: bool = rel("pres_" + k) < D.CLUB.confia
	var A := {"p": P.n, "a": P.a, "t": P.t}
	var tx: String
	if e and p:
		tx = T("Aquí no compramos a cualquiera. Antes te tienes que ganar mi confianza y la de {p}, el {t}.", A) if P.a == "el" else (T("Aquí no compramos a cualquiera. Antes te tienes que ganar mi confianza y la de {p}, la {t}.", A) if P.a == "la" else T("Aquí no compramos a cualquiera. Antes te tienes que ganar mi confianza y la de {p}, {a} {t}.", A))
	elif e:
		tx = K("Aquí no compramos a cualquiera. Antes te tienes que ganar mi confianza.")
	else:
		tx = T("Aquí no compramos a cualquiera. Antes te tienes que ganar la confianza de {p}, el {t}.", A) if P.a == "el" else (T("Aquí no compramos a cualquiera. Antes te tienes que ganar la confianza de {p}, la {t}.", A) if P.a == "la" else T("Aquí no compramos a cualquiera. Antes te tienes que ganar la confianza de {p}, {a} {t}.", A))
	await say(tx, D.CLUBS[k].n)

# invitar a probar REL.regaloG g (al encargado, id = k, o al presidente, "pres_" + k); si con eso ya se fían los dos, lo dicen
func invitar_club(id: String, k: String, N: String) -> void:
	if S.clubReg.get(id) == S.day:
		await say(K("Hoy ya me has invitado. Otro día."), N)
		return
	var lots := bud_lots(D.REL.regaloG)
	var it := lots.map(lot_item)
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Qué le das a probar?")})
	if i < 0 or i >= lots.size():
		return
	var antes := club_te_compra(k)
	use_buds(lots[i][0], D.REL.regaloG)
	S.clubReg[id] = S.day
	confia(id, int(D.REL.regalo))
	sfx("get")
	await say(K("Mm. Esto no es de cualquiera. Gracias."), N)
	if not antes and club_te_compra(k):
		sfx("get")
		await say(T("Desde hoy, {c} te compra. Lo tuyo, por la puerta de atrás.", {"c": D.CLUBS[k].n}), N)

func talk_presi(k: String):
	var P: Dictionary = D.PRESI[k]
	var N: String = P.n.to_upper()
	var id: String = "pres_" + k
	var ops := [K("Charlar")]
	var li := T("Invitar a {n} g", {"n": int(D.REL.regaloG)})
	if total_buds() >= D.REL.regaloG:
		ops.append(li)
	ops.append(K("Nada"))
	var A := {"p": P.n, "a": P.a, "t": P.t}
	var soy: String = T("Soy {p}, el {t} del club. A ti todavía no te conozco.", A) if P.a == "el" else (T("Soy {p}, la {t} del club. A ti todavía no te conozco.", A) if P.a == "la" else T("Soy {p}, {a} {t} del club. A ti todavía no te conozco.", A))
	var oi: int = await ask(K("Hombre, {N}. Lo tuyo tiene buena fama entre los socios.") if rel(id) >= D.CLUB.confia else soy, ops, N)
	var op: String = ops[oi]
	if op == "Charlar":
		await say(D.PRESI_TXT[(int(S.day) + D.PRESI.keys().find(k)) % D.PRESI_TXT.size()], N)
	elif op == li:
		await invitar_club(id, k, N)

func vender_club(k: String) -> void:
	var C: Dictionary = D.CLUBS[k]
	var N: String = C.n
	if not club_te_compra(k):
		await no_compra(k)
		return
	var resto: float = resto_mer("club_" + k, D.MERCADO.club.tope) if Datos.CAL else 1e9   # 1.45: varios lotes al día, hasta el tope
	if (S.clubDia.get(k) == S.day and not Datos.CAL) or resto < 1:
		await say(K("Hoy ya hemos cerrado caja. Mañana."), N)
		return
	var VX: Dictionary = D.VENTA_EXTR
	var lots := lotes_venta(D.CLUB.g[0], VX.club_g[0])
	if lots.is_empty():
		await say(T("De {g} g para arriba, entre {a} y {b} € el gramo según el THC. Una entrega al día.", {"g": int(D.CLUB.g[0]), "a": _dos(precio_club(12)), "b": _dos(precio_club(30))}) + (T(" Extracciones, de {g} g para arriba.", {"g": int(VX.club_g[0])}) if Datos.CAL else ""), N)
		return
	var it := lots.map(venta_item)
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Qué lote?")})
	if i < 0 or i >= lots.size():
		return
	var l: Array = lots[i]
	var x := es_extr(l)
	var kk: String = l[0]
	var b: Dictionary = l[1]
	var pg := Datos.jsround((precio_extr(kk, b.thc, "club") if x else precio_club(b.thc)) * calidad(b, not x) * (1.05 if b.get("ana") else 1.0) * 100) / 100.0
	var ops := []
	for g in (VX.club_g if x else D.CLUB.g):
		if g <= floor(b.g) and (g / D.ROSIN.rend if x else float(g)) <= resto:
			ops.append(int(g))
	if ops.is_empty():
		await say(K("Hoy ya no nos cabe tanto. Algo más pequeño, o mañana."), N)
		return
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(g * pg)])
	o.append(K("Nada"))
	var A := {"l": venta_nombre(l), "p": _dos(pg)}
	var j: int = await ask(T("{l} a {p} € el gramo (analizado). ¿Cuánto?", A) if b.get("ana") else T("{l} a {p} € el gramo. ¿Cuánto?", A), o, N)
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
	toast(T("+{e} · {g} g de {x} al club", {"e": Datos.eur(e), "g": g, "x": extr_nombre(kk, true).get_slice(" de ", 0)}) if x else T("+{e} · {g} g al club", {"e": Datos.eur(e), "g": g}), 1600)
	await say(K("Por la puerta de atrás, como siempre. Gracias."), N)
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
		await say(K("Lo de hoy ya está repartido. Mañana hay más."), N)
		return
	var sid: String = C.sid[int(S.day) % C.sid.size()]
	var s: Dictionary = D.STRAINS[sid]
	var p := Datos.jsround(precio_calle(s.thc) * D.CLUB.compraF * D.CLUB.compra)
	if await ask(T("Hoy tenemos {s} ({t} %): {g} g por {e}. ¿Te los llevas?", {"s": s.n, "t": Datos.pct(s.thc), "g": int(D.CLUB.compra), "e": Datos.eur(p)}), [K("Comprar"), K("No")], N) != 0:
		return
	if S.money < p:
		sfx("bad")
		await say(K("Sin dinero no hay reparto."), N)
		return
	if libre_mochila() < D.CLUB.compra:
		await say(K("No te caben en la bolsa."), N)
		return
	S.money -= p
	S.clubCompra[k] = S.day
	confia(k, 1)
	add_buds(sid, D.CLUB.compra, s.thc, S.buds, 1)
	discover(sid)
	sfx("coin")
	toast(T("Comprado: {g} g de {s}", {"g": int(D.CLUB.compra), "s": s.n}), 1200)

func encargo_club(k: String) -> void:
	var N: String = D.CLUBS[k].n
	var E = S.get("clubEnc")
	var EN: Dictionary = D.CLUB.enc
	if E:
		if E.k != k:
			await say(T("Ya tienes un encargo pendiente en {c}. Cumple ese primero.", {"c": D.CLUBS[E.k].n}), N)
			return
		var s = strain(E.sid)
		var t: int = int(S.seeds.get(E.sid, 0))
		if t < E.n:
			await say(T("Nos faltan {n} semillas de {s}. Hasta el {f}.", {"n": int(E.n) - t, "s": s.n, "f": Datos.fd(E.hasta, S.day)}), N)
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
		toast(T("+{e} · {n} semillas de {s}", {"e": Datos.eur(E.pago), "n": int(E.n), "s": s.n}), 1600)
		await say(K("Las sembramos para los socios. Buen trabajo."), N)
		await check_story()
		return
	if not club_te_compra(k):
		await no_compra(k)
		return
	if S.clubEncDia == S.day:
		await say(K("Hoy ya no hay más encargos. Mañana."), N)
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
	if await ask(T("Los socios quieren {n} semillas de {s}. Pagamos {e}, en {d} días. ¿Te encargas?", {"n": int(EN.n), "s": s.n, "e": Datos.eur(pago), "d": int(EN.dias)}), [K("Aceptar"), K("No")], N) != 0:
		await say(K("Si cambias de idea, aquí estamos."), N)
		return
	S.clubEnc = {"k": k, "sid": sid, "n": int(EN.n), "hasta": S.day + int(EN.dias), "pago": pago}
	await say(T("Hasta el {f}. Las semillas, aquí.", {"f": Datos.fd(S.clubEnc.hasta, S.day)}), N)

func vencer_encargo_club() -> void:
	var E = S.get("clubEnc")
	if E == null or S.day <= E.hasta:
		return
	S.clubEnc = null
	S.rep = maxi(0, S.rep - 3)
	confia(E.k, -10)
	var Nc: String = T("SMS · {n}", {"n": D.CLUBS[E.k].n})
	var L := [K("Se acabó el plazo de las semillas. Los socios no se olvidan.")]
	queue("clubEnc", func(): await talk(Nc, L), [[Nc, L]])   # i18n-no

# la cata (desde la mochila) y el analizador de THC
func nota_cata(sid: String, thc: float) -> String:
	var ind := Datos.ind_de(S, sid)
	var a: String = aroma_de(sid)
	var e := K("relaja y pesa") if ind >= 65 else (K("sube y despeja") if ind <= 35 else K("equilibrado"))
	var p: String = T("{t} % de THC", {"t": Datos.pct(thc)}) if S.items.get("analizador") else (K("floja") if thc < 12 else (K("media") if thc < 18 else (K("fuerte") if thc < 24 else K("muy fuerte"))))
	return T("Aroma {a} ({tp}) · {e} · {p}", {"a": a, "tp": D.TERPENOS[a], "e": e, "p": p}) if S.items.get("analizador") else T("Aroma {a} · {e} · {p}", {"a": a, "e": e, "p": p})

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
	await say((T("Catas {l}: {n}.", {"l": lot_nombre(k), "n": S.catas[sid]}) if g == D.CATA.g else T("Catas {g} g de {l}: {n}.", {"g": Datos.coma(g), "l": lot_nombre(k), "n": S.catas[sid]})) + (T(" Bien curada: suave y con todo el aroma.") if cu >= 1 else (T(" Sin curar del todo: rasca y huele a verde.") if cu or fresca else "")) + (cata_efecto(g, thc) if Datos.CAL else ""))   # 1.29

func marca_cata(k: String, r: bool, sid: String, thc: float) -> void:
	var L: Dictionary = S.rosin if r else S.buds
	if L.has(k):
		L[k].cata = true
	S.catas[("r:" + k) if r else sid] = nota_cata(sid, thc)

func cata_efecto(g: float, thc: float) -> String:   # cuánto sube: los mg de THC que llevas encima
	var mg := g * thc * 10
	return "" if mg < 60 else (T(" Te deja tocado un buen rato.") if mg < 150 else T(" Demasiado: te quedas un buen rato mirando a la pared."))

func cata_cuanto(k: String, r: bool):
	var b: Dictionary = (S.rosin if r else S.buds)[k]
	var mx: float = floor(minf(float(CATA_MAX["r" if r else "b"]), float(b.g)) * 100) / 100.0
	if mx < .1:
		return 0
	return await cuanto(T("¿Cuánto catas? (de una vez, {g} g como mucho)", {"g": Datos.coma(CATA_MAX["r" if r else "b"])}), snappedf(mx, .01), CATA_PASOS["r" if r else "b"], func(q): return Datos.coma(q) + " g")

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
	await say(T("Catas {g} g de {x}: {n}.", {"g": Datos.coma(g), "x": extr_nombre(k, true), "n": S.catas["r:" + k]}) + (cata_efecto(g, thc) if Datos.CAL else ""))

func extr_accion(k: String) -> void:
	var b: Dictionary = S.rosin[k]
	var ops := [K("Catar…"), K("Tirar"), K("Nada")]
	var A := {"x": extr_nombre(k, true), "g": Datos.coma(b.g), "t": Datos.pct(b.thc)}
	var oi: int = await ask(T("{x}: {g} g · {t} % · catado", A) if b.get("cata") else T("{x}: {g} g · {t} %", A), ops)
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
	await say(T("Analizado: {l} · THC {t} % · CBD {c} % · terpeno principal, {p}. Lo que va con análisis se vende mejor.", {"l": lot_nombre(k), "t": Datos.pct(b.thc), "c": Datos.pct(cbd_de(sid)), "p": D.TERPENOS[aroma_de(sid)]}))

func lote_accion(k: String) -> void:
	var b: Dictionary = S.buds[k]
	var ops := [K("Catar…") if Datos.CAL else T("Catar {g} g", {"g": Datos.coma(D.CATA.g)})]
	if S.items.get("analizador") and not b.get("ana"):
		ops.append(K("Analizar"))
	ops.append_array([K("Tirar"), K("Nada")])
	var A := {"l": lot_nombre(k), "g": int(floor(b.g)), "t": Datos.pct(b.thc), "c": cura_corto(b)}
	var ca: bool = true if b.get("cata") else false
	var an: bool = true if b.get("ana") else false
	var tx: String = (T("{l}: {g} g · {t} %{c} · catado · analizado", A) if an else T("{l}: {g} g · {t} %{c} · catado", A)) if ca else (T("{l}: {g} g · {t} %{c} · analizado", A) if an else T("{l}: {g} g · {t} %{c}", A))
	var oi: int = await ask(tx, ops)
	var op: String = ops[oi]
	if op == "Catar…":   # 1.47
		var g = await cata_cuanto(k, false)
		if g:
			await catar(k, g)
	elif op == ops[0]:
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
	var g = await cuanto(T("Tirar {x}: ¿cuánto?", {"x": extr_nombre(k, true) if r else lot_nombre(k)}), mx, [1, 5, 10, 50] if r else [10, 50, 100, 500, 1000],
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
	await say(T("Tiras {g} g de {x}.", {"g": Datos.coma(g), "x": extr_nombre(k, true)}) if r else T("Tiras {g} de {x}.", {"g": g_txt(g), "x": lot_nombre(k)}))

# los rivales (1.16, 13-combate): en las zonas de venta lejos de Darko, un camello que no quiere competencia. Cada venta en la calle
# de su zona le suma una (S.rivales[zona]); con RIVAL.umbral sale a buscarte: pelear, pagarle su cuota o irte
func nom_rival(R: Dictionary) -> String:
	return R.n.substr(0, 1) + R.n.substr(1).to_lower()

func cuota_rival(z: String) -> int:
	return Datos.jsround(D.RIVAL.cuota * D.ZONAS[z].precio)

func rival_b(kind := "rival") -> Dictionary:
	if kind == "darko":
		return {"kind": "thief", "rival": K("Darko"), "jefe": 1, "name": K("DARKO"), "look": D.LOOKS.darko, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	var R: Dictionary = D.RIVALES.get(S.map, D.RIVALES.alto)
	return {"kind": "thief", "rival": nom_rival(R), "name": R.n, "look": look_rival(R), "t": 0.0, "flashE": 0.0, "shakeP": 0.0}

# El muñeco del rival, del sexo de su nombre (GENERO.rival)
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
	await talk(N, [T("Eh, tú. Llevas {n} ventas en {s}.", {"n": int(S.rivales[z]), "s": R.sitio}), R.frase, T("O me pagas {e} o lo arreglamos aquí.", {"e": Datos.eur(c)})])
	var o: int = await ask(K("¿Qué haces?"), [K("Pelear"), T("Pagarle {e}", {"e": Datos.eur(c)}), K("Irte")], N)
	if o == 0:
		var r = await battle("rival")
		if r == "win":
			S.rivalFuera[z] = S.day + int(D.RIVAL.dias)
			S.rivales[z] = 0
			sfx("get")
			await say(T("{n} no volverá por {s} en {d} días. Mientras, sus clientes te pagan un {p} % más.", {"n": nom, "s": R.sitio, "d": int(D.RIVAL.dias), "p": Datos.jsround((D.RIVAL.f - 1) * 100)}))
			return
		if r == "talk":
			S.rivales[z] = 0
			await say(T("{n}: «Vale. Pero no te quiero ver tanto por aquí.»", {"n": nom}))
			return
		S.rivales[z] = 0 if r == "ko" else int(D.RIVAL.umbral) - int(D.RIVAL.vuelve)
		return
	if o == 1 and S.money >= c:
		S.money -= c
		S.rivales[z] = 0
		sfx("coin")
		update_hud()
		await say(T("{n} se guarda el dinero. «Así me gusta. Hasta la próxima.»", {"n": nom}))
		return
	if o == 1:
		await say(K("No llevas tanto dinero encima."))
	S.rivales[z] = int(D.RIVAL.umbral) - int(D.RIVAL.vuelve)
	await say(T("Te apartas. {n} se queda mirándote.", {"n": nom}))
