# Ribera Verde (Godot) — las estanterías, una por baldosa (lo pidió el usuario: «o las estanterías del almacén son muy anchas para con
# la baldosa, o se necesita una baldosa de espacio entre cada estantería» y «asegúrate que todas las estanterías del mapa funcionan
# igual»): en cada mapa, lo que se pinta de cada estantería (con su contorno) cabe en sus casillas (una, o dos con la de <nombre>2),
# así que en fila no se montan. Con CAL.
#   $GODOT --headless --path godot --script res://tests/estanterias.gd   → «estanterias: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --salida <dir> (y xvfb, --rendering-driver opengl3) deja est-<mapa>.png de los mapas con estanterías en fila
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Pinta = preload("res://src/pinta.gd")
const Arte = preload("res://src/arte.gd")
const Atlas = preload("res://src/atlas.gd")

# las estanterías y armarios de baldas de todos los mapas
const EST := ["almC", "armR", "armS", "baldaS", "botesW", "cajonT", "copas", "curaQ", "estP", "estanteC", "estanteE", "estanteN",
	"humidor", "libreria", "prodL", "rackP", "rackT", "recambT", "shelfW", "tarros"]   # i18n-no
const FOTOS := ["alm-rv", "setas-g", "est-rv", "loc-erro", "loc-mendi", "club-rv", "nave-s", "loc-valde"]   # i18n-no

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

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

# lo que se pinta de o en (tx, ty), como en _arte_obj de pinta.gd: [x0, x1] en px del mapa
func rango(o: String, tx: int, ty: int):
	var gr = Atlas.cubre("obj:" + o)
	if not gr or Atlas.sobre.get("obj:" + o):
		return null
	var d := Pinta.desfase(o, tx, ty)
	var sp: String = J.sprite_local(J.deco_sprite(o))
	var f = Atlas.frame_de(gr, sp, "unica", 0, {"i": 0, "esp": d.esp})
	var ge = Atlas.cubre("obj:e-" + o)
	var fd = J.pintor._detalle_obj(o, tx)
	if fd != null:
		f = fd
		ge = null
	if ge:
		var fe = Atlas.frame_de(ge, "e-" + sp, "unica", 0, {"i": 0, "esp": d.esp})
		if fe == null:
			fe = Atlas.frame_de(ge, "e-" + o, "unica", 0, {"i": 0, "esp": d.esp})
		if fe != null:
			f = fe
	if f == null and sp != o:
		f = Atlas.frame_de(gr, o, "unica", 0, {"i": 0, "esp": d.esp})
	if f == null:
		return null
	var bb: Array = Arte.caja(f.c)
	var xp: int = tx * 16 + 8 + d.dx
	var x0: int = Datos.jsround(xp - f.cel.ancla[0]) + int(bb[0])
	return [x0, x0 + int(bb[1]) - int(bb[0])]

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-est.json"
	Juego.AJUSTES = "user://prueba-est-aj.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.S.ch = 8
	J.S.aso = {"pres": true, "v": 2, "al": {"buds": {"ria": {"g": 4000.0, "thc": 15.0}}, "rosin": {}}}
	if not J.S.has("mar"):
		J.S.mar = {}
	J.oraculo = true
	J.S.mode = "world"
	J.mode = "world"
	await process_frame
	var dir := arg("--salida")
	var vistas := {}
	for mapa in J.MAPS.keys():
		var m: Dictionary = J.MAPS[mapa]
		var ex: Array = (m.exits.keys()[0] if m.get("exits", {}).size() else "1,2").split(",")
		J.enter_map(mapa, int(ex[0]), int(ex[1]) - 1, "up")
		m = J.MAPS[mapa]
		for y in int(m.h):
			for x in int(m.w):
				var o = m.o[y][x]
				if not (o is String) or not (o in EST):
					continue
				var r = rango(o, x, y)
				chk(r != null, "%s (%d, %d): %s sin dibujo" % [mapa, x, y, o])
				if r == null:
					continue
				var c := 1
				while x + c < int(m.w) and m.o[y][x + c] == o + "2":
					c += 1
				vistas[o] = true
				chk(r[0] >= x * 16 and r[1] <= (x + c) * 16 - 1, "%s (%d, %d): %s se sale de su%s casilla%s: de %d a %d px" % [mapa, x, y, o, "s" if c > 1 else "", "s" if c > 1 else "", r[0] - x * 16, r[1] - x * 16])
		if dir != "" and mapa in FOTOS:
			J.build_ents()
			J.oraculo = false
			J.mode = "world"
			J.toast_box.hide()
			J.dlg.hide()
			for q in 2:
				await process_frame
				J.pintor.redibuja(0.0)
				for k in 4:
					await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(dir.path_join("est-%s.png" % mapa))
			J.oraculo = true
	for o in EST:   # todas, en algún mapa
		chk(vistas.has(o), "%s: no sale en ningún mapa" % o)
	print("estanterias: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)
