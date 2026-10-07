# Ribera Verde (Godot) — la historia 1 → 8 contra el HTML (godot/tests/historia.json, lo saca tools/test-historia.js con
# RV_ORACULO): los mismos 71 pasos que el test del HTML, con el mismo piloto (A cada 12 ms en los diálogos, opciones de menú
# por texto, «<B>» cierra el menú) y el mismo azar (Park-Miller). El reloj del juego y los paseos están parados: el bucle solo
# corre los eventos pendientes, como el update del oráculo. Tras cada paso compara la transcripción, S, el estado del azar,
# R, I, TO y dónde está cada cosa.
#   godot --headless --path godot --script res://tests/historia.gd [-- --oraculo f.json] [--salida dir]
#   → «historia: 71 pasos (71 OK) · semilla N · 0 diferencias con el HTML · T s»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Motor = preload("res://src/motor.gd")
const Juego = preload("res://src/juego.gd")

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
		if WANT.size():
			for k in labels.size():
				if WANT[0].search(labels[k]) != null:
					WANT.pop_front()
					o = o.duplicate()
					o.initial = k
					break
		LOG.append("  [menú] " + " | ".join(labels) + "  → " + labels[int(o.get("initial", 0)) if o.get("initial") else 0])
	return o

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

func step(nombre: String, w: Array, fn: Callable, check: Callable) -> void:
	WANT = []
	for s in w:
		WANT.append(s if s == "<B>" else RegEx.create_from_string(s))
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
		func(): return (J.S.ch == 1 and J.S.map == "casa-ama" and J.llegando() and J.S.name == "EDDIE" and "autobús" in J.objective_text()) or {"ch": J.S.ch, "map": J.S.map, "name": J.S.name, "flags": J.S.flags})
	step("Prólogo: la nota de ama y el táper de la nevera", [], func():
		await run(func(): await J.object_action(5, 4))
		await run(func(): await J.object_action(9, 6))
		await run(func(): await J.object_action(9, 6)),
		func(): return (si(J.S.flags.get("notaAma")) and si(J.S.flags.get("taper")) and J.S.items.bocata == 2) or {"flags": J.S.flags, "items": J.S.items})
	step("Prólogo: el autobús de Mendialde a Ribera Verde (billete de ama)", ["Ribera Verde"], func():
		await run(func(): await J.warp(J.MAPS["casa-ama"].exits["4,7"]))
		R = {"mapa": J.S.map, "x": J.P.x, "y": J.P.y, "m": J.S.money, "t": J.S.min}
		await run(J.parada_action),
		func(): return (R.mapa == "mendialde" and R.x == 6 and R.y == 10 and J.S.map == "town" and J.P.x == 7 and J.P.y == 12 and si(J.S.flags.get("llegada"))
			and J.S.money == R.m and J.S.min - R.t >= 40 and J.S.min - R.t < 46) or {"R": R, "map": J.S.map, "x": J.P.x, "y": J.P.y, "m": J.S.money, "t": J.S.min})
	step("Entrar en el piso de la tía", [], func(): await run(func(): await J.warp(J.MAPS.town.doors["5,8"])),
		func(): return (J.S.map == "home" and J.objective_text() == "Lee la carta que hay en la mesa.") or {"map": J.S.map, "obj": J.objective_text()})
	step("Leer la carta de la tía", [], func(): await run(func(): await J.object_action(3, 5)),
		func(): return J.S.flags.get("letter") == true)
	step("Kiko regala semillas y abono", [], func(): await run(J.talk_kiko),
		func(): return (J.S.seeds.get("ria") == 3 and J.S.items.fert == 2 and si(J.S.flags.get("kiko1"))) or {"seeds": J.S.seeds, "items": J.S.items})
	step("Plantar dos Skunk #1 y abonar una", ["Skunk", "Skunk", "Abonar"], func():
		await run(func(): await J.pot_action(0))
		await run(func(): await J.pot_action(1))
		await run(func(): await J.pot_action(1)),
		func(): return (J.S.pots[0] != null and J.S.pots[0].sid == "ria" and J.S.pots[1] != null and J.S.pots[1].fert == true and J.S.items.fert == 1) or {"pots": J.S.pots})
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
		func(): return (J.S.ch == 2 and J.S.buds.has("ria") and J.S.buds.ria.g > 30 and J.S.seeds.get("ria", 0) >= 1 and J.S.clients.size() > 0) or {"ch": J.S.ch, "buds": J.S.buds, "clients": J.S.clients.size()})

	# ---------- capítulo 2 ----------
	step("Vender a un cliente (rebaja) → 300 € → capítulo 3; el plazo de 3.000 € corre desde que aparece Toño", ["Skunk", "Rebaja"], func():
		J.S.sales = int(D.META_VENTAS) - 1
		await run(func(): await J.talk_client(J.S.clients[0])),
		func(): return (J.S.ch == 3 and J.S.sales >= D.META_VENTAS and J.S.heat > 0 and J.S.due == 3000 and J.S.deadline == J.S.day + 7 and J.S.flags.get("tono") == J.S.day
			and not si(J.S.flags.get("metB"))) or {"ch": J.S.ch, "sales": J.S.sales, "due": J.S.due, "deadline": J.S.deadline})
	step("Hablar con Josune (pintxo)", ["Pintxo"], func():
		J.S.hp = 10
		await run(J.talk_josune),
		func(): return J.S.hp == 22 or {"hp": J.S.hp})
	step("Abuela Txaro: dar 5 g → Hindu Kush", ["Skunk"], func(): await run(J.talk_txaro),
		func(): return (si(J.S.flags.get("txaro")) and J.S.seeds.get("hindu") == 2) or {"seeds": J.S.seeds})
	step("Iñaki: vender 10 g → Malawi Gold", ["Skunk", "Hecho"], func():
		J.add_buds("ria", 10, 12)
		await run(J.talk_inaki),
		func(): return (si(J.S.flags.get("inaki")) and J.S.seeds.get("malawi") == 2) or {"seeds": J.S.seeds})
	step("Iñaki al por mayor: 250 g de Skunk #1 a 3,20 €/g; una carga al día", ["Venta al por mayor", "Skunk", "^250 g", "Venta al por mayor"], func():
		J.S.buds = {}
		J.add_buds("ria", 300, 12)
		R = {"m": J.S.money, "g": J.S.buds.ria.g}
		await run(J.talk_inaki)
		R.m1 = J.S.money
		R.g1 = J.S.buds.ria.g
		await run(J.talk_inaki),
		func(): return (R.m1 == R.m + 800 and R.g1 == R.g - 250 and J.S.mDay == J.S.day and J.S.money == R.m1 and absf(J.precio_mayor(12) - 3.2) < 1e-9) or R)
	step("Arbusto escondido → Acapulco Gold", [], func():
		J.S.map = "town"
		await run(func(): await J.object_action(2, 26))
		J.S.map = "home",
		func(): return J.S.seeds.get("acapulco") == 2 or {"seeds": J.S.seeds})
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
		func(): return (R.mapa == "puerto" and R.x == 20 and R.y == 9 and R.m1 == R.m - 2 and R.t1 >= 625 and R.t1 < 631 and J.S.map == "valdehierro" and J.P.x == 15
			and J.P.y == 11 and J.S.money == R.m - 6 and J.S.min - R.t1 >= 45 and J.S.min - R.t1 < 51 and J.ents.any(func(e): return e.id == "obrero")) or {"R": R, "map": J.S.map, "m": J.S.money, "t": J.S.min})
	step("Autobús de vuelta a Ribera Verde (2 €) y a casa", ["Ribera Verde"], func():
		R.m2 = J.S.money
		await run(J.parada_action)
		R.mapa2 = J.S.map
		J.enter_map("home", 2, 4, "down"),
		func(): return (J.S.money == R.m2 - 2 and R.mapa2 == "town" and J.S.map == "home") or {"R": R, "m": J.S.money, "map": J.S.map})

	# ---------- capítulo 3 ----------
	step("Don Baltasar explica la deuda", [], func(): await run(J.talk_baltasar),
		func(): return (si(J.S.flags.get("metB")) and J.S.due == 3000 and J.S.debt == 30000 and J.S.deadline == J.S.flags.tono + 7) or {"due": J.S.due, "deadline": J.S.deadline, "day": J.S.day})
	step("Plazo vencido → Toño cobra intereses (1.er plazo vencido)", [], func():
		J.S.deadline = J.S.day
		J.advance_time(24 * 60)
		await idle(),
		func(): return (J.S.due == 3600 and J.S.debt == 30600 and J.S.deadline == J.S.day + 5 and J.S.vencidos == 1) or {"due": J.S.due, "debt": J.S.debt, "vencidos": J.S.vencidos})
	step("Pagar 3.600 € → capítulo 4", ["^Pagar"], func():
		J.S.money = 6000
		await run(J.talk_baltasar),
		func(): return (J.S.ch == 4 and J.S.debt == 27000 and J.S.due == 0) or {"ch": J.S.ch, "debt": J.S.debt})

	# ---------- capítulo 4 ----------
	step("Kiko instala la mesa de genética", [], func(): await run(J.talk_kiko),
		func(): return (si(J.S.flags.get("lab")) and J.S.seeds.get("rif") == 3) or {"lab": J.S.flags.get("lab"), "seeds": J.S.seeds})
	step("Comprar en el growshop: un bote de abono (4 dosis) y un sobre de 10 Skunk #1", ["Abono", "Semillas Skunk", "Sobre de 10", "Salir"], func():
		R = {"m": J.S.money, "s": J.S.seeds.get("ria", 0)}
		await run(J.shop),
		func(): return (J.S.items.fert == 5 and J.S.seeds.ria == R.s + 10 and J.S.money == R.m - 14 - 43) or {"items": J.S.items, "R": R, "money": J.S.money, "seeds": J.S.seeds.get("ria")})
	step("Growshop: carpa de 100, foco LED 200 W colgado en el armario y una maceta de tela", ["Carpa 100", "Foco LED 200", "^Armario", "Maceta de tela 11", "Salir"], func():
		J.S.money = 2000
		await run(J.shop),
		func(): return (J.S.carpas.size() > 1 and J.S.carpas[1] and J.S.carpas[1].t == "m100" and J.S.carpas[0].foco == "led200" and J.S.items.get("f_cfl") == 1 and J.S.items.get("m_tela11") == 1
			and J.S.pots.size() == 6 and J.S.macetas.size() == 6 and J.S.money == 2000 - 120 - 220 - 3 and pr("Carpa 100") == 120) or {"carpas": J.S.carpas, "items": J.S.items, "pots": J.S.pots.size(), "money": J.S.money})
	step("Plaza vacía: cambiar la maceta de 7 L por la de tela", ["Cambiar maceta", "Tela 11"], func(): await run(func(): await J.pot_action(2)),
		func(): return (J.S.macetas[2] == "tela11" and J.S.items.m_tela11 == 0 and J.S.items.get("m_plastico7") == 1) or {"macetas": J.S.macetas, "items": J.S.items})
	step("Carpa: cambiar el foco desde la pared (sodio 400 W)", ["Cambiar foco", "Sodio 400"], func():
		J.S.items.f_sodio400 = 1
		await run(func(): await J.carpa_action(1)),
		func(): return (J.S.carpas[1].foco == "sodio400" and J.S.items.f_cfl == 2 and J.S.items.f_sodio400 == 0) or {"carpas": J.S.carpas, "items": J.S.items})
	step("Factura de la luz: solo paga la carpa con plantas (sodio 400 W: 157 kWh a 0,16 € = 25 €)", [], func():
		J.S.money = 100
		J.S.pots[2] = {"sid": "ria", "prog": .2, "water": 100, "health": 100, "fert": false, "pest": false}
		J.advance_time(24 * 60)
		await idle()
		J.S.pots[2] = null,
		func(): return (J.S.luz.e == 25 and J.S.money == 75 and J.kwh_foco("sodio400") == 157) or {"luz": J.S.luz, "money": J.S.money})
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
		func(): return (R.sel0 == 0 and R.sel == 1 and re("Plaza 2", R.info) and R.agua == 100 and J.VC == null) or R)
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
		func(): return (J.S.carpas[0].t == "p80" and J.S.carpas[0].foco == "led200" and J.S.money == 1000 - 90 and J.S.pots.size() == 7 and R.filas == "0,0,1" and R.atras
			and jj(J.S.pots[0]) == R.antes[0] and jj(J.S.pots[1]) == R.antes[1] and R.antes[3] != "null" and R.movida == R.antes[3] and J.S.pots[3] == null and J.S.macetas[2] == "plastico7"
			and J.S.macetas[3] == R.mac[2] and J.MAPS.home.carpas.size() == 2) or {"carpas": J.S.carpas, "money": J.S.money, "R": R, "macetas": J.S.macetas})
	step("Extras: ventilador, filtro y goteo en la carpa de 100; sin filtro, el olor de la floración sube el calor", ["Ventilador", "^Carpa 100", "Extractor", "^Carpa 100", "Riego por goteo", "^Carpa 100", "Salir", "Poner filtro"], func():
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
		func(): return (si(J.S.carpas[1].get("vent")) and si(J.S.carpas[1].get("filtro")) and si(J.S.carpas[1].get("goteo")) and R.money == 1000 - 20 - 110 - 55
			and absf(R.f.plaga - R.m.plaga * .7) < 1e-9 and absf(R.f.agua - R.F.agua * R.m.agua * .5) < 1e-9 and R.h1 == 30 - 12 + 2 and R.h2 == R.h1 - 12
			and si(J.S.carpas[0].get("filtro")) and not J.S.items.get("x_filtro")) or {"carpas": J.S.carpas, "R": R, "items": J.S.items})
	step("Cruce de receta: Afghani × Skunk #1 → Critical Mass (de receta, sacada en la mesa: falta cosecharla)", ["^Afghani", "^Skunk #1", "Cruzar"], func():
		J.add_seeds("ria", 2)
		J.add_seeds("txoko", 2)
		await run(J.lab_action),
		func(): return (J.S.seeds.get("kushrif") == 2 and si(J.S.disc.get("kushrif")) and J.S.gen.get("kushrif") == 1 and J.S.rec.get("kushrif") == 1 and J.rec_count() == 0) or {"seeds": J.S.seeds, "gen": J.S.gen, "rec": J.S.rec})
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
			return (J.S.custom.size() == 1 and J.disc_count() >= 8 and J.S.ch == 4 and J.S.due == 0 and not J.S.rec.has(R.k) and re("\\(0/2\\)", J.objective_text()) and c.ma == "ria" and c.pa == "hindu" and m >= 30 and m <= 70
				and c.ind == Datos.jsround((m * 65 + (100 - m) * 100) / 100.0) and c.hj == Datos.mix(STR.hindu.hj, STR.ria.hj, m / 100.0) and c.c == Datos.mix(STR.hindu.c, STR.ria.c, m / 100.0)
				and R.linea == "Índica %d %% · sativa %d %% · %d %% madre · %d %% padre" % [c.ind, 100 - c.ind, m, 100 - m]) or {"custom": J.S.custom, "disc": J.disc_count(), "ch": J.S.ch, "R": R})

	step("Estabilizar Critical Mass: F1 → F2 → F3 → estable", ["^Critical Mass", "estabilizar", "Estabilizar", "^Critical Mass", "estabilizar", "Estabilizar", "^Critical Mass", "estabilizar", "Estabilizar"], func():
		R = []
		for k in 3:
			if k:
				J.add_seeds("kushrif", 1)
			await run(J.lab_action)
			R.append("%d:%s" % [Cultivo.gen_de(J.S, "kushrif"), Datos.js_num(J.S.seeds.kushrif)]),
		func(): return (",".join(R) == "2:1,3:1,4:1" and not J.S.gen.has("kushrif")) or {"R": R, "gen": J.S.gen, "seeds": J.S.seeds.get("kushrif")})
	step("Banco de semillas del PC: Punto Rojo y Thai, llegan al día siguiente", ["Banco de semillas", "^Punto Rojo", "^Thai", "Salir"], func():
		J.S.money = 500
		await run(J.pc_action)
		R = {"pedido": J.S.pedido.duplicate(), "money": J.S.money, "antes": si(J.S.seeds.get("thai"))}
		J.new_day(),
		func(): return (",".join(R.pedido) == "punto,thai" and R.money == 500 - 30 - 30 and not R.antes and J.S.seeds.get("punto") == 10 and J.S.seeds.get("thai") == 10
			and si(J.S.disc.get("thai")) and J.S.pedido.is_empty()) or {"R": R, "seeds": J.S.seeds, "pedido": J.S.pedido})
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
			return (si(J.S.disc.get("haze")) and J.S.gen.get("haze") == 1 and gs.size() > 2 and bien and re("F1: línea inestable", J.strain_line("haze"))
				and Cultivo.tipo_gen(J.S, "haze") == "F1" and J.S.rec.get("haze") == 2 and J.rec_count() == 1 and J.S.ch == 4) or {"R": R, "gen": J.S.gen.get("haze"), "rec": J.S.rec, "ch": J.S.ch})
	step("Cosechar una Critical Mass, la 2.ª de receta sacada en la mesa → capítulo 5", [], func():
		J.S.pots[0] = {"sid": "kushrif", "prog": 1, "water": 80, "health": 100, "fert": false, "pest": false, "f": J.roll_feno("kushrif")}
		await run(func(): await J.harvest(0)),
		func():
			var sv = J.load_save()
			return (J.S.rec.get("kushrif") == 2 and J.rec_count() == 2 and J.S.ch == 5 and J.S.due == 12000 and sv and sv.due == 12000) or {"rec": J.S.rec, "ch": J.S.ch, "due": J.S.due})

	# ---------- capítulo 5 ----------
	step("Growshop: carpa 120 en el sitio C, junto a la cama (6 plazas más)", ["Carpa 120", "Salir"], func():
		J.S.money = 1000
		await run(J.shop)
		J.enter_map("home", 5, 5, "up"),
		func():
			var hay := false
			for t in J.MAPS.home.carpas:
				hay = hay or (t.ci == 2 and t.x0 == 2 and t.x1 == 3)
			return (J.S.carpas.size() > 2 and J.S.carpas[2] and J.S.carpas[2].t == "m120" and J.S.carpas[2].foco == "cfl" and J.huecos().size() == 13 and J.S.pots.size() == 13
				and J.S.macetas.size() == 13 and J.S.money == 1000 - 150 and hay and J.tile_solid(J.MAPS.home, 2, 2) and J.tile_solid(J.MAPS.home, 3, 2)) or {"carpas": J.S.carpas, "money": J.S.money, "n": J.huecos().size(), "mapa": J.MAPS.home.carpas})
	step("Sargento Molina: pagar protección (1.500 € cada 10 días)", ["^Pagar"], func():
		J.S.money = 1600
		await run(J.talk_molina),
		func(): return (J.S.protect == true and J.S.money == 100 and J.S.protHasta == J.S.day + 10 and si(J.S.flags.get("molina1"))) or {"protect": J.S.protect, "money": J.S.money, "hasta": J.S.protHasta})
	step("Calor 95 con protección → Molina para la redada", ["Skunk"], func():
		J.add_seeds("ria", 1)
		await run(func(): await J.pot_action(0))
		J.S.heat = 95
		J.advance_time(24 * 60)
		await idle(),
		func(): return (J.S.heat == 50 and J.S.pots[0] != null) or {"heat": J.S.heat, "pot": J.S.pots[0]})
	step("Calor 95 sin protección → redada", [], func():
		J.S.protect = false
		J.S.heat = 95
		J.add_buds("ria", 10, 12)
		J.advance_time(24 * 60)
		await idle(),
		func(): return (J.S.pots.all(func(p): return p == null) and J.S.buds.is_empty() and J.S.heat == 30) or {"pots": J.S.pots, "buds": J.S.buds, "heat": J.S.heat})
	step("Pagar 12.000 € → capítulo 6", ["^Pagar"], func():
		J.S.protect = true
		J.S.money = 12500
		await run(J.talk_baltasar),
		func(): return (J.S.ch == 6 and J.S.debt == 15000 and J.S.money == 500) or {"ch": J.S.ch, "debt": J.S.debt})

	# ---------- capítulo 6 ----------
	step("Darko presume", [], func(): await run(J.talk_darko), func(): return J.S.ch == 6)
	step("Copa: presentar Skunk #1 (12%) → pierde", ["Skunk"], func():
		J.add_buds("ria", 25, 12)
		await run(J.talk_jurado),
		func(): return (J.S.ch == 6 and Datos.jsround(J.S.buds.ria.g) == 5) or {"ch": J.S.ch, "buds": J.S.buds})
	step("Copa: presentar Fire OG (27,2%) → gana → capítulo 7", ["Fire OG"], func():
		J.S.money = 0
		J.add_buds("dragon", 25, 27.2)
		await run(J.talk_jurado),
		func():
			var sv = J.load_save()
			return (J.S.ch == 7 and J.S.money == 5000 and J.S.due == 15000 and si(J.S.flags.get("copa")) and sv and sv.due == 15000) or {"ch": J.S.ch, "money": J.S.money, "due": J.S.due, "guardado": sv.due if sv else null})

	# ---------- capítulo 7 → final ----------
	step("Pagar los últimos 15.000 € → deuda saldada: empieza tu imperio (capítulo 8, con su rótulo)", ["^Pagar"], func():
		J.S.money += 10000
		TO = []
		capta = true
		await run(J.talk_baltasar)
		capta = false,
		func(): return (TO.any(func(h): return re("CAPÍTULO 8.*Tu imperio", h)) and J.S.ch == 8 and J.S.debt == 0 and J.S.imp0 == J.S.sales and J.imperio_nivel() == 0
			and J.mayor_dia() == 1000 and re("^Tu imperio · Cultivador", J.objective_text()) and not J.endcard_on) or {"ch": J.S.ch, "debt": J.S.debt, "o": J.objective_text()})
	step("Imperio: 25.000 € facturados → Proveedor del barrio; Iñaki carga 2 kg al día", [], func():
		J.S.sales += 25000
		await run(J.check_story),
		func(): return (J.S.impN == 1 and J.mayor_dia() == 2000 and re("Proveedor del barrio", J.objective_text())) or {"impN": J.S.impN, "o": J.objective_text()})

	# ---------- sistemas sueltos ----------
	var spray := []
	for k in 20:
		spray.append_array(["MOCHILA", "SPRAY"])
	step("Combate ladrón: ganar con spray", spray.slice(0, 24), func():
		J.S.hpMax = 60
		J.S.hp = 60
		J.S.items.spray = 12
		J.S.money = 100
		await run(func(): await J.battle("thief"))
		WANT = [],
		func(): return (J.S.money > 100 and J.S.hpMax == 60 and J.mode == "world") or {"money": J.S.money, "hpMax": J.S.hpMax, "mode": J.mode})
	step("Combate ladrón: desmayo → despiertas en casa", [], func():
		J.S.hpMax = 30
		J.S.hp = 1
		J.S.money = 1000
		J.S.buds = {}
		J.add_buds("ria", 20, 12)
		J.S.map = "town"
		await run(func(): await J.battle("thief")),
		func(): return (J.S.map == "home" and J.S.hp == J.S.hpMax and J.S.money == 700 and J.S.buds.ria.g == 10) or {"map": J.S.map, "hp": J.S.hp, "money": J.S.money, "buds": J.S.buds})
	step("Ladrón vencido sube la VIDA máxima", ["LUCHAR", "PATADA"] + spray, func():
		J.S.hpMax = 40
		J.S.hp = 40
		J.S.items.spray = 20
		await run(func(): await J.battle("thief"))
		WANT = [],
		func(): return J.S.hpMax == 42 or {"hpMax": J.S.hpMax})
	step("Policía: soborno con protección (40 + 4 × calor + 0,5 × gramos + 5 % del dinero encima)", ["SOBORNAR", "^Sí"], func():
		J.S.protect = true
		J.S.heat = 40
		J.S.money = 1000
		J.add_buds("ria", 10, 12)
		R = {"p": J.precio_soborno(), "g": J.total_buds()}
		await run(func(): await J.battle("police")),
		func(): return (R.p == Datos.jsround(40 + 160 + R.g * .5 + 50) and J.S.money == 1000 - R.p and J.S.heat == 30 and J.S.buds.has("ria")) or {"money": J.S.money, "heat": J.S.heat, "R": R})
	step("Agente en la plaza: entregar la mercancía", ["ENTREGAR"], func():
		J.S.protect = false
		J.add_buds("ria", 5, 12)
		await run(J.talk_cop),
		func(): return J.S.buds.is_empty() or {"buds": J.S.buds})
	step("Menú START: Genoteca, Mochila, Plantas, Objetivo", ["GENOTECA", "<B>", "MOCHILA", "<B>", "PLANTAS", "<B>", "OBJETIVO", "SALIR"], func(): await run(J.start_menu),
		func(): return J.handlers.is_empty())
	step("Cama: siesta de 3 horas", ["Siesta"], func():
		J.S.min = 600
		J.S.hp = 5
		await run(J.bed_action),
		func(): return ((J.S.min == 780 or J.S.min == 781) and J.S.hp == J.S.hpMax) or {"min": J.S.min, "hp": J.S.hp})
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
			return (bien and I.ria == "65" and absf(I.media - 50) < 1 and absf(I.sd - D.GENETICA.landrace.si) < 1 and Cultivo.tipo_gen(J.S, "ria") == "estable"
				and Cultivo.tipo_gen(J.S, "mango") == "f1" and Cultivo.tipo_gen(J.S, "limon") == "poli" and Cultivo.tipo_gen(J.S, "thai") == "landrace"
				and re("Cruce F1 \\(KC 33 × Afghani\\)", J.strain_line("mango"))) or {"R": R, "I": I})
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
			return (R.n == 2 and R.id == "9999,9999" and R.feno == "estrella" and R.lote and p and p.f.id == 9999 and p.prog == .12 and R.queda == 1 and R.seco == 0) or R)
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
		func(): return (R.cfl >= .25 and R.cfl <= .4 and R.led >= 1 and R.led <= 1.35 and R.luz == 45 and R.tope == 56) or R)
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
		func(): return (R.hindu.all(func(n): return n >= 1 and n <= 3) and R.skunk[0] == 0 and R.skunk[1] >= 1) or R)
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
		func(): return (R.due == 15000 and R.dias == 7 and R.eco == 2 and R.eur == "999 €|3.000 €|1.500 €|-1.234 €|30.000 €" and R.due5 == 12000 and R.dias5 == 10) or R)
	step("Capítulo 4: la 8.ª variedad (de un arbusto) no pasa de capítulo; la 2.ª de receta cosechada, sí", [], func():
		J.S.ch = 4
		J.S.flags.lab = true
		J.S.due = 0
		J.S.disc = {"ria": true, "limon": true, "txoko": true, "niebla": true, "mango": true, "purpura": true, "rif": true}
		J.S.custom = {}
		J.S.rec = {"kushrif": 2, "citrus": 1}
		J.S.taken.erase("h_acap")
		J.S.map = "town"
		await run(func(): await J.object_action(2, 26))
		J.S.map = "home"
		await idle()
		R = {"ch": J.S.ch, "disc": J.disc_count()}
		J.S.pots[0] = {"sid": "citrus", "prog": 1, "water": 80, "health": 100, "fert": false, "pest": false, "f": J.roll_feno("citrus")}
		await run(func(): await J.harvest(0)),
		func():
			var sv = J.load_save()
			return (R.ch == 4 and R.disc == 8 and J.S.ch == 5 and J.S.due == 12000 and sv and sv.due == 12000) or {"R": R, "ch": J.S.ch, "guardado": sv.due if sv else null})
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
		func(): return (R.pista and R.tras1987 == null and J.S.caja and J.S.caja.nivel == 1 and J.S.caja.money == 300 and J.caja_g() == 0 and J.S.money == 0) or {"R": R, "caja": J.S.caja})
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
		func(): return (R.antes == 20 and R.despues == 0 and R.caja.money == 5300 and R.caja.buds.ria.g == 200 and R.caja.buds.dragon.g == 100 and R.m == 0 and R.g == 0
			and re("Caja fuerte", R.mochila)) or R)
	step("Caja: sacar 1.000 € y 100 g de Fire OG; el soborno cuenta lo de encima (+5 % del dinero)", ["Sacar dinero", "^1\\.000 €", "Sacar cogollos", "^Fire OG", "^100 g", "Cerrar"], func():
		J.S.heat = 20
		await run(func(): await J.object_action(7, 1))
		R = {"p": J.precio_soborno()},
		func(): return (J.S.money == 1000 and J.S.caja.money == 4300 and J.S.buds.has("dragon") and J.S.buds.dragon.g == 100 and not J.S.caja.buds.has("dragon") and J.S.caja.buds.ria.g == 200
			and R.p == Datos.jsround(40 + 80 + 50 + 50)) or {"R": R, "money": J.S.money, "caja": J.S.caja, "buds": J.S.buds})
	step("Redada con la caja: 3 de cada 4 veces no la ven; si la ven, sus gramos y la mitad de su dinero; la multa sale de la caja si fuera no llega", [], func():
		var mira := func():
			var np := 0
			for p in J.S.pots:
				if p:
					np += 1
			return {"m": J.S.money, "cm": J.S.caja.money, "cg": J.caja_g(), "g": J.total_buds(), "h": J.S.heat, "pots": np}
		J.S.protect = false
		vacia.call()
		J.S.pots[1] = {"sid": "ria", "prog": .5, "water": 90, "health": 100, "fert": false, "pest": false}
		J.S.caja.money = 4000
		J.S.money = 200
		J.S.heat = 95
		Cultivo.fijo = .9
		await run(J.raid_event)
		Cultivo.fijo = -1
		R = {"a": mira.call()}
		J.add_buds("ria", 30, 12)
		J.S.heat = 95
		Cultivo.fijo = .1
		await run(J.raid_event)
		Cultivo.fijo = -1
		R.b = mira.call(),
		func(): return (R.a.m == 0 and R.a.cm == 4000 - (D.MULTA_REDADA - 200) and R.a.cg == 200 and R.a.g == 0 and R.a.h == 30 and R.a.pots == 0
			and R.b.cg == 0 and R.b.g == 0 and R.b.cm == maxf(0, R.a.cm - floor(R.a.cm / 2) - D.MULTA_REDADA) and R.b.m == 0 and R.b.h == 30) or R)
	step("Caja empotrada por el ordenador (380 €, de fuera y el resto de la caja): Kiko la instala al día siguiente", ["Caja empotrada", "Pedirla"], func():
		J.S.caja.money = 1000
		J.S.money = 100
		await run(J.pc_action)
		R = {"m": J.S.money, "cm": J.S.caja.money, "mejora": J.S.caja.get("mejora"), "nivel": J.S.caja.nivel}
		var l0 := LOG.size()
		J.new_day()
		await idle()
		R.sms = lin.call(l0, "caja empotrada") != "",
		func(): return (R.m == 0 and R.cm == 1000 - 280 and R.mejora == 1 and R.nivel == 1 and J.S.caja.nivel == 2 and not J.S.caja.has("mejora") and J.S.caja.money == 720 and R.sms) or {"R": R, "caja": J.S.caja})
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
		func(): return (R.robo and R.m == 1501 and R.ria == 60 and R.kr == 41 and R.cm == 720 and R.cg == 50 and R.m2 == 1501 and R.g2 == 101) or R)
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
		func(): return (R.t == "p80,m100,m120" and R.h0 == 13 and R.a.t == "p80,m100," and R.a.n == 7 and R.a.v == 0 and R.a.p0 == "ria" and R.a.p3 == "hindu" and R.a.vivas == 2 and R.a.mapa == 2
			and R.v1 == "p80,,|901|3" and R.v2 == "p80,,|451|3") or R)
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
		func(): return (R.p == false and R.sms and R.ent == "4,2" and R.h1 == 10 and R.cub and J.S.protect and J.S.protHasta == J.S.day + 20 and J.S.money == 0) or {"R": R, "hasta": J.S.protHasta, "day": J.S.day, "money": J.S.money})
	var hay_tono := func() -> bool: return J.ents.any(func(e): return e.id == "tono2")
	step("Imperio: encargo de Don Baltasar (2 kg al almacén de los astilleros, de noche, a 6 €/g); Toño se lleva primero lo más flojo; si no llegas, reputación −10 y 5 días sin encargos", ["Aceptar", "Entregar", "Aceptar"], func():
		J.S.ch = 8
		J.S.due = 0
		J.S.encargo = null
		J.S.encVeto = 0
		J.S.rep = 50
		J.S.map = "bar"
		await run(J.talk_baltasar)
		R = {"e": J.S.encargo.duplicate() if J.S.encargo else null, "d": J.S.day}
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
		func(): return (R.e and R.e.g == 2000 and R.e.hasta == R.d + 2 and R.tono and R.dia == 2300 and R.d1.m == 12000 and R.d1.s == 12000 and R.d1.rep == 2 and R.d1.heat == 3
			and not R.d1.ria and R.d1.dragon == 300 and R.d1.enc == null and not R.d1.tono and R.e2 == 2 and R.rep3 == R.rep2 - 10 and R.enc3 == null and R.veto == 5 and R.tarde and R.fallo) or R)
	step("Mapa ampliado: barrio alto y astilleros con sus puertas; policía y ladrones según la zona; clientes de cada zona", [], func():
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
		for zr in [["town", [.0019, .0059, .0061]], ["alto", [.0029, .0049, .0051]], ["astilleros", [.0009, .0089, .0091]]]:
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
		func(): return (R.enc.town == "police,thief," and R.enc.alto == "police,thief," and R.enc.astilleros == "police,thief,"
			and R.puertas == "alto,11,28,up|alto,12,28,up|town,12,1,down|astilleros,1,21,right|town,38,20,left|comisaria,4,6,up|almacen,4,6,up|txaro,4,6,up"
			and R.salidas == "alto,26,19|astilleros,18,14|town,34,9" and R.warp == "alto,11,28" and R.c2.ends_with(",0,2") and R.c5 == "3,3" and R.tipos and R.ents == 0 and R.entsB == 3
			and R.sobre == 80 and R.sp == 2) or R)
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
		func(): return (R.ent == "6,3" and si(J.S.flags.get("txaro2")) and J.S.seeds.get("chitral") == R.ch + 3 and J.S.items.bocata == R.boc + 3 and J.S.rep == R.rep + 5 and J.S.buds.hindu.g == 5
			and J.S.buds.ria.g == 20 and re("Hindu Kush", R.menu) and not re("Skunk|Thai", R.menu)) or R)
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
		func(): return (R.m1 == Datos.jsround(J.precio_calle(12) * D.CTYPES.cur.mult * 1.2 * 10) and R.m2 == R.m1 and R.b1 == 1 and ",".join(R.b) == "thief" and D.ZONAS.astilleros.precio == 1.2) or R)
	step("Partidas viejas: capítulo 3 sin plazo → 3.000 € en 7 días desde hoy; protección sin fecha → 10 días; los campos nuevos, con su valor", [], func():
		var S0 = J.S
		J.S = Datos.enteros(norm(S0))
		J.S.ch = 3
		J.S.due = 0
		J.S.deadline = 0
		J.S.protect = true
		J.S.flags.metB = false
		J.S.flags.erase("tono")
		for k in ["caja", "rec", "vencidos", "protHasta", "encargo", "encVeto"]:
			J.S.erase(k)
		J.migrate()
		R = {"due": J.S.due, "dias": J.S.deadline - J.S.day, "tono": J.S.flags.get("tono") == J.S.day, "hasta": J.S.protHasta - J.S.day,
			"campos": jj([J.S.caja, J.S.rec, J.S.vencidos, J.S.encargo, J.S.encVeto])}
		J.S = S0,
		func(): return (R.due == 3000 and R.dias == 7 and R.tono and R.hasta == 10 and R.campos == "[null,{},0,null,0]") or R)
	step("Guardar y cargar la partida", [], func(): J.save(),
		func():
			var sv = J.load_save()
			return (sv and sv.ch == J.S.ch and sv.money == J.S.money and jj(sv.disc) == jj(J.S.disc)) or "no coincide")
