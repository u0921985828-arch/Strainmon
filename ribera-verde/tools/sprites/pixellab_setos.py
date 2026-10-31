# El seto de la huerta de PixelLab (lo pidió el usuario: «Los setos también habría que ajustarlos incluso hacer los sprites con pixel
# lab también»). Entrada: tools/sprites/pixellab-setos/crudo/esquina-35.png, la esquina └ de 32 × 32 elegida entre 64 de
# create_image_pro (un seto recortado visto a 3/4 desde arriba, con contorno: el brazo de arriba, la tapa del seto; el de la derecha,
# la tapa y la cara de delante). De ella salen las piezas por casilla, todas con la misma textura y paleta: el brazo de arriba da el
# tramo vertical (bandas de su tapa repetidas) y su remate; la esquina, tal cual; el brazo de la derecha, el tramo horizontal y su
# remate; los del lado derecho, en espejo.
# Salida: art/crudo/seto-huerta/<pieza>/unica/00.png (celda objeto_alto, 32 × 32, ancla (16, 31): la pieza de 16 de ancho en x 8..23
# y abajo del todo). Después: node tools/sprites/procesar.js seto-huerta --atlas --atlas-dir godot/arte
import os, sys
from PIL import Image

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
E = Image.open(os.path.join(R, 'tools', 'sprites', 'pixellab-setos', 'crudo', 'esquina-35.png')).convert('RGBA')

def filas(x0, ys):
    """una pieza de 16 de ancho con las filas ys de la esquina (de la columna x0 a la x0 + 15)"""
    im = Image.new('RGBA', (16, len(ys)), (0, 0, 0, 0))
    for j, y in enumerate(ys):
        for i in range(16):
            im.putpixel((i, j), E.getpixel((x0 + i, y)))
    return im

def columnas(xs, y0, y1):
    """una pieza con las columnas xs de la esquina (de la fila y0 a la y1)"""
    im = Image.new('RGBA', (len(xs), y1 - y0 + 1), (0, 0, 0, 0))
    for i, x in enumerate(xs):
        for j in range(y1 - y0 + 1):
            im.putpixel((i, j), E.getpixel((x, y0 + j)))
    return im

espejo = lambda im: im.transpose(Image.FLIP_LEFT_RIGHT)
V = filas(0, list(range(3, 13)) + list(range(5, 11)))            # el tramo vertical: la tapa, en dos bandas que casan
V2 = filas(0, list(range(8, 14)) + list(range(3, 13)))           # y otra, para que no se vea la repetición (casillas impares)
V0 = filas(0, list(range(1, 13)) + list(range(7, 11)))           # su remate de arriba, redondo
L = filas(0, range(14, 32))                                      # la esquina └, con la cara de delante
H = columnas(list(range(18, 28)) + list(range(19, 25)), 14, 31)  # el tramo horizontal: tapa y cara de delante
H2 = columnas(list(range(21, 28)) + list(range(18, 27)), 14, 31) # y otra (casillas impares)
HD = columnas(list(range(20, 24)) + list(range(20, 32)), 14, 31) # su remate a la derecha (junto al camino)
PIEZAS = {'setoV': V, 'setoV2': V2, 'setoV0': V0, 'setoL': L, 'setoH': H, 'setoH2': H2, 'setoHd': HD,
          'setoVd': espejo(V), 'setoVd2': espejo(V2), 'setoV0d': espejo(V0), 'setoR': espejo(L), 'setoHi': espejo(HD)}

def sale(nom, im, dest):
    c = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    c.paste(im, (8, 32 - im.height), im)
    d = os.path.join(dest, nom, 'unica')
    os.makedirs(d, exist_ok=True)
    c.save(os.path.join(d, '00.png'))

if __name__ == '__main__':
    dest = sys.argv[1] if len(sys.argv) > 1 else os.path.join(R, 'art', 'crudo', 'seto-huerta')
    for k, im in PIEZAS.items():
        sale(k, im, dest)
    print(len(PIEZAS), 'piezas en', dest)
