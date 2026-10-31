# python3 -I tools/sprites/a-mano/puertas_altas.py   (Python 3 + Pillow; edita art/procesado —y art/crudo donde es la misma imagen—;
# después, node tools/sprites/procesar.js <grupo> --atlas --atlas-dir godot/arte; tras volver a procesar una puerta, pásalo otra vez)
# Las puertas de la calle, a la medida del protagonista (lo pidió el usuario: «la puerta es demasiado pequeña para el personaje»):
# y «tiene que entrar perfecto el personaje en la puerta»): a 16 px/m el protagonista mide 27 px (1,70 m) y 16 de ancho; había
# puertas de 18 a 26 px de alto y huecos de 9. Cada puerta (edificio-*/puerta, sus 4 fotogramas) sube y se ensancha hasta el hueco
# HX0..HX1 × HY0..31, donde cabe entero de espaldas, repitiendo la fila y la columna de su hoja que más se parecen a su vecina (sin
# dibujar nada nuevo: misma paleta). Donde encima de la puerta hay un rótulo en la planta
# baja (el bar, el club del Ensanche, GAUA), la fachada entera sube con ella: se repite la misma fila en la fachada y en la puerta y se
# pierden otras tantas del tejado. Se puede volver a pasar: lo que ya mide lo pedido no se toca.
import json, os
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
PROC = os.path.join(ROOT, 'art/procesado')
CRUDO = os.path.join(ROOT, 'art/crudo')
MARCO = 4                     # px de marco a cada lado del hueco
# el hueco abierto, en px del sprite de la puerta (32 × 32, dibujado en doorX·16 − 8): el protagonista (16 px de ancho, de la columna
# 8 a la 23 de la puerta y, de espaldas, de la fila 1 a la 31; en las de 2 casillas entra por el medio, _dx_ancha en pinta.gd) con
# 1 px de aire a cada lado
HX0, HX1 = 7, 24
HY0 = 1
# las de una casilla que estaban corridas (dx): su dibujo se corre dentro del sprite y su dx pasa a 0 (datos.json), en el mismo sitio
CORRE = {'casco-pu': -8}   # las de locales.py ya se recortan en su sitio (dx 0): solo queda la del casco
FACHADA = {'bar': 'bar', 'club-ensanche': 'club-ensanche', 'disco': 'disco', 'club-itsaso': 'club-itsaso', 'club-fundicion': 'club-fundicion'}
# la puerta corredera de la nave se abría solo a medias (la hoja tapaba al protagonista): abierta, del todo
ABRE = {'nave'}
# la del casco (el taller y el estanco de Ibarbide) va en la última casilla de su fachada: lo que se sale de ella (la jamba derecha,
# desde la columna 24 del sprite), fuera; la esquina de la casa hace de jamba
RECORTA = {'casco-pu': 24}

def lee(k):
    return Image.open(os.path.join(PROC, k + '.png')).convert('RGBA')

def guarda(k, im):
    # en procesado y, si el crudo era la misma imagen, también en el crudo (así volver a procesar no lo deshace)
    pc = os.path.join(CRUDO, k + '.png')
    if os.path.exists(pc) and Image.open(pc).convert('RGBA').tobytes() == lee(k).tobytes():
        im.save(pc)
    im.save(os.path.join(PROC, k + '.png'))

def hueco(fs):
    # lo que cambia de la cerrada a cualquiera de las otras (la hoja que se abre también es del hueco)
    a = fs[0].load()
    xs, ys = [], []
    for f in fs[1:]:
        o = f.load()
        for y in range(fs[0].height):
            for x in range(fs[0].width):
                if a[x, y] != o[x, y]:
                    xs.append(x)
                    ys.append(y)
    return min(xs), max(xs), min(ys), max(ys)

def abre(f, fs):
    # la abierta del todo: la hoja corredera (la nave) se va entera detrás de la pared; lo que queda de ella, del oscuro del hueco
    x0, x1, y0, y1 = hueco(fs)
    a, o = fs[0].load(), f.load()
    ox = [x for y in range(y0, y1 + 1) for x in range(x0, x1 + 1) if a[x, y] != o[x, y]]
    from collections import Counter
    osc = Counter(o[x, y] for y in range(y0, y1 + 1) for x in range(x0, x1 + 1) if a[x, y] != o[x, y]).most_common(1)[0][0]
    out = f.copy()
    p = out.load()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            p[x, y] = osc
    return out

def dif(im, y0, y1, x0, x1):
    p = im.load()
    return sum(sum(abs(p[x, y0][i] - p[x, y1][i]) for i in range(4)) for x in range(x0, x1))

def fila_rep(im, ya, yb, x0, x1):
    # la fila de la hoja (ya..yb) más parecida a la de debajo: repetirla no deja costura
    return min(range(ya, yb), key=lambda y: (dif(im, y, y + 1, x0, x1), -y))

def sube(im, r, n, x0=0, x1=None):
    # repite n veces la fila r en las columnas x0..x1: lo de encima sube n filas (se pierden las n de arriba)
    x1 = im.width - 1 if x1 is None else x1
    out = im.copy()
    out.paste(im.crop((x0, n, x1 + 1, r + 1)), (x0, 0))
    for k in range(n):
        out.paste(im.crop((x0, r, x1 + 1, r + 1)), (x0, r - k))
    return out

def ensancha(im, c, n, x0, x1, der=False):
    # dentro de las columnas x0..x1 (la puerta con su marco), repite n veces la columna c, la mitad a cada lado
    iz = 0 if der else n // 2
    de = n - iz
    out = im.copy()
    b = im.crop((x0, 0, x1 + 1, im.height))
    w = b.width + n
    nb = Image.new('RGBA', (w, im.height))
    cc = c - x0
    nb.paste(b.crop((0, 0, cc + 1, im.height)), (0, 0))
    for k in range(n):
        nb.paste(b.crop((cc, 0, cc + 1, im.height)), (cc + 1 + k, 0))
    nb.paste(b.crop((cc + 1, 0, b.width, im.height)), (cc + 1 + n, 0))
    out.paste(nb, (x0 - iz, 0))
    return out

def corre(im, d):
    # el dibujo d px a la derecha (a la izquierda si d < 0); lo que entra, transparente
    out = Image.new('RGBA', im.size)
    out.paste(im, (d, 0))
    return out

def bloque(f, x0, x1, c, w, m0, m1, nx0):
    # el hueco con su marco (m0..m1), ensanchado w px repitiendo la columna c, pegado con el hueco desde nx0
    b = f.crop((m0, 0, m1 + 1, f.height))
    cc = c - m0
    nb = Image.new('RGBA', (b.width + w, f.height))
    nb.paste(b.crop((0, 0, cc + 1, f.height)), (0, 0))
    for k in range(w):
        nb.paste(b.crop((cc, 0, cc + 1, f.height)), (cc + 1 + k, 0))
    nb.paste(b.crop((cc + 1, 0, b.width, f.height)), (cc + 1 + w, 0))
    out = f.copy()
    out.paste(nb, (nx0 - (x0 - m0), 0))
    return out

def datos_dx():
    # el dx de las puertas de CORRE, a 0 (lo que se corrió en el sprite)
    pd = os.path.join(ROOT, 'godot/datos/datos.json')
    d = json.load(open(pd))
    n = 0
    def mira(o):
        nonlocal n
        if isinstance(o, dict):
            if isinstance(o.get('puerta'), str) and o['puerta'] in CORRE and o.get('dx', 0) == CORRE[o['puerta']] and not o.get('ancha'):
                o['dx'] = 0
                n += 1
            for v in o.values():
                mira(v)
        elif isinstance(o, list):
            for v in o:
                mira(v)
    mira(d)
    if n:
        open(pd, 'w').write(json.dumps(d, ensure_ascii=False, separators=(',', ':')))
    return n

def main():
    d = json.load(open(os.path.join(ROOT, 'godot/arte/atlas.json')))
    bl = json.load(open(os.path.join(ROOT, 'godot/datos/datos.json')))['MAPS']
    hecho = []
    corridas = datos_dx() == 0   # si ya estaban a 0 en los datos, sus sprites ya se corrieron
    for g, an in d['anims'].items():
        if not g.startswith('edificio-') or 'puerta' not in an:
            continue
        k = g[len('edificio-'):]
        ks = an['puerta']['dirs']['unica']
        fs = [lee(x) for x in ks]
        cambia = []
        if k in CORRE and not corridas:
            fs = [corre(f, CORRE[k]) for f in fs]
            cambia.append('corrida %+d' % CORRE[k])
        x0, x1, y0, y1 = hueco(fs)
        if y1 < fs[0].height - 2:
            continue   # no llega al suelo (el escaparate del concesionario, los caseríos con su escalón)
        n = max(0, y0 - HY0)
        if n:
            if k in FACHADA:
                fk = 'edificio-%s/base/unica/00' % FACHADA[k]
                fa = lee(fk)
                # la fila a repetir, la misma en la fachada (abajo alineadas) y en la puerta: la de la hoja que menos cambia, en todo el ancho
                off = fa.height - fs[0].height
                b = next(b for m in bl.values() for b in m.get('blds', []) if b.get('fachada', b['id']) == FACHADA[k] and b.get('doorX') is not None)
                px = (b['doorX'] - b['x0']) * 16 - 8 + b.get('dx', 0)
                comp = fa.copy()
                comp.alpha_composite(fs[0], (px, off))
                r = fila_rep(comp, off + y0 + 2, off + y1 - 2, 0, comp.width) - off
                guarda(fk, sube(fa, r + off, n))
                fs = [sube(f, r, n) for f in fs]
            else:
                # solo la puerta con lo que lleva encima (marco, dintel, farol), en sus columnas
                m0, m1 = max(0, x0 - MARCO), min(fs[0].width - 1, x1 + MARCO)
                r = fila_rep(fs[0], y0 + 2, y1 - 2, x0, x1 + 1)
                fs = [sube(f, r, n, m0, m1) for f in fs]
            cambia.append('+%d alto' % n)
        hx1 = min(HX1, RECORTA.get(k, 99) - 1)
        if x0 > HX0 or x1 < hx1:
            w = max(0, (hx1 - HX0) - (x1 - x0))
            m0, m1 = max(0, x0 - MARCO), min(fs[0].width - 1, x1 + MARCO)
            # la columna de la hoja que menos cambia con su vecina (repetirla no deja costura), cerca del medio
            c = min(range(x0, x1), key=lambda x: (sum(abs(fs[0].getpixel((x, y))[i] - fs[0].getpixel((x + 1, y))[i]) for y in range(HY0, fs[0].height) for i in range(4)), abs(x - (x0 + x1) // 2)))
            nx0 = HX0 if w else (HX0 if x0 > HX0 else hx1 - (x1 - x0))
            fs = [bloque(f, x0, x1, c, w, m0, m1, nx0) for f in fs]
            cambia.append('+%d ancho, hueco desde %d' % (w, nx0))
        if k in ABRE:
            f2 = abre(fs[-1], fs)
            if f2.tobytes() != fs[-1].tobytes():
                fs[-1] = f2
                cambia.append('abierta del todo')
        if k in RECORTA:
            r = []
            for f in fs:
                g = f.copy()
                g.paste((0, 0, 0, 0), (RECORTA[k], 0, g.width, g.height))
                r.append(g)
            if any(a.tobytes() != b.tobytes() for a, b in zip(r, fs)):
                fs = r
                cambia.append('recortada desde %d' % RECORTA[k])
        if not cambia:
            continue
        for x, f in zip(ks, fs):
            guarda(x, f)
        hecho.append('%s: %s' % (k, ', '.join(cambia)))
    print('\n'.join(hecho) or 'nada que tocar')

if __name__ == '__main__':
    main()
