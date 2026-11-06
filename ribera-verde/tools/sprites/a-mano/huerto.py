# python3 -I tools/sprites/a-mano/huerto.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.57.2 (lo pidió el usuario: «no tienen el contorno para cerrar el diseño. No son del mismo estilo que los sprites… de la carretera
# como la acera»): las plantas del bancal de exterior de la carga y el título, dibujadas a mano como el árbol y el seto de la calle
# (contorno verde muy oscuro, tres tonos por material, luz de arriba a la izquierda) y a 16 px/m: la plántula de 20 cm, la de 50 cm,
# el arbusto de 1 m, la floración de 1,4 m con los pistilos blancos y la madura de 1,6 m con los pistilos naranjas y las hojas de
# abajo amarillas. Tres variedades: la índica (baja, ancha, verde oscuro), la sativa (alta, estrecha, verde claro) y la híbrida
# (con el morado en los cogollos). Ni marcas ni nombres.
#  · huerto-pl (mueble_escala, 32 × 48, pies en (16, 47)): hp<variedad 0-2>-<fase 1-5>
# Sale a art/crudo/huerto-pl/<sprite>/unica/00.png (después, node tools/sprites/procesar.js huerto-pl --atlas --atlas-dir godot/arte)
import os, sys, glob, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

import prim, planta_a
PA = {'O': '#0d2620', 'D': '#1b4630', 'M': '#2f7038', 'L': '#57a33e', 'H': '#94d255', 'T': '#71984a', 'S': '#3b5a2e',   # los de
      'F': '#f2f4dc', 'N': '#f08a3c'}                                                                                  # exporta.py

# la hoja de abanico de la vista C (prim.hoja) en pequeño: 5 o 7 foliolos, cada pieza con su contorno, como las de casa
VAR = [  # (ind, foliolos, ancho del foliolo), alto por fase (px, 16 px/m), ancho por fase, cogollo (claro, medio, oscuro)
    (.9, 7, 1.4, (3, 8, 14, 20, 22), (7, 11, 17, 19, 20), ('#a8d080', '#7aa858', '#4e7a3a')),
    (.1, 9, 1.1, (4, 9, 18, 26, 28), (6, 9, 13, 15, 16), ('#cce49a', '#9ac070', '#6a9048')),
    (.5, 7, 1.3, (3, 8, 16, 23, 25), (7, 10, 15, 17, 18), ('#b48ad0', '#8a5aae', '#5a3a7a')),
]
AMA = {'L': '#c8b040', 'M': '#a08a2a', 'H': '#e0d070', 'D': '#7a6a20'}
AMC = {'L': 'y', 'M': 'z', 'H': 'w', 'D': 'v'}   # un carácter por color en la rejilla   # las de abajo, amarillas en la madura

def planta(v, f):
    ind, nf, anc, alto, ancho, CB = VAR[v]
    H, W = alto[f - 1], ancho[f - 1]
    G = planta_a.Lienzo(H, W + 2, ind); put, pieza = G.put, G.pieza
    sx = (W + 2) // 2
    def hj(L, giro, x, y, osc=False, ama=False, n=None):
        hp = prim.hoja(n or nf, L, anc, 95, 1.5, round(giro), 1)
        for (dx, dy), c in hp.items():   # sin el contorno entre foliolos: a este tamaño, el abanico se lee por la silueta
            if c == 'O': continue
            put(x + dx, y + dy, (AMC[c] if ama and c in AMC else planta_a.OSC.get(c, c) if osc else c))
    if f == 1:   # la plántula: el tallito y el primer par de hojas de tres
        for yy in range(H - 2, H): put(sx, yy, 'T')
        hj(2, -60, sx - 1, H - 2, n=3); hj(2, 60, sx + 1, H - 2, n=3)
        return G
    tallo = 2 if f == 2 else 3
    hub = H - tallo
    for yy in range(0, H): put(sx, yy, 'S' if yy < hub else 'T')
    paso = 3 if f == 2 else 4 if ind >= .5 else 5
    nud = list(range(hub, 2, -paso))
    for k, y in enumerate(nud):                       # de abajo arriba; las de abajo, detrás y en sombra
        t = (hub - y) / max(1, hub)
        Lh = max(2, round((W / 2 - 1) * (1 - .45 * t)))
        d = 1 if k % 2 else -1
        ama = f == 5 and k == 0
        hj(Lh, -78, sx - 1, y, osc=k == 0, ama=ama); hj(Lh, 78, sx + 1, y, osc=k == 0, ama=ama)
        if f >= 3 and k > 0: hj(max(2, Lh - 2), d * 25, sx + d, y - 1)   # la del nudo de delante
    hj(max(2, min(4, H // 6)), 0, sx, 2)              # la punta
    if f >= 4:   # las colas: la de arriba y una en cada nudo, con los pistilos
        def cola(x, y0, n, w):
            pz = {}
            for j in range(n):
                for i in range(w):
                    pz[(x + i, y0 + j)] = 'P' if (i + j) % 3 == 0 else 'Q' if i < w - 1 else 'R'
                if j % 2 == 0: pz[(x + (j // 2) % w, y0 + j)] = 'F' if f == 4 else 'N'
            pieza(pz)
        cola(sx - 1, 0, 6 if f == 4 else 8, 2 if ind < .5 else 3)
        for k, y in enumerate(nud[1:-1]):
            cola(sx - 4 if k % 2 == 0 else sx + 2, y - 3, 3, 2)
    return G

def pinta(G, v):
    filas = G.fin(False)
    ind, nf, anc, alto, ancho, CB = VAR[v]
    col = dict(PA); col.update({'P': CB[0], 'Q': CB[1], 'R': CB[2]}); col.update({AMC[k]: c for k, c in AMA.items()})
    L = Lienzo(32, 48)
    x0 = 16 - (len(filas[0]) // 2); y0 = 48 - len(filas)
    for y, r in enumerate(filas):
        for x, c in enumerate(r):
            if c in col: L.p(x0 + x, y0 + y, col[c])
    return L

SAL = {}
for v in range(len(VAR)):
    for f in range(1, 6):
        SAL[f'hp{v}-{f}'] = pinta(planta(v, f), v)

def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'huerto-pl', n, 'unica'); os.makedirs(d, exist_ok=True)
        for x in glob.glob(os.path.join(d, '*.png')): os.remove(x)
        L.im.save(os.path.join(d, '00.png'))
        print('huerto-pl', n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
