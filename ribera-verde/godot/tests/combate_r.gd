# Ribera Verde (Godot) — los combates, más realistas (lo pidió el usuario: «Habría que mejorar los sprites de los combates, que
# realmente sean más realistas»; con Datos.CAL): cada luchador pelea con su grupo «<grupo>-combate-r» de PixelLab, a unas 6 cabezas
# (tools/sprites/pixellab_combate.py), con las mismas animaciones que el de siempre; sin CAL, el de siempre (el oráculo).
#   $GODOT --headless --path godot --script res://tests/combate_r.gd   → «combate_r: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var S
var D
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func colores(im: Image) -> Dictionary:
	var o := {}
	for y in im.get_height():
		for x in im.get_width():
			var p := im.get_pixel(x, y)
			if p.a8:
				o[p.to_html(false)] = true
	return o

func caja(im: Image) -> Rect2i:
	return im.get_used_rect()

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-combate-r.json"
	Juego.AJUSTES = "user://prueba-combate-r-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	S = J.S
	D = J.D
	J.oraculo = true
	chk(Atlas.ok, "sin atlas")
	# 1 · con CAL, cada luchador con su grupo nuevo; sin CAL, el de siempre
	var casos := [
		["P chico", func(): S.sexo = "m"; J.B = {"kind": "thief"}; return "P", "player-combate"],
		["P chica", func(): S.sexo = "f"; J.B = {"kind": "thief"}; return "P", "player-f-combate"],
		["ladrón 1", func(): J.B = {"kind": "thief", "look": {"id": "ladron1"}}; return "E", "ladron1-combate"],
		["ladrón 2", func(): J.B = {"kind": "thief", "look": {"id": "ladron2"}}; return "E", "ladron2-combate"],
		["ladrón 3", func(): J.B = {"kind": "thief", "look": {"id": "ladron3"}}; return "E", "ladron3-combate"],
		["ladrón sin look", func(): J.B = {"kind": "thief"}; return "E", "ladron1-combate"],
		["Darko", func(): J.B = {"kind": "thief", "jefe": true, "look": {"id": "darko"}}; return "E", "darko-combate"],
		["policía", func(): J.B = {"kind": "cop", "look": D.LOOKS.cop}; return "E", "policia-combate"],
	]
	for c in casos:
		var who: String = c[1].call()
		Datos.CAL = true
		var g = J.grupo_combate(who)
		var viejo = c[2]
		if c[0] == "ladrón sin look":   # sin look, el de «combate:frente:ladron»
			viejo = Atlas.cubre("combate:frente:ladron")
		chk(g == viejo + "-r", "%s con CAL: %s (quiero %s-r)" % [c[0], g, viejo])
		Datos.CAL = false
		var g0 = J.grupo_combate(who)
		var viejo0 = "player-combate" if c[0] == "P chica" else viejo   # sin CAL no hay protagonista (es_chica): el chico, como siempre
		chk(g0 == viejo0, "%s sin CAL: %s (quiero %s)" % [c[0], g0, viejo0])
		Datos.CAL = true
	# 2 · las mismas animaciones y direcciones que el de siempre, con fps y bucle; dentro de la celda, pies en la fila 62, 15 colores
	for v in ["player-combate", "player-f-combate", "ladron1-combate", "ladron2-combate", "ladron3-combate", "darko-combate", "policia-combate"]:
		var A0: Dictionary = Atlas.d.anims[v]
		var A1 = Atlas.d.anims.get(v + "-r")
		chk(A1 != null, "%s-r no está en el atlas" % v)
		if A1 == null:
			continue
		chk(Atlas.d.celdas[v + "-r"].w == 64 and Atlas.d.celdas[v + "-r"].h == 64, "%s-r: celda %s" % [v, Atlas.d.celdas[v + "-r"]])
		var col := {}
		for a in A0:
			chk(A1.has(a), "%s-r sin «%s»" % [v, a])
			if not A1.has(a):
				continue
			chk(A1[a].fps == A0[a].fps and A1[a].bucle == A0[a].bucle, "%s-r/%s: fps %s bucle %s (de siempre %s %s)" % [v, a, A1[a].fps, A1[a].bucle, A0[a].fps, A0[a].bucle])
			for d in A0[a].dirs:
				chk(A1[a].dirs.has(d), "%s-r/%s sin la dirección %s" % [v, a, d])
				if not A1[a].dirs.has(d):
					continue
				chk(A1[a].dirs[d].size() == A0[a].dirs[d].size(), "%s-r/%s/%s: %d fotogramas (de siempre %d)" % [v, a, d, A1[a].dirs[d].size(), A0[a].dirs[d].size()])
				for i in A1[a].dirs[d].size():
					var f = Atlas.frame_de(v + "-r", a, d, 0, {"i": i})
					var im: Image = f.c
					chk(im.get_width() == 64 and im.get_height() == 64, "%s-r/%s/%s/%d: %dx%d" % [v, a, d, i, im.get_width(), im.get_height()])
					col.merge(colores(im))
					if i == 0 and a != "desmayo":
						chk(caja(im).end.y == 63, "%s-r/%s/%s: los pies en la fila %d (quiero 62)" % [v, a, d, caja(im).end.y - 1])
		chk(col.size() <= 15, "%s-r: %d colores (máximo 15)" % [v, col.size()])
		# más realista: más alto que el de siempre (unas 6 cabezas)
		var dir := "north" if v.begins_with("player") else "south"
		var h0 := caja(Atlas.frame_de(v, "base", dir, 0, {"i": 0}).c).size.y
		var h1 := caja(Atlas.frame_de(v + "-r", "base", dir, 0, {"i": 0}).c).size.y
		chk(h1 > h0, "%s-r: %d px de alto, no más que el de siempre (%d)" % [v, h1, h0])
	# 3 · la ropa (ROPA, ropa_c) también viste al de PixelLab: la camiseta azul (#c83839 → #3a6ac8), sin un píxel del rojo de serie
	for g in ["player-combate-r", "player-f-combate-r"]:
		var f = Atlas.frame_de(g, "idle", "north", 0, {"i": 0})
		var rojo := Color("#c83839").to_html(false)
		chk(colores(f.c).has(rojo), "%s: sin el rojo de la camiseta" % g)
		S.ropa = {"camiseta": 1}
		var r = J.ropa_c(f, g)
		chk(not colores(r.c).has(rojo) and colores(r.c).has(Color("#3a6ac8").to_html(false)), "%s: la camiseta azul no se pone" % g)
		S.ropa = {}
	print("combate_r: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
