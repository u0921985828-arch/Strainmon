# Landrace Hunters (Godot) — vuelca la hoja de abanico de cada variedad (src/hoja.gd, la misma que sale en la ficha
# del recetario) a PNG, para las láminas de la genealogía (ribera-verde/tools/genealogia_svg.py).
#   $GODOT --headless --path godot --script res://tools/genealogia_hojas.gd -- --salida ../docs/plano/genealogia/hojas
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Hoja = preload("res://src/hoja.gd")

func _initialize() -> void:
	Datos.CAL = true
	Datos.PLAY = false
	var dst := "res://../docs/plano/genealogia/hojas"
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--salida" and i + 1 < a.size():
			dst = a[i + 1]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst) if dst.begins_with("res://") else dst)
	var D: Dictionary = Datos.carga()
	var S := {}
	var n := 0
	for k in D.STRAINS:
		var im: Image = Hoja.imagen(Hoja.params(D, S, k))
		var p: String = (ProjectSettings.globalize_path(dst) if dst.begins_with("res://") else dst) + "/" + k + ".png"
		if im.save_png(p) == OK:
			n += 1
	print("genealogia_hojas: %d hojas" % n)
	quit()
