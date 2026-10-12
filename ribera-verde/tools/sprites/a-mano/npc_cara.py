# python3 -I tools/sprites/a-mano/npc_cara.py [carpeta]  (Python 3 + Pillow; no va en los scripts de npm)
# Los personajes por partes (1.12), como el jugador (player_cara.py): PixelLab dibujó cada fotograma del idle y de andar con su
# cara (los ojos, la boca y el pelo cambiaban en cada uno: la cara «mutaba») y el idle de cada uno era otra postura (el «ictus»).
# Aquí la cabeza de cada personaje sale de una sola pieza por dirección, la de base/<dir>/00 (de la coronilla a CUELLO de su alto),
# y el cuerpo, de cada fotograma:
# · idle/<dir>: la postura de base respirando (en la segunda mitad, la cabeza 1 px más abajo, sobre el cuello), como el jugador;
# · walk/<dir>: el cuerpo de cada paso con la cabeza de base pegada encima, en la fila y la columna en que casa con la de ese paso
#   (la cabeza sube y baja con el cuerpo, sin bailar de lado).
# Los de combate (más grandes, con su propia cara de cerca), las palomas y las gaviotas se quedan como están. Lee y escribe
# art/procesado (repetirlo da lo mismo); después, node tools/sprites/procesar.js --atlas. Si se vuelve a procesar un grupo desde
# art/crudo, hay que pasar otra vez este script.
import os, sys, glob
from PIL import Image

RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'art', 'procesado')
GRUPOS = ('baltasar', 'begona', 'cliente1', 'cliente2', 'cliente3', 'cliente4', 'cliente5', 'cliente6', 'cop', 'darko', 'inaki',
          'josune', 'jurado', 'kiko', 'molina', 'patxi', 'tono', 'txaro', 'unai')
CUELLO = .42   # la cabeza: la parte de arriba del personaje, hasta este tanto de su alto

def abre(f): return Image.open(f).convert('RGBA')

def alto(im):   # primera y última fila con algo
    ys = [y for y in range(im.height) if any(im.getpixel((x, y))[3] for x in range(im.width))]
    return ys[0], ys[-1]

def pieza(im):   # la cabeza: {(x, y): color} de la coronilla (y = 0) a la fila del cuello, y esa fila (absoluta)
    t, b = alto(im); c = t + round((b - t + 1) * CUELLO)
    return {(x, y - t): im.getpixel((x, y)) for y in range(t, c) for x in range(im.width) if im.getpixel((x, y))[3]}, c - t

def respira(g, d, base):   # idle: base en la primera mitad; en la segunda, la cabeza 1 px más abajo (sobre la primera fila del cuerpo)
    fs = sorted(glob.glob(os.path.join(RAIZ, g, 'idle', d, '*.png')))
    t, b = alto(base); s = t + round((b - t + 1) * CUELLO); baja = base.copy()
    for y in range(s, 0, -1):
        for x in range(base.width):
            if y < s or base.getpixel((x, y - 1))[3]: baja.putpixel((x, y), base.getpixel((x, y - 1)))
    for x in range(base.width): baja.putpixel((x, 0), (0, 0, 0, 0))
    for i, f in enumerate(fs): (baja if i >= len(fs) // 2 else base).save(f)
    return len(fs)

def pega(f, T, h):   # la cabeza T (h filas) en el paso f: donde más casa con la que ya tiene (±3 px) y encima de lo que había
    im = abre(f); t, b = alto(im)
    vieja = {(x, y) for y in range(max(0, t - 3), min(im.height, t + h + 3)) for x in range(im.width) if im.getpixel((x, y))[3]}
    def casa(k):   # lo que coincide menos la mitad de lo que no, en las filas de la cabeza
        dx, dy = k; P = {(x + dx, y + t + dy) for x, y in T}; V = {(x, y) for x, y in vieja if t + dy <= y < t + dy + h}
        return (len(P & V) - len(P ^ V) / 2, -abs(dx) - abs(dy))
    dx, dy = max(((a, c) for a in range(-3, 4) for c in range(-1, 2)), key=casa)
    xs = [x + dx for x, y in T]
    for y in range(max(0, t + dy), min(im.height, t + dy + h)):
        for x in range(max(0, min(xs) - 1), min(im.width, max(xs) + 2)): im.putpixel((x, y), (0, 0, 0, 0))
    for (x, y), c in T.items():
        if 0 <= x + dx < im.width and 0 <= y + t + dy < im.height: im.putpixel((x + dx, y + t + dy), c)
    im.save(f)
    return dx, dy

for g in GRUPOS:
    for d in ('south', 'east', 'north', 'west'):
        bf = os.path.join(RAIZ, g, 'base', d, '00.png')
        if not os.path.exists(bf): continue
        base = abre(bf); T, h = pieza(base); r = []
        ws = sorted(glob.glob(os.path.join(RAIZ, g, 'walk', d, '*.png')))
        if ws: r.append(('walk', [pega(f, T, h) for f in ws]))
        if os.path.isdir(os.path.join(RAIZ, g, 'idle', d)): r.append(('idle', respira(g, d, base)))
        if r: print(g, d, r)
