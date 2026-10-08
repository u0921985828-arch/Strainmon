# Ribera Verde (Godot) — el cultivo de 09-cultivo.js: plazas, factores de la carpa, crecimiento hora a hora, fenotipo al
# plantar, gramos y THC de cosecha. S es el estado de la partida (como el S del HTML: carpas, macetas, pots…)
extends RefCounted

const Datos = preload("res://src/datos.gd")

# azar: el de Godot o, para las pruebas, el Park-Miller del oráculo (tools/godot.js), que sustituye a Math.random
static var pm := -1
static var fijo := -1.0      # ≥ 0: azar() da siempre ese número (la prueba de las semillas al cosechar fija Math.random)
static func azar() -> float:
	if fijo >= 0:
		return fijo
	if pm < 0:
		return randf()
	pm = pm * 48271 % 2147483647
	return float(pm) / 2147483647.0

static func nuevo_estado() -> Dictionary:
	return {"day": 1, "min": 8 * 60, "money": 150, "carpas": [{"t": "m100", "foco": "sodio400"}], "macetas": ["plastico7", "plastico7", "plastico7", "plastico7"],
		"pots": [null, null, null, null], "seeds": {"ria": 2, "limon": 1, "txoko": 1, "niebla": 1}, "items": {"fert": 2, "insect": 3},
		"buds": {}, "custom": {}, "gen": {}, "fenos": {}, "fenoN": 0, "flags": {}}

# plazas de todas las carpas, en orden: S.pots[i] y S.macetas[i] son las de la plaza i
static func huecos(S: Dictionary) -> Array:
	var D := Datos.carga()
	var o := []
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if c == null:
			continue
		for j in int(D.CARPAS[c.t].plazas):
			o.append({"c": ci, "j": j})
	return o

static func factores(S: Dictionary, i: int) -> Dictionary:
	var D := Datos.carga()
	var h: Dictionary = huecos(S)[i]
	var c: Dictionary = S.carpas[h.c]
	var C: Dictionary = D.CARPAS[c.t]
	var F: Dictionary = D.FOCOS[c.foco]
	var M: Dictionary = D.MACETAS.get(S.macetas[i], D.MACETAS.plastico7)
	var dens := minf(1, F.w / (C.cm[0] * C.cm[2] / 1e4 * D.W_M2))
	var cl := clima_sala(S, es_noche(S))   # (1.10) crec lleva el clima de la sala y hr, su humedad (el moho de plant_step)
	return {"g": F.w * F.gpw / C.plazas * M.rend, "cap": M.cap, "crec": F.crec * (.85 + .15 * dens) * M.crec * f_clima(cl), "thc": F.thc * dens,
		"agua": F.agua * M.agua, "plaga": M.plaga * (.7 if c.get("vent") else 1.0), "dens": dens, "hr": cl.hr}

# ---------- la sala del piso (1.10, 09c-sala): clima, aparatos y goteo ----------
static func es_noche(S: Dictionary) -> bool:
	return S.min >= 21 * 60 or S.min < 6 * 60

static func mes_de(d: int) -> int:
	return (int(Datos.carga().MES0) + d - 1) % 12

static func fuera(v: float, r: Array) -> float:
	return r[0] - v if v < r[0] else (v - r[1] if v > r[1] else 0.0)

# t (°C, al décimo), hr (%), uso (los aparatos que trabajan) y n (plantas vivas)
static func clima_sala(S: Dictionary, noche: bool) -> Dictionary:
	var D := Datos.carga()
	var m := mes_de(int(S.day))
	var sa: Dictionary = S.get("sala", {})
	var nn := 0
	var calor := 0.0
	var filtros := 0
	for p in S.pots:
		if p and not p.get("dead"):
			nn += 1
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if not c or not plantas_vivas(S, ci):
			continue
		var F: Dictionary = D.FOCOS[c.foco]
		if not noche:
			calor += F.w * D.CALOR_W[F.tipo]
		if c.get("filtro"):
			filtros += 1
	var t: float = D.T_MES[m][1 if noche else 0] + calor - D.T_FILTRO * filtros
	var hr: float = D.HR_MES[m] + D.HR_PLANTA * nn + (D.HR_NOCHE if noche else 0.0) - D.HR_FILTRO * filtros - calor
	var uso := {}
	if nn:
		for k in D.APARATOS:
			var A: Dictionary = D.APARATOS[k]
			if not sa.get(k) or not (A.get("t") or A.get("hr")):
				continue
			if A.get("t"):
				if (t < A.obj) if A.t > 0 else (t > A.obj):
					t = minf(A.obj, t + A.t) if A.t > 0 else maxf(A.obj, t + A.t)
					uso[k] = 1
			elif (hr < A.obj) if A.hr > 0 else (hr > A.obj):
				hr = minf(A.obj, hr + A.hr) if A.hr > 0 else maxf(A.obj, hr + A.hr)
				uso[k] = 1
	return {"t": Datos.jsround(t * 10) / 10.0, "hr": Datos.jsround(hr), "uso": uso, "n": nn}

static func f_clima(cl: Dictionary) -> float:
	var D := Datos.carga()
	return clampf(1 - .06 * fuera(cl.t, D.T_OK), .4, 1) * clampf(1 - .015 * fuera(cl.hr, D.HR_OK), .7, 1)

# € al día de los aparatos que trabajan (de día H_DIA del tiempo, de noche el resto; un termostato, la mitad de ese tiempo)
static func factura_sala(S: Dictionary) -> int:
	var D := Datos.carga()
	var d := clima_sala(S, false)
	var nc := clima_sala(S, true)
	if not d.n:
		return 0
	var kwh := 0.0
	for k in D.APARATOS:
		if d.uso.get(k) or nc.uso.get(k):
			kwh += D.APARATOS[k].w * D.H_24 * (D.H_DIA * d.uso.get(k, 0) + (1 - D.H_DIA) * nc.uso.get(k, 0)) * .5 / 1000
	return Datos.jsround(kwh * D.KWH)

# riego automático en dos niveles: las garrafas (c.gar[j] litros por plaza, media cosecha; sin el valor, llena) y el goteo
# (c.dep litros, unas cinco cosechas con la carpa llena; sin el campo, lleno; con él, las garrafas no se usan)
static func goteo_l(S: Dictionary, ci: int) -> int:
	var D := Datos.carga()
	var cm: Array = D.CARPAS[S.carpas[ci].t].cm
	return Datos.jsround(D.GOTEO_X * Datos.jsround(cm[0] * cm[2] / 1e4 * D.LITROS_M2))

static func garrafa_l(S: Dictionary, i: int) -> int:
	var D := Datos.carga()
	return Datos.jsround(D.GARRAFA_X * D.MACETAS.get(S.macetas[i], D.MACETAS.plastico7).l)

static func garrafa(S: Dictionary, i: int) -> float:
	var h: Dictionary = huecos(S)[i]
	var g: Array = S.carpas[h.c].get("gar", [])
	var cap := garrafa_l(S, i)
	return minf(cap, g[h.j] if h.j < g.size() and g[h.j] != null else cap)

# litros que quedan y que caben en las garrafas de la carpa
static func garrafas_carpa(S: Dictionary, ci: int) -> Array:
	var a := [0.0, 0]
	var hu := huecos(S)
	for i in hu.size():
		if hu[i].c == ci:
			a = [a[0] + garrafa(S, i), a[1] + garrafa_l(S, i)]
	return a

# la planta que baja del 50 % de agua vuelve al 100 % gastando la mitad de los litros de su maceta por cada 100 %
static func regar_goteo(S: Dictionary, p: Dictionary, i: int) -> void:
	var D := Datos.carga()
	var h: Dictionary = huecos(S)[i]
	var c: Dictionary = S.carpas[h.c]
	if not (c.get("goteo") or c.get("garrafas")) or p.get("dead") or p.water >= 50:
		return
	var l: float = D.MACETAS.get(S.macetas[i], D.MACETAS.plastico7).l * .5 * (100 - p.water) / 100
	var d: float = (c.dep if c.get("dep") != null else float(goteo_l(S, h.c))) if c.get("goteo") else garrafa(S, i)
	if d <= 0:
		return
	var q := 0.0
	if d >= l:
		p.water = 100
		q = Datos.jsround((d - l) * 100) / 100.0
	else:
		p.water += d / l * (100 - p.water)
	if c.get("goteo"):
		c.dep = q
	else:
		if c.get("gar") == null:
			c.gar = []
		if c.gar.size() <= h.j:
			c.gar.resize(h.j + 1)
		c.gar[h.j] = q

static func plant_stage(p: Dictionary) -> int:
	return 4 if p.prog >= 1 else (0 if p.prog < .12 else (1 if p.prog < .35 else (2 if p.prog < .65 else 3)))

static func stage_name(p: Dictionary) -> String:
	return "Germinando" if p.prog < .12 else ("Plántula" if p.prog < .35 else ("Vegetativo" if p.prog < .65 else "Floración"))

static func plant_step(S: Dictionary, p: Dictionary, h: float, f: Dictionary) -> void:
	if p.get("dead"):
		return
	var s = Datos.strain(S, p.sid)
	p.water = maxf(0, p.water - 3.5 * h * f.agua)
	if not p.pest and p.prog < 1 and azar() < .006 * h * (100 - s.r) / 40 * f.plaga:
		p.pest = true
	var g: float = h / (s.d * 24) * f.crec
	if p.water < 20:
		g *= .4
	if p.water <= 0:
		g = 0
	if p.fert:
		g *= 1.1
	if p.prog < 1:
		p.prog = minf(1, p.prog + g)
	if p.water <= 0:
		p.health -= 4 * h
	if p.pest:
		p.health -= 2.5 * h
	if p.water > 30 and not p.pest:
		p.health += h
	var D := Datos.carga()
	if f.get("hr", 0) > D.HR_OK[1] and p.prog >= .65 and p.prog < 1:   # moho: humedad alta en floración (1.10)
		p.health -= h * (f.hr - D.HR_OK[1]) * D.MOHO
	p.health = clampf(p.health, 0, 100)
	if p.health <= 0:
		p.dead = true

static func plants_advance(S: Dictionary, minutos: int) -> void:
	for i in S.pots.size():
		if S.pots[i] != null:
			plant_step(S, S.pots[i], minutos / 60.0, factores(S, i))
			regar_goteo(S, S.pots[i], i)

# ---------- fenotipo: cada planta de semilla tira el suyo al plantar (THC, gramos y % índica) ----------
static func gauss() -> float:
	var u := 0.0
	var v := 0.0
	while u == 0:
		u = azar()
	while v == 0:
		v = azar()
	return sqrt(-2 * log(u)) * cos(2 * PI * v)

static func gen_de(S: Dictionary, sid: String) -> int:
	return int(S.get("gen", {}).get(sid, Datos.carga().GEN_ESTABLE))

static func tipo_gen(S: Dictionary, sid: String) -> String:
	var D := Datos.carga()
	var g := gen_de(S, sid)
	if g < D.GEN_ESTABLE:
		return "F%d" % g
	if D.STRAINS.has(sid):
		return D.STRAINS[sid].tipo
	return "estable"

static func roll_feno(S: Dictionary, sid: String) -> Dictionary:
	S.fenoN += 1
	var G: Dictionary = Datos.carga().GENETICA[tipo_gen(S, sid)]
	var m := func() -> float: return Datos.jsround(clampf(1 + G.sigma * gauss(), .6, 1.5) * 100) / 100.0
	var t: float = m.call()
	var y: float = m.call()
	return {"id": S.fenoN, "t": t, "y": y, "i": Datos.jsround(clampf(Datos.ind_de(S, sid) + G.si * gauss(), 0, 100))}

static func nueva_planta(S: Dictionary, sid: String) -> Dictionary:
	return {"sid": sid, "prog": 0.0, "water": 70.0, "health": 100.0, "fert": false, "pest": false, "f": roll_feno(S, sid)}

# ---------- cosecha ----------
static func clase_feno(f) -> String:
	if not f is Dictionary:
		return "normal"
	var D := Datos.carga()
	return "estrella" if f.t * f.y >= D.FENO_ESTRELLA else ("floja" if f.t * f.y <= D.FENO_FLOJO else "normal")

# ri de 00-nucleo: entero de a a b
static func ri(a: int, b: int) -> int:
	return a + int(floor(azar() * (b - a + 1)))

# harvest sin los diálogos: gramos y THC con el fenotipo; la estrella va a su lote (sid + "*"), con el THC medio ponderado (addBuds).
# Semillas: una línea sin fijar se poliniza entre ella (2-5); las regulares (no son de tienda), 1-3; las feminizadas (de tienda),
# solo si sale una hermafrodita (SEMILLA_HERMA), 1-3. Tira del azar en el mismo orden que el HTML
static func cosecha(S: Dictionary, i: int) -> Dictionary:
	var D := Datos.carga()
	var p: Dictionary = S.pots[i]
	var f := factores(S, i)
	var cl := clase_feno(p.get("f"))
	var g := gramos_planta(S, p, f)
	var thc := thc_cosecha(S, p, f)
	var cria: bool = gen_de(S, p.sid) < D.GEN_ESTABLE
	var fem: bool = p.sid in D.FEM
	var n := 0
	if cria:
		n = ri(2, 5)
	elif not fem or azar() < D.SEMILLA_HERMA:
		n = ri(1, 3)
	var k: String = p.sid + ("*" if cl == "estrella" else "")
	if S.buds.has(k):
		var b: Dictionary = S.buds[k]
		b.thc = (b.thc * b.g + thc * g) / (b.g + g)
		b.g += g
	else:
		S.buds[k] = {"g": g, "thc": thc}
	if n:
		S.seeds[p.sid] = int(S.seeds.get(p.sid, 0)) + n
	if p.get("f") is Dictionary and p.f.get("id"):
		S.fenos[str(int(p.f.id))] = cl
	S.pots[i] = null
	return {"k": k, "g": g, "thc": thc, "n": n, "cl": cl, "cria": cria, "fem": fem}
static func gramos_planta(S: Dictionary, p: Dictionary, f: Dictionary) -> int:
	var s = Datos.strain(S, p.sid)
	var fe: Dictionary = p.f if p.get("f") is Dictionary else {"y": 1}
	return maxi(1, Datos.jsround(minf(f.cap, f.g * s.y / Datos.carga().Y_MEDIA * (.4 + .6 * p.health / 100) * (1.25 if p.fert else 1.0) * fe.y)))

static func thc_cosecha(S: Dictionary, p: Dictionary, f: Dictionary) -> float:
	var s = Datos.strain(S, p.sid)
	var fe: Dictionary = p.f if p.get("f") is Dictionary else {"t": 1}
	return minf(35, Datos.jsround((s.thc * fe.t * (.85 + .15 * p.health / 100) + f.thc + (.3 if p.fert else 0.0)) * 10) / 10.0)

static func plantas_vivas(S: Dictionary, ci: int) -> bool:
	var H := huecos(S)
	for i in H.size():
		if H[i].c == ci and i < S.pots.size() and S.pots[i] != null and not S.pots[i].get("dead"):   # (como en JS, una plaza sin entrada en S.pots está vacía)
			return true
	return false

# € de luz al día de la carpa ci con plantas (foco H_LUZ horas; extras, día y noche)
static func luz_carpa(S: Dictionary, ci: int) -> int:
	var D := Datos.carga()
	var c: Dictionary = S.carpas[ci]
	var x := 0.0
	for k in D.EXTRAS:
		if c.get(k):
			x += D.EXTRAS[k].w
	return Datos.jsround((D.FOCOS[c.foco].w * D.H_LUZ + x * D.H_24) / 1000 * D.KWH)

# lo que se duerme en la cama (bedAction): 0, hasta las 7 (si ya son las 7, un día entero); 1, siesta de 3 h
static func minutos_cama(S: Dictionary, c: int) -> int:
	if c == 1:
		return 180
	var m := (7 * 60 - int(S.min) + 1440) % 1440
	return m if m else 1440

# el tiempo: de 60 en 60 min, como advanceTime; al pasar de las 24 h, un día nuevo con su factura de la luz
static func avanza(S: Dictionary, minutos: int) -> int:
	var luz := 0
	while minutos > 0:
		var st := mini(60, minutos)
		minutos -= st
		S.min += st
		plants_advance(S, st)
		if S.min >= 1440:
			S.min -= 1440
			S.day += 1
			var e := 0
			for ci in S.carpas.size():
				if S.carpas[ci] and plantas_vivas(S, ci):
					e += luz_carpa(S, ci)
			e += factura_sala(S)
			S.money = maxi(0, S.money - e)
			luz += e
	return luz
