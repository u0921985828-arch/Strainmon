# Fase 6 (U7, U10, U11; solo con Datos.PLAY): el progreso mientras la app está cerrada (OFFLINE: las plantas crecen OFFLINE.min_h
# minutos de juego por hora fuera, hasta OFFLINE.tope_h horas; el reloj, la deuda y los eventos no corren), el aviso de la cosecha,
# los objetivos diarios (DIARIO, por la fecha del móvil), la demo (capítulos 1-3; el 4 pide la compra única DEMO.producto), los
# logros y la nube de Play Games y el embudo del FTUE (Plataforma, solo con el opt-in de INFORMES DE ERRORES).
# Cadena: ui → mundo → granja → trama → … → eventos → campo → gestion → vida → retencion → juego.
extends "res://src/metro.gd"

const Plataforma = preload("res://src/plataforma.gd")

# 0.52 (lo pidió el usuario: «pierde el sentido… igual se te secan las plantas»): con la app cerrada no pasa nada, ni crecen las
# plantas ni hay aviso de la cosecha; al volver, todo donde lo dejaste. El código se queda, apagado (las pruebas lo encienden)
static var OFFLINE := false
# (lo pidió el usuario: «quita el bloqueo de la demo por ahora»): sin el corte del capítulo 4 ni la compra única; el código se
# queda, apagado (las pruebas lo encienden). Una partida que ya se quedó en la demo sigue desde START · JUEGO COMPLETO
static var DEMO := false
static var HOY := ""        # las pruebas fijan la fecha (AAAA-MM-DD); vacía, la del móvil
static var AHORA := -1.0    # las pruebas fijan la hora unix; negativa, la del móvil
var plat_n: Node = null
var pausa_ts := -1.0

static func ahora() -> float:
	return AHORA if AHORA >= 0 else Time.get_unix_time_from_system()

static func hoy() -> String:
	return HOY if HOY != "" else Time.get_date_string_from_system()

func plat() -> Node:
	if plat_n == null:
		plat_n = Plataforma.new()
		add_child(plat_n)
	return plat_n

# ---------- progreso offline ----------
# los minutos de juego que crecen las plantas por seg segundos fuera (tope OFFLINE.tope_h horas)
func minutos_fuera(seg: float) -> int:
	if seg <= 0:
		return 0
	return int(floor(minf(seg / 3600.0, float(D.OFFLINE.tope_h)) * float(D.OFFLINE.min_h)))

# crecen mn minutos regadas y sin plagas ni daño (el agua, la salud y la plaga se quedan como estaban); da {crecen, listas}
func crece_fuera(mn: int) -> Dictionary:
	var r := {"crecen": 0, "listas": 0}
	if mn <= 0:
		return r
	for i in S.pots.size():
		var p = S.pots[i]
		if p == null or p.get("dead") or p.prog >= 1:
			continue
		var w: float = p.water
		var h: float = p.health
		var pe: bool = p.pest
		p.water = 100.0
		p.pest = false
		Cultivo.plant_step(S, p, mn / 60.0, factores(i))
		p.water = w
		p.health = h
		p.pest = pe
		p.dead = false
		r.crecen += 1
		if p.prog >= 1:
			r.listas += 1
	return r

# al volver (CONTINUAR o la app de segundo plano): lo que ha pasado desde ts, con su pantalla «mientras estabas fuera»
func fuera_desde(ts: float) -> Dictionary:
	if not Datos.PLAY or not OFFLINE or S == null or ts <= 0:
		return {}
	var seg := ahora() - ts
	var mn := minutos_fuera(seg)
	if mn < int(D.OFFLINE.aviso):
		return {}
	var r := crece_fuera(mn)
	r.seg = seg
	r.mn = mn
	if r.crecen > 0:
		var tx := _fuera_txt(r)
		queue("fuera", func(): await leer(K("MIENTRAS ESTABAS FUERA"), tx), [[K("MIENTRAS ESTABAS FUERA"), [tx]]])
	return r

func _fuera_txt(r: Dictionary) -> String:
	var h := int(floor(r.seg / 3600.0))
	var mi := int(floor(r.seg / 60.0))
	var tp := int(D.OFFLINE.tope_h)
	var L: Array
	if r.seg > float(D.OFFLINE.tope_h) * 3600:
		L = [T("Has estado fuera {h} h (cuenta como mucho {t} h).", {"h": h, "t": tp}) if h >= 1 else T("Has estado fuera {m} min (cuenta como mucho {t} h).", {"m": mi, "t": tp})]
	else:
		L = [T("Has estado fuera {h} h.", {"h": h}) if h >= 1 else T("Has estado fuera {m} min.", {"m": mi})]
	L.append(T("Tus plantas han seguido creciendo: {n} planta, como {h} h de juego.", {"n": int(r.crecen), "h": int(r.mn / 60)}) if r.crecen == 1 else T("Tus plantas han seguido creciendo: {n} plantas, como {h} h de juego.", {"n": int(r.crecen), "h": int(r.mn / 60)}))
	if r.listas:
		L.append(T("{n} está lista para cosechar.", {"n": int(r.listas)}) if r.listas == 1 else T("{n} están listas para cosechar.", {"n": int(r.listas)}))
	L.append(T("El reloj del juego, la deuda y lo demás no han corrido."))
	return "\n".join(PackedStringArray(L))

# ---------- aviso de la cosecha ----------
# los segundos reales que faltan para que la primera planta esté lista creciendo fuera (-1 si no llega en OFFLINE.tope_h)
func seg_cosecha() -> int:
	var vivas := []
	for i in S.pots.size():
		var p = S.pots[i]
		if p != null and not p.get("dead") and p.prog < 1:
			vivas.append(i)
		elif p != null and not p.get("dead"):
			return -1   # ya hay una lista: no hace falta avisar
	if vivas.is_empty():
		return -1
	var paso := 30
	var tope: int = int(D.OFFLINE.tope_h) * int(D.OFFLINE.min_h)
	var prog := {}
	for i in vivas:
		prog[i] = S.pots[i].duplicate(true)
	var m := 0
	while m < tope:
		m += paso
		for i in vivas:
			var p: Dictionary = prog[i]
			p.water = 100.0
			p.pest = false
			p.health = 100.0
			Cultivo.plant_step(S, p, paso / 60.0, factores(i))
			if p.prog >= 1:
				return int(ceil(m / float(D.OFFLINE.min_h) * 3600.0))
	return -1

func al_pausar() -> void:
	pausa_ts = ahora()
	if not Datos.PLAY or S == null:
		return
	if OFFLINE and aj.get("avisos"):
		var s := seg_cosecha()
		if s > 0:
			plat().aviso(s, T("Landrace Hunters"), T("Tienes plantas listas para cosechar."))
	if mode == "world" or mode == "carpa":
		plat().nube_guarda(JSON.stringify(S, "", false, true))

func al_volver() -> void:
	if not Datos.PLAY:
		return
	plat().sin_aviso()
	if S != null and pausa_ts > 0 and (mode == "world" or mode == "carpa"):
		fuera_desde(pausa_ts)
	pausa_ts = -1.0

# ---------- objetivos diarios ----------
func diario() -> Dictionary:
	var f := hoy()
	if not (S.get("diario") is Dictionary) or S.diario.get("f") != f:
		var L: Array = D.DIARIOS.o
		var o := []
		var h := int(Time.get_unix_time_from_datetime_string(f + "T00:00:00") / 86400)   # cada día, el siguiente juego de tres
		for j in 3:
			o.append(L[(h + j) % L.size()].id)
		S.diario = {"f": f, "o": o, "c": {}, "v": S.sales, "ok": []}
	return S.diario

func diario_obj(id: String) -> Dictionary:
	for x in D.DIARIOS.o:
		if x.id == id:
			return x
	return {}

func diario_lleva(id: String) -> int:
	var Dd := diario()
	if id == "ventas":
		return maxi(0, int(S.sales - Dd.v))
	return int(Dd.c.get(id, 0))

func cuenta(k: String) -> void:
	if Datos.PLAY and S != null:
		var Dd := diario()
		Dd.c[k] = int(Dd.c.get(k, 0)) + 1
		if not S.flags.get("ev_" + k):   # U10: la primera vez de cada cosa, al embudo
			S.flags["ev_" + k] = 1
			evento(k)

func diario_revisa() -> void:
	if not Datos.PLAY or S == null:
		return
	var Dd := diario()
	for id in Dd.o:
		var x := diario_obj(id)
		if not Dd.ok.has(id) and diario_lleva(id) >= int(x.n):
			Dd.ok.append(id)
			S.items[D.DIARIOS.premio] = int(S.items.get(D.DIARIOS.premio, 0)) + 1
			toast(T("<small>OBJETIVO DIARIO</small>{t} · +1 abono", {"t": x.t}), 2600)

func diarios_txt() -> String:
	return "%d/%d" % [diario().ok.size(), diario().o.size()]

func diario_menu() -> void:
	var Dd := diario()
	var it := []
	for id in Dd.o:
		var x := diario_obj(id)
		var hecho: bool = Dd.ok.has(id)
		var ll := mini(diario_lleva(id), int(x.n))
		it.append({"label": x.t, "right": K("HECHO") if hecho else ("%s/%s" % [Datos.eur(ll), Datos.eur(x.n)] if id == "ventas" else "%d/%d" % [ll, int(x.n)]),
			"desc": K("Cada objetivo hecho da un abono. Cambian cada día (la fecha del móvil).")})
	it.append({"label": K("Volver"), "desc": ""})
	await menu(it, {"cls": "full", "title": K("OBJETIVOS DIARIOS"), "title2": Dd.f, "desc": true})

# ---------- la demo y la compra única ----------
func completo() -> bool:
	if Datos.PLAY and plat().comprado and not aj.get("completo", false):   # comprado en otro móvil o antes de reinstalar
		aj.completo = true
		ajustes_guarda()
	return not Datos.PLAY or not DEMO or aj.get("completo", false)

# al pagar el plazo del capítulo 3: sin el juego completo, la pantalla de la demo; true si se queda en la demo
func demo_corta() -> bool:
	if completo():
		return false
	S.flags.demo4 = 1
	save()
	if await fin_demo():
		S.flags.erase("demo4")
		return false
	return true

func fin_demo() -> bool:
	var c: int = await ask(T("FIN DE LA DEMO\nLos capítulos {c} a 8 vienen con el juego completo: una compra única, sin anuncios ni pagos dentro. La partida te espera aquí.", {"c": int(D.COMPLETO.ch)}),
		[K("Comprar el juego completo"), K("Más tarde")])
	if c != 0:
		await say(K("Cuando quieras: START · JUEGO COMPLETO."))
		return false
	var e: String = await plat().comprar(String(D.COMPLETO.producto))
	if e == "ok":
		aj.completo = true
		ajustes_guarda()
		sfx("get")
		await say(K("¡Gracias! Ya tienes el juego completo."))
		return true
	await say({"pendiente": K("La compra está pendiente. Cuando se confirme, sigue desde START · JUEGO COMPLETO."), "cancelada": K("Compra cancelada.")}.get(e, K("No se ha podido hacer la compra. Inténtalo más tarde.")))
	return false

# START · JUEGO COMPLETO (con S.flags.demo4): true si ya se puede seguir al capítulo 4
func demo_menu() -> bool:
	if completo() or await fin_demo():
		S.flags.erase("demo4")
		return true
	return false

# ---------- Play Games y el embudo ----------
func logro_play(id: String) -> void:
	if Datos.PLAY:
		plat().logro(id)

func evento(k: String) -> void:
	if Datos.PLAY and aj.get("errores"):
		plat().evento(k)
