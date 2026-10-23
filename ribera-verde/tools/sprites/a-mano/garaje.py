# python3 -I tools/sprites/a-mano/garaje.py [raiz]  (Python 3 + Pillow; no va en los scripts de npm)
# MAESTRO [3] (lo pidió el usuario: «el garaje dibujado en el mapa, junto al piso»): el garaje de la tía, pegado a la derecha
# del piso de Ribera Verde (2 × 3 casillas), con el tejado y la pared del piso y la puerta seccional gris de 2 casillas.
# Sale a art/crudo/edificio-garaje/base/unica/00.png (después, node tools/sprites/procesar.js edificio-garaje --atlas).
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

TEJA = ('#6a1818', '#8a2a1a', '#a92d1d', '#b03424')
PARED = ('#f8f8f0', '#f6e8c8', '#e0ceaa', '#c0ae8a')
CHAPA = ('#4c5560', '#6c7482', '#9aa3ad', '#c8ccd0')
K = '#2a1a10'

def garaje():
    L = Lienzo(32, 48)
    for y in range(0, 12):                      # el tejado, de teja como el del piso
        for x in range(32):
            L.p(x, y, TEJA[2])
        if y % 3 == 2:
            L.hl(0, 31, y, TEJA[1])
        for x in range((y // 3) % 2 * 4, 32, 8):
            L.p(x, y, TEJA[0] if y % 3 != 2 else TEJA[0])
            if y % 3 == 0: L.p(x + 1, y, TEJA[3])
    L.hl(0, 31, 12, TEJA[0]); L.hl(0, 31, 13, K)    # el alero
    L.r(0, 14, 32, 34, PARED[0])                # la pared
    for y in range(16, 48, 4):
        L.hl(0, 31, y, PARED[1])
    L.r(2, 19, 28, 29, PARED[3])                # el marco
    L.r(3, 20, 26, 28, CHAPA[0])
    for y in range(21, 48):                     # la puerta seccional: paneles de 5 filas
        j = (y - 21) % 5
        L.hl(4, 27, y, CHAPA[1] if j == 4 else CHAPA[2] if j else CHAPA[3])
    L.vl(4, 21, 47, CHAPA[1]); L.vl(27, 21, 47, CHAPA[1])
    L.r(14, 41, 4, 1, CHAPA[0])                 # el tirador
    L.r(14, 15, 4, 2, '#f0d878'); L.hl(14, 17, 17, CHAPA[0])   # la luz de encima
    L.vl(0, 14, 47, PARED[2]); L.vl(31, 14, 47, PARED[2])
    return L

if __name__ == '__main__':
    raiz = sys.argv[1] if len(sys.argv) > 1 else None
    d = os.path.join(raiz, 'edificio-garaje', 'base', 'unica') if raiz else P('art', 'crudo', 'edificio-garaje', 'base', 'unica')
    os.makedirs(d, exist_ok=True)
    L = garaje()
    L.im.save(os.path.join(d, '00.png'))
    print('edificio-garaje', L.im.getbbox(), len(L.colores()), 'colores')
