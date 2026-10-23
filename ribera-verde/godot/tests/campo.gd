# Landrace Hunters (Godot) — MAESTRO [4] (con Datos.CAL): el puerto con su tiempo y su noche, la botritis (BOTRITIS: lluvia o humedad
# en flor, fungicida, preventivo y sellado), la carretera comarcal entre Mendialde y Errotabarri (CAMPO) con las landraces salvajes del
# claro y el caserío de refugio, y el control de carretera (CONTROL: huir, sobornar, entregar la carga o dejar que registren).
#   $GODOT --headless --path godot --script res://tests/campo.gd   → «campo: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
	o = o.duplicate()
	o.initial = k
	return o

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-campo.json"
	Juego.AJUSTES = "user://prueba-campo-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = Datos.carga()
	var S: Dictionary = J.S
	S.ch = 5
	# 1 · el puerto con el tiempo y la noche (como la calle) y la comarcal también
	J.enter_map("muelle", 5, 10, "down")
	chk(J.pintor._al_raso(), "el muelle, al raso")
	J.enter_map("bar", 3, 3, "down")
	chk(not J.pintor._al_raso(), "el bar, no")
	# 2 · la botritis: en la tienda con CAL; la planta en flor coge botritis con humedad o lluvia; el sellado y el preventivo la frenan
	var lbls := []
	for it in D.SHOP:
		lbls.append(String(it.lbl))
	chk(lbls.has("Fungicida de cobre 250 ml") and lbls.has("Kit de sellado de carpa") and D.EXTRAS.has("sello"), "en la tienda y en los extras")
	chk(lbls.find("Fungicida de cobre 250 ml") == lbls.size() - D.BOTRITIS.shop.size(), "al final de la tienda")
	var H: Array = J.huecos()
	var i0 := 0
	var ci: int = H[0].c
	S.pots[i0] = {"sid": "ria", "prog": 0.8, "water": 80, "health": 100, "fert": true, "pest": false}
	var c: Dictionary = S.carpas[ci]
	c.erase("sello")
	var hr: float = Cultivo.clima_carpa(S, ci, true).hr
	var pr: float = J.prob_botritis(i0, ci, true)
	var esp: float = float(D.BOTRITIS.lluvia) + (float(D.BOTRITIS.hr_p) if hr > float(D.BOTRITIS.hr) else 0.0)
	chk(is_equal_approx(pr, esp), "con lluvia: %s (esperada %s, hr %s)" % [pr, esp, hr])
	c.sello = true
	var ps: float = J.prob_botritis(i0, ci, true)
	chk(ps < pr and is_equal_approx(ps, (float(D.BOTRITIS.hr_p) * float(D.BOTRITIS.sello)) if hr > float(D.BOTRITIS.hr) else 0.0), "sellada, la lluvia no entra: %s" % ps)
	c.erase("sello")
	S.pots[i0].prog = 0.3
	chk(J.prob_botritis(i0, ci, true) == 0.0, "en vegetativo, no")
	S.pots[i0].prog = 0.8
	S.pots[i0].prev = S.day + 3
	chk(J.prob_botritis(i0, ci, true) == 0.0, "con el preventivo, no")
	S.pots[i0].erase("prev")
	# a la larga, la frecuencia se parece a la probabilidad (tiradas por hash, no por el azar del cultivo)
	var pm0 = Cultivo.pm
	var nb := 0
	var d0: int = S.day
	for d in 400:
		S.day = d0 + d
		S.pots[i0] = {"sid": "ria", "prog": 0.8, "water": 80, "health": 100, "fert": true, "pest": false}
		J.botritis_dia()
		if S.pots[i0].get("bot"):
			nb += 1
	S.day = d0
	chk(nb > 0 and nb < 400, "en 400 días, %d con botritis" % nb)
	chk(Cultivo.pm == pm0, "sin tocar el azar del cultivo")
	# con botritis: pierde salud cada día, la cosecha merma y el fungicida la quita
	S.pots[i0] = {"sid": "ria", "prog": 0.8, "water": 80, "health": 100, "fert": true, "pest": false, "bot": S.day}
	J.botritis_dia()
	chk(float(S.pots[i0].health) == 100 - float(D.BOTRITIS.dano), "pierde salud: %s" % S.pots[i0].health)
	chk(J.botritis_merma(S.pots[i0], 100) == 60, "merma: %d" % J.botritis_merma(S.pots[i0], 100))
	S.items.fungi = 1
	S.mode = "world"
	J.mode = "world"
	QUIERO = ["Tratar hongos"]
	chk(corre(func(): await J.pot_action(i0)), "tratar hongos")
	chk(not S.pots[i0].has("bot") and int(S.items.fungi) == 0, "botritis parada")
	S.items.prevent = 1
	QUIERO = ["Preventivo"]
	chk(corre(func(): await J.pot_action(i0)), "preventivo")
	chk(int(S.pots[i0].prev) == S.day + int(D.BOTRITIS.prev), "protegida %s días" % D.BOTRITIS.prev)
	S.pots[i0] = null
	# 3 · la carretera comarcal: Mendialde y Errotabarri tienen salida de lado y se llega andando de una a otra
	J.enter_map("mendialde", 20, 19, "down")
	var ex = J.MAPS.mendialde.exits.get("47,17")
	chk(ex != null and ex.to == "comarcal" and ex.lado == "right", "salida de Mendialde: %s" % [ex])
	J.enter_map("errotabarri", 7, 13, "down")
	var ex2 = J.MAPS.errotabarri.exits.get("0,11")
	chk(ex2 != null and ex2.to == "comarcal" and ex2.lado == "left", "salida de Errotabarri: %s" % [ex2])
	var mc: Dictionary = J.MAPS.comarcal
	for k in mc.exits:
		var w = mc.exits[k]
		var mm: Dictionary = J.MAPS[w.to]
		chk(not J.tile_solid(mm, int(w.x), int(w.y)), "la llegada a %s (%d, %d) se pisa" % [w.to, w.x, w.y])
	for k in D.CAMPO.puertas:
		for q in D.CAMPO.puertas[k]:
			chk(not J.tile_solid(mc, int(q[2]), int(q[3])), "la llegada a la comarcal (%d, %d) se pisa" % [q[2], q[3]])
	# andando: de la llegada de Mendialde a la de Errotabarri y a la puerta del caserío
	var ok := _bfs(mc, [1, 7], [42, 8]) and _bfs(mc, [1, 7], [7, 7])
	chk(ok, "se cruza de punta a punta y se llega al caserío")
	chk(mc.doors.has("7,6") and mc.doors["7,6"].to == "refugio", "la puerta del refugio")
	var S_ch: int = S.ch
	S.ch = 0
	J.enter_map("mendialde", 20, 19, "down")
	chk(not J.MAPS.mendialde.exits.has("47,17"), "antes del capítulo %d, cerrada" % int(D.CAMPO.ch))
	S.ch = S_ch
	# 4 · el refugio: esconder y sacar; la redada no llega
	J.enter_map("refugio", 4, 4, "down")
	S.buds = {"ria": {"g": 30, "thc": 18.0}}
	QUIERO = ["Esconder", "Nada"]
	chk(corre(func(): await J.object_action(8, 2)), "el arcón")
	chk(J.total_buds() < 1 and float(S.campo.ref.ria.g) == 30.0, "escondido: %s" % [S.campo.ref])
	S.orden = S.day - 1
	S.heat = 95
	QUIERO = ["Sacar", "Nada"]
	chk(corre(func(): await J.object_action(8, 2)), "sacar")
	chk(float(S.buds.ria.g) == 30.0 and S.campo.ref.is_empty(), "sacado")
	S.orden = 0
	S.heat = 0
	QUIERO = ["Nada"]
	chk(corre(func(): await J.object_action(0, 2)), "el camastro")
	# 5 · las salvajes: en verano, esquejes; en otoño, semillas; en invierno, nada; lo recogido no vuelve hasta CAMPO.vuelve
	var dia_mes := func(m: int) -> int:
		for dd in range(1, 800):
			if int(Datos.fecha(dd).m) == m and not (Datos.tiempo(dd, 720).k in D.CAMPO.no):
				return dd
		return -1
	S.day = dia_mes.call(1)
	var n_inv := 0
	for i in D.CAMPO.sitios.size():
		if not J.salvaje(i).is_empty():
			n_inv += 1
	chk(n_inv == 0, "en enero no hay")
	var hay := {}
	for m in [6, 10]:
		var dd: int = dia_mes.call(m)
		for k in 40:   # algún día del mes con alguna
			S.day = dd + k * 7
			if int(Datos.fecha(S.day).m) != m:
				continue
			for i in D.CAMPO.sitios.size():
				var w: Dictionary = J.salvaje(i)
				if not w.is_empty() and not hay.has(m):
					hay[m] = [S.day, i, w]
	chk(hay.has(6) and hay[6][2].t == "esq", "en junio, para esquejes: %s" % [hay.get(6)])
	chk(hay.has(10) and hay[10][2].t == "sem", "en octubre, con semillas: %s" % [hay.get(10)])
	if hay.has(10):
		S.day = hay[10][0]
		var i: int = hay[10][1]
		var sid: String = hay[10][2].sid
		J.enter_map("comarcal", 30, 9, "down")
		var st: Array = D.CAMPO.sitios[i]
		chk(String(J.MAPS.comarcal.o[int(st[1])][int(st[0])]).begins_with("hp"), "se ve en el claro: %s" % J.MAPS.comarcal.o[int(st[1])][int(st[0])])
		var s0: int = int(S.seeds.get(sid, 0))
		QUIERO = ["Recoger"]
		chk(corre(func(): await J.object_action(int(st[0]), int(st[1]))), "recoger semillas")
		var ds: int = int(S.seeds.get(sid, 0)) - s0
		chk(ds >= int(D.CAMPO.n[0]) and ds <= int(D.CAMPO.n[1]) and S.disc.get(sid), "%d semillas de %s" % [ds, sid])
		chk(J.MAPS.comarcal.o[int(st[1])][int(st[0])] == null and J.salvaje(i).is_empty(), "recogida, ya no está")
		S.day += int(D.CAMPO.vuelve)
		chk(J.salvaje(i).is_empty() or true, "vuelve con la semana")
	if hay.has(6):
		S.day = hay[6][0]
		S.campo.r = {}   # lo de octubre se recogió «después»
		var i: int = hay[6][1]
		J.enter_map("comarcal", 30, 9, "down")
		var st: Array = D.CAMPO.sitios[i]
		S.esquejes = []
		QUIERO = ["Sacar esqueje"]
		chk(corre(func(): await J.object_action(int(st[0]), int(st[1]))), "sacar esqueje")
		chk(S.esquejes.size() == 1 and S.esquejes[0].sid == hay[6][2].sid, "el esqueje: %s" % [S.esquejes])
	# 6 · el control de carretera: con lo que llevas, huir, sobornar, entregar o dejar que registren
	S.coches = {"utilitario": {"dia": 0, "p": 20000, "r": S.day + 365, "iv": S.day + 365}, "deportivo": {"dia": 0, "p": 90000, "r": S.day + 365, "iv": S.day + 365}}
	var ctl: float = D.CONCE.control
	D.CONCE.control = 1.0
	S.heat = 100
	S.money = 5000
	S.buds = {"ria": {"g": 50, "thc": 18.0}}
	QUIERO = ["Entregar"]
	chk(corre(func(): await J.control_trafico("utilitario")), "entregar la carga")
	chk(J.total_buds() < 1 and int(S.money) == 5000, "sin multa: %s" % S.money)
	S.buds = {"ria": {"g": 50, "thc": 18.0}}
	S.heat = 0
	var ganados := {"huye": 0, "pilla": 0}
	for t in 60:
		S.min = t * 7
		S.buds = {"ria": {"g": 50, "thc": 18.0}}
		S.heat = 100
		QUIERO = ["Huir"]
		var m0: float = S.money + S.banco
		corre(func(): await J.control_trafico("deportivo"))
		if J.total_buds() >= 1:
			ganados.huye += 1
		else:
			ganados.pilla += 1
	chk(ganados.huye > 0 and ganados.pilla > 0, "huir a veces sale: %s" % ganados)
	S.buds = {"ria": {"g": 50, "thc": 18.0}}
	S.heat = 100
	S.money = 0
	QUIERO = ["Sobornar"]
	chk(corre(func(): await J.control_trafico("utilitario")), "sobornar sin dinero")
	chk(J.total_buds() < 1, "sin dinero, registran")
	S.buds = {"ria": {"g": 50, "thc": 18.0}}
	QUIERO = []
	chk(corre(func(): await J.control_trafico("utilitario")) and J.total_buds() < 1, "dejar que registren, como siempre")
	# el peso del maletero sube la probabilidad
	D.CONCE.control = ctl
	# 7 · sin CAL: nada de esto
	Datos.CAL = false
	D = Datos.carga()
	var hay_f := false
	for it in D.SHOP:
		if String(it.lbl).begins_with("Fungicida"):
			hay_f = true
	chk(not hay_f and not D.EXTRAS.has("sello"), "sin CAL, la tienda de siempre")
	J.enter_map("mendialde", 20, 19, "down")
	chk(not J.MAPS.mendialde.exits.has("47,17"), "sin CAL, sin salida")
	S.pots[i0] = {"sid": "ria", "prog": 0.8, "water": 80, "health": 100, "fert": true, "pest": false, "bot": S.day}
	J.botritis_dia()
	chk(float(S.pots[i0].health) == 100.0 and J.botritis_merma(S.pots[i0], 100) == 100, "sin CAL, sin botritis")
	S.pots[i0] = null
	Datos.CAL = true
	Datos.carga()
	print("campo: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  FALLO ", x)
	quit(1 if fallos.size() else 0)

func _bfs(m: Dictionary, a: Array, b: Array) -> bool:
	var vis := {}
	var q := [a]
	vis["%d,%d" % a] = true
	while q.size():
		var p: Array = q.pop_front()
		if p[0] == b[0] and p[1] == b[1]:
			return true
		for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var nx: int = p[0] + d[0]
			var ny: int = p[1] + d[1]
			var k := "%d,%d" % [nx, ny]
			if nx < 0 or ny < 0 or nx >= int(m.w) or ny >= int(m.h) or vis.has(k) or J.tile_solid(m, nx, ny):
				continue
			vis[k] = true
			q.append([nx, ny])
	return false
