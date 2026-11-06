# Ribera Verde (Godot) — las descendencias (lo pidió el usuario: «más que más landraces me refería a meter más descendencias
# no más landraces»; con CAL): autofecundación (S1), retrocruce (BX) y línea fijada (IBL). Lo que se comprueba:
# los datos de DESC y GENETICA.ibl; que el S1 gasta una semilla, da las suyas, sube los genes y fija un nivel las rarezas;
# que el BX da variedad nueva con clave propia (no la del cruce normal de los mismos dos), nombre con su número y un % de la
# madre dentro de DESC.bx.m; que la IBL necesita DESC.ibl.sel selecciones y, al llegar, tipo_gen devuelve «ibl» (la sigma más
# baja de todas); y que nada de esto nombra método, dosis ni reactivos.
#   $GODOT --path godot --script res://tests/descendencia.gd   → «descendencia: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Desc = preload("res://src/descend.gd")

var n := 0
var fallos := []

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _s() -> Dictionary:
	return {"day": 10, "seeds": {}, "gen": {}, "iv": {}, "ra": {}, "custom": {}, "disc": {}, "fenoN": 0, "cortes": [], "ibl": {}}

func _initialize() -> void:
	Datos.PLAY = false
	Datos.CAL = true
	var D: Dictionary = Datos.carga()

	# 1 · los datos
	chk(D.has("DESC"), "DESC, en los datos")
	var E: Dictionary = D.DESC
	for k in ["corte", "clon", "s1", "bx", "ibl"]:
		chk(E.has(k) and E[k].has("n") and E[k].has("d") and E[k].has("via"), "DESC.%s con nombre, nota y vía" % k)
	chk(int(E.corte.tope) >= 2, "más de un corte guardado a la vez")
	chk(int(E.clon.sem) >= 1, "el cruce entre clones da semillas")
	chk(int(E.bx.m[0]) < int(E.bx.m[1]) and int(E.bx.m[1]) < 100, "el retrocruce tira a la madre, pero no es la madre: %s" % [E.bx.m])
	chk(D.GENETICA.has("ibl"), "GENETICA.ibl, en los datos")
	var si: float = float(D.GENETICA.ibl.sigma)
	for k in D.GENETICA:
		if k != "ibl":
			chk(si <= float(D.GENETICA[k].sigma), "la IBL varía menos que %s" % k)
	chk(int(E.ibl.sel) >= 2, "la IBL pide más de una selección")

	# 2 · el S1: gasta 1, da las suyas, sube los genes y fija un nivel las rarezas
	var S := _s()
	var sid := String(D.LANDRACES[0])
	S.seeds[sid] = 6
	S.ra[sid] = {"aroma": 1}
	var iv0: Array = Cultivo.iv_linea(S, sid).duplicate()
	chk(Desc.s1_ok(S, sid), "con semilla se puede autofecundar")
	var q := Desc.s1(S, sid)
	chk(q == int(E.s1.sem), "el S1 da %d semillas: %d" % [int(E.s1.sem), q])
	chk(int(S.seeds[sid]) == 6 - int(E.s1.gasta) + 0, "gasta %d semillas: quedan %d" % [int(E.s1.gasta), int(S.seeds.get(sid, 0))])
	chk(int(E.s1.sem) <= int(E.s1.gasta), "el S1 no multiplica semillas: gasta %d y da %d" % [int(E.s1.gasta), int(E.s1.sem)])
	chk(Desc.s1_n(S, sid) == 1, "apunta la autofecundación: %d" % Desc.s1_n(S, sid))
	var iv1: Array = Cultivo.iv_linea(S, sid)
	var sube := true
	for i in 4:
		if int(iv1[i]) != mini(31, int(iv0[i]) + int(E.s1.iv)):
			sube = false
	chk(sube, "el S1 sube los genes: %s → %s" % [iv0, iv1])
	chk(int(S.ra[sid].aroma) == 1 + int(E.s1.ra), "el S1 fija un nivel la rareza: %d" % int(S.ra[sid].aroma))
	S.seeds[sid] = 99
	while Desc.s1_ok(S, sid):
		Desc.s1(S, sid)
	chk(Desc.s1_n(S, sid) == Desc.s1_tope(), "el S1 tiene tope por línea: %d de %d" % [Desc.s1_n(S, sid), Desc.s1_tope()])
	chk(not Desc.s1_ok(S, sid), "pasado el tope, la línea ya no se autofecunda")
	S.seeds.erase(sid)
	var S1b := _s()
	chk(not Desc.s1_ok(S1b, sid), "sin semilla no se autofecunda")

	# 3 · el retrocruce: clave propia, nombre con su número y un % de la madre dentro de DESC.bx.m
	var S2 := _s()
	var a := String(D.LANDRACES[0])
	var b := String(D.LANDRACES[1])
	S2.seeds[a] = 2
	S2.seeds[b] = 2
	var h := Datos.cross_result(S2, a, b)
	chk(S2.custom.has(h) and String(S2.custom[h].ma) == a, "el híbrido propio, con su madre")
	S2.seeds[h] = 2
	chk(Desc.bx_padres(S2, h).size() == 2, "el híbrido tiene dos parentales")
	var pares := Desc.bx_ls(S2)
	chk(pares.any(func(p): return String(p[0]) == h and String(p[1]) == a), "se puede retrocruzar el híbrido con su madre")
	var r1 := Desc.bx(S2, h, a)
	chk(r1 != h and r1 != Datos.cross_result(S2, h, a), "el BX no se come la clave del cruce normal: %s" % r1)
	var C: Dictionary = S2.custom[r1]
	chk(int(C.m) >= int(E.bx.m[0]) and int(C.m) <= int(E.bx.m[1]), "el BX tira a la madre un %d %%" % int(C.m))
	chk(String(C.ma) == a and int(C.bx) == 1, "el BX apunta su madre y su número")
	chk(String(C.n).ends_with("BX1") and String(C.n).length() <= Datos.NOM_MAX, "nombre del BX: «%s»" % String(C.n))
	chk(Desc.bx_n(S2, h, a) == 1, "lleva un retrocruce apuntado")
	var r2 := Desc.bx(S2, h, a)
	chk(r2 != r1 and String(S2.custom[r2].n).ends_with("BX2"), "el segundo retrocruce es otro: «%s»" % String(S2.custom[r2].n))
	S2.seeds[r2] = 2
	var r3 := Desc.bx(S2, r2, a)
	var nombres := [String(S2.custom[r1].n), String(S2.custom[r2].n), String(S2.custom[r3].n)]
	chk(nombres[2] != nombres[0] and nombres[2] != nombres[1], "ningún nombre de BX se repite: %s" % [nombres])
	var inda: float = Datos.ind_de(S2, a)
	var indh: float = Datos.ind_de(S2, h)
	chk(absf(float(C.ind) - inda) <= absf(float(C.ind) - indh) + 1, "el BX se parece a la madre en el porte")

	# 4 · la IBL: las selecciones, y luego la sigma más baja
	var S3 := _s()
	var c := String(D.LANDRACES[2])
	S3.seeds[c] = 9
	chk(Cultivo.gen_de(S3, c) >= int(D.GEN_ESTABLE), "la landrace ya viene fijada")
	chk(Desc.ibl_ok(S3, c), "una línea fijada se puede seleccionar")
	chk(Desc.ibl_falta(S3, c) == int(E.ibl.sel), "faltan %d selecciones" % int(E.ibl.sel))
	for i in int(E.ibl.sel):
		var w := Desc.ibl(S3, c)
		chk(w == int(E.ibl.sem), "cada selección da %d semillas" % int(E.ibl.sem))
	chk(Desc.es_ibl(S3, c), "con las selecciones hechas, la línea es IBL")
	chk(Desc.ibl_falta(S3, c) == 0, "ya no falta ninguna")
	chk(Cultivo.tipo_gen(S3, c) == "ibl", "tipo_gen dice ibl: %s" % Cultivo.tipo_gen(S3, c))
	var L3: Array = Cultivo.iv_linea(S3, c)
	var alto := true
	for i in 4:
		if int(L3[i]) < int(E.ibl.iv):
			alto = false
	chk(alto, "la IBL no baja de %d en sus genes: %s" % [int(E.ibl.iv), L3])
	chk(not Desc.ibl_ok(S3, c), "una IBL ya no se vuelve a seleccionar")
	# una línea sin fijar no se puede fijar a conciencia todavía
	var S4 := _s()
	S4.seeds[c] = 3
	S4.gen[c] = 2
	chk(not Desc.ibl_ok(S4, c), "una F2 no se fija a conciencia: antes hay que estabilizarla")

	# 5 · el corte de madre: nombre propio, el fenotipo tal cual y su tope
	var S5 := _s()
	var f := {"id": 1, "t": 1.2, "y": 1.1, "i": 80.0, "ra": ["aroma"]}
	var j := Desc.corte_pon(S5, sid, f)
	chk(j == 0 and Desc.cortes(S5).size() == 1, "el corte se guarda")
	chk(String(Desc.cortes(S5)[0].n).contains(Datos.strain(S5, sid).n), "el corte lleva el nombre de su variedad: «%s»" % String(Desc.cortes(S5)[0].n))
	chk(Desc.cortes(S5)[0].f == f, "el fenotipo queda tal cual")
	chk(Desc.corte_desc(S5, Desc.cortes(S5)[0]).contains("80"), "la ficha del corte dice su % índica")
	while Desc.cortes(S5).size() < Desc.corte_tope():
		Desc.corte_pon(S5, sid, f)
	chk(Desc.corte_pon(S5, sid, f) == -1, "no caben más de %d cortes" % Desc.corte_tope())
	Desc.corte_quita(S5, 0)
	chk(Desc.cortes(S5).size() == Desc.corte_tope() - 1, "el corte se tira")

	# 6 · ni método, ni dosis, ni reactivos
	var prohibido := ["colchicin", "ppm", "mg/l", "mg/ml", "giberel", "tiosulfato", "plata coloidal"]
	var mal := []
	for p in ["res://src/descend.gd", "res://datos/datos.json", "res://../tools/descendencia.py"]:
		var t := FileAccess.get_file_as_string(p).to_lower()
		for x in prohibido:
			if t.contains(x):
				mal.append("%s: %s" % [p, x])
	chk(mal.is_empty(), "nada de método ni dosis: %s" % [mal])

	if fallos.is_empty():
		print("descendencia: %d comprobaciones, 0 fallos" % n)
		quit(0)
	else:
		print("descendencia: %d comprobaciones, %d fallos" % [n, fallos.size()])
		for f2 in fallos:
			print("  · " + f2)
		quit(1)
