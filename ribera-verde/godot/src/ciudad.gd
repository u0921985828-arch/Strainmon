# Bilbao por dentro (lo pidió el usuario: «molaría poder acceder al teatro… y a la iglesia también… piensa en qué edificios
# podrían tener juego en la historia»; solo con Datos.CAL; los mapas y la gente, de tools/bilbao.py → BILBAO.IN y BILBAO.NPC):
# el teatro (la taquilla, la función de la noche y el entreacto, donde se conoce a gente que importa), las iglesias (los bancos,
# las velas, el cepillo y el confesionario: donde se enfría el calor) y el mercado de la Ribera (los puestos y la barra de
# pintxos: comer baja la borrachera y da vida). Cadena: … → copa → ciudad → retencion → juego.
extends "res://src/copa.gd"

const IGLESIAS := ["catedral-in", "sannicolas-in", "iglesiaz-in", "ermita-in", "sananton-in", "milagrosa-in"]   # i18n-no
const TEATROS := ["teatro-in", "campose-in"]   # i18n-no
const ESTACIONES := ["zorrozae-in", "abandoe-in", "concordia-in"]   # i18n-no
const OTROS_IN := {"mercado-in": "mercado", "hacienda-in": "hacienda", "molino-in": "molino", "almacen-in": "almacen"}   # i18n-no
# los horarios, en minutos [abre, cierra)
const HORARIO := {"teatro": [600, 1410], "iglesia": [480, 1200], "mercado": [480, 900], "estacion": [360, 1380], "hacienda": [510, 840],   # i18n-no
	"molino": [540, 1140], "almacen": [420, 900]}   # i18n-no
# el tren desde las estaciones: más barato y más rápido que el autobús (sobre el de la parada de Bilbao)
const TREN := {"eur": 0.8, "min": 0.6}
# la ventanilla de Hacienda: declarar efectivo, una vez por semana, hasta el tope; Hacienda se queda la cuota y el resto va a la cuenta
const HACIENDA := {"tope": 3000, "cuota": 0.3, "dias": 7}
# el jornal del almacén del muelle: una vez al día, si llegas antes de mediodía
const JORNAL := {"eur": 45, "min": 180, "hp": 3, "hasta": 720}
const CABEZADA := {"min": 90, "hp": 6}
const PERIODICO := 1.5
const GRUA_XP := 3
const TAQUILLA := [1080, 1260]   # la taquilla vende de 18:00 a 21:00
const FUNCION := [1260, 1380]    # la función, de 21:00 a 23:00
const ENTRADA := 18
const CEPILLO := 20
const VELA := 1
const VIP_DIAS := 7
const CONFIESA_DIAS := 7
# las obras de la temporada, una por semana (inventadas)
var OBRAS := [[I18n.K("La ría no duerme"), I18n.K("Dos hermanas se reparten la casa de su madre en Deusto y no se ponen de acuerdo ni en el reloj de la cocina.")],
	[I18n.K("Marea baja"), I18n.K("Un pescador jubilado espera en el muelle a un barco que nunca vuelve. El público sale en silencio.")],
	[I18n.K("El último tranvía"), I18n.K("Una comedia de enredos en un tranvía parado a medianoche. Se ríe hasta el acomodador.")],
	[I18n.K("Hierro"), I18n.K("Tres generaciones de una familia de la fundición, en una sola cena. Aplauden de pie.")],
	[I18n.K("La verbena"), I18n.K("Un musical de barrio: fiestas, una orquesta desafinada y un amor de verano. Sales tarareando.")],
	[I18n.K("Niebla en el Arenal"), I18n.K("Un misterio con un cadáver que no aparece. Hasta el final no sabes quién miente.")]]
# lo de los puestos del mercado: [qué, euros, vida, borrachera que baja]
var PUESTOS := {"fr": [I18n.K("Una bolsa de cerezas"), 3.0, 4, 4], "pe": [I18n.K("Unas anchoas en vinagre"), 4.5, 6, 6], "ca": [I18n.K("Un bocadillo de lomo"), 5.0, 10, 10],
	"qu": [I18n.K("Una cuña de queso"), 4.0, 6, 6], "ve": [I18n.K("Unos tomates con sal"), 2.5, 4, 4], "pa": [I18n.K("Una barra recién hecha"), 1.5, 5, 8],
	"fl": [I18n.K("Un ramo de margaritas"), 8.0, 0, 0], "es": [I18n.K("Un cucurucho de frutos secos"), 3.0, 4, 4]}
var OFICIO := {"fr": I18n.K("FRUTERA"), "pe": I18n.K("PESCADERO"), "ca": I18n.K("CARNICERO"), "qu": I18n.K("QUESERA"), "ve": I18n.K("VERDULERO"), "pa": I18n.K("PANADERA"), "fl": I18n.K("FLORISTA"), "es": I18n.K("ESPECIERO")}

func ciu() -> Dictionary:
	if not (S.get("ciudad") is Dictionary):
		S.ciudad = {}
	return S.ciudad

func ciudad_abierta(t: String) -> bool:
	var h: Array = HORARIO[t]
	return int(S.min) >= int(h[0]) and int(S.min) < int(h[1])

func hhmm(mn: int) -> String:
	return "%d:%02d" % [mn / 60, mn % 60]

# la puerta (entra_local): cerrado fuera de su horario
# de qué es cada sitio de dentro (el tipo de su puerta, HORARIO)
func tipo_in(mp: String) -> String:
	if mp in IGLESIAS:
		return "iglesia"
	if mp in TEATROS:
		return "teatro"
	if mp in ESTACIONES:
		return "estacion"
	return String(OTROS_IN.get(mp, ""))

# (revisión: «dentro del mercado y de las iglesias se puede comprar y usar todo fuera de hora»): a la hora de cerrar, a la calle
func ciudad_cerrada() -> bool:
	var t := tipo_in(String(S.map))
	return t != "" and MAPS.has(S.map) and D.get("BILBAO", {}).get("IN", {}).has(S.map) and not ciudad_abierta(t)

func echar_ciudad() -> void:
	await say(K("«Vamos, que cerramos.» Te acompañan a la puerta."))
	var ex: Dictionary = MAPS[S.map].exits
	await warp(ex[ex.keys()[0]])

func entra_ciudad(t: String) -> bool:
	if ciudad_abierta(t):
		return true
	atras_puerta()
	var h: Array = HORARIO[t]
	await say(T("Cerrado. En la puerta: de {a} a {b}.", {"a": hhmm(int(h[0])), "b": hhmm(int(h[1]))}))
	return false

# la gente de dentro, por su horario (build_ents)
func ciudad_npcs(mapa: String) -> Array:
	if not Datos.CAL or not D.has("BILBAO") or not D.BILBAO.has("NPC") or not D.BILBAO.IN.has(mapa):
		return []
	var o := []
	for n in D.BILBAO.NPC:
		if n.map == mapa and int(S.min) >= int(n.desde) and int(S.min) < int(n.hasta):
			if n.id == "bi_ainhoa" and FUNCION[0] <= int(S.min):
				continue
			o.append(n.duplicate())
	return o

func talk_ciudad(id: String) -> void:
	if ciudad_cerrada():
		await echar_ciudad()
		return
	if id.begins_with("bi_taquillero_"):
		await tren()
	elif id.begins_with("bi_vigilante_"):
		await say(K("«Tú. Las manos donde las vea.» Te mira la mochila de arriba abajo y te deja ir.") if float(S.heat) >= 50 else pick([K("«Sin correr por el vestíbulo.»"), K("«El ascensor de Zorroza, ni lo intentes: lleva dos años roto.»")]), K("VIGILANTE"))
	elif id == "bi_funcionaria":
		await hacienda()
	elif id == "bi_molinero":
		await talk_molinero()
	elif id == "bi_capataz":
		await jornal()
	elif id.begins_with("bi_taquillera"):
		await taquilla()
	elif id == "bi_ainhoa":
		await talk_ainhoa()
	elif id.begins_with("bi_actor"):
		await say(K("«Shhh. Estamos en escena.»"), K("ACTOR"))
	elif id == "bi_feligresa":
		await say(K("«Antes venía mucha gente. Ahora, los turistas y yo.»"), K("FELIGRESA"))
	elif id.begins_with("bi_cura_"):
		await talk_cura()
	elif id.begins_with("bi_me_"):
		await puesto(id.substr(6))
	elif id == "bi_camarero":
		await barra_mercado()
	elif id == "bi_serora":
		var C := ciu()
		if not C.get("serora"):
			C.serora = true
			await say(K("«La ermita la cuido yo, que el cura sube una vez al mes. Tu tía subía en romería todos los años, con sus cuadernos.»"), K("SERORA"))
		else:
			await say(pick([K("«Cierro a las ocho. Si te sientas, no hagas ruido.»"), K("«La campana no la toques, que baja todo el pueblo.»")]), K("SERORA"))

# ---------- el teatro ----------
func obra() -> Array:   # el del Ensanche, otra de la temporada
	return OBRAS[(int(S.day) / 7 + (3 if S.map == "campose-in" else 0)) % OBRAS.size()]

func taquilla() -> void:
	var N := K("TAQUILLERA")
	var C := ciu()
	if int(C.get("ent", -1)) == int(S.day) and String(C.get("entM", "teatro-in")) == S.map:
		await say(K("«Ya tienes la tuya. Siéntate donde quieras; empieza a las nueve.»"), N)
		return
	if int(S.min) < TAQUILLA[0] or int(S.min) >= TAQUILLA[1]:
		await say(T("«La taquilla abre a las seis. Esta semana, {o}, a las nueve.»", {"o": obra()[0]}), N)
		return
	if await ask(T("«{o}, esta noche a las nueve. {e} la entrada.»", {"o": obra()[0], "e": Datos.eur(ENTRADA)}), [K("Comprar"), K("No")], N) != 0:
		return
	if float(S.money) < ENTRADA:
		sfx("bad")
		await say(K("«Solo efectivo, cariño.»"), N)
		return
	S.money = snappedf(float(S.money) - ENTRADA, 0.01)
	C.ent = int(S.day)
	C.entM = S.map
	sfx("coin")
	update_hud()
	await say(K("«Platea, sin numerar. Que la disfrutes.»"), N)

# sentado en una butaca: ver la función (con entrada del día, de las seis a las nueve y media)
func funcion_teatro() -> void:
	var C := ciu()
	if int(C.get("ent", -1)) != int(S.day) or String(C.get("entM", "teatro-in")) != S.map:
		await say(K("Sin entrada no hay función. La taquilla vende de seis a nueve."))
		return
	if int(S.min) >= FUNCION[0] + 30:
		await say(K("La función ya va por la mitad. Hoy, ya no."))
		return
	if int(S.min) < TAQUILLA[0]:
		await say(K("Todavía no hay función. Empieza a las nueve."))
		return
	C.ent = -1
	await fade(1)
	if int(S.min) < FUNCION[0]:
		advance_time(FUNCION[0] - int(S.min))
	advance_time(FUNCION[1] - int(S.min))
	update_hud()
	await wait(300)
	await fade(0)
	var o := obra()
	await say(T("«{t}». {d}", {"t": o[0], "d": o[1]}))
	await entreacto()

# a la salida, en el vestíbulo: alguien que importa, como mucho una vez cada VIP_DIAS días y si cabe en la agenda
func entreacto() -> void:
	var C := ciu()
	if int(S.day) - int(C.get("vip", -99)) < VIP_DIAS or S.fijos.size() >= D.FIJOS_MAX:
		return
	C.vip = int(S.day)
	C.vipN = int(C.get("vipN", 0)) + 1
	var id := "teat%d" % int(C.vipN)
	var nv := nombre_fijo(id)
	S.fijos.append({"id": id, "n": nv, "t": "vip", "dia": 0})
	sfx("get")
	await say(T("A la salida, en el vestíbulo, {n} comenta la obra contigo. Habláis de todo un poco y te pide el número: «Me han dicho que tienes de lo bueno».", {"n": nv}))

func talk_ainhoa() -> void:
	var N := K("AINHOA")
	var C := ciu()
	if not C.get("ainhoa"):
		C.ainhoa = true
		await say(K("«Perdona, estoy ensayando. ¿Vienes a ver la de esta semana? Ven, que la del final la hago yo.»"), N)
		return
	if S.fijos.size() < D.FIJOS_MAX and not S.fijos.any(func(f): return f.id == "ainhoa"):
		if await ask(K("«Oye, tú. Dicen en el bar de enfrente que tienes algo para después de la función…»"), [K("Darle tu número"), K("Hacerte el tonto")], N) == 0:
			S.fijos.append({"id": "ainhoa", "n": "Ainhoa", "t": "vip", "dia": 0})   # i18n-no
			sfx("get")
			await say(K("«Te llamo cuando acabe la temporada. Discreción, ¿eh?» Apuntas su número."), N)
		return
	await say(pick([K("«Repaso el texto. Si me equivoco, me lo dices.»"), K("«El escenario es más pequeño de lo que parece desde ahí.»")]), N)

# ---------- las iglesias ----------
func talk_cura() -> void:
	var N := K("SACERDOTE")
	var C := ciu()
	if not C.get("cura"):
		C.cura = true
		await say(K("«Tú eres el sobrino de Maite, ¿verdad? Venía los jueves a encender una vela. Se la echa de menos.»"), N)
		return
	await say(pick([K("«La casa está abierta. Siéntate el rato que quieras.»"), K("«Si algo te pesa, el confesionario está ahí.»")]), N)

func iglesia_obj(o: String) -> bool:
	var C := ciu()
	match o:
		"velasI":
			if await ask(K("El lampadario, con velas encendidas. Una vela, un euro."), [K("Encender una"), K("No")]) != 0:
				return true
			if float(S.money) < VELA:
				await say(K("No llevas ni un euro suelto."))
				return true
			S.money = snappedf(float(S.money) - VELA, 0.01)
			update_hud()
			if not C.get("vela"):
				C.vela = true
				await say(K("Enciendes una por la tía Maite. Te acuerdas de sus cuadernos, de su letra pequeña, de cómo olía la casa."))
			else:
				await say(K("Enciendes una vela. La llama tiembla un rato y se queda quieta."))
		"cepilloI":
			if int(C.get("cep", -1)) == int(S.day):
				await say(K("El cepillo. Hoy ya has echado."))
				return true
			if await ask(T("El cepillo de las limosnas. ¿Echas {e}?", {"e": Datos.eur(CEPILLO)}), [K("Echar"), K("No")]) != 0:
				return true
			if float(S.money) < CEPILLO:
				await say(K("No llevas tanto suelto."))
				return true
			S.money = snappedf(float(S.money) - CEPILLO, 0.01)
			C.cep = int(S.day)
			S.heat = maxf(0, float(S.heat) - 5)
			sfx("coin")
			update_hud()
			await say(K("Echas los billetes. En el barrio se sabe quién ayuda a la parroquia: se habla menos de ti."))
		"confesI", "confesI2":   # i18n-no
			if int(S.day) - int(C.get("conf", -99)) < CONFIESA_DIAS:
				await say(K("La cortina está echada. Hace nada que viniste."))
				return true
			if await ask(K("El confesionario, con la cortina corrida."), [K("Confesarte"), K("No")]) != 0:
				return true
			C.conf = int(S.day)
			await fade(1)
			advance_time(20)
			await fade(0)
			S.heat = maxf(0, float(S.heat) - 10)
			update_hud()
			await say(K("Hablas sin dar nombres. Al otro lado, una voz cansada: «Ve con cuidado, hijo». Sales más ligero, y con menos ganas de que te vean."))
		"pilaI":
			await say(K("La pila del agua bendita, de piedra gastada."))
		"altarI", "altarI2":   # i18n-no
			await say(K("El altar, con su mantel blanco y dos candeleros."))
		"retabloI", "retabloI2", "retabloB", "retabloB2", "cruzZ", "cruzZ2":   # i18n-no
			await say(K("El retablo, dorado y oscuro. Hace falta un rato para ver todo lo que tiene."))
		"cirioI":
			await say(K("Un cirio alto. La cera le cae a chorretones."))
		"columnaI":
			await say(K("Una columna de piedra, fría al tacto."))
		_:
			return false
	return true

# sentado en un banco de la iglesia: un rato en silencio baja el calor, una vez al día
func rato_iglesia() -> void:
	advance_time(30)
	var C := ciu()
	var t := T("Media hora en silencio. Solo se oye la piedra.")
	if int(C.get("rezo", -1)) != int(S.day) and float(S.heat) > 0:
		C.rezo = int(S.day)
		S.heat = maxf(0, float(S.heat) - 3)
		t += T(" Aquí no te busca nadie.")
	update_hud()
	await say(t)

# ---------- los hitos de los pueblos (tools/pueblos.py: lavadero, kiosko, frontón, ermita, faro, chimenea, grúa, reloj, prensa,
# colmenas); cada uno da algo que hacer (revisión: «varios hitos son una sola línea de texto») ----------
func hito_de(x: int, y: int) -> String:
	if not MAPS.has(S.map):
		return ""
	for b in MAPS[S.map].get("blds", []):
		if b.has("hito") and x >= int(b.x0) and x < int(b.x0) + int(b.w) and y >= int(b.y0) and y < int(b.y0) + int(b.h):
			return str(b.hito)
	return ""

func hito_obj(x: int, y: int) -> bool:
	var h := hito_de(x, y)
	if h == "" and en_anden(x, y):
		h = "apeadero"
	if h == "":
		return false
	var C := ciu()
	match h:
		"apeadero":
			await apeadero()
		"lavadero":
			if await ask(K("El lavadero viejo del pueblo. El agua baja fría del monte."), [K("Lavarte la cara"), K("Nada")]) == 0:
				beber_alc(-8)
				advance_time(5)
				update_hud()
				await say(K("El agua helada te despeja de golpe."))
		"kiosko":
			var f: Dictionary = Datos.fecha(int(S.day))
			if int(f.s) == 6 and int(S.min) >= 720 and int(S.min) < 840:
				advance_time(20)
				update_hud()
				await say(K("Domingo: la banda toca pasodobles en el kiosko. Los mayores bailan y los críos corren alrededor."))
			elif int(C.get("kiosko", -1)) == int(S.day):
				await say(K("El kiosko de la música. Los domingos a mediodía toca la banda."))
			else:   # entre semana, los jubilados de la escalinata saben cómo está el barrio (el nivel de la policía)
				C.kiosko = int(S.day)
				advance_time(15)
				update_hud()
				await say(K("En la escalinata del kiosko, los jubilados de siempre. Entre semana no hay banda, pero se enteran de todo:") + " " + [K("«Ni un municipal en toda la mañana. Tranquilo está el barrio.»"), K("«Hay una patrulla dando vueltas de más. Ojo, que miran mucho.»"), K("«Andan preguntando por uno que vende hierba. Que no seas tú, chaval.»"), K("«Dicen que un juez ha firmado papeles. Si tienes algo en casa, muévelo.»")][nivel_poli()])
		"fronton":
			if await ask(K("La pared del frontón, con las marcas de mil pelotazos."), [K("Pelotear un rato"), K("Nada")]) == 0:
				await fade(1)
				advance_time(30)
				await fade(0)
				beber_alc(-10)
				S.hp = mini(int(S.hpMax), int(S.hp) + 3)
				update_hud()
				await say(K("Media hora a pala contra la pared. Sudas lo que no está escrito y la cabeza se te aclara."))
		"ermita":   # el pórtico, con el valle a los pies: se te pasa la borrachera, una vez al día
			if int(C.get("portico", -1)) == int(S.day) or await ask(K("La ermita del monte, de piedra y con su campana. La puerta está abajo; el pórtico mira al valle."), [K("Sentarte en el pórtico"), K("Nada")]) != 0:
				if int(C.get("portico", -1)) == int(S.day):
					await say(K("La ermita del monte. Ya has estado hoy en el pórtico."))
				return true
			C.portico = int(S.day)
			advance_time(20)
			beber_alc(-5)
			update_hud()
			await say(K("Veinte minutos con el valle a los pies y el viento en la cara. Se te asienta todo."))
		"faro":
			if int(C.get("faro", -1)) == int(S.day):
				await say(K("El faro. Ya has estado hoy mirando el mar."))
			else:
				C.faro = int(S.day)
				advance_time(20)
				S.heat = maxf(0, float(S.heat) - 2)
				update_hud()
				await say(K("Te sientas al pie del faro a ver las olas romper contra el espigón. Aquí no te busca nadie."))
		"chimenea":   # al pie, la chatarra de la fundición: un poco de cobre para Bixente, una vez al día
			if int(C.get("chatarra", -1)) == int(S.day):
				await say(K("La chimenea de la fundición vieja. Al pie ya no queda nada que valga."))
			elif await ask(K("La chimenea de la fundición vieja. Lleva treinta años sin echar humo; al pie, chatarra y cable viejo."), [K("Rebuscar"), K("Nada")]) == 0:
				C.chatarra = int(S.day)
				var e := 5 + Datos.hash_str("chatarra%d" % int(S.day)) % 11
				advance_time(30)
				S.money = snappedf(float(S.money) + e, 0.01)
				sfx("coin")
				update_hud()
				await say(T("Media hora entre ladrillos rotos. Sacas un rollo de cobre y Bixente, en la chatarrería, te da {e}.", {"e": Datos.eur(e)}))
		"gruaT":   # el gancho de la grúa, con un saco viejo: entrenar, una vez al día (experiencia de pelea)
			if int(C.get("grua", -1)) == int(S.day):
				await say(K("La grúa vieja, con el saco colgando del gancho. Ya has entrenado hoy."))
			elif await ask(K("Una grúa de astillero, oxidada. Del gancho cuelga un saco de arena que alguien usa para entrenar."), [K("Darle al saco"), K("Nada")]) == 0:
				C.grua = int(S.day)
				await fade(1)
				advance_time(45)
				await fade(0)
				S.pelea.xp = int(S.pelea.xp) + GRUA_XP
				S.hp = maxi(1, int(S.hp) - 1)
				update_hud()
				await say(K("Tres cuartos de hora de golpes y esquivas contra el saco. Te duelen los nudillos; la próxima pelea, se notará."))
		"reloj":   # la torre del reloj de Ibarbide: en su banco corrido, esperar a una hora
			var hs := [540, 840, 1080, 1260, 1380].filter(func(h): return h > int(S.min))
			if hs.is_empty():
				await say(K("La torre del reloj. Ya es tarde: la esfera, iluminada, sobre la plaza vacía."))
				return true
			var ops: Array = hs.map(func(h): return T("Hasta las {h}", {"h": hhmm(h)}))
			ops.append(K("Nada"))
			var c: int = await ask(T("La torre del reloj marca las {h}. En su banco corrido se espera bien.", {"h": hhmm(int(S.min))}), ops)
			if c >= 0 and c < hs.size():
				await fade(1)
				advance_time(int(hs[c]) - int(S.min))
				build_ents()
				update_hud()
				await fade(0)
				await say(T("Las {h}. Las campanas de la torre dan la hora sobre tu cabeza.", {"h": hhmm(int(S.min))}))
		"prensa":   # el quiosco de prensa del Ensanche: el periódico, el tiempo de mañana y cómo anda la policía
			if int(C.get("prensa", -1)) == int(S.day):
				await say(K("El quiosco de prensa. El periódico de hoy ya lo tienes."))
			elif await ask(T("El quiosco de prensa. El periódico, {e}.", {"e": Datos.eur(PERIODICO)}), [K("Comprar"), K("Nada")]) == 0:
				if float(S.money) < PERIODICO:
					await say(K("No llevas suelto."))
					return true
				S.money = snappedf(float(S.money) - PERIODICO, 0.01)
				C.prensa = int(S.day)
				sfx("coin")
				update_hud()
				var ti: Dictionary = Datos.tiempo(int(S.day) + 1, 720)
				await say(T("El tiempo de mañana: {t}, de {a} a {b} °C.", {"t": I18n.v(String(ti.n)), "a": int(ti.min), "b": int(ti.max)}) + " " + [K("En sucesos, nada de la comarca."), K("En sucesos, la policía refuerza las patrullas del barrio."), K("En sucesos, «la policía investiga una red de venta de marihuana en la comarca».") , K("En sucesos, «un juzgado autoriza registros por tráfico de marihuana».")][nivel_poli()])
		"colmenas":   # el colmenar de Errotabarri: un poco de miel del panal, una vez al día (y alguna picadura)
			if int(C.get("miel", -1)) == int(S.day):
				await say(K("El colmenar. Las abejas ya te tienen fichado: hoy, mejor no."))
			elif await ask(K("El colmenar de Errotabarri. El zumbido se oye desde el camino."), [K("Coger un poco de miel"), K("Nada")]) == 0:
				C.miel = int(S.day)
				advance_time(15)
				if Datos.hash_str("miel%d" % int(S.day)) % 4 == 0:
					S.hp = maxi(1, int(S.hp) - 2)
					update_hud()
					sfx("bad")
					await say(K("Metes la mano y te pica una en el dedo. Sales corriendo con la mano hinchada y sin miel."))
				else:
					S.hp = mini(int(S.hpMax), int(S.hp) + 6)
					beber_alc(-4)
					update_hud()
					await say(K("Un trozo de panal chorreando. Lo chupas allí mismo: dulce y espeso, te devuelve el cuerpo."))
		_:
			return false
	return true

# ---------- el mercado ----------
func puesto(k: String) -> void:
	if not PUESTOS.has(k):
		return
	var P_: Array = PUESTOS[k]
	var N: String = OFICIO[k]
	if await ask(T("«¿Qué te pongo? {q}, {e}.»", {"q": P_[0], "e": Datos.eur(P_[1])}), [K("Comprar"), K("Nada")], N) != 0:
		return
	if float(S.money) < float(P_[1]):
		await say(K("«Sin dinero no hay género, majo.»"), N)
		return
	S.money = snappedf(float(S.money) - float(P_[1]), 0.01)
	sfx("coin")
	if k == "fl":
		update_hud()
		await say(K("Te lo envuelve en papel de estraza. Huele a campo."), N)
		return
	S.hp = mini(int(S.hpMax), int(S.hp) + int(P_[2]))
	beber_alc(-float(P_[3]))
	advance_time(10)
	update_hud()
	await say(T("{q}. Te lo comes allí mismo, de pie. Se te asienta el cuerpo.", {"q": P_[0]}))

func barra_mercado() -> void:
	await beber_sentado("mercado")

func obj_ciudad(o) -> bool:
	if not Datos.CAL or not D.has("BILBAO") or not D.BILBAO.has("IN") or not D.BILBAO.IN.has(S.map):
		return false
	if ciudad_cerrada():
		await echar_ciudad()
		return true
	var s := String(o)
	if S.map in ESTACIONES:
		match s:
			"taquillaT", "taquillaT2", "maquinaE":   # i18n-no
				await tren()
			"panelE", "panelE2":   # i18n-no
				await say(K("El panel de salidas: trenes a la comarca cada media hora, de seis de la mañana a once de la noche."))
			_:
				return false
		return true
	if S.map == "hacienda-in":
		match s:
			"taquillaT", "taquillaT2":   # i18n-no
				await hacienda()
			"columnaI":
				await say(K("Una columna de mármol. El palacio entero huele a cera y a papel."))
			_:
				return false
		return true
	if S.map == "molino-in":
		match s:
			"ruedaM", "ruedaM2":   # i18n-no
				await say(K("La marea sube: el agua entra en el estanque y la compuerta está abierta. La muela, quieta.") if marea_sube() else K("La marea baja: el agua sale por el canal y la muela gira despacio, rascando la piedra."))
			"sacos":
				await cabezada()
			"cajasMe":
				await say(K("Cajas de herramientas del molinero, con su candado."))
			_:
				return false
		return true
	if S.map == "almacen-in":
		match s:
			"cajasMe":
				await say(K("Cajas de la carga, flejadas. Huelen a pescado y a gasoil."))
			"sacos":
				await say(K("Sacos de café verde, esperando al camión."))
			_:
				return false
		return true
	if S.map in TEATROS:
		match s:
			"taquillaT", "taquillaT2":   # i18n-no
				await taquilla()
			"cartelT", "cartelT2":   # i18n-no
				await say(T("El cartel de la semana: «{t}». Función a las nueve.", {"t": obra()[0]}))
			"telonI", "telonD":   # i18n-no
				await say(K("El telón de terciopelo, recogido con su cordón dorado."))
			"decoT", "decoT2":   # i18n-no
				await say(K("El decorado de la obra: una casa pintada en tela, con su ventana y todo."))
			"palcoT", "palcoT2":   # i18n-no
				await say(K("Un palco, con sus cortinas. Se sube por otra escalera que está cerrada."))
			"plantaT":
				await say(K("Una planta de interior, mustia. Le haría falta un buen abono."))
			_:
				return false
		return true
	if S.map in IGLESIAS:
		return await iglesia_obj(s)
	if S.map == "mercado-in":
		if s.begins_with("puesto"):
			await puesto(s.trim_suffix("2").substr(6).to_lower())
			return true
		match s:
			"barraMe", "barraMe2":   # i18n-no
				await barra_mercado()
			"cajasMe":
				await say(K("Cajas de fruta vacías, apiladas para el camión."))
			_:
				return false
		return true
	return false

# ---------- las estaciones: el tren ----------
# (lo pidió el usuario: «si te permite ir a demás pueblos, debería de haber estación de tren en los demás pueblos, no puede ser que
# subas al tren y aparezcas en la parada del bus»): cada pueblo de la parada tiene su apeadero (hito «apeadero» de tools/pueblos.py);
# el tren va de estación en estación: de Bilbao a los apeaderos, de un apeadero a otro y de vuelta a la estación de Zorroza
const TREN_BILBAO := [8, 14]   # delante de la puerta de la estación de Zorroza

# la casilla de delante del apeadero de un pueblo (o [] si no tiene)
func apeadero_de(k: String) -> Array:
	for b in D.get("PUEBLOS", {}).get("MAPS", {}).get(k, {}).get("blds", []):
		if str(b.get("hito", "")) == "apeadero":
			if b.has("anden"):   # el andén, entre la caseta y la vía: ahí se baja y desde ahí se sube
				return [int(b.anden[0]), int(b.anden[1])]
			return [int(b.x0) + 1, int(b.y0) + int(b.h)]
	return []

# A en la vía desde el andén del apeadero: el tren se coge ahí (la vía no se pisa)
func en_anden(x: int, y: int) -> bool:
	var m: Dictionary = MAPS.get(S.map, {})
	if m.is_empty() or y < 0 or y >= int(m.h) or x < 0 or x >= int(m.w) or not String(m.g[y][x]).begins_with("viaE"):
		return false
	var px := int(P.x)
	var py := int(P.y)
	return py >= 0 and py < int(m.h) and px >= 0 and px < int(m.w) and String(m.g[py][px]).begins_with("anden")

# de dónde sale el tren: la estación de Bilbao (cualquiera de las de dentro) o el pueblo del apeadero
func tren_origen() -> String:
	return "zorroza" if S.map in ESTACIONES else String(S.map)

func tren_viaje(k: String, de := "zorroza") -> Dictionary:
	var v := viaje(de, k)
	return {"min": maxi(10, int(float(v.min) * TREN.min)), "eur": snappedf(maxf(1.0, float(v.eur) * TREN.eur), 0.05)}

func tren() -> void:
	var de := tren_origen()
	var ds := []
	for k in D.PARADAS:
		if k != de and S.ch >= int(D.PARADAS[k].cap) and (k == "zorroza" or apeadero_de(k).size() > 0):
			ds.append(k)
	var it := []
	for k in ds:
		var v := tren_viaje(k, de)
		it.append({"label": D.PARADAS[k].n, "right": T("{e} · {m} min", {"e": Datos.eur(v.eur), "m": int(v.min)})})
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿A dónde vas en tren?")})
	if i < 0 or i >= ds.size():
		return
	var k: String = ds[i]
	var v := tren_viaje(k, de)
	if float(S.money) < float(v.eur):
		sfx("bad")
		await say(T("El billete hasta {d} cuesta {e}. No te llega.", {"d": D.PARADAS[k].n, "e": Datos.eur(v.eur)}))
		return
	S.money = snappedf(float(S.money) - float(v.eur), 0.01)
	sfx("door")
	await fade(1)
	advance_time(int(v.min))
	var a: Array = apeadero_de(k)
	if k == "zorroza":
		enter_map(k, int(TREN_BILBAO[0]), int(TREN_BILBAO[1]), "down")
	else:
		enter_map(k, int(a[0]), int(a[1]), "down")
	if S.clientsDay != S.day:
		spawn_clients()
	update_hud()
	await wait(80)
	await fade(0)
	await say(T("Bajas del tren en la estación de Zorroza.") if k == "zorroza" else T("Bajas del tren en el apeadero de {d}.", {"d": D.PARADAS[k].n}))

# el apeadero de un pueblo: la ventanilla, con el horario de las estaciones
func apeadero() -> void:
	var h: Array = HORARIO.estacion
	if int(S.min) < int(h[0]) or int(S.min) >= int(h[1]):
		await say(K("El apeadero, cerrado. En el cartel: el primer tren sale a las seis de la mañana y el último a las once de la noche."))
		return
	if await ask(K("El apeadero del tren de la comarca: la caseta, la marquesina y el andén junto a la vía. Pasa uno cada media hora."), [K("Coger el tren"), K("Nada")]) == 0:
		await tren()

# ---------- la Diputación: la ventanilla de Hacienda ----------
func hacienda() -> void:
	var N := K("FUNCIONARIA")
	var C := ciu()
	if int(S.day) - int(C.get("hac", -99)) < int(HACIENDA.dias):
		await say(K("«Una declaración por semana. Vuelva usted la que viene.»"), N)
		return
	var mx := mini(int(HACIENDA.tope), int(float(S.money)) / 100 * 100)
	if mx < 100:
		await say(K("«Para regularizar, traiga el efectivo. Desde cien euros.»"), N)
		return
	var v := []   # de quinientos en quinientos, y todo lo que se pueda
	for x in [100, 500, 1000, 2000]:
		if x < mx:
			v.append(x)
	v.append(mx)
	var ops := v.map(func(x): return Datos.eur(x))
	ops.append(K("Nada"))
	var c: int = await ask(T("«Declaración de efectivo: hasta {e} a la semana. Hacienda se queda el {p} % y el resto va a su cuenta, limpio.»", {"e": Datos.eur(HACIENDA.tope), "p": int(HACIENDA.cuota * 100)}), ops, N)
	if c < 0 or c >= v.size():
		return
	var e: int = v[c]
	var neto := snappedf(e * (1.0 - float(HACIENDA.cuota)), 0.01)
	S.money = snappedf(float(S.money) - e, 0.01)
	abono_banco(neto, K("Hacienda foral: regularización"))
	C.hac = int(S.day)
	advance_time(30)
	sfx("coin")
	update_hud()
	await say(T("Media hora de impresos y sellos. En la cuenta entran {n}, con su papel.", {"n": Datos.eur(neto)}), N)

# ---------- el molino de mareas ----------
func marea_sube() -> bool:   # dos mareas al día: 12 h 25 min cada vuelta
	return (int(S.day) * 1440 + int(S.min)) % 745 < 372

func talk_molinero() -> void:
	var N := K("MOLINERO")
	var C := ciu()
	if not C.get("molinero"):
		C.molinero = true
		await say(K("«Este molino lo movía la ría: entra la marea, se cierra la compuerta y, al bajar, el agua mueve la muela. Tu tía traía aquí el maíz del caserío, cuando todavía molíamos.»"), N)
		return
	await say(pick([K("«Si estás cansado, en los sacos se duerme bien. Yo lo hacía de chaval.»"), K("«Mira la rueda: con la marea baja, gira sola.»")]), N)

func cabezada() -> void:
	var C := ciu()
	if int(C.get("siesta", -1)) == int(S.day):
		await say(K("Sacos de grano viejo. Ya te has echado hoy."))
		return
	if await ask(K("Sacos de grano viejo, blandos como un colchón."), [K("Echar una cabezada"), K("Nada")]) != 0:
		return
	C.siesta = int(S.day)
	await fade(1)
	advance_time(int(CABEZADA.min))
	await fade(0)
	S.hp = mini(int(S.hpMax), int(S.hp) + int(CABEZADA.hp))
	beber_alc(-6)
	update_hud()
	await say(K("Hora y media con el ruido del agua por debajo. Te levantas con harina en la ropa y la cabeza despejada."))

# ---------- el almacén del muelle: el jornal ----------
func jornal() -> void:
	var N := K("CAPATAZ")
	var C := ciu()
	if int(C.get("jornal", -1)) == int(S.day):
		await say(K("«Por hoy ya has cobrado. Mañana, a las siete.»"), N)
		return
	if int(S.min) >= int(JORNAL.hasta):
		await say(K("«El camión ya ha salido. Mañana, a las siete, y no preguntes qué llevan las cajas.»"), N)
		return
	if await ask(T("«¿Vienes a descargar? Tres horas, {e} en mano.»", {"e": Datos.eur(JORNAL.eur)}), [K("Descargar"), K("No")], N) != 0:
		return
	C.jornal = int(S.day)
	await fade(1)
	advance_time(int(JORNAL.min))
	await fade(0)
	S.money = snappedf(float(S.money) + float(JORNAL.eur), 0.01)
	S.hp = maxi(1, int(S.hp) - int(JORNAL.hp))
	sfx("coin")
	update_hud()
	await say(T("Tres horas de cajas y sacos. El capataz te da {e} y no pregunta nada.", {"e": Datos.eur(JORNAL.eur)}), N)
