# python3 -I tools/sprites/a-mano/npc_ojos_acc.py [carpeta]  (Python 3 + Pillow y git; no va en los scripts de npm)
# Los ojos de la opción C en las acciones de los NPC (1.25: fumar, el móvil, la pipa…), después de npc_ojos.py: npc_cara.py no las
# toca porque la mano, el cigarro o el humo pasan por delante de la cara, y en cada fotograma PixelLab dibujó la cara a su manera.
# · Por parecido: la cabeza de antes de los ojos nuevos (base/<dir>/00 en `ANTES`, de git) se busca en el fotograma (±4 px, por todo
#   lo que no son los ojos); si casa (`CASA`) y los ojos están abiertos (con blanco donde estaban o, sin blanco, con la mitad de los
#   píxeles de los ojos viejos en su sitio), la franja de la cara de la cabeza de ahora (de 3 filas por encima de los ojos a 1 por
#   debajo) se pega encima, salvo lo que no es de la cabeza (mano, cigarro, humo, móvil: colores que la cabeza no tiene).
# · A mano (`A_MANO`): donde la cabeza no casa (mira al móvil, gira la cara) y los ojos se ven abiertos, celda a celda: A párpado,
#   W blanco, I iris, S piel.
# Los ojos cerrados (al dar una calada, al mirar abajo) y las caras de perfil se quedan como están, y `NO` no se toca.
# Lee y escribe art/procesado; después, node tools/sprites/procesar.js --atlas. Repetirlo da lo mismo (el iris marca lo ya dibujado).
import os, sys, io, subprocess, importlib.util
from collections import Counter
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(AQUI, '..', '..', '..', 'art', 'procesado')
spec = importlib.util.spec_from_file_location('npc_ojos', os.path.join(AQUI, 'npc_ojos.py'))
O = importlib.util.module_from_spec(spec); spec.loader.exec_module(O)
ANTES = '5011fec^'   # la última versión con los ojos de PixelLab en base/<dir>/00
CASA = .55
NO = {'cliente3/movil/south'}
A = (24, 14, 30, 255)
def ojo(y, xs, f): return [(x, y, 'A') for x in xs] + [(x, y + 1, c) for x, c in zip(xs, f)]
def frente(y, x1, x2): return ojo(y, range(x1, x1 + 3), 'WIW') + ojo(y, range(x2, x2 + 3), 'WIW')
A_MANO = {
    'cliente1/movil/south': {'05': frente(12, 12, 18)},
    'cliente3/movil/south': {'01': frente(15, 13, 18), '02': frente(15, 13, 18), '03': frente(15, 13, 18),
                             '04': frente(14, 13, 18), '05': frente(13, 13, 18)},
    'inaki/cabo/west': {'01': ojo(12, (14, 15), 'IW'), **{f'0{i}': ojo(12, (15, 16), 'IW') for i in range(2, 8)}},
    'josune/secar_vaso/south': {'01': frente(14, 11, 17) + [(16, 14, 'S'), (20, 14, 'S'), (16, 15, 'S')]},
    'josune/servir/south': {'03': ojo(13, (11, 12), 'IW') + ojo(13, (14, 15), 'IW') + [(11, 15, 'S'), (14, 15, 'S'), (15, 15, 'S')]},
    'molina/fumar/south': {'00': frente(13, 12, 17), '01': frente(12, 12, 17), '03': frente(11, 12, 17), '04': frente(11, 12, 17),
                           '02': frente(10, 12, 17) + [(x, 12, 'S') for x in (12, 13, 14, 17, 18, 19)]},
}

def abre(f): return Image.open(f).convert('RGBA')
def git(ruta):
    r = subprocess.run(['git', 'show', f'{ANTES}:ribera-verde/art/procesado/{ruta}'], cwd=AQUI, capture_output=True)
    return Image.open(io.BytesIO(r.stdout)).convert('RGBA') if r.returncode == 0 else None

def piel(F, ys):   # la piel más común de la cara en esas filas
    c = Counter(F.getpixel((x, y)) for y in ys for x in range(F.width) if 0 <= y < F.height and O.piel_de(F.getpixel((x, y))))
    return c.most_common(1)[0][0]

def a_mano(F, celdas):
    S = piel(F, range(min(y for x, y, c in celdas) - 1, max(y for x, y, c in celdas) + 3))
    for x, y, c in celdas: F.putpixel((x, y), {'A': A, 'W': O.BLANCO, 'I': O.IRIS, 'S': S}[c])

def parecido(F, old, new):
    D = [(x, y) for y in range(old.height) for x in range(old.width) if old.getpixel((x, y)) != new.getpixel((x, y))]
    if not D: return 0   # de espaldas
    xs = [x for x, y in D]; ys = [y for x, y in D]
    E = {(x, y) for y in range(min(ys) - 1, max(ys) + 2) for x in range(min(xs) - 1, max(xs) + 2)}
    t, c = O.cabeza(old)
    pal = {im.getpixel((x, y)) for im in (old, new) for y in range(t, c) for x in range(old.width) if im.getpixel((x, y))[3]}
    H = [(x, y) for y in range(t, c) for x in range(old.width) if old.getpixel((x, y))[3] and (x, y) not in E]
    px = lambda x, y: F.getpixel((x, y)) if 0 <= x < F.width and 0 <= y < F.height else (0, 0, 0, 0)
    dx, dy = max(((i, j) for i in range(-4, 5) for j in range(-4, 5)),
                 key=lambda k: (sum(px(x + k[0], y + k[1]) == old.getpixel((x, y)) for x, y in H), -abs(k[0]) - abs(k[1])))
    if sum(px(x + dx, y + dy) == old.getpixel((x, y)) for x, y in H) / len(H) < CASA: return 0
    if any(O.blanco(old.getpixel(p)) for p in D): abierto = any(O.blanco(px(x + dx, y + dy)) for x, y in E)
    else: abierto = sum(px(x + dx, y + dy) == old.getpixel((x, y)) for x, y in D) / len(D) >= .3
    if not abierto: return 0
    for y in range(max(t, min(ys) - 3), max(ys) + 2):
        for x in range(old.width):
            q = (x + dx, y + dy); fp = px(*q); np = new.getpixel((x, y))
            if not (0 <= q[0] < F.width and 0 <= q[1] < F.height) or fp == np or (fp[3] and fp not in pal) or (not fp[3] and not np[3]): continue
            F.putpixel(q, np)
    return 1

if __name__ == '__main__':
    for g in O.GRUPOS:
        if not os.path.isdir(os.path.join(RAIZ, g)): continue
        for a in sorted(os.listdir(os.path.join(RAIZ, g))):
            if a in ('base', 'idle', 'walk') or not os.path.isdir(os.path.join(RAIZ, g, a)): continue
            for d in sorted(os.listdir(os.path.join(RAIZ, g, a))):
                k = f'{g}/{a}/{d}'; old = git(f'{g}/base/{d}/00.png')
                if old is None: continue
                new = abre(os.path.join(RAIZ, g, 'base', d, '00.png')); M = A_MANO.get(k, {}); r = []
                for f in sorted(os.listdir(os.path.join(RAIZ, g, a, d))):
                    if not f.endswith('.png'): continue
                    p = os.path.join(RAIZ, g, a, d, f); F = abre(p)
                    if any(O.IRIS == F.getpixel((x, y)) for y in range(F.height) for x in range(F.width)): r.append(f[:2] + '='); continue
                    if f[:2] in M: a_mano(F, M[f[:2]]); hecho = 'm'
                    elif k not in NO and parecido(F, old, new): hecho = 'p'
                    else: hecho = ''
                    if hecho: F.save(p); r.append(f[:2] + hecho)
                print(k, ' '.join(r))
