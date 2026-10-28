# La sala de cultivo de KAIA (lo pidió el usuario: «incluso molaría tener un cultivo finalmente en la nueva asociación de KAIA» y,
# de las carpas, «tiene que tener lógica con el suelo que hay al rededor y las zonas donde las colocas»; solo con Datos.CAL): por la
# puerta (15, 1) del club, cerrada hasta tener la licencia (S.mar.lic). Tres carpas de 120 × 120 con su LED, cuatro plazas cada una,
# con el riego por goteo y el clima de la sala, que van solos (kc_avanza desde plants_advance); A en una carpa, sus plazas, y en cada
# una lo de siempre (pot_action con hu, como la huerta de campo.gd). Las carpas se ordenan desde el cuadro de la pared (ctrlN), solo
# encima de la zona de cultivo (la regla zona de cabe_pieza). Datos de tools/kaia_cult.py (KAIA_CULT, MAPS["cult-muelle"]).
# S.kc = {p: [plantas o null, carpa × plazas]}.
# Cadena: … → hilo → bancotia → kaiacult → retencion → juego.
extends "res://src/bancotia.gd"

func kc() -> Dictionary:
	if not (S.get("kc") is Dictionary):
		S.kc = {"p": []}
	var n: int = D.KAIA_CULT.carpas.size() * int(D.KAIA_CULT.plazas)
	while S.kc.p.size() < n:
		S.kc.p.append(null)
	return S.kc

func kc_hay() -> bool:
	return Datos.CAL and S != null and D.has("KAIA_CULT")

func kc_lic() -> bool:
	return kc_hay() and S.get("mar") is Dictionary and S.mar.get("lic") != null

# la puerta de la sala, desde KAIA (calle.gd object_action): sin la licencia, cerrada
func kc_cerrada() -> bool:
	if kc_lic():
		return false
	await say(K("La sala de cultivo de KAIA, cerrada. Hasta tener la licencia de cultivo, aquí dentro no se planta nada."))
	return true

# los factores de una plaza, como Cultivo.factores con la carpa, el foco y la maceta de la sala, y su clima controlado
func kc_f() -> Dictionary:
	var KC: Dictionary = D.KAIA_CULT
	var C: Dictionary = D.CARPAS[KC.carpa]
	var F: Dictionary = D.FOCOS[KC.foco]
	var M: Dictionary = D.MACETAS[KC.maceta]
	var dens := minf(1, float(F.w) / (float(C.cm[0]) * float(C.cm[2]) / 1e4 * float(D.W_M2)))
	return {"g": float(F.w) * float(F.gpw) / float(KC.plazas) * float(M.rend), "cap": float(M.cap), "crec": float(F.crec) * (.85 + .15 * dens) * float(M.crec) * Cultivo.f_clima(KC.clima),
		"thc": float(F.thc) * dens, "agua": float(F.agua) * float(M.agua), "plaga": float(M.plaga), "dens": dens, "hr": float(KC.clima.hr), "moho": 1.0, "ciclo": "auto"}   # i18n-no

func kc_pos(ci: int) -> Array:
	return pos_pieza(D.KAIA_CULT.mapa, "kc%d" % ci)

func kc_hu(i: int) -> Dictionary:
	var p := kc_pos(i / int(D.KAIA_CULT.plazas))
	return {"l": kc().p, "v": [(int(p[0]) + 1) * 16, int(p[1]) * 16], "f": kc_f()}

func kc_carpa_en(x: int, y: int) -> int:   # la carpa con la casilla (x, y), o -1
	for ci in D.KAIA_CULT.carpas.size():
		var p := kc_pos(ci)
		if y == int(p[1]) and (x == int(p[0]) or x == int(p[0]) + 1):
			return ci
	return -1

func kc_plantadas(ci: int) -> int:
	var n := 0
	var np: int = int(D.KAIA_CULT.plazas)
	for j in np:
		if kc().p[ci * np + j] is Dictionary:
			n += 1
	return n

# cada carpa con las plantas que tiene (carpaM-<n>, la de las madres de la nave)
func sprite_local(o: String) -> String:
	if kc_hay() and o.begins_with("carpaK"):   # i18n-no
		return "carpaM-%d" % kc_plantadas(int(o.substr(6)))   # i18n-no
	return super(o)

func bt_entra(mapa: String) -> void:
	super(mapa)
	if kc_hay() and mapa == D.KAIA_CULT.mapa:
		kc()
		aplica_orden(mapa)

# después de mover una carpa con ORDENAR (setas.gd mover_pieza), la sala con cada una donde se dejó
func rehace_orden(mapa: String) -> void:
	super(mapa)
	if kc_hay() and mapa == D.KAIA_CULT.mapa:
		aplica_orden(mapa)

func bt_obj(x: int, y: int, o) -> bool:
	if kc_hay() and S.map == D.KAIA_CULT.mapa:
		return await kc_obj(x, y, o)
	return await super(x, y, o)

func kc_obj(x: int, y: int, o) -> bool:
	var ci := kc_carpa_en(x, y)
	if ci >= 0:
		await kc_carpa(ci)
		return true
	match o:
		"ctrlN":   # i18n-no
			var c: int = await ask(K("El cuadro de la sala: el temporizador de los LED, la bomba del goteo y el clima. Todo en automático: muchas horas de luz mientras crecen y menos en cuanto toca florecer."), [K("Ordenar la sala"), K("Salir")])
			if c == 0:
				await ordenar(S.map)
			return true
		"tanqueN":   # i18n-no
			await say(K("El depósito del goteo, con el abono ya mezclado. La bomba lo lleva a cada maceta cuando la tierra se seca."))
			return true
		"riegoN":   # i18n-no
			await say(K("La bomba y el programador del riego por goteo: un gotero por maceta, a la tierra y no a las hojas."))
			return true
		"extrN", "filtroN":   # i18n-no
			await say(K("La extracción, con sus filtros de carbón: el aire de la sala sale limpio y sin olor, como pide la licencia."))
			return true
	return false

# las plazas de una carpa: cada una, con su planta o vacía; A, lo de siempre (pot_action)
func kc_carpa(ci: int) -> void:
	if not kc_lic():
		await say(K("Sin la licencia de cultivo, las carpas se quedan vacías."))
		return
	var np: int = int(D.KAIA_CULT.plazas)
	var it := []
	for j in np:
		var p = kc().p[ci * np + j]
		if p is Dictionary:
			it.append({"label": T("Plaza {n}", {"n": j + 1}), "right": strain(p.sid).n, "desc": T("{st} {p}% · Agua {w}% · Salud {h}%", {"st": stage_name(p), "p": int(floor(float(p.prog) * 100)), "w": Datos.jsround(p.water), "h": Datos.jsround(p.health)})})
		else:
			it.append({"label": T("Plaza {n}", {"n": j + 1}), "right": K("vacía"), "desc": K("Una maceta de tela con su gotero.")})
	it.append({"label": K("Salir"), "desc": ""})
	var i: int = await menu(it, {"cls": "full", "title": T("LA CARPA {n}", {"n": ci + 1}), "desc": true})
	if i < 0 or i >= np:
		return
	await pot_action(ci * np + i, kc_hu(ci * np + i))

func plants_advance(mn: int) -> void:
	super(mn)
	kc_avanza(mn)

# cada rato crecen con su carpa; el goteo las deja regadas
func kc_avanza(mn: int) -> void:
	if not kc_hay() or not (S.get("kc") is Dictionary):
		return
	var f := kc_f()
	for p in S.kc.p:
		if not (p is Dictionary) or p.get("dead"):
			continue
		Cultivo.plant_step(S, p, mn / 60.0, f)
		p.water = 100.0
