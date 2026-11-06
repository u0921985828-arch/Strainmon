#!/usr/bin/env python3
# Landrace Hunters — el esquema de genealogía en SVG estructurado (lo pidió el usuario: «.svg estructurado»).
# Sale de `godot/datos/datos.json`: nada escrito a mano. Dos láminas:
#   docs/plano/genealogia/arbol.svg      el grafo entero por generaciones, landraces a la izquierda
#   docs/plano/genealogia/landraces.svg  las 31 landraces por continente, con sus números
# Estructurado de verdad: <g> con id y class por capa y por variedad, <title>/<desc> en cada nodo, los
# estilos en un <style> con clases (nada de atributos repetidos), y las aristas con data-de/data-a.
#   python3 -I tools/genealogia_svg.py
import json, os, re, html

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = json.load(open(os.path.join(RAIZ, "godot", "datos", "datos.json"), encoding="utf-8"))
S, LAND, DEX, AUTO = D["STRAINS"], D["LANDRACES"], D["DEX"], D["AUTO"]
TODAS = list(DEX) + list(AUTO["dex"])
REC = dict(D["RECIPES"]); REC.update(AUTO["recipes"])

def nom(k): return S[k]["n"] if k in S else k
def esc(t): return html.escape(str(t), quote=True)

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

NW, NH, GX, GY, M = 182, 26, 268, 34, 28
ALTO = max(len(v) for v in CAPAS.values()) * GY + 2 * M + 70
ANCHO = (max(CAPAS) + 1) * GX + NW + 2 * M

for c in sorted(CAPAS):
    sitio = (ALTO - 70 - len(CAPAS[c]) * GY) / 2 + 48
    for i, k in enumerate(CAPAS[c]):
        pos[k] = (M + c * GX, sitio + i * GY)

def tono(k):
    ind = int(S[k]["ind"])
    return "ind-s" if ind <= 25 else ("ind-h" if ind < 75 else "ind-i")

L = []
A = L.append
A('<?xml version="1.0" encoding="UTF-8"?>')
A('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" '
  'role="img" aria-labelledby="t a">' % (ANCHO, ALTO, ANCHO, ALTO))
A('<title id="t">Landrace Hunters · árbol genealógico de las %d variedades</title>' % len(TODAS))
A('<desc id="a">De izquierda a derecha, por generaciones: las landraces en la primera columna y cada cruce '
  'a la derecha de sus padres. El color dice el porte: verde claro sativa, medio híbrida, oscuro índica.</desc>')
A('''<style>
 .bg{fill:#12170f}
 text{font-family:"DejaVu Sans",sans-serif;fill:#eaf3e0}
 .cap{font-size:13px;font-weight:700;fill:#9fbf78;letter-spacing:.08em}
 .n text{font-size:11px;dominant-baseline:middle}
 .n rect{stroke:#0a0d08;stroke-width:1;rx:5;ry:5}
 .ind-s rect{fill:#4e7a2e} .ind-h rect{fill:#3c6b3a} .ind-i rect{fill:#2d4a33}
 .land rect{stroke:#d8c070;stroke-width:1.6}
 .auto rect{stroke:#7fb4d8;stroke-width:1.6;stroke-dasharray:4 2}
 .e{fill:none;stroke:#6f8c57;stroke-width:1.1;opacity:.55}
 .e.land{stroke:#b9a75e;opacity:.7}
 .leg text{font-size:11px;fill:#b7cf95}
 .leg rect{rx:4;ry:4;stroke:#0a0d08}
 .leg .land rect{fill:#3c6b3a;stroke:#d8c070;stroke-width:1.6}
 .leg .auto rect{fill:#3c6b3a;stroke:#7fb4d8;stroke-width:1.6;stroke-dasharray:3 2}
</style>''')
A('<rect class="bg" width="100%" height="100%"/>')

# los rótulos de cada columna
A('<g class="capas">')
for c in sorted(CAPAS):
    t = "ORIGEN · sin receta" if c == 0 else "%d.ª generación" % c
    A('  <text class="cap" x="%d" y="%d">%s · %d</text>' % (M + c * GX, 34, esc(t), len(CAPAS[c])))
A('</g>')

# las aristas, antes que los nodos
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

# los nodos
A('<g class="nodos">')
for c in sorted(CAPAS):
    A('  <g class="capa c%d" id="capa-%d">' % (c, c))
    for k in CAPAS[c]:
        x, y = pos[k]
        s = S[k]
        cls = "n %s%s%s" % (tono(k), " land" if k in LAND else "", " auto" if s.get("auto") else "")
        A('    <g class="%s" id="v-%s">' % (cls, esc(k)))
        A('      <title>%s</title>' % esc("%s · %d %% índica · THC %d %% · flor %s semanas"
                                          % (nom(k), s["ind"], s["thc"], str(s["d"]).replace(".", ","))))
        A('      <desc>%s</desc>' % esc(s.get("o", "")))
        A('      <rect x="%d" y="%.1f" width="%d" height="%d"/>' % (x, y, NW, NH))
        A('      <text x="%d" y="%.1f">%s</text>' % (x + 9, y + NH / 2, esc(nom(k))))
        A('    </g>')
    A('  </g>')
A('</g>')

# la leyenda
A('<g class="leg" transform="translate(%d,%d)">' % (M, ALTO - 26))
for i, (c, t) in enumerate([("ind-s", "sativa (ind ≤ 25)"), ("ind-h", "híbrida"), ("ind-i", "índica (ind ≥ 75)"),
                            ("land", "landrace: borde dorado"), ("auto", "autofloreciente: borde azul")]):
    A('  <g class="%s" transform="translate(%d,0)"><rect width="14" height="14" y="-11"/>'
      '<text x="20" y="0">%s</text></g>' % (c, i * 210, esc(t)))
A('</g>')
A('</svg>')

dst = os.path.join(RAIZ, "docs", "plano", "genealogia")
os.makedirs(dst, exist_ok=True)
open(os.path.join(dst, "arbol.svg"), "w", encoding="utf-8").write("\n".join(L) + "\n")

# ───────────── la lámina de las landraces ─────────────
ZONAS = [("Asia · el Kush y el Himalaya", ["rif", "hindu", "chitral", "purpura", "kashmir", "malana", "nepal"]),
         ("Asia · sudeste e India", ["thai", "hthai", "choco", "lao", "vietblack", "kerala"]),
         ("África y el Mediterráneo", ["kif", "beldia", "libano", "congo", "malawi", "swazi", "durban", "etiopia"]),
         ("América", ["acapulco", "oaxaca", "mich", "punto", "colgold", "panama", "mangarosa"]),
         ("Islas", ["hawai", "lamb", "zamal"])]
CW, CH, CGX, CGY = 300, 54, 330, 62
cols = len(ZONAS)
filas = max(len(z[1]) for z in ZONAS)
W2 = cols * CGX + 2 * M
H2 = filas * CGY + 2 * M + 80
B = []
b = B.append
b('<?xml version="1.0" encoding="UTF-8"?>')
b('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" '
  'role="img" aria-labelledby="t2 a2">' % (W2, H2, W2, H2))
b('<title id="t2">Landrace Hunters · las %d landraces por continente</title>' % len(LAND))
b('<desc id="a2">Cinco columnas por región. De cada landrace: su porcentaje índica, el THC, las semanas de '
  'floración, la resistencia y de dónde es.</desc>')
b('''<style>
 .bg{fill:#12170f}
 text{font-family:"DejaVu Sans",sans-serif;fill:#eaf3e0}
 .zona{font-size:14px;font-weight:700;fill:#9fbf78}
 .f rect{rx:6;ry:6;stroke:#d8c070;stroke-width:1.3}
 .ind-s rect{fill:#4e7a2e} .ind-h rect{fill:#3c6b3a} .ind-i rect{fill:#2d4a33}
 .nm{font-size:12.5px;font-weight:700}
 .nu{font-size:10.5px;fill:#cfe3b4}
 .zn{font-size:9.5px;fill:#a9c48a}
 .bar{fill:#0a0d08;opacity:.45;rx:2;ry:2}
 .barv{fill:#cfe3b4;rx:2;ry:2}
</style>''')
b('<rect class="bg" width="100%" height="100%"/>')
b('<text class="zona" x="%d" y="34" style="font-size:18px">Las %d landraces</text>' % (M, len(LAND)))
for ci, (t, ks) in enumerate(ZONAS):
    X = M + ci * CGX
    b('<g class="col" id="zona-%d">' % ci)
    b('  <text class="zona" x="%d" y="%d">%s</text>' % (X, 70, esc(t)))
    for i, k in enumerate(ks):
        if k not in S: continue
        s = S[k]
        Y = 86 + i * CGY
        b('  <g class="f %s" id="l-%s">' % (tono(k), esc(k)))
        b('    <title>%s</title>' % esc("%s · ind %d · THC %d %% · flor %s sem · res %d"
                                        % (nom(k), s["ind"], s["thc"], str(s["d"]).replace(".", ","), s["r"])))
        b('    <desc>%s</desc>' % esc(s.get("o", "")))
        b('    <rect x="%d" y="%d" width="%d" height="%d"/>' % (X, Y, CW, CH))
        b('    <text class="nm" x="%d" y="%d">%s</text>' % (X + 10, Y + 17, esc(nom(k))))
        b('    <text class="nu" x="%d" y="%d">ind %d · THC %d %% · %s sem · res %d</text>'
          % (X + 10, Y + 32, s["ind"], s["thc"], str(s["d"]).replace(".", ","), s["r"]))
        z = re.sub(r"^Landrace · ", "", str(s.get("o", "")))
        if len(z) > 44:
            z = z[:44].rsplit(" ", 1)[0].rstrip(" ,;") + "…"
        b('    <text class="zn" x="%d" y="%d">%s</text>' % (X + 10, Y + 45, esc(z)))
        b('    <rect class="bar" x="%d" y="%d" width="80" height="5"/>' % (X + CW - 90, Y + 12))
        b('    <rect class="barv" x="%d" y="%d" width="%.1f" height="5"/>'
          % (X + CW - 90, Y + 12, 80 * s["ind"] / 100.0))
        b('  </g>')
    b('</g>')
b('<text class="nu" x="%d" y="%d">La barra de cada ficha es el porcentaje índica: vacía, sativa pura; '
  'llena, índica pura.</text>' % (M, H2 - 24))
b('</svg>')
open(os.path.join(dst, "landraces.svg"), "w", encoding="utf-8").write("\n".join(B) + "\n")
print("genealogia_svg: arbol %d nodos en %d capas (%d×%d) · landraces %d (%d×%d) · %s"
      % (len(TODAS), len(CAPAS), ANCHO, ALTO, len(LAND), W2, H2, dst))
