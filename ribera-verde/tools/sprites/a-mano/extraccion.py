# python3 -I tools/sprites/a-mano/extraccion.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.36 (lo pidió el usuario): un mueble por máquina de extracción en el piso, a 16 px/m como la mesa de la tía, más la mesa de
# manicurar. Objetos altos (objeto_alto, 32 × 32, pies en (16, 31)), de una casilla (x 8-23):
#  · trim: la mesa de manicurar (la de madera de la tía), con la bandeja de rejilla, cogollos, las tijeras de punta fina y guantes;
#  · prensaM: la prensa de rosin de palanca en su mesita, con las dos planchas y el papel de horno;
#  · tamizM: los tamices de seda apilados en su bastidor, de grueso a fino, y el kief en el cristal;
#  · mallas: el cubo de 20 L con agua y hielo y las bolsas de malla colgadas del borde (colores propios, sin marcas);
#  · lavadora: la lavadora de extracción, pequeña y de carga superior (cuba de plástico azul translúcido, tapa, dos mandos y la
#    manguera de desagüe; corregida a petición del usuario: no la de ropa de puerta delantera);
#  · staticM: la máquina de static: la base negra con la bandeja, la placa cargada encima y su pantallita.
# Sale a art/crudo/extraccion-piso/<sprite>/unica/00.png (después, node tools/sprites/procesar.js extraccion-piso --atlas)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

K = '#2a2a34'   # el contorno de los muebles (el de salon.py)
SAL = {}
def sale(n, L): SAL[n] = L

M0, M1, M2, M3 = '#5a3a20', '#8a5a32', '#c8935a', '#e0b07a'   # la madera de las mesas
def mesa(L, y=22):
    """la mesita de madera de 16 de ancho: el tablero en y, el canto y las patas hasta la fila 31"""
    L.r(8, y, 16, 3, M2); L.hl(8, 23, y, M3); L.hl(8, 23, y + 3, M1)
    for x in (9, 21):
        L.r(x, y + 4, 2, 31 - y - 3, M0); L.vl(x, y + 4, 30, M1)
    L.hl(11, 20, y + 5, M1)   # el travesaño

def trim():
    L = Lienzo(32, 32); mesa(L)
    L.r(10, 19, 9, 3, '#3a4a40'); L.hl(10, 18, 19, '#5a6e60')                     # la bandeja de rejilla
    for x in range(11, 18, 2): L.p(x, 20, '#24302a')
    for (x, y) in ((11, 17), (14, 18), (16, 17)):                                   # los cogollos
        L.r(x, y, 2, 2, '#6fae4a'); L.p(x, y, '#9cd36a'); L.p(x + 1, y + 1, '#d8c070')
    L.hl(19, 22, 20, '#d0d4d8'); L.p(23, 19, '#d0d4d8'); L.p(20, 21, '#e06a30'); L.p(21, 21, '#e06a30')   # las tijeras
    L.r(19, 17, 3, 2, '#5aa0d8'); L.p(19, 16, '#5aa0d8')                            # los guantes
    L.contorno(K)
    return L

def prensaM():
    L = Lienzo(32, 32); mesa(L)
    L.r(11, 20, 10, 2, '#3a3a40'); L.hl(11, 20, 20, '#5a5a62')                       # la base
    L.vl(12, 9, 19, '#c03a2a'); L.vl(19, 9, 19, '#c03a2a'); L.vl(13, 9, 19, '#8a2a20'); L.vl(20, 9, 19, '#8a2a20')   # los postes
    L.r(12, 8, 9, 2, '#c03a2a'); L.hl(12, 20, 8, '#e05a44')                          # el puente
    L.r(13, 14, 7, 2, '#b8bcc4'); L.hl(13, 19, 14, '#e0e4ea')                        # la plancha de arriba
    L.r(13, 18, 7, 2, '#b8bcc4'); L.hl(13, 19, 18, '#e0e4ea')                        # la de abajo
    L.hl(14, 18, 17, '#f4f0e0'); L.p(16, 17, '#e0a828')                              # el papel con el rosin
    L.vl(16, 10, 13, '#5a5a62')                                                      # el husillo
    L.hl(17, 24, 10, '#3a3a40'); L.p(25, 10, '#1a1a1e'); L.p(25, 9, '#1a1a1e')       # la palanca
    L.p(14, 15, '#f05030')                                                           # la luz del calor
    L.contorno(K)
    return L

def tamizM():
    L = Lienzo(32, 32); mesa(L)
    L.r(10, 20, 12, 2, '#d8e8ec'); L.hl(10, 21, 20, '#f0f8fa')                       # el cristal
    for i, (y, c) in enumerate(((12, '#8a8e96'), (15, '#c8b878'), (18, '#e8e0c0'))):   # los tamices, de grueso a fino
        L.r(10 + i, y, 12 - i, 3, M1); L.r(11 + i, y + 1, 10 - i, 1, c); L.hl(10 + i, 21, y, M3)
    L.r(14, 19, 4, 1, '#e8d890'); L.p(15, 18, '#f4e8b0')                             # el kief
    L.p(23, 19, '#c8c8d0'); L.p(23, 20, '#c8c8d0'); L.p(24, 18, '#8a8e96')           # la tarjeta de rascar
    L.contorno(K)
    return L

def mallas():
    L = Lienzo(32, 32)
    L.r(10, 17, 12, 14, '#e8ecee'); L.vl(10, 17, 30, '#ffffff'); L.vl(21, 17, 30, '#b8c0c4')   # el cubo
    L.hl(9, 22, 17, '#c8d0d4'); L.hl(11, 20, 31, '#a8b0b4')
    L.r(11, 18, 10, 2, '#a8d8f0'); L.p(12, 18, '#f4fbff'); L.p(17, 18, '#f4fbff'); L.p(19, 19, '#f4fbff')   # el agua y el hielo
    for (x, c, h) in ((9, '#e0c040', 9), (13, '#58a8e0', 7), (17, '#e05a6a', 8), (21, '#7ac060', 10)):   # las bolsas, colgadas
        L.r(x, 15, 3, 3, c); L.vl(x + (0 if x < 16 else 2), 18, 17 + h, c)
    L.hl(10, 21, 22, '#c8d0d4'); L.r(15, 24, 2, 3, '#b8c0c4')                        # el aro y la etiqueta
    L.contorno(K)
    return L

def lavadora():
    """la lavadora de extracción: una pequeña de carga superior (no de ropa de puerta delantera), como las de las bolsas de malla:
    la base blanca, la cuba de plástico azul translúcido con el agua y el hielo dentro, el aro blanco, la tapa azul con su asa, la
    tira de los dos mandos detrás y la manguera blanca de desagüe por el lado"""
    L = Lienzo(32, 32)
    B0, B1, B2, B3 = '#1a3a8a', '#2a52b8', '#3a6ad8', '#6a98ec'   # el azul de la cuba, de sombra a brillo
    W0, W1, W2 = '#b8c0c8', '#dde2e8', '#f6f8fa'                    # el plástico blanco
    L.r(10, 25, 12, 6, W1); L.vl(10, 25, 30, W2); L.vl(21, 25, 30, W0); L.hl(10, 21, 31, W0)   # la base
    L.hl(11, 20, 27, W0); L.p(13, 29, W0); L.p(18, 29, W0)                                     # las juntas de la base
    L.r(10, 13, 12, 12, B1); L.vl(10, 13, 24, B2); L.vl(11, 14, 23, B3); L.vl(21, 13, 24, B0)  # la cuba translúcida
    L.r(11, 18, 10, 7, B0); L.hl(11, 20, 18, '#5a8acc')                                         # el agua, que se ve a través
    for (x, y) in ((12, 19), (15, 20), (18, 19), (13, 22), (17, 22), (19, 23)): L.p(x, y, '#d8f0ff')   # y el hielo flotando
    for x in (14, 17): L.vl(x, 14, 17, B2)                                                      # los nervios de la cuba
    L.r(9, 11, 14, 2, W2); L.hl(9, 22, 12, W0)                                                  # el aro blanco
    L.r(10, 8, 12, 3, B2); L.hl(10, 21, 8, B3); L.hl(12, 18, 10, B1)                            # la tapa azul
    L.r(12, 9, 5, 1, W2)                                                                        # su asa
    L.r(18, 7, 4, 2, W1); L.p(19, 7, B1); L.p(21, 7, B1)                                        # la tira de los dos mandos
    L.vl(22, 13, 28, W2); L.vl(23, 14, 29, W0); L.p(23, 13, W1); L.hl(22, 24, 30, W0)           # la manguera de desagüe
    L.contorno(K)
    return L

def staticM():
    L = Lienzo(32, 32); mesa(L)
    L.r(10, 18, 12, 4, '#24262c'); L.hl(10, 21, 18, '#3a3e46')                       # la base
    L.r(11, 17, 10, 1, '#8a8e96')                                                     # la bandeja con la flor fría
    for x in (12, 15, 18): L.p(x, 16, '#7ab65a')
    L.vl(11, 9, 16, '#5a5e66'); L.vl(20, 9, 16, '#5a5e66')                            # las guías
    L.r(10, 10, 12, 2, '#c8e4f0'); L.hl(10, 21, 10, '#f0faff'); L.hl(12, 19, 12, '#f4e8b0')   # la placa cargada, con la resina
    L.r(13, 19, 5, 2, '#0a1a10'); L.hl(14, 16, 19, '#58f080')                         # la pantallita
    L.p(20, 19, '#e04040')
    L.p(23, 21, '#2a2a30'); L.vl(24, 22, 26, '#2a2a30')                               # el cable
    L.contorno(K)
    return L

for n, f in (('trim', trim), ('prensaM', prensaM), ('tamizM', tamizM), ('mallas', mallas), ('lavadora', lavadora), ('staticM', staticM)):
    sale(n, f())

def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'extraccion-piso', n, 'unica'); os.makedirs(d, exist_ok=True)
        for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
        L.im.save(os.path.join(d, '00.png'))
        print('extraccion-piso', n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
