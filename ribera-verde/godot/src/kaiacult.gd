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
# Datos de tools/kaia_cult.py (KAIA_CULT, MAPS["cult-muelle"]). Cadena: … → hilo → bancotia → kaiacult → salafria → acto2 → caza → copaot → acto3 → retencion → juego.
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
	if int(S.kc.get("v", 0)) < 2:   # la de un solo nivel (vender al subir): sus carpas, en los sitios de su nivel; las de antes, sin comprar
		var NV: Array = D.KAIA_CULT.niv
		var nv := clampi(int(S.kc.get("niv", 0)), 0, NV.size() - 1)
		var b := kc_base(nv)
		var ks := []
		for c in kc_ns():
			ks.append(-1)
		var vk: Array = S.kc.get("kits", [])
		for j in mini(vk.size(), int(NV[nv].max)):
			ks[b + j] = int(vk[j])
		for cl in ["pat", "cc"]:   # i18n-no
			if S.kc.get(cl) is Array:
				var pre := []
				for c in b:
					pre.append(null if cl == "pat" else {"foco": String(D.KAIA_CULT.foco), "filtro150": true, "goteo": true})
				S.kc[cl] = pre + S.kc[cl]
		S.kc.kits = ks
		var pp := []
		for c in b:
			for j in kc_n(c):
				pp.append(null)
		S.kc.p = pp + S.kc.get("p", [])
		S.kc.v = 2
	while S.kc.kits.size() < kc_ns():
		S.kc.kits.append(-1)
	var n: int = kc_off(kc_ns())
	while S.kc.p.size() < n:
		S.kc.p.append(null)
	return S.kc

# todas las carpas que caben, por niveles (lo pidió el usuario: «los anteriores serían ir completando con las diferentes medidas la
# sala, con espacio para pasar entre ellas»): [[nivel, i]…], las cuatro de 2 × 2, las dos de 4 × 2 y la de 4 × 4, que conviven
func kc_slots() -> Array:
	var l := []
	for N in D.KAIA_CULT.niv:
		for i in int(N.max):
			l.append([N, i])
	return l

func kc_ns() -> int:
	return kc_slots().size()

func kc_Nc(ci: int) -> Dictionary:   # el nivel (el tamaño) de la carpa ci
	var l := kc_slots()
	return l[clampi(ci, 0, l.size() - 1)][0]

func kc_iN(ci: int) -> int:   # su número dentro de su tamaño
	var l := kc_slots()
	return int(l[clampi(ci, 0, l.size() - 1)][1])

func kc_base(nv: int) -> int:   # la primera carpa del nivel nv
	var o := 0
	for j in mini(nv, D.KAIA_CULT.niv.size()):
		o += int(D.KAIA_CULT.niv[j].max)
	return o

func kc_tiene(ci: int) -> bool:   # la carpa ci, montada
	var k: Array = kc().kits
	return ci >= 0 and ci < k.size() and int(k[ci]) >= 0 and int(k[ci]) <= int(S.day)

func kc_pedida(ci: int) -> bool:
	var k: Array = kc().kits
	return ci >= 0 and ci < k.size() and int(k[ci]) > int(S.day)

func kc_N() -> Dictionary:   # el nivel de las carpas
	return D.KAIA_CULT.niv[clampi(int(S.kc.get("niv", 0)), 0, D.KAIA_CULT.niv.size() - 1)]

func kc_pat(ci: int) -> Dictionary:   # el esquema de la carpa ci: {m: maceta, n: plazas}
	var l: Array = S.kc.get("pat", []) if S.get("kc") is Dictionary else []
	if ci >= 0 and ci < l.size() and l[ci] is Dictionary:
		return l[ci]
	return {"m": D.KAIA_CULT.maceta, "n": int(kc_Nc(ci).plazas), "kit": true}   # las del kit: no son tuyas, no van a la mochila

func kc_n(ci: int) -> int:
	return int(kc_pat(ci).n)

func kc_off(ci: int) -> int:   # dónde empiezan en S.kc.p las plazas de la carpa ci
	var o := 0
	for c in ci:
		o += kc_n(c)
	return o

func kc_ci(i: int) -> int:   # la carpa de la plaza i
	var o := 0
	for c in kc_ns():
		o += kc_n(c)
		if i < o:
			return c
	return kc_ns() - 1

# los esquemas de este nivel que se pueden poner: [[maceta, n]…]
func kc_patrones(ci: int) -> Array:
	var l := []
	for q in D.get("KC_PATRON", {}).get(String(kc_Nc(ci).k), []):   # i18n-no
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
	for ci in kc_ns():
		if kc_tiene(ci):
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
	var N: Dictionary = kc_Nc(ci)
	if P == null:
		P = kc_pat(ci)
	var cm: Array = N.cm
	var F: Dictionary = D.FOCOS[KC.foco]
	var M: Dictionary = D.MACETAS.get(P.m, D.MACETAS[KC.maceta])
	var np := float(P.n)
	var w: float = float(F.w) * float(N.nf)
	var dens := minf(1, w / (float(cm[0]) * float(cm[1]) / 1e4 * float(D.W_M2)))
	var o := {"g": w * float(F.gpw) / np * float(M.rend) * float(N.get("efi", 1.0)), "cap": float(M.cap), "crec": float(F.crec) * (.85 + .15 * dens) * float(M.crec) * Cultivo.f_clima(KC.clima),
		"thc": float(F.thc) * dens, "agua": float(F.agua) * float(M.agua), "plaga": float(M.plaga), "dens": dens, "hr": float(KC.clima.hr), "moho": 1.0, "ciclo": Cultivo.ciclo_de(kc_cc(ci))}
	if kc_cc(ci).get("vent"):   # el ventilador, como en casa (Cultivo.factores)
		o.crec *= float(D.VENT.crec)
		o.plaga *= float(D.VENT.plaga)
		o.moho = float(D.VENT.moho)
	return o

func kc_pos(ci: int) -> Array:
	return pos_pieza(D.KAIA_CULT.mapa, "kc%s%d" % [kc_Nc(ci).k, kc_iN(ci)])

func kc_hu(i: int) -> Dictionary:
	var ci := kc_ci(i)
	var t: Array = kc_Nc(ci).tam
	var p := kc_pos(ci)
	return {"l": kc().p, "v": [int(p[0]) * 16 + int(t[0]) * 8, (int(p[1]) + int(t[1]) - 1) * 16], "f": kc_f(ci)}

func kc_carpa_en(x: int, y: int) -> int:   # la carpa (N.tam casillas) con la casilla (x, y), o -1
	if kc_f2() or kc_obra():
		return -1
	for ci in kc_ns():
		if not kc_tiene(ci):
			continue
		var t: Array = kc_Nc(ci).tam
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
		return kc_hay() and not kc_f2() and not kc_obra() and kc_tiene(kc_de_pieza(str(P_.k)))
	return super(P_)

func kc_de_pieza(k: String) -> int:   # kc<nivel><i> → la carpa
	var NV: Array = D.KAIA_CULT.niv
	for nv in NV.size():
		if k.substr(2, 1) == String(NV[nv].k):
			return kc_base(nv) + int(k.substr(3))
	return -1

# cada carpa con las plantas que tiene (kcs-<n>, kcm-<n>, kcl-<n>, de kaia_carpa.py)
func sprite_local(o: String) -> String:
	if kc_hay():
		var NV: Array = D.KAIA_CULT.niv
		for nv in NV.size():
			var N: Dictionary = NV[nv]
			if o.begins_with(N.obj) and o.substr(String(N.obj).length()).is_valid_int():
				return "%s-%d" % [N.spr, kc_dibujo(kc_base(nv) + int(o.substr(String(N.obj).length())))]   # i18n-no
	return super(o)

# las plantas que se dibujan en la carpa: el sprite tiene una por plaza del kit (N.plazas); con otro esquema, a esa escala
func kc_dibujo(ci: int) -> int:
	var q := kc_plantadas(ci)
	var np: int = int(kc_Nc(ci).plazas)
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
	# el último nivel (lo pidió el usuario: «que la carpa ocupe finalmente todo el suelo preparado para la carpa»): la carpa de sala,
	# que se entra por su puerta; dentro (cult-sala), las 8 mesas de flujo y reflujo con su riego y su drenaje
	var C: Dictionary = D.KAIA_CULT.f2.carpa
	var x0: int = int(C.def[0])
	var y0: int = int(C.def[1])
	for dy in int(C.tam[1]):
		for dx in int(C.tam[0]):
			m.o[y0 + dy][x0 + dx] = "carpaG2"   # i18n-no
	m.o[y0 + int(C.tam[1]) - 1][x0] = String(C.obj)

func kc_en_sala(x: int, y: int) -> bool:   # la casilla (x, y) de cult-muelle es de la carpa de sala
	if not kc_f2():
		return false
	var C: Dictionary = D.KAIA_CULT.f2.carpa
	return x >= int(C.def[0]) and x < int(C.def[0]) + int(C.tam[0]) and y >= int(C.def[1]) and y < int(C.def[1]) + int(C.tam[1])

# después de mover una carpa con ORDENAR (setas.gd mover_pieza), la sala con cada una donde se dejó
func rehace_orden(mapa: String) -> void:
	if kc_hay() and mapa == D.KAIA_CULT.mapa:
		kc_monta()
		return
	super(mapa)

func bt_obj(x: int, y: int, o) -> bool:
	if kc_hay() and (S.map == D.KAIA_CULT.mapa or S.map == D.KAIA_CULT.f2.sala):
		return await kc_obj(x, y, o)
	return await super(x, y, o)

func kc_obj(x: int, y: int, o) -> bool:
	if S.map == D.KAIA_CULT.mapa and kc_en_sala(x, y):   # la carpa de sala: se entra por su cremallera
		var F2: Dictionary = D.KAIA_CULT.f2
		await warp({"to": F2.sala, "x": int(F2.entra[0]), "y": int(F2.entra[1]), "dir": "up"})   # i18n-no
		return true
	if o == "drenKS":   # i18n-no
		await say(K("El depósito de recogida: lo que sobra de cada mesa baja por su tubería de drenaje y se filtra antes de volver al tanque."))
		return true
	var ci := kc_carpa_en(x, y)
	if ci >= 0:
		await kc_carpa(ci)
		return true
	var mi := kc_mesa_idx(x, y)
	if mi >= 0:
		if Atlas.ok and ArteM.hay("carpa-c-pared") and EscK.pl("o-mesaF") != null and not oraculo:   # las pruebas sin pantalla, el menú  # i18n-no
			await vista_mesas(mi)
		else:
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
	if not kc_obra() and not await vista_clima("kaia"):
		return
	while true:
		var ops := []
		var compra := {}
		var txt := ""
		if kc_obra():
			await say(T("La sala, en obras: desagües, el cuadro trifásico y el clima industrial. Las mesas estarán montadas el {f}.", {"f": Datos.fd(int(S.kc.f2), S.day)}))
			return
		if kc_f2():
			var w = kc_cultiva()
			txt = T("El cuadro de la sala: seis mesas con su LED doble, el riego centralizado y el clima. {q}", {"q": T("Las lleva {n}.", {"n": w.n}) if w != null else K("Nadie las lleva: pon a alguien de tu plantilla en la sala desde el móvil.")})
			ops.append(K("Salir"))
		else:
			var NV: Array = D.KAIA_CULT.niv
			var nv0: int = int(kc().get("niv", 0))
			var tl := []
			for nv in nv0 + 1:
				var N: Dictionary = NV[nv]
				var nk := kc_de_nivel(nv)
				tl.append(T("{k} de {m} de {n}", {"k": nk, "m": int(N.max), "n": I18n.v(N.n)}))
				if nk < int(N.max):
					var op := T("Comprar: {n} · {e}", {"n": I18n.v(N.n), "e": Datos.eur(N.kit.p)})
					ops.append(op)
					compra[op] = nv
			txt = T("El cuadro de la sala: el temporizador de los LED, el goteo y el clima. Todo en automático: muchas horas de luz mientras crecen y menos en cuanto toca florecer. Carpas: {l}.", {"l": ", ".join(PackedStringArray(tl))})
			if kc_kits() >= 1:
				ops.append(K("Ordenar la sala"))
			var sig = kc_sig()
			if sig != null:
				ops.append(T("Pasar a la {n} · {e}", {"n": I18n.v(sig.n), "e": Datos.eur(sig.kit.p)}))
			else:
				ops.append(T("Montar la carpa de sala · {e}", {"e": Datos.eur(KC.f2.p)}))
			ops.append(K("Salir"))
		var c: int = await ask(txt, ops)
		var op: String = ops[c] if c >= 0 and c < ops.size() else ""
		if compra.has(op):
			await kc_compra_kit(int(compra[op]))
		elif op.begins_with(K("Pasar a la")):
			await kc_sube()
		elif op == K("Ordenar la sala"):
			await ordenar(S.map)
			return
		elif op.begins_with(K("Montar la carpa de sala")):
			await kc_reforma()
		else:
			return

func kc_kit_txt(N: Dictionary) -> String:
	var l := []
	for x in N.kit.l:
		l.append(T("{n}: {e}", {"n": I18n.v(x[0]), "e": Datos.eur(x[1])}))
	return "; ".join(PackedStringArray(l))

func kc_de_nivel(nv: int) -> int:   # las carpas de ese tamaño, montadas o pedidas
	var n := 0
	for j in int(D.KAIA_CULT.niv[nv].max):
		if int(kc().kits[kc_base(nv) + j]) >= 0:
			n += 1
	return n

func kc_compra_kit(nv: int) -> void:
	var N: Dictionary = D.KAIA_CULT.niv[nv]
	var ci := -1
	for j in int(N.max):
		if int(kc().kits[kc_base(nv) + j]) < 0:
			ci = kc_base(nv) + j
			break
	if ci < 0:
		return
	if await ask(T("El kit de la {c}, a precio de tienda: {l}. En total, {e}, con la tarjeta; llega mañana y lo montan aquí.", {"c": I18n.v(N.n), "l": kc_kit_txt(N), "e": Datos.eur(N.kit.p)}), [K("Comprarlo"), K("Ahora no")]) != 0:
		return
	if not await tarjeta(float(N.kit.p), K("Kit de carpa (KAIA)")):
		return
	kc().kits[ci] = int(S.day) + 1
	sfx("get")
	await say(T("Pedido: la carpa {n} llega mañana, con sus LED, el extractor y el goteo. {p} plazas más.", {"n": ci + 1, "p": int(N.plazas)}))

func kc_sig():   # el nivel siguiente, o null en el último (después, la reforma)
	var i: int = int(kc().get("niv", 0)) + 1
	return D.KAIA_CULT.niv[i] if i < D.KAIA_CULT.niv.size() else null

# pasar al nivel siguiente (lo pidió el usuario: las carpas conviven, «ir completando con las diferentes medidas la sala»): las de
# ahora se quedan donde están y la primera del tamaño nuevo, pagada y mañana aquí
func kc_sube() -> void:
	var N2 = kc_sig()
	if N2 == null:
		return
	var nv: int = int(kc().get("niv", 0)) + 1
	var t := T("La {c}, con su kit a precio de tienda: {l}. En total, {e}, con la tarjeta; llega mañana. Las carpas que ya tienes se quedan: la sala se va llenando con las de cada tamaño, con su pasillo entre ellas.", {"c": I18n.v(N2.n), "l": kc_kit_txt(N2), "e": Datos.eur(N2.kit.p)})
	if await ask(t, [K("Comprarla"), K("Ahora no")]) != 0:
		return
	if not await tarjeta(float(N2.kit.p), K("Kit de carpa (KAIA)")):
		return
	kc().niv = nv
	kc().kits[kc_base(nv)] = int(S.day) + 1
	kc_monta()
	sfx("get")
	await say(T("Pedido: la primera {c} llega mañana, con sus LED, el extractor y el goteo; caben {m}.", {"c": I18n.v(N2.n), "m": int(N2.max)}))

func kc_reforma() -> void:
	var KC: Dictionary = D.KAIA_CULT
	var F2: Dictionary = KC.f2
	var l := []
	for x in F2.l:
		l.append(T("{n}: {e}", {"n": I18n.v(x[0]), "e": Datos.eur(x[1])}))
	var vende := 0
	var hay := 0
	for ci in kc_ns():
		if int(kc().kits[ci]) >= 0:
			vende += roundi(float(kc_Nc(ci).kit.p) * float(F2.venta))
			hay += 1
	var t := T("La sala entera como la nave: {l}. En total, {e}, con la tarjeta; la obra dura {d} días. Después, las mesas las lleva alguien de tu plantilla.", {"l": "; ".join(PackedStringArray(l)), "e": Datos.eur(F2.p), "d": int(F2.dias)})
	if hay:
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
	for ci in kc_ns():
		kc().kits[ci] = -1
	kc().p = []
	kc().f2 = int(S.day) + int(F2.dias)
	kc().m = []
	for q in F2.mesas:
		kc().m.append(null)
	if S.get("coloca") is Dictionary:
		S.coloca.erase(KC.mapa)
	kc_monta()
	sfx("get")
	await say(T("Empieza la obra. El {f}, la sala con sus mesas.", {"f": Datos.fd(int(S.kc.f2), S.day)}))

# las plazas de una carpa: como las de casa (lo pidió el usuario: «te dije que como las de casa… tiene que ser visual»), A abre la
# carpa por dentro (abrir_carpa, la vista C de granja.gd) con sus plantas, sus LED repartidos a lo ancho, el temporizador y su equipo;
# la de 400 × 400, por mitades (delante y al fondo). kc_lista, la de antes, sin el atlas
func kc_carpa(ci: int) -> void:
	if not kc_lic():
		await say(K("Sin la licencia de cultivo, las carpas se quedan vacías."))
		return
	if Atlas.ok and ArteM.hay("carpa-c-pared") and not oraculo:   # las pruebas sin pantalla, la lista (la vista: tests/kaia_vista.gd)
		await kc_vista(ci)
		return
	await kc_lista(ci)

func kc_lista(ci: int) -> void:
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
	for q in kc_patrones(ci):
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
	var l := kc_patrones(ci)
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

# ---------- la carpa de KAIA por dentro, con la vista de las de casa ----------
# Mientras está abierta (KCV), S.carpas, S.pots y S.macetas son los de esa carpa (o de su mitad): una carpa de casa con el tipo
# kc<nivel><plazas>[-mitad] (kc_def, en D.CARPAS solo mientras se ve), su equipo de S.kc.cc[ci] y sus plantas, las de S.kc.p (los
# mismos diccionarios). Lo de la planta va por pot_action con su hu (kc_hu); el tiempo y el guardado, con lo de casa en su sitio
# (kc_vista_off/on alrededor de advance_time y de save)
var KCV = null

func kc_cc(ci: int) -> Dictionary:   # el equipo de la carpa ci: el kit (sus LED, el extractor con su filtro y el goteo) y lo que le pongas
	if not (kc().get("cc") is Array):
		S.kc.cc = []
	while S.kc.cc.size() <= ci:
		S.kc.cc.append({"foco": String(D.KAIA_CULT.foco), "filtro150": true, "goteo": true})
	return S.kc.cc[ci]

func kc_mitades(ci: int) -> int:   # la de 400 × 400 se ve en dos mitades de 400 × 200
	var cm: Array = kc_Nc(ci).cm
	return 2 if float(cm[1]) > 200 else 1

func kc_def(ci: int) -> Dictionary:
	var N: Dictionary = kc_Nc(ci)
	var mi := kc_mitades(ci)
	var W: float = float(N.cm[0])
	var Dp: float = float(N.cm[1]) / mi
	var nv: int = kc_n(ci) / mi
	var cols := maxi(1, roundi(sqrt(nv * W / Dp)))
	return {"n": N.n, "w": 2, "cm": [W, float(N.cm[2]), Dp], "cols": cols, "filas": ceili(float(nv) / cols), "plazas": nv, "wmax": int(D.FOCOS[D.KAIA_CULT.foco].w) * int(N.nf), "lmax": int(D.MACETAS.get(kc_pat(ci).m, {"l": 25}).l), "kc": true}

func kc_vista_on() -> void:
	var ci: int = KCV.ci
	var mi := kc_mitades(ci)
	var t := "kc%s%d-%d" % [kc_Nc(ci).k, kc_n(ci), KCV.h]   # i18n-no
	D.CARPAS[t] = kc_def(ci)
	var c := kc_cc(ci)
	c.t = t
	c.nf = int(kc_Nc(ci).nf) / mi
	var nv: int = kc_n(ci) / mi
	var a: int = kc_off(ci) + int(KCV.h) * nv
	if KCV.get("bak") == null:
		KCV.bak = {"carpas": S.carpas, "pots": S.pots, "macetas": S.macetas}
	S.carpas = [c]
	S.pots = kc().p.slice(a, a + nv)
	var ms := []
	for j in nv:
		ms.append(String(kc_pat(ci).m))
	S.macetas = ms
	KCV.a = a
	KCV.t = t

func kc_vista_off() -> void:
	if KCV == null or KCV.get("bak") == null:
		return
	S.carpas = KCV.bak.carpas
	S.pots = KCV.bak.pots
	S.macetas = KCV.bak.macetas
	KCV.bak = null
	var c := kc_cc(int(KCV.ci))
	c.erase("t")
	c.erase("nf")
	D.CARPAS.erase(KCV.t)

func kc_vista(ci: int, h := 0) -> void:
	KCV = {"ci": ci, "h": clampi(h, 0, kc_mitades(ci) - 1)}
	kc_vista_on()
	await abrir_carpa(0)
	var sig = KCV.get("sig")
	kc_vista_off()
	KCV = null
	if sig != null:   # de una mitad a la otra
		await kc_vista(ci, int(sig))

func advance_time(mn: int) -> void:
	if KCV != null and KCV.get("bak") != null:
		kc_vista_off()
		super(mn)
		if KCV != null:
			kc_vista_on()
		return
	super(mn)

func kc_guarda_fuera() -> bool:   # juego.gd save: lo de casa en su sitio mientras se escribe la partida
	if KCV != null and KCV.get("bak") != null:
		kc_vista_off()
		return true
	return false

func kc_guarda_dentro(b: bool) -> void:
	if b and KCV != null:
		kc_vista_on()

# con una carpa de KAIA abierta, S.carpas y S.pots son los de esa carpa: ni misiones ni logros hasta salir (si no, se darían por
# lo de KAIA como si fuera de casa)
func revisa_misiones() -> void:
	if KCV != null and KCV.get("bak") != null:
		return
	super()

func revisa_logros() -> void:
	if KCV != null and KCV.get("bak") != null:
		return
	super()

func _vc_accion() -> void:
	if KCV == null:
		await super()
		return
	if VC.sel == Vista.SEL_TEMP:
		await temporizador(0)
	elif VC.sel < 0:
		await kc_equipo()
	else:
		var gi: int = int(KCV.a) + int(VC.sel)
		var hu := kc_hu(gi)
		hu.v = pos_plaza(VC.sel)
		await pot_action(gi, hu)
		if KCV != null and KCV.get("bak") != null:
			kc_vista_on()
	if VC:
		VC.ocupado = false
	vc_ficha()

# el equipo de la carpa de KAIA (A en sus LED): lo que se le puede poner como en casa, el esquema de macetas y, en la de 400 × 400, la
# otra mitad
# en KAIA, el kit trae su extractor con filtro a la medida, sus LED y su goteo: del equipo de casa solo se pone lo que cuenta en sus
# carpas (kc_f: el ventilador); nada de cambiar el extractor del kit (que no se compró) por uno de la mochila
const KC_EXTRAS := ["vent"]

func vc_foco(c: Dictionary) -> Array:
	if KCV == null:
		return super(c)
	var N: Dictionary = kc_Nc(int(KCV.ci))
	var F: Dictionary = D.FOCOS[D.KAIA_CULT.foco]
	return [T("{nf} × {f}", {"nf": int(N.nf), "f": I18n.v(String(F.n))}), T("{w} W de LED", {"w": n(float(F.w) * int(N.nf))}) if plantas_vivas(VC.ci) else T("Apagado")]

func kc_equipo() -> void:
	var ci: int = KCV.ci
	var N: Dictionary = kc_Nc(ci)
	var ex := extras_libres(0).filter(func(k): return k in KC_EXTRAS)
	var ops := []
	for k in ex:
		ops.append(T("Poner {x}", {"x": I18n.v(String(D.EXTRAS[k].c)).to_lower()}))
	ops.append(K("Esquema de la carpa"))
	if kc_mitades(ci) > 1:
		ops.append(K("Ver la mitad del fondo") if int(KCV.h) == 0 else K("Ver la mitad de delante"))
	ops.append(K("Salir"))
	var lst: Array = [I18n.v(String(D.FOCOS[D.KAIA_CULT.foco].n))]
	for k in D.EXTRAS:
		if kc_cc(ci).get(k):
			lst.append(I18n.v(String(D.EXTRAS[k].c)).to_lower())
	var j: int = await ask(T("{c} · {p} plantas · {nf} × {f}\nLleva: {l}", {"c": N.n, "p": kc_n(ci), "nf": int(N.nf), "f": I18n.v(String(D.FOCOS[D.KAIA_CULT.foco].n)), "l": ", ".join(lst.slice(1)) if lst.size() > 1 else K("nada más")}), ops)
	if j < 0 or j >= ops.size():
		return
	if j < ex.size():
		var x: String = ex[j]
		var vk := poner_extra(0, x)
		await say(T("Pones el {x} en la carpa.", {"x": I18n.v(String(D.EXTRAS[x].n)).to_lower()}) + "\n" + I18n.v(String(D.EXTRAS[x].d)) + (T("\nEl {k} vuelve a la mochila.", {"k": I18n.v(String(D.EXTRAS[vk].c)).to_lower()}) if vk != "" else ""))
		return
	var op: String = ops[j]
	if op == K("Esquema de la carpa"):
		if not kc_vacia(ci):
			await say(K("El esquema se cambia con la carpa vacía: primero, cosecha o quita lo que lleva."))
			return
		kc_vista_off()
		await kc_esquema(ci)
		KCV.h = 0
		kc_vista_on()
		VC.sel = -1
	elif op == K("Ver la mitad del fondo") or op == K("Ver la mitad de delante"):
		KCV.sig = 1 - int(KCV.h)
		J_salir_carpa()

func kc_vacia(ci: int) -> bool:
	return kc_plantadas(ci) == 0

func J_salir_carpa() -> void:   # cierra la vista (como B) para abrir la otra mitad
	if VC and handlers.size():
		VC.ocupado = false
		handlers[-1].call("B")

# cada rato crecen con su carpa; el goteo las deja regadas
func kc_avanza(mn: int) -> void:
	if not kc_hay() or not (S.get("kc") is Dictionary):
		return
	kc()
	var o := 0
	for ci in kc_ns():
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
	if not kc_f2() or S.map != D.KAIA_CULT.f2.sala:
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
	if o == "mesaKP" and kc_hay():   # i18n-no
		var i := kc_mesa_idx(x, y)
		var y0: int = int(D.KAIA_CULT.f2.mesas[0][1])
		return {"Me": kc_me(i), "fm": kc_fase(i), "foco": String(D.KAIA_CULT.f2.foco), "techo": (y - y0) * 16}   # la segunda fila, su techo más abajo
	return super(o, x, y)

# ---------- cada mesa por dentro (lo pidió el usuario: «el visor de cada mesa (vista C): de fondo la pared de la carpa y delante la
# mesa con sus plantas») ----------
# La pared plateada de la carpa (carpa-c-pared), el LED doble de PixelLab (o-ledK) colgado de sus cuerdas a su temporizador (18/6
# mientras crecen, 12/12 en flor), la mesa de flujo y reflujo de frente (o-mesaF) con su fila de plantas en la fase de la mesa, con
# el tono de hoja y el cogollo de su variedad, y abajo a la derecha las ocho mesas de la sala. ◀ ▶ cambian de mesa (▲ ▼, de fila);
# A, lo de la mesa (kc_mesa); B cierra. MESA_KV = {i: la mesa}
const EscK = preload("res://src/escena_extr.gd")
const MESAK_N := 6   # plantas a la vista en la mesa

func vista_mesas(i0: int) -> void:
	var i := i0
	while kc_f2():
		var r = await elegir_mesak(i)
		if r == null:
			return
		i = int(r)
		await kc_mesa(i)

func luz_mesak(i: int) -> bool:   # el LED doble, desde las 6 de la mañana: 18 h mientras crece y 12 en flor, con plantas en la mesa
	var Me = kc_me(i)
	if Me == null or Me.get("h") != null:
		return false
	return posmod(int(S.min) - 6 * 60, 24 * 60) < (18 if float(Me.p) < FLOR_MESA else 12) * 60

func desc_mesak(V: Dictionary) -> String:
	var i: int = int(V.i)
	var Me = kc_me(i)
	var que: String = K("vacía")
	if Me and Me.get("h") != null:
		que = K("cortada, secándose")
	elif Me:
		que = mesa_txt(Me) + " · " + I18n.v(D.FASE_MESA[kc_fase(i)]) + " · " + cosecha_txt(Me)
	var lz: String = (K("LED doble encendido, a 18/6.") if float(Me.p) < FLOR_MESA else K("LED doble encendido, a 12/12.")) if luz_mesak(i) else (K("LED doble apagado: sus horas de noche.") if Me else K("LED doble apagado."))
	return T("Mesa {i} · {que}. {l}\nA: la mesa · B: cerrar.", {"i": i + 1, "que": que, "l": lz})

func elegir_mesak(i0 := 0):
	if gancho_mesak.is_valid():
		return gancho_mesak.call(i0)
	var nm: int = D.KAIA_CULT.f2.mesas.size()
	MESA_KV = {"i": clampi(i0, 0, nm - 1)}
	if not oraculo:
		hud.hide()   # la vista entera, sin el recuadro del HUD encima
	_dlg_fijo(desc_mesak(MESA_KV), K("LAS MESAS"))
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(null)
			return
		if b == "A":
			pop()
			pr.res(MESA_KV.i)
			return
		var fila: int = nm >> 1
		var d: int = {"left": -1, "right": 1, "up": -fila, "down": fila}.get(b, 0)
		var n2: int = int(MESA_KV.i) + d
		if d != 0 and n2 >= 0 and n2 < nm:
			MESA_KV.i = n2
			sfx("sel")
			_dlg_fijo(desc_mesak(MESA_KV), K("LAS MESAS")))
	var e = await Motor.espera(pr)
	MESA_KV = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
		update_hud()
	return e

var _mk_cache := {}
func _mesak_planta(Me: Dictionary, fm: int, k: int):   # la planta k de la mesa en su fase, con los colores de su variedad
	var p := {"sid": lot_sid(Me.k), "f": Me.get("f")}
	var po := Datos.porte_planta(S, p)
	var n: String = "planta-c-h1-18" if fm == 1 else ("planta-c-%s2-32" % po if fm == 2 else "planta-c-%s-32" % po)
	if not ArteM.hay(n):
		return null
	var hp: int = [0, 16, 26, 32, 34][fm] - (k % 2) * 2   # i18n-no
	var sc := Datos.color_cog(S, p)
	var hj := Datos.hoja_planta(S, p)
	var ck := "%s|%d|%s|%s" % [n, hp, sc, hj]
	if not _mk_cache.has(ck):
		if _mk_cache.size() > 64:
			_mk_cache.clear()
		var mapa := {ArteM.rampa[0]: Datos.shade(sc, 50), ArteM.rampa[1]: sc, ArteM.rampa[2]: Datos.shade(sc, -60)} if ArteM.rampa.size() >= 3 else {}
		mapa.merge(Datos.vc_tonos(hj), true)
		_mk_cache[ck] = ArteM.recolor(ArteM.aplasta(ArteM.altura(n, hp)[1], hp), mapa)
	return _mk_cache[ck]

func rects_mesak(V: Dictionary) -> Array:
	var o := []
	var i: int = int(V.i)
	var x0: int = (SW - 240) >> 1
	var H: int = MAD_H
	var clip := Rect2i(x0, 0, 240, H)
	var on := luz_mesak(i)
	o.append([0, 0, SW, SH, "#0e0e12"])
	if ArteM.hay("carpa-c-pared"):
		o.append(["@", ArteM.foto("carpa-c-pared"), x0, -MAD_PARED, clip])
	var led = EscK.pl("o-ledK")   # i18n-no
	for fx in [x0 + 32, x0 + 128]:   # el LED doble, colgado del techo de la carpa
		if led != null:
			o.append([fx + 6, 0, 1, 11, ArteM.VC_CUERDA])
			o.append([fx + 73, 0, 1, 11, ArteM.VC_CUERDA])
			o.append(["@", led, fx, 2, clip])
		if on:
			o.append([fx + 4, 18, 72, H - 18, "rgba(255,244,214,0.08)"])
	var Me = kc_me(i)
	o.append_array(VistaM.temporizador(x0 + 8, 20, "veg" if Me == null or float(Me.p) < FLOR_MESA else "flor", on))
	var mf = EscK.pl("o-mesaF")   # i18n-no
	var my: int = H - 2 - mf.get_height()
	var mx: int = x0 + ((240 - mf.get_width()) >> 1)
	o.append(["@", mf, mx, my, clip])
	if Me and Me.get("h") == null:
		var fm := kc_fase(i)
		for k in MESAK_N:
			var im = _mesak_planta(Me, fm, k)
			if im == null:
				continue
			var cx: int = mx + 28 + int(round(k * (mf.get_width() - 56) / float(MESAK_N - 1)))
			o.append(["@", im, cx - (im.get_width() >> 1), my + 21 - im.get_height(), clip])
		o.append(["@", mf, mx, my, Rect2i(x0, my + 17, 240, H - my - 17)])   # el canto de la bandeja, delante de los tiestos
	if not on:
		o.append([x0, 0, 240, H, "rgba(4,4,10,0.72)"])
	var Ms: Array = D.KAIA_CULT.f2.mesas
	var fila: int = Ms.size() >> 1
	for j in Ms.size():   # las ocho mesas de la sala, en su sitio: la elegida en amarillo
		var qx: int = x0 + 240 - 6 - (fila - j % fila) * 7
		var qy: int = 4 + (j / fila) * 5
		o.append([qx, qy, 6, 3, "#f8d040" if j == i else ("#58c060" if kc_me(j) else "#5a5e66")])
	return o

# las tuberías de drenaje de la sala (lo pidió el usuario: «con tuberías de drenaje a un depósito de recogida»): de la caja de cada
# mesa baja su tubo por el suelo, por debajo de la mesa de delante, hasta el colector de la última fila, que va al depósito (drenKS);
# rectángulos [x, y, w, h, color] en píxeles del mapa, que pinta.gd pinta detrás de las mesas
const DREN_COL := ["#3e434c", "#9aa0a8", "#c4c8ce"]   # el canto, el PVC y su brillo
func tubos_dren() -> Array:
	var l := []
	if not kc_f2() or S.map != D.KAIA_CULT.f2.sala:
		return l
	var F2: Dictionary = D.KAIA_CULT.f2
	var dr: Array = [-1, -1]
	for q in F2.o:
		if q[2] == "drenKS":   # i18n-no
			dr = [int(q[0]), int(q[1])]
	var yc: int = (int(dr[1]) - 1) * 16 + 11   # el colector, en la fila de encima del depósito
	var x0 := 1 << 20
	for q in F2.mesas:
		var x: int = int(q[0]) * 16 + 15
		x0 = mini(x0, x)
		_tubo_v(l, x, int(q[1]) * 16 + 12, yc)
	var xd: int = int(dr[0]) * 16 + 7
	_tubo_h(l, x0, xd + 2, yc)
	_tubo_v(l, xd, yc, int(dr[1]) * 16 + 4)
	return l

func _tubo_v(l: Array, x: int, y0: int, y1: int) -> void:
	l.append([x - 1, y0, 1, y1 - y0 + 1, DREN_COL[0]])
	l.append([x, y0, 2, y1 - y0 + 1, DREN_COL[1]])
	l.append([x, y0, 1, y1 - y0 + 1, DREN_COL[2]])
	l.append([x + 2, y0, 1, y1 - y0 + 1, DREN_COL[0]])

func _tubo_h(l: Array, x0: int, x1: int, y: int) -> void:
	l.append([x0 - 1, y - 1, x1 - x0 + 3, 1, DREN_COL[0]])
	l.append([x0, y, x1 - x0 + 1, 2, DREN_COL[1]])
	l.append([x0, y, x1 - x0 + 1, 1, DREN_COL[2]])
	l.append([x0 - 1, y + 2, x1 - x0 + 3, 1, DREN_COL[0]])

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
		add_buds(Me.k, q, Me.t, null, 0, Me.get("cd", S.day), 0, Cultivo.ra_ar(Me.get("f")))
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
			add_buds(Me.k, q, Me.h.t, al.buds, 0, int(Me.h.d), 0, Cultivo.ra_ar(Me.get("f")))
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
		var p: float = float(Me.p) + 1.0 / float(strain(lot_sid(Me.k)).d) * Cultivo.ra_crec(Me.get("f"))
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
		* (1 + float(D.ABONO.rend) * am) * (1 + Cultivo.fam(S, "g")) * Cultivo.ra_g_mesa(Me.get("f"))
	var thc: float = Me.thc * (1 + Cultivo.fam(S, "thc")) + float(F.thc) + float(D.ABONO.thc) * am + Cultivo.ra_thc(Me.get("f"))
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
	if kc_f2() and mapa == D.KAIA_CULT.f2.sala:
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

# el controlador de clima, a la vista (lo pidió el usuario: «el controlador de clima de KAIA, que sea visual, también aplicar a la
# nave»): el cuadro de KAIA y el de la nave abren su pantalla (escena_extr.gd clima) con la temperatura, la humedad y el VPD, las 24
# horas del temporizador y el extractor a su carga; A, a lo de siempre; B, cerrar. Lo que enseña, de lo que ya cuenta el juego: en
# KAIA, el clima de la sala (KAIA_CULT.clima) y el temporizador por la fase de sus plantas; en la nave, la temperatura por el calor
# de sus focos sobre lo que saca la extracción (calor_nave, EXTR_NAVE.cap: pasada la carga, el sofoco) y 12/12 con una mesa en flor
func clima_v(s: String) -> Dictionary:
	var hz := 18
	var nf := 0
	var cg := 0.0
	var dn := 4.0   # lo que baja de noche, con los focos apagados
	var sof := 1.0
	var hs := {}   # las horas de luz de cada carpa o mesa con plantas (en KAIA, cada una con su temporizador)
	var t0: float = float(D.KAIA_CULT.clima.t)
	var hr0: float = float(D.KAIA_CULT.clima.hr)
	if s == "nave":
		var N = S.get("nave")
		if N != null:
			for i in N.m.size():
				if N.m[i]:
					nf += 1
					if fase_mesa(i) >= 3:
						hz = 12
			cg = calor_nave() / maxf(1.0, float(D.EXTR_NAVE[int(N.ex)].cap))
			sof = sofoco_nave()
		t0 = 21.0 + 9.0 * cg   # a la carga justa de la extracción, 30 °C (el tope de T_OK); pasada, el sofoco (sofoco_nave)
		dn = 0.0   # el calor de la nave (calor_nave) no depende de la hora: el mismo de día y de noche
		hr0 = clampf(50.0 + 3.0 * nf - 4.0 * int(N.ex if N != null else 0), 35, 75)
	elif S.get("kc") is Dictionary:
		kc()
		var nc := 0
		if kc_f2():   # la sala reformada: las plantas, en las mesas (S.kc.m), cada una con su LED doble
			nc = S.kc.get("m", []).size()
			for i in nc:
				var Me = kc_me(i)
				if Me != null and Me.get("h") == null:
					nf += 1
					hs[18 if float(Me.p) < FLOR_MESA else 12] = 1
		else:   # las carpas: cada una con su temporizador (veg 18/6, flor 12/12, auto por la fase de sus plantas)
			for ci in kc_ns():
				if not kc_tiene(ci):
					continue
				nc += 1
				var n := 0
				var flor := false
				for j in kc_n(ci):
					var p = S.kc.p[kc_off(ci) + j] if kc_off(ci) + j < S.kc.p.size() else null
					if p is Dictionary and not p.get("dead"):
						n += 1
						flor = flor or Cultivo.plant_stage(p) >= 3
				if n == 0:
					continue
				nf += n
				var ck: String = Cultivo.ciclo_de(kc_cc(ci))
				hs[12 if ck == "flor" or (ck == "auto" and flor) else 18] = 1
		if hs.size():
			hz = int(hs.keys().max())
		# la extracción de cada kit va a la medida de sus LED: con todas encendidas, al 70 %; la temperatura y la humedad, con lo que
		# hay encendido y con las plantas que transpiran
		cg = .7 * float(hs.size() > 0)
		t0 = 21.0 + 6.0 * cg
		hr0 = clampf(48.0 + 14.0 * float(nf) / maxf(1.0, float(nc) * 6.0), 40, 70)
	var on := func(m: int) -> bool:
		if nf == 0:
			return false
		var d := posmod(m - Cultivo.LUZ_DESDE, 24 * 60)
		if hs.size():
			return hs.keys().any(func(h): return d < int(h) * 60)
		return d < hz * 60
	var graf := []
	for hh in 24:
		var l: bool = on.call(hh * 60)
		graf.append([t0 if l else t0 - dn, l])
	var luz: bool = on.call(int(S.min))
	var t: float = t0 if luz else t0 - dn
	var hr: float = hr0 if luz else minf(hr0 + 6.0, 90)
	var es := .6108 * exp(17.27 * t / (t + 237.3))
	return {"t": t, "hr": hr, "vpd": es * (1 - hr / 100.0), "luz": luz, "hz": hz, "mix": hs.size() > 1, "nf": nf, "cg": cg, "sof": sof, "graf": graf, "min": int(S.min), "s": s}

func vista_clima(s: String) -> bool:
	if not Datos.CAL or oraculo or gancho_menu.is_valid():
		return true
	var C := clima_v(s)
	CLIMA_V = {"s": s}
	var nm: String = K("EL CLIMA DE LA NAVE") if s == "nave" else K("EL CLIMA DE LA SALA")
	var est: String = K("todo en su sitio")
	if float(C.sof) < 1.0 or float(C.t) > float(D.T_OK[1]):   # lo mismo que hace el juego: pasada la carga, el sofoco
		est = K("demasiado calor: la extracción no da para tantos focos")
	elif float(C.t) < float(D.T_OK[0]):
		est = K("hace frío")
	var lz: String = T("luz por carpa, a 18/6 y a 12/12, {l}", {"l": K("encendida") if C.luz else K("apagada")}) if C.mix else T("luz a {a}/{b}, {l}", {"a": int(C.hz), "b": 24 - int(C.hz), "l": K("encendida") if C.luz else K("apagada")})
	_dlg_fijo(T("{t} °C · {h} % · VPD {v} kPa · {z} · extracción al {c} %: {e}.\nA: el cuadro · B: cerrar.", {"t": ("%.1f" % float(C.t)).replace(".", ","), "h": roundi(float(C.hr)), "v": ("%.1f" % float(C.vpd)).replace(".", ","), "z": lz, "c": roundi(100 * float(C.cg)), "e": est}), nm)
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "B":
			pop()
			pr.res(b == "A"))
	var e = await Motor.espera(pr)
	CLIMA_V = null
	dlg.hide()
	dlg_nm.hide()
	return bool(e)
