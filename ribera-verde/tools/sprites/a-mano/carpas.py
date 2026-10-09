# python3 -I tools/sprites/a-mano/carpas.py  (Python 3 + Pillow; no va en los scripts de npm)
# El armario de 80 y la carpa de 120 (1.10), alargando por dentro el arte aprobado (y ya procesado) de sus vecinas: solo se repiten columnas y
# filas que ya están en el sprite (misma paleta, mismo contorno), como alturas.py.
#  · en el piso (carpa_mapa, 16 px/m como carpaMapa): el de 80 sale del de 60 (de 10 × 31 a 13 × 35: 1 columna más de tela a
#    la izquierda de la puerta, 2 de sombra a la derecha, 1 fila más de techo y 3 de frente); la de 120, de la de 100 (de 16 × 39
#    a 19 × 40: 3 columnas más de sombra y 1 fila más de techo).
#  · por dentro (carpa_vista, ancho ≈ 0,64 px/cm + 3,6 y alto ≈ 0,7 px/cm − 7, como las de 60, 100 y 150): el de 80, de 42 × 105
#    a 55 × 119, con un tramo de 13 columnas y otro de 14 filas del mylar repetidos; la de 120, de 68 × 133 a 80 × 133, con un
#    tramo de 12 columnas. Los tramos son los que mejor casan consigo mismos (la columna de después del tramo, casi igual a la
#    primera del tramo), para que no se note la costura.
# Sale a art/crudo/carpas-medias-mapa/carpa-<p80|m120>-mapa/unica/00.png y art/crudo/carpas-medias-vista/carpa-<p80|m120>-vista/
# unica/00.png (después, node tools/sprites/procesar.js carpas-medias-mapa carpas-medias-vista --atlas)
import os
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
P = lambda *a: os.path.join(ROOT, *a)

def columnas(im, cols):
    """im con las columnas de `cols` (índices del original, en orden)"""
    out = Image.new('RGBA', (len(cols), im.height), (0, 0, 0, 0))
    for k, x in enumerate(cols):
        out.paste(im.crop((x, 0, x + 1, im.height)), (k, 0))
    return out

def filas(im, fs):
    """im con las filas de `fs` (índices del original, en orden)"""
    out = Image.new('RGBA', (im.width, len(fs)), (0, 0, 0, 0))
    for k, y in enumerate(fs):
        out.paste(im.crop((0, y, im.width, y + 1)), (0, k))
    return out

def tramo(n, i, k):
    """los índices 0..n-1 con el tramo [i, i + k) repetido justo detrás de él"""
    return list(range(0, i + k)) + list(range(i, n))

def lee(*ruta):
    """el sprite aprobado ya procesado (paleta bloqueada), recortado a lo que pinta"""
    im = Image.open(P(*ruta)).convert('RGBA')
    return im.crop(im.getbbox())

def guarda(im, *ruta):
    os.makedirs(os.path.dirname(P(*ruta)), exist_ok=True)
    im.save(P(*ruta))

def main():
    # piso: p60 (10 × 31) = poste A, tela B, puerta 2-7, sombra 8, poste 9; techo 0-4 (borde de luz en la 4), frente 5-30
    p = lee('art/procesado/carpas-mapa/carpa-p60-mapa/unica/00.png')
    p = columnas(p, [0, 1, 1, 2, 3, 4, 5, 6, 7, 8, 8, 8, 9])
    p = filas(p, [0, 1, 2, 2] + list(range(3, 22)) + [21] * 3 + list(range(22, 31)))
    guarda(p, 'art/crudo/carpas-medias-mapa/carpa-p80-mapa/unica/00.png')
    # m100 (16 × 39) = poste, tela 1-3, puerta 4-11, sombra 12-14, poste 15; techo 0-6 (borde de luz en la 6)
    m = lee('art/procesado/carpas-mapa/carpa-m100-mapa/unica/00.png')
    m = columnas(m, list(range(0, 13)) + [12, 13, 13, 14, 14, 15])
    m = filas(m, [0, 1, 2, 3, 3] + list(range(4, 39)))
    guarda(m, 'art/crudo/carpas-medias-mapa/carpa-m120-mapa/unica/00.png')
    # por dentro
    v = lee('art/procesado/carpas-vista/carpa-p60-vista/unica/00.png')
    v = filas(columnas(v, tramo(v.width, 12, 13)), tramo(v.height, 28, 14))
    guarda(v, 'art/crudo/carpas-medias-vista/carpa-p80-vista/unica/00.png')
    w = lee('art/procesado/carpas-vista/carpa-m100-vista/unica/00.png')
    w = columnas(w, tramo(w.width, 45, 12))
    guarda(w, 'art/crudo/carpas-medias-vista/carpa-m120-vista/unica/00.png')

if __name__ == '__main__':
    main()
