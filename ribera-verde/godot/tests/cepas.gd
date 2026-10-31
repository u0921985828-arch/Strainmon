# Ribera Verde (Godot) — 1.46: las cepas de setas (lo pidió el usuario: «que se puedan comprar diferentes panes… diferentes micelios…
# como razas… juntar esos micelios y crear nuevas variedades… preestablecidas en un libro de recetas… que no se permita hacer ciertos
# cruces… diferentes formas de las setas»): CEPAS en datos.json (inventadas, sin método ni dosis), los panes de Txomin, la bandeja de
# tu pan, juntar micelios en la mesa (solo lo del cuaderno; unas formas se repelen; lo que no está, no prende), el cuaderno, lo
# recogido y lo seco por cepa, el precio por cepa, cada forma dibujada y, sin Datos.CAL, el bajo de antes.
#   $GODOT --headless --path godot --script res://tests/cepas.gd   → «cepas: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también cepas-<forma>.png
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
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
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


func pinta(dir: String, k: String, V: Dictionary) -> void:
	J.SETAS_V = V
	J._dlg_fijo(J.desc_bajo(V), "EL BAJO")
	for q in 2:
		await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("cepas-%s.png" % k))
	J.SETAS_V = null

# los rectángulos de una bandeja lista de la cepa v, a u = 1
func dibuja(v: String) -> Array:
	var o := []
	J._bandeja_seta(o, {"d": J.S.day - 20, "hum": 90, "v": v}, 0, 0, 1, 7)
	return o

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-cepas.json"
	Juego.AJUSTES = "user://prueba-cepas-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "setas":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	var C: Dictionary = J.D.CEPAS
	var V: Dictionary = C.v
	S.ch = maxi(int(S.ch), int(J.D.SETAS.ch))
	var dir := arg("--pintar")
	if dir != "":
		J.enter_map("setas", 5, 4, "up")
		J.mode = "world"
		await process_frame
		J.set_process(false)
		for par in [["a", ["txuria", "urre", "iluna", "adar", "gaztain", "ilargi"]], ["b", ["ekaitz", "errota", "orri", "gautxori", "izar", "basoa"]]]:
			S.setas.bandejas = []
			for v in par[1]:
				S.setas.bandejas.append({"d": S.day - 20, "hum": 90, "v": v})
			await pinta(dir, par[0], {"i": 5})
			await pinta(dir, par[0], {"i": 5})
		J.set_process(true)
		S.setas = e.S.setas.duplicate(true)
	# 1 · el cuaderno: 12 cepas inventadas, 4 formas, las recetas de cepas que existen, sin cruces vetados y todas alcanzables
	var formas := {}
	for k in V:
		formas[V[k].f] = true
	chk(V.size() == 12 and formas.size() == 4 and C.fam.size() == 4, "12 cepas, 4 formas: %d %s" % [V.size(), formas.keys()])
	var base: Array = V.keys().filter(func(k): return V[k].has("pan"))
	chk(base.size() == 5 and base.has("txuria"), "5 panes de Txomin: %s" % [base])
	var hay := base.duplicate()
	for vuelta in 4:
		for r in C.r:
			chk(V.has(r[0]) and V.has(r[1]) and V.has(r[2]) and not V[r[2]].has("pan") and not J.veta_cepa(r[0], r[1]), "receta válida: %s" % [r])
			if hay.has(r[0]) and hay.has(r[1]) and not hay.has(r[2]):
				hay.append(r[2])
	chk(hay.size() == V.size(), "todas salen de los panes: %s" % [hay])
	chk(J.veta_cepa("adar", "txuria") and J.veta_cepa("iluna", "adar") and not J.veta_cepa("adar", "gaztain") and not J.veta_cepa("txuria", "iluna"), "lo que se repele")
	chk(J.receta_cepa("urre", "txuria") == "ilargi" and J.receta_cepa("txuria", "urre") == "ilargi" and J.receta_cepa("txuria", "iluna") == "", "la receta, en los dos órdenes")
	# 2 · los panes de Txomin, en la puerta
	S.setas = {"bandejas": [], "g": 0, "r": S.day + 30}
	S.money = 1000
	S.heat = 0
	J.enter_map("setas", 5, 4, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("B" if J.SETAS_V != null else "A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var m0: int = S.money
	QUIERO = ["Panes de micelio", "Txuria", "Urrezko", "Adartxo", "Gaztain", "Nada", "Nada"]
	chk(corre(J.talk_txomin), "panes bloqueado")
	var L: Dictionary = S.setas
	chk(m0 - S.money == int(V.txuria.pan + V.urre.pan + V.adar.pan + V.gaztain.pan) and L.panes == {"txuria": 1, "urre": 1, "adar": 1, "gaztain": 1}, "los panes: %d %s" % [m0 - S.money, L.get("panes")])
	chk(L.cd.has("urre") and L.cd.has("gaztain") and not L.cd.has("ilargi"), "lo descubierto: %s" % [L.cd])
	# 3 · juntar en la mesa: Txuria + Urrezko = 2 panes de Ilargi, en CEPAS.min
	var t0: int = int(S.min) + 1440 * int(S.day)
	LOG = []
	QUIERO = ["Juntar micelios", "Txuria", "Urrezko", "Nada"]
	chk(corre(J.mesa_setas), "juntar bloqueado")
	chk(L.panes.txuria == 0 and L.panes.urre == 0 and L.panes.ilargi == int(C.sale) and L.cd.has("ilargi"), "Ilargi: %s" % [L.panes])
	chk(int(S.min) + 1440 * int(S.day) - t0 == int(C.min) and LOG.any(func(t): return t.contains("Nueva en tu cuaderno")), "el tiempo y el aviso: %s" % [LOG])
	# 4 · lo que se repele (racimo con cúpula) y lo que no está en el cuaderno no gastan nada
	var p0: Dictionary = L.panes.duplicate()
	LOG = []
	QUIERO = ["Juntar micelios", "Adartxo", "Ilargi", "Nada"]
	chk(corre(J.mesa_setas) and L.panes == p0 and LOG.any(func(t): return t.contains("se repelen")), "se repelen: %s" % [LOG])
	LOG = []
	QUIERO = ["Juntar micelios", "Ilargi", "Gaztain", "Nada"]
	chk(corre(J.mesa_setas) and L.panes == p0 and LOG.any(func(t): return t.contains("No prende")), "no prende: %s" % [LOG])
	LOG = []
	QUIERO = ["Juntar micelios", "Gaztain", "Nada", "Nada"]
	L.panes.adar = 0
	L.panes.ilargi = 0
	chk(corre(J.mesa_setas) and LOG.any(func(t): return t.contains("otra cepa")), "un pan solo: %s" % [LOG])
	L.panes.ilargi = 2
	# 5 · 3.ª generación: Ilargi + Ekaitz = Izar
	L.panes.ekaitz = 1
	QUIERO = ["Juntar micelios", "Ilargi", "Ekaitz", "Nada"]
	chk(corre(J.mesa_setas) and L.panes.izar == 2 and L.panes.ilargi == 1 and L.panes.ekaitz == 0, "Izar: %s" % [L.panes])
	# 6 · la bandeja de tu pan (Txomin la prepara); la de Txuria, sin gastar pan
	m0 = S.money
	QUIERO = ["Comprar bandeja", "Izar", "Comprar bandeja", "Txuria", "Nada"]
	chk(corre(J.talk_txomin), "bandeja bloqueada")
	chk(L.bandejas.size() == 2 and L.bandejas[0].v == "izar" and L.bandejas[1].v == "txuria" and L.panes.izar == 1 and m0 - S.money == 2 * int(J.D.SETAS.bandeja), "las bandejas: %s %s" % [L.bandejas, L.panes])
	chk(J.desc_bajo({"i": 0}).contains("Izar"), "la bandeja dice su cepa: %s" % J.desc_bajo({"i": 0}))
	# 7 · recoger: cada cepa rinde lo suyo y se seca aparte; el armario, por cepa
	for b in L.bandejas:
		b.d = S.day - 20
	L.bandejas.append({"d": S.day - 20, "hum": 90, "v": "adar"})
	QUIERO = ["Recoger"]
	chk(corre(func(): await J.bajo_menu("")), "recoger bloqueado")
	var fv := {}
	for f in L.fr:
		fv[f.v] = int(f.g)
	chk(fv.size() == 3 and fv.has("izar") and fv.has("adar") and fv.has("txuria"), "a secar por cepa: %s" % [L.fr])
	S.day += int(J.D.SETAS_PRO.seca)
	var gs: int = J.secar_setas()
	var gv: Dictionary = J.gv_setas(L)
	var sv := 0.0
	for k in gv:
		sv += gv[k]
	chk(gs == fv.izar + fv.adar + fv.txuria and absf(sv - L.g) < 0.01 and gv.izar == fv.izar, "lo seco por cepa: %s %s" % [gv, L.g])
	chk(J.desc_armario().contains("Izar") and J.desc_armario().contains("Adartxo"), "el armario: %s" % J.desc_armario())
	# 8 · cada cepa a su precio (Izar ×2,4); lo de antes sin cepa cuenta como Txuria
	L.g += 10
	gv = J.gv_setas(L)
	chk(absf(gv.txuria - fv.txuria - 10) < 0.01, "lo de antes, Txuria: %s" % [gv])
	var esp := 0.0
	for k in gv:
		esp += gv[k] * float(J.D.SETAS.precio) * float(V[k].p)
	m0 = S.money
	QUIERO = ["Venderle"]
	chk(corre(J.talk_txomin), "venta bloqueada")
	chk(S.money - m0 == roundi(esp * floor(gv.values().reduce(func(a, b): return a + b)) / gv.values().reduce(func(a, b): return a + b)) and L.g < 1, "el precio por cepa: %d de %d" % [S.money - m0, roundi(esp)])
	chk(S.money - m0 > (fv.izar + fv.adar + fv.txuria + 10) * int(J.D.SETAS.precio), "Izar se paga mejor")
	# 9 · la mesa: un lote sale de la cepa que más hay
	L.g = 0
	L.gv = {}
	J.suma_gv(L, "gaztain", 30)
	L.g = 30
	J.suma_gv(L, "orri", 12)
	L.g = 42
	L.enc = true
	QUIERO = ["Microdosis", "Nada"]
	chk(corre(J.mesa_setas) and L.g == 32 and J.gv_setas(L).gaztain == 20 and J.gv_setas(L).orri == 12, "el lote, de la que más hay: %s" % [L.gv])
	# 10 · el cuaderno: lo tuyo con ✓, de dónde sale y lo que no se junta
	LOG = []
	MENUS = []
	QUIERO = ["El cuaderno", "✓ Ilargi", "Lo que no se junta", "Nada", "Nada"]
	chk(corre(J.mesa_setas), "cuaderno bloqueado")
	chk(MENUS.any(func(l): return l.any(func(t): return t.begins_with("✓ Izar"))) and MENUS.any(func(l): return l.any(func(t): return t.begins_with("Basoa"))), "el cuaderno: %s" % [MENUS])
	chk(LOG.any(func(t): return t.contains("Sale de juntar Txuria con Urrezko")) and LOG.any(func(t): return t.contains("se repelen")), "la receta y lo vetado: %s" % [LOG])
	# 11 · cada forma, dibujada: el sombrero de su color; el plato más ancho que la cúpula; la campana más alta
	var ancho := {}
	var alto := {}
	for v in ["txuria", "urre", "iluna", "adar", "gaztain", "izar"]:
		var R: Array = dibuja(v)
		chk(R.any(func(r): return r[4] == V[v].c[0]) and R.any(func(r): return r[4] == V[v].pie), "%s, de su color" % v)
		var w := 0
		var top := 99
		for r in R:
			if r[4] == V[v].c[0]:
				w = maxi(w, int(r[2]))
			if r[4] in V[v].c or r[4] == V[v].pie:
				top = mini(top, int(r[1]))
		ancho[v] = w
		alto[v] = top
	chk(ancho.gaztain > ancho.txuria and ancho.adar < ancho.txuria and alto.iluna < alto.txuria, "las formas: ancho %s, arriba %s" % [ancho, alto])
	Datos.CAL = false
	var R0: Array = dibuja("iluna")
	Datos.CAL = true
	chk(R0.any(func(r): return r[4] == "#9a6a3a") and not R0.any(func(r): return r[4] == V.iluna.c[0]), "sin CAL, la seta de siempre")
	# 12 · sin Datos.CAL: el bajo de antes (sin panes, sin juntar, la bandeja sin cepa)
	Datos.CAL = false
	L.bandejas = []
	MENUS = []
	QUIERO = ["Comprar bandeja", "Nada"]
	chk(corre(J.talk_txomin) and not MENUS[0].any(func(t): return t.begins_with("Panes")) and L.bandejas.size() == 1 and not L.bandejas[0].has("v"), "sin CAL: %s %s" % [MENUS, L.bandejas])
	MENUS = []
	QUIERO = ["Nada"]
	chk(corre(J.mesa_setas) and not MENUS.any(func(l): return l.has("Juntar micelios")), "sin CAL, sin juntar: %s" % [MENUS])
	Datos.CAL = true
	for x in fallos:
		print("  FALLO ", x)
	print("cepas: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
