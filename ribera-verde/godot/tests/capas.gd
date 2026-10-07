# Ribera Verde (Godot) — orden de las capas y cortes de la vista C, en todas las carpas y focos con campana, en cada plaza,
# con cada fase, porte y con y sin agua (sin ventana):
#   $GODOT --headless --path godot --script res://tests/capas.gd
# · arte: ningún fotograma de planta, maceta o campana toca el borde de su celda (cortado al recortar), salvo por donde se
#   apoya: la planta y la maceta abajo y la campana abajo (la boca) y arriba (cuelga del techo)
# · vcAplasta: quitar filas no deja trozos sueltos (no sube el número de manchas de 8 vecinos)
# · cada planta, con el balanceo (±1 px arriba), dentro de la pantalla y de las paredes de su fila, sin tocar la campana
#   y por debajo de su distancia al foco
# · dos plantas de la misma fila no se pisan ni balanceándose una hacia la otra
# · se pinta de atrás adelante: la más honda (cy) antes y más arriba
# · las barras de agua y cosecha (con la «!» de plaga) y el cursor de la elegida no se pisan
#   y caben en la pantalla, con cualquier plaza elegida, también con plazas vacías o secas y plantas del todo altas; los daños de plaga de cada sprite (niveles 1-3) cambian
#   píxeles de la planta y nunca su silueta ni la base del tallo; tratada, la planta de siempre
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Vista = preload("res://src/vista.gd")
const Arte = preload("res://src/arte.gd")

var n := 0
var fallos := []

func check(que: String, ok: bool) -> void:
	n += 1
	if not ok:
		fallos.append(que)
		if fallos.size() <= 40:
			print("FALLO  " + que)

func opaco(im: Image, x: int, y: int) -> bool:
	return im.get_pixel(x, y).a8 > 0

# manchas de píxeles con algo (8 vecinos)
func manchas(im: Image) -> int:
	var W := im.get_width()
	var H := im.get_height()
	var visto := {}
	var m := 0
	for y in H:
		for x in W:
			if not opaco(im, x, y) or visto.has(y * W + x):
				continue
			m += 1
			var pila := [Vector2i(x, y)]
			visto[y * W + x] = true
			while pila.size():
				var c: Vector2i = pila.pop_back()
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var a: int = c.x + dx
						var b: int = c.y + dy
						if a >= 0 and b >= 0 and a < W and b < H and not visto.has(b * W + a) and opaco(im, a, b):
							visto[b * W + a] = true
							pila.append(Vector2i(a, b))
	return m

# filas con algo: {fila: [x mínima, x máxima]}
func filas(im: Image) -> Dictionary:
	var o := {}
	for y in im.get_height():
		var a := -1
		var b := -1
		for x in im.get_width():
			if opaco(im, x, y):
				if a < 0:
					a = x
				b = x
		if a >= 0:
			o[y] = [a, b]
	return o

func _initialize() -> void:
	var D := Datos.carga()
	Arte.carga()
	# 1. arte
	for k in Arte.spr:
		if not (k.begins_with("planta-c-") or k.begins_with("maceta-c-") or k.begins_with("foco-c-")):
			continue
		for f in Arte.n_fotos(k):
			var im := Arte.foto(k, f)
			var W := im.get_width()
			var H := im.get_height()
			var borde := 0
			for x in W:
				if not k.begins_with("foco-c-"):
					borde += int(opaco(im, x, 0))
			for y in H:
				borde += int(opaco(im, 0, y)) + int(opaco(im, W - 1, y))
			check("%s/%d toca el borde de su celda en %d px" % [k, f, borde], borde == 0)
	# 2-5. cada carpa y foco
	var portes := {"i": 90, "h": 50, "s": 10}
	var progs := [.05, .2, .5, .8, 1.0]
	var apl := {}
	for t in D.CARPAS:
		for fk in D.FOCOS:
			var S := Cultivo.nuevo_estado()
			S.carpas = [{"t": t, "foco": fk}]
			var np := int(D.CARPAS[t].plazas)
			S.macetas = []
			S.pots = []
			for i in np:
				S.macetas.append("plastico7")
				S.pots.append(null)
			var g0 = Vista.geo(S, 0)
			if g0.vc == null:
				continue
			var Z: float = g0.vc.Z
			var boca: int = int(D.VCA.boca)
			var sep: float = D.FOCO_SEP[fk] * Z
			# la campana: sus píxeles en pantalla
			var fc := Arte.foto(g0.vc.foco.n)
			var campana := {}
			for y in fc.get_height():
				for x in fc.get_width():
					if opaco(fc, x, y):
						campana[Vector2i(96 + x, boca - 15 + y)] = true
			# cada plaza con cada planta: sus filas en pantalla y cuánto se mueve cada una
			var dib := {}   # i → [{c, f: {y: [a, b]}, sh: {y: 0|1}}]
			for i in np:
				dib[i] = []
				for po in portes:
					for pr in progs:
						for agua in [70.0, 0.0]:
							S.pots[i] = {"sid": "ria", "prog": pr, "water": agua, "health": 100.0, "fert": false, "pest": false, "f": {"id": 1, "t": 1, "y": 1, "i": portes[po]}}
							var g = Vista.geo(S, 0)
							var q: Dictionary
							for e in g.pl:
								if e.i == i:
									q = e
							var v: Dictionary = q.v
							var nombre := "%s %s · plaza %d · %s %d %% %s" % [t, fk, i, po, int(pr * 100), "seca" if agua <= 0 else "regada"]
							if v.p == null:
								check(nombre + ": sin sprite", false)
								continue
							var c0 := Arte.aplasta(Arte.altura(v.p.n, v.hp)[1], v.hp)
							var ka := "%s|%d" % [v.p.n, v.hp]
							if not apl.has(ka):
								apl[ka] = true
								var orig: Image = Arte.altura(v.p.n, v.hp)[1]
								var m0 := manchas(orig)
								var m1 := manchas(c0)
								check("%s a %d px: quitar filas deja %d trozos sueltos" % [v.p.n, v.hp, m1 - m0], m1 <= m0)
							var im := Vista.img_planta(S, S.pots[i], v)
							var H := im.get_height()
							var b := H - 1
							var x0: int = q.x - (im.get_width() >> 1)
							var y0: int = q.y - v.tierra - b
							var a := 1 if agua > 0 else 0
							var F := filas(im)
							var fs := {}
							var sh := {}
							var top := 999
							var pisa := 0
							var fuera := 0
							var wy: float = g.vc.w + 32 * (q.y - D.VCA.fondo) / 19.0
							var L := 120 - wy / 2
							var R := 120 + wy / 2
							for r in F:
								var s := 0
								if a:
									s = absi(Datos.jsround(a * 1.0 * pow(maxf(0, float(b - r + (r % 2)) / b), 1.5)))
								var ya: int = y0 + r
								var xa: int = x0 + F[r][0]
								var xb: int = x0 + F[r][1]
								fs[ya] = [xa, xb]
								sh[ya] = s
								top = mini(top, ya)
								if xa - s < 0 or xb + s > 239 or ya < 0 or ya > 159:
									fuera += 1
								if xa - s < L or xb + s + 1 > R:
									fuera += 1
								for x in range(xa - s, xb + s + 1):
									if campana.has(Vector2i(x, ya)):
										pisa += 1
							check(nombre + ": %d filas fuera de la pantalla o de sus paredes" % fuera, fuera == 0)
							check(nombre + ": pisa la campana en %d px" % pisa, pisa == 0)
							check(nombre + ": arriba en %d, más cerca del foco que %d" % [top, int(ceil(boca + sep))], top >= floor(boca + sep))
							# daños de plaga encima: la misma silueta, la base del tallo igual y algún píxel cambiado
							var pl: Dictionary = S.pots[i]
							for salud in [100.0, 60.0, 20.0]:
								pl.pest = true
								pl.health = salud
								var d := Vista.img_planta(S, pl, v)
								var cambia := 0
								var silueta := 0
								for y in H:
									for x in im.get_width():
										var c1 := im.get_pixel(x, y)
										var c2 := d.get_pixel(x, y)
										if c1.a8 != c2.a8 or (y >= H - 3 and c1 != c2):
											silueta += 1
										elif c1 != c2:
											cambia += 1
								check(nombre + " con plaga (nivel %d): %d px dañados, %d fuera de sitio" % [Vista.nivel_dano(pl), cambia, silueta], cambia > 0 and silueta == 0)
							pl.pest = false
							pl.health = 100.0
							check(nombre + ": tratada, sin daños", Vista.img_planta(S, pl, v).get_data() == im.get_data())
							dib[i].append({"c": nombre, "f": fs, "sh": sh, "y": q.y})
				S.pots[i] = null
			# vecinas de la misma fila
			for i in np:
				for j in range(i + 1, np):
					if dib[i].is_empty() or dib[j].is_empty() or dib[i][0].y != dib[j][0].y:
						continue
					var peor := 999
					var cual := ""
					for A in dib[i]:
						for B in dib[j]:
							for y in A.f:
								if not B.f.has(y):
									continue
								var a1: Array = A.f[y]
								var b1: Array = B.f[y]
								var gap: int
								if a1[0] <= b1[0]:
									gap = b1[0] - a1[1] - 1 - A.sh[y] - B.sh[y]
								else:
									gap = a1[0] - b1[1] - 1 - A.sh[y] - B.sh[y]
								if gap < peor:
									peor = gap
									cual = "%s / %s" % [A.c, B.c]
					check("%s %s · plazas %d y %d: aire mínimo %d px (%s)" % [t, fk, i, j, peor, cual], peor >= 0)
			# barras: todas las plazas con planta (de cada fase y porte, por turnos) y luego con plazas vacías y secas, y con
			# plantas del todo altas; con cada plaza elegida, ni las barras ni el cursor se pisan y caben en la pantalla
			for vuelta in 36:
				for i in np:
					var po: String = portes.keys()[(vuelta + i) % 3]
					var pr: float = progs[(vuelta / 3 + i) % 5] if vuelta < 30 else 1.0
					S.pots[i] = {"sid": "ria", "prog": pr, "water": 40.0, "health": 100.0, "fert": false, "pest": (vuelta + i) % 2 == 0, "f": {"id": 1, "t": 1, "y": 1, "i": portes[po]}}
					var hueco := (vuelta * 7 + i * 3) % 5   # vacía (0) o seca (1), sin ir atada al porte
					if vuelta >= 15 and hueco == 0:
						S.pots[i] = null
					elif vuelta >= 15 and hueco == 1:
						S.pots[i].dead = true
				var g = Vista.geo(S, 0)
				var conb: int = g.pl.filter(func(q): return Vista.con_barra(S, q)).size()
				for sel in range(-1, np):
					var bs := Vista.barras(S, g, sel)
					var mal := bs.size() != conb
					var cajas := bs.map(func(e): return e.r)
					if sel >= 0:
						cajas.append(Vista.caja_cursor(Vista.pos_cursor(g, sel, bs)))
					for a in cajas.size():
						var A: Rect2i = cajas[a]
						mal = mal or A.position.y < 0 or A.position.x < 0 or A.end.x > 240 or A.end.y > 160
						for b in cajas.size():
							mal = mal or (a != b and A.intersects(cajas[b]))
					for a in bs.size():
						for b in bs.size():
							mal = mal or (a != b and bs[a].caja.intersects(bs[b].caja))
					check("%s %s · vuelta %d · elegida %d: barras y cursor sin pisarse y en la pantalla" % [t, fk, vuelta, sel], not mal)
			for i in np:
				S.pots[i] = null
			# orden: de atrás adelante
			var o: Array = Vista.orden(g0)
			var bien := true
			for k in range(1, o.size()):
				bien = bien and o[k - 1].y <= o[k].y
			for a in o.size():
				for b in o.size():
					if o[a].cy > o[b].cy:
						bien = bien and a < b and o[a].y < o[b].y
			check("%s %s: de atrás adelante" % [t, fk], bien)
	for k in ["borde de su celda", "trozos sueltos", "fuera de la pantalla", "pisa la campana", "cerca del foco", "aire mínimo", "de atrás adelante", "barras", "con plaga", "tratada"]:
		var m := fallos.filter(func(f): return f.contains(k)).size()
		if m:
			print("  %s: %d" % [k, m])
	print("capas: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
