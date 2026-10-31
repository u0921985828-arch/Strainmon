# Los combates, más realistas (lo pidió el usuario: «Habría que mejorar los sprites de los combates, que realmente sean más
# realistas»): cada luchador sale de PixelLab con unas 6 cabezas de alto (create_image_pro de frente con la pose y el estilo del
# protagonista nuevo → create_character v3 → animate_character v3 con las mismas animaciones y fotogramas que el de siempre) y va en
# su grupo «<grupo>-combate-r», que solo se usa con Datos.CAL (grupo_combate en policia.gd): el de siempre se queda para el oráculo.
# Entrada: art/crudo/<grupo>-combate-r/<anim>/<dir>/<NN>.png, lo bajado de PixelLab tal cual. Aquí se pasa a la paleta del grupo (el
# protagonista y la protagonista, a los 15 colores del player-combate, que son los que ROPA cambia; los demás, a 15 colores por
# grupo), se quitan los píxeles sueltos y se encaja en la celda de combate (64 × 64, los pies en la fila 62 y el centro en la
# columna 32; un desplazamiento por animación, el de su primer fotograma, como procesar.js) en art/procesado/<grupo>-combate-r.
# Después: node tools/sprites/procesar.js --atlas --atlas-dir godot/arte
import colorsys
from collections import Counter
import glob
import os
import sys
from PIL import Image

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
W = H = 64
ANCLA = (32, 62)
hx = lambda s: tuple(int(s[i:i + 2], 16) for i in (1, 3, 5))
# los 15 del player-combate: contorno, camiseta (ROPA: clara y sombra), vaquero (claro y oscuro), gorra (3), pelo (2), piel (3),
# zapatillas (blanco y gris)
PJ = {'contorno': ['#180e1e'], 'camiseta': ['#c83839', '#a03031'], 'vaquero': ['#385897', '#24345d'],
      'gorra': ['#5aa861', '#3f8a47', '#2a6a41'], 'pelo': ['#483e37', '#2a2031'], 'piel': ['#e8b088', '#c49464', '#a8805a'],
      'zapa': ['#f4f4f4', '#3c444e']}
PAL_PJ = {'player': PJ, 'player-f': PJ}
TOPE = 15
EXTRA = 5

def dist(a, b):   # «redmean»: lo bastante perceptual para elegir entre pocos colores
    r = (a[0] + b[0]) / 2
    d = [a[i] - b[i] for i in range(3)]
    return (2 + r / 256) * d[0] ** 2 + 4 * d[1] ** 2 + (2 + (255 - r) / 256) * d[2] ** 2

def material(c):   # de qué es un color de PixelLab, por su tono: así la camiseta no cae en la piel ni el vaquero en el pelo
    h, s, v = colorsys.rgb_to_hsv(*[x / 255 for x in c])
    if v < .2:
        return 'contorno'
    if s < .16:
        return 'zapa'
    h *= 360
    if (h < 14 or h > 260) and v < .3:   # el pelo oscuro de PixelLab tira a granate o a morado
        return 'pelo'
    if (h < 14 or h > 340) and s > .45:
        return 'camiseta'
    if 14 <= h < 45:
        return 'piel' if v > .55 and s < .62 else 'pelo'
    if 70 <= h < 170:
        return 'gorra'
    if 190 <= h < 260:
        return 'vaquero'
    return None

def a_pj(c, pal, pie=False):
    m = material(c)
    if m == 'gorra' and pie:   # las suelas verdes (PixelLab las pinta del color de la gorra): zapatillas, que ROPA no cambia
        m = 'zapa'
    cand = [hx(x) for x in pal[m]] if m else [hx(x) for k in pal for x in pal[k] if not (pie and k == 'gorra')]
    return min(cand, key=lambda p: dist(p, c))

def paleta_grupo(ims):   # los demás: 15 colores para todos los fotogramas del grupo a la vez (como un sprite de GBA): 10 por
    px = [p[:3] for im in ims for p in im.get_flattened_data() if p[3] >= 128]   # MEDIANCUT y 5, uno a uno, los que más error
    tira = Image.new('RGB', (len(px), 1))   # quitan (MEDIANCUT solo se comía el blanco de las zapatillas y la camisa del policía)
    tira.putdata(px)
    q = tira.quantize(TOPE - EXTRA, method=Image.Quantize.MEDIANCUT)
    p = q.getpalette()[:(TOPE - EXTRA) * 3]
    pal = [tuple(p[i:i + 3]) for i in range(0, len(p), 3)]
    cnt = Counter(px)
    for _ in range(EXTRA):
        err = {c: min(dist(q, c) for q in pal) for c in cnt}
        pal.append(max(cnt, key=lambda c: sum(n * max(0, err[x] - dist(x, c)) for x, n in cnt.items())))
    return pal

def a_paleta(im, f, pie=None):   # pie(x, y): ahí no hay gorra (de pie, la mitad de abajo; tumbado, la de los pies)
    o = Image.new('RGBA', im.size, (0, 0, 0, 0))
    src, dst = im.load(), o.load()
    cache = {}
    for y in range(im.height):
        for x in range(im.width):
            p = src[x, y]
            if p[3] < 128:
                continue
            k = (p[:3], pie is not None and pie(x, y))
            if k not in cache:
                cache[k] = f(*k)
            dst[x, y] = cache[k] + (255,)
    return o

def sin_sueltos(im):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] and not any(0 <= x + dx < im.width and 0 <= y + dy < im.height and px[x + dx, y + dy][3]
                                       for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy):
                px[x, y] = (0, 0, 0, 0)
    return im

def encaja(ims):   # el desplazamiento del primer fotograma; si así algo se sale, el de la caja de todos
    def off(b):
        return ANCLA[0] - (b[0] + b[2]) // 2, ANCLA[1] - (b[3] - 1)
    cajas = [im.getbbox() for im in ims]
    cabe = lambda o: all(b[0] + o[0] >= 0 and b[1] + o[1] >= 0 and b[2] + o[0] <= W and b[3] + o[1] <= H for b in cajas if b)
    o = off(cajas[0])
    if not cabe(o):
        u = [min(b[0] for b in cajas), min(b[1] for b in cajas), max(b[2] for b in cajas), max(b[3] for b in cajas)]
        o = off(u) if cabe(off(u)) else (off(u)[0], H - u[3])
    sale = []
    for im in ims:   # paste recorta lo que se sale de la celda
        c = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        c.paste(im, o, im)
        sale.append(c)
    return sale

def grupo(g):
    base = os.path.join(R, 'art', 'crudo', g + '-combate-r')
    seqs = {}
    for f in sorted(glob.glob(os.path.join(base, '*', '*', '*.png'))):
        a, d = f.split(os.sep)[-3:-1]
        seqs.setdefault((a, d), []).append(Image.open(f).convert('RGBA'))
    if not seqs:
        print(g, 'sin crudo')
        return
    if g in PAL_PJ:
        f = lambda c, pie: a_pj(c, PAL_PJ[g], pie)
    else:
        pal = paleta_grupo([im for v in seqs.values() for im in v])
        f = lambda c, pie: min(pal, key=lambda p: dist(p, c))
    colores = set()
    for (a, d), ims in seqs.items():
        b0 = ims[0].getbbox()
        def pie(im):   # de pie, por debajo de la cintura; tumbado (menos de 0,6 del alto de pie), la mitad de abajo del lado
            b = im.getbbox()   # contrario a la cabeza (la gorra va en la columna más alta)
            if g not in PAL_PJ or not b:
                return None
            if b[3] - b[1] >= .6 * (b0[3] - b0[1]):
                return lambda x, y: y >= (b0[1] + b0[3]) // 2
            px = im.load()
            top = next(x for y in range(b[1], b[3]) for x in range(b[0], b[2]) if px[x, y][3] >= 128)
            cx, cy = (b[0] + b[2]) // 2, (b[1] + b[3]) // 2
            return lambda x, y: y >= cy and (x < cx) == (top >= cx)
        ims = [sin_sueltos(a_paleta(im, f, pie(im))) for im in ims]
        out = os.path.join(R, 'art', 'procesado', g + '-combate-r', a, d)
        os.makedirs(out, exist_ok=True)
        for n in os.listdir(out):
            os.remove(os.path.join(out, n))
        for i, im in enumerate(encaja(ims)):
            im.save(os.path.join(out, '%02d.png' % i))
            colores |= {p[:3] for p in im.get_flattened_data() if p[3]}
    print(g + '-combate-r', len(seqs), 'animaciones,', len(colores), 'colores')

for g in sys.argv[1:] or ['player', 'player-f', 'ladron1', 'ladron2', 'ladron3', 'darko', 'policia']:
    grupo(g)
