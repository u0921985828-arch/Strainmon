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
	if S.kc.get("f2") != null:   # la sala reformada de antes, con seis mesas: las que faltan hasta las ocho, vacías
		if not (S.kc.get("m") is Array):
			S.kc.m = []
		while S.kc.m.size() < D.KAIA_CULT.f2.mesas.size():
			S.kc.m.append(null)
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

func kc_carpa_en(x: int, y: int, dep := false) -> int:   # la carpa (N.tam casillas) con la casilla (x, y), o -1; con dep, la de ese depósito
	if kc_f2() or kc_obra():
		return -1
	for ci in kc_ns():
		if not kc_tiene(ci):
			continue
		var t: Array = kc_Nc(ci).tam
		var p := kc_pos(ci)
		if dep:
			var d := kc_dep(ci)
			if x == int(p[0]) + int(d[0]) and y == int(p[1]) + int(d[1]):
				return ci
		elif y >= int(p[1]) and y < int(p[1]) + int(t[1]) and x >= int(p[0]) and x < int(p[0]) + int(t[0]):
			return ci
	return -1

func kc_dep(ci: int) -> Array:   # la casilla de su depósito del goteo, desde la de arriba a la izquierda de la carpa (kaia_cult.py: NIV.dep)
	return kc_Nc(ci).dep[kc_iN(ci)]

# el lado del servicio de la carpa ci (la puerta lateral, la ventana de malla y la manga del intractor, abajo): el que tiene más casillas
# libres al lado donde se dejó, donde cabe quien la abre y de donde viene el aire limpio (lo pidió el usuario: «el extractor y el
# intractor… se verá… dependiendo de dónde esté la mesa colocada»); si empatan, el de su depósito, que hay que tener a mano. 1, la
# derecha; -1, la izquierda. Se queda al montarla: mover otra carpa no le cambia las aberturas (S.kc.ld[ci] = [lado, x, y], del sitio
# donde se calculó; de serie, el de su sitio de serie con las siete en el suyo, kc_lado_serie), y ORDENAR no deja tapárselo (cabe_pieza).
# El extractor va arriba en el lado contrario (kc_ruta): el aire entra abajo por un lado y sale arriba por el otro
func kc_lado(ci: int) -> int:
	var mapa: String = D.KAIA_CULT.mapa
	var p := kc_pos(ci)
	var k := "kc%s%d" % [kc_Nc(ci).k, kc_iN(ci)]   # i18n-no
	var co = S.get("coloca")
	var movida: bool = (co is Dictionary and co.get(mapa) is Dictionary and co[mapa].has(k)) or (ORDEN != null and ORDEN.mapa == mapa and ORDEN.k == k)
	if not movida:
		return kc_lado_serie(ci)
	var ld = kc().get("ld", {}).get(str(ci)) if kc().get("ld") is Dictionary else null
	if ld is Array and int(ld[1]) == int(p[0]) and int(ld[2]) == int(p[1]):
		return int(ld[0])
	var l := kc_lado_en(ci, MAPS[mapa].o, p)
	if ORDEN == null and S.map == mapa and not _kc_mt:   # donde la dejaste, con la sala montada
		if not (kc().get("ld") is Dictionary):
			S.kc.ld = {}
		S.kc.ld[str(ci)] = [l, int(p[0]), int(p[1])]
	return l

# las casillas de suelo libres en O al lado (lado) de la carpa ci en p a las que se llega (v: andable con O)
func kc_libres(ci: int, O: Array, p: Array, lado: int, v = null) -> int:
	var m: Dictionary = MAPS[D.KAIA_CULT.mapa]
	if v == null:
		v = andable(m, O)
	var t: Array = kc_Nc(ci).tam
	var x: int = int(p[0]) - 1 if lado < 0 else int(p[0]) + int(t[0])
	var n := 0
	for y in range(int(p[1]), int(p[1]) + int(t[1])):
		if x >= 0 and x < int(m.w) and y >= 0 and y < int(m.h) and String(m.g[y][x]).begins_with("floor") and not O[y][x] and v.has("%d,%d" % [x, y]):
			n += 1
	return n

func kc_lado_en(ci: int, O: Array, p: Array) -> int:   # el lado con más sitio en O con la carpa ci en p (si empatan, el de su depósito)
	var v := andable(MAPS[D.KAIA_CULT.mapa], O)
	var iz := kc_libres(ci, O, p, -1, v)
	var de := kc_libres(ci, O, p, 1, v)
	if iz != de:
		return -1 if iz > de else 1
	return -1 if int(kc_dep(ci)[0]) < 0 else 1

var _kc_ls := {}
var _kc_mt := false   # montando la sala (kc_monta): aún no está entera
func kc_lado_serie(ci: int) -> int:   # el de su sitio de serie, con las siete en el suyo (kaia_cult.py NIV.def)
	if not _kc_ls.has(ci):
		var mapa: String = D.KAIA_CULT.mapa
		var O: Array = D.MAPS[mapa].o.map(func(r): return r.duplicate())
		for P_ in D.ORDEN_P[mapa].piezas:
			var d: Array = def_p(P_)
			for c in celdas_p(P_, int(d[0]), int(d[1])):
				O[int(c[1])][int(c[0])] = c[2]
		var d: Array = def_p(pieza_de(mapa, "kc%s%d" % [kc_Nc(ci).k, kc_iN(ci)]))   # i18n-no
		_kc_ls[ci] = kc_lado_en(ci, O, d)
	return int(_kc_ls[ci])

func kc_ancla(o) -> int:   # la carpa del objeto o, si es el ancla de una (carpaKS0…), o -1
	if not (o is String):
		return -1
	var NV: Array = D.KAIA_CULT.niv
	for nv in NV.size():
		var N: Dictionary = NV[nv]
		if o.begins_with(N.obj) and o.substr(String(N.obj).length()).is_valid_int():
			return kc_base(nv) + int(o.substr(String(N.obj).length()))
	return -1

# ORDENAR en la sala de cultivo (lo pidió el usuario: «coherencia y lógica»): además de lo de siempre (calle.gd), ninguna carpa con su
# lado de servicio tapado (servicio: la que mueves, con el lado que le quedaría ahí) y todas con camino para su tubo a la pared (tubo)
func cabe_pieza(mapa: String, k: String, x: int, y: int, O = null, jug := true, sol := true) -> String:
	var r: String = super(mapa, k, x, y, O, jug, sol)
	if r != "" or not sol or not kc_hay() or mapa != D.KAIA_CULT.mapa or kc_f2() or kc_obra():
		return r
	var ci := kc_de_pieza(k)
	if ci < 0:
		return r
	if O == null:
		O = sin_pieza(mapa, k)
	var O2: Array = O.map(func(rr): return rr.duplicate())
	for c in celdas_p(pieza_de(mapa, k), x, y):
		O2[int(c[1])][int(c[0])] = c[2]
	var lados := {}
	var v := andable(MAPS[mapa], O2)
	for a in kc_anclas(O2):
		var cj: int = a[0]
		var l: int = kc_lado_en(ci, O2, [x, y]) if cj == ci else kc_lado(cj)
		if kc_libres(cj, O2, [a[1], a[2]], l, v) < 1:
			return "servicio"   # i18n-no
		lados[cj] = l
	if not kc_ruta(O2, lados).ok:
		return "tubo"   # i18n-no
	return ""

func kc_anclas(O: Array) -> Array:   # [carpa, x, y de su casilla de arriba a la izquierda] de cada carpa en O
	var l := []
	for ty in O.size():
		for tx in O[ty].size():
			var ci := kc_ancla(O[ty][tx])
			if ci >= 0:
				l.append([ci, tx, ty - int(kc_Nc(ci).tam[1]) + 1])
	return l

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

# cada carpa, cerrada como las de casa (lo pidió el usuario: «de como están hechas en casa»): kcs, kcm y kcl, y la de sala, kcx, de
# kaia_carpa.py; lo de dentro se ve en su vista (kc_vista)
func sprite_local(o: String) -> String:
	if kc_hay():
		if o == String(D.KAIA_CULT.f2.carpa.obj):
			return "kcx"   # i18n-no
		var NV: Array = D.KAIA_CULT.niv
		for nv in NV.size():
			var N: Dictionary = NV[nv]
			if o.begins_with(N.obj) and o.substr(String(N.obj).length()).is_valid_int():
				var ci := kc_base(nv) + int(o.substr(String(N.obj).length()))
				return String(N.spr) + ("i" if ci < kc_ns() and kc_lado(ci) < 0 else "")   # el servicio a la izquierda (kcsi, kcmi, kcli)  # i18n-no
	return super(o)

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
	_kc_mt = true
	aplica_orden(mapa)
	_kc_mt = false
	if not kc_f2():
		return
	var cq: Array = D.KAIA_CULT.ctrl   # con la carpa de sala, su cuadro va dentro (f2.o): fuera no queda otro para lo mismo
	if String(m.o[int(cq[1])][int(cq[0])]) == "ctrlN":   # i18n-no
		m.o[int(cq[1])][int(cq[0])] = null
	# el último nivel (lo pidió el usuario: «que la carpa ocupe finalmente todo el suelo preparado para la carpa»): la carpa de sala,
	# que se entra por su puerta; dentro (cult-sala), las 8 mesas de flujo y reflujo con su riego y su drenaje
	var C: Dictionary = D.KAIA_CULT.f2.carpa
	var x0: int = int(C.def[0])
	var y0: int = int(C.def[1])
	for dy in int(C.tam[1]):
		for dx in int(C.tam[0]):
			m.o[y0 + dy][x0 + dx] = "carpaG2"   # i18n-no
	m.o[y0 + int(C.tam[1]) - 1][x0] = String(C.obj)
	for q in D.KAIA_CULT.f2.get("fuera", []):   # el rincón del riego, fuera de la carpa (red_fuera)  # i18n-no
		m.o[int(q[1])][int(q[0])] = String(q[2])

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
	if S.map == D.KAIA_CULT.mapa and kc_en_sala(x, y):   # la carpa de sala: se entra por su cremallera, no por la tela
		var F2: Dictionary = D.KAIA_CULT.f2
		var pu: Array = F2.carpa.get("puerta", [x, y])
		if absi(x - int(pu[0])) > 1 or absi(y - int(pu[1])) > 1:
			await say(K("La tela de la carpa de sala, cerrada: se entra por su puerta, la cremallera de delante."))
			return true
		await warp({"to": F2.sala, "x": int(F2.entra[0]), "y": int(F2.entra[1]), "dir": "up"})   # i18n-no
		return true
	if o == "drenKS" or o == "drenKS2" or o == "drenKB" or o == "drenKB2":   # i18n-no
		await say(K("El depósito de recogida: lo que sobra de cada mesa baja por su tubería de drenaje y se filtra antes de volver al tanque."))
		return true
	if o is String and DEP_BD.has(o):   # el depósito del goteo de una carpa, fuera de ella (kaia_cult.py: NIV.dep)
		var cd := kc_carpa_en(x, y, true)
		await say(T("El depósito del goteo de la carpa {n}, de {l} L, fuera de ella: su bomba manda el agua con el abono por la manguera, que entra por la pared de la carpa, a cada maceta.", {"n": cd + 1, "l": int(kc_Nc(cd).dl)}))
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
		"tanqueKB":   # el rincón del riego, fuera de la carpa de sala  # i18n-no
			await say(K("El rincón del riego, fuera de la carpa: el tanque con el abono ya mezclado, el programador que lo manda a cada mesa por la boca de servicio y el depósito de recogida, al que vuelve por ella lo que sobra."))
			return true
		"riegoN", "riegoKB":   # i18n-no
			await say(K("El programador del riego de las mesas: los turnos de cada una, el pH y la EC, en automático."))
			return true
		"filtroN", "extrG":   # i18n-no
			await say(K("El filtro de carbón y el extractor de la carpa: el aire sale limpio por el tubo del techo y entra el de fuera por los intractores de abajo."))
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
			txt = T("El cuadro de la sala: ocho mesas con su LED doble, el riego centralizado y el clima. {q}", {"q": T("Las lleva {n}.", {"n": w.n}) if w != null else K("Nadie las lleva: pon a alguien de tu plantilla en la sala desde el móvil.")})
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
			txt = T("El cuadro de la sala: el clima, el goteo y la corriente de las carpas. La luz la lleva el temporizador de cada carpa, dentro: muchas horas mientras crecen y menos en cuanto toca florecer. Carpas: {l}.", {"l": ", ".join(PackedStringArray(tl))})
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

# la carpa ci como las de casa (D.CARPAS) para su vista C; la de 400 × 400, la mitad h (0, la de delante; 1, la del fondo): su tubo sale
# por la boca del fondo del techo, así que el extractor solo se ve en la del fondo (ext), y en la pared del servicio (sl: la de la
# izquierda) la puerta lateral va en la de delante y la manga del intractor en la del fondo, con una ventana en cada una (serv)
func kc_def(ci: int, h := 0) -> Dictionary:
	var N: Dictionary = kc_Nc(ci)
	var mi := kc_mitades(ci)
	var W: float = float(N.cm[0])
	var Dp: float = float(N.cm[1]) / mi
	var nv: int = kc_n(ci) / mi
	var cols := maxi(1, roundi(sqrt(nv * W / Dp)))
	return {"n": N.n, "w": 2, "cm": [W, float(N.cm[2]), Dp], "cols": cols, "filas": ceili(float(nv) / cols), "plazas": nv, "wmax": int(D.FOCOS[D.KAIA_CULT.foco].w) * int(N.nf), "lmax": int(D.MACETAS.get(kc_pat(ci).m, {"l": 25}).l), "kc": true, "depi": int(kc_dep(ci)[0]) < 0,
		"dl": int(N.dl), "ds": String(N.ds), "fil": N.fil, "ux": kc_ux(ci), "sl": kc_lado(ci) < 0, "ext": mi == 1 or h == 1,
		"serv": ["puerta", "ventana", "manga"] if mi == 1 else (["puerta", "ventana"] if h == 0 else ["manga", "ventana"])}   # i18n-no

# dónde sale su tubo de extracción por el techo (tubos_ext), de 0 (su canto izquierdo) a 1 (el derecho): ahí cuelga el extractor con
# su filtro en la vista C (lo pidió el usuario: «el extractor y el intractor… se verá… dependiendo de dónde esté la mesa colocada»)
func kc_ux(ci: int) -> float:
	var p := kc_pos(ci)
	var w: int = int(kc_Nc(ci).tam[0]) * 16
	for q in tubos_ext():
		if int(q[3]) == ci:
			return clampf(float(int(q[0]) - int(p[0]) * 16) / w, 0.0, 1.0)
	return 0.5

func kc_vista_on() -> void:
	var ci: int = KCV.ci
	var mi := kc_mitades(ci)
	var t := "kc%s%d-%d" % [kc_Nc(ci).k, kc_n(ci), KCV.h]   # i18n-no
	D.CARPAS[t] = kc_def(ci, int(KCV.h))
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
		if int(Ms[i][1]) == y and x >= int(Ms[i][0]) and x <= int(Ms[i][0]) + 2:   # la mesa de 240 cm, en sus tres casillas
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
# De fondo la pared plateada de la carpa (carpa-c-pared, la de casa) y, delante, la mesa de flujo y reflujo de frente (o-mesaF, de
# PixelLab) con sus cinco macetas de tela de 11 L dentro de la bandeja, como en la nave (3 delante y 2 detrás, a tresbolillo), y en
# cada una su planta de la vista C en la fase de la mesa, con el tono de hoja y el cogollo de su variedad; encima, el «LED doble»: dos
# LED de 720 W de casa (foco-c-led720-78) colgados de sus cuerdas, que suben a medida que crecen las plantas, a su temporizador (18/6
# mientras crecen, 12/12 en flor), y arriba a la derecha las ocho mesas de la sala. ◀ ▶ cambian de mesa (▲ ▼, de fila); A, lo de la
# mesa (kc_mesa); B cierra. MESA_KV = {i: la mesa}
const EscK = preload("res://src/escena_extr.gd")
const MESAK_LED := "foco-c-led720-78"   # i18n-no
const MESAK_MAC := [[-29, 17], [29, 17], [-58, 24], [0, 24], [58, 24]]   # cada maceta: x desde el centro de la mesa y la fila de su base
const MESAK_CANTO := 23   # o-mesaF: el fondo de la bandeja, de la fila 12 a la 22; el canto de delante, desde la 23
const MESAK_ALTO := 0.45   # px por cm de alto de las plantas (PLANTA_CM): más bajas que a escala, para que quepan bajo su LED
const MESAK_TOPE := 28
const MESAK_ESP := 44   # el sitio de cada planta a lo ancho (vc_planta_sprite)

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
func _mesak_planta(Me: Dictionary, fm: int, hp: int):   # la planta de la mesa en su fase y a su alto, con los colores de su variedad
	var p := {"sid": lot_sid(Me.k), "f": Me.get("f")}
	var po := Datos.porte_planta(S, p)
	var s = VistaM.vc_planta_sprite(po, fm, MESAK_ESP)
	if s == null or not ArteM.hay(s.n):
		return null
	var n: String = s.n
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
	var Me = kc_me(i)
	var viva: bool = Me != null and Me.get("h") == null
	o.append([0, 0, SW, SH, "#0e0e12"])
	if ArteM.hay("carpa-c-pared"):
		o.append(["@", ArteM.foto("carpa-c-pared"), x0, -MAD_PARED, clip])
	var mf = EscK.pl("o-mesaF")   # i18n-no
	var my: int = H - 2 - mf.get_height()
	var mx: int = x0 + ((240 - mf.get_width()) >> 1)
	var cx0: int = mx + (mf.get_width() >> 1)
	# las macetas en la bandeja, de atrás adelante, cada una con su planta (con el pie en su tierra, VC_TIERRA)
	var mc := "maceta-c-tela11-20"   # i18n-no
	var mi: Image = ArteM.foto(mc) if ArteM.hay(mc) else null
	var ti: int = int(D.VC_TIERRA.get(mc, 17))
	var cosas := []
	var tope: int = my + 8   # lo más alto de las plantas: sin ellas, el LED a su altura más baja
	if viva:
		var fm := kc_fase(i)
		var Dh: Array = D.PLANTA_CM[Datos.porte_planta(S, {"sid": lot_sid(Me.k), "f": Me.get("f")})].h
		for k in MESAK_MAC.size():
			var cx: int = cx0 + int(MESAK_MAC[k][0])
			var yb: int = my + int(MESAK_MAC[k][1])
			if mi != null:
				cosas.append(["@", mi, cx - (mi.get_width() >> 1), yb - mi.get_height(), clip])
			var im = _mesak_planta(Me, fm, mini(Datos.jsround(float(Dh[fm]) * MESAK_ALTO), MESAK_TOPE) - (k % 2) * 2)
			if im != null:
				var y: int = yb - ti - im.get_height() + 1
				cosas.append(["@", im, cx - (im.get_width() >> 1), y, clip])
				tope = mini(tope, y + im.get_height() - ArteM.alto(im))   # su cima: la primera fila con algo
	# el LED doble, colgado de sus cuerdas del techo de la carpa: a 6 filas de lo más alto de las plantas
	var fi: Image = ArteM.foto(MESAK_LED) if ArteM.hay(MESAK_LED) else null
	if fi != null:
		var cu: Array = ArteM.cuelga(fi)
		var ly: int = clampi(tope - 6 - fi.get_height(), -4, 10)
		for d in [-46, 46]:
			var fx: int = cx0 + d - (fi.get_width() >> 1)
			o.append([fx + int(cu[0]), 0, 1, ly + int(cu[2]), ArteM.VC_CUERDA])
			o.append([fx + int(cu[1]), 0, 1, ly + int(cu[2]), ArteM.VC_CUERDA])
			o.append(["@", fi, fx, ly, clip])
	o.append_array(VistaM.temporizador(x0 + 8, 20, "veg" if Me == null or float(Me.p) < FLOR_MESA else "flor", on))
	o.append(["@", mf, mx, my, clip])
	o.append_array(cosas)
	if viva:
		o.append(["@", mf, mx, my, Rect2i(x0, my + MESAK_CANTO, 240, H - my - MESAK_CANTO)])   # el canto de la bandeja, delante de las macetas
	if on and fi != null:   # la luz de los dos LED, de ellos hacia abajo
		for d in [-46, 46]:
			o.append([cx0 + d - 40, 12, 80, H - 12, "rgba(255,244,214,0.06)"])
	if not on:
		o.append([x0, 0, 240, H, "rgba(4,4,10,0.72)"])
	var Ms: Array = D.KAIA_CULT.f2.mesas
	var fila: int = Ms.size() >> 1
	for j in Ms.size():   # las ocho mesas de la sala, en su sitio: la elegida en amarillo
		var qx: int = x0 + 240 - 6 - (fila - j % fila) * 7
		var qy: int = 4 + (j / fila) * 5
		o.append([qx, qy, 6, 3, "#f8d040" if j == i else ("#58c060" if kc_me(j) else "#5a5e66")])
	return o

# el riego y el drenaje de la carpa de sala (lo pidió el usuario: «todas las conexiones de riego, de drenaje hazlas con cabeza y
# pensando… LOGICAS» y «que tampoco sea el depósito… tendrá que estar fuera de las carpas»), como en una sala de mesas de flujo y
# reflujo de verdad: dentro, la impulsión (PE negro) corre por debajo de cada fila de mesas, con una electroválvula en cada una, y del
# desagüe de cada mesa baja su tubo al colector (PVC gris) de debajo de su fila; los dos bajan por la pared de la derecha y salen por
# la boca de servicio del frente (red_riego). Fuera, en el paso de delante de la carpa (f2.fuera, red_fuera): la bomba del tanque da
# al programador (riegoN, con sus dosificadoras), que sube la solución a la boca por el frente de la carpa; el drenaje baja de la boca
# por gravedad al tubo de arriba del depósito de recogida (drenKS, en la esquina), y su bomba lo devuelve filtrado al tanque por el
# suelo, por detrás de los aparatos. Nada cruza un pasillo ni otro tubo: todo va por debajo de las mesas, pegado a una pared o por el
# frente de la carpa, por encima de los aparatos.
# Tramos [x0, y0, x1, y1, tipo, alto] en píxeles del mapa, en horizontal o en vertical (tipo: "sum", la impulsión; "dren", el drenaje
# y la vuelta; alto: por el frente de la carpa o por encima de los aparatos); pinta.gd los pinta detrás de las mesas (tubos_dren) y
# de los aparatos (tubos_fuera)
const DREN_COL := ["#3e434c", "#9aa0a8", "#c4c8ce"]   # el canto, el PVC y su brillo
const SUM_COL := ["#16171c", "#4e525a"]   # el PE negro de la impulsión y su brillo
const KC_BOCA := [176, 100, 8, 6]   # la boca de servicio en el sprite de la carpa de sala (kaia_carpa.py BOCA_SALA): x, y, ancho y alto
func red_riego() -> Array:
	var l := []
	if not kc_hay():
		return l
	var F2: Dictionary = D.KAIA_CULT.f2
	var xs: int = int(F2.W) * 16 - 8   # por la pared de la derecha: la impulsión y, pegado a la pared, el colector
	var xd: int = int(F2.W) * 16 - 5
	var yf: int = int(F2.H) * 16 - 1   # el canto de delante: la boca de servicio
	var filas := {}
	for q in F2.mesas:
		filas[int(q[1])] = mini(int(filas.get(int(q[1]), 1 << 20)), int(q[0]))
	var ytop := 1 << 20
	for r in filas:
		var Y: int = int(r) * 16
		ytop = mini(ytop, Y)
		var xa: int = int(filas[r]) * 16 - 3   # desde el canto de la primera mesa de la fila
		l.append([xa, Y + 10, xs, Y + 10, "sum", false])
		l.append([xa, Y + 13, xd, Y + 13, "dren", false])
	for q in F2.mesas:   # de cada mesa: su desagüe (el de mesaN, delante a la derecha) baja al colector
		var x: int = int(q[0]) * 16 + 29
		var Y: int = int(q[1]) * 16
		l.append([x, Y + 9, x, Y + 13, "dren", false])
	l.append([xs, ytop + 10, xs, yf, "sum", false])   # la impulsión, de la boca de servicio por la pared de la derecha
	l.append([xd, ytop + 13, xd, yf, "dren", false])   # y el colector, a la boca
	return l

# la boca de servicio en cult-muelle: [x, y, ancho, alto] en píxeles del mapa (la carpa de sala, de 112 filas, con el pie en su fila de abajo)
func kc_boca() -> Array:
	var C: Dictionary = D.KAIA_CULT.f2.carpa
	return [int(C.def[0]) * 16 + int(KC_BOCA[0]), (int(C.def[1]) + int(C.tam[1])) * 16 - 112 + int(KC_BOCA[1]), int(KC_BOCA[2]), int(KC_BOCA[3])]

# lo de fuera, contra sus sprites (kaia_riego.py, de una casilla de alto y con el pie en la fila de abajo de la suya; columnas de su
# celda de 32): el tanque (tanqueKB: el cuerpo de la 7 a la 24 y su salida, que acaba en la 28, en las filas 3 y 4), el programador
# (riegoKB: las dosificadoras de la 8 a la 20 y el mueble, de la 7 a la 22, desde la fila 5) y el depósito de recogida (drenKB: el
# tubo de entrada de la 11 a la 14, arriba, y la bomba de la 24 a la 31, abajo). La salida del tanque da al programador; de su
# mueble sube la impulsión por el frente de la carpa y entra por el lado de la boca; el drenaje cae de la boca, recto, al tubo de
# entrada del depósito, y la vuelta, de la bomba al tanque, va por el suelo, por detrás de los aparatos
func red_fuera() -> Array:
	var l := []
	if not kc_hay() or not kc_f2():
		return l
	var pos := {}
	for q in D.KAIA_CULT.f2.get("fuera", []):
		pos[String(q[2])] = [int(q[0]), int(q[1])]
	if not (pos.has("tanqueKB") and pos.has("riegoKB") and pos.has("drenKB")):   # i18n-no
		return l
	var b := kc_boca()
	var tq: Array = pos.tanqueKB
	var rg: Array = pos.riegoKB
	var dr: Array = pos.drenKB
	var Y: int = int(rg[1]) * 16   # la fila de arriba de los aparatos
	var xp: int = int(rg[0]) * 16 - 8 + 21   # el canto de la derecha del mueble del programador
	var ys: int = int(b[1]) + 2   # por el agujero de la boca
	l.append([int(tq[0]) * 16 + 21, Y + 3, int(rg[0]) * 16 - 1, Y + 3, "sum", true])   # de la salida del tanque al programador
	l.append([xp, ys, xp, Y + 5, "sum", true])   # de su mueble sube por el frente de la carpa
	l.append([xp, ys, int(b[0]) + 1, ys, "sum", true])   # y entra por el lado de la boca
	var xe: int = int(dr[0]) * 16 - 8 + 12   # el drenaje: de la boca, recto abajo, al tubo de entrada del depósito
	l.append([xe, int(b[1]) + int(b[3]) - 2, xe, Y + 1, "dren", true])
	l.append([int(tq[0]) * 16 + 13, Y + 12, int(dr[0]) * 16 - 8 + 24, Y + 12, "dren", false])   # la vuelta: de la bomba al tanque, por detrás
	return l

# los rectángulos [x, y, w, h, color] de una red (red_riego o red_fuera)
func _tubos_de(red: Array) -> Array:
	var l := []
	for t in red:
		var x0: int = mini(int(t[0]), int(t[2]))
		var x1: int = maxi(int(t[0]), int(t[2]))
		var y0: int = mini(int(t[1]), int(t[3]))
		var y1: int = maxi(int(t[1]), int(t[3]))
		if t[4] == "sum":   # i18n-no
			if y0 == y1:
				l.append([x0, y0, x1 - x0 + 2, 1, SUM_COL[1]])
				l.append([x0, y0 + 1, x1 - x0 + 2, 1, SUM_COL[0]])
			else:
				l.append([x0, y0, 1, y1 - y0 + 2, SUM_COL[1]])
				l.append([x0 + 1, y0, 1, y1 - y0 + 2, SUM_COL[0]])
		elif y0 == y1:
			_tubo_h(l, x0, x1, y0)
		else:
			_tubo_v(l, x0, y0, y1)
	return l

# los de la carpa de sala por dentro, con una electroválvula en cada mesa y, en el canto de delante, el pasamuros de la boca de servicio
func tubos_dren() -> Array:
	if not kc_f2() or S.map != D.KAIA_CULT.f2.sala:
		return []
	var l := _tubos_de(red_riego())
	for q in D.KAIA_CULT.f2.mesas:   # la electroválvula de cada mesa, en la impulsión, con su piloto
		var x: int = int(q[0]) * 16 + 9
		var Y: int = int(q[1]) * 16
		l.append([x, Y + 9, 4, 3, "#2a2c32"])
		l.append([x + 1, Y + 9, 2, 1, "#6a6e76"])
		l.append([x + 3, Y + 10, 1, 1, "#58e070"])
	var xs: int = int(D.KAIA_CULT.f2.W) * 16 - 8
	var yf: int = int(D.KAIA_CULT.f2.H) * 16 - 1
	l.append([xs - 3, yf - 3, 11, 4, "#2a2a34"])   # el pasamuros, con su aro y el agujero por el que salen
	l.append([xs - 2, yf - 2, 9, 3, "#8a8e98"])
	l.append([xs - 1, yf - 1, 7, 2, "#16171c"])
	for e in _tubos_de([[xs, yf - 6, xs, yf - 2, "sum", false], [xs + 3, yf - 6, xs + 3, yf - 2, "dren", false]]):
		l.append(e)   # los tubos, entrando en él
	return l

# los de fuera, delante de la carpa de sala
func tubos_fuera() -> Array:
	if not kc_f2() or S.map != D.KAIA_CULT.mapa:
		return []
	return _tubos_de(red_fuera())

# el tubo de extracción de cada carpa a la pared, como en casa (lo pidió el usuario: «todas las conexiones… lógicas»): el extractor y el
# filtro de carbón, colgados dentro; el tubo sale por la boca del techo, en su canto de atrás (como _tubos_casa), y va pegado al techo
# de la sala hasta la pared de atrás, donde la atraviesa por un pasamuros de chapa en la fila de arriba. Uno por carpa (la de 400 ×
# 400 lleva dos filtros en un tubo de 315 mm) y dos en la de sala. Sin pisar nada (lo pidió el usuario: «No quiero que ningún objeto de
# pared o suelo se superponga sobre otro»): ni otra carpa, ni un depósito, ni lo de la pared, ni otro tubo (a un tubo como poco), con
# los pasamuros separados; recto, si cabe, por la mitad de su techo contraria al servicio (kc_lado) y, si no (las que tienen otra carpa
# detrás), al colector: un tubo por el techo del paso de delante de las de atrás, al que llega cada una por su ramal en T y que sale a
# la pared por un lado, con sus codos (kc_ruta). Cada uno, [x, y de arriba, y de abajo, carpa, en su mitad, [x0, x1] del colector,
# tipo] en píxeles del mapa: «recto», del pasamuros a la boca; «rama», del colector a la boca; «col», el colector (carpa -2), del
# pasamuros a su altura y de x0 a x1
const KC_TUBO_PARED := 8   # el centro del pasamuros, en la fila de arriba de la pared
# lo que ocupa cada depósito del goteo en su casilla (kaia_riego.py, a su tamaño: 100, 200 y 400 L): [columna de la izquierda, de la
# derecha, filas de alto desde el suelo]; el «d», a la derecha de su carpa
const DEP_BD := {"depK": [3, 14, 16], "depKd": [1, 12, 16], "depKm": [2, 14, 22], "depKmd": [1, 13, 22], "depKl": [0, 14, 25], "depKld": [1, 15, 25]}   # i18n-no
# la manguera del depósito del goteo de cada carpa (NIV.dep: a su lado) a su pared, del grifo, a 40 cm del suelo como en casa
# (pinta.gd _y_goteo), con el pasamuros en el poste: [clave de orden, rectángulos]. El grifo del bidón, en sus filas 40-42 (la manguera,
# en la 41: el grifo, en sus columnas 20-21, con el canto en la 22; en espejo, depKd, a la derecha de su carpa, en la 10-11 y la 9)
func tubos_dep() -> Array:
	var l := []
	if not kc_hay() or kc_f2() or kc_obra() or S.map != D.KAIA_CULT.mapa:
		return l
	for ci in kc_ns():
		if not kc_tiene(ci):
			continue
		var d := kc_dep(ci)
		var p := kc_pos(ci)
		var X: int = (int(p[0]) + int(d[0])) * 16
		var yb: int = (int(p[1]) + int(d[1]) + 1) * 16 - 1
		var y := yb - 6
		var xh: int = X + 15 if int(d[0]) < 0 else X - 1   # de la columna de al lado del grifo a la pared de su carpa
		var xp: int = X + 16 if int(d[0]) < 0 else X - 1
		l.append([yb + 1, [[xh, y - 1, 2, 1, "#4a4c54"], [xh, y, 2, 1, "#1c1d22"], [xp, y - 2, 1, 4, "#3a3c44"]]])
	return l

func tubos_ext() -> Array:
	if not kc_hay() or S.map != D.KAIA_CULT.mapa:
		return []
	if kc_f2():
		var l := []
		var C: Dictionary = D.KAIA_CULT.f2.carpa
		var x0: int = int(C.def[0]) * 16
		var yb: int = (int(C.def[1]) + int(C.tam[1])) * 16 - 112 + 1   # la de sala, de 112 filas (kaia_carpa.py)
		for e in D.KAIA_CULT.f2.ext:   # encima de cada extractor de dentro (f2.ext: sus columnas)
			l.append([x0 + int(e) * 16 + 8, KC_TUBO_PARED, yb, -1, true, [], "recto"])   # i18n-no
		return l
	var m: Dictionary = MAPS[S.map]
	var lados := {}
	for a in kc_anclas(m.o):
		lados[int(a[0])] = kc_lado(int(a[0]))
	return kc_ruta(m.o, lados).l

const KC_PM := 6   # medio pasamuros: 13 px de ancho
var _kc_rc := {}
# los tubos de las carpas de O con los lados de servicio lados: {l: los tubos (tubos_ext), ok: si todas tienen camino sin pisar nada}
func kc_ruta(O: Array, lados: Dictionary) -> Dictionary:
	var key := "%s|%d" % [lados, O.hash()]
	if _kc_rc.has(key):
		return _kc_rc[key]
	if _kc_rc.size() > 64:
		_kc_rc.clear()
	var mapa: String = D.KAIA_CULT.mapa
	var Wp: int = int(MAPS[mapa].w) * 16
	var yw: int = KC_TUBO_PARED
	var pared := {}
	for e in D.PUERTAS_INT.get(mapa, []):
		pared["%d,%d" % [int(e.x), int(e.y)]] = true
	var obs := []   # lo que no se pisa: [x0, y0, x1, y1, su carpa o -1]
	var cs := []   # cada carpa: [x0, x1 del tubo, y de su boca, carpa], de atrás adelante
	for ty in O.size():
		for tx in O[ty].size():
			var o = O[ty][tx]
			var ci := kc_ancla(o)
			if ci >= 0:
				var t: Array = kc_Nc(ci).tam
				var y0: int = (ty + 1) * 16 - (int(t[1]) * 8 + 32)
				obs.append([tx * 16, y0, (tx + int(t[0])) * 16 - 1, (ty + 1) * 16 - 1, ci])
				cs.append([tx * 16 + 6, (tx + int(t[0])) * 16 - 7, y0 + 1, ci])
			elif o is String and DEP_BD.has(o):   # el depósito, lo que ocupa su sprite
				var q: Array = DEP_BD[o]
				obs.append([tx * 16 + int(q[0]), ty * 16 + 16 - int(q[2]), tx * 16 + int(q[1]), ty * 16 + 15, -1])
			elif (o is String and o != "carpaG2") or pared.has("%d,%d" % [tx, ty]):   # lo demás, su casilla; lo de la pared, hasta arriba
				obs.append([tx * 16, 0 if ty <= 1 else ty * 16, tx * 16 + 15, ty * 16 + 15, -1])
	cs.sort_custom(func(a, b): return a[2] < b[2] if a[2] != b[2] else a[0] < b[0])
	var fuera := {}   # las que van al colector aunque quepan rectas (su tubo recto lo cortaría)
	var out := {}
	for intento in cs.size() + 1:
		var l := []
		var segs := []   # los tramos rectos ya puestos: [x0, y0, x1, y1]
		var pms := []
		var R := []
		for c in cs:
			var ci: int = c[3]
			var h := _kc_mitad(c, int(lados.get(ci, 1)))
			var x := -1
			if not fuera.has(ci):
				x = _kc_busca(h, func(x2): return _kc_pm(obs, Wp, x2, pms) and _kc_libre(obs, [x2 - 2, yw - 5, x2 + 2, int(c[2])], ci, segs))
			if x < 0:
				R.append(c)
				continue
			segs.append([x - 2, yw - 5, x + 2, int(c[2])])
			pms.append(x)
			l.append([x, yw, int(c[2]), ci, true, [], "recto"])   # i18n-no
		if R.is_empty():
			out = {"l": l, "ok": true}
			break
		var col := _kc_colector(obs, Wp, R, lados, segs, pms)
		if not col.is_empty():
			out = {"l": l + col, "ok": true}
			break
		var bmin: int = R.map(func(c): return int(c[2])).min()
		var xr: int = (int(R.map(func(c): return int(c[0])).min()) + int(R.map(func(c): return int(c[1])).max())) / 2
		var otra := -1
		var dm := 99999
		for q in l:   # la recta de su fila más cerca de ellas, también al colector, y otra vez
			if int(q[2]) > bmin - 24 and absi(int(q[0]) - xr) < dm:
				dm = absi(int(q[0]) - xr)
				otra = int(q[3])
		if otra >= 0:
			fuera[otra] = true
			continue
		for c in R:   # sin camino (una partida de antes): recto donde caiga, para que se vea
			var h := _kc_mitad(c, int(lados.get(int(c[3]), 1)))
			var x := _kc_busca(h, func(x2): return segs.all(func(b): return absi(int(b[0]) + 2 - x2) >= 9))
			if x < 0:
				x = int(h[2])
			segs.append([x - 2, yw - 5, x + 2, int(c[2])])
			l.append([x, yw, int(c[2]), int(c[3]), false, [], "recto"])   # i18n-no
		out = {"l": l, "ok": false}
	_kc_rc[key] = out
	return out

func _kc_mitad(c: Array, lado: int) -> Array:   # [x0, x1, x preferida, carpa, su canto izquierdo] de la mitad del techo contraria al servicio, a un cuarto de su ancho
	var x0: int = c[0]
	var x1: int = c[1]
	var xm: int = (x0 + x1 + 1) / 2
	if lado < 0:   # el servicio a la izquierda: el tubo, por la derecha
		return [xm + 1, x1, x0 + (x1 - x0) * 3 / 4, int(c[3]), x0 - 6]
	return [x0, xm - 1, x0 + (x1 - x0) / 4, int(c[3]), x0 - 6]

func _kc_busca(h: Array, f: Callable) -> int:   # la x de h más cerca de la preferida que cumpla f y donde le cabe el filtro en su vista C, o -1
	for d in int(h[1]) - int(h[0]) + 1:
		for x in [int(h[2]) - d, int(h[2]) + d]:
			if x >= int(h[0]) and x <= int(h[1]) and (h.size() < 5 or kc_cabe_filtro(int(h[3]), x - int(h[4]))) and f.call(x):
				return x
	return -1

# si con su tubo a dx px de su canto izquierdo el extractor con su filtro cuelga en su vista C sin tocar ninguna cuerda de los LED
# (vista.gd kc_techo y kc_filtro_en: de lado o de frente a fondo); sin el arte de la vista, sí
var _kc_cf := {}
func kc_cabe_filtro(ci: int, dx: int) -> bool:
	var N: Dictionary = kc_Nc(ci)
	var k := "%s|%d" % [N.k, dx]
	if not _kc_cf.has(k):
		var T: Dictionary = VistaM.kc_techo(float(N.cm[0]), float(N.cm[2]), int(N.nf) / kc_mitades(ci), String(D.KAIA_CULT.foco), N.fil)
		var ux := float(dx) / (int(N.tam[0]) * 16)
		_kc_cf[k] = T.is_empty() or not VistaM.kc_filtro_en(T, int(T.xl) + Datos.jsround(ux * int(T.w)), ux < .5).is_empty()
	return _kc_cf[k]

func _kc_cruza(a: Array, b: Array, e: int) -> bool:
	return int(a[0]) <= int(b[2]) + e and int(b[0]) - e <= int(a[2]) and int(a[1]) <= int(b[3]) + e and int(b[1]) - e <= int(a[3])

func _kc_libre(obs: Array, r: Array, ci: int, segs: Array) -> bool:   # r, sin pisar nada (menos su carpa) ni a menos de un tubo de otro
	for b in obs:
		if (ci < 0 or int(b[4]) != ci) and _kc_cruza(r, b, 0):
			return false
	for b in segs:
		if _kc_cruza(r, b, 4):
			return false
	return true

func _kc_pm(obs: Array, Wp: int, x: int, pms: Array) -> bool:   # el pasamuros en x: en la pared, sin pisar lo de la pared ni otro
	if x - KC_PM < 0 or x + KC_PM > Wp - 1:
		return false
	for q in pms:
		if absi(int(q) - x) < 2 * KC_PM + 2:
			return false
	for b in obs:
		if _kc_cruza([x - KC_PM, KC_TUBO_PARED - 5, x + KC_PM, KC_TUBO_PARED + 4], b, 0):
			return false
	return true

# el colector de las carpas R: a la altura yt, lo más cerca de sus bocas, un ramal por carpa en su mitad y la salida a la pared por la
# izquierda de todos o por la derecha (la más corta), con su codo; [] si no cabe
func _kc_colector(obs: Array, Wp: int, R: Array, lados: Dictionary, segs: Array, pms: Array) -> Array:
	var yw: int = KC_TUBO_PARED
	var bmin: int = R.map(func(c): return int(c[2])).min()
	var bajo := []   # hasta dónde baja libre un tubo desde la pared en cada x
	for x in Wp:
		var y := 99999
		for b in obs:
			if x - 2 <= int(b[2]) and int(b[0]) <= x + 2:
				y = mini(y, int(b[1]) - 1)
		for b in segs:
			if x - 2 <= int(b[2]) + 4 and int(b[0]) - 4 <= x + 2:
				y = mini(y, int(b[1]) - 5)
		bajo.append(y)
	for yt in range(bmin - 9, yw + 16, -1):
		var ram := []
		for c in R:
			var ci: int = c[3]
			var x := _kc_busca(_kc_mitad(c, int(lados.get(ci, 1))), func(x2): return ram.all(func(q): return absi(int(q) - x2) >= 9) and _kc_libre(obs, [x2 - 2, yt - 2, x2 + 2, int(c[2])], ci, segs))
			if x < 0:
				break
			ram.append(x)
		if ram.size() < R.size():
			continue
		var xa: int = ram.min()
		var xb: int = ram.max()
		var mejor := []
		for lado in [-1, 1]:
			var xs: Array = range(xa - 12, KC_PM - 1, -1) if lado < 0 else range(xb + 12, Wp - KC_PM)
			for x2 in xs:
				if int(bajo[x2]) >= yt + 2 and _kc_pm(obs, Wp, x2, pms) and _kc_libre(obs, [mini(x2, xa) - 2, yt - 2, maxi(x2, xb) + 2, yt + 2], -1, segs):
					var lg: int = absi(x2 - (xa if lado < 0 else xb))
					if mejor.is_empty() or lg < int(mejor[1]):
						mejor = [x2, lg]
					break
		if mejor.is_empty():
			continue
		var xe: int = mejor[0]
		var l := [[xe, yw, yt, -2, true, [mini(xe, xa), maxi(xe, xb)], "col"]]   # i18n-no
		for i in R.size():
			l.append([ram[i], yt, int(R[i][2]), int(R[i][3]), true, [], "rama"])   # i18n-no
		return l
	return []

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
		await say(T("{n}: «Mañana empiezo en la sala de cultivo de KAIA: las ocho mesas, el riego y los cortes. {e} al día».", {"n": w.n, "e": Datos.eur(D.PLANTILLA.sueldo.kaia)}))
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
		# la extracción de cada kit va a la medida de sus LED: con todas encendidas, al 70 %; el controlador las tiene en su consigna
		# (KAIA_CULT.clima), como siempre (lo dijo el usuario: «el controlador está bien»)
		cg = .7 * float(hs.size() > 0)
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
