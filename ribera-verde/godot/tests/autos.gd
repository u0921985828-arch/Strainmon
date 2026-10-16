# Ribera Verde (Godot) — 1.52: la Ruderalis y las autoflorecientes (lo pidió el usuario: «se nos ha olvidado meter Ruderalis y toda la
# gran variedad de genéticas que hay AUTO»; con Datos.CAL; nombres reales, sin bancos ni criadores).
#   $GODOT --headless --path godot --script res://tests/autos.gd   → «autos: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")

var n := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# una planta sola, 'dias' días de 24 h con agua de sobra, en el ciclo dado
func crece(sid: String, ciclo: String, dias: int) -> Dictionary:
	var S := {"custom": {}}
	var p := {"sid": sid, "prog": 0.0, "water": 100.0, "health": 100.0, "pest": false, "fert": false}
	var f := {"agua": 0.0, "plaga": 0.0, "crec": 1.0, "ciclo": ciclo, "hr": 50}
	for h in dias * 24:
		p.water = 100.0
		Cultivo.plant_step(S, p, 1.0, f)
	return p

func _corre() -> void:
	Datos.CAL = true
	var D := Datos.carga()
	var A: Array = D.AUTO.dex
	# 1 · las variedades: la Ruderalis en el banco, la Lowryder y quince «Auto» de genéticas que ya estaban
	chk(A.size() == 17 and A.has("ruderalis") and A.has("lowryder"), "17 autoflorecientes (%d)" % A.size())
	chk(A.all(func(k): return D.STRAINS.has(k) and D.STRAINS[k].get("auto") and D.DIARIO.has(k)), "todas con auto y su nota en el diario")
	chk(D.DEX.size() == 104 and A.all(func(k): return D.DEX.has(k)), "en la Genoteca: %d" % D.DEX.size())
	chk(D.BANCO.any(func(b): return b[0] == "ruderalis"), "la Ruderalis en el banco del PC")
	var malas := ["dinafem", "clarks", "boveda", "seeds", "genetics", "sensi", "dutch passion", "barney", "royal queen", "fastbuds", "joint doctor", "critical auto"]
	var txt := ""
	for k in A:
		txt += (str(D.STRAINS[k].n) + " " + str(D.STRAINS[k].o) + " " + str(D.STRAINS[k].h) + " " + str(D.DIARIO[k]) + " ").to_lower()
	chk(malas.all(func(m): return not txt.contains(m)), "sin bancos ni criadores")
	var otras := A.filter(func(k): return k != "ruderalis" and k != "lowryder")
	chk(otras.all(func(k): return str(D.STRAINS[k].n).ends_with(" Auto") and str(D.STRAINS[k].o).ends_with("× Ruderalis")), "«X Auto» = X × Ruderalis")
	# 2 · la receta: cualquier genética de las quince con la Ruderalis, en cualquier orden; la Lowryder con su NL y la ruderalis mexicana
	var S := {"custom": {}}
	for k in otras:
		var r: Array = D.RECIPES.keys().filter(func(h): return D.RECIPES[h] == k)
		chk(r.size() == 1 and r[0].contains("ruderalis"), "%s: su receta (%s)" % [k, r])
		var base: String = r[0].replace("ruderalis", "").replace("+", "")
		chk(Datos.receta_de(S, base, "ruderalis") == k and Datos.receta_de(S, "ruderalis", base) == k, "%s: %s × ruderalis en los dos sentidos" % [k, base])
		chk(float(D.STRAINS[k].d) < float(D.STRAINS[base].d) and int(D.STRAINS[k].y) < int(D.STRAINS[base].y), "%s: más rápida y rinde menos que la %s" % [k, base])
	chk(D.RECIPES.get("mich+nl+ruderalis") == "lowryder", "la Lowryder")
	# 3 · florece por la edad: a 18/6 la auto llega a cosecha y la de foto se queda de madre
	var pa := crece("nlauto", "veg", 6)
	var pf := crece("nl", "veg", 6)
	chk(pa.prog >= 1.0, "la NL Auto a 18/6 llega a cosecha (%.2f)" % pa.prog)
	chk(pf.prog < .65, "la NL a 18/6 no florece (%.2f)" % pf.prog)
	var a18 := crece("nlauto", "veg", 1)
	var a12 := crece("nlauto", "flor", 1)
	chk(a12.prog < a18.prog and not a12.get("corta"), "a 12/12 la auto crece menos (%.3f < %.3f) y no se acorta" % [a12.prog, a18.prog])
	chk(crece("nlauto", "auto", 1).prog == a18.prog, "en automático, igual que a 18/6")
	# 4 · el cruce propio: auto × auto sale auto; auto × de foto, no (la auto es recesiva)
	S = {"custom": {}, "gen": {}}
	var x1 := Datos.cross_result(S, "nlauto", "wwauto")
	var x2 := Datos.cross_result(S, "nlauto", "haze")
	chk(S.custom.has(x1) and S.custom[x1].get("auto") == 1, "auto × auto: auto")
	chk(S.custom.has(x2) and not S.custom[x2].get("auto"), "auto × Haze: de foto")
	# 5 · sin CAL, como el HTML: ni Genoteca, ni receta, ni banco, ni edad
	Datos.CAL = false
	D = Datos.carga()
	chk(D.DEX.size() == 87 and not D.BANCO.any(func(b): return b[0] == "ruderalis") and Datos.receta_de({"custom": {}}, "nl", "ruderalis") == null, "sin CAL, las 87 de antes")
	chk(crece("nlauto", "veg", 6).prog < .65, "sin CAL, a 18/6 no florece")
	Datos.CAL = true
	D = Datos.carga()
	chk(D.DEX.size() == 104, "con CAL otra vez, 104")
	print("autos: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
