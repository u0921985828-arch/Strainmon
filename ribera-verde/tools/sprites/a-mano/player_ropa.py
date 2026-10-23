# python3 -I tools/sprites/a-mano/player_ropa.py [carpeta]  (Python 3 + Pillow; no va en los scripts de npm)
# La ropa del jugador con colores propios (1.22, revisión de la 1.21): PixelLab pintó la gorra con los verdes de las zapatillas (y de la
# regadera y la planta de algunas acciones), la camiseta con el rojo de la regadera y, en el combate, el pelo con el oscuro de los
# hombros y los pies. `ROPA` (12c-salon) cambia colores exactos, así que cada pieza pasa a sus propios tonos (`VARIANTE`: 1 de azul
# más; no se nota), solo en sus píxeles: las manchas (8 vecinos) de sus colores que son la pieza:
# · gorra y pelo, las que tienen el centro en la cabeza (el 45 % de arriba del dibujo);
# · camiseta, la mayor y las que no quedan por debajo de ella;
# · pantalón, la mayor y las que no quedan por encima de ella.
# Las variantes no salían en ninguno de los dos grupos antes de pasarlo (comprobado al escribirlo).
# Lo demás (zapatillas, regadera, planta) se queda con el color de antes y no cambia con la ropa. Va después de player_cara.py y de
# player_pelo.py (el pelo del player ya tiene sus tonos); repetirlo da lo mismo (las manchas se miden con los dos tonos). Después,
# node tools/sprites/procesar.js --atlas.
import os, sys, glob
from PIL import Image

RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'art', 'procesado')
h = lambda s: tuple(int(s[i:i + 2], 16) for i in (1, 3, 5))
PIEZAS = {   # grupo → pieza → colores de antes (en `ROPA.src`, ya con su variante)
    'player': {'camiseta': ['#c83838', '#a03030'], 'pantalon': ['#6c7482', '#36466e'], 'gorra': ['#5aa860', '#2a8a5a']},
    'player-combate': {'camiseta': ['#c83838', '#a03030'], 'pantalon': ['#385896', '#24345c'], 'gorra': ['#5aa860', '#3f8a46', '#2a6a40'],
                       'pelo': ['#483e36', '#2a2030']},
}
VARIANTE = lambda c: (c[0], c[1], c[2] + 1 if c[2] < 255 else c[2] - 1)
CABEZA = .45

def manchas(px, W, H, cs):
    vistos, out = set(), []
    for y in range(H):
        for x in range(W):
            if (x, y) in vistos or not px[x, y][3] or px[x, y][:3] not in cs: continue
            pila, m = [(x, y)], []; vistos.add((x, y))
            while pila:
                a, b = pila.pop(); m.append((a, b))
                for i in (-1, 0, 1):
                    for j in (-1, 0, 1):
                        u, v = a + i, b + j
                        if 0 <= u < W and 0 <= v < H and (u, v) not in vistos and px[u, v][3] and px[u, v][:3] in cs:
                            vistos.add((u, v)); pila.append((u, v))
            out.append(m)
    return sorted(out, key=len, reverse=True)

def pieza(k, ms, t, b):
    if not ms: return []
    cy = lambda m: sum(y for x, y in m) / len(m)
    if k in ('gorra', 'pelo'): return [m for m in ms if cy(m) < t + (b - t + 1) * CABEZA]
    y0, y1 = min(y for x, y in ms[0]), max(y for x, y in ms[0])
    if k == 'camiseta': return [ms[0]] + [m for m in ms[1:] if cy(m) <= y1]
    return [ms[0]] + [m for m in ms[1:] if cy(m) >= y0]

if __name__ == '__main__':
    for g, P in PIEZAS.items():
        n = 0
        for f in sorted(glob.glob(os.path.join(RAIZ, g, '*', '*', '*.png'))):
            im = Image.open(f).convert('RGBA'); px = im.load(); W, H = im.size
            ys = [y for y in range(H) if any(px[x, y][3] for x in range(W))]
            if not ys: continue
            t, b = ys[0], ys[-1]; cambia = 0
            for k, cols in P.items():
                antes = {h(c) for c in cols}; tb = {c: VARIANTE(c) for c in antes}
                for m in pieza(k, manchas(px, W, H, antes | set(tb.values())), t, b):
                    for x, y in m:
                        if px[x, y][:3] in tb: px[x, y] = tb[px[x, y][:3]] + (px[x, y][3],); cambia += 1
            if cambia: im.save(f); n += 1
        print(g, n, 'fotogramas')
