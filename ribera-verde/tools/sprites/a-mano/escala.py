# python3 -I tools/sprites/a-mano/escala.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.47 (lo pidió el usuario: «el mobiliario debe de ser a escala realista para con el personaje»): los muebles que se quedaban
# cortos al lado del protagonista (27 px = 1,70 m, 16 px/m) salen otra vez, a su alto real con la regla de los muebles a escala
# (props-escala): el frente a su alto y la tapa a medio fondo. No se redibujan: se alargan las filas que se repiten (las patas, el
# frente del mueble) del sprite ya procesado, para que sigan siendo los mismos, y se quitan columnas iguales donde sobra ancho.
# Salen como e-<sprite> (también cada estilo de club) en los grupos escala-alto (celda mueble_escala, 32 × 48) y escala-ancho
# (mueble_ancho, 48 × 48); el juego los usa solo con Datos.CAL (_arte_obj de pinta.gd), así las pantallas del HTML no cambian.
# Después: node tools/sprites/procesar.js escala-alto escala-ancho --atlas --atlas-dir godot/arte
import os, sys, glob
from PIL import Image
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
P = lambda *a: os.path.join(RAIZ, *a)

# sprite: (grupo de origen, filas que se añaden, columnas que se quitan, medida real que se busca[, la fila que se repite])
ALTO = {
    'table': ('props-16', 6, 0, 'mesa redonda de 90 cm, 75 de alto'),
    'pc': ('props-16', 7, 0, 'escritorio de 75 cm con el ordenador'),
    'lab': ('props-16', 6, 0, 'mesa de 90 cm de alto con el microscopio'),
    'lab2': ('props-16', 6, 0, 'mesa de 90 cm de alto con los botes'),
    'counter': ('props-altura', 5, 0, 'mostrador de 100 cm'),
    'barcounter': ('props-altura', 5, 0, 'barra de 100 cm'),
    'btable': ('props-16', 8, 0, 'mesa alta de bar de 105 cm'),
    'bench': ('props-16', 5, 0, 'banco con respaldo de 80 cm'),
    'display': ('props-16', 6, 0, 'vitrina de 100 cm'),
    'vitrina': ('locales-16', 6, 0, 'vitrina del dispensario de 100 cm'),
    'barraD': ('locales-16', 7, 0, 'barra de la discoteca de 110 cm'),
    'cajaL': ('negocios-16', 7, 0, 'mostrador de 100 cm con la caja', 12),
    'lavaL': ('negocios-16', 6, 3, 'lavadora industrial de 80 × 110 cm'),
    'secaL': ('negocios-16', 6, 3, 'secadora industrial de 80 × 110 cm'),
    'barrilT': ('negocios-16', 5, 0, 'barrica de 95 cm'),
    'cambioL': ('negocios-16', 12, 0, 'máquina de cambio de 160 cm'),
    'mesaC': ('negocios-16', 3, 0, 'mesa de 75 cm'),
    'mesita': ('locales-16', 2, 0, 'mesa baja de 45 cm'),
    'jukebox': ('prop-gramola-alta', 6, 0, 'gramola de 160 cm'),
}
ANCHO = {
    'sofaF': ('locales-ancho', 2, 0, 'sofá de 85 cm de alto'),
    'sofaB': ('locales-ancho', 2, 0, 'sofá de 85 cm de alto'),
    'sofaV': ('locales-ancho', 2, 0, 'sofá de 85 cm de alto'),
}

def filas(im):
    return [tuple(im.getpixel((x, y)) for x in range(im.width)) for y in range(im.height)]

def vacia(f):
    return all(p[3] == 0 for p in f)

def alarga(im, n, fila=None):
    """mete n copias de la fila que más se repite en la mitad de abajo (las patas o el frente) y sube lo de encima"""
    F = filas(im)
    llenas = [y for y, f in enumerate(F) if not vacia(f)]
    if not llenas or n <= 0:
        return im
    y0, y1 = llenas[0], llenas[-1]
    # la fila de las patas: la de menos píxeles en la mitad de abajo (sin la última); a igualdad, la que se repite con la de
    # debajo y la más cercana al 70 % del alto (el frente liso de un mueble macizo)
    desde = y0 + (y1 - y0 + 1) // 2
    cuenta = lambda f: sum(1 for p in f if p[3])
    obj = y0 + (y1 - y0) * 70 // 100
    mejor = min(range(desde, y1), key=lambda y: (cuenta(F[y]), F[y] != F[y + 1], abs(y - obj))) if desde < y1 else y1 - 1
    if fila is not None:
        mejor = fila
    G = F[:mejor + 1] + [F[mejor]] * n + F[mejor + 1:]
    G = G[n:] if all(vacia(f) for f in G[:n]) else G
    out = Image.new('RGBA', (im.width, len(G)))
    for y, f in enumerate(G):
        for x, p in enumerate(f):
            out.putpixel((x, y), p)
    return out

def estrecha(im, n):
    """quita n columnas iguales a su vecina, del centro hacia fuera (el frente liso del aparato)"""
    for _ in range(n):
        W = im.width
        cols = [tuple(im.getpixel((x, y)) for y in range(im.height)) for x in range(W)]
        cand = [x for x in range(1, W) if cols[x] == cols[x - 1] and any(p[3] for p in cols[x])]
        if not cand:
            break
        x = min(cand, key=lambda c: abs(c - W // 2))
        out = Image.new('RGBA', (W - 1, im.height))
        out.paste(im.crop((0, 0, x, im.height)), (0, 0))
        out.paste(im.crop((x + 1, 0, W, im.height)), (x, 0))
        im = out
    return im

def hecho(src, n, q, celda, fila=None):
    """el sprite alargado en su celda nueva, con la base y el centro donde estaban"""
    im = Image.open(src).convert('RGBA')
    bb = im.getbbox()
    cx = (bb[0] + bb[2]) / 2 if bb else im.width / 2
    a = alarga(estrecha(im, q), n, fila)
    bb2 = a.getbbox()
    cw, ch = celda
    out = Image.new('RGBA', (cw, ch))
    # la base de abajo a la última fila de la celda; el centro de lo dibujado, donde estaba respecto al ancla
    ax = {16: 8, 32: 16, 48: 16}[im.width]
    nx = {32: 16, 48: 16}[cw]
    dx = round(cx - ax - ((bb2[0] + bb2[2]) / 2 - ax)) if q else 0
    out.paste(a, (nx - ax + dx, ch - a.height))
    return out

def sale(grupo, n, im):
    d = P('art', 'crudo', grupo, n, 'unica'); os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, '00.png'))

if __name__ == '__main__':
    for T, grupo, celda in ((ALTO, 'escala-alto', (32, 48)), (ANCHO, 'escala-ancho', (48, 48))):
        for k, (g, n, q, _, *fi) in T.items():
            for src in sorted(glob.glob(P('art', 'procesado', g, k, 'unica', '00.png')) + glob.glob(P('art', 'procesado', g, k + '-*', 'unica', '00.png'))):
                nom = src.split(os.sep)[-3]
                sale(grupo, 'e-' + nom, hecho(src, n, q, celda, fi[0] if fi else None))
                print(grupo, 'e-' + nom)
