# Landrace Hunters (Godot) — sin destellos por las cachés de texturas (lo vio el usuario: «pam, pam, cada cierto tiempo… en la casa,
# en el armario no puede pasar»): Atlas.tex y Arte.tex tenían un tope (R7) que, al llenarse, hacía clear() y soltaba las texturas que
# ya estaban en la orden de pintar del fotograma (draw_texture solo guarda el RID): salían en blanco o sin pintar. Ahora, por
# generaciones: la que se acaba de pedir sigue viva al llenarse, y la que se pide en cada fotograma no se suelta nunca.
#   $GODOT --headless --path godot --script res://tests/texturas.gd   → «texturas: N comprobaciones, 0 fallos»
extends SceneTree

const Atlas = preload("res://src/atlas.gd")
const Arte = preload("res://src/arte.gd")

var n_ok := 0
var fallos := []

func ok(que: String, c: bool) -> void:
	if c:
		n_ok += 1
	else:
		fallos.append(que)

func _initialize() -> void:
	var tope := 2048   # Atlas.TX_TOPE y Arte.TEXS_TOPE (a mano: la prueba corre también con el código de antes)
	# 1) Atlas.tex: la textura recién pedida (en la orden de pintar) sigue viva aunque justo después se llene la caché
	var ims := []
	var A := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	var wa := Atlas.tex(A).get_instance_id()
	for i in tope + 8:
		var im := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		ims.append(im)
		Atlas.tex(im)
	ok("Atlas: la de este fotograma, viva tras llenarse", is_instance_id_valid(wa))
	ok("Atlas: la misma al volver a pedirla", Atlas.tex(A).get_instance_id() == wa)
	# 2) la que se pide cada fotograma no se suelta nunca, por mucho que se llene
	var wb := Atlas.tex(A).get_instance_id()
	for f in 6:
		for i in tope / 2:
			var im := Image.create(2, 2, false, Image.FORMAT_RGBA8)
			ims.append(im)
			Atlas.tex(im)
		ok("Atlas: la de cada fotograma, la misma (%d)" % f, Atlas.tex(A).get_instance_id() == wb)
	ok("Atlas: viva tras %d texturas" % (3 * tope), is_instance_id_valid(wb))
	ok("Atlas: con tope", Atlas.tx.size() <= tope + 1)
	ims.clear()
	# 3) Arte.tex (la vista C), igual
	var B := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	var wc := Arte.tex("prueba|b", B).get_instance_id()
	for i in tope + 8:
		Arte.tex("prueba|%d" % i, Image.create(2, 2, false, Image.FORMAT_RGBA8))
	ok("Arte: la de este fotograma, viva tras llenarse", is_instance_id_valid(wc))
	ok("Arte: la misma al volver a pedirla", Arte.tex("prueba|b", B).get_instance_id() == wc)
	for f in 6:
		for i in tope / 2:
			Arte.tex("prueba|%d|%d" % [f, i], Image.create(2, 2, false, Image.FORMAT_RGBA8))
		ok("Arte: la de cada fotograma, la misma (%d)" % f, Arte.tex("prueba|b", B).get_instance_id() == wc)
	ok("Arte: con tope", Arte.texs.size() <= tope + 1)
	for e in fallos:
		print("FALLO ", e)
	print("texturas: %d comprobaciones, %d fallos" % [n_ok + fallos.size(), fallos.size()])
	quit(1 if fallos.size() else 0)
