# Descendencias (lo pidió el usuario: «más que más landraces me refería a meter más descendencias no más landraces»):
# el catálogo no crece con nombres de fuera, crece con lo que sale de tus propias plantas. Cuatro vías, todas reales y sin
# nombrar criadores ni bancos:
#  · CORTE DE MADRE: de una madre que te ha salido buena guardas el corte con nombre propio (DESC.corte.tope a la vez). El
#    fenotipo queda congelado tal cual y cada esqueje sale idéntico, porque ya es la misma planta.
#  · POLINIZAR ENTRE CLONES: dos esquejes pinchados en el carro, uno de madre y otro de padre: semillas F1 de las dos líneas
#    sin perder ninguna de las dos, porque las madres siguen vivas en el armario.
#  · AUTOFECUNDACIÓN (S1): en el laboratorio, una línea consigo misma. No gana generación en el árbol (es la misma línea), pero
#    fija lo que ya tenía: sube sus genes (DESC.s1.iv) y sube un nivel la fijación de sus rarezas.
#  · RETROCRUCE (BX): cruzar un híbrido tuyo con una de sus dos parentales. Lo que sale se parece a esa madre en un
#    DESC.bx.m %: variedad nueva, con nombre «<madre> BX1», «BX2»…
#  · LÍNEA FIJADA (IBL): DESC.ibl.sel selecciones seguidas de una línea ya fijada. Pasa al tipo genético «ibl» (GENETICA.ibl,
#    sigma mínima): deja de variar de planta a planta y sus genes no bajan de DESC.ibl.iv.
# Nada de método, dosis ni reactivos: el juego dice lo que se juega, nunca cómo se hace.
# Ninguna vía es gratis ni se repite sin fin: el cruce entre clones gasta los dos esquejes y solo cuaja uno cada
# DESC.clon.dias; el S1 gasta más semillas de las que da y tiene tope por línea (DESC.s1.tope); el BX y el IBL gastan
# semilla y ocupan el laboratorio sus días; la madre metida desde un corte entra a DESC.corte.v de vigor, no hecha.
# Estado: S.cortes = [{k: sid, f: fenotipo, n: nombre, dia}], S.ibl = {sid: selecciones}, S.s1 = {sid: autofecundaciones}.
extends RefCounted

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const I18n = preload("res://src/i18n.gd")

static func hay() -> bool:
	return Datos.CAL and Datos.carga().has("DESC")   # i18n-no

static func d() -> Dictionary:
	return Datos.carga().DESC

# ---------- el corte de madre ----------
static func cortes(S: Dictionary) -> Array:
	if not (S.get("cortes") is Array):
		S.cortes = []
	return S.cortes

static func corte_tope() -> int:
	return int(d().corte.tope)

# el vigor con el que entra al armario una madre metida desde un corte: hay que criarla, no sale hecha
static func corte_vigor() -> int:
	return int(d().corte.get("v", 100))

# el nombre del corte n de la variedad sid: «Haze 98 · corte 2»
static func corte_nombre(S: Dictionary, sid: String) -> String:
	var n := 1
	var k0 := sid.trim_suffix("*")
	for c in cortes(S):
		if String(c.get("k", "")).trim_suffix("*") == k0:
			n += 1
	var st = Datos.strain(S, sid)
	return I18n.T(String(d().corte.nom), {"s": String(st.n) if st != null else sid, "n": n})

# guarda el corte de una madre (su fenotipo tal cual); devuelve el índice, o -1 si no cabe
static func corte_pon(S: Dictionary, sid: String, f, nom := "") -> int:
	var l := cortes(S)
	if l.size() >= corte_tope():
		return -1
	l.append({"k": sid, "f": f, "n": nom if nom != "" else corte_nombre(S, sid), "dia": int(S.get("day", 1))})
	return l.size() - 1

# lo que fija el corte, para la ficha: % índica, THC y lo raro que tenga
static func corte_desc(S: Dictionary, c: Dictionary) -> String:
	var sid := String(c.get("k", "")).trim_suffix("*")
	var s = Datos.strain(S, sid)
	var f = c.get("f")
	var t: float = minf(Cultivo.THC_TOPE, float(s.thc) * (float(f.t) if f is Dictionary else 1.0))
	var o := I18n.T("Corte de {s} · THC {t} % · {i} % índica.", {"s": s.n, "t": Datos.pct(t), "i": int(f.i) if f is Dictionary and f.has("i") else int(Datos.ind_de(S, sid))})
	if f is Dictionary and f.get("ra") is Array and not f.ra.is_empty():
		var D := Datos.carga()
		var ns := []
		for k in f.ra:
			if D.has("RAREZAS") and D.RAREZAS.r.has(k):
				ns.append(String(D.RAREZAS.r[k].n))
		if ns.size():
			o += " " + I18n.T("Lleva: {l}.", {"l": ", ".join(PackedStringArray(ns))})
	return o + " " + I18n.K("Cada esqueje sale igual.")

static func corte_quita(S: Dictionary, i: int) -> void:
	var l := cortes(S)
	if i >= 0 and i < l.size():
		l.remove_at(i)

# ---------- polinizar entre clones ----------
# a: el esqueje madre, b: el esqueje padre (sus sid). Devuelve la variedad que sale; las semillas las pone quien llama
static func clones(S: Dictionary, a: String, b: String) -> String:
	return Datos.cross_result(S, a, b)

static func clon_sem() -> int:
	return int(d().clon.sem)

# ---------- autofecundación (S1) ----------
static func s1_n(S: Dictionary, sid: String) -> int:
	if not (S.get("s1") is Dictionary):
		S.s1 = {}
	return int(S.s1.get(sid, 0))

static func s1_tope() -> int:
	return int(d().s1.get("tope", 2))

static func s1_gasta() -> int:
	return int(d().s1.get("gasta", 1))

static func s1_ok(S: Dictionary, sid: String) -> bool:
	if not hay() or s1_n(S, sid) >= s1_tope():
		return false
	return int(S.get("seeds", {}).get(sid, 0)) >= s1_gasta()

# gasta 1 semilla, sube los genes de la línea y un nivel la fijación de sus rarezas. Devuelve las semillas que salen
static func s1(S: Dictionary, sid: String) -> int:
	var E: Dictionary = d().s1
	if not s1_ok(S, sid):
		return 0
	S.seeds[sid] = int(S.seeds[sid]) - s1_gasta()
	if int(S.seeds[sid]) <= 0:
		S.seeds.erase(sid)
	S.s1[sid] = s1_n(S, sid) + 1
	var L := Cultivo.iv_linea(S, sid)
	for i in 4:
		L[i] = mini(31, int(L[i]) + int(E.iv))
	var D := Datos.carga()
	if D.has("RAREZAS") and S.get("ra") is Dictionary and S.ra.get(sid) is Dictionary:
		var fj := int(D.RAREZAS.fija)
		for k in S.ra[sid].keys():
			S.ra[sid][k] = mini(fj, int(S.ra[sid][k]) + int(E.ra))
	return int(E.sem)

# ¿hay algo que trabajar hoy en el laboratorio? (si no, no se mete un menú de más: se va derecho a fijar la línea)
static func algo(S: Dictionary) -> bool:
	if not hay():
		return false
	if not bx_ls(S).is_empty():
		return true
	for sid in S.get("seeds", {}).keys():
		if s1_ok(S, String(sid)) or ibl_ok(S, String(sid)):
			return true
	return false

# ---------- retrocruce (BX) ----------
# las parentales de un híbrido propio (ma y pa de S.custom): con cuál se puede retrocruzar
static func bx_padres(S: Dictionary, sid: String) -> Array:
	var C = S.get("custom", {}).get(sid)
	if not (C is Dictionary):
		return []
	var o := []
	for k in [C.get("ma"), C.get("pa")]:
		if k != null and String(k) != "" and not o.has(String(k)):
			o.append(String(k))
	return o

# los híbridos propios que tienes en semilla y se pueden retrocruzar con una parental que también tengas
static func bx_ls(S: Dictionary) -> Array:
	var o := []
	if not hay():
		return o
	var g := bx_gasta()
	for sid in S.get("seeds", {}).keys():
		if int(S.seeds[sid]) < g:
			continue
		for p in bx_padres(S, String(sid)):
			if int(S.get("seeds", {}).get(p, 0)) >= g:
				o.append([String(sid), p])
	return o

# cuántos retrocruces lleva ya esa madre: cuenta todos los suyos, también los hechos sobre un BX anterior, para que
# «<madre> BX1» no salga dos veces (bx_nombre no pasa por el control de nombres usados de Datos.nombre_cruce)
static func bx_n(S: Dictionary, _hijo: String, madre: String) -> int:
	var n := 0
	for k in S.get("custom", {}).keys():
		var C = S.custom[k]
		if C is Dictionary and int(C.get("bx", 0)) > 0 and String(C.get("ma", "")) == madre:
			n = maxi(n, int(C.bx))
	return n

# el retrocruce: variedad nueva que tira a la madre en un DESC.bx.m %. Gasta 1 semilla de cada
static func bx(S: Dictionary, hijo: String, madre: String) -> String:
	var E: Dictionary = d().bx
	var n := bx_n(S, hijo, madre) + 1
	var id := "b" + Datos.b36(Datos.hash_str("bx|%s|%s|%d" % [hijo, madre, n]))
	if not (S.get("custom") is Dictionary):
		S.custom = {}
	if not S.custom.has(id):
		var A = Datos.strain(S, madre)
		var B = Datos.strain(S, hijo)
		var R := Datos.rng_seed(Datos.hash_str(id))
		var m := int(E.m[0]) + int(floor(R.sig() * (int(E.m[1]) - int(E.m[0]) + 1)))
		var C := {"n": _bx_nombre(S, A.n, n)}
		C.thc = minf(33, Datos.jsround(((A.thc * m + B.thc * (100 - m)) / 100.0 + R.sig() * 2 - 1) * 10) / 10.0)
		C.y = Datos.jsround((A.y * m + B.y * (100 - m)) / 100.0)
		C.d = Datos.jsround(((A.d * m + B.d * (100 - m)) / 100.0) * 2) / 2.0
		C.r = int(clamp(Datos.jsround((A.r * m + B.r * (100 - m)) / 100.0), 20, 95))
		C.o = I18n.T("{a} × {b} · retrocruce propio", {"a": B.n, "b": A.n})
		if A.get("auto") and B.get("auto"):
			C.auto = 1
		C.m = m
		C.ma = madre
		C.pa = hijo
		C.bx = n
		C.bxh = hijo
		C.hojas = Datos.hojas_cruce(S, madre, hijo)
		C.ind = Datos.jsround((m * Datos.ind_de(S, madre) + (100 - m) * Datos.ind_de(S, hijo)) / 100.0)
		C.hj = Datos.mix(Datos.hoja_de(S, hijo), Datos.hoja_de(S, madre), m / 100.0)
		C.c = Datos.mix(B.c, A.c, m / 100.0)
		S.custom[id] = C
	return id

static func _bx_nombre(S: Dictionary, base: String, n: int) -> String:
	var suf := " " + I18n.T(String(d().bx.suf), {"n": n})
	var nm := base
	if nm.length() + suf.length() > Datos.NOM_MAX:
		nm = nm.substr(0, Datos.NOM_MAX - suf.length()).rstrip(" ")
	return nm + suf

static func bx_sem() -> int:
	return int(d().bx.sem)

static func bx_gasta() -> int:
	return int(d().bx.get("gasta", 1))

# los días que ocupa cada trabajo del laboratorio (DESC.<vía>.dias)
static func dias(v: String) -> int:
	return maxi(1, int(d()[v].get("dias", 1)))

# ---------- línea fijada (IBL) ----------
static func ibls(S: Dictionary) -> Dictionary:
	if not (S.get("ibl") is Dictionary):
		S.ibl = {}
	return S.ibl

static func es_ibl(S: Dictionary, sid: String) -> bool:
	return hay() and int(ibls(S).get(sid, 0)) >= int(d().ibl.sel)

# se puede seleccionar: línea ya fijada (F4), con semilla y todavía sin llegar a IBL
static func ibl_ok(S: Dictionary, sid: String) -> bool:
	if not hay() or es_ibl(S, sid):
		return false
	if int(S.get("seeds", {}).get(sid, 0)) < int(d().ibl.get("gasta", 1)):
		return false
	return Cultivo.gen_de(S, sid) >= int(Datos.carga().GEN_ESTABLE)

# una selección más. Devuelve las semillas que salen; al llegar a DESC.ibl.sel la línea pasa a IBL
static func ibl(S: Dictionary, sid: String) -> int:
	var E: Dictionary = d().ibl
	if not ibl_ok(S, sid):
		return 0
	S.seeds[sid] = int(S.seeds[sid]) - int(E.get("gasta", 1))
	if int(S.seeds[sid]) <= 0:
		S.seeds.erase(sid)
	var m := ibls(S)
	m[sid] = int(m.get(sid, 0)) + 1
	if es_ibl(S, sid):
		var L := Cultivo.iv_linea(S, sid)
		for i in 4:
			L[i] = mini(31, maxi(int(L[i]), int(E.iv)))
	return int(E.sem)

static func ibl_falta(S: Dictionary, sid: String) -> int:
	return maxi(0, int(d().ibl.sel) - int(ibls(S).get(sid, 0)))
