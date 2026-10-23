# Landrace Hunters — el atrezo de la tierra (lo pidió el usuario: «le daría más atrezo a los suelos de la tierra… me parece muy plano.
# Lo haría más imperfecto»), dibujado a mano, sin PixelLab, con la paleta del mosaico de tierra (mo-dirt de detalle.py):
#  · tierra-detalles (tira_tierra, 128 × 16): ocho detalles de 16 × 16 que el juego reparte por las casillas de tierra y de pista con
#    el hash de la casilla (pinta.gd, _detalle_tierra; solo con Datos.CAL): la piedra con su sombra, las huellas de unas botas, el
#    matojo seco, el charco de barro, la grieta, la ramita con dos hojas, las piedrecitas y el terrón.
# Píxel perfecto: alfa 0 o 255, sin degradados ni antialias; luz arriba a la izquierda como el resto de la calle.
# Sale a art/crudo/tierra-detalles/tierra/unica/00.png; después, node tools/sprites/procesar.js tierra-detalles --atlas --atlas-dir godot/arte
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

TIERRA, TIERRA_O, TIERRA_OO, TIERRA_L = '#c48a52', '#b47c48', '#a0744c', '#dca476'
SOMBRA = '#8a6040'
PIEDRA, PIEDRA_L, PIEDRA_O = '#a8a296', '#d0cabc', '#78726a'
SECO, SECO_O, SECO_L = '#b89c58', '#8c7a3c', '#d8c07a'
BARRO, BARRO_O, AGUA_L = '#7a5434', '#5e402a', '#a8b4b8'
HOJA, HOJA_O = '#7c9a48', '#5a7434'

def piedra():
    L = Lienzo(16, 16)
    L.hl(6, 11, 10, SOMBRA); L.hl(5, 10, 11, SOMBRA)                    # la sombra, abajo a la derecha
    L.r(5, 7, 6, 3, PIEDRA); L.hl(6, 9, 6, PIEDRA)
    L.hl(6, 8, 7, PIEDRA_L); L.p(6, 6, PIEDRA_L)                         # la luz, arriba a la izquierda
    L.hl(7, 10, 9, PIEDRA_O); L.p(10, 8, PIEDRA_O)
    return L

def huellas():
    L = Lienzo(16, 16)
    for (x, y) in ((3, 2), (8, 6), (4, 10)):                              # tres pisadas en zigzag, cuesta arriba
        L.hl(x, x + 1, y, TIERRA_OO); L.r(x, y + 1, 3, 2, TIERRA_OO); L.hl(x, x + 1, y + 3, TIERRA_OO)
        L.p(x + 1, y + 1, BARRO); L.p(x + 1, y + 2, BARRO)
        L.p(x + 2, y + 3, TIERRA_L)                                       # el canto de la huella, con luz
    return L

def matojo():
    L = Lienzo(16, 16)
    L.hl(5, 10, 12, SOMBRA)
    for x, alto, c in ((5, 3, SECO_O), (6, 5, SECO), (7, 4, SECO_O), (8, 6, SECO), (9, 4, SECO_O), (10, 3, SECO)):
        L.vl(x, 12 - alto, 11, c)
    for (x, y) in ((6, 6), (8, 5), (10, 8), (4, 9)):
        L.p(x, y, SECO_L)                                                 # las puntas, secas y claras
    L.p(4, 10, SECO_O); L.p(11, 10, SECO_O)
    return L

def charco():
    L = Lienzo(16, 16)
    L.hl(4, 11, 7, TIERRA_OO); L.hl(3, 12, 8, BARRO); L.hl(3, 12, 9, BARRO); L.hl(4, 11, 10, TIERRA_OO)
    L.hl(5, 10, 8, BARRO_O); L.hl(4, 11, 9, BARRO_O)
    L.hl(6, 8, 8, AGUA_L); L.p(10, 9, AGUA_L)                             # el brillo del cielo en el agua
    L.p(2, 9, TIERRA_OO); L.p(13, 8, TIERRA_OO)
    return L

def grieta():
    L = Lienzo(16, 16)
    camino = ((2, 4), (3, 4), (4, 5), (5, 5), (6, 6), (7, 7), (8, 7), (9, 8), (10, 8), (11, 9), (12, 10), (13, 10))
    for (x, y) in camino:
        L.p(x, y, BARRO)
        L.p(x, y + 1, TIERRA_L)                                           # el labio de abajo, con luz
    for (x, y) in ((7, 8), (7, 9), (6, 10), (9, 7), (10, 6)):              # dos ramales
        L.p(x, y, TIERRA_OO)
    return L

def ramita():
    L = Lienzo(16, 16)
    for (x, y) in ((3, 9), (4, 9), (5, 8), (6, 8), (7, 8), (8, 7), (9, 7), (10, 7), (11, 6)):
        L.p(x, y, BARRO); L.p(x, y + 1, SOMBRA)
    L.p(7, 7, BARRO); L.p(6, 6, BARRO)                                    # la horquilla
    L.hl(10, 12, 9, HOJA); L.p(11, 10, HOJA_O); L.p(12, 9, HOJA_O)        # dos hojas caídas
    L.hl(3, 5, 5, SECO); L.p(4, 6, SECO_O)
    return L

def piedrecitas():
    L = Lienzo(16, 16)
    for (x, y) in ((3, 4), (9, 3), (6, 9), (12, 8), (4, 12), (10, 12)):
        L.hl(x, x + 1, y, PIEDRA); L.p(x, y, PIEDRA_L); L.hl(x, x + 1, y + 1, SOMBRA)
    return L

def terron():
    L = Lienzo(16, 16)
    L.hl(5, 11, 11, SOMBRA); L.hl(6, 11, 12, SOMBRA)
    L.r(5, 7, 6, 4, TIERRA_O); L.hl(6, 9, 6, TIERRA_O)
    L.hl(6, 8, 7, TIERRA_L); L.p(6, 6, TIERRA_L); L.p(9, 8, TIERRA_L)
    L.hl(7, 10, 10, TIERRA_OO); L.p(10, 9, TIERRA_OO)
    L.p(3, 10, TIERRA_O); L.p(12, 7, TIERRA_O)                            # migas
    return L

DETALLES = (piedra, huellas, matojo, charco, grieta, ramita, piedrecitas, terron)

def tira():
    T = Lienzo(16 * len(DETALLES), 16)
    for i, f in enumerate(DETALLES):
        T.pega(f(), 16 * i, 0)
    return T

if __name__ == '__main__':
    d = P('art', 'crudo', 'tierra-detalles', 'tierra', 'unica'); os.makedirs(d, exist_ok=True)
    for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
    T = tira()
    T.im.save(os.path.join(d, '00.png'))
    print('tierra-detalles', T.im.size, len(T.colores()), 'colores')
