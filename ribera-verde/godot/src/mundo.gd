# Ribera Verde (Godot) — 04-mapas, 08-mundo y 10-calle: el estado S, los mapas, el jugador y los personajes, moverse, hablar y
# coger cosas, y los clientes de la calle. Igual que el HTML: los guiones son corrutinas lanzadas con run() (lock), los eventos
# de historia esperan en pending (queue) a que el mundo quede libre y todo el azar pasa por Cultivo.azar() (Math.random).
extends "res://src/ui.gd"

const TS := 16

const DV := {"up": [0, -1], "down": [0, 1], "left": [-1, 0], "right": [1, 0]}

const OPP := {"up": "down", "down": "up", "left": "right", "right": "left"}

const COUNTERS := ["counter", "barcounter", "btable", "vitrina", "barraD", "cabina", "cabina2", "mesaK", "mesaK2", "barraN", "barraN2", "mostrN", "mostrN2", "mostrE", "mostrE2", "barraTb", "barraTb2"]   # i18n-no · 1.30: la vitrina del dispensario, la barra y la cabina del DJ; 1.43: la mesa del concesionario

const SILLAS := ["silla", "sillaG", "sillaG2"]   # i18n-no · 1.27.1: delante de un ordenador; con A, el ordenador de encima (delante)

var SOLID_G := RegEx.create_from_string("^(water|roof|wall|win|iwT|iwB|void)")

var lock := 0

var ents: Array = []

var B = null

var time_acc := 0.0

var hud_t := 0.0

var hud_visto = ""   # lo último que enseñó la barra de sospecha (sosp_hud)

var pending: Array = []

var queued := {}

var MAPS := {}

var P := {"x": 0, "y": 0, "px": 0.0, "py": 0.0, "dir": "down", "moving": false, "fx": 0, "fy": 0, "t": 0.0, "dur": 240.0, "parity": 0,
	"hold": 0.0, "chain": false, "bumpT": -1e9, "act": null, "pisT": 0.0}

var vfx: Array = []    # efectos en marcha (01b-arte lanzarVfx): {id, x, y, t0, capa, sube}

func _ready() -> void:
	super()
	MAPS = D.MAPS.duplicate(true)
	Datos.enteros(MAPS)
	mapa_nave_r()

# ---------- utilidades (00-nucleo) ----------
static func mayus(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)

static func n(x) -> String:
	return Datos.js_num(x)

func pick(a: Array):
	return a[int(floor(Cultivo.azar() * a.size()))]

func ri(a: int, b: int) -> int:
	return Cultivo.ri(a, b)

func strain(sid: String):
	return Datos.strain(S, sid)

func ic_cog(sid: String):
	return null if oraculo else Atlas.icono_cogollo(S, sid)

func icono(k: String):
	return null if oraculo else Atlas.icono(k)

# ---------- estado ----------
func new_state() -> Dictionary:
	return Datos.enteros(D.NEW_STATE.duplicate(true))

func is_free() -> bool:
	return mode == "world" and lock == 0 and handlers.is_empty()

func is_night() -> bool:
	return S.min >= 21 * 60 or S.min < 6 * 60

func run(fn: Callable) -> void:
	lock += 1
	await fn.call()
	lock -= 1
	if lock == 0 and get("relanza"):   # E10: la partida importada, con los menús ya cerrados
		call("relanzar")
	if lock == 0 and S and S.has("misiones"):   # 1.11: las misiones guiadas, al acabar cada guion (trama.gd)
		revisa_misiones()

# av (E7, fase 3): lo que dice el aviso, [[quien, [líneas]], …] (quien "": say), para guardarlo con la partida (cola_guardar)
func queue(key: String, fn: Callable, av := []) -> void:
	if queued.has(key):
		return
	queued[key] = av if av.size() else true
	pending.append(func():
		cola_ya[key] = true
		await fn.call()
		cola_ya.erase(key)
		queued.erase(key))

var cola_ya := {}   # los avisos que ya están saliendo (no se guardan)

# los avisos que se rehacen al cargar con su función (los de la policía y el plazo vencido los rehace enter_game)
func cola_deriva() -> Dictionary:
	# por nombre: aviso_mision y los demás están en trama.gd
	var o := {}
	var f := {"plazo": "recuerdo_plazo", "calor": "heat_warn", "historia": "check_story", "mision": "aviso_mision", "logro": "aviso_logro", "itin": "aviso_itin"}
	for k in f:
		o[k] = Callable(self, f[k])
	return o

func cola_guardar() -> Array:
	var o := []
	var dv := cola_deriva()
	for k in queued:
		if cola_ya.has(k):
			continue
		if queued[k] is Array:
			o.append({"k": k, "av": queued[k]})
		elif dv.has(k):
			o.append({"k": k})
	return o

func cola_cargar() -> void:
	var c = S.get("_cola")
	S.erase("_cola")
	if not c is Array:
		return
	var dv := cola_deriva()
	for e in c:
		if not e is Dictionary or not e.get("k") is String:
			continue
		var av = e.get("av")
		if av is Array and av.size():
			queue(e.k, func():
				for x in av:
					if x is Array and x.size() == 2 and x[1] is Array:
						if x[0] == "":
							for l in x[1]:
								await say(str(l))
						else:
							await talk(str(x[0]), x[1]), av)
		elif dv.has(e.k):
			queue(e.k, dv[e.k])

func total_buds() -> float:
	var t := 0.0
	for k in S.buds:
		t += S.buds[k].g
	return t

func disc_count() -> int:
	return S.disc.size()

# variedades de receta (RECIPES) sacadas en la mesa (S.rec[sid] = 1) y ya cosechadas (2): el capítulo 4 pide 2 (1.10)
func rec_count() -> int:
	var nn := 0
	for k in S.rec:
		if S.rec[k] == 2:
			nn += 1
	return nn

# la caja fuerte (1.10, 11b-caja): lo de dentro no va encima
func caja_g() -> float:
	var t := 0.0
	if S.get("caja"):
		for k in S.caja.buds:
			t += S.caja.buds[k].g
	return t

# lo que llevas encima (cogollos y extractos) y su tope, la mochila (1.10, 09c-sala); lo que no cabe, a la caja fuerte (1.36: sin arcón)
# la mejor bolsa que tienes o que ya has pedido a Kiko (no se vende otra igual o peor)
func bolsa_ya() -> int:
	var b := int(S.items.get("bolsa", 0))
	for l in S.envio:
		for x in D.SHOP:
			if x.lbl == l:
				b = maxi(b, int(x.get("bolsa", 0)))
	return b

func peso_encima() -> float:
	return total_buds() + total_rosin()

func cap_mochila() -> float:   # MAESTRO [1]: el protagonista, un 15 % más de carga
	return D.MOCHILAS[int(S.items.get("bolsa", 0))].g

func libre_mochila() -> float:
	return maxf(0, cap_mochila() - peso_encima())

# la agenda del móvil (1.10, 12b-movil): el cliente que te compra te da su número
# la confianza (1.15, 11e-gente): 0-100 con cada persona con nombre; +1 al hablar el primer día
func rel(id: String) -> int:
	return int(S.rel.get(id, 0))

func confia(id: String, d: int) -> void:
	S.rel[id] = clampi(rel(id) + d, 0, int(D.REL.max))

func rel_nivel(id: String) -> String:
	return "socio" if rel(id) >= D.REL.socio else ("amigo" if rel(id) >= D.REL.amigo else "conocido")

func saludo(id: String) -> void:
	if S.relDia.get(id) == S.day:
		return
	S.relDia[id] = S.day
	confia(id, int(D.REL.charla))

# de quién es la confianza que suma hablar con alguien (relDe, 11j-locales; 1.30): el club del encargado, del socio y del del
# billar; GAUA, la de su gente; los de la nave, ninguna (son de tu plantilla)
func rel_de(id: String):
	if id.begins_with("club_"):
		return id.substr(5)
	if id == "socio" or id == "billarista" or (id.length() == 3 and id.begins_with("cg") and id[2].is_valid_int()):   # 1.34: los demás socios
		return S.map.substr(5)
	if id == "darko2":
		return "darko"
	if id in ["gorila", "camarera", "dj", "rrpp", "gentD1", "gentD2", "gentD3"] or (id.length() == 6 and id.begins_with("baila") and id[5].is_valid_int()):   # i18n-no
		return "gaua"
	if id.length() == 3 and id.begins_with("nv") and (id[2].is_valid_int() or id[2] == "m"):   # 1.34: y el de las madres
		return null
	return id

func nombre_fijo(id: String) -> String:
	var a := 0
	for i in id.length():
		a = (a * 31 + id.unicode_at(i)) % 9973
	var L: Array = D.NOMBRES_FIJO
	if Datos.CAL and not id.begins_with("gaua"):   # 1.43.3: del mismo sexo que el muñeco del cliente
		var m := mujer_look({"id": "n" + id})
		L = L.filter(func(x): return mujer_nombre(x) == m)
	return L[a % L.size()]

# (GENERO): el muñeco de un look (como Atlas.grupo_look: los de la calle, por su hash) y si es de chica
func sprite_look(look) -> String:
	if not look:
		return ""
	var id := str(look.id)
	if id.length() > 1 and not _sprites_look().has(id):
		if id[0] == "n":
			return "cliente" + str(1 + Datos.hash_str(id) % 6)
		if id[0] == "t":
			return "ladron" + str(1 + Datos.hash_str(id) % 3)
	return id

var _spr_look := {}

func _sprites_look() -> Dictionary:
	if _spr_look.is_empty():
		for k in D.LOOKS:
			if D.LOOKS[k] is Dictionary and D.LOOKS[k].has("id"):
				_spr_look[str(D.LOOKS[k].id)] = 1
	return _spr_look

func mujer_look(look) -> bool:
	return D.GENERO.mujeres.has(sprite_look(look))

# MAESTRO [8]: el retrato de quien habla (ui.gd, _pon_retrato): [look, mujer] por su nombre (NPCDEF y LOOKS; «SMS · X», «DON X»),
# si no, el de la persona con la que hablas en vivo (habla_look) y, si es un nombre de persona sin muñeco (Koldo, Gorka…), uno
# propio por su nombre; lo que no es una persona (CARTA, BANCO…), sin retrato
const NO_PERSONA := ["carta", "gente", "banco", "ayuntamiento", "taller", "kaia", "aseguradora", "autobuses de la comarca", "notas de la tia", "el olor", "movil", "nave"]   # i18n-no
var _looks_n := {}

static func _llano(t: String) -> String:
	var r := t.to_lower().strip_edges()
	for q in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ñ", "n"], ["ü", "u"]]:
		r = r.replace(q[0], q[1])
	return r

func retrato_de(n: String):
	if S == null:
		return null
	var k := _llano(n.trim_prefix("SMS · ").trim_prefix("SMS: "))
	if k.begins_with("don "):
		k = k.substr(4)
	if k == "" or k in NO_PERSONA:
		return null
	if habla_look is Dictionary and k in etiquetas_ct():   # el cliente con el que hablas (TURISTA, PIJO…): su muñeco, no el NPC turista
		return [habla_look, mujer_look(habla_look)]
	if B is Dictionary and B.get("kind") in ["thief", "police"] and B.get("look") is Dictionary and _llano(str(B.get("name", ""))) == k:
		return [B.look, mujer_look(B.look)]   # el ladrón de la pelea, con su capucha, y el agente (no un cliente al azar)
	if _looks_n.is_empty():
		for d in D.NPCDEF:
			if d.get("look") is String and not _looks_n.has(_llano(str(d.id))):
				_looks_n[_llano(str(d.id))] = d.look
		_looks_n["agente"] = "cop"
	var L = null
	var lk := ""
	if _looks_n.has(k) and D.LOOKS.has(_looks_n[k]):
		lk = _looks_n[k]
	elif D.LOOKS.has(k):
		lk = k
	if lk != "":
		L = D.LOOKS[lk]
		if Datos.CAL and D.GENERO.look.has(lk):   # el mismo muñeco que en el mapa (mk_ent)
			L = L.duplicate()
			L.id = D.GENERO.look[lk]
	elif S.get("name") and _llano(str(S.name)) == k:
		L = D.LOOKS.player
		if es_chica():   # la protagonista, la suya (player-f)
			L = L.duplicate()
			L.id = "player-f"
	else:
		for z in D.RIVALES:   # los rivales, con el muñeco de su pelea (look_rival)
			if _llano(str(D.RIVALES[z].n)) == k:
				L = look_rival(D.RIVALES[z])
	if L is Dictionary:
		return [L, mujer_look(L)]
	if habla_look is Dictionary:
		return [habla_look, mujer_look(habla_look)]
	if " " in k or k.length() < 3:
		return null
	return [Datos.rand_look("ret" + k, "client"), mujer_nombre(k)]

var _etq_ct := []
func etiquetas_ct() -> Array:
	if _etq_ct.is_empty():
		for t in D.CTYPES:
			_etq_ct.append(_llano(str(D.CTYPES[t].label)))
			_etq_ct.append(_llano(Datos.tp(str(D.CTYPES[t].label))))
		for t in D.GENERO.ctM:
			_etq_ct.append(_llano(str(D.GENERO.ctM[t])))
			_etq_ct.append(_llano(Datos.tp(str(D.GENERO.ctM[t]))))
	return _etq_ct

# PIJA, CATADORA: la etiqueta del tipo de cliente, en femenino si es una chica (1.43.3)
func etiqueta_ct(t: String, m: bool) -> String:
	return D.GENERO.ctM.get(t, D.CTYPES[t].label) if m and Datos.CAL else D.CTYPES[t].label

func mujer_nombre(n: String) -> bool:
	return D.GENERO.nombresM.has(n.capitalize()) or D.GENERO.nombresM.has(n)

# el look de una persona con nombre n: si el muñeco no es de su sexo, otro de la lista (lH / lM) por el índice i
func look_genero(look, n: String, i: int, lH: Array, lM: Array):
	if not Datos.CAL or not look or mujer_look(look) == mujer_nombre(n):
		return look
	var o: Dictionary = look.duplicate()
	o.id = (lM if mujer_nombre(n) else lH)[i % (lM if mujer_nombre(n) else lH).size()]
	return o

func apunta_fijo(c: Dictionary) -> void:
	if c.get("fijo") or S.fijos.size() >= D.FIJOS_MAX:
		return
	for f in S.fijos:
		if f.id == c.id:
			return
	S.fijos.append({"id": c.id, "n": nombre_fijo(c.id), "t": c.type, "dia": 0})

func caja_e() -> float:
	return S.caja.money if S.get("caja") else 0

# pagar desde el piso: primero lo de fuera y después la caja. Devuelve lo que falta
func pagar_casa(e: float) -> float:
	var a: float = minf(S.money, e)
	S.money -= a
	e -= a
	if e > 0 and S.get("caja"):
		var b: float = minf(S.caja.money, e)
		S.caja.money -= b
		e -= b
	return e

# g gramos del lote k de «de» a «a»: si el lote ya está, se juntan con el THC medio por gramos (1.29: con su curado y su día)
func mover_lote(de: Dictionary, a: Dictionary, k: String, g: float) -> void:
	var b: Dictionary = de[k]
	if a.has(k):
		junta_lote(a[k], g, b.thc, b.get("cu", 0), b.get("dia"), b.get("mc", 0), b.get("af", 0))
	else:
		a[k] = {"g": g, "thc": b.thc}
		a[k].merge(cura_de(b))
	b.g -= g
	if b.g < .5:
		de.erase(k)

# lo mismo con el rosin, al décimo de gramo (como add_rosin y use_rosin)
func mover_rosin(de: Dictionary, a: Dictionary, k: String, g: float) -> void:
	var b: Dictionary = de[k]
	if a.has(k):
		var t: Dictionary = a[k]
		var c: float = (float(t.get("cu", 0)) * t.g + float(b.get("cu", 0)) * g) / (t.g + g)   # 1.36: con lo curado en la nevera
		t.thc = (t.thc * t.g + b.thc * g) / (t.g + g)
		t.g = Datos.jsround((t.g + g) * 10) / 10.0
		if c:
			t.cu = c
		else:
			t.erase("cu")
	else:
		a[k] = {"g": g, "thc": b.thc}
		if b.get("cu"):
			a[k].cu = b.cu
	b.g = Datos.jsround((b.g - g) * 10) / 10.0
	if b.g < .1:
		de.erase(k)

func gm2(s) -> int:
	return Datos.jsround(D.W_M2 * .85 * 1.25 * s.y / D.Y_MEDIA / 10) * 10

func linea_ind(k: String) -> String:
	var s = strain(k)
	var i := Datos.ind_de(S, k)
	return T("Índica {i} % · sativa {s} % · {m} % madre · {p} % padre", {"i": n(i), "s": n(100 - i), "m": n(s.m), "p": n(100 - s.m)}) if s.get("m") else T("Índica {i} % · sativa {s} %", {"i": n(i), "s": n(100 - i)})

func strain_line(k: String) -> String:
	var s = strain(k)
	var G: Dictionary = D.GENETICA[Cultivo.tipo_gen(S, k)]
	var pa = D.PADRES.get(k)
	return T("THC {thc}% · ~{gm} g/m² · {d} días · Resist. {r}%\n{ind}\n{gn}{pa}: {gd}. Estrella: 1 de cada ~{uno}.\n{o}", {"thc": Datos.pct(s.thc), "gm": gm2(s), "d": Datos.coma(s.d), "r": n(s.r),
		"ind": linea_ind(k), "gn": G.n, "pa": (" (" + pa + ")") if pa else "", "gd": G.d, "uno": Datos.miles(G.uno), "o": T("{g}.ª generación · {o}", {"g": int(s.gen), "o": s.o}) if s.get("gen") else s.o})

func discover(sid: String) -> void:
	if not S.disc.get(sid):
		S.disc[sid] = true
		var cu := ""   # 1.25: cuántas de la Genoteca llevas
		if D.STRAINS.has(sid):
			cu = " · %d/%d" % [D.DEX.filter(func(k): return S.disc.get(k)).size(), D.DEX.size()]
		toast((T("<small>NUEVA EN LA CANNADEX{cu}</small>", {"cu": cu}) if Datos.CAL else T("<small>NUEVA EN LA GENOTECA{cu}</small>", {"cu": cu})) + esc(strain(sid).n))
		queue("historia", check_story)

func add_seeds(sid: String, k: int) -> void:
	S.seeds[sid] = S.seeds.get(sid, 0) + k
	discover(sid)

func lot_sid(k: String) -> String:
	return k.get_slice("~", 0).trim_suffix("!").trim_suffix("*")   # 1.35: «~tipo», las extracciones; «!», la rara (MAESTRO [5])

func lot_nombre(k: String) -> String:
	return strain(lot_sid(k)).n + (" ★" if k.contains("*") else "") + (T(" (rara)") if k.get_slice("~", 0).ends_with("!") else "")

# L: otro sitio (la caja fuerte); cu y dia: el curado y el día de la cosecha (1.29; sin dar dia, hoy; dia null, sin día, como los de antes)
func add_buds(k: String, g: float, thc: float, L = null, cu = 0, dia = -1, mc = 0) -> void:
	if L == null:
		L = S.buds
	if dia != null and float(dia) < 0:
		dia = S.day
	if L.has(k):
		var b: Dictionary = L[k]
		junta_lote(b, g, thc, cu, dia, mc)
		b.erase("cata")   # 1.15: lo que entra nuevo no está catado ni analizado
		b.erase("ana")
	else:
		L[k] = {"g": g, "thc": thc}
		if dia != null:
			L[k].dia = dia
		if cu:
			L[k].cu = cu
		if mc:
			L[k].mc = mc
		if k.ends_with("!"):
			L[k].sh = 1
	discover(lot_sid(k))

# ---------- el curado (1.29, 09c-sala) ----------
# Cada lote lleva el día de la cosecha (dia) y lo curado (cu, de 0 a 1; sin él, nada). Con los tarros, en la caja fuerte (1.36: sin arcón)
# (1.36), 1/CURADO.dias al día; curado se vende CURADO.precio más caro (calidad) y el THC sube CURADO.thc por lo que se cura (1.36). 1.36: sin curar ya no
# pierde THC; los extractos se curan en frío en la nevera (S.nevera.rosin, sin tarros) y el manicurado (mc, de 0 a 1) pela los
# cogollos: MANICURA.precio más caro. Al juntar dos lotes, el THC, lo curado, lo manicurado y el día van por gramos
func calidad(b: Dictionary, flor := false) -> float:
	var q: float = 1 + D.CURADO.precio * float(b.get("cu", 0)) + D.MANICURA.precio * float(b.get("mc", 0)) + D.CAMAROTE.extra * float(b.get("af", 0))   # 1.43.6: afinado en el camarote
	if Datos.CAL and flor:   # MAESTRO [5]: la hierba verde vale poco y en tarros, semana a semana, más; la rara, ×SHINY.x
		q *= verde(b) * (float(D.SHINY.x) if b.get("sh") else 1.0)
	if Datos.CAL and b.get("oz"):   # MAESTRO [6]: secada con el ozono en la sala, sin terpenos
		q *= float(D.OLOR_NAVE.oz_q)
	return q

# recién cortada, VERDE.min; seca del todo a los VERDE.dias; y lo curado, VERDE.semana más por semana (hasta VERDE.semanas)
func verde(b: Dictionary) -> float:
	if b.get("dia") == null:
		return 1.0
	var V: Dictionary = D.VERDE
	var d := maxf(0, S.day - float(b.dia))
	var f: float = minf(1, float(V.min) + (1 - float(V.min)) * d / float(V.dias))
	return f * (1 + float(V.semana) * minf(d / 7.0, float(V.semanas)) * float(b.get("cu", 0)))

func cura_de(b: Dictionary) -> Dictionary:
	var o := {}
	if b.get("dia") != null:
		o.dia = b.dia
	if b.get("cu"):
		o.cu = b.cu
	if b.get("mc"):
		o.mc = b.mc
	if b.get("af"):
		o.af = b.af
	if b.get("sh"):
		o.sh = b.sh
	return o

func junta_lote(t: Dictionary, g: float, thc: float, cu, dia, mc = 0, af = 0) -> void:
	var nn: float = t.g + g
	var fa: float = (float(t.get("af", 0)) * t.g + float(af if af else 0) * g) / nn   # 1.43.6: lo afinado en el camarote, por gramos
	if fa:
		t.af = fa
	else:
		t.erase("af")
	var c: float = (float(t.get("cu", 0)) * t.g + float(cu if cu else 0) * g) / nn
	var m: float = (float(t.get("mc", 0)) * t.g + float(mc if mc else 0) * g) / nn
	t.thc = (t.thc * t.g + thc * g) / nn
	if c:
		t.cu = c
	else:
		t.erase("cu")
	if m:
		t.mc = m
	else:
		t.erase("mc")
	if dia != null:
		t.dia = Datos.jsround((float(t.get("dia", dia)) * t.g + float(dia) * g) / nn)
	t.g = nn

func y_lista(l: Array) -> String:
	return (", ".join(l.slice(0, -1)) + " y " + l[-1]) if l.size() > 1 else l[0]

# la nevera (1.36): los extractos, en frío
func nevera() -> Dictionary:
	if S.get("nevera") == null:
		S.nevera = {"rosin": {}}
	return S.nevera

func nevera_r() -> float:
	var t := 0.0
	if S.get("nevera") != null:
		for k in S.nevera.rosin:
			t += S.nevera.rosin[k].g
	return t

# lo que cabe en frío (1.39, lo pidió el usuario): la nevera de serie, 1 kg; con el arcón congelador de la tienda online, 5 kg más
func nevera_cap() -> float:
	return float(D.NEVERA.g) + (float(D.NEVERA.arcon.g) if S.get("nevera") != null and S.nevera.get("arcon") == 1 else 0.0)

# ---------- el camarote (1.43.6, lo pidió el usuario: «habilitar el camarote de arriba… como almacén», solo con Datos.CAL) ----------
# S.cam = {d: el día en que acaban la obra, e: [el día en que llega cada estantería], sob: los sobres de humedad que quedan (uno por
# tarro cada CAMAROTE.dura días), sp: [[día, sobres]] los pedidos, buds: los lotes}; caben CAMAROTE.tarro g por tarro de 10 L
func cam() -> Dictionary:
	return S.cam if S.get("cam") is Dictionary else {}

func cam_ya() -> bool:
	return Datos.CAL and cam().has("d") and float(S.cam.d) <= S.day

func cam_est() -> int:
	return cam().get("e", []).filter(func(d): return float(d) <= S.day).size()

func cam_cap() -> float:
	return float(cam_est() * int(D.CAMAROTE.est.tarros) * int(D.CAMAROTE.tarro))

func cam_g() -> float:
	var t := 0.0
	for k in cam().get("buds", {}):
		t += S.cam.buds[k].g
	return t

# los tarros de 10 L que ocupan los lotes (cada lote, en los suyos)
func cam_tarros() -> int:
	var n := 0
	for k in cam().get("buds", {}):
		n += maxi(1, ceili(floor(S.cam.buds[k].g) / float(D.CAMAROTE.tarro) - 1e-9))
	return n

func extr_nombre(k: String, mn := false) -> String:
	return (D.EXTR[tipo_extr(k)].n.to_lower() if mn else D.EXTR[tipo_extr(k)].n) + " de " + lot_nombre(base_extr(k))

func de_art(art: String) -> String:   # «de» + el artículo: «del utilitario», «de la moto»
	return ("del " + art.substr(3)) if art.begins_with("el ") else ("de " + art)   # i18n-no

func _cura(L: Dictionary) -> Array:
	var o := []
	for k in L:
		var b: Dictionary = L[k]
		if float(b.get("cu", 0)) < 1:
			var c0 := float(b.get("cu", 0))
			b.cu = minf(1.0, c0 + 1.0 / D.CURADO.dias * (float(D.FISIO.indica.cura) if indica_ayer() else 1.0))   # MAESTRO [2]: con la índica, sin prisa, se cura antes
			b.thc = b.thc * (1 + D.CURADO.thc * (b.cu - c0))
			if b.cu >= 1:
				o.append(k)
	return o

# al amanecer (new_day): lo que se cura; av, los avisos del día
func curado_dia(av: Array) -> void:
	var c: Array = _cura(S.caja.buds) if S.items.get("tarros") and S.get("caja") else []
	var nv: Array = _cura(S.nevera.rosin) if S.items.get("tarros") and S.get("nevera") != null else []   # 1.36: los dos, con los tarros
	if c.size():
		av.append(T("Curada en la caja fuerte: {l}", {"l": y_lista(c.map(lot_nombre))}))
	if nv.size():
		av.append(T("Curado en la nevera: {l}", {"l": y_lista(nv.map(extr_nombre))}))
	if Datos.CAL and S.items.get("tarros") and S.get("coches") is Dictionary:   # MAESTRO [3]: el maletero también cura en botes (los tarros); lo envasado al vacío, no
		for k in D.CONCE.orden:
			var ml = S.coches.get(k, {}).get("mal")
			if ml is Dictionary and ml.get("buds", {}).size():
				var bs := {}
				for q in ml.buds:
					if not ml.buds[q].get("vac"):
						bs[q] = ml.buds[q]
				var cm: Array = _cura(bs)
				if cm.size():
					av.append(T("Curada en el maletero {dv}: {l}", {"dv": de_art(String(D.CONCE.v[k].art)), "l": y_lista(cm.map(lot_nombre))}))
	if navc().get("buds", {}).size():   # MAESTRO [8]: las estanterías de la nave
		var cn: Array = _cura(S.nave.cur.buds)
		if cn.size():
			av.append(T("Curada en la nave: {l}", {"l": y_lista(cn.map(lot_nombre))}))
	if cam_ya() and cam().get("buds", {}).size():   # 1.43.6: el camarote cura en sus tarros de 10 L y, con sobres, afina
		var cc: Array = _cura(S.cam.buds)
		if cc.size():
			av.append(T("Curada en el camarote: {l}", {"l": y_lista(cc.map(lot_nombre))}))
		if float(S.cam.get("sob", 0)) > 0:
			var af := []
			for k in S.cam.buds:
				var b: Dictionary = S.cam.buds[k]
				if float(b.get("cu", 0)) >= 1 and float(b.get("af", 0)) < 1:
					b.af = minf(1.0, float(b.get("af", 0)) + 1.0 / float(D.CAMAROTE.af))
					if b.af >= 1:
						af.append(k)
			if af.size():
				av.append(T("Afinada al 62 % en el camarote: {l} (un {p} % más cara)", {"l": y_lista(af.map(lot_nombre)), "p": int(Datos.jsround(D.CAMAROTE.extra * 100))}))
			S.cam.sob = maxf(0.0, float(S.cam.sob) - float(cam_tarros()) / float(D.CAMAROTE.dura))
			if S.cam.sob <= 0:
				av.append(K("Se han gastado los sobres de humedad del camarote"))

# cómo está un lote, para la mochila: curado, curándose o sin curar ("" en los de antes de la 1.29), y manicurado
func man_txt(b: Dictionary) -> String:
	var mc := float(b.get("mc", 0))
	return T(" Manicurada: un {p} % más cara.", {"p": int(Datos.jsround(D.MANICURA.precio * 100))}) if mc >= 1 else (T(" Manicurada en parte.") if mc else "")

func cura_txt(b: Dictionary) -> String:
	var cu := float(b.get("cu", 0))
	var t := ""
	if cu >= 1:
		t = T("Curada: un {t} % más de THC y se vende un {p} % más cara.", {"t": int(Datos.jsround(D.CURADO.thc * 100)), "p": int(Datos.jsround(D.CURADO.precio * 100))})
	elif cu:
		t = T("Curándose ({p} %): termina de curarla con los tarros, en la caja fuerte.", {"p": int(Datos.jsround(cu * 100))})
	elif b.get("dia") != null:
		t = T("Sin curar: con tarros, en la caja fuerte, se cura en {d} días: sube un {t} % de THC y se vende un {p} % más cara.", {"d": int(D.CURADO.dias), "t": int(Datos.jsround(D.CURADO.thc * 100)), "p": int(Datos.jsround(D.CURADO.precio * 100))})
	return (t + man_txt(b)).strip_edges()

func cura_corto(b: Dictionary) -> String:
	var cu := float(b.get("cu", 0))
	return (T(" · curada") if cu >= 1 else (T(" · curándose") if cu else (T(" · sin curar") if b.get("dia") != null else ""))) + (T(" · manicurada") if float(b.get("mc", 0)) >= 1 else "")

func use_buds(k: String, g: float) -> void:
	var b: Dictionary = S.buds[k]
	b.g -= g
	if b.g < .5:
		S.buds.erase(k)

func bud_lots(mn: float, min_thc := 0.0) -> Array:
	var o := []
	for k in S.buds:
		var b: Dictionary = S.buds[k]
		if b.g >= mn and b.thc >= min_thc:
			o.append([k, b])
	return o

func lot_item(l: Array) -> Dictionary:
	var k: String = l[0]
	return {"label": lot_nombre(k), "right": "%d g · %s%%" % [int(floor(l[1].g)), Datos.pct(l[1].thc)], "sw": strain(lot_sid(k)).c, "ic": ic_cog(lot_sid(k))}

# rosin (1.10): lo que sale de prensar cogollos en la mesa (prensar, granja), por lotes como ellos y al décimo de gramo
func total_rosin() -> float:
	var t := 0.0
	for k in S.rosin:
		t += S.rosin[k].g
	return t

func add_rosin(k: String, g: float, thc: float) -> void:
	if S.rosin.has(k):
		var b: Dictionary = S.rosin[k]
		if b.get("cu"):
			b.cu = b.cu * b.g / (b.g + g)
			if not b.cu:
				b.erase("cu")
		b.thc = (b.thc * b.g + thc * g) / (b.g + g)
		b.g = Datos.jsround((b.g + g) * 10) / 10.0
	else:
		S.rosin[k] = {"g": g, "thc": thc}

func use_rosin(k: String, g: float) -> void:
	var b: Dictionary = S.rosin[k]
	b.g = Datos.jsround((b.g - g) * 10) / 10.0
	if b.g < .1:
		S.rosin.erase(k)

func rosin_txt(r: float) -> String:
	return T("{g} g de rosin", {"g": Datos.coma(Datos.jsround(r * 10) / 10.0)})

# lo que llevas encima en gramos de flor: el rosin, como la flor de la que sale (1 g ↔ 1 / ROSIN.rend = 5 g). Ladrones y Darko
func gramos_flor() -> float:
	return total_buds() + total_rosin() / D.ROSIN.rend

func rosin_lots(mn: float) -> Array:
	var o := []
	for k in S.rosin:
		if S.rosin[k].g >= mn:
			o.append([k, S.rosin[k]])
	return o

func rosin_item(l: Array) -> Dictionary:
	var k: String = l[0]
	return {"label": D.EXTR[tipo_extr(k)].n + " · " + lot_nombre(k) + (T(" · curado") if float(l[1].get("cu", 0)) >= 1 else ""), "right": "%s g · %s%%" % [Datos.coma(l[1].g), Datos.pct(l[1].thc)], "sw": "#d89a18", "ic": ic_cog(lot_sid(k))}

# las extracciones (1.35, 11l-extraccion): el tipo va en la clave del lote («ria~seco»; el rosin, sin nada)
func tipo_extr(k: String) -> String:
	return k.get_slice("~", 1) if k.contains("~") else "rosin"

func base_extr(k: String) -> String:
	return k.get_slice("~", 0)

func kief_lots(mn: float) -> Array:
	return rosin_lots(mn).filter(func(l): return D.EXTR[tipo_extr(l[0])].get("kief"))

# (lo pidió el usuario: «las extracciones se deberían poder vender al por mayor, en clubs y donde se pueda vender cogollos»;
# con Datos.CAL): los lotes que se venden, los cogollos [k, b] y detrás las extracciones de encima [k, b, true], a precio_rosin × su
# px × VENTA_EXTR[canal] (al por mayor la mitad, en el club tres cuartos: lo que pagan por la flor frente a la calle)
func lotes_venta(mn: float, mnx: float) -> Array:
	var o := bud_lots(mn)
	if Datos.CAL:
		for l in rosin_lots(mnx):
			o.append([l[0], l[1], true])
	return o

func es_extr(l: Array) -> bool:
	return l.size() > 2 and l[2] == true

func venta_item(l: Array) -> Dictionary:
	return rosin_item(l) if es_extr(l) else lot_item(l)

func venta_nombre(l: Array) -> String:
	return extr_nombre(l[0]) if es_extr(l) else lot_nombre(l[0])

func precio_extr(k: String, thc: float, canal: String) -> float:
	return precio_rosin(thc) * float(D.EXTR[tipo_extr(k)].px) * float(D.VENTA_EXTR[canal])

func usa_lote(l: Array, g: float) -> void:
	if es_extr(l):
		use_rosin(l[0], g)
	else:
		use_buds(l[0], g)

# las cantidades de una extracción: las de VENTA_EXTR que caben y, al final, lo que hay (hasta el tope)
func ops_extr(b: Dictionary, tope: float, gs: Array) -> Array:
	var t: int = int(floor(minf(b.g, tope)))
	var o := []
	for g in gs:
		if g < t:
			o.append(int(g))
	o.append(t)
	return o

func mayor_lote(l: Array):
	var a = null
	for x in l:
		if a == null or x[1].g > a[1].g:
			a = x
	return a

func mueble_ya(E: Dictionary) -> bool:
	return true if (S.items.get(E.item) or (E.get("alt") and S.items.get(E.alt))) else false

func extr_algo() -> bool:   # algún aparato: catadores en la calle y el extracto en la caja
	var it: Dictionary = S.items
	return true if (it.get("prensa") or it.get("tamiz") or it.get("mallas00") or it.get("ice") or it.get("lavadora") or it.get("estatica")) else false

# las que puedes hacer: la de cada aparato, el charas con cualquiera, el prensado con kief y el moonrock con la prensa y kief
func extr_ya() -> Array:
	var it: Dictionary = S.items
	var kf: bool = true if (it.get("tamiz") or it.get("mallas00") or it.get("ice") or it.get("lavadora") or it.get("estatica")) else false
	var si := {"rosin": it.get("prensa"), "seco": it.get("tamiz") or it.get("mallas00"), "ice": it.get("ice"), "charas": extr_algo(), "hash": kf, "moon": it.get("prensa") and kf,
		"lava": it.get("lavadora"), "stat": it.get("estatica")}
	return D.EXTR.keys().filter(func(t): return true if si[t] else false)

# el prólogo (1.10): S.flags.llegada === false hasta que el autobús de ama deja al jugador en Ribera Verde (las partidas viejas
# no la llevan: ya han llegado)
func llegando() -> bool:
	return S.flags.has("llegada") and S.flags.llegada is bool and S.flags.llegada == false

func got(t: String) -> void:
	sfx("get")
	await say(T("Consigues {t}.", {"t": t}))

# las semillas que escondió la tía Maite (1.25): landraces que no están en el banco
func semillas_tia(k: String, txt: String, k_n: int = 2) -> void:
	add_seeds(k, k_n)
	await got(T("{n} semillas de {nom}", {"n": k_n, "nom": D.STRAINS[k].n.to_upper()}))
	await say(txt)

# ---------- mapas (04-mapas) ----------
# el equipo de la nave (1.33, montarNave de 11j-locales): extractores, filtros, controlador, tanque y máquina según S.nave.ex/rg
func montar_nave() -> void:
	var n = MAPS.get("nave")
	if n == null:
		return
	quita_orden("nave")   # 1.37: las mesas y el tanque, donde los puso el jugador (12d-orden: la pieza riego)
	for e in D.EQUIPO_NAVE:
		if e[3] == "ex":
			n.o[int(e[1])][int(e[0])] = null
	if S != null and S.get("nave") != null:
		for e in D.EQUIPO_NAVE:
			var v := int(S.nave.get(e[3], 0))
			if e[3] == "ex" and v >= int(e[4]) and v <= int(e[5]):
				n.o[int(e[1])][int(e[0])] = e[2]
	if S != null:
		aplica_orden("nave")
	# El carro de las bandejas de clones (S.nave.bc), contra la pared, entre el secadero y el escritorio
	for x in [8, 9]:
		if n.o[2][x] in ["clonN", "clonN2"]:   # i18n-no
			n.o[2][x] = null
	if S != null and S.get("nave") != null and Datos.CAL and not S.nave.has("bc"):
		S.nave.bc = []
	if S != null and S.get("nave") != null and S.nave.has("bc") and n.o[2][8] == null and n.o[2][9] == null:
		n.o[2][8] = "clonN"   # i18n-no
		n.o[2][9] = "clonN2"   # i18n-no
	# (lo pidió el usuario: «en la nave en la que cultivas, lo mismo»): el camastro del rincón, para dormir allí
	for y in [6, 7]:
		if n.o[y][17] in ["bedT", "bedB"]:   # i18n-no
			n.o[y][17] = null
	if S != null and S.get("nave") != null and Datos.CAL and n.o[6][17] == null and n.o[7][17] == null and puertas_int("nave").is_empty():
		n.o[6][17] = "bedT"   # i18n-no
		n.o[7][17] = "bedB"
	# MAESTRO [8]: las estanterías de tarros de 10 L del curado de la nave (CURADO_NAVE), en los huecos libres de la pared
	for q in D.get("CURADO_NAVE", {}).get("sitio", []):
		if n.o[int(q[1])][int(q[0])] == "estanteC":   # i18n-no
			n.o[int(q[1])][int(q[0])] = null
	var ne := navc_est()
	for q in D.get("CURADO_NAVE", {}).get("sitio", []):
		if ne <= 0:
			break
		if n.o[int(q[1]) - 1][int(q[0])] in ["extrN", "extrG", "ctrlN"]:   # i18n-no  delante del extractor o del controlador de la pared, no
			continue
		if n.o[int(q[1])][int(q[0])] == null:
			n.o[int(q[1])][int(q[0])] = "estanteC"   # i18n-no
			ne -= 1
	montar_puertas("nave")   # 1.51: el despacho y la habitación, detrás de sus puertas

# (lo pidió el usuario: «cuando lo vayas a alquilar, entres al local y por reformar»): la nave sin alquilar por dentro (nave-r),
# la de siempre sin muebles y con los trastos del último inquilino; se entra con Arrieta (talk_nave), no por la persiana
const NAVE_RUINA := [[0, 2, "crate"], [1, 2, "cajasT"], [4, 2, "sacos"], [5, 2, "crate"], [9, 2, "bidonT"], [10, 2, "barrilT"],   # i18n-no
	[14, 2, "neumT"], [16, 2, "cajasT"], [17, 2, "crate"], [2, 5, "neumT"], [11, 4, "garrafa"], [12, 5, "cuboS"], [15, 6, "crate"], [16, 6, "sacos"]]   # i18n-no

func mapa_nave_r() -> void:
	if not D.MAPS.has("nave"):
		return
	var m: Dictionary = D.MAPS.nave.duplicate(true)
	Datos.enteros(m)
	m.name = "nave-r"
	for y in m.h:
		for x in m.w:
			m.o[y][x] = null
	for q in NAVE_RUINA:
		m.o[q[1]][q[0]] = q[2]
	MAPS["nave-r"] = m

# MAESTRO [8]: el despacho de lujo (DESPACHO): la tarima, las paredes, la alfombra y los muebles, sobre la copia del de siempre
var _desp0 = null

func montar_despacho() -> void:
	var m = MAPS.get("nave-d")
	if m == null:
		return
	if _desp0 == null:
		_desp0 = {"g": m.g.duplicate(true), "o": m.o.duplicate(true)}
	for y in int(m.h):
		m.g[y] = _desp0.g[y].duplicate()
		m.o[y] = _desp0.o[y].duplicate()
	if not desp_ya():
		return
	var DS: Dictionary = D.DESPACHO
	for y in int(m.h):
		for x in int(m.w):
			var g: String = m.g[y][x]
			if g == "floorN":
				m.g[y][x] = DS.suelo
			elif g == "iwT_nave" or g == "iwB_nave":
				m.g[y][x] = g.left(4) + "home-" + str(int(DS.pared))   # i18n-no
	var al: Array = DS.alf
	for j in 4:
		m.g[int(al[1]) + j / 2][int(al[0]) + j % 2] = String(al[2]) + "abcd"[j] + "-" + String(DS.suelo).get_slice("-", 1)
	for q in DS.quita:
		m.o[int(q[1])][int(q[0])] = null
	for q in DS.o:
		m.o[int(q[1])][int(q[0])] = q[2]

# MAESTRO [8]: el curado de la nave, como el camarote: S.nave.cur = {buds, mj (1 con la ampliación)}; CURADO_NAVE.est
# estanterías de serie, el doble con la ampliación, de CAMAROTE.est.tarros tarros de CAMAROTE.tarro g
func navc() -> Dictionary:
	if not Datos.CAL or S == null or S.get("nave") == null:
		return {}
	if not (S.nave.get("cur") is Dictionary):
		S.nave.cur = {"buds": {}, "mj": 0}
	return S.nave.cur

func navc_est() -> int:
	var c := navc()
	return 0 if c.is_empty() else int(D.CURADO_NAVE.est) * (2 if int(c.get("mj", 0)) else 1)

func navc_cap() -> float:
	return float(navc_est() * int(D.CAMAROTE.est.tarros) * int(D.CAMAROTE.tarro))

func navc_g() -> float:
	var t := 0.0
	for k in navc().get("buds", {}):
		t += float(S.nave.cur.buds[k].g)
	return t

# MAESTRO [8]: el despacho de lujo comprado (S.desp = {d, money, buds}); la caja fuerte del despacho no la encuentra la redada
func desp() -> Dictionary:
	return S.desp if S != null and S.get("desp") is Dictionary else {}

func desp_ya() -> bool:
	return Datos.CAL and not desp().is_empty() and S.get("nave") != null

# el concesionario del barrio alto (1.43, lo pidió el usuario): con AUTOS RIBERA abierto (S.flags.conce), su edificio (D.CONCE.bld),
# sin los árboles de donde va (CONCE.quita), con la acera, las banderas y la puerta; sin él, el barrio alto como estaba
var _alto0 = null

func montar_alto() -> void:
	var m = MAPS.get("alto")
	if m == null:
		return
	var C: Dictionary = D.CONCE
	var b: Dictionary = C.bld
	var abre: bool = S != null and S.get("flags") is Dictionary and S.flags.get("conce") != null
	if _alto0 == null:
		_alto0 = {"g": m.g.duplicate(true), "o": m.o.duplicate(true), "doors": m.doors.duplicate(true), "blds": m.blds.duplicate(true)}
	if m.get("conceK", false) == abre:
		return
	m.conceK = abre
	for y in int(m.h):
		m.g[y] = _alto0.g[y].duplicate()
		m.o[y] = _alto0.o[y].duplicate()
	m.doors.clear()
	m.doors.merge(_alto0.doors.duplicate(true))
	m.blds.clear()
	m.blds.append_array(_alto0.blds.duplicate(true))
	if not abre:
		return
	for q in C.quita:
		m.o[int(q[1])][int(q[0])] = null
	var y0 := int(b.y0)
	var dy: int = y0 + int(b.h) - 1
	for y in range(y0, dy + 1):
		for x in range(int(b.x0), int(b.x0) + int(b.w)):
			m.g[y][x] = ("roofT_" if y == y0 else "roofB_" if y == y0 + 1 else "wall_") + "conce"   # i18n-no
			m.o[y][x] = null
	for x in range(int(b.x0) + 1, int(b.x0) + int(b.w) - 1):   # la acera de delante
		m.g[dy + 1][x] = "walk"
	for j in 2:
		var x: int = int(b.doorX) + j
		m.g[dy][x] = "door_conce"
		m.doors["%d,%d" % [x, dy]] = {"to": "conce", "x": 8 + j, "y": 8, "dir": "up"}
	for f in C.fuera:
		m.o[int(f[1])][int(f[0])] = f[2]
	m.blds.append(b.duplicate())

func montar_casa() -> void:
	var h: Dictionary = MAPS.home
	if S == null:
		return
	var ks := []
	for c in S.carpas:
		ks.append(c.t if c else "-")
	var ya := muebles_ya()
	var su := deco_v("suelo")
	var pa := deco_v("pared")
	var key := ",".join(ks) + "|" + ",".join(ya) + "|" + ",".join([su, pa, deco_v("alfombra")]) + "|" + ",".join(D.MUEBLE_EXTR.keys().filter(func(k): return mueble_ya(D.MUEBLE_EXTR[k]))) + "|" + JSON.stringify(S.get("coloca", {}).get("home", {}) if S.get("coloca") is Dictionary else {}) + ("|cam" if cam_ya() else "")
	if h.get("carpasK") == key:
		return
	h.carpasK = key
	quita_orden("home")   # 1.37: los muebles que se ordenan (12d-orden), fuera; después, donde los puso el jugador
	var al = pos_pieza("home", "alfombra") if "alfombra" in ya else null
	# El suelo y las paredes de la reforma (REFORMA) y la alfombra (suelo: 1, sus 4 trozos sobre el suelo que haya)
	var vs := ("-" + str(pa)) if pa else ""
	var fs := ("-" + str(su)) if su else ""
	for y in int(h.h):
		for x in int(h.w):
			if h.g[y][x] == "mat":
				continue
			if y == 0:
				h.g[y][x] = "iwT_home" + vs   # i18n-no
			elif y == 1:
				h.g[y][x] = "iwB_home" + vs   # i18n-no
			elif al and x >= al[0] and x <= al[0] + 1 and y >= al[1] and y <= al[1] + 1:
				h.g[y][x] = "alf" + str(deco_v("alfombra")) + "abcd"[(y - int(al[1])) * 2 + x - int(al[0])] + fs
			else:
				h.g[y][x] = "floor" + fs
	for s in D.SITIOS:
		for x in range(s.x, s.x + s.w):
			h.o[s.y][x] = null
	for k in D.MUEBLES:   # los de la pared que ya han llegado (12c-salon: el cuadro y el póster), en su sitio; los demás, piezas (1.37)
		var mu: Dictionary = D.MUEBLES[k]
		if mu.get("suelo") or not pieza_de("home", k).is_empty():
			continue
		h.o[mu.y][mu.x] = k if k in ya else null
		if not mu.get("uno"):
			h.o[mu.y][mu.x + 1] = (k + "2") if k in ya else null
	h.carpas = []
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if not c or Datos.CAL:   # 1.55: con CAL, las carpas son piezas de ORDENAR LA CASA (aplica_orden)
			continue
		var s: Dictionary = D.SITIOS[ci]
		var x0: int = s.x
		var x1: int = x0 + int(D.CARPAS[c.t].w) - 1
		for x in range(x0, x1 + 1):
			h.o[s.y][x] = "carpa"
		h.carpas.append({"ci": ci, "t": c.t, "x0": x0, "x1": x1, "y": int(s.y)})
	if Datos.CAL:   # 1.55: cada carpa ocupa lo que mide la suya (1 o 2 casillas)
		for ci in S.carpas.size():
			var P_ := pieza_de("home", "carpa%d" % ci)
			if not P_.is_empty() and S.carpas[ci]:
				P_.o = [[0, 0, "carpa"]] + ([[1, 0, "carpa"]] if int(D.CARPAS[S.carpas[ci].t].w) > 1 else [])
	aplica_orden("home")   # la nevera, la mesa, las plantas, el taller y los muebles del salón (con la silla gaming)
	if Datos.CAL:
		carpas_casa(h)
	montar_puertas("home")   # 1.51: la puerta del pasillo del sótano
	if puertas_int("home").size():
		var dl := delante_puertas("home")
		var quita := false
		for Q in piezas_ya("home"):
			var q := pos_pieza("home", Q.k)
			for c in celdas_p(Q, q[0], q[1]) + gente_p(Q, q[0], q[1]):
				if [int(c[0]), int(c[1])] in dl and S.get("coloca") is Dictionary and S.coloca.get("home") is Dictionary and S.coloca.home.has(Q.k):
					S.coloca.home.erase(Q.k)
					quita = true
		if quita:
			h.carpasK = ""
			montar_casa()
			return
	# La escalera escamoteable del camarote, entre las carpas A y B, bajo la ventana; se sube desde la casilla de delante
	# (CAMAROTE.vuelta); ninguna de las dos se ocupa al ordenar
	var CM: Dictionary = D.CAMAROTE
	if h.o[int(CM.y)][int(CM.x)] == "escaleraC":
		h.o[int(CM.y)][int(CM.x)] = null
	if not cam_ya():
		return
	var esc := [[int(CM.x), int(CM.y)], [int(CM.vuelta[0]), int(CM.vuelta[1])]]
	var fuera := false
	for Q in piezas_ya("home"):   # lo que estuviera en la escalera o delante vuelve a su sitio (las de serie no caen ahí)
		var q := pos_pieza("home", Q.k)
		for c in celdas_p(Q, q[0], q[1]) + gente_p(Q, q[0], q[1]):
			if [int(c[0]), int(c[1])] in esc and S.get("coloca") is Dictionary and S.coloca.get("home") is Dictionary and S.coloca.home.has(Q.k):
				S.coloca.home.erase(Q.k)
				fuera = true
	if fuera:
		h.carpasK = ""
		montar_casa()
		return
	h.o[int(CM.y)][int(CM.x)] = "escaleraC"   # i18n-no

# el camarote por dentro: las estanterías que han llegado, contra la pared de arriba (x 1, 3, 5 y 7)
# el bajo de las setas entero (1.44, con Datos.CAL): el armario de almacén, la mesa de trabajo y, si se lo has comprado a Txomin,
# el deshidratador (SETAS_PRO.x); sin Datos.CAL, el bajo de antes
var _setas0 = null

var _setas_g := false

func montar_setas() -> void:
	var m = MAPS.get("setas")
	if m == null:
		return
	if Datos.CAL and not _setas_g and MAPS.has("setas-g"):   # 1.51 (lo pidió el usuario: «que sea más grande y que se cultive como la nave»)
		_setas_g = true
		var G: Dictionary = MAPS["setas-g"]
		m.w = int(G.w)
		m.g = G.g.duplicate(true)
		m.o = G.o.duplicate(true)
		_setas0 = null
	if _setas0 == null:
		_setas0 = m.o.duplicate(true)
	for y in int(m.h):
		m.o[y] = _setas0[y].duplicate()
	if not Datos.CAL:
		return
	var X: Dictionary = D.SETAS_PRO.x
	m.o[int(X.armS[1])][int(X.armS[0])] = "armS"   # i18n-no
	m.o[int(X.mesaS[1])][int(X.mesaS[0])] = "mesaS"   # i18n-no
	if S != null and S.get("setas") is Dictionary and S.setas.get("dh"):
		m.o[int(X.deshidS[1])][int(X.deshidS[0])] = "deshidS"   # i18n-no
	if S != null and S.get("setas") is Dictionary and S.setas.get("ay") and int(m.w) > 10:   # 1.51: la mesa del ayudante
		m.o[int(D.SETAS_AY.mesa[1])][int(D.SETAS_AY.mesa[0])] = "mesita"

# los negocios por dentro (1.45, lo pidió el usuario: «que tú puedas acceder a ese sitio y controlarlo desde ahí»; con Datos.CAL):
# en la calle, la puerta del local (NEGOCIO.k[k]: x, puerta, ancha, dx, tile; gate «neg:k»); dentro (loc-<k>), lo que ponen las mejoras
# compradas (S.loc[k].mj); sin Datos.CAL, la calle y el local como estaban (la copia _neg0)
const NEG_ANCHO := ["elevT", "fosoT", "bancoT", "boxL", "cubaQ", "mostrQ", "hornoP", "mostrP", "doblaL", "hornoN", "recambT", "barraN", "botN", "estP", "mostrN", "doblaN", "mesaP", "barraTb", "botTb"]   # 1.47: los muebles de PixelLab de dos casillas   # i18n-no

# El elevador y el foso, a escala con los coches del concesionario (5 casillas, como la exposición); 1.47, el box de lavado
const NEG_LARGO := {"elevT": 5, "fosoT": 5, "boxL": 5}

var _neg0 := {}

func montar_locales(mapa: String) -> void:
	if not D.has("NEGOCIO"):
		return
	for k in D.NEGOCIO.k:
		var N: Dictionary = D.NEGOCIO.k[k]
		var L: Dictionary = D.LOCALES[k]
		var dentro: String = "loc-" + k
		if mapa != L.map and mapa != dentro:
			continue
		var m = MAPS.get(mapa)
		if m == null:
			continue
		if not _neg0.has(mapa):
			_neg0[mapa] = {"g": m.g.duplicate(true), "o": m.o.duplicate(true), "doors": m.doors.duplicate(true), "blds": m.blds.duplicate(true)}
		var c: Dictionary = _neg0[mapa]
		if mapa == L.map:
			for y in int(m.h):
				m.g[y] = c.g[y].duplicate()
			m.doors.clear()
			m.doors.merge(c.doors.duplicate(true))
			m.blds.clear()
			m.blds.append_array(c.blds.duplicate(true))
		else:
			for y in int(m.h):
				m.o[y] = c.o[y].duplicate()
		if not Datos.CAL:
			continue
		if mapa == L.map:
			for b in m.blds:
				if int(b.x0) == int(N.bld) and int(b.y0) + int(b.h) - 1 == int(N.dy):
					b.doorX = int(N.x)
					b.puerta = N.puerta
					if N.ancha:
						b.ancha = 1
					b.dx = int(N.dx)
			for j in (2 if N.ancha else 1):
				m.g[int(N.dy)][int(N.x) + j] = N.tile
				m.doors["%d,%d" % [int(N.x) + j, int(N.dy)]] = {"to": dentro, "x": int(N.mat[mini(j, N.mat.size() - 1)]), "y": int(MAPS[dentro].h) - 2, "dir": "up", "gate": "neg:" + k}
		elif S != null and S.get("loc") is Dictionary and S.loc.has(k):
			for i in mini(int(S.loc[k].get("mj", 0)), N.mj.size()):
				for q in N.mj[i].o:
					m.o[int(q[1])][int(q[0])] = q[2]
					if q[2] in NEG_ANCHO:
						for j in range(1, int(NEG_LARGO.get(q[2], 2))):
							m.o[int(q[1])][int(q[0]) + j] = q[2] + "2"
		if mapa == dentro:   # 1.57.2: la puerta del cuartucho no se pierde al comprar una mejora estando dentro; y el taller, por zonas
			montar_puertas(mapa)
			montar_taller(mapa)

# (lo pidió el usuario: «la discoteca tiene que ser más grande, el piso de arriba reservado»), solo con Datos.CAL: GAUA, la planta
# baja grande (disco-g en lugar de la de antes, con el mismo nombre de mapa), su gente en su sitio y la puerta del Ensanche a la entrada
var _disco_cal := false

func montar_disco() -> void:
	if not Datos.CAL or _disco_cal or not MAPS.has("disco-g"):
		return
	_disco_cal = true
	var m: Dictionary = MAPS.disco
	var G: Dictionary = MAPS["disco-g"]
	m.w = int(G.w)
	m.h = int(G.h)
	for k in ["g", "o", "exits"]:
		m[k] = G[k].duplicate(true)
	var C: Dictionary = D.DISCO_CAL
	for d in D.NPCDEF:
		if d.map == "disco" and C.npc.has(d.id):
			d.x = int(C.npc[d.id][0])
			d.y = int(C.npc[d.id][1])
	for k in C.puerta:
		if MAPS.ensanche.doors.has(k):
			MAPS.ensanche.doors[k].x = int(C.puerta[k][0])
			MAPS.ensanche.doors[k].y = int(C.puerta[k][1])

const VITRINA_GROW := {"shop": [7, 6], "growcity": [9, 5]}

const CAJERO_CAL := {"town": [[31, 8], [30, 8]]}   # 1.47 (lo pidió el usuario): el cajero que tapaba la farola, una casilla a la izquierda

# (lo pidió el usuario: «un estanco en cada pueblo»), solo con Datos.CAL: la puerta en una casa libre de cada pueblo (en el barrio
# alto, una casa nueva del Casco), el rótulo de la T y el estanco por dentro (est-<k>); va después de montar_locales y de montar_alto,
# que vuelven a poner el mapa como estaba
func montar_estancos(mapa: String) -> void:
	if not Datos.CAL or not D.has("ESTANCO"):
		return
	for k in D.ESTANCO.k:
		var E: Dictionary = D.ESTANCO.k[k]
		if mapa != E.map:
			continue
		var m = MAPS.get(mapa)
		if m == null:
			continue
		var dy := int(E.dy)
		var b = null
		if E.has("nuevo"):
			for q in m.blds:
				if q.get("est") == k:
					b = q
			if b == null:
				var nb: Dictionary = E.nuevo
				var ib: Dictionary = MAPS.ibarbide
				var src = null
				for q in ib.blds:
					if q.id == nb.id:
						src = q
						break
				for q in E.quita:
					m.o[int(q[1])][int(q[0])] = null
				for y in int(nb.h):
					for x in int(nb.w):
						m.g[int(nb.y0) + y][int(nb.x0) + x] = ib.g[int(src.y0) + y][int(src.x0) + x]
						m.o[int(nb.y0) + y][int(nb.x0) + x] = null
				for x in range(int(E.acera[0]), int(E.acera[1]) + 1):
					m.g[int(E.acera[2])][x] = "walk"
					m.o[int(E.acera[2])][x] = null
				b = {"id": nb.id, "x0": int(nb.x0), "y0": int(nb.y0), "w": int(nb.w), "h": int(nb.h), "est": k}
				m.blds.append(b)
		else:
			for q in m.blds:
				if int(q.x0) == int(E.bld[0]) and int(q.y0) == int(E.bld[1]):
					b = q
		if b == null:
			continue
		b.rotulo = "rotuloE"   # i18n-no
		if E.puerta != null:
			b.doorX = int(E.x)
			b.puerta = E.puerta
			b.dx = int(E.dx)
			if E.ancha:
				b.ancha = 1
		for j in (2 if E.ancha else 1):
			m.g[dy][int(E.x) + j] = E.tile
			m.doors["%d,%d" % [int(E.x) + j, dy]] = {"to": "est-" + k, "x": 4 + j, "y": int(MAPS["est-" + k].h) - 2, "dir": "up"}

func montar_camarote() -> void:
	var m: Dictionary = MAPS.camarote
	for i in int(D.CAMAROTE.est.max):
		m.o[2][1 + i * 2] = "estanteC" if i < cam_est() else null   # i18n-no

# lo que no se puede ocupar al ordenar (12d-orden): delante de la escalera del camarote (1.43.6)
func reserva_orden(mapa: String) -> Array:
	return D.ORDEN_RESERVA.get(mapa, []) + ([[D.CAMAROTE.x, D.CAMAROTE.y], D.CAMAROTE.vuelta] if mapa == "home" and (cam_ya() or Datos.CAL) else []) + delante_puertas(mapa)   # 1.55.1: con CAL, la escalera del camarote, libre siempre

# (lo pidió el usuario: «una puerta en la casa, luego un mapa pequeño como un mini pasillito»; y en el taller y en la nave): las
# puertas de dentro (PUERTAS_INT, con Datos.CAL), en la fila de la pared; se abren con A desde la casilla de delante, que no se ocupa
func puertas_int(mapa: String) -> Array:
	return D.PUERTAS_INT.get(mapa, []) if Datos.CAL and D.has("PUERTAS_INT") else []

func delante_puertas(mapa: String) -> Array:
	return puertas_int(mapa).map(func(e): return [int(e.x), int(e.y) + 1])

func puerta_int(mapa: String, x: int, y: int):
	for e in puertas_int(mapa):
		if int(e.x) == x and int(e.y) == y:
			return e
	return null

func montar_puertas(mapa: String) -> void:
	var m = MAPS.get(mapa)
	if m == null:
		return
	for e in puertas_int(mapa):
		m.o[int(e.y)][int(e.x)] = e.o
	if mapa == "nave" and puertas_int(mapa).size():   # el escritorio, al despacho
		for x in [12, 13]:
			if m.o[2][x] in ["escritorio", "escritorio2"]:
				m.o[2][x] = null

# (lo pidió el usuario): el taller por zonas, con CAL; montar_locales lo vuelve a poner cada vez que rehace el local
func montar_taller(mapa: String) -> void:
	if not Datos.CAL or mapa != "loc-valde" or not MAPS.has(mapa):
		return
	var m: Dictionary = MAPS[mapa]
	for z in TALLER_SUELO:
		for y in range(int(z[1]), int(z[3]) + 1):
			for x in range(int(z[0]), int(z[2]) + 1):
				var t: String = z[4]
				if t == "floorTc":   # el hormigón, con alguna mancha de aceite o una rodada
					t = ["floorTc", "floorTc", "floorTc", "floorTc2", "floorTc", "floorTc3"][_hash_t(x, y) % 6]   # i18n-no
				m.g[y][x] = t
	for q in [[0, 3], [16, 3]]:   # una pila de tres ruedas por sitio: dos seguidas, de fondo, parecían una torre más alta que el coche
		if m.o[q[1]][q[0]] == "neumT":
			m.o[q[1]][q[0]] = null
	m.atrezo = false
	montar_atrezo(mapa)

# (lo pidió el usuario: «un mapa lateral en Puerto Viejo, un mini puerto para los envíos»): desde el capítulo de MAR.ch, el paso
# del final de la plaza de Puerto Viejo (a la derecha) al muelle; en el muelle, la puerta del piso franco y los barcos que tengas,
# amarrados delante de su noray
var _muelle0 := {}

func montar_muelle(mapa: String) -> void:
	if not Datos.CAL or not D.has("MAR") or S == null:
		return
	var R: Dictionary = D.MAR
	if mapa == "puerto" and int(S.ch) >= int(R.ch):
		var m: Dictionary = MAPS.puerto
		var px: int = int(R.puerto.x)
		var py: int = int(R.puerto.y)
		for x in [px - 1, px]:   # el paso, con su hueco en el monte (las copas de abajo lo tapaban)
			for y in range(py - 1, py + 4):
				m.o[y][x] = null
				m.g[y][x] = "plaza" if y == py else "grass"
		if m.o[py + 3][px - 2] == "tree":   # y el árbol de la esquina, que tapaba el paso con su copa
			m.o[py + 3][px - 2] = null
		m.exits["%d,%d" % [px, py]] = {"to": "muelle", "x": int(R.puerto.a[0]), "y": int(R.puerto.a[1]), "dir": "right", "lado": "right"}
	if mapa != "muelle":
		return
	var mu: Dictionary = MAPS.muelle
	if not _muelle0.has("o"):
		_muelle0 = {"o": mu.o.duplicate(true), "g": mu.g.duplicate(true)}
	for y in int(mu.h):
		mu.o[y] = _muelle0.o[y].duplicate()
		mu.g[y] = _muelle0.g[y].duplicate()
	var F: Dictionary = R.franco
	for b in mu.blds:
		if int(b.x0) == int(F.x) - 1 and int(b.y0) + int(b.h) - 1 == int(F.dy):
			b.doorX = int(F.x)
			b.puerta = F.puerta
			b.ancha = 1
			b.dx = int(F.dx)
	mu.doors.clear()
	for j in 2:
		mu.g[int(F.dy)][int(F.x) + j] = F.tile
		mu.doors["%d,%d" % [int(F.x) + j, int(F.dy)]] = {"to": "franco", "x": int(F.mat[j]), "y": int(MAPS.franco.h) - 2, "dir": "up", "gate": "franco"}
	# (lo pidió el usuario: «comenzar destartalado… ir reformándolo poco a poco, edificio por edificio»): cada casa, en ruina hasta
	# su obra (MAR.obras); el pantalán, podrido hasta el suyo; la casa blanca reformada es el club KAIA, con su puerta
	for b in mu.blds:
		b.erase("fachada")
		for O in R.get("obras", []):
			if b.id in O.get("b", []):
				if not obra_ya(O.k):
					b.fachada = b.id + "-ruina"
				elif O.k == "club":
					b.fachada = R.kaia.fach
	if R.has("obras") and not obra_ya("pantalan"):
		for x in R.podrido:
			if mu.g[10][int(x)] == "dock":
				mu.g[10][int(x)] = "dockR"   # i18n-no
	if R.has("kaia") and obra_ya("club"):
		var K: Dictionary = R.kaia
		mu.g[int(K.door[1])][int(K.door[0])] = K.tile
		mu.doors["%d,%d" % [int(K.door[0]), int(K.door[1])]] = {"to": "club-muelle", "x": 7, "y": 8, "dir": "up", "gate": "club:muelle"}
	var mar = S.get("mar")
	for B in R.barcos:
		if mar is Dictionary and B.k in mar.get("b", []):
			mu.o[int(B.y)][int(B.x)] = B.o
			for j in range(1, int(B.L)):
				if int(B.x) + j < int(mu.w):
					mu.o[int(B.y)][int(B.x) + j] = B.o + "2"

# Una obra del muelle, terminada (S.mar.ob: el día en que se acaba cada una)
func obra_ya(k: String) -> bool:
	var mar = S.get("mar") if S else null
	return mar is Dictionary and mar.get("ob") is Dictionary and mar.ob.has(k) and int(S.day) >= int(mar.ob[k])

func cruzar_puerta(e: Dictionary) -> void:
	sfx("door")
	await fade(1)
	enter_map(e.to, int(e.tx), int(e.ty), e.dir)
	update_hud()
	await wait(80)
	await fade(0)

# el salón (1.10, 12c-salon): los muebles comprados que ya han llegado, y de qué mueble es un objeto (k o su mitad k + "2")
func muebles_ya() -> Array:
	var l := []
	var mu: Dictionary = S.get("muebles", {}) if S.get("muebles") is Dictionary else {}
	for k in D.MUEBLES:
		if mu.get(k) and mu[k] <= S.day:
			l.append(k)
	return l

func mueble_de(o) -> String:
	if not (o is String):
		return ""
	if D.MUEBLES.has(o):
		return o
	if o.ends_with("2") and D.MUEBLES.has(o.left(-1)) and not D.MUEBLES[o.left(-1)].get("uno") and not D.MUEBLES[o.left(-1)].get("suelo"):
		return o.left(-1)
	return ""

# ropa y pelo (1.21, ropaMapa/ropaC): el fotograma del protagonista (grupo g: player o player-combate) con los colores de S.ropa
func ropa_v(k: String) -> int:
	return int(S.ropa.get(k, 0)) if S.get("ropa") is Dictionary else 0

func ropa_mapa(g):
	if not (S.get("ropa") is Dictionary):
		return null
	var m := {}
	var id := ""
	for k in D.ROPA:
		var i := ropa_v(k)
		var s = D.ROPA[k].src.get(g)
		id += str(i)
		if i <= 0 or s == null or i >= D.ROPA[k].v.size():   # como en el HTML: un índice negativo no viste
			continue
		for j in s.size():
			var d = D.ROPA[k].v[i][j + 1]
			if s[j] != null and d != null:
				m[s[j]] = d
	return [m, id] if not m.is_empty() else null   # id: el color de cada pieza, en orden (1.22)

func ropa_c(f, g):
	var r = ropa_mapa(g) if f != null else null
	if r == null:
		return f
	var o: Dictionary = f.duplicate()
	o.c = Atlas.con_rampa(f.c, r[0], "ropa|" + r[1], 0x5c3a28 if g == "player-f" else -1)   # i18n-no
	return o

# MAESTRO [1]: la protagonista tiene su sprite de PixelLab (player-f en el mapa, player-f-combate de espaldas en el combate)
func grupo_pj():
	var g = Atlas.cubre("look:player-f") if es_chica() else null
	return g if g else Atlas.grupo_look(D.LOOKS.player)

func es_chica() -> bool:
	return Datos.CAL and S != null and S.get("sexo") == "f"

func es_chico() -> bool:   # solo si lo eligió (las partidas de antes no tienen sexo: sin pasiva)
	return Datos.CAL and S != null and S.get("sexo") == "m"

# las casillas que ve una patrulla (de día o de noche; persiguiéndote, el doble)
func vista_pat(caza := false) -> int:
	var v := int(float(D.PAT.vista[0 if caza else (1 if is_night() else 0)]) * (2 if caza else 1))
	return v + (int(D.FISIO.sativa.vista) if efecto() == "sativa" else 0)   # MAESTRO [2]: con la sativa, la paranoia (te ven antes)

# MAESTRO [2] (con CAL): la borrachera (S.borr) y el colocón (S.colo), de 0 a 100, que bajan con las horas (FISIO.baja);
# S.efe.ind, el % índica de lo que has fumado (de su variedad): de FISIO.efecto para arriba se nota la sativa o la índica
func borr() -> float:
	return float(S.get("borr", 0)) if Datos.CAL and S != null else 0.0

func colo() -> float:
	return float(S.get("colo", 0)) if Datos.CAL and S != null else 0.0

func efecto() -> String:
	if colo() < float(D.FISIO.efecto):
		return ""
	return "indica" if float(S.get("efe", {}).get("ind", 50)) >= 50 else "sativa"

func fisio_pasa(mn: int) -> void:   # granja: con cada rato que pasa
	if not Datos.CAL:
		return
	for i in 2:
		var k: String = ["borr", "colo"][i]
		if S.has(k):
			S[k] = maxf(0, float(S[k]) - float(D.FISIO.baja[i]) * mn / 60.0)
			if S[k] <= 0:
				S.erase(k)
				if k == "colo":
					S.erase("efe")

func beber_alc(p: float) -> void:
	if Datos.CAL and p > 0:
		S.borr = minf(float(D.FISIO.tope), borr() + p)

# lo que sube fumar o catar: los mg de THC (g × % × 10) por FISIO.colo; el perfil, la media de lo fumado por lo que sube cada vez
var humo_ms := -1e9
func colocar(sid: String, mg: float) -> void:
	if not Datos.CAL or mg <= 0:
		return
	humo_ms = Time.get_ticks_msec()   # el humo en la pantalla (vision_borracho)
	var c0 := colo()
	var sube := minf(float(D.FISIO.tope) - c0, mg * float(D.FISIO.colo))
	if sube <= 0:
		return
	var st = Datos.strain(S, sid) if sid != "" else null
	var ind := float(st.get("ind", 50)) if st else 50.0
	var i0 := float(S.get("efe", {}).get("ind", ind))
	S.colo = c0 + sube
	S.efe = {"ind": snappedf((i0 * c0 + ind * sube) / (c0 + sube), 0.1)}
	if efecto() == "indica":
		S.ind_d = int(S.day)

func indica_ayer() -> bool:   # el curado de esta mañana: si ayer o hoy notaste la índica
	return Datos.CAL and int(S.get("ind_d", -9)) >= int(S.day) - 1

# personalizar la casa (1.16, 12c-salon): el tapizado o la lámina de un mueble (S.deco[k], índice en DECO[k].v) y su sprite
func deco_v(k: String) -> int:
	return int(S.deco.get(k, 0)) if S.get("deco") is Dictionary else 0

func deco_sprite(o: String) -> String:
	var v := deco_v(o) if D.DECO.has(o) else 0
	return (o + "-" + str(v)) if v else o

func sitio_visible(ci: int) -> bool:
	return not (ci < S.carpas.size() and S.carpas[ci]) and (ci < 2 or (S.carpas.size() > 1 and S.carpas[1] != null))

# (lo pidió el usuario: «la puerta del sótano está inaccesible porque hay una carpa delante» y «poder ordenar las carpas al
# gusto»): con CAL, el sitio de cada carpa es una pieza de ORDENAR LA CASA (carpa0..2, en la fila de la pared); la C, de serie junto
# a la cama (1, 2), fuera de delante de la puerta del pasillo
func sitio(ci: int) -> Dictionary:
	var s: Dictionary = D.SITIOS[ci]
	if not Datos.CAL or S == null or pieza_de("home", "carpa%d" % ci).is_empty():
		return s
	var p := pos_pieza("home", "carpa%d" % ci)
	return {"x": p[0], "y": p[1], "w": int(s.w)}

# las carpas del mapa (para pintarlas y abrirlas) donde las dejó aplica_orden
func carpas_casa(h: Dictionary) -> void:
	h.carpas = []
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if not c or not h.get("opos", {}).has("carpa%d" % ci):
			continue
		var p: Array = h.opos["carpa%d" % ci]
		h.carpas.append({"ci": ci, "t": c.t, "x0": int(p[0]), "x1": int(p[0]) + int(D.CARPAS[c.t].w) - 1, "y": int(p[1])})

func sitio_libre(x: int, y: int) -> int:
	for ci in D.SITIOS.size():
		var s: Dictionary = sitio(ci)
		if sitio_visible(ci) and x >= s.x and x < s.x + s.w and y == s.y:
			return ci
	return -1

# ---------- personajes (NPCDEF: cond y talk, que el JSON no lleva) ----------
# el título (1.35, renderDemo de 14-render): la partida de fondo, a partir del reloj (demo_en: el mismo instante, igual que en el
# HTML). demo_entra pone S, los personajes y el jugador de la demo y devuelve lo de la partida; demo_sale lo devuelve
var demo_s = null

var demo_e = null

func demo_en(R: Dictionary, T: float) -> Dictionary:
	var ruta: Array = R.ruta
	var dur := float(R.dur)
	var tr := []
	var tot := 0.0
	for i in ruta.size():
		var a: Array = ruta[i]
		var b: Array = ruta[(i + 1) % ruta.size()]
		var n: int = absi(int(b[0]) - int(a[0])) + absi(int(b[1]) - int(a[1]))
		tr.append([a, b, n])
		tot += n * dur + (float(b[2]) if b.size() > 2 else 0.0)
	var t := fmod(T, tot)
	for e in tr:
		var a: Array = e[0]
		var b: Array = e[1]
		var n: int = e[2]
		var dx: int = signi(int(b[0]) - int(a[0]))
		var dy: int = signi(int(b[1]) - int(a[1]))
		var dir := "right" if dx > 0 else "left" if dx < 0 else "down" if dy > 0 else "up"
		if t < n * dur:
			var k := floori(t / dur)
			var f: float = t - k * dur
			var x: int = int(a[0]) + dx * k
			var y: int = int(a[1]) + dy * k
			return {"x": x + dx, "y": y + dy, "px": (x + dx * f / dur) * 16, "py": (y + dy * f / dur) * 16, "dir": dir, "moving": true, "t": f, "dur": dur, "parity": k & 1}
		t -= n * dur
		var p: float = float(b[2]) if b.size() > 2 else 0.0
		if t < p:
			return {"x": int(b[0]), "y": int(b[1]), "px": float(b[0]) * 16, "py": float(b[1]) * 16, "dir": b[3] if b.size() > 3 else dir, "moving": false, "t": 0.0, "dur": dur, "parity": 0}
		t -= p
	var a0: Array = ruta[0]
	return {"x": int(a0[0]), "y": int(a0[1]), "px": float(a0[0]) * 16, "py": float(a0[1]) * 16, "dir": "down", "moving": false, "t": 0.0, "dur": dur, "parity": 0}

func demo_entra(now_: float) -> Array:
	var sv := [S, ents]
	var DM: Dictionary = D.DEMO
	if demo_s == null:
		demo_s = new_state()
		demo_s.map = DM.map
		demo_s.min = DM.min
	S = demo_s
	if demo_e == null:
		var quieto := func(id: String, x: int, y: int, dir: String, look, def: Dictionary) -> Dictionary:
			return {"id": id, "x": x, "y": y, "px": x * 16.0, "py": y * 16.0, "hx": x, "hy": y, "fx": x, "fy": y, "dir": dir, "look": look, "def": def,
				"wander": 0, "wt": 0.0, "moving": false, "t": 0.0, "dur": 320.0, "act": null}
		demo_e = []
		for d in D.NPCDEF:
			if d.map == DM.map and npc_cond(d):
				demo_e.append(quieto.call(d.id, int(d.x), int(d.y), d.dir if d.get("dir") else "down", d.get("lookObj") if d.get("lookObj") else D.LOOKS.get(d.get("look", "")), d))
		demo_e.append(quieto.call("demo1", int(DM.cliente[0]), int(DM.cliente[1]), "down", Datos.rand_look("demo1", "client"), {"client": {"type": "cur"}}))
		demo_e.append(quieto.call("demo2", 0, 0, "left", D.LOOKS.cop, {}))
		if Datos.CAL:   # 1.57: el atrezo del título, detrás del poli
			for i in DEMO_CAL.gente.size():
				demo_e.insert(demo_e.size() - 1, quieto.call("demoG%d" % i, 0, 0, "left", Datos.rand_look("demoG%d" % i, "client"), {}))   # i18n-no
			for i in DEMO_CAL.coches.size():
				var c: Array = DEMO_CAL.coches[i]
				var ce: Dictionary = quieto.call("demoC%d" % i, 0, int(c[1]), "right" if int(c[2]) > 0 else "left", Datos.rand_look("demoC%d" % i, "client"), {})   # i18n-no
				ce.veh = c[0]
				demo_e.insert(demo_e.size() - 1, ce)
	ents = demo_e
	var cal: bool = Datos.CAL
	demo_e[-1].merge(demo_en(DEMO_CAL.poli if cal else DM.poli, now_), true)
	P.merge(demo_en(DEMO_CAL.P if cal else DM.P, now_), true)
	if cal:
		for e in demo_e:
			if e.id.begins_with("demoG"):
				e.merge(demo_en(DEMO_CAL.gente[int(e.id.substr(5))], now_), true)
			elif e.id.begins_with("demoC"):
				e.merge(demo_coche(DEMO_CAL.coches[int(e.id.substr(5))], now_), true)
	return sv

# (lo pidió el usuario: «luego aparece la pantalla de inicio START con más atrezo»): en el título, con CAL, el protagonista y el
# poli por las aceras (no por la calzada), más gente andando y coches y una moto por la carretera, cada uno en su carril; los coches
# entran por un lado del mapa y salen por el otro, y vuelven al rato (coches: vehículo, fila, sentido, ms por casilla, desfase en ms)
const DEMO_CAL := {
	"P": {"dur": 320, "ruta": [[5, 9, 700, "down"], [11, 9, 1600, "right"], [5, 9, 500, "up"]]},
	"poli": {"dur": 420, "ruta": [[36, 12], [22, 12, 900, "up"]]},
	"gente": [{"dur": 360, "ruta": [[14, 9, 500, "up"], [37, 9, 800, "down"]]}, {"dur": 400, "ruta": [[2, 12, 700, "down"], [18, 12, 1100, "up"]]}],
	"coches": [["utilitario", 11, 1, 120, 0], ["berlina", 10, -1, 105, 2600], ["moto", 11, 1, 90, 4700], ["deportivo", 10, -1, 70, 7900]],
	"ancho": 64,   # casillas de vuelta: el mapa (40) y lo de fuera, para que no vayan pegados

}

func demo_coche(c: Array, T: float) -> Dictionary:
	var dur := float(c[3])
	var L: float = DEMO_CAL.ancho * dur
	var t := fmod(T + float(c[4]), L)
	var k := t / dur
	var x: float = -6.0 + k if int(c[2]) > 0 else 46.0 - k
	return {"x": int(round(x)), "y": int(c[1]), "px": x * 16, "py": float(c[1]) * 16, "dir": "right" if int(c[2]) > 0 else "left", "moving": true,
		"t": fmod(t, dur), "dur": dur, "parity": int(k) & 1}

func demo_sale(sv: Array) -> void:
	S = sv[0]
	ents = sv[1]

func npc_cond(d: Dictionary) -> bool:
	match d.id:
		"txomin":   # Google Play (Datos.PLAY): sin el bajo de las setas
			return not Datos.PLAY
		"tono":
			return S.ch >= 3 and S.ch < 8
		"inaki", "cop":
			return S.ch >= 2
		"darko":
			return (S.ch >= 2 and S.ch < 7 and not S.flags.get("darko1")) or S.ch == 6
		"darko2":
			return S.ch >= 7 and not S.flags.get("darkoFin")
		"miren":   # la amiga de la tía Maite (1.17)
			return S.ch >= int(D.MIREN.ch)
		"txaro":    # 1.10: después del aceite, en su casa
			return (d.map == "txaro") == (true if S.flags.get("txaro") else false)
		"molina":   # 1.10: la primera vez en la plaza; después, en la comisaría
			return S.ch >= 5 and (d.map == "comisaria") == (true if S.flags.get("molina1") else false)
		"tono2":
			return S.get("encargo") != null
		"jurado":
			return S.ch == 6 or cup_hoy()   # MAESTRO [5]: y los días de la CannaCup
		"julen":   # 1.23: en el piso hasta la primera cosecha; después, en el growshop
			return (S.flags.get("kiko1") and not S.flags.get("harvest1")) if d.map == "home" else (true if S.flags.get("harvest1") else false)
	if d.id.begins_with("est_") or d.id in ["camareraV", "vipA", "vipB", "gentD1", "gentD2", "gentD3"]:   # i18n-no · 1.47: el estanco, el reservado de GAUA y su gente de abajo
		return Datos.CAL
	if d.id.begins_with("neg_"):   # 1.45: la gente de los negocios alquilados
		return Datos.CAL and S.get("loc") is Dictionary and S.loc.has(d.id.substr(4))
	if d.id == "delroy":   # 1.32: en la asociación, desde la segunda visita
		return delroy_aqui()
	if d.id.begins_with("club_") or d.id.begins_with("pres_"):   # los clubs (1.15) y sus presidentes (1.34), desde su capítulo
		return S.ch >= int(D.CLUBS[d.id.substr(5)].ch)
	match d.id:   # los locales (1.30): cada trabajador de la nave, junto a su mesa; el portero de GAUA, desde su capítulo
		"nv0", "nv1", "nv2", "nv3":
			return S.get("nave") != null and navero_de(int(d.id.substr(2))) != null
		"nvm":   # 1.34: el de las madres
			return S.get("nave") != null and cuida_madres() != null
		"arantxa", "conce2":   # 1.43: el concesionario
			return S.get("flags") is Dictionary and S.flags.get("conce") != null
		"gorila":
			return S.ch >= int(D.DISCO.ch)
	return true

func npc_talk(d: Dictionary) -> void:
	if d.id.begins_with("sec_") or d.id.begins_with("secb_"):   # 1.51: los recados
		await talk_sec(d.id)
		return
	if d.get("look") == "cop" and d.id.begins_with("pat"):   # las patrullas (1.10)
		await say(pick([K("«Circule.»"), K("«Buenas. Nada que ver aquí.»"), K("«¿Todo bien? Siga.»")]), K("AGENTE"))
		return
	if d.id == "setero":   # 1.51
		await talk_setero()
		return
	if d.id.begins_with("m9_"):   # MAESTRO [9]: la ciudad (metro.gd)
		await talk_metro(d.id)
		return
	if d.id == "koldo":   # 1.51: el muelle
		await talk_koldo()
		return
	if d.id == "gorka":
		await talk_gorka()
		return
	if d.id.begins_with("neg_"):   # 1.45
		await talk_neg(d.id.substr(4))
		return
	if d.id.begins_with("est_"):   # 1.47
		await talk_estanco(d.id.substr(4))
		return
	match d.id:
		"kiko":
			await talk_kiko()
		"julen":
			await talk_julen()
		"ane":
			await talk_ane()
		"nerea":
			await talk_nerea()
		"bixente":
			await talk_bixente()
		"andoni":
			await talk_andoni()
		"miren":
			await talk_miren()
		"arrieta":   # la nave de Valdehierro (1.19)
			await talk_nave()
		"txomin":   # el bajo de las setas (1.20)
			await talk_txomin()
		"ibarbitarra":
			await say(pick([K("Esto es el Ensanche: pisos, oficinas y el parque. El Casco Viejo, por la avenida."), K("En Ibarbide hay policía en cada esquina. Y aun así..."), K("Los de los pueblos venís en autobús, ¿no? La estación está en el Casco.")]), K("VECINO"))
		"josune":
			await talk_josune()
		"baltasar":
			await talk_baltasar()
		"tono":
			await say(pick([K("Don Baltasar está ocupado. Habla con él si traes el dinero."), K("Aquí dentro no se hacen preguntas.")]), K("TOÑO"))
		"begona":   # 1.15: consejos, regalos y la jardinera
			await talk_begona()
		"club_puerto", "club_valde", "club_ibar", "club_ens", "club_rv":   # los clubs (1.15); la asociación (1.32)
			await talk_club(d.id.substr(5))
		"delroy":
			await talk_delroy()
		# los locales (1.30, 11j-locales)
		"socio":
			await talk_socio(S.map.substr(5))
		"billarista":
			await talk_billar(S.map.substr(5))
		"nv0", "nv1", "nv2", "nv3":
			await talk_navero(int(d.id.substr(2)))
		"nvm":   # 1.34: las madres de la nave
			await talk_madres()
		"arantxa":   # 1.43: el concesionario
			await talk_conce()
		"conce2":
			await say(pick([K("Vengo a por la berlina de empresa. Bueno, a mirar; lo de comprar, lo decide mi mujer."), K("¿Has visto el rojo? Doscientos cuarenta y cinco mil. Con eso me compro dos pisos en el pueblo."), K("La moto es lo más práctico: aparcas en cualquier sitio y gasta nada.")]), K("CLIENTE"))
		"cg1", "cg2", "cg3", "cg4":   # 1.34: los demás socios de cada club
			await talk_gente_club(S.map.substr(5), int(d.id.substr(2)) - 1)
		"pres_puerto", "pres_valde", "pres_ibar", "pres_ens":   # 1.34: los presidentes de los clubs de fuera
			await talk_presi(d.id.substr(5))
		"gorila":
			await talk_gorila()
		"camarera", "camareraV":
			await talk_barra()
		"vipA", "vipB":   # 1.47 · i18n-no
			await talk_vip(0 if d.id == "vipA" else 1)
		"gentD1", "gentD2", "gentD3":   # i18n-no · 1.47: la gente de la pista, la que se ve desde el cristal del reservado
			await say(D.DISCO_CAL.gente[(int(d.id.substr(5)) + S.day) % D.DISCO_CAL.gente.size()], K("GENTE"))
		"dj":
			await talk_dj()
		"rrpp":
			await talk_rrpp()
		"baila1", "baila2", "baila3":
			await talk_baila(int(d.id.substr(5)) - 1)
		"unai":
			await say(pick([K("Si mantienes pulsado B, corres."), K("Mi hermano dice que de noche, en la hierba alta del parque, roban a la gente."), K("Con START abres tu GENOTECA y la mochila."), K("En los arbustos del parque la gente esconde cosas. Mira delante de ellos con A.")]), K("UNAI"))
		"patxi":
			await talk_patxi()
		"txaro":
			await talk_txaro()
		"inaki":
			await talk_inaki()
		"cop":
			await talk_cop()
		"darko", "darko2":
			await talk_darko()
		"tono2":
			await talk_tono_almacen()
		"molina":
			await talk_molina()
		"jurado":
			await talk_jurado()
		# la comarca (1.10)
		"vecina":
			await say(pick([K("En Mendialde el autobús para en la plaza. El último sale a las nueve."), K("Tu ama dice que en la ciudad no comes. Llévate el táper."), K("Aquí el maíz se siembra en mayo y se recoge en octubre. Como toda la vida.")]), K("VECINA"))
		"excursionista":
			await say(pick([K("El molino tiene trescientos años. Todavía muele algún domingo."), K("Del puente para arriba, el río baja limpio. Para abajo, ya no tanto."), K("Vengo en el autobús de Ribera Verde: treinta minutos y tres euros.")]), K("EXCURSIONISTA"))
		"turista":
			await say(pick([K("Las casas son de colores para que cada pescador viera la suya desde el mar."), K("Dicen que en este puerto se paga bien... y que la policía mira poco."), K("He venido a por anchoas y me han ofrecido de todo.")]), K("TURISTA"))
		"obrero":
			await say(pick([K("La fundición cerró hace años. Ahora el solar es del chatarrero."), K("Aquí la gente cobra poco y paga poco. Y de noche, cuidado con la cartera."), K("De Valdehierro a Ribera Verde, veinte minutos de autobús.")]), K("OBRERO"))

func mk_ent(d: Dictionary) -> Dictionary:
	var look = d.get("lookObj")
	if look == null:
		look = D.LOOKS.get(d.get("look", ""))
		if Datos.CAL and look and D.GENERO.look.has(d.get("look", "")):   # 1.43.3: cada nombre con su muñeco
			look = look.duplicate()
			look.id = D.GENERO.look[d.look]
	return {"id": d.id, "x": d.x, "y": d.y, "px": d.x * 16.0, "py": d.y * 16.0, "hx": d.x, "hy": d.y, "dir": d.dir if d.get("dir") else "down",
		"look": look, "def": d, "wander": d.get("wander", 0) if d.get("wander") else 0, "wt": 800 + Cultivo.azar() * 2400, "moving": false, "t": 0.0, "fx": d.x, "fy": d.y, "act": null}

func build_ents() -> void:
	var old := {}
	for e in ents:
		old[e.id] = e
	ents = []
	for d in D.NPCDEF:
		if d.map != S.map or not npc_cond(d):
			continue
		ents.append(old[d.id] if old.has(d.id) and is_same(old[d.id].def, d) else mk_ent(d))
	if Datos.CAL:   # 1.51: la gente de los recados (D.SECUNDARIAS), desde su capítulo
		for sc in D.get("SECUNDARIAS", []):
			if int(S.ch) < int(sc.ch):
				continue
			for ab in ["a", "b"]:
				if not sc.has(ab) or sc[ab].map != S.map or (ab == "b" and sec_estado(sc.id) != 1):
					continue
				var dd: Dictionary = sc[ab].duplicate()
				dd.id = ("sec_" if ab == "a" else "secb_") + sc.id
				ents.append(old[dd.id] if old.has(dd.id) else mk_ent(dd))
	if Datos.CAL and S.map == "setas" and S.get("setas") is Dictionary and S.setas.get("ay") and int(MAPS.setas.w) > 10:   # 1.51: el ayudante del bajo
		var A: Dictionary = D.SETAS_AY
		ents.append(old["setero"] if old.has("setero") else mk_ent({"id": "setero", "map": "setas", "x": int(A.x), "y": int(A.y), "look": A.look, "dir": "down", "wander": 0}))
	if Datos.CAL and D.has("MAR") and S.map == "muelle":   # 1.51: Koldo en el muelle y Gorka en el piso franco
		var K: Dictionary = D.MAR.koldo
		ents.append(old["koldo"] if old.has("koldo") else mk_ent({"id": "koldo", "map": "muelle", "x": int(K.x), "y": int(K.y), "look": K.look, "dir": "down", "wander": 0}))
	if Datos.CAL and D.has("MAR") and S.map == "franco" and S.get("franco") is Dictionary:
		var Gk: Dictionary = D.MAR.gorka
		ents.append(old["gorka"] if old.has("gorka") else mk_ent({"id": "gorka", "map": "franco", "x": int(Gk.x), "y": int(Gk.y), "look": Gk.look, "dir": "down", "wander": 0}))
	for dd in metro_npcs(S.map):   # MAESTRO [9]: el concejal, las bandas y los encargados de los clubs VIP
		ents.append(old[dd.id] if old.has(dd.id) else mk_ent(dd))
	for c in S.clients:
		if c.get("map", "town") == S.map:
			ents.append(old[c.id] if old.has(c.id) else mk_ent({"id": c.id, "x": c.x, "y": c.y, "wander": 2, "lookObj": c.look, "client": c}))
	for e in old.values():   # las patrullas (más abajo)
		if e.get("pat") and e.mapa == S.map:
			ents.append(e)
	pon_patrullas()
	if D.ORDEN_P.has(S.map):
		coloca_gente(S.map)   # 1.37: la gente de los sofás y del billar, donde estén (12d-orden)
	if S.map == "nave":
		coloca_naveros()   # 1.35
		if Datos.CAL and puertas_int("nave").size():   # 1.55.2: el de las madres, delante de su carpa y no de la puerta de la habitación
			for e in ents:
				if e.id == "nvm" and not MAPS.nave.o[3][16]:
					e.x = 16; e.y = 3; e.px = 256.0; e.py = 48.0; e.hx = 16; e.hy = 3; e.fx = 16; e.fy = 3; e.dir = "up"; e.moving = false
		for e in ents:   # 1.43.3: el muñeco de cada uno, del sexo de su nombre
			if e.id.length() == 3 and e.id.begins_with("nv"):
				var w = cuida_madres() if e.id == "nvm" else navero_de(int(e.id[2]))
				if w:
					var lk = D.LOOKS.get(e.def.get("look", ""))
					e.look = look_genero(lk, str(w.n), 4 if e.id == "nvm" else int(e.id[2]), D.GENERO.naveH, D.GENERO.naveM)

# dónde trabaja cada uno de la nave (1.35, colocaNaveros de 11j-locales): por la hora, el día y su mesa
const PUESTO_MIN := 120

func puestos_mesa(i: int) -> Array:   # 1.37: donde esté la mesa, en las casillas libres; detrás, solo si no tapa nada (ni el sitio del tanque)
	var XY := pos_mesa(i)
	var X: int = XY[0]
	var Y: int = XY[1]
	var m: Dictionary = MAPS.nave
	var T := pos_pieza("nave", "riego")
	var p := [[X, Y + 1, "up"], [X + 1, Y + 1, "up"], [X - 1, Y, "right"]]
	if Y - 1 >= 3 and not m.o[Y - 2][X] and not (T[0] == X and T[1] == Y - 2):
		p.append([X, Y - 1, "down"])
	var q := p.filter(func(c): return pisable(m, c[0], c[1]) and not m.o[c[1]][c[0]])
	return q if q.size() else [[X, Y + 1, "up"]]

func puesto_navero(i: int) -> Array:
	var p := puestos_mesa(i)
	return p[(int(floor(float(S.min) / PUESTO_MIN)) + int(S.day) + i) % p.size()]

func coloca_naveros() -> void:
	for e in ents:
		var id := str(e.id)
		if not (id.length() == 3 and id.begins_with("nv") and id[2] >= "0" and id[2] <= "9"):
			continue
		var q := puesto_navero(int(id[2]))
		var x := int(q[0])
		var y := int(q[1])
		if int(e.x) == x and int(e.y) == y and e.get("puesto"):
			continue
		e.x = x; e.y = y; e.px = x * 16.0; e.py = y * 16.0; e.hx = x; e.hy = y; e.fx = x; e.fy = y; e.dir = q[2]; e.moving = false; e.puesto = 1

func item_give(id: String) -> void:
	match id:
		"i_spray":
			S.items.spray += 2
			await got(K("2 × SPRAY DE PIMIENTA"))
		"i_fert":
			S.items.fert += 3
			await got(K("3 dosis de MEATZA FLORACIÓN"))
		"i_boc":
			S.items.bocata += 2
			await got(K("2 × BOCATA"))
		"h_acap":
			add_seeds("acapulco", 2)
			await got(K("2 semillas de ACAPULCO GOLD"))
			await say(K("Un bote de carrete con dos semillas y una etiqueta a boli: «Guerrero, 1979»."))
		"h_50":
			S.money += 50
			await got(K("50 € en billetes doblados"))
		"h_ins":
			S.items.insect += 1
			await got(K("1 tratamiento de INSECTICIDA"))
		"i_ast":
			S.items.spray += 2
			await got(K("2 × SPRAY DE PIMIENTA"))
		"h_alto":
			S.money += 80
			await got(K("80 € en un sobre arrugado"))
		"h_kale":   # la Kale Zaharra (1.14)
			S.money += 120
			await got(K("120 € en una riñonera abandonada"))
		"h_lamb":   # las de la tía Maite (1.25)
			await semillas_tia("lamb", K("Una lata de tabaco oxidada con una etiqueta a boli: «Jamaica». Es la letra de la tía Maite."))
		"h_kerala":
			await semillas_tia("kerala", K("Un bote de carrete envuelto en plástico: «Kerala, India». Es la letra de la tía Maite."))
		"h_manga":
			await semillas_tia("mangarosa", K("Un sobre en una bolsa de congelar: «Manga Rosa · Brasil». Es la letra de la tía Maite."))
		"h_mallas":   # 1.36: las mallas 00, en un arbusto de Mendialde
			S.items.mallas00 = 1
			await got(K("unas MALLAS 00 (DOBLE CERO)"))
			await say(K("Una bolsa de tela con un bastidor y una malla finísima: «00». Con esto se tamiza en seco lo más fino, solo las cabezas de resina."))
		"h_hawai":
			await semillas_tia("hawai", K("Un tubo de pastillas con semillas dentro: «Hawái». Es la letra de la tía Maite."))

func item_at(x: int, y: int):
	for it in D.ITEMS:
		if not it.hidden and it.map == S.map and it.x == x and it.y == y and not S.taken.get(it.id):
			return it
	return null

func pick_item(it: Dictionary) -> void:
	S.taken[it.id] = true
	await item_give(it.id)

func tile_solid(m: Dictionary, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= m.w or y >= m.h:
		return true
	if SOLID_G.search(m.g[y][x]) or m.o[y][x]:
		return true
	return item_at(x, y) != null

# la casilla donde deja el autobús en este mapa (1.10): ahí no se para nadie
func llegada_bus(x: int, y: int) -> bool:
	var pa = D.PARADAS.get(S.map)
	return pa != null and int(pa.a[0]) == x and int(pa.a[1]) == y

func ent_at(x: int, y: int):
	for e in ents:
		if (e.x == x and e.y == y) or (e.moving and e.fx == x and e.fy == y):
			return e
	return null

# (lo pidió el usuario: «la casa de Txaro es la casa con menos atrezo que hay en el mundo… que en casi todos los lugares donde
# puedes interactuar con alguien, que tenga un poquito de atrezo»): lo que se añade, con CAL, en las casillas que estén libres; cada
# cosa con su texto (ATREZO_TXT). Nada corta el paso (lo comprueba tests/atrezo.gd)
const ATREZO := {
	"txaro": [[3, 2, "tv"], [4, 2, "tv2"], [6, 1, "cuadro"], [8, 2, "libreria"], [3, 4, "sillon"], [4, 4, "sillon2"], [5, 5, "silla"], [8, 6, "mesita"], [5, 1, "cartel"]],
	"casa-ama": [[4, 1, "cuadro"], [3, 2, "libreria"], [7, 2, "sillon"], [8, 2, "sillon2"], [5, 5, "silla"], [8, 6, "mesita"]],
	"comisaria": [[6, 2, "escritorio"], [7, 2, "escritorio2"], [3, 1, "cuadro"]],
	"almacen": [[3, 2, "sacos"], [2, 1, "red"], [7, 2, "estanteN"], [8, 4, "barrilT"]],   # i18n-no
	# (lo pidió el usuario: «está muy vacío… el atrezo deja que desear o por lo menos cómo está usado»): el taller, cada cosa en
	# su zona: la manguera del aire sobre el elevador, el bidón y la grúa junto a los puestos, el lavabo entre el banco y el compresor,
	# las ruedas nuevas en su estantería, el extintor junto a la puerta del cuartucho, entre las cajas y la recogedora y la espera con su máquina de café
	"loc-valde": [[3, 1, "mangT"], [17, 1, "calT"], [11, 2, "lavabT"], [15, 2, "rackT"], [19, 3, "extinT"], [0, 6, "bidonT"],   # i18n-no
		[6, 6, "gatoT"], [6, 7, "gruaT"], [19, 6, "cajonT"], [19, 7, "bidonT"], [14, 9, "sillaT"], [16, 9, "cafeM"]],   # i18n-no

}

# El suelo del taller por zonas (x0, y0, x1, y1, casilla): el hormigón de los puestos (con manchas de aceite por hash_t), la
# línea amarilla que los separa del paso, la goma delante del banco y del lavabo, el gres de la espera y el sumidero entre el elevador
# y el foso; el resto, la resina azul de siempre
const TALLER_SUELO := [[0, 2, 5, 9, "floorTc"], [6, 2, 6, 9, "floorTcR"], [8, 5, 12, 8, "floorTc"], [8, 5, 12, 5, "floorTcT"],   # i18n-no
	[9, 3, 11, 3, "floorTg"], [9, 9, 16, 9, "floorTr"], [3, 6, 3, 6, "floorTd"]]   # i18n-no

var ATREZO_TXT := {   # F7: var, por K()
	"txaro": {"tv": I18n.K("La tele, con un tapete de ganchillo encima del mueble. Echan un concurso."), "tv2": I18n.K("La tele, con un tapete de ganchillo encima del mueble. Echan un concurso."),
		"cuadro": I18n.K("Una lámina de la ría. La enmarcó su Paco en el sesenta y ocho."), "libreria": I18n.K("Novelas de bolsillo, un misal y un álbum de fotos de un viaje a las montañas."),
		"mesita": I18n.K("Un costurero abierto y unas gafas de cerca."), "cartel": I18n.K("Un póster del faro de Puerto Viejo. Paco trabajó allí de joven.")},
	"casa-ama": {"cuadro": I18n.K("Una lámina del monte, con el marco descolorido por el sol."), "libreria": I18n.K("Los libros de aitona: el monte, los pájaros y una enciclopedia por fascículos."),
		"mesita": I18n.K("Una radio vieja con la emisora de la comarca.")},
	"comisaria": {"escritorio": I18n.K("Una mesa con un ordenador viejo y una montaña de atestados."), "escritorio2": I18n.K("Una mesa con un ordenador viejo y una montaña de atestados."),
		"cuadro": I18n.K("Una lámina de la ría, torcida. Nadie la endereza.")},
	"almacen": {"sacos": I18n.K("Sacos de sal gorda de la conservera."), "red": I18n.K("Una red de pesca vieja, colgada de un clavo."), "estanteN": I18n.K("Una estantería con latas oxidadas y cuerdas."),
		"barrilT": I18n.K("Un bidón azul. Huele a gasoil.")},
	"loc-valde": {"mangT": I18n.K("El enrollador de la manguera del aire, colgado encima del elevador: se estira hasta el coche y vuelve solo."),
		"calT": I18n.K("Un calendario de pared con un coche de rally de los noventa, sin marca. Los días de las citas, en rojo."),
		"lavabT": I18n.K("El lavabo de acero con el jabón de taller, el de la piedra pómez, y un rollo de papel azul."),
		"rackT": I18n.K("La estantería de las ruedas nuevas, de pie y con su etiqueta de medida."),
		"extinT": I18n.K("El extintor de polvo de 6 kg, con la revisión al día y su placa encima."),
		"bidonT": I18n.K("Un bidón de 200 litros de aceite usado, esperando al gestor de residuos."),
		"gatoT": I18n.K("El gato de carretilla de 3 toneladas: se mete debajo del coche y se bombea con la palanca."),
		"gruaT": I18n.K("La grúa de motores, plegada: con la pluma y la cadena se saca un motor entero."),
		"cajonT": I18n.K("El armario de herramientas grande: siete cajones de llaves, carracas y vasos, y encima la caja de las brocas."),
		"sillaT": I18n.K("Las sillas de la espera, de plástico. Una revista de coches de hace dos años."),
		"cafeM": I18n.K("La máquina de café de la espera: solo, cortado y chocolate. El de chocolate sale aguado.")},

}

var ASIENTO_FUERA := {"sofa": I18n.K("Un sofá."), "sillon": I18n.K("Un sillón."), "silla": I18n.K("Una silla.")}

func montar_atrezo(k: String) -> void:
	if not Datos.CAL or not ATREZO.has(k) or not MAPS.has(k):
		return
	var m: Dictionary = MAPS[k]
	if m.get("atrezo"):
		return
	m.atrezo = true
	for a in ATREZO[k]:
		if m.o[a[1]][a[0]] == null:
			m.o[a[1]][a[0]] = a[2]

# (lo preguntó el usuario: «los árboles no pueden estar encima de los edificios, ¿no?»): con CAL, ningún árbol, manzano ni mata del
# monte se pinta encima de un edificio (sus píxeles, con el desfase, el espejo y el ancla de pinta.gd). Los que tienen el pie detrás o
# al lado (por encima de la última fila del edificio) van en m.tras y se pintan antes que los edificios, que los tapan; los de delante,
# cuya copa taparía la fachada, se quitan (en _arb0, y vuelven sin CAL). Se rehace si cambian los edificios del mapa
const ARBOLES := ["tree", "tree2", "manzano", "monte", "monte2"]   # i18n-no
const Pintor = preload("res://src/pinta.gd")
var _arb0 := {}   # mapa → [[x, y, el que se quitó]]
var _arb_k := {}  # mapa → los edificios con los que se calculó

func arboles_fuera(k: String) -> void:
	if not MAPS.has(k):
		return
	var m: Dictionary = MAPS[k]
	var bl: Array = m.get("blds", [])
	var clave := str(bl)
	if Datos.CAL and (_arb_k.get(k) == clave or not Atlas.carga()):
		return
	for q in _arb0.get(k, []):
		m.o[q[1]][q[0]] = q[2]
	_arb0.erase(k)
	_arb_k.erase(k)
	m.erase("tras")
	if not Datos.CAL:
		return
	_arb_k[k] = clave
	_arb0[k] = []
	m.tras = {}
	var ed := []   # [esquina en px, su imagen, la fila de debajo de su última fila]
	for b in bl:
		var f = Atlas.frame_de("edificio-" + String(b.get("fachada", b.id)), "base", "unica", 0, {"i": 0})
		if f != null:
			ed.append([Vector2i(int(b.x0) * 16, int(b.y0) * 16), f.c, int(b.y0) + int(b.h)])
	if ed.is_empty():
		return
	for ty in int(m.h):
		for tx in int(m.w):
			var o = m.o[ty][tx]
			if not (o in ARBOLES):
				continue
			var d: Dictionary = Pintor.desfase(o, tx, ty)
			var f = Atlas.frame_de(Atlas.cubre("obj:" + o), o, "unica", 0, {"i": 0, "esp": d.esp})
			if f == null:
				continue
			var p := Vector2i(tx * 16 + 8 + int(d.dx) - int(f.cel.ancla[0]), ty * 16 + 15 + int(d.dy) - int(f.cel.ancla[1]))
			var pisa := false
			var delante := false
			for e in ed:
				if _pisa(f.c, p, e[1], e[0]):
					pisa = true
					delante = delante or ty >= int(e[2])
			if delante:
				_arb0[k].append([tx, ty, o])
				m.o[ty][tx] = null
			elif pisa:
				m.tras["%d,%d" % [tx, ty]] = true

# ¿se tocan dos imágenes (a en pa, b en pb) en algún píxel con algo?
static func _pisa(a: Image, pa: Vector2i, b: Image, pb: Vector2i) -> bool:
	var r := Rect2i(pa, a.get_size()).intersection(Rect2i(pb, b.get_size()))
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if a.get_pixel(x - pa.x, y - pa.y).a > 0 and b.get_pixel(x - pb.x, y - pb.y).a > 0:
				return true
	return false

func enter_map(name_: String, x: int, y: int, dir = null) -> void:
	SENT = null   # 1.49: al cambiar de sitio, de pie
	S.map = name_
	montar_huerta(name_)   # con CAL, la huerta de la tía (campo.gd): la cancilla del pueblo y su mapa
	if name_ == "home":
		montar_casa()
	if name_ == "nave":
		montar_nave()
	if Datos.CAL and name_ == "valdehierro" and S.flags.get("naveVer"):   # de ver la nave por dentro: Arrieta, en la calle, pregunta
		S.flags.erase("naveVer")
		if S.get("nave") == null:
			queue("naveVer", func(): await nave_vista())   # i18n-no
	if name_ == "alto":
		montar_alto()
	if name_ == "camarote":
		montar_camarote()
	if name_ == "nave-d":
		montar_despacho()
	if name_ == "setas":
		montar_setas()
	montar_locales(name_)   # 1.45: la puerta de los negocios y sus mejoras
	montar_estancos(name_)   # 1.47: el estanco de cada pueblo
	if name_ in ["disco", "disco-vip", "ensanche"]:
		montar_disco()
	if Datos.CAL and VITRINA_GROW.has(name_):   # 1.47: la vitrina de las pipas y demás en los dos grows
		var vg: Array = VITRINA_GROW[name_]
		MAPS[name_].o[vg[1]][vg[0]] = "vitrinaP"   # i18n-no
		MAPS[name_].o[vg[1]][vg[0] + 1] = "vitrinaP2"   # i18n-no
	if Datos.CAL and CAJERO_CAL.has(name_):
		var cj: Array = CAJERO_CAL[name_]
		if MAPS[name_].o[cj[0][1]][cj[0][0]] == "cajero":
			MAPS[name_].o[cj[0][1]][cj[0][0]] = null
			MAPS[name_].o[cj[1][1]][cj[1][0]] = "cajero"
	montar_club(name_)
	montar_atrezo(name_)
	if name_ != "home" and name_ != "nave":
		montar_puertas(name_)
	montar_muelle(name_)
	montar_campo(name_)   # MAESTRO [4]
	montar_carreteras(name_)   # la red de carreteras que se andan (CARRETERAS)
	montar_garaje(name_)
	montar_aparcamiento(name_)
	arboles_fuera(name_)   # con CAL, ningún árbol encima de un edificio
	P.x = x
	P.y = y
	P.px = x * 16.0
	P.py = y * 16.0
	P.fx = x
	P.fy = y
	P.moving = false
	P.chain = false
	P.hold = 0.0
	if dir:
		P.dir = dir
	S.x = x
	S.y = y
	S.dir = P.dir
	ents = []
	reset_sosp()
	build_ents()
	music(map_music())

# cada mapa lleva su canción (04-mapas); en la calle, de noche, su versión nocturna (Ribera: night); 1.30: con la alarma,
# la suya, y el piso de noche, la suya
func map_music() -> String:
	var m: String = MAPS[S.map].music
	if D.ZONAS.has(S.map) and SOSP.alarma != null:
		return "alarma"
	if S.map == "home" and is_night():
		return "home_n"
	if D.ZONAS.has(S.map) and is_night():
		return "night" if m == "town" else m + "_n"
	return m

func warp(w: Dictionary) -> void:
	sfx("door")
	await fade(1)
	var vo = volante_llega(w)   # con CAL, al volante por una carretera: aparcado en el pueblo al que llegas (eventos.gd)
	if vo:
		enter_map(w.to, int(vo.a[0]), int(vo.a[1]), vo.a[2])
	else:
		enter_map(w.to, w.x, w.y, w.dir)
	update_hud()
	await wait(80)
	await fade(0)
	if vo:
		await volante_fin(vo)

var paso_sobra := 0.0

# sentarse (1.47, solo con CAL): en los asientos, mirando al sur (se ven de frente) o al norte (de espaldas); sentado, fumarte
# uno de lo que lleves (medio gramo), pedir algo, hablar con el de al lado, el móvil, quedarte un rato o levantarte; no se guarda
const ASIENTOS := {"sofaF": "sur", "sofaV": "sur", "bench": "sur", "sofaB": "norte", "sofa": "norte", "sillon": "norte", "silla": "norte", "sillaG": "norte", "stool": "norte",
	"sillaTs": "sur", "sillaTn": "norte", "taburTb": "norte", "sillaT": "sur"}   # 1.57.2: las sillas y los taburetes de la taberna y la espera del taller, muebles de verdad

var ASIENTO_TXT := {"sofaF": I18n.K("Un sofá del club."), "sofaB": I18n.K("Un sofá del club."), "sofaV": I18n.K("El sofá del reservado."), "bench": I18n.K("Un banco."), "stool": I18n.K("Un taburete."),
	"sofa": I18n.K("Tu sofá."), "sillon": I18n.K("Tu sillón de lectura."), "silla": I18n.K("La silla del ordenador de la tía."), "sillaG": I18n.K("Tu silla gaming."),
	"sillaTs": I18n.K("Una silla de la taberna."), "sillaTn": I18n.K("Una silla de la taberna."), "taburTb": I18n.K("Un taburete de la barra."), "sillaT": I18n.K("Las sillas de la espera.")}

# (lo pidió el usuario: «la altura correcta en todos los muebles donde se puede sentar»): por asiento, [dx, cadera]: dx,
# lo que se corre a la derecha para quedar en medio del dibujo (la silla gaming, de 2 casillas, va centrada entre las dos), y
# cadera, la fila de la casilla (0 arriba, 15 los pies de pie) en la que queda la cadera, la del cojín medida en cada sprite;
# de pie, en la 9. De espaldas, la cabeza asoma por encima del respaldo (en la silla gaming, alto, la cadera por encima
# del cojín para que se vea la cabeza; lo de debajo lo tapa el respaldo). El taburete, con SENT_TABURETE en pinta.gd
const SENT_GEO := {"silla": [0, 1], "sillaG": [8, 2], "sillon": [0, 7], "sofa": [0, 8], "sofaB": [0, 9], "sofaF": [2, 7], "sofaV": [2, 7], "bench": [0, 9], "stool": [0, 4],
	"sillaTs": [0, 8], "sillaTn": [0, 5], "taburTb": [0, 4], "sillaT": [-6, 8]}

const TABURETES := ["stool", "taburTb"]   # 1.57.2: con las piernas de SENT_TABURETE (pinta.gd)   # i18n-no

const SENT_PORRO := 0.5

var SENT = null   # {x, y, d}

# bebidas en la barra o en la mesa, por sitio (1.49): [texto, euros, minutos, borrachera que sube (MAESTRO [2], con CAL)]
var BEBIDAS := {
	"bar": [[I18n.K("Un café"), 1.5, 10, 0], [I18n.K("Una caña"), 2.5, 15, 10], [I18n.K("Un refresco"), 2.2, 15, 0], [I18n.K("Un vino"), 2.0, 15, 12]],
	"club": [[I18n.K("Un café"), 1.2, 10, 0], [I18n.K("Un refresco"), 1.8, 15, 0], [I18n.K("Un zumo"), 2.0, 15, 0], [I18n.K("Una cerveza"), 2.2, 15, 12]],
	"disco": [[I18n.K("Un refresco"), 5.0, 15, 0], [I18n.K("Una cerveza"), 6.0, 15, 12], [I18n.K("Una copa"), 9.0, 20, 25]],

}

# (lo pidió el usuario): con qué se fuma. El papel, el tabaco, las boquillas y el mechero, del estanco (ESTANCO); la pipa,
# el bong, el vaporizador y el grinder, del grow (PARAFERNALIA). g: cogollos por vez (el porro, con tabaco, gt); gr: extracto
# por vez (0 = el porro no lleva extracto); con: lo que hace falta en S.items
var FUMAR := {
	"porro": {"n": I18n.K("Liarte un porro"), "g": 0.5, "gt": 0.3, "gr": 0.0, "grt": 0.1, "con": ["papel", "mechero"]},   # grt (1.57.1): extracto con tabaco
	"pipa": {"n": I18n.K("Una pipa"), "g": 0.2, "gr": 0.1, "con": ["pipa", "mechero"]},
	"bong": {"n": I18n.K("Un bong"), "g": 0.3, "gr": 0.1, "con": ["bong", "mechero"]},
	"vapo": {"n": I18n.K("El vaporizador"), "g": 0.2, "gr": 0.1, "con": ["vapo"]},

}

const NO_FUMAR := ["bar", "disco", "disco-vip", "shop", "growcity"]

func talk_vip(_i: int) -> void:   # trama (1.47)
	pass

func talk_estanco(_k: String) -> void:   # trama (1.47)
	pass

func marca_cata(_k: String, _r: bool, _sid: String, _thc: float) -> void:   # trama (1.47)
	pass

# ---------- clientes y venta (10-calle) ----------
func precio_calle(thc: float) -> float:
	return 4 + thc * .2

func precio_mayor(thc: float) -> float:
	return 2 + thc * .1

# rosin (1.10, 10-calle): el gramo, a 10 + 0,6 × THC €
func precio_rosin(thc: float) -> float:
	return 10 + thc * .6

# ---------- patrullas (1.10, 10b-patrulla.js): los policías se ven por la calle ----------
# PATRULLAS, PAT, CALLE, TAPA_VISTA y las casillas de ronda de cada mapa (RONDA) vienen del HTML (tools/godot.js)
var SOSP := {"v": 0.0, "alarma": null, "sinVer": 0.0, "aviso": 0, "tregua": 0.0}

var _re_calle: RegEx = null

var _re_tapa: RegEx = null

var _re_edif := RegEx.create_from_string("^(roof|wall|win|door)")

static func _hash_t(x: int, y: int) -> int:
	var a := (x * 1103 + y * 2459 + x * y * 31) % 9973
	return (a * a + x * 7 + y * 3) % 9973

# ---------- virtuales: las definen granja, trama y juego ----------
func check_story():
	pass

func revisa_misiones() -> void:
	pass

func talk_kiko():
	pass

func talk_julen():
	pass

func itin_ok(_id: String) -> bool:
	return false

func talk_ane():
	pass

func talk_nerea():
	pass

func talk_bixente():
	pass

func talk_andoni():
	pass

func extraer(_t: String):
	pass

func talk_nave():
	pass

func talk_txomin():
	pass

func setas_dia():
	pass

func talk_miren():
	pass

func talk_josune():
	pass

func talk_baltasar():
	pass

func talk_patxi():
	pass

func talk_txaro():
	pass

func talk_sec(_id: String) -> void:   # 1.51 (trama.gd)
	pass

func talk_koldo() -> void:   # 1.51 (trama.gd)
	pass

func talk_gorka() -> void:   # 1.51 (trama.gd)
	pass

func talk_setero() -> void:   # 1.51 (trama.gd)
	pass

func sec_estado(_id: String) -> int:
	return 0

func talk_inaki():
	pass

func talk_cop():
	pass

func talk_darko():
	pass

func talk_molina():
	pass

func talk_jurado():
	pass

func talk_tono_almacen():
	pass

func diploma_action():
	pass

func instalar_caja():
	pass

func vencer_encargo():
	pass

func robo_darko():
	pass

func recibir_envio():
	pass

func talk_begona():
	pass

func talk_club(_k):
	pass

# la asociación (1.32, trama.gd)
func delroy_aqui() -> bool:
	return false

func talk_delroy():
	pass

# los locales (1.30, trama.gd)
func naveros() -> Array:
	return []

func navero_de(_i: int):
	return null

func nave_vista() -> void:
	pass

func entra_local(_d):
	pass

func advance_time(_mn: int) -> void:   # granja (1.47: fumar sentado)
	pass

func obj_local(_x: int, _y: int, _o) -> bool:
	return false

func disco_abierta() -> bool:
	return false

func echar_disco():
	pass

func talk_socio(_k):
	pass

func talk_billar(_k):
	pass

func talk_navero(_i):
	pass

func cuida_madres():
	return null

func sprite_local(o: String) -> String:
	return o

func bandejas_balda(_x: int) -> Array:
	return []

func talk_madres():
	pass

func talk_conce():   # trama (1.43)
	pass

func coches_mios() -> Array:
	return []

func conducir(_k):
	pass

func volante_llega(_w: Dictionary):   # con CAL, en eventos.gd
	return null

func volante_fin(_vo: Dictionary) -> void:
	pass

func coche_menu(_k: String):   # MAESTRO [3], en eventos.gd
	pass

func garaje_menu():   # MAESTRO [3], en eventos.gd
	pass

func maletero(_k: String) -> void:   # MAESTRO [3], en eventos.gd
	pass

func montar_aparcamiento(_mapa: String) -> void:   # MAESTRO [3], en calle.gd
	pass

func llegada_parque(_mapa: String, _k: String) -> Array:   # MAESTRO [3], en calle.gd
	return []

func montar_garaje(_mapa: String) -> void:   # MAESTRO [3], en calle.gd
	pass

func seguro_anio(_k) -> int:
	return 0

func conce_dia() -> void:
	pass

func talk_gente_club(_k, _j):
	pass

func talk_presi(_k):
	pass

func talk_gorila():
	pass

func talk_barra():
	pass

func talk_dj():
	pass

func talk_rrpp():
	pass

func talk_baila(_i):
	pass

func curro_dia():
	pass

func vencer_encargo_club():
	pass

func notas_tia():
	pass

func pedir_caja():
	pass

func cajero():
	pass

func rotulo_local(_k):
	pass

func local_de(_m: String, _x: int, _y: int) -> String:
	return ""

func battle(_kind):
	pass

func rival_venta(_z):
	pass

func recetario():
	pass

func start_menu():
	pass

func movil_menu():
	pass

func mueble_action(_k):
	pass

func abrir_carpa(_ci):
	pass

func bed_action(_txt := ""):
	pass

func pc_action():
	pass

func lab_action():
	pass

func mueble_extr(_o: String):   # 1.36, en trama.gd
	pass

func manicura_action():
	pass

func nevera_action():
	pass

func camarote_action():   # 1.43.6, en trama.gd
	pass

func talk_neg(_k: String):   # 1.45, en granja.gd
	pass

func letter_action():
	pass

func parada_action():
	pass

func title_press(_b):
	pass

# ---------- ordenar la casa, la asociación y la nave (1.37, 12d-orden) ----------
# cada pieza (D.ORDEN_P): sus objetos [dx, dy, objeto (, desde el nivel de riego)], su gente [dx, dy, id, dir] y su sitio de serie;
# lo elegido, en S.coloca[mapa][pieza] = [x, y]; ORDEN, mientras mueves una (mover_pieza, en trama)
var ORDEN = null

var ORDEN_SIN_LADO := RegEx.create_from_string("^(bedT|pc|gpc|.*2)$")

var RIEGO_CACHE = null

const DIRS_ORDEN := [[0, 1], [-1, 0], [1, 0], [0, -1]]

func ordenar(_mapa: String) -> void:   # trama
	pass

func acceso(_k: String, _c := "", _ok := true) -> void:   # trama (1.53)
	pass

const GESTO_DE := {"regar": "regar", "plantar": "plantar", "sembrar": "sembrar", "cosechar": "cosechar", "cruzar": "polen", "vender": "vender"}   # accion() → gesto (1.54)

func gesto(_k: String, _o := {}) -> void:   # trama (1.54)
	pass

# la planta (S.pots[i]) o la variedad (sid) del próximo gesto: sale tal como es (tamaño, fase, colores, daños) o con sus colores
var gesto_p = null
var gesto_sid := ""

func cifras_acceso(_k: String) -> String:   # trama
	return ""

# F8: lo que vive en los módulos de después de la cadena (calle), declarado aquí para quien lo llama antes
func accion(nn: String, vf = null) -> void:
	pass

func alarma(e: Dictionary) -> void:
	pass

func aplica_orden(mapa: String) -> void:
	pass

func celdas_p(P_: Dictionary, x: int, y: int) -> Array:
	return []

func coloca_gente(mapa: String) -> void:
	pass

func delante() -> Array:
	return []

func gente_p(P_: Dictionary, x: int, y: int) -> Array:
	return []

func heat_warn() -> void:
	pass

func montar_club(mapa: String) -> void:
	pass

func pieza_de(mapa: String, k: String) -> Dictionary:
	return {}

func piezas_ya(mapa: String) -> Array:
	return []

func pisable(m: Dictionary, x: int, y: int) -> bool:
	return false

func pon_patrullas() -> void:
	pass

func pos_mesa(i: int) -> Array:
	return []

func pos_pieza(mapa: String, k: String) -> Array:
	return []

func quita_orden(mapa: String) -> void:
	pass

func reset_sosp() -> void:
	pass

func sosp_hud():
	pass

func montar_campo(_mapa: String) -> void:   # MAESTRO [4], en campo.gd
	pass

func montar_carreteras(_mapa: String) -> void:   # en campo.gd
	pass

func campo_obj(_x: int, _y: int, _o) -> bool:   # MAESTRO [4], en campo.gd
	return false

func montar_huerta(_k: String) -> void:   # la huerta de la tía, en campo.gd
	pass

func huerta_lista() -> bool:   # en campo.gd
	return false

func huerta_tienda() -> void:   # en campo.gd
	pass

# MAESTRO [6], en gestion.gd
func staff_ok() -> bool:
	return false

func lealtad(w: Dictionary) -> int:
	return int(w.lea)

func pon_lealtad(_w: Dictionary, _v: int) -> void:
	pass

func eficiencia(_w: Dictionary) -> int:
	return 0

func tira_topo(_w: Dictionary, _tag: String) -> void:
	pass

func staff_dia() -> void:
	pass

func contable_dia() -> void:
	pass

func robos_dia() -> void:
	pass

func carbon_dia() -> void:
	pass

func olor_nave() -> float:
	return float(D.EXTR_NAVE[int(S.nave.ex)].olor)

func chivato_nave() -> float:
	return 1.0

func seg_tiene(_k: String, _it: String) -> bool:
	return false

func ops_staff(_w: Dictionary) -> Array:
	return []

func staff_op(_w: Dictionary, _op: String) -> bool:
	return false

func plantilla_locales() -> void:
	pass

func panel_club(_id: String, _N: String) -> void:
	pass

func kaia_estilo() -> String:   # eventos
	return "itsaso"

func carbon(_N: Dictionary) -> float:
	return 100.0

func olor_txt() -> String:
	return ""

func olor_menu() -> void:
	pass

func seguridad_menu() -> void:
	pass

func seguridad_local(_k: String) -> void:
	pass

func monitores() -> void:
	pass

# MAESTRO [7], en vida.gd
func cal_saludo(_c: Dictionary, _N: String) -> bool:
	return false

func cal_busco(_c: Dictionary) -> String:
	return ""

func cal_precio(_c: Dictionary, _sid: String, _b: Dictionary) -> float:
	return 1.0

func cal_acc(_c: Dictionary, _sid: String, _b: Dictionary, _j: int, acc: float) -> float:
	return acc

func cal_frase(_k: String, _c: Dictionary) -> String:
	return ""

func cal_vendido(_c: Dictionary, _sid: String, _b: Dictionary, _N: String) -> void:
	pass

func cal_fiar(_c: Dictionary, _e: int) -> int:
	return 0

func cal_charla(_e) -> void:
	pass

func carta(bb: String) -> Array:
	return BEBIDAS[bb]

func arma_rival() -> void:
	pass

func mod_comb() -> Dictionary:
	return {"acc": 0.0, "esq": 0.0, "huir": 0.0, "recibe": 1.0}

func facil_combate() -> void:
	pass

func aviso_colocon() -> void:
	pass

func aturdido() -> bool:
	return false

func recibe_txt() -> String:
	return ""

func corte() -> void:
	pass

func golpe_txt(_mv: String) -> String:
	return ""

func arma_d() -> int:
	return 0

func tras_golpe() -> void:
	pass

func sangra_tick() -> void:
	pass

func filtra_tienda(list: Array, _F: Dictionary) -> Dictionary:
	return {"filas": [], "list": list}

func marca_de(_it: Dictionary) -> String:
	return ""

func armas_venta() -> Array:
	return []

func cal_llamar_filas() -> Array:
	return []

func entrega_encargo(_E: Dictionary) -> void:
	pass

func gusto_txt(_id: String) -> String:
	return ""

func arq_txt(_a: String) -> String:
	return ""

func arq_de(_c: Dictionary) -> String:
	return ""

func fiados() -> Array:
	return []

func deudas() -> void:
	pass

func vida_dia() -> void:
	pass

func navc_action():   # MAESTRO [8], en setas.gd
	pass

func caja_desp():   # MAESTRO [8], en nave.gd
	pass

# MAESTRO [9], en metro.gd
func pisos_ok() -> bool:
	return false

func pisos() -> void:
	pass

func pisos_dia() -> void:
	pass

func metro_ya() -> bool:
	return false

func metro_dia() -> void:
	pass

func metro_npcs(_mapa: String) -> Array:
	return []

func talk_metro(_id: String) -> void:
	pass

func vip_puerta(_k: String) -> bool:
	return true

func obj_vip(_o) -> bool:
	return false

func metro_llegada() -> void:
	pass

func piso_n(k: String) -> String:
	return k

func look_rival(_R: Dictionary) -> Dictionary:
	return {}

func cult_apunta(_sid: String) -> void:   # MAESTRO [5], en copa.gd
	pass

func cup_hoy() -> bool:
	return false

func talk_cup() -> void:
	pass

func cup_aviso() -> void:
	pass

func cup_marcas() -> Array:
	return []

func energia_dia(_av: Array) -> void:
	pass

func energia_tienda() -> void:
	pass

func fam_menu() -> void:
	pass

func fam_cuenta() -> Array:
	return [0, 0]

func fam_bono_txt(_F: Dictionary) -> String:
	return ""

func cup_trofeos() -> Array:
	return []
