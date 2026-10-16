# python3 -I tools/sprites/a-mano/sotano.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.51 (lo pidió el usuario: «antes de comprar o alquilar el bajo… habilitar el sótano de la casa… unas escaleras y también una
# puerta en la casa, luego un mapa pequeño como un mini pasillito»; y lo mismo en el taller y en la nave): a 16 px/m, como el piso.
#  · Casillas (tile, 16 × 16): bajS1 y bajS2, el hueco de la escalera del pasillo que baja al sótano (los peldaños de madera, cada vez
#    más oscuros, con la barandilla al lado); escS, los peldaños de hormigón del sótano que suben al pasillo (la salida, abajo).
#  · Objetos altos (objeto_alto, 32 × 32, pies en (16, 31)), en la fila de la pared: puertaI, la puerta de madera de dentro del piso
#    (marco, cuarterones y el pomo); puertaM, la puerta metálica gris de los locales (el taller y la nave), con la barra y la rejilla de
#    ventilación; perchero, la percha de pared con dos chaquetas y un paraguas.
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js sotano-tiles sotano-alto --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar

K = '#2a2a34'   # el contorno de los muebles (el de salon.py)
SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

MAD = ('#c48a52', '#a46e40', '#dcac6c', '#74502e')   # la madera de la paleta fija
def bajS(n):
    """el hueco de la escalera: tres peldaños por casilla, del claro de arriba al oscuro de abajo; la barandilla a la derecha"""
    L = Lienzo(16, 16)
    tonos = (('#b07a46', '#8a5e36'), ('#946436', '#6e4a2a'), ('#7a5230', '#5a3c22')) if n == 1 else (('#5e4028', '#46301e'), ('#463020', '#32241a'), ('#30221a', '#221a14'))
    for i, (c0, c1) in enumerate(tonos):
        y = i * 5 + (1 if n == 1 else 0)
        L.r(0, y, 13, 4, c0); L.hl(0, 12, y, MAD[2] if n == 1 and i == 0 else c0); L.hl(0, 12, y + 4 if y + 4 < 16 else 15, c1)
    L.r(13, 0, 3, 16, '#3a2c20'); L.vl(13, 0, 15, MAD[3])                    # la pared del hueco
    L.vl(14, 0, 15, '#b8bcc4'); L.vl(15, 0, 15, '#6a6e76')                     # la barandilla de tubo
    if n == 1:
        L.hl(0, 15, 0, MAD[3])                                                  # el canto del suelo de arriba
    return L

def escS():
    """los peldaños de hormigón del sótano, que suben hacia el pasillo (la salida de abajo), con el borde gastado"""
    L = Lienzo(16, 16); R = azar(911)
    for i in range(4):
        y = i * 4
        c = ('#8a8a82', '#7a7a72', '#6e6e66', '#626258')[i]
        L.r(0, y, 16, 4, c); L.hl(0, 15, y, '#9a9a92' if i == 0 else '#8a8a82'); L.hl(0, 15, y + 3, '#4e4e46')
    for _ in range(8): L.p(int(R() * 16), int(R() * 16), '#5e5e56')
    L.vl(0, 0, 15, '#b8bcc4'); L.vl(1, 0, 15, '#6a6e76')                       # el pasamanos de la pared
    return L

# 1.52 (lo pidió el usuario: «el alto de la pared no puede ser igual que el de la puerta»): la pared de dentro tiene 32 px (2 casillas);
# la puerta, 27 px de marco (2,03 m frente a los 2,5 m del techo, a escala de la pared), con la pared a la vista encima del dintel
TOP = 5
def puertaI():
    """la puerta de madera de dentro del piso: el marco, cuatro cuarterones, el pomo de latón y la sombra del umbral"""
    L = Lienzo(32, 32); t = TOP
    L.r(7, t, 18, 32 - t, MAD[3])                                             # el marco
    L.r(8, t + 1, 16, 31 - t, MAD[0]); L.vl(8, t + 1, 31, MAD[2]); L.hl(8, 23, t + 1, MAD[2]); L.vl(23, t + 2, 31, MAD[1])
    for (x, y, h) in ((10, t + 3, 8), (17, t + 3, 8), (10, t + 14, 10), (17, t + 14, 10)):  # los cuarterones
        L.r(x, y, 5, h, MAD[1]); L.hl(x, x + 4, y, MAD[3]); L.vl(x, y, y + h - 1, MAD[3]); L.vl(x + 4, y + 1, y + h - 1, MAD[2])
    L.p(21, t + 13, '#e8c860'); L.p(21, t + 14, '#a88a30'); L.p(22, t + 13, '#f8e8a0')   # el pomo
    L.hl(8, 23, 31, '#5a3c22')                                                 # el umbral
    L.contorno(K)
    return L

def puertaM():
    """la puerta metálica de los locales: gris, con la barra antipánico, la rejilla de abajo y el cartel en blanco"""
    L = Lienzo(32, 32); G0, G1, G2, G3 = '#4a5058', '#7a828c', '#a4acb6', '#c8d0d8'; t = TOP
    L.r(7, t, 18, 32 - t, '#3a3e44')
    L.r(8, t + 1, 16, 31 - t, G1); L.vl(8, t + 1, 31, G2); L.hl(8, 23, t + 1, G3); L.vl(23, t + 2, 31, G0)
    L.r(12, t + 4, 8, 4, '#e8e8e0'); L.hl(13, 18, t + 5, '#9aa2aa'); L.hl(13, 16, t + 6, '#9aa2aa')   # el cartel
    L.r(9, t + 13, 14, 2, G3); L.hl(9, 22, t + 15, G0); L.p(9, t + 12, G0); L.p(22, t + 12, G0)   # la barra
    for y in range(24, 30, 2): L.hl(11, 20, y, G0)                                         # la rejilla
    L.hl(8, 23, 31, '#2e3238')
    L.contorno(K)
    return L

def perchero():
    """la percha de pared: la tabla con tres ganchos, una chaqueta verde, una gabardina y un paraguas colgado"""
    L = Lienzo(32, 32)
    L.r(6, 8, 20, 3, MAD[1]); L.hl(6, 25, 8, MAD[2]); L.hl(6, 25, 10, MAD[3])
    for x in (9, 16, 23): L.p(x, 11, '#d8d0b0'); L.p(x, 12, '#a89e7a')
    L.r(6, 12, 7, 12, '#3f8a46'); L.vl(6, 12, 23, '#62aa56'); L.r(8, 12, 3, 2, '#2e6a36'); L.hl(6, 12, 23, '#2e6a36')   # la chaqueta
    L.r(13, 12, 7, 15, '#c8b48a'); L.vl(13, 12, 26, '#e0d0a8'); L.vl(16, 14, 26, '#a8946a'); L.hl(13, 19, 26, '#8a7650')   # la gabardina
    L.vl(23, 12, 27, '#26262e'); L.r(22, 18, 3, 8, '#4a72c2'); L.vl(22, 18, 25, '#6a92e2'); L.p(24, 28, '#26262e'); L.p(25, 27, '#26262e')   # el paraguas
    L.contorno(K)
    return L

sale('bajS1', bajS(1), 'sotano-tiles'); sale('bajS2', bajS(2), 'sotano-tiles'); sale('escS', escS(), 'sotano-tiles')
sale('puertaI', puertaI(), 'sotano-alto'); sale('puertaM', puertaM(), 'sotano-alto'); sale('perchero', perchero(), 'sotano-alto')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
