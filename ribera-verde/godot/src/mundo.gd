# Ribera Verde (Godot) — 04-mapas, 08-mundo y 10-calle: el estado S, los mapas, el jugador y los personajes, moverse, hablar y
# coger cosas, y los clientes de la calle. Igual que el HTML: los guiones son corrutinas lanzadas con run() (lock), los eventos
# de historia esperan en pending (queue) a que el mundo quede libre y todo el azar pasa por Cultivo.azar() (Math.random).
extends "res://src/ui.gd"

const TS := 16
const SH := 160
const DV := {"up": [0, -1], "down": [0, 1], "left": [-1, 0], "right": [1, 0]}
const OPP := {"up": "down", "down": "up", "left": "right", "right": "left"}
const COUNTERS := ["counter", "barcounter", "btable"]
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

# el rosin de la caja (S.caja.rosin, que no existe hasta que guardas el primero): ocupa el hueco de los cogollos
func caja_r() -> float:
	var t := 0.0
	if S.get("caja") and S.caja.get("rosin"):
		for k in S.caja.rosin:
			t += S.caja.rosin[k].g
	return t

# lo que llevas encima (cogollos y rosin) y su tope, la mochila (1.10, 09c-sala); el arcón de casa no tiene tope
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

func arcon_g() -> float:
	var t := 0.0
	for k in S.arcon.buds:
		t += S.arcon.buds[k].g
	return t

func arcon_r() -> float:
	var t := 0.0
	for k in S.arcon.rosin:
		t += S.arcon.rosin[k].g
	return t

# la agenda del móvil (1.10, 12b-movil): el cliente que te compra te da su número
func nombre_fijo(id: String) -> String:
	var a := 0
	for i in id.length():
		a = (a * 31 + id.unicode_at(i)) % 9973
	return D.NOMBRES_FIJO[a % D.NOMBRES_FIJO.size()]

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

# g gramos del lote k de «de» a «a»: si el lote ya está, se juntan con el THC medio por gramos
func mover_lote(de: Dictionary, a: Dictionary, k: String, g: float) -> void:
	var b: Dictionary = de[k]
	if a.has(k):
		var t: Dictionary = a[k]
		t.thc = (t.thc * t.g + b.thc * g) / (t.g + g)
		t.g += g
	else:
		a[k] = {"g": g, "thc": b.thc}
	b.g -= g
	if b.g < .5:
		de.erase(k)

# lo mismo con el rosin, al décimo de gramo (como add_rosin y use_rosin)
func mover_rosin(de: Dictionary, a: Dictionary, k: String, g: float) -> void:
	var b: Dictionary = de[k]
	if a.has(k):
		var t: Dictionary = a[k]
		t.thc = (t.thc * t.g + b.thc * g) / (t.g + g)
		t.g = Datos.jsround((t.g + g) * 10) / 10.0
	else:
		a[k] = {"g": g, "thc": b.thc}
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
		linea_ind(k), G.n, (" (" + pa + ")") if pa else "", G.d, Datos.miles(G.uno), s.o]

func discover(sid: String) -> void:
	if not S.disc.get(sid):
		S.disc[sid] = true
		toast("<small>NUEVA EN LA GENOTECA</small>" + esc(strain(sid).n))
		queue("historia", check_story)

func add_seeds(sid: String, k: int) -> void:
	S.seeds[sid] = S.seeds.get(sid, 0) + k
	discover(sid)

func lot_sid(k: String) -> String:
	return k.trim_suffix("*")

func lot_nombre(k: String) -> String:
	return strain(lot_sid(k)).n + (" ★" if k.ends_with("*") else "")

func add_buds(k: String, g: float, thc: float) -> void:
	if S.buds.has(k):
		var b: Dictionary = S.buds[k]
		b.thc = (b.thc * b.g + thc * g) / (b.g + g)
		b.g += g
	else:
		S.buds[k] = {"g": g, "thc": thc}
	discover(lot_sid(k))

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
	return {"label": "Rosin · " + lot_nombre(k), "right": "%s g · %s%%" % [Datos.coma(l[1].g), Datos.pct(l[1].thc)], "sw": "#d89a18", "ic": ic_cog(lot_sid(k))}

# el prólogo (1.10): S.flags.llegada === false hasta que el autobús de ama deja al jugador en Ribera Verde (las partidas viejas
# no la llevan: ya han llegado)
func llegando() -> bool:
	return S.flags.has("llegada") and S.flags.llegada is bool and S.flags.llegada == false

func got(t: String) -> void:
	sfx("get")
	await say("Consigues %s." % t)

# ---------- mapas (04-mapas) ----------
func montar_casa() -> void:
	var h: Dictionary = MAPS.home
	if S == null:
		return
	var ks := []
	for c in S.carpas:
		ks.append(c.t if c else "-")
	var ya := muebles_ya()
	var key := ",".join(ks) + "|" + ",".join(ya)
	if h.get("carpasK") == key:
		return
	h.carpasK = key
	for s in D.SITIOS:
		for x in range(s.x, s.x + s.w):
			h.o[s.y][x] = null
	for k in D.MUEBLES:   # los muebles del salón que ya han llegado (12c-salon): k y k + "2"
		var mu: Dictionary = D.MUEBLES[k]
		h.o[mu.y][mu.x] = k if k in ya else null
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
	if o.ends_with("2") and D.MUEBLES.has(o.left(-1)):
		return o.left(-1)
	return ""

func sitio_visible(ci: int) -> bool:
	return not (ci < S.carpas.size() and S.carpas[ci]) and (ci < 2 or (S.carpas.size() > 1 and S.carpas[1] != null))

func sitio_libre(x: int, y: int) -> int:
	for ci in D.SITIOS.size():
		var s: Dictionary = D.SITIOS[ci]
		if sitio_visible(ci) and x >= s.x and x < s.x + s.w and y == s.y:
			return ci
	return -1

# ---------- personajes (NPCDEF: cond y talk, que el JSON no lleva) ----------
func npc_cond(d: Dictionary) -> bool:
	match d.id:
		"tono":
			return S.ch >= 3 and S.ch < 8
		"inaki", "cop":
			return S.ch >= 2
		"darko":
			return (S.ch >= 2 and S.ch < 7 and not S.flags.get("darko1")) or S.ch == 6
		"darko2":
			return S.ch >= 7
		"txaro":    # 1.10: después del aceite, en su casa
			return (d.map == "txaro") == (true if S.flags.get("txaro") else false)
		"molina":   # 1.10: la primera vez en la plaza; después, en la comisaría
			return S.ch >= 5 and (d.map == "comisaria") == (true if S.flags.get("molina1") else false)
		"tono2":
			return S.get("encargo") != null
		"jurado":
			return S.ch == 6
	return true

func npc_talk(d: Dictionary) -> void:
	if d.get("look") == "cop" and d.id.begins_with("pat"):   # las patrullas (1.10)
		await say(pick(["«Circule.»", "«Buenas. Nada que ver aquí.»", "«¿Todo bien? Siga.»"]), "AGENTE")
		return
	match d.id:
		"kiko":
			await talk_kiko()
		"josune":
			await talk_josune()
		"baltasar":
			await talk_baltasar()
		"tono":
			await say(pick(["Don Baltasar está ocupado. Habla con él si traes el dinero.", "Aquí dentro no se hacen preguntas."]), "TOÑO")
		"begona":
			await say(pick(["Bajo una lámpara las plantas beben mucho. Riégalas a diario, majo.", "Si se te ponen amarillas las hojas de abajo, les falta agua o abono.", "Tu tía siempre tenía el piso oliendo a limón. Ahora sé por qué."]), "BEGOÑA")
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
			await say(pick(["La fundición cerró hace años. Ahora el solar no es de nadie.", "Aquí la gente cobra poco y paga poco. Y de noche, cuidado con la cartera.", "De Valdehierro a Ribera Verde, veinte minutos de autobús."]), "OBRERO")

func mk_ent(d: Dictionary) -> Dictionary:
	var look = d.get("lookObj")
	if look == null:
		look = D.LOOKS.get(d.get("look", ""))
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
	for c in S.clients:
		if c.get("map", "town") == S.map:
			ents.append(old[c.id] if old.has(c.id) else mk_ent({"id": c.id, "x": c.x, "y": c.y, "wander": 2, "lookObj": c.look, "client": c}))
	for e in old.values():   # las patrullas (más abajo)
		if e.get("pat") and e.mapa == S.map:
			ents.append(e)
	pon_patrullas()

func item_give(id: String) -> void:
	match id:
		"i_spray":
			S.items.spray += 2
			await got("2 × SPRAY DE PIMIENTA")
		"i_fert":
			S.items.fert += 3
			await got("3 dosis de ABONO")
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

func enter_map(name_: String, x: int, y: int, dir = null) -> void:
	S.map = name_
	if name_ == "home":
		montar_casa()
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

func map_music() -> String:
	return ("night" if is_night() else "town") if D.ZONAS.has(S.map) else "home"

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
	P.dur = 130.0 if held.B else 240.0
	P.parity ^= 1

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
		run(func(): await warp(door))
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
	if b == "A":
		interact()
	elif b == "START":
		run(start_menu)
	elif b == "MOVIL":
		run(movil_menu)

func interact() -> void:
	var dv: Array = DV[P.dir]
	var m: Dictionary = MAPS[S.map]
	var tx: int = P.x + dv[0]
	var ty: int = P.y + dv[1]
	var e = ent_at(tx, ty)
	if e == null and ty >= 0 and ty < m.h and tx >= 0 and tx < m.w and m.o[ty][tx] in COUNTERS:
		e = ent_at(tx + dv[0], ty + dv[1])
	if e:
		run(func():
			if not e.moving:
				e.dir = OPP[P.dir]
			if e.def.get("client"):
				await talk_client(e.def.client)
			else:
				await npc_talk(e.def))
		return
	var it = item_at(tx, ty)
	if it:
		run(func(): await pick_item(it))
		return
	run(func(): await object_action(tx, ty))

func object_action(x: int, y: int) -> void:
	var m: Dictionary = MAPS[S.map]
	var o = m.o[y][x] if y >= 0 and y < m.h and x >= 0 and x < m.w else null
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
			if (x == mu.x or x == mu.x + 1) and y == mu.y:
				var pd = S.get("muebles", {}).get(k) if S.get("muebles") is Dictionary else null
				await say(("Aquí va %s: llega mañana." % mu.art) if pd else ("Aquí iría bien %s. Se compra por internet: en el ordenador de la tía o con el móvil." % mu.art))
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
			"table":
				await letter_action()
				return
			"fridge":
				await say("La nevera: medio limón, leche y un táper de alubias que dejó la tía.")
				return
			"crate":
				await arcon_action()
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
	if txt:
		await say(txt)
		return
	match o:
		"sign":
			await say(D.SIGNS.get("%s:%d,%d" % [S.map, x, y], "Está tan desgastado que no se lee."))
		"parada":
			await parada_action()
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
		"bottles":
			await say("Txakoli, pacharán y orujo casero.")
		"jukebox":
			sfx("get")
			await say("La gramola suena: rock vasco de los 80.")
		"crate":
			await say("Cajas de madera de los astilleros, podridas por la humedad." if S.map == "astilleros" else ("Cajas de piezas de la fundición, oxidadas." if S.map == "valdehierro" else "Cajas de pescado vacías del puerto."))

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
		var usado := {}
		if S.ch >= 3 and S.items.get("prensa"):
			for zx in [["town", 2], ["astilleros", 1], ["puerto", 1], ["valdehierro", 1]]:
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
				var id := "c%d_%s%s%d" % [S.day, pre, {"town": "", "alto": "b", "astilleros": "s", "puerto": "p", "valdehierro": "v", "mendialde": "m", "errotabarri": "e"}[map_], i]
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
	var N: String = c.get("n", ct.label)   # n: el nombre de un cliente de la agenda (12b-movil)
	var ext: bool = c.type == "ext"
	await say(pick(ct.greet), N)
	if ext:
		await say("Busco %s g de rosin." % n(c.want), N)
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
	var base: float = (precio_rosin(b.thc) if ext else precio_calle(b.thc)) * ct.mult * D.ZONAS[c.get("map", "town")].precio * c.want
	var pr := [Datos.jsround(base * .85), Datos.jsround(base), Datos.jsround(base * 1.3)]
	var j: int = await ask("%s g de %s%s. ¿Cuánto le pides?" % [n(c.want), "rosin de " if ext else "", lot_nombre(sid)], ["Rebaja · %d €" % pr[0], "Justo · %d €" % pr[1], "Caro · %d €" % pr[2], "Cancelar"])
	if j == 3:
		await say("Entonces me voy.", N)
		return
	var mt: float = 50.0 if ext else (c.minThc if c.minThc else 14)
	var acc: float = [1.0, .92, clampf(.3 + (b.thc - mt) * .05 + (.25 if c.type == "pij" else 0.0) + (.15 if c.type == "tur" else 0.0), .1, .9)][j]
	if Cultivo.azar() < acc:
		if ext:
			use_rosin(sid, c.want)
		else:
			use_buds(sid, c.want)
		S.money += pr[j]
		S.sales += pr[j]
		S.heat = minf(100, S.heat + 3 + c.want * (2.5 if ext else .5))
		S.rep += [3, 2, 1][j]
		sfx("coin")
		await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
		remove_client(c.id)
		apunta_fijo(c)
		await say(pick(["Trato hecho.", "Gracias. Nos vemos.", "Bien. Se lo diré a mis amigos."]), N)
		toast("+%s · %s g %svendidos" % [Datos.eur(pr[j]), n(c.want), "de rosin " if ext else ""], 1600)
		visto_vender()
		heat_warn()
		await check_story()
		# en las esquinas de Darko (1.10), 1 de cada 3 ventas acaba con uno de sus chicos encima
		if c.get("map") == "astilleros" and Cultivo.azar() < 1.0 / 3:
			await say("Uno de los chicos de Darko te ha visto vender.")
			await say("«Te dijimos que lejos de nuestras esquinas.»", "CHICO DE DARKO")
			await battle("thief")
	else:
		S.rep = maxi(0, S.rep - 1)
		sfx("bad")
		remove_client(c.id)
		await say(pick(["¿Tanto? No.", "A ese precio, paso.", "Eso es demasiado. Adiós."]), N)

func heat_warn() -> void:
	if S.heat >= 70 and not S.flags.get("heatW"):
		S.flags.heatW = true
		toast("<small>CUIDADO</small>Mucha presión policial. Si llega a 90 habrá registro.", 3200)
	if S.heat < 60:
		S.flags.heatW = false

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
	return int(p[1 if is_night() else 0]) if p != null and S.ch >= 2 else 0

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
func talk_kiko():
	pass
func talk_josune():
	pass
func talk_baltasar():
	pass
func talk_patxi():
	pass
func talk_txaro():
	pass
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
func arcon_action():
	pass
func recibir_envio():
	pass
func notas_tia():
	pass
func pedir_caja():
	pass
func battle(_kind):
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
func letter_action():
	pass
func parada_action():
	pass
func title_press(_b):
	pass
