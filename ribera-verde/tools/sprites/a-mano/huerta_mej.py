# python3 -I tools/sprites/a-mano/huerta_mej.py  (Python 3 + Pillow; no va en los scripts de npm)
# Lo pidió el usuario: «Opción a comprar mejoras como tanques de agua de 1m3 o tanques azules de 100L dependiendo, también sistema de
# riego... Herramientas para trabajar la tierra o motoazada siguiente mejora... Habría que hacer los sprites y eso». Las mejoras de la
# huerta abandonada, a mano como los muebles del taller (taller.py): contorno #2a2a34, tres tonos por material, luz de arriba a la
# izquierda, de frente a 3/4 y a 16 px/m. Ni marcas ni rótulos.
#  · huerta-mej (mueble_escala, 32 × 48, pies en (16, 47)): bidonA (el bidón azul de 100 L, 50 × 70 cm, sobre dos bloques),
#    ibcD-0..4 (el depósito de 1000 L, 1,2 × 1 × 1,16 m, en su jaula y su palé, con el agua de vacío a lleno), herrH (la laya, la
#    azada y el rastrillo apoyados en un travesaño a 1 m), motoA (la motoazada de perfil, 1,3 m × 1 m) y bombaS (la placa solar
#    sobre su estaca con el programador del goteo y la bomba)
# Sale a art/crudo/huerta-mej/<sprite>/unica/00.png (después, node tools/sprites/procesar.js huerta-mej --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P
from salon import suelo

K = '#2a2a34'
AZ = ('#173c78', '#2358a8', '#3a78c8', '#6a9ee0')   # el polietileno azul
AC = ('#4a4e56', '#7a7e88', '#a8acb4', '#ccd0d6')   # el acero galvanizado
NG = ('#1e1e24', '#2e2e36', '#44444e')              # la goma y el plástico negro
RJ = ('#7a1e1e', '#b83030', '#e05a4a')              # el rojo del depósito de gasolina
LA = ('#a07a10', '#e0b030', '#f4d870')              # el latón
HO = ('#76787a', '#8e9092', '#a6a8aa')              # el hormigón de los bloques
MA = ('#5a3e1e', '#7a5a30', '#a07a44', '#c49a5a')   # la madera de los mangos y el travesaño
PL = ('#b8c0c2', '#d2d8da', '#e6eaea')              # el plástico blanco translúcido del IBC
AG = ('#7a98a8', '#9ab4c0', '#b8d0da')              # el agua vista a través
VI = ('#3e3630', '#5a5048', '#7a7068')              # la madera vieja, gris, del travesaño


def linea(L, x0, y0, x1, y1, c):
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    e = dx + dy
    while True:
        L.p(x0, y0, c)
        if x0 == x1 and y0 == y1: break
        e2 = 2 * e
        if e2 >= dy: e += dy; x0 += sx
        if e2 <= dx: e += dx; y0 += sy


def bidonA():
    """el bidón de 100 L (50 × 70 cm, 8 × 11 px) de polietileno azul, con dos nervios, los dos tapones arriba y el grifo de latón
    abajo, sobre dos bloques de hormigón para que quepa la regadera"""
    L = Lienzo(32, 48)
    x0, x1 = 12, 19
    for x in (12, 17): L.r(x, 44, 3, 3, HO[1]); L.hl(x, x + 2, 44, HO[2]); L.vl(x + 2, 45, 46, HO[0])   # los bloques
    L.r(x0, 34, 8, 10, AZ[1]); L.hl(x0 + 1, x1 - 1, 33, AZ[1])                                       # el cuerpo, la tapa redonda
    L.vl(x0, 34, 43, AZ[2]); L.vl(x0 + 1, 34, 43, AZ[3]); L.vl(x1, 34, 43, AZ[0]); L.vl(x1 - 1, 35, 43, AZ[0])
    L.hl(x0 + 1, x1 - 1, 34, AZ[2])
    for y in (37, 40): L.hl(x0 + 2, x1, y, AZ[0])                                                   # los nervios
    L.hl(x0 + 1, x1 - 1, 43, AZ[0])
    L.p(14, 32, AZ[0]); L.p(17, 32, AZ[0])                                                          # los tapones
    L.r(20, 41, 2, 1, LA[1]); L.p(21, 42, LA[0]); L.p(20, 40, LA[2])                                # el grifo
    L.contorno(K); suelo(L, x0, x1, K)
    return L


def ibcD(n):
    """el depósito de 1000 L (1,2 × 1 × 1,16 m): la jaula de tubo galvanizado cada 25 cm, el depósito blanco translúcido con el
    agua a n cuartos, la boca arriba, la válvula abajo y el palé negro"""
    L = Lienzo(32, 48)
    x0, x1, yf, yb, yt = 6, 24, 28, 43, 21
    # la tapa, a medio fondo: el depósito por arriba, la boca y los tubos de la jaula
    L.r(x0 + 1, yt, x1 - x0 - 1, yf - yt, PL[1])
    L.hl(x0 + 1, x1 - 1, yt, AC[2])
    for x in range(x0 + 4, x1, 4): L.vl(x, yt, yf - 1, AC[2]); L.vl(x + 1, yt + 1, yf - 1, PL[0])
    for y in (yt + 3, yt + 6): L.hl(x0 + 1, x1 - 1, y, AC[1])
    L.r(14, yt + 2, 4, 3, NG[2]); L.r(15, yt + 2, 2, 2, NG[1]); L.hl(14, 17, yt + 1, AC[3])           # la boca de 150 mm
    # la cara: el depósito con el agua y la jaula por delante
    L.r(x0 + 1, yf, x1 - x0 - 1, yb - yf + 1, PL[2])
    L.vl(x0 + 1, yf, yb, PL[1]); L.vl(x1 - 1, yf, yb, PL[0])
    alto = yb - yf - 1
    h = round(alto * n / 4)
    if h:
        L.r(x0 + 1, yb - h + 1, x1 - x0 - 1, h, AG[1])
        L.vl(x1 - 1, yb - h + 1, yb, AG[0])
        L.hl(x0 + 1, x1 - 1, yb - h + 1, AG[2])
    for y in range(yf, yb + 1, 4): L.hl(x0, x1, y, AC[1]); L.hl(x0 + 1, x1 - 1, y, AC[2])
    for x in range(x0, x1 + 1, 4):
        L.vl(x, yt if x in (x0, x1) else yf, yb, AC[1])
        if x not in (x0, x1): L.vl(x, yf, yb, AC[2])
    L.vl(x0, yt, yb, AC[2]); L.vl(x1, yt, yb, AC[0])
    L.r(14, 40, 4, 3, NG[1]); L.hl(14, 17, 40, NG[2]); L.r(18, 41, 2, 1, NG[0])                     # la válvula de mariposa
    # el palé de plástico negro, con las patas
    L.r(x0, 44, x1 - x0 + 1, 1, NG[1]); L.hl(x0, x1, 44, NG[2])
    for x in (x0, 14, x1 - 2): L.r(x, 45, 3, 2, NG[1]); L.p(x, 45, NG[2])
    L.contorno(K); suelo(L, x0, x1, K)
    return L


def herrH():
    """la laya de dos púas, la azada y el rastrillo con la cabeza en el suelo y el mango (1,2 m) apoyado en un travesaño de
    madera vieja a 1 m sobre dos estacas"""
    L = Lienzo(32, 48)
    for x in (4, 27): L.vl(x, 31, 46, VI[1]); L.p(x, 31, VI[2])                                    # las estacas
    L.hl(3, 28, 30, VI[2]); L.hl(3, 28, 31, VI[0])                                                 # el travesaño
    # la laya: las dos púas largas, el travesaño de hierro, el mango y el puño
    for x in (7, 10): L.vl(x, 39, 46, AC[2]); L.p(x + 1, 46, AC[0])
    L.hl(7, 10, 38, AC[1]); L.p(8, 37, AC[0])
    linea(L, 8, 36, 11, 25, MA[3]); linea(L, 9, 36, 12, 25, MA[1])
    L.hl(10, 13, 24, MA[2])
    # la azada: la hoja de 20 cm de cara, el ojo y el mango
    L.r(13, 43, 5, 3, AC[1]); L.hl(13, 17, 43, AC[2]); L.hl(14, 16, 46, AC[0]); L.vl(13, 43, 45, AC[3])
    L.r(15, 41, 2, 2, AC[0])
    linea(L, 15, 40, 17, 25, MA[3]); linea(L, 16, 40, 18, 25, MA[1])
    # el rastrillo: el peine de 40 cm, las púas y el mango
    L.hl(20, 26, 42, AC[2]); L.hl(20, 26, 43, AC[0])
    for x in range(20, 27, 2): L.vl(x, 44, 46, AC[1])
    linea(L, 23, 41, 23, 25, MA[3]); linea(L, 24, 41, 24, 25, MA[1])
    L.contorno(K); suelo(L, 3, 28, K)
    return L


def motoA():
    """la motoazada de perfil (1,4 m × 1 m): las fresas de 35 cm con el guardabarros, el motor con el depósito rojo, la rueda de
    transporte delante, el espolón detrás y el manillar hacia atrás y arriba con los puños; sin marca"""
    L = Lienzo(32, 48)
    cx, cy = 10, 43
    for y in range(cy - 4, cy + 4):                                                                # las fresas
        for x in range(cx - 4, cx + 5):
            d = (x - cx) ** 2 + (y - cy) ** 2
            if d <= 13: L.p(x, y, AC[0] if d > 5 else NG[2])
    for x, y in ((cx - 3, cy - 2), (cx + 3, cy - 2), (cx - 3, cy + 2), (cx + 3, cy + 2), (cx, cy - 3), (cx, cy + 3)):
        L.p(x, y, AC[2])                                                                           # las cuchillas
    L.p(cx, cy, AC[3])                                                                             # el eje
    L.hl(5, 15, 38, RJ[1]); L.hl(6, 14, 37, RJ[2]); L.p(5, 39, RJ[0]); L.p(15, 39, RJ[0])           # el guardabarros
    L.r(8, 32, 7, 5, NG[1]); L.hl(8, 14, 32, NG[2]); L.vl(8, 32, 36, NG[2])                         # el motor
    L.r(10, 33, 3, 2, AC[1]); L.hl(10, 12, 33, AC[2])                                              # la culata
    L.r(13, 34, 2, 3, NG[0])                                                                       # el escape
    L.r(8, 30, 6, 2, RJ[1]); L.hl(8, 13, 30, RJ[2]); L.p(10, 29, NG[0])                            # el depósito con su tapón
    L.r(6, 33, 2, 3, AC[1])                                                                        # el filtro del aire
    linea(L, 3, 43, 7, 38, AC[1]); L.r(2, 43, 3, 3, NG[1]); L.p(3, 44, AC[2])                      # la rueda de transporte
    L.vl(15, 40, 46, AC[1]); L.vl(16, 41, 46, AC[0])                                              # el espolón
    linea(L, 14, 35, 25, 27, AC[1]); linea(L, 14, 36, 25, 28, AC[0])                               # el manillar
    L.r(25, 26, 3, 2, NG[1]); L.p(25, 26, NG[2])                                                   # los puños
    linea(L, 20, 30, 22, 28, NG[2])                                                                # la maneta del embrague
    L.contorno(K); suelo(L, 2, 16, K)
    return L


def bombaS():
    """la placa solar de 30 × 40 cm inclinada sobre su estaca, la caja gris del programador del goteo y la bomba en el suelo con
    su manguera"""
    L = Lienzo(32, 48)
    L.vl(15, 33, 46, AC[1]); L.vl(16, 33, 46, AC[0])                                              # la estaca
    L.r(11, 26, 10, 6, '#1a2a5a'); L.hl(11, 20, 26, AC[3]); L.hl(11, 20, 31, AC[0])                # la placa, con el marco
    L.vl(11, 26, 31, AC[2]); L.vl(20, 26, 31, AC[1])
    for x in (14, 17): L.vl(x, 27, 30, '#3a5a9a')
    L.hl(12, 19, 28, '#3a5a9a'); L.p(12, 27, '#7a9ad8')
    L.r(13, 35, 5, 4, AC[2]); L.hl(13, 17, 35, AC[3]); L.p(14, 37, '#5ac85a'); L.p(16, 37, NG[0])   # el programador y su luz
    L.r(19, 43, 5, 4, AC[1]); L.hl(19, 23, 43, AC[2]); L.r(20, 42, 2, 1, NG[1])                   # la bomba
    L.hl(24, 28, 45, NG[1]); L.hl(24, 28, 46, NG[0]); linea(L, 17, 38, 20, 42, NG[1])              # la manguera y el cable
    L.contorno(K); suelo(L, 13, 28, K)
    return L


SAL = {'bidonA': bidonA(), 'herrH': herrH(), 'motoA': motoA(), 'bombaS': bombaS()}
for n in range(5): SAL['ibcD-%d' % n] = ibcD(n)


def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'huerta-mej', n, 'unica'); os.makedirs(d, exist_ok=True)
        for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
        L.im.save(os.path.join(d, '00.png'))
        print('huerta-mej', n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
