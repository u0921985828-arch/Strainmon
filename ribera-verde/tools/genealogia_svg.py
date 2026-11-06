#!/usr/bin/env python3
# Landrace Hunters — el esquema de genealogía en SVG estructurado, con los gráficos del juego
# (lo pidió el usuario: «.svg estructurado» y «haz como el recetario, con los gráficos del juego»).
# Cada variedad sale como su ficha del recetario: el papel, la franja del grupo, la hoja de abanico de
# `src/hoja.gd` (la misma que ve el jugador) y el nombre. Nada escrito a mano: todo de
# `godot/datos/datos.json` y de las hojas que vuelca `godot/tools/genealogia_hojas.gd`.
#   docs/plano/genealogia/arbol.svg      el grafo entero por generaciones, con fichas pequeñas
#   docs/plano/genealogia/landraces.svg  las 31 landraces por región, con la ficha entera
# Estructurado: <g> con id y class por capa y por variedad, <title>/<desc> en cada ficha, los estilos en
# un <style> con clases y las aristas con data-de/data-a. Las hojas van una sola vez en <defs>.
#   godot: $GODOT --headless --path godot --script res://tools/genealogia_hojas.gd -- --salida <hojas>
#   python3 -I tools/genealogia_svg.py
import base64, json, os, re, html

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DST = os.path.join(RAIZ, "docs", "plano", "genealogia")
HOJAS = os.path.join(DST, "hojas")
D = json.load(open(os.path.join(RAIZ, "godot", "datos", "datos.json"), encoding="utf-8"))
S, LAND, DEX, AUTO = D["STRAINS"], D["LANDRACES"], D["DEX"], D["AUTO"]
TODAS = list(DEX) + list(AUTO["dex"])
REC = dict(D["RECIPES"]); REC.update(AUTO["recipes"])

# la paleta de la ficha del juego (menus.gd rects_ficha y trama.gd COLOR_GRUPO)
PAPEL = ["#5a5040", "#f4f2ea", "#e8e4d6", "#f8f6ee"]
COLOR_GRUPO = ["#c07a1e", "#8a9a2a", "#5a8a5a", "#7a4a8a", "#5a2a7a"]
GRUPO_T = ["SATIVA", "HÍBRIDO SATIVA", "EQUILIBRADO", "HÍBRIDO ÍNDICA", "ÍNDICA"]
TINTA = "#22261e"

def nom(k): return S[k]["n"] if k in S else k
def esc(t): return html.escape(str(t), quote=True)
def coma(x): return str(x).replace(".", ",")

def grupo_n(ind):   # menus.gd grupo_n
    p = int(round(ind))
    return 0 if p <= 10 else (1 if p < 40 else (2 if p <= 60 else (3 if p < 90 else 4)))

def hoja_b64(k):
    p = os.path.join(HOJAS, k + ".png")
    if not os.path.exists(p): return None
    return base64.b64encode(open(p, "rb").read()).decode("ascii")

def defs_hojas(ks):
    o = ['<defs>']
    for k in ks:
        b = hoja_b64(k)
        if b is None: continue
        o.append('  <symbol id="h-%s" viewBox="0 0 64 64">'
                 '<image width="64" height="64" href="data:image/png;base64,%s"/></symbol>' % (esc(k), b))
    o.append('</defs>')
    return o

# ── padres de cada variedad (todas sus recetas juntas, sin repetir) ──
padres = {}
for clave, hijo in REC.items():
    for p in clave.split("+"):
        padres.setdefault(hijo, [])
        if p not in padres[hijo]:
            padres[hijo].append(p)
for clave, hijo in D["RECETA_ORD"].items():
    for p in clave.split(">"):
        padres.setdefault(hijo, [])
        if p not in padres[hijo]:
            padres[hijo].append(p)

# ── capas: la landrace en la 0; cada cruce, una más que su padre más alto ──
capa = {}
def nivel(k, visto=()):
    if k in capa: return capa[k]
    if k in visto or k not in padres: return 0
    n = 1 + max(nivel(p, tuple(visto) + (k,)) for p in padres[k])
    capa[k] = n
    return n
for k in TODAS:
    capa[k] = 0 if k not in padres else nivel(k)

CAPAS = {}
for k in TODAS:
    CAPAS.setdefault(capa[k], []).append(k)

# ── el orden dentro de cada capa: el baricentro de los padres, tres pasadas ──
pos = {}
for c in sorted(CAPAS):
    CAPAS[c].sort(key=lambda k: (S[k]["ind"] if c == 0 else 0, nom(k)))
for _ in range(3):
    for c in sorted(CAPAS):
        if c == 0: continue
        CAPAS[c].sort(key=lambda k: sum(CAPAS[capa[p]].index(p) / max(1, len(CAPAS[capa[p]]))
                                        for p in padres.get(k, [])) / max(1, len(padres.get(k, []))))

# ───────────────────────── el árbol ─────────────────────────
NW, NH, GX, GY, M = 206, 46, 300, 54, 30
ALTO = max(len(v) for v in CAPAS.values()) * GY + 2 * M + 76
ANCHO = (max(CAPAS) + 1) * GX + NW + 2 * M

for c in sorted(CAPAS):
    sitio = (ALTO - 76 - len(CAPAS[c]) * GY) / 2 + 52
    for i, k in enumerate(CAPAS[c]):
        pos[k] = (M + c * GX, sitio + i * GY)

L = []
A = L.append
A('<?xml version="1.0" encoding="UTF-8"?>')
A('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" '
  'role="img" aria-labelledby="t a">' % (ANCHO, ALTO, ANCHO, ALTO))
A('<title id="t">Landrace Hunters · árbol genealógico de las %d variedades</title>' % len(TODAS))
A('<desc id="a">De izquierda a derecha, por generaciones: en la primera columna lo que no tiene receta '
  '(las landraces y las variedades de partida) y cada cruce a la derecha de sus padres. Cada variedad sale '
  'en su ficha del recetario, con la hoja de abanico que le toca por genética.</desc>')
A('''<style>
 .bg{fill:#12170f}
 text{font-family:"DejaVu Sans",sans-serif}
 .cap{font-size:14px;font-weight:700;fill:#9fbf78;letter-spacing:.08em}
 .f image{image-rendering:pixelated}
 .f .p0{fill:#5a5040} .f .p1{fill:#f4f2ea} .f .p2{fill:#e8e4d6} .f .p3{fill:#f8f6ee}
 .f .nm{font-size:11.5px;font-weight:700;fill:#22261e}
 .f .nu{font-size:9px;fill:#6a6450}
 .f .gr{font-size:8px;font-weight:700;letter-spacing:.06em}
 .land .p0{fill:#d8c070}
 .auto .p0{fill:#5f8fb4}
 .e{fill:none;stroke:#6f8c57;stroke-width:1.1;opacity:.5}
 .e.land{stroke:#b9a75e;opacity:.65}
 .leg text{font-size:11px;fill:#b7cf95}
 .leg rect{stroke:#0a0d08}
</style>''')
A('<rect class="bg" width="100%" height="100%"/>')
L.extend(defs_hojas(TODAS))

A('<g class="capas">')
for c in sorted(CAPAS):
    t = "ORIGEN · sin receta" if c == 0 else "%d.ª generación" % c
    A('  <text class="cap" x="%d" y="%d">%s · %d</text>' % (M + c * GX, 36, esc(t), len(CAPAS[c])))
A('</g>')

A('<g class="aristas" aria-hidden="true">')
for k in TODAS:
    for p in padres.get(k, []):
        if p not in pos or k not in pos: continue
        x1, y1 = pos[p][0] + NW, pos[p][1] + NH / 2
        x2, y2 = pos[k][0], pos[k][1] + NH / 2
        mx = (x1 + x2) / 2
        A('  <path class="e%s" data-de="%s" data-a="%s" d="M%.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f"/>'
          % (" land" if p in LAND else "", esc(p), esc(k), x1, y1, mx, y1, mx, y2, x2, y2))
A('</g>')

def ficha(o, k, x, y, w, h, grande=False):
    """La ficha del recetario: el papel de cuatro capas, la franja del grupo, la hoja y el texto."""
    s = S[k]
    g = grupo_n(s["ind"])
    cls = "f%s%s" % (" land" if k in LAND else "", " auto" if s.get("auto") else "")
    o.append('    <g class="%s" id="v-%s">' % (cls, esc(k)))
    o.append('      <title>%s</title>' % esc("%s · %d %% índica · THC %d %% · flor %s semanas · res %d"
                                             % (nom(k), s["ind"], s["thc"], coma(s["d"]), s["r"])))
    o.append('      <desc>%s</desc>' % esc(s.get("o", "")))
    o.append('      <rect class="p0" x="%d" y="%.1f" width="%d" height="%d" rx="2"/>' % (x, y, w, h))
    o.append('      <rect class="p1" x="%d" y="%.1f" width="%d" height="%d"/>' % (x + 1, y + 1, w - 2, h - 2))
    o.append('      <rect class="p2" x="%d" y="%.1f" width="%d" height="%d"/>' % (x + 3, y + 3, w - 6, h - 6))
    o.append('      <rect class="p3" x="%d" y="%.1f" width="%d" height="%d"/>' % (x + 4, y + 4, w - 8, h - 8))
    o.append('      <rect x="%d" y="%.1f" width="3" height="%d" fill="%s"/>' % (x + 4, y + 4, h - 8, COLOR_GRUPO[g]))
    hs = 64 if grande else 36
    hx, hy = x + 10, y + (h - hs) / 2
    o.append('      <use href="#h-%s" x="%.1f" y="%.1f" width="%d" height="%d"/>' % (esc(k), hx, hy, hs, hs))
    tx = hx + hs + 8
    if grande:
        o.append('      <text class="nm" x="%.1f" y="%.1f" style="font-size:14px">%s</text>' % (tx, y + 24, esc(nom(k))))
        o.append('      <text class="gr" x="%.1f" y="%.1f" fill="%s" style="font-size:9.5px">%s</text>'
                 % (tx, y + 39, COLOR_GRUPO[g], esc(GRUPO_T[g])))
        o.append('      <text class="nu" x="%.1f" y="%.1f" style="font-size:10.5px">%s</text>'
                 % (tx, y + 55, esc("ind %d · THC %d %% · %s sem · res %d" % (s["ind"], s["thc"], coma(s["d"]), s["r"]))))
        z = re.sub(r"^Landrace · ", "", str(s.get("o", "")))
        if len(z) > 38:
            z = z[:34].rsplit(" ", 1)[0].rstrip(" ,;") + "…"
        o.append('      <text class="nu" x="%.1f" y="%.1f" style="font-size:12px;fill:#44483a">%s</text>'
                 % (tx, y + 71, esc(z)))
    else:
        t = nom(k)
        if len(t) > 19: t = t[:18] + "."
        o.append('      <text class="nm" x="%.1f" y="%.1f">%s</text>' % (tx, y + 20, esc(t)))
        o.append('      <text class="nu" x="%.1f" y="%.1f">%s</text>'
                 % (tx, y + 33, esc("ind %d · THC %d %%" % (s["ind"], s["thc"]))))
    o.append('    </g>')

A('<g class="nodos">')
for c in sorted(CAPAS):
    A('  <g class="capa c%d" id="capa-%d">' % (c, c))
    for k in CAPAS[c]:
        x, y = pos[k]
        ficha(L, k, x, y, NW, NH)
    A('  </g>')
A('</g>')

A('<g class="leg" transform="translate(%d,%d)">' % (M, ALTO - 26))
leg = [(COLOR_GRUPO[i], GRUPO_T[i].lower()) for i in range(5)] + \
      [("#d8c070", "landrace: canto dorado"), ("#5f8fb4", "autofloreciente: canto azul")]
x = 0
for col, t in leg:
    A('  <g transform="translate(%d,0)"><rect width="12" height="12" y="-10" rx="2" fill="%s"/>'
      '<text x="18" y="0">%s</text></g>' % (x, col, esc(t)))
    x += 42 + int(6.2 * len(t))
A('</g>')
A('</svg>')
os.makedirs(DST, exist_ok=True)
open(os.path.join(DST, "arbol.svg"), "w", encoding="utf-8").write("\n".join(L) + "\n")

# ───────────── la lámina de las landraces ─────────────
ZONAS = [("Asia · el Kush y el Himalaya", ["rif", "hindu", "chitral", "purpura", "kashmir", "malana", "nepal"]),
         ("Asia · sudeste e India", ["thai", "hthai", "choco", "lao", "vietblack", "kerala"]),
         ("África y el Mediterráneo", ["kif", "beldia", "libano", "congo", "malawi", "swazi", "durban", "etiopia"]),
         ("América", ["acapulco", "oaxaca", "mich", "punto", "colgold", "panama", "mangarosa"]),
         ("Islas", ["hawai", "lamb", "zamal"])]
for _z, _ks in ZONAS:            # que no se quede ninguna fuera por un id mal escrito
    for _k in _ks:
        assert _k in S, _k
assert sum(len(z[1]) for z in ZONAS) == len(LAND), "faltan landraces en las regiones"
CW, CH, CGX, CGY, M2 = 320, 84, 348, 94, 30
cols = len(ZONAS)
filas = max(len(z[1]) for z in ZONAS)
W2 = cols * CGX + 2 * M2
H2 = filas * CGY + 2 * M2 + 86
B = []
b = B.append
b('<?xml version="1.0" encoding="UTF-8"?>')
b('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" '
  'role="img" aria-labelledby="t2 a2">' % (W2, H2, W2, H2))
b('<title id="t2">Landrace Hunters · las %d landraces por región</title>' % len(LAND))
b('<desc id="a2">Cinco columnas por región. De cada landrace, su ficha del recetario: la hoja de abanico, el '
  'grupo, el porcentaje índica, el THC, las semanas de floración, la resistencia y de dónde es.</desc>')
b('''<style>
 .bg{fill:#12170f}
 text{font-family:"DejaVu Sans",sans-serif}
 .zona{font-size:14px;font-weight:700;fill:#9fbf78}
 .pie{font-size:11px;fill:#b7cf95}
 .f image{image-rendering:pixelated}
 .f .p0{fill:#d8c070} .f .p1{fill:#f4f2ea} .f .p2{fill:#e8e4d6} .f .p3{fill:#f8f6ee}
 .f .nm{font-weight:700;fill:#22261e}
 .f .nu{fill:#6a6450}
 .f .gr{font-weight:700;letter-spacing:.06em}
</style>''')
b('<rect class="bg" width="100%" height="100%"/>')
B.extend(defs_hojas([k for z in ZONAS for k in z[1]]))
b('<text class="zona" x="%d" y="38" style="font-size:19px">Las %d landraces</text>' % (M2, len(LAND)))
for ci, (t, ks) in enumerate(ZONAS):
    X = M2 + ci * CGX
    b('<g class="col" id="zona-%d">' % ci)
    b('  <text class="zona" x="%d" y="%d">%s</text>' % (X, 74, esc(t)))
    for i, k in enumerate(ks):
        if k not in S: continue
        ficha(B, k, X, 90 + i * CGY, CW, CH, True)
    b('</g>')
b('<text class="pie" x="%d" y="%d">La ficha es la del recetario del juego: la franja del canto dice el grupo y '
  'la hoja de abanico sale de la genética de cada variedad.</text>' % (M2, H2 - 24))
b('</svg>')
open(os.path.join(DST, "landraces.svg"), "w", encoding="utf-8").write("\n".join(B) + "\n")
print("genealogia_svg: arbol %d fichas en %d capas (%d×%d) · landraces %d (%d×%d) · %s"
      % (len(TODAS), len(CAPAS), ANCHO, ALTO, len(LAND), W2, H2, DST))
