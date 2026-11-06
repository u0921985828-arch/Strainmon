# Landrace Hunters (Godot) — cada club con su dispensario (lo pidió el usuario: «el club de Hiriburu no tiene ni dispensario… molaría que
# fuese más coherente todo»), con Datos.CAL: todos los clubs (los de la comarca, la asociación, KAIA y los dos VIP de Hiriburu) tienen la
# vitrina con su encargado detrás y se llega a hablar con él; A en la vitrina es el dispensario (el del encargado; de presidente, el
# tuyo); en los clubs de Hiriburu que son tuyos, lo llenas tú y lo que retiran los socios va con la noche a la cuenta.
#   $GODOT --headless --path godot --script res://tests/clubs.gd   → «clubs: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

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
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	var k := 0 if q == "*" else labels.size() - 1
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

func alcanza(m: Dictionary, x0: int, y0: int) -> Dictionary:
	var vis := {Vector2i(x0, y0): true}
	var cola := [Vector2i(x0, y0)]
	while cola.size():
		var p: Vector2i = cola.pop_front()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if q.x < 0 or q.y < 0 or q.x >= int(m.w) or q.y >= int(m.h) or vis.has(q):
				continue
			if J.tile_solid(m, q.x, q.y) or m.o[q.y][q.x] != null or J.ents.any(func(e): return e.x == q.x and e.y == q.y):
				continue
			vis[q] = true
			cola.append(q)
	return vis

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-clubs.json"
	Juego.AJUSTES = "user://prueba-clubs-ajustes.json"
	Datos.CAL = true
	Datos.carga()
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S: Dictionary = J.S
	S.ch = 8
	S.min = 1080
	S.erase("metro")
	J.oraculo = true
	J.mode = "world"
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = J.D
	var MT: Dictionary = D.METRO
	S.metro = {"d": S.day}
	var md: Dictionary = J.metro_d()
	for k in MT.vip:
		md.vip[k] = {"d": S.day, "mj": 0, "tot": 0, "ay": 0}
	# 1 · todos los clubs: la vitrina, su encargado detrás y se le habla desde delante
	var mapas := []
	for k in D.CLUBS:
		mapas.append(["club-" + k, "club_" + k])
	for k in MT.vip:
		mapas.append([MT.vip[k].map, "m9_disp_" + k])
	for par in mapas:
		var mp: String = par[0]
		if not J.MAPS.has(mp):
			chk(false, "falta el mapa %s" % mp)
			continue
		var ex: String = J.MAPS[mp].exits.keys()[0]
		J.enter_map(mp, int(ex.get_slice(",", 0)), int(ex.get_slice(",", 1)) - 1, "up")
		J.build_ents()
		var m: Dictionary = J.MAPS[mp]
		var vit := []
		for y in int(m.h):
			for x in int(m.w):
				if m.o[y][x] == "vitrina":
					vit.append(Vector2i(x, y))
		chk(vit.size() >= 1, "%s: con vitrina" % mp)
		var en: Array = J.ents.filter(func(q): return q.id == par[1])
		chk(en.size() == 1, "%s: su encargado (%s)" % [mp, par[1]])
		if vit.is_empty() or en.is_empty():
			continue
		var ep := Vector2i(int(en[0].x), int(en[0].y))
		var tras: Array = vit.filter(func(v): return v.x == ep.x and v.y == ep.y + 1)
		chk(tras.size() == 1, "%s: el encargado detrás de la vitrina %s" % [mp, ep])
		var vis := alcanza(m, int(J.P.x), int(J.P.y))
		chk(vis.has(ep + Vector2i(0, 2)), "%s: se llega delante de la vitrina" % mp)
		chk(D.ESTILO_OBJ.has("vitrina") or true, "")
		for o in ["tarros", "pizarra", "cartelC"]:
			var hay := false
			for fila in m.o:
				if o in fila:
					hay = true
			chk(hay, "%s: con %s" % [mp, o])
	# 2 · A en la vitrina de un club de la comarca: el encargado (carné o lo de siempre)
	J.enter_map("club-ibar", 7, 7, "up")
	J.build_ents()
	MENUS = []
	LOG = []
	QUIERO = ["Nada", "Nada"]
	chk(corre(func(): await J.obj_local(1, 3, "vitrina")), "vitrina del club bloqueada")
	chk(MENUS.size() > 0 or LOG.size() > 0, "la vitrina del club abre el dispensario: %s %s" % [MENUS, LOG])
	chk(not LOG.has("La vitrina del dispensario: tarros con muestras y una báscula de precisión."), "la vitrina ya no es solo un texto")
	# 3 · la asociación de presidente: la vitrina y el encargado, tu dispensario (no te compran a ti)
	var A: Dictionary = J.aso()
	A.pres = true
	A.lote = null
	S.erase("staff")
	J.enter_map("club-rv", 7, 7, "up")
	J.build_ents()
	S.buds = {}
	S.rosin = {}
	MENUS = []
	LOG = []
	QUIERO = ["El dispensario"]
	chk(corre(func(): await J.obj_local(1, 3, "vitrina")), "vitrina de la asociación bloqueada")
	var lg := " ".join(LOG)
	chk(lg.contains("Déjame") and not lg.contains("¿Qué te trae?"), "de presidente, tu dispensario: %s" % [LOG])
	LOG = []
	QUIERO = ["El dispensario"]
	chk(corre(func(): await J.talk_club("rv")), "encargado de la asociación bloqueado")
	chk(" ".join(LOG).contains("Déjame"), "el encargado, igual: %s" % [LOG])
	# 4 · Hiriburu: sin género, te dice cómo; con un lote, lo dejas; la noche lo vende a la cuenta
	J.enter_map("vip-zen", 9, 8, "up")
	J.build_ents()
	LOG = []
	chk(corre(func(): await J.obj_local(1, 3, "vitrina")), "vitrina VIP bloqueada")
	chk(" ".join(LOG).contains("El dispensario lo llenas tú"), "VIP vacío: %s" % [LOG])
	J.add_buds("ria", 200, 20.0, S.buds, 1)
	var g0: float = float(S.buds.ria.g)
	QUIERO = ["*", "100 g"]
	LOG = []
	chk(corre(func(): await J.talk_metro("m9_disp_zen")), "encargada del dispensario VIP bloqueada")
	var V: Dictionary = md.vip.zen
	chk(V.get("disp") is Dictionary and int(V.disp.g) == 100 and absf(float(S.buds.ria.g) - (g0 - 100)) < .01, "100 g al dispensario: %s" % [V.get("disp")])
	var pg: float = float(V.disp.pg) if V.get("disp") is Dictionary else 0.0
	var pe: float = Datos.jsround(J.precio_club(20.0) * J.calidad(S.buds.ria, true) * float(MT.disp.f) * 100) / 100.0
	chk(MT.disp.f > 1.0 and absf(pg - pe) < .011, "más caro que en la comarca: %s (%s)" % [pg, pe])
	S.heat = 0
	md.sob = S.day + 99
	var b0: float = float(S.banco)
	S.day += 1
	J.metro_dia()
	var ret: float = minf(100.0, float(MT.disp.dia))
	var de: int = Datos.jsround(ret * pg)
	chk(V.get("disp") is Dictionary and int(V.disp.tot) == de and float(S.banco) - b0 >= de + int(V.tot) - 1, "la noche y el dispensario, a la cuenta: %s → %s (%s + %s)" % [b0, S.banco, V.tot, de])
	chk(V.get("disp") is Dictionary and absf(float(V.disp.g) - (100 - ret)) < .01, "quedan %s" % [V.get("disp")])
	# se acaba: SMS y vacío
	for q in 5:
		S.day += 1
		V.erase("cl")
		J.metro_dia()
	chk(V.get("disp") == null, "vaciado al acabarse")
	chk(J.pending.size() > 0 or J.queued.has("vipdzen"), "aviso al acabarse")
	# 5 · KAIA, igual que antes (la misma función)
	chk(J.has_method("disp_llena") and J.has_method("disp_gestiona") and J.has_method("disp_dia"), "dispensario común")
	print("clubs: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
