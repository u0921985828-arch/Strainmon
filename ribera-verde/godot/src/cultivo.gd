# Ribera Verde (Godot) — el cultivo de 09-cultivo.js: plazas, factores de la carpa, crecimiento hora a hora, fenotipo al
# plantar, gramos y THC de cosecha. S es el estado de la partida (como el S del HTML: carpas, macetas, pots…)
extends RefCounted

const Datos = preload("res://src/datos.gd")

# azar: el de Godot o, para las pruebas, el Park-Miller del oráculo (tools/godot.js), que sustituye a Math.random
static var pm := -1
static func azar() -> float:
	if pm < 0:
		return randf()
	pm = pm * 48271 % 2147483647
	return float(pm) / 2147483647.0

static func nuevo_estado() -> Dictionary:
	return {"day": 1, "min": 8 * 60, "money": 150, "carpas": [{"t": "m100", "foco": "sodio400"}], "macetas": ["plastico7", "plastico7", "plastico7", "plastico7"],
		"pots": [null, null, null, null], "seeds": {"ria": 2, "limon": 1, "txoko": 1, "niebla": 1}, "items": {"fert": 2, "insect": 3},
		"buds": {}, "custom": {}, "gen": {}, "fenos": {}, "fenoN": 0}

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
	return {"g": F.w * F.gpw / C.plazas * M.rend, "cap": M.cap, "crec": F.crec * (.85 + .15 * dens) * M.crec, "thc": F.thc * dens,
		"agua": F.agua * M.agua * (.5 if c.get("goteo") else 1.0), "plaga": M.plaga * (.7 if c.get("vent") else 1.0), "dens": dens}

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
	p.health = clampf(p.health, 0, 100)
	if p.health <= 0:
		p.dead = true

static func plants_advance(S: Dictionary, minutos: int) -> void:
	for i in S.pots.size():
		if S.pots[i] != null:
			plant_step(S, S.pots[i], minutos / 60.0, factores(S, i))

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
		if H[i].c == ci and S.pots[i] != null and not S.pots[i].get("dead"):
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
			S.money = maxi(0, S.money - e)
			luz += e
	return luz
