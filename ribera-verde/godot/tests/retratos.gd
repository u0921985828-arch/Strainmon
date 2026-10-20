# Ribera Verde (Godot) — MAESTRO [8]: los retratos de diálogo son el muñeco del mapa en grande (bustos de PixelLab de
# arte/retratos.png, uno por grupo de sprite del atlas): cada look tiene el suyo, el de la calle por su hash y de su sexo,
# la boca al hablar, el parpadeo y los gestos (los estados, con CAL; sin ellos, el vaivén), la ficha dentro de la caja: el retrato enmarcado con el nombre en la cinta de su pie; sin busto, el dibujado.
#   con xvfb (la caja se coloca con la ventana): $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy
#   --resolution 1560x720 --script res://tests/retratos.gd -- --sin-arranque [--pintar <dir>] → «retratos: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")
const Retrato = preload("res://src/retrato.gd")

var J
var M
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func arg(k: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else ""

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			return false
	return true

func pinta(dir: String, k: String) -> void:
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("retratos-%s.png" % k))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-retratos.json"
	Juego.AJUSTES = "user://prueba-retratos-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	var dir := arg("--pintar")
	J.S = e.S
	J.enter_map("town", 8, 8, "down")
	J.mode = "world"
	var D = J.D
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · un busto por cada muñeco del mapa (las claves look: del atlas), de 64 × 64 y sin semitransparencias
	Atlas.carga()
	Retrato._carga()
	var grupos := {}
	for k in Atlas.d.cubre:
		if str(k).begins_with("look:"):
			grupos[Atlas.d.cubre[k]] = 1
	chk(grupos.size() == 27, "27 muñecos con look (%d)" % grupos.size())
	for g in grupos:
		chk(Retrato.bustos.has(g), "busto de %s" % g)
	chk(Retrato.BW == 64 and Retrato.hoja.get_width() >= 64 * 8, "hoja de bustos de 64")
	var semi := 0
	for y in Retrato.hoja.get_height():
		for x in Retrato.hoja.get_width():
			var a := Retrato.hoja.get_pixel(x, y).a8
			if a > 0 and a < 255:
				semi += 1
	chk(semi == 0, "sin semitransparencias (%d)" % semi)
	# 2 · cada look de LOOKS: el busto de su muñeco del mapa
	for k in D.LOOKS:
		var L = D.LOOKS[k]
		if not (L is Dictionary and L.has("id")):
			continue
		var g = Atlas.grupo_look(L)
		var r := Retrato.grupo(L, J.mujer_look(L))
		chk(r == (str(g) if g is String and Retrato.bustos.has(g) else ""), "look %s → %s (mapa %s)" % [k, r, g])
	chk(Retrato.grupo(D.LOOKS.kid, false) == "unai", "Unai, el suyo")
	chk(Retrato.grupo(J.retrato_de("KIKO")[0], false) == "kiko", "Kiko, el suyo")
	chk(Retrato.grupo(D.LOOKS.granny, true) == "txaro" and Retrato.grupo(D.LOOKS.sailor, false) == "inaki", "Txaro e Iñaki")
	# 3 · los de la calle: el cliente de su hash (como en el mapa) y de su sexo
	var iguales := 0
	var cambiados := 0
	for i in 60:
		var L := {"id": "n%d" % i}
		var gm: String = J.sprite_look(L)
		var m: bool = J.mujer_look(L)
		var r := Retrato.grupo(L, m)
		if r == gm:
			iguales += 1
		var r2 := Retrato.grupo(L, not m)
		if r2 != gm and ((r2 in Retrato.CHICAS) == (not m)):
			cambiados += 1
	chk(iguales == 60, "calle: el mismo muñeco que en el mapa (%d/60)" % iguales)
	chk(cambiados == 60, "calle: de otro sexo, otro cliente de su sexo (%d/60)" % cambiados)
	var rk = J.retrato_de("SMS · KOLDO")
	chk(rk is Array and Retrato.grupo(rk[0], rk[1]) in Retrato.CHICOS, "Koldo, un chico")
	# 3b · el mismo muñeco que en el mapa cuando el nombre lo cambia (GENERO.look, la protagonista, los rivales)
	var rbx = J.retrato_de("BIXENTE")
	chk(rbx is Array and Retrato.grupo(rbx[0], rbx[1]) == Atlas.grupo_look(J.mk_ent({"id": "bixente", "x": 0, "y": 0, "look": "bixente"}).look), "Bixente, el del mapa (%s)" % [rbx])
	for d in D.NPCDEF:
		if str(d.id).begins_with("pres_"):
			J.habla_look = J.mk_ent(d).look
			var rp = J.retrato_de("LA PRESIDENCIA")
			chk(rp is Array and Retrato.grupo(rp[0], rp[1]) == Atlas.grupo_look(J.habla_look), "%s, el del mapa" % d.id)
	J.habla_look = null
	var nom0 = J.S.get("name")
	var sx0 = J.S.get("sexo")
	J.S.name = "Leire"
	J.S.sexo = "f"
	var rpf = J.retrato_de("LEIRE")
	chk(rpf is Array and Retrato.grupo(rpf[0], rpf[1]) == "player-f", "la protagonista, la suya")
	J.S.sexo = "m"
	chk(Retrato.grupo(J.retrato_de("LEIRE")[0], false) == "player", "el protagonista, el suyo")
	J.S.name = nom0
	if sx0 == null:
		J.S.erase("sexo")
	else:
		J.S.sexo = sx0
	for z in D.RIVALES:
		var Rv: Dictionary = D.RIVALES[z]
		var rr = J.retrato_de(str(Rv.n))
		chk(rr is Array and Retrato.grupo(rr[0], rr[1]) == Atlas.grupo_look(J.look_rival(Rv)), "rival %s, el de su pelea" % Rv.n)
	# 4 · la textura: el busto de 64, en caché; sin CAL, el vaivén de 1 px al hablar
	var t0: ImageTexture = Retrato.textura(D.LOOKS.kid, false, 0, 0)
	chk(t0.get_width() == 64 and t0.get_height() == 64, "busto de 64")
	chk(t0 == Retrato.textura(D.LOOKS.kid, false, 0, 0), "en caché")
	var i0 := t0.get_image()
	var p: Array = Retrato.bustos.unai
	chk(i0.get_data() == Retrato.hoja.get_region(Rect2i(int(p[0]), int(p[1]), 64, 64)).get_data(), "Unai, el de la hoja")
	Datos.CAL = false
	Retrato.cache.clear()
	var i1 := Retrato.textura(D.LOOKS.kid, false, 0, 1).get_image()
	chk(i0.get_region(Rect2i(0, 0, 64, 63)).get_data() == i1.get_region(Rect2i(0, 1, 64, 63)).get_data(), "sin CAL, vaivén: 1 px abajo")
	chk(Retrato.textura(D.LOOKS.kid, false, Retrato.ENFADO, 0).get_image().get_data() == i0.get_data(), "sin CAL, sin gestos")
	Datos.CAL = true
	Retrato.cache.clear()
	# 4b · los estados (tools/retratos.py): los 27 con parpadeo y los tres gestos; los 24 sin tapar, con la boca en todos
	var celda := func(g: String, e: String) -> PackedByteArray:
		var q: Array = Retrato.estados[g][e]
		return Retrato.hoja.get_region(Rect2i(int(q[0]), int(q[1]), 64, 64)).get_data()
	var tapados := 0
	for g in grupos:
		var E: Dictionary = Retrato.estados.get(g, {})
		chk(E.has("p") and E.has("a0") and E.has("e0") and E.has("d0"), "%s: parpadeo y gestos (%s)" % [g, E.keys()])
		if E.has("n1"):
			chk(E.has("a1") and E.has("e1") and E.has("d1"), "%s: la boca en los gestos" % g)
		else:
			tapados += 1
		for es in E:
			chk(celda.call(g, es) != Retrato.hoja.get_region(Rect2i(int(Retrato.bustos[g][0]), int(Retrato.bustos[g][1]), 64, 64)).get_data(), "%s-%s distinto del busto" % [g, es])
	chk(tapados == 3, "solo los 3 ladrones, tapados, sin boca (%d)" % tapados)
	var tx := func(e: int, b: int, o: int) -> PackedByteArray:
		return Retrato.textura(D.LOOKS.kid, false, e, b, o).get_image().get_data()
	chk(tx.call(0, 1, 0) == celda.call("unai", "n1"), "hablando: la boca abierta")
	chk(tx.call(0, 0, 1) == celda.call("unai", "p"), "parpadeo: los ojos cerrados")
	chk(tx.call(Retrato.ALEGRE, 0, 0) == celda.call("unai", "a0") and tx.call(Retrato.ALEGRE, 1, 0) == celda.call("unai", "a1"), "contento, callado y hablando")
	chk(tx.call(Retrato.ENFADO, 0, 0) == celda.call("unai", "e0") and tx.call(Retrato.ENFADO, 1, 0) == celda.call("unai", "e1"), "enfadado, callado y hablando")
	chk(tx.call(Retrato.DUDA, 0, 0) == celda.call("unai", "d0") and tx.call(Retrato.DUDA, 1, 0) == celda.call("unai", "d1"), "dudando, callado y hablando")
	chk(tx.call(Retrato.ALEGRE, 0, 1) == celda.call("unai", "a0") and tx.call(0, 1, 1) == celda.call("unai", "n1"), "no parpadea con gesto ni hablando")
	chk(Retrato.textura(D.LOOKS.kid, false, 0, 0, 1) != Retrato.textura(D.LOOKS.kid, false, 0, 0, 0), "los ojos, en la clave de la caché")
	var lad: Image = Retrato.estado("ladron1-combate", Retrato.ENFADO, 1)
	var le: Array = Retrato.estados["ladron1-combate"]["e0"]
	chk(lad.get_region(Rect2i(0, 1, 64, 63)).get_data() == Retrato.hoja.get_region(Rect2i(int(le[0]), int(le[1]), 64, 63)).get_data(), "tapado: el gesto con el vaivén")
	# 5 · sin busto (un look sin muñeco), el dibujado de siempre
	var tz: ImageTexture = Retrato.textura({"id": "zz-nadie", "skin": "#e0b080"}, false, 0)
	chk(Retrato.grupo({"id": "zz-nadie"}, false) == "" and tz.get_width() == Retrato.W, "sin busto, el dibujado")
	# 6 · en pantalla: la ficha dentro de la caja, a la izquierda (el retrato enmarcado y el nombre en la cinta de su pie); el texto, a su derecha
	J.oraculo = false
	J.gancho_texto = Callable()
	J.habla_look = D.LOOKS.kid
	chk(corre(func(): await J.type_text("Eh, ¿tienes algo para mí?", "UNAI")), "type_text bloqueado")
	for q in 3:
		await process_frame
	J._coloca()
	var us: float = J.us
	var R: TextureRect = J.retrato
	chk(R.visible and R.texture != null and R.texture.get_width() == 64, "busto a la vista")
	chk(absf(R.size.x - 64 * us) < 0.5 and absf(R.size.y - 64 * us) < 0.5, "a 1:1 en u (%s, us %s)" % [R.size, us])
	var M: Rect2 = J.retrato_marco.get_rect()
	var C: Rect2 = Rect2(J.dlg.position, J.dlg.size)
	chk(C.grow(-3 * us).encloses(M), "la ficha, entera dentro de la caja (%s / %s)" % [M, C])
	chk(absf((M.position.y - C.position.y) - (C.end.y - M.end.y)) <= us + 0.5, "centrada en alto (%s / %s)" % [M.position.y - C.position.y, C.end.y - M.end.y])
	chk(M.position.x - C.position.x <= 8 * us and M.end.x < C.position.x + C.size.x * 0.5, "a la izquierda")
	var ml: float = J.dlg.get_theme_stylebox("panel").content_margin_left
	chk(C.position.x + ml >= M.end.x + 4 * us, "el texto, a su derecha (%s)" % ml)
	var N: Rect2 = J.dlg_nm.get_rect()
	chk(absf(N.position.x - M.position.x) < 0.5 and absf(N.size.x - M.size.x) < 0.5 and absf(N.end.y - M.end.y) < 0.5, "el nombre, en la cinta del pie del retrato (%s / %s)" % [N, M])
	chk(J.dlg_nm.get_index() > R.get_index() and J.dlg_nm_txt.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "la cinta, encima y centrada")
	chk(R.position.y >= 0, "dentro de la pantalla")
	if dir != "":
		await pinta(dir, "unai")
	# 6b · el parpadeo en la caja: callado y tranquilo, cada PARPADEO[0] ms; nunca mientras escribe
	chk(J.retrato_e == Retrato.DUDA and R.texture.get_image().get_data() == celda.call("unai", "d0"), "con «¿», dudando")
	chk(corre(func(): await J.type_text("Hoy hace buen día en el barrio.", "UNAI")), "type_text bloqueado (tranquilo)")
	chk(not J.retrato_hab and J.retrato_e == Retrato.NEUTRO, "escrito y tranquilo")
	var tw := Time.get_ticks_msec()
	while Time.get_ticks_msec() % J.PARPADEO[0] >= J.PARPADEO[1] - 40 and Time.get_ticks_msec() - tw < 8000:
		await process_frame
	J._parpadeo()
	chk(J.retrato_ojo == 1 and R.texture.get_image().get_data() == celda.call("unai", "p"), "parpadea")
	while Time.get_ticks_msec() % J.PARPADEO[0] < J.PARPADEO[1] and Time.get_ticks_msec() - tw < 8000:
		await process_frame
	J._parpadeo()
	chk(J.retrato_ojo == 0 and R.texture.get_image().get_data() == i0.get_data(), "abre los ojos")
	J.retrato_hab = true
	while Time.get_ticks_msec() % J.PARPADEO[0] >= J.PARPADEO[1] - 40 and Time.get_ticks_msec() - tw < 16000:
		await process_frame
	J._parpadeo()
	chk(J.retrato_ojo == 0, "no parpadea escribiendo")
	J.retrato_hab = false
	chk(corre(func(): await J.type_text("¡Gracias, de lujo!", "UNAI")), "type_text bloqueado (contento)")
	chk(J.retrato_e == Retrato.ALEGRE and R.texture.get_image().get_data() == celda.call("unai", "a0"), "contento al acabar")
	if dir != "":
		await pinta(dir, "unai-contento")
	J.habla_look = null
	chk(corre(func(): await J.type_text("Me debes 3.000 €. Último aviso.", "SMS · TOÑO")), "type_text bloqueado (SMS)")
	chk(R.visible and Retrato.grupo(J.retrato_l[0], J.retrato_l[1]) == "tono", "Toño en el SMS")
	if dir != "":
		await pinta(dir, "tono-sms")
	chk(corre(func(): await J.type_text("Hay una carta en la mesa.", "CARTA")), "type_text bloqueado (carta)")
	chk(not R.visible, "sin retrato en la carta")
	Datos.CAL = false
	chk(corre(func(): await J.type_text("Hola.", "KIKO")), "type_text bloqueado (sin CAL)")
	chk(not R.visible, "sin retrato sin CAL")
	Datos.CAL = true
	J.dlg.hide()
	J.oraculo = true
	for x in fallos:
		print("  FALLO ", x)
	print("retratos: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
