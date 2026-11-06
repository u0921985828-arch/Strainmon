# python3 -I tools/sprites/a-mano/taberna.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.57.2 (lo pidió el usuario: «en el bar este del Puerto Viejo… no están para nada acorde con el estilo… Una silla tiene que ser de
# verdad un mueble… crea todo como muebles… que parezca que la haya creado la misma persona»): la taberna de Puerto Viejo entera a
# mano, a 16 px/m y de frente a 3/4 como el salón (salon.py): el frente a su ancho y alto reales, la tapa a medio fondo, el contorno
# de los muebles y la madera de la silla de la tía. Cada silla, un mueble aparte en el que te sientas. Genérico, sin marcas.
#  · taberna-alto (mueble_escala, 32 × 48, base en (16, 47)): mesaTb (la mesa de pino de 80 × 80 × 75 cm con un vino y un pintxo),
#    sillaTs (la silla de madera de cara, al norte de la mesa), sillaTn (la misma de espaldas, al sur: la silla de la tía de salon.py),
#    taburTb (el taburete de barra de 75 cm con el aro de los pies), cafeTb (la cafetera de dos grupos sobre su mueble de acero de
#    90 cm) y barrilTb (la barrica de 95 cm de pie, de mesa alta, con un vaso)
#  · taberna-ancho (mueble_ancho, 48 × 48, base en (16, 47); la casilla de la derecha, k + '2', no se pinta): barraTb (la barra de
#    pintxos de 2 m y 1,1 m: el frente de tablas de pino, el mármol y la vitrina con las banderillas) y botTb (el botellero de pared
#    de 2 m: dos baldas de botellas, los vasos boca abajo y el armario de abajo)
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js taberna-alto taberna-ancho --atlas
# --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P
from salon import suelo, silla

SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

K = '#2a2a34'                                                          # el contorno de los muebles (el de salon.py)
O, D, M, W, C, H = '#2e2a2a', '#3a2a20', '#74502e', '#c48a52', '#d8a868', '#e6bc80'   # la madera de la silla de la tía
AC = ('#4a4e56', '#7a7e88', '#a8acb4', '#ccd0d6')                       # el acero
MA = ('#b8b4ac', '#d8d4cc', '#eeeae4')                                  # el mármol
VI = ('#7ab8c8', '#b8e0e8', '#e8f8fc')                                  # el cristal
VINO = ('#5a1020', '#8a1c30')

def mesaTb():
    """la mesa de pino de 80 × 80 cm y 75 de alto (13 × 12 px): la tapa a medio fondo, el faldón y las cuatro patas; encima, un vaso
    de vino y un plato con un pintxo"""
    L = Lienzo(32, 48)
    x0, x1 = 9, 22
    L.r(x0, 34, 14, 5, C); L.hl(x0, x1, 34, H); L.hl(x0, x1, 38, W)         # la tapa
    for x in range(x0 + 2, x1, 4): L.vl(x, 35, 37, W)                       # las juntas de las tablas
    L.r(x0, 39, 14, 2, M); L.hl(x0, x1, 40, D)                              # el canto y el faldón
    L.vl(x0 + 2, 41, 44, D); L.vl(x1 - 2, 41, 44, D)                        # las patas de atrás, más cortas (más lejos)
    L.r(x0, 41, 2, 6, W); L.vl(x0, 41, 46, C); L.r(x1 - 1, 41, 2, 6, M)     # las de delante
    L.r(11, 32, 2, 3, VINO[1]); L.p(11, 32, VINO[0]); L.vl(11, 31, 31, VI[2])   # el vaso de vino
    L.hl(16, 20, 36, '#f4f4ee'); L.hl(17, 19, 35, '#f4f4ee'); L.r(17, 33, 3, 2, '#e0b060'); L.p(18, 32, '#4a7a2e')   # el pintxo
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def sillaTs():
    """la silla de madera de la tía, de cara (mira al sur, a la mesa de debajo): el respaldo detrás con su travesaño curvo y el
    listón, el asiento a 45 cm (7 px) visto desde arriba y las patas de delante"""
    L = Lienzo(32, 48)
    x0, x1 = 12, 19; yF = 47; yS = yF - 7; yT = yS - 9
    L.vl(x0 + 1, yT + 2, yS - 1, M); L.vl(x1 - 1, yT + 2, yS - 1, M)         # los palos de atrás (más lejos, más oscuros)
    L.r(x0 + 1, yT, 6, 3, W); L.hl(x0 + 2, x1 - 2, yT, H); L.hl(x0 + 1, x1 - 1, yT + 2, M)   # el travesaño de arriba
    L.vl(15, yT + 3, yS - 1, W); L.vl(16, yT + 3, yS - 1, M)                 # el listón del medio
    L.r(x0, yS, 8, 3, C); L.hl(x0, x1, yS, H); L.hl(x0, x1, yS + 2, W)       # el asiento, desde arriba
    L.hl(x0, x1, yS + 3, D)                                                  # el canto
    L.vl(x0 + 1, yS + 4, yF - 2, D); L.vl(x1 - 1, yS + 4, yF - 2, D)         # las patas de atrás, entre las de delante
    L.vl(x0, yS + 4, yF, W); L.vl(x1, yS + 4, yF, M)                         # las de delante
    L.hl(x0, x1, yF - 3, M)                                                  # el travesaño de las patas
    L.contorno(O)
    return L

def sillaTn():
    """la misma silla de espaldas (mira al norte, a la mesa de encima): la de la tía (salon.py), en su casilla"""
    S = silla(42)
    L = Lienzo(32, 48)
    for y in range(48):
        for x in range(32):
            c = S.g(x, y)
            if c[3]: L.p(x, y, c)
    return L

def taburTb():
    """el taburete de barra de 75 cm (12 px): el asiento redondo desde arriba, cuatro patas abiertas y el aro de los pies"""
    L = Lienzo(32, 48)
    for y, (a, b) in zip(range(35, 39), ((13, 18), (12, 19), (12, 19), (13, 18))):
        L.hl(a, b, y, C if y < 37 else W)
    L.hl(13, 16, 35, H); L.hl(12, 19, 38, M)                                  # el brillo y el canto
    L.vl(13, 39, 46, W); L.vl(18, 39, 46, M); L.vl(14, 39, 44, D); L.vl(17, 39, 44, D)   # las patas (las de atrás, más cortas)
    L.p(12, 46, W); L.p(19, 46, M)
    L.hl(12, 19, 43, AC[1]); L.hl(13, 18, 42, AC[2])                          # el aro de los pies, de hierro
    L.contorno(K); suelo(L, 12, 19, K)
    return L

def cafeTb():
    """la cafetera de dos grupos (60 cm) sobre su mueble de acero de 90: las tazas encima, los manómetros, los dos grupos con su
    brazo y la bandeja; el mueble con la puerta y el cajón de los posos"""
    L = Lienzo(32, 48)
    L.r(8, 33, 16, 14, AC[2]); L.hl(8, 23, 33, AC[3]); L.vl(23, 33, 46, AC[1])   # el mueble
    L.r(10, 36, 5, 9, AC[1]); L.r(17, 36, 5, 9, AC[1]); L.p(14, 40, AC[3]); L.p(17, 40, AC[3])   # las dos puertas
    L.r(10, 22, 12, 11, '#c8ccd2'); L.hl(10, 21, 22, '#e8ecf0'); L.vl(21, 22, 32, AC[1])   # el cuerpo de la cafetera
    for x in (11, 14, 17): L.r(x, 20, 2, 2, '#f4f4ee'); L.p(x, 20, '#d0d0c8')     # las tazas, encima
    L.r(12, 24, 2, 2, '#f4f4ee'); L.r(18, 24, 2, 2, '#f4f4ee'); L.p(12, 24, '#1e1e24'); L.p(18, 24, '#1e1e24')   # los manómetros
    for x in (11, 17):
        L.r(x, 28, 4, 2, AC[0]); L.hl(x - 1 if x == 11 else x, x + 4, 30, '#1e1e24')   # los grupos y el brazo del portafiltros
    L.hl(10, 21, 32, AC[0])                                                   # la bandeja
    L.p(13, 31, '#f4f4ee'); L.p(19, 31, '#f4f4ee')                            # las tazas debajo
    L.contorno(K); suelo(L, 8, 23, K)
    return L

def barrilTb():
    """la barrica de vino de pie (95 cm, 10 px de ancho), de mesa alta: las duelas, los aros de hierro y el grifo; encima, un vaso"""
    L = Lienzo(32, 48)
    filas = [(12, 20), (11, 21), (11, 21), (10, 22), (10, 22), (10, 22), (10, 22), (10, 22), (10, 22), (10, 22), (10, 22), (11, 21), (11, 21), (12, 20)]
    for i, (a, b) in enumerate(filas):
        y = 33 + i
        L.hl(a, b, y, W)
        for x in range(a + 2, b, 3): L.p(x, y, M)                            # las juntas de las duelas
        L.p(a, y, C); L.p(b, y, M)
    L.r(12, 31, 9, 2, C); L.hl(12, 20, 31, H)                                 # la tapa
    for y in (35, 44): L.hl(filas[y - 33][0], filas[y - 33][1], y, '#3a3a42')   # los aros
    L.r(15, 40, 3, 2, '#c8a040'); L.p(16, 42, '#c8a040')                      # el grifo
    L.r(14, 28, 2, 3, VI[1]); L.p(14, 28, VI[2]); L.r(14, 30, 2, 1, '#e0b040')   # el vaso, con un dedo de sidra
    L.contorno(K); suelo(L, 10, 22, K)
    return L

def barraTb():
    """la barra de pintxos de 2 m (32 px) y 1,1 m (18 px): el frente de tablas de pino, el zócalo, el mármol y la vitrina de cristal
    con las bandejas de pintxos"""
    L = Lienzo(48, 48)
    x0, x1 = 8, 39
    L.r(x0, 33, 32, 12, C)                                                    # el frente
    for x in range(x0, x1 + 1, 4): L.vl(x, 33, 44, W)                         # las tablas
    L.hl(x0, x1, 33, H)
    L.r(x0, 45, 32, 2, D)                                                     # el zócalo
    L.r(x0 - 1, 29, 34, 4, MA[1]); L.hl(x0 - 1, x1 + 1, 29, MA[2]); L.hl(x0 - 1, x1 + 1, 32, MA[0])   # el mármol
    L.r(x0 + 2, 22, 28, 7, VI[1]); L.hl(x0 + 2, x1 - 2, 22, VI[2]); L.vl(x0 + 2, 22, 28, VI[2]); L.vl(x1 - 2, 22, 28, VI[0])   # la vitrina
    for i, c in enumerate(('#e0b060', '#c84a30', '#4a7a2e', '#e0b060', '#f0e0b0', '#c84a30')):
        x = x0 + 4 + i * 4
        L.hl(x, x + 2, 27, '#f4f4ee'); L.r(x, 25, 3, 2, c); L.p(x + 1, 24, '#4a7a2e' if c != '#4a7a2e' else '#e0b060')   # los pintxos y su palillo
    L.contorno(K); suelo(L, x0 - 1, x1 + 1, K)
    return L

def botTb():
    """el botellero de pared de 2 m (32 px de ancho y de alto): el marco de pino, dos baldas de botellas (vino, vermú, licores), la
    fila de vasos boca abajo y el armario de abajo con sus dos puertas"""
    L = Lienzo(48, 48)
    x0, x1 = 8, 39
    L.r(x0, 15, 32, 32, D); L.r(x0, 15, 32, 2, W); L.hl(x0, x1, 15, H)        # el fondo y el copete
    L.vl(x0, 15, 46, W); L.vl(x1, 15, 46, M); L.vl(23, 17, 37, M)             # los costados y el montante
    cols = ('#2e5a2a', '#5a1020', '#c89a30', '#e8e0c8', '#2e5a2a', '#7a3a10', '#5a1020', '#3a6a8a')
    for fila, yb in enumerate((26, 36)):
        L.hl(x0 + 1, x1 - 1, yb, C); L.hl(x0 + 1, x1 - 1, yb + 1, M)         # la balda
        for i in range(9):
            x = x0 + 2 + i * 3 + (1 if i > 4 else 0)
            if x >= x1 - 1: break
            c = cols[(i + fila * 3) % len(cols)]
            alto = 7 if (i + fila) % 3 else 6
            L.r(x, yb - alto + 2, 2, alto - 2, c); L.vl(x, yb - alto, yb - alto + 1, c)   # la botella y el cuello
            L.p(x, yb - alto + 3, '#f4f4ee')                                  # el brillo
    for i in range(10): L.r(x0 + 2 + i * 3, 19, 2, 2, VI[1]); L.p(x0 + 2 + i * 3, 19, VI[2])   # los vasos boca abajo
    L.r(x0 + 1, 38, 30, 9, W); L.vl(23, 38, 46, M)                            # el armario
    L.hl(x0 + 1, x1 - 1, 38, C); L.p(21, 42, '#c8a040'); L.p(25, 42, '#c8a040')   # los tiradores
    L.contorno(K); suelo(L, x0, x1, K)
    return L

for f in (mesaTb, sillaTs, sillaTn, taburTb, cafeTb, barrilTb):
    sale(f.__name__, f(), 'taberna-alto')
for f in (barraTb, botTb):
    sale(f.__name__, f(), 'taberna-ancho')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
