# python3 -I tools/sprites/a-mano/aparcamiento.py [raiz]  (Python 3 + Pillow; no va en los scripts de npm)
# MAESTRO [3] (lo pidió el usuario: «del garaje viajas al otro pueblo y se queda estacionado en un aparcamiento»): el
# aparcamiento de cada pueblo, junto a la parada (3 × 4 casillas, plano en el suelo): asfalto con su bordillo, cuatro plazas de
# 2 × 1 con las rayas blancas a la izquierda y el pasillo a la derecha con la P pintada en azul.
# Sale a art/crudo/edificio-aparcamiento/base/unica/00.png (después, node tools/sprites/procesar.js edificio-aparcamiento --atlas).
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

ASF = ('#545b66', '#5e6672', '#6c7482')
BORDE = ('#8a8e94', '#bcb4a2')
RAYA = '#f0f0e8'
AZUL = ('#2c5aa0', '#4a7ad0')

def aparcamiento():
    L = Lienzo(48, 64)
    L.r(0, 0, 48, 64, ASF[1])
    for y in range(64):                         # el asfalto con su grano, por hash, sin rejilla
        for x in range(48):
            h = (x * 73856093 ^ y * 19349663) & 31
            if h == 0: L.p(x, y, ASF[0])
            elif h == 1: L.p(x, y, ASF[2])
    for y in (0, 63):                           # el bordillo
        L.hl(0, 47, y, BORDE[1])
    L.vl(0, 0, 63, BORDE[1]); L.vl(47, 0, 63, BORDE[1])
    L.hl(1, 46, 1, BORDE[0]); L.hl(1, 46, 62, BORDE[0])
    L.vl(1, 1, 62, BORDE[0]); L.vl(46, 1, 62, BORDE[0])
    for y in (3, 16, 32, 48, 60):               # las rayas de las cuatro plazas (2 × 1 casillas), por las casillas
        L.hl(3, 30, y, RAYA)
    L.vl(3, 3, 60, RAYA)
    for y in (4, 17, 33, 49):                   # el tope de cada plaza
        L.r(5, y + 4, 2, 6, BORDE[1])
    # la P del pasillo, pintada en el suelo: cuadro azul con la P blanca
    L.r(35, 22, 10, 13, AZUL[0])
    L.hl(35, 44, 22, AZUL[1])
    L.r(38, 25, 2, 8, RAYA)
    L.r(40, 25, 3, 1, RAYA); L.r(40, 28, 3, 1, RAYA); L.r(42, 26, 1, 2, RAYA)
    # la flecha de salida del pasillo, hacia arriba
    L.vl(40, 43, 55, RAYA); L.hl(38, 42, 45, RAYA); L.hl(39, 41, 44, RAYA)
    return L

if __name__ == '__main__':
    raiz = sys.argv[1] if len(sys.argv) > 1 else None
    d = os.path.join(raiz, 'edificio-aparcamiento', 'base', 'unica') if raiz else P('art', 'crudo', 'edificio-aparcamiento', 'base', 'unica')
    os.makedirs(d, exist_ok=True)
    L = aparcamiento()
    L.im.save(os.path.join(d, '00.png'))
    print('edificio-aparcamiento', L.im.getbbox(), len(L.colores()), 'colores')
