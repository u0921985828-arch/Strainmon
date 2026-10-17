# python3 -I tools/sprites/a-mano/camarote.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.43.6 (lo pidió el usuario: «habilitar el camarote de arriba, el piso de arriba, como almacén» con «botes más grandes de cristal
# con bóvedas de humedad»): el camarote del piso de la tía, a 16 px/m como el piso.
#  · Casillas (tile, 16 × 16): floorCam, la tarima de pino en lamas de 8 cm; iwT_cam, el techo abuhardillado (machihembrado de
#    pino con la viga del faldón) e iwT_camV, con la ventana de tejado (el cristal con el cielo y su marco); iwB_cam, el murete de
#    pladur blanco con el rodapié; trampC, la trampilla abierta en el suelo con el último peldaño y la barandilla de la escalera.
#  · Objetos altos (objeto_alto, 32 × 32, pies en (16, 31)): estanteC, la estantería metálica de 180 cm con los tarros de cristal de
#    10 L (tapa de rosca y su sobre de humedad dentro); escaleraC, la escalera escamoteable del piso (la trampilla abierta en el
#    techo del pasillo y la escalera de aluminio plegable bajada hasta el suelo, contra la pared).
#  · Objeto de 1 casilla (objeto_1x1): deshumC, el deshumidificador blanco con su rejilla y el piloto verde.
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js camarote-tiles camarote-alto camarote-16 --atlas)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar

K = '#2a2a34'   # el contorno de los muebles (el de salon.py)
SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

PINO = ('#d8b07a', '#c89c64', '#b08452', '#8a6640')   # el pino, de claro a junta
def floorCam():
    """la tarima de pino: lamas de 4 px de ancho a matajunta, con algún nudo"""
    L = Lienzo(16, 16); R = azar(613)
    for y in range(16):
        f = y // 4
        for x in range(16):
            c = PINO[0] if (x + y * 3) % 7 else PINO[1]
            if y % 4 == 3: c = PINO[3]                                       # la junta entre lamas
            elif (x + f * 6) % 16 == 0: c = PINO[2]                           # la testa de cada lama
            L.p(x, y, c)
    for _ in range(3):
        x, y = int(R() * 15), int(R() * 4) * 4 + 1
        L.p(x, y, PINO[2]); L.p(x + 1, y, PINO[3])                           # los nudos
    return L

def iwT_cam(velux=False):
    """el techo abuhardillado: machihembrado de pino en vertical y la viga del faldón abajo; con velux, la ventana de tejado"""
    L = Lienzo(16, 16)
    for x in range(16):
        c = PINO[1] if x % 4 else PINO[3]
        L.vl(x, 0, 12, c)
        if x % 4 == 1: L.vl(x, 0, 12, PINO[0])
    L.r(0, 12, 16, 4, '#7a5432'); L.hl(0, 15, 12, '#9a6e44'); L.hl(0, 15, 15, '#4e341e')   # la viga
    if velux:
        L.r(3, 1, 10, 9, '#4a4e56'); L.r(4, 2, 8, 7, '#9ccbee'); L.hl(4, 11, 2, '#c6e4f8')     # el marco y el cielo
        L.r(4, 6, 8, 3, '#b4dcfa'); L.p(5, 3, '#ffffff'); L.p(6, 3, '#e8f4fc'); L.vl(8, 2, 8, '#6a6e78')
        L.hl(3, 12, 10, '#2e3238')
    return L

def iwB_cam():
    """el murete de pladur blanco (el de la buhardilla), con las juntas de las placas y el rodapié de pino"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 13, '#ece8e0'); L.hl(0, 15, 0, '#d4cfc4')
    L.vl(15, 1, 12, '#dcd7cc')                                               # la junta de la placa (120 cm)
    L.p(5, 4, '#e2ddd2'); L.p(10, 8, '#e2ddd2')                              # los tornillos, tapados
    L.r(0, 13, 16, 3, PINO[2]); L.hl(0, 15, 13, PINO[0]); L.hl(0, 15, 15, PINO[3])   # el rodapié
    return L

def trampC():
    """la trampilla en el suelo: el hueco oscuro, el último peldaño de aluminio y los dos largueros que asoman"""
    L = floorCam()
    L.r(2, 2, 12, 12, '#2a2420'); L.r(3, 3, 10, 10, '#141210')              # el hueco y su marco
    L.hl(2, 13, 2, PINO[3]); L.vl(2, 2, 13, PINO[3])
    L.hl(3, 12, 13, '#4a3e34')                                               # el canto del forjado, al fondo
    for x in (4, 11): L.vl(x, 3, 12, '#a8b0b8'); L.vl(x + 1, 3, 12, '#6e767e')   # los largueros
    for y in (5, 9): L.hl(4, 12, y, '#c8d0d6'); L.hl(4, 12, y + 1, '#7a828a')    # los peldaños
    L.p(4, 3, '#e4e8ec'); L.p(11, 3, '#e4e8ec')
    return L

VI0, VI1, VI2, VI3 = '#6e8c98', '#a8c4ce', '#c8dce4', '#e8f4f8'           # el cristal (el de almacen.py)
def tarro10(L, x, y, lleno, c):
    """un tarro de 10 L de 6 × 8: la tapa de latón, el cristal y lo de dentro hasta su nivel (c, el verde de los cogollos)"""
    L.hl(x + 1, x + 4, y, '#b08a3a'); L.hl(x + 1, x + 4, y + 1, '#8a6a2a')
    L.vl(x, y + 2, y + 7, VI0); L.vl(x + 5, y + 2, y + 7, VI0); L.hl(x + 1, x + 4, y + 7, VI0)
    L.r(x + 1, y + 2, 4, 5, '#3a4448')
    if lleno:
        L.r(x + 1, y + 7 - lleno, 4, lleno, c); L.p(x + 2, y + 7 - lleno, '#d8e4c0')
    L.vl(x + 1, y + 2, y + 4, VI3); L.p(x + 4, y + 3, VI2)
    L.p(x + 3, y + 5, '#e8e0c8')                                             # el sobre de humedad, dentro

def estanteC():
    """la estantería metálica de 180 cm (4 baldas, 3 con tarros de 10 L y la de abajo con las cajas de los sobres)"""
    L = Lienzo(32, 32); M0, M1, M2 = '#3a4048', '#7e8a94', '#b4bec6'
    x0, x1 = 6, 25
    for y in (2, 11, 20, 28): L.hl(x0, x1, y, M2); L.hl(x0, x1, y + 1, M1)
    for x in (x0, x1): L.vl(x, 1, 31, M0)
    VERDES = ('#5a8a3a', '#6e9a40', '#4e7a36')
    for i, y in enumerate((3, 12)):
        for j, x in enumerate((8, 15, 20 if i else 21)):
            if x + 5 <= x1: tarro10(L, x if x < 20 else 19, y, (6, 4, 5, 3, 6, 2)[i * 3 + j], VERDES[(i + j) % 3])
    L.r(8, 23, 7, 5, '#c8b48a'); L.hl(8, 14, 23, '#e0d0a8'); L.r(10, 25, 3, 1, '#4e7ab0')   # la caja de los sobres al 62 %
    L.r(16, 24, 7, 4, '#c8b48a'); L.hl(16, 22, 24, '#e0d0a8'); L.r(18, 25, 3, 1, '#4e7ab0')
    L.r(9, 21, 4, 1, '#f0ecd8')                                              # un sobre suelto
    L.contorno(K)
    return L

def escaleraC():
    """la escalera escamoteable: la trampilla del techo abierta (la tapa colgando) y la escalera de aluminio bajada contra la pared"""
    L = Lienzo(32, 32); A0, A1, A2 = '#6e767e', '#a8b0b8', '#d4dade'
    L.r(8, 0, 16, 4, '#3a2c20'); L.r(9, 1, 14, 2, '#141210'); L.hl(8, 23, 3, '#8a6640')   # el hueco del techo, con su marco
    L.r(21, 3, 3, 9, '#e8e2d4'); L.vl(23, 3, 11, '#c8c0b0'); L.p(22, 4, '#a89e8a')      # la tapa abierta, colgando
    for x in (11, 19):
        L.vl(x, 3, 31, A1); L.vl(x + 1, 3, 31, A0)                                       # los largueros
    for y in range(6, 31, 5):
        L.hl(12, 18, y, A2); L.hl(12, 18, y + 1, A0)                                     # los peldaños
    L.r(10, 30, 4, 2, '#2a2a30'); L.r(18, 30, 4, 2, '#2a2a30')                           # las zapatas de goma
    L.vl(14, 4, 9, '#8a8a90'); L.p(15, 9, '#d8483a')                                     # el cordón con su tirador
    L.contorno(K)
    return L

def deshumC():
    """el deshumidificador: la caja blanca, la rejilla de arriba, el depósito y el piloto verde (60-62 %)"""
    L = Lienzo(16, 16)
    L.r(4, 3, 9, 12, '#e8eaec'); L.hl(4, 12, 3, '#ffffff'); L.vl(12, 4, 14, '#b8bcc0'); L.hl(4, 12, 14, '#a8acb0')
    for x in range(5, 12, 2): L.vl(x, 4, 6, '#6a7078')                       # la rejilla
    L.r(5, 9, 7, 4, '#d4d8dc'); L.hl(5, 11, 9, '#f4f6f8')                     # el depósito
    L.p(11, 7, '#58d080'); L.p(5, 7, '#4a90c8')                               # los pilotos
    L.contorno(K)
    return L

sale('floorCam', floorCam(), 'camarote-tiles'); sale('iwT_cam', iwT_cam(), 'camarote-tiles'); sale('iwT_camV', iwT_cam(True), 'camarote-tiles')
sale('iwB_cam', iwB_cam(), 'camarote-tiles'); sale('trampC', trampC(), 'camarote-tiles')
sale('estanteC', estanteC(), 'camarote-alto'); sale('escaleraC', escaleraC(), 'camarote-alto')
sale('deshumC', deshumC(), 'camarote-16')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
