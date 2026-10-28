# El banco de semillas de la tía (ESTUDIO tanda 1; lo pidió el usuario: «mete mano a las mejoras que hablamos»; solo con Datos.CAL):
# el final del juego es la genética, no el tráfico. La lata del manzano (hilo.gd) trae la llave del cuarto de atrás de la
# asociación del barrio alto (banco-rv, por la puerta de al lado de la foto de la tía), el banco de semillas del barrio que ella
# empezó y no terminó. Se restaura como el Centro Cívico: en su fichero se entregan colecciones de semillas (BANCO_TIA.col, de
# tools/banco_tia.py) y cada una destapa un mueble del cuarto, que abre lo suyo: la cámara fría (una semilla de lo guardado cada
# saca días), el laboratorio (estabilizar con una semilla, una vez al día), la sala de catas (un análisis al día), el archivo de la
# tía (una receta al día), el mostrador de los socios (un sobre de una landrace cada socios días) y, con la Haze del 98 fijada, la
# placa: el banco, abierto. Eso es la meta del capítulo 8; IMPERIO, los barcos y los pisos quedan de rama aparte.
# S.bt = {c: {colección: día}, saca, lab, cata, arch, so: días de lo último, v: visto el cuarto, fin: día del final}.
# Cadena: … → ciudad → hilo → bancotia → retencion → juego.
extends "res://src/hilo.gd"

func bt() -> Dictionary:
	if not (S.get("bt") is Dictionary):
		S.bt = {"c": {}}
	if not (S.bt.get("c") is Dictionary):
		S.bt.c = {}
	return S.bt

# la llave, con la lata (hilo paso 5): en las partidas de antes con la lata ya abierta, también
func bt_abierto() -> bool:
	return Datos.CAL and S != null and D.has("BANCO_TIA") and hilo_p() >= 5

func bt_visible() -> bool:
	return bt_abierto()

func bt_col(id: String) -> Dictionary:
	for c in D.BANCO_TIA.col:
		if c.id == id:
			return c
	return {}

func bt_hecha(id: String) -> bool:
	return bt().c.has(id)

func bt_zona(z: String) -> bool:
	for c in D.BANCO_TIA.col:
		if c.z == z and bt_hecha(c.id):
			return true
	return false

func bt_n() -> int:
	return D.BANCO_TIA.col.filter(func(c): return bt_hecha(c.id)).size()

func bt_k(c: Dictionary) -> int:
	return int(c.get("k", D.BANCO_TIA.k))

# lo que falta de cada variedad: [sid, las que tienes, las que pide, fijada]
func bt_falta(c: Dictionary) -> Array:
	var r := []
	for sid in c.s:
		var fija: bool = not c.get("fija") or Cultivo.gen_de(S, sid) >= int(D.GEN_ESTABLE)
		r.append([sid, int(S.seeds.get(sid, 0)), bt_k(c), fija])
	return r

func bt_ultima(c: Dictionary) -> bool:   # la Haze del 98 va en el último cajón: antes, las otras
	return c.get("fija", false) == true and bt_n() < D.BANCO_TIA.col.size() - 1

func bt_puede(c: Dictionary) -> bool:
	return not bt_hecha(c.id) and not bt_ultima(c) and bt_falta(c).all(func(f): return f[1] >= f[2] and f[3])

func bt_lista(c: Dictionary) -> String:
	var l := []
	for f in bt_falta(c):
		var nom: String = strain(f[0]).n if S.disc.get(f[0]) else "??????"
		l.append(("✓ " if bt_hecha(c.id) or (f[1] >= f[2] and f[3]) else "· ") + nom + ("" if bt_hecha(c.id) else " %d/%d" % [mini(f[1], f[2]), f[2]]) + ("" if f[3] or bt_hecha(c.id) else T(" (sin fijar)")))
	return ", ".join(l)

func bt_premio(z: String) -> String:
	var B: Dictionary = D.BANCO_TIA
	match z:
		"camara":
			return T("Abre la cámara fría: una semilla de lo que hayas guardado cada {d} días.", {"d": int(B.saca)})
		"lab":
			return K("Abre el laboratorio, la puerta de al lado de la placa: estabilizar con una semilla en vez de dos, una vez al día y una vez por cosecha de cada línea, con las normas de un laboratorio de verdad.")
		"cata":
			return K("Abre la sala de catas: un lote analizado al día, sin analizador.")
		"archivo":
			return K("Abre el archivo de la tía: cada día, una receta de sus cuadernos.")
		"socios":
			return T("Abre el mostrador de los socios: cada {d} días te dejan un sobre con semillas de una landrace.", {"d": int(B.socios)})
	return K("Cuelga la placa de la tía: el banco de semillas, abierto.")

# las variedades guardadas en el banco (de las colecciones entregadas)
func bt_guardadas() -> Array:
	var l := []
	for c in D.BANCO_TIA.col:
		if bt_hecha(c.id):
			l.append_array(c.s)
	return l

# ---------- el cuarto ----------
func bt_entra(mapa: String) -> void:
	if not Datos.CAL or not D.has("BANCO_TIA") or mapa != String(D.BANCO_TIA.mapa) or not MAPS.has(mapa):
		return
	var m: Dictionary = MAPS[mapa]
	for k in D.BANCO_TIA.zonas:
		var z: Dictionary = D.BANCO_TIA.zonas[k]
		var x := int(z.x)
		var y := int(z.y)
		if z.get("puerta"):   # el laboratorio, una sala aparte: la puerta precintada hasta que se restaura
			m.o[y][x] = z.o if bt_zona(k) else "puertaLabP"   # i18n-no
		elif k == "placa":
			m.o[y][x] = z.o if bt_zona(k) else null
			m.o[y][x + 1] = (z.o + "2") if bt_zona(k) else null
		else:
			m.o[y][x] = z.o if bt_zona(k) else "btTapado"   # i18n-no
			m.o[y][x + 1] = (z.o + "2") if bt_zona(k) else "btTapado2"   # i18n-no
	if not bt().get("v"):
		bt().v = int(S.day)
		queue("btVisto", func(): await bt_intro())   # i18n-no

func bt_intro() -> void:
	await talk(K("EL CUARTO DE ATRÁS"), [K("Huele a cerrado y a papel viejo. Todo está tapado con sábanas, menos un fichero de madera."),
		K("En cada cajoncito, una etiqueta con la letra de la tía: Kush, costa, África, sierra, Asia... y uno solo: «Haze 98»."),
		K("Era su banco de semillas. Lo empezó para que las variedades del barrio no se perdieran, y lo dejó a medias."),
		T("Si llenas los cajones, el cuarto vuelve a la vida. Entrega las colecciones en el fichero (dos semillas de cada variedad).")])

# A en un mueble del cuarto (calle.gd, object_action)
func bt_obj(x: int, y: int, o) -> bool:
	if not Datos.CAL or not D.has("BANCO_TIA") or not (o is String):
		return false
	if en_lab():
		return await lab_obj(x, y, o)
	if S.map != String(D.BANCO_TIA.mapa):
		return false
	var b: String = o.trim_suffix("2")
	if b == "puertaLabP":
		await say(T("La puerta del laboratorio, precintada con cinta. Se abre al entregar «{c}» en el fichero.", {"c": I18n.v(String(bt_col_z("lab").get("n", "")))}))
		return true
	if b == "btFichero":
		await bt_menu(false)
		return true
	if b == "btTapado":
		await say(K("Un mueble tapado con una sábana llena de polvo. Se destapa al entregar su colección en el fichero."))
		return true
	match b:
		"btCamara":
			await bt_camara()
		"btCata":
			await bt_cata()
		"btArchivo":
			await bt_archivo()
		"btMostrador":
			await bt_socios()
		"btPlaca":
			await say(K("La placa de la tía, de madera y latón, con una hoja grabada. Debajo, alguien ha dejado un ramo de flores del monte."))
		_:
			return false
	return true

# el fichero: las colecciones; desde OBJETIVO, solo se miran (ver)
func bt_menu(ver := true) -> void:
	var i := 0
	var cs: Array = D.BANCO_TIA.col
	while true:
		var it := []
		for c in cs:
			var f := bt_falta(c)
			var tengo: int = f.filter(func(q): return q[1] >= q[2] and q[3]).size()
			var hecha := bt_hecha(c.id)
			it.append({"label": ("★ " if hecha else "") + I18n.v(String(c.n)), "right": K("HECHA") if hecha else ("%d/%d" % [tengo, f.size()]),
				"desc": bt_premio(String(c.z)) + "\n" + bt_lista(c)})
		it.append({"label": K("Volver"), "desc": K("Cada colección, dos semillas de cada variedad (la Haze del 98, cinco, y fijada en F4).")})
		i = await menu(it, {"cls": "full", "title": K("EL BANCO DE LA TÍA"), "title2": "%d/%d" % [bt_n(), cs.size()], "desc": true, "initial": i})
		if i < 0 or i >= cs.size():
			return
		if ver:
			continue
		var c: Dictionary = cs[i]
		if bt_hecha(c.id):
			await say(K("Esa ya está en su cajón."))
		elif bt_ultima(c):
			await say(K("La Haze del 98 va en el último cajón: antes, las otras cinco colecciones."))
		elif not bt_puede(c):
			await say(K("Te faltan semillas para esa colección. Mira la lista: cada variedad, en su cajón."))
		elif await ask(T("¿Entregar «{n}»? Las semillas se quedan en el banco.", {"n": I18n.v(String(c.n))}), [K("Entregar"), K("Todavía no")]) == 0:
			await bt_entrega(c)

func bt_entrega(c: Dictionary) -> void:
	for sid in c.s:
		S.seeds[sid] = int(S.seeds.get(sid, 0)) - bt_k(c)
		if S.seeds[sid] <= 0:
			S.seeds.erase(sid)
	bt().c[c.id] = int(S.day)
	S.rep = float(S.rep) + 2
	sfx("get")
	await fade(1, true)
	bt_entra(String(D.BANCO_TIA.mapa))
	await wait(300)
	await fade(0, true)
	var z: Dictionary = D.BANCO_TIA.zonas[c.z]
	await say(T("«{c}», en su cajón. {z}: destapado.\n{p}", {"c": I18n.v(String(c.n)), "z": I18n.v(String(z.n)), "p": bt_premio(String(c.z))}))
	if bt_n() >= D.BANCO_TIA.col.size():
		await bt_fin()

func bt_fin() -> void:
	var B: Dictionary = D.BANCO_TIA
	bt().fin = int(S.day)
	S.rep = float(S.rep) + int(B.rep)
	S.prest = int(S.get("prest", 0)) + int(B.prest)
	await talk(K("EL BANCO DE SEMILLAS"), [K("El último cajón, el de la Haze del 98. Cierras el fichero y el cuarto está entero."),
		K("Delroy cuelga la placa de la tía en la pared. Kiko ha traído a medio barrio, Miren ha bajado del monte y la abuela Txaro se ha sentado en primera fila."),
		K("Nadie dice nada un rato. Luego Delroy abre la puerta del cuarto a los socios: desde hoy, el banco es del barrio.")])
	await talk(K("DELROY"), [K("Treinta años diciendo que esto había que terminarlo. Lo has hecho tú."), K("Ahora cualquiera del barrio puede pedir una semilla y devolver dos. Como quería ella.")])
	await got(T("{r} de reputación y {p} de prestigio: el banco de semillas de la tía, abierto", {"r": int(B.rep), "p": int(B.prest)}))
	var L := [K("Me han contado lo del banco. Tu tía estaría orgullosa. Yo lo estoy."), K("Lo demás ya es cosa tuya: cultivar, cruzar y que no se pierda nada.")]
	queue("btFin", func(): await talk(K("SMS · KIKO"), L), [[K("SMS · KIKO"), L]])   # i18n-no

# ---------- lo que abre cada mueble ----------
func bt_espera(k: String, dias: int) -> int:   # los días que faltan para volver a usarlo (0: ya)
	if not bt().has(k):
		return 0
	return maxi(0, int(bt()[k]) + dias - int(S.day))

func bt_camara() -> void:
	var w := bt_espera("saca", int(D.BANCO_TIA.saca))
	if w > 0:
		await say(T("La cámara fría solo suelta un sobre cada {d} días. El próximo, el {f}.", {"d": int(D.BANCO_TIA.saca), "f": Datos.fd(int(S.day) + w, S.day)}))
		return
	var l := bt_guardadas()
	var it: Array = l.map(func(sid): return {"label": strain(sid).n, "right": "%d" % int(S.seeds.get(sid, 0)), "desc": K("Una semilla de esa variedad, del banco.")})
	it.append({"label": K("Nada"), "desc": ""})
	var i: int = await menu(it, {"cls": "full", "title": K("LA CÁMARA FRÍA"), "desc": true})
	if i < 0 or i >= l.size():
		return
	add_seeds(l[i], 1)
	bt().saca = int(S.day)
	sfx("get")
	await got(T("1 semilla de {s}, de la cámara fría", {"s": strain(l[i]).n}))

func bt_lab() -> void:
	if bt_espera("lab", 1) > 0:
		await say(K("El laboratorio, por hoy, ya está. Vuelve mañana."))
		return
	var no := lab_norma(true)
	if no != "":
		await say(no)
		return
	var l: Array = S.seeds.keys().filter(func(sid): return int(S.seeds[sid]) >= 1 and Cultivo.gen_de(S, sid) < int(D.GEN_ESTABLE))
	if l.is_empty():
		await say(K("En el laboratorio se fija una línea con una sola semilla. Ahora no tienes ninguna sin fijar."))
		return
	l = l.filter(func(sid): return bt_lab_ok(sid))
	if l.is_empty():
		await say(K("Cada generación es una cosecha: cultiva la línea y vuelve con lo cosechado."))
		return
	var it: Array = l.map(func(sid): return {"label": strain(sid).n, "right": "F%d" % Cultivo.gen_de(S, sid), "desc": T("{n} semillas", {"n": int(S.seeds[sid])})})   # i18n-no
	it.append({"label": K("Nada"), "desc": ""})
	var i: int = await menu(it, {"cls": "full", "title": K("EL LABORATORIO"), "desc": true})
	if i < 0 or i >= l.size():
		return
	var cn := bt_cos(l[i])
	if await estabilizar(l[i], 1):
		bt().lab = int(S.day)
		lab().r = true   # lo usado, al contenedor amarillo
		if not bt().has("lc"):
			bt().lc = {}
		bt().lc[l[i]] = cn

# las cosechas de cada línea (cult_apunta, desde harvest y la nave) y la última que usó el laboratorio
func bt_cos(sid: String) -> int:
	return int(bt().get("cn", {}).get(sid, 0))

func bt_lab_ok(sid: String) -> bool:
	return bt_cos(sid) > int(bt().get("lc", {}).get(sid, 0))

func cult_apunta(sid: String) -> void:
	super(sid)
	if not Datos.CAL or not D.has("BANCO_TIA"):
		return
	if not bt().has("cn"):
		bt().cn = {}
	bt().cn[sid] = bt_cos(sid) + 1

func bt_cata() -> void:
	if bt_espera("cata", 1) > 0:
		await say(K("La sala de catas, por hoy, ya está. Vuelve mañana."))
		return
	var l: Array = S.buds.keys().filter(func(k): return not S.buds[k].get("ana"))
	if l.is_empty():
		await say(K("En la sala de catas se analiza un lote al día. No llevas ninguno sin analizar."))
		return
	var it: Array = l.map(func(k): return {"label": lot_nombre(k), "right": "%d g" % int(floor(S.buds[k].g)), "desc": T("THC {t} %", {"t": Datos.pct(S.buds[k].thc)})})   # i18n-no
	it.append({"label": K("Nada"), "desc": ""})
	var i: int = await menu(it, {"cls": "full", "title": K("LA SALA DE CATAS"), "desc": true})
	if i < 0 or i >= l.size():
		return
	var k: String = l[i]
	var b: Dictionary = S.buds[k]
	b.ana = true
	bt().cata = int(S.day)
	sfx("get")
	var sid := lot_sid(k)
	await say(T("Analizado: {l} · THC {t} % · CBD {c} % · terpeno principal, {p}. Lo que va con análisis se vende mejor.", {"l": lot_nombre(k), "t": Datos.pct(b.thc), "c": Datos.pct(cbd_de(sid)), "p": D.TERPENOS[aroma_de(sid)]}))

func bt_archivo() -> void:
	if bt_espera("arch", 1) > 0:
		await say(K("Ya has leído lo de hoy en los cuadernos de la tía. Mañana, más."))
		return
	var ks: Array = D.RECIPES.keys()
	ks.sort()
	var r := ""
	for k in ks:
		if not S.disc.get(String(D.RECIPES[k])):
			r = k
			break
	if r == "":
		await say(K("Ya conoces todo lo que la tía apuntó en sus cuadernos."))
		return
	bt().arch = int(S.day)
	var nom: Array = Array(r.split("+")).map(func(sid): return strain(sid).n)
	await say(T("En un cuaderno del archivo, con la letra de la tía: «{a}: de ahí sale la {r}».", {"a": " × ".join(nom), "r": strain(String(D.RECIPES[r])).n}))

func bt_socios() -> void:
	var w := bt_espera("so", int(D.BANCO_TIA.socios))
	if w > 0:
		await say(T("El mostrador está vacío. Los socios dejan un sobre cada {d} días: el próximo, el {f}.", {"d": int(D.BANCO_TIA.socios), "f": Datos.fd(int(S.day) + w, S.day)}))
		return
	var l: Array = D.LANDRACES.filter(func(sid): return not S.disc.get(sid) and not D.REGALO.has(sid))   # primero, las que aún no has encontrado (no las que escondió la tía)
	if l.is_empty():
		l = bt_guardadas()
	var sid: String = l[int(S.day) % l.size()]
	bt().so = int(S.day)
	add_seeds(sid, 2)
	sfx("get")
	await say(K("En el mostrador, un sobre de papel con una nota: «Para el banco de Maite. Eran de mi padre»."))
	await got(T("2 semillas de {s}", {"s": strain(sid).n}))

# ---------- OBJETIVO ----------
func bt_objetivo() -> String:
	if not Datos.CAL or not D.has("BANCO_TIA"):
		return ""
	if not bt_abierto():
		return K("Sigue el cuaderno azul de la tía: OBJETIVO → LA TÍA MAITE.") if hilo_visible() else ""
	var tot: int = D.BANCO_TIA.col.size()
	if bt().has("fin"):
		return K("El banco de semillas de la tía, abierto. Cultiva, cruza y que no se pierda ninguna variedad.")
	var sig := {}
	var mejor := -1.0
	for c in D.BANCO_TIA.col:
		if bt_hecha(c.id):
			continue
		var f := bt_falta(c)
		var p: float = f.filter(func(q): return q[1] >= q[2] and q[3]).size() / float(f.size())
		if p > mejor:
			mejor = p
			sig = c
	return T("Restaura el banco de semillas de la tía, en el cuarto de atrás de la asociación: {a}/{b} colecciones. La más cerca: «{n}».", {"a": bt_n(), "b": tot, "n": I18n.v(String(sig.n))})

func bt_derecha() -> String:
	return "%d/%d" % [bt_n(), D.BANCO_TIA.col.size()]

# ---------- el laboratorio (lo pidió el usuario: «El laboratorio debe parecer un laboratorio de verdad, no los materiales de labo y
# ya, las normas que tienes que tener en un laboratorio real»): lab-rv (LAB, de tools/banco_tia.py), por la puerta de al lado de la
# placa. La antesala, hasta la línea amarilla (LAB.linea): el lavamanos, la percha con la bata, las gafas y los guantes, el cartel de
# las normas y el botiquín; la zona de trabajo, detrás. Las normas, de verdad: no se pasa la línea sin las manos lavadas y el EPI
# puesto (linea_lab, desde try_move), las manos antes que los guantes, nada de comer, beber ni fumar (catar), nadie trabaja colocado
# ni borracho, el instrumental esterilizado en el autoclave ese día, lo usado al contenedor amarillo antes de volver a empezar y el
# EPI se deja en la antesala al salir (cruzar_puerta). S.bt.ld = {m: manos, e: EPI, at: el día del autoclave, r: lo usado sin tirar,
# v: el día que lo viste}
func lab() -> Dictionary:
	if not (bt().get("ld") is Dictionary):
		bt().ld = {}
	return bt().ld

func en_lab() -> bool:
	return Datos.CAL and S != null and D.has("LAB") and S.map == String(D.LAB.mapa)

func bt_col_z(z: String) -> Dictionary:
	for c in D.BANCO_TIA.col:
		if c.z == z:
			return c
	return {}

func lab_sereno() -> bool:
	return colo() < float(D.FISIO.efecto) and borr() < float(D.FISIO.efecto)

# '' si se puede trabajar; si no, por qué (con el puesto: el autoclave de hoy y lo de ayer tirado)
func lab_norma(puesto := false) -> String:
	if not lab_sereno():
		return K("Así no se trabaja en un laboratorio: nadie toca nada colocado ni bebido. Vuelve cuando se te pase.")
	if not lab().get("m") or not lab().get("e"):
		return K("Sin las manos lavadas y la bata, las gafas y los guantes, aquí no se toca nada. Está todo en la antesala.")
	if puesto and lab().get("r"):
		return K("El puesto, sin recoger: primero, lo usado al contenedor amarillo y la cabina limpia con alcohol.")
	if puesto and int(lab().get("at", -1)) != int(S.day):
		return K("El instrumental, sin esterilizar: las pinzas, el bisturí y las placas pasan antes por el autoclave, cada día.")
	return ""

# la línea amarilla: de la antesala a la zona de trabajo, solo con las manos lavadas y el EPI
func linea_lab(nx: int, _ny: int) -> bool:
	if not en_lab():
		return false
	var li := int(D.LAB.linea)
	return int(P.x) <= li and nx > li and not (lab().get("m") and lab().get("e"))

func aviso_linea() -> void:
	if not lab().get("m"):
		await say(K("La línea amarilla no se pasa sin lavarte las manos y ponerte la bata, las gafas y los guantes. El lavamanos y la percha, en la antesala."))
	else:
		await say(K("Las manos, ya. Ahora la bata, las gafas y los guantes, en la percha: sin el EPI no se pasa la línea amarilla."))

func cruzar_puerta(e: Dictionary) -> void:
	if Datos.CAL and D.has("LAB"):
		if String(e.get("to", "")) == String(D.LAB.mapa):   # se entra con las manos sin lavar y sin nada puesto
			lab().m = false
			lab().e = false
		elif en_lab() and lab().get("e"):
			lab().e = false
			lab().m = false
			await say(K("Antes de salir, en la antesala: los guantes al cubo, la bata a su percha con las gafas y las manos, otra vez al lavabo. El EPI no sale del laboratorio."))
	await super(e)
	if en_lab() and not lab().has("v"):
		lab().v = int(S.day)
		await lab_intro()

func lab_intro() -> void:
	await talk(K("EL LABORATORIO"), [K("Azulejo blanco, el suelo sin juntas y una línea amarilla que parte la sala en dos. Huele a alcohol y a lejía."),
		K("Antes de la línea, la antesala: el lavamanos de pedal, la percha con las batas, las gafas y los guantes, y un cartel con las normas."),
		K("Debajo del cartel, con la letra de la tía: «Aquí se trabaja como en un laboratorio de verdad, o no se trabaja».")])

func lab_normas() -> void:
	await talk(K("LAS NORMAS DEL LABORATORIO"), [K("1. Antes de pasar la línea amarilla: las manos lavadas, la bata abrochada, las gafas y los guantes."),
		K("2. Aquí dentro no se come, no se bebe y no se fuma. Y en la nevera de las muestras, nada de comida."),
		K("3. Nadie trabaja colocado ni bebido."),
		K("4. El instrumental se esteriliza en el autoclave antes de usarlo, cada día."),
		K("5. Todo lo que toca las muestras va al contenedor amarillo, y el puesto se deja limpio. Cada placa y cada sobre, con su etiqueta: qué es, de quién y la fecha."),
		K("6. Antes de necesitarlos, se sabe dónde están la ducha, el lavaojos, el extintor y el botiquín."),
		K("7. El EPI no sale del laboratorio: se deja en la antesala y las manos se lavan otra vez al salir."),
		K("Firmado, con una hoja dibujada: M.")])

func lab_obj(_x: int, _y: int, o) -> bool:
	var b: String = String(o).trim_suffix("2")
	match b:
		"labNormas":
			await lab_normas()
		"labPila":
			if lab().get("e"):
				await say(K("Con los guantes puestos, no: las manos se lavan antes de ponértelos y después de quitártelos."))
			elif lab().get("m"):
				await say(K("Ya te has lavado las manos. Ahora, la percha."))
			else:
				lab().m = true
				sfx("agua")   # i18n-no
				await say(K("Te lavas las manos con jabón, entre los dedos y hasta las muñecas, y te las secas con papel. El grifo, con el pedal."))
		"labPercha":
			if lab().get("e"):
				await say(K("Ya llevas la bata abrochada, las gafas y los guantes."))
			elif not lab().get("m"):
				await say(K("Antes de los guantes, las manos: el lavamanos está al lado."))
			else:
				lab().e = true
				sfx("get")   # i18n-no
				await say(K("Te pones la bata y te la abrochas, las gafas y los guantes de nitrilo por encima de los puños. Ya puedes pasar la línea amarilla."))
		"labFlujo":
			await bt_lab()
		"labAutoclave":
			var no := lab_norma()
			if no != "":
				await say(no)
			elif int(lab().get("at", -1)) == int(S.day):
				await say(K("El instrumental de hoy ya está esterilizado, en sus botes con la cinta que cambia de color."))
			elif await ask(K("El autoclave: el instrumental, a presión y con vapor, para que no lleve nada de fuera a las semillas. ¿Esterilizarlo ahora? Es media hora."), [K("Esterilizar"), K("Nada")]) == 0:
				advance_time(int(D.LAB.esteril))
				lab().at = int(S.day)
				sfx("get")   # i18n-no
				update_hud()
				await say(K("El instrumental, esterilizado: la cinta de los botes ha cambiado de color. Ya se puede trabajar en la cabina."))
		"labResiduos":
			if lab().get("r") and lab_norma() == "":
				lab().r = false
				sfx("get")   # i18n-no
				await say(K("Las placas, las puntas y lo que ha tocado las muestras, al contenedor amarillo. La cabina, limpia con alcohol. El puesto, listo."))
			else:
				await say(K("El contenedor amarillo, para lo que toca las muestras, y el rojo, para lo que corta. Se los lleva un gestor autorizado: nada de eso va a la basura de casa."))
		"labMicro":
			var no := lab_norma()
			await say(no if no != "" else K("Al microscopio, una semilla de cada línea: la cubierta, las vetas, si está madura. Lo que no se ve a simple vista se apunta en el cuaderno, con la fecha."))
		"labBalanza":
			var no := lab_norma()
			await say(no if no != "" else K("La balanza de precisión, con su urna para que el aire no la mueva. Cada lote de semillas se pesa y se apunta: las vanas no llegan al peso."))
		"labEstufa":
			await say(K("La estufa de germinación: las semillas, en placas a oscuras y a temperatura fija. Cada placa, con su etiqueta."))
		"labNevera":
			await say(K("La nevera de las muestras: tubos y sobres, todos etiquetados. Ni comida ni bebida: es una de las normas."))
		"labDucha":
			await say(K("La ducha de emergencia: si te cae algo encima, se tira del triángulo y uno se queda debajo hasta quitárselo todo. Se prueba cada semana."))
		"labLavaojos":
			await say(K("El lavaojos: si salpica algo a los ojos, se empuja la palanca y se lavan abiertos, sin frotar, un buen rato. Luego, al médico."))
		"labExtintor":
			await say(K("El extintor de dióxido de carbono, el de los aparatos eléctricos, con la revisión al día en su etiqueta."))
		"labBotiquin":
			await say(K("El botiquín: gasas, vendas, tiritas, suero y guantes. Al lado, con la letra de la tía, el teléfono de urgencias."))
		"labTaburete":
			await say(K("Un taburete de laboratorio, regulable y con ruedas."))
		_:
			return false
	return true

# las normas: en el laboratorio no se come, no se bebe y no se fuma
func catar(k: String, g := -1.0) -> void:
	if en_lab():
		await say(K("En el laboratorio no se come, no se bebe y no se fuma. Es la segunda norma del cartel."))
		return
	await super(k, g)

func catar_extr(k: String, g: float) -> void:
	if en_lab():
		await say(K("En el laboratorio no se come, no se bebe y no se fuma. Es la segunda norma del cartel."))
		return
	await super(k, g)
