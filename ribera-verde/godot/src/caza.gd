# Las landraces por estación y por gente y las fiestas fijas (ESTUDIO, tanda 4; lo pidió el usuario: «metas mano a las mejoras
# que hablamos»; solo con Datos.CAL): CAZA de tools/caza.py. Diecisiete personas dan, una vez por partida, una landrace en su
# estación, un día de temporal o en su fiesta (S.caza = {k: día}; con CAL no se venden en el banco del PC); las fiestas —la feria de semillas de primavera en Bilbao, las
# del barrio en agosto y la romería de la ermita— salen en el calendario, con su SMS la víspera y un aviso al llegar (S.fiv).
# Cadena: … → salafria → acto2 → caza → retencion → juego.
extends "res://src/acto2.gd"

const CAZA_COLOR := "#e0a020"   # i18n-no
var CAZA_N := {"koldo": I18n.K("KOLDO"), "bi_serora": I18n.K("SERORA"), "bi_me_es": I18n.K("ESPECIERO"), "bi_me_fl": I18n.K("FLORISTA"),
	"bi_me_ve": I18n.K("VERDULERO"), "patxi": I18n.K("PATXI"), "txaro": I18n.K("ABUELA TXARO"), "julen": I18n.K("JULEN"),
	"bixente": I18n.K("BIXENTE"), "andoni": I18n.K("ANDONI"), "txomin": I18n.K("TXOMIN"), "inaki": I18n.K("IÑAKI"),
	"arrieta": I18n.K("ARRIETA"), "delroy": I18n.K("DELROY"), "miren": I18n.K("MIREN"), "kiko": I18n.K("KIKO"), "bi_capataz": I18n.K("CAPATAZ")}

func caza() -> Dictionary:
	if not (S.get("caza") is Dictionary):
		S.caza = {}
	return S.caza

func fiesta_ini(f: Dictionary, y: int) -> int:
	return Datos.dia_de(y, int(f.m), int(f.d))

# la fiesta de ese día ({} si no hay)
func fiesta_de(dia: int) -> Dictionary:
	if not Datos.CAL:
		return {}
	var y: int = int(Datos.fecha(dia).y)
	for f in D.CAZA.fi:
		var a := fiesta_ini(f, y)
		if dia >= a and dia < a + int(f.dias):
			return f
	return {}

# si esa persona da hoy su landrace: una vez, desde su capítulo, en su estación, con su tiempo, en su fiesta y con confianza
func caza_ok(e: Dictionary) -> bool:
	if not Datos.CAL or caza().has(String(e.k)) or int(S.ch) < int(e.get("ch", 2)):
		return false
	if e.has("est") and not (Datos.estacion(int(S.day)) in e.est):
		return false
	if e.has("cl") and not (String(Datos.tiempo(int(S.day), int(S.min)).k) in e.cl):
		return false
	if e.has("fi") and String(fiesta_de(int(S.day)).get("k", "")) != String(e.fi):
		return false
	if e.has("flag") and not S.flags.get(String(e.flag)):
		return false
	if e.has("mar") and S.get("mar") == null:   # Koldo, después de conocerle en el muelle
		return false
	if S.get("cazaN") is Dictionary and int(S.cazaN.get(String(e.k), -1)) == int(S.day):   # i18n-no · dicho que no hoy: lo de siempre
		return false
	return rel(String(e.q)) >= int(e.get("rel", 0))

# npc_talk: la landrace de esa persona, si toca hoy; si no, lo de siempre (false, sin esperar: ver hilo_talk en acto2.gd)
func hilo_talk(id: String) -> bool:
	if await super(id):
		return true
	if not Datos.CAL or (id.begins_with("bi_") and ciudad_cerrada()):
		return false
	for e in D.CAZA.l:
		if String(e.q) == id and caza_ok(e):
			await caza_da(e)
			return true
	return false

func caza_da(e: Dictionary) -> void:
	var k := String(e.k)
	var N: String = CAZA_N.get(String(e.q), String(e.q).to_upper())
	await talk(N, e.t.map(func(t): return I18n.v(t)))
	var nom := String(strain(k).n).to_upper()
	if e.has("eur"):
		if await ask(T("{n} semillas de {s}, {e}.", {"n": int(e.n), "s": nom, "e": Datos.eur(float(e.eur))}), [K("Comprar"), K("No")], N) != 0:
			caza_no(k)
			await say(K("«Tú verás. Hasta que acabe la feria, aquí las tengo.»"), N)
			return
		if float(S.money) < float(e.eur):
			caza_no(k)
			sfx("bad")
			await say(K("«En la feria, solo efectivo.»"), N)
			return
		S.money = snappedf(float(S.money) - float(e.eur), 0.01)
		sfx("coin")
		update_hud()
	add_seeds(k, int(e.n))
	caza()[k] = int(S.day)
	await got(T("{n} semillas de {s}", {"n": int(e.n), "s": nom}))

func caza_no(k: String) -> void:   # por hoy, no vuelve a ofrecerla: lo que vende de siempre
	if not (S.get("cazaN") is Dictionary):   # i18n-no
		S.cazaN = {}
	S.cazaN[k] = int(S.day)

# si en esa fiesta queda alguien con su landrace por dar (las fiestas vuelven cada año; lo de la caza, una vez)
func fiesta_pend(f: Dictionary) -> bool:
	return D.CAZA.l.any(func(e): return String(e.get("fi", "")) == String(f.k) and not caza().has(String(e.k)))

# al amanecer: la víspera de cada fiesta, su SMS
func hilo_dia() -> void:
	super()
	if not Datos.CAL or int(S.ch) < 2:
		return
	var f := fiesta_de(int(S.day) + 1)
	if f.is_empty() or not fiesta_de(int(S.day)).is_empty() or not fiesta_pend(f):
		return
	var de: String = K("SMS · ") + I18n.v(f.de)
	var L := [I18n.v(f.sms)]
	queue("fiesta" + String(f.k), func(): await talk(de, L), [[de, L]])   # i18n-no

# al entrar donde se celebra, el aviso, una vez al día
func hilo_entra(mapa: String) -> void:
	super(mapa)
	var f := fiesta_de(int(S.day))
	if f.is_empty() or String(f.mapa) != mapa or int(S.get("fiv", -1)) == int(S.day) or not fiesta_pend(f):
		return
	S.fiv = int(S.day)
	toast(T("Hoy: {f}", {"f": I18n.v(f.n)}), 2200)

# las fiestas, en el calendario (este año y el que viene): una marca, el primer día, con los días que dura (que no tape los plazos)
func marcas_cal() -> Array:
	var r := super()
	if not Datos.CAL:
		return r
	var y: int = int(Datos.fecha(int(S.day)).y)
	for yy in [y, y + 1]:
		for f in D.CAZA.fi:
			var t: String = I18n.v(f.n) if int(f.dias) < 2 else T("{n}, {d} días", {"n": I18n.v(f.n), "d": int(f.dias)})
			r.append({"d": fiesta_ini(f, yy), "c": CAZA_COLOR, "t": t})
	r.sort_custom(func(a, b): return a.d < b.d)
	return r
