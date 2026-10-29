# La sala fría del sótano (lo pidió el usuario: una habitación fría para las extracciones, «en el sótano del piso», con las máquinas
# allí y que rindan más; solo con Datos.CAL): por la puerta (3, 1) del sótano, cerrada hasta la obra (FRIA: paneles, equipo de frío a
# 4 °C y mesa de acero; tienda online, con la tarjeta, al día siguiente). Con la obra hecha, las máquinas de extracción que tengas
# (MUEBLE_EXTR) dejan el piso y se montan aquí, en fila contra la pared (FRIA.pos), y lo que se saca aquí rinde FRIA.rend más.
# En Google Play, donde el sótano no se vende para setas, la obra lo habilita también (FRIA.p_play).
# S.fria = {d: el día en que acaban}. Datos de tools/sala_fria.py. Cadena: … → bancotia → kaiacult → salafria → acto2 → caza → copaot → retencion → juego.
extends "res://src/kaiacult.gd"

var _fria_t := ""   # la extracción que se está haciendo en la sala fría (para sale_extr)

func fria_hay() -> bool:
	return Datos.CAL and S != null and D.has("FRIA")

func fria_ya() -> bool:
	return fria_hay() and S.get("fria") is Dictionary and int(S.fria.get("d", 1 << 30)) <= int(S.day)

# en la tienda online: después del sótano (en Play, desde su capítulo, con el sótano incluido)
func fria_venta() -> bool:
	if not fria_hay() or int(S.ch) < int(D.FRIA.ch):
		return false
	return Datos.PLAY or sot_ya() or S.get("fria") is Dictionary

func fria_precio() -> int:
	return int(D.FRIA.p_play) if Datos.PLAY and not sot_ya() else int(D.FRIA.p)

func fria_item() -> Dictionary:
	var F: Dictionary = D.FRIA
	var d = S.fria.get("d") if S.get("fria") is Dictionary else null
	var l := []
	for x in F.l:
		l.append(I18n.v(x[0]))
	var ds := T("La sala de al lado del sótano, a {t} °C: {l}. Las máquinas de extracción bajan allí y rinden más en frío.", {"t": int(F.t), "l": "; ".join(PackedStringArray(l))})
	if Datos.PLAY and not sot_ya() and d == null:
		ds += " " + K("Con la obra, también se habilita el sótano: sin trastos, con luz y desagüe.")
	return {"label": I18n.v(String(F.n)) + (T(" · hecho") if d != null and int(d) <= int(S.day) else T(" · mañana") if d != null else ""), "right": Datos.eur(fria_precio()), "disabled": d != null, "desc": ds, "fria": 1}

func fria_tienda() -> void:
	if S.get("fria") is Dictionary:
		return
	var p := fria_precio()
	if not await tarjeta(float(p), K("Tienda online") + " · " + I18n.v(String(D.FRIA.n))):
		return
	S.fria = {"d": int(S.day) + 1}
	if Datos.PLAY and not (S.get("sot") is Dictionary):   # en Play, el sótano va con la obra
		S.sot = {"d": int(S.day) + 1, "bandejas": [], "g": 0, "fr": []}
	sfx("coin")
	toast(T("Pedido: {n} · los obreros vienen mañana", {"n": I18n.v(String(D.FRIA.n))}), 1400)

func llega_mueble() -> void:
	super()
	if fria_hay() and S.get("fria") is Dictionary and int(S.fria.get("d", -1)) == int(S.day):
		var L := [K("Los obreros acaban la sala fría del sótano: paneles aislantes, el equipo de frío a 4 °C y la mesa de acero. Las máquinas de extracción ya están abajo, en su sitio.")]
		queue("fria", func():
			sfx("get")
			await say(L[0]), [["", L]])

# la puerta del sótano: sin la obra, cerrada
func fria_cerrada() -> bool:
	if fria_ya():
		return false
	await say(K("El cuarto de al lado del sótano: frío y vacío. Con una obra (MÓVIL → Tienda online) sería la sala fría de las extracciones.") if not (S.get("fria") is Dictionary) else K("La sala fría, a medio hacer: mañana acaban los obreros."))
	return true

# con la sala fría, las máquinas no se montan en el piso (ORDENAR LA CASA tampoco las ofrece)
func pieza_ya(P_: Dictionary) -> bool:
	if str(P_.get("si", "")) == "extr" and fria_ya():
		return false
	return super(P_)

func bt_entra(mapa: String) -> void:
	super(mapa)
	if fria_hay() and mapa == String(D.FRIA.mapa) and MAPS.has(mapa):
		var m: Dictionary = MAPS[mapa]
		for k in D.FRIA.pos:
			var q: Array = D.FRIA.pos[k]
			m.o[int(q[1])][int(q[0])] = k if mueble_ya(D.MUEBLE_EXTR[k]) else null

func bt_obj(x: int, y: int, o) -> bool:
	if fria_hay() and S.map == String(D.FRIA.mapa) and o is String:
		if D.MUEBLE_EXTR.has(o):
			await mueble_extr(o)
			return true
		match o:
			"frioF":   # i18n-no
				await say(T("El evaporador del equipo de frío: {t} °C, sin escarcha. En frío los tricomas se quiebran y se sueltan mejor: el hielo, el tamiz, la lavadora y la static rinden más, y la prensa saca un rosin más limpio.", {"t": int(D.FRIA.t)}))
				return true
			"mesaF":   # i18n-no
				await say(K("La mesa de acero inoxidable: aquí se enfría el material antes de cada extracción y se recoge lo que sale."))
				return true
	if fria_hay() and Datos.PLAY and S.map == "sotano" and o is String and o in ["baldaS", "humidS", "secaS", "deshidS", "armS", "tuboS", "cuboS", "mesaS"]:   # en Play, el sótano sin setas · i18n-no
		await say(K("Estanterías de rejilla y trastos del sótano. La sala fría, por la puerta de la pared."))
		return true
	return await super(x, y, o)

# con la sala fría, las máquinas están abajo: fuera de ella (la mesa de la tía), solo lo que se hace a mano (el charas)
func extr_ya() -> Array:
	var L := super()
	if not fria_ya() or S.map == String(D.FRIA.mapa):
		return L
	var abajo := []
	for k in D.MUEBLE_EXTR:
		abajo.append_array(D.MUEBLE_EXTR[k].t)
	return L.filter(func(t): return not (t in abajo))

# lo que se saca en la sala fría: el rendimiento de su tipo (FRIA.rend)
func extraer(t: String):
	_fria_t = t if fria_ya() and S.map == String(D.FRIA.mapa) else ""
	await super(t)
	_fria_t = ""

func sale_extr(E: Dictionary, g: float, q: float) -> float:
	var r := super(E, g, q)
	if _fria_t != "" and fria_hay():
		r = Datos.jsround(r * float(D.FRIA.rend.get(_fria_t, 1.0)) * 10) / 10.0
	return r
