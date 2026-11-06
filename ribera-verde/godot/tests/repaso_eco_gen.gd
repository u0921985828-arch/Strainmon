# Landrace Hunters (Godot) — lo que quedaba del repaso 0.76 en «4 · Economía» y «5 · Genética y estadísticas»
# (docs/REPASO-ESTRUCTURA.md), todo con Datos.CAL:
#   1 · la deuda: lo que pesan los plazos del capítulo 5 y del 7 frente a lo que da el canal de ese capítulo (la medida
#       que justifica el hallazgo) y el arreglo, PLAZO_PCT con plazo_due: el plazo pide lo pactado o esa parte de lo
#       facturado desde el plazo anterior (S.plazoS), lo que sea más;
#   2 · la calidad: la cadena entera (curado, manicura, afinado, semanas en tarro, aroma, rareza, revista) y su techo;
#   3 · los clubs y el por mayor: el tope por club y día sube con la confianza (MERCADO.club.topec) y el calor va por
#       gramos (CLUB.calorg), así que cada canal tiene su sitio: el club paga mejor el gramo, el por mayor mueve más
#       volumen (los cinco clubs a tope no llegan a una carga de Iñaki) y calienta menos por gramo;
#   4 · los IV de una línea nueva nacen en el punto neutro (IVS.basec), no por debajo;
#   5 · la potencia contratada (ENERGIA.*.limc): a tope hay que pasarse, o el generador y las placas no valen de nada;
#   6 · las variedades dominadas en las cuatro cifras (79 de las 88 sin contar las autoflorecientes): ninguna se
#       queda sin motivo para cultivarla;
#   7 · las rarezas de una línea feminizada, sin esperar a una hermafrodita (Cultivo.ra_sin_semilla);
#   8 · la doble cosecha en las mesas de la nave y de KAIA, que valía un 5,6 % en vez de un 20 % (prog_rebrote).
#   $GODOT --headless --path godot --script res://tests/repaso_eco_gen.gd   → «repaso_eco_gen: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var D: Dictionary
var n := 0
var fallos := []
var notas := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	Datos.CAL = true
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func nota(t: String) -> void:
	notas.append("  · " + t)

func _2(x: float) -> String:
	return Datos.to_fixed(x, 2).replace(".", ",")

# ---------- 6 · dominancia en las cuatro cifras (THC, rinde, días de flor, resistencia) ----------
func domina(a: Dictionary, b: Dictionary) -> bool:
	var ge: bool = float(a.thc) >= float(b.thc) and float(a.y) >= float(b.y) and float(a.d) <= float(b.d) and float(a.r) >= float(b.r)
	var st: bool = float(a.thc) > float(b.thc) or float(a.y) > float(b.y) or float(a.d) < float(b.d) or float(a.r) > float(b.r)
	return ge and st

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-repaso-eg.json"
	Juego.AJUSTES = "user://prueba-repaso-eg-ajustes.json"
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	J.oraculo = true
	root.add_child(J)
	J.S = e.S.duplicate(true)
	D = J.D
	var S: Dictionary = J.S

	# ---------- 1 · la deuda: la medida del hallazgo ----------
	# Lo que pide cada plazo frente a lo que da, en los días de ese plazo, el canal que se abre en su capítulo: el por
	# mayor de Iñaki (capítulo 3) y, desde el capítulo 5, la nave. Si el plazo se paga con una parte pequeña de eso, la
	# deuda ha dejado de pesar
	var px20: float = J.precio_mayor(20.0)
	var dia_mayor: float = float(D.IMPERIO[0].mayor) * px20
	var p5: float = float(D.PLAZOS["5"])
	var p7: float = float(D.PLAZOS["7"])
	var d5: int = 10   # dias_plazo(5) sin PLAY
	var d7: int = 7
	nota("al por mayor, %s g/día al %s €/g = %s/día" % [int(D.IMPERIO[0].mayor), _2(px20), Datos.eur(dia_mayor)])
	nota("plazo cap. 5: %s en %d días = %s días de carga · plazo cap. 7: %s en %d días = %s días · lo que queda de deuda en el capítulo 5, %s = %s días de los %d de plazo"
		% [Datos.eur(p5), d5, _2(p5 / dia_mayor), Datos.eur(p7), d7, _2(p7 / dia_mayor), Datos.eur(p5 + p7), _2((p5 + p7) / dia_mayor), d5 + d7])
	chk((p5 + p7) / dia_mayor < (d5 + d7) / 2.0, "la deuda que queda en el capítulo 5 se paga con menos de la mitad del plazo vendiendo solo a Iñaki")
	# la nave, que entra justo en el capítulo 5: una mesa por ciclo
	var FN: Dictionary = D.FOCO_NAVE.led
	var mesa_g: float = float(FN.w) * float(FN.gpw) * float(FN.get("rend", 1))
	var nave_ciclo: float = mesa_g * float(D.NAVE.max) * px20
	nota("la nave (cap. %d), %d mesas de LED: %s por ciclo, con la deuda del capítulo 5 en %s y el plazo en %s"
		% [int(D.NAVE.ch), int(D.NAVE.max), Datos.eur(nave_ciclo), Datos.eur(p5 + p7), Datos.eur(p5)])
	chk(int(D.NAVE.ch) == 5 and nave_ciclo > p5, "un ciclo de la nave, que se alquila justo en el capítulo 5, paga el plazo de ese capítulo")
	# el arreglo: el plazo pide lo pactado o PLAZO_PCT de lo facturado desde el plazo anterior, lo que sea más
	var pct: float = float(D.PLAZO_PCT)
	var sales0 = S.get("sales", 0)
	S.sales = 0
	S.plazoS = 0
	chk(J.plazo_due(5) == int(p5), "quien no ha facturado nada paga lo pactado: %s" % Datos.eur(J.plazo_due(5)))
	S.sales = 9430   # lo más que factura entre plazos el mejor de los tres perfiles de tests/economia.gd
	chk(J.plazo_due(5) == int(p5), "al jugador justo tampoco le sube (%s facturados → %s)" % [Datos.eur(9430), Datos.eur(J.plazo_due(5))])
	S.sales = 40000   # el que tira de la nave o del barco a diario
	chk(J.plazo_due(5) == int(40000 * pct), "al fuerte le pide esa parte de lo facturado: %s" % Datos.eur(J.plazo_due(5)))
	S.plazoS = 36000   # pagado un plazo, solo cuenta lo facturado desde su marca
	chk(J.plazo_due(5) == int(p5), "desde la marca del plazo anterior: %s" % Datos.eur(J.plazo_due(5)))
	S.erase("plazoS")
	chk(J.plazo_due(5) == int(p5), "sin marca (partida migrada o tutorial saltado), lo pactado y nada más")
	S.plazoS = 0
	Datos.CAL = false
	chk(J.plazo_due(5) == int(p5), "sin CAL, lo pactado: el oráculo del HTML no cambia")
	Datos.CAL = true
	# los otros dos caminos a S.due del capítulo 5 (migración de juego.gd) pasan por plazo_due y la deuda los acota
	S.sales = 40000
	S.plazoS = 0
	S.ch = 5
	S.debt = int(D.DEUDA)
	S.due = 0
	S.erase("eco")
	J.migrate()
	chk(S.due == int(40000 * pct), "la partida vieja del capítulo 5 sin eco: %s" % Datos.eur(S.due))
	S.due = 0
	S.eco = 1
	S.debt = 3000   # menos que el plazo: la deuda lo acota
	J.migrate()
	chk(S.due == 3000, "y la guardada por chapter() sin plazo, acotada por la deuda: %s" % Datos.eur(S.due))
	nota("plazo del capítulo 5: %s pactados · %s facturando %s entre plazos" % [Datos.eur(p5), Datos.eur(int(40000 * pct)), Datos.eur(40000)])
	J.S = e.S.duplicate(true)
	S = J.S
	S.sales = sales0

	# ---------- 2 · la calidad: la cadena entera y su techo ----------
	var CU: Dictionary = D.CURADO
	var MC: Dictionary = D.MANICURA
	var CM: Dictionary = D.CAMAROTE
	var V: Dictionary = D.VERDE
	S.day = 400
	S.erase("rev")   # primero la cadena sin las técnicas de EL ESQUEJE
	var seco := {"g": 100.0, "thc": 20.0, "dia": S.day - int(V.dias)}
	chk(is_equal_approx(J.calidad(seco, true), 1.0), "un lote seco, sin nada: ×1 (%s)" % _2(J.calidad(seco, true)))
	var verde := {"g": 100.0, "thc": 20.0, "dia": S.day}
	chk(is_equal_approx(J.calidad(verde, true), float(V.min)), "recién cortado, ×%s" % _2(float(V.min)))
	var ofi := {"g": 100.0, "thc": 20.0, "dia": S.day - 2, "cu": 1}
	chk(is_equal_approx(J.calidad(ofi, false), 1 + float(CU.precio)), "curado, al extracto: +15 %% (×%s)" % _2(J.calidad(ofi, false)))
	# el máximo: curado, manicurado, afinado en el camarote, ocho semanas en tarro, aroma único y las técnicas
	S.rev = {"tec": ["lavado", "secado", "curado"], "n": []}   # las tres técnicas de calidad de EL ESQUEJE
	var rb: float = Cultivo.rev_bono(S, "cal")
	chk(rb > 0 and is_equal_approx(rb, minf(.1, float(D.REVISTA.tope.cal))), "las técnicas de calidad suman +%s" % _2(rb))
	var art := {"g": 100.0, "thc": 20.0, "dia": S.day - 7 * int(V.semanas), "cu": 1, "mc": 1, "af": 1}
	var tope_art: float = (1 + float(CU.precio) + float(MC.precio) + float(CM.extra)) * (1 + float(V.semana) * float(V.semanas)) * (1 + rb)
	chk(is_equal_approx(J.calidad(art, true), tope_art), "el techo de lo que se trabaja: ×%s (%s)" % [_2(tope_art), _2(J.calidad(art, true))])
	var ar := art.duplicate()
	ar.ar = 1.0
	var sh := ar.duplicate()
	sh.sh = 1
	nota("calidad: oficio ×%s · con ocho semanas en tarro ×%s · con las técnicas ×%s · con aroma único ×%s · y rara ×%s"
		% [_2(1 + float(CU.precio) + float(MC.precio) + float(CM.extra)), _2((1 + float(CU.precio) + float(MC.precio) + float(CM.extra)) * (1 + float(V.semana) * float(V.semanas))),
		_2(tope_art), _2(J.calidad(ar, true)), _2(J.calidad(sh, true))])
	chk(is_equal_approx(J.calidad(ar, true), tope_art * (1 + float(D.RAREZAS.r.aroma.x))) and is_equal_approx(J.calidad(sh, true), J.calidad(ar, true) * float(D.SHINY.x)),
		"el aroma único y la rara, encima (×%s, ×%s)" % [_2(J.calidad(ar, true)), _2(J.calidad(sh, true))])
	var comp := art.duplicate()
	comp.cp = 1.0
	chk(is_equal_approx(J.calidad(comp, true), 1.0), "lo comprado hecho no cobra prima: ×%s" % _2(J.calidad(comp, true)))
	S.erase("rev")

	# ---------- 3 · los clubs y el por mayor, cada uno en su sitio ----------
	var TC: Dictionary = D.MERCADO.club
	var TP: Dictionary = TC.topec
	chk(TP.has("min") and TP.has("max") and TP.has("rel") and float(TP.rel) == float(D.REL.socio), "MERCADO.club.topec, hasta la confianza de socio")
	S.rel = {}
	chk(is_equal_approx(J.club_tope("rv"), float(TP.min)), "sin conocerte, %d g al día (%s)" % [int(TP.min), _2(J.club_tope("rv"))])
	S.rel = {"rv": float(D.REL.socio)}
	chk(is_equal_approx(J.club_tope("rv"), float(TP.max)), "de socio, %d g (%s)" % [int(TP.max), _2(J.club_tope("rv"))])
	S.rel = {"rv": float(D.CLUB.confia)}
	var t15: float = float(TP.min) + (float(TP.max) - float(TP.min)) * float(D.CLUB.confia) / float(TP.rel)
	chk(is_equal_approx(J.club_tope("rv"), t15), "con la confianza que piden para comprarte, %s g" % _2(t15))
	Datos.CAL = false
	chk(is_equal_approx(J.club_tope("rv"), float(TC.tope)), "sin CAL, los %d g de siempre" % int(TC.tope))
	Datos.CAL = true
	# los clubs que te compran: todos menos KAIA, que es tuyo y se llena por el dispensario (disp_llena), no vendiéndole
	var nclubs: int = 0
	for k in D.CLUBS:
		if not D.CLUBS[k].get("tuyo", false):
			nclubs += 1
	var pc: float = J.precio_club(20.0)
	var clubs_max: float = nclubs * float(TP.max)
	nota("los %d clubs que te compran: de %d a %d g/día cada uno (%s a %s al día entre todos, al %s €/g) · Iñaki %d g por carga (%s al %s €/g) y %d g con el imperio"
		% [nclubs, int(TP.min), int(TP.max), Datos.eur(nclubs * float(TP.min) * pc), Datos.eur(clubs_max * pc), _2(pc),
		int(D.IMPERIO[0].mayor), Datos.eur(dia_mayor), _2(px20), int(D.IMPERIO[-1].mayor)])
	chk(pc > px20, "el club sigue pagando el gramo mejor que el por mayor (%s > %s)" % [_2(pc), _2(px20)])
	chk(float(D.IMPERIO[0].mayor) * px20 > float(TP.max) * pc, "una carga de Iñaki mueve más dinero que la mejor entrega a un club (%s > %s)"
		% [Datos.eur(dia_mayor), Datos.eur(float(TP.max) * pc)])
	chk(float(D.CLUB.confia) > 0 and float(TP.min) * pc < dia_mayor / 4.0,
		"al principio solo te compra el club de tu barrio (los demás piden confianza %d) y eso es menos de un cuarto de una carga de Iñaki" % int(D.CLUB.confia))
	chk(clubs_max < float(D.IMPERIO[0].mayor), "ni los %d clubs a tope (%d g) llegan a una carga de Iñaki (%d g): el por mayor es el canal del volumen"
		% [nclubs, int(clubs_max), int(D.IMPERIO[0].mayor)])
	chk(clubs_max * pc < dia_mayor, "y tampoco en dinero (%s < %s)" % [Datos.eur(clubs_max * pc), Datos.eur(dia_mayor)])
	# el calor: una entrega grande ya no sale al mismo precio que una pequeña
	var cg: float = float(D.CLUB.calorg)
	var c50: float = float(D.CLUB.calor) + 50.0 / cg
	var c300: float = float(D.CLUB.calor) + float(TP.max) / cg
	nota("calor del club: %s por 50 g y %s por %d g · Iñaki, %s por %d g" % [_2(c50), _2(c300), int(TP.max), _2(2 + float(D.IMPERIO[0].mayor) / 100.0), int(D.IMPERIO[0].mayor)])
	chk(c300 > c50 and c300 / float(TP.max) > (2 + float(D.IMPERIO[0].mayor) / 100.0) / float(D.IMPERIO[0].mayor),
		"el calor del club va por gramos y, como paga mejor el gramo, calienta más por gramo que el por mayor")

	# ---------- 4 · los IV de una línea nueva, en el punto neutro ----------
	var IV: Dictionary = D.IVS
	chk(IV.has("basec") and float(IV.basec[1]) - float(IV.basec[0]) == float(IV.base[1]) - float(IV.base[0]), "IVS.basec, con el mismo abanico que IVS.base")
	for par in [["base", IV.base], ["basec", IV.basec]]:
		var B: Array = par[1]
		var t := 0.0
		var c := 0
		for sid in D.DEX:
			for i in 4:
				t += int(B[0]) + Datos.hash_str("iv%d|%s" % [i, sid]) % (int(B[1]) - int(B[0]) + 1)
				c += 1
		var med: float = t / c
		nota("IVS.%s %s: media de los %d IV de las %d líneas = %s (iv_f %s)" % [par[0], B, c, D.DEX.size(), _2(med), _2((med - 16.0) / 15.0)])
		if par[0] == "base":
			chk((med - 16.0) / 15.0 < -0.2, "IVS.base nacía por debajo del punto neutro (iv_f %s)" % _2((med - 16.0) / 15.0))
		else:
			chk(absf((med - 16.0) / 15.0) < 0.03, "IVS.basec nace en el punto neutro (iv_f %s)" % _2((med - 16.0) / 15.0))
	S.erase("iv")
	var L: Array = Cultivo.iv_linea(S, "haze")
	var ok := L.size() == 4
	for v in L:
		ok = ok and int(v) >= int(IV.basec[0]) and int(v) <= int(IV.basec[1])
	chk(ok, "la línea sale de IVS.basec: %s" % [L])

	# ---------- 5 · la potencia contratada ----------
	var E: Dictionary = D.ENERGIA
	for sitio in ["casa", "nave"]:
		chk(E[sitio].has("limc") and int(E[sitio].limc) < int(E[sitio].lim), "%s con limc por debajo de lo de antes (%s)" % [sitio, E[sitio].get("limc")])
		chk(J.ener_lim(sitio) == int(E[sitio].limc), "con CAL, la potencia es limc (%d)" % J.ener_lim(sitio))
	Datos.CAL = false
	chk(J.ener_lim("casa") == int(E.casa.lim), "sin CAL, la de antes")
	Datos.CAL = true
	# el piso a tope: tres carpas con el foco más gordo, extractor, intractor y ventilador, y todos los aparatos
	var fmax := ""
	for k in D.FOCOS:
		if fmax == "" or float(D.FOCOS[k].w) > float(D.FOCOS[fmax].w):
			fmax = k
	var w_carpa: float = float(D.FOCOS[fmax].w) + float(D.EXTRAS.vent.w) + float(D.EXTRAS.filtro150.w) + float(D.EXTRAS.intra.w)
	var w_apar := 0.0
	for a in D.APARATOS:
		w_apar += float(D.APARATOS[a].w)
	var w_casa: float = 3 * w_carpa + w_apar
	var w_nave: float = float(D.NAVE.max) * float(D.FOCO_NAVE.led.w)
	nota("a tope: el piso %d W de %d contratados (antes %d) · la nave %d W de %d (antes %d)"
		% [int(w_casa), J.ener_lim("casa"), int(E.casa.lim), int(w_nave), J.ener_lim("nave"), int(E.nave.lim)])
	chk(w_casa > J.ener_lim("casa") and w_casa < int(E.casa.lim), "el piso a tope se pasa de lo contratado (antes, nunca)")
	chk(w_nave > J.ener_lim("nave") and w_nave < int(E.nave.lim), "la nave a tope también")
	chk(w_casa - J.ener_lim("casa") <= float(E.pl.w) and w_nave - J.ener_lim("nave") <= float(E.gen.w), "las placas cubren el exceso del piso y el generador el de la nave")

	# ---------- 6 · las variedades dominadas y su motivo ----------
	var padres := {}
	for r in D.RECIPES:
		for p in String(r).split("+"):
			padres[p] = 1
	var fam := {}
	for k in D.FAMILIAS:
		for s2 in D.FAMILIAS[k].s:
			fam[s2] = 1
	var col := {}
	for c in D.BANCO_TIA.col:
		for s2 in c.s:
			col[s2] = 1
	var autos := {}
	for a2 in D.AUTO.dex:
		if String(a2) != "ruderalis":   # la Ruderalis es la landrace de la que salen, no una autofloreciente: cuenta entre las del repaso
			autos[a2] = 1
	var vars_: Array = D.DEX.filter(func(s2): return not autos.has(s2))   # las 87 del repaso, sin las dieciséis autoflorecientes
	var dom := []
	var sin_motivo := []
	for b in vars_:
		var B: Dictionary = D.STRAINS[b]
		for a in vars_:
			if a != b and domina(D.STRAINS[a], B):
				dom.append(b)
				break
		if not fam.has(b) and not padres.has(b) and not col.has(b):
			sin_motivo.append(b)
	var dp := 0
	var dc := 0
	for b in dom:
		if padres.has(b):
			dp += 1
		if col.has(b):
			dc += 1
	nota("%d de las %d variedades están dominadas en las cuatro cifras; de ellas %d son madre o padre de una receta, %d van en una colección de la tía y %d en una familia de la CannaDex"
		% [dom.size(), vars_.size(), dp, dc, dom.size()])
	chk(dom.size() > vars_.size() * 0.8, "la dominancia es real: %d de %d" % [dom.size(), vars_.size()])
	chk(sin_motivo.is_empty(), "ninguna variedad se queda sin motivo para cultivarla: %s" % [sin_motivo])
	for k in D.FAMILIAS:
		chk(D.FAMILIAS[k].s.all(func(s2): return D.STRAINS.has(s2)), "la familia %s, con variedades que existen" % k)

	# ---------- 7 · las rarezas de una línea feminizada ----------
	chk(Cultivo.ra_sin_semilla("ria") and not Cultivo.ra_sin_semilla("haze"), "la feminizada guarda la rareza sin semilla; la regular, no")
	Datos.CAL = false
	chk(not Cultivo.ra_sin_semilla("ria"), "sin CAL, como antes")
	Datos.CAL = true
	var fija: int = int(D.RAREZAS.fija)
	var antes: float = fija / float(D.SEMILLA_HERMA)
	nota("fijar una rareza: %d cosechas en una línea regular y %s en una feminizada (antes, ×%s)" % [fija, fija, _2(antes / fija)])
	chk(absf(antes / fija - 1 / float(D.SEMILLA_HERMA)) < .01 and antes / fija > 8.0, "era %s veces más lenta" % _2(antes / fija))
	S.ra = {}
	var ch: Array = Cultivo.hereda_ra(S, "ria", {"ra": ["resina"], "ral": {"resina": 0}})
	chk(ch == [["resina", 1]] and int(S.ra.ria.resina) == 1, "la línea la aprende (%s)" % [S.ra])
	S.erase("ra")

	# ---------- 8 · la doble cosecha en las mesas ----------
	var DB: Dictionary = D.RAREZAS.r.doble
	var clon: float = float(D.NAVE.clon)
	var pr: float = J.prog_rebrote()
	chk(is_equal_approx(pr, clon + float(DB.vuelve) * (1 - clon)), "la mesa rebrotada arranca en %s (clon %s)" % [_2(pr), _2(clon)])
	var casa_x: float = (float(DB.g2) / float(DB.vuelve)) / 1.0                     # en casa: la planta nace en 0
	var mesa_antes: float = (float(DB.g2) / (1 - float(DB.vuelve))) / (1 / (1 - clon))
	var mesa_ahora: float = (float(DB.g2) / (1 - pr)) / (1 / (1 - clon))
	nota("doble cosecha por día de ciclo: en casa ×%s · en una mesa, antes ×%s · ahora ×%s" % [_2(casa_x), _2(mesa_antes), _2(mesa_ahora)])
	chk(mesa_antes < 1.07, "antes, en una mesa la doble cosecha no daba casi nada (×%s)" % _2(mesa_antes))
	chk(absf(mesa_ahora - casa_x) < .01, "ahora vale lo mismo que en casa (×%s)" % _2(mesa_ahora))
	var Me := {"k": "ria", "f": {"id": 1, "ra": ["doble"]}}
	chk(J.mesa_rebrote(Me) and int(Me.rb) == 1 and is_equal_approx(Cultivo.ra_g_mesa(Me.f, true), float(DB.g2)), "la mesa rebrota una vez y su segunda cosecha va al %d %%" % int(float(DB.g2) * 100))
	chk(not J.mesa_rebrote(Me) and not Me.has("rb"), "y a la siguiente vuelve a empezar")

	for x in notas:
		print(x)
	for x in fallos:
		print("  FALLO ", x)
	print("repaso_eco_gen: %d comprobaciones, %d fallos" % [n, fallos.size()])
	J.queue_free()
	quit(1 if fallos.size() else 0)
