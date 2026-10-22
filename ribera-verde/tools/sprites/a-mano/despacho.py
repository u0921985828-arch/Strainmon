# python3 -I tools/sprites/a-mano/despacho.py  (Python 3 + Pillow; no va en los scripts de npm)
# MAESTRO [8] «Despacho Narco»: el despacho de la nave en su nivel máximo, a 16 px/m como la nave.
#  · monD (mueble_ancho, 48 × 48, base en (16, 47); monD2 no se pinta): la pared de monitores de seguridad, colgada sobre la
#    pared del despacho: seis pantallas con lo que ven las cámaras de tus locales (una puerta, un pasillo, un mostrador, una calle
#    de noche…), cada una con su piloto rojo de grabación, y el grabador con sus luces debajo.
#  · cajaD (objeto_alto, 32 × 32, pies en (16, 31)): la caja fuerte de alta capacidad, de pie: el cuerpo de acero gris oscuro, la
#    puerta con la rueda de tres brazos, el teclado y las bisagras.
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js despacho-ancho despacho-alto --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

K = '#2a2a34'   # el contorno de los muebles (el de salon.py)
SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

PANT = ('#1c2a26', '#2e4a40', '#4e7a64', '#8ec0a0')   # la imagen de las cámaras, verdosa, de oscuro a claro
def pantalla(L, x, y, que):
    """una pantalla de 12 × 9 con su marco y lo que ve su cámara"""
    L.r(x, y, 12, 9, '#16181c'); L.r(x + 1, y + 1, 10, 7, PANT[0])
    if que == 0:     # la puerta de un local: el marco y una figura delante
        L.r(x + 3, y + 2, 4, 6, PANT[1]); L.vl(x + 3, y + 2, y + 7, PANT[2]); L.vl(x + 6, y + 2, y + 7, PANT[2])
        L.p(x + 8, y + 3, PANT[3]); L.vl(x + 8, y + 4, y + 7, PANT[2])
    elif que == 1:   # un pasillo con su fuga
        L.hl(x + 1, x + 10, y + 7, PANT[1]); L.p(x + 2, y + 6, PANT[2]); L.p(x + 9, y + 6, PANT[2])
        L.r(x + 5, y + 3, 2, 3, PANT[1]); L.p(x + 5, y + 2, PANT[2]); L.p(x + 6, y + 2, PANT[2])
    elif que == 2:   # el mostrador con la caja registradora
        L.hl(x + 1, x + 10, y + 5, PANT[2]); L.r(x + 1, y + 6, 10, 2, PANT[1]); L.r(x + 7, y + 3, 3, 2, PANT[3])
    elif que == 3:   # la calle de noche: la farola y un coche aparcado
        L.vl(x + 3, y + 2, y + 7, PANT[2]); L.p(x + 3, y + 1, PANT[3]); L.p(x + 4, y + 2, PANT[3])
        L.r(x + 6, y + 5, 4, 2, PANT[2]); L.p(x + 6, y + 7, PANT[3]); L.p(x + 9, y + 7, PANT[3])
    elif que == 4:   # las mesas de la nave desde arriba
        for i in range(3): L.r(x + 2 + i * 3, y + 3, 2, 3, PANT[2]); L.p(x + 2 + i * 3, y + 2, PANT[3])
    else:            # el muelle: el agua y un barco
        L.r(x + 1, y + 5, 10, 3, PANT[1]); L.r(x + 3, y + 3, 5, 2, PANT[2]); L.vl(x + 5, y + 1, y + 2, PANT[3])
    L.hl(x + 1, x + 10, y + 1 + (que * 3) % 7, PANT[1])                     # la línea de barrido
    L.p(x + 10, y + 1, '#e04040')                                            # el piloto de grabación

MON_DY = 6   # el bastidor, 6 px más abajo: arriba, 2 px de pared libres; abajo, el grabador sobre el zócalo

def monD():
    """la pared de monitores de seguridad (2 × 3 pantallas) sobre un soporte negro y el grabador debajo"""
    L = Lienzo(48, 48)
    d = MON_DY   # (lo pidió el usuario: «la tele está encima de la pared»): todo dentro de la pared, nada por encima de su canto
    L.r(4, 12 + d, 40, 24, '#202228'); L.hl(4, 43, 12 + d, '#3a3e46')       # el bastidor de la pared
    for j in range(2):
        for i in range(3):
            pantalla(L, 5 + i * 13, 13 + d + j * 10, i + j * 3)
    L.r(14, 34 + d, 20, 4, '#2c2e34'); L.hl(14, 33, 34 + d, '#4a4e56')      # el grabador
    for i in range(4): L.p(16 + i * 2, 36 + d, ('#58d080', '#58d080', '#e8b040', '#58d080')[i])
    L.r(28, 36 + d, 4, 1, '#16181c')
    L.contorno(K)
    return L

AC = ('#2c3036', '#464c54', '#626a74', '#8a929c')   # el acero de la caja
def cajaD():
    """la caja fuerte de alta capacidad: 1,4 m de alto, de pie, con la rueda, el teclado y las bisagras"""
    L = Lienzo(32, 32)
    L.r(7, 9, 18, 22, AC[0]); L.r(8, 10, 16, 20, AC[1])                      # el cuerpo
    L.hl(8, 23, 10, AC[3]); L.vl(8, 10, 29, AC[2])
    L.r(10, 12, 12, 16, AC[2]); L.hl(10, 21, 12, AC[3]); L.hl(10, 21, 27, AC[0]); L.vl(21, 12, 27, AC[0])   # la puerta
    for y in (14, 24): L.r(8, y, 2, 3, '#1a1c20')                            # las bisagras
    cx, cy = 15, 19                                                          # la rueda de tres brazos
    L.r(cx - 1, cy - 1, 3, 3, '#c8ccd2'); L.p(cx, cy, AC[0])
    for dx, dy in ((0, -3), (-3, 2), (3, 2)):
        L.p(cx + dx, cy + dy, '#d8dce0'); L.p(cx + dx // 2, cy + dy // 2, '#a8aeb6')
    L.r(18, 14, 3, 4, '#16181c')                                             # el teclado
    L.p(19, 15, '#58d080'); L.p(19, 16, '#8a929c'); L.p(19, 17, '#8a929c')
    L.r(7, 30, 18, 1, '#1a1c20')                                             # el zócalo
    L.contorno(K)
    return L

sale('monD', monD(), 'despacho-ancho')
sale('cajaD', cajaD(), 'despacho-alto')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
