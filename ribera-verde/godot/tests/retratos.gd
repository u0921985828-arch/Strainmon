# Ribera Verde (Godot) — MAESTRO [8]: los retratos de diálogo son el muñeco del mapa en grande (bustos del generador de sprites de
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

func foto() -> Image:
	for q in 3:
		await process_frame
	J._coloca()   # el cuadro, ya colocado, antes de leer el fotograma (si no, se lee el de antes del diálogo)
	J.pintor.redibuja(0.0)
	for q in 8:
		await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

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
	# 3c · lo vio el usuario: un cliente de la calle (TURISTA, PIJO…) con el retrato del muñeco con el que hablas, no el del NPC turista
	var lbls := []
	for t in D.CTYPES:
		lbls.append(str(D.CTYPES[t].label))
	for t in D.GENERO.ctM:
		lbls.append(str(D.GENERO.ctM[t]))
	for i in 6:
		var Lc: Dictionary = Datos.rand_look("ret-cli%d" % i, "client")
		J.habla_look = Lc
		var gc := Retrato.grupo(Lc, J.mujer_look(Lc))
		for lb in lbls:
			var rc = J.retrato_de(lb)
			chk(rc is Array and Retrato.grupo(rc[0], rc[1]) == gc, "cliente %s %d: el del muñeco (%s)" % [lb, i, gc])
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
	# los ladrones de la calle (lo vio el usuario: «me ha salido un tío con sombrero»): el encapuchado de la pelea, no un cliente
	for nl in D.THIEVES:
		for s in 4:
			J.B = {"kind": "thief", "name": nl, "look": Datos.rand_look("th%d" % s, "thief")}
			var rl = J.retrato_de(nl)
			var gl := Retrato.grupo(rl[0], rl[1]) if rl is Array else ""
			chk(gl.begins_with("ladron") and gl.ends_with("-combate"), "%s, con capucha (%s)" % [nl, gl])
	for nc in D.COPS:
		J.B = {"kind": "police", "name": nc, "look": D.LOOKS.cop}
		var rc = J.retrato_de(nc)
		chk(rc is Array and Retrato.grupo(rc[0], rc[1]) == "cop", "%s, el agente" % nc)
	J.B = null
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
	# Lo dijo el usuario («el cuadro de texto es siempre igual y se adapta el texto al cuadro. Pero
	# tiene que ser quid pro quo»): el cuadro mide lo que pide el texto y la ficha se ancla a su pie, con el
	# mismo margen por la izquierda; el busto que no cabe asoma por arriba
	var mg: float = J.RETRATO_M * us
	# 0.84 (lo dijo el usuario: «ese aire encima del Sprite del personaje queda mal»): con el cuadro corto la ficha
	# sigue anclada al pie, y cuando el cuadro da de sí más que ella se centra, de modo que el aire se reparte
	chk(C.end.y - M.end.y >= mg - 0.5 and C.end.y - M.end.y <= mg + us + 0.5, "la ficha, anclada al pie (%.1f u)" % ((C.end.y - M.end.y) / us))
	chk(absf((M.position.x - C.position.x) - mg) <= 0.5 and M.end.x < C.position.x + C.size.x * 0.5, "a la izquierda, con el mismo aire (%.1f u)" % ((M.position.x - C.position.x) / us))
	chk(C.size.y < M.size.y and M.position.y < C.position.y, "el cuadro, a la medida del texto: el busto asoma (%.1f u de caja)" % (C.size.y / us))
	# y el contorno sube a rodearlo (lo pidió el usuario: «que haga como el contorno por encima y por el lado
	# izquierdo y derecho de la foto»): el saliente, pegado al lado izquierdo del cuadro, con el mismo canto
	# por los tres lados y el pie metido en el cuadro
	var S: Rect2 = J.dlg_sal.get_rect()
	var cn: float = (J.SAL_AIRE + J.SAL_CANTO) * us
	chk(J.dlg_sal.visible and absf(S.position.x - C.position.x) <= 0.5, "el saliente, a la vista y en el lado izquierdo del cuadro (%s)" % S)
	chk(absf((M.position.x - S.position.x) - cn) <= 0.5 and absf((S.end.x - M.end.x) - cn) <= 0.5 and absf((M.position.y - S.position.y) - cn) <= 0.5, "rodea la ficha por arriba y por los dos lados (%s / %s)" % [S, M])
	chk(S.end.y > C.position.y + 2 * us and S.end.y < C.position.y + 6 * us, "y su pie, dentro del cuadro (%.1f u)" % ((S.end.y - C.position.y) / us))
	chk(J.dlg_sal.get_index() > J.dlg.get_index() and J.dlg_sal.get_index() < J.retrato_marco.get_index(), "detrás de la ficha y delante del cuadro")
	# la esquina de arriba a la izquierda, de 90°: ahí empalma el saliente, y el píxel del vértice es la línea
	# del contorno. Lo dijo el usuario: «esa esquina no puede ser así, tiene que ser 90 grados lo que haga la
	# linea y el contorno por dentro»
	var im: Image = await foto()
	var CG: Rect2i = Rect2i(Vector2i(C.position.round()), Vector2i(C.size.round()))
	# la referencia es el mismo contorno de arriba del cuadro, más a la derecha (fuera del saliente): así la
	# comprobación no depende del fundido de entrada ni de la penumbra de la escena, solo de que la esquina es línea
	var lin: Color = im.get_pixel(CG.position.x + int(S.size.x) + 20, CG.position.y)
	chk(im.get_pixel(CG.position.x, CG.position.y) == lin, "la esquina de arriba a la izquierda, de 90° (%s, línea %s)" % [im.get_pixel(CG.position.x, CG.position.y), lin])
	# el reborde redondeado se queda en las otras tres esquinas (lo dijo el usuario: «únicamente esa esquina…
	# el reborde del Sprite no lo quites»): su píxel de esquina no es la línea, porque la curva lo deja fuera
	var red := 0
	for q in [Vector2i(CG.end.x - 1, CG.position.y), Vector2i(CG.position.x, CG.end.y - 1), Vector2i(CG.end.x - 1, CG.end.y - 1)]:
		if im.get_pixel(q.x, q.y) != lin:
			red += 1
	chk(red == 3, "el reborde redondeado, en las otras tres esquinas (%d de 3)" % red)
	var ml: float = J.dlg.get_theme_stylebox("panel").content_margin_left
	chk(C.position.x + ml >= M.end.x + 4 * us, "el texto, a su derecha (%s)" % ml)
	var N: Rect2 = J.dlg_nm.get_rect()
	chk(absf(N.position.x - M.position.x) < 0.5 and absf(N.size.x - M.size.x) < 0.5 and absf(N.end.y - M.end.y) < 0.5, "el nombre, en la cinta del pie del retrato (%s / %s)" % [N, M])
	chk(J.dlg_nm.get_index() > R.get_index() and J.dlg_nm_txt.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "la cinta, encima y centrada")
	var cs: StyleBox = J.dlg_nm.get_theme_stylebox("panel")
	chk(cs.content_margin_top + cs.content_margin_bottom < 1.0 and cs.content_margin_left >= 4 * us and cs.content_margin_right >= 4 * us, "la cinta, sin aire arriba ni abajo y con aire a los lados (%s %s / %s %s)" % [cs.content_margin_top, cs.content_margin_bottom, cs.content_margin_left, cs.content_margin_right])
	chk(R.position.y >= 0, "dentro de la pantalla")
	if dir != "":
		await pinta(dir, "unai")
	# 6b · el parpadeo en la caja: callado y tranquilo, cada PARPADEO[0] ms; nunca mientras escribe
	chk(J.retrato_e == Retrato.DUDA and R.texture.get_image().get_data() == celda.call("unai", "d0"), "con «¿», dudando")
	chk(corre(func(): await J.type_text("Hoy hace buen día en el barrio.", "UNAI")), "type_text bloqueado (tranquilo)")
	chk(not J.retrato_hab and J.retrato_e == Retrato.NEUTRO, "escrito y tranquilo")
	# La ventana del parpadeo son 130 ms de cada 3,6 s: con un fotograma lento se puede saltar, así que no
	# se espera al reloj, se llama a _parpadeo cada fotograma y se sale en cuanto el ojo cambia.
	var tw := Time.get_ticks_msec()
	while J.retrato_ojo == 0 and Time.get_ticks_msec() - tw < 30000:
		J._parpadeo()
		await process_frame
	chk(J.retrato_ojo == 1 and R.texture.get_image().get_data() == celda.call("unai", "p"), "parpadea")
	tw = Time.get_ticks_msec()
	while J.retrato_ojo == 1 and Time.get_ticks_msec() - tw < 30000:
		J._parpadeo()
		await process_frame
	chk(J.retrato_ojo == 0 and R.texture.get_image().get_data() == i0.get_data(), "abre los ojos")
	J.retrato_hab = true
	tw = Time.get_ticks_msec()
	var ciego := true
	while Time.get_ticks_msec() - tw < J.PARPADEO[0] + 400:
		J._parpadeo()
		if J.retrato_ojo != 0:
			ciego = false
			break
		await process_frame
	chk(ciego and J.retrato_ojo == 0, "no parpadea escribiendo")
	J.retrato_hab = false
	chk(corre(func(): await J.type_text("¡Gracias, de lujo!", "UNAI")), "type_text bloqueado (contento)")
	chk(J.retrato_e == Retrato.ALEGRE and R.texture.get_image().get_data() == celda.call("unai", "a0"), "contento al acabar")
	if dir != "":
		await pinta(dir, "unai-contento")
	# 6c · con la página llena, el busto cabe en el cuadro y el saliente se esconde (el contorno, de una pieza)
	chk(corre(func(): await J.type_text("Lo primero es el agua: la del grifo hay que corregirla, que si no la planta no come bien y se te queda pálida en nada.", "UNAI")), "type_text bloqueado (página llena)")
	for q in 3:
		await process_frame
	J._coloca()
	var C2: Rect2 = Rect2(J.dlg.position, J.dlg.size)
	var M2: Rect2 = J.retrato_marco.get_rect()
	chk(C2.size.y > C.size.y + 8 * us, "el cuadro crece con el texto (%.1f → %.1f u)" % [C.size.y / us, C2.size.y / us])
	chk(M2.position.y >= C2.position.y - 0.5 and not J.dlg_sal.visible, "el busto, dentro del cuadro: sin saliente (%.1f u)" % ((M2.position.y - C2.position.y) / us))
	var ar: float = M2.position.y - C2.position.y
	var ab: float = C2.end.y - M2.end.y
	# centrada, y el u que sobra de un hueco impar cae debajo del busto, nunca encima (lo dijo el usuario)
	chk(ar <= ab + 0.5 and ab - ar <= us + 0.5 and ab >= mg - 0.5, "y la ficha, centrada: %.1f u de aire arriba y %.1f abajo" % [ar / us, ab / us])
	if dir != "":
		await pinta(dir, "unai-lleno")
	# 6d · 0.84: la página a medias (lo dijo el usuario: «se va demasiado arriba el texto y ese aire encima del Sprite
	# del personaje queda mal»). Al busto le falta poco para caber: el cuadro da esos pocos u y no sale el escalón
	chk(corre(func(): await J.type_text("Eh, ¿tienes algo para mí? Te traigo lo de siempre, si quieres.", "UNAI")), "type_text bloqueado (media página)")
	for q in 3:
		await process_frame
	J._coloca()
	var C3: Rect2 = Rect2(J.dlg.position, J.dlg.size)
	var M3: Rect2 = J.retrato_marco.get_rect()
	chk(not J.dlg_sal.visible and M3.position.y >= C3.position.y - 0.5, "media página: el busto cabe, sin escalón (%.1f u)" % ((M3.position.y - C3.position.y) / us))
	chk(C3.size.y >= M3.size.y + 2 * mg - 0.5, "y el cuadro da de sí lo justo (%.1f u de cuadro, %.1f de ficha)" % [C3.size.y / us, M3.size.y / us])
	chk(C3.size.y - M3.size.y <= (2 * J.RETRATO_M + J.SAL_SUBE) * us + 0.5, "sin pasarse: como mucho SAL_SUBE (%.1f u)" % ((C3.size.y - M3.size.y) / us))
	if dir != "":
		await pinta(dir, "unai-media")
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
