# Ribera Verde (Godot) — 1.47 (lo pidió el usuario, con Datos.CAL): catar cualquier lote en la cantidad que quieras hasta un tope,
# fumar con lo del estanco y lo del grow, un estanco en cada pueblo, la vitrina del grow, las mesas de los sofás de los clubs de
# frente a 3/4 y GAUA grande con el reservado arriba y la cristalera en el suelo.
#   $GODOT --headless --path godot --script res://tests/ocio.gd   → «ocio: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también ocio-<sitio>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

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
	var q: String = QUIERO.pop_front() if QUIERO.size() and not labels.has("TENGO 18 O MÁS") else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
			break
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
			print("  bloqueo: fin %s libre %s modo %s" % [st.fin, J.is_free(), J.mode])
			return false
	return true

func llega(mapa: String, de: Array, a: Array) -> bool:
	var m: Dictionary = J.MAPS[mapa]
	var v := {"%d,%d" % de: true}
	var q := [de]
	while q.size():
		var c: Array = q.pop_front()
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			var nx: int = c[0] + d[0]
			var ny: int = c[1] + d[1]
			if nx == a[0] and ny == a[1]:
				return true
			var kk := "%d,%d" % [nx, ny]
			if not v.has(kk) and nx >= 0 and ny >= 0 and nx < int(m.w) and ny < int(m.h) and J.pisable(m, nx, ny) and not m.o[ny][nx]:
				v[kk] = true
				q.append([nx, ny])
	return false

func foto(dir: String, k: String) -> void:
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("ocio-%s.png" % k))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-ocio.json"
	Juego.AJUSTES = "user://prueba-ocio-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	var D = J.D
	S.ch = maxi(int(S.ch), 6)
	S.loc = {}
	S.money = 5000
	var dir := arg("--pintar")
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	J.enter_map("town", 16, 17, "up")
	J.mode = "world"
	# 1 · catar lo que sea: cogollos, de 0,1 a 1 g; extracto, de 0,1 a 0,5 g
	S.buds = {"ak47": {"g": 10.0, "thc": 18.0, "dia": S.day}, "ria": {"g": 0.6, "thc": 20.0, "dia": S.day}}
	S.rosin = {"ak47~rosin": {"g": 2.0, "thc": 60.0}}
	S.catas = {}
	MENUS = []
	QUIERO = ["Catar", "0,25"]
	chk(corre(func(): await J.lote_accion("ak47")) and is_equal_approx(float(S.buds.ak47.g), 9.75) and S.buds.ak47.get("cata") and S.catas.has("ak47"),
		"catar 0,25 g de cogollos (%s g)" % S.buds.ak47.g)
	chk(MENUS.size() >= 2 and MENUS[1] == ["0,1 g", "0,25 g", "0,5 g", "1 g", "Nada"], "las cantidades de cogollos %s" % [MENUS.slice(0, 2)])
	MENUS = []
	QUIERO = ["Catar", "0,6"]
	chk(corre(func(): await J.lote_accion("ria")) and not S.buds.has("ria"), "catar lo que queda, 0,6 g (%s)" % [S.buds.get("ria")])
	chk(MENUS.size() >= 2 and MENUS[1].has("0,6 g") and not MENUS[1].has("1 g"), "el tope, lo que queda %s" % [MENUS.slice(0, 2)])
	MENUS = []
	QUIERO = ["Catar", "0,2"]
	LOG = []
	chk(corre(func(): await J.extr_accion("ak47~rosin")) and is_equal_approx(float(S.rosin["ak47~rosin"].g), 1.8) and S.catas.has("r:ak47~rosin")
		and LOG.any(func(t): return t.contains("Te deja tocado")), "catar 0,2 g de extracto (%s, %s)" % [S.rosin["ak47~rosin"].g, LOG])
	chk(MENUS.size() >= 2 and MENUS[1] == ["0,1 g", "0,2 g", "0,3 g", "0,5 g", "Nada"], "las cantidades de extracto %s" % [MENUS.slice(0, 2)])
	# 2 · fumar: sin nada, no; con la pipa, el extracto; con el vaporizador, menos calor; el porro con grinder, 0,4 g
	S.items.erase("papel")
	S.items.erase("mechero")
	LOG = []
	chk(corre(func(): await J.fumar_sentado()) and LOG.any(func(t): return t.contains("en el estanco")), "sin papel ni mechero: %s" % [LOG])
	S.buds = {}
	S.items.pipa = 1
	S.items.mechero = 1
	S.heat = 0
	chk(corre(func(): await J.fumar_sentado()) and is_equal_approx(float(S.rosin["ak47~rosin"].g), 1.7) and float(S.heat) == 3.0, "la pipa: 0,1 g de extracto (%s, calor %s)" % [S.rosin["ak47~rosin"].g, S.heat])
	S.items.erase("pipa")
	S.items.vapo = 1
	S.heat = 0
	chk(corre(func(): await J.fumar_sentado()) and is_equal_approx(float(S.rosin["ak47~rosin"].g), 1.6) and float(S.heat) == 1.0, "el vapo: calor 1 (%s)" % S.heat)
	S.items.erase("vapo")
	S.rosin = {}
	S.buds = {"ak47": {"g": 10.0, "thc": 18.0, "dia": S.day}}
	S.items.papel = 2
	S.items.grinder = 1
	S.items.tabaco = 5.0
	QUIERO = ["Solo hierba"]
	chk(corre(func(): await J.fumar_sentado()) and is_equal_approx(float(S.buds.ak47.g), 9.6) and int(S.items.papel) == 1, "el porro con grinder: 0,4 g (%s)" % S.buds.ak47.g)
	QUIERO = ["Con tabaco"]
	chk(corre(func(): await J.fumar_sentado()) and is_equal_approx(float(S.buds.ak47.g), 9.3) and is_equal_approx(float(S.items.tabaco), 4.3), "con tabaco: 0,3 g y 0,7 de tabaco (%s, %s)" % [S.buds.ak47.g, S.items.tabaco])
	# 2b · 1.57.1: el extracto en el porro, solo con tabaco (0,1 g); sin tabaco, no (a la pipa)
	S.buds = {}
	S.rosin = {"ak47~rosin": {"g": 1.0, "thc": 60.0, "dia": S.day}}
	S.items.papel = 3
	LOG = []
	QUIERO = ["Solo hierba"]
	chk(corre(func(): await J.fumar_sentado()) and is_equal_approx(float(S.rosin["ak47~rosin"].g), 1.0) and LOG.any(func(t): return t.contains("solo se lía con tabaco")), "el extracto sin tabaco, no: %s" % [LOG])
	LOG = []
	QUIERO = ["Con tabaco"]
	chk(corre(func(): await J.fumar_sentado()) and is_equal_approx(float(S.rosin["ak47~rosin"].g), 0.9) and is_equal_approx(float(S.items.tabaco), 3.6) and LOG.any(func(t): return t.contains("con tabaco")), "el extracto con tabaco: 0,1 g (%s, %s, %s)" % [S.rosin["ak47~rosin"].g, S.items.tabaco, LOG])
	S.rosin = {}
	# 3 · los estancos: la puerta y el rótulo en su pueblo, se llega desde la calle, el estanquero y la compra
	for k in D.ESTANCO.k:
		var E: Dictionary = D.ESTANCO.k[k]
		J.enter_map(E.map, int(E.x), int(E.dy) + 1, "up")
		var m: Dictionary = J.MAPS[E.map]
		var dk := "%d,%d" % [int(E.x), int(E.dy)]
		chk(m.doors.has(dk) and m.doors[dk].to == "est-" + k and m.g[int(E.dy)][int(E.x)] == E.tile, "%s: la puerta" % k)
		chk(m.blds.any(func(b): return b.get("rotulo") == "rotuloE"), "%s: el rótulo" % k)
		var sal = m.exits.keys()[0].split(",") if m.exits.size() else m.doors.keys()[0].split(",")
		chk(J.pisable(m, int(E.x), int(E.dy) + 1) and not m.o[int(E.dy) + 1][int(E.x)] and llega(E.map, [int(E.x), int(E.dy) + 1], [int(sal[0]), int(sal[1])]), "%s: se llega a la puerta" % k)
		J.enter_map("est-" + k, 4, 5, "up")
		chk(J.ents.any(func(q): return q.id == "est_" + k), "%s: el estanquero" % k)
		chk(llega("est-" + k, [4, 5], [2, 4]) and llega("est-" + k, [2, 5], [4, 6]), "%s: del mostrador a la salida" % k)
	# 3b · el cajero (1.47, lo pidió el usuario: «está detrás de la farola… asegúrate de que no haya pasado en otros pueblos»):
	# en ningún mapa de calle, una farola delante de un cajero ni de una puerta; al cajero se llega
	var tapa := []
	var cajeros := 0
	for mp in J.MAPS.keys():
		if not J.D.ZONAS.has(mp):
			continue
		J.enter_map(mp, 0, 0, "down")
		var mm: Dictionary = J.MAPS[mp]
		for y in range(mm.h - 1):
			for x in mm.w:
				var o = mm.o[y][x]
				var delante = mm.o[y + 1][x]
				if o == "cajero":
					cajeros += 1
					if not J.pisable(mm, x, y + 1) or delante:
						tapa.append("%s %d,%d" % [mp, x, y])
				if mm.doors.has("%d,%d" % [x, y]) and (delante == "lamp" or (y + 2 < mm.h and mm.o[y + 2][x] == "lamp")):
					tapa.append("%s puerta %d,%d" % [mp, x, y])
	chk(cajeros >= 5 and tapa.is_empty(), "ningún cajero ni puerta detrás de una farola (%d cajeros; %s)" % [cajeros, tapa])
	J.enter_map("town", 30, 9, "up")
	chk(J.MAPS.town.o[8][30] == "cajero" and J.MAPS.town.o[8][31] == null and J.MAPS.town.o[9][31] == "lamp" and llega("town", [30, 9], [27, 9]), "el cajero del pueblo, una casilla a la izquierda de la farola")
	S.items.erase("papel")
	S.items.erase("mechero")
	var m0: int = S.money
	QUIERO = ["Librillo", "Mechero"]
	J.enter_map("est-puerto", 2, 5, "up")
	J.P.dir = "up"
	chk(corre(func(): J.interact()) and int(S.items.get("papel", 0)) == 50 and int(S.items.get("mechero", 0)) == 1 and S.money == m0 - 2, "el estanco: librillo y mechero (%s, %s €)" % [S.items.get("papel"), m0 - S.money])
	# 4 · el grow: las pipas y demás, en la vitrina y en el mostrador; una de cada
	J.enter_map("shop", 4, 6, "up")
	chk(J.MAPS.shop.o[6][7] == "vitrinaP" and J.MAPS.shop.o[6][8] == "vitrinaP2", "la vitrina en el grow de Kiko")
	S.items.erase("bong")
	MENUS = []
	QUIERO = ["Bong"]
	chk(corre(func(): await J.shop()) and int(S.items.get("bong", 0)) == 1, "el bong, en el grow")
	chk(MENUS.size() >= 2 and MENUS[0].has("Bong de cristal") and not MENUS[0].has("Grinder de aluminio") and not MENUS[1].has("Bong de cristal"), "una de cada %s" % [MENUS.slice(0, 2)])
	J.enter_map("growcity", 5, 7, "up")
	chk(J.MAPS.growcity.o[5][9] == "vitrinaP", "la vitrina en GROW IBARBIDE")
	# 5 · las mesitas de los clubs, de frente a 3/4 y de dos casillas
	for s in ["w-mesita", "w-mesita-kalea", "w-mesita-itsaso", "w-mesita-fundicion", "w-mesita-ensanche"]:
		var f = Atlas.frame_de("ocio-ancho", s, "unica", 0, {"i": 0})
		chk(f != null and f.c.get_width() == 48, "%s" % s)
	# 6 · GAUA: la planta baja grande, la pista y la escalera; sin mesa no se sube; con mesa, arriba, con la cristalera encima de la pista
	S.min = 24 * 60 - 30
	J.enter_map("ensanche", 38, 9, "up")
	chk(int(J.MAPS.ensanche.doors["38,8"].x) == 10 and int(J.MAPS.ensanche.doors["38,8"].y) == 10, "la puerta de GAUA, a la entrada nueva")
	J.enter_map("disco", 10, 10, "up")
	var md: Dictionary = J.MAPS.disco
	chk(int(md.w) == 22 and int(md.h) == 12 and md.g[7][10] == "baile" and md.o[2][18] == "escaleraD", "GAUA, 22 × 12")
	chk(J.ents.any(func(q): return q.id == "dj" and int(q.x) == 10) and J.ents.any(func(q): return q.id == "rrpp"), "su gente en su sitio")
	chk(llega("disco", [10, 10], [18, 3]) and llega("disco", [10, 10], [2, 5]) and llega("disco", [10, 10], [10, 4]), "de la puerta a la escalera, la barra y la cabina")
	J.noche_gaua().mesa = 0
	J.enter_map("disco", 18, 3, "up")
	LOG = []
	chk(corre(func(): J.interact()) and J.S.map == "disco" and LOG.any(func(t): return t.contains("Sin mesa")), "sin mesa, no se sube")
	J.noche_gaua().mesa = 1
	chk(corre(func(): J.interact()) and J.S.map == "disco-vip" and J.P.x == 18 and J.P.y == 3, "con mesa, al reservado")
	var mv: Dictionary = J.MAPS["disco-vip"]
	var igual := true
	for y in md.h:
		for x in md.w:
			if md.g[y][x] == "baile" and mv.g[y][x] != "cristalV":
				igual = false
	chk(igual, "la cristalera, encima de toda la pista")
	var mas := 0   # 1.47 (lo pidió el usuario): por el cristal, algo más que la pista
	for y in md.h:
		for x in md.w:
			if mv.g[y][x] == "cristalV" and md.o[y][x] != null:
				mas += 1
	var gente := 0
	for d in J.D.NPCDEF:
		if d.map == "disco" and J.npc_cond(d) and mv.g[int(d.y)][int(d.x)] == "cristalV" and not d.id.begins_with("baila"):
			gente += 1
	chk(mas >= 4 and gente >= 2, "por el cristal, la barra, los altavoces y gente que no baila (%d cosas, %d personas)" % [mas, gente])
	chk(J.D.NPCDEF.all(func(d): return d.map != "disco-vip" or (mv.g[int(d.y)][int(d.x)] != "cristalV" and mv.o[int(d.y)][int(d.x)] == null)), "nadie del reservado encima del cristal ni de un mueble")
	chk(J.ents.any(func(q): return q.id == "camareraV") and llega("disco-vip", [18, 3], [10, 4]) and llega("disco-vip", [18, 3], [3, 7]), "la barra y las mesas del reservado")
	if dir != "":
		J.set_process(false)
		J.mode = "world"
		J.P.x = 10
		J.P.y = 6
		J.P.px = 160.0
		J.P.py = 96.0
		await foto(dir, "vip")
		await foto(dir, "vip")
		J.set_process(true)
	J.P.x = 18
	J.P.y = 3
	J.P.px = 18 * 16.0
	J.P.py = 3 * 16.0
	J.P.dir = "up"
	chk(corre(func(): J.interact()) and J.S.map == "disco", "y abajo")
	S.min = 7 * 60
	J.enter_map("disco-vip", 18, 3, "up")
	chk(corre(func(): J.on_step_end()) and J.S.map == "ensanche", "a las siete, el portero echa también del reservado")
	if dir != "":
		J.set_process(false)
		S.min = 24 * 60 - 30
		for q in [["est-puerto", 4, 5], ["est-erro", 4, 5], ["disco", 10, 9], ["club-ibar", 8, 5], ["club-puerto", 7, 5], ["club-valde", 6, 5], ["club-ens", 6, 5], ["club-rv", 5, 6], ["shop", 5, 6], ["growcity", 6, 7]]:
			J.enter_map(q[0], q[1], q[2], "up")
			J.mode = "world"
			await foto(dir, q[0])
			await foto(dir, q[0])
		for k in D.ESTANCO.k:
			var E: Dictionary = D.ESTANCO.k[k]
			J.enter_map(E.map, int(E.x), int(E.dy) + 2, "up")
			J.mode = "world"
			await foto(dir, "fuera-" + k)
			await foto(dir, "fuera-" + k)
	print("ocio: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit()
