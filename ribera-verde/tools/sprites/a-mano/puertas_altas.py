# python3 -I tools/sprites/a-mano/puertas_altas.py   (Python 3 + Pillow; edita art/procesado —y art/crudo donde es la misma imagen—;
# después, node tools/sprites/procesar.js <grupo> --atlas --atlas-dir godot/arte; tras volver a procesar una puerta, pásalo otra vez)
# Las puertas de la calle, a la medida del protagonista (lo pidió el usuario: «la puerta es demasiado pequeña para el personaje»):
# a 16 px/m el protagonista mide 27 px (1,70 m) y unos 12 de ancho; había puertas de 18 a 26 px de alto y hojas de 9 px. Cada puerta
# (edificio-*/puerta, sus 4 fotogramas) sube hasta ALTO px de hueco y se ensancha hasta su ANCHO, repitiendo la fila y la columna de
# su hoja que más se parecen a su vecina (sin dibujar nada nuevo: misma paleta). Donde encima de la puerta hay un rótulo en la planta
# baja (el bar, el club del Ensanche, GAUA), la fachada entera sube con ella: se repite la misma fila en la fachada y en la puerta y se
# pierden otras tantas del tejado. Se puede volver a pasar: lo que ya mide lo pedido no se toca.
import json, os
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
PROC = os.path.join(ROOT, 'art/procesado')
CRUDO = os.path.join(ROOT, 'art/crudo')
MARCO = 4                     # px de marco a cada lado del hueco
ALTO = 29                     # px de hueco: 1,80 m, por encima de la cabeza (27 px)
# lo que se ensancha cada hoja (px) y las que suben con la fachada entera (el rótulo de la planta baja, justo encima)
ANCHO = {'asociacion': 4, 'club-kalea': 4, 'casco-pu': 4, 'bajo-setas': 4, 'club-ensanche': 4,
         'club-fundicion': 2, 'club-itsaso': 2, 'marinera-pu': 2, 'bar': 2}
# el hueco abierto de antes (px de ancho), para no ensanchar dos veces
ANCHO0 = {'asociacion': 6, 'club-kalea': 6, 'casco-pu': 6, 'bajo-setas': 6, 'club-ensanche': 8,
          'club-fundicion': 9, 'club-itsaso': 9, 'marinera-pu': 9, 'bar': 10}
# las que crecen solo hacia la derecha (su hoja estaba a la izquierda de sus casillas)
DERECHA = {'asociacion'}
FACHADA = {'bar': 'bar', 'club-ensanche': 'club-ensanche', 'disco': 'disco'}

def lee(k):
    return Image.open(os.path.join(PROC, k + '.png')).convert('RGBA')

def guarda(k, im):
    # en procesado y, si el crudo era la misma imagen, también en el crudo (así volver a procesar no lo deshace)
    pc = os.path.join(CRUDO, k + '.png')
    if os.path.exists(pc) and Image.open(pc).convert('RGBA').tobytes() == lee(k).tobytes():
        im.save(pc)
    im.save(os.path.join(PROC, k + '.png'))

def hueco(fs):
    a, o = fs[0].load(), fs[-1].load()
    xs, ys = [], []
    for y in range(fs[0].height):
        for x in range(fs[0].width):
            if a[x, y] != o[x, y]:
                xs.append(x)
                ys.append(y)
    return min(xs), max(xs), min(ys), max(ys)

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

def main():
    d = json.load(open(os.path.join(ROOT, 'godot/arte/atlas.json')))
    bl = json.load(open(os.path.join(ROOT, 'godot/datos/datos.json')))['MAPS']
    hecho = []
    for g, an in d['anims'].items():
        if not g.startswith('edificio-') or 'puerta' not in an:
            continue
        k = g[len('edificio-'):]
        ks = an['puerta']['dirs']['unica']
        fs = [lee(x) for x in ks]
        x0, x1, y0, y1 = hueco(fs)
        if y1 < fs[0].height - 2:
            continue   # no llega al suelo (el escaparate del concesionario, de suelo propio)
        alto = y1 - y0 + 1
        n = max(0, ALTO - alto)
        w = ANCHO.get(k, 0)
        if x1 - x0 + 1 >= ANCHO0.get(k, 0) + w:
            w = 0   # ya ensanchada
        if n == 0 and w == 0:
            continue
        # el marco: el hueco y MARCO px a cada lado (las jambas y lo que lleva encima; más allá, la pared, que no se mueve)
        if True:   # siempre: también acota lo que sube
            m0, m1 = max(0, x0 - MARCO), min(fs[0].width - 1, x1 + MARCO)
            # ya ensanchada si el hueco de la abierta ya llega: se mira por el ancho de lo oscuro abierto
            c = min(range(x0, x1), key=lambda x: (sum(abs(fs[0].getpixel((x, y))[i] - fs[0].getpixel((x + 1, y))[i]) for y in range(y0, y1 + 1) for i in range(4)), abs(x - (x0 + x1) // 2)))
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
                r = fila_rep(fs[0], y0 + 2, y1 - 2, x0, x1 + 1)
                fs = [sube(f, r, n, m0, m1) for f in fs]
        if w:
            fs = [ensancha(f, c, w, m0, m1, k in DERECHA) for f in fs]
        for x, f in zip(ks, fs):
            guarda(x, f)
        hecho.append('%s: +%d alto, +%d ancho' % (k, n, w))
    print('\n'.join(hecho) or 'nada que tocar')

if __name__ == '__main__':
    main()
