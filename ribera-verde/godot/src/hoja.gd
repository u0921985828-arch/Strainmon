# Ribera Verde (Godot) — 1.51 (lo pidió el usuario: «en el cannabis, dependiendo de la variedad o linaje, las hojas son diferentes»):
# la hoja de abanico de cada variedad, dibujada en código pixel a pixel como el resto del arte a mano. La genética manda:
#  · el % de índica (ind, 0 sativa … 1 índica) da el número de foliolos (9 las sativas puras, 7 las demás), lo ancho de cada foliolo
#    (las sativas, finos y largos; las índicas, anchos y cortos) y lo abierto del abanico;
#  · el tono de hoja de la variedad (hj) o el de su ficha de hoja (D.HOJA[sid]: f foliolos, a ancho, cu caída de las puntas, c color),
#    para las landraces que se distinguen a simple vista (las tailandesas, de puntas caídas; la hawaiana, ancha y clara…).
# Contorno oscuro de su tono, luz arriba a la izquierda (la mitad de cada foliolo que mira arriba, más clara), nervio central y dientes.
extends RefCounted

const Datos = preload("res://src/datos.gd")
const I18n = preload("res://src/i18n.gd")

const W := 64
const H := 64

static func _c(h: String) -> Color:
	return Color(h)

static func params(D: Dictionary, S: Dictionary, sid: String) -> Dictionary:
	var ind: float = clampf(Datos.ind_de(S, sid) / 100.0, 0, 1)
	var st = Datos.strain(S, sid)
	var hj: String = st.get("hj", "#57a33e") if st else "#57a33e"
	var p := {"ind": ind, "f": 9 if ind < .25 else 7, "a": 1.0, "cu": 0.0, "c": hj}
	var o = D.get("HOJA", {}).get(sid)
	if o is Dictionary:
		for k in o:
			p[k] = o[k]
	return p

# el foliolo: a lo largo del eje (t de 0 a 1), medio ancho w(t); los dientes, un serrucho en el borde
static func imagen(p: Dictionary) -> Image:
	var im := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var ind: float = p.ind
	var f: int = int(p.f)
	var base := _c(p.c)
	var luz := base.lightened(.28)
	var som := base.darkened(.22)
	var ner := base.darkened(.45)
	var bor := base.darkened(.62)
	var ox := W / 2.0
	var oy := H - 9.0
	var abre: float = deg_to_rad(150 + 40 * ind)                 # el abanico: las índicas, más abierto
	var L0: float = 44.0 - 8 * ind                                 # el foliolo central
	var anch: float = (.05 + .09 * ind) * float(p.a)              # medio ancho máximo / largo: la sativa, 1 a 10; la índica, 1 a 4
	var e: float = log(.5) / log(.5 - .1 * ind)                    # dónde es más ancho: las índicas, algo antes del medio
	var cu: float = float(p.cu)
	var M := {}   # (x, y) → 0 sombra, 1 luz, 2 nervio
	for i in f:
		var u: float = (i - (f - 1) / 2.0) / ((f - 1) / 2.0)        # -1 … 1
		var ang: float = -PI / 2 + u * abre / 2
		var L: float = L0 * (1 - .62 * pow(absf(u), 1.6))
		var dir := Vector2(cos(ang), sin(ang))
		var nor := Vector2(-dir.y, dir.x)
		var pasos := int(L * 3)
		for s in pasos + 1:
			var t: float = float(s) / pasos
			# la caída de las puntas (las tailandesas): el eje se dobla hacia abajo al final
			var c: Vector2 = Vector2(ox, oy) + dir * (L * t) + Vector2(0, cu * L * .35 * t * t) * (1 if absf(u) > .05 else .3)
			var perf: float = pow(sin(PI * pow(t, e)), 1.25)        # el pie del foliolo, estrecho: cada uno, suelto hasta el rabillo
			var w: float = maxf(.4, L * anch * perf)
			if t > .15 and t < .92 and w > 1.2:   # los dientes: un píxel que entra y sale
				w += .9 * (absf(fmod(t * L / 2.5, 1.0) - .5) * 2 - .5)
			var q := -w
			while q <= w:
				var pt: Vector2 = c + nor * q
				var k := Vector2i(roundi(pt.x), roundi(pt.y))
				var v := 2 if absf(q) < .5 and t < .9 else (1 if (nor * q).y < 0 or (nor * q).x < -.2 else 0)
				if not M.has(k) or v == 2:
					M[k] = v
				q += .35
	# el rabillo
	for y in range(int(oy), H - 1):
		M[Vector2i(int(ox), y)] = 2
		M[Vector2i(int(ox) + 1, y)] = 0
	for k in M:
		if k.x >= 1 and k.y >= 1 and k.x < W - 1 and k.y < H - 1:
			im.set_pixelv(k, [som, luz, ner][M[k]])
	# el contorno, por fuera
	var bordes := []
	for y in H:
		for x in W:
			if im.get_pixel(x, y).a > 0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < W and n.y < H and im.get_pixelv(n).a > 0 and im.get_pixelv(n) != bor:
					bordes.append(Vector2i(x, y))
					break
	for b in bordes:
		im.set_pixelv(b, bor)
	return im

# lo que se lee en la ficha: el grupo (como en las láminas de genéticas) y cómo es la hoja
static func grupo(ind: float, landrace: bool) -> String:
	var pi_ := roundi(ind * 100)
	if pi_ <= 10:
		return I18n.T("Sativa · landrace pura · ~{n} % sativa", {"n": 100 - pi_}) if landrace else I18n.T("Sativa · ~{n} % sativa", {"n": 100 - pi_})
	if pi_ < 40:
		return I18n.T("Híbrido de dominancia sativa · ~{a}/{b} sativa", {"a": 100 - pi_, "b": pi_})
	if pi_ <= 60:
		return I18n.T("Landrace intermedia · ~{a}/{b}", {"a": 100 - pi_, "b": pi_}) if landrace else I18n.T("Híbrido equilibrado · ~{a}/{b}", {"a": 100 - pi_, "b": pi_})
	if pi_ < 90:
		return I18n.T("Híbrido de dominancia índica · ~{a}/{b} índica", {"a": pi_, "b": 100 - pi_})
	return I18n.T("Índica · landrace pura · ~{n} % índica", {"n": pi_}) if landrace else I18n.T("Índica · ~{n} % índica", {"n": pi_})

static func como(p: Dictionary) -> String:
	var ind: float = p.ind
	var fo := I18n.T("{n} foliolos", {"n": int(p.f)})
	var an := I18n.K("finos y largos") if ind < .3 and float(p.a) < 1.15 else (I18n.K("anchos y cortos") if ind > .7 or float(p.a) > 1.2 else I18n.K("medianos"))
	return I18n.T("Hoja de {fo} {an}, con las puntas caídas.", {"fo": fo, "an": an}) if float(p.cu) > .3 else I18n.T("Hoja de {fo} {an}.", {"fo": fo, "an": an})
