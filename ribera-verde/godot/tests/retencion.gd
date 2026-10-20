# Landrace Hunters (Godot) — fase 6 del plan de Google Play (U7, U10, U11), con Datos.PLAY: el progreso offline (0 h, 3 h y 30 h →
# el tope de 8 h), el aviso de la cosecha, los objetivos diarios, la demo con la compra única, los 27 logros de Play Games y el
# embudo con el opt-in. Sin el plugin de Android: Plataforma apunta lo que pediría (enviados) y la compra responde PRUEBA_COMPRA.
#   $GODOT --headless --path godot --script res://tests/retencion.gd   → «retencion: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Retencion = preload("res://src/retencion.gd")
const Plataforma = preload("res://src/plataforma.gd")

var J
var M
var n := 0
var fallos := []
var QUIERO := []

func _initialize() -> void:
	Datos.PLAY = true   # la versión de la tienda
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo: fin %s libre %s pend %s modo %s" % [st.fin, J.is_free(), J.pending.size(), J.mode])
			return false
	return true

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
	o = o.duplicate()
	o.initial = k
	return o

func estado(k: String) -> Dictionary:
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	for x in O:
		if x.k == k:
			return Datos.enteros(x).S
	return {}

func _paga3() -> void:   # como el pago del plazo del capítulo 3 en trama.gd
	if Datos.PLAY and await J.demo_corta():
		return
	await J.cap4_sigue()

func planta(prog: float, agua: float, plaga: bool) -> Dictionary:
	return {"sid": "ria", "prog": prog, "water": agua, "health": 80.0, "fert": false, "pest": plaga, "f": J.roll_feno("ria")}

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-retencion.json"
	Juego.AJUSTES = "user://prueba-retencion-ajustes.json"
	Datos.CAL = true
	var D: Dictionary = Datos.carga()
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	J.gancho_combate = func(_k): return "win"
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var S0 := estado("casa-extr")
	J.S = S0.duplicate(true)
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	var PL = J.plat()

	# 1 · progreso offline: 0 h, 3 h y 30 h (tope de OFFLINE.tope_h)
	var tope: int = int(D.OFFLINE.tope_h) * int(D.OFFLINE.min_h)
	chk(J.minutos_fuera(0) == 0 and J.minutos_fuera(-50) == 0, "offline: 0 h → 0 min (%d)" % J.minutos_fuera(0))
	chk(J.minutos_fuera(3 * 3600) == 3 * int(D.OFFLINE.min_h), "offline: 3 h → %d min (%d)" % [3 * int(D.OFFLINE.min_h), J.minutos_fuera(3 * 3600)])
	chk(J.minutos_fuera(30 * 3600) == tope and J.minutos_fuera(8 * 3600) == tope, "offline: 30 h → el tope de %d h, %d min (%d)" % [D.OFFLINE.tope_h, tope, J.minutos_fuera(30 * 3600)])
	Retencion.AHORA = 1_800_000_000.0
	# 0.52 (lo pidió el usuario): de serie, con la app cerrada no pasa nada: ni crecen, ni pantalla, ni aviso
	Retencion.OFFLINE = false
	J.S = S0.duplicate(true)
	J.S.pots[0] = planta(.4, 50.0, false)
	var pr0 := float(J.S.pots[0].prog)
	J.pending.clear()
	chk(J.fuera_desde(Retencion.AHORA - 5 * 3600.0).is_empty() and float(J.S.pots[0].prog) == pr0 and J.pending.is_empty(), "sin OFFLINE: 5 h fuera, la planta igual y sin «mientras estabas fuera»")
	PL.enviados.clear()
	J.aj.avisos = true
	J.al_pausar()
	chk(not PL.enviados.any(func(e): return e.begins_with("aviso:")), "sin OFFLINE: sin aviso de la cosecha")
	J.aj.avisos = false
	Retencion.OFFLINE = true   # lo de antes, encendido para probarlo
	var casos := [[0.0, 0], [3.0, 3 * int(D.OFFLINE.min_h)], [30.0, tope]]
	for c in casos:
		J.S = S0.duplicate(true)
		J.S.pots[0] = planta(.4, 15.0, true)
		J.pending.clear()
		J.queued.clear()
		var p0: Dictionary = J.S.pots[0].duplicate(true)
		var r: Dictionary = J.fuera_desde(Retencion.AHORA - c[0] * 3600.0)
		var p: Dictionary = J.S.pots[0]
		if c[1] == 0:
			chk(r.is_empty() and p.prog == p0.prog and J.pending.is_empty(), "offline 0 h: nada crece ni sale pantalla")
		else:
			chk(int(r.get("mn", -1)) == c[1] and p.prog > p0.prog, "offline %d h: %d min de juego, crece de %.3f a %.3f" % [c[0], r.get("mn", -1), p0.prog, p.prog])
			chk(p.water == p0.water and p.pest == p0.pest and p.health == p0.health and not p.get("dead"), "offline %d h: el agua, la plaga y la salud, como estaban" % c[0])
			chk(J.pending.size() == 1, "offline %d h: la pantalla «mientras estabas fuera» (%d en la cola)" % [c[0], J.pending.size()])
	chk(J.minutos_fuera(30 * 3600) == J.minutos_fuera(300 * 3600), "offline: 300 h, igual que el tope")
	# el reloj y la deuda no corren
	J.S = S0.duplicate(true)
	J.S.pots[0] = planta(.4, 50.0, false)
	var d0: int = J.S.day
	var m0: int = J.S.min
	J.pending.clear()
	J.fuera_desde(Retencion.AHORA - 5 * 3600.0)
	chk(J.S.day == d0 and J.S.min == m0, "offline: el día y la hora del juego no cambian")
	# guardar apunta la hora del móvil (no en el oráculo: aquí, a mano)
	J.oraculo = false
	J.save()
	J.oraculo = true
	chk(float(J.S.get("ts", 0)) == Retencion.AHORA, "guardar apunta la hora (%s)" % J.S.get("ts"))

	# 2 · el aviso de la cosecha: solo con AVISO DE COSECHA, y con lo que falta para la primera lista
	J.S = S0.duplicate(true)
	for i in J.S.pots.size():
		J.S.pots[i] = null
	J.S.pots[0] = planta(.97, 60.0, false)
	var s: int = J.seg_cosecha()
	chk(s > 0 and s <= int(D.OFFLINE.tope_h) * 3600, "aviso: la primera lista en %d s (dentro del tope)" % s)
	PL.enviados.clear()
	J.aj.avisos = false
	J.al_pausar()
	chk(not PL.enviados.any(func(e): return e.begins_with("aviso:")), "aviso: apagado, no se programa")
	J.aj.avisos = true
	J.al_pausar()
	chk(PL.enviados.has("aviso:%d" % s), "aviso: encendido, se programa a %d s (%s)" % [s, PL.enviados])
	J.al_volver()
	chk(PL.enviados.has("sin_aviso"), "aviso: al volver se quita")
	J.S.pots[0] = planta(.1, 60.0, false)
	chk(J.seg_cosecha() == -1, "aviso: una que no llega en el tope no avisa")
	J.S.pots[0] = planta(1.0, 60.0, false)
	chk(J.seg_cosecha() == -1, "aviso: con una ya lista, nada")
	PL.enviados.clear()
	J.aj.avisos = true
	Plataforma.PRUEBA_PERMISO = false
	var ok_p: bool = await PL.permiso_avisos()
	chk(not ok_p, "aviso: sin permiso, no")

	# 3 · objetivos diarios
	J.S = S0.duplicate(true)
	J.S.erase("diario")
	Retencion.HOY = "2026-10-19"
	var Dd: Dictionary = J.diario()
	var ids: Array = Dd.o
	chk(ids.size() == 3 and ids[0] != ids[1] and ids[1] != ids[2] and ids[0] != ids[2], "diarios: tres distintos (%s)" % [ids])
	var f0 := int(J.S.items.fert)
	for id in ids:
		var x: Dictionary = J.diario_obj(id)
		if id == "ventas":
			J.S.sales += int(x.n)
		else:
			for k in int(x.n):
				J.cuenta(id)
	J.diario_revisa()
	chk(Dd.ok.size() == 3 and int(J.S.items.fert) == f0 + 3, "diarios: hechos los tres, 3 abonos (%s, %d → %d)" % [Dd.ok, f0, J.S.items.fert])
	J.diario_revisa()
	chk(int(J.S.items.fert) == f0 + 3, "diarios: el premio, una vez")
	Retencion.HOY = "2026-10-20"
	var D2: Dictionary = J.diario()
	chk(D2.f == "2026-10-20" and D2.ok.is_empty() and D2.c.is_empty() and D2.o != ids, "diarios: otro día, otros y a cero (%s)" % [D2.o])
	chk(J.diarios_txt() == "0/3", "diarios: en OBJETIVO, 0/3 (%s)" % J.diarios_txt())

	# 4 · la demo (capítulos 1-3) y la compra única
	J.S = S0.duplicate(true)
	J.S.ch = 3
	J.aj.completo = false
	PL.comprado = false
	Plataforma.PRUEBA_COMPRA = "cancelada"
	var res := {"v": null}
	QUIERO = ["Comprar"]
	corre(func(): res.v = await J.demo_corta())
	chk(res.v == true and J.S.flags.get("demo4") and J.S.ch == 3, "demo: cancelada, se queda en el 3 con START · JUEGO COMPLETO")
	chk(PL.enviados.has("compra:" + String(D.COMPLETO.producto)), "demo: pide %s" % D.COMPLETO.producto)
	QUIERO = ["Más tarde"]
	corre(func(): res.v = await J.demo_corta())
	chk(res.v == true and not J.aj.completo, "demo: más tarde, sigue la demo")
	Plataforma.PRUEBA_COMPRA = "ok"
	QUIERO = ["Comprar"]
	corre(func(): res.v = await J.demo_menu())
	chk(res.v == true and J.aj.completo and not J.S.flags.get("demo4"), "demo: comprada desde START, al capítulo 4")
	corre(func(): res.v = await J.demo_corta())
	chk(res.v == false, "demo: con el juego completo, no corta")
	J.aj.completo = false
	PL.comprado = true   # comprado en otro móvil (consultar)
	chk(J.completo() and J.aj.completo, "demo: la compra de antes se recuerda")
	# el pago del plazo del capítulo 3 de verdad: sin comprar, no pasa al 4
	J.aj.completo = false
	PL.comprado = false
	Plataforma.PRUEBA_COMPRA = "cancelada"
	J.S = S0.duplicate(true)
	J.S.ch = 3
	J.S.flags.erase("demo4")
	chk(J.has_method("cap4_sigue"), "demo: cap4_sigue")
	QUIERO = ["Más tarde"]
	corre(_paga3)
	chk(J.S.ch == 3, "demo: el plazo pagado sin comprar se queda en el 3 (cap. %d)" % J.S.ch)
	Plataforma.PRUEBA_COMPRA = "ok"
	J.S.flags.erase("demo4")
	QUIERO = ["Comprar"]
	corre(_paga3)
	chk(J.S.ch == 4, "demo: comprado, al 4 (cap. %d)" % J.S.ch)

	# 5 · Play Games: los 27 logros mapeados y el envío al conseguirlos
	var pg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Plataforma.PG_JSON))
	var lg: Dictionary = pg.get("logros", {})
	var pts := 0
	var mapeados := 0
	for l in D.LOGROS:
		if lg.has(l.id) and lg[l.id].has("id") and int(lg[l.id].get("puntos", 0)) > 0 and int(lg[l.id].puntos) % 5 == 0:
			mapeados += 1
			pts += int(lg[l.id].puntos)
	chk(D.LOGROS.size() == 27 and mapeados == 27 and lg.size() == 27, "logros: %d/%d mapeados (en el JSON, %d)" % [mapeados, D.LOGROS.size(), lg.size()])
	chk(pts > 0 and pts <= 1000, "logros: %d puntos (≤ 1000)" % pts)
	J.S = S0.duplicate(true)
	J.S.logros = {}
	J.S.sales = 1
	PL.enviados.clear()
	J.revisa_logros()
	chk(PL.enviados.has("logro:venta"), "logros: «Primera venta» va a Play Games (%s)" % [PL.enviados])
	J.pending.clear()
	J.queued.clear()

	# 6 · el embudo, solo con INFORMES DE ERRORES
	J.S = S0.duplicate(true)
	J.aj.errores = false
	PL.enviados.clear()
	corre(func(): await J.chapter(2))
	J.cuenta("riego")
	chk(not PL.enviados.any(func(e): return e.begins_with("evento:")), "embudo: sin el opt-in, nada (%s)" % [PL.enviados])
	J.aj.errores = true
	J.S.flags.erase("ev_riego")
	corre(func(): await J.chapter(3))
	J.cuenta("riego")
	chk(PL.enviados.has("evento:cap_3") and PL.enviados.has("evento:riego"), "embudo: con el opt-in, capítulo y primer riego (%s)" % [PL.enviados])
	J.cuenta("riego")
	chk(PL.enviados.count("evento:riego") == 1, "embudo: cada cosa, la primera vez")

	# 7 · sin Datos.PLAY no hay nada de esto (las pruebas contra el HTML)
	Datos.PLAY = false
	J.S = S0.duplicate(true)
	J.S.pots[0] = planta(.4, 50.0, false)
	var pp: float = J.S.pots[0].prog
	chk(J.fuera_desde(Retencion.AHORA - 5 * 3600.0).is_empty() and J.S.pots[0].prog == pp and J.completo(), "sin PLAY: ni offline ni demo")
	Datos.PLAY = true

	for f in fallos:
		print("FALLO  " + f)
	print("retencion: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for r in [Juego.GUARDADO, Juego.GUARDADO + ".bak", Juego.AJUSTES]:
		if FileAccess.file_exists(r):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	quit(1 if fallos.size() else 0)
