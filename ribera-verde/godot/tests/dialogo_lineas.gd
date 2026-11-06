# Landrace Hunters (Godot) — 0.74 (lo pidió el usuario: «que el cuadro de texto únicamente pueda tener
# máximo 4 líneas»): ninguna página del cuadro de diálogo pasa de UI.DLG_LINEAS líneas, con retrato y sin él,
# midiendo el Label de verdad (get_line_count) con los textos más largos del juego.
#   xvfb-run … $GODOT --path godot --resolution 2400x1080 --script res://tests/dialogo_lineas.gd
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var fallos := []
var alto := [{}, {}]   # alto del cuadro en píxeles por número de líneas, sin busto y con busto
var n := 0

func _initialize() -> void:
	Datos.PLAY = true
	Datos.CAL = true
	_corre.call_deferred()

func espera(k: int) -> void:
	for i in k:
		await process_frame

func textos() -> Array:
	var out: Array = []
	var f := FileAccess.open("res://i18n/strings.csv", FileAccess.READ)
	if f:
		f.get_csv_line()
		while not f.eof_reached():
			var l := f.get_csv_line()
			if l.size() > 1 and String(l[1]).length() > 70:
				out.append(String(l[1]))
	out.sort_custom(func(a, b): return a.length() > b.length())
	# los largos del juego y, detrás, textos cortos de 1 y 2 líneas (el cuadro tiene que encoger con ellos)
	return out.slice(0, 120) + ["Vale.", "Pasas media hora mirando a la gente.", "Ya duermo de un tirón. Gracias, de verdad."]

# el Label parte el texto en el layout: se espera a que diga dos veces seguidas lo mismo
func lineas_estables() -> int:
	var l: int = J.dlg_txt.get_line_count()
	for i in 8:
		await espera(2)
		var m: int = J.dlg_txt.get_line_count()
		if m == l:
			return l
		l = m
	return l

func _corre() -> void:
	Datos.carga()
	Juego.GUARDADO = "user://prueba-dlglin.json"
	Juego.AJUSTES = "user://prueba-dlglin-ajustes.json"
	J = Juego.new()
	J.oraculo = false
	root.add_child(J)
	await espera(3)
	J.aj.texto = 2   # el texto sale al momento: nada de máquina de escribir
	J.ajustes_aplica()
	await espera(2)
	for con_nombre in [true, false]:
		var nom: String = "KIKO" if con_nombre else ""
		for t in textos():
			var pg: Array = J.paginas_dlg(J.nm(t), con_nombre)
			for p in pg:
				await J.type_text(String(p), nom)
				await espera(5)   # el cuadro se mide y se recoloca un par de fotogramas después
				n += 1
				var l: int = await lineas_estables()
				if l > J.DLG_LINEAS:
					fallos.append("%d líneas (%s): %s" % [l, nom, String(p).substr(0, 60)])
				else:
					# el texto entero cabe en el cuadro (el alto del cuerpo da para sus líneas)
					var hl: float = J._alto_linea(J.fs_txt(J._dlg_px * J.us))
					if J.dlg_txt.size.y + 1 < l * hl:
						fallos.append("se corta: %d líneas de %.1f en %.1f (%s): %s" % [l, hl, J.dlg_txt.size.y, nom, String(p).substr(0, 40)])
					# (lo dijo el usuario: «los cuadros de texto no se adaptan al texto cuando es menor del
					# máximo no?»): el cuadro mide por el texto, no DLG_LINEAS siempre
					var k: int = (1 if con_nombre else 0)
					alto[k][l] = maxi(int(alto[k].get(l, 0)), roundi(J.dlg.size.y))
			J.dlg.hide()
	# el cuadro de una línea es más bajo que el de cuatro (con busto, la ficha pone el suelo)
	for k in 2:
		var h: Dictionary = alto[k]
		var ks: Array = h.keys()
		ks.sort()
		for i in range(1, ks.size()):
			if h[ks[i]] < h[ks[i - 1]]:
				fallos.append("alto %d líneas (%d) < %d líneas (%d)" % [ks[i], h[ks[i]], ks[i - 1], h[ks[i - 1]]])
		if ks.size() > 1 and h[ks[-1]] <= h[ks[0]]:
			fallos.append("el cuadro no encoge con el texto corto (busto %d): %s" % [k, str(h)])
	print("altos con busto: ", alto[1], " · sin busto: ", alto[0])
	for x in fallos.slice(0, 10):
		print("FALLO ", x)
	print("dialogo_lineas: %d páginas, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() > 0 else 0)
