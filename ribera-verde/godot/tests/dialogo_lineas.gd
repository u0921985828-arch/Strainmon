# Landrace Hunters (Godot) — 0.74 (lo pidió el usuario: «que el cuadro de texto únicamente pueda tener
# máximo 4 líneas»): ninguna página del cuadro de diálogo pasa de UI.DLG_LINEAS líneas, con retrato y sin él,
# midiendo el Label de verdad (get_line_count) con los textos más largos del juego.
#   xvfb-run … $GODOT --path godot --resolution 2400x1080 --script res://tests/dialogo_lineas.gd
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var fallos := []
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
	return out.slice(0, 120)

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
				await espera(2)
				n += 1
				var l: int = J.dlg_txt.get_line_count()
				if l > J.DLG_LINEAS:
					fallos.append("%d líneas (%s): %s" % [l, nom, String(p).substr(0, 60)])
			J.dlg.hide()
	for x in fallos.slice(0, 10):
		print("FALLO ", x)
	print("dialogo_lineas: %d páginas, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() > 0 else 0)
