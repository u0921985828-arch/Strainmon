# LA TIENDA DE EXTRAS (lo pidió el usuario: «Quiero que el juego no sea demo pero que podamos elegir cosas para que sean como
# extras o dlc, objetos para comprar y demas / O incluso algún tipo de moneda especial»; solo con Datos.CAL). TIENDA de
# tools/tienda.py. El juego entero viene con la aplicación: los ocho capítulos, la historia y todo lo que se juega. Aquí solo
# hay atajos: trabajo ya hecho (obras, salas, locales) y cosas (semillas, abono, tarros, macetas, focos), y todo se consigue
# también jugando.
# La moneda son las SEMILLAS DORADAS (S.tn.sd), que se ganan jugando (TIENDA.gana: objetivos diarios, capítulos, la Copa, los
# fenotipos raros, los números de EL ESQUEJE y los logros) y, solo en la versión de Google Play (TIENDA_REAL, la marca «tienda»
# del AAB; tools/godot-aab.js), se pueden comprar en paquetes (consumibles de Play). A quien compró el juego completo cuando el
# juego era una demo se le regalan TIENDA.mon.regalo semillas doradas la primera vez que abre (tn_regalo).
# S.tn = {sd: las semillas doradas, c: {clave: veces compradas}, g: {vía: lo ganado por ella}, r: el regalo ya dado}.
# Cadena: … → acto3 → revista → retencion → tienda → juego.
extends "res://src/retencion.gd"

# el dinero de verdad solo en el AAB de Google Play; en el APK y en la web, las semillas doradas se ganan jugando
static var TIENDA_REAL := OS.has_feature("tienda")

func tn_hay() -> bool:
	return Datos.CAL and D.has("TIENDA")

func tn() -> Dictionary:
	if not (S.get("tn") is Dictionary):
		S.tn = {"sd": 0, "c": {}, "g": {}, "r": 0}
	var t: Dictionary = S.tn
	if not (t.get("c") is Dictionary):
		t.c = {}
	if not (t.get("g") is Dictionary):
		t.g = {}
	if t.get("sd") == null:
		t.sd = 0
	if t.get("r") == null:
		t.r = 0
	return t

func tn_sd() -> int:
	return int(tn().sd) if tn_hay() else 0

func tn_mon() -> Dictionary:
	return D.TIENDA.mon if tn_hay() else {}

# «3 semillas doradas» / «1 semilla dorada»
func tn_txt(n: int) -> String:
	var M := tn_mon()
	if M.is_empty():
		return str(n)
	return T("{n} {m}", {"n": Datos.miles(n), "m": I18n.v(String(M.n1 if absi(n) == 1 else M.n))})

func tn_def(k: String) -> Dictionary:
	if tn_hay():
		for x in D.TIENDA.it:
			if String(x.k) == k:
				return x
	return {}

func tn_veces(k: String) -> int:
	return int(tn().c.get(k, 0)) if tn_hay() else 0

# ---------- ganar semillas doradas jugando ----------
func tn_gana_def(k: String) -> Dictionary:
	if tn_hay():
		for g in D.TIENDA.gana:
			if String(g.k) == k:
				return g
	return {}

# lo llama el juego cuando pasa algo de TIENDA.gana (el stub está en mundo.gd); n, cuántas veces de golpe
func tn_gana(k: String, n := 1) -> void:
	if not tn_hay() or n <= 0:
		return
	var g := tn_gana_def(k)
	if g.is_empty():
		return
	var T0 := tn()
	var da: int = int(g.v) * n
	var tope: int = int(g.get("tope", 0))
	if tope > 0:
		da = mini(da, maxi(0, tope - int(T0.g.get(k, 0))))
	if da <= 0:
		return
	T0.sd = int(T0.sd) + da
	T0.g[k] = int(T0.g.get(k, 0)) + da
	toast(T("<small>LA TIENDA</small>+{n}", {"n": tn_txt(da)}), 1300)

# el regalo a quien compró el juego completo cuando el juego era una demo (una vez)
func tn_regalo() -> void:
	if not tn_hay() or int(tn().r) != 0:
		return
	if not (aj.get("completo", false) or (Datos.PLAY and plat().comprado)):
		return
	var M := tn_mon()
	var T0 := tn()
	T0.r = 1
	T0.sd = int(T0.sd) + int(M.regalo)
	queue("tienda", func(): await say(T("Compraste el juego completo cuando los capítulos del 4 al 8 iban aparte. Ya no: el juego entero viene con la aplicación. Por las molestias, {n} en LA TIENDA.", {"n": tn_txt(int(M.regalo))})))

# ---------- lo que hace falta para cada extra ----------
# true si ese extra se puede comprar ya; si no, el texto de por qué todavía no
func tn_req(x: Dictionary) -> bool:
	var r := String(x.get("req", ""))
	match r:
		"":
			return true
		"haze":
			return S.disc.get(String(HILO.semilla), false) == true
		"cam":
			return cam_ya()
		"nave":
			return S.get("nave") is Dictionary and int(S.nave.get("d", 0)) > 0
		"huerta":
			return S.get("huerta") is Dictionary and S.huerta.has("v")
		"bt":
			return bt_llave()
		"muelle":
			return S.get("mar") is Dictionary and int(S.mar.get("d", 0)) > 0
	return true

# la llave del cuarto de atrás viene con la lata del cuaderno azul (hilo.gd), que da sus semillas
func bt_llave() -> bool:
	return D.has("BANCO_TIA") and S.disc.get(String(HILO.semilla), false) == true

# ---------- las semillas que da la tienda ----------
# las variedades del grupo que todavía no tienes (sin ficha y sin semillas); vacío, nada que mandar
func tn_faltan(grupo: String) -> Array:
	var o := []
	match grupo:
		"haze":
			return [String(HILO.semilla)]
		"land":
			for b in D.BANCO:
				var sid := String(b[0])
				if not S.disc.get(sid) and int(S.seeds.get(sid, 0)) <= 0:
					o.append(sid)
			if D.has("CAZA"):
				for c in D.CAZA.l:
					var sid := String(c.k)
					if D.STRAINS.has(sid) and not S.disc.get(sid) and int(S.seeds.get(sid, 0)) <= 0 and not o.has(sid):
						o.append(sid)
		"rec":
			for r in D.RECIPES:
				var sid := String(D.RECIPES[r])
				if D.STRAINS.has(sid) and not S.disc.get(sid) and int(S.seeds.get(sid, 0)) <= 0 and not o.has(sid):
					o.append(sid)
		"auto":
			for sid in D.AUTO.dex:
				if not S.disc.get(String(sid)) and int(S.seeds.get(String(sid), 0)) <= 0:
					o.append(String(sid))
	o.sort()
	return o

# ---------- aplicar lo comprado ----------
# da lo que lleva x; devuelve el texto de lo que ha llegado, o "" si no había nada que mandar
func tn_aplica(x: Dictionary) -> String:
	var ef: Dictionary = x.get("ef", {})
	match String(ef.get("tipo", "")):
		"items":
			var L := []
			for k in ef.it:
				S.items[k] = int(S.items.get(k, 0)) + int(ef.it[k])
			L.append(I18n.v(String(x.n)).to_lower())
			return _lista(L)
		"semillas":
			var l := tn_faltan(String(ef.grupo))
			if l.is_empty():
				return ""
			var n: int = int(ef.n)
			var L := []
			if bool(ef.get("misma", false)):   # todas de la misma variedad
				var sid := String(l[Datos.hash_str("tn|%s|%d" % [String(x.k), int(S.day)]) % l.size()])
				discover(sid)
				add_seeds(sid, n)
				L.append(T("{n} semillas de {s}", {"n": n, "s": String(strain(sid).n)}))
			else:
				for i in mini(n, l.size()):
					var sid := String(l[i])
					discover(sid)
					add_seeds(sid, 1)
					L.append(T("una semilla de {s}", {"s": String(strain(sid).n)}))
			return _lista(L)
		"sobres":
			if not cam_ya():
				return ""
			S.cam.sob = int(S.cam.get("sob", 0)) + int(ef.n)
			return T("{n} sobres de humedad", {"n": int(ef.n)})
		"arcon":
			if not (S.get("nevera") is Dictionary):
				S.nevera = {}
			S.nevera.arcon = 1
			return K("el arcón congelador")
		"reforma":
			if not (S.get("tn") is Dictionary):
				tn()
			S.tn.obra = 1   # REFORMAS: las obras ya pagadas (reforma_pagada)
			return K("las reformas de suelo y pared, pagadas")
		"conce":
			if S.flags.get("conce") == null:
				S.flags.conce = S.day
				rev_nota("conce")
				if S.map == "alto":
					montar_alto()
			return K("AUTOS RIBERA, abierto")
		"camarote":
			var C: Dictionary = D.CAMAROTE
			if not (S.get("cam") is Dictionary):
				S.cam = {}
			S.cam.d = mini(int(S.cam.get("d", 99999)), int(S.day))
			var e: Array = S.cam.get("e", [])
			while e.size() < int(C.est.max):
				e.append(int(S.day))
			S.cam.e = e
			S.cam.sob = int(S.cam.get("sob", 0)) + int(C.sob.u)
			if S.map == "home":
				montar_casa()
			elif S.map == "camarote":
				montar_camarote()
			return K("el camarote con sus estanterías y doce sobres")
		"despacho":
			if desp().is_empty():
				S.desp = {"d": int(S.day), "money": 0, "buds": []}
				if S.map == "nave-d":
					montar_despacho()
			return K("el despacho de lujo")
		"huerta":
			if not (S.get("huerta") is Dictionary):
				return ""
			var H: Dictionary = S.huerta
			H.l = mini(int(H.get("l", 99999)), int(S.day))
			var m: Dictionary = H.get("m", {}) if H.get("m") is Dictionary else {}
			for k in ["bidon", "ibc", "goteo", "herr", "moto", "amp"]:   # las mismas que la tienda online (huerta_tienda)
				var mx: int = int(HUERTA_MEJ[k].get("max", 1))
				m[k] = maxi(int(m.get(k, 0)), mx)
			H.m = m
			montar_huerta(String(S.map))
			return K("la huerta ampliada con todas sus mejoras")
		"banco":
			var B := bt()
			B.v = int(S.day)
			for c in D.BANCO_TIA.col:
				if not B.c.has(String(c.id)):
					B.c[String(c.id)] = int(S.day)
			bt_entra(String(S.map))
			return K("el banco de la tía, con sus seis colecciones entregadas")
		"kaia":
			if not (S.get("mar") is Dictionary):
				return ""
			var ob: Dictionary = S.mar.get("ob", {}) if S.mar.get("ob") is Dictionary else {}
			for o in D.MAR.obras:
				if not ob.has(String(o.k)):
					ob[String(o.k)] = int(S.day)
			S.mar.ob = ob
			if S.map == "muelle":
				montar_muelle(String(S.map))
			return K("el muelle reformado y KAIA abierto")
	return ""

# REFORMAS: true si las obras del piso están pagadas por la tienda
func reforma_pagada() -> bool:
	return tn_hay() and int(tn().get("obra", 0)) == 1

# ---------- la pantalla de LA TIENDA ----------
func tn_estado(x: Dictionary) -> Dictionary:
	var k := String(x.k)
	var una: bool = bool(x.get("una", false))
	if una and tn_veces(k) > 0:
		return {"ok": false, "rz": K("Ya lo tienes."), "ya": true}
	if not tn_req(x):
		return {"ok": false, "rz": I18n.v(String(x.get("rz", ""))), "ya": false}
	if int(x.sd) > tn_sd():
		return {"ok": false, "rz": T("Te faltan {n}.", {"n": tn_txt(int(x.sd) - tn_sd())}), "ya": false}
	return {"ok": true, "rz": "", "ya": false}

func tn_como() -> String:
	var L := [I18n.v(String(tn_mon().txt)), ""]
	for g in D.TIENDA.gana:
		L.append("· %s: %s" % [I18n.v(String(g.t)), tn_txt(int(g.v))])
	L.append("")
	L.append(I18n.v(String(tn_mon().pie)))
	return "\n".join(PackedStringArray(L))

func tienda_menu() -> void:
	if not tn_hay():
		return
	tn_regalo()
	var i := 0
	while true:
		var cs: Array = D.TIENDA.cat.filter(func(c): return String(c.k) != "sd" or TIENDA_REAL)
		var it := []
		for c in cs:
			var n: int = D.TIENDA.it.filter(func(x): return String(x.cat) == String(c.k) and not tn_estado(x).ya).size()
			it.append({"label": I18n.v(String(c.n)), "right": str(n) if n else K("—"), "desc": I18n.v(String(c.d)), "ic": icono("bolsa")})
		it.append({"label": K("CÓMO SE GANAN"), "desc": K("De dónde salen las semillas doradas."), "ic": icono("trofeo")})
		it.append({"label": K("Volver"), "desc": ""})
		i = await menu(it, {"cls": "full", "title": K("LA TIENDA"), "title2": tn_txt(tn_sd()), "desc": true, "initial": clampi(i, 0, it.size() - 1)})
		if i < 0 or i >= it.size() - 1:
			return
		if i == it.size() - 2:
			await leer(K("LAS SEMILLAS DORADAS"), tn_como())
			continue
		await tn_cat(String(cs[i].k))

func tn_cat(ck: String) -> void:
	var j := 0
	while true:
		var l: Array = D.TIENDA.it.filter(func(x): return String(x.cat) == ck)
		var it := []
		for x in l:
			var e := tn_estado(x)
			var pr: String = Datos.eur(float(x.p)) if ck == "sd" else tn_txt(int(x.sd))
			it.append({"label": I18n.v(String(x.n)), "right": K("YA") if e.ya else pr, "disabled": not (e.ok or ck == "sd"),
				"desc": I18n.v(String(x.t)) + ("\n" + String(e.rz) if String(e.rz) != "" else "")})
		it.append({"label": K("Volver"), "desc": ""})
		var nm := ""
		for c in D.TIENDA.cat:
			if String(c.k) == ck:
				nm = I18n.v(String(c.n))
		j = await menu(it, {"cls": "full", "title": nm, "title2": tn_txt(tn_sd()), "desc": true, "initial": clampi(j, 0, it.size() - 1)})
		if j < 0 or j >= l.size():
			return
		if ck == "sd":
			await tn_pack(l[j])
		else:
			await tn_compra(l[j])

# un paquete de semillas doradas, con dinero de verdad (Google Play)
func tn_pack(x: Dictionary) -> void:
	if not TIENDA_REAL:
		await say(K("Los paquetes solo se compran en la versión de Google Play. Aquí las semillas doradas se ganan jugando."))
		return
	var c: int = await ask(T("{n} por {p}. Se paga por Google Play.", {"n": tn_txt(int(x.da)), "p": Datos.eur(float(x.p))}), [K("Comprar"), K("Dejarlo")])
	if c != 0:
		return
	var e: String = await plat().comprar(String(x.prod))
	if e == "ok":
		var T0 := tn()
		T0.sd = int(T0.sd) + int(x.da)
		T0.c[String(x.k)] = tn_veces(String(x.k)) + 1
		sfx("get")
		save()
		await say(T("¡Gracias! {n} en LA TIENDA.", {"n": tn_txt(int(x.da))}))
		return
	await say({"pendiente": K("La compra está pendiente. Cuando se confirme, las tendrás aquí."), "cancelada": K("Compra cancelada.")}.get(e, K("No se ha podido hacer la compra. Inténtalo más tarde.")))

# algo del catálogo, con semillas doradas
func tn_compra(x: Dictionary) -> void:
	var e := tn_estado(x)
	if not e.ok:
		if String(e.rz) != "":
			await say(String(e.rz))
		return
	var c: int = await ask(T("{n} por {p}.", {"n": I18n.v(String(x.n)), "p": tn_txt(int(x.sd))}), [K("Comprar"), K("Dejarlo")])
	if c != 0:
		return
	var txt := tn_aplica(x)
	if txt == "":
		await say(K("No hay nada que mandarte de esto ahora mismo. No se te cobra."))
		return
	var T0 := tn()
	T0.sd = int(T0.sd) - int(x.sd)
	T0.c[String(x.k)] = tn_veces(String(x.k)) + 1
	sfx("get")
	save()
	await got(txt)
