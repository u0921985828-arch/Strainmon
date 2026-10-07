# Ribera Verde (Godot) — el atlas entero de PixelLab (arte/atlas.png + atlas.json, copiados del HTML por tools/godot.js) y lo
# que 01b-arte hace con él: animaciones por dirección (este ↔ oeste en espejo), fotograma por tiempo o fase, duración, cambio
# de rampa (conRampa) e iconos de los menús. Todo static: se carga una vez
extends RefCounted

const Datos = preload("res://src/datos.gd")

static var img: Image
static var d := {}           # el JSON del atlas (frames, anims, cubre, celdas, rampas, ambiente, fumador, menores)
static var fr := {}          # clave → Image
static var tx := {}          # clave de imagen → ImageTexture
static var mir := {}
static var rec := {}
static var sobre := {}       # «tile:k» / «obj:k» → [[grupo, anim], …]
static var ok := false

static func carga() -> bool:
	if ok or img:
		return ok
	img = Image.new()
	if not FileAccess.file_exists("res://arte/atlas.png"):
		return false
	img.load_png_from_buffer(FileAccess.get_file_as_bytes("res://arte/atlas.png"))
	img.convert(Image.FORMAT_RGBA8)
	d = JSON.parse_string(FileAccess.get_file_as_string("res://arte/atlas.json"))
	for g in d.anims:
		for s in d.anims[g]:
			var a: Dictionary = d.anims[g][s]
			if a.get("sobre"):
				if not sobre.has(a.sobre):
					sobre[a.sobre] = []
				sobre[a.sobre].append([g, s])
	ok = true
	return true

static func frame(k: String) -> Image:
	if not fr.has(k):
		var f: Dictionary = d.frames[k]
		fr[k] = img.get_region(Rect2i(int(f.x), int(f.y), int(f.w), int(f.h)))
	return fr[k]

static func tex(im: Image) -> ImageTexture:
	var k := im.get_instance_id()
	if not tx.has(k):
		tx[k] = ImageTexture.create_from_image(im)
	return tx[k]

static func anim_de(g, s: String):
	if not g or not ok:
		return null
	var A = d.anims.get(g)
	if A == null:
		return null
	return A.get(s)

static func cubre(k: String):
	return d.get("cubre", {}).get(k) if ok else null

# fotogramas de una dirección; si falta, la más cercana (este ↔ oeste en espejo, después sur)
static func claves_de(g, s: String, dir: String):
	var a = anim_de(g, s)
	if a == null:
		return null
	var D: Dictionary = a.dirs
	if D.has(dir):
		return [D[dir], false]
	if dir == "east" and D.has("west"):
		return [D.west, true]
	if dir == "west" and D.has("east"):
		return [D.east, true]
	if D.has("south"):
		return [D.south, false]
	if D.has("unica"):
		return [D.unica, false]
	return [D[D.keys()[0]], false]

static func tiene_dir(g, s: String, dir: String) -> bool:
	var a = anim_de(g, s)
	if a == null:
		return false
	var D: Dictionary = a.dirs
	return D.has(dir) or (dir == "east" and D.has("west")) or (dir == "west" and D.has("east"))

static func espejo(k: String) -> Image:
	if not mir.has(k):
		var s := frame(k).duplicate()
		s.flip_x()
		mir[k] = s
	return mir[k]

static func n_fotos(g, s: String) -> int:
	var a = anim_de(g, s)
	if a == null:
		return 0
	var n := 0
	for v in a.dirs.values():
		n = maxi(n, v.size())
	return n

static func fps(a) -> float:
	return float(a.fps) if a.get("fps") else 8.0

static func duracion(g, s: String) -> float:
	var a = anim_de(g, s)
	return n_fotos(g, s) * 1000.0 / fps(a) if a else 0.0

# o.i: índice fijo · o.ph: fase 0-1 del ciclo · si no, por tiempo t (ms) con fps y bucle del atlas
static func frame_de(g, s: String, dir: String, t: float, o := {}):
	var r = claves_de(g, s, dir)
	if r == null:
		return null
	var ks: Array = r[0]
	var a = anim_de(g, s)
	var n := ks.size()
	var i: int
	if o.has("i"):
		i = posmod(int(o.i), n)
	elif o.has("ph"):
		i = int(floor(o.ph * n)) % n
	else:
		i = int(floor(maxf(0, t) * (a.fps if a.get("fps") else 8) / 1000.0))
		var bucle = o.bucle if o.has("bucle") else a.get("bucle")
		i = i % n if bucle else mini(n - 1, i)
	var cel = a.get("celda")
	if cel == null:
		cel = d.celdas[g]
	var esp := true if o.get("esp") else false   # o.esp (orgánico): en espejo
	return {"c": espejo(ks[i]) if r[1] != esp else frame(ks[i]), "i": i, "n": n, "cel": cel}

# cambia colores exactos (rampa clave → rampa destino); una vez por fotograma y rampa
static func con_rampa(c: Image, mapa: Dictionary, id: String) -> Image:
	var k := "%d|%s" % [c.get_instance_id(), id]
	if rec.has(k):
		return rec[k]
	var o := c.duplicate()
	var tb := {}
	for a in mapa:
		tb[Datos.hexi(a)] = Datos.hexi(mapa[a])
	for y in o.get_height():
		for x in o.get_width():
			var p: Color = o.get_pixel(x, y)
			if p.a8 == 0:
				continue
			var n: int = (p.r8 << 16) | (p.g8 << 8) | p.b8
			if tb.has(n):
				var b: int = tb[n]
				o.set_pixel(x, y, Color8((b >> 16) & 255, (b >> 8) & 255, b & 255, p.a8))
	rec[k] = o
	return o

static func foto_misc(n: String):
	if not ok:
		return null
	return frame_de(cubre("misc:" + n), n, "unica", 0, {"i": 0})

static func grupo_look(look):
	if not ok or not look:
		return null
	var g = cubre("look:" + str(look.id))
	if g:
		return g
	var id := str(look.id)
	if id[0] == "n":
		return cubre("look:cliente" + str(1 + Datos.hash_str(id) % 6))
	if id[0] == "t":
		return cubre("look:ladron" + str(1 + Datos.hash_str(id) % 3))
	return null

# iconos de los menús: el fotograma del atlas; el cogollo de la Genoteca con el color de la variedad
static var ico := {}
static func icono(n: String):
	if not ok:
		return null
	if not ico.has(n):
		var f = frame_de("iconos", n, "unica", 0, {"i": 0})
		ico[n] = tex(f.c) if f else null
	return ico[n]

static func icono_cogollo(S, sid: String):
	if not ok:
		return null
	var s = Datos.strain(S if S else {}, sid)
	var key := "c|%s|%s" % [sid, s.c if s else ""]
	if ico.has(key):
		return ico[key]
	var t: String = Datos.carga().TIPO_COGOLLO.get(sid, "hibrido")
	var f = frame_de("cogollos-genoteca", t, "unica", 0, {"i": 0})
	if f == null or s == null:
		ico[key] = null
		return null
	var rk = d.get("rampas", {}).get("cogollos-genoteca", {}).get("cogollo")
	var c: Image = f.c
	if rk:
		var m := {}
		m[rk.rampa[0]] = Datos.shade(s.c, 50)
		m[rk.rampa[1]] = s.c
		m[rk.rampa[2]] = Datos.shade(s.c, -60)
		c = con_rampa(f.c, m, "g|" + s.c)
	ico[key] = tex(c)
	return ico[key]
