# Ribera Verde (Godot) — la historia 1 → 8 contra el HTML (godot/tests/historia.json, lo saca tools/test-historia.js con
# RV_ORACULO): los mismos 77 pasos que el test del HTML, con el mismo piloto (A cada 12 ms en los diálogos, opciones de menú
# por texto, «<B>» cierra el menú) y el mismo azar (Park-Miller). El reloj del juego y los paseos están parados: el bucle solo
# corre los eventos pendientes, como el update del oráculo. Tras cada paso compara la transcripción, S, el estado del azar,
# R, I, TO y dónde está cada cosa.
#   godot --headless --path godot --script res://tests/historia.gd [-- --oraculo f.json] [--salida dir]
#   → «historia: 77 pasos (77 OK) · semilla N · 0 diferencias con el HTML · T s»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Motor = preload("res://src/motor.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var D: Dictionary
var LOG: Array = []
var WANT: Array = []
var HOLD := false
var R = null
var I = null
var TO = null
var capta := false
var n_ok := 0
var difs: Array = []
var pasos: Array = []   # [{name, ok, detail}]
var O: Dictionary

func _initialize() -> void:
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

# Array.join(',') de JavaScript: null → '', números como en JS
func jn(a: Array) -> String:
	var o := []
	for x in a:
		o.append("" if x == null else ("true" if x else "false") if x is bool else Datos.js_num(x) if (x is int or x is float) else str(x))
	return ",".join(PackedStringArray(o))

# ---------- JSON como el de JavaScript (para R.antes, R.pot…) ----------
func jj(v) -> String:
	if v == null:
		return "null"
	if v is bool:
		return "true" if v else "false"
	if v is int or v is float:
		return Datos.js_num(v)
	if v is String or v is StringName:
		return JSON.stringify(str(v))
	if v is Array:
		var o := []
		for x in v:
			o.append(jj(x))
		return "[" + ",".join(o) + "]"
	if v is Dictionary:
		var o := []
		for k in v:
			o.append(JSON.stringify(str(k)) + ":" + jj(v[k]))
		return "{" + ",".join(o) + "}"
	return str(v)

# lo que JavaScript da por verdadero
func si(v) -> bool:
	if v == null:
		return false
	if v is bool:
		return v
	if v is int or v is float:
		return v != 0
	if v is String:
		return v != ""
	return true

# la comprobación de un paso: true si se cumple y, si no, lo que se informa (en GDScript «(cond) or R» da siempre un bool: true)
func chk(c, r):
	return true if si(c) else r

func re(p: String, s) -> bool:
	return s is String and RegEx.create_from_string(p).search(s) != null

# ---------- el piloto ----------
func _gancho_menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	if WANT.size() and WANT[0] is String and WANT[0] == "<B>":
		WANT.pop_front()
		HOLD = true
		M.timeout(func():
			J.press("B")
			HOLD = false, 5)
		LOG.append("  [menú] " + " | ".join(labels) + "  → (B)")
	else:
		if WANT.size() and WANT[0] is RegEx:
			for k in labels.size():
				if WANT[0].search(labels[k]) != null:
					WANT.pop_front()
					o = o.duplicate()
					o.initial = k
					break
		LOG.append("  [menú] " + " | ".join(labels) + "  → " + labels[int(o.get("initial", 0)) if o.get("initial") else 0])
	return o

# la caja de texto (1.11, window.pedirTexto del piloto): '=texto' lo escribe y acepta; '<B>' cancela; sin nada, acepta lo que había
func _gancho_pedir(t: String, ini: String, mx: int, cancela: bool):
	var v = ini
	if WANT.size() and WANT[0] is Dictionary:
		v = WANT.pop_front().txt.strip_edges().substr(0, mx)
	elif WANT.size() and WANT[0] is String and WANT[0] == "<B>" and cancela:
		WANT.pop_front()
		v = null
	LOG.append("  [texto] " + t + " → " + ("(B)" if v == null else "(texto largo)" if v.length() > 60 else v))   # la partida importada (1.22), sin copiarla
	return v

func _gancho_texto(t: String, n: String) -> void:
	LOG.append((n + ": " if n != "" else "") + J.nm(t))

func _gancho_toast(h: String, _ms) -> void:
	if capta:
		TO.append(h)

# hasta que se cumpla (el reloj del motor va de evento en evento; el piloto y el bucle siempre tienen algo pendiente)
func bombea(cond: Callable, limite := 900000.0) -> bool:
	var t0: float = M.reloj
	while not cond.call():
		if M.reloj - t0 > limite or not M.paso():
			return false
	return true

# idle(): cada 25 ms mira si el mundo está libre y sin eventos pendientes
func idle() -> void:
	var p := Motor.Prom.new()
	var h := {"iv": 0}
	h.iv = M.intervalo(func():
		if J.is_free() and J.pending.is_empty():
			M.quita(h.iv)
			p.res(), 25)
	await Motor.espera(p)

func hasta(f: Callable) -> void:
	var p := Motor.Prom.new()
	var h := {"iv": 0}
	h.iv = M.intervalo(func():
		if f.call():
			M.quita(h.iv)
			p.res(), 20)
	await Motor.espera(p)

func run(f: Callable) -> void:
	await J.run(f)

# window.want del piloto: lo que se elige en los menús que vienen ('<B>' sale; '=texto', en la caja de texto)
func want(w: Array) -> void:
	WANT = []
	for s in w:
		WANT.append(s if s == "<B>" else ({"txt": s.substr(1)} if s.begins_with("=") else RegEx.create_from_string(s)))

func step(nombre: String, w: Array, fn: Callable, check: Callable) -> void:
	want(w)
	var l0 := LOG.size()
	LOG.append("\n=== " + nombre + " ===")
	var st := {"fin": false}
	var co := func():
		await fn.call()
		await idle()
		st.fin = true
	co.call()
	var ok := bombea(func(): return st.fin)
	var detail := ""
	if ok:
		var r = check.call()
		ok = r is bool and r == true
		detail = "" if ok else jj(r)
	else:
		detail = "bloqueado (reloj %d, handlers %d, lock %d, pend %d, modo %s)" % [M.reloj, J.handlers.size(), J.lock, J.pending.size(), J.mode]
	pasos.append({"name": nombre, "ok": ok, "detail": detail})
	print("%s  %s%s" % ["OK   " if ok else "FALLO", nombre, "  → " + detail if detail != "" else ""])
	compara(pasos.size() - 1, LOG.slice(l0))

# ---------- comparar con el HTML ----------
func norm(v):
	return JSON.parse_string(JSON.stringify([v], "", false, true))[0]

func dif(ruta: String, a, b, out: Array) -> void:
	if (a is int or a is float) and (b is int or b is float):
		if absf(float(a) - float(b)) > 1e-9 * maxf(1.0, absf(float(b))):
			out.append("%s: godot %s ≠ html %s" % [ruta, jj(a), jj(b)])
	elif a is Dictionary and b is Dictionary:
		for k in b:
			if not a.has(k):
				if b[k] != null:
					out.append("%s.%s: falta en godot (html %s)" % [ruta, k, jj(b[k]).left(120)])
			else:
				dif(ruta + "." + str(k), a[k], b[k], out)
		for k in a:
			if not b.has(k) and a[k] != null:
				out.append("%s.%s: sobra en godot (%s)" % [ruta, k, jj(a[k]).left(120)])
	elif a is Array and b is Array:
		if a.size() != b.size():
			out.append("%s: godot %d elementos ≠ html %d · godot %s · html %s" % [ruta, a.size(), b.size(), jj(a).left(200), jj(b).left(200)])
		else:
			for i in a.size():
				dif(ruta + "[%d]" % i, a[i], b[i], out)
	elif not ((a == null and b == null) or (typeof(a) == typeof(b) and a == b)):
		out.append("%s: godot %s ≠ html %s" % [ruta, jj(a).left(160), jj(b).left(160)])

func compara(i: int, log: Array) -> void:
	if i >= O.pasos.size():
		difs.append("paso %d: no está en el oráculo" % i)
		return
	var o: Dictionary = O.pasos[i]
	var out := []
	if o.name != pasos[i].name:
		out.append("nombre: %s ≠ %s" % [pasos[i].name, o.name])
	if si(o.ok) != pasos[i].ok:
		out.append("ok: godot %s ≠ html %s" % [pasos[i].ok, o.ok])
	# la transcripción, línea a línea (la primera diferencia y el resto en una)
	var ol: Array = o.log
	for k in maxi(log.size(), ol.size()):
		var a = log[k] if k < log.size() else "(nada)"
		var b = ol[k] if k < ol.size() else "(nada)"
		if a != b:
			out.append("log[%d]:\n      godot %s\n      html  %s" % [k, a, b])
			if log.size() != ol.size():
				out.append("log: godot %d líneas ≠ html %d" % [log.size(), ol.size()])
			break
	dif("S", norm(J.S), o.get("S"), out)
	if int(o.pm) != Cultivo.pm:
		out.append("pm: godot %d ≠ html %d" % [Cultivo.pm, int(o.pm)])
	dif("R", norm(R), o.get("R"), out)
	dif("I", norm(I), o.get("I"), out)
	dif("TO", norm(TO), o.get("TO"), out)
	var ents := []
	for e in J.ents:
		ents.append([e.id, e.x, e.y, e.dir, e.wt])
	var ex := {"mode": J.mode, "map": J.S.map if J.S else null, "x": J.P.x, "y": J.P.y, "dir": J.P.dir, "ents": ents,
		"vc": {"ci": J.VC.ci, "sel": J.VC.sel, "ocupado": J.VC.ocupado} if J.VC else null, "h": J.handlers.size(), "lock": J.lock, "pend": J.pending.size()}
	dif("extra", norm(ex), o.extra, out)
	n_ok += 1
	if out.size():
		difs.append("paso %d «%s»:\n    %s" % [i, pasos[i].name, "\n    ".join(out.slice(0, 12)) + ("\n    … y %d más" % (out.size() - 12) if out.size() > 12 else "")])

# ---------- los pasos (los de tools/test-historia.js, en el mismo orden) ----------
func pr(l: String) -> int:
	for it in D.SHOP:
		if it.lbl.begins_with(l):
			return int(it.p)
	return -1

func _corre() -> void:
	var o = JSON.parse_string(FileAccess.get_file_as_string(arg("--oraculo", "res://tests/historia.json")))
	if not o is Dictionary:
		print("uso: … --script res://tests/historia.gd [-- --oraculo f.json] (falta el oráculo o no se lee)")
		quit(2)
		return
	O = o
	var sem := int(O.semilla)
	Juego.GUARDADO = "user://prueba-historia.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.GUARDADO))
	J = Juego.new()
	J.oraculo = true
	root.add_child(J)
	M = J.M
	D = J.D
	J.show_title()
	Cultivo.pm = sem
	J.gancho_menu = _gancho_menu
	J.gancho_texto = _gancho_texto
	J.gancho_toast = _gancho_toast
	J.gancho_pedir = _gancho_pedir
	M.intervalo(func():
		if not HOLD and J.handlers.size() and not (J.mode == "carpa" and J.VC and not J.VC.ocupado):
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var t0 := Time.get_ticks_msec()
	await _pasos()
	var sal := arg("--salida")
	if sal != "":
		DirAccess.make_dir_recursive_absolute(sal)
		var f := FileAccess.open(sal.path_join("transcripcion-godot.txt"), FileAccess.WRITE)
		f.store_string("\n".join(LOG) + "\n")
		f.close()
	var fallos := 0
	for p in pasos:
		if not p.ok:
			fallos += 1
	for d in difs:
		print(d)
	print("historia: %d pasos (%d OK) · semilla %d · %d diferencias con el HTML · %.1f s" % [pasos.size(), pasos.size() - fallos, sem, difs.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.GUARDADO))
	J.queue_free()
	quit(1 if fallos or difs.size() or pasos.size() != O.pasos.size() else 0)

func _pasos() -> void:
	var S = func(): return J.S
	# ---------- capítulo 1 ----------
	step("Nueva partida e intro (prólogo en Mendialde)", [], func(): await run(J.new_game),
		func(): return chk(J.S.ch == 1 and J.S.map == "casa-ama" and J.llegando() and J.S.name == "EDDIE" and "autobús" in J.objective_text(), {"ch": J.S.ch, "map": J.S.map, "name": J.S.name, "flags": J.S.flags}))
	step("Prólogo: la nota de ama y el táper de la nevera", [], func():
		await run(func(): await J.object_action(5, 4))
		await run(func(): await J.object_action(9, 6))
		await run(func(): await J.object_action(9, 6)),
		func(): return chk(si(J.S.flags.get("notaAma")) and si(J.S.flags.get("taper")) and J.S.items.bocata == 2, {"flags": J.S.flags, "items": J.S.items}))
	step("Prólogo: el autobús de Mendialde a Ribera Verde (billete de ama)", ["Ribera Verde"], func():
		await run(func(): await J.warp(J.MAPS["casa-ama"].exits["4,7"]))
		R = {"mapa": J.S.map, "x": J.P.x, "y": J.P.y, "m": J.S.money, "t": J.S.min}
		await run(J.parada_action),
		func(): return chk(R.mapa == "mendialde" and R.x == 6 and R.y == 12 and J.S.map == "town" and J.P.x == 7 and J.P.y == 12 and si(J.S.flags.get("llegada"))
			and J.S.money == R.m and J.S.min - R.t >= 40 and J.S.min - R.t < 46, {"R": R, "map": J.S.map, "x": J.P.x, "y": J.P.y, "m": J.S.money, "t": J.S.min}))
	step("Entrar en el piso de la tía", [], func(): await run(func(): await J.warp(J.MAPS.town.doors["5,8"])),
		func(): return chk(J.S.map == "home" and J.objective_text() == "Lee la carta que hay en la mesa.", {"map": J.S.map, "obj": J.objective_text()}))
	step("Leer la carta de la tía", [], func(): await run(func(): await J.object_action(3, 5)),
		func(): return J.S.flags.get("letter") == true)
	step("Kiko regala semillas y abono", [], func(): await run(J.talk_kiko),
		func(): return chk(J.S.seeds.get("ria") == 3 and J.S.items.fert == 2 and si(J.S.flags.get("kiko1")), {"seeds": J.S.seeds, "items": J.S.items}))
	step("Plantar dos Skunk #1 y abonar una", ["Skunk", "Skunk", "Abonar"], func():
		await run(func(): await J.pot_action(0))
		await run(func(): await J.pot_action(1))
		await run(func(): await J.pot_action(1)),
		func(): return chk(J.S.pots[0] != null and J.S.pots[0].sid == "ria" and J.S.pots[1] != null and J.S.pots[1].fert == true and J.S.items.fert == 1, {"pots": J.S.pots}))
	step("Cuidar 3 días y cosechar → capítulo 2", ["Cosechar", "Cosechar"], func():
		for i in 9:
			for p in J.S.pots:
				if p:
					p.water = 100
					p.pest = false
			J.advance_time(8 * 60)
		await idle()
		await run(func(): await J.pot_action(0))
		await run(func(): await J.pot_action(1)),
		func(): return chk(J.S.ch == 2 and J.S.buds.has("ria") and J.S.buds.ria.g > 30 and J.S.seeds.get("ria", 0) >= 1 and J.S.clients.size() > 0, {"ch": J.S.ch, "buds": J.S.buds, "clients": J.S.clients.size()}))

	# ---------- capítulo 2 ----------
	step("Vender a un cliente (rebaja) → 300 € → capítulo 3; el plazo de 3.000 € corre desde que aparece Toño", ["Skunk", "Rebaja"], func():
		J.S.sales = int(D.META_VENTAS) - 1
		await run(func(): await J.talk_client(J.S.clients[0])),
		func(): return chk(J.S.ch == 3 and J.S.sales >= D.META_VENTAS and J.S.heat > 0 and J.S.due == 3000 and J.S.deadline == J.S.day + 7 and J.S.flags.get("tono") == J.S.day
			and not si(J.S.flags.get("metB")), {"ch": J.S.ch, "sales": J.S.sales, "due": J.S.due, "deadline": J.S.deadline}))
	step("Hablar con Josune (pintxo)", ["Pintxo"], func():
		J.S.hp = 10
		await run(J.talk_josune),
		func(): return chk(J.S.hp == 22, {"hp": J.S.hp}))
	step("Abuela Txaro: dar 5 g → Hindu Kush", ["Skunk"], func(): await run(J.talk_txaro),
		func(): return chk(si(J.S.flags.get("txaro")) and J.S.seeds.get("hindu") == 2, {"seeds": J.S.seeds}))
	step("Iñaki: vender 10 g → Malawi Gold", ["Skunk", "Hecho"], func():
		J.add_buds("ria", 10, 12)
		await run(J.talk_inaki),
		func(): return chk(si(J.S.flags.get("inaki")) and J.S.seeds.get("malawi") == 2, {"seeds": J.S.seeds}))
	step("Iñaki al por mayor: 250 g de Skunk #1 a 3,20 €/g; una carga al día", ["Venta al por mayor", "Skunk", "^250 g", "Venta al por mayor"], func():
		J.S.buds = {}
		J.add_buds("ria", 300, 12)
		R = {"m": J.S.money, "g": J.S.buds.ria.g}
		await run(J.talk_inaki)
		R.m1 = J.S.money
		R.g1 = J.S.buds.ria.g
		await run(J.talk_inaki),
		func(): return chk(R.m1 == R.m + 800 and R.g1 == R.g - 250 and J.S.mDay == J.S.day and J.S.money == R.m1 and absf(J.precio_mayor(12) - 3.2) < 1e-9, R))
	step("Arbusto escondido → Acapulco Gold", [], func():
		J.S.map = "town"
		await run(func(): await J.object_action(2, 26))
		J.S.map = "home",
		func(): return chk(J.S.seeds.get("acapulco") == 2, {"seeds": J.S.seeds}))
	step("Autobús de pago: de Ribera Verde a Puerto Viejo (2 €, 25 min) y de allí a Valdehierro (4 €, 45 min)", ["Puerto Viejo", "Valdehierro"], func():
		J.enter_map("town", 7, 12, "up")
		J.S.min = 10 * 60
		R = {"m": J.S.money}
		await run(J.parada_action)
		R.mapa = J.S.map
		R.x = J.P.x
		R.y = J.P.y
		R.m1 = J.S.money
		R.t1 = J.S.min
		await run(J.parada_action),
		func(): return chk(R.mapa == "puerto" and R.x == 20 and R.y == 9 and R.m1 == R.m - 2 and R.t1 >= 625 and R.t1 < 631 and J.S.map == "valdehierro" and J.P.x == 15
			and J.P.y == 11 and J.S.money == R.m - 6 and J.S.min - R.t1 >= 45 and J.S.min - R.t1 < 51 and J.ents.any(func(e): return e.id == "obrero"), {"R": R, "map": J.S.map, "m": J.S.money, "t": J.S.min}))
	step("Autobús de vuelta a Ribera Verde (2 €) y a casa", ["Ribera Verde"], func():
		R.m2 = J.S.money
		await run(J.parada_action)
		R.mapa2 = J.S.map
		J.enter_map("home", 2, 4, "down"),
		func(): return chk(J.S.money == R.m2 - 2 and R.mapa2 == "town" and J.S.map == "home", {"R": R, "m": J.S.money, "map": J.S.map}))

	# ---------- capítulo 3 ----------
	step("Don Baltasar explica la deuda", [], func(): await run(J.talk_baltasar),
		func(): return chk(si(J.S.flags.get("metB")) and J.S.due == 3000 and J.S.debt == 30000 and J.S.deadline == J.S.flags.tono + 7, {"due": J.S.due, "deadline": J.S.deadline, "day": J.S.day}))
	# 1.11: a 3 días del plazo, Toño avisa con lo que llevas (recuerdo_plazo)
	step("Plazo: a 3 días, el SMS de Toño con lo que llevas; vencido → Toño cobra intereses (1.er plazo vencido)", [], func():
		# (el aviso, sin cambiar de día: new_day lo encola con S.deadline − S.day = 3 o 0)
		var l0 := LOG.size()
		J.S.deadline = J.S.day + 3
		await run(J.recuerdo_plazo)
		J.S.deadline = J.S.day
		await run(J.recuerdo_plazo)
		R = {"av": LOG.slice(l0), "ll": J.S.money + J.caja_e(), "d": J.S.day}
		J.advance_time(24 * 60)
		await idle(),
		func(): return chk(J.S.due == 3600 and J.S.debt == 30600 and J.S.deadline == J.S.day + 5 and J.S.vencidos == 1
			and R.av.has("SMS · TOÑO: Don Baltasar quiere %s antes de que acabe el día %d. Te quedan 3 días." % [Datos.eur(3000), R.d + 3])
			and R.av.has("SMS · TOÑO: Hoy es el último día para los %s de Don Baltasar." % Datos.eur(3000))
			and R.av.filter(func(l): return l.begins_with("Llevas %s entre el bolsillo y la caja" % Datos.eur(R.ll))).size() == 2, {"due": J.S.due, "debt": J.S.debt, "vencidos": J.S.vencidos, "R": R}))
	step("Pagar 3.600 € → capítulo 4", ["^Pagar"], func():
		J.S.money = 6000
		await run(J.talk_baltasar),
		func(): return chk(J.S.ch == 4 and J.S.debt == 27000 and J.S.due == 0, {"ch": J.S.ch, "debt": J.S.debt}))

	# ---------- capítulo 4 ----------
	step("Kiko instala la mesa de genética", [], func(): await run(J.talk_kiko),
		func(): return chk(si(J.S.flags.get("lab")) and J.S.seeds.get("rif") == 3, {"lab": J.S.flags.get("lab"), "seeds": J.S.seeds}))
	step("Comprar en el growshop: un bote de abono (4 dosis) y un sobre de 10 Skunk #1", ["Abono", "Semillas Skunk", "Sobre de 10", "Salir"], func():
		R = {"m": J.S.money, "s": J.S.seeds.get("ria", 0), "f": J.S.items.fert}
		await run(J.shop),
		func(): return chk(J.S.items.fert == R.f + 4 and J.S.seeds.ria == R.s + 10 and J.S.money == R.m - 14 - 43, {"items": J.S.items, "R": R, "money": J.S.money, "seeds": J.S.seeds.get("ria")}))
	step("Growshop: carpa de 100, foco LED 200 W colgado en el armario y una maceta de tela", ["Carpa 100", "Foco LED 200", "^Armario", "Maceta de tela 11", "Salir"], func():
		J.S.money = 2000
		await run(J.shop),
		func(): return chk(J.S.carpas.size() > 1 and J.S.carpas[1] and J.S.carpas[1].t == "m100" and J.S.carpas[0].foco == "led200" and J.S.items.get("f_cfl") == 1 and J.S.items.get("m_tela11") == 1
			and J.S.pots.size() == 6 and J.S.macetas.size() == 6 and J.S.money == 2000 - 120 - 220 - 3 and pr("Carpa 100") == 120, {"carpas": J.S.carpas, "items": J.S.items, "pots": J.S.pots.size(), "money": J.S.money}))
	step("Plaza vacía: cambiar la maceta de 7 L por la de tela", ["Cambiar maceta", "Tela 11"], func(): await run(func(): await J.pot_action(2)),
		func(): return chk(J.S.macetas[2] == "tela11" and J.S.items.m_tela11 == 0 and J.S.items.get("m_plastico7") == 1, {"macetas": J.S.macetas, "items": J.S.items}))
	step("Carpa: cambiar el foco desde la pared (sodio 400 W)", ["Cambiar foco", "Sodio 400"], func():
		J.S.items.f_sodio400 = 1
		await run(func(): await J.carpa_action(1)),
		func(): return chk(J.S.carpas[1].foco == "sodio400" and J.S.items.f_cfl == 2 and J.S.items.f_sodio400 == 0, {"carpas": J.S.carpas, "items": J.S.items}))
	step("Factura de la luz: solo paga la carpa con plantas (sodio 400 W: 157 kWh a 0,16 € = 25 €)", [], func():
		J.S.money = 100
		J.S.pots[2] = {"sid": "ria", "prog": .2, "water": 100, "health": 100, "fert": false, "pest": false}
		J.advance_time(24 * 60)
		await idle()
		J.S.pots[2] = null,
		func(): return chk(J.S.luz.e == 25 and J.S.money == 75 and J.kwh_foco("sodio400") == 157, {"luz": J.S.luz, "money": J.S.money}))
	step("Vista de carpa: A delante del armario, ▶ plaza 2, A → Regar, B sale", ["Regar"], func():
		J.S.pots[1] = {"sid": "ria", "prog": .5, "water": 20, "health": 100, "fert": false, "pest": false}
		var t = null
		for c in J.MAPS.home.carpas:
			if c.ci == 0:
				t = c
				break
		J.enter_map("home", t.x0, t.y + 1, "up")
		J.press("A")
		await hasta(func(): return J.mode == "carpa" and J.handlers.size() == 1)
		var x0 := []
		for q in J.vc_geo(0).pl:
			x0.append(q.x)
		R = {"sel0": J.VC.sel, "x0": x0}
		J.press("right")
		R.sel = J.VC.sel
		R.info = J.vc_texto
		J.press("A")
		await hasta(func(): return J.VC and not J.VC.ocupado and J.handlers.size() == 1)
		R.agua = J.S.pots[1].water
		J.press("B")
		await hasta(func(): return J.mode == "world" and J.is_free()),
		func(): return chk(R.sel0 == 0 and R.sel == 1 and re("Plaza 2", R.info) and R.agua == 100 and J.VC == null, R))
	step("Growshop: armario 80 en el sitio A; cada planta se queda en su carpa y su plaza", ["Armario 80", "Salir"], func():
		J.S.money = 1000
		J.S.pots[3] = {"sid": "txoko", "prog": .3, "water": 90, "health": 100, "fert": false, "pest": false}
		var antes := []
		for p in J.S.pots:
			antes.append(jj(p))
		R = {"antes": antes, "mac": J.S.macetas.duplicate()}
		await run(J.shop)
		J.enter_map("home", 5, 5, "up")
		var g: Array = J.vc_geo(0).pl
		var fl := []
		for q in g:
			fl.append(Datos.js_num(q.fila))
		R.filas = ",".join(fl)
		R.atras = g[2].x > g[0].x and g[2].x < g[1].x
		R.movida = jj(J.S.pots[4])
		J.S.pots[4] = null,
		func(): return chk(J.S.carpas[0].t == "p80" and J.S.carpas[0].foco == "led200" and J.S.money == 1000 - 90 and J.S.pots.size() == 7 and R.filas == "0,0,1" and R.atras
			and jj(J.S.pots[0]) == R.antes[0] and jj(J.S.pots[1]) == R.antes[1] and R.antes[3] != "null" and R.movida == R.antes[3] and J.S.pots[3] == null and J.S.macetas[2] == "plastico7"
			and J.S.macetas[3] == R.mac[2] and J.MAPS.home.carpas.size() == 2, {"carpas": J.S.carpas, "money": J.S.money, "R": R, "macetas": J.S.macetas}))
	step("Extras: ventilador, filtro y garrafas en la carpa de 100 (las garrafas riegan); sin filtro, el olor de la floración sube el calor", ["Ventilador", "^Carpa 100", "Extractor 125", "^Carpa 100", "Garrafas", "^Carpa 100", "Salir", "Poner extractor 125"], func():
		J.S.money = 1000
		await run(J.shop)
		var flor := func(): return {"sid": "ria", "prog": .8, "water": 100, "health": 100, "fert": false, "pest": false}
		R = {"money": J.S.money, "f": J.factores(4), "m": D.MACETAS[J.S.macetas[4]], "F": D.FOCOS[J.S.carpas[1].foco]}
		J.S.protect = false
		J.S.pots[0] = flor.call()
		J.S.pots[4] = flor.call()
		J.S.heat = 30
		J.advance_time(24 * 60)
		await idle()
		R.h1 = J.S.heat
		J.S.items.x_filtro = 1
		await run(func(): await J.carpa_action(0))
		J.advance_time(24 * 60)
		await idle()
		R.h2 = J.S.heat
		J.S.pots[0] = null
		J.S.pots[4] = null,
		func(): return chk(si(J.S.carpas[1].get("vent")) and si(J.S.carpas[1].get("filtro")) and si(J.S.carpas[1].get("garrafas")) and R.money == 1000 - 20 - 110 - 15
			and absf(R.f.plaga - R.m.plaga * .7) < 1e-9 and absf(R.f.agua - R.F.agua * R.m.agua) < 1e-9 and Cultivo.garrafas_carpa(J.S, 1)[0] < Cultivo.garrafas_carpa(J.S, 1)[1] and R.h1 == 30 - 12 + 2 and R.h2 == R.h1 - 12
			and si(J.S.carpas[0].get("filtro")) and not J.S.items.get("x_filtro"), {"carpas": J.S.carpas, "R": R, "items": J.S.items}))
	step("Cruce de receta: Afghani × Skunk #1 → Critical Mass (de receta, sacada en la mesa: falta cosecharla)", ["^Afghani", "^Skunk #1", "Cruzar"], func():
		J.add_seeds("ria", 2)
		J.add_seeds("txoko", 2)
		await run(J.lab_action),
		func(): return chk(J.S.seeds.get("kushrif") == 2 and si(J.S.disc.get("kushrif")) and J.S.gen.get("kushrif") == 1 and J.S.rec.get("kushrif") == 1 and J.rec_count() == 0, {"seeds": J.S.seeds, "gen": J.S.gen, "rec": J.S.rec}))
	step("Cruce libre: Skunk #1 × Hindu Kush → híbrido propio (m % de la madre, el resto del padre); 8 variedades ya no pasan de capítulo", ["^Skunk #1", "^Hindu Kush", "Cruzar"], func():
		await run(J.lab_action)
		var k = J.S.custom.keys()[0] if J.S.custom.size() else null
		R = {"k": k, "c": J.S.custom.get(k) if k else null, "linea": J.strain_line(k).split("\n")[1] if k else null},
		func():
			var c = R.c
			if c == null:
				return R
			var m: int = int(c.m)
			var STR: Dictionary = D.STRAINS
			return chk(J.S.custom.size() == 1 and J.disc_count() >= 8 and J.S.ch == 4 and J.S.due == 0 and not J.S.rec.has(R.k) and re("\\(0/2\\)", J.objective_text()) and c.ma == "ria" and c.pa == "hindu" and m >= 30 and m <= 70
				and c.ind == Datos.jsround((m * 65 + (100 - m) * 100) / 100.0) and c.hj == Datos.mix(STR.hindu.hj, STR.ria.hj, m / 100.0) and c.c == Datos.mix(STR.hindu.c, STR.ria.c, m / 100.0)
				and R.linea == "Índica %d %% · sativa %d %% · %d %% madre · %d %% padre" % [c.ind, 100 - c.ind, m, 100 - m], {"custom": J.S.custom, "disc": J.disc_count(), "ch": J.S.ch, "R": R}))

	step("Estabilizar Critical Mass: F1 → F2 → F3 → estable", ["^Critical Mass", "estabilizar", "Estabilizar", "^Critical Mass", "estabilizar", "Estabilizar", "^Critical Mass", "estabilizar", "Estabilizar"], func():
		R = []
		for k in 3:
			if k:
				J.add_seeds("kushrif", 1)
			await run(J.lab_action)
			R.append("%d:%s" % [Cultivo.gen_de(J.S, "kushrif"), Datos.js_num(J.S.seeds.kushrif)]),
		func(): return chk(",".join(R) == "2:1,3:1,4:1" and not J.S.gen.has("kushrif"), {"R": R, "gen": J.S.gen, "seeds": J.S.seeds.get("kushrif")}))
	step("Banco de semillas del PC: Punto Rojo y Thai, llegan al día siguiente", ["Banco de semillas", "^Punto Rojo", "^Thai", "Salir"], func():
		J.S.money = 500
		await run(J.pc_action)
		R = {"pedido": J.S.pedido.duplicate(), "money": J.S.money, "antes": si(J.S.seeds.get("thai"))}
		J.new_day(),
		func(): return chk(",".join(R.pedido) == "punto,thai" and R.money == 500 - 30 - 30 and not R.antes and J.S.seeds.get("punto") == 10 and J.S.seeds.get("thai") == 10
			and si(J.S.disc.get("thai")) and J.S.pedido.is_empty(), {"R": R, "seeds": J.S.seeds, "pedido": J.S.pedido}))
	step("Cruce de landraces: Punto Rojo × Thai → Haze (F1: cada planta con su fenotipo; la línea da semillas)", ["^Punto Rojo", "^Thai", "Cruzar"], func():
		await run(J.lab_action)
		R = []
		var haze := func() -> float:
			var t := 0.0
			for k in J.S.buds:
				if J.lot_sid(k) == "haze":
					t += J.S.buds[k].g
			return t
		for k in 12:
			J.S.pots[0] = {"sid": "haze", "prog": 1, "water": 80, "health": 100, "fert": false, "pest": false, "f": J.roll_feno("haze")}
			var e: int = J.gramos_planta(J.S.pots[0], J.factores(0))
			var y = J.S.pots[0].f.y
			var b: float = haze.call()
			var sd: int = J.S.seeds.get("haze", 0)
			await run(func(): await J.harvest(0))
			R.append({"g": haze.call() - b, "e": e, "y": y, "sd": J.S.seeds.haze - sd}),
		func():
			var gs := {}
			var bien := true
			for r in R:
				gs[r.g] = true
				bien = bien and r.g == r.e and r.sd >= 2 and r.sd <= 5
			return chk(si(J.S.disc.get("haze")) and J.S.gen.get("haze") == 1 and gs.size() > 2 and bien and re("F1: línea inestable", J.strain_line("haze"))
				and Cultivo.tipo_gen(J.S, "haze") == "F1" and J.S.rec.get("haze") == 2 and J.rec_count() == 1 and J.S.ch == 4, {"R": R, "gen": J.S.gen.get("haze"), "rec": J.S.rec, "ch": J.S.ch}))
	step("Cosechar una Critical Mass, la 2.ª de receta sacada en la mesa → capítulo 5", [], func():
		J.S.pots[0] = {"sid": "kushrif", "prog": 1, "water": 80, "health": 100, "fert": false, "pest": false, "f": J.roll_feno("kushrif")}
		await run(func(): await J.harvest(0)),
		func():
			var sv = J.load_save()
			return chk(J.S.rec.get("kushrif") == 2 and J.rec_count() == 2 and J.S.ch == 5 and J.S.due == 12000 and sv and sv.due == 12000, {"rec": J.S.rec, "ch": J.S.ch, "due": J.S.due}))

	# ---------- capítulo 5 ----------
	step("Growshop: carpa 120 en el sitio C, junto a la cama (6 plazas más)", ["Carpa 120", "Salir"], func():
		J.S.money = 1000
		await run(J.shop)
		J.enter_map("home", 5, 5, "up"),
		func():
			var hay := false
			for t in J.MAPS.home.carpas:
				hay = hay or (t.ci == 2 and t.x0 == 2 and t.x1 == 3)
			return chk(J.S.carpas.size() > 2 and J.S.carpas[2] and J.S.carpas[2].t == "m120" and J.S.carpas[2].foco == "cfl" and J.huecos().size() == 13 and J.S.pots.size() == 13
				and J.S.macetas.size() == 13 and J.S.money == 1000 - 150 and hay and J.tile_solid(J.MAPS.home, 2, 2) and J.tile_solid(J.MAPS.home, 3, 2), {"carpas": J.S.carpas, "money": J.S.money, "n": J.huecos().size(), "mapa": J.MAPS.home.carpas}))
	step("Sargento Molina: pagar protección (1.500 € cada 10 días)", ["^Pagar"], func():
		J.S.money = 1600
		await run(J.talk_molina),
		func(): return chk(J.S.protect == true and J.S.money == 100 and J.S.protHasta == J.S.day + 10 and si(J.S.flags.get("molina1")), {"protect": J.S.protect, "money": J.S.money, "hasta": J.S.protHasta}))
	step("Calor 95 con protección → Molina para la redada", ["Skunk"], func():
		J.add_seeds("ria", 1)
		await run(func(): await J.pot_action(0))
		J.S.heat = 95
		J.advance_time(24 * 60)
		await idle(),
		func(): return chk(J.S.heat == 50 and J.S.pots[0] != null, {"heat": J.S.heat, "pot": J.S.pots[0]}))
	step("Calor 95 sin protección → orden de registro: Kiko avisa, el calor no baja y la redada es al día siguiente (las plantas y el equipo de su carpa, la multa por lo hallado; las semillas se quedan)", [], func():
		J.S.protect = false
		J.S.heat = 95
		J.add_buds("ria", 10, 12)
		J.S.carpas[0].vent = true
		var l0 := LOG.size()
		J.advance_time(24 * 60)
		await idle()
		for p in J.S.pots:   # vivas: la redada se lleva el equipo de las carpas con plantas vivas
			if p:
				p.erase("dead")
				p.health = 100
				p.water = 100
		var npot := 0
		var nviva := 0
		for p in J.S.pots:
			if p:
				npot += 1
				if not p.get("dead"):
					nviva += 1
		R = {"orden": J.S.orden == J.S.day, "heat": J.S.heat, "nivel": J.nivel_poli(), "aviso": LOG.slice(l0).any(func(l): return re("mañana entran en tu piso con orden de registro", l)), "pots": npot}
		R.hud = float(J.S.get("orden", 0)) > 0   # la etiqueta ORDEN del HUD (ui.gd hud_pon) sale de S.orden
		R.np = nviva
		R.sd = jj(J.S.seeds)
		J.S.money = 5000
		R.multa = J.multa_redada(nviva, int(floor(J.total_buds() + J.arcon_g())) + Datos.jsround((J.total_rosin() + J.arcon_r()) / D.ROSIN.rend))
		var l1 := LOG.size()
		J.advance_time(24 * 60)
		await idle()
		R.log = "|".join(LOG.slice(l1))
		R.m = J.S.money,
		func(): return chk(R.orden and R.heat == 95 and R.nivel == 3 and R.aviso and R.pots > 0 and R.hud and J.S.pots.all(func(p): return p == null) and J.S.buds.is_empty() and J.S.heat == D.CALOR_REDADA
			and not J.S.get("orden") and not J.S.carpas[0].get("vent") and R.multa > 601 and R.m == 5000 - R.multa - J.S.luz.e and re("equipo de las carpas con plantas: ventilador", R.log) and jj(J.S.seeds) == R.sd, {"R": R, "pots": J.S.pots, "buds": J.S.buds, "heat": J.S.heat}))
	step("Pagar 12.000 € → capítulo 6", ["^Pagar"], func():
		J.S.protect = true
		J.S.money = 12500
		await run(J.talk_baltasar),
		func(): return chk(J.S.ch == 6 and J.S.debt == 15000 and J.S.money == 500, {"ch": J.S.ch, "debt": J.S.debt}))

	# ---------- capítulo 6 ----------
	step("Darko presume", [], func(): await run(J.talk_darko), func(): return J.S.ch == 6)
	step("Copa: presentar Skunk #1 (12%) → pierde", ["Skunk"], func():
		J.add_buds("ria", 25, 12)
		await run(J.talk_jurado),
		func(): return chk(J.S.ch == 6 and Datos.jsround(J.S.buds.ria.g) == 5, {"ch": J.S.ch, "buds": J.S.buds}))
	step("Copa: presentar Sour Diesel (27,2%) → gana → capítulo 7", ["Sour Diesel"], func():
		J.S.money = 0
		J.add_buds("dragon", 25, 27.2)
		await run(J.talk_jurado),
		func():
			var sv = J.load_save()
			return chk(J.S.ch == 7 and J.S.money == 5000 and J.S.due == 15000 and si(J.S.flags.get("copa")) and sv and sv.due == 15000, {"ch": J.S.ch, "money": J.S.money, "due": J.S.due, "guardado": sv.due if sv else null}))

	# ---------- capítulo 7 → final ----------
	step("Pagar los últimos 15.000 € → deuda saldada: empieza tu imperio (capítulo 8, con su rótulo)", ["^Pagar"], func():
		J.S.money += 10000
		TO = []
		capta = true
		await run(J.talk_baltasar)
		capta = false,
		func(): return chk(TO.any(func(h): return re("CAPÍTULO 8.*Tu imperio", h)) and J.S.ch == 8 and J.S.debt == 0 and J.S.imp0 == J.S.sales and J.imperio_nivel() == 0
			and J.mayor_dia() == 1000 and re("^Tu imperio · Cultivador", J.objective_text()) and not J.endcard_on, {"ch": J.S.ch, "debt": J.S.debt, "o": J.objective_text()}))
	step("Imperio: 25.000 € facturados → Proveedor del barrio; Iñaki carga 2 kg al día", [], func():
		J.S.sales += 25000
		await run(J.check_story),
		func(): return chk(J.S.impN == 1 and J.mayor_dia() == 2000 and re("Proveedor del barrio", J.objective_text()), {"impN": J.S.impN, "o": J.objective_text()}))

	# ---------- sistemas sueltos ----------
	var spray := []
	for k in 20:
		spray.append_array(["MOCHILA", "SPRAY"])
	step("Combate ladrón: ganar con spray", spray.slice(0, 24), func():
		var pv: Dictionary = J.S.pelea.duplicate()
		J.S.hpMax = 60
		J.S.hp = 60
		J.S.items.spray = 12
		J.S.money = 100
		await run(func(): await J.battle("thief"))
		WANT = []
		J.S.pelea = pv,
		func(): return chk(J.S.money > 100 and J.S.hpMax == 60 and J.mode == "world", {"money": J.S.money, "hpMax": J.S.hpMax, "mode": J.mode}))
	step("Combate ladrón: desmayo → despiertas en casa (se lleva la mitad de la flor y del rosin y el 30 % del dinero, y lo dice)", [], func():
		J.S.hpMax = 30
		J.S.hp = 1
		J.S.money = 1000
		J.S.buds = {}
		J.add_buds("ria", 20, 12)
		J.S.rosin = {"ria": {"g": 3, "thc": 36}}
		J.S.map = "town"
		await run(func(): await J.battle("thief")),
		func(): return chk(J.S.map == "home" and J.S.hp == J.S.hpMax and J.S.money == 700 and J.S.buds.ria.g == 10 and J.S.rosin.ria.g == 1.5
			and LOG.any(func(l): return "Te roba 10 g, 1,5 g de rosin y 300 €" in l), {"map": J.S.map, "hp": J.S.hp, "money": J.S.money, "buds": J.S.buds, "rosin": J.S.rosin}))
	step("Ladrón vencido sube la VIDA máxima", ["LUCHAR", "PATADA"] + spray, func():
		var pv: Dictionary = J.S.pelea.duplicate()
		J.S.hpMax = 40
		J.S.hp = 40
		J.S.items.spray = 20
		await run(func(): await J.battle("thief"))
		WANT = []
		J.S.pelea = pv,
		func(): return chk(J.S.hpMax == 42, {"hpMax": J.S.hpMax}))
	step("Policía: soborno con protección (40 + 4 × calor + 0,5 × gramos + 5 % del dinero encima)", ["SOBORNAR", "^Sí"], func():
		J.S.protect = true
		J.S.rosin = {}
		J.S.heat = 40
		J.S.money = 1000
		J.add_buds("ria", 10, 12)
		R = {"p": J.precio_soborno(), "g": J.total_buds()}
		await run(func(): await J.battle("police")),
		func(): return chk(R.p == Datos.jsround(40 + 160 + R.g * .5 + 50) and J.S.money == 1000 - R.p and J.S.heat == 30 and J.S.buds.has("ria"), {"money": J.S.money, "heat": J.S.heat, "R": R}))
	step("Agente en la plaza: entregar la mercancía", ["ENTREGAR"], func():
		J.S.protect = false
		J.add_buds("ria", 5, 12)
		await run(J.talk_cop),
		func(): return chk(J.S.buds.is_empty(), {"buds": J.S.buds}))
	step("Menú START: Genoteca, Mochila, Plantas, Objetivo", ["GENOTECA", "<B>", "MOCHILA", "<B>", "PLANTAS", "<B>", "OBJETIVO", "<B>", "SALIR"], func(): await run(J.start_menu),
		func(): return chk(J.handlers.is_empty() and LOG.any(func(l): return l.begins_with("  [menú] CAPÍTULO %d | %s | LOGROS | DEUDA | Volver" % [J.S.ch, " | ".join(PackedStringArray(J.D.MISIONES.map(func(m): return m.t)))])), LOG.slice(-4)))
	step("Cama: siesta de 3 horas", ["Siesta"], func():
		J.S.min = 600
		J.S.hp = 5
		await run(J.bed_action),
		func(): return chk((J.S.min == 780 or J.S.min == 781) and J.S.hp == J.S.hpMax, {"min": J.S.min, "hp": J.S.hp}))
	step("Fenotipos: 200.000 plantas por tipo → 1 estrella de cada N (GENETICA[t].uno); de menos a más variable; % índica de cada planta", [], func():
		R = {}
		for t in D.GENETICA:
			var n := 0
			var fl := 0
			var sg: float = D.GENETICA[t].sigma
			for k in 200000:
				var cl := Cultivo.clase_feno(J.tira_feno(sg))
				if cl == "estrella":
					n += 1
				elif cl == "floja":
					fl += 1
			R[t] = {"n": n, "fl": fl, "E": 200000.0 / D.GENETICA[t].uno}
		var n0 = J.S.fenoN
		var ria := {}
		var np := []
		for k in 5000:
			ria[J.roll_feno("ria").i] = true
			np.append(J.roll_feno("nepal").i)
		J.S.fenoN = n0
		var m := 0.0
		for x in np:
			m += x
		m /= np.size()
		var v := 0.0
		for x in np:
			v += (x - m) ** 2
		var rs := []
		for x in ria:
			rs.append(Datos.js_num(x))
		I = {"ria": ",".join(rs), "media": float(Datos.to_fixed(m, 1)), "sd": float(Datos.to_fixed(sqrt(v / np.size()), 1))},
		func():
			var bien := true
			for t in R:
				bien = bien and absf(R[t].n - R[t].E) <= 4 * sqrt(R[t].E) + 3 + .1 * R[t].E
			var ord := ["estable", "f1", "F1", "landrace", "poli", "F2"]
			for i in range(1, ord.size()):
				bien = bien and R[ord[i]].n > R[ord[i - 1]].n
			return chk(bien and I.ria == "65" and absf(I.media - 50) < 1 and absf(I.sd - D.GENETICA.landrace.si) < 1 and Cultivo.tipo_gen(J.S, "ria") == "estable"
				and Cultivo.tipo_gen(J.S, "txoko") == "f1" and Cultivo.tipo_gen(J.S, "limon") == "poli" and Cultivo.tipo_gen(J.S, "thai") == "landrace"
				and re("Cruce F1: [^\\n]*\\n2\\.ª generación · Skunk #1 × Afghani$", J.strain_line("txoko")) and re("origen incierto", J.strain_line("mango")), {"R": R, "I": I}))
	step("Árbol por generaciones (1.11; 1.24, hasta la 4.ª; 1.26, más cruces clásicos): las 53 de la tabla con su generación y ✔/≈; todas salen en la mesa desde landraces y tienda; sin criadores", [], func():
		var T := {1: "Skunk #1 ✔|Haze ≈|Northern Lights ≈|Purple Thai ✔|Trainwreck ≈|AK-47 ✔|Laughing Buddha ✔|Cannalope Haze ✔|Master Kush ≈|Purple Kush ≈|Congo × Panama ✔|Malawi × Panama ✔|Malawi × PCK ✔|Kali Mist ≈|White Widow ≈",
			2: "Blueberry ✔|Super Skunk ✔|Shiva Skunk ✔|Critical Mass ✔|Cheese ✔|NL5 × Haze ✔|Neville's Haze ✔|Silver Haze ≈|Chocolope ✔|Pineapple Express ≈|Tangie ✔|Amnesia Haze ≈|Purple Haze ≈|White Russian ✔|Chronic ✔|White Rhino ≈",
			3: "Jack Herer ✔|Super Silver Haze ✔|Blue Dream ✔|Blue Cheese ✔|Lemon Haze ≈|Sour Diesel ≈|Kali 47 ✔|Critical Kali Mist ✔|Big Bud ≈|Blue Widow ✔|White Shark ✔|Hawaiian Snow ✔|Ice ✔|Critical 47 ≈|Critical Cheese ≈|Northern Light Blue ✔",
			4: "Super Lemon Haze ✔|Jack Flash ✔|Jack 47 ✔|Sour Tangie ✔|NL × Big Bud ✔|Critical Jack ≈"}
		var tabla := true
		for g in [1, 2, 3, 4]:
			var l := []
			for k in D.DEX:
				if D.STRAINS[k].get("gen") == g:
					l.append(D.STRAINS[k].n + (" ≈" if re("origen incierto", D.STRAINS[k].o) else " ✔"))
			l.sort()
			var e := Array(T[g].split("|"))
			e.sort()
			tabla = tabla and "|".join(l) == "|".join(e)
		R = {"tabla": tabla}
		var sale: Array = D.RECIPES.values() + D.RECETA_ORD.values()
		var RS := []
		for k in D.RECIPES:
			RS.append(Array(k.split("+")))
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.custom = {}
		var ids := []
		for k in D.DEX:
			if not sale.has(k):
				ids.append(k)
		var vistas := ids.duplicate()
		var via := {}
		var cambia := true
		while cambia:
			cambia = false
			var L := ids.duplicate()
			for a in L:
				for b in L:
					if a == b:
						continue
					var h: Array = Datos.hojas_cruce(J.S, a, b)
					var sub := false
					for r in RS:
						if r.size() > h.size() and h.all(func(x): return r.has(x)):
							sub = true
					if not Datos.receta_de(J.S, a, b) and not sub:
						continue
					var r: String = Datos.cross_result(J.S, a, b)
					var hk := "+".join(Datos.hojas_de(J.S, r))
					if not ids.has(r) and not vistas.has(hk):
						ids.append(r)
						vistas.append(hk)
						via[r] = a + "×" + b
						cambia = true
		R.faltan = D.DEX.filter(func(k): return not ids.has(k))
		R.cm = Datos.cross_result(J.S, "rif", "ria")
		R.ss = Datos.cross_result(J.S, "ria", "rif")
		R.ria = via.ria
		J.S = S0
		var txt := JSON.stringify(D.STRAINS) + JSON.stringify(D.RECIPE_HINTS) + JSON.stringify(D.SHOP.map(func(i): return i.lbl))
		var ms := RegEx.create_from_string("Sensi|Serious|DNA|Barney|Green ?House|Mr\\.? ?Nice|Sacred|DJ Short|Skunkman|Brothers|\\bAce\\b|Ghost|Fire OG|OG Kush").search_all(txt)
		R.marcas = ms.map(func(m): return m.get_string()) if ms.size() else null
		R.linea = Array(J.strain_line("ria").split("\n"))[-1],
		func(): return chk(R.tabla and R.faltan.is_empty() and R.cm == "kushrif" and R.ss == "txoko" and re("(^|×)x", R.ria) and R.marcas == null
			and R.linea == "1.ª generación · Afghani × Colombian Gold × Acapulco Gold", R))
	step("Esquejes: el clon guarda el fenotipo estrella de la madre; su cosecha va a un lote aparte (★); sin plantar se seca", ["Sacar esqueje", "Sacar esqueje", "Cosechar", "^Esqueje"], func():
		J.S.esquejes = []
		J.S.buds = {}
		var f := {"id": 9999, "t": 1.25, "y": 1.15}
		J.S.pots[0] = {"sid": "limon", "prog": .4, "water": 100, "health": 100, "fert": false, "pest": false, "f": f}
		await run(func(): await J.pot_action(0))
		await run(func(): await J.pot_action(0))
		var ids := []
		for e in J.S.esquejes:
			ids.append(Datos.js_num(e.f.id))
		R = {"n": J.S.esquejes.size(), "id": ",".join(ids)}
		J.S.pots[0].prog = 1
		await run(func(): await J.pot_action(0))
		R.feno = J.S.fenos.get("9999")
		R.lote = J.S.buds.has("limon*") and not J.S.buds.has("limon")
		await run(func(): await J.pot_action(0))
		R.pot = jj(J.S.pots[0])
		R.queda = J.S.esquejes.size()
		J.advance_time(48 * 60)
		await idle()
		R.seco = J.S.esquejes.size()
		J.S.pots[0] = null,
		func():
			var p = JSON.parse_string(R.pot) if R.pot != "null" else null
			return chk(R.n == 2 and R.id == "9999,9999" and R.feno == "estrella" and R.lote and p and p.f.id == 9999 and p.prog == .12 and R.queda == 1 and R.seco == 0, R))
	step("Cifras reales: CFL en el armario 60 ≈ 0,3 g/W; LED 720 W en la carpa 150 con macetas de 25 L ≈ 1-1,35 g/W y 45 € de luz; tope de la maceta", [], func():
		var S0 = J.S
		J.S = norm(S0)
		J.S = Datos.enteros(J.S)
		var sk := func(h): return {"sid": "ria", "prog": 1, "water": 100, "health": h, "fert": true, "pest": false, "f": {"t": 1, "y": 1}}
		J.S.carpas = [{"t": "p60", "foco": "cfl"}, {"t": "g150", "foco": "led720"}]
		J.S.macetas = ["plastico7", "plastico7"]
		for k in 6:
			J.S.macetas.append("tela25")
		var gw := func(a: int, b: int, w: float) -> float:
			var s := 0.0
			for j in J.huecos().slice(a, b).size():
				s += J.gramos_planta(sk.call(100), J.factores(a + j))
			return s / w
		R = {"cfl": gw.call(0, 2, 125), "led": gw.call(2, 8, 720), "luz": J.luz_carpa(1)}
		J.S.carpas[0].foco = "led200"
		R.tope = J.gramos_planta(sk.call(100), J.factores(0))
		J.S = S0,
		func(): return chk(R.cfl >= .25 and R.cfl <= .4 and R.led >= 1 and R.led <= 1.35 and R.luz == 45 and R.tope == 56, R))
	step("Semillas al cosechar: Hindu Kush (regular) da 1-3 siempre; Skunk #1 (feminizada de tienda) solo si sale hermafrodita", [], func():
		var sd = J.S.seeds
		R = {}
		var cos := func(sid: String, x: float) -> int:
			J.S.seeds = {}
			Cultivo.fijo = x
			J.S.pots[0] = {"sid": sid, "prog": 1, "water": 100, "health": 100, "fert": false, "pest": false, "f": {"t": 1, "y": 1}}
			await run(func(): await J.harvest(0))
			Cultivo.fijo = -1
			return int(J.S.seeds.get(sid, 0))
		var h := []
		for x in [.99, .5, .01]:
			h.append(await cos.call("hindu", x))
		R.hindu = h
		var s := []
		for x in [.5, .05]:
			s.append(await cos.call("ria", x))
		R.skunk = s
		J.S.seeds = sd,
		func(): return chk(R.hindu.all(func(n): return n >= 1 and n <= 3) and R.skunk[0] == 0 and R.skunk[1] >= 1, R))
	step("Partida de la 1.9 en el capítulo 7 (2.000 € en 3 días) → 15.000 € con 7 días; guardada sin plazo en el 5 → 12.000 €; punto de miles", [], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.ch = 7
		J.S.debt = 2000
		J.S.due = 2000
		J.S.deadline = J.S.day + 3
		J.S.erase("eco")
		J.migrate()
		R = {"due": J.S.due, "dias": J.S.deadline - J.S.day, "eco": J.S.eco, "eur": "|".join([Datos.eur(999), Datos.eur(3000), Datos.eur(1500.4), Datos.eur(-1234), Datos.eur(30000)])}
		J.S.ch = 5
		J.S.debt = 27000
		J.S.due = 0
		J.S.deadline = J.S.day - 2
		J.migrate()
		R.due5 = J.S.due
		R.dias5 = J.S.deadline - J.S.day
		J.S = S0,
		func(): return chk(R.due == 15000 and R.dias == 7 and R.eco == 2 and R.eur == "999 €|3.000 €|1.500 €|-1.234 €|30.000 €" and R.due5 == 12000 and R.dias5 == 10, R))
	step("Capítulo 4: la 8.ª variedad (de un arbusto) no pasa de capítulo; la 2.ª de receta cosechada, sí", [], func():
		J.S.ch = 4
		J.S.flags.lab = true
		J.S.due = 0
		J.S.disc = {"ria": true, "limon": true, "txoko": true, "niebla": true, "mango": true, "purpura": true, "rif": true}
		J.S.custom = {}
		J.S.rec = {"kushrif": 2, "shiva": 1}
		J.S.taken.erase("h_acap")
		J.S.map = "town"
		await run(func(): await J.object_action(2, 26))
		J.S.map = "home"
		await idle()
		R = {"ch": J.S.ch, "disc": J.disc_count()}
		J.S.pots[0] = {"sid": "shiva", "prog": 1, "water": 80, "health": 100, "fert": false, "pest": false, "f": J.roll_feno("shiva")}
		await run(func(): await J.harvest(0)),
		func():
			var sv = J.load_save()
			return chk(R.ch == 4 and R.disc == 8 and J.S.ch == 5 and J.S.due == 12000 and sv and sv.due == 12000, {"R": R, "ch": J.S.ch, "guardado": sv.due if sv else null}))
	# ---------- 1.10: la caja fuerte, el guion completo y el mapa ampliado ----------
	var vacia := func():
		var o := []
		for p in J.S.pots:
			o.append(null)
		J.S.pots = o
	var lin := func(l0: int, p: String) -> String:
		for l in LOG.slice(l0):
			if re(p, l):
				return l
		return ""
	step("Caja de la tía: la pista en el PC («el año en que lo gané»); detrás del diploma, 1987 no abre y 1998 sí (300 € dentro)", ["Notas de la tía", "Mirar detrás", "^1987", "Mirar detrás", "^1998"], func():
		for k in J.S.seeds.keys():   # el paso de la 8.ª variedad vació S.custom: fuera las semillas del híbrido
			if J.strain(k) == null:
				J.S.seeds.erase(k)
		J.S.map = "home"
		J.S.ch = 5
		J.S.caja = null
		J.S.money = 0
		var l0 := LOG.size()
		await run(J.pc_action)
		await run(func(): await J.object_action(7, 1))
		R = {"pista": lin.call(l0, "el año en que lo gané") != "", "tras1987": J.S.caja}
		await run(func(): await J.object_action(7, 1)),
		func(): return chk(R.pista and R.tras1987 == null and J.S.caja and J.S.caja.nivel == 1 and J.S.caja.money == 300 and J.caja_g() == 0 and J.S.money == 0, {"R": R, "caja": J.S.caja}))
	# sin nada encima, ni policía ni ladrones: 20 pasos con el azar a 0 en la primera casilla de clientes del barrio
	var enc := func() -> int:
		var nb := []
		J.gancho_combate = func(t): nb.append(t)
		Cultivo.fijo = 0
		J.S.map = "town"
		var t0: Array = D.CLIENT_TILES.town[0]
		for k in 20:
			J.P.x = int(t0[0])
			J.P.y = int(t0[1])
			J.S.cool = 0
			J.on_step_end()
		Cultivo.fijo = -1
		J.gancho_combate = Callable()
		J.S.map = "home"
		J.S.cool = 0
		return nb.size()
	step("Caja: guardar todo (5.000 € y 300 g); sin nada encima no hay ladrones ni policía en la calle; la mochila la enseña", ["Guardar todo", "Cerrar", "MOCHILA", "<B>", "SALIR"], func():
		J.S.money = 5000
		J.S.buds = {}
		J.add_buds("ria", 200, 12)
		J.add_buds("dragon", 100, 27)
		J.S.protect = false
		J.S.heat = 100
		R = {"antes": enc.call()}
		await run(func(): await J.object_action(7, 1))
		R.despues = enc.call()
		R.caja = norm(J.S.caja)
		R.m = J.S.money
		R.g = J.total_buds()
		var l0 := LOG.size()
		await run(J.start_menu)
		R.mochila = lin.call(l0, "\\[menú\\] Dinero"),
		func(): return chk(R.antes == 20 and R.despues == 0 and R.caja.money == 5300 and R.caja.buds.ria.g == 200 and R.caja.buds.dragon.g == 100 and R.m == 0 and R.g == 0
			and re("Caja fuerte", R.mochila), R))
	step("Caja: sacar 1.000 € y 100 g de Sour Diesel; el soborno cuenta lo de encima (+5 % del dinero)", ["Sacar dinero", "^1\\.000 €", "Sacar cogollos", "^Sour Diesel", "^100 g", "Cerrar"], func():
		J.S.heat = 20
		await run(func(): await J.object_action(7, 1))
		R = {"p": J.precio_soborno()},
		func(): return chk(J.S.money == 1000 and J.S.caja.money == 4300 and J.S.buds.has("dragon") and J.S.buds.dragon.g == 100 and not J.S.caja.buds.has("dragon") and J.S.caja.buds.ria.g == 200
			and R.p == Datos.jsround(40 + 80 + 50 + 50), {"R": R, "money": J.S.money, "caja": J.S.caja, "buds": J.S.buds}))
	step("Redada con la caja (1.11): la caja nunca se toca; la multa (601 € + 300 por planta + 3 por gramo) sale de lo de fuera y, si no llega, de la caja", [], func():
		var mira := func():
			var np := 0
			for p in J.S.pots:
				if p:
					np += 1
			return {"m": J.S.money, "cm": J.S.caja.money, "cg": J.caja_g(), "g": J.total_buds(), "h": J.S.heat, "pots": np}
		J.S.protect = false
		J.S.buds = {}
		vacia.call()
		J.S.pots[1] = {"sid": "ria", "prog": .5, "water": 90, "health": 100, "fert": false, "pest": false}
		J.S.caja.money = 4000
		J.S.money = 200
		J.S.heat = 95
		await run(J.raid_event)
		R = {"a": mira.call()}
		J.add_buds("ria", 30, 12)
		J.S.heat = 95
		await run(J.raid_event)
		R.b = mira.call(),
		func(): return chk(R.a.m == 0 and R.a.cm == 4000 - (901 - 200) and R.a.cg == 200 and R.a.g == 0 and R.a.h == D.CALOR_REDADA and R.a.pots == 0
			and R.b.cg == 200 and R.b.g == 0 and R.b.cm == R.a.cm - 691 and R.b.m == 0 and R.b.h == D.CALOR_REDADA, R))
	step("Caja empotrada por el ordenador (380 €, de fuera y el resto de la caja): Kiko la instala al día siguiente", ["Caja empotrada", "Pedirla"], func():
		J.S.caja.money = 1000
		J.S.money = 100
		await run(J.pc_action)
		R = {"m": J.S.money, "cm": J.S.caja.money, "mejora": J.S.caja.get("mejora"), "nivel": J.S.caja.nivel}
		var l0 := LOG.size()
		J.new_day()
		await idle()
		R.sms = lin.call(l0, "caja empotrada") != "",
		func(): return chk(R.m == 0 and R.cm == 1000 - 280 and R.mejora == 1 and R.nivel == 1 and J.S.caja.nivel == 2 and not J.S.caja.has("mejora") and J.S.caja.money == 720 and R.sms, {"R": R, "caja": J.S.caja}))
	step("Capítulo 7: Darko roba el piso la primera noche con dinero o cogollos fuera de la caja (la mitad); la caja, intacta; la segunda noche, nada", ["Dormir", "Dormir"], func():
		J.S.ch = 7
		J.S.flags.robo = false
		J.S.deadline = J.S.day + 20
		J.S.money = 3001
		J.S.buds = {}
		J.add_buds("ria", 120, 12)
		J.add_buds("kushrif", 81, 20)
		J.S.caja.money = 720
		J.S.caja.buds = {"dragon": {"g": 50, "thc": 27}}
		vacia.call()
		J.S.min = 23 * 60
		await run(J.bed_action)
		R = {"m": J.S.money, "ria": J.S.buds.ria.g, "kr": J.S.buds.kushrif.g, "cm": J.S.caja.money, "cg": J.caja_g(), "robo": J.S.flags.robo}
		J.S.min = 23 * 60
		await run(J.bed_action)
		R.m2 = J.S.money
		R.g2 = J.total_buds(),
		func(): return chk(R.robo and R.m == 1501 and R.ria == 60 and R.kr == 41 and R.cm == 720 and R.cg == 50 and R.m2 == 1501 and R.g2 == 101, R))
	step("Tercer plazo vencido: Toño se lleva la carpa más grande (la de 120, no la de 100) y cada planta sigue en su plaza; después, la otra; sin carpas, la mitad del dinero", [], func():
		J.S.ch = 5
		var pl := func(sid: String): return {"sid": sid, "prog": .3, "water": 90, "health": 100, "fert": false, "pest": false}
		vacia.call()
		J.S.pots[0] = pl.call("ria")
		J.S.pots[3] = pl.call("hindu")
		J.S.pots[8] = pl.call("thai")
		J.S.pots[12] = pl.call("haze")
		var ts := func() -> String:
			var o := []
			for c in J.S.carpas:
				o.append(c.t if c else "")
			return ",".join(o)
		R = {"t": ts.call(), "h0": J.huecos().size()}
		J.S.vencidos = 2
		J.S.due = 1000
		J.S.money = 901
		await run(J.penalty_event)
		var viv := 0
		for p in J.S.pots:
			if p:
				viv += 1
		R.a = {"t": ts.call(), "n": J.huecos().size(), "v": J.S.vencidos, "p0": J.S.pots[0].sid if J.S.pots[0] else null, "p3": J.S.pots[3].sid if J.S.pots[3] else null,
			"vivas": viv, "mapa": J.MAPS.home.carpas.size()}
		for k in [1, 2]:
			J.S.vencidos = 2
			await run(J.penalty_event)
			R["v%d" % k] = "%s|%s|%d" % [ts.call(), Datos.js_num(J.S.money), J.S.pots.size()],
		func(): return chk(R.t == "p80,m100,m120" and R.h0 == 13 and R.a.t == "p80,m100," and R.a.n == 7 and R.a.v == 0 and R.a.p0 == "ria" and R.a.p3 == "hindu" and R.a.vivas == 2 and R.a.mapa == 2
			and R.v1 == "p80,,|901|3" and R.v2 == "p80,,|451|3", R))
	var donde := func(id: String) -> String:
		var o := []
		for e in J.ents:
			if e.id == id:
				o.append("%d,%d" % [int(e.x), int(e.y)])
		return ",".join(o)
	step("Cuota de Molina: se acaba a los 10 días (SMS) y se renueva en la comisaría del barrio alto, de 10 en 10", ["^Pagar", "^Pagar"], func():
		J.S.protect = true
		J.S.protHasta = J.S.day
		J.S.flags.molina1 = true
		var l0 := LOG.size()
		J.new_day()
		await idle()
		R = {"p": J.S.protect, "sms": lin.call(l0, "Se acabó lo pagado") != ""}
		J.S.map = "comisaria"
		J.build_ents()
		R.ent = donde.call("molina")
		J.S.money = 3000
		await run(J.talk_molina)
		R.h1 = J.S.protHasta - J.S.day
		await run(J.talk_molina)
		R.cub = lin.call(l0, "Estás cubierto hasta el día") != ""
		J.S.map = "home",
		func(): return chk(R.p == false and R.sms and R.ent == "4,2" and R.h1 == 10 and R.cub and J.S.protect and J.S.protHasta == J.S.day + 20 and J.S.money == 0, {"R": R, "hasta": J.S.protHasta, "day": J.S.day, "money": J.S.money}))
	var hay_tono := func() -> bool: return J.ents.any(func(e): return e.id == "tono2")
	step("Imperio: encargo de Don Baltasar (2 kg al almacén de los astilleros, de noche, a 6 €/g); Toño se lleva primero lo más flojo; si no llegas, reputación −10 y 5 días sin encargos", ["Aceptar", "Entregar", "Aceptar"], func():
		J.S.ch = 8
		J.S.due = 0
		J.S.encargo = null
		J.S.encVeto = 0
		J.S.rep = 50
		J.S.map = "bar"
		J.S.items.bolsa = 0   # 1.13: 2 kg no caben en la mochila
		var l9 := LOG.size()
		await run(J.talk_baltasar)
		var sin: bool = J.S.encargo == null and LOG.slice(l9).any(func(l): return re("No te caben en la mochila\\. Hazte con una bolsa de deporte", l))
		J.S.items.bolsa = 1
		await run(J.talk_baltasar)
		R = {"e": J.S.encargo.duplicate() if J.S.encargo else null, "d": J.S.day, "sin": sin}
		J.S.map = "almacen"
		J.build_ents()
		R.tono = hay_tono.call()
		J.S.buds = {}
		J.add_buds("ria", 1500, 12)
		J.add_buds("dragon", 800, 27)
		J.S.min = 600
		await run(J.talk_tono_almacen)
		R.dia = J.total_buds() if J.S.encargo else J.S.encargo
		J.S.min = 22 * 60
		R.m = J.S.money
		R.s = J.S.sales
		R.rep = J.S.rep
		R.heat = J.S.heat
		await run(J.talk_tono_almacen)
		R.d1 = {"m": J.S.money - R.m, "s": J.S.sales - R.s, "rep": J.S.rep - R.rep, "heat": J.S.heat - R.heat, "ria": J.S.buds.get("ria"), "dragon": J.S.buds.dragon.g,
			"enc": J.S.encargo, "tono": hay_tono.call()}
		J.S.map = "bar"
		J.S.min = 600
		await run(J.talk_baltasar)
		R.e2 = J.S.encargo.hasta - J.S.day if J.S.encargo else J.S.encargo
		R.rep2 = J.S.rep
		J.S.map = "almacen"
		J.build_ents()
		for k in 3:
			J.new_day()
			await idle()
		R.veto = J.S.encVeto - J.S.day
		R.rep3 = J.S.rep
		R.enc3 = J.S.encargo
		J.S.min = 22 * 60
		var l0 := LOG.size()
		await run(J.talk_tono_almacen)
		R.tarde = hay_tono.call() and lin.call(l0, "El plazo se acabó") != ""   # vencido con Toño delante
		J.S.map = "bar"
		J.S.min = 600
		l0 = LOG.size()
		await run(J.talk_baltasar)
		R.fallo = lin.call(l0, "Me fallaste") != ""
		J.S.map = "home",
		func(): return chk(R.e and R.sin and R.e.g == 2000 and R.e.hasta == R.d + 2 and R.tono and R.dia == 2300 and R.d1.m == 12000 and R.d1.s == 12000 and R.d1.rep == 2 and R.d1.heat == 3
			and not R.d1.ria and R.d1.dragon == 300 and R.d1.enc == null and not R.d1.tono and R.e2 == 2 and R.rep3 == R.rep2 - 10 and R.enc3 == null and R.veto == 5 and R.tarde and R.fallo, R))
	step("Mapa ampliado: barrio alto y astilleros con sus puertas; ladrones al azar y patrullas según la zona; clientes de cada zona", [], func():
		J.S.ch = 5
		J.S.protect = false
		J.S.heat = 0
		J.S.min = 600
		J.S.money = 200
		J.S.buds = {}
		J.add_buds("ria", 10, 12)
		R = {"enc": {}}
		var nb := {"t": null}
		J.gancho_combate = func(t): nb.t = t
		var pt := []
		for z in ["town", "alto", "astilleros", "puerto", "valdehierro", "mendialde", "errotabarri"]:
			J.S.map = z
			var o := []
			for mn in [600, 1380]:
				J.S.min = mn
				o.append(str(J.n_patrullas()))
			pt.append("/".join(o))
		R.pat = ",".join(pt)
		J.S.min = 600
		for zr in [["town", [.0039, .0041]], ["alto", [.0019, .0021]], ["astilleros", [.0079, .0081]]]:
			J.S.map = zr[0]
			var t0: Array = D.CLIENT_TILES[zr[0]][0]
			var o := []
			for r in zr[1]:
				nb.t = null
				Cultivo.fijo = r
				J.P.x = int(t0[0])
				J.P.y = int(t0[1])
				J.S.cool = 0
				J.on_step_end()
				Cultivo.fijo = -1
				o.append(nb.t if nb.t else "")
			R.enc[zr[0]] = ",".join(o)
		J.gancho_combate = Callable()
		J.S.cool = 0
		var W := func(m: String, k: String) -> String:
			var d = J.MAPS[m].doors.get(k)
			return ("%s,%d,%d,%s" % [d.to, d.x, d.y, d.dir]) if d else ""
		R.puertas = "|".join([W.call("town", "11,0"), W.call("town", "12,0"), W.call("alto", "12,29"), W.call("town", "39,21"), W.call("astilleros", "0,20"), W.call("alto", "26,18"),
			W.call("astilleros", "18,13"), W.call("town", "34,8")])
		var sal := []
		for mm in ["comisaria", "almacen", "txaro"]:
			var e: Dictionary = J.MAPS[mm].exits["4,7"]
			sal.append("%s,%d,%d" % [e.to, e.x, e.y])
		R.salidas = "|".join(sal)
		J.S.map = "alto"
		R.m0 = J.S.money
		await run(func(): await J.object_action(2, 10))
		R.sobre = J.S.money - R.m0
		J.S.map = "astilleros"
		R.sp = J.S.items.spray
		var it = J.item_at(4, 5)
		if it:
			await run(func(): await J.pick_item(it))
		R.sp = J.S.items.spray - R.sp
		J.S.map = "town"
		await run(func(): await J.warp(J.MAPS.town.doors["11,0"]))
		R.warp = "%s,%d,%d" % [J.S.map, J.P.x, J.P.y]
		var cz := func(z: String) -> int: return J.S.clients.filter(func(c): return c.get("map") == z).size()
		J.S.ch = 2
		J.spawn_clients()
		R.c2 = "%d,%d,%d" % [cz.call("town"), cz.call("alto"), cz.call("astilleros")]
		J.S.ch = 5
		J.spawn_clients()
		R.c5 = "%d,%d" % [cz.call("alto"), cz.call("astilleros")]
		R.tipos = J.S.clients.all(func(c):
			var ti: Array = ["pij", "tur"] if c.map == "alto" else (["est", "cur"] if c.map == "astilleros" else D.CTYPES.keys())
			return ti.has(c.type) and D.CLIENT_TILES[c.map].any(func(t): return t[0] == c.x and t[1] == c.y))
		var rc := RegEx.create_from_string("^c")
		var rb := RegEx.create_from_string("^c\\d+_b")
		R.ents = J.ents.filter(func(e): return rc.search(e.id) != null and rb.search(e.id) == null).size()
		R.entsB = J.ents.filter(func(e): return rb.search(e.id) != null).size()
		J.S.map = "home"
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.enc.town == "thief," and R.enc.alto == "thief," and R.enc.astilleros == "thief," and R.pat == "1/2,2/2,1/1,1/1,1/1,0/0,0/0"
			and R.puertas == "alto,11,28,up|alto,12,28,up|town,12,1,down|astilleros,1,21,right|town,38,20,left|comisaria,4,6,up|almacen,4,6,up|txaro,4,6,up"
			and R.salidas == "alto,26,19|astilleros,18,14|town,34,9" and R.warp == "alto,11,28" and R.c2.ends_with(",0,2") and R.c5 == "3,3" and R.tipos and R.ents == 0 and R.entsB == 3
			and R.sobre == 80 and R.sp == 2, R))
	# la comarca por capítulos (1.14)
	step("Líneas por capítulo (1.14): Puerto Viejo y Valdehierro desde el 2, Errotabarri desde el 3, Ibarbide desde el 4 (SMS al abrirse); Ibarbide (4 €), el Casco Viejo y por la avenida el Ensanche", ["Ibarbide"], func():
		var sv: int = J.S.ch
		R = {}
		J.enter_map("town", 7, 12, "up")
		J.S.min = 10 * 60
		var ll := []
		for c in [1, 2, 3, 4]:
			J.S.ch = c
			ll.append("+".join(D.PARADAS.keys().filter(func(k): return k != "town" and J.S.ch >= int(D.PARADAS[k].cap))))
		R.l = "|".join(ll)
		J.S.ch = 4
		var l0 := LOG.size()
		await run(func(): await J.lineas_nuevas())
		R.sms = " / ".join(LOG.slice(l0).filter(func(l): return l.begins_with("SMS")))
		R.m = J.S.money
		await run(func(): await J.parada_action())
		R.mapa = "%s,%d,%d" % [J.S.map, J.P.x, J.P.y]
		R.m = R.m - J.S.money
		R.pat = "%d/%d,%d/%d" % [D.PATRULLAS.ibarbide[0], D.PATRULLAS.ibarbide[1], D.PATRULLAS.ensanche[0], D.PATRULLAS.ensanche[1]]
		await run(func(): await J.warp(J.MAPS.ibarbide.doors["43,21"]))
		R.en = "%s,%d,%d" % [J.S.map, J.P.x, J.P.y]
		R.vecino = J.ents.any(func(e): return e.id == "ibarbitarra")
		var d: Dictionary = J.MAPS.ensanche.doors["0,11"]
		R.vuelta = "%s,%d,%d" % [d.to, d.x, d.y]
		R.cli = ",".join(["ibarbide", "ensanche"].map(func(z): return "true" if D.CLIENT_TILES[z].size() >= 60 else "false"))
		J.S.ch = sv
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.l == "mendialde|puerto+valdehierro+mendialde|puerto+valdehierro+mendialde+errotabarri|puerto+valdehierro+mendialde+errotabarri+ibarbide"
			and R.sms == "SMS · AUTOBUSES DE LA COMARCA: Nueva línea desde Ribera Verde: Ibarbide. / SMS · AUTOBUSES DE LA COMARCA: Salidas de 7:00 a 21:00, en la parada de la calle Ribera."
			and R.mapa == "ibarbide,10,20" and R.m == 4 and R.en == "ensanche,1,10" and R.vuelta == "ibarbide,42,22" and R.vecino and R.cli == "true,true" and R.pat == "2/2,2/3", R))
	step("GROW IBARBIDE (1.14): el equipo de Kiko a −10 % y hasta un capítulo antes (la maleta del 5, en el 4); sin semillas, carro ni aparatos", ["Maleta con ruedas", "Salir"], func():
		var sv := {"ch": J.S.ch, "b": J.S.items.bolsa}
		J.S.ch = 4
		J.S.items.bolsa = 0
		J.S.money = 2000
		J.enter_map("growcity", 4, 6, "up")
		R = {"m": J.S.money, "ane": J.ents.any(func(e): return e.id == "ane")}
		var l0 := LOG.size()
		await run(func(): await J.talk_ane())
		var mm: Array = LOG.slice(l0).filter(func(l): return re("\\[menú\\]", l))
		R.menu = mm[0] if mm.size() else ""
		R.m = R.m - J.S.money
		R.b = J.S.items.bolsa
		J.S.ch = sv.ch
		J.S.items.bolsa = sv.b
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.ane and R.m == Datos.jsround(pr("Maleta") * .9) and R.b == 2 and re("Foco LED 720 W", R.menu) and not re("Semillas|Carro|Termohigr|Calefactor", R.menu), R))
	step("La comarca con función (1.14): la lonja (Puerto Viejo) carga a ×1,15 cada 3 días; la chatarrería (Valdehierro), 3 piezas al día a mitad de precio; el molino (Errotabarri), 20 g por 3 semillas de una landrace que no tienes", ["^Skunk", "^250 g"], func():
		J.S.ch = 5
		J.S.money = 1000
		J.S.buds = {}
		J.add_buds("ria", 300, 12)
		J.S.lonja = 0
		J.S.trueque = 0
		J.S.chatarra = null
		R = {}
		J.enter_map("puerto", 20, 9, "down")
		R.m = J.S.money
		await run(func(): await J.talk_nerea())
		R.lonja = J.S.money - R.m
		R.g = J.S.buds.ria.g
		R.m = J.S.money
		await run(func(): await J.talk_nerea())
		R.otra = J.S.money - R.m
		J.enter_map("valdehierro", 15, 11, "down")
		R.dia = J.chatarra_dia()
		var it: Dictionary = {}
		for l in R.dia:
			var x: Dictionary = D.SHOP.filter(func(s): return s.lbl == l)[0]
			if J.S.ch >= int(x.ch) and J.shop_cond(x):
				it = x
				break
		R.lbl = it.lbl
		var pide := false
		if it.get("foco"):
			pide = J.S.carpas.any(func(c): return c and D.FOCOS[it.foco].w <= D.CARPAS[c.t].wmax)
		elif it.get("extra"):
			pide = J.S.carpas.any(func(c): return J.falta_extra(c, it.extra))
		want(["^" + it.lbl] + (["^Luego"] if pide else []) + ["<B>"])
		R.m = J.S.money
		await run(func(): await J.talk_bixente())
		R.chat = R.m - J.S.money
		R.v = "|".join(J.S.chatarra.v) if J.S.chatarra else null
		R.p = Datos.jsround(it.p * .5)
		want(["<B>"])
		R.m = J.S.money
		await run(func(): await J.talk_bixente())
		R.chat2 = R.m - J.S.money
		J.enter_map("errotabarri", 7, 13, "down")
		R.k = J.landrace_trueque()
		R.s = J.S.seeds.get(R.k, 0)
		want(["^Skunk"])
		await run(func(): await J.talk_andoni())
		R.s = J.S.seeds.get(R.k, 0) - R.s
		R.g2 = J.S.buds.ria.g
		R.d = J.S.disc.get(R.k)
		R.n = "nerea,bixente,andoni"
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.lonja == Datos.jsround(250 * Datos.jsround(J.precio_mayor(12) * 1.15 * 100) / 100.0) and R.g == 50 and R.otra == 0 and R.dia.size() == 3
			and R.dia[0] != R.dia[1] and R.dia[1] != R.dia[2] and R.dia[0] != R.dia[2]
			and R.chat == R.p and R.v == R.lbl and R.chat2 == 0 and R.s == 3 and R.g2 == 30 and si(R.d) and J.S.lonja == J.S.day and J.S.trueque == J.S.day, R))
	step("Kale Zaharra (1.14): por el callejón de detrás de GROW IBARBIDE, una plazuela sin patrullas (más ladrones, el gramo ×1,3) con algo en el arbusto; se vuelve por el mismo callejón", [], func():
		J.S.ch = 5
		R = {}
		J.enter_map("ibarbide", 19, 1, "up")
		await run(func(): await J.warp(J.MAPS.ibarbide.doors["19,0"]))
		R.en = "%s,%d,%d" % [J.S.map, J.P.x, J.P.y]
		R.m = J.S.money
		await run(func(): await J.object_action(21, 10))
		R.m = J.S.money - R.m
		var d: Dictionary = J.MAPS.callejon.doors["11,17"]
		R.vuelta = "%s,%d,%d" % [d.to, d.x, d.y]
		R.z = "%d/%d,%s,%s,%s" % [D.PATRULLAS.callejon[0], D.PATRULLAS.callejon[1], str(D.ZONAS.callejon.lad), str(D.ZONAS.callejon.precio), "true" if D.CLIENT_TILES.callejon.size() >= 20 else "false"]
		J.S.clientsDay = 0
		J.spawn_clients()
		R.c = J.S.clients.filter(func(c): return c.map == "callejon").size()
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.en == "callejon,10,16" and R.m == 120 and R.vuelta == "ibarbide,20,1" and R.z == "0/0,1.6,1.3,true" and R.c == 2, R))
	step("Clubs cannábicos (1.15): el carné (la cuota), un lote al día entre lo de Iñaki y la calle, 10 g de la variedad del día (entra en la Genoteca) y un encargo de semillas que se paga al entregarlo", ["^Hacerme socio", "^Vender al club", "^Skunk", "^100 g"], func():
		J.S.ch = 5
		J.S.money = 1000
		J.S.buds = {}
		J.add_buds("ria", 300, 12)
		J.S.clubs = {}
		J.S.clubDia = {}
		J.S.clubCompra = {}
		J.S.clubEnc = null
		J.S.clubEncDia = 0
		J.S.rel = {}
		R = {}
		J.enter_map("puerto", 10, 9, "up")
		var l := []
		for e in J.ents:
			if e.id == "club_puerto":
				l.append("%d,%d" % [e.x, e.y])
		R.ent = ",".join(l)
		R.m = J.S.money
		await run(func(): await J.talk_club("puerto"))
		R.venta = J.S.money - R.m + int(D.CLUBS.puerto.cuota)
		R.g = J.S.buds.ria.g
		R.pg = Datos.jsround(J.precio_club(12) * 100) / 100.0
		want(["^Vender al club"])
		R.m = J.S.money
		await run(func(): await J.talk_club("puerto"))
		R.otra = J.S.money - R.m
		var sid: String = D.CLUBS.puerto.sid[int(J.S.day) % 2]
		want(["^Comprar", "^Comprar"])
		R.m = J.S.money
		await run(func(): await J.talk_club("puerto"))
		R.compra = R.m - J.S.money
		R.cb = J.S.buds[sid].g if J.S.buds.has(sid) else null
		R.disc = J.S.disc.get(sid, false) == true
		R.pc = Datos.jsround(J.precio_calle(D.STRAINS[sid].thc) * 1.2 * 10)
		want(["^Encargo", "^Aceptar"])
		await run(func(): await J.talk_club("puerto"))
		R.enc = ("%s,%d,%d" % [J.S.clubEnc.k, int(J.S.clubEnc.n), int(J.S.clubEnc.hasta) - int(J.S.day)]) if J.S.get("clubEnc") else null
		J.S.seeds[J.S.clubEnc.sid] = int(J.S.seeds.get(J.S.clubEnc.sid, 0)) + 10
		want(["^Entregar"])
		R.m = J.S.money
		R.rep = J.S.rep
		await run(func(): await J.talk_club("puerto"))
		R.pago = J.S.money - R.m
		R.rep = J.S.rep - R.rep
		R.fin = J.S.get("clubEnc") == null and J.S.clubEncDia == J.S.day
		R.rel = J.S.rel.get("puerto")
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.ent == "10,8" and R.venta == Datos.jsround(100 * R.pg) and R.g == 200 and J.S.clubs.get("puerto") == true and R.otra == 0 and R.compra == R.pc and R.cb == 10 and R.disc and R.enc == "puerto,10,7" and R.pago > 0 and R.rep == 3 and R.fin and R.rel == 9, R))
	step("La cata y el analizador (1.15): catar medio gramo (30 min) deja la nota (aroma, efecto y potencia) en la Genoteca y marca el lote; con el analizador, el THC exacto y el lote analizado", [], func():
		J.S.ch = 5
		J.S.min = 10 * 60
		J.S.buds = {}
		J.add_buds("ria", 20, 12.3)
		J.add_buds("thai", 10, 17)
		J.S.catas = {}
		J.S.items.analizador = 0
		R = {"min": J.S.min}
		await run(func(): await J.catar("ria"))
		R.n1 = J.S.catas.ria
		R.g = J.S.buds.ria.g
		R.c = J.S.buds.ria.get("cata", false) == true
		R.t = J.S.min - R.min
		J.S.items.analizador = 1
		await run(func(): await J.catar("thai"))
		R.n2 = J.S.catas.thai
		await run(func(): await J.analizar("ria"))
		R.a = J.S.buds.ria.get("ana", false) == true
		R.a0 = J.S.buds.thai.get("ana", false) == true
		R.nota = J.nota_cata("ria", 12.3),
		func(): return chk(RegEx.create_from_string("^Aroma .+ · relaja y pesa · media$").search(R.n1) != null and R.g == 19.5 and R.c and R.t == 30 and RegEx.create_from_string("^Aroma .+ · sube y despeja · 17,0 % de THC$").search(R.n2) != null and R.a and not R.a0 and R.nota.ends_with("12,3 % de THC"), R))
	step("Confianza y trabajadores (1.15): hablar suma 1 al día; Begoña, con 20 y desde el cap. 3, se contrata de jardinera (riega y cobra 20 € al amanecer); un cliente de la agenda con 50 vende para ti a comisión y te deja lo vendido en el buzón", ["^Contratarla", "^Hecho"], func():
		J.S.ch = 5
		J.S.money = 500
		J.S.rel = {}
		J.S.relDia = {}
		J.S.curro = {"jard": null, "vend": []}
		R = {}
		J.enter_map("town", 21, 22, "up")
		J.interact()
		await idle()
		R.patxi = J.S.rel.get("patxi")
		J.interact()
		await idle()
		R.patxi2 = J.S.rel.get("patxi")
		J.S.rel.begona = int(D.REL.amigo)
		await run(func(): await J.talk_begona())
		R.jard = J.S.curro.get("jard") != null
		J.S.buds = {}
		J.add_buds("ria", 200, 12)
		J.S.fijos = [{"id": "cF", "n": "Asier", "t": "cur", "dia": 0}]
		J.S.rel.cF = int(D.REL.socio)
		want(["^Que venda", "^Skunk", "^50 g"])
		await run(func(): await J.fijo_menu(J.S.fijos[0]))
		R.vend = ("%s,%d" % [J.S.curro.vend[0].id, int(J.S.curro.vend[0].g)]) if J.S.curro.vend.size() else ""
		R.g = J.S.buds.ria.g
		for p in J.S.pots:
			if p:
				p.water = 20
		R.m = J.S.money
		R.luz = J.factura_luz()
		R.sms = J.S.sms.size()
		J.new_day()
		await idle()
		R.agua = J.S.pots.filter(func(p): return p != null).all(func(p): return p.water == 100)
		var v = J.S.curro.vend[0] if J.S.curro.vend.size() else null
		R.gone = v == null
		R.v = v.g if v else 0
		R.e = Datos.jsround(J.precio_calle(12) * D.ZONAS.town.precio * (50 - v.g) * (1 - D.CURRO.vend.com)) if v else 0
		R.dinero = J.S.money - (R.m - int(D.CURRO.jard.sueldo) + R.e - R.luz)
		R.sms = J.S.sms.size() - R.sms
		J.S.curro = {"jard": null, "vend": []}
		J.S.fijos = []
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.patxi == 1 and R.patxi2 == 1 and R.jard and R.vend == "cF,50" and R.g == 150 and R.agua and (R.gone or R.v < 50) and R.dinero == 0 and R.sms >= 1, R))
	step("Rivales, combates y la casa (1.16): el rival de la zona sale a la 8.ª venta (si le ganas, se va una semana y sus clientes pagan un 5 % más; o le pagas su cuota, o te apartas); CUBRIRSE para la mitad del golpe; el sillón con la lámpara y el cuadro, con su tapizado y su lámina, y el diario de la tía Maite desde el sillón", ["^Pelear"], func():
		J.S.ch = 5
		J.S.money = 1000
		J.S.min = 10 * 60
		J.S.rivales = {}
		J.S.rivalFuera = {}
		R = {"b": []}
		J.gancho_combate = func(t):
			R.b.append(t)
			return "win"
		var c1: Array = D.CLIENT_TILES.alto[0]
		J.enter_map("alto", int(c1[0]), int(c1[1]), "down")
		for k in int(D.RIVAL.umbral) - 1:
			J.rival_venta("alto")
		R.q7 = J.queued.has("rival")
		R.c7 = J.S.rivales.alto
		J.rival_venta("alto")
		await idle()
		R.fuera = J.S.rivalFuera.alto - J.S.day
		R.cero = J.S.rivales.alto
		R.f = J.rival_f("alto")
		J.rival_venta("alto")
		R.otra = J.S.rivales.alto
		var c2: Array = D.CLIENT_TILES.puerto[0]
		J.enter_map("puerto", int(c2[0]), int(c2[1]), "down")
		J.S.rivales.puerto = int(D.RIVAL.umbral)
		want(["^Pagarle"])
		R.m = J.S.money
		await run(func(): await J.rival_event("puerto"))
		R.pago = R.m - J.S.money
		var c3: Array = D.CLIENT_TILES.ensanche[0]
		J.enter_map("ensanche", int(c3[0]), int(c3[1]), "down")
		J.S.rivales.ensanche = int(D.RIVAL.umbral)
		want(["^Irte"])
		await run(func(): await J.rival_event("ensanche"))
		R.irte = J.S.rivales.ensanche
		J.S.rivales.ibarbide = int(D.RIVAL.umbral)
		await run(func(): await J.rival_event("ibarbide"))
		R.lejos = J.S.rivales.ibarbide
		J.gancho_combate = Callable()
		J.S.rivales = {}
		J.S.rivalFuera = {}
		J.S.hp = 20
		J.S.hpMax = 30
		await run(func():
			J.B = {"kind": "thief", "name": "ATRACADOR", "atk": [5, 5], "hp": 10, "hpMax": 10, "cubre": 1, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
			await J.enemy_hits()
			J.B = null)
		R.hp = J.S.hp
		var m0 = J.S.get("muebles", {}).duplicate(true)
		J.S.muebles = {"sofa": J.S.day, "sillon": J.S.day, "cuadro": J.S.day}
		J.S.deco = {}
		J.enter_map("home", 12, 2, "up")
		var o: Array = J.MAPS.home.o
		R.obj = ",".join(PackedStringArray([o[1][12], o[1][13], o[5][16], o[5][17], o[5][13], o[5][14]].map(func(v): return v if v else "")))
		want(["^Cambiar la lámina", "^La hoja"])
		await run(func(): await J.mueble_action("cuadro"))
		R.cuadro = "%d,%s" % [int(J.S.deco.cuadro), J.deco_sprite("cuadro")]
		want(["^Cambiar el tapizado", "^Granate"])
		await run(func(): await J.mueble_action("sofa"))
		R.sofa = J.deco_sprite("sofa")
		R.min = J.S.min
		want(["^Leer el diario", "Volver"])
		await run(func(): await J.mueble_action("sillon"))
		R.t = J.S.min - R.min
		R.tienda = ",".join(PackedStringArray(D.MUEBLES.keys().filter(func(k): return not D.MUEBLES[k].get("grow"))))
		J.S.muebles = m0
		J.S.deco = {}
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(not R.q7 and R.c7 == 7 and ",".join(PackedStringArray(R.b)) == "rival" and R.fuera == D.RIVAL.dias and R.cero == 0 and is_equal_approx(R.f, 1.05) and R.otra == 0 and R.pago == 230 and R.irte == 6 and R.lejos == 8 and R.hp == 17
			and R.obj == "cuadro,,sillon,sillon2,sofa,sofa2" and R.cuadro == "2,cuadro-2" and R.sofa == "sofa-2" and R.t == 30 and R.tienda == "sofa,tv,gpc,sillon,cuadro,cartel,alfombra"
			and LOG.has("ROBER: Eh, tú. Llevas 8 ventas en el barrio alto.") and LOG.has("Te cubres: el golpe duele la mitad.") and LOG.has("Rober no volverá por el barrio alto en 7 días. Mientras, sus clientes te pagan un 5 % más."), R))
	step("Darko y Miren (1.17): en el capítulo 8, el ajuste de cuentas con Darko en los astilleros (coge la barra: el golpe siguiente, doble, y CUBRIRSE lo deja en la mitad; si le ganas, se va y sus chicos ya no salen); Miren, la amiga de la tía Maite, en Errotabarri: 20 g de Purple Thai por la última página del diario y 5 semillas de Haze", ["^Pelear"], func():
		J.S.ch = 8
		J.S.flags.darkoFin = 0
		var sv := {"hp": J.S.hp, "hpMax": J.S.hpMax, "rep": J.S.rep, "pelea": J.S.pelea.duplicate()}
		R = {"b": []}
		J.gancho_combate = func(t):
			R.b.append(t)
			return "win"
		J.enter_map("astilleros", 24, 17, "up")
		J.S.buds = {}
		J.add_buds("ria", 30, 12)
		var cl := func(id: String) -> Callable:
			var c := {"id": id, "map": "astilleros", "x": 5, "y": 20, "type": "cur", "want": 10, "minThc": 0}
			J.S.clients.append(c)
			want(["Justo"])
			return func():
				Cultivo.fijo = .2
				await J.talk_client(c)
				Cultivo.fijo = -1
		await run(cl.call("cx6"))
		want(["^Pelear"])
		R.dk = J.ents.any(func(e): return e.id == "darko2")
		R.rep = J.S.rep
		await run(J.talk_darko)
		R.fin = J.S.flags.darkoFin == J.S.day
		R.rep = J.S.rep - R.rep
		R.dk2 = J.ents.any(func(e): return e.id == "darko2")
		await run(cl.call("cx7"))
		R.vend = J.S.buds.ria.g
		J.gancho_combate = Callable()
		J.S.hp = 30
		J.S.hpMax = 30
		R.jefe = J.rival_b("darko").jefe
		await run(func():
			J.B = {"kind": "thief", "rival": "Darko", "jefe": 1, "name": "DARKO", "atk": [6, 6], "hp": 40, "hpMax": 40, "t": 0.0, "flashE": 0.0, "shakeP": 0.0, "cubre": 1, "esquiva": 1}
			Cultivo.fijo = 0
			R.r1 = await J.enemy_hits()
			R.carga = J.B.carga
			R.hp1 = J.S.hp
			R.gasta = "%d,%d" % [J.B.cubre, J.B.esquiva]
			Cultivo.fijo = .99
			J.B.cubre = 1
			await J.enemy_hits()
			R.hp2 = J.S.hp
			R.carga2 = J.B.carga
			await J.enemy_hits()
			R.hp3 = J.S.hp
			J.B.hp = 1
			R.rep0 = J.S.rep
			want(["HABLAR", "CALMAR"])
			R.t1 = await J.thief_round()
			R.hp4 = J.S.hp
			Cultivo.fijo = 0
			want(["LUCHAR", "PUÑETAZO", "^Fuerza"])
			R.t2 = await J.thief_round()
			R.repJ = J.S.rep - R.rep0
			R.hpMax = J.S.hpMax
			Cultivo.fijo = -1
			J.B = null)
		J.S.hp = sv.hp
		J.S.hpMax = sv.hpMax
		J.S.rep = sv.rep
		J.S.pelea = sv.pelea
		J.S.flags.darkoFin = 0
		J.S.ch = 5
		J.S.flags.miren = 0
		J.S.flags.pagina = 0
		J.S.buds = {}
		J.enter_map("errotabarri", 24, 11, "up")
		R.mi = ",".join(PackedStringArray(J.ents.filter(func(e): return e.id == "miren").map(func(e): return "%d,%d" % [int(e.x), int(e.y)])))
		await run(J.talk_miren)
		R.m1 = true if J.S.flags.miren else false
		await run(J.talk_miren)
		R.h0 = int(J.S.seeds.get("haze", 0))
		J.S.flags.lao = 0
		R.l0 = int(J.S.seeds.get("lao", 0))
		J.add_buds("amanecer*", 10, 20)
		J.add_buds("amanecer", 15, 18)
		J.add_buds("ria", 30, 12)
		want(["^Dárselos"])
		await run(J.talk_miren)
		R.pt = "%s,%s" % [J.n(J.S.buds["amanecer*"].g) if J.S.buds.has("amanecer*") else "0", "true" if J.S.buds.has("amanecer") else "false"]
		R.ria = J.S.buds.ria.g
		R.h = int(J.S.seeds.haze) - R.h0
		R.lao = int(J.S.seeds.lao) - R.l0
		R.pag = J.S.flags.pagina == J.S.day
		var l0 := LOG.size()
		want(["La última página", "Volver"])
		await run(J.recetario)
		R.ult = LOG.slice(l0).filter(func(l): return l.contains("[menú]") and l.contains("La última página")).size()
		J.S.flags.pagina = 0
		J.S.flags.miren = 0
		J.S.buds = {}
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.dk and not R.dk2 and ",".join(PackedStringArray(R.b)) == "thief,darko" and R.vend == 10 and R.fin and R.rep == D.DARKO.rep and R.jefe == 1 and R.r1 == null and R.carga == 1 and R.hp1 == 30 and R.gasta == "0,0" and R.hp2 == 24 and R.carga2 == 0 and R.hp3 == 18
			and R.t1 == null and R.hp4 == 12 and R.t2 == "win" and R.repJ == 0 and R.hpMax == 32 and LOG.has("«Aquí ya no hay nada que hablar.»") and LOG.has("Darko cae al suelo, sin aire.")
			and R.mi == "24,10" and R.m1 and R.pt == "5,false" and R.ria == 30 and R.h == D.MIREN.n and R.lao == D.MIREN.n2 and R.pag and R.ult == 2
			and LOG.has("DARKO: Las esquinas son tuyas. Yo me largo de aquí una temporada.") and LOG.has("SMS · DON BALTASAR: Me han contado lo de mi sobrino.") and LOG.has("Darko coge una barra de hierro del suelo. El próximo golpe va a doler."), R))
	step("Combates con más fondo (1.18): ESQUIVAR (si te apartas, tu golpe siguiente no falla y hace 3 más; si no, te da entero), AMENAZAR (mejor cuanto más tocado está; si falla, el golpe siguiente hace 2 más; a Darko no se le amenaza) y la experiencia: al ganar subes de nivel y eliges FUERZA o REFLEJOS (hasta 5 cada una), con la fila Pelea en la MOCHILA", [], func():
		var sv := {"hp": J.S.hp, "hpMax": J.S.hpMax, "rep": J.S.rep, "money": J.S.money, "pelea": J.S.pelea.duplicate()}
		R = {}
		J.S.hp = 30
		J.S.hpMax = 30
		J.S.pelea = {"xp": 0, "fue": 0, "ref": 0}
		await run(func():
			J.B = {"kind": "thief", "name": "ATRACADOR", "atk": [5, 5], "hp": 20, "hpMax": 20, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
			Cultivo.fijo = 0
			want(["LUCHAR", "ESQUIVAR"])
			R.e1 = await J.thief_round()
			R.hp1 = J.S.hp
			R.contra = J.B.contra
			Cultivo.fijo = .99
			want(["LUCHAR", "PUÑETAZO"])
			await J.thief_round()
			R.bh = J.B.hp
			R.hp2 = J.S.hp
			want(["LUCHAR", "ESQUIVAR"])
			await J.thief_round()
			R.hp3 = J.S.hp
			R.pa = J.prob_amenaza()
			want(["HABLAR", "AMENAZAR"])
			await J.thief_round()
			R.hp4 = J.S.hp
			R.furia = J.B.furia
			Cultivo.fijo = 0
			want(["HABLAR", "AMENAZAR"])
			R.am = await J.thief_round()
			J.B = {"kind": "thief", "rival": "Darko", "jefe": 1, "name": "DARKO", "atk": [6, 6], "hp": 1, "hpMax": 40, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
			Cultivo.fijo = .5
			want(["HABLAR", "AMENAZAR"])
			R.am2 = await J.thief_round()
			R.hp5 = J.S.hp
			J.B.carga = 1
			Cultivo.fijo = 0
			want(["LUCHAR", "ESQUIVAR"])
			R.e2 = await J.thief_round()
			R.carga3 = J.B.carga
			R.hp6 = J.S.hp
			J.S.pelea = {"xp": 0, "fue": 0, "ref": 0}
			want(["LUCHAR", "PUÑETAZO", "^Fuerza"])
			R.wd = await J.thief_round()
			R.dx = "%d,%d" % [int(J.S.pelea.xp), int(J.S.pelea.fue)]
			J.S.hp = 30
			J.S.pelea = {"xp": 1, "fue": 0, "ref": 0}
			J.B = {"kind": "thief", "name": "ATRACADOR", "atk": [5, 5], "hp": 1, "hpMax": 20, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
			Cultivo.fijo = 0
			want(["LUCHAR", "PUÑETAZO", "^Reflejos"])
			R.w = await J.thief_round()
			R.pe = "%d,%d,%d" % [int(J.S.pelea.xp), int(J.S.pelea.fue), int(J.S.pelea.ref)]
			R.nv = J.nivel_pelea()
			R.ficha = J.ficha_pelea()
			J.S.pelea = {"xp": 64, "fue": 5, "ref": 4}
			J.B = {"kind": "thief", "rival": "Rober", "name": "ROBER", "atk": [5, 5], "hp": 1, "hpMax": 20, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
			want(["LUCHAR", "PUÑETAZO"])
			R.w2 = await J.thief_round()
			R.max = "%d,%d,%d" % [int(J.S.pelea.xp), int(J.S.pelea.fue), int(J.S.pelea.ref)]
			R.pe5 = J.prob_esquiva()
			J.B = {"kind": "thief", "name": "ATRACADOR", "atk": [5, 5], "hp": 20, "hpMax": 20, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
			Cultivo.fijo = .69
			want(["HUIR"])
			R.h = await J.thief_round()
			Cultivo.fijo = -1
			J.B = null)
		var l0 := LOG.size()
		want(["<B>"])
		await run(J.mochila)
		R.fila = LOG.slice(l0).filter(func(l): return l.contains("[menú]") and l.contains("| Pelea |")).size()
		J.S.hp = sv.hp
		J.S.hpMax = sv.hpMax
		J.S.rep = sv.rep
		J.S.money = sv.money
		J.S.pelea = sv.pelea,
		func(): return chk(R.e1 == null and R.hp1 == 30 and R.contra == 1 and R.bh == 20 - (7 + int(D.PELEA.contra)) and R.hp2 == 25 and R.hp3 == 20 and absf(R.pa - (float(D.PELEA.amen0) + .5 * float(D.PELEA.amen))) < 1e-9 and R.hp4 == 20 - (5 + int(D.PELEA.furia)) and R.furia == 0 and R.am == "talk"
			and R.am2 == null and R.hp5 == 13 - (6 + int(D.PELEA.furia)) and R.e2 == null and R.carga3 == 0 and R.hp6 == R.hp5 and R.wd == "win" and R.dx == "%d,1" % int(D.PELEA.xp.darko)
			and R.w == "win" and R.pe == "2,0,1" and R.nv == 1 and R.ficha == "Fuerza 0 · reflejos 1 · 2 de experiencia (nivel 2 con 5).\nSube ganando peleas: un ladrón da 1, un rival 2."
			and R.w2 == "win" and R.max == "66,5,5" and absf(R.pe5 - .75) < 1e-9 and R.h == "flee" and R.fila == 1
			and LOG.has("El atracador se lanza y te apartas a tiempo.") and LOG.has("Darko baja la barra y te apartas a tiempo.") and LOG.has("Le pillas abierto.") and LOG.has("No te apartas a tiempo.") and LOG.has("«¿A mí? Ahora vas a ver.»")
			and LOG.has("El atracador se lo piensa mejor y se va.") and LOG.has("«A mí no me amenaza nadie.»") and LOG.has("Subes a nivel 1 de pelea.") and LOG.has("REFLEJOS 5: aciertas, esquivas y escapas mejor."), R))
	step("La plantilla (1.19): Patxi te manda gente del barrio por un sobre (labia, cuidado y lealtad del 1 al 5); a la calle con un lote (vende, o le para la policía, le atracan, se larga o le timan, según sus números), de gerente (cuida y cosecha al arcón con su sisa) y en la nave de Valdehierro, que alquila Arrieta (cada mañana, el alquiler, la redada y lo que saca cada uno)", [], func():
		var sv: Dictionary = {"money": J.S.money, "heat": J.S.heat, "buds": J.S.buds.duplicate(true), "arcon": J.S.arcon.duplicate(true), "pots": J.S.pots.duplicate(true), "carpas": J.S.carpas.duplicate(true), "seeds": J.S.seeds.duplicate(true),
			"sales": J.S.sales, "ch": J.S.ch, "fenos": J.S.fenos.duplicate(true), "rec": J.S.rec.duplicate(true), "h1": J.S.flags.get("harvest1", false)}
		R = {}
		J.S.ch = 5
		J.S.money = 5000
		J.S.heat = 0
		J.S.plantilla = []
		J.S.plN = 0
		J.S.nave = null
		J.S.buds = {}
		J.add_buds("ria", 100, 12)
		J.S.arcon = {"buds": {}, "rosin": {}}
		var fi := func(w): return ("%s,%d,%d,%d,%s" % [w.n, int(w.lab), int(w.cui), int(w.lea), w.rol if w.rol else ""]) if w else ""
		var dia := func(v: float):
			Cultivo.fijo = v
			J.plantilla_dia()
			Cultivo.fijo = -1
			await idle()
		await run(func():
			Cultivo.fijo = .99
			want(["^Contratar"])
			await J.pedir_gente()
			R.w1 = fi.call(J.S.plantilla[0])
			Cultivo.fijo = 0
			want(["^No"])
			await J.pedir_gente()
			R.n2 = J.S.plantilla.size()
			want(["^Contratar"])
			await J.pedir_gente()
			R.w2 = fi.call(J.S.plantilla[1])
			Cultivo.fijo = .5
			want(["^Contratar"])
			await J.pedir_gente()
			R.w3 = fi.call(J.S.plantilla[2])
			R.pl = "%d,%d" % [int(J.S.plN), 5000 - J.S.money]
			Cultivo.fijo = -1)
		var itz: Dictionary = J.S.plantilla[0]
		var mik: Dictionary = J.S.plantilla[1]
		var ike: Dictionary = J.S.plantilla[2]
		want(["^A la calle", "^Skunk", "^25 g"])
		await run(func(): await J.trabajo(mik))
		R.calle = "%s,%s,%d,%d" % [mik.rol, mik.k, int(mik.g), int(J.S.buds.ria.g)]
		want(["^De gerente"])
		await run(func(): await J.trabajo(ike))
		var l0 := LOG.size()
		want(["<B>"])
		await run(func(): await J.trabajo(itz))
		R.ops = LOG.slice(l0).filter(func(l): return l.begins_with("  [menú] A la calle | Despedir | Nada")).size()
		J.S.pots = J.S.pots.map(func(_p): return null)
		J.S.pots[0] = {"sid": "ria", "prog": 1, "water": 100, "health": 100, "fert": false, "pest": false, "f": {"t": 1, "y": 1}}
		R.gc = J.gramos_planta(J.S.pots[0], J.factores(0))
		R.m = J.S.money
		await dia.call(.5)
		R.e = Datos.jsround(J.precio_calle(12) * D.ZONAS.town.precio * 3 * (1 - D.PLANTILLA.com))
		R.venta = jn([mik.g, J.S.money - R.m + int(D.PLANTILLA.sueldo.gerente), J.S.heat])
		R.arc = J.S.arcon.buds.ria.g if J.S.arcon.buds.has("ria") else 0
		R.pot = J.S.pots[0]
		R.m = J.S.money
		await dia.call(.01)
		R.poli = jn([mik.rol, not mik.has("g"), J.S.heat, R.m - J.S.money])
		want(["^A la calle", "^Skunk", "^25 g"])
		await run(func(): await J.trabajo(mik))
		await dia.call(.1)
		R.robo = mik.g
		await dia.call(.2)
		R.timo = mik.g
		await dia.call(.14)
		R.fuga = ",".join(PackedStringArray(J.S.plantilla.map(func(w): return w.n)))
		J.S.money = 10
		await dia.call(.5)
		R.sin = jn([ike.rol, J.S.money])
		J.S.money = 5000
		J.enter_map("valdehierro", 17, 8, "up")
		R.ar = ",".join(PackedStringArray(J.ents.filter(func(e): return e.id == "arrieta").map(func(e): return "%d,%d" % [e.x, e.y])))
		want(["^Alquilarla"])
		await run(func(): await J.talk_nave())
		R.nave = jn([J.S.nave != null, 5000 - J.S.money])
		want(["^A la nave"])
		await run(func(): await J.trabajo(itz))
		J.S.seeds.ria = int(J.S.seeds.get("ria", 0)) + 1
		R.s0 = J.S.seeds.ria
		want(["^Cambiar", "^" + J.strain("ria").n + "$"])
		await run(func(): await J.talk_nave())
		R.var = jn([J.S.nave.sid, J.S.nave.thc, R.s0 - int(J.S.seeds.get("ria", 0))])
		R.m = J.S.money
		await dia.call(.99)
		R.crece = jn([J.S.nave.g, R.m - J.S.money])
		R.b = J.S.buds.ria.g
		want(["^Recoger"])
		await run(func(): await J.talk_nave())
		R.rec = jn([J.S.buds.ria.g - R.b, J.S.nave.g])
		R.h = J.S.heat
		await dia.call(0)
		R.redada = jn([J.S.nave == null, ",".join(PackedStringArray(J.S.plantilla.map(func(w): return w.n))), J.S.heat - R.h])
		J.S.money = 5000
		want(["^Alquilarla"])
		await run(func(): await J.talk_nave())
		R.m = J.S.money
		want(["^Dejar la nave", "^Dejarla"])
		await run(func(): await J.talk_nave())
		R.dejar = jn([J.S.nave == null, J.S.money - R.m])
		J.S.money = 5000
		want(["^Alquilarla"])
		await run(func(): await J.talk_nave())
		J.S.money = 50
		await dia.call(.5)
		R.impago = jn([J.S.nave == null, J.S.money])
		var l1 := LOG.size()
		want(["<B>"])
		await run(J.movil_menu)
		want(["<B>"])
		await run(J.plantilla)
		R.menus = LOG.slice(l1).filter(func(l): return l.contains(" | Gente | Plantilla | ") or l.ends_with("| Pedir gente a Patxi  → (B)")).size()
		R.ln = J.lot_nombre("ria")
		J.S.plantilla = []
		J.S.plN = 0
		J.S.nave = null
		J.S.money = sv.money
		J.S.heat = sv.heat
		J.S.buds = sv.buds
		J.S.arcon = sv.arcon
		J.S.pots = sv.pots
		J.S.carpas = sv.carpas
		J.S.seeds = sv.seeds
		J.S.sales = sv.sales
		J.S.ch = sv.ch
		J.S.fenos = sv.fenos
		J.S.rec = sv.rec
		J.S.flags.harvest1 = sv.h1
		J.enter_map("home", 5, 5, "up"),
		func():
			var P: Dictionary = D.PLANTILLA
			var N: Dictionary = D.NAVE
			return chk(R.w1 == "Itziar,5,5,5," and R.n2 == 1 and R.w2 == "Mikel,1,1,1," and R.w3 == "Iker,3,3,3," and R.pl == "4,%d" % (4 * int(P.sobre)) and R.calle == "calle,ria,25,75" and R.ops == 1
				and R.venta == jn([22, R.e, P.calor]) and R.arc == R.gc - int(floor(R.gc * P.sisa * 2)) and R.pot == null
				and R.poli == jn([null, true, P.calor + P.calorPoli, P.sueldo.gerente])
				and R.robo == 12 and R.timo == 10 and R.fuga == "Itziar,Iker" and R.sin == ",10" and R.ar == "17,7" and R.nave == jn([true, N.fianza])
				and R.var == jn(["ria", Datos.jsround(J.strain("ria").thc * N.thc * 10) / 10.0, 1]) and R.crece == jn([N.g + 2 * N.gC, N.dia + P.sueldo.nave])
				and R.rec == jn([N.g + 2 * N.gC, 0]) and R.redada == jn([true, "Iker", N.calor])
				and R.dejar == jn([true, N.fianza]) and R.impago == "true,50" and R.menus == 2
				and LOG.has("SMS · PATXI: Te mando a Itziar. Vale oro.") and LOG.has("Mikel se va por donde ha venido. El sobre ya es de Patxi.") and LOG.has("SMS · PATXI: Te mando a Iker. Gente normal del barrio.")
				and LOG.has("SMS · IKER: He cosechado %d g. Está en el arcón." % R.arc) and LOG.has("SMS · MIKEL: Me ha parado la policía. Se han quedado con 22 g de %s. Lo siento." % R.ln)
				and LOG.has("SMS · MIKEL: Me han atracado en un portal. Se han llevado 13 g de %s. Me quedan 12 g." % R.ln) and LOG.has("SMS · MIKEL: Me han pagado 2 g con billetes falsos. No me he dado cuenta hasta el banco.")
				and LOG.has("Mikel no contesta al móvil. Se ha largado con 10 g de %s." % R.ln) and LOG.has("SMS · IKER: Sin cobrar no curro. Cuando tengas el dinero, me llamas.")
				and LOG.has("La policía ha entrado en la nave de Valdehierro. Se lleva las plantas y a Itziar.") and LOG.has("SMS · ARRIETA: No me has pagado la nave. Cambio la cerradura y me quedo la fianza."), R))
	step("El bajo de las setas (1.20): Txomin alquila el bajo de la Kale Zaharra desde el capítulo 4; las bandejas que prepara él (húmedas: cada día pierden; secas o contaminadas, a tirar), 6 días colonizando y 4 fructificando; la cosecha se seca en el bajo y él la compra; el alquiler cada mañana, la redada, el impago y dejarlo", [], func():
		var sv: Dictionary = {"money": J.S.money, "heat": J.S.heat, "sales": J.S.sales, "ch": J.S.ch, "day": J.S.day, "min": J.S.min}
		R = {}
		var dia := func(v: float):
			J.S.day += 1
			Cultivo.fijo = v
			J.setas_dia()
			Cultivo.fijo = -1
			await idle()
		J.S.ch = 3
		J.S.money = 5000
		J.S.heat = 0
		J.S.min = 600
		J.S.setas = null
		J.enter_map("callejon", 17, 9, "up")
		R.tx = ",".join(PackedStringArray(J.ents.filter(func(e): return e.id == "txomin").map(func(e): return "%d,%d" % [e.x, e.y])))
		await run(J.talk_txomin)
		R.antes = J.S.setas
		J.S.ch = 4
		want(["^Alquilarlo"])
		await run(J.talk_txomin)
		R.alq = jn([J.S.setas != null, 5000 - J.S.money])
		want(["^Comprar", "^Comprar", "^Comprar", "^Nada"])
		await run(J.talk_txomin)
		var A: Dictionary = J.S.setas.bandejas[0]
		var B: Dictionary = J.S.setas.bandejas[1]
		var C: Dictionary = J.S.setas.bandejas[2]
		R.b = jn([J.S.setas.bandejas.size(), 5000 - J.S.money])
		R.m = J.S.money
		await dia.call(.5)
		R.d1 = jn([A.hum, J.fase_seta(A), R.m - J.S.money])
		R.min = J.S.min
		want(["^Pulverizar", "^Nada"])
		await run(J.talk_txomin)
		R.pulv = jn([A.hum, B.hum, C.hum, J.S.min - R.min])
		A.hum = 40
		B.hum = 30
		await dia.call(.1)
		R.malas = jn([J.fase_seta(A), J.fase_seta(B), J.fase_seta(C), C.hum])
		want(["^Tirar", "^Nada"])
		await run(J.talk_txomin)
		R.tirar = J.S.setas.bandejas.size()
		J.S.day = C.d + D.SETAS.colon - 1
		R.f1 = J.fase_seta(C)
		J.S.day = C.d + D.SETAS.colon
		R.f2 = J.fase_seta(C)
		J.S.day = C.d + D.SETAS.colon + D.SETAS.fruto
		R.f3 = J.fase_seta(C)
		await run(func():
			Cultivo.fijo = .5
			want(["^Recoger", "^Nada"])
			await J.talk_txomin()
			Cultivo.fijo = -1)
		R.g = J.S.setas.g
		R.quedan = J.S.setas.bandejas.size()
		R.m = J.S.money
		R.h = J.S.heat
		want(["^Venderle", "^Nada"])
		await run(J.talk_txomin)
		R.venta = jn([J.S.money - R.m, J.S.heat - R.h, J.S.setas.g])
		want(["^Comprar", "^Nada"])
		await run(J.talk_txomin)
		R.h = J.S.heat
		await dia.call(0)
		R.redada = jn([J.S.setas == null, J.S.heat - R.h])
		want(["^Alquilarlo"])
		await run(J.talk_txomin)
		J.S.money = 10
		await dia.call(.5)
		R.impago = jn([J.S.setas == null, J.S.money])
		J.S.money = 5000
		want(["^Alquilarlo"])
		await run(J.talk_txomin)
		R.m = J.S.money
		want(["^Dejar el bajo", "^Dejarlo"])
		await run(J.talk_txomin)
		R.dejar = jn([J.S.setas == null, J.S.money - R.m])
		J.S.setas = null
		J.S.money = sv.money
		J.S.heat = sv.heat
		J.S.sales = sv.sales
		J.S.ch = sv.ch
		J.S.day = sv.day
		J.S.min = sv.min
		J.enter_map("home", 5, 5, "up"),
		func():
			var Z: Dictionary = D.SETAS
			return chk(R.tx == "17,8" and R.antes == null and R.alq == jn([true, Z.fianza]) and R.b == jn([3, Z.fianza + 3 * Z.bandeja]) and R.d1 == jn([100 - Z.seca, "colonizando", Z.dia]) and R.pulv == jn([100, 100, 100, Z.min])
				and R.malas == jn(["contaminada", "seca", "colonizando", 100 - Z.seca]) and R.tirar == 1 and R.f1 == "colonizando" and R.f2 == "fructificando" and R.f3 == "lista" and R.g == 33 and R.quedan == 0
				and R.venta == jn([33 * Z.precio, Z.calor, 0]) and R.redada == jn([true, Z.calorRedada]) and R.impago == "true,10" and R.dejar == jn([true, Z.fianza])
				and LOG.has("TXOMIN: ¿Setas? Eso era antes, chaval. Ahora solo paseo.") and LOG.has("SMS · TXOMIN: Se te han echado a perder 2 bandejas. Tíralas.") and LOG.has("Tiras 2 bandejas.")
				and LOG.has("TXOMIN: El bajo: 1 lista · humedad %s %%." % Datos.js_num(100 - Z.seca)) and LOG.has("Recoges las setas y las dejas secando en el bajo: 33 g.")
				and LOG.has("La policía ha entrado en el bajo de la Kale Zaharra. Se lleva las bandejas.") and LOG.has("SMS · TXOMIN: No me has pagado el bajo. Cambio la cerradura; lo de dentro y la fianza, para mí."), R))
	step("Ropa y pelo, Darko y Miren (1.21): en la cama del piso, CAMBIARTE DE ROPA (camiseta, pantalón, gorra y pelo: cambian los colores del protagonista, también de espaldas en el combate; fuera del piso, no sale); Darko pelea con su sprite de combate y Miren lleva el suyo", [], func():
		R = {}
		var l0 := LOG.size()
		var sv = J.S.get("ropa")
		J.S.ropa = {}
		J.enter_map("home", 5, 5, "up")
		want(["^Cambiarte de ropa", "^Camiseta", "^Azul", "^Pelo", "^Rubio", "^Pelo", "^Volver", "^Listo"])
		await run(func(): await J.bed_action())
		R.ropa = jn([J.S.ropa.get("camiseta"), J.S.ropa.get("pelo"), J.S.ropa.get("gorra", 0)])
		var n := func(im: Image, h: String) -> int:
			var v := Datos.hexi(h)
			var k := 0
			for y in im.get_height():
				for x in im.get_width():
					var p := im.get_pixel(x, y)
					if p.a8 and ((p.r8 << 16) | (p.g8 << 8) | p.b8) == v:
						k += 1
			return k
		var f = Atlas.frame_de("player", "base", "south", 0, {"i": 0})
		var c: Image = J.ropa_c(f, "player").c
		R.px = jn([n.call(f.c, "#c83839"), n.call(c, "#c83839"), n.call(c, "#3a6ac8"), n.call(f.c, "#4a2a2b"), n.call(c, "#c8a050"), n.call(f.c, "#e8b894") == n.call(c, "#e8b894")])
		R.comb = J.ropa_mapa("player-combate")[1]
		var r0 = J.S.ropa
		J.S.ropa = {"gorra": 1}   # la gorra roja (1.22): las zapatillas no
		var fc = Atlas.frame_de("player-combate", "base", "north", 0, {"i": 0})
		var cc: Image = J.ropa_c(fc, "player-combate").c
		R.zap = jn([n.call(fc.c, "#5aa860") > 0, n.call(fc.c, "#5aa860") == n.call(cc, "#5aa860"), n.call(cc, "#5aa861"), n.call(cc, "#e06060") == n.call(fc.c, "#5aa861")])
		J.S.ropa = r0
		var b0 = J.B
		J.B = {"kind": "thief", "jefe": 1, "look": D.LOOKS.darko}
		R.darko = J.grupo_combate("E")
		J.B = b0
		R.miren = Atlas.grupo_look(D.LOOKS.miren)
		J.S.map = "txaro"
		want(["^Nada"])
		await run(func(): await J.bed_action("Una cama."))
		var lg := LOG.slice(l0)
		R.log = jn([lg.any(func(l): return l.contains("[menú] Dormir hasta las 7 | Siesta de 3 h | Cambiarte de ropa | Nada")),
			lg.any(func(l): return l.contains("[menú] Camiseta: azul | Pantalón: vaquero | Gorra: verde | Pelo: rubio | Listo")), lg.any(func(l): return l.contains("[menú] Dormir hasta las 7 | Siesta de 3 h | Nada"))])
		J.S.ropa = sv if sv is Dictionary else {}
		J.enter_map("home", 5, 5, "up"),
		func():
			var p: PackedStringArray = str(R.px).split(",")
			return chk(R.ropa == "1,2,0" and int(p[0]) > 0 and int(p[1]) == 0 and p[2] == p[0] and int(p[3]) > 0 and p[4] == p[3] and p[5] == "true" and R.comb == "1002" and R.zap == "true,true,0,true"
				and R.darko == "darko-combate" and R.miren == "miren" and R.log == "true,true,true", R))
	step("Abuela Txaro, en su casa desde el capítulo 4: 10 g de una índica (solo le valen las de 70 % o más) → 3 semillas de Chitral Kush y 3 bocatas", ["^Hindu Kush"], func():
		J.S.ch = 5
		J.S.flags.txaro = true
		J.S.flags.txaro2 = false
		J.S.map = "txaro"
		J.build_ents()
		R = {"ent": donde.call("txaro")}
		J.S.buds = {}
		J.add_buds("ria", 20, 12)
		J.add_buds("hindu", 15, 18)
		J.add_buds("thai", 20, 16)
		R.ch = J.S.seeds.get("chitral", 0)
		R.boc = J.S.items.bocata
		R.rep = J.S.rep
		var l0 := LOG.size()
		await run(J.talk_txaro)
		R.menu = lin.call(l0, "\\[menú\\].*Ahora no")
		J.S.map = "home",
		func(): return chk(R.ent == "6,3" and si(J.S.flags.get("txaro2")) and J.S.seeds.get("chitral") == R.ch + 3 and J.S.items.bocata == R.boc + 3 and J.S.rep == R.rep + 5 and J.S.buds.hindu.g == 5
			and J.S.buds.ria.g == 20 and re("Hindu Kush", R.menu) and not re("Skunk|Thai", R.menu), R))
	step("Astilleros: el gramo, un 20 % más caro; 1 de cada 3 ventas, un chico de Darko te sale al paso", ["Justo", "Justo"], func():
		J.S.ch = 5
		J.S.map = "astilleros"
		J.S.buds = {}
		J.add_buds("ria", 20, 12)
		R = {"b": []}
		J.gancho_combate = func(t): R.b.append(t)
		var cl := func(id: String, r: float) -> Callable:
			var c := {"id": id, "map": "astilleros", "x": 5, "y": 20, "type": "cur", "want": 10, "minThc": 0}
			J.S.clients.append(c)
			return func():
				Cultivo.fijo = r
				await J.talk_client(c)
				Cultivo.fijo = -1
		R.m = J.S.money
		await run(cl.call("cx1", .2))
		R.m1 = J.S.money - R.m
		R.b1 = R.b.size()
		await run(cl.call("cx2", .5))
		R.m2 = J.S.money - R.m - R.m1
		J.gancho_combate = Callable()
		J.S.map = "home",
		func(): return chk(R.m1 == Datos.jsround(J.precio_calle(12) * D.CTYPES.cur.mult * 1.2 * 10) and R.m2 == R.m1 and R.b1 == 1 and ",".join(R.b) == "thief" and D.ZONAS.astilleros.precio == 1.2, R))
	step("Rosin: la prensa de Kiko (250 €, capítulo 3); en la mesa, 25 g de Skunk #1 al 12 % → 5 g de rosin al 36 % en media hora; catadores en 4 zonas; uno paga 10 + 0,6 × THC el gramo", ["Prensa de rosin", "Salir", "Prensar rosin", "^Skunk", "^25 g", "Rebaja"], func():
		J.S.ch = 5
		J.S.money = 1000
		J.S.buds = {}
		J.S.rosin = {}
		J.S.items.prensa = 0
		J.add_buds("ria", 40, 12)
		await run(J.shop)
		R = {"m": J.S.money, "p": J.S.items.prensa, "min": J.S.min}
		J.S.map = "home"
		await run(J.lab_action)
		R.min = J.S.min - R.min
		R.ros = J.S.rosin.duplicate(true)
		R.g = J.total_buds()
		J.S.clientsDay = 0
		J.spawn_clients()
		R.ext = ",".join(J.S.clients.filter(func(c): return c.type == "ext").map(func(c): return c.map))
		J.S.map = "town"
		var c := {"id": "cx9", "map": "town", "x": 5, "y": 20, "type": "ext", "want": 2, "minThc": 0}
		J.S.clients.append(c)
		R.m1 = J.S.money
		await run(func(): await J.talk_client(c))
		R.m1 = J.S.money - R.m1
		R.r = J.total_rosin()
		R.h = J.S.heat
		J.S.map = "home",
		func(): return chk(R.m == 750 and R.p == 1 and R.ros.ria.g == 5 and R.ros.ria.thc == 36 and R.g == 15 and R.min == 30 and R.ext == "town,town,astilleros,puerto,valdehierro,ibarbide,ensanche"
			and R.m1 == Datos.jsround(J.precio_rosin(36) * 2 * .85) and R.r == 3 and D.GLYPH.has("gota") and D.CTYPES.ext.label == "CATADOR", R))
	step("Rosin a salvo: la caja lo guarda y lo saca (en el hueco de los cogollos); Darko (con 21 g de rosin = 105 g de flor) se lleva la mitad del de fuera y la caja, intacta; la redada, el de fuera (la caja nunca); el rosin atrae ladrones (1 g = 5 g de flor)",
		["Guardar rosin", "^Rosin · Skunk", "^1 g", "Guardar todo", "Sacar rosin", "^Rosin · Skunk", "^1 g", "Cerrar", "Dormir"], func():
		var sv := {"ch": J.S.ch, "robo": J.S.flags.get("robo"), "money": J.S.money, "caja": J.S.caja.duplicate(true), "due": J.S.due, "heat": J.S.heat}
		J.S.map = "home"
		J.S.ch = 7
		J.S.flags.robo = false
		J.S.due = 0
		J.S.money = 0
		J.S.heat = 0
		J.S.buds = {}
		J.S.rosin = {}
		vacia.call()
		J.add_rosin("ria", 3, 36)
		J.add_rosin("hindu", 2, 40)
		J.S.caja.money = 0
		J.S.caja.buds = {}
		J.S.caja.erase("rosin")
		var l0 := LOG.size()
		await run(func(): await J.object_action(7, 1))
		R = {"caja": norm(J.S.caja.rosin), "fuera": norm(J.S.rosin), "cr": J.caja_r(), "txt": "|".join(LOG.slice(l0).filter(func(l): return re("Guardas", l)))}
		J.add_rosin("hindu", 20, 40)
		R.flor = J.gramos_flor()
		J.S.min = 23 * 60
		var l1 := LOG.size()
		await run(J.bed_action)
		R.robo = J.S.flags.robo
		R.f2 = norm(J.S.rosin)
		R.c2 = J.caja_r()
		R.dk = "|".join(LOG.slice(l1).filter(func(l): return re("Se han llevado", l)))
		J.S.protect = false
		Cultivo.fijo = .1
		var l2 := LOG.size()
		await run(J.raid_event)
		Cultivo.fijo = -1
		R.c3 = J.S.caja.has("rosin")
		R.f3 = J.total_rosin()
		R.rd = "|".join(LOG.slice(l2).filter(func(l): return re("ni la ven", l)))
		J.S.money = 0
		J.S.buds = {}
		J.S.rosin = {}
		J.add_rosin("ria", 1, 36)
		R.l1 = enc.call()
		J.S.rosin = {}
		J.add_rosin("ria", .9, 36)
		R.l0 = enc.call()
		J.S.rosin = {}
		J.S.ch = sv.ch
		J.S.flags.robo = sv.robo
		J.S.money = sv.money
		J.S.caja = sv.caja
		J.S.due = sv.due
		J.S.heat = sv.heat,
		func(): return chk(R.caja.ria.g == 2 and R.caja.hindu.g == 2 and R.fuera.ria.g == 1 and not R.fuera.has("hindu") and R.cr == 4 and re("Guardas 0 € y 4 g de rosin\\.", R.txt)
			and R.flor == 105 and R.robo and R.f2.ria.g == .5 and R.f2.hindu.g == 10 and R.c2 == 4 and re("Se han llevado 0 € y 10,5 g de rosin\\.", R.dk)
			and R.c3 and R.f3 == 0 and R.rd != "" and R.l1 == 20 and R.l0 == 0, R))
	step("Autobús perdido: en Errotabarri a las 23:50, esperar → a las 7:00 del día siguiente sale el primero; en Mendialde, dormir en casa de ama (sin robo de Darko)",
		["Esperar", "^Ribera Verde", "Dormir"], func():
		var sv := {"ch": J.S.ch, "robo": J.S.flags.get("robo"), "money": J.S.money, "due": J.S.due}
		var pa: Dictionary = D.PARADAS.errotabarri
		var v: Dictionary = J.viaje("errotabarri", "town")
		J.S.ch = 7
		J.S.flags.robo = false
		J.S.due = 0
		J.S.money = 3000
		vacia.call()
		J.enter_map("errotabarri", int(pa.a[0]), int(pa.a[1]), pa.a[2])
		J.S.min = 23 * 60 + 50
		R = {"d": J.S.day}
		await run(func(): await J.object_action(int(pa.x), int(pa.y)))
		R.d1 = J.S.day - R.d
		R.min = J.S.min
		R.map = J.S.map
		R.m = J.S.money
		R.v = v
		J.enter_map("casa-ama", 1, 3, "left")
		J.S.min = 22 * 60
		R.d2 = J.S.day
		await run(func(): await J.object_action(0, 3))
		R.d3 = J.S.day - R.d2
		R.min2 = J.S.min
		R.robo = J.S.flags.robo
		R.hp = J.S.hp == J.S.hpMax
		J.enter_map("home", 5, 6, "up")
		J.S.ch = sv.ch
		J.S.flags.robo = sv.robo
		J.S.money = sv.money
		J.S.due = sv.due,
		func(): return chk(R.d1 == 1 and R.min == 7 * 60 + R.v.min and R.map == "town" and R.m == 3000 - R.v.eur and R.d3 == 1 and R.min2 == 7 * 60 and not R.robo and R.hp, R))
	step("Patrullas: andan solo por la calle; la sospecha sube si te ven con algo (50 g: 14/s de día, 35 de noche, 5,6 con Molina; nada a la espalda ni sin nada encima); llena → te persiguen → control", ["ENTREGAR"], func():
		J.S.ch = 5
		J.S.protect = false
		J.S.heat = 0
		J.S.min = 600
		J.S.buds = {}
		J.S.rosin = {}
		J.S.clients = []
		J.enter_map("town", 16, 17, "up")
		var pat := func() -> Array: return J.ents.filter(func(e): return e.get("pat"))
		var vis := []
		R = {}
		for t in 1200:
			J.update_patrullas(50)
			if t % 20 == 0:
				for e in pat.call():
					vis.append("%d,%d" % [e.x, e.y])
		R.calle = vis.all(func(k):
			var xy: PackedStringArray = k.split(",")
			return J.re_calle().search(J.MAPS.town.g[int(xy[1])][int(xy[0])]) != null)
		R.traza = " ".join(vis)
		R.v0 = J.SOSP.v
		var sitios := {}
		for k in vis:
			sitios[k] = 1
		R.sitios = sitios.size()
		var mira := func(noche: bool, prot: bool, dir: String) -> float:
			J.S.min = 1380 if noche else 600
			J.S.protect = prot
			J.reset_sosp()
			J.pon_patrullas()
			var ps: Array = pat.call()
			var e: Dictionary = ps[0]
			e.merge({"x": 16, "y": 14, "fx": 16, "fy": 14, "px": 256.0, "py": 224.0, "dir": dir, "moving": false, "espera": 1e9, "caza": false}, true)
			for o in ps.slice(1):
				o.merge({"x": 1, "y": 1, "fx": 1, "fy": 1, "moving": false, "espera": 1e9}, true)
			J.P.merge({"x": 16, "y": 17, "fx": 16, "fy": 17, "moving": false}, true)
			J.update_patrullas(1000)
			return Datos.jsround(J.SOSP.v * 100) / 100.0
		R.sinNada = mira.call(false, false, "down")
		J.add_buds("ria", 50, 12)
		R.dia = mira.call(false, false, "down")
		R.noche = mira.call(true, false, "down")
		R.molina = mira.call(false, true, "down")
		R.espalda = mira.call(false, false, "up")
		J.S.buds = {}
		J.S.rosin = {"ria": {"g": 2, "thc": 36}}
		R.rosin = mira.call(false, false, "down")
		J.S.rosin = {}
		J.add_buds("ria", 50, 12)
		mira.call(false, false, "down")
		var t := 1000
		while t < 20000 and J.is_free():
			J.update_patrullas(50)
			t += 50
		R.t = t
		R.al = J.SOSP.alarma,
		func(): return chk(R.calle and R.sitios >= 20 and R.v0 == 0 and R.sinNada == 0 and R.dia == 14 and R.noche == 35 and R.molina == 5.6 and R.espalda == 0 and R.rosin == 8.24
			and R.t > 7000 + D.PAT.alto and R.t < 9000 + D.PAT.alto and J.S.buds.is_empty() and J.SOSP.tregua == D.PAT.tregua and R.al == null and R.traza.split(" ").size() == 60, R))
	step("Patrullas: con la alarma te pierde a más de 10 casillas y 4 s sin verte (la sospecha se queda en 50); por una puerta, al momento; vender a 5 casillas o menos de un agente, aunque no mire: +60", [], func():
		J.S.ch = 5
		J.S.min = 600
		J.S.buds = {}
		J.add_buds("ria", 50, 12)
		J.enter_map("town", 16, 17, "up")
		var una := func() -> Dictionary: return J.ents.filter(func(e): return e.get("pat"))[0]
		var e: Dictionary = una.call()
		e.merge({"x": 16, "y": 14, "fx": 16, "fy": 14, "dir": "down", "moving": false}, true)
		J.alarma(e)
		J.P.merge({"x": 37, "y": 26, "fx": 37, "fy": 26}, true)
		R = {"a": J.SOSP.alarma}
		var t := 0
		while t < 30000 and J.SOSP.alarma != null:
			J.update_patrullas(50)
			t += 50
		R.t = t
		R.v = J.SOSP.v
		R.d = absi(e.x - J.P.x) + absi(e.y - J.P.y)
		J.enter_map("town", 16, 17, "up")
		e = una.call()
		J.alarma(e)
		var k := ""
		for kk in J.MAPS.town.doors:
			if J.MAPS.town.doors[kk].to == "home" and k == "":
				k = kk
		await run(func(): await J.warp(J.MAPS.town.doors[k]))
		R.puerta = "%s,%s,%s" % [J.S.map, J.SOSP.alarma if J.SOSP.alarma != null else "", Datos.js_num(J.SOSP.v)]
		J.enter_map("town", 16, 17, "up")
		e = una.call()
		e.merge({"x": 16, "y": 14, "fx": 16, "fy": 14, "dir": "up", "moving": false}, true)
		J.visto_vender()
		R.vende = J.SOSP.v
		J.S.map = "mendialde"
		R.pueblo = J.n_patrullas()
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.a == "pat0" and R.t == 4000 and R.v == 50 and R.d > 10 and R.puerta == "home,,0" and R.vende == 60 and R.pueblo == 0, R))
	step("Patrullas: fuera de la calle (tras una caza por el parque) vuelve a ella y sigue la ronda; si al amanecer se va el agente que te seguía, lo has despistado (sospecha 50)", [], func():
		J.S.ch = 5
		J.S.min = 600
		J.S.buds = {}
		J.S.rosin = {}
		J.enter_map("town", 16, 17, "up")
		var pats := func() -> Array: return J.ents.filter(func(e): return e.get("pat"))
		var e: Dictionary = pats.call()[0]
		R = {"g": J.MAPS.town.g[16][2]}
		e.merge({"x": 2, "y": 16, "fx": 2, "fy": 16, "px": 32.0, "py": 256.0, "moving": false, "espera": 0.0, "caza": false, "pasos": 1000000000}, true)
		var calle := func(x: int, y: int) -> bool: return J.re_calle().search(J.MAPS.town.g[y][x]) != null
		var t := 0
		while t < 20000 and not calle.call(e.x, e.y):
			J.update_patrullas(50)
			t += 50
		R.t = t
		R.en = "%d,%d" % [e.x, e.y]
		for i in 100:
			J.update_patrullas(50)
		R.sigue = "%d,%d" % [e.x, e.y] != R.en and calle.call(e.x, e.y)
		J.S.min = 359
		J.reset_sosp()
		J.enter_map("town", 16, 17, "up")
		R.n = pats.call().size()
		for o in pats.call():
			if o.id == "pat1":
				J.alarma(o)
		J.S.min = 360
		J.update_patrullas(50)
		R.alba = "%d,%s,%s" % [pats.call().size(), J.SOSP.alarma if J.SOSP.alarma != null else "", Datos.js_num(J.SOSP.v)]
		J.S.min = 600
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(J.re_calle().search(R.g) == null and R.t > 0 and R.t <= 3000 and R.sigue and R.n == 2 and R.alba == "1,,50", R))
	step("Goteo (1.10): el depósito riega solo lo que baja del 50 %, gasta la mitad de los litros de la maceta por cada 100 % y, vacío, no riega; se rellena desde la carpa", ["Rellenar depósito"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"carpas": [{"t": "m100", "foco": "sodio400", "goteo": true, "dep": 10}], "macetas": ["plastico7", "plastico7", "plastico7", "plastico7"], "pots": [null, null, null, null]}, true)
		var i := 1
		var p := {"sid": "ria", "prog": .3, "water": 40, "health": 100, "fert": false, "pest": false}
		var l: float = D.MACETAS[J.S.macetas[i]].l * .5
		J.S.pots[i] = p
		Cultivo.regar_goteo(J.S, p, i)
		R = {"w1": p.water, "d1": J.S.carpas[0].dep, "e1": Datos.jsround((10 - l * .6) * 100) / 100.0}
		J.S.carpas[0].dep = 1
		p.water = 40
		Cultivo.regar_goteo(J.S, p, i)
		R.w2 = p.water
		R.e2 = 40 + 1 / (l * .6) * 60
		R.d2 = J.S.carpas[0].dep
		p.water = 45
		Cultivo.regar_goteo(J.S, p, i)
		R.w3 = p.water
		p.water = 50.1
		J.S.carpas[0].dep = 50
		J.plants_advance(10)
		R.w4 = p.water
		R.d4 = J.S.carpas[0].dep
		await run(func(): await J.carpa_action(0))
		R.d5 = J.S.carpas[0].dep
		R.gl = Cultivo.goteo_l(J.S, 0)
		J.S = S0,
		func(): return chk(R.w1 == 100 and R.d1 == R.e1 and absf(R.w2 - R.e2) < 1e-9 and R.d2 == 0 and R.w3 == 45 and R.w4 == 100 and R.d4 < 50 and R.d5 == R.gl and R.gl == 650, R))
	# con el azar fijo (sin plagas): una cosecha de Hindu Kush en la carpa de 100 con LED 480 W y 4 macetas de 25 L
	step("Riego en dos niveles (1.10): las garrafas (15 €) se vacían hacia media cosecha y se rellenan; el goteo (1.200 €, capítulo 4) devuelve las garrafas a la mochila y dura unas cinco cosechas con la carpa llena", ["Rellenar garrafas", "Poner goteo"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		Cultivo.fijo = .99
		J.S.merge({"day": 1, "min": 600, "sala": {}, "carpas": [{"t": "m100", "foco": "led480", "garrafas": true, "gar": []}], "macetas": ["tela25", "tela25", "tela25", "tela25"]}, true)
		var nueva := func():
			J.S.pots = []
			for m in J.S.macetas:
				J.S.pots.append({"sid": "hindu", "prog": 0, "water": 100, "health": 100, "fert": false, "pest": false})
		var crece := func():
			for p in J.S.pots:
				if not p.get("dead") and p.prog < 1:
					return true
			return false
		# la primera garrafa que se vacía marca hv; desde ahí se rellenan cada hora para medir la cosecha entera (h)
		nueva.call()
		var ga: Array = Cultivo.garrafas_carpa(J.S, 0)
		R = {"cap": "%s,%s" % [Datos.js_num(ga[0]), Datos.js_num(ga[1])], "g1": 1e9}
		var h := 0
		var hv := 0
		var gv = null
		while crece.call() and h < 2000:
			J.plants_advance(60)
			h += 1
			if hv == 0:
				for i in J.S.pots.size():
					if Cultivo.garrafa(J.S, i) <= 0:
						hv = h
						R.g1 = Cultivo.garrafas_carpa(J.S, 0)[0]
						gv = J.S.carpas[0].gar.duplicate()
						break
			if hv:
				J.S.carpas[0].gar = []
		R.gar = float(hv) / h
		R.muertas = 0
		for p in J.S.pots:
			if p.get("dead"):
				R.muertas += 1
		J.S.carpas[0].gar = gv if gv != null else []
		await run(func(): await J.carpa_action(0))
		ga = Cultivo.garrafas_carpa(J.S, 0)
		R.g2 = "%s,%s" % [Datos.js_num(ga[0]), Datos.js_num(ga[1])]
		J.S.items.x_goteo = 1
		J.S.items.x_garrafas = 0
		await run(func(): await J.carpa_action(0))
		R.vu = "%s,%s,%s,%s" % [Datos.js_num(J.S.items.x_garrafas), "true" if J.S.carpas[0].get("garrafas") else "false", "true" if J.S.carpas[0].has("gar") else "false", Datos.js_num(J.S.carpas[0].dep)]
		R.cos = 0
		while R.cos < 20:
			nueva.call()
			var k := 0
			while crece.call() and k < 2000:
				J.plants_advance(60)
				k += 1
			if J.S.carpas[0].dep <= 0:
				break
			R.cos += 1
		var gt := 0
		for it in D.SHOP:
			if it.get("extra") == "goteo":
				gt = it.ch
		R.precios = "%d,%d,%d" % [pr("Garrafas"), pr("Riego por goteo"), gt]
		Cultivo.fijo = -1
		J.S = S0,
		func(): return chk(R.cap == "64,64" and R.gar >= .4 and R.gar <= .6 and R.g1 < 64 and R.muertas == 0 and R.g2 == "64,64" and R.vu == "1,false,false,650" and R.cos >= 4 and R.cos <= 6 and R.precios == "15,1200,4", R))
	step("Clima de la sala (1.10): enero, de día con sodio 400 W (+4 °C) y de noche (frío: crecen −18 %); con LED casi no calienta; termohigrómetro, calefactor y deshumidificador del growshop, su factura de noche; moho en floración y su aviso al despertar (julio, de noche)", ["Termohigrómetro", "Calefactor", "Deshumidificador", "Salir"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"ch": 5, "money": 1000, "sala": {}, "day": 10, "carpas": [{"t": "m100", "foco": "sodio400"}], "macetas": ["plastico7", "plastico7", "plastico7", "plastico7"]}, true)
		var pots := []
		for m in J.S.macetas:
			pots.append({"sid": "ria", "prog": .8, "water": 100, "health": 90, "fert": false, "pest": false})
		J.S.pots = pots
		R = {"mes": D.MESES[Cultivo.mes_de(int(J.S.day))], "dia": Cultivo.clima_sala(J.S, false), "noche": Cultivo.clima_sala(J.S, true)}
		R.f = Cultivo.f_clima(R.noche)
		J.S.min = 23 * 60
		R.c0 = J.factores(0).crec
		R.cc0 = Cultivo.clima_carpa(J.S, 0, true)
		J.S.carpas[0].foco = "led480"
		R.led = Cultivo.clima_sala(J.S, false).t
		J.S.carpas[0].foco = "sodio400"
		await run(J.shop)
		R.m = J.S.money
		R.sala = ",".join(J.S.sala.keys())
		R.n2 = Cultivo.clima_sala(J.S, true)
		R.d2 = Cultivo.clima_sala(J.S, false)
		R.c1 = J.factores(0).crec
		R.cc1 = Cultivo.clima_carpa(J.S, 0, true)
		R.fs = Cultivo.factura_sala(J.S)
		var p: Dictionary = J.S.pots[0]
		var f: Dictionary = J.factores(0).duplicate()
		f.merge({"hr": 70, "plaga": 0}, true)
		Cultivo.plant_step(J.S, p, 1, f)
		R.moho = p.health
		J.S.day = 4
		J.S.sala = {}
		R.julio = Cultivo.clima_sala(J.S, true).hr
		var l0 := LOG.size()
		await run(func(): await J.aviso_plaga([]))
		R.aviso = "|".join(LOG.slice(l0).filter(func(l): return l.begins_with("Moho")))
		J.S = S0,
		func(): return chk(R.mes == "enero" and R.dia.t == 22 and R.dia.hr == 49 and R.noche.t == 15 and R.noche.hr == 58 and absf(R.f - .82) < 1e-9 and R.led == 19.9
			and R.m == 1000 - pr("Termohigrómetro") - pr("Calefactor") - pr("Deshumidificador") and R.sala == "termo,calef,deshu" and R.n2.t == 20 and R.n2.hr == 55 and si(R.n2.uso.get("calef")) and si(R.n2.uso.get("deshu")) and not si(R.d2.uso.get("calef"))
			and R.cc0.hr == R.noche.hr + 4 * D.HR_CARPA and R.cc0.t == R.noche.t and absf(R.c1 / R.c0 - Cultivo.f_clima(R.cc1) / Cultivo.f_clima(R.cc0)) < 1e-9 and R.c1 > R.c0 and R.fs == Datos.jsround((1500 + 250) * D.H_24 * (1 - D.H_DIA) * .5 / 1000 * D.KWH) and R.moho == 90 and R.julio == 55 + 8 + 5
			and re("^Moho en .*\\(plaza 1\\), .* y .*\\(plaza 4\\): de noche la carpa pasa del 60 % de humedad\\.", R.aviso), R))
	step("Accesorios (1.11): la carpa de 120 con sodio 600 pide 525 m³/h; sin extractor huele (+2) y se cuece; el de 125 se queda corto (huele +1), el de 150 lo devuelve a la mochila y con intractor rinde entero; el ventilador; abono de crecimiento sin pH− (la mitad), de floración a ojo (×0,75) y, con medidor, la EC y el pH", ["Abonar", "Abonar", "Abonar"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"day": 4, "min": 12 * 60, "sala": {}, "carpas": [{"t": "m120", "foco": "sodio600"}], "macetas": ["tela25", "tela25", "tela25", "tela25", "tela25", "tela25"]}, true)
		var pots := []
		for m in J.S.macetas:
			pots.append({"sid": "ria", "prog": .8, "water": 100, "health": 100, "fert": false, "pest": false})
		J.S.pots = pots
		J.S.items.merge({"x_filtro": 1, "x_filtro150": 1, "x_intra": 1, "x_vent": 1, "fert": 1, "fertv": 1, "phm": 0, "medidor": 0}, true)
		var cc := func() -> Dictionary: return Cultivo.clima_carpa(J.S, 0, false)
		var sala := Cultivo.clima_sala(J.S, false)
		R = {"pide": Cultivo.caudal_pide(J.S, 0), "e0": Cultivo.ext_carpa(J.S, 0), "c0": cc.call(), "o0": J.olor_dia(), "dt": cc.call().t - sala.t, "dh": cc.call().hr - sala.hr}
		R.k1 = J.poner_extra(0, "filtro")
		R.e1 = Cultivo.ext_carpa(J.S, 0)
		R.o1 = J.olor_dia()
		R.k2 = J.poner_extra(0, "filtro150")
		R.e2 = Cultivo.ext_carpa(J.S, 0)
		R.o2 = J.olor_dia()
		R.x = [J.S.items.x_filtro, J.S.items.x_filtro150, si(J.S.carpas[0].get("filtro"))]
		J.poner_extra(0, "intra")
		R.e3 = Cultivo.ext_carpa(J.S, 0)
		R.c3 = cc.call()
		R.f0 = J.factores(0)
		J.poner_extra(0, "vent")
		R.f1 = J.factores(0)
		J.S.pots[0].prog = .3
		J.S.pots[1].prog = .3
		await run(func(): await J.pot_action(0))
		R.p0 = J.S.pots[0].fv
		J.S.items.phm = 2
		await run(func(): await J.pot_action(1))
		R.p1 = [J.S.pots[1].fert, J.S.pots[1].fq, J.S.items.phm, J.S.items.fert]
		J.S.items.medidor = 1
		J.S.items.fert = 1
		await run(func(): await J.pot_action(2))
		R.p2 = [J.S.pots[2].fq, J.abono_txt(J.S.pots[2]), J.abono_txt(J.S.pots[1]), J.abono_txt(J.S.pots[0])]
		R.g = [Cultivo.gramos_planta(J.S, J.S.pots[1], R.f1), Cultivo.gramos_planta(J.S, J.S.pots[2], R.f1)]
		R.txt = Cultivo.ext_txt(J.S, 0)
		J.S = S0,
		func(): return chk(R.pide == 525 and R.e0 == 0 and R.o0 == 2 and absf(R.dt - 9) < 1e-9 and R.dh == 9 and R.k1 == "" and absf(R.e1 - 400.0 / 525 * D.INTRA) < 1e-9 and R.o1 == 1
			and R.k2 == "filtro" and absf(R.e2 - D.INTRA) < 1e-9 and R.o2 == 0 and str(R.x[0]) + "," + str(R.x[1]) + "," + str(R.x[2]).to_lower() == "1,0,false" and R.e3 == 1 and R.c3.t < R.c0.t and R.c3.hr < R.c0.hr
			and absf(R.f1.crec / R.f0.crec - 1.03) < 1e-9 and R.f1.moho == .5 and R.f0.moho == 1 and R.p0 == .5 and R.p1[0] == true and R.p1[1] == .75 and R.p1[2] == 1 and R.p1[3] == 0
			and R.p2[0] == 1 and R.p2[1] == "Abonada (floración) · EC 1,3 · pH 6,2" and R.p2[2] == "Abonada (floración) · EC 1,3 · pH 6,6" and R.p2[3] == "Abonada (crecimiento) · EC 1,1 · pH 7,5"
			and R.g[0] < R.g[1] and R.txt == "Extractor 150 mm: 750 de 525 m³/h", R))
	step("Temporizador (1.10): 18/6 deja la planta en vegetativo (madre) y gasta más luz; 12/12 acorta el vegetativo y la cosecha; automático quita c.ciclo", ["18/6", "12/12", "Automático"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"carpas": [{"t": "m100", "foco": "led480"}], "macetas": ["tela25", "tela25", "tela25", "tela25"], "pots": [null, null, null, null]}, true)
		R = {"l0": J.luz_carpa(0)}
		var crece := func() -> Dictionary:
			var q := {"sid": "rif", "prog": .3, "water": 100, "health": 100, "fert": false, "pest": false}
			J.S.pots[0] = q
			var f: Dictionary = J.factores(0).duplicate()
			f.merge({"plaga": 0, "hr": 50}, true)
			for h in 30:
				q.water = 100
				Cultivo.plant_step(J.S, q, 1, f)
			return q
		R.a = crece.call().prog
		await run(func(): await J.temporizador(0))
		R.c1 = J.S.carpas[0].get("ciclo")
		R.l1 = J.luz_carpa(0)
		R.m = crece.call().prog
		await run(func(): await J.temporizador(0))
		R.c2 = J.S.carpas[0].get("ciclo")
		R.l2 = J.luz_carpa(0)
		var p: Dictionary = crece.call()
		R.fl = [p.prog, float(p.get("corta", 0))]
		var p0 := p.duplicate()
		p0.corta = 0
		R.g = [J.gramos_planta(p, J.factores(0)), J.gramos_planta(p0, J.factores(0))]
		await run(func(): await J.temporizador(0))
		R.c3 = J.S.carpas[0].has("ciclo")
		J.S = S0,
		func(): return chk(R.l1 > R.l0 and R.l0 > R.l2 and R.c1 == "veg" and absf(R.m - D.VEG_TOPE) < 1e-9 and R.a > .65 and R.c2 == "flor" and R.fl[0] > R.a and R.fl[1] > .9 and R.g[0] < R.g[1] * .65 and R.c3 == false, R))
	step("Salón (1.10): en el ordenador de la tía, la tienda online → el sofá y la tele llegan mañana (lo que no llega de fuera, de la caja); el sofá, una cabezada (+5 de vida); la tele, las noticias según el calor",
		["Tienda online", "^Sofá", "^Tele", "Salir", "Echar", "Noticias"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.erase("muebles")
		J.S.merge({"money": 500, "caja": {"nivel": 1, "money": 1000, "buds": {}, "rosin": {}}, "heat": 40, "hp": 10, "map": "home"}, true)
		J.montar_casa()
		var h: Dictionary = J.MAPS.home
		R = {"libre": not J.tile_solid(h, 13, 5), "d": J.S.day}
		await run(func(): await J.pc_action())
		R.m = [J.S.money, J.S.caja.money]
		R.ped = [J.S.muebles.get("sofa"), J.S.muebles.get("tv"), J.S.muebles.has("gpc")]
		J.S.day += 1
		J.llega_mueble()
		await idle()
		R.ya = ",".join(J.muebles_ya())
		R.solido = J.tile_solid(h, 13, 5) and h.o[5][14] == "sofa2" and h.o[2][14] == "tv2"
		await run(func(): await J.object_action(14, 5))
		R.hp = J.S.hp
		await run(func(): await J.object_action(13, 2))
		J.S = S0
		J.montar_casa()
		R.vacio = not h.o[5][13],
		func(): return chk(R.libre and R.m[0] == 0 and R.m[1] == 652 and R.ped[0] == R.d + 1 and R.ped[1] == R.d + 1 and R.ped[2] == false and R.ya == "sofa,tv" and R.solido and R.hp == 15 and R.vacio
			and LOG.any(func(l): return l.contains("Llega el mensajero con el sofá y la tele")) and LOG.any(func(l): return l.contains("Noticias: detenido en el puerto")), R))
	step("Patinete y bici (1.13): por la tienda online, llegan mañana; en la calle vas montado en el mejor (la bici), más rápido que corriendo y con B más aún; en casa, a pie",
		["Tienda online", "^Patinete", "^Bici", "Salir"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.erase("veh")
		J.S.merge({"money": 500, "map": "home"}, true)
		R = {"d": J.S.day}
		await run(func(): await J.pc_action())
		R.m = J.S.money
		R.ped = [J.S.veh.get("patinete"), J.S.veh.get("bici")]
		J.S.map = "town"
		R.antes = J.vehiculo()
		J.S.day += 1
		J.llega_mueble()
		await idle()
		R.v = J.vehiculo()
		J.held.B = false
		R.p = J.paso_ms()
		J.held.B = true
		R.pb = J.paso_ms()
		J.held.B = false
		J.S.map = "home"
		R.casa = [J.vehiculo(), J.paso_ms()]
		J.S = S0,
		func(): return chk(R.m == 500 - J.D.VEHICULOS.patinete.p - J.D.VEHICULOS.bici.p and R.ped[0] == R.d + 1 and R.ped[1] == R.d + 1 and R.antes == null and R.v == "bici"
			and R.p == J.D.VEHICULOS.bici.paso[0] and R.pb == J.D.VEHICULOS.bici.paso[1] and R.p < 130 and R.casa[0] == null and R.casa[1] == 240
			and LOG.any(func(l): return l.contains("Llega el mensajero con el patinete y la bici")), R))
	step("Carro de esquejes (1.11): Kiko lo vende (no la tienda online) y lo sube mañana delante de las carpas; en la tabla de corte se pinchan los del propagador; en las bandejas aguantan CARRO.dias y gastan luz; se plantan desde ahí; la redada se los lleva",
		["Carro de esquejes", "Salir", "Pinchar esquejes", "^Esqueje"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.erase("muebles")
		J.S.merge({"money": 500, "map": "home", "esquejes": [], "bandejas": [], "heat": 0, "due": 0, "protect": false}, true)
		for k in J.S.items:
			if k.begins_with("m_"):
				J.S.items[k] = 0
		J.montar_casa()
		var h: Dictionary = J.MAPS.home
		R = {"libre": not J.tile_solid(h, 8, 5), "d": J.S.day, "online": ",".join(D.MUEBLES.keys().filter(func(k): return not D.MUEBLES[k].get("grow")))}
		await run(func(): await J.shop())
		R.m = J.S.money
		R.ped = J.S.muebles.get("carro")
		J.S.day += 1
		J.llega_mueble()
		await idle()
		R.ya = J.carro_ya()
		R.solido = J.tile_solid(h, 8, 5) and h.o[5][9] == "carro2"
		var f := {"id": 9997, "t": 1, "y": 1, "i": 50}
		J.S.esquejes = []
		for q in 3:
			J.S.esquejes.append({"sid": "limon", "f": f.duplicate(), "dia": J.S.day - 1})
		R.l0 = J.factura_luz()
		await run(func(): await J.object_action(9, 5))
		R.n = "%d,%d,%s" % [J.S.esquejes.size(), J.S.bandejas.size(), str(J.S.bandejas.all(func(e): return e.dia == J.S.day)).to_lower()]
		R.l1 = J.factura_luz() - R.l0
		J.S.day += D.CARRO.dias - 1
		J.new_day()
		await idle()
		R.dura = J.S.bandejas.size()
		J.S.pots[0] = null
		await run(func(): await J.pot_action(0))
		R.pot = J.S.pots[0] != null and Datos.js_num(J.S.pots[0].f.id) == "9997" and J.S.pots[0].prog == .12
		R.queda = J.S.bandejas.size()
		J.S.bandejas.append({"sid": "limon", "f": f.duplicate(), "dia": J.S.day - 1})
		J.new_day()
		await idle()
		R.seca = ",".join(J.S.bandejas.map(func(e): return Datos.js_num(e.dia)))
		await run(J.raid_event)
		R.redada = J.S.bandejas.size()
		J.S = S0
		J.montar_casa()
		R.vacio = not h.o[5][8],
		func(): return chk(R.libre and R.online == "sofa,tv,gpc,sillon,cuadro,cartel,alfombra" and R.m == 500 - D.CARRO.p and R.ped == R.d + 1 and R.ya and R.solido and R.n == "0,3,true" and R.l1 == 4
			and R.dura == 3 and R.pot and R.queda == 2 and R.seca == Datos.js_num(R.d + D.CARRO.dias) and R.redada == 0 and R.vacio
			and LOG.any(func(l): return l.contains("Kiko te sube el carro de esquejes")), R))
	step("Cama (1.11): la siesta que no pasa de las 12 no cobra la luz; dormir hasta las 7 pasando la medianoche cobra el día y lo dice", ["Siesta", "Dormir hasta las 7"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"ch": 5, "map": "home", "money": 5000, "heat": 0, "due": 0, "protect": false, "esquejes": [], "bandejas": [], "muebles": {},
			"carpas": [{"t": "m100", "foco": "sodio400", "filtro": true, "goteo": true, "dep": 60}], "macetas": ["plastico7", "plastico7", "plastico7", "plastico7"]}, true)
		J.S.pots = []
		for q in 4:
			J.S.pots.append({"sid": "ria", "prog": .2, "water": 100, "health": 100, "fert": false, "pest": false, "f": {"id": 9996, "t": 1, "y": 1, "i": 50}})
		var to0 = TO
		TO = []
		capta = true
		J.S.min = 600
		var m: int = J.S.money
		var d: int = J.S.day
		await run(J.bed_action)
		R = {"siesta": TO.back(), "s": m - J.S.money, "s0": J.S.day - d}
		J.S.min = 23 * 60
		m = J.S.money
		d = J.S.day
		TO = []
		await run(J.bed_action)
		R.merge({"d": J.S.day - d, "gasto": m - J.S.money, "t": TO.back(), "luz": J.luz_carpa(0), "min": J.S.min})
		capta = false
		TO = to0
		J.S = S0,
		func(): return chk(R.siesta == "Has descansado · Partida guardada" and R.s == 0 and R.s0 == 0 and R.d == 1 and R.min == 420 and R.gasto >= R.luz and R.gasto > 0
			and R.t.begins_with("Has descansado · Luz −" + Datos.eur(R.gasto)), R))
	step("Plantas con nombre (1.11): la nº de su fenotipo; «Nombrar» le pone nombre y lo heredan sus esquejes; B cancela y vacío lo quita; en la mochila se tiran esquejes y semillas (una o todas)",
		["Nombrar", "=Madre Lima", "Sacar esqueje", "Nombrar", "<B>", "MOCHILA", "^Esqueje", "Tirar", "^Semilla Skunk", "Tirar 1", "^Semilla Lemon", "^Tirar$", "<B>", "PLANTAS", "<B>", "SALIR", "Nombrar", "="], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"ch": 5, "map": "home", "heat": 0, "due": 0, "protect": false, "esquejes": [], "bandejas": [], "fnom": {}, "seeds": {"ria": 3, "limon": 1},
			"carpas": [{"t": "m100", "foco": "sodio400"}], "macetas": ["plastico7", "plastico7", "plastico7", "plastico7"], "pots": [null, null, null, null]}, true)
		J.S.pots[0] = {"sid": "ria", "prog": .3, "water": 100, "health": 100, "fert": true, "pest": false, "f": {"id": 9995, "t": 1, "y": 1, "i": 50}}
		await run(func(): await J.pot_action(0))
		R = {"n1": J.S.fnom.get("9995")}
		await run(func(): await J.pot_action(0))
		R.esq = ",".join(PackedStringArray(J.S.esquejes.map(func(e): return str(int(e.f.id)))))
		await run(func(): await J.pot_action(0))
		R.n2 = J.S.fnom.get("9995")
		var l0 := LOG.size()
		await run(J.start_menu)
		R.esq2 = J.S.esquejes.size()
		R.seeds = JSON.stringify(J.S.seeds)
		R.lab = LOG.slice(l0).any(func(l): return re("\\[menú\\] .*  1 · Skunk #1 «Madre Lima»", l))
		await run(func(): await J.pot_action(0))
		R.n3 = J.S.fnom.has("9995")
		J.S = S0,
		func(): return chk(R.n1 == "Madre Lima" and R.esq == "9995" and R.n2 == "Madre Lima" and R.esq2 == 0 and R.seeds == '{"ria":2}' and R.lab and R.n3 == false
			and LOG.any(func(l): return l == "  [texto] Nombre de la planta (y sus esquejes) → Madre Lima") and LOG.any(func(l): return l == "  [texto] Nombre de la planta (y sus esquejes) → (B)")
			and LOG.any(func(l): return l.begins_with("Cortas una punta de la Skunk #1 «Madre Lima»")) and LOG.any(func(l): return l == "Sin nombre: vuelve a ser la nº 9995."), R))
	step("Cruces y recetario (1.11): nombres cortos (sin «×», hasta 20 letras, sin repetir); las partidas viejas pasan a nombres cortos con la misma clave (y las que se llaman como una variedad, 1.24); se cambia el nombre de una propia (sin repetir otro); el recetario, con las 50 de receta y de dónde sale cada semilla (1.25: el diario, con una nota de la tía en todas; 1.26: 87)",
		["GENOTECA", "DIARIO DE LA TÍA", "Skunk #1$", "Volver", "<B>", "^★ Skunk Haze", "=Haze Corta", "^★ Haze Corta", "=skunk #1", "<B>", "SALIR"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.custom = {}
		J.S.map = "home"
		var Rn := Datos.rng_seed(7)
		var pool: Array = J.D.DEX.duplicate()
		for g in 120:
			var a: String = pool[int(floor(Rn.sig() * pool.size()))]
			var c: String = pool[int(floor(Rn.sig() * pool.size()))]
			if a == c:
				continue
			var id := Datos.cross_result(J.S, a, c)
			if not pool.has(id):
				pool.append(id)
		var ns := []
		for k in J.S.custom:
			ns.append(J.S.custom[k].n)
		var mx := 0
		var nx := 0
		var nd := 0
		var un := {}
		for nm in ns:
			mx = maxi(mx, nm.length())
			if nm.contains("×"):
				nx += 1
			un[nm] = true
			for k in J.D.DEX:
				if J.D.STRAINS[k].n == nm:
					nd += 1
		R = {"n": ns.size(), "x": nx, "max": mx, "rep": ns.size() - un.size(), "dex": nd}
		var base := {"thc": 15, "y": 400, "d": 9, "r": 50, "o": "x", "c": "#5a8a3a"}
		J.S.custom = {"xv1": base.merged({"n": "Skunk #1 × Lemon Haze F5"}), "xv2": base.merged({"n": "Northern Lights Haze Skunk Lemon Thai"}), "xv3": base.merged({"n": "Thai Haze"}), "xv4": base.merged({"n": "Purple Haze"})}
		J.S.disc.merge({"xv1": true, "xv2": true, "xv3": true, "xv4": true}, true)
		J.migrate()
		var mg := []
		for k in J.S.custom:
			mg.append(k + ":" + J.S.custom[k].n)
		R.mig = "|".join(PackedStringArray(mg))
		await run(J.start_menu)
		R.ren = J.S.custom.xv1.n
		var Rc: Dictionary = J.recetas()
		var hojas := []
		for t in Rc:
			for o in Rc[t]:
				for k in o.k:
					if not hojas.has(k):
						hojas.append(k)
		R.rec = Rc.size()
		R.sin = ",".join(PackedStringArray(hojas.filter(func(k): return J.donde_semilla(k) == "Semillas: .")))
		R.parque = J.donde_semilla("acapulco")
		R.ss = "|".join(PackedStringArray(Rc.txoko.map(func(o): return J.receta_txt(o))))
		R.diario = ",".join(PackedStringArray(D.DEX.filter(func(t): return J.diario_txt(t) == "")))
		J.S = S0,
		func(): return chk(R.n > 50 and R.x == 0 and R.max <= 20 and R.rep == 0 and R.dex == 0 and R.mig == "xv1:Skunk Haze|xv2:Northern Thai|xv3:Thai Haze|xv4:Haze Purple" and R.ren == "Haze Corta"
			and R.rec == 50 and R.sin == "" and R.diario == "" and R.parque == "Semillas: escondidas en el parque del barrio." and R.ss == "Skunk #1 × Afghani, en ese orden"
			and LOG.any(func(l): return l == "  [texto] Nuevo nombre de la variedad → Haze Corta") and LOG.any(func(l): return l == "Ya hay una variedad con ese nombre.") and LOG.any(func(l): return re("\\[menú\\] .*Afghani.*Volver  → Volver", l)), R))
	step("El diario y las landraces de la tía (1.25): el diario sale bajo la almohada la primera vez que duermes en el piso (antes, ni en la Genoteca ni en el sillón; las partidas de antes ya lo tienen); 13 landraces en el banco (19 desde la 1.26) y las otras 7 en la nevera, la caja fuerte, 4 arbustos de la comarca y Miren; la Genoteca cuenta cada nueva; el trueque del molino da antes la que se te acabe (1.26)",
		["GENOTECA", "<B>", "SALIR", "Siesta", "GENOTECA", "<B>", "SALIR", "Siesta", "Nada", "Cerrar"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		R = {}
		J.S.flags.diario = 0
		J.S.map = "home"
		J.S.min = 600
		J.S.ch = 5
		var l0 := LOG.size()
		await run(J.start_menu)
		R.antes = LOG.slice(l0).any(func(l): return re("\\[menú\\] DIARIO DE LA TÍA", l))
		l0 = LOG.size()
		await run(J.bed_action)
		R.alm = LOG.slice(l0).filter(func(l): return re("almohada|tapas verdes|START → GENOTECA", l)).size()
		R.f = J.S.flags.diario == J.S.day
		l0 = LOG.size()
		await run(J.start_menu)
		R.despues = LOG.slice(l0).any(func(l): return re("\\[menú\\] DIARIO DE LA TÍA MAITE \\| 01 ", l))
		J.S.min = 600
		l0 = LOG.size()
		await run(J.bed_action)
		R.otra = LOG.slice(l0).any(func(l): return re("almohada", l))
		J.S.flags.diario = 0
		l0 = LOG.size()
		await run(func(): await J.mueble_action("sillon"))
		R.sillon = LOG.slice(l0).any(func(l): return re("\\[menú\\] Cambiar el tapizado \\| Nada", l))
		J.S.flags.erase("diario")
		J.migrate()
		R.mig = J.S.flags.diario
		var mov := ["choco", "oaxaca", "lamb", "kerala", "mangarosa", "hawai", "lao"]
		R.banco = ",".join(PackedStringArray(D.BANCO.map(func(b): return b[0])))
		R.fuera = ",".join(PackedStringArray(mov.filter(func(k): return D.BANCO.any(func(b): return b[0] == k) or not D.REGALO.has(k) or not re("Semillas: [^.]", J.donde_semilla(k)))))
		J.S.seeds = {}
		for k in mov:
			J.S.disc.erase(k)
		J.S.flags.nevera = 0
		J.S.flags.cajaSem = 0
		J.S.flags.lao = 0
		var n0: int = D.DEX.filter(func(k): return J.S.disc.get(k)).size()
		var T0 = TO
		TO = []
		capta = true
		await run(func(): await J.object_action(0, 6))
		R.toast = TO.any(func(h): return h.contains("NUEVA EN LA GENOTECA · %d/%d</small>" % [n0 + 1, D.DEX.size()]))
		capta = false
		TO = T0
		await run(func(): await J.object_action(0, 6))
		R.choco = J.S.seeds.choco
		J.S.caja = {"money": 0, "buds": {}, "nivel": 1}
		await run(J.caja_action)
		R.oax = J.S.seeds.oaxaca
		R.oax2 = J.S.flags.cajaSem == J.S.day
		var arb := []
		for p in [["h_lamb", "lamb"], ["h_kerala", "kerala"], ["h_manga", "mangarosa"], ["h_hawai", "hawai"]]:
			var it: Dictionary = D.ITEMS.filter(func(i): return i.id == p[0])[0]
			arb.append("%s:%s:%s" % ["true" if it.hidden else "false", J.MAPS[it.map].o[it.y][it.x], p[1]])
		R.arb = ",".join(PackedStringArray(arb))
		for id in ["h_lamb", "h_kerala", "h_manga", "h_hawai"]:
			var it: Dictionary = D.ITEMS.filter(func(i): return i.id == id)[0]
			J.S.taken.erase(id)
			J.S.map = it.map
			await run(func(): await J.object_action(it.x, it.y))
		R.sem = ",".join(PackedStringArray(["lamb", "kerala", "mangarosa", "hawai"].map(func(k): return str(int(J.S.seeds.get(k, 0))))))
		J.S.map = "errotabarri"
		J.S.flags.pagina = J.S.day
		await run(J.talk_miren)
		R.lao = J.S.seeds.lao
		R.laoF = J.S.flags.lao == J.S.day
		R.nuevas = D.DEX.filter(func(k): return J.S.disc.get(k)).size() - n0
		for b in D.BANCO:
			J.S.disc[b[0]] = 1
		J.S.ch = 8
		for k in D.REGALO:
			if not J.S.seeds.get(k):
				J.S.seeds[k] = 1
		J.S.seeds.chitral = 0
		J.S.seeds.lamb = 0
		R.tq = J.landrace_trueque()
		J.S.seeds.lamb = 1
		R.tq2 = J.landrace_trueque()
		J.S = S0
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(not R.antes and R.alm == 3 and R.f and R.despues and not R.otra and R.sillon and R.mig == 1 and R.banco == "mich,punto,colgold,thai,kif,beldia,chitral,nepal,congo,hthai,panama,libano,durban,kashmir,swazi,malana,vietblack,zamal,etiopia" and R.fuera == ""
			and R.toast and R.choco == 3 and R.oax == 3 and R.oax2 and R.arb == "true:bush:lamb,true:bush:kerala,true:bush:mangarosa,true:bush:hawai" and R.sem == "2,2,2,2" and R.lao == 3 and R.laoF and R.nuevas == 7
			and R.tq == "lamb" and (D.BANCO.any(func(b): return b[0] == R.tq2) or D.REGALO.has(R.tq2)), R))
	step("Exportar partida (1.11): OPCIONES → EXPORTAR PARTIDA copia el JSON de la partida", ["OPCIONES", "EXPORTAR", "VOLVER", "SALIR"], func():
		J.exportado = ""
		await run(J.start_menu)
		var s = JSON.parse_string(J.exportado) if J.exportado != "" else null
		R = {"clip": s is Dictionary and int(s.day) == int(J.S.day) and float(s.money) == float(J.S.money) and JSON.stringify(norm(s.custom)) == JSON.stringify(norm(J.S.custom))},
		func(): return chk(R.clip and LOG.any(func(l): return l == "Partida copiada al portapapeles. Pégala en una nota o en un correo para guardarla."), R))
	step("Importar partida (1.22): OPCIONES → IMPORTAR PARTIDA con algo que no es una partida, no; con la exportada (pegada), la carga en lugar de la de ahora y la guarda", ["OPCIONES", "IMPORTAR", "=hola", "VOLVER", "SALIR"], func():
		await run(J.start_menu)
		J.S.x = J.P.x
		J.S.y = J.P.y
		J.S.dir = J.P.dir
		var t := JSON.stringify(J.S, "", false, true)
		var m0 = J.S.money
		var d0 = J.S.day
		var S0 = J.S
		J.S.money += 777
		want(["OPCIONES", "IMPORTAR", "=" + t, "^Cargar", "VOLVER", "SALIR"])
		await run(J.start_menu)
		var g = JSON.parse_string(FileAccess.get_file_as_string(Juego.GUARDADO))
		R = {"imp": jn([not is_same(J.S, S0), float(J.S.money) == float(m0), int(J.S.day) == int(d0), g is Dictionary and float(g.money) == float(m0), J.pending.size()])},
		func():
			var re := RegEx.create_from_string("^¿Cargar la partida de .+, día \\d+\\? La de ahora se pierde\\.$")
			return chk(R.imp == "true,true,true,true,0" and LOG.has("Eso no es una partida exportada.") and LOG.has("  [texto] Pega aquí la partida exportada → (texto largo)")
				and LOG.any(func(l): return re.search(l) != null) and LOG.has("Partida cargada."), R))
	step("Arcón y mochila (1.10): lo que no cabe al cosechar va al arcón; sacar llega hasta el tope; la bolsa de deporte (3 kg); un control no lo ve; la redada se lo lleva; de la caja tampoco sacas más del tope; Darko, la mitad",
		["Sacar un lote", "^Hindu", "^10 g", "Guardar todo", "Cerrar", "Bolsa de deporte", "Salir", "Sacar todo", "Cerrar"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"ch": 5, "map": "home", "buds": {}, "rosin": {}, "arcon": {"buds": {}, "rosin": {}}, "protect": false, "caja": null}, true)
		J.S.items.bolsa = 0
		J.add_buds("ria", 990, 12)
		J.S.pots[0] = {"sid": "hindu", "prog": 1, "water": 100, "health": 100, "fert": false, "pest": false, "f": {"id": 9998, "t": 1, "y": 1}}
		var g: int = J.gramos_planta(J.S.pots[0], J.factores(0))
		var l0 := LOG.size()
		await run(func(): await J.harvest(0))
		R = {"g": g, "encima": J.peso_encima(), "arcon": J.arcon_g(), "aviso": "|".join(LOG.slice(l0).filter(func(l): return "arcón" in l))}
		J.use_buds("ria", 500)
		await run(J.arcon_action)
		R.a2 = J.arcon_g()
		R.b2 = J.total_buds()
		J.S.money = 100
		await run(J.shop)
		R.cap = J.cap_mochila()
		R.bolsa = J.S.items.bolsa
		J.add_buds("ria", 20, 12)
		J.confiscate(false)
		R.control = J.arcon_g()
		J.add_buds("ria", 5, 12)
		var l1 := LOG.size()
		await run(J.raid_event)
		R.redada = "|".join(LOG.slice(l1).filter(func(l): return "Se llevan" in l))
		R.a3 = J.arcon_g()
		J.S.caja = {"money": 0, "buds": {"ria": {"g": 1500, "thc": 12}}, "nivel": 1}
		J.S.buds = {}
		J.add_buds("ria", 2000, 12)
		var l3 := LOG.size()
		await run(J.caja_action)
		R.sacar = "%s,%s,%s" % [Datos.js_num(J.total_buds()), Datos.js_num(J.caja_g()), "true" if LOG.slice(l3).any(func(l): return "No te cabe todo encima" in l) else "false"]
		J.S.arcon = {"buds": {"ria": {"g": 101, "thc": 12}}, "rosin": {"ria": {"g": 3, "thc": 36}}}
		J.S.money = 0
		J.S.buds = {}
		J.S.rosin = {}
		var l2 := LOG.size()
		await run(J.robo_darko)
		R.darko = "|".join(LOG.slice(l2).filter(func(l): return "Se han llevado" in l))
		R.a4 = jj(J.S.arcon)
		J.S = S0,
		func(): return chk(R.g > 10 and R.encima == 1000 and R.arcon == R.g - 10 and re("en la mochila: %d g van al arcón" % (R.g - 10), R.aviso) and R.a2 == 490 + R.g and R.b2 == 0
			and R.cap == 3000 and R.bolsa == 1 and R.control == R.a2 and re("^Se llevan %d g\\." % int(floor(5 + R.a2)), R.redada) and R.a3 == 0
			and R.sacar == "3000,500,true" and re("Se han llevado 0 €, 50 g y 1,5 g de rosin\\.", R.darko) and R.a4 == "{\"buds\":{\"ria\":{\"g\":51,\"thc\":12}},\"rosin\":{\"ria\":{\"g\":1.5,\"thc\":36}}}", R))
	step("Móvil (1.10): START → MÓVIL; pedir a Kiko (+15 %, llega mañana) y su SMS en Mensajes; llamar a Kiko; quien te compra te da su número y, llamado, viene a la calle (20 min, +1 de calor, una vez al día)",
		["MÓVIL", "Pedir a Kiko", "^Abono", "Salir", "Colgar", "SALIR", "MÓVIL", "Mensajes", "<B>", "Llamar", "^Kiko", "Colgar", "SALIR", "^Skunk", "Rebaja",
			"MÓVIL", "Llamar", "^(?!Kiko|Nada)", "^Skunk", "Rebaja", "SALIR", "MÓVIL", "Llamar", "^(?!Kiko|Nada)", "Colgar", "SALIR"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"map": "home", "money": 100, "sms": [], "envio": [], "fijos": [], "protect": false, "protHasta": 0, "encargo": null, "heat": 0, "due": 0, "buds": {}, "rosin": {}, "min": 600}, true)
		J.S.flags.kiko1 = true
		J.S.flags.tono = 0
		J.S.flags.inaki = false
		var f0: int = J.S.items.fert
		await run(J.start_menu)
		R = {"m": J.S.money, "envio": ",".join(J.S.envio)}
		J.advance_time(24 * 60)
		await idle()
		R.fert = J.S.items.fert - f0
		R.sms = null
		for m in J.S.sms:
			if m.n == "KIKO":
				R.sms = m
				break
		R.envio2 = J.S.envio.size()
		var l0 := LOG.size()
		await run(J.start_menu)
		R.log = LOG.slice(l0)
		J.enter_map("town", 16, 17, "up")
		J.S.min = 600
		J.add_buds("ria", 50, 12)
		var c := {"id": "cz1", "map": "town", "x": 5, "y": 20, "type": "cur", "want": 2, "minThc": 0}
		J.S.clients.append(c)
		await run(func(): await J.talk_client(c))
		R.fijos = jj(J.S.fijos)
		R.nom = J.nombre_fijo("cz1")
		R.h = J.S.heat
		R.min = J.S.min
		R.mon = J.S.money
		var l1 := LOG.size()
		await run(J.start_menu)
		R.t = J.S.min - R.min
		R.dh = J.S.heat - R.h
		R.cobra = J.S.money - R.mon
		R.dia = J.S.fijos[0].dia == J.S.day
		R.log2 = LOG.slice(l1)
		var l2 := LOG.size()
		await run(J.start_menu)
		R.otra = "|".join(LOG.slice(l2))
		J.S = S0
		J.enter_map("home", 5, 5, "up"),
		func(): return chk(R.m == 100 - Datos.jsround(pr("Abono") * D.ENVIO) and R.envio == "Abono floración MEATZA 1 L" and R.fert == 4 and R.envio2 == 0 and R.sms != null and R.sms.t == "Te he dejado el paquete en casa: Abono floración MEATZA 1 L."
			and R.log.any(func(l): return re("\\[menú\\] KIKO", l)) and R.log.any(func(l): return l.begins_with("KIKO: ")) and R.fijos == jj([{"id": "cz1", "n": R.nom, "t": "cur", "dia": 0}])
			and R.t == D.LLAMADA_MIN and R.dh >= 1 + D.CALOR_CALLE.base and R.cobra > 0 and R.dia and R.log2.any(func(l): return l == "  [menú] Kiko | %s | Nada  → %s" % [R.nom, R.nom])
			and R.log2.any(func(l): return l.begins_with(R.nom.to_upper() + ": Busco")) and re("%s ya ha venido hoy" % R.nom, R.otra), R))
	step("Marcas, Julen e itinerario (1.23): Julen, en el piso tras Kiko, regala ORTUA BIO y pH− y lo explica; el itinerario apunta los pasos y avisa (y Julen lo comenta); el de crecimiento orgánico con su pH− cítrico (×0,95, sustrato vivo); en flor, a elegir marca: MEATZA con el pH− de la otra (×0,75) y ORTUA BIO (no acelera, más THC); «¿Qué hago ahora?»; START → OBJETIVO → ITINERARIO; con la primera cosecha, Julen se despide y se va al growshop",
		["Regar", "Abonar", "Abonar", "MEATZA", "Abonar", "¿Qué hago", "ITINERARIO", "Volver", "Volver"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"ch": 1, "map": "home", "day": 3, "min": 12 * 60, "sales": 0, "itin": {}, "flags": {"llegada": true, "letter": true, "kiko1": true}, "carpas": [{"t": "m100", "foco": "cfl"}], "macetas": ["plastico7", "plastico7", "plastico7", "plastico7"]}, true)
		var mis := {}
		for m in D.MISIONES:
			mis[m.id] = 0
		J.S.misiones = mis
		J.S.pots = []
		for q in 3:
			J.S.pots.append({"sid": "ria", "prog": .3, "water": 100, "health": 100, "fert": false, "pest": false})
		J.S.pots.append(null)
		J.S.items.merge({"fert": 1, "fertv": 0, "phm": 0, "ofert": 1, "ofertv": 0, "ophm": 0, "medidor": 0}, true)
		var to0 = TO
		TO = []
		capta = true
		J.build_ents()
		R = {"julen": J.ents.any(func(e): return e.id == "julen"), "obj": J.objective_text()}
		await run(J.talk_julen)
		await idle()
		R.it = [J.S.items.ofertv, J.S.items.ophm, si(J.S.flags.get("julen1")), ",".join(PackedStringArray(J.S.itin.keys()))]
		await run(func(): await J.pot_action(0))
		await idle()
		await run(func(): await J.pot_action(0))
		await idle()
		R.p0 = [J.S.pots[0].fv, J.S.pots[0].fvo, J.S.items.ophm, J.abono_txt(J.S.pots[0])]
		J.S.pots[1].prog = .8
		J.S.pots[2].prog = .8
		await run(func(): await J.pot_action(1))
		await idle()
		R.p1 = [J.S.pots[1].fq, J.S.pots[1].get("fo", 0), J.S.items.ophm, J.abono_txt(J.S.pots[1])]
		await run(func(): await J.pot_action(2))
		await idle()
		R.p2 = [J.S.pots[2].fq, J.S.pots[2].fo, J.S.items.ophm, J.abono_txt(J.S.pots[2])]
		var f: Dictionary = J.factores(0).duplicate()
		f.plaga = 0
		var pm := {"sid": "ria", "prog": .7, "water": 100, "health": 100, "fert": true, "fq": 1, "pest": false}
		var pb := pm.duplicate()
		pb.fo = 1
		Cultivo.plant_step(J.S, pm, 1, f)
		Cultivo.plant_step(J.S, pb, 1, f)
		R.crec = [pm.prog, pb.prog]
		R.g = [Cultivo.gramos_planta(J.S, J.S.pots[1], f), Cultivo.gramos_planta(J.S, J.S.pots[2], f), Cultivo.thc_cosecha(J.S, J.S.pots[1], f), Cultivo.thc_cosecha(J.S, J.S.pots[2], f)]
		await run(J.talk_julen)
		await idle()
		R.sig = J.itin_sig().id
		await run(J.objetivo_menu)
		await idle()
		R.n = J.itin_n()
		R.TO = TO.duplicate()
		capta = false
		TO = to0
		J.S.flags.harvest1 = true
		await run(J.check_story)
		await idle()
		R.fin = [J.S.ch, J.ents.any(func(e): return e.id == "julen"), D.NPCDEF.any(func(d): return d.id == "julen" and d.map == "shop" and J.npc_cond(d)), J.S.itin.get("cosecha") == J.S.day]
		R.log = [LOG.has("JULEN: " + D.JULEN.ok.plantar), LOG.has("JULEN: " + D.JULEN.adios[0]), LOG.has("JULEN: " + D.ITINERARIO[8].d)]
		# riego automático y partida de antes de gVeg/gFlor (abonada, en flor); pH por marca; Julen por primera vez tras la cosecha
		J.S.merge({"itin": {}, "carpas": [{"t": "m100", "foco": "cfl", "garrafas": true}], "pots": [{"sid": "ria", "prog": .8, "water": 100, "health": 100, "fert": true, "fq": 1, "pest": false}, null, null, null]}, true)
		J.S.flags = {"llegada": true, "letter": true, "kiko1": true, "julen1": true}
		R.vieja = J.itin_sig().id
		J.S.items.medidor = 1
		R.ph = J.abono_txt({"sid": "ria", "fv": D.ABONO_BIO.q[0], "fvo": 1, "org": 1, "fert": false})
		J.S.items.medidor = 0
		J.S.flags = {"llegada": true, "letter": true, "kiko1": true, "harvest1": true}
		J.S.map = "shop"
		var pt = load("res://src/pinta.gd").new()   # la «!» (story_mark, de pinta.gd; en el oráculo no hay pintor)
		pt.J = J
		R.mark = pt.story_mark("julen")
		var l3 := LOG.size()
		var o0: int = J.S.items.ofertv
		await run(J.talk_julen)
		await idle()
		var L3 := LOG.slice(l3)
		R.tarde = [L3.has("JULEN: " + D.JULEN.tarde[1]), not L3.has("JULEN: " + D.JULEN.aqui[0]), J.S.items.ofertv - o0, si(J.S.flags.get("julen1")), pt.story_mark("julen")]
		for x in [pt.c0, pt.ad, pt.vc, pt.c1, pt]:
			x.free()
		J.S = S0
		J.build_ents(),
		func(): return chk(R.julen and R.obj == D.ITINERARIO[3].d and R.it[0] == 2 and R.it[1] == 4 and R.it[2] and R.it[3] == "bus,carta,kiko,julen,plantar"
			and absf(R.p0[0] - .95) < 1e-9 and R.p0[1] == 1 and R.p0[2] == 3 and R.p0[3] == "Abonada (crecimiento bio) · sustrato vivo"
			and absf(R.p1[0] - .75) < 1e-9 and R.p1[1] == 0 and R.p1[2] == 2 and R.p1[3] == "Abonada (floración)"
			and absf(R.p2[0] - .95) < 1e-9 and R.p2[1] == 1 and R.p2[2] == 1 and R.p2[3] == "Abonada (floración bio) · sustrato vivo"
			and R.crec[0] > R.crec[1] and R.g[3] > R.g[2] and R.sig == "cosecha" and R.n == 8 and R.TO.size() == 4 and R.TO[0] == "<small>ITINERARIO · 5/14</small>Plantar<br>Ahora: Regar"
			and R.TO[3] == "<small>ITINERARIO · 8/14</small>Abono de floración<br>Ahora: Primera cosecha" and R.fin[0] == 2 and not R.fin[1] and R.fin[2] and R.fin[3] and R.log.all(func(x): return x)
			and R.vieja == "cosecha" and R.ph == "Abonada (crecimiento bio) · sustrato vivo · EC 0,8 · pH 7,5" and R.tarde[0] and R.tarde[1] and R.tarde[2] == 2 and R.tarde[3] and R.mark and not R.tarde[4], R))
	step("Reformas, decoración y logros (1.27): en la tienda online, el póster, la alfombra y REFORMAS (suelo y paredes: se pagan al pedir y vienen al día siguiente; el piso cambia sus casillas, la alfombra va en el suelo nuevo y la pared sigue siendo sólida); DECORAR LA CASA en la cama; los logros con su aviso (detrás del SMS de la misión, sin pisarlo) y START → OBJETIVO → LOGROS; en una partida de antes, lo conseguido, sin aviso",
		["Póster", "Alfombra", "Reformas", "Suelo: Baldosa", "Paredes: Pintura verde", "Volver", "Salir", "Decorar", "póster", "La ola", "alfombra", "Persa", "Listo", "LOGROS", "Volver", "Volver"], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.merge({"ch": 8, "map": "home", "day": 20, "min": 12 * 60, "money": 9000, "sales": 0, "caja": {"nivel": 1, "money": 0, "buds": {}, "rosin": {}}, "muebles": {}, "deco": {}, "obra": {}}, true)
		J.S.flags.kiko1 = true
		var mis := {}
		for m in D.MISIONES:
			mis[m.id] = 0
		J.S.misiones = mis
		var iti := {}
		for p in D.ITINERARIO:
			iti[p.id] = 0
		J.S.itin = iti
		var lg := {}
		for l in D.LOGROS:
			if l.id != "casa" and l.id != "venta":
				lg[l.id] = 0
		J.S.logros = lg
		J.enter_map("home", 10, 6, "up")
		var to0 = TO
		TO = []
		capta = true
		await run(J.tienda_online)
		await idle()
		R = {"compra": "%s %s %s" % [Datos.js_num(J.S.money), jj(J.S.obra), jj(J.S.muebles)]}
		await run(func():
			J.S.day += 1
			J.llega_mueble())
		await idle()
		var m: Dictionary = J.MAPS.home
		R.g = ",".join([m.g[0][3], m.g[1][3], m.g[4][3], m.g[3][13], m.g[4][14]])
		R.o = m.o[1][4]
		R.solido = jn([J.tile_solid(m, 3, 1), J.tile_solid(m, 13, 3)])
		await run(J.bed_action)
		await idle()
		R.deco = jn([J.S.deco.cartel, J.S.deco.alfombra, J.deco_sprite("cartel"), m.g[3][13]])
		J.S.misiones.erase("caja")
		J.S.sales = 50
		await run(func(): pass)
		await idle()
		await run(J.objetivo_menu)
		await idle()
		R.n = J.logros_n()
		R.TO = TO.duplicate()
		capta = false
		TO = to0
		J.S.erase("logros")
		J.migrate()
		R.mig = jn([J.S.logros.size() == D.LOGROS.filter(func(l): return J.logro_ok(l.id)).size(), J.S.logros.values().all(func(v): return v == 0), J.pending.size()])
		J.S = S0
		J.enter_map("home", 5, 5, "up"),
		func():
			var n: int = D.LOGROS.size()
			return chk(R.compra == "2582 {\"suelo\":{\"v\":3,\"dia\":21},\"pared\":{\"v\":1,\"dia\":21}} {\"cartel\":21,\"alfombra\":21}" and R.g == "iwT_home-1,iwB_home-1,floor-3,alf0a-3,alf0d-3" and R.o == "cartel" and R.solido == "true,false"
				and LOG.has("El instalador viene a primera hora: suelo nuevo, baldosa hidráulica.") and LOG.has("El pintor viene a primera hora: paredes nuevas, pintura verde salvia.")
				and R.deco == "1,1,cartel-1,alf1a-3" and LOG.has("Cambias el dibujo del póster: la ola.") and R.n == n and R.mig == "true,true,0"
				and "|".join(R.TO) == "Pedido: Póster enmarcado · llega mañana|Pedido: Alfombra de 180 × 140 · llega mañana|Pedido: suelo, baldosa hidráulica · mañana|Pedido: paredes, pintura verde salvia · mañana|<small>LOGRO · %d/%d</small>A tu gusto|<small>MISIÓN CUMPLIDA</small>La caja de la tía|<small>LOGRO · %d/%d</small>Primera venta" % [n - 1, n, n, n]
				and LOG.any(func(l): return l.begins_with("  [menú] %s | Volver" % " | ".join(PackedStringArray(D.LOGROS.map(func(x): return x.t))))), R))
	step("Partidas viejas: capítulo 3 sin plazo → 3.000 € en 7 días desde hoy; protección sin fecha → 10 días; los campos nuevos, con su valor (también arcón, sala, agenda, mensajes, pedidos y bolsa); con Toño ya visto, sale en el móvil", [], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.ch = 3
		J.S.due = 0
		J.S.deadline = 0
		J.S.protect = true
		J.S.flags.metB = false
		J.S.flags.erase("tono")
		for k in ["caja", "rec", "vencidos", "protHasta", "encargo", "encVeto", "arcon", "sala", "fijos", "sms", "envio", "misiones", "itin"]:
			J.S.erase(k)
		J.S.items.erase("bolsa")
		J.migrate()
		R = {"due": J.S.due, "dias": J.S.deadline - J.S.day, "tono": J.S.flags.get("tono") == J.S.day, "hasta": J.S.protHasta - J.S.day,
			"campos": jj([J.S.caja, J.S.rec, J.S.vencidos, J.S.encargo, J.S.encVeto]), "nuevos": jj([J.S.arcon, J.S.sala, J.S.fijos, J.S.sms, J.S.envio, J.S.items.bolsa]),
			"mis": ",".join(PackedStringArray(J.S.misiones.keys())) + "/" + ",".join(PackedStringArray(J.S.misiones.values().map(func(v): return str(int(v))))),
			"iti": ",".join(PackedStringArray(J.S.itin.keys())) + "/" + ",".join(PackedStringArray(J.S.itin.values().map(func(v): return str(int(v)))))}
		J.S = Datos.enteros(norm(S0))
		J.S.flags.metB = true
		J.S.flags.erase("tono")
		J.migrate()
		R.tono2 = J.S.flags.get("tono") == J.S.day
		J.S = S0,
		func(): return chk(R.due == 3000 and R.dias == 7 and R.tono and R.hasta == 10 and R.campos == "[null,{},0,null,0]"
			and R.nuevos == "[{\"buds\":{},\"rosin\":{}},{},[],[],[],0]" and R.tono2 and R.mis == "caja,luz,carpa,olor,inaki/0,0,0,0,0"
			and R.iti == "bus,carta,kiko,julen,plantar,regar,veg,flor,cosecha,vender,ventas/0,0,0,0,0,0,0,0,0,0,0", R))
	step("Guardar y cargar la partida", [], func(): J.save(),
		func():
			var sv = J.load_save()
			return chk(sv and sv.ch == J.S.ch and sv.money == J.S.money and jj(sv.disc) == jj(J.S.disc), "no coincide"))
