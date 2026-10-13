# python3 -I tools/sprites/a-mano/npc_ojos.py [carpeta]  (Python 3 + Pillow; no va en los scripts de npm)
# Los ojos de la opción C en los personajes (1.21), como los del jugador (player_cara.py): PixelLab les dibujó a cada uno los ojos a
# su manera (de frente, 2 de ancho y 3 de alto, con la pupila de 2 filas; de lado, un borrón). Aquí, en la cabeza de cada dirección
# (base/<dir>/00, la que npc_cara.py pega en cada paso), cada ojo se busca por su blanco (casi blanco, con piel a menos de 2 px) y
# lo oscuro que lo toca (sin lo que toca el contorno de fuera); se borra a piel y se dibuja otra vez desde su fila de arriba:
# · de frente: el párpado de 3 (o de 2 si no cabe: hacia fuera, si es piel; si no, hacia dentro) y debajo blanco, iris y blanco
#   (con 2, el iris hacia dentro), y la fila de abajo de la pupila vieja, a piel;
# · de lado: el párpado de 2 y debajo el blanco detrás y el iris delante.
# Donde no hay blanco que buscar (Iñaki, Molina) o sobra (el brillo del pelo de Josune, las cejas blancas de Patxi), y en los lados
# de Baltasar y Darko, van a mano (1.24, `A_MANO`), donde estaban los ojos viejos. Con gafas (`GAFAS`) se quedan como están. Lee y escribe art/procesado; después, npc_cara.py (pega la cabeza en walk e idle) y
# node tools/sprites/procesar.js --atlas. Repetirlo da lo mismo (el iris `IRIS` marca lo ya dibujado).
import os, sys, colorsys
from collections import Counter
from PIL import Image

RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'art', 'procesado')
GRUPOS = ('baltasar', 'begona', 'cliente1', 'cliente2', 'cliente3', 'cliente4', 'cliente5', 'cliente6', 'cop', 'darko', 'inaki',
          'josune', 'kiko', 'miren', 'molina', 'patxi', 'tono', 'unai')
GAFAS = ('jurado', 'txaro')
CUELLO = .42
BLANCO, IRIS = (244, 244, 244, 255), (92, 58, 40, 255)
A_MANO = {   # de frente: (fila del párpado, x de cada ojo[, lo que vuelve a piel, y su color]); de lado: (fila del párpado, x de los 2)
    'baltasar': {'east': (12, 18), 'west': (12, 12)},
    'darko': {'east': (12, 19), 'west': (12, 12)},
    'inaki': {'south': (13, 12, 17), 'east': (12, 18), 'west': (12, 12)},
    'josune': {'south': (12, 11, 17, ((12, 14), (13, 14), (17, 14), (18, 14)), (232, 176, 136, 255)), 'east': (12, 18), 'west': (12, 12)},
    'molina': {'south': (13, 12, 17), 'east': (13, 18), 'west': (13, 13)},
    'patxi': {'south': (11, 12, 19), 'east': (11, 18), 'west': (12, 13)},
}

def hls(c): return colorsys.rgb_to_hls(*(v / 255 for v in c[:3]))
def piel_de(c): h, l, s = hls(c); return c[3] and .02 <= h <= .12 and .3 <= l <= .85 and s >= .25 and c[0] > c[2] + 30
def blanco(c): h, l, s = hls(c); return c[3] and l >= .88 and (s <= .3 or l >= .95)
def oscuro(c): return c[3] and hls(c)[1] <= .25

def cabeza(im):
    ys = [y for y in range(im.height) if any(im.getpixel((x, y))[3] for x in range(im.width))]
    return ys[0], ys[0] + round((ys[-1] - ys[0] + 1) * CUELLO)

def hecho(im):   # el iris marca lo ya dibujado
    t, c = cabeza(im)
    return any(im.getpixel((x, y)) == IRIS for y in range(t, c) for x in range(im.width))

def a_mano(im, d, m):
    if hecho(im): return 0
    A = (24, 14, 30, 255)
    if d == 'south':
        y, x1, x2 = m[:3]
        for x0 in (x1, x2):
            for i, col in enumerate((BLANCO, IRIS, BLANCO)): im.putpixel((x0 + i, y), A); im.putpixel((x0 + i, y + 1), col)
        for p in (m[3] if len(m) > 3 else ()): im.putpixel(p, m[4])
        return 1
    y, x = m
    for i, col in enumerate((BLANCO, IRIS) if d == 'east' else (IRIS, BLANCO)): im.putpixel((x + i, y), A); im.putpixel((x + i, y + 1), col)
    return 1

def ojos(im, d, F0=None):   # F0: la piel de la cabeza de frente (de lado, el pelo castaño puede pasar por piel)
    t, c = cabeza(im)
    px = lambda x, y: im.getpixel((x, y)) if 0 <= x < im.width and 0 <= y < im.height else (0, 0, 0, 0)
    if hecho(im): return 0
    fuera = lambda x, y: any(not px(x + i, y + j)[3] for i in (-1, 0, 1) for j in (-1, 0, 1))
    bl = [(x, y) for y in range(t, c) for x in range(im.width) if blanco(px(x, y)) and not fuera(x, y)]
    cara = lambda x, y: piel_de(px(x, y)) and (F0 is None or sum(abs(a - b) for a, b in zip(px(x, y)[:3], F0[:3])) < 90)
    A = (24, 14, 30, 255)
    if d == 'south':
        grupos = {}
        for x, y in bl: grupos.setdefault(x, []).append(y)
        if len(grupos) != 2: return 0
        (x1, y1), (x2, y2) = sorted(grupos.items()); cx = (x1 + x2) / 2
        F = Counter(px(x, y) for x in range(x1 + 1, x2) for y in y1 + y2 if cara(x, y)).most_common(1)
        if not F: return 0
        F = F[0][0]
        for wx, ws in ((x1, y1), (x2, y2)):
            fu = -1 if wx < cx else 1; w0, w1 = min(ws), max(ws)
            core = [wx] + ([wx - fu] if oscuro(px(wx - fu, w0)) else [])
            cols = sorted(set(core) | {wx + fu} | ({wx - fu} if len(core) == 1 else set()))
            ly = w0 - 1 if any(oscuro(px(x, w0 - 1)) for x in core) else w0
            for y in range(ly, w1 + 1):
                for x in core:
                    if blanco(px(x, y)) or oscuro(px(x, y)): im.putpixel((x, y), F)
            for x in cols: im.putpixel((x, ly), A)
            for x, col in zip(cols, (BLANCO, IRIS, BLANCO)): im.putpixel((x, ly + 1), col)
        return F
    f = 1 if d == 'east' else -1
    pup = [(x, y) for y in range(t, c) for x in range(im.width) if oscuro(px(x, y)) and not fuera(x, y)
           and (cara(x - 1, y) or blanco(px(x - 1, y))) and (cara(x + 1, y) or blanco(px(x + 1, y)))]
    if not pup: return 0
    y0 = min(y for x, y in pup); x = max((x for x, y in pup if y <= y0 + 1), key=lambda v: f * v)
    y = min(y for xx, y in pup if xx == x)
    F = Counter(px(x + i, y + j) for i in (-2, -1, 1, 2) for j in (0, 1, 2) if cara(x + i, y + j)).most_common(1)[0][0]
    for j in (1, 2):   # lo que quede de la pupila y de su blanco debajo, a piel
        for i in (0, -f):
            if oscuro(px(x + i, y + j)) and not fuera(x + i, y + j) or blanco(px(x + i, y + j)): im.putpixel((x + i, y + j), F)
    for i in (-f, -2 * f):
        if blanco(px(x + i, y)) or blanco(px(x + i, y + 1)): im.putpixel((x + i, y + 1 if blanco(px(x + i, y + 1)) else y), F)
    for p, col in (((x, y), A), ((x - f, y), A), ((x - f, y + 1), BLANCO), ((x, y + 1), IRIS)): im.putpixel(p, col)
    return 1

if __name__ == '__main__':
    for g in GRUPOS:
        ruta = lambda d: os.path.join(RAIZ, g, 'base', d, '00.png')
        if not os.path.exists(ruta('south')): continue
        M = A_MANO.get(g, {})
        im = Image.open(ruta('south')).convert('RGBA'); F0 = a_mano(im, 'south', M['south']) if 'south' in M else ojos(im, 'south')
        if F0: im.save(ruta('south'))
        lados = {d: Image.open(ruta(d)).convert('RGBA') for d in ('east', 'west') if os.path.exists(ruta(d))}
        hechos = {d: a_mano(im, d, M[d]) if d in M else F0 and ojos(im, d, F0) for d, im in lados.items()}
        if lados and all(hechos.values()):   # de lado, los dos o ninguno
            for d, im in lados.items(): im.save(ruta(d))
        print(g, 'frente' if F0 else '-', 'lados' if lados and all(hechos.values()) else '')
