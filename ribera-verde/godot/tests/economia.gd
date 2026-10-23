# Landrace Hunters (Godot) — U3 de la fase 5 del plan de Google Play: tres jugadores (prudente, medio y torpe) juegan la deuda
# con el motor de verdad (Cultivo: nueva_planta, avanza —crecimiento, agua, plagas y la factura de la luz— y cosecha; los precios
# de la calle y del por mayor de mundo.gd; las carpas, focos y macetas con sus precios de SHOP) y se mira, plazo a plazo, el dinero
# frente a lo que pide Baltasar. Lo que no se simula se resume: los clientes del día (4 + rep/15, de 2 a 12 g), cuánto se vende
# de eso (por perfil) y lo que duran los capítulos sin plazo (el 4 y el 6, dos cosechas). Con Datos.PLAY: rescate al primer
# impago (RESCATE) y embargo como mucho una vez por capítulo, como en penalty_event.
#   godot --headless --path godot --script res://tests/economia.gd [-- --salida <archivo.md>]   → «economia: …», sale con 1 si el
#   medio no paga todos los plazos a tiempo o el torpe no acaba la deuda
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")

var D: Dictionary
var J

const PERFILES := {
	# cuida: días que riega y abona de cada 10 · vende: parte de lo que piden los clientes de la calle · mayor: parte del tope de
	# Iñaki (desde el cap. 3) · mejora: compra equipo · reserva: lo que guarda para el plazo antes de comprar
	"prudente": {"cuida": 10, "vende": .8, "mayor": .5, "mejora": 2, "reserva": 1.0},
	"medio": {"cuida": 8, "vende": .55, "mayor": .3, "mejora": 1, "reserva": 1.0},
	# el torpe, tras el rescate de Toño, se pone las pilas (aprende): juega como el medio
	"torpe": {"cuida": 6, "vende": .5, "mayor": .15, "mejora": 0, "reserva": 0.0, "aprende": "medio"},
}
const SEMILLA := 5   # Skunk #1 en Kiko

func _initialize() -> void:
	Datos.PLAY = true
	D = Datos.carga()
	J = load("res://src/juego.gd").new()
	J.D = D
	var sal := ""
	var a := OS.get_cmdline_user_args()
	if a.size() > 1 and a[0] == "--salida":
		sal = a[1]
	var L := ["# Simulación de la deuda (fase 5, U3)", "", "Generado con `tests/economia.gd` (motor real de cultivo y precios). Plazos: %s · interés %d %% · rescate %s · días por plazo %s." % [D.PLAZOS, int(D.INTERES * 100), D.get("RESCATE", "—"), D.get("PLAZO_DIAS", "—")], "", "Criterio: el medio paga los tres plazos a tiempo y sin recargos; el torpe, que tras el rescate de Toño juega como el medio, acaba la deuda con un embargo por capítulo como mucho. Los recargos de un plazo no pasan del tope (RESCATE.tope de lo que pedía).", ""]
	var ok := true
	for k in PERFILES:
		Cultivo.pm = int(OS.get_environment("ECO_AZAR")) if OS.get_environment("ECO_AZAR") != "" else 4242
		var r: Dictionary = juega(k, PERFILES[k])
		L.append("## %s" % k)
		L.append("")
		L.append("| Plazo | Pide | Vence (día) | Pagado (día) | Recargos | Embargos |")
		L.append("|---|---|---|---|---|---|")
		for p in r.plazos:
			L.append("| cap. %d | %s | %d | %s | %d | %d |" % [p.ch, Datos.eur(p.pide), p.vence, ("%d" % p.pagado) if p.pagado >= 0 else "—", p.recargos, p.embargos])
		L.append("")
		L.append("Deuda saldada: %s · día %d · dinero al final %s · gramos vendidos %d · embargos por capítulo como mucho %d." % ["sí" if r.fin else "no", r.dia, Datos.eur(r.money), r.g, r.emb_cap])
		L.append("")
		if k == "medio":
			ok = ok and r.fin and r.plazos.all(func(p): return p.recargos == 0 and p.pagado <= p.vence)
		if k == "torpe":
			ok = ok and r.fin and r.emb_cap <= 1
	var txt := "\n".join(L) + "\n"
	print(txt)
	if sal != "":
		var f := FileAccess.open(sal, FileAccess.WRITE)
		f.store_string(txt)
		f.close()
	print("economia: %s" % ("en verde" if ok else "EN ROJO"))
	J.free()
	quit(0 if ok else 1)

func precio(it: Dictionary) -> int:
	return int(it.p)

func compra(S: Dictionary, clave: String, valor: String) -> bool:
	for it in D.SHOP:
		if it.get(clave) == valor and int(it.get("ch", 1)) <= int(S.ch) and S.money >= precio(it):
			S.money -= precio(it)
			return true
	return false

func juega(nombre: String, P0: Dictionary) -> Dictionary:
	var S: Dictionary = Datos.enteros(D.NEW_STATE.duplicate(true))
	S.ch = 1
	S.min = 7 * 60
	S.day = 1
	J.S = S
	var plazos := []
	var actual = null
	var fin := false
	var g_tot := 0
	var cap_dias := 0   # días en el capítulo sin plazo (4 y 6)
	var cosechas_cap := 0
	var emb_cap := {}
	var rescatado := false
	var vendido := 0.0
	for dia in 120:
		var P: Dictionary = PERFILES[P0.aprende] if rescatado and P0.has("aprende") else P0
		# plantar lo que esté vacío (semillas a 5 €)
		for i in S.pots.size():
			if S.pots[i] == null and S.money >= SEMILLA:
				S.money -= SEMILLA
				S.pots[i] = Cultivo.nueva_planta(S, "ria")
		# cuidar: regar y, en flor, abonar (los días que toca)
		var cuida: bool = (dia % 10) < int(P.cuida)
		for p in S.pots:
			if p is Dictionary and not p.get("dead"):
				if cuida:
					p.water = 100.0
					if p.pest:
						p.pest = false
					if p.prog >= .35:
						p.fert = true   # MEATZA, mineral
				elif p.water < 25:
					p.water = 60.0
		# un día del motor (crecimiento, agua, plagas y la luz)
		Cultivo.avanza(S, 1440)
		# cosechar lo listo y quitar lo muerto
		for i in S.pots.size():
			var p = S.pots[i]
			if p is Dictionary and p.get("dead"):
				S.pots[i] = null
			elif p is Dictionary and p.prog >= 1:
				var rc: Dictionary = Cultivo.cosecha(S, i)
				if OS.get_environment("ECO_DBG") == nombre + "+":
					print("  c d%d i%d %dg salud %.0f %s %s" % [dia, i, rc.g, p.health, Cultivo.huecos(S)[i], S.carpas.map(func(c): return c.foco if c else "-")])
				cosechas_cap += 1
				if S.ch == 1:
					S.ch = 2
		# vender: calle (clientes del día) y, desde el cap. 3, al por mayor
		var stock := 0.0
		var thc := 0.0
		for k in S.buds:
			stock += S.buds[k].g
			thc = S.buds[k].thc
		var pide: float = (4 + floor(S.get("rep", 0) / 15.0)) * 7.0 * P.vende
		var calle: float = minf(stock, pide)
		var mayor: float = minf(stock - calle, 1000.0 * P.mayor) if S.ch >= 3 else 0.0
		var ing: float = calle * J.precio_calle(thc) + mayor * J.precio_mayor(thc)
		if calle + mayor > 0:
			var q: float = calle + mayor
			for k in S.buds.keys():
				var t: float = minf(q, S.buds[k].g)
				S.buds[k].g -= t
				q -= t
				if S.buds[k].g <= 0:
					S.buds.erase(k)
			S.money += ing
			S.sales += ing
			g_tot += int(calle + mayor)
			S.rep = mini(100, int(S.get("rep", 0)) + 1)
		if S.ch == 2 and S.sales >= D.META_VENTAS:
			S.ch = 3
			actual = {"ch": 3, "pide": int(D.PLAZOS["3"]), "vence": dia + dias_plazo(3), "pagado": -1, "recargos": 0, "embargos": 0}
			plazos.append(actual)
			S.due = actual.pide
		# mejorar el equipo: lo que sobra, salvo en los 3 últimos días de un plazo (entonces se guarda para pagarlo)
		var guarda: float = S.due * P.reserva if actual and actual.pagado < 0 and actual.vence - dia <= 3 else 0.0
		var mej: Array = []
		if P.mejora >= 1:
			mej = [["foco", "led200", 0], ["extra", "vent", 0], ["carpa", "m100", 1], ["foco", "sodio400" if P.mejora == 1 else "led480", 1], ["extra", "vent", 1], ["extra", "filtro", 1],
				["carpa", "g150", 2], ["foco", "sodio600" if P.mejora == 1 else "led720", 2], ["extra", "vent", 2], ["extra", "filtro", 2]]
		elif S.ch >= 3:
			mej = [["carpa", "m100", 1], ["foco", "sodio400", 1]]
		for m in mej:
			var ci: int = m[2]
			var hay: bool = ci < S.carpas.size() and S.carpas[ci] != null
			var ya: bool = hay if m[0] == "carpa" else (hay and (S.carpas[ci].foco != "cfl" if m[0] == "foco" else S.carpas[ci].get(m[1], false)))
			if m[0] != "carpa" and not hay:
				continue
			if ya:
				continue
			var pr := 0
			for it in D.SHOP:
				if it.get(m[0]) == m[1] and int(it.get("ch", 1)) <= int(S.ch):
					pr = precio(it)
			if pr == 0 or S.money - guarda < pr + 50:
				break
			S.money -= pr
			if m[0] == "carpa":
				J.comprar_carpa(m[1], ci)
				for i in S.macetas.size():   # macetas de 18 L en la nueva (2 € cada una)
					if Cultivo.huecos(S)[i].c == ci and S.ch >= 2:
						S.macetas[i] = "plastico18"
						S.money -= 2
			elif m[0] == "foco":
				S.carpas[ci].foco = m[1]
			else:
				S.carpas[ci][m[1]] = true
			break
		# el plazo: se paga en cuanto llega; si vence, recargo (y rescate o embargo)
		if actual and actual.pagado < 0:
			if S.money >= S.due:
				S.money -= S.due
				S.debt -= S.due
				actual.pagado = dia
				S.due = 0
				S.ch += 1
				cap_dias = 0
				cosechas_cap = 0
				actual = null
				if S.debt <= 0:
					fin = true
					return {"plazos": plazos, "fin": true, "dia": dia, "money": S.money, "g": g_tot, "emb_cap": _max(emb_cap)}
			elif dia > actual.vence:
				# como penalty_event (trama.gd): con Datos.PLAY, el recargo sobre lo que pedía el plazo y el rescate al primer impago
				var play: bool = Datos.PLAY and D.has("RESCATE")
				var base: float = float(actual.pide) if play else float(S.due)
				var resc: bool = play and not rescatado
				var it := Datos.jsround(base * D.INTERES * (float(D.RESCATE.interes) if resc else 1.0) / 100) * 100
				if play:
					it = maxi(0, mini(it, int(base * (1 + float(D.RESCATE.get("tope", 9.0)))) - int(S.due)))
				S.due += it
				S.debt += it
				actual.recargos += 1
				actual.vence = dia + (int(D.RESCATE.dias) if resc else 5)
				if resc:
					rescatado = true
				else:
					S.vencidos = int(S.get("vencidos", 0)) + 1
					var limite: bool = play and int(emb_cap.get(S.ch, 0)) >= 1
					if not resc and S.vencidos >= 3 and not limite:
						S.vencidos = 0
						actual.embargos += 1
						emb_cap[S.ch] = int(emb_cap.get(S.ch, 0)) + 1
						if S.carpas.size() > 1 and S.carpas[1]:   # la carpa grande, con sus plantas
							S.carpas[1] = null
							S.carpas.resize(1)
							S.pots.resize(Cultivo.huecos(S).size())
						else:
							S.money = floor(S.money / 2.0)
		if OS.get_environment("ECO_DBG") == nombre:
			print("  d%d ch%d %.0f€ due %d stock %.0f vend %.0f ing %.0f pots %s" % [dia, S.ch, S.money, S.due, stock, calle + mayor, ing, S.pots.map(func(p): return ("%.2f" % p.prog) if p is Dictionary else "-")])
		# los capítulos sin plazo (4: dos de receta; 6: la Copa): dos cosechas
		if S.ch == 4 or S.ch == 6:
			cap_dias += 1
			if cosechas_cap >= 2 * S.pots.size() and cap_dias >= 3:
				S.ch += 1
				var pp: int = mini(int(D.PLAZOS[str(S.ch)]), int(S.debt)) if S.ch == 5 else int(S.debt)
				actual = {"ch": S.ch, "pide": pp, "vence": dia + dias_plazo(S.ch), "pagado": -1, "recargos": 0, "embargos": 0}
				plazos.append(actual)
				S.due = pp
				cosechas_cap = 0
	return {"plazos": plazos, "fin": fin, "dia": 120, "money": S.money, "g": g_tot, "emb_cap": _max(emb_cap)}

# los días de cada plazo (con Datos.PLAY, PLAZO_DIAS; si no, los de siempre: 7, 10 y 7)
func dias_plazo(ch: int) -> int:
	if Datos.PLAY and D.has("PLAZO_DIAS"):
		return int(D.PLAZO_DIAS[str(ch)])
	return 10 if ch == 5 else 7

func _max(d: Dictionary) -> int:
	var m := 0
	for k in d:
		m = maxi(m, int(d[k]))
	return m
