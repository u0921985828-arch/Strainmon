# Landrace Hunters (Godot) — la paleta del arte, cerrada: cada hoja de arte/*.png solo usa los colores que declara
# art/paleta/ribera.json («arte», medida con «node tools/sprites/paleta.js --solo-arte») y ningún píxel es semitransparente.
# Antes, el control de paleta se hacía contra «maestra» (121 colores sacados del arte procedural de art/referencias): fallaba
# en todas las hojas y no discriminaba nada. Esta sí: si un sprite nuevo mete un tono que no está en la lista, falla, y para
# que pase hay que volver a medir la paleta a propósito.
#   $GODOT --headless --path godot --script res://tests/paleta.gd   → «paleta: N comprobaciones, 0 fallos»
extends SceneTree

const RUTA := "../art/paleta/ribera.json"

var n := 0
var fallos := []

func _initialize() -> void:
	var f := ProjectSettings.globalize_path("res://").path_join(RUTA)
	var txt := FileAccess.get_file_as_string(f)
	if txt.is_empty():
		print("FALLO no se puede leer ", f)
		print("paleta: 0 comprobaciones, 1 fallos")
		quit(1)
		return
	var pal = JSON.parse_string(txt)
	var hojas: Dictionary = pal.get("arte", {}).get("hojas", {})
	# 1 · toda hoja del juego, declarada (una nueva no se cuela sin paleta)
	var dir := DirAccess.open("res://arte")
	var en_disco := []
	for x in dir.get_files():
		if x.ends_with(".png"):
			en_disco.append(x)
	en_disco.sort()
	for x in en_disco:
		n += 1
		if not hojas.has(x):
			fallos.append("arte/%s no tiene paleta en art/paleta/ribera.json («arte»): mide con «node tools/sprites/paleta.js --solo-arte»" % x)
	for x in hojas:
		n += 1
		if not en_disco.has(x):
			fallos.append("art/paleta/ribera.json declara arte/%s, que ya no existe" % x)
	# 2 · cada hoja, dentro de su lista; ni un píxel semitransparente
	for x in en_disco:
		if not hojas.has(x):
			continue
		var decl := {}
		for c in String(hojas[x].lista).split(" ", false):
			decl[c] = false
		var img := Image.new()
		img.load_png_from_buffer(FileAccess.get_file_as_bytes("res://arte/" + x))
		img.convert(Image.FORMAT_RGBA8)
		var fuera := {}
		var semi := 0
		for v in _colores(img):
			var a: int = (v >> 24) & 0xFF
			if a == 0:
				continue
			if a < 255:
				semi += 1
				continue
			var h := "%02x%02x%02x" % [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF]
			if decl.has(h):
				decl[h] = true
			else:
				fuera[h] = true
		n += 1
		if not fuera.is_empty():
			var l := fuera.keys()
			l.sort()
			fallos.append("arte/%s usa %d colores que no están en su paleta: %s%s" % [x, l.size(), ", ".join(l.slice(0, 8)), " …" if l.size() > 8 else ""])
		n += 1
		if semi:
			fallos.append("arte/%s tiene %d colores con alfa a medias (el arte va con alfa binario)" % [x, semi])
		# la paleta se mide del propio arte (tools/sprites/paleta.js --solo-arte), asi que un color declarado que la hoja
		# no usa es paleta vieja: o el arte cambio sin volver a medirla, o sobra una entrada. Tambien es fallo
		var sinu := []
		for c in decl:
			if not decl[c]:
				sinu.append(c)
		n += 1
		if not sinu.is_empty():
			sinu.sort()
			fallos.append("arte/%s declara %d colores que ya no usa (vuelve a medir la paleta): %s%s"
				% [x, sinu.size(), ", ".join(sinu.slice(0, 8)), " …" if sinu.size() > 8 else ""])
		print("  %s: %d colores declarados, %d sin usar" % [x, decl.size(), sinu.size()])
	for x in fallos:
		print("FALLO ", x)
	print("paleta: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos else 0)

# los colores distintos de la imagen (RGBA8 en un entero por píxel): ordenar es nativo y de ahí se salta de valor en valor,
# así no hay un paso de GDScript por cada uno de los 12 millones de píxeles del arte
func _colores(img: Image) -> Array:
	var d := img.get_data().to_int32_array()
	d.sort()
	var o := []
	var i := 0
	while i < d.size():
		var v: int = d[i]
		o.append(v)
		if v == 0x7FFFFFFF:
			break
		i = d.bsearch(v + 1, true)
	return o
