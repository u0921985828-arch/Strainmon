# Ribera Verde (Godot) — 04-mapas, 08-mundo y 10-calle: el estado S, los mapas, el jugador y los personajes, moverse, hablar y
# coger cosas, y los clientes de la calle. Igual que el HTML: los guiones son corrutinas lanzadas con run() (lock), los eventos
# de historia esperan en pending (queue) a que el mundo quede libre y todo el azar pasa por Cultivo.azar() (Math.random).
extends "res://src/ui.gd"

const TS := 16
const DV := {"up": [0, -1], "down": [0, 1], "left": [-1, 0], "right": [1, 0]}
const OPP := {"up": "down", "down": "up", "left": "right", "right": "left"}
const COUNTERS := ["counter", "barcounter", "btable", "vitrina", "barraD", "cabina", "cabina2", "mesaK", "mesaK2", "barraN", "barraN2", "mostrN", "mostrN2", "mostrE", "mostrE2"]   # 1.30: la vitrina del dispensario, la barra y la cabina del DJ; 1.43: la mesa del concesionario
const SILLAS := ["silla", "sillaG", "sillaG2"]   # 1.27.1: delante de un ordenador; con A, el ordenador de encima (delante)
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
	if lock == 0 and S and S.has("misiones"):   # 1.11: las misiones guiadas, al acabar cada guion (trama.gd)
		revisa_misiones()

func queue(key: String, fn: Callable) -> void:
	if queued.has(key):
		return
	queued[key] = true
	pending.append(func():
		await fn.call()
		queued.erase(key))

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

func cap_mochila() -> float:
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
	if id in ["gorila", "camarera", "dj", "rrpp", "gentD1", "gentD2", "gentD3"] or (id.length() == 6 and id.begins_with("baila") and id[5].is_valid_int()):
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

# 1.43.3 (GENERO): el muñeco de un look (como Atlas.grupo_look: los de la calle, por su hash) y si es de chica
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
	return "Índica %s %% · sativa %s %%%s" % [n(i), n(100 - i), (" · %s %% madre · %s %% padre" % [n(s.m), n(100 - s.m)]) if s.get("m") else ""]

func strain_line(k: String) -> String:
	var s = strain(k)
	var G: Dictionary = D.GENETICA[Cultivo.tipo_gen(S, k)]
	var pa = D.PADRES.get(k)
	return "THC %s%% · ~%d g/m² · %s días · Resist. %s%%\n%s\n%s%s: %s. Estrella: 1 de cada ~%s.\n%s" % [Datos.pct(s.thc), gm2(s), Datos.coma(s.d), n(s.r),
		linea_ind(k), G.n, (" (" + pa + ")") if pa else "", G.d, Datos.miles(G.uno), (str(int(s.gen)) + ".ª generación · " if s.get("gen") else "") + s.o]

func discover(sid: String) -> void:
	if not S.disc.get(sid):
		S.disc[sid] = true
		var cu := ""   # 1.25: cuántas de la Genoteca llevas
		if D.STRAINS.has(sid):
			cu = " · %d/%d" % [D.DEX.filter(func(k): return S.disc.get(k)).size(), D.DEX.size()]
		toast("<small>NUEVA EN LA GENOTECA%s</small>" % cu + esc(strain(sid).n))
		queue("historia", check_story)

func add_seeds(sid: String, k: int) -> void:
	S.seeds[sid] = S.seeds.get(sid, 0) + k
	discover(sid)

func lot_sid(k: String) -> String:
	return k.get_slice("~", 0).trim_suffix("*")   # 1.35: «~tipo», las extracciones

func lot_nombre(k: String) -> String:
	return strain(lot_sid(k)).n + (" ★" if k.contains("*") else "")

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
	discover(lot_sid(k))

# ---------- el curado (1.29, 09c-sala) ----------
# Cada lote lleva el día de la cosecha (dia) y lo curado (cu, de 0 a 1; sin él, nada). Con los tarros, en la caja fuerte (1.36: sin arcón)
# (1.36), 1/CURADO.dias al día; curado se vende CURADO.precio más caro (calidad) y el THC sube CURADO.thc por lo que se cura (1.36). 1.36: sin curar ya no
# pierde THC; los extractos se curan en frío en la nevera (S.nevera.rosin, sin tarros) y el manicurado (mc, de 0 a 1) pela los
# cogollos: MANICURA.precio más caro. Al juntar dos lotes, el THC, lo curado, lo manicurado y el día van por gramos
func calidad(b: Dictionary) -> float:
	return 1 + D.CURADO.precio * float(b.get("cu", 0)) + D.MANICURA.precio * float(b.get("mc", 0)) + D.CAMAROTE.extra * float(b.get("af", 0))   # 1.43.6: afinado en el camarote

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

func _cura(L: Dictionary) -> Array:
	var o := []
	for k in L:
		var b: Dictionary = L[k]
		if float(b.get("cu", 0)) < 1:
			var c0 := float(b.get("cu", 0))
			b.cu = minf(1.0, c0 + 1.0 / D.CURADO.dias)
			b.thc = b.thc * (1 + D.CURADO.thc * (b.cu - c0))
			if b.cu >= 1:
				o.append(k)
	return o

# al amanecer (new_day): lo que se cura; av, los avisos del día
func curado_dia(av: Array) -> void:
	var c: Array = _cura(S.caja.buds) if S.items.get("tarros") and S.get("caja") else []
	var nv: Array = _cura(S.nevera.rosin) if S.items.get("tarros") and S.get("nevera") != null else []   # 1.36: los dos, con los tarros
	if c.size():
		av.append("Curada en la caja fuerte: " + y_lista(c.map(lot_nombre)))
	if nv.size():
		av.append("Curado en la nevera: " + y_lista(nv.map(extr_nombre)))
	if cam_ya() and cam().get("buds", {}).size():   # 1.43.6: el camarote cura en sus tarros de 10 L y, con sobres, afina
		var cc: Array = _cura(S.cam.buds)
		if cc.size():
			av.append("Curada en el camarote: " + y_lista(cc.map(lot_nombre)))
		if float(S.cam.get("sob", 0)) > 0:
			var af := []
			for k in S.cam.buds:
				var b: Dictionary = S.cam.buds[k]
				if float(b.get("cu", 0)) >= 1 and float(b.get("af", 0)) < 1:
					b.af = minf(1.0, float(b.get("af", 0)) + 1.0 / float(D.CAMAROTE.af))
					if b.af >= 1:
						af.append(k)
			if af.size():
				av.append("Afinada al 62 %% en el camarote: %s (un %d %% más cara)" % [y_lista(af.map(lot_nombre)), Datos.jsround(D.CAMAROTE.extra * 100)])
			S.cam.sob = maxf(0.0, float(S.cam.sob) - float(cam_tarros()) / float(D.CAMAROTE.dura))
			if S.cam.sob <= 0:
				av.append("Se han gastado los sobres de humedad del camarote")

# cómo está un lote, para la mochila: curado, curándose o sin curar ("" en los de antes de la 1.29), y manicurado
func man_txt(b: Dictionary) -> String:
	var mc := float(b.get("mc", 0))
	return (" Manicurada: un %d %% más cara." % Datos.jsround(D.MANICURA.precio * 100)) if mc >= 1 else (" Manicurada en parte." if mc else "")

func cura_txt(b: Dictionary) -> String:
	var cu := float(b.get("cu", 0))
	var t := ""
	if cu >= 1:
		t = "Curada: un %d %% más de THC y se vende un %d %% más cara." % [Datos.jsround(D.CURADO.thc * 100), Datos.jsround(D.CURADO.precio * 100)]
	elif cu:
		t = "Curándose (%d %%): termina de curarla con los tarros, en la caja fuerte." % Datos.jsround(cu * 100)
	elif b.get("dia") != null:
		t = "Sin curar: con tarros, en la caja fuerte, se cura en %d días: sube un %d %% de THC y se vende un %d %% más cara." % [int(D.CURADO.dias), Datos.jsround(D.CURADO.thc * 100), Datos.jsround(D.CURADO.precio * 100)]
	return (t + man_txt(b)).strip_edges()

func cura_corto(b: Dictionary) -> String:
	var cu := float(b.get("cu", 0))
	return (" · curada" if cu >= 1 else (" · curándose" if cu else (" · sin curar" if b.get("dia") != null else ""))) + (" · manicurada" if float(b.get("mc", 0)) >= 1 else "")

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
	return Datos.coma(Datos.jsround(r * 10) / 10.0) + " g de rosin"

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
	return {"label": D.EXTR[tipo_extr(k)].n + " · " + lot_nombre(k) + (" · curado" if float(l[1].get("cu", 0)) >= 1 else ""), "right": "%s g · %s%%" % [Datos.coma(l[1].g), Datos.pct(l[1].thc)], "sw": "#d89a18", "ic": ic_cog(lot_sid(k))}

# las extracciones (1.35, 11l-extraccion): el tipo va en la clave del lote («ria~seco»; el rosin, sin nada)
func tipo_extr(k: String) -> String:
	return k.get_slice("~", 1) if k.contains("~") else "rosin"

func base_extr(k: String) -> String:
	return k.get_slice("~", 0)

func kief_lots(mn: float) -> Array:
	return rosin_lots(mn).filter(func(l): return D.EXTR[tipo_extr(l[0])].get("kief"))

# 1.43.7 (lo pidió el usuario: «las extracciones se deberían poder vender al por mayor, en clubs y donde se pueda vender cogollos»;
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
	await say("Consigues %s." % t)

# las semillas que escondió la tía Maite (1.25): landraces que no están en el banco
func semillas_tia(k: String, txt: String, k_n: int = 2) -> void:
	add_seeds(k, k_n)
	await got("%d semillas de %s" % [k_n, D.STRAINS[k].n.to_upper()])
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
	# 1.43: el carro de las bandejas de clones (S.nave.bc), contra la pared, entre el secadero y el escritorio
	for x in [8, 9]:
		if n.o[2][x] in ["clonN", "clonN2"]:
			n.o[2][x] = null
	if S != null and S.get("nave") != null and Datos.CAL and not S.nave.has("bc"):
		S.nave.bc = []
	if S != null and S.get("nave") != null and S.nave.has("bc") and n.o[2][8] == null and n.o[2][9] == null:
		n.o[2][8] = "clonN"
		n.o[2][9] = "clonN2"
	# 1.45 (lo pidió el usuario: «en la nave en la que cultivas, lo mismo»): el camastro del rincón, para dormir allí
	for y in [6, 7]:
		if n.o[y][17] in ["bedT", "bedB"]:
			n.o[y][17] = null
	if S != null and S.get("nave") != null and Datos.CAL and n.o[6][17] == null and n.o[7][17] == null and puertas_int("nave").is_empty():
		n.o[6][17] = "bedT"
		n.o[7][17] = "bedB"
	montar_puertas("nave")   # 1.51: el despacho y la habitación, detrás de sus puertas

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
			m.g[y][x] = ("roofT_" if y == y0 else "roofB_" if y == y0 + 1 else "wall_") + "conce"
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
	# 1.27: el suelo y las paredes de la reforma (REFORMA) y la alfombra (suelo: 1, sus 4 trozos sobre el suelo que haya)
	var vs := ("-" + str(pa)) if pa else ""
	var fs := ("-" + str(su)) if su else ""
	for y in int(h.h):
		for x in int(h.w):
			if h.g[y][x] == "mat":
				continue
			if y == 0:
				h.g[y][x] = "iwT_home" + vs
			elif y == 1:
				h.g[y][x] = "iwB_home" + vs
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
		if not c:
			continue
		var s: Dictionary = D.SITIOS[ci]
		var x0: int = s.x
		var x1: int = x0 + int(D.CARPAS[c.t].w) - 1
		for x in range(x0, x1 + 1):
			h.o[s.y][x] = "carpa"
		h.carpas.append({"ci": ci, "t": c.t, "x0": x0, "x1": x1, "y": int(s.y)})
	aplica_orden("home")   # la nevera, la mesa, las plantas, el taller y los muebles del salón (con la silla gaming)
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
	# 1.43.6: la escalera escamoteable del camarote, entre las carpas A y B, bajo la ventana; se sube desde la casilla de delante
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
	h.o[int(CM.y)][int(CM.x)] = "escaleraC"

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
	m.o[int(X.armS[1])][int(X.armS[0])] = "armS"
	m.o[int(X.mesaS[1])][int(X.mesaS[0])] = "mesaS"
	if S != null and S.get("setas") is Dictionary and S.setas.get("dh"):
		m.o[int(X.deshidS[1])][int(X.deshidS[0])] = "deshidS"
	if S != null and S.get("setas") is Dictionary and S.setas.get("ay") and int(m.w) > 10:   # 1.51: la mesa del ayudante
		m.o[int(D.SETAS_AY.mesa[1])][int(D.SETAS_AY.mesa[0])] = "mesita"

# los negocios por dentro (1.45, lo pidió el usuario: «que tú puedas acceder a ese sitio y controlarlo desde ahí»; con Datos.CAL):
# en la calle, la puerta del local (NEGOCIO.k[k]: x, puerta, ancha, dx, tile; gate «neg:k»); dentro (loc-<k>), lo que ponen las mejoras
# compradas (S.loc[k].mj); sin Datos.CAL, la calle y el local como estaban (la copia _neg0)
const NEG_ANCHO := ["elevT", "fosoT", "bancoT", "boxL", "cubaQ", "mostrQ", "hornoP", "mostrP", "doblaL", "hornoN", "recambT", "barraN", "botN", "estP", "mostrN", "doblaN", "mesaP"]   # 1.47: los muebles de PixelLab de dos casillas
# 1.46: el elevador y el foso, a escala con los coches del concesionario (5 casillas, como la exposición); 1.47, el box de lavado
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

# 1.47 (lo pidió el usuario: «la discoteca tiene que ser más grande, el piso de arriba reservado»), solo con Datos.CAL: GAUA, la planta
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
# 1.47 (lo pidió el usuario: «un estanco en cada pueblo»), solo con Datos.CAL: la puerta en una casa libre de cada pueblo (en el barrio
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
		b.rotulo = "rotuloE"
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
		m.o[2][1 + i * 2] = "estanteC" if i < cam_est() else null

# lo que no se puede ocupar al ordenar (12d-orden): delante de la escalera del camarote (1.43.6)
func reserva_orden(mapa: String) -> Array:
	return D.ORDEN_RESERVA.get(mapa, []) + ([[D.CAMAROTE.x, D.CAMAROTE.y], D.CAMAROTE.vuelta] if mapa == "home" and cam_ya() else []) + delante_puertas(mapa)

# 1.51 (lo pidió el usuario: «una puerta en la casa, luego un mapa pequeño como un mini pasillito»; y en el taller y en la nave): las
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
	o.c = Atlas.con_rampa(f.c, r[0], "ropa|" + r[1])
	return o

# personalizar la casa (1.16, 12c-salon): el tapizado o la lámina de un mueble (S.deco[k], índice en DECO[k].v) y su sprite
func deco_v(k: String) -> int:
	return int(S.deco.get(k, 0)) if S.get("deco") is Dictionary else 0

func deco_sprite(o: String) -> String:
	var v := deco_v(o) if D.DECO.has(o) else 0
	return (o + "-" + str(v)) if v else o

func sitio_visible(ci: int) -> bool:
	return not (ci < S.carpas.size() and S.carpas[ci]) and (ci < 2 or (S.carpas.size() > 1 and S.carpas[1] != null))

func sitio_libre(x: int, y: int) -> int:
	for ci in D.SITIOS.size():
		var s: Dictionary = D.SITIOS[ci]
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
	ents = demo_e
	demo_e[-1].merge(demo_en(DM.poli, now_), true)
	P.merge(demo_en(DM.P, now_), true)
	return sv

func demo_sale(sv: Array) -> void:
	S = sv[0]
	ents = sv[1]

func npc_cond(d: Dictionary) -> bool:
	match d.id:
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
			return S.ch == 6
		"julen":   # 1.23: en el piso hasta la primera cosecha; después, en el growshop
			return (S.flags.get("kiko1") and not S.flags.get("harvest1")) if d.map == "home" else (true if S.flags.get("harvest1") else false)
	if d.id.begins_with("est_") or d.id in ["camareraV", "vipA", "vipB", "gentD1", "gentD2", "gentD3"]:   # 1.47: el estanco, el reservado de GAUA y su gente de abajo
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
		await say(pick(["«Circule.»", "«Buenas. Nada que ver aquí.»", "«¿Todo bien? Siga.»"]), "AGENTE")
		return
	if d.id == "setero":   # 1.51
		await talk_setero()
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
			await say(pick(["Esto es el Ensanche: pisos, oficinas y el parque. El Casco Viejo, por la avenida.", "En Ibarbide hay policía en cada esquina. Y aun así...", "Los de los pueblos venís en autobús, ¿no? La estación está en el Casco."]), "VECINO")
		"josune":
			await talk_josune()
		"baltasar":
			await talk_baltasar()
		"tono":
			await say(pick(["Don Baltasar está ocupado. Habla con él si traes el dinero.", "Aquí dentro no se hacen preguntas."]), "TOÑO")
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
			await say(pick(["Vengo a por la berlina de empresa. Bueno, a mirar; lo de comprar, lo decide mi mujer.", "¿Has visto el rojo? Doscientos cuarenta y cinco mil. Con eso me compro dos pisos en el pueblo.", "La moto es lo más práctico: aparcas en cualquier sitio y gasta nada."]), "CLIENTE")
		"cg1", "cg2", "cg3", "cg4":   # 1.34: los demás socios de cada club
			await talk_gente_club(S.map.substr(5), int(d.id.substr(2)) - 1)
		"pres_puerto", "pres_valde", "pres_ibar", "pres_ens":   # 1.34: los presidentes de los clubs de fuera
			await talk_presi(d.id.substr(5))
		"gorila":
			await talk_gorila()
		"camarera", "camareraV":
			await talk_barra()
		"vipA", "vipB":   # 1.47
			await talk_vip(0 if d.id == "vipA" else 1)
		"gentD1", "gentD2", "gentD3":   # 1.47: la gente de la pista, la que se ve desde el cristal del reservado
			await say(D.DISCO_CAL.gente[(int(d.id.substr(5)) + S.day) % D.DISCO_CAL.gente.size()], "GENTE")
		"dj":
			await talk_dj()
		"rrpp":
			await talk_rrpp()
		"baila1", "baila2", "baila3":
			await talk_baila(int(d.id.substr(5)) - 1)
		"unai":
			await say(pick(["Si mantienes pulsado B, corres.", "Mi hermano dice que de noche, en la hierba alta del parque, roban a la gente.", "Con START abres tu GENOTECA y la mochila.", "En los arbustos del parque la gente esconde cosas. Mira delante de ellos con A."]), "UNAI")
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
			await say(pick(["En Mendialde el autobús para en la plaza. El último sale a las nueve.", "Tu ama dice que en la ciudad no comes. Llévate el táper.", "Aquí el maíz se siembra en mayo y se recoge en octubre. Como toda la vida."]), "VECINA")
		"excursionista":
			await say(pick(["El molino tiene trescientos años. Todavía muele algún domingo.", "Del puente para arriba, el río baja limpio. Para abajo, ya no tanto.", "Vengo en el autobús de Ribera Verde: treinta minutos y tres euros."]), "EXCURSIONISTA")
		"turista":
			await say(pick(["Las casas son de colores para que cada pescador viera la suya desde el mar.", "Dicen que en este puerto se paga bien... y que la policía mira poco.", "He venido a por anchoas y me han ofrecido de todo."]), "TURISTA")
		"obrero":
			await say(pick(["La fundición cerró hace años. Ahora el solar es del chatarrero.", "Aquí la gente cobra poco y paga poco. Y de noche, cuidado con la cartera.", "De Valdehierro a Ribera Verde, veinte minutos de autobús."]), "OBRERO")

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
			await got("2 × SPRAY DE PIMIENTA")
		"i_fert":
			S.items.fert += 3
			await got("3 dosis de MEATZA FLORACIÓN")
		"i_boc":
			S.items.bocata += 2
			await got("2 × BOCATA")
		"h_acap":
			add_seeds("acapulco", 2)
			await got("2 semillas de ACAPULCO GOLD")
			await say("Un bote de carrete con dos semillas y una etiqueta a boli: «Guerrero, 1979».")
		"h_50":
			S.money += 50
			await got("50 € en billetes doblados")
		"h_ins":
			S.items.insect += 1
			await got("1 tratamiento de INSECTICIDA")
		"i_ast":
			S.items.spray += 2
			await got("2 × SPRAY DE PIMIENTA")
		"h_alto":
			S.money += 80
			await got("80 € en un sobre arrugado")
		"h_kale":   # la Kale Zaharra (1.14)
			S.money += 120
			await got("120 € en una riñonera abandonada")
		"h_lamb":   # las de la tía Maite (1.25)
			await semillas_tia("lamb", "Una lata de tabaco oxidada con una etiqueta a boli: «Jamaica». Es la letra de la tía Maite.")
		"h_kerala":
			await semillas_tia("kerala", "Un bote de carrete envuelto en plástico: «Kerala, India». Es la letra de la tía Maite.")
		"h_manga":
			await semillas_tia("mangarosa", "Un sobre en una bolsa de congelar: «Manga Rosa · Brasil». Es la letra de la tía Maite.")
		"h_mallas":   # 1.36: las mallas 00, en un arbusto de Mendialde
			S.items.mallas00 = 1
			await got("unas MALLAS 00 (DOBLE CERO)")
			await say("Una bolsa de tela con un bastidor y una malla finísima: «00». Con esto se tamiza en seco lo más fino, solo las cabezas de resina.")
		"h_hawai":
			await semillas_tia("hawai", "Un tubo de pastillas con semillas dentro: «Hawái». Es la letra de la tía Maite.")

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

# 1.51 (lo pidió el usuario: «la casa de Txaro es la casa con menos atrezo que hay en el mundo… que en casi todos los lugares donde
# puedes interactuar con alguien, que tenga un poquito de atrezo»): lo que se añade, con CAL, en las casillas que estén libres; cada
# cosa con su texto (ATREZO_TXT). Nada corta el paso (lo comprueba tests/atrezo.gd)
const ATREZO := {
	"txaro": [[3, 2, "tv"], [4, 2, "tv2"], [6, 1, "cuadro"], [8, 2, "libreria"], [3, 4, "sillon"], [4, 4, "sillon2"], [5, 5, "silla"], [8, 6, "mesita"], [5, 1, "cartel"]],
	"casa-ama": [[4, 1, "cuadro"], [3, 2, "libreria"], [7, 2, "sillon"], [8, 2, "sillon2"], [5, 5, "silla"], [8, 6, "mesita"]],
	"comisaria": [[6, 2, "escritorio"], [7, 2, "escritorio2"], [3, 1, "cuadro"]],
	"almacen": [[3, 2, "sacos"], [2, 1, "red"], [7, 2, "estanteN"], [8, 4, "barrilT"]],
}
const ATREZO_TXT := {
	"txaro": {"tv": "La tele, con un tapete de ganchillo encima del mueble. Echan un concurso.", "tv2": "La tele, con un tapete de ganchillo encima del mueble. Echan un concurso.",
		"cuadro": "Una lámina de la ría. La enmarcó su Paco en el sesenta y ocho.", "libreria": "Novelas de bolsillo, un misal y un álbum de fotos de un viaje a las montañas.",
		"mesita": "Un costurero abierto y unas gafas de cerca.", "cartel": "Un póster del faro de Puerto Viejo. Paco trabajó allí de joven."},
	"casa-ama": {"cuadro": "Una lámina del monte, con el marco descolorido por el sol.", "libreria": "Los libros de aitona: el monte, los pájaros y una enciclopedia por fascículos.",
		"mesita": "Una radio vieja con la emisora de la comarca."},
	"comisaria": {"escritorio": "Una mesa con un ordenador viejo y una montaña de atestados.", "escritorio2": "Una mesa con un ordenador viejo y una montaña de atestados.",
		"cuadro": "Una lámina de la ría, torcida. Nadie la endereza."},
	"almacen": {"sacos": "Sacos de sal gorda de la conservera.", "red": "Una red de pesca vieja, colgada de un clavo.", "estanteN": "Una estantería con latas oxidadas y cuerdas.",
		"barrilT": "Un bidón azul. Huele a gasoil."},
}
const ASIENTO_FUERA := {"sofa": "Un sofá.", "sillon": "Un sillón.", "silla": "Una silla."}

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

func enter_map(name_: String, x: int, y: int, dir = null) -> void:
	SENT = null   # 1.49: al cambiar de sitio, de pie
	S.map = name_
	if name_ == "home":
		montar_casa()
	if name_ == "nave":
		montar_nave()
	if name_ == "alto":
		montar_alto()
	if name_ == "camarote":
		montar_camarote()
	if name_ == "setas":
		montar_setas()
	montar_locales(name_)   # 1.45: la puerta de los negocios y sus mejoras
	montar_estancos(name_)   # 1.47: el estanco de cada pueblo
	if name_ in ["disco", "disco-vip", "ensanche"]:
		montar_disco()
	if Datos.CAL and VITRINA_GROW.has(name_):   # 1.47: la vitrina de las pipas y demás en los dos grows
		var vg: Array = VITRINA_GROW[name_]
		MAPS[name_].o[vg[1]][vg[0]] = "vitrinaP"
		MAPS[name_].o[vg[1]][vg[0] + 1] = "vitrinaP2"
	if Datos.CAL and CAJERO_CAL.has(name_):
		var cj: Array = CAJERO_CAL[name_]
		if MAPS[name_].o[cj[0][1]][cj[0][0]] == "cajero":
			MAPS[name_].o[cj[0][1]][cj[0][0]] = null
			MAPS[name_].o[cj[1][1]][cj[1][0]] = "cajero"
	montar_club(name_)
	montar_atrezo(name_)
	if name_ != "home" and name_ != "nave":
		montar_puertas(name_)
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
	enter_map(w.to, w.x, w.y, w.dir)
	update_hud()
	await wait(80)
	await fade(0)

# ---------- movimiento ----------
func update_player(dt: float) -> void:
	if P.moving:
		P.t += dt
		var k := minf(1, P.t / P.dur)
		P.px = (P.fx + (P.x - P.fx) * k) * 16
		P.py = (P.fy + (P.y - P.fy) * k) * 16
		if k < 1:
			return
		P.moving = false
		P.px = P.x * 16.0
		P.py = P.y * 16.0
		on_step_end()
		P.chain = true
	if not is_free():
		P.chain = false
		return
	var d = dir_order[-1] if dir_order.size() else null
	if d == null:
		P.chain = false
		P.hold = 0.0
		return
	if SENT != null:   # 1.49: una flecha te levanta, mirando hacia ella, sin dar el paso todavía
		levantarte(d)
		P.chain = false
		P.hold = 150.0
		return
	if d != P.dir:
		P.dir = d
		if not P.chain:
			P.hold = 90.0
			return
	if P.hold > 0:
		P.hold -= dt
		return
	try_move(d)

func try_move(d: String) -> void:
	var m: Dictionary = MAPS[S.map]
	var dv: Array = DV[d]
	var ex = m.exits.get("%d,%d" % [P.x, P.y])
	if d == "down" and ex:
		P.chain = false
		run(func(): await warp(ex))
		return
	var nx: int = P.x + dv[0]
	var ny: int = P.y + dv[1]
	if tile_solid(m, nx, ny) or ent_at(nx, ny):
		if M.reloj - P.bumpT > 350:
			sfx("bump")
			P.bumpT = M.reloj
		P.chain = false
		return
	P.fx = P.x
	P.fy = P.y
	P.x = nx
	P.y = ny
	P.t = 0.0
	P.moving = true
	P.pisT = M.reloj
	P.dur = paso_ms()
	P.parity ^= 1

# el patinete o la bici (1.13, vehiculo() de 12c-salon): en la calle (ZONAS), el mejor que tengas
func vehiculo():
	var v = S.get("veh")
	if not D.ZONAS.has(S.map):
		return null
	for k in ["deportivo", "berlina", "utilitario", "moto"]:   # 1.43: lo del concesionario, antes que nada (el mejor que tengas)
		if coche_ya(k) and not S.coches[k].get("grua") and D.VEHICULOS.has(k):
			return k
	if not (v is Dictionary):
		return null
	for k in ["bici", "patinete"]:
		if v.get(k) and float(v[k]) <= S.day:
			return k
	return null

# 1.43: un vehículo del concesionario (S.coches: {k: {dia: cuándo llega, p: lo pagado, r: el próximo recibo del seguro o null}}), ya entregado
func coche_ya(k: String) -> bool:
	return S.get("coches") is Dictionary and S.coches.has(k) and int(S.coches[k].dia) <= int(S.day)

func paso_ms() -> float:   # ms por casilla: a pie, corriendo o montado (pasoMs)
	var v = vehiculo()
	if v:
		return float(D.VEHICULOS[v].paso[1 if held.B else 0])
	return 130.0 if held.B else 240.0

func on_step_end() -> void:
	S.x = P.x
	S.y = P.y
	S.dir = P.dir
	S.steps += 1
	if S.cool > 0:
		S.cool -= 1
	var m: Dictionary = MAPS[S.map]
	var door = m.doors.get("%d,%d" % [P.x, P.y])
	if door:
		if door.get("gate"):   # 1.30: la puerta de un local (entra_local, trama.gd)
			run(func(): await entra_local(door))
		else:
			run(func(): await warp(door))
		return
	if (S.map == "disco" or S.map == "disco-vip") and not disco_abierta():
		run(func(): await echar_disco())
		return
	if not D.ZONAS.has(S.map):
		return
	var Z: Dictionary = D.ZONAS[S.map]
	if S.map == "town" and P.y >= 13 and P.y <= 14 and P.x >= 18 and P.x <= 22:
		if S.ch >= 2 and S.ch < 7 and not S.flags.get("darko1"):
			queue("darko", func():
				for e in ents:
					if e.id == "darko":
						e.dir = "up"
				await talk_darko())
			return
		if S.ch >= 5 and not S.flags.get("molina1"):
			queue("molina", talk_molina)
			return
	# ladrones al azar por paso; la policía ya no (1.10): patrulla por la calle (más abajo). Con la alarma, nada
	if S.ch >= 2 and S.cool <= 0 and SOSP.alarma == null:
		var g := gramos_flor()   # el rosin también atrae ladrones (1.10)
		var tall: bool = m.g[P.y][P.x] == "tallgrass"
		var pt: float = .004 * (2.5 if is_night() else 1.0) * (3.0 if tall else 1.0) * Z.lad if (g >= 5 or S.money >= 150) else 0.0
		if Cultivo.azar() < pt:
			S.cool = 25
			run(func(): await battle("thief"))

func update_ents(dt: float) -> void:
	var free := is_free()
	var m: Dictionary = MAPS[S.map]
	for e in ents:
		if e.get("pat"):   # las patrullas andan en update_patrullas
			continue
		if e.moving:
			e.t += dt
			var k := minf(1, e.t / 320)
			e.px = (e.fx + (e.x - e.fx) * k) * 16
			e.py = (e.fy + (e.y - e.fy) * k) * 16
			if k >= 1:
				e.moving = false
				e.fx = e.x
				e.fy = e.y
			continue
		if not free or not e.wander:
			continue
		e.wt -= dt
		if e.wt > 0:
			continue
		e.wt = 1200 + Cultivo.azar() * 2600
		var d: String = pick(["up", "down", "left", "right"])
		e.dir = d
		var nx: int = e.x + DV[d][0]
		var ny: int = e.y + DV[d][1]
		if absi(nx - e.hx) > e.wander or absi(ny - e.hy) > e.wander:
			continue
		var k := "%d,%d" % [nx, ny]
		if tile_solid(m, nx, ny) or ent_at(nx, ny) or (nx == P.x and ny == P.y) or (P.moving and nx == P.fx and ny == P.fy) or m.doors.has(k) or m.exits.has(k) or llegada_bus(nx, ny):   # ni en la llegada del autobús (1.10)
			continue
		e.fx = e.x
		e.fy = e.y
		e.x = nx
		e.y = ny
		e.t = 0.0
		e.moving = true

func world_press(b: String) -> void:
	if mode == "title":
		title_press(b)
		return
	if not is_free() or P.moving:
		return
	if SENT != null and b == "A":   # 1.49: sentado, lo que puedes hacer sin levantarte
		run(menu_sentado)
	elif SENT != null and b == "B":
		levantarte()
	elif b == "A":
		interact()
	elif b == "START":
		run(start_menu)
	elif b == "MOVIL":
		run(movil_menu)

# la casilla de delante; si es una silla (1.27.1), la de encima, desde cualquier lado: el ordenador que tiene delante
func delante() -> Array:
	var dv: Array = DV[P.dir]
	var m: Dictionary = MAPS[S.map]
	var tx: int = P.x + dv[0]
	var ty: int = P.y + dv[1]
	if ty >= 0 and ty < m.h and tx >= 0 and tx < m.w and m.o[ty][tx] in SILLAS:
		ty -= 1
	return [tx, ty]

func interact() -> void:
	var dv: Array = DV[P.dir]
	var m: Dictionary = MAPS[S.map]
	if Datos.CAL:   # 1.47: un asiento delante (sofá, sillón, silla, banco, taburete): sentarte
		var sx: int = P.x + dv[0]
		var sy: int = P.y + dv[1]
		if sy >= 0 and sy < m.h and sx >= 0 and sx < m.w and asiento_de(m.o[sy][sx]) != "" and ent_at(sx, sy) == null:
			run(func(): await asiento(sx, sy))
			return
	var de := delante()
	var tx: int = de[0]
	var ty: int = de[1]
	var e = ent_at(tx, ty)
	if e == null and ty >= 0 and ty < m.h and tx >= 0 and tx < m.w and m.o[ty][tx] in COUNTERS:
		e = ent_at(tx + dv[0], ty + dv[1])
	if e:
		run(func(): await hablar_con(e))
		return
	var it = item_at(tx, ty)
	if it:
		run(func(): await pick_item(it))
		return
	run(func(): await object_action(tx, ty))

# sentarse (1.47, solo con CAL): en los asientos, mirando al sur (se ven de frente) o al norte (de espaldas); sentado, fumarte
# uno de lo que lleves (medio gramo), pedir algo, hablar con el de al lado, el móvil, quedarte un rato o levantarte; no se guarda
const ASIENTOS := {"sofaF": "sur", "sofaV": "sur", "bench": "sur", "sofaB": "norte", "sofa": "norte", "sillon": "norte", "silla": "norte", "sillaG": "norte", "stool": "norte"}
const ASIENTO_TXT := {"sofaF": "Un sofá del club.", "sofaB": "Un sofá del club.", "sofaV": "El sofá del reservado.", "bench": "Un banco.", "stool": "Un taburete.",
	"sofa": "Tu sofá.", "sillon": "Tu sillón de lectura.", "silla": "La silla del ordenador de la tía.", "sillaG": "Tu silla gaming."}
const SENT_CORTA := 5   # las filas de piernas que no se ven sentado
const SENT_CORTA_SUR := 0   # 1.50: de frente, en el asiento, a la altura de pie (6 filas de piernas dobladas, SENT_PIERNAS en pinta.gd)
const SENT_SUBE := 6    # de espaldas, el culo en medio del asiento: la cabeza asoma por encima del respaldo
const SENT_PORRO := 0.5
var SENT = null   # {x, y, d}

func asiento_de(o) -> String:
	if not (o is String):
		return ""
	if ASIENTOS.has(o):
		return o
	if o.ends_with("2") and ASIENTOS.has(o.left(-1)):
		return o.left(-1)
	return ""

func asiento(x: int, y: int) -> void:
	var k := asiento_de(MAPS[S.map].o[y][x])
	var ops := ["Sentarte"]
	var fuera: bool = Datos.CAL and S.map != "home" and ASIENTO_FUERA.has(k)   # 1.51: el sillón y la silla de otras casas no son los tuyos
	if fuera:
		pass
	elif k in ["silla", "sillaG"]:
		ops.append("Usar el ordenador")
	elif k in ["sofa", "sillon", "sofaF", "sofaB", "sofaV"]:
		ops.append("Otra cosa")
	ops.append("Nada")
	var j: int = await ask(ASIENTO_FUERA[k] if fuera else ASIENTO_TXT[k], ops)
	var c: String = ops[j] if j >= 0 and j < ops.size() else "Nada"
	if c == "Nada":
		return
	if c != "Sentarte":
		var de := delante()
		await object_action(de[0], de[1])
		return
	await sentado(x, y, k)

func sentado(x: int, y: int, k: String) -> void:
	SENT = {"x": x, "y": y, "d": ASIENTOS[k], "k": k, "dir0": P.dir}
	P.dir = "down" if SENT.d == "sur" else "up"

# 1.49 (lo pidió el usuario: «que te puedas sentar de verdad»): sentado es un estado, no un menú; el mundo sigue (la gente
# anda, el reloj corre, el móvil y START funcionan) y te quedas hasta que te levantas: con B o con una flecha. Con A, lo que
# se puede hacer sentado (menu_sentado)
func levantarte(d = null) -> void:
	if SENT == null:
		return
	P.dir = d if d != null else SENT.dir0
	SENT = null

# bebidas en la barra o en la mesa, por sitio (1.49): [texto, euros, minutos]
const BEBIDAS := {
	"bar": [["Un café", 1.5, 10], ["Una caña", 2.5, 15], ["Un refresco", 2.2, 15], ["Un vino", 2.0, 15]],
	"club": [["Un café", 1.2, 10], ["Un refresco", 1.8, 15], ["Un zumo", 2.0, 15], ["Una cerveza", 2.2, 15]],
	"disco": [["Un refresco", 5.0, 15], ["Una cerveza", 6.0, 15], ["Una copa", 9.0, 20]],
}

func bebidas_aqui() -> String:
	if S.map in ["bar", "loc-puerto"]:
		return "bar"
	if S.map.begins_with("club-"):
		return "club"
	if S.map in ["disco", "disco-vip", "disco-g"]:
		return "disco"
	return ""

# quien está a tu lado: junto al asiento o junto a la casilla donde estás (ni la policía de patrulla)
func al_lado() -> Array:
	var r := []
	if SENT == null:
		return r
	for e in ents:
		if e.get("pat") or e.moving:
			continue
		var d1: int = absi(e.x - SENT.x) + absi(e.y - SENT.y)
		var d2: int = absi(e.x - P.x) + absi(e.y - P.y)
		if d1 <= 1 or d2 <= 1 or (absi(e.x - SENT.x) <= 1 and absi(e.y - SENT.y) <= 1):
			r.append(e)
	return r

func hablar_con(e) -> void:
	if not e.moving:
		e.dir = OPP[P.dir]
	if e.def.get("client"):
		await talk_client(e.def.client)
	else:
		await npc_talk(e.def)
		var r = rel_de(e.id)
		if not e.get("pat") and r:
			saludo(r)

func menu_sentado() -> void:
	if SENT == null:
		return
	var ops := []   # [texto, clave]
	ops.append(["Fumarte uno", "fumar"])
	var bb := bebidas_aqui()
	if bb != "":
		ops.append(["Pedir algo", "beber"])
	for e in al_lado():
		ops.append(["Hablar con " + nombre_ent(e), e])
	ops.append(["Mirar el móvil", "movil"])
	ops.append(["Quedarte un rato", "rato"])
	ops.append(["Levantarte", "fuera"])
	var j: int = await ask("Estás sentado.", ops.map(func(o): return o[0]))
	if j < 0 or j >= ops.size():
		return
	var c = ops[j][1]
	if not (c is String):
		await hablar_con(c)
		return
	match c:
		"fumar":
			await fumar_sentado()
		"beber":
			await beber_sentado(bb)
		"movil":
			await movil_menu()
		"rato":
			await rato_sentado()
		"fuera":
			levantarte()

func nombre_ent(e) -> String:   # dónde está respecto al asiento
	var dx: int = e.x - SENT.x
	var dy: int = e.y - SENT.y
	if dx < 0:
		return "quien tienes a la izquierda"
	if dx > 0:
		return "quien tienes a la derecha"
	return "quien tienes delante" if (dy > 0) == (SENT.d == "sur") else "quien tienes detrás"

func beber_sentado(bb: String) -> void:
	var L: Array = BEBIDAS[bb]
	var j: int = await ask("¿Qué te pones?", L.map(func(b): return "%s · %s" % [b[0], Datos.eur(b[1])]) + ["Nada"])
	if j < 0 or j >= L.size():
		return
	var b: Array = L[j]
	if float(S.money) < float(b[1]):
		await say("No llevas suelto ni para eso.")
		return
	S.money = snappedf(float(S.money) - float(b[1]), 0.01)
	advance_time(int(b[2]))
	update_hud()
	await say("%s. Te lo tomas sentado, sin prisa." % b[0])

func rato_sentado() -> void:
	advance_time(30)
	var t := "Pasas media hora mirando a la gente."
	if D.ZONAS.has(S.map) and float(S.heat) > 0 and not is_night():
		S.heat = maxf(0, float(S.heat) - 1)   # sentado y quieto en un banco, pasas desapercibido
		t += " Sentado en un banco no llamas la atención."
	update_hud()
	await say(t)

# dónde echa el humo sentado (la boca, o encima de la cabeza si está de espaldas)
func boca_sentado() -> Vector2:
	if SENT == null:   # de pie
		return Vector2(P.px + 8, P.py - 4)
	var sur: bool = SENT.d == "sur"
	return Vector2(SENT.x * 16 + 8 + (4 if sur else 0), SENT.y * 16 + 15 - (18 if sur else 22 + SENT_SUBE) + (SENT_CORTA_SUR if sur else SENT_CORTA) - (4 if SENT.get("k") == "stool" else 0))   # en el taburete, 4 más arriba

# 1.47 (lo pidió el usuario): con qué se fuma. El papel, el tabaco, las boquillas y el mechero, del estanco (ESTANCO); la pipa,
# el bong, el vaporizador y el grinder, del grow (PARAFERNALIA). g: cogollos por vez (el porro, con tabaco, gt); gr: extracto
# por vez (0 = el porro no lleva extracto); con: lo que hace falta en S.items
const FUMAR := {
	"porro": {"n": "Liarte un porro", "g": 0.5, "gt": 0.3, "gr": 0.0, "con": ["papel", "mechero"]},
	"pipa": {"n": "Una pipa", "g": 0.2, "gr": 0.1, "con": ["pipa", "mechero"]},
	"bong": {"n": "Un bong", "g": 0.3, "gr": 0.1, "con": ["bong", "mechero"]},
	"vapo": {"n": "El vaporizador", "g": 0.2, "gr": 0.1, "con": ["vapo"]},
}
const NO_FUMAR := ["bar", "disco", "disco-vip", "shop", "growcity"]

func fumar_sentado() -> void:
	if S.map == "comisaria":
		await say("¿Aquí, en comisaría? Mejor no.")
		return
	if S.map in NO_FUMAR or S.map.begins_with("loc-") or S.map.begins_with("est-"):
		await say("Aquí dentro no se puede fumar.")
		return
	var ms := []
	for k in FUMAR:
		if FUMAR[k].con.all(func(i): return float(S.items.get(i, 0)) > 0):
			ms.append(k)
	if ms.is_empty():
		await say("No tienes con qué: el papel y el mechero, en el estanco; las pipas, el bong y el vaporizador, en el grow.")
		return
	var mk: String = ms[0]
	if ms.size() > 1:
		var j: int = await ask("¿Cómo?", ms.map(func(k): return FUMAR[k].n) + ["Nada"])
		if j < 0 or j >= ms.size():
			return
		mk = ms[j]
	var F: Dictionary = FUMAR[mk]
	var gb: float = F.g
	var tab := false
	if mk == "porro":
		if S.items.get("grinder"):
			gb = 0.4   # desmenuzado con el grinder, se aprovecha más
		if float(S.items.get("tabaco", 0)) >= 0.7:
			var t: int = await ask("¿Con tabaco?", ["Con tabaco", "Solo hierba", "Nada"])
			if t < 0 or t > 1:
				return
			if t == 0:
				tab = true
				gb = F.gt
	var ls := bud_lots(gb).map(func(l): return [l[0], l[1], false])
	if F.gr > 0:
		ls += rosin_lots(F.gr).map(func(l): return [l[0], l[1], true])
	if ls.is_empty():
		await say("No llevas nada para fumar." if F.gr > 0 else "No llevas cogollos para liarte uno.")
		return
	var i := 0
	if ls.size() > 1:
		i = await menu(ls.map(func(l): return rosin_item([l[0], l[1]]) if l[2] else lot_item([l[0], l[1]])), {"title": "¿DE CUÁL?"})
		if i < 0 or i >= ls.size():
			return
	var lk: String = ls[i][0]
	var r: bool = ls[i][2]
	var thc: float = ls[i][1].thc
	var nom: String = extr_nombre(lk, true) if r else lot_nombre(lk)
	if r:
		use_rosin(lk, F.gr)
	else:
		use_buds(lk, gb)
	if mk == "porro":
		S.items.papel = int(S.items.papel) - 1
		if S.items.get("filtros"):
			S.items.filtros = int(S.items.filtros) - 1
		if tab:
			S.items.tabaco = snappedf(float(S.items.tabaco) - 0.7, 0.1)
	marca_cata(lk, r, lot_sid(lk), thc)   # fumarlo es catarlo
	var b := boca_sentado()
	for n in 3:
		lanzar_vfx("vfx-humo-porro", b.x, b.y, M.reloj, S.map, true)
		await wait(700)
	advance_time(15)
	var t := ("Te lías uno de %s%s y te lo fumas sin prisa." % [nom, " con tabaco" if tab else ""]) if mk == "porro" else \
		("Cargas %s de %s y le das unas caladas." % [{"pipa": "la pipa", "bong": "el bong"}.get(mk, "el vaporizador"), nom])
	if D.ZONAS.has(S.map):
		S.heat = minf(100, S.heat + (1 if mk == "vapo" else 3))
		heat_warn()
		t += " Fumar en la calle llama la atención."
	update_hud()
	await say(t)

func talk_vip(_i: int) -> void:   # trama (1.47)
	pass

func talk_estanco(_k: String) -> void:   # trama (1.47)
	pass

func marca_cata(_k: String, _r: bool, _sid: String, _thc: float) -> void:   # trama (1.47)
	pass

func object_action(x: int, y: int) -> void:
	var m: Dictionary = MAPS[S.map]
	var o = m.o[y][x] if y >= 0 and y < m.h and x >= 0 and x < m.w else null
	var pi_ = puerta_int(S.map, x, y)
	if pi_ != null and o == pi_.o:   # 1.51: las puertas de dentro
		await cruzar_puerta(pi_)
		return
	if await obj_local(x, y, o):   # los locales (1.30)
		return
	if S.map == "home":
		for t in m.get("carpas", []):
			if x >= t.x0 and x <= t.x1 and y == t.y:
				await abrir_carpa(t.ci)
				return
		var sl := sitio_libre(x, y)
		if sl >= 0:
			await say(("Hueco junto a la cama: aquí cabe una carpa de 120×120." + (" Kiko las tendrá más adelante." if S.ch < 5 else " Kiko las vende.")) if sl == 2 else "Aquí cabe una carpa de cultivo. Kiko vende carpas de 100×100.")
			return
		if mueble_de(o) != "":
			await mueble_action(mueble_de(o))
			return
		for k in D.MUEBLES:   # el sitio vacío de un mueble del salón
			var mu: Dictionary = D.MUEBLES[k]
			if mu.get("suelo") and k in muebles_ya():   # la alfombra puesta no es un objeto: nada (1.27)
				continue
			var mp: Array = pos_pieza("home", k) if not pieza_de("home", k).is_empty() else [int(mu.x), int(mu.y)]   # 1.37: donde lo puso el jugador
			if (o == null or o == "plantDeco") and (x == mp[0] or (not mu.get("uno") and x == mp[0] + 1)) and y == mp[1]:   # lo que haya encima, antes (como en el HTML)
				var pd = S.get("muebles", {}).get(k) if S.get("muebles") is Dictionary else null
				if mu.get("grow") and not pd:   # el carro de esquejes (1.11): sin pedir, nada
					break
				await say(("Aquí va %s: llega mañana." % mu.art) if pd else ("Aquí iría bien %s. Se compra por internet: en el ordenador de la tía o con el móvil." % mu.art))
				return
		if o != null and D.MUEBLE_EXTR.has(o):   # 1.36: los muebles de las extracciones
			await mueble_extr(o)
			return
		match o:
			"bedT", "bedB":
				await bed_action()
				return
			"pc":
				await pc_action()
				return
			"lab", "lab2":
				await lab_action()
				return
			"trim":   # 1.36
				await manicura_action()
				return
			"table":
				if not S.flags.get("letter"):
					await letter_action()
					return
				# 1.37 (lo pidió el usuario): con la carta leída, la mesa redonda ordena la casa (12d-orden)
				var j := await ask("La mesa redonda de la tía. Desde aquí se ve todo el piso.", ["Ordenar la casa", "Leer la carta", "Nada"])
				if j == 0:
					await ordenar("home")
				elif j == 1:
					await letter_action()
				return
			"fridge":
				if S.flags.get("nevera"):
					if extr_algo() or nevera_r() > 0 or total_rosin() > 0:   # 1.36: los extractos, en frío
						await nevera_action()
					else:
						await say("La nevera: medio limón, leche y un táper de alubias que dejó la tía.")
					return
				S.flags.nevera = S.day   # 1.25: el bote de la tía
				await say("Detrás del táper de alubias hay un bote de cristal con una etiqueta: «Choco Thai. NO TOCAR».")
				await semillas_tia("choco", "El frío las ha conservado: siguen buenas.", 3)
				return
			"plantDeco":
				await say("Una monstera. La tía Maite le hablaba cada mañana.")
				return
			"iwin":
				await say("Por la ventana se ve la ría. Huele a salitre.")
				return
			"poster":
				await diploma_action()
				return
	if o == "escaleraC" and S.map == "home":   # 1.43.6: el camarote
		sfx("door")
		await fade(1)
		enter_map("camarote", int(D.CAMAROTE.desde[0]), int(D.CAMAROTE.desde[1]), "up")
		update_hud()
		await wait(80)
		await fade(0)
		return
	if S.map == "camarote":
		match o:
			"estanteC":
				await camarote_action()
				return
			"deshumC":
				await say("El deshumidificador: deja el camarote entre el 58 y el 62 % de humedad, a 18 °C. Los sobres de dentro de los tarros hacen el resto.")
				return
			"crate":
				await say("Cajas de la tía: revistas de jardinería, un ventilador viejo y los adornos de Navidad.")
				return
	if S.map == "casa-ama":   # el caserío de la familia, en Mendialde (1.10)
		match o:
			"table":
				var nueva: bool = not S.flags.get("notaAma")
				S.flags.notaAma = true
				await say("Una nota de tu ama: «Te he dejado un táper de alubias en la nevera. Llama cuando llegues. Y no te metas en líos»." if nueva else "La nota de ama: «...y no te metas en líos».")
				return
			"fridge":
				if S.flags.get("taper"):
					await say("La nevera de casa. El táper ya va en la mochila.")
					return
				S.flags.taper = true
				S.items.bocata += 1
				await got("el táper de alubias de ama (1 × BOCATA)")
				return
			"bedT", "bedB":   # si pierdes el último autobús
				await bed_action("Tu cama de siempre, con la colcha de cuadros.")
				return
			"iwin":
				await say("Por la ventana se ven el monte y la carretera de la comarca.")
				return
			"plantDeco":
				await say("Los geranios de ama. Les sobra agua.")
				return
	var txt := ""
	if S.map == "txaro":
		txt = {"bedT": "Una cama con colcha de ganchillo.", "bedB": "Una cama con colcha de ganchillo.", "table": "Un bote de aceite con una etiqueta a mano: «Para dormir. 2 gotas».",
			"fridge": "Nevera de las de antes. No es tuya.", "iwin": "Por la ventana se ve el parque de los Sauces."}.get(o, "")
	elif S.map == "comisaria":
		txt = {"iwin": "Por la ventana se ve la plaza del Ensanche.", "shelfW": "Archivadores con expedientes. Hay uno con tu calle.", "counter": "El mostrador de denuncias. No hay nadie detrás."}.get(o, "")
	elif S.map == "almacen":
		txt = {"crate": "Cajas precintadas con el sello de una conservera que cerró hace años.", "btable": "Una mesa con una báscula y rollos de film transparente."}.get(o, "")
	if not txt and Datos.CAL and ATREZO_TXT.has(S.map):   # 1.51
		txt = ATREZO_TXT[S.map].get(o, "")
	if txt:
		await say(txt)
		return
	match o:
		"sign":
			var st: String = "%s:%d,%d" % [S.map, x, y]
			await say(D.SIGNS.get(st, "Está tan desgastado que no se lee.") + (("\n" + D.SETAS_SITIO.cartel) if Datos.CAL and st == D.SETAS_SITIO.k else ""))   # 1.43.8
		"parada":
			await parada_action()
		"cajero":   # 1.35 (granja.gd)
			await cajero()
		"rotuloL":
			var k := local_de(S.map, x, y)
			if k != "":
				await rotulo_local(k)
		"bush":
			for it in D.ITEMS:
				if it.hidden and it.map == S.map and it.x == x and it.y == y and not S.taken.get(it.id):
					await pick_item(it)
					return
		"fountain":
			await say("La fuente de la plaza. Lleva años sin agua potable.")
		"shelfW":
			await say("Botes de abono, sustrato de coco y medidores de pH.")
		"display":
			await say("Sobres de semillas de bancos de todo el mundo, ordenados por tipo.")
		"vitrinaP", "vitrinaP2":   # 1.47
			await say("La vitrina iluminada: grinders, pipas de cristal, bongs y vaporizadores. Se piden en el mostrador.")
		"estanteE", "estanteE2":
			await say("Cajetillas de todos los colores, en filas. Lo de liar, en el mostrador.")
		"humidor":
			await say("El humidificador de los puros, con su higrómetro.")
		"papelE":
			await say("El expositor del papel de fumar: librillos de todos los tamaños.")
		"mostrE", "mostrE2":
			await say("Mecheros de colores en la vitrina del mostrador.")
		"bottles":
			await say("Txakoli, pacharán y orujo casero.")
		"jukebox":
			sfx("get")
			await say("La gramola suena: rock vasco de los 80.")
		"crate":
			await say("Cajas de madera de los astilleros, podridas por la humedad." if S.map == "astilleros" else ("Cajas de piezas de la fundición, oxidadas." if S.map == "valdehierro" else ("Cajas de fruta vacías. La frutería de la esquina cerró en verano." if S.map == "callejon" else "Cajas de pescado vacías del puerto.")))

# ---------- acciones y efectos del atlas (01b-arte accion, lanzarVfx) ----------
func accion(nn: String, vf = null) -> void:
	var g = Atlas.grupo_look(D.LOOKS.player)
	if g == null or Atlas.anim_de(g, nn) == null:
		return
	P.act = {"n": nn, "t0": M.reloj}
	if vf:
		lanzar_vfx(vf.id, vf.x, vf.y, M.reloj, S.map, false)
	await wait(Atlas.duracion(g, nn))
	if P.act and P.act.n == nn:
		P.act = null

func lanzar_vfx(id: String, x: float, y: float, now: float, capa: String, sube: bool) -> void:
	if Atlas.anim_de(id, "efecto"):
		vfx.append({"id": id, "x": x, "y": y, "t0": now, "capa": capa, "sube": sube})

# ---------- clientes y venta (10-calle) ----------
func precio_calle(thc: float) -> float:
	return 4 + thc * .2

# los rivales (1.16, 13-combate): con el rival de la zona echado, sus clientes pagan un RIVAL.f más
func rival_f(z: String) -> float:
	return float(D.RIVAL.f) if float(S.rivalFuera.get(z, 0)) >= S.day else 1.0

func precio_mayor(thc: float) -> float:
	return 2 + thc * .1

# rosin (1.10, 10-calle): el gramo, a 10 + 0,6 × THC €
func precio_rosin(thc: float) -> float:
	return 10 + thc * .6

# clientes del día por zona (1.10): en el barrio, como siempre; en el barrio alto, pijos y turistas desde el capítulo 3; en los
# astilleros (las esquinas de Darko), estudiantes y currelas. Con la prensa (1.10), catadores de rosin en la ciudad, los
# astilleros, Puerto Viejo y Valdehierro
func spawn_clients() -> void:
	S.clientsDay = S.day
	S.clients = []
	if S.ch >= 2:
		var nn := mini(10, 4 + int(floor(S.rep / 15.0)) + (1 if S.ch >= 4 else 0))
		var tipos := ["est", "est", "cur", "cur"]
		if S.ch >= 3:
			tipos.append("tur")
		if S.ch >= 4:
			tipos.append_array(["pij", "pij"])
		var zonas := [["town", nn, tipos], ["astilleros", 2 + (1 if S.ch >= 4 else 0), ["est", "cur"]]]
		if S.ch >= 3:
			zonas.append(["alto", 2 + (1 if S.ch >= 4 else 0), ["pij", "tur"]])
		var mas := 1 if S.ch >= 4 else 0   # la comarca (1.10)
		zonas.append_array([["puerto", 2 + mas, ["tur", "tur", "cur", "est"]], ["valdehierro", 2 + mas, ["est", "cur", "cur"]], ["mendialde", 1, ["cur"]], ["errotabarri", 1, ["cur", "tur"]]])
		if S.ch >= 4:   # la ciudad grande (1.14), con su línea
			var m5 := 1 if S.ch >= 5 else 0
			zonas.append_array([["ibarbide", 3 + m5, ["tur", "tur", "pij", "est"]], ["ensanche", 3 + m5, ["pij", "pij", "cur", "est"]], ["callejon", 2, ["est", "cur", "pij"]]])
		var usado := {}
		if S.ch >= 3 and extr_algo():
			for zx in [["town", 2], ["astilleros", 1], ["puerto", 1], ["valdehierro", 1]] + ([["ibarbide", 1], ["ensanche", 1]] if S.ch >= 4 else []):
				zonas.append([zx[0], zx[1], ["ext"], "x"])
		for zz in zonas:
			var map_: String = zz[0]
			if not usado.has(map_):
				usado[map_] = {}
				for d in D.NPCDEF:
					if d.map == map_:
						usado[map_]["%d,%d" % [d.x, d.y]] = true
				for it in D.ITEMS:
					if it.map == map_:
						usado[map_]["%d,%d" % [it.x, it.y]] = true
			var used: Dictionary = usado[map_]
			var pre: String = zz[3] if zz.size() > 3 else ""
			for i in int(zz[1]):
				var t: Array = []
				for k in 30:
					t = pick(D.CLIENT_TILES[map_])
					if not used.has("%d,%d" % [t[0], t[1]]):
						break
				used["%d,%d" % [t[0], t[1]]] = true
				var type: String = pick(zz[2])
				var ct: Dictionary = D.CTYPES[type]
				var id := "c%d_%s%s%d" % [S.day, pre, {"town": "", "alto": "b", "astilleros": "s", "puerto": "p", "valdehierro": "v", "mendialde": "m", "errotabarri": "e", "ibarbide": "i", "ensanche": "n", "callejon": "k"}[map_], i]
				var want := ri(int(ct.g[0]), int(ct.g[1]))
				var mt := 0
				if type == "pij":
					mt = mini(24, 15 + S.ch)
				elif type == "tur" and Cultivo.azar() < .4:
					mt = 15
				S.clients.append({"id": id, "map": map_, "x": int(t[0]), "y": int(t[1]), "type": type, "want": want, "minThc": mt, "look": Datos.rand_look(id, "client")})
	if D.ZONAS.has(S.map):
		build_ents()

func remove_client(id: String) -> void:
	S.clients = S.clients.filter(func(c): return c.id != id)
	ents = ents.filter(func(e): return e.id != id)

# el catador (1.10) solo compra rosin: a precio_rosin, y el «caro» cuela según lo que pase del 50 % de THC
func talk_client(c: Dictionary) -> void:
	var ct: Dictionary = D.CTYPES[c.type]
	var N: String = c.get("n", etiqueta_ct(c.type, mujer_look(c.get("look"))))   # n: el nombre de un cliente de la agenda (12b-movil)
	var ext: bool = c.type == "ext"
	await say(pick(ct.greet), N)
	if ext:
		await say("Busco %s g de rosin o de hachís." % n(c.want), N)
	else:
		await say("Busco %s g%s." % [n(c.want), (" de algo potente, mínimo %s%% de THC" % n(c.minThc)) if c.minThc else ""], N)
	var lots := rosin_lots(c.want) if ext else bud_lots(c.want, c.minThc)
	if lots.is_empty():
		await say("Eso no me vale. Vuelve cuando tengas lo que busco." if (total_rosin() if ext else total_buds()) > 0 else "¿No llevas nada? Vale.", N)
		return
	var it := lots.map(rosin_item if ext else lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué le vendes?"})
	if i < 0 or i >= lots.size():
		await say("Vale, otro día.", N)
		return
	var sid: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var xn: String = (D.EXTR[tipo_extr(sid)].n.to_lower() + " ") if ext else ""
	var base: float = (precio_rosin(b.thc) * D.EXTR[tipo_extr(sid)].px if ext else precio_calle(b.thc)) * calidad(b) * ct.mult * D.ZONAS[c.get("map", "town")].precio * rival_f(c.get("map", "town")) * c.want
	var pr := [Datos.jsround(base * .85), Datos.jsround(base), Datos.jsround(base * 1.3)]
	var j: int = await ask("%s g de %s%s. ¿Cuánto le pides?" % [n(c.want), (xn + "de ") if ext else "", lot_nombre(sid)], ["Rebaja · %d €" % pr[0], "Justo · %d €" % pr[1], "Caro · %d €" % pr[2], "Cancelar"])
	if j == 3:
		await say("Entonces me voy.", N)
		return
	var mt: float = 50.0 if ext else (c.minThc if c.minThc else 14)
	var acc: float = [1.0, .92, clampf(.3 + (b.thc - mt) * .05 + (.25 if c.type == "pij" else 0.0) + (.15 if c.type == "tur" else 0.0) + (.3 if c.type == "vip" else 0.0), .1, .9)][j]
	if j > 0:   # 1.15: la confianza de los de la agenda, la cata y el análisis
		acc = minf(.97, acc + (rel(c.fid) / 250.0 if c.get("fid") else 0.0) + (.05 if b.get("cata") else 0.0) + (.1 if b.get("ana") else 0.0))
	if Cultivo.azar() < acc:
		if c.get("fid"):
			confia(c.fid, [3, 2, 1][j])
		if ext:
			use_rosin(sid, c.want)
		else:
			use_buds(sid, c.want)
		S.money += pr[j]
		S.sales += pr[j]
		S.heat = minf(100, Datos.jsround((S.heat + D.CALOR_CALLE.base + c.want * (D.CALOR_CALLE.rosin if ext else D.CALOR_CALLE.g)) * 10) / 10.0)
		S.rep += [3, 2, 1][j]
		sfx("coin")
		await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
		remove_client(c.id)
		apunta_fijo(c)
		await say(pick(["Trato hecho.", "Gracias. Nos vemos.", "Bien. Se lo diré a mis amigos."]), N)
		toast("+%s · %s g %svendidos" % [Datos.eur(pr[j]), n(c.want), ("de " + xn) if ext else ""], 1600)
		visto_vender()
		heat_warn()
		await check_story()
		rival_venta(c.get("map", "town"))
		# en las esquinas de Darko (1.10), 1 de cada 3 ventas acaba con uno de sus chicos encima
		if c.get("map") == "astilleros" and not S.flags.get("darkoFin") and Cultivo.azar() < 1.0 / 3:
			await say("Uno de los chicos de Darko te ha visto vender.")
			await say("«Te dijimos que lejos de nuestras esquinas.»", "CHICO DE DARKO")
			await battle("thief")
	else:
		S.rep = maxi(0, S.rep - 1)
		if c.get("fid"):
			confia(c.fid, -2)
		sfx("bad")
		remove_client(c.id)
		await say(pick(["¿Tanto? No.", "A ese precio, paso.", "Eso es demasiado. Adiós."]), N)

# policía por niveles (1.11, 11-historia): el nivel por el calor (con la orden, 3), lo que baja cada día y la multa de la redada
func nivel_poli() -> int:
	if S.get("orden"):
		return 3
	var n := 0
	for i in D.NIVEL_POLI.size():
		if S.heat >= D.NIVEL_POLI[i][0]:
			n = i
	return n

func baja_calor() -> float:
	return D.NIVEL_POLI[nivel_poli()][2] * (1.5 if S.protect else 1.0)

func multa_redada(plantas: int, g: int) -> int:
	return mini(int(D.MULTA_TOPE), int(D.MULTA_REDADA) + int(D.MULTA_PLANTA) * plantas + int(D.MULTA_G) * g)

# 1.11: un aviso antes, con 50 (con 60 investigan), que dice por dónde se vende sin tanto calor
func heat_warn() -> void:
	if S.heat >= 70 and not S.flags.get("heatW"):
		S.flags.heatW = true
		S.flags.heatA = true
		toast("<small>CUIDADO</small>La policía investiga. Si el calor llega a %d al cambiar el día, habrá orden de registro." % int(D.NIVEL_POLI[3][0]), 3200)
	elif S.heat >= D.CALOR_AVISO and S.heat < 70 and not S.flags.get("heatA"):
		S.flags.heatA = true
		toast("<small>CALOR</small>Con %d, la policía investiga. Vende menos en la calle: %s con menos calor." % [int(D.NIVEL_POLI[2][0]), "Iñaki compra al por mayor" if S.ch >= 3 else "Iñaki compra 10 g al día"], 3200)
	if S.heat < 60:
		S.flags.heatW = false
	if S.heat < D.CALOR_AVISO - 10:
		S.flags.heatA = false

# ---------- patrullas (1.10, 10b-patrulla.js): los policías se ven por la calle ----------
# PATRULLAS, PAT, CALLE, TAPA_VISTA y las casillas de ronda de cada mapa (RONDA) vienen del HTML (tools/godot.js)
var SOSP := {"v": 0.0, "alarma": null, "sinVer": 0.0, "aviso": 0, "tregua": 0.0}
var _re_calle: RegEx = null
var _re_tapa: RegEx = null
var _re_edif := RegEx.create_from_string("^(roof|wall|win|door)")

static func _hash_t(x: int, y: int) -> int:
	var a := (x * 1103 + y * 2459 + x * y * 31) % 9973
	return (a * a + x * 7 + y * 3) % 9973

func re_calle() -> RegEx:
	if _re_calle == null:
		_re_calle = RegEx.create_from_string(D.CALLE)
		_re_tapa = RegEx.create_from_string(D.TAPA_VISTA)
	return _re_calle

func n_patrullas() -> int:
	var p = D.PATRULLAS.get(S.map)
	var k := int(p[1 if is_night() else 0]) if p != null and S.ch >= 2 else 0
	return k + 1 if k and nivel_poli() >= 2 else k   # investigación (1.11): una más

# lo que enseña la barra del HUD: si cambia, el HUD se rehace sin esperar a su cuarto de segundo
func sosp_hud():
	return ("A" if SOSP.alarma != null else str(Datos.jsround(SOSP.v))) if n_patrullas() else ""

func carga_sosp() -> float:
	return total_buds() + total_rosin()

func sitio_patrulla(i: int) -> Array:
	var l: Array = D.RONDA[S.map]
	var h0 := _hash_t(S.day * 7 + i * 131, S.map.length() * 17 + i)
	for k in l.size():
		var t: Array = l[(h0 + k * 61) % l.size()]
		if absi(t[0] - P.x) + absi(t[1] - P.y) >= 6 and ent_at(t[0], t[1]) == null:
			return [int(t[0]), int(t[1])]
	var t0: Array = l[h0 % l.size()]
	return [int(t0[0]), int(t0[1])]

func mk_patrulla(i: int) -> Dictionary:
	var xy := sitio_patrulla(i)
	var x: int = xy[0]
	var y: int = xy[1]
	var d := {"id": "pat%d" % i, "map": S.map, "x": x, "y": y, "look": "cop"}
	return {"id": d.id, "x": x, "y": y, "px": x * 16.0, "py": y * 16.0, "hx": x, "hy": y, "dir": ["down", "left", "up", "right"][_hash_t(x, y) % 4], "look": D.LOOKS.cop,
		"def": d, "wander": 0, "wt": 0, "moving": false, "t": 0.0, "fx": x, "fy": y, "act": null,
		"pat": true, "mapa": S.map, "pasos": 6 + _hash_t(y, x) % 6, "espera": 0.0, "giro": 0, "caza": false, "dur": float(D.PAT.paso[0])}

func pon_patrullas() -> void:
	var nn := n_patrullas()
	var hay := ents.filter(func(e): return e.get("pat")).size()
	for i in range(hay, nn):
		ents.append(mk_patrulla(i))
	if hay > nn:
		ents = ents.filter(func(e): return not e.get("pat") or int(e.id.substr(3)) < nn)

# ¿ve el agente e la casilla (x, y)? En su cono (o, con lejos, a lejos casillas a la redonda) o pegada a él, con la línea limpia
func ve_casilla(e: Dictionary, x: int, y: int, lejos: int) -> bool:
	re_calle()
	var dx: int = x - e.x
	var dy: int = y - e.y
	var ad := absi(dx) + absi(dy)
	if ad == 0:
		return true
	var m: Dictionary = MAPS[S.map]
	if ad > 1:
		if lejos:
			if ad > lejos:
				return false
		else:
			var f: Array = DV[e.dir]
			var fr: int = dx * f[0] + dy * f[1]
			var la: int = absi(dx * f[1]) + absi(dy * f[0])
			if fr <= 0 or la > fr or fr > int(D.PAT.vista[1 if is_night() else 0]):
				return false
	var nn := maxi(absi(dx), absi(dy))
	for s in range(1, nn):
		var cx: int = e.x + Datos.jsround(float(dx) * s / nn)
		var cy: int = e.y + Datos.jsround(float(dy) * s / nn)
		var o = m.o[cy][cx]
		if _re_edif.search(m.g[cy][cx]) != null or (o and _re_tapa.search(o) != null):
			return false
	return true

func te_pilla(e: Dictionary) -> bool:
	return ve_casilla(e, P.x, P.y, int(D.PAT.vista[0]) * 2 if e.caza else 0)

func _libre_ronda(e: Dictionary, m: Dictionary, d: String) -> bool:
	var nx: int = e.x + DV[d][0]
	var ny: int = e.y + DV[d][1]
	var k := "%d,%d" % [nx, ny]
	if nx < 0 or ny < 0 or nx >= m.w or ny >= m.h or re_calle().search(m.g[ny][nx]) == null:
		return false
	return not tile_solid(m, nx, ny) and ent_at(nx, ny) == null and not (nx == P.x and ny == P.y) and not (P.moving and nx == P.fx and ny == P.fy) \
		and not m.doors.has(k) and not m.exits.has(k) and not llegada_bus(nx, ny)

# un paso de ronda: recto si puede (3 de cada 4), si no, a un lado; media vuelta solo en un callejón
func paso_ronda(e: Dictionary, m: Dictionary) -> void:
	if re_calle().search(m.g[e.y][e.x]) == null:
		paso_vuelta(e, m)
		return
	var ops := ["up", "down", "left", "right"].filter(func(d): return d != OPP[e.dir] and _libre_ronda(e, m, d))
	var otras := ops.filter(func(d): return d != e.dir)
	var d = null
	if ops.has(e.dir) and Cultivo.azar() < .75:
		d = e.dir
	elif otras.size():
		d = pick(otras)
	elif ops.size():
		d = ops[0]
	elif _libre_ronda(e, m, OPP[e.dir]):
		d = OPP[e.dir]
	if d == null:
		return
	e.dir = d
	e.fx = e.x
	e.fy = e.y
	e.x += DV[d][0]
	e.y += DV[d][1]
	e.t = 0.0
	e.moving = true
	e.dur = float(D.PAT.paso[1 if is_night() else 0])

# fuera de la calle (tras una caza, por la hierba o el parque): un paso por el camino más corto a la calle más cercana
func paso_vuelta(e: Dictionary, m: Dictionary) -> void:
	var k0 := "%d,%d" % [e.x, e.y]
	var prev := {k0: null}
	var q := [[e.x, e.y]]
	var fin = null
	var qi := 0
	while qi < q.size() and fin == null:
		var c: Array = q[qi]
		qi += 1
		for d in ["up", "down", "left", "right"]:
			var nx: int = c[0] + DV[d][0]
			var ny: int = c[1] + DV[d][1]
			var k := "%d,%d" % [nx, ny]
			if prev.has(k) or tile_solid(m, nx, ny) or m.doors.has(k) or m.exits.has(k) or (nx == P.x and ny == P.y) or (P.moving and nx == P.fx and ny == P.fy) \
					or ents.any(func(o): return not is_same(o, e) and o.x == nx and o.y == ny):
				continue
			prev[k] = [c[0], c[1], d]
			if re_calle().search(m.g[ny][nx]) != null:
				fin = k
				break
			q.append([nx, ny])
	if fin == null:
		return
	var k: String = fin
	var p: Array = prev[k]
	while "%d,%d" % [p[0], p[1]] != k0:
		k = "%d,%d" % [p[0], p[1]]
		p = prev[k]
	var xy := k.split(",")
	e.dir = p[2]
	e.fx = e.x
	e.fy = e.y
	e.x = int(xy[0])
	e.y = int(xy[1])
	e.t = 0.0
	e.moving = true
	e.dur = float(D.PAT.paso[1 if is_night() else 0])

# un paso de caza: el primero del camino más corto hasta el jugador (por lo que no es sólido, sin puertas ni salidas ni gente)
func paso_caza(e: Dictionary, m: Dictionary) -> void:
	var k0 := "%d,%d" % [e.x, e.y]
	var prev := {k0: null}
	var q := [[e.x, e.y]]
	var fin = null
	var qi := 0
	while qi < q.size() and fin == null:
		var c: Array = q[qi]
		qi += 1
		for d in ["up", "down", "left", "right"]:
			var nx: int = c[0] + DV[d][0]
			var ny: int = c[1] + DV[d][1]
			var k := "%d,%d" % [nx, ny]
			if prev.has(k):
				continue
			if nx == P.x and ny == P.y:
				prev[k] = [c[0], c[1], d]
				fin = k
				break
			if tile_solid(m, nx, ny) or m.doors.has(k) or m.exits.has(k) or ents.any(func(o): return not is_same(o, e) and o.x == nx and o.y == ny):
				continue
			prev[k] = [c[0], c[1], d]
			q.append([nx, ny])
	if fin == null:
		return
	var k: String = fin
	var p: Array = prev[k]
	while "%d,%d" % [p[0], p[1]] != k0:
		k = "%d,%d" % [p[0], p[1]]
		p = prev[k]
	e.dir = p[2]
	var xy := k.split(",")
	var nx := int(xy[0])
	var ny := int(xy[1])
	if nx == P.x and ny == P.y:
		return
	e.fx = e.x
	e.fy = e.y
	e.x = nx
	e.y = ny
	e.t = 0.0
	e.moving = true
	e.dur = float(D.PAT.corre[1 if is_night() else 0])

# en el mundo y libre (update): mueve a los agentes, sube o baja la sospecha y lleva la alarma
func update_patrullas(dt: float) -> void:
	if not D.ZONAS.has(S.map):
		return
	if ents.filter(func(e): return e.get("pat")).size() != n_patrullas():
		pon_patrullas()
	var pats := ents.filter(func(e): return e.get("pat"))
	var m: Dictionary = MAPS[S.map]
	if pats.is_empty():
		SOSP.v = 0.0
		return
	for e in pats:
		if e.moving:
			e.t += dt
			var k := minf(1, e.t / e.dur)
			e.px = (e.fx + (e.x - e.fx) * k) * 16
			e.py = (e.fy + (e.y - e.fy) * k) * 16
			if k >= 1:
				e.moving = false
				e.fx = e.x
				e.fy = e.y
			continue
		if e.caza:
			if e.espera > 0:   # el «¡alto!» (PAT.alto ms quieto)
				e.espera -= dt
				continue
			if absi(e.x - P.x) + absi(e.y - P.y) == 1 and not P.moving:
				pillado(e)
				return
			paso_caza(e, m)
			continue
		if e.espera > 0:
			e.espera -= dt
			if e.espera <= 600 and not e.giro:
				e.giro = 1
				e.dir = pick(["up", "down", "left", "right"])
			continue
		e.pasos -= 1
		if e.pasos <= 0:
			e.pasos = 6 + int(floor(Cultivo.azar() * 6))
			e.espera = 900 + Cultivo.azar() * 900
			e.giro = 0
			continue
		paso_ronda(e, m)
	var ve = null
	for e in pats:
		if te_pilla(e):
			ve = e
			break
	var seg := dt / 1000.0
	if SOSP.alarma != null:
		var e = null
		for p in pats:
			if p.id == SOSP.alarma:
				e = p
		if e == null:   # al cambiar el turno se va el que te seguía
			SOSP.alarma = null
			SOSP.v = 50.0
			music(map_music())
			toast("Lo has despistado.", 1600)
			return
		if ve:
			SOSP.sinVer = 0.0
		else:
			SOSP.sinVer += dt
		if SOSP.sinVer >= D.PAT.olvida and absi(e.x - P.x) + absi(e.y - P.y) > D.PAT.pierde:
			e.caza = false
			e.espera = 1200.0
			SOSP.alarma = null
			SOSP.v = 50.0
			music(map_music())
			toast("Lo has despistado.", 1600)
		return
	if SOSP.tregua > 0:
		SOSP.tregua -= dt
	var g := 0.0 if SOSP.tregua > 0 else carga_sosp()
	if ve and g > 0:
		SOSP.v = minf(100, SOSP.v + (8 + minf(g, 100) * .12) * float(D.PAT.sube[1 if is_night() else 0]) * (1 + S.heat / 100.0) * (.4 if S.protect else 1.0) * seg)
		if not SOSP.aviso and (not is_night() or SOSP.v >= 40):
			SOSP.aviso = 1
			toast("Oyes pasos detrás de ti." if is_night() else "Un agente te está mirando.", 1800)
	else:
		SOSP.v = maxf(0, SOSP.v - D.PAT.baja * seg)
	if SOSP.v >= 100:
		alarma(ve if ve else pats[0])

func alarma(e: Dictionary) -> void:
	SOSP.alarma = e.id
	SOSP.sinVer = 0.0
	e.caza = true
	e.espera = float(D.PAT.alto)
	sfx("enc")
	music(map_music())
	toast("<small>¡ALTO, POLICÍA!</small>Corre (B): métete en un portal o aléjate.", 2200)

# vender cerca de un agente (talk_client), aunque no mire: la sospecha sube de golpe
func visto_vender() -> void:
	if SOSP.alarma != null:
		return
	for e in ents:
		if e.get("pat") and ve_casilla(e, P.x, P.y, int(D.PAT.vista[0])):
			SOSP.v = minf(100, SOSP.v + D.PAT.vende)
			SOSP.aviso = 1
			toast("Un agente te ha visto vender.", 1600)
			return

# te alcanza: el control de siempre (battle); después, una tregua
func pillado(e: Dictionary) -> void:
	e.caza = false
	e.espera = 1500.0
	e.dir = OPP[P.dir]
	SOSP = {"v": 0.0, "alarma": null, "sinVer": 0.0, "aviso": 1, "tregua": float(D.PAT.tregua)}
	run(func(): await battle("police"))

# al cambiar de mapa (enter_map): la sospecha y la alarma se quedan en la calle
func reset_sosp() -> void:
	SOSP = {"v": 0.0, "alarma": null, "sinVer": 0.0, "aviso": 0, "tregua": 0.0}

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

func pieza_de(mapa: String, k: String) -> Dictionary:
	for P_ in D.ORDEN_P[mapa].piezas:
		if P_.k == k:
			return P_
	return {}

func pieza_ya(P_: Dictionary) -> bool:
	match str(P_.get("si", "")):
		"extr":
			return mueble_ya(D.MUEBLE_EXTR[P_.k])
		"mueble":
			return P_.k in muebles_ya()
		"riego":
			return S.get("nave") != null and int(S.nave.get("rg", 0)) >= 1
	return true

func piezas_ya(mapa: String) -> Array:
	return D.ORDEN_P[mapa].piezas.filter(func(P_): return pieza_ya(P_))

func pos_pieza(mapa: String, k: String) -> Array:
	if ORDEN != null and ORDEN.mapa == mapa and ORDEN.k == k:
		return [int(ORDEN.x), int(ORDEN.y)]
	var c = S.get("coloca") if S != null else null
	if c is Dictionary and c.get(mapa) is Dictionary and c[mapa].has(k):
		return [int(c[mapa][k][0]), int(c[mapa][k][1])]
	var d: Array = pieza_de(mapa, k).def
	return [int(d[0]), int(d[1])]

func celdas_p(P_: Dictionary, x: int, y: int) -> Array:
	var l := []
	for o in P_.o:
		var ob_ = o[2] if o.size() > 2 else null
		if o.size() > 3 and not (S.get("nave") != null and int(S.nave.get("rg", 0)) >= int(o[3])):
			ob_ = null
		l.append([x + int(o[0]), y + int(o[1]), ob_])
	return l

func gente_p(P_: Dictionary, x: int, y: int) -> Array:
	var l := []
	for g in P_.get("gente", []):
		l.append([x + int(g[0]), y + int(g[1]), g[2], g[3]])
	return l

func gente_fija(mapa: String) -> Array:
	var con := {}
	for P_ in D.ORDEN_P[mapa].piezas:
		for g in P_.get("gente", []):
			con[g[2]] = true
	var l := []
	for d in D.NPCDEF:
		if d.map == mapa and not con.has(d.id):
			l.append([int(d.x), int(d.y)])
	return l

func hueco_carpa(mapa: String) -> Array:
	var l := []
	if mapa != "home":
		return l
	for ci in D.SITIOS.size():
		if sitio_visible(ci):
			var s: Dictionary = D.SITIOS[ci]
			for j in int(s.w):
				l.append([int(s.x) + j, int(s.y)])
	return l

func pisable(m: Dictionary, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= int(m.w) or y >= int(m.h):
		return false
	var k := "%d,%d" % [x, y]
	return SOLID_G.search(m.g[y][x]) == null and m.g[y][x] != "mat" and not m.exits.has(k) and not m.doors.has(k)

func andable(m: Dictionary, O: Array, B := {}) -> Dictionary:
	var v := {}
	var q := []
	var semillas: Array = m.exits.keys()
	for mp in (D.PUERTAS_INT if Datos.CAL and D.has("PUERTAS_INT") else {}):   # 1.51: las puertas de dentro también son entradas
		if is_same(MAPS.get(mp), m):
			for e in D.PUERTAS_INT[mp]:
				semillas.append("%d,%d" % [int(e.x), int(e.y)])
	for k in semillas:
		var p: PackedStringArray = k.split(",")
		var x := int(p[0])
		var y := int(p[1])
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			var nx: int = x + d[0]
			var ny: int = y + d[1]
			var kk := "%d,%d" % [nx, ny]
			if not v.has(kk) and pisable(m, nx, ny) and not O[ny][nx] and not B.has(kk):
				v[kk] = true
				q.append([nx, ny])
	var i := 0
	while i < q.size():
		var c: Array = q[i]
		i += 1
		for d in DIRS_ORDEN:
			var nx: int = c[0] + d[0]
			var ny: int = c[1] + d[1]
			var kk := "%d,%d" % [nx, ny]
			if not v.has(kk) and pisable(m, nx, ny) and not O[ny][nx] and not B.has(kk):
				v[kk] = true
				q.append([nx, ny])
	return v

func copia_o(m: Dictionary) -> Array:
	return m.o.map(func(r): return r.duplicate())

func sin_pieza(mapa: String, k: String) -> Array:
	var m: Dictionary = MAPS[mapa]
	var O := copia_o(m)
	var P_ := pieza_de(mapa, k)
	var op = m.get("opos", {})
	if op.has(k) and not P_.get("suelo"):
		for c in celdas_p(P_, int(op[k][0]), int(op[k][1])):
			if c[1] >= 0 and c[1] < O.size() and c[0] >= 0 and c[0] < O[c[1]].size():
				O[c[1]][c[0]] = null
	return O

# '' si la pieza k cabe en (x, y); si no, el motivo (D.ORDEN_MOTIVO)
func cabe_pieza(mapa: String, k: String, x: int, y: int, O = null, jug := true) -> String:
	if O == null:
		O = sin_pieza(mapa, k)
	var m: Dictionary = MAPS[mapa]
	var Dm: Dictionary = D.ORDEN_P[mapa]
	var P_ := pieza_de(mapa, k)
	var F := celdas_p(P_, x, y)
	var G := gente_p(P_, x, y)
	for c in F + G:
		if c[0] < 0 or c[1] < 0 or c[0] >= int(m.w) or c[1] >= int(m.h):
			return "fuera"
	var fila := func(cy: int, dy: int) -> bool:
		if dy < 0:
			return cy == 1
		if P_.has("fila"):
			return cy == int(P_.fila)
		return cy >= int(Dm.filas[0]) and cy <= int(Dm.filas[1])
	if P_.get("suelo"):
		for c in F:
			if not fila.call(c[1], 0) or not pisable(m, c[0], c[1]):
				return "fuera"
		return ""
	for j in F.size():
		var dy := int(P_.o[j][1])
		if not fila.call(F[j][1], dy) or (dy >= 0 and not pisable(m, F[j][0], F[j][1])):
			return "fuera"
	for c in G:
		if not pisable(m, c[0], c[1]):
			return "fuera"
	var res := {}
	for c in gente_fija(mapa) + Dm.pie + reserva_orden(mapa):
		res["%d,%d" % [int(c[0]), int(c[1])]] = true
	var otras: Array = piezas_ya(mapa).filter(func(Q): return Q.k != k)
	for Q in otras:
		var q := pos_pieza(mapa, Q.k)
		for g in gente_p(Q, q[0], q[1]):
			res["%d,%d" % [g[0], g[1]]] = true
	var hueco := {}
	for c in hueco_carpa(mapa):
		hueco["%d,%d" % [c[0], c[1]]] = true
	for c in F + G:
		var kk := "%d,%d" % [c[0], c[1]]
		if hueco.has(kk):
			return "carpa"
		if O[c[1]][c[0]] or res.has(kk):
			return "ocupado"
	if jug and S.map == mapa:
		for c in F + G:
			if c[0] == int(P.x) and c[1] == int(P.y):
				return "tu"
	var O2: Array = O.map(func(r): return r.duplicate())
	for c in F:
		O2[c[1]][c[0]] = c[2]
	# la gente no se mueve y no se pasa por ella: a cada uno se le habla desde al lado o por encima de un mostrador
	var gente: Array = gente_fija(mapa) + G
	for Q in otras:
		var q := pos_pieza(mapa, Q.k)
		gente += gente_p(Q, q[0], q[1])
	var B := {}
	for g in gente:
		B["%d,%d" % [int(g[0]), int(g[1])]] = true
	var v := andable(m, O2, B)
	var deben: Array = Dm.pie + hueco_carpa(mapa)
	if jug and S.map == mapa:
		deben.append([int(P.x), int(P.y)])
	for c in deben:
		if not v.has("%d,%d" % [int(c[0]), int(c[1])]):
			return "paso"
	for g in gente:
		var gx := int(g[0])
		var gy := int(g[1])
		var ok := false
		for d in DIRS_ORDEN:
			var nx: int = gx + d[0]
			var ny: int = gy + d[1]
			if v.has("%d,%d" % [nx, ny]):
				ok = true
			elif ny >= 0 and ny < O2.size() and nx >= 0 and nx < O2[ny].size() and O2[ny][nx] and v.has("%d,%d" % [gx + 2 * d[0], gy + 2 * d[1]]):
				ok = true
			if ok:
				break
		if not ok:
			return "paso"
	for cy in range(2, int(m.h)):
		for cx in int(m.w):
			var o = O2[cy][cx]
			if not o or ORDEN_SIN_LADO.search(o) != null:
				continue
			var lado := false
			for d in DIRS_ORDEN:
				var kd := "%d,%d" % [cx + d[0], cy + d[1]]
				if v.has(kd) or B.has(kd):
					lado = true
					break
			if not lado:
				return "paso"
	if mapa == "nave" and S.get("nave") != null and int(S.nave.get("rg", 0)) >= 1:
		var pos := {k: [x, y]}
		for i in D.MESAS_X.size():
			if ruta_riego(i, O2, pos) == null:
				return "riego"
	return ""

# quita las piezas del mapa (las de serie del plano la primera vez: las que están enteras en su sitio de serie)
func quita_orden(mapa: String) -> void:
	var m: Dictionary = MAPS[mapa]
	if not m.has("opos"):
		m.opos = {}
		for P_ in D.ORDEN_P[mapa].piezas:
			if P_.get("suelo"):
				continue
			var ok := true
			for o in P_.o:
				var yy: int = int(P_.def[1]) + int(o[1])
				var xx: int = int(P_.def[0]) + int(o[0])
				if not (yy >= 0 and yy < int(m.h) and xx >= 0 and xx < int(m.w) and m.o[yy][xx] == (o[2] if o.size() > 2 else null)):
					ok = false
					break
			if ok:
				m.opos[P_.k] = [int(P_.def[0]), int(P_.def[1])]
	for k in m.opos:
		var P_ := pieza_de(mapa, k)
		if P_.get("suelo"):
			continue
		for o in P_.o:
			var xx: int = int(m.opos[k][0]) + int(o[0])
			var yy: int = int(m.opos[k][1]) + int(o[1])
			if xx >= 0 and yy >= 0 and xx < int(m.w) and yy < int(m.h):
				m.o[yy][xx] = null
	m.opos = {}

# monta las piezas: cada una donde se eligió; si ya no cabe, en su sitio de reserva o en el libre más cercano (y se apunta)
func aplica_orden(mapa: String) -> void:
	if not MAPS.has(mapa) or S == null:
		return
	var m: Dictionary = MAPS[mapa]
	quita_orden(mapa)
	for P_ in piezas_ya(mapa):
		var p := pos_pieza(mapa, P_.k)
		if cabe_pieza(mapa, P_.k, p[0], p[1], copia_o(m), false) != "":
			var cs := []
			if P_.has("alt"):
				cs.append([int(P_.alt[0]), int(P_.alt[1])])
			cs += cercanas(m, p)
			var hit = null
			for c in cs:
				if cabe_pieza(mapa, P_.k, c[0], c[1], copia_o(m), false) == "":
					hit = c
					break
			if hit == null:
				continue
			p = hit
			if not (S.get("coloca") is Dictionary):
				S.coloca = {}
			if not S.coloca.has(mapa):
				S.coloca[mapa] = {}
			S.coloca[mapa][P_.k] = [p[0], p[1]]
		m.opos[P_.k] = [p[0], p[1]]
		if not P_.get("suelo"):
			for c in celdas_p(P_, p[0], p[1]):
				if c[0] >= 0 and c[1] >= 0 and c[0] < int(m.w) and c[1] < int(m.h):
					m.o[c[1]][c[0]] = c[2]

func cercanas(m: Dictionary, p: Array) -> Array:
	var c := []
	for y in int(m.h):
		for x in int(m.w):
			c.append([x, y])
	var x0: int = p[0]
	var y0: int = p[1]
	c.sort_custom(func(a, b):
		var da: int = absi(a[0] - x0) + absi(a[1] - y0)
		var db: int = absi(b[0] - x0) + absi(b[1] - y0)
		if da != db:
			return da < db
		if a[1] != b[1]:
			return a[1] < b[1]
		return a[0] < b[0])
	return c

func coloca_gente(mapa: String) -> void:
	if mapa == "nave":
		coloca_naveros()
		return
	for P_ in piezas_ya(mapa):
		var q := pos_pieza(mapa, P_.k)
		for g in gente_p(P_, q[0], q[1]):
			for e in ents:
				if e.id == g[2]:
					e.x = g[0]; e.y = g[1]; e.px = g[0] * 16.0; e.py = g[1] * 16.0; e.hx = g[0]; e.hy = g[1]; e.fx = g[0]; e.fy = g[1]; e.dir = g[3]; e.moving = false
					break

func montar_club(mapa: String) -> void:
	if mapa.begins_with("club-") and D.ORDEN_P.has(mapa):
		aplica_orden(mapa)
	if mapa == "club-rv":   # 1.45 (lo pidió el usuario): el almacén del club, de presidente (MERCADO.alm)
		var m: Dictionary = MAPS[mapa]
		for y in int(m.h):
			for x in int(m.w):
				if m.o[y][x] == "almC":
					m.o[y][x] = null
		if Datos.CAL and S != null and S.get("aso") is Dictionary and S.aso.get("pres"):
			for q in [[9, 2], [12, 2], [13, 2], [11, 2]]:
				if m.o[q[1]][q[0]] == null and m.o[q[1] + 1][q[0]] == null:
					m.o[q[1]][q[0]] = "almC"
					break

func ordenar(_mapa: String) -> void:   # trama
	pass

# el marco de la pieza en el cursor: verde si cabe, rojo si no; y la casilla de su gente, en azul
func rects_orden() -> Array:
	if ORDEN == null:
		return []
	var P_ := pieza_de(ORDEN.mapa, ORDEN.k)
	var F := []
	var cs := celdas_p(P_, ORDEN.x, ORDEN.y)
	for j in cs.size():
		if P_.get("suelo") or int(P_.o[j][1]) >= 0:
			F.append(cs[j])
	var c := "#e04040" if ORDEN.no != "" else "#58d080"
	var x0 := 99999
	var y0 := 99999
	var x1 := -99999
	var y1 := -99999
	for f in F:
		x0 = mini(x0, f[0] * 16); y0 = mini(y0, f[1] * 16); x1 = maxi(x1, (f[0] + 1) * 16); y1 = maxi(y1, (f[1] + 1) * 16)
	var o := [[x0, y0, x1 - x0, 1, c], [x0, y1 - 1, x1 - x0, 1, c], [x0, y0, 1, y1 - y0, c], [x1 - 1, y0, 1, y1 - y0, c]]
	for g in gente_p(P_, ORDEN.x, ORDEN.y):
		o.append([g[0] * 16 + 6, g[1] * 16 + 6, 4, 4, "#80b0f0"])
	return o

# las mesas de la nave, donde estén
func pos_mesa(i: int) -> Array:
	return pos_pieza("nave", "m" + str(i))

func mesa_idx(x: int, y: int) -> int:
	for i in D.MESAS_X.size():
		var p := pos_mesa(i)
		if p[1] == y and (p[0] == x or p[0] + 1 == x):
			return i
	return -1

# la lámpara del billar de la asociación, sobre el billar, donde esté
func luz_club(k: String) -> Dictionary:
	var L: Dictionary = D.LUZ_CLUB[k]
	if k != "rv":
		return L
	var p := pos_pieza("club-rv", "billar")
	var l0: Array = [p[0] * 16 + 16, p[1] * 16 + 6] + L.l[0].slice(2)
	return {"fondo": L.fondo, "l": [l0, L.l[1]]}

# la manguera guiada (rutaRiego): {c, t, lado, Y} o null
func ruta_riego(i: int, O = null, pos := {}):
	var m: Dictionary = MAPS.nave
	if O == null:
		O = m.o
	var XY: Array = pos["m" + str(i)] if pos.has("m" + str(i)) else pos_mesa(i)
	var X: int = int(XY[0])
	var Y: int = int(XY[1])
	var T: int = int((pos.riego if pos.has("riego") else pos_pieza("nave", "riego"))[0])
	var libre := func(x: int, y: int) -> bool: return y >= 3 and pisable(m, x, y) and not O[y][x]
	var fin := func(x: int, y: int) -> String:
		if y == Y - 1 and (x == X or x == X + 1):
			return "up"
		if y == Y and x == X - 1:
			return "right"
		if y == Y and x == X + 2:
			return "left"
		return ""
	var peso := func(c: int) -> float: return (100.0 if c == T else 0.0) + (0.0 if c == X else 0.5 if c == X + 1 else 1.0 + absi(c - X))
	var cols := range(int(m.w))
	cols.sort_custom(func(a, b):
		var pa: float = peso.call(a)
		var pb: float = peso.call(b)
		if pa != pb:
			return pa < pb
		return a < b)
	for c in cols:
		if Y == 3:
			if c == X or c == X + 1:
				return {"c": c, "t": [], "lado": "up", "Y": Y}
			continue
		if not libre.call(c, 3):
			continue
		var pa := {"%d,3" % c: null}
		var q := [[c, 3]]
		var hit = null
		var i_ := 0
		while i_ < q.size():
			var cu: Array = q[i_]
			i_ += 1
			if fin.call(cu[0], cu[1]) != "":
				hit = cu
				break
			for d in DIRS_ORDEN:
				var nx: int = cu[0] + d[0]
				var ny: int = cu[1] + d[1]
				var kk := "%d,%d" % [nx, ny]
				if not pa.has(kk) and libre.call(nx, ny):
					pa[kk] = cu
					q.append([nx, ny])
		if hit == null:
			continue
		var t := []
		var p = hit
		while p != null:
			t.push_front(p)
			p = pa["%d,%d" % [p[0], p[1]]]
		return {"c": c, "t": t, "lado": fin.call(hit[0], hit[1]), "Y": Y}
	return null

# la manguera de la nave (mangueraNave, 11j-locales): el grifo, la tubería por el pie de la pared y cada bajada por su ruta
func manguera_nave() -> Array:
	if S == null or S.get("nave") == null or not int(S.nave.get("rg", 0)):
		return []
	var rg := int(S.nave.rg)
	var key := str(rg) + "|" + JSON.stringify(S.get("coloca", {}).get("nave", {})) + "|" + (str(ORDEN.k) + str(ORDEN.x) + "," + str(ORDEN.y) if ORDEN != null and ORDEN.mapa == "nave" else "")
	if RIEGO_CACHE != null and RIEGO_CACHE.key == key:
		return RIEGO_CACHE.o
	var y: int = int(D.RIEGO_Y)
	var K := "#1c1d22"
	var G := "#3a3c44"
	var L := "#8a92a2"
	var o := []
	var TX: int = pos_pieza("nave", "riego")[0]
	var t0: int = TX * 16 + 8
	var cx: int = (TX + 2) * 16
	var rutas := []
	for i in D.MESAS_X.size():
		var r = ruta_riego(i)
		if r != null:
			rutas.append(r)
	o.append_array([[t0, 0, 1, 12, "#a46e40"], [t0 + 1, 0, 1, 12, "#dcac6c"], [t0 - 2, 12, 5, 2, L], [t0 - 1, 10, 3, 1, "#e04040"], [t0, 9, 1, 1, "#e04040"], [t0, 14, 1, 2, L], [t0, 16, 1, 7, G]])
	var a := t0
	var b := t0
	for r in rutas:
		a = mini(a, int(r.c) * 16 + 8)
		b = maxi(b, int(r.c) * 16 + 8)
	o.append_array([[a, y, b + 1 - a, 1, G], [a, y + 1, b + 1 - a, 1, K]])
	var xx := t0 + 32
	while xx < b:
		o.append([xx, y - 1, 1, 3, L])
		xx += 32
	xx = t0 - 32
	while xx > a:
		o.append([xx, y - 1, 1, 3, L])
		xx -= 32
	for r in rutas:
		var x: int = int(r.c) * 16 + 8
		var pts := [[x, y + 2]]
		for tt in r.t:
			pts.append([int(tt[0]) * 16 + 8, int(tt[1]) * 16 + 8])
		var e: Array = pts[pts.size() - 1]
		pts.append([e[0], int(r.Y) * 16 - 7] if r.lado == "up" else [e[0] + (-9 if r.lado == "left" else 9), e[1]])
		var j := pts.size() - 2
		while j > 0:
			var p0: Array = pts[j - 1]
			var p1: Array = pts[j]
			var p2: Array = pts[j + 1]
			if (p0[0] == p1[0] and p1[0] == p2[0]) or (p0[1] == p1[1] and p1[1] == p2[1]):
				pts.remove_at(j)
			j -= 1
		for jj in range(1, pts.size()):
			var q1: Array = pts[jj - 1]
			var q2: Array = pts[jj]
			if q1[0] == q2[0]:
				o.append_array([[q1[0], mini(q1[1], q2[1]), 1, absi(q2[1] - q1[1]), K], [q1[0] + 1, mini(q1[1], q2[1]), 1, absi(q2[1] - q1[1]), G]])
			else:
				o.append_array([[mini(q1[0], q2[0]), q1[1], absi(q2[0] - q1[0]) + 2, 1, K], [mini(q1[0], q2[0]), q1[1] + 1, absi(q2[0] - q1[0]) + 2, 1, G]])
		if rg < 2:
			o.append_array([[x - 1, y - 1, 3, 2, L], [x - 1, y - 2, 3, 1, "#e04040"]])
		else:
			o.append_array([[x - 1, y - 2, 3, 3, "#4a72c2"], [x - 1, y - 5, 3, 3, "#26262e"]])
			var c: int = cx + (int(D.RIEGO_CTRL[0]) if x < cx + int(D.RIEGO_CTRL[0]) else int(D.RIEGO_CTRL[1]))
			o.append_array([[x, int(D.RIEGO_CABLE), 1, y - 5 - int(D.RIEGO_CABLE), "#26262e"], [mini(x, c), int(D.RIEGO_CABLE), absi(c - x) + 1, 1, "#26262e"]])
	RIEGO_CACHE = {"key": key, "o": o}
	return o
