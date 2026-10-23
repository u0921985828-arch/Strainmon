# Landrace Hunters (Godot) — la CannaDex única (con Datos.CAL; lo pidió el usuario: «juntarlo todo… que en CannaDex salga la misma
# información… catalogarlo por zonas o por los cruces»): la Genoteca, el diario de la tía Maite y las familias en un solo menú, con
# las variedades por familias, por generación, todas y tus cruces, y en cada una su ficha, la nota de la tía, la receta o las
# semillas, la familia y la cata. Sin CAL, la Genoteca de antes. Parte del S de la pantalla casa-extr.
#   $GODOT --headless --path godot --script res://tests/cannadex.gd   → «cannadex: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var S
var D
var n := 0
var fallos := []
var MENUS := []   # [título, etiquetas, descripciones]
var PILOTO := []  # lo que se elige, por prefijo de la etiqueta («<B>», cancelar); sin nada, la última fila
var ST := {"b": false}   # B en la próxima pulsación

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	o = o.duplicate()
	var ls := []
	var ds := []
	for it in items:
		ls.append(str(it.label) if it is Dictionary else str(it))
		ds.append(str(it.get("desc", "")) if it is Dictionary else "")
	MENUS.append([str(o.get("title", "")), ls, ds])
	var i := ls.size() - 1
	if PILOTO.size():
		var p: String = PILOTO.pop_front()
		if p == "<B>":
			ST.b = true
		for j in ls.size():
			if ls[j].begins_with(p):
				i = j
				break
	o.initial = i
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
			return false
	return true

func menu_de(t: String) -> Array:
	for m in MENUS:
		if m[0] == t:
			return m
	return []

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-cannadex.json"
	Juego.AJUSTES = "user://prueba-cannadex-ajustes.json"
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
	S = J.S
	D = J.D
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			var b: String = "B" if ST.b else "A"
			ST.b = false   # antes de pulsar: la pulsación abre el menú siguiente, que puede volver a pedir B
			J.press(b), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var DEX: Array = D.DEX
	var R: Dictionary = J.recetas()
	S.flags.erase("diario")
	S.flags.erase("pagina")

	# 1 · START: la primera fila es la CANNADEX y abre el menú único
	PILOTO = ["CANNADEX", "Volver", "SALIR"]
	MENUS.clear()
	chk(corre(J.start_menu), "START termina")
	chk(MENUS.size() > 0 and MENUS[0][1][0] == "CANNADEX", "START: la primera fila es CANNADEX (%s)" % [MENUS[0][1][0] if MENUS.size() else "-"])
	var m := menu_de("CANNADEX")
	chk(m.size() > 0, "START → CANNADEX abre la CannaDex")
	chk(m.size() > 0 and m[1].slice(0, 3) == ["POR FAMILIAS", "POR GENERACIÓN", "TODAS"], "la CannaDex: por familias, por generación y todas (%s)" % [m[1] if m.size() else "-"])
	chk(m.size() > 0 and not m[1].has("TUS CRUCES") and not m[1].has("LA ÚLTIMA PÁGINA"), "sin cruces propios ni la página, no salen")
	chk(menu_de("GENOTECA").is_empty() and menu_de("DIARIO DE LA TÍA MAITE").is_empty(), "ya no hay Genoteca ni diario aparte")

	# 2 · TODAS: una fila por variedad, en su orden; sin el diario, solo las descubiertas tienen nombre
	PILOTO = ["TODAS", "Volver", "Volver"]
	MENUS.clear()
	chk(corre(J.genoteca), "TODAS termina")
	m = menu_de("TODAS")
	chk(m.size() > 0 and m[1].size() == DEX.size() + 1, "TODAS: %d variedades y Volver (%d)" % [DEX.size(), m[1].size() if m.size() else 0])
	var mal := 0
	for j in DEX.size():
		var k: String = DEX[j]
		var nom: bool = m.size() > 0 and m[1][j].contains(D.STRAINS[k].n)
		if (S.disc.get(k) and not nom) or (not S.disc.get(k) and (nom or not m[1][j].contains("??????"))):
			mal += 1
		if m.size() and not m[1][j].begins_with("%02d " % (j + 1)):
			mal += 1
	chk(mal == 0, "sin el diario: nombre y número solo las descubiertas (%d mal)" % mal)

	# 3 · con el diario, todas con nombre y su nota dentro; con receta, la receta; si no, dónde están sus semillas
	S.flags.diario = 1
	for j in 12:
		S.disc[DEX[j]] = true
	PILOTO = ["TODAS", "Volver", "Volver"]
	MENUS.clear()
	chk(corre(J.genoteca), "TODAS con el diario termina")
	m = menu_de("TODAS")
	var sin_nom := 0
	var sin_nota := 0
	var sin_rec := 0
	var sin_fam := 0
	for j in DEX.size():
		var k: String = DEX[j]
		if m.is_empty() or not m[1][j].contains(D.STRAINS[k].n):
			sin_nom += 1
			continue
		var d: String = m[2][j]
		if D.DIARIO.has(k) and not d.contains(String(D.DIARIO[k]).left(20)):
			sin_nota += 1
		if R.has(k) and not d.contains("Receta: "):
			sin_rec += 1
		if not R.has(k) and not d.contains("Semillas: "):
			sin_rec += 1
		if J.dex_familia(k) != "" and not d.contains("Familia: "):
			sin_fam += 1
		if S.disc.get(k) and not d.contains(J.strain_line(k).get_slice("\n", 0)):
			sin_nom += 1
	chk(sin_nom == 0, "con el diario: todas con su nombre y las descubiertas con su ficha (%d)" % sin_nom)
	chk(sin_nota == 0, "la nota de la tía de cada variedad, dentro (%d sin)" % sin_nota)
	chk(sin_rec == 0, "la receta o dónde están las semillas (%d sin)" % sin_rec)
	chk(sin_fam == 0, "la familia (%d sin)" % sin_fam)
	var k0 := ""
	for k in DEX:
		if S.disc.get(k) and D.STRAINS[k].get("h"):
			k0 = k
			break
	chk(k0 != "" and J.dex_desc(k0, R, true).contains(D.STRAINS[k0].h), "Leerlo todo: con la historia de la variedad")

	# 4 · por generación: cada variedad en un solo grupo y todas dentro
	var G: Array = J.dex_generaciones()
	var vistas := {}
	var rep := 0
	for g in G:
		for k in g[1]:
			if vistas.has(k):
				rep += 1
			vistas[k] = g[0]
	chk(rep == 0 and vistas.size() == DEX.size(), "por generación: %d en un solo grupo (%d, %d repetidas)" % [DEX.size(), vistas.size(), rep])
	var gn := G.map(func(g): return g[0])
	chk(gn.has("Landraces") and gn.has("1.ª generación") and gn.has("4.ª generación"), "los grupos: landraces y de 1.ª a 4.ª (%s)" % [gn])
	chk(G.all(func(g): return g[1].all(func(k): return g[0] != "Landraces" or D.STRAINS[k].get("tipo") == "landrace")), "las landraces, todas landrace")
	PILOTO = ["POR GENERACIÓN", "Landraces", "Volver", "Volver", "Volver"]
	MENUS.clear()
	chk(corre(J.genoteca), "por generación termina")
	m = menu_de("LANDRACES")
	chk(m.size() > 0 and m[1].size() == G[0][1].size() + 1, "Landraces abre sus %d variedades" % G[0][1].size())

	# 5 · por familias: cada familia abre sus variedades con su bono
	var f0: String = D.FAMILIAS.keys()[0]
	var F: Dictionary = D.FAMILIAS[f0]
	PILOTO = ["POR FAMILIAS", String(F.n), "Volver", "Volver", "Volver"]
	MENUS.clear()
	chk(corre(J.genoteca), "por familias termina")
	m = menu_de("POR FAMILIAS")
	chk(m.size() > 0 and m[1].size() == D.FAMILIAS.size() + 1, "por familias: %d familias y Volver" % D.FAMILIAS.size())
	m = menu_de(String(F.n).to_upper())
	chk(m.size() > 0 and m[1].size() == F.s.size() + 1, "la familia %s abre sus %d variedades" % [F.n, F.s.size()])

	# 6 · tus cruces y la última página, cuando los hay
	var kc: String = DEX[0]
	S.custom["zz1"] = D.STRAINS[kc].duplicate(true)
	S.custom["zz1"].n = "Prueba Corta"
	S.disc["zz1"] = true
	S.flags.pagina = 1
	PILOTO = ["TUS CRUCES", "Volver", "Volver"]
	MENUS.clear()
	chk(corre(J.genoteca), "tus cruces termina")
	m = menu_de("CANNADEX")
	chk(m.size() > 0 and m[1].has("TUS CRUCES") and m[1].has("LA ÚLTIMA PÁGINA"), "con cruces propios y la página, salen (%s)" % [m[1] if m.size() else "-"])
	m = menu_de("TUS CRUCES")
	chk(m.size() > 0 and m[1][0] == "★ Prueba Corta", "tus cruces: la propia")

	# 7 · el ordenador: CannaDex
	PILOTO = ["CannaDex", "Volver"]
	MENUS.clear()
	chk(corre(J.pc_action), "el PC termina")
	chk(MENUS.size() > 0 and MENUS[0][1][0] == "CannaDex" and not menu_de("CANNADEX").is_empty(), "el PC: CannaDex abre la CannaDex")

	# 8 · sin CAL, la Genoteca de antes
	Datos.CAL = false
	PILOTO = ["GENOTECA", "<B>", "SALIR"]
	MENUS.clear()
	chk(corre(J.start_menu), "sin CAL termina")
	chk(MENUS.size() > 0 and MENUS[0][1][0] == "GENOTECA" and not menu_de("GENOTECA").is_empty() and menu_de("CANNADEX").is_empty(), "sin CAL: la Genoteca de antes")
	Datos.CAL = true

	for f in fallos:
		print("FALLO  ", f)
	print("cannadex: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
