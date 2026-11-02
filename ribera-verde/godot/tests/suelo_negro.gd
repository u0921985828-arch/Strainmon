# Landrace Hunters (Godot) — ningún agujero negro en el suelo (lo vio el usuario: «¿Y ese pedazo de error en el mapa?», una franja
# negra en la calle): en todos los mapas montados, cada casilla de g o tiene arte de suelo o la tapa el sprite de un edificio. Si no,
# _arte_tile no pinta nada y se ve el negro de debajo (el carril de entrada del aparcamiento era «road», que no existe en el atlas).
#   $GODOT --headless --path godot --script res://tests/suelo_negro.gd   → «suelo_negro: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Pinta = preload("res://src/pinta.gd")
const Atlas = preload("res://src/atlas.gd")

var J

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func res_(k: String) -> bool:
	if k == "" or k == "<null>":
		return false
	if k == "cristalV" or k.begins_with("cv") or k == "iwT_kcs" or k == "iwB_kcs" or k == "arena" or k == "surco" or k == "surcoV":
		return true
	if k.begins_with("hito_"):
		return res_(k.substr(5))
	if Atlas.sobre.has("tile:" + k):
		return true
	if Pinta.MOSAICO_TILE.has(k):
		return true
	return Atlas.frame_de(Atlas.cubre("tile:" + k), k, "unica", 0, {"i": 0}) != null

func rects(m: Dictionary) -> Array:
	var r := []
	for b in m.get("blds", []):
		var f = Atlas.frame_de("edificio-" + String(b.get("fachada", b.id)), "base", "unica", 0, {"i": 0})
		if f:
			r.append([int(b.x0) * 16, int(b.y0) * 16, f.c.get_width(), f.c.get_height()])
		if b.get("doorX") != null:
			var p = Atlas.frame_de("edificio-" + String(b.get("puerta", b.id)), "puerta", "unica", 0, {"i": 0})
			if p:
				var dy: int = int(b.y0) + int(b.h) - 1
				r.append([int(b.doorX) * 16 - 8 + int(b.get("dx", 0)), (dy + 1) * 16 - 32, p.c.get_width(), p.c.get_height()])
	return r

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-tiles.json"
	Juego.AJUSTES = "user://prueba-tiles-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.oraculo = true
	J.S.ch = 8
	J.S.min = 12 * 60
	J.S.flags.conce = true
	Atlas.carga()
	var tot := 0
	var n := 0
	var fallos := []
	for k in J.D.MAPS.keys():
		var md = J.D.MAPS[k]
		if not md is Dictionary or not md.has("g"):
			continue
		J.enter_map(String(k), 1, 1, "right")
		var m: Dictionary = J.MAPS[String(k)]
		var rr := rects(m)
		var hue := []
		for y in m.g.size():
			for x in m.g[y].size():
				var t := String(m.g[y][x])
				if res_(t):
					continue
				var px: int = int(x) * 16
				var py: int = int(y) * 16
				var ok := false
				for r in rr:
					if px >= r[0] and py >= r[1] and px + 16 <= r[0] + r[2] and py + 16 <= r[1] + r[3]:
						ok = true
						break
				if not ok:
					hue.append("%s(%d,%d)" % [t, x, y])
		n += 1
		if hue.size():
			tot += hue.size()
			fallos.append("%s: %d casillas negras (%s)" % [k, hue.size(), ", ".join(hue.slice(0, 8))])
	for f in fallos:
		print("  ", f)
	print("suelo_negro: %d comprobaciones, %d fallos (%d casillas)" % [n, fallos.size(), tot])
	quit(1 if fallos.size() else 0)
