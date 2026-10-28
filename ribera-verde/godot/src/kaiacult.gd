# La sala de cultivo de KAIA (lo pidió el usuario: «incluso molaría tener un cultivo finalmente en la nueva asociación de KAIA» y,
# de las carpas, «tiene que tener lógica con el suelo que hay al rededor y las zonas donde las colocas»; solo con Datos.CAL): por la
# puerta (15, 1) del club, cerrada hasta tener la licencia (S.mar.lic). Por fases (lo pidió el usuario: «como en casa, cultivo con
# carpas, pero más grandes de primeras, con una inversión realista, después como en la nave en esa misma habitación, ya con
# posibilidad de poner a alguien a trabajar ahí y la inversión será más grande»):
#  · fase 1: las carpas por niveles (lo pidió el usuario: «4 de 2×2, luego 2 de 4×2, luego una de 4×4 y después la reforma»;
#    KAIA_CULT.niv, cada nivel con su kit: la carpa, sus LED de 720 W, el extractor con su filtro y el goteo) que se pagan con la
#    cuenta desde el cuadro (ctrlN) y llegan al día siguiente, hasta N.max; al pasar al siguiente (kc_sube), las de antes se venden de
#    segunda mano y llega la primera del nuevo; N.plazas por carpa, con el riego
#    y el clima solos (kc_avanza desde plants_advance); A en una carpa, sus plazas, y en cada una lo de siempre (pot_action con hu,
#    como la huerta de campo.gd). Las carpas se ordenan desde el cuadro, solo encima de la zona de cultivo (la regla zona de
#    cabe_pieza) y sin montarse encima de nada (pieza_solapa).
#  · fase 2: la obra de la sala entera (KAIA_CULT.f2), con las plazas vacías: las carpas se venden de segunda mano y, a los días de la
#    obra, la sala lleva las mesas de la nave con su LED doble, el riego centralizado y alguien de la plantilla de cultivo (rol kaia);
#    cada mañana las lleva como un navero (kc_dia, desde nave_dia), lo cortado se seca y va al almacén de KAIA; lo que no cabe, en su
#    mesa, para llevártelo.
# S.kc = {niv: el nivel de las carpas, kits: [día de llegada de cada kit], p: [plantas o null, las plazas de cada carpa seguidas
# (kc_off)], pat: [el esquema de cada carpa o null], f2: null o el día en que acaba la obra, m: [mesas]}.
# El esquema de cada carpa (lo pidió el usuario: «Posibilidad de poner x de cierto tamaño, elegir por patrones igual, cuando ya tienes
# ciertas macetas para completar todo el esquema de la carpa te ofrece poner X cantidad dependiendo de cada maceta»): {m: maceta,
# n: plazas}; sin él, el del kit (N.plazas macetas de KAIA_CULT.maceta). KC_PATRON[N.k] dice cuántas de cada maceta llenan la carpa
# (tools/patrones.py); la luz de la carpa se reparte entre las n, al mismo ritmo: más plantas pequeñas (más fenotipos donde
# elegir) o menos y más grandes (las de 50 L rinden más por cosecha).
# Datos de tools/kaia_cult.py (KAIA_CULT, MAPS["cult-muelle"]). Cadena: … → hilo → bancotia → kaiacult → salafria → retencion → juego.
extends "res://src/bancotia.gd"

var _kc0 = null   # los muebles de la sala tal como vienen de datos.json, para montar las mesas encima

const KC_KIT_VIEJO := 3180   # lo que costaba el kit de 240 × 240 de antes de los niveles

func kc() -> Dictionary:
	if not (S.get("kc") is Dictionary):
		S.kc = {"niv": 0, "kits": [], "p": []}
	if not S.kc.has("kits"):   # la primera, con tres carpas de 4 plazas de regalo: cada una, un kit montado de 9 plazas, con sus plantas
		var viejas: Array = S.kc.get("p", [])
		S.kc = {"kits": [0, 0, 0], "p": []}
		for i in viejas.size():
			if viejas[i] is Dictionary:
				while S.kc.p.size() <= (i / 4) * 9 + i % 4:
					S.kc.p.append(null)
				S.kc.p[(i / 4) * 9 + i % 4] = viejas[i]
	if not S.kc.has("niv"):   # la de los kits de 240 × 240: en el nivel de las de 4 × 2, con dos como mucho y sus plantas en las primeras plazas
		var N1: Dictionary = D.KAIA_CULT.niv[1]
		var pl: Array = S.kc.p.filter(func(q): return q is Dictionary)
		S.kc.niv = 0 if S.kc.get("f2") != null else 1
		var kv: Array = S.kc.kits
		S.kc.kits = kv.slice(0, int(N1.max)) if S.kc.get("f2") == null else []
		var cabe: int = int(N1.plazas) * S.kc.kits.size()
		S.kc.p = pl.slice(0, cabe)
		# lo que no cabe, devuelto: los kits de más (también el que venía de camino) a lo que costaron, y de cada planta, su semilla
		var dev: int = (kv.size() - S.kc.kits.size()) * KC_KIT_VIEJO
		var sem := 0
		for q in pl.slice(cabe):
			var sid := str(q.get("sid", ""))
			if sid != "":
				S.seeds[sid] = int(S.seeds.get(sid, 0)) + 1
				sem += 1
		if dev > 0:
			abono_banco(float(dev), K("Kits de carpa devueltos (KAIA)"))
		if dev > 0 or sem > 0:
			var L := [T("La sala de cultivo de KAIA pasa a las carpas nuevas. Lo que no cabe se devuelve: {e} a la cuenta por los kits de más y {n} semillas por las plantas que no caben.", {"e": Datos.eur(dev), "n": sem})]
			queue("kcmig", func(): await say(L[0]), [["", L]])
		if S.get("coloca") is Dictionary:
			S.coloca.erase(D.KAIA_CULT.mapa)
	var n: int = kc_off(int(kc_N().max))
	while S.kc.p.size() < n:
		S.kc.p.append(null)
	return S.kc

func kc_N() -> Dictionary:   # el nivel de las carpas
	return D.KAIA_CULT.niv[clampi(int(S.kc.get("niv", 0)), 0, D.KAIA_CULT.niv.size() - 1)]

func kc_pat(ci: int) -> Dictionary:   # el esquema de la carpa ci: {m: maceta, n: plazas}
	var l: Array = S.kc.get("pat", []) if S.get("kc") is Dictionary else []
	if ci >= 0 and ci < l.size() and l[ci] is Dictionary:
		return l[ci]
	return {"m": D.KAIA_CULT.maceta, "n": int(kc_N().plazas), "kit": true}   # las del kit: no son tuyas, no van a la mochila

func kc_n(ci: int) -> int:
	return int(kc_pat(ci).n)

func kc_off(ci: int) -> int:   # dónde empiezan en S.kc.p las plazas de la carpa ci
	var o := 0
	for c in ci:
		o += kc_n(c)
	return o

func kc_ci(i: int) -> int:   # la carpa de la plaza i
	var o := 0
	for c in int(kc_N().max):
		o += kc_n(c)
		if i < o:
			return c
	return int(kc_N().max) - 1

# los esquemas de este nivel que se pueden poner: [[maceta, n]…]
func kc_patrones() -> Array:
	var l := []
	for q in D.get("KC_PATRON", {}).get(String(kc_N().k), []):   # i18n-no
		if D.MACETAS.has(q[0]):
			l.append([String(q[0]), int(q[1])])
	return l

func kc_hay() -> bool:
	return Datos.CAL and S != null and D.has("KAIA_CULT")

func kc_lic() -> bool:
	return kc_hay() and S.get("mar") is Dictionary and S.mar.get("lic") != null

# los kits ya montados (los que han llegado)
func kc_kits() -> int:
	var n := 0
	for d in kc().kits:
		if int(d) <= int(S.day):
			n += 1
	return n

func kc_f2() -> bool:   # la sala reformada, con las mesas
	return kc_hay() and S.get("kc") is Dictionary and S.kc.get("f2") != null and int(S.kc.f2) <= int(S.day)

func kc_obra() -> bool:   # la obra en marcha
	return kc_hay() and S.get("kc") is Dictionary and S.kc.get("f2") != null and int(S.kc.f2) > int(S.day)

# la puerta de la sala, desde KAIA (calle.gd object_action): sin la licencia, cerrada
func kc_cerrada() -> bool:
	if kc_lic():
		return false
	await say(K("La sala de cultivo de KAIA, cerrada. Hasta tener la licencia de cultivo, aquí dentro no se planta nada."))
	return true

# los factores de una plaza de la carpa ci, como Cultivo.factores con la carpa grande, sus LED y las macetas de su esquema, y su clima
# controlado
func kc_f(ci := 0, P = null) -> Dictionary:
	var KC: Dictionary = D.KAIA_CULT
	var N: Dictionary = kc_N()
	if P == null:
		P = kc_pat(ci)
	var cm: Array = N.cm
	var F: Dictionary = D.FOCOS[KC.foco]
	var M: Dictionary = D.MACETAS.get(P.m, D.MACETAS[KC.maceta])
	var np := float(P.n)
	var w: float = float(F.w) * float(N.nf)
	var dens := minf(1, w / (float(cm[0]) * float(cm[1]) / 1e4 * float(D.W_M2)))
	return {"g": w * float(F.gpw) / np * float(M.rend) * float(N.get("efi", 1.0)), "cap": float(M.cap), "crec": float(F.crec) * (.85 + .15 * dens) * float(M.crec) * Cultivo.f_clima(KC.clima),
		"thc": float(F.thc) * dens, "agua": float(F.agua) * float(M.agua), "plaga": float(M.plaga), "dens": dens, "hr": float(KC.clima.hr), "moho": 1.0, "ciclo": "auto"}   # i18n-no

func kc_pos(ci: int) -> Array:
	return pos_pieza(D.KAIA_CULT.mapa, "kc%s%d" % [kc_N().k, ci])

func kc_hu(i: int) -> Dictionary:
	var t: Array = kc_N().tam
	var ci := kc_ci(i)
	var p := kc_pos(ci)
	return {"l": kc().p, "v": [int(p[0]) * 16 + int(t[0]) * 8, (int(p[1]) + int(t[1]) - 1) * 16], "f": kc_f(ci)}

func kc_carpa_en(x: int, y: int) -> int:   # la carpa (N.tam casillas) con la casilla (x, y), o -1
	if kc_f2() or kc_obra():
		return -1
	var t: Array = kc_N().tam
	for ci in kc_kits():
		var p := kc_pos(ci)
		if y >= int(p[1]) and y < int(p[1]) + int(t[1]) and x >= int(p[0]) and x < int(p[0]) + int(t[0]):
			return ci
	return -1

func kc_plantadas(ci: int) -> int:
	var n := 0
	var o := kc_off(ci)
	for j in kc_n(ci):
		if kc().p[o + j] is Dictionary:
			n += 1
	return n

func kc_vacias() -> bool:
	for p in kc().p:
		if p is Dictionary:
			return false
	return true

# cada carpa montada sale en ORDENAR solo si su kit ha llegado y no hay obra
func pieza_ya(P_: Dictionary) -> bool:
	if str(P_.get("si", "")) == "kc":
		return kc_hay() and not kc_f2() and not kc_obra() and str(P_.k).substr(2, 1) == str(kc_N().k) and int(str(P_.k).substr(3)) < kc_kits()
	return super(P_)

# cada carpa con las plantas que tiene (kcs-<n>, kcm-<n>, kcl-<n>, de kaia_carpa.py)
func sprite_local(o: String) -> String:
	if kc_hay():
		for N in D.KAIA_CULT.niv:
			if o.begins_with(N.obj):
				return "%s-%d" % [N.spr, kc_dibujo(int(o.substr(String(N.obj).length()))) if N.k == kc_N().k else 0]   # i18n-no
	return super(o)

# las plantas que se dibujan en la carpa: el sprite tiene una por plaza del kit (N.plazas); con otro esquema, a esa escala
func kc_dibujo(ci: int) -> int:
	var q := kc_plantadas(ci)
	var np: int = int(kc_N().plazas)
	return 0 if q == 0 else clampi(ceili(float(q) * np / float(kc_n(ci))), 1, np)

func bt_entra(mapa: String) -> void:
	super(mapa)
	if kc_hay() and mapa == D.KAIA_CULT.mapa:
		kc()
		kc_monta()

# la sala: las carpas que hayan llegado (aplica_orden) o, reformada, las mesas, el tanque y la bomba
func kc_monta() -> void:
	var mapa: String = D.KAIA_CULT.mapa
	var m: Dictionary = MAPS[mapa]
	if _kc0 == null:
		_kc0 = m.o.duplicate(true)
	m.o = _kc0.duplicate(true)   # siempre desde la sala vacía: lo de antes no se queda debajo
	m.erase("opos")
	aplica_orden(mapa)
	if not kc_f2():
		return
	var F2: Dictionary = D.KAIA_CULT.f2
	for e in F2.o:
		m.o[int(e[1])][int(e[0])] = e[2]
	for q in F2.mesas:
		m.o[int(q[1])][int(q[0])] = "mesaKC"   # i18n-no
		m.o[int(q[1])][int(q[0]) + 1] = "mesaKC2"   # i18n-no

# después de mover una carpa con ORDENAR (setas.gd mover_pieza), la sala con cada una donde se dejó
func rehace_orden(mapa: String) -> void:
	if kc_hay() and mapa == D.KAIA_CULT.mapa:
		kc_monta()
		return
	super(mapa)

func bt_obj(x: int, y: int, o) -> bool:
	if kc_hay() and S.map == D.KAIA_CULT.mapa:
		return await kc_obj(x, y, o)
	return await super(x, y, o)

func kc_obj(x: int, y: int, o) -> bool:
	var ci := kc_carpa_en(x, y)
	if ci >= 0:
		await kc_carpa(ci)
		return true
	var mi := kc_mesa_idx(x, y)
	if mi >= 0:
		await kc_mesa(mi)
		return true
	match o:
		"ctrlN":   # i18n-no
			await kc_cuadro()
			return true
		"tanqueN":   # i18n-no
			await say(K("El tanque del riego centralizado, con el abono ya mezclado: las bombas lo llevan a cada mesa."))
			return true
		"riegoN":   # i18n-no
			await say(K("El programador del riego de las mesas: los turnos de cada una, el pH y la EC, en automático."))
			return true
	return false

# el cuadro de la pared: el temporizador, el clima y lo que se compra para la sala
func kc_cuadro() -> void:
	var KC: Dictionary = D.KAIA_CULT
	while true:
		var ops := []
		var txt := ""
		if kc_obra():
			await say(T("La sala, en obras: desagües, el cuadro trifásico y el clima industrial. Las mesas estarán montadas el {f}.", {"f": Datos.fd(int(S.kc.f2), S.day)}))
			return
		if kc_f2():
			var w = kc_cultiva()
			txt = T("El cuadro de la sala: seis mesas con su LED doble, el riego centralizado y el clima. {q}", {"q": T("Las lleva {n}.", {"n": w.n}) if w != null else K("Nadie las lleva: pon a alguien de tu plantilla en la sala desde el móvil.")})
			ops.append(K("Salir"))
		else:
			var N: Dictionary = kc_N()
			var nk: int = kc().kits.size()
			txt = T("El cuadro de la sala: el temporizador de los LED, el goteo y el clima. Todo en automático: muchas horas de luz mientras crecen y menos en cuanto toca florecer. Carpas de {n}: {k} de {m}.", {"n": I18n.v(N.n), "k": nk, "m": int(N.max)})
			if nk < int(N.max):
				ops.append(T("Comprar una carpa · {e}", {"e": Datos.eur(N.kit.p)}))
			if kc_kits() >= 1:
				ops.append(K("Ordenar la sala"))
			var sig = kc_sig()
			if sig != null:
				ops.append(T("Pasar a la {n} · {e}", {"n": I18n.v(sig.n), "e": Datos.eur(sig.kit.p)}))
			else:
				ops.append(T("Reformar la sala · {e}", {"e": Datos.eur(KC.f2.p)}))
			ops.append(K("Salir"))
		var c: int = await ask(txt, ops)
		var op: String = ops[c] if c >= 0 and c < ops.size() else ""
		if op.begins_with(K("Comprar una carpa")):
			await kc_compra_kit()
		elif op.begins_with(K("Pasar a la")):
			await kc_sube()
		elif op == K("Ordenar la sala"):
			await ordenar(S.map)
			return
		elif op.begins_with(K("Reformar la sala")):
			await kc_reforma()
		else:
			return

func kc_kit_txt(N: Dictionary) -> String:
	var l := []
	for x in N.kit.l:
		l.append(T("{n}: {e}", {"n": I18n.v(x[0]), "e": Datos.eur(x[1])}))
	return "; ".join(PackedStringArray(l))

func kc_compra_kit() -> void:
	var N: Dictionary = kc_N()
	if await ask(T("El kit de la {c}, a precio de tienda: {l}. En total, {e}, con la tarjeta; llega mañana y lo montan aquí.", {"c": I18n.v(N.n), "l": kc_kit_txt(N), "e": Datos.eur(N.kit.p)}), [K("Comprarlo"), K("Ahora no")]) != 0:
		return
	if not await tarjeta(float(N.kit.p), K("Kit de carpa (KAIA)")):
		return
	kc().kits.append(int(S.day) + 1)
	sfx("get")
	await say(T("Pedido: la carpa {n} llega mañana, con sus LED, el extractor y el goteo. {p} plazas más.", {"n": kc().kits.size(), "p": int(N.plazas)}))

func kc_sig():   # el nivel siguiente, o null en el último (después, la reforma)
	var i: int = int(kc().get("niv", 0)) + 1
	return D.KAIA_CULT.niv[i] if i < D.KAIA_CULT.niv.size() else null

# pasar al nivel siguiente: las carpas de ahora, de segunda mano; la primera del nuevo, pagada y mañana aquí
func kc_sube() -> void:
	var N: Dictionary = kc_N()
	var N2 = kc_sig()
	if N2 == null:
		return
	var vende := roundi(float(N.kit.p) * float(D.KAIA_CULT.f2.venta) * kc().kits.size())
	var t := T("La {c}, con su kit a precio de tienda: {l}. En total, {e}, con la tarjeta; llega mañana y caben más.", {"c": I18n.v(N2.n), "l": kc_kit_txt(N2), "e": Datos.eur(N2.kit.p)})
	if kc().kits.size():
		t += " " + T("Las carpas de ahora se desmontan y se venden de segunda mano por {e}.", {"e": Datos.eur(vende)})
	if not kc_vacias():
		await say(t + " " + K("Antes, cosecha o arranca lo que tengas en las carpas."))
		return
	if kc().kits.any(func(d): return int(d) > int(S.day)):
		await say(t + " " + K("Antes, espera a que llegue la carpa que tienes pedida."))
		return
	if await ask(t, [K("Comprarla"), K("Ahora no")]) != 0:
		return
	if not await tarjeta(float(N2.kit.p), K("Kit de carpa (KAIA)")):
		return
	if vende > 0:
		abono_banco(vende, K("Carpas de segunda mano (KAIA)"))
	var mv := kc_devuelve_macetas()
	kc().niv = int(kc().get("niv", 0)) + 1
	kc().kits = [int(S.day) + 1]
	kc().p = []
	kc()
	if S.get("coloca") is Dictionary:
		S.coloca.erase(D.KAIA_CULT.mapa)
	kc_monta()
	sfx("get")
	await say(T("Pedido: la primera {c} llega mañana, con sus LED, el extractor y el goteo; caben {m}.", {"c": I18n.v(N2.n), "m": int(N2.max)}) + (" " + T("Las {n} macetas que pusiste tú, a la mochila.", {"n": mv}) if mv else ""))

func kc_reforma() -> void:
	var KC: Dictionary = D.KAIA_CULT
	var F2: Dictionary = KC.f2
	var l := []
	for x in F2.l:
		l.append(T("{n}: {e}", {"n": I18n.v(x[0]), "e": Datos.eur(x[1])}))
	var vende := roundi(float(kc_N().kit.p) * float(F2.venta) * kc().kits.size())
	var t := T("La sala entera como la nave: {l}. En total, {e}, con la tarjeta; la obra dura {d} días. Después, las mesas las lleva alguien de tu plantilla.", {"l": "; ".join(PackedStringArray(l)), "e": Datos.eur(F2.p), "d": int(F2.dias)})
	if kc().kits.size():
		t += " " + T("Las carpas se desmontan y se venden de segunda mano por {e}.", {"e": Datos.eur(vende)})
	if not kc_vacias():
		await say(t + " " + K("Antes, cosecha o arranca lo que tengas en las carpas."))
		return
	if kc().kits.any(func(d): return int(d) > int(S.day)):   # un kit pagado y en camino: primero que llegue
		await say(t + " " + K("Antes, espera a que llegue la carpa que tienes pedida."))
		return
	if await ask(t, [K("Hacer la obra"), K("Ahora no")]) != 0:
		return
	if not await tarjeta(float(F2.p), K("Obra de la sala de cultivo (KAIA)")):
		return
	if vende > 0:
		abono_banco(vende, K("Carpas de segunda mano (KAIA)"))
	kc_devuelve_macetas()
	kc().kits = []
	kc().f2 = int(S.day) + int(F2.dias)
	kc().m = []
	for q in F2.mesas:
		kc().m.append(null)
	if S.get("coloca") is Dictionary:
		S.coloca.erase(KC.mapa)
	kc_monta()
	sfx("get")
	await say(T("Empieza la obra. El {f}, la sala con sus mesas.", {"f": Datos.fd(int(S.kc.f2), S.day)}))

# las plazas de una carpa: cada una, con su planta o vacía; A, lo de siempre (pot_action)
func kc_carpa(ci: int) -> void:
	if not kc_lic():
		await say(K("Sin la licencia de cultivo, las carpas se quedan vacías."))
		return
	var np := kc_n(ci)
	var o := kc_off(ci)
	var P := kc_pat(ci)
	var l: int = int(D.MACETAS.get(P.m, {"l": 0}).l)
	var it := []
	for j in np:
		var p = kc().p[o + j]
		if p is Dictionary:
			it.append({"label": T("Plaza {n}", {"n": j + 1}), "right": strain(p.sid).n, "desc": T("{st} {p}% · Agua {w}% · Salud {h}%", {"st": stage_name(p), "p": int(floor(float(p.prog) * 100)), "w": Datos.jsround(p.water), "h": Datos.jsround(p.health)})})
		else:
			it.append({"label": T("Plaza {n}", {"n": j + 1}), "right": K("vacía"), "desc": T("Una maceta de tela de {l} L con su gotero.", {"l": l})})
	var pue := kc_puedes(ci)
	it.append({"label": K("Esquema de la carpa"), "right": T("{n} × {l} L", {"n": np, "l": l}), "desc": (T("Con las macetas que tienes, puedes ponerle {q}.", {"q": pue}) if pue != "" else K("Cuántas macetas lleva y de qué tamaño: con otro esquema, más plantas más pequeñas o menos y más grandes."))})
	it.append({"label": K("Salir"), "desc": ""})
	var i: int = await menu(it, {"cls": "full", "title": T("LA CARPA {n}", {"n": ci + 1}), "desc": true})
	if i == np:
		await kc_esquema(ci)
		return
	if i < 0 or i >= np:
		return
	await pot_action(o + i, kc_hu(o + i))

# las macetas de un tamaño que tienes para la carpa ci: las de la mochila y, si son del mismo, las que ya lleva
func kc_tengo(ci: int, k: String) -> int:
	var P := kc_pat(ci)
	return int(S.items.get("m_" + k, 0)) + (int(P.n) if P.m == k and not P.get("kit") else 0)

# los esquemas que ya puedes completar con tus macetas, en texto («9 de 35 L o 16 de 25 L»), o ""
func kc_puedes(ci: int) -> String:
	var P := kc_pat(ci)
	var l := []
	for q in kc_patrones():
		if not (q[0] == P.m and q[1] == int(P.n)) and kc_tengo(ci, q[0]) >= q[1]:
			l.append(T("{n} de {l} L", {"n": q[1], "l": int(D.MACETAS[q[0]].l)}))
	return (" " + K("o") + " ").join(PackedStringArray(l))

func kc_precio_maceta(k: String) -> float:
	for it in D.SHOP:
		if it.get("maceta") == k:
			return float(it.p)
	return 0.0

# elegir el esquema de la carpa ci: cuántas macetas de cada tamaño, con las que tienes y, si faltan, las que faltan por la cuenta
func kc_esquema(ci: int) -> void:
	var P := kc_pat(ci)
	var l := kc_patrones()
	var N := kc_N()
	var it := []
	for q in l:
		var M: Dictionary = D.MACETAS[q[0]]
		var f := kc_f(ci, {"m": q[0], "n": q[1]})
		var gp: float = minf(float(f.g), float(f.cap))
		var ya: bool = q[0] == P.m and q[1] == int(P.n)
		var t := kc_tengo(ci, q[0])
		it.append({"label": T("{n} macetas de {l} L", {"n": q[1], "l": int(M.l)}), "right": K("puesto") if ya else (T("tienes {t}", {"t": t}) if t < q[1] else K("las tienes")), "ic": icono("maceta"),
			"desc": T("{tl} L de tierra · unos {g} por planta y {c} la carpa por cosecha", {"tl": q[1] * int(M.l), "g": g_txt(gp), "c": g_txt(gp * q[1])})})
	it.append({"label": K("Salir"), "desc": ""})
	var j: int = await menu(it, {"cls": "full", "title": T("ESQUEMA DE LA CARPA {n}", {"n": ci + 1}), "title2": T("Ahora: {n} macetas de {l} L", {"n": int(P.n), "l": int(D.MACETAS.get(P.m, {"l": 0}).l)}), "desc": true})
	if j < 0 or j >= l.size():
		return
	var k: String = l[j][0]
	var nn: int = l[j][1]
	var lk: int = int(D.MACETAS[k].l)
	if k == P.m and nn == int(P.n):
		await say(K("La carpa ya lleva ese esquema."))
		return
	if kc_plantadas(ci) > 0:
		await say(K("Antes, cosecha o arranca lo que tengas en esta carpa: las macetas se cambian con la carpa vacía."))
		return
	var t := kc_tengo(ci, k)
	var falta := maxi(0, nn - t)
	var e := falta * kc_precio_maceta(k)
	var txt := T("Retiras las {a} macetas de {la} L del kit y pones {n} de {l} L, con sus goteros: {tl} L de tierra.", {"a": int(P.n), "la": int(D.MACETAS.get(P.m, {"l": 0}).l), "n": nn, "l": lk, "tl": nn * lk}) if P.get("kit") else T("Quitas las {a} macetas de {la} L y pones {n} de {l} L, con sus goteros: {tl} L de tierra. Las que sobren, a la mochila.", {"a": int(P.n), "la": int(D.MACETAS.get(P.m, {"l": 0}).l), "n": nn, "l": lk, "tl": nn * lk})
	if falta > 0:
		txt += " " + T("Tienes {t}: las {f} que faltan se piden por {e} con la tarjeta y te las suben ahora.", {"t": t, "f": falta, "e": Datos.eur(e)})
	if await ask(txt, [K("Ponerlas") if falta == 0 else K("Pedirlas y ponerlas"), K("Ahora no")]) != 0:
		return
	if falta > 0 and not await tarjeta(e, K("Macetas de la sala de cultivo (KAIA)")):
		return
	if not P.get("kit"):
		S.items["m_" + String(P.m)] = int(S.items.get("m_" + String(P.m), 0)) + int(P.n)
	S.items["m_" + k] = int(S.items.get("m_" + k, 0)) + falta - nn
	kc_pon_pat(ci, {"m": k, "n": nn})
	sfx("get")
	await say(T("La carpa {c}, con {n} macetas de {l} L y sus goteros.", {"c": ci + 1, "n": nn, "l": lk}))

# cambia el esquema de la carpa ci (vacía): sus plazas en S.kc.p, de las de antes a las nuevas
func kc_pon_pat(ci: int, P: Dictionary) -> void:
	var p: Array = kc().p
	var o := kc_off(ci)
	var a := kc_n(ci)
	var q: Array = p.slice(0, o)
	for j in int(P.n):
		q.append(null)
	q.append_array(p.slice(o + a))
	S.kc.p = q
	if not (S.kc.get("pat") is Array):
		S.kc.pat = []
	while S.kc.pat.size() <= ci:
		S.kc.pat.append(null)
	S.kc.pat[ci] = P
	kc()

# las macetas que pusiste tú en las carpas, de vuelta a la mochila (al venderlas o al reformar); las del kit se van con él
func kc_devuelve_macetas() -> int:
	var n := 0
	for P in kc().get("pat", []):
		if P is Dictionary:
			S.items["m_" + String(P.m)] = int(S.items.get("m_" + String(P.m), 0)) + int(P.n)
			n += int(P.n)
	S.kc.pat = []
	return n

func plants_advance(mn: int) -> void:
	super(mn)
	kc_avanza(mn)

# cada rato crecen con su carpa; el goteo las deja regadas
func kc_avanza(mn: int) -> void:
	if not kc_hay() or not (S.get("kc") is Dictionary):
		return
	kc()
	var o := 0
	for ci in int(kc_N().max):
		var f := kc_f(ci)
		for j in kc_n(ci):
			var p = S.kc.p[o + j] if o + j < S.kc.p.size() else null
			if not (p is Dictionary) or p.get("dead"):
				continue
			Cultivo.plant_step(S, p, mn / 60.0, f)
			p.water = 100.0
		o += kc_n(ci)

# ---------- fase 2: las mesas ----------
func kc_mesa_idx(x: int, y: int) -> int:
	if not kc_f2():
		return -1
	var Ms: Array = D.KAIA_CULT.f2.mesas
	for i in Ms.size():
		if int(Ms[i][1]) == y and (int(Ms[i][0]) == x or int(Ms[i][0]) + 1 == x):
			return i
	return -1

func kc_me(i: int):
	var m: Array = kc().get("m", [])
	return m[i] if i >= 0 and i < m.size() and m[i] is Dictionary else null

func kc_fase(i: int) -> int:
	var Me = kc_me(i)
	if Me == null:
		return 0
	var p := float(Me.p)
	return 1 if p < .35 else (2 if p < .65 else (3 if p < .85 else 4))

# las mesas en el mapa, como las de la nave (pinta.gd): la mesa, sus plantas y su foco
func mesa_de(o: String, x: int, y: int):
	if o == "mesaKC" and kc_hay():   # i18n-no
		var i := kc_mesa_idx(x, y)
		var y0: int = int(D.KAIA_CULT.f2.mesas[0][1])
		return {"Me": kc_me(i), "fm": kc_fase(i), "foco": String(D.KAIA_CULT.f2.foco), "techo": (y - y0) * 16}   # la segunda fila, su techo más abajo
	return super(o, x, y)

func kc_cultiva():   # quien lleva las mesas
	for w in S.plantilla:
		if w.get("rol") == "kaia":
			return w
	return null

func kc_mesa(i: int) -> void:
	var Me = kc_me(i)
	var w = kc_cultiva()
	var ops: Array = [K("Arrancar y plantar") if Me else K("Plantar")]
	if Me and float(Me.g) >= 1:
		ops.push_front(T("Llevarte lo seco · {g}", {"g": g_txt(Me.g)}))
	ops.append(K("Nada"))
	var que: String = (mesa_txt(Me) + " · " + I18n.v(D.FASE_MESA[kc_fase(i)]) + " · " + cosecha_txt(Me)) if Me else K("vacía")
	var oi: int = await ask(T("Mesa {i} · {que} · {foco}\n{cuida}", {"i": i + 1, "que": que, "foco": D.FOCO_NAVE[D.KAIA_CULT.f2.foco].n, "cuida": T("La lleva {n}.", {"n": w.n}) if w else K("Nadie la lleva: pon a alguien de tu plantilla en la sala.")}), ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op.begins_with(K("Llevarte lo seco")):
		var q: int = mini(int(floor(Me.g)), int(floor(libre_mochila())))
		if q < 1:
			await say(K("No te cabe nada más en la mochila."))
			return
		add_buds(Me.k, q, Me.t, null, 0, Me.get("cd", S.day))
		Me.g = Datos.jsround((Me.g - q) * 10) / 10.0
		sfx("get")
		update_hud()
		await say(T("Te llevas {g} de la mesa {i}.", {"g": g_txt(q), "i": i + 1}))
	elif op == K("Plantar") or op == K("Arrancar y plantar"):
		if Me and Me.get("h") != null:
			await say(K("Lo de esta mesa aún se está secando: espera a que esté seco."))
			return
		if Me and float(Me.g) >= 1:
			await say(K("Antes, llévate lo seco de esta mesa."))
			return
		var p = await elegir_planta(K("¿QUÉ PLANTAS EN LA MESA?"), false)
		if p == null:
			return
		var sid: String = p.sid
		kc().m[i] = {"k": sid + ("*" if Cultivo.clase_feno(p.f) == "estrella" else ""), "f": p.f, "thc": thc_nave(sid, p.f), "y": p.f.y, "dia": S.day, "g": 0, "t": 0, "abo": 1, "p": float(D.NAVE.clon), "dn": 0, "am": 0, "ao": 0, "n": 0}
		sfx("sel")
		await say(T("Mesa {i}: {nom}{et}. La mesa entera de clones: enraízan, crecen a 18/6 y florecen a 12/12. Se cosecha entera en unos {d} días y vuelve a empezar.", {"i": i + 1, "nom": strain(sid).n, "et": etiq(p.f), "d": dias_mesa(kc().m[i])}))

# cada mañana (desde nave_dia): lo que se seca pasa al almacén de KAIA y quien lleva la sala hace avanzar cada mesa y la corta entera
func nave_dia() -> void:
	super()
	kc_dia()

func kc_dia() -> void:
	if not kc_f2():
		return
	var al := alm_club("muelle")
	for Me in kc().m:
		if not (Me is Dictionary) or Me.get("h") == null or S.day - int(Me.h.d) < int(D.NAVE.seca):
			continue
		var g: float = float(Me.h.g)
		var cabe: float = maxf(0, float(D.MERCADO.alm.g) - alm_g("muelle"))
		var q: int = mini(int(floor(g)), int(floor(cabe)))
		if q >= 1:
			add_buds(Me.k, q, Me.h.t, al.buds, 0, int(Me.h.d))
		var resto: float = g - q
		if resto >= .05:
			Me.t = Datos.jsround((Me.t * Me.g + Me.h.t * resto) / (Me.g + resto) * 10) / 10.0 if Me.g + resto > 0 else Me.h.t
			Me.g = Datos.jsround((Me.g + resto) * 10) / 10.0
			Me.cd = int(Me.h.d)
		Me.erase("h")
	var w = kc_cultiva()
	if w == null:
		return
	for i in kc().m.size():
		var Me = kc().m[i]
		if not (Me is Dictionary):
			continue
		Me.dn = int(Me.get("dn", 0)) + 1
		Me.am = int(Me.get("am", 0)) + 1   # el abono va en el riego centralizado, cada día
		var p: float = float(Me.p) + 1.0 / float(strain(lot_sid(Me.k)).d)
		if p < 1:
			Me.p = Datos.jsround(p * 1000) / 1000.0
			continue
		var c := kc_cosecha(Me, w)
		Me.h = {"g": c.g, "t": c.t, "d": S.day}
		Me.p = float(D.NAVE.clon)
		Me.n = int(Me.get("n", 0)) + 1
		Me.dn = 0
		Me.am = 0
		Me.ao = 0

# la cosecha de una mesa de la sala: la de la nave (cosecha_mesa) con el LED doble, el riego centralizado y el abono de cada día
func kc_cosecha(Me: Dictionary, w: Dictionary) -> Dictionary:
	var F: Dictionary = D.FOCO_NAVE[D.KAIA_CULT.f2.foco]
	var dn := maxf(1, float(Me.get("dn", 1)))
	var am := float(Me.get("am", 0)) / dn
	var g: float = float(F.w) * float(F.gpw) * float(strain(lot_sid(Me.k)).y) / float(D.Y_MEDIA) * float(Me.y) * nave_g(w) / float(D.NAVE.g) \
		* (1 + float(D.ABONO.rend) * am) * (1 + Cultivo.fam(S, "g"))
	var thc: float = Me.thc * (1 + Cultivo.fam(S, "thc")) + float(F.thc) + float(D.ABONO.thc) * am
	cult_apunta(lot_sid(Me.k))
	return {"g": Datos.jsround(g * 10) / 10.0, "t": Datos.jsround(thc * 10) / 10.0}

# ---------- quien lleva la sala (rol kaia, en la plantilla) ----------
func ops_staff(w: Dictionary) -> Array:
	var o := super(w)
	if kc_f2() and w.get("rol") != "kaia" and kc_cultiva() == null:
		o.push_front(K("A la sala de KAIA"))
	return o

func staff_op(w: Dictionary, op: String) -> bool:
	if op == K("A la sala de KAIA"):
		libre(w)
		w.rol = "kaia"
		sfx("sel")
		await say(T("{n}: «Mañana empiezo en la sala de cultivo de KAIA: las seis mesas, el riego y los cortes. {e} al día».", {"n": w.n, "e": Datos.eur(D.PLANTILLA.sueldo.kaia)}))
		return true
	return await super(w, op)

func rol_txt(w: Dictionary) -> String:
	if w.get("rol") == "kaia":
		return T("sala de KAIA")
	return super(w)

func rol_desc(w: Dictionary) -> String:
	if w.get("rol") == "kaia":
		return T("Lleva las mesas de la sala de cultivo de KAIA por {e} al día: con su cuidado, la cosecha da un {p} %.", {"e": Datos.eur(D.PLANTILLA.sueldo.kaia), "p": int(Datos.jsround(100.0 * nave_g(w) / float(D.NAVE.g)))})
	return super(w)

# quien lleva la sala, de pie entre las mesas
func ciudad_npcs(mapa: String) -> Array:
	var l := super(mapa)
	if kc_f2() and mapa == D.KAIA_CULT.mapa:
		var w = kc_cultiva()
		if w != null:
			var q: Array = D.KAIA_CULT.f2.npc
			l.append({"id": "kcw", "map": mapa, "x": int(q[0]), "y": int(q[1]), "lookObj": look_genero(D.LOOKS.navero1, String(w.n), 0, D.GENERO.naveH, D.GENERO.naveM), "dir": "up", "wander": 0, "nombre": w.n})
	return l

func hilo_talk(id: String) -> bool:
	if id == "kcw" and kc_hay():
		var w = kc_cultiva()
		if w != null:
			var vivas := 0
			for Me in kc().m:
				if Me is Dictionary:
					vivas += 1
			await say(T("«Las {n} mesas que tienen plantas van bien: riego, poda y el corte cuando toca. Lo seco, al almacén del club».", {"n": vivas}) if vivas else K("«Las mesas, vacías. Planta en ellas y me encargo del resto»."), w.n.to_upper())
			return true
	return await super(id)
