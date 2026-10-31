# Ribera Verde (Godot) — la translucidez en todas las baldosas (lo pidió el usuario: «revisa cada baldosa para asegurar que no hay
# errores de transparencia y destellos cuando opaca algún objeto»; con CAL): en cada mapa, el protagonista anda píxel a píxel de cada
# casilla libre a la de la derecha y a la de abajo junto a lo alto (pinta.gd tapa_obj) y se mira que
#   - las piezas seguidas de un mismo mueble en su fila se vuelvan translúcidas juntas (sin medio mostrador entero), salvo los árboles
#     y el monte (SOLAPE_LIBRE), que solo lo hacen donde le pisan el cuerpo;
#   - nada que no sea árbol o monte se encienda y se apague en 1-3 px (destello).
#   $GODOT --headless --path godot --script res://tests/tapa_mapas.gd   → «tapa_mapas: N comprobaciones, 0 fallos»
extends SceneTree
const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")
var J
func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()
func _corre() -> void:
	Juego.GUARDADO = "user://prueba-tapa-mapas.json"
	Juego.AJUSTES = "user://prueba-tapa-mapas-aj.json"
	Datos.CAL = true
	Atlas.carga()
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.S = e.S.duplicate(true)
	J.oraculo = true
	J.S.ch = 9
	var ns: Dictionary = J.new_state()
	for k in ns:
		if not J.S.has(k):
			J.S[k] = ns[k]
	if not (J.S.get("loc") is Dictionary):
		J.S.loc = {}
	if not (J.S.get("mar") is Dictionary):
		J.S.mar = {}
	if J.S.get("aso") is Dictionary and J.S.aso.get("al") is Dictionary and not J.S.aso.al.has("buds"):
		J.S.aso.erase("al")
	J.queued.clear()
	J.pending.clear()
	var Pn = J.pintor
	var tot_par := 0
	var tot_flk := 0
	var tot_corto := 0
	var tot_pos := 0
	var ej := []
	var vistos := {}
	for mk in J.MAPS.keys():
		if J.D.ZONAS.has(mk):
			continue
		var m: Dictionary = J.MAPS[mk]
		J.enter_map(mk, 1, 1, "down")
		J.mode = "world"
		J.SENT = null
		Pn.cam = Vector2i.ZERO
		Pn._tapa_reg.clear()
		for ty in m.o.size():
			for tx in m.o[ty].size():
				var oo = m.o[ty][tx]
				if oo and oo != "carpa":
					Pn._arte_obj(oo, tx, ty, [], [])
		var cs: Array = []
		for k in Pn._tapa_reg:
			var r: Dictionary = Pn._tapa_reg[k]
			var q: PackedStringArray = k.split(",")
			cs.append({"o": r.o, "x": int(q[0]), "y": int(q[1]), "c": r.c, "px": r.x, "py": r.y})
		if cs.is_empty():
			continue
		var P = J.P
		var tapa := func(c) -> bool: return Pn.tapa_obj(c.x, c.y)
		for y in int(m.h):
			for x in int(m.w):
				if not J.pisable(m, x, y) or (m.o[y][x] != null and m.o[y][x] != ""):
					continue
				# objetos cerca
				var cerca := cs.filter(func(c): return absi(c.x - x) <= 4 and c.y - y >= 0 and c.y - y <= 6)
				if cerca.is_empty():
					continue
				for dv in [[1, 0], [0, 1]]:
					var nx: int = x + dv[0]
					var ny: int = y + dv[1]
					if nx >= int(m.w) or ny >= int(m.h) or not J.pisable(m, nx, ny) or (m.o[ny][nx] != null and m.o[ny][nx] != ""):
						continue
					var cambios := {}
					Pn._tapa_mem.clear()
					var corrida := {}
					var prev := {}
					for s in 17:
						P.px = x * 16 + dv[0] * s
						P.py = y * 16 + dv[1] * s
						tot_pos += 1
						var est := {}
						Pn._tapa_res.clear()
						for c in cerca:
							var t: bool = tapa.call(c)
							est[c] = t
							if prev.has(c) and prev[c] != t:
								cambios[c] = int(cambios.get(c, 0)) + 1
								if not t and int(corrida.get(c, 0)) <= 3:
									tot_corto += 1
									if true:
										ej.append("DESTELLO %s %s (%d,%d) %d px andando de (%d,%d) %s" % [mk, c.o, c.x, c.y, corrida.get(c, 0), x, y, dv])
							corrida[c] = int(corrida.get(c, 0)) + 1 if t else 0
						prev = est
						# piezas seguidas del mismo mueble: una translúcida y la de al lado no
						for a in cerca:
							if not est[a]:
								continue
							for b in cerca:
								if b == a or est[b] or b.o != a.o or b.y != a.y or absi(b.x - a.x) != 1:
									continue
								var ra := Rect2i(a.px, a.py, a.c.get_width(), a.c.get_height())
								var rb := Rect2i(b.px - 1, b.py, b.c.get_width() + 2, b.c.get_height())
								if ra.intersects(rb):
									tot_par += 1
									if not ("PARTIDO " + mk + " " + a.o) in vistos:
										vistos["PARTIDO " + mk + " " + a.o] = 1
										ej.append("PARTIDO %s %s (%d,%d)/(%d,%d) pj (%d,%d)" % [mk, a.o, a.x, a.y, b.x, b.y, P.px, P.py])
					for c in cambios:
						if cambios[c] > 1:
							tot_flk += 1
	var malos := ej.filter(func(t): return t.begins_with("PARTIDO") or t.begins_with("DESTELLO"))
	var de_mueble := malos.filter(func(t): return not t.split(" ")[2] in J.SOLAPE_LIBRE)
	print("tapa_mapas: %d posiciones, %d piezas partidas y %d destellos de árboles y monte" % [tot_pos, malos.size() - de_mueble.size(), tot_corto])
	var n := tot_pos
	var fallos := de_mueble.slice(0, 20)
	if tot_pos < 100000:
		fallos.append("solo %d posiciones" % tot_pos)
	print("tapa_mapas: %d comprobaciones, %d fallos" % [n + de_mueble.size(), fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
