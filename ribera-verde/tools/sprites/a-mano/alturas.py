# python3 -I tools/sprites/a-mano/alturas.py  (Python 3 + Pillow; no va en los scripts de npm)
# Muebles y farolas a su altura (1.10, a 16 px/m como los personajes), alargando por dentro el arte aprobado: solo se repiten
# filas que ya están en el sprite (misma paleta, mismo contorno).
#  · mostrador (counter) y barra (barcounter): de 11 a 16 px (1 m con la tapa), con 5 filas más de frente; caben en su
#    casilla (objeto_1x1). Así la barra ya no queda más baja que los taburetes (14 px).
#  · farola (lamp): de 27 a 56 px (3,5 m), con 29 filas más de poste, en la celda objeto_muy_alto (32 × 64, pies abajo).
#  · gramola (jukebox): de 16 a 24 px (1,5 m), con 8 filas más del panel de abajo, en la celda objeto_alto (32 × 32, pies abajo).
# Sale a art/crudo/props-altura/<counter|barcounter>/unica/00.png, art/crudo/prop-farola-alta/lamp/unica/00.png y
# art/crudo/prop-gramola-alta/jukebox/unica/00.png (después, node tools/sprites/procesar.js props-altura prop-farola-alta
# prop-gramola-alta --atlas)
import os
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
P = lambda *a: os.path.join(ROOT, *a)

def alarga(im, filas, alto):
    """im con las filas de `filas` (lista de índices del original, en orden) apiladas desde abajo en un lienzo del ancho de im y
    alto `alto`: la última fila de la lista cae en la última fila del lienzo"""
    out = Image.new('RGBA', (im.width, alto), (0, 0, 0, 0))
    for k, y in enumerate(reversed(filas)):
        out.paste(im.crop((0, y, im.width, y + 1)), (0, alto - 1 - k))
    return out

def guarda(im, *ruta):
    os.makedirs(os.path.dirname(P(*ruta)), exist_ok=True)
    im.save(P(*ruta))

def main():
    c = Image.open(P('art/procesado/props-16/counter/unica/00.png')).convert('RGBA')        # tapa 5-10, frente 11-15
    guarda(alarga(c, list(range(5, 14)) + [13] * 5 + [14, 15], 16), 'art/crudo/props-altura/counter/unica/00.png')
    b = Image.open(P('art/procesado/props-16/barcounter/unica/00.png')).convert('RGBA')     # tapa 5-9, frente 10-15 (tablas 11-14)
    guarda(alarga(b, list(range(5, 13)) + [12] * 5 + [13, 14, 15], 16), 'art/crudo/props-altura/barcounter/unica/00.png')
    f = Image.open(P('art/procesado/prop-farola/lamp/unica/00.png')).convert('RGBA')        # farol 5-10, poste 11-28, base 29-31
    filas = list(range(5, 21)) + [20] * 15 + list(range(21, 29)) + [28] * 14 + [29, 30, 31]
    guarda(alarga(f, filas, 64), 'art/crudo/prop-farola-alta/lamp/unica/00.png')
    g = Image.open(P('art/procesado/props-16/jukebox/unica/00.png')).convert('RGBA')          # arco 0-8, panel 9-12, base 13-15
    lienzo = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    lienzo.paste(alarga(g, list(range(0, 11)) + [10] * 8 + list(range(11, 16)), 24), (8, 8))
    guarda(lienzo, 'art/crudo/prop-gramola-alta/jukebox/unica/00.png')

if __name__ == '__main__':
    main()
