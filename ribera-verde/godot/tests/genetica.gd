# Landrace Hunters (Godot) — MAESTRO [5]: los valores ocultos (IVs) de cada línea y planta, la planta rara (shiny), la saturación
# del mercado por pueblo y la hierba verde que se cura en tarros; sin Datos.CAL, nada de esto.
#   $GODOT --headless --path godot --script res://tests/genetica.gd   → «genetica: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-genetica.json"
	Juego.AJUSTES = "user://prueba-genetica-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.oraculo = true
	var S: Dictionary = J.S
	var D = J.D
	var IV: Dictionary = D.IVS
	S.erase("iv")
	# 1 · la línea: 4 valores de IVS.base, siempre los mismos para la misma variedad
	var L: Array = Cultivo.iv_linea(S, "ria").duplicate()
	var ok := L.size() == 4
	for v in L:
		ok = ok and int(v) >= int(IV.base[0]) and int(v) <= int(IV.base[1])
	chk(ok, "línea en %s: %s" % [IV.base, L])
	S.erase("iv")
	chk(Cultivo.iv_linea(S, "ria") == L, "la línea no depende de nada más")
	# 2 · cada planta: los de su línea ± IVS.var, entre 1 y 31, sin tocar el azar
	var pm0
	var fs := []
	ok = true
	for i in 200:
		S.day = 10 + i
		var f := Cultivo.roll_feno(S, "ria")
		fs.append(f)
		if not f.get("iv") is Array:
			ok = false
			continue
		for j in 4:
			ok = ok and absi(int(f.iv[j]) - int(L[j])) <= int(IV.var) and int(f.iv[j]) >= 1 and int(f.iv[j]) <= 31
	chk(ok, "IVs de planta en su línea ±%d" % int(IV.var))
	var dist := {}
	for f in fs:
		dist[str(f.iv)] = 1
	chk(dist.size() > 20, "las plantas varían: %d distintas" % dist.size())
	# 3 · efecto: IV 31 da más gramos y THC que IV 1, IV 16 lo mismo que sin IVs
	var p := Cultivo.nueva_planta(S, "ria")
	p.prog = 1.0
	p.health = 100.0
	var fa := {"cap": 1000.0, "g": 100.0, "thc": 0.0}
	p.f = {"id": 1, "t": 1, "y": 1}
	var g0 := Cultivo.gramos_planta(S, p, fa)
	var t0 := Cultivo.thc_cosecha(S, p, fa)
	p.f.iv = [16, 16, 16, 16]
	chk(Cultivo.gramos_planta(S, p, fa) == g0 and Cultivo.thc_cosecha(S, p, fa) == t0, "IV 16 = sin IVs")
	p.f.iv = [31, 31, 31, 31]
	var gA := Cultivo.gramos_planta(S, p, fa)
	var tA := Cultivo.thc_cosecha(S, p, fa)
	p.f.iv = [1, 1, 1, 1]
	var gB := Cultivo.gramos_planta(S, p, fa)
	var tB := Cultivo.thc_cosecha(S, p, fa)
	chk(gA > g0 and g0 > gB and absf(float(gA) / g0 - (1 + float(IV.prod))) < .02, "producción %d %d %d" % [gB, g0, gA])
	chk(tA > t0 and t0 > tB, "potencia %s %s %s" % [tB, t0, tA])
	chk(is_equal_approx(Cultivo.iv_f({"iv": [31, 1, 16, 16]}, 0), 1.0) and is_equal_approx(Cultivo.iv_f({"iv": [31, 1, 16, 16]}, 1), -1.0) and Cultivo.iv_f(null, 0) == 0.0, "iv_f")
	# 4 · herencia: las semillas suben la línea al máximo; el cruce, lo mejor de los dos padres + hasta IVS.mejora, tope 31
	S.iv = {"a": [10, 20, 30, 5], "b": [15, 12, 31, 6]}
	Cultivo.hereda_iv(S, "a", [12, 18, 31, 5])
	chk(S.iv.a == [12, 20, 31, 5], "hereda_iv: %s" % [S.iv.a])
	Cultivo.cruza_iv(S, "a", "b", "ab")
	var c: Array = S.iv.ab
	ok = true
	var mx := [15, 20, 31, 6]
	for j in 4:
		ok = ok and int(c[j]) >= mx[j] and int(c[j]) <= mini(31, mx[j] + int(IV.mejora))
	chk(ok, "cruza_iv: %s" % [c])
	S.iv.ab = [31, 31, 31, 31]
	Cultivo.cruza_iv(S, "a", "b", "ab")
	chk(S.iv.ab == [31, 31, 31, 31], "el cruce no baja una línea ya hecha")
	# 5 · la rara: 1 de cada 1/SHINY.p plantas, más o menos; a su lote «!», ×SHINY.x, el esqueje la copia, su color
	S.erase("iv")
	var nsh := 0
	for i in 20000:
		S.day = 1000 + i
		if Cultivo.roll_feno(S, "ria").get("sh"):
			nsh += 1
	var E: float = 20000 * float(D.SHINY.p)
	chk(absf(nsh - E) <= 4 * sqrt(E) + 3, "raras: %d de 20000 (esperadas %.0f)" % [nsh, E])
	pm0 = Cultivo.pm
	Cultivo.genes(S, "ria", {"id": 77})
	chk(Cultivo.pm == pm0, "IVs y raras no tiran del azar")
	var sh := Cultivo.nueva_planta(S, "ria")
	sh.f.sh = "dorada"
	sh.prog = 1.0
	chk(Datos.color_cog(S, sh) == String(D.SHINY.c.dorada) and Datos.color_cog(S, {"sid": "ria", "f": {}}) == String(Datos.strain(S, "ria").c), "color de la rara")
	var esq := {"sid": sh.sid, "f": sh.f}
	chk(esq.f.get("sh") == "dorada", "el esqueje es la misma planta")
	S.buds = {}
	J.add_buds("ria!", 10, 20)
	chk(J.lot_sid("ria!") == "ria" and J.lot_sid("ria*!") == "ria" and S.buds["ria!"].get("sh") == 1, "lote de la rara")
	chk(J.lot_nombre("ria!").ends_with(")"), "nombre: %s" % J.lot_nombre("ria!"))
	var bv: Dictionary = {"g": 10, "thc": 20, "dia": S.day - 100}
	var bs: Dictionary = bv.duplicate()
	bs.sh = 1
	chk(is_equal_approx(J.calidad(bs, true), J.calidad(bv, true) * float(D.SHINY.x)) and is_equal_approx(J.calidad(bs), J.calidad(bv)), "×%s solo en flor" % D.SHINY.x)
	chk(J.cura_de(bs).get("sh") == 1, "cura_de copia la rara")
	# la cosecha de la rara va a «ria!»
	var H: Array = Cultivo.huecos(S)
	var ih := -1
	for i in H.size():
		if i < S.pots.size():
			ih = i
			break
	if ih >= 0:
		S.pots[ih] = sh
		var r := Cultivo.cosecha(S, ih)
		chk(r.k.ends_with("!") and S.buds.has(r.k) and S.buds[r.k].get("sh") == 1, "cosecha de la rara: %s" % r.k)
	else:
		chk(false, "sin plaza para cosechar")
	# 6 · la saturación: con SATURA.g vendidos en el pueblo, el precio a la mitad; cada día se olvida SATURA.dia
	S.erase("sat")
	chk(J.saturado("ria", "town") == 1.0, "sin vender, 1")
	J.satura("ria", "town", float(D.SATURA.g) / 2)
	chk(is_equal_approx(J.saturado("ria", "town"), 1 - float(D.SATURA.baja) / 2), "a la mitad, %s" % J.saturado("ria", "town"))
	J.satura("ria", "town", float(D.SATURA.g))
	chk(is_equal_approx(J.saturado("ria", "town"), 1 - float(D.SATURA.baja)), "tope: %s" % J.saturado("ria", "town"))
	chk(J.saturado("ria", "puerto") == 1.0 and J.saturado("limon", "town") == 1.0, "solo ese pueblo y esa variedad")
	var g1: float = S.sat.town.ria
	J.sat_dia()
	chk(is_equal_approx(S.sat.town.ria, g1 * (1 - float(D.SATURA.dia))), "sat_dia olvida")
	for i in 100:
		J.sat_dia()
	chk(S.get("sat", {}).is_empty() and J.saturado("ria", "town") == 1.0, "se olvida del todo")
	# 7 · verde: recién cortada VERDE.min, seca a los VERDE.dias, curada sube VERDE.semana por semana
	var V: Dictionary = D.VERDE
	var b := {"g": 10, "thc": 20, "dia": S.day}
	chk(is_equal_approx(J.verde(b), float(V.min)), "recién cortada %s" % J.verde(b))
	b.dia = S.day - int(V.dias)
	chk(is_equal_approx(J.verde(b), 1.0), "seca a los %d días" % int(V.dias))
	b.dia = S.day - 14
	b.cu = 1.0
	chk(is_equal_approx(J.verde(b), 1 + float(V.semana) * 2), "curada 2 semanas %s" % J.verde(b))
	b.dia = S.day - 700
	chk(is_equal_approx(J.verde(b), 1 + float(V.semana) * float(V.semanas)), "tope de semanas %s" % J.verde(b))
	chk(J.verde({"g": 1}) == 1.0, "lote sin día, 1")
	chk(is_equal_approx(J.calidad({"g": 1, "dia": S.day}, false), 1.0), "los extractos no pierden por verdes")
	# 8 · sin CAL: ni IVs, ni raras, ni verde, ni rara en el precio
	Datos.CAL = false
	var f2 := Cultivo.roll_feno(S, "ria")
	chk(not f2.has("iv") and not f2.has("sh"), "sin CAL, sin IVs")
	chk(is_equal_approx(J.calidad({"g": 1, "dia": S.day, "sh": 1}, true), 1.0), "sin CAL, calidad de siempre")
	Datos.CAL = true
	print("genetica: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  FALLO ", x)
	quit(1 if fallos.size() else 0)
