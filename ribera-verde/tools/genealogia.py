#!/usr/bin/env python3
# Landrace Hunters — el esquema de las landraces y los árboles genealógicos de todas las variedades
# (lo pidió el usuario: «haz un esquema de todas las Landrace y todos los árboles genealógicos»).
# Sale de `godot/datos/datos.json`, la fuente: nada escrito a mano, así que no se queda desfasado.
#   python3 -I tools/genealogia.py            → ribera-verde/docs/GENEALOGIA.md
import json, os, sys, re

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = json.load(open(os.path.join(RAIZ, "godot", "datos", "datos.json"), encoding="utf-8"))
S, LAND, DEX = D["STRAINS"], D["LANDRACES"], D["DEX"]
AUTO = D["AUTO"]
TODAS = list(DEX) + list(AUTO["dex"])
RECETAS = dict(D["RECIPES"])
RECETAS.update(AUTO["recipes"])
ORD = D["RECETA_ORD"]

def nom(k):
    return S[k]["n"] if k in S else k

# ── de qué se hace cada variedad: {hijo: [ [padres...], ... ] } ──
hijos = {}
for clave, hijo in RECETAS.items():
    hijos.setdefault(hijo, []).append(clave.split("+"))
for clave, hijo in ORD.items():
    a, b = clave.split(">")
    hijos.setdefault(hijo, []).append([a, b])   # con la madre delante

def vias(k):
    """Cómo se consigue: banco del PC, growshop, la tía, la caza, la revista, receta…"""
    v = []
    if any(b[0] == k for b in D["BANCO"]) or any(b[0] == k for b in AUTO["banco"]):
        v.append("banco del PC")
    if k in D["REGALO"]:
        v.append("lo escondió la tía")
    if any(str(c.get("k")) == k for c in D["CAZA"]["l"]):
        v.append("la caza")
    for c in D.get("BANCO_TIA", {}).get("col", []):
        if k in c.get("s", []):
            v.append("banco de la tía")
            break
    if k in hijos:
        v.append("receta")
    return v or ["del growshop o de la historia"]

def fam(k):
    for fk, f in D["FAMILIAS"].items():
        if k in f.get("s", []):
            return f["n"]
    return "—"

def arbol(k, prof=0, visto=None, pre=""):
    """El árbol de una variedad, hacia atrás hasta las landraces."""
    visto = set(visto or ())
    out = []
    if k in visto or prof > 6:
        return ["%s└─ %s (…)" % (pre, nom(k))]
    visto.add(k)
    ps = hijos.get(k, [])
    if not ps:
        marca = " ·landrace·" if k in LAND else ""
        return ["%s%s%s" % (pre, nom(k), marca)]
    out.append("%s%s" % (pre, nom(k)))
    # la receta con menos padres primero; si hay varias, se listan todas
    varias = len(ps) > 1
    for i, padres in enumerate(sorted(ps, key=len)):
        base = pre + "   "
        if varias:
            ult = i == len(ps) - 1
            out.append("%s%s receta %d: %s" % (pre, "└" if ult else "├", i + 1,
                                               " × ".join(nom(p) for p in padres)))
            base = pre + ("   " if ult else "│  ")
        for j, p in enumerate(padres):
            rama = "└─ " if j == len(padres) - 1 else "├─ "
            sig = "   " if j == len(padres) - 1 else "│  "
            sub = arbol(p, prof + 1, visto, "")
            out.append("%s%s%s" % (base, rama, sub[0]))
            for l in sub[1:]:
                out.append("%s%s%s" % (base, sig, l[3:] if l[:3] == "   " else l))
    return out

L = []
A = L.append
A("# Las landraces y los árboles genealógicos")
A("")
A("Sacado de `godot/datos/datos.json` con `python3 -I tools/genealogia.py`: **%d variedades** "
  "(%d landraces, %d cruces y %d autoflorecientes). Nada escrito a mano aquí; si cambia el juego, se vuelve a pasar."
  % (len(TODAS), len(LAND), len(TODAS) - len(LAND) - len(AUTO["dex"]), len(AUTO["dex"])))
A("")
A("Leyenda: **ind** es el porcentaje índica de verdad (0 = sativa pura, 100 = índica pura), **THC** el techo de la "
  "variedad, **flor** las semanas de floración y **res** la resistencia al moho y a las plagas. En los árboles, "
  "`·landrace·` marca la hoja: ahí se acaba el linaje.")
A("")

# ── 1. las landraces ──
A("## 1. Las landraces, por continente")
A("")
ZONAS = [
    ("Asia: el Kush y el Himalaya", ["rif", "hindu", "chitral", "purpura", "kashmir", "malana", "nepal"]),
    ("Asia: el sudeste y la India", ["thai", "hthai", "choco", "lao", "vietblack", "kerala"]),
    ("África y el Mediterráneo", ["kif", "beldia", "libano", "congo", "malawi", "swazi", "durban", "etiopia"]),
    ("América", ["acapulco", "oaxaca", "mich", "punto", "colgold", "panama", "mangarosa"]),
    ("Islas", ["hawai", "lamb", "zamal"]),
]
puestas = set()
for t, ks in ZONAS:
    A("### %s" % t)
    A("")
    A("| Variedad | ind | THC | flor | res | De dónde es | Cómo se consigue |")
    A("|---|--:|--:|--:|--:|---|---|")
    for k in ks:
        if k not in S:
            continue
        puestas.add(k)
        s = S[k]
        orig = re.sub(r"^Landrace · ", "", str(s.get("o", "")))
        A("| **%s** | %d | %d %% | %s sem | %d | %s | %s |"
          % (nom(k), s["ind"], s["thc"], str(s["d"]).replace(".", ","), s["r"], orig, ", ".join(vias(k))))
    A("")
resto = [k for k in LAND if k not in puestas]
if resto:
    A("### Las que faltan por colocar")
    A("")
    for k in resto:
        A("- **%s** — %s" % (nom(k), S[k].get("o", "")))
    A("")
A("La Ruderalis va aparte: es landrace de Rusia y Asia central, florece por la edad y de ella salen las "
  "%d autoflorecientes." % len(AUTO["dex"]))
A("")

# ── 2. los árboles ──
A("## 2. Los árboles genealógicos")
A("")
A("Cada variedad que no es landrace, con su linaje hacia atrás hasta las landraces. Cuando tiene más de una "
  "receta, se listan todas (en el juego vale cualquiera).")
A("")
for gen in [1, 2, 3, 4, 5]:
    ks = [k for k in TODAS if k in S and S[k].get("gen") == gen and k not in LAND]
    if not ks:
        continue
    A("### %d.ª generación (%d)" % (gen, len(ks)))
    A("")
    for k in ks:
        s = S[k]
        A("**%s** — ind %d · THC %d %% · flor %s sem · %s" %
          (nom(k), s["ind"], s["thc"], str(s["d"]).replace(".", ","), fam(k)))
        A("")
        A("    " + ("\n    ".join(arbol(k))))
        A("")
        A("> %s" % s.get("o", ""))
        A("")
sin = [k for k in TODAS if k in S and S[k].get("gen") is None and k not in LAND]
if sin:
    A("### Sin generación (landraces aparte)")
    A("")
    for k in sin:
        A("- **%s** — %s" % (nom(k), S[k].get("o", "")))
    A("")

# ── 3. las familias ──
A("## 3. Las familias (el bono de la CannaDex)")
A("")
A("| Familia | Bono | Variedades |")
A("|---|---|---|")
for fk, f in D["FAMILIAS"].items():
    A("| **%s** | %s +%s | %s |" % (f["n"], f["b"], str(f["v"]).replace(".", ","),
                                    ", ".join(nom(x) for x in f["s"])))
A("")

dst = os.path.join(RAIZ, "docs", "GENEALOGIA.md")
open(dst, "w", encoding="utf-8").write("\n".join(L) + "\n")
print("genealogia: %d variedades · %d landraces · %d con receta · %s" %
      (len(TODAS), len(LAND), len(hijos), dst))
